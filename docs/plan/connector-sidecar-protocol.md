# Connector ↔ sidecar protocol and interaction baseline

Status: source-derived protocol baseline, 2026-09-10. This document describes current observable contracts and their gaps; it does not assert a stable wire protocol.

## Endpoints, authentication, and envelope

The CFE posts to `POST /sidecar` using `mol_Transport.Transporter_HTTP_Send`; its inbound HTTP service passes requests to `Transporter_HTTP_Receive`. The sidecar `$sidecar` service exposes the same path through `ApiGateway` and verifies requests using an AWS SigV4-like authorization header. Request-option construction adds `host`, and the CFE also sends `content-type`, `content-length`, `x-amz-date`, `x-amz-content-sha256`, and `authorization`. Its `SignedHeaders` calculation explicitly excludes authorization, content length, content type and user agent, so the current signature covers `host`, `x-amz-content-sha256`, and `x-amz-date`.

The transport envelope is `{ sender, meta, data, stream }`. `data` is a context payload. A stream request is multipart with a JSON `packet` field and a `stream` field; ordinary requests are JSON. The definitive current implementations are [CFE transport](../../src/cfe/MoleculerSidecarConnector/CommonModules/mol_Transport/Ext/Module.bsl), [CFE context payload](../../src/cfe/MoleculerSidecarConnector/CommonModules/mol_ContextFactory/Ext/Module.bsl), [sidecar gateway](../../moleculer-sidecar-next/src/mixins/api-gateway.ts), and [packet utility](../../moleculer-sidecar-next/src/packet.ts).

| Direction | Payload fields | Result |
| --- | --- | --- |
| 1C → sidecar action | `id`, `action`, `params`, `meta`, `timeout`, `locals`, `level`, `tracing`, `parentID`, `requestID`, `caller`, `stream` | response packet data or structured error |
| 1C → sidecar event | `id`, `event`, `params`, `groups`, `broadcast`, `meta`, `locals`, `level`, `tracing`, `parentID`, `requestID`, `caller`, `needAck`; `meta` was missing until 2026-09-30, when the sidecar's own `fromContext` and Moleculer's `transit.js` were read to settle the field | currently no meaningful acknowledged event result |
| sidecar → 1C proxy | Moleculer context serialized by gateway; `locals.handler` is transmitted | CFE resolves/executes handler, serializes data/error |

The sidecar’s generated action/event handlers initially replace `ctx.locals` with `{ handler, connection }`. `ApiGateway.send` consumes and deletes `connection` before packet serialization, so credentials/endpoint selection are not intentionally transmitted in `locals`; `handler` remains remote-controlled and needs strict validation/allowlisting. Handler resolution lives in [ContextFactory.Handler](../../src/cfe/MoleculerSidecarConnector/CommonModules/mol_ContextFactory/Ext/Module.bsl).

### HTTP success and error forms

Both directions use HTTP 200 with a packet envelope for ordinary success. A stream success is multipart with packet and stream parts. The sidecar returns non-2xx failures as a bare JSON Moleculer error object containing selected `name`, `message`, `code`, `type`, `data`, and `stack`; the CFE parses it and calls `RegenerateError`. The CFE inbound service likewise returns a bare JSON error with the error code as HTTP status, or a plain 500 response if no structured error exists. This success-packet/error-object asymmetry is part of current behavior, not a versioned contract.

## Action surface

### CFE→sidecar

`mol_Broker` calls `$sidecar.register`, `$sidecar.unregister`, `$sidecar.callLocalNode`, `$node.services`, and ordinary Moleculer actions/events. `$sidecar.register` asks back to `$internal.services` on the supplied 1C publication. `$sidecar.callLocalNode` is an administrative bridge used for publication validation. The CFE service-item form calls `$sidecar.updateService`, but execution first calls the nonexistent `mol_Broker.GetActivePublications`, so the checked-in granular-update flow cannot reach that action successfully.

| Action | Request | Current result/failure contract |
| --- | --- | --- |
| Ordinary action | action name; arbitrary params; options may include timeout, meta, request/node IDs, stream and internal connection selection | Returns packet `data`/stream; a non-2xx bare error is reconstructed and raised. |
| Emit/broadcast | event name, arbitrary params, optional groups and connection | Procedure-style fire-and-forget from 1C; acknowledgement fields are not completed. |
| `$sidecar.register` | `{connection}` where connection is the publication callback descriptor (`id`, endpoint, port, SSL, path, auth). When a sidecar route is selected, the original publication also contains a nested `connection` with sidecar access/secret keys. | Returns null/undefined; conversion failures are swallowed and the database row may still be committed. Sidecar TypeScript also declares an unused required `handler` field not enforced by the action validator. |
| `$sidecar.unregister` | `{publicationID: string}` | Destroys matching proxies with `allSettled`, removes database row even if destruction failed, no structured per-service result. |
| `$sidecar.updateService` | `{publicationID: string, service: string}` | Public sidecar action; destructive implementation has lookup/schema defects described below and no transaction/rollback. |
| `$sidecar.callLocalNode` | `{action: string, params?: any, nodeInfo: callback connection/auth}` | Public sidecar action that forwards to an arbitrary supplied 1C endpoint and returns its result. |
| `$node.services` | booleans `onlyLocal`, `skipInternal`, `withActions`, `onlyAvailable` from current CFE helper | Returns sidecar-node service discovery data; exact response schema is inherited from Moleculer and not pinned here. |

### Sidecar→CFE

`mol_Internal` declares `$internal.list`, `.services`, `.actions`, `.events`, `.health`, `.options`, `.metrics`, `.ping`, and `.wellknown`. Only `.services`, `.ping`, and `.wellknown` have meaningful current implementation; several discovery/health methods return an example string. `$internal.services` calls `Moleculer.GetServices(True)`.

The sidecar additionally provides `$sidecar.utils.parseYAML` in [utils.service.ts](../../moleculer-sidecar-next/src/services/utils.service.ts) and authentication actions in [auth.service.ts](../../moleculer-sidecar-next/src/services/auth.service.ts). `mol_SchemaFactory` uses the former. `mol_Helpers` calls a different, unobserved `$sidecar.parseYAML` endpoint.

| Action | Request | Current response |
| --- | --- | --- |
| `$internal.services` | context; declared option booleans are accepted by schema but handler ignores them | Array of `ServiceInfo` wrappers from `Moleculer.GetServices(True)`; `Schema` is currently unset. |
| `$internal.ping` | context | String `pong`. |
| `$internal.wellknown` | context | String form of `mol_TestConnection` UUID; directly depends on the CFE constant. |
| Other `$internal.*` | declared boolean/filter params depending on action | Mostly example string, not operational discovery/health data. |
| `$sidecar.utils.parseYAML` | `{string: string}` | Parsed JavaScript value or parser error. |
| `$sidecar.auth.verifyRequest` | Node request object, protected | Boolean true or authorization error after SigV4-like verification. |
| `$sidecar.auth.generateAccessKey` | protected, no params | `{accessKey, secretKey}` persisted in auth SQLite. |

## Registration lifecycle: observed behaviour

1. CFE reads enabled `mol_Publications` and invokes `$sidecar.register` once for each.
2. Sidecar calls `$internal.services` on that publication using the supplied connection/auth object.
3. For each returned item it calls `convertSidecarService(serviceInfo.Schema, connection)`, tags metadata with `$publicationID`, and creates a Moleculer proxy service.
4. It stores publication endpoint/auth information in `./.data/publication.sqlite` if no row already exists.
5. On sidecar start, it reloads database rows, calls `$internal.services`, and recreates proxy services.
6. Unregister destroys services with matching publication metadata and removes the row.

`RegisterPublication` creates a sanitized publication copy and deletes its nested `Connection`, but never uses that copy; it sends the original publication as `params.connection`. The selected sidecar route is also used separately as the transport destination. Consequently the signed request body unintentionally transmits the sidecar endpoint and access/secret keys back to that sidecar along with the 1C callback descriptor.

Current failures are unsafe: the CFE omits `ServiceInfo.Schema`; conversion errors are caught per service; registration then persists the publication and returns success. Startup only logs a generic warning. `$sidecar.updateService` first destroys the first local service matching the publication, regardless of requested full name. It then searches returned BSL `ServiceInfo` wrappers using lowercase `fullName` although the serialized wrapper declares `FullName`, and even a corrected match would pass the wrapper rather than its `Schema` to `convertSidecarService`. The observed source path is therefore destructive failure after removing an unrelated/first service, not a safe recreation. `destroyService` promises in unregister use `allSettled`, so failed destruction does not prevent publication-row deletion.

## Error, context and stream semantics

CFE transport uses an internal `{ Error, Result }` helper around parsed HTTP outcomes and raises regenerated errors; successful response packet meta is merged into the current context. CFE errors carry `name`, `type`, `message`, `code`, `data`, `stack`, `errorInfo`. Sidecar errors are Moleculer errors converted by [errors.ts](../../moleculer-sidecar-next/src/errors.ts). `RegenerateError` accepts remote stack text, but native remote `ErrorInfo` cannot cross the wire and local/reconstructed frames are not explicitly separated.

Context serialization intends to include correlation, hierarchy, caller, meta, tracing and `locals`, but directional losses are visible in source:

- CFE action payloads include `meta`; CFE event payloads omit it.
- Sidecar action deserialization does not restore `payload.requestID`, while its event branch does.
- The packet envelope contains `sender`, but `Packet.toContext` reads `payload.sender`; CFE payload construction does not insert `sender`, so 1C→sidecar context node identity is lost.
- CFE parent-context creation can inherit request ID, meta, level, caller and tracing, but outgoing broker operations leave ambient context entries behind.

No cross-language fixture establishes property casing or null/undefined behavior. Stream payload handling exists but has no stated limits, cancellation or backpressure contract.

## Error taxonomy

`mol_Errors` is where every error is built. `CustomError(Type, …)` is the dispatcher for the type a *caller*
names, and the table below is the documented set. A name that is not a row is refused loudly, with the name
in the message, because a silent downgrade is what hid sixteen undispatched call sites until T023.

| Caller type | Factory | `Type` on the wire | `Code` |
|---|---|---|---|
| `TypeError` | `TypeError` | `TYPE_ERROR` | 400 |
| `ServiceNotFound` | `ServiceNotFound` | `SERVICE_NOT_FOUND` | 404 |
| `ServiceNotAvailable` | `ServiceNotAvailable` | `SERVICE_NOT_AVAILABLE` | 404 |
| `RequestTimeout` | `RequestTimeout` | `REQUEST_TIMEOUT` | 504 |
| `RequestSkipped` | `RequestSkipped` | `REQUEST_SKIPPED` | 514 |
| `RequestRejected` | `RequestRejected` | `REQUEST_REJECTED` | 503 |
| `ValidationError` | `ValidationError` | `VALIDATION_ERROR` | 422 |
| `MaxCallLevel` | `MaxCallLevel` | `MAX_CALL_LEVEL` | 500 |
| `ServiceSchema`, `ServiceSchemaError` | `ServiceSchemaError` | `SERVICE_SCHEMA_ERROR` | 500 |
| `InvalidPacketData` | `InvalidPacketData` | `INVALID_PACKET_DATA` | 500 |
| `NotFoundError` | `NotFoundError` | `NOT_FOUND` | 404 |
| `InvalidArgument` | `InvalidArgumentError` | `InvalidArgument` | 400 |
| `AccessKeyRequired` | `AccessKeyRequiredError` | `AccessKeyRequired` | 401 |
| `SecretKeyRequired` | `SecretKeyRequiredError` | `SecretKeyRequired` | 401 |
| `ExpiresParam` | `ExpiresParamError` | `ExpiresParamError` | 403 |
| `Error` | — | `GENERIC_ERROR` | 500 |

The rules that come with the table:

- A **type a caller names** has to be a row. The connector's own guards still pass `"Error"`, which is a
  documented row for "the connector refuses this call" and keeps the shape those sites already produced;
  retyping them to `InvalidArgument` is a recorded follow-up rather than a change to make blind.
- `ServiceSchema` and `ServiceSchemaError` are normalised to one row *before* the chain, so one concept has
  one meaning instead of two branches that differ only in spelling.
- A **platform error** converted by `FromErrorInfo` is not a caller type: it is built from the platform's own
  category and name, so it does not pass through the dispatcher at all. A transport failure
  (`ErrorCategory.NetworkError`) becomes a retryable `NETWORK_ERROR` 503, which is what lets a caller tell a
  failed exchange from a business rejection returned by an end node. It used to omit `Code` entirely.
- Every factory returns a numeric `Code` and a filled `Name`. The eleven signing and argument factories used
  to leave the code argument empty, so a caller compared `Undefined`.
- `ServiceNotFound` and `ServiceNotAvailable` carry different codes: they shared `SERVICE_NOT_AVAILABLE`,
  which is the confusion the taxonomy exists to remove.

## Security and operations findings

The sidecar’s verifier accepts `x-amz-content-sha256` as the body hash without recomputing it from raw body. `x-amz-expires` is converted with `Number`; omitted values do not provide a robust expiry policy. The sidecar logs request bodies and errors in [api-gateway.ts](../../moleculer-sidecar-next/src/mixins/api-gateway.ts). Publication username/password/token material is persisted in plaintext SQLite by [sidecar.service.ts](../../moleculer-sidecar-next/src/services/sidecar.service.ts). The data model includes username/password authentication, but the observed outbound request code only emits a Bearer token and does not implement Basic/password authentication.

The sidecar registration parameter interface declares a `handler` member, while action validation accepts only `connection` and registration does not use `handler`. Packet and service structures also cross a case-insensitive BSL/case-sensitive TypeScript boundary without generated types or fixtures. These are signs that the wire contract is inferred from implementation rather than owned as a versioned interface.

Additional production security surfaces are explicit in current source:

- CFE transport disables safe mode around HTTP but restores it only on success.
- `$sidecar.callLocalNode` is public and accepts an arbitrary endpoint plus credentials, creating an authenticated SSRF/credential-forwarding surface unless separately constrained.
- `$sidecar.updateService` has default public visibility despite destructive behavior.
- Inbound sidecar access/secret keys and publication callback credentials are both stored in plaintext SQLite.
- The callback path implements Bearer token auth only; password/basic configuration is not honored.

These issues, lack of protocol versioning, replay protection, authoritative status, TLS/topology evidence, bounded retry/failover telemetry, packet-size limits, and shutdown semantics prevent production readiness.

## Locked target protocol direction

Keep HTTP as the baseline until representative latency/operability measurements justify another transport. Define a versioned health and registration handshake containing connector identity, infobase generation, publication/service identity, desired generation/digest, applied generation, status, timestamp, and per-service error. CFE owns desired state; sidecar reconciles and returns typed outcomes. Authentication must recompute request-body integrity, enforce bounded clock/replay policy, redact secrets, use protected credential storage, and authenticate both directions. Unsupported fields/schema features must fail validation.

The semantic baseline remains always-sidecar dispatch. A local fast path, dynamic handler registry, session registry, filesystem registry, or sidecar-maintained registry is a later evidence-driven decision; any option must define authorization and invalidation after failed reconciliation or infobase replacement.

## Evidence limitations

No packet fixture, TypeScript test, CFE compile, live HTTP exchange, stream test, or security test was executed for this baseline. Field casing and actual Moleculer serializer compatibility are source observations only.
