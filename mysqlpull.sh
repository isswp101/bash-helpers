#!/bin/bash

LOCAL_MYSQL_HOST="localhost"
LOCAL_MYSQL_USER="root"
LOCAL_MYSQL_PWD=""
LOCAL_MYSQL_DB=""

REMOTE_MYSQL_HOST="localhost"
REMOTE_MYSQL_USER="root"
REMOTE_MYSQL_PWD=""
REMOTE_MYSQL_DB=""

SSH_HOST=""
SSH_USER=""
SSH_PASSWORD=""

VERBOSE=0
SSH_VERBOSE=""
MYSQL_VERBOSE=""

CMD=""

# Process Arguments
while [ "$1" != "" ]; do
  PARAM=`echo $1 | awk -F= '{print $1}'`
  VALUE=`echo $1 | awk -F= '{print $2}'`
  case $PARAM in
    # --help) help; safeExit ;;
    -h|--local-mysql-host) LOCAL_MYSQL_HOST=$VALUE ;;
    -u|--local-mysql-user) LOCAL_MYSQL_USER=$VALUE ;;
    -p|--local-mysql-password) LOCAL_MYSQL_PWD=$VALUE ;;
    -d|--local-mysql-database) LOCAL_MYSQL_DB=$VALUE ;;
    --remote-mysql-host) REMOTE_MYSQL_HOST=$VALUE ;;
    --remote-mysql-user) REMOTE_MYSQL_USER=$VALUE ;;
    --remote-mysql-password) REMOTE_MYSQL_PWD=$VALUE ;;
    --remote-mysql-database) REMOTE_MYSQL_DB=$VALUE ;;
    --ssh-host) SSH_HOST=$VALUE ;;
    # --ssh-user) SSH_USER=$VALUE ;;
    # --ssh-port) SSH_PORT=$VALUE ;;
    # --ssh-key) SSH_KEY=$VALUE ;;
    # -c|--compress) COMPRESS=1 ;;
    # -o|--output) OUTPUT=$VALUE ;;
    # -e|--env) ENV=$VALUE ;;
    # -f|--file-name) FILENAME=$VALUE ;;
    # --prefix) PREFIX=$VALUE ;;
    # --suffix) SUFFIX=$VALUE ;;
    -v|--verbose) VERBOSE=1 ;;
    -vv) VERBOSE=2 ;;
    *) echo "ERROR: unknown parameter \"$PARAM\""; help; exit 1 ;;
  esac
  shift
done

prepare() {
    if [ ! -z $LOCAL_MYSQL_PWD ]; then
        LOCAL_MYSQL_PWD="-p'$LOCAL_MYSQL_PWD'"
    fi

    if [ ! -z $REMOTE_MYSQL_PWD ]; then
        REMOTE_MYSQL_PWD="-p'$REMOTE_MYSQL_PWD'"
    fi

    if [ -z $REMOTE_MYSQL_DB ]; then
        REMOTE_MYSQL_DB=$LOCAL_MYSQL_DB
    fi

    if [ $VERBOSE -gt 1 ]; then
        SSH_VERBOSE="-v"
    fi

    if [ $VERBOSE -gt 0 ]; then
        MYSQL_VERBOSE="-v"
    fi
}

validate() {
    if [ -z $SSH_HOST ]; then
        echo -n "SSH Host: "
        read SSH_HOST
    fi

    if [ -z $LOCAL_MYSQL_DB ]; then
        echo -n "MySQL Database Name: "
        read LOCAL_MYSQL_DB
    fi
}

run() {
    FILENAME="db.sql"
    LOCAL_MYSQL_CONNECT="mysql $MYSQL_VERBOSE -h $LOCAL_MYSQL_HOST -u $LOCAL_MYSQL_USER $LOCAL_MYSQL_PWD"
    REMOTE_MYSQL_DUMP="mysqldump $MYSQL_VERBOSE -h $REMOTE_MYSQL_HOST -u $REMOTE_MYSQL_USER $REMOTE_MYSQL_PWD $REMOTE_MYSQL_DB"

    CMD="ssh $SSH_HOST $SSH_VERBOSE '$REMOTE_MYSQL_DUMP | gzip -c' | gunzip > $FILENAME"
    CMD="$CMD && $LOCAL_MYSQL_CONNECT -e 'DROP DATABASE IF EXISTS $LOCAL_MYSQL_DB; CREATE DATABASE $LOCAL_MYSQL_DB;'"
    CMD="$CMD && $LOCAL_MYSQL_CONNECT $LOCAL_MYSQL_DB < $FILENAME"
    eval $CMD

    CMD="rm $FILENAME"
    eval $CMD
}

validate
prepare
run