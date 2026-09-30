# MoleculerSidecarConnector — architecture baseline and audit

Status: documentation baseline, 2026-09-10. This is an evidence-led description of the checked-in connector; it is not an implementation task or an approval to change runtime behaviour. “Target direction” sections record decisions from the approved architecture baseline and must be refined into tasks before source changes.

## Purpose and boundaries

`MoleculerSidecarConnector` is a 1C extension (CFE) that lets a 1C infobase consume Moleculer actions/events through a Node.js sidecar and expose selected 1C common modules as Moleculer proxy services. The extension is a combined runtime, persistence, administration and developer-tool package. Its configuration inventory is in [Configuration.xml](../../src/cfe/MoleculerSidecarConnector/Configuration.xml); the inbound endpoint is [HTTPServices/mol_Moleculer.xml](../../src/cfe/MoleculerSidecarConnector/HTTPServices/mol_Moleculer.xml).

The CFE owns 1C configuration data and service definitions. The sidecar owns the Moleculer broker and generated proxy services. The external processor (EPF) installer is a separate deployment tool; see [installer baseline](installer-baseline.md). The sidecar itself is described in [the protocol baseline](connector-sidecar-protocol.md).

## Components and current flows

| Component | Current responsibility | Primary evidence |
| --- | --- | --- |
| `Moleculer` | Public consumer façade; reads configuration, connections, publications and services | [Moleculer module](../../src/cfe/MoleculerSidecarConnector/CommonModules/Moleculer/Ext/Module.bsl) |
| `mol_Broker` | Creates requests/events, registers publications, queries `$node.services` | [mol_Broker](../../src/cfe/MoleculerSidecarConnector/CommonModules/mol_Broker/Ext/Module.bsl) |
| `mol_ContextFactory` | Creates serializable contexts and invokes inbound handlers | [mol_ContextFactory](../../src/cfe/MoleculerSidecarConnector/CommonModules/mol_ContextFactory/Ext/Module.bsl) |
| `mol_Transport` | Packet encoding, signed HTTP send/failover, and HTTP-service receive | [mol_Transport](../../src/cfe/MoleculerSidecarConnector/CommonModules/mol_Transport/Ext/Module.bsl) |
| `mol_SchemaFactory` | Compiles static or catalog-backed BSL service schemas | [mol_SchemaFactory](../../src/cfe/MoleculerSidecarConnector/CommonModules/mol_SchemaFactory/Ext/Module.bsl) |
| `mol_Errors` | Maps 1C errors to serializable Moleculer-style error structures | [mol_Errors](../../src/cfe/MoleculerSidecarConnector/CommonModules/mol_Errors/Ext/Module.bsl) |
| Persistence/UI | Three catalogs, six constants, a single broad role, admin and laboratory forms | [catalogs](../../src/cfe/MoleculerSidecarConnector/Catalogs), [role rights](../../src/cfe/MoleculerSidecarConnector/Roles/mol_Administrator/Ext/Rights.xml) |

```text
1C consumer call: Moleculer.Call → mol_Broker.Call → ContextFactory → Transport
                 → signed POST /sidecar → sidecar Moleculer broker → remote action

Remote proxy call: Moleculer action/event → sidecar generated proxy → HTTP request
                   → 1C /hs/moleculer/sidecar → Transport → ContextFactory handler

Registration: enabled publication → $sidecar.register → $internal.services in 1C
              → sidecar creates proxy services and persists publication credentials
```

The public call path deliberately always goes through the sidecar: the only local-call branch in `mol_Broker.Call` is `If False Then`. Local event dispatch is also present only as commented `Delete_EmitLocalServices` code. Treat “local” semantics as unimplemented, not as an optimization already available.

## Public and semi-public 1C interface

### Consumer façade

[`Moleculer`](../../src/cfe/MoleculerSidecarConnector/CommonModules/Moleculer/Ext/Module.bsl) exports `Call`, `Emit`, `Broadcast`, `Namespace`, `GetCurrentContext`, `GetCurrentError`, `RaiseError`, `RaiseCustomError`, and `Broker`. It rejects an explicit `Opts.Connection` for façade calls, directing callers to `mol_Broker` for connection selection. `Call` returns data or raises; there is no non-throwing `TryCall` contract today.

| Façade member | Parameters | Result/current failure behavior |
| --- | --- | --- |
| `Call(ActionName, Params=Undefined, Opts=Undefined)` | String action; arbitrary params; options structure | Arbitrary action result/stream; raises reconstructed transport/service errors. Rejects `Opts.Connection`. |
| `Emit(EventName, Data=Undefined, Opts=Undefined)` | Event name/data; options structure, or string/array shorthand for groups | No result; routes through sidecar. Rejects `Opts.Connection`. |
| `Broadcast(EventName, Data=Undefined, Opts=Undefined)` | Event name/data; optional groups/options | No result; routes through sidecar. Rejects `Opts.Connection`. |
| `Namespace()` | None | Configured namespace. |
| `GetCurrentContext()` | None | Last request-reuse context or undefined; current implementation can return a stale outbound context. |
| `GetCurrentError()` | None | Last request-reuse error or undefined; caught errors are not reliably removed. |
| `RaiseError(Error)` | Error structure or native `ErrorInfo` | Always raises a 1C exception after translating/storing the error. |
| `RaiseCustomError(Type, Message="", Data=Undefined, ErrorInfo=Undefined)` | Moleculer/custom type and optional detail | Constructs and raises; no return. |
| `Broker()` | None | Returns internal module `mol_Broker`, intentionally exposing explicit-connection and administrative operations. |

The same module also exports semi-public construction/discovery functions: `NewConfigParams`, `NewConnectionParams`, `NewPublicationParams`, `NewPublicationAuthParams`, `AuthTypes`, `IsStandalone`, `GetConfig`, `GetConnections`, `GetPublications`, `GetServiceModules`, `GetServices`, and `AdaptConnectionParams`. Their `Export` marker makes them callable, but no compatibility/versioning policy distinguishes supported integration points from implementation helpers.

| Module | Exported surface | Current intended use and caveat |
| --- | --- | --- |
| `MoleculerClientServer` | `NewOpts`, `NewMCallOpts`, `NewActionDef`, `GetConfig` | Call option/action structures; several advertised options are not demonstrated end to end. |
| `MoleculerOverridable` | `GetConfig`, `GetConnections`, `GetPublications`, `GetServiceModules`, `GetServices` | Host provider callbacks; mutation semantics and required fields are undocumented. |
| `mol_Broker` | `Call`, `Emit`, `Broadcast`, `NodeID`, `GenerateUid`, registration functions, sidecar service query and publication validation | Protected operational layer; permits explicit connection routing that the façade rejects. |
| `mol_ContextFactory` | `Broker`, `Call`, `Emit`, `Create`, endpoint/parameter setters, payload conversion, handler execution and current-context functions | Runtime protocol machinery; unsafe as a general consumer API because it assumes handler/request stack state. |
| `mol_SchemaFactory` | `FromString`, lifecycle/meta/action/event/channel builders, four parameter-rule builders, `CompileServiceSchema` | Code-first schema DSL plus dynamic/declarative compilation. |
| `mol_Errors` | Error constructors for Moleculer, validation and legacy Minio/S3 cases; raise/convert/string/stack/regeneration helpers | Large mixed-domain API; error taxonomy, stack model and consumer stability are not specified. |
| `CodeEditor*` / `YAML*` | Editor initialization/client callbacks; `ToObject` on each YAML parser | UI/parser utilities bundled as common modules, not runtime façade contracts. |

`Moleculer` is available on server, external connection, ordinary client and server call; it is not global and does not use reusable return values. Most `mol_*` modules are server-only implementation modules. This execution-context split is sensible, but it is documented only in metadata and needs a supported-context matrix for consumers.

### Service authoring and models

`mol_SchemaFactory` is the canonical builder for code-first common modules: `Constructor(Builder, Schema)` calls builder methods such as `Action`, `Event`, `Channel`, `Meta`, `OnStarted`, `OnStopped`, `TypeString`, `TypeBoolean`, `TypeArray`, and `TypeMulti`. Dynamic catalog services execute stored constructor text using `Execute`; text definitions can be parsed through `FromString`.

`Moleculer.NewConfigParams`, `NewConnectionParams`, `NewPublicationParams`, and `NewPublicationAuthParams` expose the structures consumed by configuration discovery. `MoleculerOverridable` is intended as the host extension point (`GetConfig`, `GetConnections`, `GetPublications`, `GetServiceModules`, `GetServices`), but its checked-in implementation inserts incomplete sample data and clears the discovered module list before adding `ServiceTsd`; it is not yet a reliable provider contract.

`mol_Broker` exports registration/unregistration and sidecar-discovery helpers. They are operational APIs rather than a stable consumer interface: `RegisterPublication` and `UnregisterPublication` catch/log failures and return no structured result, and `GetPublicationValidationCode` mutates its `Publication` argument by deleting `Connection`.

### Structure and handler contracts

The following shapes are constructed by exported functions. Names are shown with the spelling used at construction; BSL property access is case-insensitive, but JSON consumers are not.

| Constructor/result | Current fields and semantics |
| --- | --- |
| `NewConfigParams()` | `UUID`, `NodeID`, `Name`, `Caption`, `Namespace`, `ModulePrefix`, `LogLevel`, `ExtVersion`, `ExtAdminRole`, plus `LaunchParameters.Enable` and `.SkipRolesCheck`. CFE defaults identify `MoleculerSidecarConnector`, use prefix `Service`, and read namespace/log level/version from metadata/constants. |
| `NewConnectionParams()` | `Id`, `Description`, `Default`, `Type`, `Endpoint`, `Port`, `UseSSL`, `AccessKey`, `SecretKey`, `Timeout`, `Proxy`. Runtime discovery currently emits type `HTTP`; `Proxy` is constructed but not populated from `mol_Connections`. |
| `NewPublicationParams()` | `id`, `description`, `endpoint`, `port`, `useSSL`, `path`, `auth`, `connection`. `auth` is undefined for `NoAuth`, `{token}` for access-token auth, or `{username,password}` for password auth. |
| `NewOpts()` | `timeout`, `retries`, `fallbackResponse`, `nodeID`, `meta`, `parentCtx`, `requestID`, `stream`; defaults are null except `meta` is a new map. `NewMCallOpts()` adds `settled=false`. Several options are declared but not honored demonstrably by the 1C/sidecar round trip. |
| `NewActionDef(action, params, options)` | `{action, params, options}` for multi-call-style definition; no complete consuming implementation was found. |
| `ServiceInfo` returned by `GetServices()` | `Module`, `Name`, `Version`, `FullName`, `Settings`, `Metadata`, `Description`, `Actions`, `Events`, `Schema`. `Schema` is declared but currently left unset. Secure settings named by `$secureSettings` are removed from the public settings copy. |
| Compiled `Schema` | `name`, `fullName`, `version`, `settings`, `dependencies`, `metadata`, `actions`, `methods`, `hooks`, `events`, `created`, `started`, `stopped`, `channels`. Prefix/version logic derives `fullName`; `$dynamic` is inserted into metadata. |
| Action schema | `name`, `rest`, `visibility`, `params`, `cache`, `handler`, `tracing`, `bulkhead`, `circuitBreaker`, `retryPolicy`, `fallback`, `hooks`, `version`, `description`. Many fields mirror Moleculer but lack preservation/compatibility evidence. |
| Event/channel schema | `name`, `group`, `params`, `tracing`, `bulkhead`, `handler`, `context`, `description`. Sidecar event proxies exist; channel proxying is commented out. |
| Context | `This`, `Broker`, `Id`, `NodeID`, action/event/endpoint fields, `Options`, `ParentID`, `Caller`, `Level`, `Params`, `Meta`, `Locals`, `RequestID`, tracing/span fields, acknowledgement fields, cached/raise flags and `Stream`. It is an internal mutable protocol object, not a stable serialization type. |
| Error | `name`, `type`, `message`, `code`, `data`, `stack`, `errorInfo`. Only serializable members cross HTTP; native `ErrorInfo` is local-only. |

A static service module must expose `Procedure Constructor(Builder, Schema) Export`. Action handlers are exported functions receiving one context and returning any serializable value or stream; event handlers are exported procedures receiving one context. Dynamic constructors run stored text with local variables `Schema` and `Builder`. These signatures are convention-based and are not validated before execution.

The builder parameter rules currently cover only string, boolean, array and multi-rule shapes. `FromString` accepts JSON when the first character is `{` or `[`, otherwise delegates YAML parsing to the sidecar. Code-first builders are the locked canonical authoring model; declarative parsing is convenience/import behavior until separately specified.

### Schema publication mismatch

`Moleculer.GetServices` creates `ServiceInfo` with a `Schema` member but never assigns `Schema` before returning it. The sidecar’s registration expects `serviceInfo.Schema`. Consequently ordinary registration can receive `undefined` schemas, catch the conversion error, and still store the publication. This is a blocking cross-process contract defect.

## Current configuration, UI, and access control

The extension declares `mol_Connections`, `mol_Publications`, and `mol_Services` catalogs; constants for namespace, logging, publication, proxy, dynamic services and test connection; functional options for proxy/dynamic services; and the `mol_Administrator` role.

| Stored object | Current fields/defaults and use |
| --- | --- |
| `mol_Connections` | Description plus `Endpoint` (string 100), `Port` (nonnegative 5-digit integer, default 5103), `UseSSL`, `AccessKey`/`SecretKey` (string 250), `Enabled`, `Timeout` (nonnegative integer, default 120). Enabled rows are sidecar routes; the predefined row is treated as `Default`. Secrets are ordinary catalog attributes, not protected storage. |
| `mol_Publications` | Description plus `Endpoint` (100), `Port` (default 5103), `UseSSL`, `Enabled`, `Path` (150), infobase-user UUID, `Password` (150), authorization enum, and optional `mol_Connections` reference. It describes how sidecar calls back into 1C and which sidecar connection receives registration. |
| `mol_Services` | Description/code plus `Version`, `Enabled`, unlimited `ServiceConstructor`; `Elements` rows (`Id`, `Name`, unlimited `Code`, element-type enum); `Metadata` rows (`Key`, boolean/string/integer `Value`). Only `ServiceConstructor` is used by the observed compiler; the visual element tables are not connected to schema compilation. |
| Constants | `mol_Namespace` string(50), `mol_LogLevel` enum, booleans `mol_PublishServices`, `mol_UseDynamicServices`, `mol_UseProxy`, and UUID `mol_TestConnection`. Runtime reads namespace/log level/test UUID; publication/dynamic/proxy settings are not consistently enforced outside UI. |
| Functional options | `mol_UseDynamicServices`, `mol_UseProxy`, each tied to its constant. They control form presentation but do not form a complete runtime capability boundary. |

Operator entrypoints are subsystem commands opening the admin configuration and service-list forms. Configuration writes constants immediately and opens connection/publication/dynamic-service lists. Connection and publication item forms provide synchronous server-side tests. Publication list commands batch-register/unregister and attach an empty status idle handler. Service list queries compiled services and sidecar `$node.services`; service item attempts granular refresh; action-call form sends arbitrary JSON through `Moleculer.Call`. Laboratory calls `$node.list` and discards the result. Error viewer, sidecar-info and user-selection common forms exist, but no coherent navigation/status/error workflow connects all of them.

The UI is not consistently wired to runtime contracts. For example, [ServiceItemForm](../../src/cfe/MoleculerSidecarConnector/DataProcessors/mol_AdminPanel/ServiceItemForm/Ext/Form/Module.bsl) calls nonexistent `mol_Broker.GetActivePublications`; [ServiceInfo](../../src/cfe/MoleculerSidecarConnector/DataProcessors/mol_AdminPanel/ServiceInfo/Ext/Form/Module.bsl) reads nonexistent `ServiceInfo.RawSchema` and calls `mol_Transit.DiscoverNodes`. `mol_UseProxy` and `mol_UseDynamicServices` drive form visibility, but evidence does not show equivalent runtime enforcement.

The single role is contradictory: it grants configuration administration, database update, exclusive mode, event log, extension administration, multiple clients and full edit rights for publications/constants, yet it does not enumerate `mol_Connections`, `mol_Services`, `mol_TestConnection`, the laboratory, or several common forms exposed by the UI. Default/derived access still requires runtime verification, but there is no comprehensible least-privilege division between sidecar runtime identity, observer, operator, dynamic-service developer, and installer administrator. Runtime startup currently may add the extension role to the current administrator and relaunch; locked target behavior moves any confirmed minimum-role self-grant into the installer.

`NoAuth` is advertised by the authorization enum and constructor, but `GetPublications` handles token and password then treats every other type as unknown. An enabled no-auth publication therefore cannot be discovered successfully through the current path.

### Monaco/editor and YAML

The bundled `CodeEditor` wrapper injects a common-template editor into managed forms; its exact Monaco version, asset provenance, supported clients, and failure path are not documented or verified. It is therefore a developer UI dependency, not a core runtime guarantee. A native text-editor fallback is absent from the observed integration.

Four parser modules (`YAML`, `YAML1`, `YAML2`, `YAML3`) are bundled. Schema parsing calls `$sidecar.utils.parseYAML` in `mol_SchemaFactory`; a separate helper calls `$sidecar.parseYAML`, which is not the observed sidecar action. The internal `YAML.ToObject` fallback following the sidecar `Return` is unreachable. Parser compatibility and error locations have no automated evidence. YAML implementation choice is intentionally deferred.

## Dynamic services and standalone operation

Static services are common modules selected by prefix and expected to implement `Constructor`. Dynamic services are enabled catalog rows whose BSL constructor text is executed by `mol_SchemaFactory`; this is privileged executable configuration and needs validation, audit/version history, rollback and dedicated rights before production use.

`Moleculer.IsStandalone()` returns whether `Catalog.mol_Services` is absent. That can describe copied common modules in a host configuration, but it cannot make the shipped extension standalone because the catalog is part of the extension metadata. Current guarded code still assumes constants and `$internal.WellKnown` assumes `Constants.mol_TestConnection`, so the standalone path is incomplete.

### Locked target direction

Create a database-free core containing the façade, option structures, broker, context/packet transport, errors, logging interfaces, helpers, schema builder and functional internal service. Keep CFE catalogs/constants/roles/functional options/HTTP metadata/forms/dynamic persistence/Monaco and the EPF out of that core. Replace the metadata-presence heuristic with an explicit `MoleculerOverridable` provider/capability contract, including configuration, connections, publications, service discovery, secrets, logging and platform capabilities. The core must use compatibility shims suitable for the required 8.2.16 compatibility-mode ordinary thick-client target.

## Contexts, errors, and abstraction quality

The separations between façade, broker, context, transport, schema and errors are a sound prototype foundation. Packet encoding, HTTP signing/failover and binary/multipart handling are centralized. However, ownership/lifetime boundaries are not complete:

- `mol_ContextFactory.Handler` pushes and normally pops its inbound context after its internal try/except. The leak is in outbound `mol_Broker.Call`, `Emit`, and `Broadcast`, which call `SetCurrentContext` after completion and never pop it. Stale mutable context can therefore be observed by later operations in the same 1C request.
- `mol_Errors.RaiseError` pushes the error then raises. `GetCurrentError` consequently relies on ambient stack state instead of a handler-scoped lifecycle.
- `GenerateStackTrace(OffsetIndex=...)` checks the supplied index but does not assign it; its module-steering parser relies on formatted/localized 1C error output. `RegenerateError` can retain a remote stack string but cannot reconstruct a native remote `ErrorInfo`, so remote and local frames still lack an explicit model.
- Public calls raise exceptions, while transport internally uses `{Error, Result}` responses. No stable reusable result type defines when errors are thrown versus returned.

The reusable-value pattern is clever but overextended. `mol_Reuse` uses session reuse for configuration, connections, publications, services, HTTP connections and regular expressions; callers receive mutable structures and cache invalidation is largely a broad `RefreshReusableValues` UI action. `mol_ReuseCalls` uses request reuse as mutable stack storage. These mechanisms save repeated discovery work, but they conflate caching with ambient execution state and make credential/configuration freshness and granular registration changes difficult to reason about.

### Pattern and maintainability assessment

- **Façade:** appropriate public boundary, but leaks `Broker()` and exposes discovery/build helpers without a stability classification.
- **Factory/builder:** schema and context factories express useful responsibilities; the builder advertises more Moleculer features than the proxy layer preserves.
- **Provider/override:** the right seam for standalone deployment, but currently an example/stub rather than a validated interface.
- **Transport strategy:** `Connection.Type` anticipates alternatives, yet dispatch is a hardcoded branch and only HTTP exists. Keep the seam but do not add transports without workload evidence.
- **Repository structure:** responsibilities are named consistently with a `mol_` prefix, but mixed English/Russian code, stale moved-source references, commented implementations and large helper/error modules reduce traceability.
- **Failure handling:** broad catches frequently log and continue where the caller requires an outcome. This is unsuitable for registration, service compilation and administrative operations.

### Locked target direction

`Call` remains throwing and `TryCall` will return `{ Success, Result, Error }`. Preserve remote type/code/message/data/retryability/remote stack separately from locally generated propagation frames. A context exists only during an inbound handler; nested calls inherit it, root calls create a new one, and cleanup is mandatory on success and failure. Stack steering needs tested frame selection plus a safe fallback when platform-format parsing fails.

## Production-readiness assessment

Overall: coherent prototype, not production-ready. Positive foundations are the compact façade, recognizable responsibilities, useful builder pattern, centralized HTTP transport, and proxy-service mapping. Blocking or high-risk findings include:

- Registration is fire-and-forget: failures are logged/suppressed, publication success has no acknowledgement, generation, desired/actual state, drift or per-service result.
- Sidecar registration can persist a publication after every service conversion failed; granular update destroys the first publication service, then fails on casing and wrapper/schema contract mismatches instead of safely recreating the requested service (see [protocol baseline](connector-sidecar-protocol.md)).
- `$internal.services` works, but most other discovery/health actions return sample strings. Lifecycle forwarding, hooks, channels, local events and local calls are incomplete or disabled.
- HTTP has no demonstrated bounded retry policy, protocol version/identity/health handshake, cancellation, stream-backpressure, request-size control, or shutdown semantics.
- Security, credentials and logging have sidecar blockers documented in the protocol baseline. No end-to-end cross-language fixtures or production runtime evidence exists.
- `mol_Transport.Send` disables safe mode before HTTP and restores it only on the success path; an exception can leave safe mode disabled for the remaining execution context.

## Required future reconciliation model

The CFE is the desired-state authority. Every publication and service needs stable identity and generation/digest; sidecar acknowledgements need to state what generation was applied. Operator UI should show `healthy`, `applying`, `drifted`, `failed`, `stale` or `unknown`, including last attempt and actionable error. Reconciliation must cover startup, sidecar restart, infobase replacement, partial registration, granular update and removal. Batch operations return per-item outcomes; they never report success solely because errors were logged.

## Supported Moleculer subset and known unknowns

No explicit compatibility matrix exists. The implemented subset is action call plus emit/broadcast packet construction, schema action/event declarations and a commented channel/lifecycle design. Unsupported Moleculer schema options must be rejected by validation instead of silently accepted. It is unknown whether packet structures, action parameter rules, streams, event acknowledgement, tracing and response metadata exactly match the target Moleculer version under representative runtime use.

Open design questions deliberately left for task refinement: safe inbound handler registry/cache invalidation after infobase replacement; evidence for a local-call fast path versus always-sidecar semantics; deployment topology and TLS termination; state-store/secret-management choice; supported web-client scope; and visual dynamic-service designer semantics. No task is created by this document.

## Evidence limits and acceptance evidence for later work

This baseline is source inspection only. It does not prove CFE compilation, infobase loading, UI behaviour, Node TypeScript compilation, sidecar startup, authentication, or end-to-end Moleculer behaviour. Later tasks require contract fixtures for JSON/multipart packets, context/error/stream fields and casing; registration/restart/drift/removal cases; nesting/error cleanup; tampering/replay/identity/secret-redaction checks; static/dynamic service validation; core compatibility checks; editor fallback; and separately recorded source, build, runtime and deployment evidence.
