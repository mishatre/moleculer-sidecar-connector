#!/usr/bin/env bash
#
# Build the BSL test extension from tests/bsl/CommonModules and run it with YAxUnit
# against a disposable infobase.
#
# Usage:
#   tests/bsl/run-tests.sh                  # build, load, run
#   tests/bsl/run-tests.sh --rebuild-base   # recreate the infobase first
#   tests/bsl/run-tests.sh --tests mol_ReuseTests.GetRegexCacheTurnsDoubleStarIntoManySegments
#
# Requires: java (JDK 21), vrunner, and the vendored YAxUnit and md-sparrow artifacts.
# The test extension is compiled from source, so the connector extension under test is
# rebuilt by tools/standalone-builder before this script is useful.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

SUITE_ROOT="tests/bsl/CommonModules"
WORK_DIR="build/test/bsl-src"
TESTS_CFE="build/test/MoleculerTests.cfe"
EXTENSION_NAME="MoleculerTests"
BASE="build/ib-tests"
CONNECTOR_CFE="build/standalone/MoleculerSidecarConnectorStandalone.cfe"
CONNECTOR_NAME="MoleculerSidecarConnectorStandalone"
YAXUNIT_CFE="build/vendor/yaxunit/YAxUnit.cfe"
YAXUNIT_NAME="YAXUNIT"
# The YAxUnit release file name contains a hyphen, which vrunner rejects as an
# extension name, hence the hyphen-free copy above.
MD_SPARROW_JAR="build/vendor/md-sparrow/md-sparrow-0.6.3-all.jar"
REPORT_DIR="build/test/reports"
V8VERSION="8.3"
SCHEMA_VERSION="V2_17"

REBUILD_BASE=0
TESTS_FILTER=""

while [ $# -gt 0 ]; do
	case "$1" in
		--rebuild-base)
			REBUILD_BASE=1
			;;
		--tests)
			TESTS_FILTER="${2:?--tests needs a value}"
			shift
			;;
		*)
			echo "unknown option: $1" >&2
			exit 2
			;;
	esac
	shift
done

for required in "$CONNECTOR_CFE" "$YAXUNIT_CFE" "$MD_SPARROW_JAR"; do
	if [ ! -e "$required" ]; then
		echo "missing required file: $required" >&2
		exit 1
	fi
done

for tool in java vrunner; do
	command -v "$tool" >/dev/null || {
		echo "required tool not found on PATH: $tool" >&2
		exit 1
	}
done

base_connection="/F$REPO_ROOT/$BASE"

echo "==> scaffolding the test extension in $WORK_DIR"
rm -rf "$WORK_DIR"
java -jar "$MD_SPARROW_JAR" init-empty-cfe "$WORK_DIR" \
	--name "$EXTENSION_NAME" --name-prefix mol_ -v "$SCHEMA_VERSION" >/dev/null

echo "==> registering test modules"
module_count=0
for suite_path in "$SUITE_ROOT"/*/; do
	module_name="$(basename "$suite_path")"
	module_file="$suite_path/Ext/Module.bsl"

	if [ ! -e "$module_file" ]; then
		echo "    skipping $module_name (no Ext/Module.bsl)" >&2
		continue
	fi

	echo "    $module_name"
	java -jar "$MD_SPARROW_JAR" add-md-object "$WORK_DIR/Configuration.xml" "$module_name" \
		-v "$SCHEMA_VERSION" --type COMMON_MODULE >/dev/null
	mkdir -p "$WORK_DIR/CommonModules/$module_name/Ext"
	cp "$module_file" "$WORK_DIR/CommonModules/$module_name/Ext/Module.bsl"
	module_count=$((module_count + 1))
done

if [ "$module_count" -eq 0 ]; then
	echo "no test modules found under $SUITE_ROOT" >&2
	exit 1
fi

echo "==> compiling $TESTS_CFE"
# Run from a neutral directory: vrunner auto-loads autumn-properties.json, which pins
# ibconnection to this project's development base.
neutral_dir="$(mktemp -d)"
(
	cd "$neutral_dir"
	vrunner cfe compile --src "$REPO_ROOT/$WORK_DIR" \
		--extension-name "$EXTENSION_NAME" --ibcmd --v8version "$V8VERSION" \
		"$REPO_ROOT/$TESTS_CFE"
) >/dev/null

if [ ! -d "$BASE" ] || [ "$REBUILD_BASE" = "1" ]; then
	echo "==> creating the disposable infobase $BASE"
	rm -rf "$BASE"
	# --ibcmd leaves extension safe mode at the platform default, which is ON.
	# yaxunit cannot read its parameter file in safe mode, so the properties are
	# cleared explicitly below.
	vrunner infobase init --src src/cf \
		--ext "$CONNECTOR_CFE" --ext "$YAXUNIT_CFE" --ext "$TESTS_CFE" \
		--ibconnection "$base_connection" --ibcmd --v8version "$V8VERSION" >/dev/null
fi

echo "==> loading extensions with safe mode off"
# Passing --active makes vrunner take the ibcmd property path, which also sets
# safe mode and unsafe-action protection to false. Without it vrunner leaves the
# platform defaults untouched and YAxUnit fails with "Расширение подключено в
# безопасном режиме".
for spec in "$CONNECTOR_CFE:$CONNECTOR_NAME" "$YAXUNIT_CFE:$YAXUNIT_NAME" "$TESTS_CFE:$EXTENSION_NAME"; do
	cfe_path="${spec%%:*}"
	extension_name="${spec##*:}"
	vrunner cfe load --extension-name "$extension_name" --ibcmd --active \
		--ibconnection "$base_connection" --v8version "$V8VERSION" "$cfe_path" >/dev/null
done

echo "==> running tests"
mkdir -p "$REPORT_DIR"
report_path="$REPO_ROOT/$REPORT_DIR/yaxunit.xml"
exitcode_path="$REPO_ROOT/$REPORT_DIR/exitcode.txt"
run_log="$REPO_ROOT/$REPORT_DIR/run.log"
rm -f "$report_path" "$exitcode_path" "$run_log"

run_options=(test yaxunit
	--ibconnection "$base_connection"
	--v8version "$V8VERSION"
	--ext "$EXTENSION_NAME"
	--report "$report_path"
	--report-format jUnit
	--exitcode "$exitcode_path")
if [ -n "$TESTS_FILTER" ]; then
	run_options+=(--tests "$TESTS_FILTER")
fi

set +e
vrunner "${run_options[@]}" >"$run_log" 2>&1
status=$?
set -e

grep -E "YAxUnit: |^  \[" "$run_log" || true

exit_code="$(cat "$exitcode_path" 2>/dev/null || echo '?')"
echo "==> exit code $exit_code, report $REPORT_DIR/yaxunit.xml, log $REPORT_DIR/run.log"

exit "$status"
