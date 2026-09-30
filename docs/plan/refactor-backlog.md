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

## T030 — make the ambient context stack balanced

Outcome: every push onto the ambient stack is matched by a pop, so the stack stops growing for the
process lifetime and a finished operation stops being the current context.

Why: `mol_ContextFactory.Handler` pushes the incoming context and pops it again, so the inbound path is
balanced. `mol_Broker.Call`, `Emit` and `Broadcast` call `SetCurrentContext`, which pushes onto the same
stack, and nothing pops it. `mol_Errors` does the same with a raised error. Two consequences: the stack
grows once per call, and `GetCurrentContext` and `GetCurrentError` keep returning a value after the
operation that produced it has ended.

Evidence: `tests/bsl/canonical/CommonModules/mol_AmbientContextTests` pins the reachable half — an
ambient error survives an unrelated successful operation — and its header names all four sites. The
broker's push happens after the transport answers, so reaching it needs a sidecar; the HTTP integration
test provides that path but does not observe the stack today.

Shape, to confirm during refinement: either a pop around the transport call in the three broker methods,
or a scoped helper on `mol_ContextFactory` that pushes and pops around a passed block. The second is
harder in BSL, which has no closures, so the first is the likely answer.

## T031 — keep the live branch when stripping a standalone guard

Outcome: the generated variant contains the surviving branch of every
`If Not IsStandalone() … Else … EndIf`, instead of losing the mapping that branch holds.

Why: `strip_dead_standalone_branches` walks from a dead `If` to its matching `EndIf` and deletes the
whole statement. That is correct when there is no `Else`: `GetConfig`'s constant block is dead in the
variant and should go. When a live `Else` is present it is the branch the variant depends on, and it is
discarded together with the dead half. Two mappings are lost that way — `LogLevels()` and `AuthTypes()`
— leaving every key `Undefined`.

Evidence: the generated `Moleculer` shows both functions with an empty gap where the `If` was, and
`tests/bsl/standalone/CommonModules/StandaloneRuntimeTests` pins the consequences: the log level can no
longer select a branch, a declared auth type is refused, and an absent one is answered with token auth.

Shape, to confirm during refinement: keep the statement when a live `Else` or `ElsIf` survives, emitting
that branch's body at the original indentation, and keep deleting it outright when every branch is dead.
The existing verification step should also assert that a live branch survives, since today it only
checks that dead ones do not.

Fixed 2026-09-30: `strip_dead_standalone_branches` now splits the statement into its branches, drops the
dead ones and emits what remains — promoting a surviving `ElsIf` to `If`, inlining a bare `Else` body and
dedenting it to the statement level so the generated module stays readable. `LogLevels()` and
`AuthTypes()` carry their mappings in the variant again, which is proven by the two tests that used to
pin their absence: the variant now answers `EventLogLevel` values, dispatches a declared auth type to its
own fields, and refuses an absent one exactly as extension mode does.

The guard was placed in `tests/standalone-builder/test_standalone_strip.py` rather than in
`validate_merged`, because what needs checking is the transformation's behaviour on shapes rather than
the final text: seven container-only cases cover the surviving `Else`, the promoted `ElsIf`, the nested
`If`, the dropped dead `ElsIf` and the preprocessor case that must not be treated as a branch. The
verification step still only checks that dead branches do not survive, which is now the weaker half of
the pair rather than the only half.

## T032 — make the connector's own actions reachable over HTTP

Outcome: a packet addressed to one of the connector's `$internal` actions either runs its handler and
returns the result, or is refused for a documented reason rather than because two name tests disagree.

Why: `mol_Transport.RequestHandler` tries the local resolver only when the action begins with
`"$internal"`, but `mol_Broker.Delete_FindInternalHandler` matches names qualified by the compiled
schema's `fullName`, which begins with the module name. The two conditions cannot both hold, so the
resolver is never consulted for a name it could match, and every such request answers 503
`Handler is not provided`. The same path is what `mol_Internal`'s actions — `ping`, `health`, `services`,
`actions`, `events`, `metrics`, `options`, `wellknown`, `list` — were written for.

Evidence: `tests/bsl/http/test-inbound-transport.sh` sends a complete payload to `$internal.ping` and
records the 503 as a gap, in both modes. The payload itself is accepted, which the test proves separately
by sending the same shape to an unregistered action and getting the envelope rather than a platform page.

Owner decision required: the prefix check may be deliberate exposure control rather than a naming
mistake. Enabling the resolver for every action would make `services`, `actions` and `metrics` answer any
caller that can reach the service, so the fix is either to widen the guard to the qualified prefix the
resolver actually matches, or to keep the restriction and rename the actions to match it — and to say
which in the documentation.

## T033 — agree on the shape of a context's action

Outcome: a context can be turned back into a payload, so a received request can be forwarded to another
node instead of being terminal.

Why: `mol_ContextFactory.FromPayload` stores the payload's `action` string in `Context.Action`, while
`ToPayload` reads `Context.Action.Name`, which only the structure form that `mol_Broker.Call` builds has.
The two directions never meet today — outbound contexts are built locally, inbound ones arrive from the
wire — so nothing breaks, but the asymmetry is why `ToPayload(FromPayload(payload))` raises
`Поле объекта не обнаружено (Name)`.

Evidence: `tests/bsl/canonical/CommonModules/mol_PayloadContractTests` pins the failure as current
behaviour, in a test written to be rewritten rather than deleted. Two other tests in the same suite pin
the field sets each direction emits, which is the contract a fix has to preserve.

Shape: either `ToPayload` accepts both forms and reads the name from whichever it finds, or `FromPayload`
wraps the string in a structure. The first keeps inbound contexts as they are, which matters because
`mol_Transport.RequestHandler` compares `Context.Action` against the `$internal` prefix as a string — see
T032, which touches the same comparison.

## Open decisions

1. Delivery target for this cycle: smaller/simpler, or more testable? The two pull
   in different orders and 1 versus 2 above should be sequenced accordingly.
2. Whether the form layer belongs in this cycle or its own.
