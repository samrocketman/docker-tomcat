FROM alpine

RUN set -ex; \
apk add --no-cache openjdk11-jdk dumb-init; \
adduser -u 100 -G nogroup -h /home/tomcat -S tomcat; \
mkdir /tomcat; \
cd /tomcat; \
mkdir -p bin conf lib temp webapps; \
cd lib; \
# harden tomcat server info properties
mkdir -p org/apache/catalina/util; \
echo -e 'server.info=Tomcat\nserver.number=\nserver.built=' > org/apache/catalina/util/ServerInfo.properties; \
jar cf catalina.jar org/apache/catalina/util/ServerInfo.properties; \
rm -r org

# Install tomcat 10
# https://tomcat.apache.org/download-10.cgi
RUN set -ex; \
cd /opt; \
version=10.1.1; \
hash=5718b877eb2d3fb05ec0c11d0af8a2bb34766e14b915ecda8d61e92670a7a911ff08c3cb03dafe8f28f10df19172ca0681ade953ccda5363fc5b57468a47476c; \
wget -q https://dlcdn.apache.org/tomcat/tomcat-10/v"$version"/bin/apache-tomcat-"$version".tar.gz; \
echo "$hash  apache-tomcat-$version.tar.gz" | sha512sum -c -;\
tar -xzf apache-tomcat-"$version".tar.gz; \
rm apache-tomcat-"$version".tar.gz; \
ln -s apache-tomcat-"$version" tomcat; \
chown -R tomcat: apache-tomcat-"$version"

# set up catalina base
ADD tomcat-base /tomcat/
RUN set -ex; \
mkdir /webapp; \
chown -R tomcat: /tomcat /webapp

USER tomcat
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
ENV CATALINA_BASE=/tomcat CATALINA_HOME=/opt/tomcat
CMD ["/opt/apache-tomcat-10.1.1/bin/catalina.sh", "run"]
