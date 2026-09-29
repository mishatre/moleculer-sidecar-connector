#!/usr/bin/env python3
"""Run md-sparrow commands through one resident process.

`md-sparrow serve` keeps the JVM and the JAXB contexts alive between commands, so a
sequence of metadata operations pays for one start-up instead of one per command.
Measured on the test harness scaffold sequence: 17.35 s of one-shot invocations became
2.81 s, and the resident process was ready in 0.82 s — less than a single one-shot call.

Reads one command per line on stdin, with arguments separated by `|`:

    init-empty-cfe|build/test/bsl-src|--name|MoleculerTests|-v|V2_17
    add-md-object|build/test/bsl-src/Configuration.xml|mol_ReuseTests|-v|V2_17|--type|COMMON_MODULE

Pipe is used rather than JSON because the caller is a shell script, and the arguments
contain paths and Cyrillic text that must not go through a second round of quoting.

Exits non-zero if any command failed, printing that command's stderr. Falls back to
one-shot invocations when the jar has no `serve` command, so a harness pointed at an
older md-sparrow still runs — just slower.
"""

import argparse
import json
import subprocess
import sys


def parse_requests(lines):
    """Turn `|`-separated command lines into argument lists."""

    requests = []

    for number, line in enumerate(lines, start=1):
        line = line.strip()
        if not line:
            continue

        args = line.split("|")
        if not args[0]:
            raise SystemExit(f"line {number}: no command name")

        requests.append(args)

    return requests


def run_resident(jar, requests):
    """Run every request through one serve process. Returns None if serve is unavailable."""

    process = subprocess.Popen(
        ["java", "-jar", jar, "serve"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        bufsize=1,
    )

    ready = process.stdout.readline()
    try:
        greeting = json.loads(ready)
    except json.JSONDecodeError:
        process.kill()
        return None

    if not greeting.get("ready"):
        process.kill()
        return None

    results = []

    for request_id, args in enumerate(requests, start=1):
        process.stdin.write(json.dumps({"id": request_id, "args": args}) + "\n")
        process.stdin.flush()

        while True:
            line = process.stdout.readline()
            if not line:
                stopped = process.stderr.read().strip()
                raise SystemExit(
                    f"md-sparrow serve stopped while running {args[0]}: {stopped}"
                )

            answer = json.loads(line)
            if answer.get("id") != request_id:
                continue

            results.append((answer.get("exitCode", 1), answer.get("stderr", "")))
            break

        if answer.get("closing"):
            raise SystemExit(f"md-sparrow serve is closing: {answer.get('stderr', '')}")

    shutdown(process)
    return results


def shutdown(process):
    try:
        process.stdin.write(json.dumps({"shutdown": True}) + "\n")
        process.stdin.flush()
        process.wait(timeout=30)
    except Exception:
        process.kill()


def run_one_shot(jar, args):
    """The fallback path: one process per command."""

    finished = subprocess.run(
        ["java", "-jar", jar] + args, capture_output=True, text=True, encoding="utf-8"
    )
    return finished.returncode, finished.stderr


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--jar", required=True, help="path to the md-sparrow jar")
    options = parser.parse_args()

    requests = parse_requests(sys.stdin)
    if not requests:
        return 0

    results = run_resident(options.jar, requests)

    if results is None:
        print(
            "md-sparrow serve is unavailable, running one-shot instead (slower)",
            file=sys.stderr,
        )
        results = [run_one_shot(options.jar, args) for args in requests]

    failures = 0

    for args, (exit_code, stderr) in zip(requests, results):
        if exit_code == 0:
            continue

        failures += 1
        print(f"failed ({exit_code}): {args[0]} — {stderr.strip()}", file=sys.stderr)

    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
