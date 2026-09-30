#!/usr/bin/env bash

################################################################################
# Copyright (c) 2026, M.Tregub
# SPDX-License-Identifier: MIT
# All rights reserved. This program and its accompanying materials are provided
# under the terms of the MIT License.
# The license text is available at:
# https://opensource.org/licenses/MIT
################################################################################

#
# Run the BSL test suites against one of the disposable infobases.
#
# The suites themselves execute inside 1C, so this is the entry point for the
# behavioural tests (T017 onward).  It is deliberately honest about the one thing it
# cannot do: without a 1C licence the client cannot start, and the script says so
# instead of failing obscurely.
#
# Usage:
#   run-bsl-tests.sh [ib|standalone] [yaxunit|xunit] [extra vrunner options...]
#
# Environment:
#   PLATFORM_DIR   platform directory (default /opt/1cv8/current)
#   V8VERSION      platform version passed to vrunner (default 8.3)
#
set -euo pipefail

PLATFORM_DIR="${PLATFORM_DIR:-/opt/1cv8/current}"
V8VERSION="${V8VERSION:-8.3}"

TARGET="${1:-ib}"
FRAMEWORK="${2:-yaxunit}"
shift 2 2>/dev/null || true

case "$TARGET" in
    ib | extension) INFOBASE=/workspace/build/ib ;;
    standalone) INFOBASE=/workspace/build/ib-standalone ;;
    /*) INFOBASE="$TARGET" ;;
    *)
        echo "Unknown infobase '$TARGET'. Use ib, standalone or an absolute path." >&2
        exit 2
        ;;
esac

if [ ! -d "$INFOBASE" ]; then
    echo "Infobase not found: $INFOBASE" >&2
    echo "Create it with: vrunner infobase init --src src/cf [--ext <cfe>] --ibconnection /F$INFOBASE --ibcmd" >&2
    exit 1
fi

# The client needs a licence; the platform reports this instead of starting.  Probe it
# once so the failure is explained rather than buried in a test run.
probe_licence() {
    local out
    out="$(mktemp)"
    timeout 120 "$PLATFORM_DIR/1cv8" DESIGNER "/F$INFOBASE" /CheckModules \
        /Out"$out" /DisableStartupDialogs /DisableStartupMessages < /dev/null > /dev/null 2>&1 || true

    if grep -qi "лиценз\|licen" "$out" 2>/dev/null; then
        rm -f "$out"
        return 1
    fi

    rm -f "$out"
    return 0
}

if ! probe_licence; then
    cat >&2 <<'MESSAGE'
The 1C client cannot start because no licence was found:

    Не найдена лицензия. Не обнаружен ключ защиты программы или полученная программная лицензия!

The platform has no command-line licence activation. Activate it once from the
launcher or the client (tools/1c-platform/open-infobase.sh), or place a 1Cv8Licence
file in ~/.1cv8/1C/ or /var/1C/licenses/.

Everything that executes BSL is blocked until then. Static verification is not:
see tools/standalone-builder/README.md and docs/plan/notes/toolkit-research.md for the BSL
Language Server route, which needs no licence.
MESSAGE
    exit 3
fi

case "$FRAMEWORK" in
    yaxunit)
        # YAxUnit must be loaded into the base as an extension; the runner only
        # provides the CLI and the report.
        if [ ! -e "${YAXUNIT_EXTENSION:-/nonexistent}" ]; then
            echo "Note: set YAXUNIT_EXTENSION to a YAxUnit .cfe and load it into the base" >&2
            echo "      with: vrunner cfe load --ibconnection /F$INFOBASE --ibcmd <yaxunit.cfe>" >&2
        fi
        exec vrunner test yaxunit --ibconnection "/F$INFOBASE" --v8version "$V8VERSION" "$@"
        ;;
    xunit)
        exec vrunner test xunit --ibconnection "/F$INFOBASE" --v8version "$V8VERSION" "$@"
        ;;
    vanessa)
        exec vrunner test vanessa --ibconnection "/F$INFOBASE" --v8version "$V8VERSION" "$@"
        ;;
    *)
        echo "Unknown framework '$FRAMEWORK'. Use yaxunit, xunit or vanessa." >&2
        exit 2
        ;;
esac
