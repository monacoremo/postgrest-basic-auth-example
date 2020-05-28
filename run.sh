#!/usr/bin/env bash

set -euo pipefail

tutorialdir="$(realpath "${TUTORIAL_DIR:-.}")"
export TUTORIAL_DIR="$tutorialdir"

rootdir="$(realpath "$(dirname "$0")")"
rundir="$rootdir"/run
export RUN_DIR="$rundir"

rm -rf "$rundir"


# DATABASE

# Setting up and running the database
dblog="$rundir/db.log"
dbsetuplog="$rundir/dbsetup.log"

dblog() {
  echo "$1" >> "$dbsetuplog"
}

mkdir -p "$rundir"/{db,dbsocket}

export PGDATA="$rundir"/db
export PGHOST="$rundir"/dbsocket
export PGUSER=postgres
export PGDATABASE=postgres
export DB_URI="postgresql://$PGDATABASE?host=$PGHOST&user=$PGUSER"

dblog "Initializing database cluster..."
# We try to make the database cluster as independent as possible from the host
# by specifying the timezone, locale and encoding.
PGTZ=UTC initdb --no-locale --encoding=UTF8 --nosync -U "$PGUSER" --auth=trust \
  >> "$dbsetuplog"

dblog "Starting the database cluster..."
# Instead of listening on a local port, we will listen on a unix domain socket.
pg_ctl -l "$dblog" start -o "-F -c listen_addresses=\"\" -k $PGHOST" \
  >> "$dbsetuplog"

dblog "Loading application from $tutorialdir..."
psql -v ON_ERROR_STOP=1 >> "$dbsetuplog" << EOF
  \i $tutorialdir/app.sql
EOF

stopDb() {
  pg_ctl stop >> "$dbsetuplog"
}

trap "stopDb; kill 0" exit

# POSTGREST API

postgrest "$tutorialdir"/postgrest.conf &

# NGINX INGRESS

mkdir -p "$rundir"/nginx/{logs,conf}
ln -s "$tutorialdir"/nginx.conf "$rundir"/nginx/conf/nginx.conf
nginx -p "$rundir"/nginx -c nginx.conf &


if [ "$#" -lt 1 ]; then
  echo "Application is running. Press Ctrl-C to exit."
  wait
else
  echo "Running command \"$*\"..."
  # We don't `exec` the command in order to keep our exit trap.
  "$@"
fi