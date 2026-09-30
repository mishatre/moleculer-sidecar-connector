# T018 — Core unit suites A: transport, context factory, errors

Status: in_progress — the payload contract is covered and canonical is 140/140. Remaining, in the
acceptance's own terms: the packet encode/decode round-trip, the outbound header set with its signed
subset, the multipart stream form, the bare non-2xx error object, and restoration of safe mode on the
failure path. The context factory's handler resolution and its inbound push/pop cleanup are next.
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

### Payload contract — verified 2026-09-30

`tests/bsl/canonical/CommonModules/mol_PayloadContractTests`, six tests, canonical only. The canonical
suite is **140/140**.

Each test names the source function it exercises, which the acceptance asks for:
`mol_ContextFactory.ToPayload` and `mol_ContextFactory.FromPayload`. What is pinned:

- the **action** payload's field set, twelve fields, with the action name taken from the context's action;
- the **event** payload's field set, also twelve, and the difference the acceptance calls out: an event
  payload carries **no `meta`**;
- refusal of a context that names neither an action nor an event, with the reason in the failure;
- that `FromPayload` reads the wire's lower-case keys and selects the action branch from `action`;
- field fidelity against the payload the HTTP integration test sends, so the in-process fixture and the
  live-server fixture describe one contract.

### A finding: the two directions disagree about the shape of `Action`

`FromPayload` assigns the payload's `action` **string** to `Context.Action`, while `ToPayload` reads
`Context.Action.Name`, which only the structure form `mol_Broker.Call` builds has. So an inbound context
cannot be turned back into a payload: the round-trip raises `Поле объекта не обнаружено (Name)`.

That makes the acceptance's "packet encode/decode round-trip" item unreachable as written. The current
behaviour is pinned by a test written to be rewritten rather than deleted, and the fix is raised as T033,
because it decides which shape a context carries — a design decision rather than a test gap.

### The outbound half needs an external service

Per this task's stop condition: the outbound paths — the header set, the multipart stream form, the bare
non-2xx error object, and safe-mode restoration on the failure path — cannot be exercised without a live
sidecar, and no seam exists to inject one. That is recorded as the missing seam rather than worked
around, because the coordinator owns that decision.

## Optional pilot metrics

Actual models/efforts:
Elapsed time / repair rounds / human review minutes:
