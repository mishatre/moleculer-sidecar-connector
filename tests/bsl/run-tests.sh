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
#   tests/bsl/run-tests.sh --force                          # ignore the reuse cache
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
# Steps are reused when their inputs have not changed: the connector compile, the test
# extension compile, and each extension load are keyed on a content hash of what they were
# built from. Reuse also requires the artifact to still be on disk, and a load additionally
# requires that this run did not recreate the infobase. --force bypasses all of it;
# --rebuild-base on its own still reuses the compiled artifacts and only forces the loads.
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
# Vendor artifact: a Native API YAML component wrapped as an extension that carries its own
# binary template. It is loaded like any other extension, and it needs safe mode off for the
# same reason everything else does — the platform will not connect an external component while
# safe mode is on.
YAML_CFE="vendor/YamlParserNative/YamlParser.cfe"
YAML_NAME="YamlParser"
# The YAxUnit release file name contains a hyphen, which vrunner rejects as an
# extension name, hence the hyphen-free copy above.
MD_SPARROW_JAR="build/vendor/md-sparrow/md-sparrow-0.6.3-all.jar"
REPORT_DIR="build/test/reports"
V8VERSION="8.3"
SCHEMA_VERSION="V2_17"

MODE="canonical"
REBUILD_BASE=0
TESTS_FILTER=""
USE_CACHE=1

while [ $# -gt 0 ]; do
	case "$1" in
		--mode)
			MODE="${2:?--mode needs a value}"
			shift
			;;
		--rebuild-base)
			REBUILD_BASE=1
			;;
		--force)
			USE_CACHE=0
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

# Reuse cache. Every step records the inputs it was built from in a marker file, and it is
# skipped only when that marker still matches and the artifact it produced is still on disk.
# Markers are written after a step succeeds, so a failure is never cached.
CACHE_DIR="build/test/.cache"

# Content hash of a directory tree: file names and bytes, so an edit and a rename both count.
hash_tree() {
	find "$1" -type f -print0 2>/dev/null \
		| sort -z \
		| xargs -0 sha256sum 2>/dev/null \
		| sha256sum \
		| cut -d' ' -f1
}

hash_file() {
	sha256sum "$1" 2>/dev/null | cut -d' ' -f1
}

# An empty expected value never counts as a hit: it would mean the inputs could not be read.
cache_hit() {
	local marker="$CACHE_DIR/$1"

	[ -n "$2" ] && [ "$USE_CACHE" = "1" ] && [ -e "$marker" ] && [ "$(cat "$marker")" = "$2" ]
}

cache_store() {
	mkdir -p "$CACHE_DIR"
	printf '%s' "$2" >"$CACHE_DIR/$1"
}

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
# The whole scaffold-and-register sequence goes through one resident md-sparrow process, which
# loads the JVM and the JAXB contexts once. Measured on this exact sequence: 17.35 s of
# one-shot invocations become 2.81 s.
requests=("init-empty-cfe|$WORK_DIR|--name|$EXTENSION_NAME|--name-prefix|mol_|-v|$SCHEMA_VERSION")

echo "==> registering test modules"
module_names=()
module_files=()
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
		requests+=("add-md-object|$WORK_DIR/Configuration.xml|$module_name|-v|$SCHEMA_VERSION|--type|COMMON_MODULE")
			module_names+=("$module_name")
			module_files+=("$module_file")
		module_count=$((module_count + 1))
	done
done

if [ "$module_count" -eq 0 ]; then
	echo "no test modules found under ${SUITE_ROOTS[*]}" >&2
	exit 1
fi

printf '%s\n' "${requests[@]}" \
	| python3 "$REPO_ROOT/tools/md-sparrow/serve-requests.py" --jar "$MD_SPARROW_JAR"

# Module bodies are copied after the registration sequence, not during it. md-sparrow writes the
# descriptor and the compiler reads Ext/Module.bsl next to it, so the order between the two does
# not matter — but copying afterwards is what allows the whole sequence to share one process.
# Copying before it does not work: init-empty-cfe recreates the scaffold and takes the copies
# with it.
for index in "${!module_names[@]}"; do
	mkdir -p "$WORK_DIR/CommonModules/${module_names[$index]}/Ext"
	cp "${module_files[$index]}" "$WORK_DIR/CommonModules/${module_names[$index]}/Ext/Module.bsl"
done

# Run vrunner from a neutral directory: it auto-loads autumn-properties.json from the
# working directory, which pins ibconnection to this project's development base.
neutral_dir="$(mktemp -d)"

if [ -n "$CONNECTOR_SRC" ]; then
	connector_inputs="$(hash_tree "$REPO_ROOT/$CONNECTOR_SRC")|$V8VERSION"

	if cache_hit "connector-build" "$connector_inputs" && [ -e "$CONNECTOR_CFE" ]; then
		echo "==> reusing $CONNECTOR_CFE (connector sources unchanged)"
	else
		echo "==> compiling the connector extension from $CONNECTOR_SRC"
		(
			cd "$neutral_dir"
			vrunner cfe compile --src "$REPO_ROOT/$CONNECTOR_SRC" \
				--extension-name "$CONNECTOR_NAME" --ibcmd --v8version "$V8VERSION" \
				"$REPO_ROOT/$CONNECTOR_CFE"
		) >/dev/null
		cache_store "connector-build" "$connector_inputs"
	fi
fi

# The mode belongs in the key because both modes write the same artifact path from different
# suite sets, so the file on disk means different things depending on the mode.
tests_inputs="$(hash_tree "$REPO_ROOT/tests/bsl")|$(hash_file "$MD_SPARROW_JAR")|$MODE|$SCHEMA_VERSION|$EXTENSION_NAME|$V8VERSION"

if cache_hit "tests-build" "$tests_inputs" && [ -e "$TESTS_CFE" ]; then
	echo "==> reusing $TESTS_CFE (suites unchanged)"
else
	echo "==> compiling $TESTS_CFE"
	(
		cd "$neutral_dir"
		vrunner cfe compile --src "$REPO_ROOT/$WORK_DIR" \
			--extension-name "$EXTENSION_NAME" --ibcmd --v8version "$V8VERSION" \
			"$REPO_ROOT/$TESTS_CFE"
	) >/dev/null
	cache_store "tests-build" "$tests_inputs"
fi

# A base created by this run holds the extensions with the platform's default properties, so
# safe mode is still on in it: the loads below have to run whatever the cache says.
base_recreated=0

if [ ! -d "$BASE" ] || [ "$REBUILD_BASE" = "1" ]; then
	echo "==> creating the disposable infobase $BASE"
	rm -rf "$BASE"
	vrunner infobase init --src src/cf \
		--ext "$CONNECTOR_CFE" --ext "$YAXUNIT_CFE" \
		--ibconnection "$base_connection" --ibcmd --v8version "$V8VERSION" >/dev/null
	base_recreated=1
fi

echo "==> loading extensions with safe mode off"
# Passing --active makes vrunner take the ibcmd property path, which also sets safe mode
# and unsafe-action protection to false. Without it vrunner leaves the platform defaults
# untouched and YAxUnit fails with "Расширение подключено в безопасном режиме".
#
# Cost of this loop, measured 2026-09-29: ~14.3 s per extension, of which ~4.7 s is vrunner's own
# OneScript start-up and ~5.5 s is the DB configuration update that cfe load performs by default.
# vrunner has an incremental cache for this (--increment, setting increment.cache-dir, default
# /tmp/vanessa-runner/cache) and it does its job — with no changes it logs "Инкрементальная
# загрузка: изменений не найдено, загрузка пропущена" — but it still runs that DB update, so a
# load only comes down to ~11.6 s. Adding --no-update-db reaches ~6.1 s and is deliberately NOT
# used: the tool warns that extension properties are then not applied, so the suites could run
# against the previously loaded extension. Skipping a load entirely when the artifact and the base
# are unchanged is harness work; the built-in cache is file-level and does not do it.
extensions=("$CONNECTOR_CFE:$CONNECTOR_NAME" "$YAXUNIT_CFE:$YAXUNIT_NAME")
# The vendored YAML component is only exercised by the canonical suites, so standalone mode
# does not pay for loading it.
if [ "$MODE" = "canonical" ]; then
	if [ ! -e "$YAML_CFE" ]; then
		echo "missing vendored component: $YAML_CFE" >&2
		exit 1
	fi
	extensions+=("$YAML_CFE:$YAML_NAME")
fi
# The test extension goes through the same call as the rest: cfe load registers it when it is not
# present yet and refreshes its safe-mode properties when it is, which is all any of these need.
extensions+=("$TESTS_CFE:$EXTENSION_NAME")

for spec in "${extensions[@]}"; do
	cfe_path="${spec%%:*}"
	extension_name="${spec##*:}"
	artifact_hash="$(hash_file "$cfe_path")"

	if [ "$base_recreated" = "0" ] && cache_hit "loaded-$extension_name" "$artifact_hash"; then
		echo "    reusing $extension_name (this artifact is already loaded)"
		continue
	fi

	vrunner cfe load --extension-name "$extension_name" --ibcmd --active \
		--ibconnection "$base_connection" --v8version "$V8VERSION" "$cfe_path" >/dev/null
	cache_store "loaded-$extension_name" "$artifact_hash"
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

# YAxUnit leaves a suite that fails to compile out of its counters, so the summary can read
# "success 41, failed 0, errors 0" while a whole module never ran. The only trace is the
# log, so the run is only accepted when no module failed to load.
if grep -qE "Ошибка инициализации модуля|ОшибкаКомпиляцииВстроенногоЯзыка" "$run_log"; then
	echo "==> a suite did not load, so the counters above understate the run" >&2
	grep -E "Ошибка инициализации модуля|ОшибкаКомпиляцииВстроенногоЯзыка" "$run_log" >&2 || true
	status=1
fi

# A run that found nothing at all also exits 0: YAxUnit printed "всего 0" and the script
# reported success while no test executed. Success has to mean that something ran.
total="$(sed -nE 's/.*YAxUnit: всего ([0-9]+),.*/\1/p' "$run_log" | head -1)"
if [ -z "$total" ] || [ "$total" -eq 0 ]; then
	echo "==> the run executed no tests, so a green summary means nothing here" >&2
	status=1
fi

grep -E "YAxUnit: |^  \[" "$run_log" || true

exit_code="$(cat "$exitcode_path" 2>/dev/null || echo '?')"
echo "==> exit code $exit_code, report $REPORT_DIR/yaxunit.xml, log $REPORT_DIR/run.log"

exit "$status"
