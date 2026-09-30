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
# Run this worktree's dev container from the macOS host.
#
# Orca has no dev-container support of its own: it runs setup hooks and default
# terminal tabs from `orca.yaml` on the host. This script is what those hooks
# call, and the same verbs are what a person or an agent uses to reach the 1C and
# OneScript toolchain, which exists only inside the container.
#
# Usage:
#   container.sh up              build and start the container (idempotent)
#   container.sh shell           interactive shell inside it, at /workspace
#   container.sh run <command>   run one command inside it
#   container.sh down            stop and remove this worktree's container
#   container.sh status          report whether it is running
#
# The container is per worktree. Docker Compose would name the project after the
# folder holding the compose file, which is `.devcontainer` for every checkout, so
# the project name is set explicitly to `<worktree>_devcontainer` — the same name
# the Dev Containers CLI uses, so VS Code and Orca share one container per
# worktree instead of creating two.
#
set -euo pipefail

COMPOSE_FILE=".devcontainer/docker-compose.yml"
SERVICE="dev"

workspace() {
    git rev-parse --show-toplevel
}

sanitize() {
    tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_-'
}

compose() {
    local ws="$1"
    shift

    docker compose \
        --project-name "$(basename "$ws" | sanitize)_devcontainer" \
        --file "$ws/$COMPOSE_FILE" \
        "$@"
}

command_up() {
    local ws="$1"

    # The GitHub CLI inside the container reads GH_TOKEN. Resolve it from the host
    # `gh` login when the caller has not exported one, so an Orca worktree gets
    # authenticated issues and pull requests without a token in any file.
    if [ -z "${GH_TOKEN:-}" ] && command -v gh >/dev/null 2>&1; then
        GH_TOKEN="$(gh auth token 2>/dev/null || true)"
    fi
    export GH_TOKEN

    compose "$ws" up --detach --build

    # What devcontainer.json's postCreateCommand does on the VS Code path. It is
    # repeated here because a bare Compose start applies neither `features` nor
    # `postCreateCommand`: uv and Serena come from a dev-container feature and stay
    # absent, which is why that step is tolerant.
    compose "$ws" exec --no-TTY "$SERVICE" bash -lc '
        if command -v uv >/dev/null 2>&1 && ! command -v serena >/dev/null 2>&1; then
            uv tool install -p 3.13 serena-agent
        fi
        oscript --version
        opm --version
        gh --version | head -1
    '

    echo "Container for $ws is up. 1C commands: tools/orca/container.sh run <command>"
}

command_shell() {
    local ws="$1"

    compose "$ws" exec "$SERVICE" bash -l
}

command_run() {
    local ws="$1"
    shift

    if [ "$#" -eq 0 ]; then
        echo "container.sh run needs a command, for example: container.sh run oscript -version" >&2
        exit 2
    fi

    local quoted=""
    local word
    for word in "$@"; do
        quoted+="$(printf '%q ' "$word")"
    done

    compose "$ws" exec --no-TTY "$SERVICE" bash -lc "$quoted"
}

command_down() {
    local ws="$1"

    compose "$ws" down --remove-orphans
}

command_status() {
    local ws="$1"

    compose "$ws" ps
}

usage() {
    sed -n '20,32p' "$0" | sed 's/^# \{0,1\}//'
}

main() {
    local verb="${1:-}"

    if [ -z "$verb" ]; then
        usage
        exit 2
    fi

    shift

    local ws
    ws="$(workspace)"

    case "$verb" in
        up)
            command_up "$ws"
            ;;
        shell)
            command_shell "$ws"
            ;;
        run)
            command_run "$ws" "$@"
            ;;
        down)
            command_down "$ws"
            ;;
        status)
            command_status "$ws"
            ;;
        *)
            echo "Unknown verb '$verb'. Use up, shell, run, down or status." >&2
            exit 2
            ;;
    esac
}

main "$@"
