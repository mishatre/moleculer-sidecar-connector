# T022 — Static quality gate and standalone delivery documentation

Status: verified 2026-09-30 — the rule set is selected and justified, the gate and the entry point are
verified in both directions, the syntax-check command is recorded, and the manual-migration route has been
rehearsed against a real host configuration. The one thing left unverified is a run-time call from a
migrated host; that is recorded below and is not an acceptance item.
Depends on: T018, T019, T020, T021
Recipe: normal
Coordinator: Sol Medium
Worker: Luna Medium
Reviewer: Sol Medium

## Decision card

Outcome: the repository has a repeatable static gate and a user-facing guide for
the standalone variant.
Included: BSL Language Server diagnostics enabled for the connector and the
generated tree, a syntax-check command, a single entry point that runs all layers,
and the install/manual-migration documentation.
Deferred: CI wiring on a remote service and any release publication.
Success: one documented command runs static checks and all test layers and reports
a clear pass/fail; `INSTALL.md` is validated against a real manual migration.
Next: publish or hand the artifact to its consumer as a separate delivery action.

## Acceptance and consumer example

- [ ] `.bsl-language-server.json` enables diagnostics for `src/cfe` and the
      generated tree, and the selected rule set is justified rather than defaulted.
- [ ] `vrunner validate syntax-check` runs with the recorded command and an
      exception file, or the reason it cannot run is recorded.
- [ ] One entry point runs the OneScript suites, the BSL suites for both modes, and
      the static checks, and returns non-zero on any failure.
- [ ] `tests/README.md` and the standalone `INSTALL.md` describe the commands, the
      two infobases and the expected output.
- [ ] `INSTALL.md` covers both routes: install the `.cfe` as an extension, or move
      the two common modules and the HTTP service into a host configuration by
      hand, including the compatibility-mode limitation and the server-only
      execution-context change.
- [ ] Repeated runs are not required where a clean run is already recorded, unless
      a relevant change occurred.

## Implementation context

Entry point: the commands verified in T014 and the harness from T017.
Relevant files: `.bsl-language-server.json` (currently only language and
formatting settings), `.vscode/settings.json`, `tests/README.md`, the emitted
`INSTALL.md`, `docs/plan/environment.md`.
Constraints: mechanical and documentation work with clear examples; do not
reformat unrelated BSL.
Unknowns: the achievable diagnostics set without a full BSL LS analysis pass.

## Environment and verification

Commands: the static-check command, the syntax-check command, and the combined
entry point. Expected: clean diagnostics on changed files, or an explicitly
recorded exclusion with justification.

## Delivery and authority

Deliverable: configuration, entry point and documentation. Publication of any
artifact remains a separate, separately authorized action.

## Stop conditions

Stop if the diagnostics run produces an unmanageable pre-existing warning volume;
record the counts and propose a bounded rule set instead of disabling the gate.

## Completion evidence / resume point

Record: rule set and rationale, commands, observed output, the combined entry-point
result, and the `INSTALL.md` validation notes including which step was rehearsed.

## Static layer landed — 2026-09-30

### The rule set is selected and justified, not defaulted

Measured over the connector's 38 modules: the default rule set produces **780** findings (35 Error, 133
Warning, 143 Information, 469 Hint), the selection in `.bsl-language-server.json` produces **63**. That is
the stop condition this task names, and the response is the bounded set rather than a disabled gate.
`tools/bsl-checks/README.md` records which families are excluded and why; the twelve included rules are
the correctness ones; `bsl-ls-baseline.json` holds the 63 as debt behind a per-rule ratchet.

`tools/bsl-checks/bsl-language-server.py` runs the analysis, applies the ratchet and exits non-zero only
where a rule exceeds its recorded count. Verified in both directions: the connector passes at 63, and one
unused local variable injected into a copy of the tree fails the run with
`UnusedLocalVariable: 14 -> 15`.

The language server is not vendored — its jar ships inside the `1c-syntax.language-1c-bsl` VS Code
extension, so the runner discovers it under `~/.vscode-server`, with `BSL_LS_JAR` as an override. The work
also corrects `docs/plan/environment.md`, which claimed a headless JRE was missing: `/usr/bin/java` is
OpenJDK 21.0.12 and the server answers, so the analysis runs here instead of being reason-only.

### Two defects the rule set found on its first run

Both are recorded as T036 and T037 in the refactor backlog, because fixing either is a source change
outside this task's deliverable:

* `MissingCommonModuleMethod` — `mol_AdminPanel`'s `ServiceItemForm` calls
  `mol_Broker.GetActivePublications()`, which does not exist. Invisible to every other check, because the
  platform loads metadata without compiling form bodies.
* `UnavailableMemberCall` — `mol_Errors` uses two members added in 8.3.23 while the extension declares
  `Version8_3_21` compatibility.

### The single entry point, verified end to end

`tools/check.sh` runs five layers and was exercised with all of them selected:

| Layer | Result in the recorded run |
|---|---|
| `static` | 63 diagnostics in 12 recorded rules, no rule above its baseline |
| `builder` | `Ran 54 tests` / `OK` |
| `bsl-canonical` | `YAxUnit: всего 179, успешно 179, провалено 0, ошибок 0, пропущено 0`, and no skip notice, so the live suite ran |
| `bsl-standalone` | `YAxUnit: всего 26, успешно 26, провалено 0, ошибок 0, пропущено 0` |
| `syntax-check` | `Проверка конфигурации завершена за 3с`, `Ошибок не обнаружено`, JUnit report written |

Exit code 0 for that run; per-layer logs in `build/test/reports/check/`. The failure path was verified
separately, by lowering one baseline count on purpose: the `static` layer failed, the summary printed
`FAIL: at least one layer did not pass`, and the entry point returned 1. The baseline was then restored
and the tree was left clean.

The same rule set was pointed at the generated tree (`--source build/standalone/default`), the second half
of the first acceptance item: 29 findings in 7 rules — `UnusedLocalVariable` 9, `FunctionShouldHaveReturn`
8, `AllFunctionPathMustHaveReturn` 5, `EmptyCodeBlock` 3, `IfElseDuplicatedCodeBlock` 2,
`DeletingCollectionItem` 1, `UnreachableCode` 1. The generated tree is not in the gate's default baseline:
it is machine-written, so it would need its own recorded counts and would move with every builder change.

### The syntax check, and why the two layers do not overlap

`vrunner validate syntax-check --mode ExtendedModulesCheck` over an infobase that already carries the
extension answers zero errors in 3 s and writes `build/test/reports/syntax-check.xml`. vrunner looks for
`tools/syntax-check-excludes.txt` by default and only warns when it is missing, so the entry point names it
explicitly; the file is empty because the check reports nothing. The recorded command is in
`docs/plan/environment.md`.

The platform's checks do not compile module bodies, so this layer cannot see T036: a call to a method that
does not exist loads and passes here exactly as it passes `vrunner cfe compile`. That is why the static
layer is not redundant with it, and `tests/README.md` says so where it lists the layers.

### The manual-migration route, rehearsed

The guide's claim was rehearsed in the form the XML-source workflow allows:

1. `src/cf` — the reference host configuration, which carries no common modules and no HTTP services of its
   own — was copied to `/tmp/host-migration`.
2. The generated tree's four common modules and its HTTP service were copied in:
   `CommonModules/{Moleculer, MoleculerOverridable, mol_Reuse, mol_ReuseCalls}` and
   `HTTPServices/mol_Moleculer`. No XML editing was needed: the emitted `mol_Reuse.xml` has the same shape
   and the same uuid as the connector's own.
3. The five objects were registered in the host's `Configuration.xml` `ChildObjects`.
4. A base was built from the migrated host,
   `vrunner infobase init --src /tmp/host-migration --ibcmd --v8version 8.3 --ibconnection /F/workspace/build/ib-migration`,
   which answered `Конфигурация успешно загружена из файлов через ibcmd`, `Конфигурация БД обновлена` and
   `Инициализация информационной базы завершена`, exit 0.

Step 3 is what the rehearsal was worth. The guide did not mention it. In the Designer the registration
happens by itself when a module is added to the tree, but a host that lives as files does not see a module
its `Configuration.xml` does not list. The step is in the guide now, and
`tests/standalone-builder/test_builder.py` asserts the manual route still names it together with all five
objects, so the omission cannot creep back.

Not rehearsed: the run-time call the guide suggests as the final check (`Moleculer.Broker().Call(...)` from
the migrated host). The migration's mechanics and the base it produces are verified; that the migrated host
can then reach a sidecar is not, and the install-as-an-extension route is covered at run time by T021.

### A finding for the release contract: the artifact is not byte-reproducible

Building the same tree twice with the same profile produced two different artifacts —
`sha256 c5a5312c65cb…` and `sha256 9d40771201ec…`. The inputs are reproducible: the manifest records
`sourceRevision c220d80df831`, 13 file hashes and 64 merged-module hashes. The difference therefore comes
from `vrunner cfe compile`, not from the builder. This matters to the release contract in
`docs/plan/environment.md`, which promises a reproducibly traceable artifact: the manifest is the
traceability anchor, the CFE hash is not. Recorded there and on T005, whose outcome covers this.

## Optional pilot metrics

Actual models/efforts:
Elapsed time / repair rounds / human review minutes:
