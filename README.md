# Hardened minimal tomcat

Minimal tomcat container based on alpine meant for production use.  TLS is
assumed to be provided externally by a load balancer.

- [Best practices](#best-practices)
- [Tomcat base image](#tomcat-base-image)
- [Application deployment](#application-deployment)
  - [Example Application Dockerfile](#example-application-dockerfile)
  - [Security Manager on by default](#security-manager-on-by-default)
  - [Debug security manager](#debug-security-manager)
  - [Disable Security Manager](#disable-security-manager)
- [Logging](#logging)
- [Filesystem layout](#filesystem-layout)
- [WebApp example](#webapp-example)

# Best practices

- Tomcat 9 running on openjdk11
  - JRE by default but JDK available by Docker build arg.
  - Configuration split between `CATALINA_HOME` and `CATALINA_BASE`.
- Docker practices
  - Minimal alpine image.
    - Final image size is 187MB.
    - Compatible with both AMD64 and ARM architectures.
  - PID 1 init program to handle process signals and child processes.
  - Application starts as a normal system user instead of `root`.
  - Web server starts in foreground.
  - Web server logs to stdout and stderr to be handled by Docker instead of
    writing logs to disk.
- Security hardened
  - CIS Apache Tomcat 9 Benchmark; v1.1.0 - 12-18-2020
  - Default tomcat apps removed.
  - Tomcat security manager enabled with a sane initial security policy.
  - Access restricted to tomcat user for configuration files
  - `unpackWARs` and `autoDeploy` is disabled.
  - Printing stack traces on error is disabled.
  - TRACE HTTP method disabled.
  - LockOutRealm is configured.
  - Shutdown port is disabled.
  - Shutdown command is randomized on boot.
  - Connector security configured for HTTP
  - Autodeployment on startup is disabled and `/webapps/ROOT` is defined for
    manual deployment context in `server.xml`.
  - Connection timeout set to 60 seconds.


# Tomcat base image

The tomcat base image can be viewed in [`Dockerfile`](Dockerfile).

    docker build -t tomcat .

# Application deployment

* `/webapps/ROOT` - Extract your application WAR here.
* `/data` - If your app requires persistent data then `/data` is the location
  assumed.

Security policy grants your app unconstrained access to the following locations.

```
/data
/dev/shm
/home/tomcat
/tmp
/var/tmp
/webapps/ROOT
```

Other locations will require a policy update.

Modify JVM behavior through the following environment variables.

* `CATALINA_OPTS`
* `JAVA_OPTS`

### Example Application Dockerfile

An example [application Dockerfile](example/Dockerfile) has also been provided.

Due to hardening automatic application deployment is disabled.  You must extract
your war files as part of Docker image building.

> Note: The application Dockerfile uses `java xf *.war` to extract an
> application into `/webapps/ROOT`.  This folder is the ROOT context for tomcat.

### Security Manager on by default

It is recommended to keep tomcat security hardening in place.  By default a very
broad policy is applied which allows most actions within reason.

If you wish to overwrite this policy then overwrite the following policy file in
the tomcat container.

* [`/tomcat/conf/catalina.policy`](tomcat-base/conf/catalina.policy) (see also [Tomcat
docs][tomcat-security]).

### Debug security manager

You can enable more debug logs for security manager with the following
environment variable.

    docker run -e CATALINA_OPTS=-Djava.security.debug=access ...

### Disable Security Manager

If you want to disable sandboxing entirely you can add the following line to the
end of your [application Dockerfile](example/Dockerfile) removing `-security`
option.

```dockerfile
CMD ["/opt/tomcat/bin/catalina.sh", "run"]
```

# Logging

All logs should push to stdout.

If your application has special logging enabled, then don't write to a file.
Instead, write the log to stdout and add a log prefix to differentiate instead.

* Logs with no prefix are assumed to be tomcat and its deployed application.
* Access logs are prefixed with `ACCESS:` followed by standard tomcat format.

For a `stdout` example, see `AccessLogValve` in
[`/tomcat/conf/server.xml`](tomcat-base/conf/server.xml).

# Filesystem layout

A filesystem layout has been generated highlighting the parts for tomcat
excluding Java.

See [filesystem-layout.txt](example/filesystem-layout.txt)

```bash
docker run -u root tomcat /bin/sh -c \
  'apk add --no-cache tree &> /dev/null; \
      rm -rf /var/cache/*; \
      tree /home/tomcat /tmp /var/cache /var/tmp /webapps /tomcat /opt/tomcat' \
  > example/filesystem-layout.txt
```

# WebApp example

You can try this out with Jenkins.  At the root of this repository download
Jenkins.

    curl -sSfLO https://get.jenkins.io/war-stable/2.361.3/jenkins.war

Build all prerequisite docker images.

    docker build --build-arg java=jdk --build-arg all=true -t tomcat .
    docker build -t sample -f example/Dockerfile .

Run Jenkins webapp in hardened tomcat container.

```bash
mkdir ../jenkins_home
JENKINS_HOME="$(cd ../jenkins_home; pwd)"
docker run -v "${JENKINS_HOME}:/data \
  -e JENKINS_HOME=/jenkins --rm -p 8080:8080 sample
```

Visit http://localhost:8080/ to see your example app running.  Use `CTRL+C` to
exit.

[tomcat-security]: https://tomcat.apache.org/tomcat-9.0-doc/security-manager-howto.html
