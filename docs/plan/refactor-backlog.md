# Refactoring cycle — backlog and evidence (draft, 2026-09-29)

Status: draft for the next planning cycle. Nothing here is authorised for
implementation yet; this document exists so the cycle starts from evidence rather
than from impressions. Every item below was observed while building the test
harness, so each one has a reproduction.

Scope: simplify and reorder the connector, not change what it does. The tests
written in T018 are the safety net for the parts already covered; the biggest
refactoring target is also the part with no safety net.

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

Needed for the next cycle:

- 1 — delete the YAML modules. The size win is large and the risk is low: the
  code is unreachable, so removing it cannot change behaviour. Confirm with a
  build and the suites, then delete.
- 2 — cover the inbound transport by integration test. It is the boundary the
  sidecar actually talks to, and it is the only way to observe the error mapping.

Later, once the two above land:

- 3 and 5 — error taxonomy and its dispatch table; T023 already exists.
- 4 — number handling.
- 6 and 7 — module surface and naming.

Undecided, needs the owner:

- 8 — the form layer. "Recreate almost every form" is a different size of job
  from the rest and may belong in its own cycle.

## Proposed dependency-ordered tasks

| ID | Outcome | Status | Depends on |
|---|---|---|---|
| T024 | All four YAML modules are deleted | verified | none |
| T025 | The inbound transport boundary is covered by an integration test | draft | none |
| T026 | Module surface and naming are consistent | draft | T023, T025 |
| T027 | The form layer is rebuilt | draft | owner decision |
| T028 | Service definitions parse locally instead of through the sidecar | draft | owner decision on safe mode; T025 |

T024 is elaborated below. The rest stay outlines until the cycle is authorised.

## T024 — delete the YAML modules

Outcome: ~3,500 lines of unreachable parser code leave the extension, and the
configuration stops declaring four modules nobody calls.

Why first: it is the cheapest item here. The code cannot run, so there is no
behaviour to preserve and the suites are enough to prove it.

Evidence: `mol_SchemaFactory.ParseServiceDefinition` returns the sidecar call
first, so `Return YAML.ToObject(Text)` is unreachable; the owner confirms YAML is
validated and converted on the Node side on purpose.

Shape, to confirm during refinement:

- delete `CommonModules/YAML`, `YAML1`, `YAML2`, `YAML3` and their descriptors;
- drop the four `<CommonModule>` entries from `Configuration.xml` and the items
  from `Subsystems/Moleculer.xml`;
- decide what to do with the dead lines after the `Return` rather than leaving
  them in place;
- `ConfigDumpInfo.xml` carries version entries for the removed modules; it is a
  regenerable cache, so confirm whether it should be refreshed or dropped.

Acceptance: `vrunner cfe compile` still builds the canonical extension, the
canonical suites stay green, and `tools/bsl-checks/find-procedure-as-function.py`
stays clean.

## T025 — integration test for the inbound transport

Outcome: a test sends a sidecar packet to the connector's HTTP service over real
HTTP and asserts the response, covering body parsing, context building, handler
dispatch and the error mapping.

Route, discovered this cycle: the stand-alone server serves the service natively,
so no Apache is needed.

```bash
/opt/1cv8/current/ibsrv --config=/workspace/build/ibsrv/publication.yaml --data=/workspace/build/ibsrv
curl -s -o /tmp/resp.txt -w '%{http_code}' -X POST \
  -H 'Content-Type: application/json' --data-binary @packet.json \
  http://localhost:8314/ib/hs/moleculer/sidecar
```

The publication already exists in `build/ibsrv/publication.yaml`: `build/ib` on
`localhost:8314`, base `/ib`, HTTP services published by default. The service is
`mol_Moleculer`, root URL `moleculer`, template `/sidecar`, POST.

Known blocker: the request reaches the service, but the server answers 503 with
`Недопустимое значение аргумента функции / sessionId != kUUIDNull`
(`ibsrv - src/ib-server-worker/src/serverImpl.cpp(262)`). That is the stand-alone
server failing to establish a session, not the connector. Solving it is part of
this task; stop and record if it needs a publication or authentication change
that affects anything shared.

Note the server holds a lock on `build/ib`, so stop it before any harness run
that recreates that base.

## T028 — parse service definitions locally

Outcome: a service constructor written in YAML compiles with **no sidecar node connected**, so the
capability stops depending on connectivity.

Why: `mol_SchemaFactory.ParseServiceDefinition` sends anything that is not JSON to
`$sidecar.utils.parseYAML`. A YAML constructor therefore works only while a sidecar happens to be up,
and a dynamic-service constructor stored in `Catalog.mol_Services.ServiceConstructor` cannot use YAML
for anything at all — not even to convert it. The component's own speed is not the obstacle: parsing
costs ~0.07 ms against ~2.5 ms for connecting it.

What it involves:

- a local parser behind the seams this project already has (`providerModule:
  MoleculerOverridable` at runtime, profile `patches` at build time), reading
  `vendor/YamlParserNative/`;
- connecting the component once and holding the instance. That also removes the per-call reconnect,
  and it is the same change that clears the safe-mode constraint: `CompileServiceSchema` wraps the
  service constructor in `SetSafeMode(True)`, and the platform forbids connecting an external
  component while safe mode is on;
- the conversions the requirement names, not just parsing: YAML to object, YAML to JSON, object to
  YAML;
- a bounded YAML subset — mappings, sequences and scalars. Anchors, tags, multiple documents and
  complex keys are needed by nothing in `src/`.

Full assessment and measurements: [yaml-native-parser-viability.md](yaml-native-parser-viability.md).

Low priority: nothing in `src/` reads YAML today, so this restores a capability rather than
unblocking existing code.

## Open decisions

1. Delivery target for this cycle: smaller/simpler, or more testable? The two pull
   in different orders and 1 versus 2 above should be sequenced accordingly.
2. Whether the form layer belongs in this cycle or its own.
