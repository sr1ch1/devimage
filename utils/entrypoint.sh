#!/usr/bin/env bash
set -euo pipefail

# start cron
rm -f /var/run/crond.pid /var/run/cron.pid || true
cron -f &
CRON_PID=$!

cleanup() {
  kill "$CRON_PID" 2>/dev/null || true
  wait "$CRON_PID" 2>/dev/null || true
}
trap cleanup SIGTERM SIGINT

# call provisionibng script
PROV_CMD="${1:-/usr/local/bin/provision.sh}"

echo "Starting provision as ${GITHUB_USER} via gosu" >&2
exec gosu "$GITHUB_USER" bash -i -c "$PROV_CMD"
