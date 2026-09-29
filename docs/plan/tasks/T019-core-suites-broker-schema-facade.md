# T019 — Core unit suites B: broker, schema factory, facade, provider

Status: in_progress — the schema factory and the facade are covered and the canonical suite is 94/94.
Two acceptance items remain, and both are larger than the suite counts suggest: `mol_Broker` has only
its two `GenerateUid` tests, and `MoleculerOverridable` is not exercised at all. Details below.
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

Untested corners: `GetCurrentContext`, `GetCurrentError` and `RaiseError` are not asserted yet. The
first two read thread state another suite could leave dirty, and `RaiseError` needs the platform
error-object shape. `GetServiceModules`, `GetServices` and `GetPublications` remain uncovered in
canonical mode; the standalone suite covers their empty-provider case.

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

Still open, in the acceptance's own words:

- `mol_Broker` — only `GenerateUid` is covered. The payload field set for each direction, the fact that
  event payloads omit `meta` and do not carry `sender`, the `$node.services` query shape, and
  `GetPublicationValidationCode` deleting `Connection` from its argument are all unasserted.
- `MoleculerOverridable` — no test invokes it. The acceptance wants every procedure invoked and
  honoured, the mutation semantics and required fields pinned, and `GetServices` reached.

## Optional pilot metrics

Actual models/efforts:
Elapsed time / repair rounds / human review minutes:
