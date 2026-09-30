# The T000–T040 identifier map

`T000`–`T040` are the retired global task series. They are kept as they are: never renumbered,
never reused, and never given a domain prefix. They are cited in source comments, test suites,
tooling and vendor documentation across the repository, so the numbers are permanent names.

The series is closed. New tasks take a per-domain ID (`<PREFIX>-NNN`), which
[tasks.md](../conventions/tasks.md) explains.

| ID | Domain | Outcome | Status |
|---|---|---|---|
| T000 | `workflow` | Codex can find local workflow files and identify real tooling | verified |
| T001 | `installer` | Installer refinement is decomposed into bounded outcomes | verified |
| T002 | `installer` | Installer form module follows official structure without behavior change | ready |
| T003 | `installer` | Installer reports installed connector presence, state, and version | draft |
| T004 | `installer` | Explicit GitHub source selection returns available connector versions | draft |
| T005 | `installer` | Installer build reproducibly bundles a traceable connector artifact | ready |
| T006 | `installer` | Safe local CFE inspection feasibility is researched | deferred |
| T007 | `installer` | Installer selects bundled/GitHub version and recommends updates | draft |
| T008 | `installer` | Installer installs, updates, or activates the selected connector | draft |
| T009 | `installer` | Initial Default connection parameters are handed off safely | draft |
| T010 | `installer` | Guided installer UI is useful in Russian and English | draft |
| T011 | `installer` | Optional SSL/BSP role-protection extension is specified | deferred |
| T012 | `installer` | Installed connector receives deeper compatibility validation | deferred |
| T013 | `installer` | Installer removes only the connector after destructive confirmation | draft |
| T014 | `tooling` | Container toolchain, test runner and test hosting are verified | verified |
| T015 | `standalone` | Standalone CFE variant is generated from the canonical sources | verified |
| T016 | `standalone` | Builder transformation and output shape are guarded by container-only tests | verified |
| T017 | `tooling` | A BSL suite can run and report in extension and standalone modes | verified |
| T018 | `core` | Transport, context factory and errors are covered by executable tests | verified |
| T019 | `core` | Broker, schema factory, facade and provider are covered by executable tests | verified |
| T020 | `core` | Helpers, logger, reuse caching and context cleanup are covered by tests | verified |
| T021 | `standalone` | The generated standalone CFE loads and works in a database-free infobase | verified |
| T022 | `tooling` | Static quality gate and standalone delivery documentation exist | verified |
| T023 | `core` | Error reporting distinguishes internal, sidecar and end-node failures | in_progress |
| T024 | `core` | All four YAML modules are deleted | verified |
| T025 | `core` | The inbound transport boundary is covered by an integration test | verified |
| T026 | `core` | Module surface and naming are consistent | draft |
| T027 | `core` | The form layer is rebuilt | draft |
| T028 | `core` | Service definitions parse locally instead of through the sidecar | draft |
| T029 | `core` | Service modules migrate from the removed registration API to the constructor shape | draft |
| T030 | `core` | The ambient context stack is pushed and popped symmetrically | verified |
| T031 | `standalone` | The standalone variant keeps the live branch of a standalone guard | verified |
| T032 | `standalone` | The connector's own actions work in the standalone variant | verified |
| T033 | `core` | Both payload directions agree on the shape of a context's action | verified |
| T034 | `core` | A nested call chains to its parent context | withdrawn |
| T035 | `standalone` | The standalone merge keeps service identities apart | verified |
| T036 | `core` | The admin panel form stops calling a method that does not exist | verified |
| T037 | `core` | The connector stops calling platform members newer than its compatibility mode | draft |
| T038 | `global` | Every first-party source file declares one copyright and license | in_progress |
| T039 | `style` | The internal API is marked with `// @internal` | draft |
| T040 | `style` | The internal API region is named `Internal` and holds only its exports | draft |

The status column is a snapshot and goes stale; each task file is the authority, and the domain
index of the row links to it. Use the search box rather than this table when looking for a
specific ID: a task's own folder is `docs/plan/tasks/<domain>/`, and a finished one is under
`history/` there.
