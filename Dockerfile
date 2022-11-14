FROM alpine
ARG java=jre tls=false extras=false all=false

# Install packages
RUN set -ex; \
  if ! [ "${java}" = jdk -o "${java}" = jre ]; then \
    echo 'ERROR: docker-build arg java must be jre or jdk.' >&2; \
    exit 1; \
  fi; \
  apk add --no-cache openjdk11-"${java}" dumb-init; \
  [ "${tls}" = false -a "${all}" = false ] || apk add --no-cache java-cacerts ca-certificates; \
  [ "${extras}" = false -a "${all}" = false ] || apk add --no-cache ttf-dejavu fontconfig; \
  adduser -u 100 -G nogroup -h /home/tomcat -S tomcat; \
  mkdir /tomcat; \
  cd /tomcat; \
  mkdir -p bin conf; \
  rm -rf /var/cache/apk

# Install Tomcat 9
# https://tomcat.apache.org/download-90.cgi
#   - Copy minimally necessary config to catalina base
#   - Harden tomcat
#   - Slim down tomcat
ARG tomcat_major=9 \
  tomcat_version=9.0.68 \
  tomcat_hash=840b21c5cd2bfea7bbfed99741c166608fa1515bb00475ebd4eccfd4f3ed2a1be6bfffd590b2a6600003205b62f271b6ba0937e557fc65a536df61cb4f7b7c8f
RUN set -ex; \
  cd /opt; \
  wget -q https://dlcdn.apache.org/tomcat/tomcat-"$tomcat_major"/v"$tomcat_version"/bin/apache-tomcat-"$tomcat_version".tar.gz; \
  echo "$tomcat_hash  apache-tomcat-$tomcat_version.tar.gz" | sha512sum -c -;\
  tar -xzf apache-tomcat-"$tomcat_version".tar.gz; \
  rm apache-tomcat-"$tomcat_version".tar.gz; \
  ln -s apache-tomcat-"$tomcat_version" tomcat; \
  mkdir -p /tomcat/conf; \
  mkdir -p /tomcat/lib/org/apache/catalina/util; \
  echo -e 'server.info=\nserver.number=\nserver.built=' > /tomcat/lib/org/apache/catalina/util/ServerInfo.properties; \
  cd tomcat; \
  rm -r webapps logs work temp conf *.txt *.md; \
  cd ..; \
  chown -R tomcat: apache-tomcat-"$tomcat_version"

# set up catalina base based on RUNNING.txt
ADD tomcat-base /tomcat/
RUN set -ex; \
  cd /tomcat; \
  cp /opt/tomcat/bin/tomcat-juli.jar /tomcat/bin/; \
  mkdir -p /data /webapps/ROOT work temp; \
  chown -R tomcat: /data /tomcat /webapps

# Harden permissions
RUN set -ex; \
  chmod 700 /data /home/tomcat /opt/apache-tomcat-"$tomcat_version" /tomcat /webapps;

# Application startup environment
USER tomcat
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
WORKDIR /home/tomcat
ENV HOME=/home/tomcat USER=tomcat
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk
ENV PATH="${JAVA_HOME}"/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV CATALINA_BASE=/tomcat CATALINA_HOME=/opt/tomcat
ENV JAVA_OPTS=-Djava.awt.headless=true
EXPOSE 8080
CMD ["/opt/tomcat/bin/catalina.sh", "run", "-security"]
