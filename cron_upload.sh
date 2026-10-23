#!/bin/sh

cd "$(dirname "$0")" || exit 1

# Load credentials from .env file (git ignored)
if [ ! -f .env ]; then
    echo "Error: .env file not found in $(pwd)" >&2
    exit 1
fi
# shellcheck disable=SC1091
. ./.env

: "${HOST:?Error: HOST not set in .env}"
: "${USER:?Error: USER not set in .env}"
: "${PASSWD:?Error: PASSWD not set in .env}"

# Upload the status page via FTPS (FTP with explicit TLS, port 21).
# Credentials and file content are encrypted in transit.
FILE='index.html'
curl -sS --fail --ssl-reqd -m 60 --user "$USER:$PASSWD" -T "$FILE" "ftp://$HOST/"
