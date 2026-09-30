# T018 — Core unit suites A: transport, context factory, errors

Status: in_progress — the payload contract and the inbound dispatch path are covered and canonical is
145/145. Remaining: the packet encode/decode round-trip (unreachable as written; the shape decision is
T033), the context factory's field casing and nested-call handling, `mol_Errors`' construction,
conversion and stack-parsing fallback, and the outbound transport half, which needs the sidecar seam.
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

### Inbound dispatch — verified 2026-09-30

`tests/bsl/canonical/CommonModules/mol_InboundDispatchTests`, five tests. Canonical **145/145**.

Source function exercised: `mol_ContextFactory.Handler`, the inbound counterpart of the broker's
outbound entry points and the only place in the connector that pushes an ambient context and pops it
again. What is pinned: a resolvable handler runs and its result comes back — `mol_Internal.PingAction`,
a real exported handler rather than a fixture written for the test; an unlisted handler is **reported as
an error response, not raised**, because the raise happens inside the function's own `Try`; a context
naming neither an action nor an event is reported the same way and says why; and the stack is **balanced
after both outcomes**, verified by putting a sentinel on the stack and finding it current again
afterwards.

Why the balance can be asserted here and not for the broker: this pop sits in the function's tail,
outside the `Try`, so it runs on both paths, whereas the broker's push happens after the transport
answers and is never popped. That contrast is what the acceptance is pointing at, and the broker half is
T030.

### Error shapes — verified 2026-09-30

`tests/bsl/canonical/CommonModules/mol_ErrorShapesTests`, five tests. Canonical **150/150**.

Source functions exercised: `mol_Errors.ClientError`/`ServerError`/`RetryableError`, the named factory
family, `RegenerateError` and `ToString`. What is pinned: the seven-field shape every factory funnels
into; the three classes' names and their default codes; that **every one of the ten named factories
returns a numeric code, a name and a type** — walked rather than sampled, with the type carried in each
assertion message so a failure names the offender; that regeneration preserves type, name, code, message
and data; and that the human-readable form states the message, the type and the code.

The family walk matters for T023, whose acceptance is exactly that claim: it holds today, which narrows
that task to the *values* rather than the shape. `ServiceNotFound` passes it while still reporting
`SERVICE_NOT_AVAILABLE`, because its name and code are well formed — the defect is the type it reuses,
not what it returns.

Still open here: conversion from a platform `ErrorInfo` through `FromErrorInfo`, retention of a remote
stack through regeneration, and the fallback when a formatted stack cannot be parsed. One test was
removed rather than kept: `NoExceptionError` is not exported, and the public path to it depends on
whether another suite left an error on the ambient stack.

Extended the same day with the conversion and the remote stack:

- `FromErrorInfoConvertsACaughtPlatformError` — a real caught platform error converts with its
description preserved, a name chosen from the category set, a derived type and the `ErrorInfo` retained.
  This also answers a question left open by `mol_Reuse.BSPVersion` reporting no subsystem version: the
  platform's error-processing module the conversion relies on **is** available in this base.
- `FromErrorInfoRefusesSomethingThatIsNotAnErrorInfo` — the argument's type is enforced, and the refusal
  names the argument.
- `ARemoteStackIsRetainedThroughRegeneration` — an error carrying a foreign stack as a marked string
  keeps it through `RegenerateError`, which is the only diagnostic the receiver has for the far side.

One test was removed rather than kept: `WrapExternalStack` is not exported either, making it the second
private function to catch me. Both are now in the repository's convention notes, together with the
`grep` that answers the question before a run is spent.

Still open: the fallback when a formatted stack cannot be parsed, and the context factory's field-casing
and nested-call handling.

## Optional pilot metrics

Actual models/efforts:
Elapsed time / repair rounds / human review minutes:
