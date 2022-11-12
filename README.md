# Hardened minimal tomcat

Minimal tomcat container based on alpine meant for production use.  TLS is
assumed to be provided externally by a load balancer.

# Best practices

- Tomcat 9 running on openjdk11
  - Configuration split between `CATALINA_HOME` and `CATALINA_BASE`.
  - Final image size is 292MB.
  - Compatible with both AMD64 and ARM (due to Java on Alpine)
- Docker practices
  - Minimal alpine image.
  - PID 1 init program to handle process signals and child processes.
  - Application starts as a normal system user instead of `root`.
  - Web server starts in foreground.
  - Web server logs to stdout and stderr to be handled by Docker instead of
    writing logs to disk.
- Security hardened
  - CIS Apache Tomcat 9 Benchmark; v1.1.0 - 12-18-2020

# Tomcat base image

The tomcat base image can be viewed in [`Dockerfile`](Dockerfile).

    docker build -t tomcat .

# Application deployment

An example [application Dockerfile](Dockerfile.multistage) has also been
provided.

Due to hardening `unpackWARs` and `autoDeploy` are both disabled.  You must
extract your war files as part of Docker image building.

> Note: The application Dockerfile uses `java xf *.war` to extract an
> application into `/webapps/ROOT`.

It is recommended to keep tomcat security hardening in place and add your own
[`catalina.policy`](tomcat-base/conf/catalina.policy) (see [Tomcat
docs][tomcat-security]).  However, if you want to disable sandboxing entirely
you can add the following line to the end of your [application
Dockerfile](Dockerfile.multistage) removing `-security` option.

```dockerfile
CMD ["/opt/tomcat/bin/catalina.sh", "run"]
```

# Logging

All logs push to stdout.  Access logs are prefixed with `ACCESS:` followed by
the standard tomcat logging format.

# Filesystem layout

A filesystem layout has been generated highlighting the parts for tomcat
excluding Java.

See [filesystem-layout.txt](filesystem-layout.txt)

```bash
docker run -itu root tomcat /bin/sh -c \
  'apk add tree &> /dev/null; tree /tmp /webapps /opt/tomcat /tomcat' \
  > filesystem-layout.txt
```

# WebApp example

You can try this out with Jenkins.  At the root of this repository download
Jenkins.

    curl -sSfLO https://get.jenkins.io/war-stable/2.361.3/jenkins.war

Build all prerequisite docker images.

    docker build -t tomcat .
    docker build -t sample -f Dockerfile.multistage .
    mkdir ../jenkins_home

Run Jenkins webapp in hardened tomcat container.

```bash
JENKINS_HOME="$(cd ../jenkins_home; pwd)"
docker run -v "${JENKINS_HOME}:/jenkins \
  -e JENKINS_HOME=/jenkins --rm -p 8080:8080 sample
```

Visit http://localhost:8080/ to see your example app running.  Use `CTRL+C` to
exit.

[tomcat-security]: https://tomcat.apache.org/tomcat-9.0-doc/security-manager-howto.html
