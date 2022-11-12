FROM alpine

RUN set -ex; \
apk add --no-cache java-cacerts ca-certificates ttf-dejavu fontconfig openjdk11-jdk dumb-init; \
adduser -u 100 -G nogroup -h /home/tomcat -S tomcat; \
mkdir /tomcat; \
cd /tomcat; \
mkdir -p bin conf

# Install tomcat 9
# https://tomcat.apache.org/download-90.cgi
# - Copy minimally necessary config to catalina base
# - Harden tomcat
# - Slim down tomcat
RUN set -ex; \
cd /opt; \
tomcat_major=9; \
version=9.0.68; \
hash=840b21c5cd2bfea7bbfed99741c166608fa1515bb00475ebd4eccfd4f3ed2a1be6bfffd590b2a6600003205b62f271b6ba0937e557fc65a536df61cb4f7b7c8f; \
wget -q https://dlcdn.apache.org/tomcat/tomcat-"$tomcat_major"/v"$version"/bin/apache-tomcat-"$version".tar.gz; \
echo "$hash  apache-tomcat-$version.tar.gz" | sha512sum -c -;\
tar -xzf apache-tomcat-"$version".tar.gz; \
rm apache-tomcat-"$version".tar.gz; \
ln -s apache-tomcat-"$version" tomcat; \
mkdir -p /tomcat/conf; \
cp /opt/tomcat/conf/web.xml /opt/tomcat/conf/catalina.* /tomcat/conf/; \
mkdir -p /tomcat/lib/org/apache/catalina/util; \
echo -e 'server.info=\nserver.number=\nserver.built=' > /tomcat/lib/org/apache/catalina/util/ServerInfo.properties; \
cd tomcat; \
rm -r webapps logs work temp conf *.txt *.md; \
cd ..; \
chmod 750 apache-tomcat-"$version"; \
chown -R tomcat: apache-tomcat-"$version"

# set up catalina base based on RUNNING.txt
ADD tomcat-base /tomcat/
RUN set -ex; \
cp /opt/tomcat/bin/tomcat-juli.jar /tomcat/bin/; \
mkdir /webapps /tomcat/work; \
chmod 750 /tomcat /webapps; \
chown -R tomcat: /tomcat /webapps

USER tomcat
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk
ENV PATH="${JAVA_HOME}"/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV CATALINA_BASE=/tomcat CATALINA_HOME=/opt/tomcat
ENV JAVA_OPTS=-Djava.awt.headless=true
EXPOSE 8080
CMD ["/opt/tomcat/bin/catalina.sh", "run"]
