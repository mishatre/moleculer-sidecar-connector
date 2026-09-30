# T030 — make the ambient context stack balanced

Status: draft
Depends on: T020 (closed)
Recipe: normal
Coordinator: Sol Medium
Worker: TBD
Reviewer: Sol Medium

## Decision card

Outcome: every push onto the ambient stack is matched by a pop, so the stack stops growing for the process
lifetime and a finished operation stops being the current context.

Why now: `mol_ContextFactory.Handler` pushes the incoming context and pops it again, so the inbound path is
balanced. `mol_Broker.Call`, `Emit` and `Broadcast` call `SetCurrentContext`, which pushes onto the same
stack, and nothing pops it. `mol_Errors` does the same with a raised error. Two consequences: the stack
grows once per call, and `GetCurrentContext` and `GetCurrentError` keep returning a value after the
operation that produced it has ended.

Included: a pop for each of the four sites, and the tests that pin them, in both modes.
Deferred: nothing recorded.
Success: after a call, the ambient context is what it was before; after a raise, `GetCurrentError` stops
answering once the operation ends.
Next: run the live suite and watch the assertion named in Evidence below — it currently pins the leak.

## Evidence

`tests/bsl/canonical/CommonModules/mol_AmbientContextTests` pins the reachable half — an ambient error
survives an unrelated successful operation — and its header names all four sites. It is written to be
rewritten, not deleted, when the lifecycle changes.

The broker's push happens after the transport answers, so reaching it needs a sidecar, and that gap is
closed rather than described: `tests/bsl/canonical/CommonModules/LiveSidecarCallTests` calls the service
over HTTP and asserts the ambient context left behind is the call's own. The push-without-pop is therefore
pinned as observed behaviour in the suite that actually reaches it, and the fix has to change that
assertion rather than merely add one.

## Shape, to confirm during refinement

Either a pop around the transport call in the three broker methods, or a scoped helper on
`mol_ContextFactory` that pushes and pops around a passed block. The second is harder in BSL, which has no
closures, so the first is the likely answer.

While fixing it, the finding recorded on T023 is worth keeping in view: an unreachable sidecar makes the
client hang instead of failing, so a `Try`/`Except` around the call is part of what has to be right, not
just the pop.

## Implementation context

Relevant files: `mol_Broker/Ext/Module.bsl` (`Call`, `Emit`, `Broadcast`), `mol_ContextFactory/Ext/Module.bsl`
(the stack contract and `Handler`), `mol_Errors/Ext/Module.bsl`, and `mol_Helpers` (the named stacks).

## Environment and verification

Link: [environment.md](../environment.md)

Commands: `tools/check.sh --layers bsl-canonical,bsl-standalone` with the sidecar running, so the live suite
takes part. Expected: the rewritten assertions pass in both modes.
Required runtime check: the live sidecar, because the broker's push is only reachable through a completed
transport call.

## Stop conditions

Stop if the stack contract has to change shape (for example, if one stack must become per-operation state)
— that is a design decision, not a fix. After two failed repairs, diagnose before another attempt.
