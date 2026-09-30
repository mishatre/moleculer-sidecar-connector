# The T000–T040 identifier map

`T000`–`T040` are the retired global task series. They are kept as they are: never renumbered,
never reused, and never given a domain prefix. They are cited in source comments, test suites,
tooling and vendor documentation across the repository, so the numbers are permanent names.

The series is closed. New tasks take a per-domain ID (`<PREFIX>-NNN`), which
[tasks.md](../conventions/tasks.md) explains.

| ID | Domain | Outcome | Status | Issue |
|---|---|---|---|---|
| T000 | `workflow` | Codex can find local workflow files and identify real tooling | verified | [#43](https://github.com/mishatre/moleculer-sidecar-connector/issues/43) |
| T001 | `installer` | Installer refinement is decomposed into bounded outcomes | verified | [#37](https://github.com/mishatre/moleculer-sidecar-connector/issues/37) |
| T002 | `installer` | Installer form module follows official structure without behavior change | ready | [#25](https://github.com/mishatre/moleculer-sidecar-connector/issues/25) |
| T003 | `installer` | Installer reports installed connector presence, state, and version | draft | [#26](https://github.com/mishatre/moleculer-sidecar-connector/issues/26) |
| T004 | `installer` | Explicit GitHub source selection returns available connector versions | draft | [#27](https://github.com/mishatre/moleculer-sidecar-connector/issues/27) |
| T005 | `installer` | Installer build reproducibly bundles a traceable connector artifact | ready | [#28](https://github.com/mishatre/moleculer-sidecar-connector/issues/28) |
| T006 | `installer` | Safe local CFE inspection feasibility is researched | deferred | [#29](https://github.com/mishatre/moleculer-sidecar-connector/issues/29) |
| T007 | `installer` | Installer selects bundled/GitHub version and recommends updates | draft | [#30](https://github.com/mishatre/moleculer-sidecar-connector/issues/30) |
| T008 | `installer` | Installer installs, updates, or activates the selected connector | draft | [#31](https://github.com/mishatre/moleculer-sidecar-connector/issues/31) |
| T009 | `installer` | Initial Default connection parameters are handed off safely | draft | [#32](https://github.com/mishatre/moleculer-sidecar-connector/issues/32) |
| T010 | `installer` | Guided installer UI is useful in Russian and English | draft | [#33](https://github.com/mishatre/moleculer-sidecar-connector/issues/33) |
| T011 | `installer` | Optional SSL/BSP role-protection extension is specified | deferred | [#34](https://github.com/mishatre/moleculer-sidecar-connector/issues/34) |
| T012 | `installer` | Installed connector receives deeper compatibility validation | deferred | [#35](https://github.com/mishatre/moleculer-sidecar-connector/issues/35) |
| T013 | `installer` | Installer removes only the connector after destructive confirmation | draft | [#36](https://github.com/mishatre/moleculer-sidecar-connector/issues/36) |
| T014 | `tooling` | Container toolchain, test runner and test hosting are verified | verified | [#38](https://github.com/mishatre/moleculer-sidecar-connector/issues/38) |
| T015 | `standalone` | Standalone CFE variant is generated from the canonical sources | verified | [#19](https://github.com/mishatre/moleculer-sidecar-connector/issues/19) |
| T016 | `standalone` | Builder transformation and output shape are guarded by container-only tests | verified | [#20](https://github.com/mishatre/moleculer-sidecar-connector/issues/20) |
| T017 | `tooling` | A BSL suite can run and report in extension and standalone modes | verified | [#39](https://github.com/mishatre/moleculer-sidecar-connector/issues/39) |
| T018 | `core` | Transport, context factory and errors are covered by executable tests | verified | [#11](https://github.com/mishatre/moleculer-sidecar-connector/issues/11) |
| T019 | `core` | Broker, schema factory, facade and provider are covered by executable tests | verified | [#12](https://github.com/mishatre/moleculer-sidecar-connector/issues/12) |
| T020 | `core` | Helpers, logger, reuse caching and context cleanup are covered by tests | verified | [#13](https://github.com/mishatre/moleculer-sidecar-connector/issues/13) |
| T021 | `standalone` | The generated standalone CFE loads and works in a database-free infobase | verified | [#21](https://github.com/mishatre/moleculer-sidecar-connector/issues/21) |
| T022 | `tooling` | Static quality gate and standalone delivery documentation exist | verified | [#40](https://github.com/mishatre/moleculer-sidecar-connector/issues/40) |
| T023 | `core` | Error reporting distinguishes internal, sidecar and end-node failures | in_progress | [#4](https://github.com/mishatre/moleculer-sidecar-connector/issues/4) |
| T024 | `core` | All four YAML modules are deleted | verified | [#14](https://github.com/mishatre/moleculer-sidecar-connector/issues/14) |
| T025 | `core` | The inbound transport boundary is covered by an integration test | verified | [#15](https://github.com/mishatre/moleculer-sidecar-connector/issues/15) |
| T026 | `core` | Module surface and naming are consistent | draft | [#5](https://github.com/mishatre/moleculer-sidecar-connector/issues/5) |
| T027 | `core` | The form layer is rebuilt | draft | [#6](https://github.com/mishatre/moleculer-sidecar-connector/issues/6) |
| T028 | `core` | Service definitions parse locally instead of through the sidecar | draft | [#7](https://github.com/mishatre/moleculer-sidecar-connector/issues/7) |
| T029 | `core` | Service modules migrate from the removed registration API to the constructor shape | draft | [#8](https://github.com/mishatre/moleculer-sidecar-connector/issues/8) |
| T030 | `core` | The ambient context stack is pushed and popped symmetrically | verified | [#16](https://github.com/mishatre/moleculer-sidecar-connector/issues/16) |
| T031 | `standalone` | The standalone variant keeps the live branch of a standalone guard | verified | [#22](https://github.com/mishatre/moleculer-sidecar-connector/issues/22) |
| T032 | `standalone` | The connector's own actions work in the standalone variant | verified | [#23](https://github.com/mishatre/moleculer-sidecar-connector/issues/23) |
| T033 | `core` | Both payload directions agree on the shape of a context's action | verified | [#17](https://github.com/mishatre/moleculer-sidecar-connector/issues/17) |
| T034 | `core` | A nested call chains to its parent context | withdrawn | [#9](https://github.com/mishatre/moleculer-sidecar-connector/issues/9) |
| T035 | `standalone` | The standalone merge keeps service identities apart | verified | [#24](https://github.com/mishatre/moleculer-sidecar-connector/issues/24) |
| T036 | `core` | The admin panel form stops calling a method that does not exist | verified | [#18](https://github.com/mishatre/moleculer-sidecar-connector/issues/18) |
| T037 | `core` | The connector stops calling platform members newer than its compatibility mode | draft | [#10](https://github.com/mishatre/moleculer-sidecar-connector/issues/10) |
| T038 | `global` | Every first-party source file declares one copyright and license | in_progress | [#1](https://github.com/mishatre/moleculer-sidecar-connector/issues/1) |
| T039 | `style` | The internal API is marked with `// @internal` | draft | [#2](https://github.com/mishatre/moleculer-sidecar-connector/issues/2) |
| T040 | `style` | The internal API region is named `Internal` and holds only its exports | draft | [#3](https://github.com/mishatre/moleculer-sidecar-connector/issues/3) |

The status column is a snapshot and goes stale; the issue is the authority, and the `Issue` column
links to it. Use this table only to resolve a `T0NN` back to its domain and issue.
