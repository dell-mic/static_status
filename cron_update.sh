#!/bin/sh
cd "$(dirname "$0")";

set -e # fail on error

# Only proceed if internet is reachable
wget -q --spider http://google.com

./status.sh silent

./cron_upload.sh

# Ping monitoring (dead man's switch, e.g. healthchecks.io)
# Set HEALTHCHECK_UUID in the .env file to enable.
# Skipped silently if not set.
if [ -f .env ]; then
    # shellcheck disable=SC1091
    . ./.env
fi
if [ -n "$HEALTHCHECK_UUID" ]; then
    curl -s -m 10 --retry 5 "https://hc-ping.com/$HEALTHCHECK_UUID" > /dev/null || true
fi
