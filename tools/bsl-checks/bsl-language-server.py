#!/usr/bin/env python3

################################################################################
# Copyright (c) 2026, M.Tregub
# SPDX-License-Identifier: MIT
# All rights reserved. This program and its accompanying materials are provided
# under the terms of the MIT License.
# The license text is available at:
# https://opensource.org/licenses/MIT
################################################################################

"""Static diagnostics gate over the connector sources.

The rule set is selected, not defaulted: `.bsl-language-server.json` enables the
twelve correctness rules listed in its `diagnostics.parameters` and leaves out the
style and documentation families, because the connector has 780 findings under the
default set and only 63 under this one. See `tools/bsl-checks/README.md` for why
each family is in or out.

This script turns that selection into a gate. It runs the language server over the
sources and compares the result with the recorded baseline in
`bsl-ls-baseline.json`:

  * a rule above its baseline count fails the run;
  * a rule below it is reported, so the baseline can be tightened;
  * a rule in the baseline that no longer appears is reported, so it can be removed.

The language server is not vendored. Its jar ships inside the
`1c-syntax.language-1c-bsl` VS Code extension, so it is discovered there; set
`BSL_LS_JAR` to use another copy. When java or the jar is missing the run prints a
skip notice and exits 0, the same way the live sidecar suite does, so the gate does
not fail for a reason that has nothing to do with the code.

Usage:
    tools/bsl-checks/bsl-language-server.py
    tools/bsl-checks/bsl-language-server.py --source src/cfe/MoleculerSidecarConnector
    tools/bsl-checks/bsl-language-server.py --print-baseline   # counts as JSON
"""

from __future__ import annotations

import argparse
import collections
import glob
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

DEFAULT_CONFIG = ROOT / ".bsl-language-server.json"
DEFAULT_BASELINE = Path(__file__).resolve().parent / "bsl-ls-baseline.json"
DEFAULT_REPORT_DIR = ROOT / "build" / "test" / "reports" / "bsl-ls"
DEFAULT_SOURCES = ["src/cfe/MoleculerSidecarConnector"]

JAR_PATTERNS = [
    "data/User/globalStorage/*language-1c-bsl*/bsl-language-server/*/bsl-language-server/lib/app/*-exec.jar",
    "extensions/*language-1c-bsl*/bsl-language-server/*/bsl-language-server/lib/app/*-exec.jar",
]


def find_jar() -> Path | None:
    override = os.environ.get("BSL_LS_JAR")
    if override:
        path = Path(override)
        return path if path.is_file() else None

    home = Path.home()
    for pattern in JAR_PATTERNS:
        matches = sorted(glob.glob(str(home / ".vscode-server" / pattern)))
        if matches:
            return Path(matches[-1])

    return None


def diagnostic_code(diagnostic: dict) -> str:
    code = diagnostic.get("code")
    if isinstance(code, dict):
        return code.get("left") or code.get("right") or "Unknown"
    return code or "Unknown"


def collect_counts(report_path: Path) -> collections.Counter:
    report = json.loads(report_path.read_text(encoding="utf-8"))
    files = report.get("fileinfos") or report.get("files") or []

    counts: collections.Counter = collections.Counter()
    for file_info in files:
        for diagnostic in file_info.get("diagnostics", []):
            counts[diagnostic_code(diagnostic)] += 1

    return counts


def load_baseline(path: Path) -> dict:
    data = json.loads(path.read_text(encoding="utf-8"))
    return {key: value for key, value in data.items() if not key.startswith("_")}


def run_analysis(java: str, jar: Path, config: Path, sources: list[str], report_dir: Path) -> Path:
    report_dir.mkdir(parents=True, exist_ok=True)

    for stale in report_dir.glob("*.json"):
        stale.unlink()

    failure = None
    for source in sources:
        source_path = ROOT / source
        if not source_path.is_dir():
            print(f"skip: {source} is not a directory", file=sys.stderr)
            continue

        command = [
            java,
            "-jar",
            str(jar),
            "analyze",
            "-c",
            str(config),
            "-s",
            str(source_path),
            "-o",
            str(report_dir),
            "-r",
            "json",
            "-q",
        ]

        result = subprocess.run(command, capture_output=True, text=True)
        output = (result.stdout + result.stderr).splitlines()
        noisy = ("token recognition error", " INFO ", " WARN ")
        for line in output:
            if line.strip() and not any(marker in line for marker in noisy):
                print(f"  {line}")

        if result.returncode != 0:
            failure = f"the language server exited {result.returncode} on {source}"
            break

    reports = sorted(report_dir.glob("*.json"))
    if failure:
        raise SystemExit(f"FAIL: {failure}")
    if not reports:
        raise SystemExit("FAIL: the language server wrote no JSON report")

    return reports[-1]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--source", action="append", dest="sources")
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    parser.add_argument("--baseline", type=Path, default=DEFAULT_BASELINE)
    parser.add_argument("--report-dir", type=Path, default=DEFAULT_REPORT_DIR)
    parser.add_argument("--print-baseline", action="store_true", help="print the observed counts as JSON and exit")
    args = parser.parse_args()

    sources = args.sources or DEFAULT_SOURCES

    java = shutil.which("java")
    if not java:
        print("skipped: no java on PATH, so the BSL Language Server cannot run")
        return 0

    jar = find_jar()
    if not jar:
        print("skipped: no bsl-language-server jar found (set BSL_LS_JAR to point at one)")
        return 0

    print(f"==> analysing {', '.join(sources)}")
    print(f"    java   {java}")
    print(f"    jar    {jar}")
    print(f"    config {args.config.relative_to(ROOT) if args.config.is_relative_to(ROOT) else args.config}")

    report = run_analysis(java, jar, args.config, sources, args.report_dir)
    observed = collect_counts(report)

    if args.print_baseline:
        print(json.dumps(dict(sorted(observed.items())), indent=4))
        return 0

    baseline = load_baseline(args.baseline)

    print(f"==> {sum(observed.values())} diagnostics in {len(baseline)} recorded rules")
    print()
    print(f"    {'rule':<32} {'now':>4} {'base':>5}  verdict")
    print(f"    {'-' * 32} {'-' * 4} {'-' * 5}  {'-' * 22}")

    regressions = []
    improvements = []
    for rule in sorted(set(observed) | set(baseline)):
        now = observed.get(rule, 0)
        base = baseline.get(rule, 0)

        if now > base:
            verdict = "REGRESSION"
            regressions.append((rule, base, now))
        elif now == base:
            verdict = "ok"
        elif now == 0:
            verdict = "gone, drop from baseline"
            improvements.append((rule, base, now))
        else:
            verdict = "improved, tighten baseline"
            improvements.append((rule, base, now))

        print(f"    {rule:<32} {now:>4} {base:>5}  {verdict}")

    print()
    if improvements:
        print(f"{len(improvements)} rule(s) came in at or below the recorded count:")
        for rule, base, now in improvements:
            print(f"  {rule}: {base} -> {now}")
        print()

    if regressions:
        print(f"FAIL: {len(regressions)} rule(s) above the baseline")
        for rule, base, now in regressions:
            print(f"  {rule}: {base} -> {now}")
        print()
        print(f"report: {report}")
        return 1

    print("PASS: no rule is above its recorded count")
    print(f"report: {report}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
