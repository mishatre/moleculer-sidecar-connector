# T019 — Core unit suites B: broker, schema factory, facade, provider

Status: blocked — requires a runnable 1C client (see T014 completion evidence)
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

Record suite names, command, report path, summary, the current-behaviour
assertions deliberately pinning known defects, and untested corners.

## Optional pilot metrics

Actual models/efforts:
Elapsed time / repair rounds / human review minutes:
