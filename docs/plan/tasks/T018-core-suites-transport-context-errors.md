# T018 — Core unit suites A: transport, context factory, errors

Status: in_progress — unblocked: the client runs and the harness reports in both modes.
The transport boundary has an integration test, so what remains is the unit coverage
recorded below.
Depends on: T017
Recipe: normal
Coordinator: Sol Medium
Worker: Terra Medium
Reviewer: Sol Medium

## Decision card

Outcome: the wire-facing core is covered by executable BSL tests.
Included: `mol_Transport`, `mol_ContextFactory`, `mol_Errors`.
Deferred: broker, schema factory, facade, helpers and reuse suites (T019, T020).
Success: suites pass and demonstrably catch seeded regressions in packet handling,
context conversion and error mapping.
Next: continue with T019.

## Acceptance and consumer example

- [ ] `mol_Transport`: packet encode/decode round-trip; the outbound header set
      including the signed-header subset; deterministic signing for fixed inputs;
      multipart stream form for a stream payload; parsing of the bare non-2xx error
      object; and restoration of safe mode on the failure path, not only success.
- [ ] `mol_ContextFactory`: payload-to-context conversion including field casing;
      handler resolution and rejection of an unlisted handler; nested call
      handling; and push/pop cleanup of the inbound context on both success and
      failure.
- [ ] `mol_Errors`: construction of each error shape; conversion and regeneration
      of a remote error including the retained remote stack; and a tested fallback
      when the formatted stack cannot be parsed.
- [ ] Contract fixtures: golden packet and context samples are stored as data and
      round-tripped, so casing and null handling are pinned rather than inferred.
- [ ] Each suite names the source function it exercises.

## Implementation context

Entry point: the T017 harness.
Relevant files: `src/cfe/MoleculerSidecarConnector/CommonModules/mol_Transport/Ext/Module.bsl`,
`.../mol_ContextFactory/Ext/Module.bsl`, `.../mol_Errors/Ext/Module.bsl`.
Constraints: tests run inside 1C, so they must not depend on a live sidecar; use
fixed payload fixtures and a stubbed HTTP interaction where a network call would
otherwise occur.
Unknowns: whether the transport can be tested without an outbound HTTP call, or
whether a seam is needed.

## Environment and verification

Commands: the harness command filtered to these suites. Expected: report with 0
failures; a seeded defect in each area produces a failure.

## Delivery and authority

Deliverable: test modules and fixtures. No artifact publication.

## Stop conditions

Stop if the transport cannot be exercised without an external service and no
authorized seam exists; record the missing seam as a blocker for the coordinator.

## Completion evidence / resume point

Record suite names, command, report path, summary, seeded-regression proof, and
untested corners with the reason.

## Optional pilot metrics

Actual models/efforts:
Elapsed time / repair rounds / human review minutes:
