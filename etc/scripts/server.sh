#!/bin/sh
set -f

case "$1" in
  -h|--help|"")
    echo "$0 should be run by emacs plugin. M-x ensime should start the server for you"
    exit 1
  ;;
  *)
    PORT_FILE=$1
  ;;
esac

INITIAL_HEAP=256M
MAX_HEAP=1024M
CLASSPATH=<RUNTIME_CLASSPATH>
# CLASSPATH is relative to dist directory. So cd into that directory before running java:
cd "$(dirname "$(dirname "$0")")"
java -classpath $CLASSPATH -Xms${INITIAL_HEAP} -Xmx${MAX_HEAP} org.ensime.server.Server "$@"
