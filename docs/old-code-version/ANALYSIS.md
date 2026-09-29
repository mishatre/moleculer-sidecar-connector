# The oldest version of the connector — what it is and what it tells us

This directory holds the module as it was **before** it was rewritten as an extension: an all-in-one
pair of common modules plus two thin reuse modules.

| File | Lines | What it holds |
|---|---|---|
| `Moleculer.bsl` | 1 493 | service host, schema builder, registration flow, error taxonomy, sidecar client |
| `HTTPConnector.bsl` | 3 415 | general HTTP client — 141 procedures, including AWS4 signing and gzip |
| `MoleculerReuse.bsl` | 9 | mirrors two hot `Moleculer` calls |
| `HTTPConnectorReuse.bsl` | 8 | mirrors two hot `HTTPConnector` calls |

It is kept for three reasons: it is the **origin API** that T029 migrates from, it is the **historical
baseline** for T023's error taxonomy, and it documents capabilities that the current connector does not
have. Nothing here is source to be restored — see the defects section.

## The old shape

One module did everything the extension now splits across `Moleculer`, `mol_Broker`, `mol_Errors`,
`mol_SchemaFactory`, `mol_Transport` and `mol_Helpers`:

- **service hosting** — `RequestHandler(HTTPServiceRequest)`, `GetServicesRegistrationInfo`,
  `NewServiceContext(Payload, RegisterSchema = False)`;
- **the schema builder** — `SchemaAddAction`, `SchemaAddEvent`, `SchemaAddChannelEvent`,
  `SchemaAddProperty`, `SchemaAddDependency`, `SchemaAddSettings`, `NewServiceSchema`;
- **the error taxonomy** — 19 factories, below;
- **the sidecar client** — `ExecuteSidecarCall`, `GetSidecarActions`, `NewSidecarActionMethod`;
- **an HTTP/AWS client** — `HTTPConnector` with `Get`/`Post`/`Put`/`Patch`/`Delete`, `JsonToObject`,
  `ObjectToJson`, `ReadGZip`/`WriteGZip`, `HMAC`, `ParseURL`, and an `AWS4Authentication` region.

The HTTP client is the part that no longer exists in any form here: the current connector talks the
connector protocol to the sidecar and lets the sidecar own outbound HTTP. That is a deliberate
division, not a regression, but it means **old service modules that reached for `HTTPConnector`
directly have no drop-in replacement** and are outside T029's scope.

The reuse modules show the pattern the extension still uses: a tiny module that mirrors the hot calls of
the real one, so the platform caches the mirror. `MoleculerReuse` mirrors `GetServiceSchema` and
`GetServiceModules`; `HTTPConnectorReuse` mirrors `HTTPStatusCodes` and
`HTTPStatusesCodesDescriptions`.

## The `|` vocabulary, decoded

This is the most directly useful finding for T029. The old BSL contained the parser for the
`"string|optional|trim"` form, so the vocabulary is **not** something to reverse-engineer from the
sidecar — its rules are written down in `Moleculer.ParseParamsDescription`:

| Input part | Result |
|---|---|
| first part, e.g. `string` | `{type: "string"}` |
| first part ending `[]`, e.g. `productUids[]` | `{type: "array"}` |
| bare flag, e.g. `optional`, `trim` | `{optional: true}`, `{trim: true}` |
| `no-` prefix, e.g. `no-empty` | `{empty: false}` |
| `key:value`, e.g. `min:1`, `optional:true` | `{min: 1}`, `{optional: true}`, with booleans and numbers coerced |

Two consequences for the migration tool:

1. The old parser's **output shape is the new builder's descriptor shape**. The old compact string and
   the current `mol_SchemaFactory.TypeBoolean()` / `TypeArray()` descriptors are the same structure, so
   the translation is close to identity and the table has an authoritative reference instead of a guess.
2. The semantic keys are `empty`, `optional`, `trim`, `min`, `max` plus any `key:value` the sidecar
   accepts. A migrated module that silently drops `empty: false` changes validation behaviour, which is
   why T029 treats an unrecognised suffix as a failure.

`ConvertParameter` also coerces `date` values, choosing `JSONDateFormat.JavaScript` for a numeric input
and ISO otherwise. Whatever replaces it must keep that behaviour, because callers depend on it rather
than on the wire format.

## The error taxonomy: baseline and a live defect

The old code defined the taxonomy that T023 now has to settle. Comparing it with the current
`mol_Errors` shows what survived the rewrite and what did not:

| Old factory | Type / Code / Name | Current |
|---|---|---|
| `MoleculerClientError` | caller's type / 400 / `MoleculerClientError` | `ClientError(Type, 400, …)` — same defaults |
| `MoleculerServerError` | caller's type / 500 / `MoleculerServerError` | `ServerError(Type, 500, …)` |
| `MoleculerRetryableError` | caller's type / 500 / `MoleculerRetryableError` | `RetryableError(Type, 500, …)` |
| `ServiceNotFoundError` | `SERVICE_NOT_AVAILABLE` / 404 / retryable | `ServiceNotFound` — **same wrong type** |
| `ServiceNotAvailableError` | `SERVICE_NOT_AVAILABLE` / 404 | `ServiceNotAvailable` — an indistinguishable twin |
| `RequestTimeoutError` | `REQUEST_TIMEOUT` / 504 | `RequestTimeout` |
| `RequestSkippedError` | `REQUEST_SKIPPED` / 514 / name **omitted** | `RequestSkipped` — name now supplied |
| `RequestRejectedError` | `REQUEST_REJECTED` / 503 | `RequestRejected` |
| `ValidationError` | `VALIDATION_ERROR` / 422 | `ValidationError` |
| `MaxCallLevelError` | `MAX_CALL_LEVEL` / 500 | `MaxCallLevel` |
| `ServiceSchemaError` | `SERVICE_SCHEMA_ERROR` / 500 | `ServiceSchemaError` |
| `InvalidPacketDataError` | `INVALID_PACKET_DATA` / 500 | `InvalidPacketData` |
| `QueueIsFullError` | `QUEUE_FULL` / 429 | **absent** |
| `BrokerOptionsError` | `BROKER_OPTIONS_ERROR` / 500 | **absent** |
| `GracefulStopTimeoutError` | `GRACEFUL_STOP_TIMEOUT` / 500 | **absent** |
| `ProtocolVersionMismatchError` | `PROTOCOL_VERSION_MISMATCH` / 500 | **absent** |

Three things worth acting on rather than just recording:

- **`ServiceNotFound` still reports `SERVICE_NOT_AVAILABLE`.** It did so in the oldest version and the
  rewrite copied it. So a genuinely missing service and an unavailable one are indistinguishable to a
  caller, which is exactly the confusion T023 exists to remove. The HTTP integration test sees
  `REQUEST_REJECTED` / 503 from the other path, so this one is the remaining offender.
- **`QueueIsFull`, `BrokerOptions`, `GracefulStopTimeout` and `ProtocolVersionMismatch` were dropped.**
  T023's "documented set of names" should decide explicitly whether their absence matters or whether
  the set simply shrank on purpose.
- **The rewrite fixed one old bug**: `RequestSkippedError` passed an empty name through a doubled comma,
  and `RequestSkipped` now supplies `MoleculerError`. The same doubled-comma omission made six other old
  factories produce errors with no name at all, which is why "every factory returns a name" is worth
  asserting rather than assuming.

## Capabilities whose current equivalent must be confirmed

The old builder exposed four things the current `mol_SchemaFactory` surface does not obviously carry.
T029 should confirm each before migrating a module that uses it, because YAML and JSON may express them
even when the builder API does not:

- `SchemaAddDependency(Schema, NameOrShortName, Version)` — service dependencies with version
  constraints;
- `SchemaAddSettings(Schema, Name, Value)` — non-parameter service settings;
- `SchemaAddProperty(Schema, PropertyName)` — schema-level properties;
- `SchemaAddEvent(Schema, Name, Handler, Rest)` and `SchemaAddChannelEvent(…)` — the optional `Rest`
  argument, plus channel events. The current builder does have `Channel(Name, Handler)`.

The old code also kept its default connection parameters in a `ParametersByDefault` region and a
`Compatibility` region, which is the ancestor of the installer's default-parameters work in T009.

## Defects in the old code — do not restore them

Recorded so that a migration does not treat them as intent:

- `ServiceNotFoundError` classifies as `SERVICE_NOT_AVAILABLE` and is a *retryable* error, so a missing
  service invites a retry that cannot succeed.
- `RequestSkippedError`, `QueueIsFullError`, `MaxCallLevelError`, `ServiceSchemaError`,
  `BrokerOptionsError`, `GracefulStopTimeoutError`, `ProtocolVersionMismatchError` and
  `InvalidPacketDataError` all pass an empty name through `, ,`, leaving `name` undefined.
- `MoleculerReuse.GetServiceSchema(ModuleInfo)` calls `Moleculer.GetServiceSchema(ModuleInfo)` while
  the module declares `GetServiceSchema(ModuleName, Module = Undefined)`. The names disagree, which
  shows the mirror was written against a different revision — the reuse pattern is fragile to keep
  aligned by hand.

## Caveats

`Moleculer.bsl` was read in depth: the factory bodies, the parameter-description parser and the region
map. `HTTPConnector.bsl` was surveyed by its 141-procedure surface and its region map, not read line by
line, so claims about it are limited to structure.
