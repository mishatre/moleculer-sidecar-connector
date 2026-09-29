# T015 — Generate a standalone CFE variant from the canonical extension sources

Status: in_progress — implemented and verified headlessly; independent review pending
Depends on: T014
Recipe: normal
Coordinator: Sol Medium
Worker: Sol High
Reviewer: Sol Medium

## Decision card

Outcome: one command turns the canonical connector sources into a fresh,
database-free extension tree containing two common modules plus the HTTP service,
and compiles it into an installable `.cfe`.
Included: the `tools/standalone-builder` generator, a declarative standalone
profile, the module merge with collision renaming, the standalone-provider
implementation, and the compile step.
Deferred: publishing the artifact, the guided installer path for the variant, and
any change to the canonical extension sources.
Success: `build/standalone/<variant>/` contains only `Configuration.xml`,
`Languages/Русский.xml`, `CommonModules/Moleculer`, `CommonModules/MoleculerOverridable`,
`HTTPServices/mol_Moleculer`, the manifest and `INSTALL.md`, and
`vrunner cfe compile` produces a loadable `.cfe`.
Next: run T016 (builder transformation tests) against this generator; then load
the artifact in T021.

## Acceptance and consumer example

- [ ] `tools/standalone-builder/build-standalone.os` reads the canonical sources
      under `src/cfe/MoleculerSidecarConnector/` and writes a variant tree under
      `build/standalone/<variant>/` without modifying the canonical tree.
- [ ] The variant declares no constants, catalogs, enums, functional options,
      forms, data processors, roles, subsystems, styles or pictures.
- [ ] The merged `Moleculer` module contains no `mol_*` qualifier, no
      `Catalog.`/`Constant.`/`Enum.`/`FunctionalOption.`/`Form.`/`DataProcessor.`
      reference, and no duplicate symbol definition.
- [ ] `MoleculerOverridable` carries the injected settings and every provider
      procedure (`GetConfig`, `GetConnections`, `GetPublications`,
      `GetServiceModules`, `GetServices`) runs without the standalone
      early-return guard and without sample placeholder identifiers.
- [ ] `Moleculer.IsStandalone()` returns `True` in the generated variant.
- [ ] The compatibility mode is taken from the profile, not hard-coded.
- [ ] `vrunner cfe compile` produces the artifact, and a manifest records profile
      values, source revision, generated files and hashes.

Representative example:

```bash
oscript tools/standalone-builder/build-standalone.os \
  --profile tools/standalone-builder/profiles/default.json
# expected: build/standalone/default/ tree + ./build/standalone/MoleculerSidecarConnectorStandalone.cfe
```

## Implementation context

Entry point and relevant files/symbols:
- `src/cfe/MoleculerSidecarConnector/Configuration.xml` — canonical identity,
  prefix and compatibility mode used as the profile default.
- `src/cfe/MoleculerSidecarConnector/CommonModules/Moleculer/Ext/Module.bsl` —
  merge target and public facade; `IsStandalone()` at line 215; catalog branches
  guarded at lines 199, 239, 262, 303, 386, 475.
- `src/cfe/MoleculerSidecarConnector/CommonModules/MoleculerOverridable/Ext/Module.bsl`
  — the settings seam; currently a stub with sample `Id="UUID"` rows and a
  `GetServices` that is never called.
- Merge inputs: `mol_Broker`, `mol_ContextFactory`, `mol_Transport`,
  `mol_SchemaFactory`, `mol_Errors`, `mol_Helpers`, `mol_HelpersClientServer`,
  `mol_Logger`, `mol_Reuse`, `mol_ReuseCalls`, `mol_Internal`.
- Dropped inputs: `YAML`, `YAML1`, `YAML2`, `YAML3`, `CodeEditor`,
  `CodeEditorClient`, `CodeEditorClientServer`, `mol_Client`,
  `MoleculerClientServer`, `mol_Server`, and
  `Ext/ManagedApplicationModule.bsl`, `Ext/OrdinaryApplicationModule.bsl`.
- Kept object: `HTTPServices/mol_Moleculer.xml` and its
  `Ext/Module.bsl` handler, which must call the merged module's exported
  transport entry point.

Existing example to follow:
`СервисРасширений.СоздатьИсходникиПустогоРасширения` and
`ТекстConfigurationXmlПустогоРасширения` in
`/home/usr1cv8/.local/share/ovm/stable/lib/vanessa-runner/src/core/Сервисы/Классы/СервисРасширений.os`
— read-only reference for the minimal extension source set and the required
`Configuration.xml` shape. Do not vendor the file.

Main operations and responsibility boundaries:
1. Parse the profile and validate it before any file is written.
2. Load the canonical module set; apply the per-module preamble rename map for the
   collision set (`This`, `ThisMetadata`, `NewContext`, `Constructor` and the
   exported collisions recorded in the connector architecture audit).
3. Rewrite qualified call sites so `mol_X.` becomes a local call while
   `Moleculer.` is kept as a self-reference.
4. Concatenate in dependency order into one server-only module body, and drop
   client-context branches.
5. Resolve the two unguarded standalone paths: `mol_Internal` `WellKnown` reads
   `Constants.mol_TestConnection` and `mol_Reuse` reads the BSP
   `InformationRegister.ВерсииПодсистем` and `AccessRight`.
6. Emit the `MoleculerOverridable` body from the profile's settings.
7. Emit the tree, manifest and `INSTALL.md`, then compile.

Constraints and current callers:
- Canonical sources are read-only inputs; the builder must be re-runnable and
  must not leave partial output on failure.
- The generated module is server-only; the canonical module is also available on
  ordinary client and server-call contexts today, and that difference must be
  recorded in `INSTALL.md`.
- The behaviour of `ReturnValuesReuse` (`mol_Reuse` is `DuringSession`,
  `mol_ReuseCalls` is `DuringRequest`) cannot survive the merge. The PoC must
  decide, with evidence from the actual callers, between an explicit module-level
  cache in the merged module and keeping the two reuse modules separate. Record
  the decision and its consequence in the completion evidence.

Future extension note (not implementation scope): the profile is the seam for
additional variants; do not add hosts, transports or installer integration now.

## Verified inputs from T014

Use these observed facts directly; do not re-derive them.

- Compile with: `vrunner cfe compile --src <XML-SRC-DIR> --ibcmd --v8version 8.3 <OUT.cfe>`.
  The positional `OUT` must follow the options or the runner reports
  "Ошибка чтения параметров команды". The command creates a temporary infobase,
  so it does not touch `build/ib`.
- A minimal extension tree needs only `Configuration.xml` plus object descriptors.
  No `ConfigDumpInfo.xml` is required, and a hand-assembled tree compiles.
- Any object that exists in the extended configuration must declare
  `<ObjectBelonging>Adopted</ObjectBelonging>` in its descriptor. Omitting it
  makes the extension fail to apply with
  "Добавление дочерних объектов этого типа к заимствованным в расширениях
  недопустимо". Copy the canonical `Languages/Русский.xml` shape.
- `<Version>` accepts both `1.0.0.0` and the display form `0.2.0 beta 4`; no
  conversion is needed to keep the canonical version string.
- The canonical `build/MoleculerSidecarConnector 2909.cfe` loads and applies
  cleanly into a base created from `src/cf`, so the merge target's baseline is
  loadable. Use that as the regression comparison.
- Verify a generated variant end to end with
  `vrunner infobase init --src /workspace/src/cf --ext <variant.cfe> --ibconnection /F<path> --ibcmd --v8version 8.3`,
  then `ibcmd config check --db-path=<path> --extension=<name>`.
- Keep artifact file names space-free.

## Environment and verification

Link: ../environment.md

Commands and expected results:
- `oscript tools/standalone-builder/build-standalone.os --profile <profile>` —
  exit 0 and the expected tree.
- `vrunner cfe compile --src <variant tree> --ibcmd --v8version 8.3 <OUT.cfe>` —
  exit 0 and the artifact (options before the positional `OUT`, as verified in
  T014).
- Structural checks: enumerate the generated tree and assert the exact expected
  file list; grep the merged module for `mol_`, `Catalog.`, `Constant.`, `Enum.`,
  `FunctionalOption.`, `DataProcessor.`, `Form.` and for duplicate definitions of
  the collision symbols.
- Re-run the generator into a clean directory and require an identical manifest
  and identical merged-module hash, or document the nondeterministic input.

Required runtime/manual checks: load the artifact into the task-authorized
infobase only if this task claims loadability; otherwise record loading as
deferred to T021.

Unavailable checks and who can perform them: any check requiring a licence,
GitHub access or an authenticated release tool, if T014 recorded it as
unavailable.

## Delivery and authority

Required destination/artifact: source under `tools/standalone-builder/` plus a
generated tree and `.cfe` under `build/standalone/`. Generated bytes stay out of
source review.

Build/output path: `build/standalone/<variant>/` and
`build/standalone/MoleculerSidecarConnectorStandalone.cfe`.

Consumer integration or installation method: documented in the emitted
`INSTALL.md` for both routes — install the `.cfe` as an extension, or move the two
common modules and the HTTP service into a host configuration by hand.

Publication/deployment authorized by this task: none. No GitHub release, no
installer change.

Reversal/recovery method: delete `build/standalone/`; canonical sources are
untouched, so recovery is unconditional.

## Stop conditions

Stop if: the canonical sources cannot be parsed with a bounded rewrite; a
collision cannot be resolved without changing public behaviour; the merged module
does not compile and the cause is not a mechanical rewrite; or the T014 command
set is unavailable. After two failed repairs of the same compile failure, record a
diagnosis instead of retrying.

## Completion evidence / resume point

Implemented 2026-09-29. Entry point `tools/standalone-builder/build-standalone.py`
with `profiles/default.json`, `README.md` and the container-only suite
`tests/standalone-builder/test_builder.py`.

Implementation note recorded as a deliberate deviation: the generator is Python 3,
not OneScript. The bundled OneScript `json` package exposes no global reader and the
repository has no XML library, so Python removed two dependency risks at once for a
developer-only tool. It is present in the container.

| Check | Result |
|---|---|
| `python3 -m unittest discover -s tests/standalone-builder` | **30 tests, 0 failures** |
| Merge statistics | 162 renames, 239 local calls, 31 module references, 12 patches |
| Static checks | passed: no duplicate definition, no removed-module reference, balanced `Procedure`/`Function` |
| `vrunner cfe compile --src build/standalone/default --extension-name MoleculerSidecarConnectorStandalone --ibcmd` | exit 0, 37 727 bytes, sha256 `4511708c…` |
| `vrunner infobase init --src src/cf --ext <variant.cfe> --ibcmd` | exit 0, extension loaded and applied |
| `ibcmd config check --db-path=… --extension=MoleculerSidecarConnectorStandalone` | exit 0, metadata correct |

Generated tree is exactly eight files: `Configuration.xml`,
`Languages/Русский.xml`, the two module descriptors and bodies, the HTTP service
descriptor and handler, and `standalone-manifest.json`. No catalog, constant, enum,
functional option, form, data processor, role, subsystem or style is emitted.

Accepted decisions inside the merge: the internal `$internal` service is compiled
from the merged module (`CompileServiceSchema(Moleculer)`) and `mol_Internal`'s
`Constructor` deliberately keeps its discovered name; `ReturnValuesReuse` is
replaced by explicit module caches with the request-scoped stack reset on inbound
request; client contexts are dropped, so the merged module is server-only.

Unverified work: BSL module syntax (no runnable 1C client), runtime and HTTP
behaviour (T021), and manual host-configuration migration.

Next action: independent review of the generator and the generated tree, then T016
extension and T021.

## Optional pilot metrics

Actual models/efforts: coordinator only, no delegation (single-session implementation)
Elapsed time / repair rounds / human review minutes: 4 compile/verification repairs
Quota before/after, observation times, concurrent-work caveat: not observable
