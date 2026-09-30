#!/usr/bin/env bash
#
# One entry point over every check this repository has.
#
# Usage:
#   tools/check.sh                          # every layer
#   tools/check.sh --layers static,builder  # a subset
#   tools/check.sh --skip bsl-standalone    # everything but one layer
#   tools/check.sh --force                  # ignore the BSL harness reuse cache
#   tools/check.sh --rebuild-base           # recreate the BSL test infobase first
#   tools/check.sh --tests <filter>         # one YAxUnit test, for a quick loop
#   tools/check.sh --list                   # print the layer names and exit
#
# Layers, in the order they run:
#
#   static          BSL Language Server diagnostics, then the procedure-as-function scan
#   builder         the standalone builder's own container-only tests
#   bsl-canonical   the YAxUnit suites against the canonical extension
#   bsl-standalone  the YAxUnit suites against the generated standalone variant
#   syntax-check    the platform's syntax check over the loaded extension
#
# The order matters twice over: the syntax check inspects an infobase, so it runs after
# the canonical BSL layer has left the extension loaded there, and the static layer runs
# first because it is the cheapest way to learn that the tree does not compile.
#
# Exit code is 0 only when every selected layer passed. A layer that reports itself
# skipped — the language server with no java on the machine, for instance — is reported
# and does not fail the run, because that is a property of the machine, not of the code.
#
# Not a layer here: there is no first-party OneScript suite tree. The container-only
# suites that exist are Python, and they are the builder layer.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

ALL_LAYERS=(static builder bsl-canonical bsl-standalone syntax-check)
REPORT_DIR="$ROOT/build/test/reports"

SELECTED=("${ALL_LAYERS[@]}")
SKIPPED=()
HARNESS_FLAGS=()

print_usage() {
        sed -n '3,30p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'
}

while [[ $# -gt 0 ]]; do
        case "$1" in
        --layers)
                IFS=',' read -r -a SELECTED <<<"${2:-}"
                shift 2
                ;;
        --skip)
                IFS=',' read -r -a SKIPPED <<<"${2:-}"
                shift 2
                ;;
        --force)
                HARNESS_FLAGS+=(--force)
                shift
                ;;
        --rebuild-base)
                HARNESS_FLAGS+=(--rebuild-base)
                shift
                ;;
        --tests)
                HARNESS_FLAGS+=(--tests "${2:-}")
                shift 2
                ;;
        --list)
                echo "layers: ${ALL_LAYERS[*]}"
                exit 0
                ;;
        -h | --help)
                print_usage
                exit 0
                ;;
        *)
                echo "unknown argument: $1" >&2
                print_usage >&2
                exit 2
                ;;
        esac
done

layer_is_selected() {
        local wanted="$1"
        local name

        for name in "${SKIPPED[@]}"; do
                [[ "$name" == "$wanted" ]] && return 1
        done

        for name in "${SELECTED[@]}"; do
                [[ "$name" == "$wanted" ]] && return 0
        done

        return 1
}

# The language server gate already fails on its own findings. The textual scan does not:
# it prints candidates and always exits 0, because it is meant for manual review, so the
# count is what decides here. A procedure used as a function is never valid BSL, so any
# candidate is a failure.
run_static_checks() {
        local output
        local candidates

        "$ROOT/tools/bsl-checks/bsl-language-server.py" || return 1

        output="$("$ROOT/tools/bsl-checks/find-procedure-as-function.py" "$ROOT/src")"
        printf '%s\n' "$output"

        candidates="$(printf '%s\n' "$output" | sed -n 's/^# candidates: //p')"
        if [[ "${candidates:-0}" -gt 0 ]]; then
                echo "FAIL: ${candidates} call site(s) use a procedure as a function"
                return 1
        fi
}

mkdir -p "$REPORT_DIR/check"

declare -a RESULT_NAME=()
declare -a RESULT_STATUS=()

run_layer() {
        local name="$1"
        local description="$2"
        shift 2

        local log="$REPORT_DIR/check/${name}.log"
        local status

        echo
        echo "=== ${name}: ${description}"
        echo "    log: ${log#${ROOT}/}"

        "$@" >"$log" 2>&1
        status=$?

        if [[ $status -eq 0 ]]; then
                if grep -qiE '^(skipped|skip):' "$log"; then
                        RESULT_STATUS+=("skipped")
                        echo "    skipped"
                else
                        RESULT_STATUS+=("passed")
                        echo "    passed"
                fi
        else
                RESULT_STATUS+=("FAILED (exit ${status})")
                echo "    FAILED (exit ${status})"
                tail -20 "$log" | sed 's/^/    | /'
        fi

        RESULT_NAME+=("$name")
}

if layer_is_selected static; then
        run_layer static "static analysis" run_static_checks
fi

if layer_is_selected builder; then
        run_layer builder "standalone builder tests" \
                python3 -m unittest discover -s tests/standalone-builder -t tests/standalone-builder
fi

if layer_is_selected bsl-canonical; then
        run_layer bsl-canonical "YAxUnit suites against the canonical extension" \
                tests/bsl/run-tests.sh --mode canonical "${HARNESS_FLAGS[@]}"
fi

if layer_is_selected bsl-standalone; then
        run_layer bsl-standalone "YAxUnit suites against the standalone variant" \
                tests/bsl/run-tests.sh --mode standalone "${HARNESS_FLAGS[@]}"
fi

if layer_is_selected syntax-check; then
        run_layer syntax-check "platform syntax check over the loaded extension" \
                vrunner validate syntax-check \
                --ibconnection "/F${ROOT}/build/ib" \
                --v8version 8.3 \
                --mode ExtendedModulesCheck \
                --junitpath "$REPORT_DIR/syntax-check.xml" \
                --exception-file "$ROOT/tools/syntax-check-excludes.txt"
fi

echo
echo "=== summary"
failed=0
for index in "${!RESULT_NAME[@]}"; do
        printf '    %-16s %s\n' "${RESULT_NAME[$index]}" "${RESULT_STATUS[$index]}"
        case "${RESULT_STATUS[$index]}" in
        FAILED*) failed=1 ;;
        esac
done

echo
if [[ $failed -ne 0 ]]; then
        echo "FAIL: at least one layer did not pass"
        exit 1
fi

echo "PASS: every selected layer passed or was skipped with a reason"
