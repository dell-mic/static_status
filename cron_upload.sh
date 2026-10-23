#!/bin/sh

cd "$(dirname "$0")" || exit 1

# Load credentials from .env file (git ignored)
if [ ! -f .env ]; then
    echo "Error: .env file not found in $(pwd)" >&2
    exit 1
fi
# HOST and PASSWD can also be passed as environment variables (e.g. by
# cron_update.sh); they take precedence over the .env file.
MY_ENV_HOST=${HOST:-}
MY_ENV_PASSWD=${PASSWD:-}
# USER is also the system login name; drop it before loading .env so
# only the FTP username from .env is used.
unset USER
# shellcheck disable=SC1091
. ./.env
if [ -n "$MY_ENV_HOST" ]; then
    HOST=$MY_ENV_HOST
fi
if [ -n "$MY_ENV_PASSWD" ]; then
    PASSWD=$MY_ENV_PASSWD
fi

: "${HOST:?Error: HOST not set in .env}"
: "${USER:?Error: USER not set in .env}"
: "${PASSWD:?Error: PASSWD not set in .env}"

# Upload the status page via FTPS (FTP with explicit TLS, port 21).
# Credentials and file content are encrypted in transit.
FILE='generated/index.html'
curl -sS --fail --ssl-reqd -m 60 --user "$USER:$PASSWD" -T "$FILE" "ftp://$HOST/"
