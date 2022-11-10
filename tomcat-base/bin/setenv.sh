# These vars should not be modified
if [ -e "/proc/self/fd/1" ]; then
  CATALINA_OUT="/proc/self/fd/1"
else
  CATALINA_OUT="/dev/stdout"
fi
CATALINA_OUT_CMD=
CATALINA_TMPDIR=/tmp
CATALINA_PID=
