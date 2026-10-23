#!/bin/sh
cd "$(dirname "$0")";

set -e # fail on error

# Only proceed if internet is reachable
wget -q --spider http://google.com

./status.sh silent

# Settings for the upload: HOST, USER and PASSWD.
# They are read from the .env file (git ignored) if present.
# HOST and PASSWD can also be passed as environment variables to this
# script; passed variables take precedence over the .env file.
# Note: USER is also the system login name, so it is always taken from
# the .env file only.
MY_ENV_HOST=${HOST:-}
MY_ENV_PASSWD=${PASSWD:-}
unset USER
if [ -f .env ]; then
    # shellcheck disable=SC1091
    . ./.env
fi
if [ -n "$MY_ENV_HOST" ]; then
    HOST=$MY_ENV_HOST
fi
if [ -n "$MY_ENV_PASSWD" ]; then
    PASSWD=$MY_ENV_PASSWD
fi

# Upload the status page only if all FTP settings are present.
# Skipped silently if not all are present.
if [ -n "$HOST" ] && [ -n "$USER" ] && [ -n "$PASSWD" ]; then
    export HOST USER PASSWD
    ./cron_upload.sh
fi

# Ping monitoring (dead man's switch, e.g. healthchecks.io)
# Set HEALTHCHECK_UUID in the .env file to enable.
# Skipped silently if not set.
if [ -n "$HEALTHCHECK_UUID" ]; then
    curl -s -m 10 --retry 5 "https://hc-ping.com/$HEALTHCHECK_UUID" > /dev/null || true
fi
