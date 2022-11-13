FROM tomcat

# Install jar command if missing
USER root
RUN set -ex; \
  if ! type -f jar; then apk add --no-cache openjdk11-jdk; fi

# Extract provided war file
USER tomcat
WORKDIR /webapps
ADD *.war ./
RUN set -ex; \
  cd /webapps/ROOT; \
  jar xf ../*.war

# Build final image with war file statically deployed
FROM tomcat
COPY --from=0 /webapps/ROOT /webapps/ROOT
