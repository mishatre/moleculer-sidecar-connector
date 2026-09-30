# T017 — Test harness foundation and two disposable test infobases

Status: verified — 2026-09-30. Reconciliation note: this line said "blocked" long after the blocker was
gone, and the completion-evidence section was never written at all, so the file disagreed with the index
while the harness it describes ran every day. Both are fixed here, and every item below is evidenced by an
observed run rather than by intent.
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

- [x] Test modules live at the location decided in T014 and are named so the
      coverage map in the project plan can be matched to files.
      (`tests/bsl/canonical/CommonModules/<Suite>/Ext/Module.bsl`,
      `tests/bsl/standalone/CommonModules/<Suite>/Ext/Module.bsl`, `tests/bsl/common/`
      shared; a suite is named for the module or mechanism it covers, which is what
      makes it mappable.)
- [x] One documented command runs the harness against the extension-mode infobase
      and produces a jUnit-style report.
      (`tests/bsl/run-tests.sh --mode canonical` → `build/test/reports/yaxunit.xml`.)
- [x] The same command, pointed at the standalone-mode infobase, reports the
      trivial test passing with `Moleculer.IsStandalone()` asserted as `True`.
      (Superseded in substance: `--mode standalone` runs the real suites, and
      `StandaloneRuntimeTests.TheVariantKnowsItIsStandalone` is the assertion this
      item was asking for.)
- [x] Both infobases are reproducible: the exact create/update and CFE-load
      commands are recorded, and neither is a shared or consumer infobase.
      (`build/ib` and `build/ib-tests`, both created with `--ibcmd`; the harness
      rebuilds them with `--rebuild-base`, and `tests/README.md` documents the
      extension loading it does.)
- [x] A failing assertion produces a non-zero exit code.
      (Observed 2026-09-30: a deliberately failing assertion gave
      `провалено 1`, `exitcode.txt` = 1, and harness exit code 1.)
- [x] `tests/README.md` describes the harness, the commands and the two bases.

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

## Completion evidence / resume point

Verified 2026-09-30 in the dev container. The harness is `tests/bsl/run-tests.sh`, the runner behind it is
`vrunner test yaxunit`, and `tests/README.md` documents both.

| Check | Observed |
|---|---|
| `tests/bsl/run-tests.sh --mode canonical` | exit 0, `YAxUnit: всего 166, успешно 166, провалено 0, ошибок 0` |
| `tests/bsl/run-tests.sh --mode standalone` | exit 0, `YAxUnit: всего 25, успешно 25, провалено 0, ошибок 0`, re-observed after the generator gained `INSTALL.md` and the manifest fields |
| A deliberately failing assertion in `mol_AmbientContextTests` | `провалено 1`, `exitcode.txt` = 1, harness exit code 1; the assertion was reverted immediately and the tree confirmed clean |
| A test extension whose suite is not discovered | `YAxUnit: всего 0` and exit 0, with the runner saying "Не найдено ни одного теста - проверьте фильтр (--ext/--modules)" |
| Reports | `build/test/reports/yaxunit.xml` (jUnit), `run.log`, `exitcode.txt` |
| Bases | `build/ib` (canonical) and `build/ib-tests` (standalone), both created with `--ibcmd`, both disposable |

The zero-test row is why the harness does not trust the runner's exit code. Two guards sit on top of it,
and the second was observed to matter rather than assumed:

1. A suite that fails to compile is left out of the counters, so a run is only accepted when the log has
   no "Ошибка инициализации модуля"/"ОшибкаКомпиляцииВстроенногоЯзыка".
2. A run that finds nothing at all exits 0, so a run is only accepted when the log reports at least one
   test. Without this, an extension whose modules the framework did not discover would report success
   while nothing ran, which is exactly what happened to the throwaway probe extension kept under
   `build/test/probe-src/`.

The test extension `MoleculerTests` is scaffolded from `tests/bsl` into `build/test/bsl-src` by the
harness, so the test-hosting source lives in `tests/bsl/` and the canonical extension under `src/` is
never modified by a run.

Not covered here: the standalone variant's own defects. They are in the merge rather than in the test
wiring, so no harness change would reveal them — T032 and T035 carry them.

## Stop conditions

Stop if no runner can execute BSL in this container, or if the framework artifact
cannot be obtained; record the blocker and keep T018–T020 pending.

## Completion evidence / resume point

Record: chosen hosting, exact commands, report paths, infobase paths, trivial-test
output, seeded-failure exit code, and anything still unverified.

## Optional pilot metrics

Actual models/efforts:
Elapsed time / repair rounds / human review minutes:
