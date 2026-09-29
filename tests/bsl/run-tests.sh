#!/usr/bin/env bash
#
# Build the BSL test extension from tests/bsl and run it with YAxUnit against a
# disposable infobase.
#
# Usage:
#   tests/bsl/run-tests.sh                                  # canonical extension, shared + canonical suites
#   tests/bsl/run-tests.sh --mode standalone                # standalone variant, shared + standalone suites
#   tests/bsl/run-tests.sh --rebuild-base                   # recreate the infobase first
#   tests/bsl/run-tests.sh --tests mol_ErrorsTests.MessageIsPreserved
#
# Suites are collected from tests/bsl/common/CommonModules (valid in both modes) plus
# tests/bsl/<mode>/CommonModules. The split exists because the builder merges ten
# modules into Moleculer and keeps only mol_Reuse and mol_ReuseCalls, so the callable
# surface differs between the canonical extension and the standalone variant.
#
# In canonical mode the connector extension is compiled from src on every run, so the
# suites always exercise current code. In standalone mode the artifact comes from
# tools/standalone-builder, which must be run first.
#
# Requires: java (JDK 21), vrunner, and the vendored YAxUnit and md-sparrow artifacts.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

TESTS_CFE="build/test/MoleculerTests.cfe"
EXTENSION_NAME="MoleculerTests"
WORK_DIR="build/test/bsl-src"
YAXUNIT_CFE="build/vendor/yaxunit/YAxUnit.cfe"
YAXUNIT_NAME="YAXUNIT"
# The YAxUnit release file name contains a hyphen, which vrunner rejects as an
# extension name, hence the hyphen-free copy above.
MD_SPARROW_JAR="build/vendor/md-sparrow/md-sparrow-0.6.3-all.jar"
REPORT_DIR="build/test/reports"
V8VERSION="8.3"
SCHEMA_VERSION="V2_17"

MODE="canonical"
REBUILD_BASE=0
TESTS_FILTER=""

while [ $# -gt 0 ]; do
	case "$1" in
		--mode)
			MODE="${2:?--mode needs a value}"
			shift
			;;
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

case "$MODE" in
	canonical)
		# Compiled from source on every run, so the suites always exercise current code.
		CONNECTOR_SRC="src/cfe/MoleculerSidecarConnector"
		CONNECTOR_CFE="build/test/connector-canonical.cfe"
		CONNECTOR_NAME="MoleculerSidecarConnector"
		BASE="build/ib"
		;;
	standalone)
		# Built by tools/standalone-builder, which must be run first:
		#   python3 tools/standalone-builder/build-standalone.py
		CONNECTOR_SRC=""
		CONNECTOR_CFE="build/standalone/MoleculerSidecarConnectorStandalone.cfe"
		CONNECTOR_NAME="MoleculerSidecarConnectorStandalone"
		BASE="build/ib-tests"
		;;
	*)
		echo "unknown mode: $MODE (expected canonical or standalone)" >&2
		exit 2
		;;
esac

SUITE_ROOTS=("tests/bsl/common/CommonModules" "tests/bsl/$MODE/CommonModules")
base_connection="/F$REPO_ROOT/$BASE"

for required in "$YAXUNIT_CFE" "$MD_SPARROW_JAR"; do
	if [ ! -e "$required" ]; then
		echo "missing required file: $required" >&2
		exit 1
	fi
done

if [ -n "$CONNECTOR_SRC" ]; then
	[ -d "$CONNECTOR_SRC" ] || {
		echo "missing connector sources: $CONNECTOR_SRC" >&2
		exit 1
	}
elif [ ! -e "$CONNECTOR_CFE" ]; then
	echo "missing connector artifact: $CONNECTOR_CFE (run the standalone builder first)" >&2
	exit 1
fi

for tool in java vrunner; do
	command -v "$tool" >/dev/null || {
		echo "required tool not found on PATH: $tool" >&2
		exit 1
	}
done

echo "==> mode $MODE, suites under ${SUITE_ROOTS[*]}"

echo "==> scaffolding the test extension in $WORK_DIR"
rm -rf "$WORK_DIR"
java -jar "$MD_SPARROW_JAR" init-empty-cfe "$WORK_DIR" \
	--name "$EXTENSION_NAME" --name-prefix mol_ -v "$SCHEMA_VERSION" >/dev/null

echo "==> registering test modules"
module_count=0
for suite_root in "${SUITE_ROOTS[@]}"; do
	[ -d "$suite_root" ] || continue

	for suite_path in "$suite_root"/*/; do
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
done

if [ "$module_count" -eq 0 ]; then
	echo "no test modules found under ${SUITE_ROOTS[*]}" >&2
	exit 1
fi

# Run vrunner from a neutral directory: it auto-loads autumn-properties.json from the
# working directory, which pins ibconnection to this project's development base.
neutral_dir="$(mktemp -d)"

if [ -n "$CONNECTOR_SRC" ]; then
	echo "==> compiling the connector extension from $CONNECTOR_SRC"
	(
		cd "$neutral_dir"
		vrunner cfe compile --src "$REPO_ROOT/$CONNECTOR_SRC" \
			--extension-name "$CONNECTOR_NAME" --ibcmd --v8version "$V8VERSION" \
			"$REPO_ROOT/$CONNECTOR_CFE"
	) >/dev/null
fi

echo "==> compiling $TESTS_CFE"
(
	cd "$neutral_dir"
	vrunner cfe compile --src "$REPO_ROOT/$WORK_DIR" \
		--extension-name "$EXTENSION_NAME" --ibcmd --v8version "$V8VERSION" \
		"$REPO_ROOT/$TESTS_CFE"
) >/dev/null

if [ ! -d "$BASE" ] || [ "$REBUILD_BASE" = "1" ]; then
	echo "==> creating the disposable infobase $BASE"
	rm -rf "$BASE"
	vrunner infobase init --src src/cf \
		--ext "$CONNECTOR_CFE" --ext "$YAXUNIT_CFE" \
		--ibconnection "$base_connection" --ibcmd --v8version "$V8VERSION" >/dev/null
fi

echo "==> loading extensions with safe mode off"
# Passing --active makes vrunner take the ibcmd property path, which also sets safe mode
# and unsafe-action protection to false. Without it vrunner leaves the platform defaults
# untouched and YAxUnit fails with "Расширение подключено в безопасном режиме".
for spec in "$CONNECTOR_CFE:$CONNECTOR_NAME" "$YAXUNIT_CFE:$YAXUNIT_NAME"; do
	cfe_path="${spec%%:*}"
	extension_name="${spec##*:}"
	vrunner cfe load --extension-name "$extension_name" --ibcmd --active \
		--ibconnection "$base_connection" --v8version "$V8VERSION" "$cfe_path" >/dev/null
done

# The test extension is created or updated through cfe load, which registers it when it
# is not present yet and refreshes its safe-mode properties when it is.
vrunner cfe load --extension-name "$EXTENSION_NAME" --ibcmd --active \
	--ibconnection "$base_connection" --v8version "$V8VERSION" "$TESTS_CFE" >/dev/null

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

# YAxUnit leaves a suite that fails to compile out of its counters, so the summary can read
# "success 41, failed 0, errors 0" while a whole module never ran. The only trace is the
# log, so the run is only accepted when no module failed to load.
if grep -qE "Ошибка инициализации модуля|ОшибкаКомпиляцииВстроенногоЯзыка" "$run_log"; then
	echo "==> a suite did not load, so the counters above understate the run" >&2
	grep -E "Ошибка инициализации модуля|ОшибкаКомпиляцииВстроенногоЯзыка" "$run_log" >&2 || true
	status=1
fi

grep -E "YAxUnit: |^  \[" "$run_log" || true

exit_code="$(cat "$exitcode_path" 2>/dev/null || echo '?')"
echo "==> exit code $exit_code, report $REPORT_DIR/yaxunit.xml, log $REPORT_DIR/run.log"

exit "$status"
