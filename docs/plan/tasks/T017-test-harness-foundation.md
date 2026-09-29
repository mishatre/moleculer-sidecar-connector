# T017 — Test harness foundation and two disposable test infobases

Status: blocked — the 1C client libraries are fixed, but no 1C licence is present
Depends on: T014
Recipe: normal
Coordinator: Sol Medium
Worker: Terra Medium
Reviewer: Sol Medium

## Decision card

Outcome: a BSL test suite can be written, executed and reported in this container,
in both extension mode and standalone mode.
Included: the test-module hosting location decided in T014, the runner command and
report path, the extension-mode infobase, the standalone-mode infobase, and one
trivial green test proving the wiring.
Deferred: the connector suites themselves (T018–T020) and standalone runtime
verification (T021).
Success: one documented command runs the harness against each infobase and emits a
machine-readable report with the trivial test passing.
Next: author the core suites in T018.

## Acceptance and consumer example

- [ ] Test modules live at the location decided in T014 and are named so the
      coverage map in the project plan can be matched to files.
- [ ] One documented command runs the harness against the extension-mode infobase
      and produces a jUnit-style report.
- [ ] The same command, pointed at the standalone-mode infobase, reports the
      trivial test passing with `Moleculer.IsStandalone()` asserted as `True`.
- [ ] Both infobases are reproducible: the exact create/update and CFE-load
      commands are recorded, and neither is a shared or consumer infobase.
- [ ] A failing assertion produces a non-zero exit code.
- [ ] `tests/README.md` describes the harness, the commands and the two bases.

## Implementation context

Entry point: the runner selected in T014 (`vrunner test yaxunit`, `test xunit` or
`test vanessa`) plus the container-only `oscript` suites from T016.
Relevant files: `tests/README.md` (currently describes an aspirational structure),
`src/cfe/`, `build/ib`, and the standalone artifact from T015.
Existing example to follow: the runner's own test conventions; the installed
`add` smoke sets for structure only.
Constraints: `build/ib` is disposable and mutable only for implementation tasks
that require it; never mutate a consumer infobase. Framework artifacts must be
available locally or the dependency is recorded as a blocker.
Unknowns: whether the test extension can be built by the same generator as T015 or
needs its own source tree.

## Environment and verification

Commands: the harness command per infobase, plus the infobase create/update
commands. Expected: report file created, trivial test passing, non-zero exit code
on a seeded failure.

## Delivery and authority

Deliverable: test-hosting source, harness entry point, and `tests/README.md`
update. Infobase creation and update are authorized for the two disposable bases
only. Reversal: delete the created infobases and the test-hosting source.

## Stop conditions

Stop if no runner can execute BSL in this container, or if the framework artifact
cannot be obtained; record the blocker and keep T018–T020 pending.

## Completion evidence / resume point

Record: chosen hosting, exact commands, report paths, infobase paths, trivial-test
output, seeded-failure exit code, and anything still unverified.

## Optional pilot metrics

Actual models/efforts:
Elapsed time / repair rounds / human review minutes:
