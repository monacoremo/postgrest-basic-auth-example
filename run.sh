#!/usr/bin/env bash

set -euo pipefail

tutorialdir="$(realpath "${TUTORIAL_DIR:-$(pwd)}")"
rundir="$(mktemp -d)"/run

export INGRESS_PORT=8080
export API_PORT=3000
export API_URI="http://localhost:$API_PORT"
export PGDATA="$rundir"/db
export PGHOST="$rundir"/dbsocket
export PGUSER=postgres
export PGDATABASE=postgres
export DB_URI="postgresql://$PGDATABASE?host=$PGHOST&user=$PGUSER"
export SHAKEDOWN_URL="http://localhost:$INGRESS_PORT"

# Clear run dir from previous runs.
rm -rf "$rundir"

# DATABASE

dblog="$rundir/db.log"
dbsetuplog="$rundir/dbsetup.log"

dblog() {
  echo "$1" >> "$dbsetuplog"
}

mkdir -p "$rundir"/{db,dbsocket}

dblog "Initializing database cluster..."
PGTZ=UTC initdb --no-locale --encoding=UTF8 --nosync -U "$PGUSER" --auth=trust >> "$dbsetuplog"

dblog "Starting the database cluster..."
pg_ctl -l "$dblog" start -o "-F -c listen_addresses=\"\" -k $PGHOST" >> "$dbsetuplog"

dblog "Loading application from $tutorialdir..."
psql -v ON_ERROR_STOP=1 -f "$tutorialdir/app.sql" >> "$dbsetuplog"

stopDb() {
  pg_ctl stop >> "$dbsetuplog"
}

trap 'stopDb; pkill -P $$; rm -rf $rundir' exit

# POSTGREST API

postgrest "$tutorialdir"/postgrest.conf >> "$rundir/api.log" &

# NGINX INGRESS

mkdir -p "$rundir"/nginx/conf
envsubst < "$tutorialdir"/nginx.conf > "$rundir"/nginx/conf/nginx.conf
nginx -p "$rundir"/nginx 2> "$rundir"/nginx/err.log &

# MAIN

echo "Waiting for application to be ready..."
while [ "$(curl -o /dev/null -s -w "%{response_code}" "http://localhost:8080/")" != "200" ]; do
  sleep 0.1;
done

if [ "$#" -lt 1 ]; then
  echo "Application is ready. Press Ctrl-C to exit."
  wait
else
  echo "Application is ready. Running command \"$*\"..."
  # We don't `exec` the command in order to keep our exit trap.
  "$@"
fi
