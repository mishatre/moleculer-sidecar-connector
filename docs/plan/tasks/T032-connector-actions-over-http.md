# T032 — make the connector's own actions reachable over HTTP

Status: draft — the cause is now proven; the fix is not chosen.
Depends on: T035 (same root cause), T015
Recipe: normal
Coordinator: Sol Medium
Worker: TBD
Reviewer: Sol Medium

## Decision card

Outcome: a packet addressed to one of the connector's `$internal` actions either runs its handler and
returns the result, or is refused for a documented reason rather than because two name tests disagree.

Why now: this is the last merge defect in the cycle. In the standalone variant the internal service cannot
be compiled at all, and the failure is swallowed, so the request answers 503 with no explanation.

Included: the cause to be observed rather than inferred, the fix, and a resolver that stops hiding its
reason.
Deferred: nothing recorded.
Success: the inbound transport test asserts each mode separately and passes in both.
Next: observe the swallowed exception — the section below says why reading cannot settle it.

## What the request does today

`mol_Transport.RequestHandler` tries the local resolver only when the action begins with `"$internal"`, but
`mol_Broker.Delete_FindInternalHandler` matches names qualified by the compiled schema's `fullName`, which
begins with the module name. The two conditions cannot both hold, so the resolver is never consulted for a
name it could match, and every such request answers 503 `Handler is not provided`. The same path is what
`mol_Internal`'s actions — `ping`, `health`, `services`, `actions`, `events`, `metrics`, `options`,
`wellknown`, `list` — were written for.

Owner decision required: the prefix check may be deliberate exposure control rather than a naming mistake.
Enabling the resolver for every action would make `services`, `actions` and `metrics` answer any caller that
can reach the service, so the fix is either to widen the guard to the qualified prefix the resolver actually
matches, or to keep the restriction and rename the actions to match it — and to say which in the
documentation.

## What three wrong readings taught, in order

**RESOLVED 2026-09-30, with the cause proven rather than read:** the two paragraphs above are wrong twice
over. `CompileServiceSchema("mol_Internal")` yields `$internal` — the constructor's declared name — and
`Delete_FindInternalHandler("$internal.ping")` returns the `PingAction` handler in extension mode, both
pinned by `mol_BrokerTests`. The HTTP test confirms it end to end: in extension mode the request runs the
handler and returns `pong`, which is why the canonical run reports twelve passes.

**SETTLED 2026-09-30, from the artifact:** the paragraph above is wrong as well, and for a different
reason. The variant does not fail to find a module. The profile already carries a patch for exactly this
call (`tools/standalone-builder/profiles/default.json`, described as "the internal service is a service of
the merged module, not a separate module"), rewriting it to `CompileServiceSchema(Moleculer)` — and the
emitted module proves the patch ran: `build/standalone/default/CommonModules/Moleculer/Ext/Module.bsl:4119`.

The compile therefore succeeds, and that is the defect. `CompileServiceSchema` dispatches on the literal
name `"Constructor"` (`Moleculer/Ext/Module.bsl:4354-4365`), and the merged module has exactly one such entry
point (`:4764`) — the outer service's. `mol_Internal`'s own constructor (`mol_Internal/Ext/Module.bsl:11`)
is gone, because a module can hold only one procedure of that name and the profile's rename map for
`mol_Internal` renames `this`/`thismetadata` but not `constructor`. The internal schema can no longer be
built in the variant, `Delete_FindInternalHandler` returns Undefined, and the request answers 503.

Both possible outcomes end the same way: either the surviving constructor builds the outer service, so the
loop over `Schema.FullName + "." + Key` finds only `moleculer.*` and never `$internal.ping`, or it raises on
the argument it was handed. Which one happens does not change the conclusion — the internal service is
uncompilable in the variant and compilable in extension mode, and the HTTP test now asserts the two modes
separately for that reason.

**SHARPENED 2026-09-30, from the same artifact:** the surviving constructor is the internal service's own —
`build/standalone/default/CommonModules/Moleculer/Ext/Module.bsl:4764` sets `Schema.Name = "$internal"` at
`:4768` — so the patch is not selecting the wrong service. The lookup fails because the compile **raises**
and its `Except` branch returns Undefined. The rename map makes that possible and is worth naming: it
renames `constructor` for `mol_ContextFactory` (`profiles/default.json:78`) and for `mol_SchemaFactory`
(`:88`) but not for `mol_Internal`, so the internal constructor competes for one name and the merge keeps
one definition.

Which statement raises is not established, and that is itself the finding: `CompileServiceSchema` builds an
error message and calls `LoggerError` before returning Undefined, and no log line survives from the
standalone run, so the reason has to be observed rather than inferred. A resolver that answers `Undefined`
for both "no such action" and "compiling it threw" is what made this task take three wrong readings before
the artifact was read instead. Whatever fixes the compile should also stop hiding its reason.

## Evidence

`tests/bsl/http/test-inbound-transport.sh` sends a complete payload to `$internal.ping` and records the 503
as a gap in the variant, while the same payload in extension mode returns `pong`. The payload itself is
accepted, which the test proves separately by sending the same shape to an unregistered action and getting
the envelope rather than a platform page.

## Environment and verification

Link: [environment.md](../environment.md)

Commands: `tools/check.sh --layers bsl-standalone` plus `tests/bsl/http/test-inbound-transport.sh` in both
modes. The first step, though, is a diagnostic run with enough logging to catch what the `Except` swallows.

## Stop conditions

Stop if observing the exception needs a change to the shared merge behaviour that other modules depend on —
record the constraint and hand it back rather than guessing. After two failed repairs of this issue, diagnose
before another attempt; three readings have already been wrong here.
