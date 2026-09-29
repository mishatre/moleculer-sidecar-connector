# T023 — Error reporting distinguishes internal, sidecar and end-node failures

Status: draft
Depends on: T018 (the error suites establish current behaviour)
Recipe: normal
Coordinator: Sol Medium
Worker: TBD
Reviewer: Sol Medium

## Decision card

Outcome: a failure anywhere in the chain is reported with enough context to tell
where it came from — inside the connector, from the sidecar HTTP boundary, or
from an end node behind the sidecar — instead of a single flat error shape.

Included: an error taxonomy that names those origins, a decision on what the
wire format to the sidecar carries (`name`, `type`, `code`, `data` are the
fields `mol_Errors.NewError` already declares), and the reporting path that
renders it for a human.

Deferred: anything about retry policy or user-facing UI.

Success: a test can assert each origin, and a reviewer can tell the three apart
from the reported error alone.

Next: refine against the current `mol_Errors` surface once T018 has pinned it.

## Why this exists

Recorded during T018. The current factories are inconsistent in ways that a
proper taxonomy has to settle:

- `CustomError` dispatches on a fixed list of type names. Callers use types that
  are not in it — `"Error"` (Moleculer, several places), `"NotFoundError"`
  (Moleculer line 472), `"ServiceSchema"` (mol_SchemaFactory, several places).
  Those silently fall back to a generic error instead of the specific code the
  author presumably wanted, so `"NotFoundError"` does not produce 404.
- The same concept appears under two spellings: `"ServiceSchema"` and
  `"ServiceSchemaError"` are both used as types.
- `RaiseError` renders `Code` as `StrTemplate("%1: %2", Error.Type, Error.Code)`,
  which assumes a numeric code; a non-numeric one reads as nonsense.
- Transport failures and remote node failures are not distinguished at all, so a
  sidecar that is down and a node that rejected a call look the same to a
  caller.

## Acceptance and consumer example

- [ ] Every factory returns `Code` as a number and a `Name` from a documented set.
- [ ] `type` values used by callers are either dispatched or rejected loudly, not
      silently degraded.
- [ ] A failed HTTP exchange to the sidecar is distinguishable from a business
      rejection returned by an end node.
- [ ] A suite asserts each origin end to end.

## Stop conditions

Stop if the taxonomy cannot be settled without changing the sidecar's protocol;
record the constraint and hand it back instead of guessing.
