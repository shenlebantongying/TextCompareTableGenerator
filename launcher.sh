#!/bin/sh
# Hack
MYSELF=$(which "$0" 2>/dev/null)
exec java -jar $MYSELF "$@"
exit $?