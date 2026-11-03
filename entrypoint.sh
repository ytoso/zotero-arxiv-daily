#!/usr/bin/env bash
# Generate the crontab from CRON_SCHEDULE and run supercronic in the foreground.
set -euo pipefail

SCHEDULE="${CRON_SCHEDULE:-30 1 * * *}"
printf '%s /app/run.sh\n' "$SCHEDULE" > /app/crontab

echo "[entrypoint] schedule: ${SCHEDULE} (UTC)"
echo "[entrypoint] starting supercronic..."
exec supercronic /app/crontab
