# CORE — canonical connector

Scope: `src/cfe/MoleculerSidecarConnector/`, `src/cf/`, `tests/bsl/canonical/`, `tests/bsl/common/`.
Next free ID: `CORE-001`
Rules: [tasks](../../conventions/tasks.md) · [domains](../../conventions/domains.md) · [commits](../../conventions/commits.md)

Next recommended task: **T023**, whose last acceptance items are the only thing keeping the
error taxonomy half-open. **T037** is a small independent source change that the static gate
found and can run alongside it.

The evidence and reasoning that produced the refactoring tasks, with the findings behind each
one, is [refactor-backlog.md](../../notes/refactor-backlog.md). Protocol behaviour is described
in [connector-sidecar-protocol.md](../../notes/connector-sidecar-protocol.md) and the public
interface audit in [connector-architecture-audit.md](../../notes/connector-architecture-audit.md).

## Open

| ID | Outcome | Status | Depends on | File |
|---|---|---|---|---|
| T023 | Error reporting distinguishes internal, sidecar and end-node failures | in_progress | none | [Task](T023-error-taxonomy.md) |
| T026 | Module surface and naming are consistent | draft | T023, T025 | [Task](T026-module-surface-and-naming.md) |
| T027 | The form layer is rebuilt | draft | owner decision | [Task](T027-rebuild-the-form-layer.md) |
| T028 | Service definitions parse locally instead of through the sidecar | draft | owner decision on safe mode; T025 | [Task](T028-parse-service-definitions-locally.md) |
| T029 | Service modules migrate from the removed registration API to the constructor shape | draft | constructor contract; T028 for YAML output | [Task](T029-migrate-service-modules.md) |
| T034 | A nested call chains to its parent context | withdrawn | T030, T033 | [Task](T034-nested-call-parent-context.md) |
| T037 | The connector stops calling platform members newer than its compatibility mode | draft | platform-support decision | [Task](T037-compatibility-mode-versus-members.md) |

## Closed

| ID | Outcome | Closed | File |
|---|---|---|---|
| T018 | Transport, context factory and errors are covered by executable tests | verified | [Task](history/T018-core-suites-transport-context-errors.md) |
| T019 | Broker, schema factory, facade and provider are covered by executable tests | verified | [Task](history/T019-core-suites-broker-schema-facade.md) |
| T020 | Helpers, logger, reuse caching and context cleanup are covered by tests | verified | [Task](history/T020-core-suites-helpers-logger-reuse.md) |
| T024 | All four YAML modules are deleted | verified | [Task](history/T024-drop-yaml-modules.md) |
| T025 | The inbound transport boundary is covered by an integration test | verified | [Task](history/T025-integration-test-inbound-transport.md) |
| T030 | The ambient context stack is pushed and popped symmetrically | verified | [Task](history/T030-balance-the-ambient-context-stack.md) |
| T033 | Both payload directions agree on the shape of a context's action | verified | [Task](history/T033-agree-on-the-shape-of-an-action.md) |
| T036 | The admin panel form stops calling a method that does not exist | verified | [Task](history/T036-admin-panel-form-method.md) |

T034 is kept as the record of a wrong finding, not as work to do.
