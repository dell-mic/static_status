#!/usr/bin/env bash

# status.sh retry test script

set -euo pipefail

BASE_PATH=$(cd "$(dirname "$0")" && pwd)
TEST_HOME=$(mktemp -d)

cleanup() {
	rm -rf "$TEST_HOME"
}
trap cleanup EXIT

for cmd in ping ping6 nc curl grep sed traceroute timeout; do
	if ! command -v "$cmd" >/dev/null 2>&1; then
		echo "SKIP: command '$cmd' not found"
		exit 0
	fi
done

mkdir "$TEST_HOME/status"

cat > "$TEST_HOME/status/flaky.sh" << 'EOF'
#!/usr/bin/env bash
counter_file="$HOME/status/flaky_count"
attempt="0"
if [ -f "$counter_file" ]; then
	attempt=$(cat "$counter_file")
fi
attempt="$((attempt + 1))"
echo "$attempt" > "$counter_file"
if [ "$attempt" -lt "3" ]; then
	exit 1
fi
exit 0
EOF

cat > "$TEST_HOME/status/always-down.sh" << 'EOF'
#!/usr/bin/env bash
counter_file="$HOME/status/always_down_count"
attempt="0"
if [ -f "$counter_file" ]; then
	attempt=$(cat "$counter_file")
fi
attempt="$((attempt + 1))"
echo "$attempt" > "$counter_file"
exit 1
EOF

chmod +x "$TEST_HOME/status/flaky.sh" "$TEST_HOME/status/always-down.sh"

cat > "$TEST_HOME/status/status_hostname_list.txt" << 'EOF'
script;flaky.sh|Flaky
script;always-down.sh|Always down
EOF

(
	cd "$BASE_PATH"
	HOME="$TEST_HOME" MY_RETRY_STRATEGY="linear" MY_RETRY_INTERVAL="0" MY_RETRY_TOTAL="2" bash status.sh silent
)

if ! grep -q 'script;flaky.sh|Flaky;' "$TEST_HOME/status/status_hostname_ok.txt"; then
	echo "FAIL: flaky script should be marked up after retries"
	exit 1
fi

if grep -q 'script;flaky.sh|Flaky;' "$TEST_HOME/status/status_hostname_down.txt"; then
	echo "FAIL: flaky script should not be marked down after retry success"
	exit 1
fi

if ! grep -q 'script;always-down.sh|Always down;' "$TEST_HOME/status/status_hostname_down.txt"; then
	echo "FAIL: always-down script should be marked down after retries"
	exit 1
fi

if [ "$(cat "$TEST_HOME/status/flaky_count")" != "3" ]; then
	echo "FAIL: flaky script should run initial attempt plus two retries"
	exit 1
fi

if [ "$(cat "$TEST_HOME/status/always_down_count")" != "3" ]; then
	echo "FAIL: always-down script should run initial attempt plus two retries"
	exit 1
fi

if (
	cd "$BASE_PATH"
	HOME="$TEST_HOME" MY_RETRY_STRATEGY="invalid" bash status.sh silent
) >/dev/null 2>&1; then
	echo "FAIL: invalid retry strategy should fail"
	exit 1
fi

echo "Retry tests passed"
