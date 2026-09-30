# Refactoring cycle — rationale and task index

Status: 2026-09-30. The cycle is authorised and every task now lives in its own file, so a delegated worker
can be pointed at a single packet. This page keeps the evidence and the reasoning that produced those tasks;
it does not define any of them.

Scope: simplify and reorder the connector, not change what it does. The T018 suites are the safety net for
the parts already covered; the biggest refactoring target is also the part with no safety net.

## Evidence

| # | Finding | Evidence |
|---|---|---|
| 1 | All four YAML parsers are dead code: `YAML`, `YAML1`, `YAML2`, `YAML3` | `mol_SchemaFactory.ParseServiceDefinition` does `Return Moleculer.Call("$sidecar.utils.parseYAML", Params)` and the `Return YAML.ToObject(Text)` line below it is **unreachable**; YAML is parsed on the Node side. `YAML1`/`YAML2`/`YAML3` appear only in the configuration declarations, the subsystem item list and `ConfigDumpInfo`. 864–879 lines each, ~3,500 total |
| 2 | The transport's inbound boundary has no test | `mol_Transport` exports only `ExecuteRequest` and `Transporter_HTTP_Receive`; `New HTTPServiceRequest()` fails with `Конструктор не найден`, because the platform only builds that class behind a web publication. So the inbound path is reachable only as integration testing, not from a unit test |
| 3 | The error taxonomy does not distinguish origins | T023: sidecar-down and end-node-rejection look alike; caller types `"NotFoundError"` and `"ServiceSchema"` are not dispatched; one concept has two spellings |
| 4 | Number handling is duplicated and partly redundant | `IsNumber` (strict) plus `CanBeNumber` (`Try`/`Number`); `mol_SchemaFactory` then converts again with `Number()` after the guard; the platform's `TypeDescription.AdjustValue` is the real cast |
| 5 | `CustomError` is a 50-line if/else chain | one branch per type name, so a new type means editing control flow instead of adding a row |
| 6 | Every type predicate is a passthrough | `mol_Helpers.IsString/IsMap/…` each forward to `mol_HelpersClientServer`, an indirection with no logic in between |
| 7 | Module naming is inconsistent | `Moleculer*` versus `mol_*` prefixes; `mol_Reuse` and `mol_ReuseCalls` exist only to work around the platform rule that a common module cannot hold module variables |
| 8 | The form layer is not aimed at reuse | the owner reports almost every form needs recreating; the admin-panel layout defect fixed in `7af2cd6` was a symptom, not the disease |

## Classification

Needed for the cycle:

- 1 — delete the YAML modules. The size win is large and the risk is low: the code is unreachable, so
  removing it cannot change behaviour. Landed as T024.
- 2 — cover the inbound transport by integration test. It is the boundary the sidecar actually talks to, and
  it is the only way to observe the error mapping. Landed as T025.

Later, once the two above land:

- 3 and 5 — error taxonomy and its dispatch table; T023 already exists as a task file.
- 4 — number handling; folded into T026.
- 6 and 7 — module surface and naming; T026.

Undecided, needs the owner:

- 8 — the form layer; T027.

## Tasks

| ID | Outcome | Status | Depends on | File |
|---|---|---|---|---|
| T024 | All four YAML modules are deleted | verified | none | [Task](tasks/history/T024-drop-yaml-modules.md) |
| T025 | The inbound transport boundary is covered by an integration test | verified | none | [Task](tasks/history/T025-integration-test-inbound-transport.md) |
| T026 | Module surface and naming are consistent | draft | T023, T025 | [Task](tasks/T026-module-surface-and-naming.md) |
| T027 | The form layer is rebuilt | draft | owner decision | [Task](tasks/T027-rebuild-the-form-layer.md) |
| T028 | Service definitions parse locally instead of through the sidecar | draft | owner decision on safe mode; T025 | [Task](tasks/T028-parse-service-definitions-locally.md) |
| T029 | Service modules migrate from the removed registration API to the constructor shape | draft | constructor contract; T028 for YAML output | [Task](tasks/T029-migrate-service-modules.md) |
| T030 | The ambient context stack is pushed and popped symmetrically | draft | T020 | [Task](tasks/T030-balance-the-ambient-context-stack.md) |
| T031 | The standalone variant keeps the live branch of a standalone guard | verified | T015, T016 | [Task](tasks/history/T031-keep-the-live-branch-when-stripping.md) |
| T032 | The connector's own actions work in the standalone variant | verified | T035, T015 | [Task](tasks/history/T032-connector-actions-over-http.md) |
| T033 | Both payload directions agree on the shape of a context's action | verified | T018 | [Task](tasks/history/T033-agree-on-the-shape-of-an-action.md) |
| T034 | A nested call chains to its parent context | withdrawn | T030, T033 | [Task](tasks/T034-nested-call-parent-context.md) |
| T035 | The standalone merge keeps service identities apart | verified | T015 | [Task](tasks/history/T035-standalone-merge-identities.md) |
| T036 | The admin panel form stops calling a method that does not exist | verified | none | [Task](tasks/history/T036-admin-panel-form-method.md) |
| T037 | The connector stops calling platform members newer than its compatibility mode | draft | platform-support decision | [Task](tasks/T037-compatibility-mode-versus-members.md) |

T036 and T037 were found by the static gate built in T022, after this cycle's list was written.

## Open decisions

1. Delivery target for this cycle: smaller/simpler, or more testable? The two pull in different orders and
   1 versus 2 above should be sequenced accordingly.
2. Whether the form layer belongs in this cycle or its own.

## Related

- [yaml-native-parser-viability.md](yaml-native-parser-viability.md) — the study behind T028.
- [connector-architecture-audit.md](connector-architecture-audit.md) — the earlier reading of the same code.
- [T023](tasks/T023-error-taxonomy.md) — the error taxonomy, which this cycle's evidence table feeds.
- [tasks/history/README.md](tasks/history/README.md) — where completed task files go, and the rule for when.
