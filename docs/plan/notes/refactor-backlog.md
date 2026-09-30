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

The cycle's tasks are T023-T037 (plus the two that the static gate found later). Their files,
their status and their dependencies live in the [CORE domain index](../tasks/core/index.md),
which is the only place they are mirrored. This page keeps the evidence behind them and the
reasoning that produced them; it defines none of them.

T036 and T037 were found by the static gate built in T022, after this cycle's list was written.

## Open decisions

1. Delivery target for this cycle: smaller/simpler, or more testable? The two pull in different orders and
   1 versus 2 above should be sequenced accordingly.
2. Whether the form layer belongs in this cycle or its own.

## Related

- [yaml-native-parser-viability.md](yaml-native-parser-viability.md) — the study behind T028.
- [connector-architecture-audit.md](connector-architecture-audit.md) — the earlier reading of the same code.
- [T023](../tasks/core/T023-error-taxonomy.md) — the error taxonomy, which this cycle's evidence table feeds.
- [tasks/history/README.md](../conventions/tasks.md) — where completed task files go, and the rule for when.
