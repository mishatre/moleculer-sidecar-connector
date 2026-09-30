# Task index

Two workstreams share this index: the installer roadmap (T001–T013, unchanged)
and the standalone-builder/test workstream (T014–T022).

Next: **the suite workstream (T014–T021) is finished, so T022 is unblocked and is the next task to pick
up.** T032 is the remaining merge defect: the variant cannot build its internal service and the reason is
swallowed, so it needs that exception observed before a fix is chosen.

Files for completed tasks are moved to `tasks/history/` — see [its README](tasks/history/README.md) — so
this folder shows only work that is still open. The links below keep working across that move.

| ID | Outcome | Status | Depends on | File |
|---|---|---|---|---|
| T000 | Codex can find local workflow files and identify real tooling | verified | Open project in dev container | [Task](tasks/history/T000-verify-workflow.md) |
| T001 | Installer refinement is decomposed into bounded outcomes | verified | T000 | [Task](tasks/history/T001-refine-sidecar-connector-installer.md) |
| T002 | Installer form module follows official structure without behavior change | ready | T000 | [Task](tasks/T002-refactor-installer-form-module.md) |
| T003 | Installer reports installed connector presence, state, and version | draft | T002 | [Task](tasks/T003-detect-installed-connector.md) |
| T004 | Explicit GitHub source selection returns available connector versions | draft | T003, T005 | [Task](tasks/T004-fetch-github-connector-versions.md) |
| T005 | Installer build reproducibly bundles a traceable connector artifact | ready | T002 | [Task](tasks/T005-build-and-bundle-installer.md) |
| T006 | Safe local CFE inspection feasibility is researched | deferred | Supported inspection mechanism | [Task](tasks/T006-validate-selected-cfe.md) |
| T007 | Installer selects bundled/GitHub version and recommends updates | draft | T003–T005 | [Task](tasks/T007-select-version-and-recommend-update.md) |
| T008 | Installer installs, updates, or activates the selected connector | draft | T007 | [Task](tasks/T008-install-selected-connector-artifact.md) |
| T009 | Initial Default connection parameters are handed off safely | draft | T008 | [Task](tasks/T009-initial-connection-parameters.md) |
| T010 | Guided installer UI is useful in Russian and English | draft | T009, T013 | [Task](tasks/T010-refine-installer-ui-and-texts.md) |
| T011 | Optional SSL/BSP role-protection extension is specified | deferred | User details; T005, T008 | [Task](tasks/T011-optional-ssl-role-protection-extension.md) |
| T012 | Installed connector receives deeper compatibility validation | deferred | Concrete failure cases; T003, T008 | [Task](tasks/T012-validate-installed-connector.md) |
| T013 | Installer removes only the connector after destructive confirmation | draft | T003 | [Task](tasks/T013-remove-sidecar-connector.md) |
| T014 | Container toolchain, test runner and test hosting are verified | verified | none | [Task](tasks/history/T014-verify-toolchain-and-test-runner.md) |
| T015 | Standalone CFE variant is generated from the canonical sources | verified | T014 | [Task](tasks/history/T015-standalone-builder.md) |
| T016 | Builder transformation and output shape are guarded by container-only tests | verified | T015 | [Task](tasks/history/T016-builder-transformation-tests.md) |
| T017 | A BSL suite can run and report in extension and standalone modes | verified | T014 | [Task](tasks/history/T017-test-harness-foundation.md) |
| T018 | Transport, context factory and errors are covered by executable tests | verified | T017 | [Task](tasks/history/T018-core-suites-transport-context-errors.md) |
| T019 | Broker, schema factory, facade and provider are covered by executable tests | verified | T017 | [Task](tasks/history/T019-core-suites-broker-schema-facade.md) |
| T020 | Helpers, logger, reuse caching and context cleanup are covered by tests | verified | T017 | [Task](tasks/history/T020-core-suites-helpers-logger-reuse.md) |
| T021 | The generated standalone CFE loads and works in a database-free infobase | verified | T015, T017 | [Task](tasks/history/T021-standalone-runtime-verification.md) |
| T022 | Static quality gate and standalone delivery documentation exist | ready | T018–T021 | [Task](tasks/T022-static-gate-and-delivery-docs.md) |
| T023 | Error reporting distinguishes internal, sidecar and end-node failures | draft | T018 | [Task](tasks/T023-error-taxonomy.md) |

### Next cycle — refactoring

Outlines only, collected from evidence gathered while building the harness. Task
files are written once the cycle is authorised; the reasoning and the acceptance
for T024 and T025 live in [refactor-backlog.md](refactor-backlog.md).

| ID | Outcome | Status | Depends on | Where |
|---|---|---|---|---|
| T024 | All four YAML modules are deleted | verified | none | [Plan](refactor-backlog.md) |
| T025 | The inbound transport boundary is covered by an integration test | verified | none | [Plan](refactor-backlog.md) |
| T026 | Module surface and naming are consistent | draft | T023, T025 | [Plan](refactor-backlog.md) |
| T027 | The form layer is rebuilt | draft | owner decision | [Plan](refactor-backlog.md) |
| T028 | Service definitions parse locally instead of through the sidecar | draft | owner decision on safe mode; T025 | [Plan](refactor-backlog.md) |
| T030 | The ambient context stack is pushed and popped symmetrically | draft | T020 | [Plan](refactor-backlog.md) |
| T031 | The standalone variant keeps the live branch of a standalone guard | verified | T015, T016 | [Plan](refactor-backlog.md) |
| T032 | The connector's own actions work in the standalone variant | draft | T035 (same root cause), T015 | [Plan](refactor-backlog.md) |
| T033 | Both payload directions agree on the shape of a context's action | verified | T018 | [Plan](refactor-backlog.md) |
| T034 | A nested call chains to its parent context | withdrawn | T030, T033 | [Plan](refactor-backlog.md) |
| T035 | The standalone merge keeps service identities apart | verified | T015 | [Plan](refactor-backlog.md) |
| T036 | The admin panel form stops calling a method that does not exist | draft | none | [Plan](refactor-backlog.md) |
| T037 | The connector stops calling platform members newer than its compatibility mode | draft | platform-support decision | [Plan](refactor-backlog.md) |

### Service module migration (new, low priority)

Consumer service modules written against the removed registration API
(`Moleculer.SchemaAddAction`, `Context.RegisterSchema`) no longer compile against this
connector. The fixtures are the three real modules in `docs/service-migration/`; the
decisions, the verification approach and the open questions are in
[service-migration-tool.md](service-migration-tool.md).

| ID | Outcome | Status | Depends on | Where |
|---|---|---|---|---|
| T029 | Service modules migrate from the removed registration API to the constructor shape | draft | constructor contract; T028 for YAML output | [Plan](service-migration-tool.md) |

### Research notes

- [docs/old-code-version/ANALYSIS.md](../old-code-version/ANALYSIS.md) — the module before the
  extension rewrite: what the rewrite dropped, the error-taxonomy baseline that T023 compares against,
  and the specification for the `|`-suffixed parameter vocabulary that T029 needs.

- [yaml-native-parser-viability.md](yaml-native-parser-viability.md) — revised after
  owner review. The requirement (constructors must compile with no sidecar connected)
  is accepted and a local parser is the answer. The platform has no YAML API, so the
  choice is a BSL parser or a Native API component: Native is first-class
  (`AddInType = { COM, Native }`) and the loader accepts a configuration template, so
  one CFE can carry the binary. Safe mode forbids loading and connecting, not using,
  an already-connected component, and does not restrict local computation. A BSL
  parser is the lower-risk route; a Native component cannot be built in this container
  today. **Update:** the Native component was supplied and measured — it works on this
  platform (canonical suite 68/68), parses a service definition in well under a tenth of a
  millisecond when a connection is held, and its only blocker is that
  `CompileServiceSchema` holds safe mode across the service constructor, which forbids
  connecting it there.

### Resolved: the 1C client starts and a licence is present

The client libraries were fixed on 2026-09-29 — `tools/1c-platform/install-client-runtime.sh`
installs the WebKitGTK 4.0 runtime from Ubuntu 22.04 and redirects the platform's
older bundled `libstdc++`, and it is wired into `.devcontainer/Dockerfile`. `ldd`
on `1cv8c` is now clean and the designer starts.

The licence was supplied out of band the same day:
`/var/1C/licenses/20260929101630.lic` is present, and `vrunner test yaxunit` now
launches the client and executes the BSL suites (54/54 in canonical mode). Client
launches are therefore no longer licence-blocked, so `vrunner run enterprise`,
`vrunner validate syntax-check` and `vrunner test xunit|vanessa` are untried
rather than blocked — none of them has been run yet.

Still available without a client: `vrunner cfe compile --ibcmd`,
`vrunner infobase init --ibcmd`, `ibcmd config check`, and the container-only
Python suites (T016).

### Delivered since planning (2026-09-29)

T015 produced `tools/standalone-builder/` and a compiled, loadable standalone
variant: 12 modules merged into one `Moleculer` plus a generated
`MoleculerOverridable`, a single HTTP service, no infobase objects.
`build/standalone/MoleculerSidecarConnectorStandalone.cfe` (37 727 bytes) loads and
applies into `build/ib-standalone` and passes `ibcmd config check`. T016 delivered
30 container-only tests, all passing. BSL runtime behaviour remains unverified and
is tracked by T021.

### Recommended order for the new workstream

T014 (spike) → T015 (builder) → T016 (builder tests, container-only and always
runnable) → T017 (BSL harness) → T018 → T019 → T020 → T021 → T022.

T015 precedes T017 because the builder is the larger risk, its output is an input
to standalone-mode testing, and its own tests need no 1C platform. T018–T020 are
independent of each other once T017 exists and may be reordered.

Setup and task refinement do not authorize application implementation.
