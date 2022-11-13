# These vars should not be modified
if [ -e "/proc/self/fd/1" ]; then
  CATALINA_OUT="/proc/self/fd/1"
else
  CATALINA_OUT="/dev/stdout"
fi
CATALINA_OUT_CMD=
CATALINA_PID=

# Set random shutdown command on boot
random_password="`tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32`"
sed -i "s/SHUTDOWN/$random_password/" /tomcat/conf/server.xml
