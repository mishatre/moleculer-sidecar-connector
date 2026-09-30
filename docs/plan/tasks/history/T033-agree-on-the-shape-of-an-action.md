# T033 — agree on the shape of a context's action

Status: verified 2026-09-30 — settled by mirroring Moleculer rather than by choosing between the two
candidates proposed when the task was written.
Depends on: T018
Recipe: normal
Coordinator: Sol Medium
Worker: Terra Medium
Reviewer: Sol Medium

## Decision card

Outcome: a context can be turned back into a payload, so a received request can be forwarded to another node
instead of being terminal.

Why: `mol_ContextFactory.FromPayload` stored the payload's `action` string in `Context.Action`, while
`ToPayload` read `Context.Action.Name`, which only the structure form that `mol_Broker.Call` builds has. The
two directions never met — outbound contexts are built locally, inbound ones arrive from the wire — so
nothing broke, but the asymmetry is why `ToPayload(FromPayload(payload))` raised
`Поле объекта не обнаружено (Name)`.

Success: `ToPayload(FromPayload(payload))` returns the payload it came from, for both a request and an event.

## What was decided

The wire carries the action **name** and the context carries the action **object**, which is what Moleculer
does. `transit.js` sends `action: ctx.action.name` and `context.js` sets `this.action = endpoint.action`, so
the directions are not asymmetric in the library either — they agree because each side holds the shape that
side needs. `FromPayload` now builds the object through `NewActionReference`, `mol_Transport.RequestHandler`
reads its name, and the round trip holds.

The same reading of the reference found two more differences, both fixed: an inbound event belongs in
`eventName`, not in `event` (the sidecar's own `packet.ts` maps `payload.event` to `ctx.eventName`, and
`ctx.event` is the subscription the receiver matched), and the event payload was missing the `meta` field
that both Moleculer's `transit.js` and the sidecar's `fromContext` send.

## Completion evidence / resume point

`mol_PayloadContractTests` now asserts both round trips — action and event — in place of the test that
pinned the failure. Canonical 176/176 at the time, the inbound transport test 12 passed and 0 failed,
standalone 25/25. `mol_Transport.RequestHandler` compares the action's name against the `$internal` prefix,
which is the comparison T032 works with.
