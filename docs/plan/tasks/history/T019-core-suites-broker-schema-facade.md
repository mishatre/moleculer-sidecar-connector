# T019 — Core unit suites B: broker, schema factory, facade, provider

Status: verified — the canonical suite is 163/163 and every acceptance item is covered or explicitly
re-scoped. The one exception, recorded below and in the closure note: the `$node.services` parameter
shape is private to `GetSidecarNodeServices`, which ends in a sidecar call, so it cannot be reached
in-process.
Depends on: T017
Recipe: normal
Coordinator: Sol Medium
Worker: Terra Medium
Reviewer: Sol Medium

## Decision card

Outcome: the public consumer contract and the service-authoring path are covered
by executable BSL tests.
Included: `mol_Broker`, `mol_SchemaFactory`, the `Moleculer` facade, and the
`MoleculerOverridable` provider.
Deferred: helpers, logger and reuse suites (T020); standalone-mode variants (T021).
Success: suites pass and catch seeded regressions in payload construction, schema
compilation and provider resolution.
Next: continue with T020.

## Acceptance and consumer example

- [ ] `mol_Broker`: action and event payload fields for each direction, including
      the known differences (event payloads omit `meta`; `sender` is not inserted);
      `NodeID`/`GenerateUid` behaviour; the `$node.services` query shape; and that
      `GetPublicationValidationCode` mutates its argument by deleting `Connection`.
- [ ] `mol_SchemaFactory`: the builder DSL (`Action`, `Event`, `Channel`, `Meta`,
      `OnStarted`, `OnStopped`, the `Type*` rules); `CompileServiceSchema`
      including prefix and version derivation of `fullName` and the `$dynamic`
      metadata marker; `FromString` for JSON and YAML delegation; and rejection of
      a dynamic constructor in standalone mode.
- [ ] `Moleculer` facade: every public member's contract; rejection of
      `Opts.Connection` for facade calls; configuration discovery in extension mode
      and standalone mode; `AdaptConnectionParams`; and the documented `NoAuth`
      handling gap covered by a test that states current behaviour.
- [ ] `MoleculerOverridable`: every provider procedure is invoked and honoured; the
      mutation semantics and required fields are pinned; `GetServices` is reached.
- [ ] Tests assert current behaviour explicitly where the audit recorded a defect,
      so the defect is visible rather than latent.

## Implementation context

Entry point: the T017 harness.
Relevant files: `.../CommonModules/mol_Broker/Ext/Module.bsl`,
`.../mol_SchemaFactory/Ext/Module.bsl`, `.../Moleculer/Ext/Module.bsl`,
`.../MoleculerOverridable/Ext/Module.bsl`.
Reference: `docs/plan/connector-architecture-audit.md` for the documented shapes
and defects.
Constraints: extension-mode tests run against `build/ib`; do not depend on a live
sidecar.
Unknowns: whether `CompileServiceSchema` can be exercised without a registered
publication.

## Environment and verification

Commands: the harness command filtered to these suites. Expected: report with 0
failures; a seeded defect in each area produces a failure.

## Delivery and authority

Deliverable: test modules and fixtures. No artifact publication.

## Stop conditions

Stop if a facade member cannot be isolated from live discovery; record the
dependency and test the remainder.

## Completion evidence / resume point

Verified 2026-09-29, canonical mode:

- `tests/bsl/canonical/CommonModules/MoleculerFacadeTests` adds 13 tests over the facade's parameter
  factories (`NewConfigParams`, `NewConnectionParams`, `NewPublicationParams`,
  `NewPublicationAuthParams`), `AuthTypes` resolving to the enum, `Namespace`, the `Call` connection
  guard, `RaiseCustomError`, `AdaptConnectionParams` and `Broker`.
- Command `tests/bsl/run-tests.sh --mode canonical`; report `build/test/reports/yaxunit.xml`; summary
  **81/81 passed, 0 failed, 0 errors** in 50 s.
- Two of the new assertions failed on the first run and exposed five empty-message `NStr` sites in
  `src/`. They are recorded and fixed in T023. That is what asserting message content rather than only
  the raise buys.
- Recorded rather than hidden: `ProviderConnectionsMatchTheDeclaredStructure` is vacuous while
  `Catalog.mol_Connections` is empty, which is the state of the test base, so its message carries the
  declared count instead of letting an empty loop look like coverage.

The helper predicates come from `mol_Helpers`, not from `Moleculer`: the facade's own `IsString` and
`IsArray` exist only in the standalone build, where the builder merges the helpers in.

Corners that were listed here as untested are now covered: `GetCurrentContext` and `GetCurrentError` by
delegation comparisons that do not depend on ambient state, and `RaiseError` by a test that asserts what
a raise actually carries. `GetServiceModules`, `GetServices` and `GetPublications` are asserted to return
arrays with their declared count in the message, which is vacuous while the catalogs are empty — recorded
rather than hidden, and the standalone suite covers the empty-provider case explicitly.

### Corrected later the same day

An earlier revision of this file described the remaining gap as "the facade and the provider
`mol_HelpersClientServer`". The facade was indeed missing, but the provider named by the acceptance is
`MoleculerOverridable`, and `mol_HelpersClientServer` is a different module the acceptance never
mentions. Both below.

Added in the same pass:

- `tests/bsl/canonical/CommonModules/mol_HelpersClientServerTests` — 13 tests over all 11 of that
  module's exports, plus one asserting that `mol_Helpers` forwards to it, so the pair cannot drift
  apart unnoticed. This is extra coverage, not an acceptance item. One test needed correcting on the
  first run: `BinaryData` cannot be built from base64 through its constructor, which expects a path.
- canonical suite now **94/94** in 43 s.

Progress on those two:

- `mol_Broker` — seven tests added, taking its suite from 2 to 9: the node identifier, `Call`'s refusal
  when no sidecar is reachable, `Emit` and `Broadcast` each with and without a group, and
  `GetPublicationValidationCode` deleting `Connection` from the caller's argument.
  Two acceptance items cannot be asserted from here, and are recorded rather than faked: the payload
  field set for each direction is built in `mol_Transport` and belongs to the transport suite, and the
  `$node.services` parameter shape is private to `GetSidecarNodeServices`, which ends in a sidecar call.
- `MoleculerOverridable` — still not started. The acceptance wants every procedure invoked and honoured,
  the mutation semantics and required fields pinned, and `GetServices` reached.

A defect came out of the broker tests, and is fixed. `Broadcast` never inserted a `groups` key when its
options were absent, so `Moleculer.Broadcast("event", payload)` — the plainest form of the documented
API — failed with `Поле объекта не обнаружено (groups)` at `mol_Broker.Модуль(174)` before reaching the
transport, while `Emit` handled the identical case. `Broadcast` now normalises its options exactly as
`Emit` does, and its `EventGroups` assignment uses the same capitalisation.

The first version of that test hid the cause behind a boolean. Returning the failure text instead is
what made the diagnosis immediate, so the suite now uses `TransportRefusal`, which hands the actual
error back to the assertion message.

### Provider, schema and facade completed

- `MoleculerOverridable` — seven tests. In extension mode all five procedures return without touching
their argument, because the catalogs are the source of truth there and the standalone builder replaces
the module wholesale. The suite pins that inertness with a sentinel in each collection, so a provider
that started filling data in this mode would be caught; the filling contract is asserted by
`tests/bsl/standalone`. It also asserts the premise (`IsStandalone()` is false) so the rest cannot pass
for the wrong reason, and invokes all five procedures with empty collections, which is the acceptance's
"every provider procedure is invoked" item.
- `mol_SchemaFactory` — one more test, `AnEmptyServiceReferenceIsNotATypeError`: a catalog reference has
to be dispatched as a dynamic service rather than rejected as an unsupported value type. `RaiseTypeError`
names its parameter, so asserting that the failure does not mention it proves which branch ran. This also
established that the test extension can reference `Справочники.mol_Services` at compile time.
- `Moleculer` facade — seven more tests: the `Emit` and `Broadcast` guards, which also protect the
  `NStr` fix, because a non-empty message proves the locale parse now succeeds; the array shape of
  `GetServices`, `GetPublications` and `GetServiceModules`; and delegation checks for
  `GetCurrentContext` and `GetCurrentError`, written as facade-versus-module comparisons so they do not
depend on whatever thread state the surrounding suite left behind.
- canonical suite **116/116** in 43 s.

Closed 2026-09-30. The two items recorded above are now covered, and one of them corrected a claim made
elsewhere:

- the facade's `RaiseError` is asserted to raise with the message and the class name reaching the caller.
  The **type** does not survive a raise, which is worth knowing: the envelope path reads the structure,
  so a caller catching the platform exception cannot see it.
- the `fullName` derivation is pinned: `CompileServiceSchema("mol_Internal")` yields `$internal`, the name
  the constructor declares rather than the module it lives in, and a service declaring no version gets no
  version suffix. That disproved the premise of T032's entry, which is corrected there.

The `mol_Broker` payload items this task re-scoped to T018 are covered by `mol_PayloadContractTests`, and
the `$node.services` parameter shape remains unreachable in-process and recorded as such. Everything else
in the acceptance is covered by the suites listed above, so this task is verified with that one recorded
exception.

## Optional pilot metrics

Actual models/efforts:
Elapsed time / repair rounds / human review minutes:
