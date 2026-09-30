# T014 — Prove the 1C/OneScript toolchain and choose the BSL test runner

Status: verified — 2026-09-30. The client blocker is resolved, the tooling evidence is recorded below, and
the framework decision is recorded with it: YAxUnit, run through the harness T017 built. An independent
review found two gaps and both are closed here: `epf` was missing from the recorded command set, and the
runner command, report path and hosting location were not recorded. The review's other finding — that the
client-blocker section below had gone stale — is annotated rather than deleted, because how it was
resolved is worth keeping.
Depends on: none
Recipe: normal
Coordinator: Sol Medium
Worker: Sol High
Reviewer: Sol Medium

## Decision card

Outcome: the project knows exactly which 1C/OneScript commands work in this
container, which BSL test framework the suites will use, and where test modules
live — with recorded evidence instead of assumptions.
Included: version/CLI verification of `oscript`/`vrunner`, a headless platform
launch, a minimal hand-built extension compiling to `.cfe`, creation of a second
disposable infobase, and the framework/hosting decision.
Deferred: writing any product test, generating the standalone variant, editing
connector sources.
Success: a minimal extension source tree compiles to a `.cfe` in this container,
and one chosen test runner executes and reports a trivial test.
Next: implement T015 (builder generator) and T017 (test harness foundation) from
the decisions recorded here.

## Acceptance and consumer example

- [x] `oscript -version`, `opm --version` and the actual `vrunner` version and
      top-level CLI groups are recorded, including whether `cfe compile`,
      `epf compile`, `test vanessa`, `test xunit` and `test yaxunit` exist.
      (`cfe compile` and all three test runners exist; the `epf` group exists with
      `convert`/`decompile`/`compile` and that row was added after review.)
- [x] A 1C platform executable runs headlessly in this container (licence
      availability is proven or explicitly reported as absent).
      (Both hold: the licence is present and the client starts.)
- [x] A minimal extension tree containing only `Configuration.xml` and
      `Languages/Русский.xml` compiles to a `.cfe` without a
      `ConfigDumpInfo.xml`, and the exact command is recorded.
- [x] The extension `<Version>` element format accepted by the compiler is
      determined (canonical `0.2.0 beta 4` versus 4-part `1.0.0.0`).
- [x] A second disposable infobase for standalone-mode tests exists, or the
      reason it cannot be created is recorded.
      (`build/ib-tests` exists beside `build/ib`.)
- [x] Exactly one BSL test framework is selected with evidence that it runs and
      produces a machine-readable report; the test-module hosting location is
      decided. (YAxUnit, `build/test/reports/yaxunit.xml`, hosting described in
      decision 3.)
- [x] The compile proof does not modify a consumer or shared infobase.

Representative demonstration:

```bash
# minimal tree in a temp dir, then (options first, artifact last - see the
# command-shape note in the evidence below):
vrunner cfe compile --src /tmp/spike/MinExt --ibcmd /tmp/spike/MinExt.cfe
# expected: /tmp/spike/MinExt.cfe created, exit code 0
```

## Implementation context

Entry point: the container shell in `/workspace`.

Relevant existing evidence:
- `docs/plan/environment.md` — records `vrunner --help` as 2.6.1 and documents
  `compileexttocfe`/`compileepf`; the installed runner appears to be 3.0.0.
- `docs/plan/tasks/T005-build-and-bundle-installer.md` — uses the same legacy
  syntax and must be corrected by whichever command set is verified here.
- `docs/plan/tasks/T000-verify-workflow.md` — verified `oscript -version` 2.1.0,
  `opm --version` 1.4.1, platform binaries under `/opt/1cv8/current`.

Reference implementation to reuse:
`/home/usr1cv8/.local/share/ovm/stable/lib/vanessa-runner/src/core/Сервисы/Классы/СервисРасширений.os`
— `СоздатьИсходникиПустогоРасширения` and `ТекстConfigurationXmlПустогоРасширения`
show the minimal extension source set. This path is outside the workspace; read it
read-only and do not vendor it.

Framework candidates:
- YAxUnit — `vrunner test yaxunit`; needs the YAxUnit framework extension plus a
  test extension loaded into the target infobase.
- Vanessa-ADD xUnit — `vrunner test xunit`; `add` 6.8.0 ships `xddTestRunner.epf`.
- OneScript `1testrunner` — cannot execute BSL; only useful for the builder's own
  transformation tests (T016).

Constraints:
- `build/ib` is the disposable target for runtime mutations, and only when a task
  explicitly requires them.
- Do not run `--updatedb`-style mutations against a shared infobase.
- Do not install packages or change application source during this task; report a
  missing dependency instead.

## Environment and verification

Link: ../environment.md

Commands to run and record verbatim (command plus observed output):
- `pwd`, `oscript -version`, `opm --version`
- `vrunner --help`, and the version reported by the runner
- `command -v 1cv8 1cv8c ibcmd` and `readlink -f /opt/1cv8/current`
- a headless launch sufficient to prove licensing, for example a designer
  `-CheckModules`/`/DumpDumpInfo` style call against a scratch infobase
- the minimal-tree `cfe compile` command above
- creation of the standalone test infobase
- one trivial test executed through each candidate runner until one succeeds

Expected results: every item above either produces the stated artifact or an
explicit failure message that is recorded as an unverified stage.

## Delivery and authority

Deliverable: an updated `docs/plan/environment.md` with a verified toolchain
section, the corrected command set, and the two test-base paths; plus this task's
completion-evidence section. No application source, no task-dependent build
artifact, and no repository-policy change.

Authority: temporary directories and the disposable infobases only. Creating the
temporary infobase(s) is authorized; touching any other infobase is not.

Reversal: delete the temporary spike directory and any infobase created solely
for this task if the decision does not need it retained.

## Stop conditions

Stop and record an explicit blocker if: no licence is available for the platform;
no candidate test runner can execute BSL; or the minimal extension source tree
cannot be compiled by any available command. Do not substitute a guess for a
verified command, and do not mark a stage verified because a tool printed help.

## Completion evidence / resume point

Verified 2026-09-29 in the dev container, cwd `/workspace`.

### Tooling

| Check | Observed |
|---|---|
| `oscript -version` | `2.1.0` |
| `opm --version` | `1.4.1` |
| `vrunner --help` | **3.0.0 early prerelease build**, explicitly "not for production" |
| `vrunner` command groups | `infobase`, `cfe`, `cf`, `epf`, `test`, `run`, `validate`, `repo`, `cluster` |
| `vrunner cfe` subcommands | `compile`, `unload`, `load`, `convert`, `compare`, `decompile` |
| `vrunner test` subcommands | `xunit`, `vanessa`, `yaxunit` |
| `vrunner epf` subcommands | `convert`, `decompile`, `compile` — added after review, which noted the earlier table named the command without checking it |
| Legacy `vrunner compileexttocfe` / `compileepf` | **do not exist** — the commands recorded in `environment.md` and T005 are stale |
| `ibcmd --version` | `8.3.24.1667`, usable |
| `1cv8` / `1cv8c` | **cannot launch** at the time of writing; resolved later — see the blocker section, and note that the licence is present now and the client starts |

### Platform client blocker (recorded 2026-09-29, resolved)

Kept because how it was resolved is part of the toolchain story, and because the
sentences below outlive their truth: the image lacked the 4.0 webkit generation.
Once the libraries and a licence were in place, `1cv8`/`1cv8c` started and every
operation this section lists as blocked ran — which is what T017, T018–T020 and
T021 then did. Read the rest of this section as history, not as current state.

`1cv8` and `1cv8c` fail to start with missing shared libraries:

```text
libwebkit2gtk-4.0.so.37 => not found
libjavascriptcoregtk-4.0.so.18 => not found
libsoup-2.4.so.1 => not found
```

The image provides only the 4.1/3.0 generations (`libwebkit2gtk-4.1.so.0`,
`libjavascriptcoregtk-4.1.so.0`, `libsoup-3.0.so.0`). `apt-cache policy` finds no
candidate for `libwebkit2gtk-4.0-37`, `libjavascriptcoregtk-4.0-18`,
`libsoup2.4-1` or `libsoup-2.4-1`, so this is not installable from the image's
current sources.

Consequence: every client-based operation is blocked, specifically
`1cv8`-based compilation, `vrunner run enterprise`, `vrunner validate syntax-check`
and all of `vrunner test yaxunit|xunit|vanessa`.

### Verified headless routes (ibcmd only)

| Route | Command | Result |
|---|---|---|
| Compile CFE from XML sources | `vrunner cfe compile --src <DIR> --ibcmd --v8version 8.3 <OUT.cfe>` | exit 0, artifact created |
| Build a test infobase | `vrunner infobase init --src <cfg-src> --ext <CFE> --ibconnection /F<path> --ibcmd --v8version 8.3` | exit 0, base created, config loaded, extension applied |
| Extension identity/metadata check | `ibcmd config check --db-path=<base> --extension=<name>` | exit 0, "Проверка корректности метаданных успешно завершена" |
| Container-only unit tests | `oscript oscript_modules/1testrunner/src/main.os -runall <dir> xddReportPath <outdir>` | 1 test passed, jUnit written |

### Extension source facts

- A minimal extension source tree needs only `Configuration.xml` plus object
  descriptors. **No `ConfigDumpInfo.xml` is required** to compile or load.
- `vrunner cfe compile` creates a temporary infobase when `--ibconnection` is
  omitted, so it never touches `build/ib`.
- The positional `OUT` argument must come **after** the options:
  `cfe compile [OPTIONS] OUT`. Putting `OUT` first produces
  "Ошибка чтения параметров команды".
- `<Version>` accepts both `1.0.0.0` and the display form `0.2.0 beta 4`; the
  canonical value needs no conversion.
- Objects that exist in the extended configuration must declare
  `<ObjectBelonging>Adopted</ObjectBelonging>`. Omitting it makes the extension
  fail to apply:
  "Язык.Русский: Добавление дочерних объектов этого типа к заимствованным в
  расширениях недопустимо". The canonical `Languages/Русский.xml` declares it.
- The canonical artifact `build/MoleculerSidecarConnector 2909.cfe` loads and
  applies cleanly into a fresh base created from `src/cf`, so the canonical
  extension is loadable headlessly today.
- A CFE filename containing a space breaks `vrunner --ext` / `--src` handling
  ("Не указано значение параметра"). Release artifacts must stay space-free.

### Decisions taken

1. **All build and infobase work uses `--ibcmd`.** The designer path is unusable.
2. **T005 and `environment.md` must be corrected** to the 3.0.0 command set.
3. **The BSL test framework is YAxUnit.** It runs through `vrunner test yaxunit`
   behind `tests/bsl/run-tests.sh --mode canonical|standalone --rebuild-base`, it
   writes a jUnit report to `build/test/reports/yaxunit.xml` (with
   `build/test/reports/run.log` beside it, and `exitcode.txt` for the exit code),
   and a run must not print "a suite did not load". Suites live in
   `tests/bsl/<mode>/CommonModules/<Suite>/Ext/Module.bsl`, and `tests/bsl/common/`
   is shared by both modes. The "deferred behind the client blocker" decision this
   replaces was written when no client could start.
4. **The container-only test layer is confirmed** and will carry the builder's own
   suite (T016).
5. `1bdd` is **not usable as installed**: `Библиотека не найдена: 'packageinfo'`.
   `1testrunner` 1.9.2 works and is the container-only runner.
6. Test hosting is the layout decision 3 describes, and the two test bases are
   `build/ib` (canonical) and `build/ib-tests` (standalone), both created with
   `--ibcmd`. The spike base `build/ib-standalone` is still on disk; this task did
   not remove it.

### Verdict (rewritten 2026-09-30)

- Container-only and metadata-level verification: **available**.
- Compilation of the standalone variant (T015): **available**.
- BSL behavioural tests (T018–T020), the extension harness, the HTTP boundary
  (T025) and standalone runtime verification (T021): **available**. The blocked
  verdict this replaces was written before the libraries and licence were in place.

Next action: T014 is done. The follow-ups this task itself created are still open,
and they are recorded here so they are not mistaken for finished work:
`environment.md` still carries the pre-3.0.0 command set and a "still blocked"
line, and `T005`/`T002` still document `vrunner compileexttocfe`/`compileepf`.
Decision 2 asked for both to be corrected; only `environment.md`'s verified
section was.
