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
# Open one of the disposable infobases in the 1C client or designer.
#
# The 1C platform has no command-line licence activation, so the first run has to
# be interactive: start the client, follow the licence prompt, and let the platform
# store the licence under ~/.1cv8/1C/.  After that, headless `1cv8`-based commands
# (`vrunner validate syntax-check`, `vrunner test ...`) work.
#
# Usage:
#   open-infobase.sh [client|designer|launcher] [ib|standalone|<path>]
#
# Defaults to `client ib`, which opens the extension-mode base.
#
set -euo pipefail

PLATFORM_DIR="${PLATFORM_DIR:-/opt/1cv8/current}"

MODE="${1:-client}"
TARGET="${2:-ib}"

case "$TARGET" in
    ib | extension)
        INFOBASE=/workspace/build/ib
        ;;
    standalone | ib-standalone)
        INFOBASE=/workspace/build/ib-standalone
        ;;
    /*)
        INFOBASE="$TARGET"
        ;;
    *)
        echo "Unknown infobase '$TARGET'. Use ib, standalone or an absolute path." >&2
        exit 2
        ;;
esac

if [ ! -d "$INFOBASE" ]; then
    echo "Infobase directory not found: $INFOBASE" >&2
    exit 1
fi

echo "Infobase: $INFOBASE"
echo "If the platform asks for a licence, activate it from the dialog; it is stored under ~/.1cv8/1C/."

# Every mode here opens a window. Without a usable display the platform answers
# "Unable to initialize GTK+ or connect to the windowing system", which reads as a
# broken platform rather than a missing X server, so say which one it is.
require_display() {
    if [ -z "${DISPLAY:-}" ]; then
        cat >&2 <<'MSG'
DISPLAY is not set and every mode of this script opens a window.
Start the container through tools/orca/container.sh up (or reopen the folder in
the dev container); it sets DISPLAY=host.docker.internal:0 for the macOS host.
MSG
        exit 1
    fi

    if ! command -v xdpyinfo >/dev/null 2>&1; then
        echo "xdpyinfo is unavailable, so the display is not checked." >&2
        return 0
    fi

    if ! xdpyinfo -display "$DISPLAY" >/dev/null 2>&1; then
        cat >&2 <<MSG
Cannot open the display at $DISPLAY. XQuartz must be running on the macOS host
with "Allow connections from network clients", and it must authorize this
container. On the host, once per X server start:

    xhost +127.0.0.1

See "Display" in docs/plan/environment.md.
MSG
        exit 1
    fi

    echo "Display: $DISPLAY"
}

require_display

case "$MODE" in
    client)
        exec "$PLATFORM_DIR/1cv8c" "/F$INFOBASE"
        ;;
    designer)
        exec "$PLATFORM_DIR/1cv8" DESIGNER "/F$INFOBASE"
        ;;
    launcher)
        exec "$PLATFORM_DIR/1cv8"
        ;;
    *)
        echo "Unknown mode '$MODE'. Use client, designer or launcher." >&2
        exit 2
        ;;
esac
