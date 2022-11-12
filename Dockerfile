FROM alpine

RUN set -ex; \
apk add --no-cache openjdk11-jdk dumb-init; \
adduser -u 100 -G nogroup -h /home/tomcat -S tomcat; \
mkdir /tomcat; \
cd /tomcat; \
mkdir -p bin conf

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
rm -r tomcat/webapps; \
chown -R tomcat: apache-tomcat-"$version"

# harden tomcat server info properties
#RUN set -ex; \
#cp /opt/tomcat/conf/web.xml /opt/tomcat/conf/catalina.* /tomcat/conf/; \
#cd /opt/tomcat/lib; \
#mkdir -p org/apache/catalina/util; \
#echo -e 'server.info=Tomcat\nserver.number=\nserver.built=' > org/apache/catalina/util/ServerInfo.properties; \
#jar uf catalina.jar org/apache/catalina/util/ServerInfo.properties; \
#rm -r org

# set up catalina base based on RUNNING.txt
#ADD tomcat-base /tomcat/
RUN set -ex; \
cp /opt/tomcat/bin/tomcat-juli.jar /tomcat/bin/; \
mkdir /webapps /tomcat/work /tomcat/temp; \
cp -r /opt/tomcat/conf /tomcat/; \
ln -s /opt/tomcat/lib /tomcat/; \
chown -R tomcat: /tomcat /webapps

USER tomcat
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
ENV CATALINA_BASE=/tomcat CATALINA_HOME=/opt/tomcat
EXPOSE 8080
CMD ["/opt/apache-tomcat-10.1.1/bin/catalina.sh", "run"]
