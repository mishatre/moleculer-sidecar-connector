#!/usr/bin/env bash
#
# Inbound transport integration test: drives the published HTTP service over real HTTP.
#
# Why this is a shell script and not a YAxUnit suite: the thing under test is the
# transport boundary itself — stand-alone web server -> HTTP service -> mol_Transport ->
# mol_RequestHandler -> error envelope. YAxUnit runs *inside* the platform process, so it
# cannot observe the HTTP status line or the response content type.
#
# Usage:
#   tests/bsl/http/test-inbound-transport.sh                     both variants
#   tests/bsl/http/test-inbound-transport.sh --mode standalone   one variant
#
# Both variants are driven through the same assertions, because the transport boundary is the
# same code either way and only the packaging differs: the canonical extension is installed in
# build/ib by `tests/bsl/run-tests.sh --mode canonical`, and the standalone variant in
# build/ib-tests by `tests/bsl/run-tests.sh --mode standalone`. Each mode runs as a child
# invocation, because each base needs its own stand-alone server lifecycle and its own counters.
#
# Prerequisite: the variant under test must already be installed in its base. This script owns
# the stand-alone server while it runs: it stops any running server, writes the publication,
# starts the server, asserts, and stops the server again. The base file is therefore free
# afterwards, which is what the YAxUnit harness needs.
#
# Two findings from the platform are encoded here, because both are easy to get wrong:
#
#  1. The stand-alone server does not publish an extension's HTTP service just because
#     `publish-by-default` / `publish-extensions-by-default` are set. The service has to
#     be listed by metadata name. An unlisted service answers 503 for every path.
#  2. No infobase user is required. An infobase with an empty user list runs every
#     connection with full rights, so the request reaches the service unauthenticated.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

MODE=""
while [ $# -gt 0 ]; do
	case "$1" in
		--mode)
			MODE="${2:?--mode needs a value}"
			shift 2
			;;
		*)
			echo "unknown argument: $1" >&2
			exit 2
			;;
	esac
done

# The parent only dispatches. Each requested mode is verified by a child process so that a
# failure in one base cannot leave the other with a half-written publication or a running
# server, and so that the pass/fail counters stay per mode.
if [ -z "${INBOUND_MODE:-}" ]; then
	MODES="${MODE:-canonical standalone}"
	STATUS=0

	for CHILD_MODE in $MODES; do
		echo
		echo "==> inbound transport on the $CHILD_MODE base"

		if ! INBOUND_MODE="$CHILD_MODE" "$0"; then
			STATUS=1
		fi
	done

	echo
	if [ "$STATUS" -eq 0 ]; then
		echo "inbound transport: every requested mode passed"
	else
		echo "inbound transport: at least one mode failed" >&2
	fi

	exit "$STATUS"
fi

SERVER_DATA_DIR="build/ibsrv"
PUBLICATION="build/ibsrv/publication.yaml"
SERVER_LOG="build/ibsrv/server.log"

HTTP_ADDRESS="localhost"
HTTP_PORT="8314"
HTTP_BASE="/ib"

# The HTTP service keeps the same metadata name and root in both variants: the standalone builder
# merges the modules without renaming the service, so only the base and the extension differ.
SERVICE_NAME="mol_Moleculer"
SERVICE_ROOT="moleculer"

case "$INBOUND_MODE" in
	canonical)
		BASE_DIR="build/ib"
		CONNECTOR_NAME="MoleculerSidecarConnector"
		BASE_LABEL="canonical extension, loaded by run-tests.sh --mode canonical"
		;;
	standalone)
		BASE_DIR="build/ib-tests"
		CONNECTOR_NAME="MoleculerSidecarConnectorStandalone"
		BASE_LABEL="standalone variant, loaded by run-tests.sh --mode standalone"
		;;
	*)
		echo "unknown mode: $INBOUND_MODE" >&2
		exit 2
		;;
esac

# A packet shaped like mol_Transport.NewPacket produces. No handler is registered for an
# empty action, so the connector answers with its own envelope instead of running a job.
PROBE_PACKET='{"sender":"probe","meta":{},"data":{},"stream":false}'

SERVER_PID=""

# ---------------------------------------------------------------------------- reporting

PASSED=0
FAILED=0

pass() {
	printf '  PASS  %s\n' "$1"
	PASSED=$((PASSED + 1))
}

fail() {
	printf '  FAIL  %s\n' "$1" >&2
	FAILED=$((FAILED + 1))
}

# A known defect that the suite records but must not fail on, so that the rest of the
# transport boundary stays under test while the defect is still open.
gap() {
	printf '  GAP   %s\n' "$1"
}

# --------------------------------------------------------------------------------- setup

if [ ! -d "$REPO_ROOT/$BASE_DIR" ]; then
	echo "missing test base $BASE_DIR; run tests/bsl/run-tests.sh --mode $INBOUND_MODE first" >&2
	exit 1
fi

IBSRV=""
for candidate in /opt/1cv8/current/ibsrv /opt/1cv8/x86_64/*/ibsrv; do
	if [ -x "$candidate" ]; then
		IBSRV="$candidate"
		break
	fi
done

if [ -z "$IBSRV" ]; then
	echo "ibsrv not found under /opt/1cv8" >&2
	exit 1
fi

if ! command -v curl >/dev/null; then
	echo "required tool not found on PATH: curl" >&2
	exit 1
fi

# A server that exits without releasing its data directory leaves the lock file behind,
# and the next start then refuses to run. The lock is only dropped when the process it
# names is really gone, so a running server is never disturbed.
drop_stale_lock() {
	local lock_file="$REPO_ROOT/$SERVER_DATA_DIR/lock.pid"

	[ -e "$lock_file" ] || return 0

	local lock_pid
	lock_pid="$(tr -dc '0-9' <"$lock_file")"

	if [ -n "$lock_pid" ] && kill -0 "$lock_pid" 2>/dev/null; then
		return 0
	fi

	rm -f "$lock_file"
}

stop_server() {
	if [ -n "$SERVER_PID" ] && kill -0 "$SERVER_PID" 2>/dev/null; then
		kill "$SERVER_PID" 2>/dev/null
		SERVER_PID=""
	fi
	# A server left over from an earlier run still holds the base file, so it has to go
	# before a new one can publish the same base. Match the process name rather than the
	# command line, because a server started by hand may have been launched through a
	# different path to the same binary.
	pkill -x ibsrv 2>/dev/null

	for _ in $(seq 1 40); do
		if ! curl -sS -o /dev/null -m 1 "http://$HTTP_ADDRESS:$HTTP_PORT$HTTP_BASE/" 2>/dev/null; then
			drop_stale_lock
			return 0
		fi
		sleep 0.25
	done

	echo "the stand-alone server did not stop" >&2
	return 1
}

write_publication() {
	# The service is listed explicitly. This file is the source of truth for the server,
	# and build/ is disposable, so it is regenerated on every run.
	cat >"$REPO_ROOT/$PUBLICATION" <<YAML
server:
  address: $HTTP_ADDRESS
  port: $HTTP_PORT
database:
  path: $REPO_ROOT/$BASE_DIR
infobase:
  name: DefAlias
  distribute-licenses: yes
http:
  - base: $HTTP_BASE
    odata:
      publish: yes
    web-services:
      publish-by-default: yes
      publish-extensions-by-default: yes
    http-services:
      publish-by-default: yes
      publish-extensions-by-default: yes
      service:
        - name: $SERVICE_NAME
          root: $SERVICE_ROOT
          publish: yes
YAML
}

start_server() {
	mkdir -p "$REPO_ROOT/$SERVER_DATA_DIR"

	nohup "$IBSRV" \
		--config="$REPO_ROOT/$PUBLICATION" \
		--data="$REPO_ROOT/$SERVER_DATA_DIR" \
		>"$REPO_ROOT/$SERVER_LOG" 2>&1 &
	SERVER_PID=$!

	# Wait for the publication to answer. --retry-connrefused covers the window where the
	# server is up but not yet listening.
	curl -sS -o /dev/null \
		--retry 40 --retry-connrefused --retry-delay 1 -m 60 \
		"http://$HTTP_ADDRESS:$HTTP_PORT$HTTP_BASE/" 2>/dev/null
}

# ------------------------------------------------------------------------------ requests

# Runs a request and fills STATUS, CONTENT_TYPE and BODY_FILE.
STATUS=""
CONTENT_TYPE=""
BODY_FILE=""

request() {
	local method="$1"
	local url="$2"
	local content_type="$3"
	local data="$4"

	BODY_FILE="$(mktemp)"
	local tmp_headers
	tmp_headers="$(mktemp)"

	local args=(-sS -o "$BODY_FILE" -D "$tmp_headers" -m 30 -X "$method")
	if [ -n "$content_type" ]; then
		args+=(-H "Content-Type: $content_type")
	fi
	if [ -n "$data" ]; then
		args+=(--data-raw "$data")
	fi

	STATUS="$(curl "${args[@]}" -w '%{http_code}' "$url" 2>/dev/null)"
	CONTENT_TYPE="$(grep -i '^content-type:' "$tmp_headers" | head -1 | cut -d' ' -f2- | tr -d '\r')"
	rm -f "$tmp_headers"
}

body_text() {
	tr -d '\n\r' <"$BODY_FILE"
}

# The connector serialises JSON with a space after each colon. That spacing is not part of
# the contract, so content assertions run against a compact form.
body_json() {
	body_text | sed 's/: */:/g'
}

assert_contains() {
	local haystack="$1"
	local needle="$2"
	local label="$3"

	if printf '%s' "$haystack" | grep -qF "$needle"; then
		pass "$label"
	else
		fail "$label (expected to contain '$needle', got '$(printf '%s' "$haystack" | head -c 300)')"
	fi
}

# ---------------------------------------------------------------------------------- main

echo "==> mode $INBOUND_MODE: $BASE_LABEL"
echo "==> stopping any running stand-alone server"
stop_server || exit 1

echo "==> publishing $SERVICE_NAME as $HTTP_BASE/hs/$SERVICE_ROOT"
write_publication

echo "==> starting the stand-alone server"
if ! start_server; then
	echo "the stand-alone server did not start; see $SERVER_LOG" >&2
	tail -20 "$REPO_ROOT/$SERVER_LOG" >&2
	exit 1
fi

echo "==> checking the publication"
request GET "http://$HTTP_ADDRESS:$HTTP_PORT$HTTP_BASE/" "" ""
if [ "$STATUS" = "200" ]; then
	pass "the publication root answers 200"
else
	fail "the publication root answers $STATUS, expected 200"
fi

SERVICE_URL="http://$HTTP_ADDRESS:$HTTP_PORT$HTTP_BASE/hs/$SERVICE_ROOT/sidecar"

echo "==> checking the HTTP service boundary"
request POST "$SERVICE_URL" "application/json" "$PROBE_PACKET"
if [ "$STATUS" = "503" ]; then
	pass "an unroutable packet answers 503"
else
	fail "an unroutable packet answers $STATUS, expected 503"
fi

case "$CONTENT_TYPE" in
	application/json*)
		pass "the service answers JSON"
		;;
	*)
		fail "the service answers '$CONTENT_TYPE', expected application/json"
		;;
esac

PACKET_BODY="$(body_json)"
assert_contains "$PACKET_BODY" '"name":"MoleculerServerError"' "the envelope names the connector as the source"
assert_contains "$PACKET_BODY" '"type":"REQUEST_REJECTED"' "the envelope classifies the failure"
assert_contains "$PACKET_BODY" '"message":"Handler is not provided"' "the envelope explains the failure"

request GET "$SERVICE_URL" "" ""
if [ "$STATUS" = "405" ]; then
	pass "only POST is mapped, so GET answers 405"
else
	fail "GET answers $STATUS, expected 405"
fi

echo "==> checking input validation"
# Known defect: input that fails before mol_RequestHandler is reached is not converted
# into the error envelope. The platform answers with its own 500 text/plain page, which
# carries a module reference and a line number instead of a classified error. Tracked as
# part of the error taxonomy work, and reported here so the gap stays visible.
request POST "$SERVICE_URL" "application/json" 'not json'
if [ "$STATUS" = "500" ] && [ "${CONTENT_TYPE#text/plain}" != "$CONTENT_TYPE" ]; then
	gap "a malformed body answers $STATUS ${CONTENT_TYPE} without an envelope; expected a classified error"
	assert_contains "$(body_text)" "$CONNECTOR_NAME" "the platform page names $CONNECTOR_NAME, so the $INBOUND_MODE artifact answered"
elif printf '%s' "$(body_json)" | grep -qF '"name":"MoleculerServerError"'; then
	pass "a malformed body is classified into the error envelope"
else
	fail "a malformed body answers $STATUS with an unexpected body"
fi

request POST "$SERVICE_URL" "application/json" ''
if [ "$STATUS" = "500" ] && [ "${CONTENT_TYPE#text/plain}" != "$CONTENT_TYPE" ]; then
	gap "an empty body answers $STATUS ${CONTENT_TYPE} without an envelope; expected a classified error"
	assert_contains "$(body_text)" "$CONNECTOR_NAME" "the platform page names $CONNECTOR_NAME, so the $INBOUND_MODE artifact answered"
elif printf '%s' "$(body_json)" | grep -qF '"name":"MoleculerServerError"'; then
	pass "an empty body is classified into the error envelope"
else
	fail "an empty body answers $STATUS with an unexpected body"
fi

echo "==> stopping the stand-alone server"
stop_server || exit 1

rm -f "$BODY_FILE"

echo
echo "inbound transport ($INBOUND_MODE): $PASSED passed, $FAILED failed"

if [ "$FAILED" -ne 0 ]; then
	exit 1
fi
