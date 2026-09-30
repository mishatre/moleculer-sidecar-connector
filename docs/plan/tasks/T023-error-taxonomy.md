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
- `mol_Helpers.Get` takes an `IgnoreCase` flag that is inert for Structures: the
  platform's `Structure.Property()` already matches case-insensitively, while the
  Map branch uses the case-sensitive `Map.Get()`. The same flag therefore means
  two different things depending on the container. Pinned by the
  `GetOnStructureIgnoresCase` and `GetOnMapIsCaseSensitiveByDefault` tests.

### Measured inventory of the mismatch

`CustomError` dispatches on ten keys: `TypeError`, `ServiceNotFound`,
`ServiceNotAvailable`, `RequestTimeout`, `RequestSkipped`, `RequestRejected`,
`ValidationError`, `MaxCallLevel`, `ServiceSchemaError`, `InvalidPacketData`.
The thirty `RaiseCustomError` call sites in `src/cfe` pass:

| Call-site key | Sites | Dispatched |
|---|---|---|
| `Error` | 5 | no |
| `ServiceSchemaError` | 5 | yes |
| `TypeError` | 4 | yes |
| `ServiceSchema` | 4 | no |
| `SecretKeyRequired` | 2 | no |
| `ExpiresParam` | 2 | no |
| `AccessKeyRequired` | 2 | no |
| `ValidationError` | 1 | yes |
| `NotFoundError` | 1 | no |
| `InvalidPacketData` | 1 | yes |

Eleven of thirty sites therefore degrade to the generic fallback. Guarded by
`mol_SchemaFactoryTests.SchemaFailuresUseATypeTheFactoriesDoNotProduce`, which
asserts the current classification (`Type = "ServiceSchema"` instead of
`SERVICE_SCHEMA_ERROR`) and is written to be rewritten, not deleted, once the
taxonomy is settled. The three signing keys are Moleculer's own error types
(`AccessKeyRequired`, `SecretKeyRequired`, `ExpiresParam`) and need an explicit
decision: give them factories or map them onto `ValidationError`.

### Found and fixed: an empty message that every check missed

While adding facade coverage (T019), two assertions failed on the *message* rather than on the raise,
and the cause had nothing to do with the factory taxonomy:

```
{...ОбщийМодуль.mol_Errors.Модуль(205)}: MoleculerError: :
{...ОбщийМодуль.Moleculer.Модуль(472)}: Ошибка при вызове метода контекста (СтрШаблон): Слишком много фактических параметров
```

Both come from the same defect: an unescaped apostrophe inside the English fragment of an `NStr(...)`
literal. `NStr` does not fail; it returns an empty string, so the message disappears. The second line
proves it independently — `СтрШаблон` reported too many arguments, which is only possible when the
template it received contains no `%1` at all, that is, when it is empty.

Five sites carried it, all of them user-facing:

| Site | Text |
|---|---|
| `Moleculer.Call` guard | `Opts.Connection should't be used … Moleculer common module!` |
| `Moleculer.Emit` guard | same text, without `common` |
| `Moleculer.Broadcast` guard | byte-identical to the `Emit` block |
| `Moleculer.AdaptConnectionParams` | `Couldn't found connection with id ""%1""` |
| `mol_Broker` unregister-publication path | `Couldn't unregister service publication ""%1"" (%2).` |

Fixed by dropping the contractions — `should not`, `Cannot`, `A connection with the id ""%1"" was not
found` — rather than by doubling the apostrophes, so the fix does not depend on `NStr`'s escaping
rules. The apostrophes in `mol_Helpers` sit inside double-quoted BSL strings rather than `NStr`
fragments, so those were never affected.

Why it belongs here: a taxonomy that distinguishes origins is worth nothing when the message carrying
the distinction is empty, and nothing in the project could see it. Compilation passes, the raise
happens, and any assertion that stops at "an error was raised" passes as well. Only asserting the
message content catches it.

### Historical baseline

The oldest version of the connector, kept in `docs/old-code-version/`, defined this taxonomy before
the extension rewrite: three classes with fixed defaults (`MoleculerClientError` 400,
`MoleculerServerError` 500, `MoleculerRetryableError` 500) and fourteen internal factories carrying an
explicit type and code. That file is the reference for "a documented set of names", and comparing it
with `mol_Errors` today gives one live defect and one open decision:

- `ServiceNotFound` still reports `SERVICE_NOT_AVAILABLE`, exactly as the oldest version did, so a
  missing service and an unavailable one cannot be told apart. The rewrite copied that instead of
  correcting it, and it is the same confusion this task exists to remove.
- `QueueIsFull`, `BrokerOptions`, `GracefulStopTimeout` and `ProtocolVersionMismatch` were dropped by
  the rewrite. Decide whether the documented set should be smaller on purpose or whether those origins
  are needed again.

The old code also shipped six factories with no `name` at all, through a doubled comma, which is why
"every factory returns a name" is worth asserting rather than assuming. Details in that directory's
analysis.

Shape verified 2026-09-30: `tests/bsl/canonical/CommonModules/mol_ErrorShapesTests` walks all ten named
factories and asserts that each returns a numeric code, a name and a type. That acceptance item holds
today, which narrows this task to the *values*: `ServiceNotFound` satisfies the shape while still
reporting `SERVICE_NOT_AVAILABLE`, so the defect is the type it reuses rather than what it returns.

A second exception to that claim, found by reading rather than by test: `FromErrorInfo`'s `NetworkError`
branch calls `Error(Type, , "NetworkError", …)` with the code argument omitted, so a network error
carries `Code` as `Undefined`. The named factories all pass the family walk; this path does not. It is
the same doubled-comma omission the old code shipped six times, which suggests checking the remaining
`Error(` call sites for it while this task is open.

## Acceptance and consumer example

- [ ] Every factory returns `Code` as a number and a `Name` from a documented set.
- [ ] `type` values used by callers are either dispatched or rejected loudly, not
      silently degraded.
- [ ] A failed HTTP exchange to the sidecar is distinguishable from a business
      rejection returned by an end node.
- [ ] A suite asserts each origin end to end, including the message text and not only the raise. The
      empty-message defect above passed every check that stopped at "an error was raised".

## Stop conditions

Stop if the taxonomy cannot be settled without changing the sidecar's protocol;
record the constraint and hand it back instead of guessing.
