#!/usr/bin/env python3
################################################################################
# Copyright (c) 2026, M.Tregub
# SPDX-License-Identifier: MIT
# All rights reserved. This program and its accompanying materials are provided
# under the terms of the MIT License.
# The license text is available at:
# https://opensource.org/licenses/MIT
################################################################################

"""Checks the copyright/license header on every first-party source file.

The header rule is defined in `docs/code-standards/module-structure.md` section 4.1:
every first-party source file opens with an 80-column box that names the copyright
holder, an `SPDX-License-Identifier`, the license and a link to its text; the file may
then add one compressed description line.

This check looks only at the top of each file, so a block copied into the middle does
not pass, requires the box as the first line after any shebang, and requires the
`Copyright (c)`, `SPDX-License-Identifier:`, `All rights reserved` and license-URL
lines. It reports every offending path and exits non-zero when one is found.

Usage:
    tools/bsl-checks/check-headers.py
    tools/bsl-checks/check-headers.py --root /workspace
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

# Files that take a comment header, by language family.
COMMENT_PREFIX = {
    ".bsl": "//",
    ".sh": "#",
    ".py": "#",
    ".os": "#",
}

# A comment header is not valid in these, or the platform stores the copyright in a
# metadata property instead: 1C configuration XML uses <Copyright>, JSON has no comments.
# `moleculer-sidecar-next/` is a separate Node subproject and is deliberately out of
# scope, so its `.ts` files are not scanned.
SCAN_DIRS = ["src", "tests", "tools"]

# Directories that hold third-party code and keep their own headers.
EXCLUDED_PARTS = {"node_modules", "oscript_modules", "vendor", "build", ".git"}

NEEDED = ("Copyright (c)", "SPDX-License-Identifier:", "All rights reserved", "opensource.org/licenses/MIT")

# The box that opens and closes the block is the comment prefix repeated to width 80.
BOX_WIDTH = 80


def candidate_files(root: Path):
    for scan_dir in SCAN_DIRS:
        base = root / scan_dir
        if not base.is_dir():
            continue
        for path in sorted(base.rglob("*")):
            if not path.is_file():
                continue
            if EXCLUDED_PARTS.intersection(path.parts):
                continue
            if path.suffix in COMMENT_PREFIX:
                yield path


def head_lines(path: Path, limit: int = 16) -> list[str]:
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return []
    return text.splitlines()[:limit]


def check_file(path: Path) -> str | None:
    """Return a message when the header is missing or malformed, otherwise None."""
    lines = head_lines(path)
    if not lines:
        return "empty or unreadable"

    # A shebang stays on line 1; the block follows it, optionally after one blank line.
    body = lines[1:] if lines[0].startswith("#!") else lines
    while body and body[0].strip() == "":
        body = body[1:]

    prefix = COMMENT_PREFIX[path.suffix]
    box = prefix[0] * BOX_WIDTH
    if not body or body[0] != box:
        return f"first line is not the {BOX_WIDTH}-column '{prefix[0]}' box"

    for needed in NEEDED:
        if not any(needed in line for line in body):
            return f"missing {needed!r} near the top"

    return None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=None, help="repository root (default: discovered)")
    args = parser.parse_args()

    root = Path(args.root).resolve() if args.root else Path(__file__).resolve().parents[2]

    offending: list[tuple[Path, str]] = []
    checked = 0
    for path in candidate_files(root):
        checked += 1
        problem = check_file(path)
        if problem:
            offending.append((path, problem))

    print(f"checked {checked} file(s) for the copyright/license header")

    if offending:
        for path, problem in offending:
            print(f"  MISSING: {path.relative_to(root)} — {problem}")
        print(f"FAIL: {len(offending)} file(s) without the header")
        return 1

    print("PASS: every first-party source file carries the header")
    return 0


if __name__ == "__main__":
    sys.exit(main())
