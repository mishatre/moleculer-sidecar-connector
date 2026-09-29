# Standalone CFE builder

Generates a database-free variant of the `MoleculerSidecarConnector` extension.

The canonical extension is a combined runtime, persistence, administration and
developer-tool package. The generated variant contains **no constants, no catalogs,
no dynamic services and no admin panel**; all deployment settings are declared in a
single overrideable module, and the remaining common modules are merged into one
public module.

The canonical sources are never modified. Everything is written under
`build/standalone/`.

## Usage

```bash
python3 tools/standalone-builder/build-standalone.py \
  --profile tools/standalone-builder/profiles/default.json
```

Useful options:

| Option | Effect |
|---|---|
| `--profile <file.json>` | Override the built-in default profile |
| `--out-root <dir>` | Write the variant somewhere other than `build/standalone` |
| `--no-compile` | Emit the source tree without invoking the compiler |
| `--keep-tree` | Refuse to replace an existing output tree instead of deleting it |

Output:

```text
build/standalone/<variant>/
    Configuration.xml
    Languages/Русский.xml
    CommonModules/Moleculer.xml
    CommonModules/Moleculer/Ext/Module.bsl        <- all runtime code, merged
    CommonModules/MoleculerOverridable.xml
    CommonModules/MoleculerOverridable/Ext/Module.bsl  <- deployment settings
    HTTPServices/mol_Moleculer.xml
    HTTPServices/mol_Moleculer/Ext/Module.bsl
    standalone-manifest.json
build/standalone/MoleculerSidecarConnectorStandalone.cfe
```

## Profile

`profiles/default.json` is the shipped profile. Every field is optional and falls
back to the built-in defaults.

| Field | Meaning |
|---|---|
| `variant` | Output subdirectory name under the output root |
| `extensionName` | Extension name, also the artifact base name (must be one word) |
| `namePrefix` | Configuration name prefix, default `mol_` |
| `version` | Written verbatim to `<Version>`; the display form `0.2.0 beta 4` is accepted |
| `purpose` | `AddOn` or `Customization` |
| `compatibilityMode` | e.g. `Version8_3_21`; empty omits the element |
| `targetModule` | Name of the merged module, default `Moleculer` |
| `providerModule` | Name of the settings module, default `MoleculerOverridable` |
| `compile` | Whether to run the compiler (default `true`) |
| `v8version` | Platform version passed to `vrunner` |
| `settings.config` | Namespace, module prefix, log level, extension version, admin role |
| `settings.connections` | Sidecar connections written into the provider module |
| `settings.publications` | Publications written into the provider module |

A connection entry needs `id`, `endpoint` and `port`; `description`, `default`,
`useSSL`, `accessKey`, `secretKey` and `timeout` are optional. A publication entry
needs `id`, `endpoint` and `port`; `description`, `useSSL` and `path` are optional.

## What the generator does

1. **Strips.** Administration and role bootstrap (`mol_Server`, `mol_Client`,
   `MoleculerClientServer`, the application-module hooks), the Monaco editor wrapper
   (`CodeEditor*` plus its template) and the unused local YAML parsers
   (`YAML`, `YAML1`–`YAML3`) are left out, together with every catalog, constant,
   enum, functional option, form, data processor, role, subsystem and style.
2. **Merges.** `Moleculer`, `mol_Errors`, `mol_Logger`, `mol_Helpers`,
   `mol_HelpersClientServer`, `mol_Reuse`, `mol_ReuseCalls`, `mol_Transport`,
   `mol_ContextFactory`, `mol_Broker`, `mol_SchemaFactory` and `mol_Internal` are
   folded into the target module.
3. **Renames.** Symbol names defined in more than one module are renamed in the
   non-owning module. BSL identifiers are case-insensitive, so the list was derived
   from a case-insensitive scan. The owner keeps the original name.
4. **Rewrites.** `Module.Symbol` becomes a local call, and a bare `Module` reference
   becomes the merged module, so `Metadata.CommonModules.mol_Broker` correctly
   becomes `Metadata.CommonModules.Moleculer`.
5. **Patches.** A short, explicit list of transforms for facts a textual merge cannot
   infer: the internal service is compiled from the merged module; the request-scoped
   cache stack is reset when a request arrives; the two `ReturnValuesReuse` caches
   become explicit module variables; the local YAML call and the unguarded
   test-connection constant are removed; developer-facing guidance names
   `Moleculer.Broker()`.
6. **Validates.** Static checks that stand in for the unavailable BSL syntax check:
   no duplicate definitions, no reference to a removed module, balanced
   `Procedure`/`Function` blocks.
7. **Emits and compiles** the tree with `vrunner cfe compile --ibcmd`.

Text rewriting is aware of BSL string literals, `""` escapes, `//` comments and
`#Region`-style preprocessor directives, so identifiers inside them are never
touched.

## Verification

Container-only suite (no 1C platform needed):

```bash
python3 -m unittest discover -s tests/standalone-builder -t tests/standalone-builder
```

End-to-end, using the verified headless commands:

```bash
vrunner cfe compile --src build/standalone/default \
  --extension-name MoleculerSidecarConnectorStandalone \
  --ibcmd --v8version 8.3 build/standalone/MoleculerSidecarConnectorStandalone.cfe

vrunner infobase init --src src/cf \
  --ext build/standalone/MoleculerSidecarConnectorStandalone.cfe \
  --ibconnection /Fbuild/ib-standalone --ibcmd --v8version 8.3

ibcmd config check --db-path=build/ib-standalone \
  --extension=MoleculerSidecarConnectorStandalone
```

The last command is the strongest check available in this container without a 1C
client.

## Using the artifact

Two routes, both documented for the consumer:

- **Install as an extension.** Load the `.cfe` into the target infobase when its
  compatibility mode accepts the chosen `compatibilityMode`. The variant contains
  only common modules and one HTTP service.
- **Move the modules by hand.** Copy `Moleculer` and `MoleculerOverridable` from
  `CommonModules/` into the host configuration, then recreate the HTTP service
  `mol_Moleculer` with root URL `moleculer`, template `/sidecar`, method `POST` and
  handler `GatewayPOST`.

Edit `MoleculerOverridable` to change connections and publications; it is plain BSL
and needs no rebuild of the merged module.

## Known limitations

- **BSL syntax is not verified by the platform.** The container's 1C client cannot
  start (missing `libwebkit2gtk-4.0`, `libjavascriptcoregtk-4.0`, `libsoup-2.4`), so
  neither the designer module check nor any test runner can run. The generator
  therefore relies on its own static checks plus the platform's metadata check.
  Loading does not compile module bodies, so a syntax error would only appear at
  runtime.
- **Runtime behaviour is unverified.** No action call or HTTP round-trip has been
  exercised. See `docs/plan/tasks/T021-standalone-runtime-verification.md`.
- **Client contexts are dropped.** The canonical `Moleculer` module is also
  available to thin clients; the variant's merged module is server-only because the
  merged code uses server APIs.
- **`ReturnValuesReuse` is reimplemented.** The two caches are now module variables.
  The request-scoped stack is cleared when an inbound request is handled; the HTTP
  connection cache is session-scoped.
- **Dead guarded code is retained.** `Moleculer.GetConfig`/`GetConnections`/
  `GetPublications` still contain their `If Not IsStandalone()` branches. They can
  never execute in the variant (there is no `Catalog.mol_Services`), but they keep
  the module usable in both modes. The manifest lists them under `observations`.
- **The provider is a starting point.** `settings.connections` and
  `settings.publications` default to empty, so a freshly generated variant has no
  sidecar route until the profile or the provider module is filled in.
