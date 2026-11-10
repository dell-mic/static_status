#!/bin/sh
cd "$(dirname "$0")" || exit 0

# Static status update: regenerate the page, upload it, ping the dead-man switch.
# Convention (user preference): silent on success, log ONLY on failure. The
# monitoring ping always fires — plain ping on success, /fail when any step
# failed — so a broken step can never swallow the dead-man signal again
# (the old set -e chain died before the ping and logged to /dev/null).
# A run must never exit non-zero: cron output would mail-spam.

LOG_DIR=/home/pi/media/cron-logs
LOG="$LOG_DIR/static_status-$(date +%F).log"
FAILED_STEPS=""
FAIL_OUT=""
STEP_TIMEOUT=120

run_step() {
    name="$1"; shift
    out=$(timeout "$STEP_TIMEOUT" "$@" 2>&1)
    rc=$?
    if [ "$rc" -ne 0 ]; then
        if [ "$rc" -eq 124 ]; then
            FAILED_STEPS="$FAILED_STEPS $name(timeout ${STEP_TIMEOUT}s)"
        else
            FAILED_STEPS="$FAILED_STEPS $name(exit $rc)"
        fi
        FAIL_OUT="$FAIL_OUT
--- $name (exit $rc) ---
$(echo "$out" | tail -12)"
    fi
    return 0
}

# Only proceed if internet is reachable (bounded: the old unbounded wget
# could hang and stack up the per-minute cron runs).
run_step "internet-check" wget -q -T 8 -t 2 --spider http://google.com

run_step "status.sh" ./status.sh silent

# Settings for the upload: HOST, USER and PASSWD.
# They are read from the .env file (git ignored) if present.
# HOST and PASSWD can also be passed as environment variables to this
# script; passed variables take precedence over the .env file.
# Note: USER is also the system login name, so it is always taken from
# the .env file only. HEALTHCHECK_UUID follows the same override rule
# (an empty passed value disables the ping, used for tests).
MY_ENV_HOST=${HOST:-}
MY_ENV_PASSWD=${PASSWD:-}
if [ "${HEALTHCHECK_UUID+set}" = "set" ]; then
    MY_ENV_HC_SET=1
    MY_ENV_HC=$HEALTHCHECK_UUID
else
    MY_ENV_HC_SET=0
fi
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
if [ "$MY_ENV_HC_SET" = "1" ]; then
    HEALTHCHECK_UUID=$MY_ENV_HC
fi

# Upload the status page only if all FTP settings are present.
# Skipped silently if not all are present.
if [ -n "$HOST" ] && [ -n "$USER" ] && [ -n "$PASSWD" ]; then
    export HOST USER PASSWD
    run_step "upload" ./cron_upload.sh
fi

# Dead-man ping (e.g. healthchecks.io). ALWAYS fires: /fail marks the check
# down when a step failed, so monitoring sees the difference between
# "cron did not run" and "a step is broken".
if [ -n "$HEALTHCHECK_UUID" ]; then
    if [ -n "$FAILED_STEPS" ]; then
        curl -s -m 10 --retry 5 "https://hc-ping.com/$HEALTHCHECK_UUID/fail" > /dev/null 2>&1 || true
    else
        curl -s -m 10 --retry 5 "https://hc-ping.com/$HEALTHCHECK_UUID" > /dev/null 2>&1 || true
    fi
fi

# Log on failure only (success runs stay silent and leave no trace).
if [ -n "$FAILED_STEPS" ]; then
    mkdir -p "$LOG_DIR" 2>/dev/null
    {
        echo "=== $(date '+%F %T') FAIL:$FAILED_STEPS"
        echo "$FAIL_OUT"
    } >> "$LOG" 2>/dev/null
fi

exit 0
