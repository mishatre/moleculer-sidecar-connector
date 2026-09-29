# Viability of a native YAML parser module

Status: analysis, no implementation authorised
Triggered by: a request to consider a native API module for an internal YAML parser,
judged on speed, testing value, sidecar mitigation and build-config guarding.

Short answer: **not viable as framed.** The platform has no YAML API at all, the
external-component route is blocked by the connector's own safe-mode window plus
delivery and ABI costs, and a BSL parser contradicts a decision the owner already
recorded. The three goals behind the request are reachable more cheaply, and one
of them is already met by the JSON branch that exists today.

## What was checked

| Claim | Evidence |
|---|---|
| The platform has no native YAML | `YAML` appears nowhere in `bslGlobals.json` (443 globals, 59 classes, 616 enums, keywords, structure menu) |
| `ЧтениеДанных`/`ЗаписьДанных` are not format parsers | 47 and 32 methods respectively, all stream primitives: `ПрочитатьБайт`, `ПрочитатьСтроку`, `ПрочитатьЦелые16/32/64`, `ПрочитатьВБуферДвоичныхДанных`, `Пропустить`, `РазделитьНаЧастиПо`, plus `...Асинх` variants. No `ПрочитатьYAML`, no `ПрочитатьJSON` |
| YAML is one call site, not a subsystem | `mol_SchemaFactory.ParseServiceDefinition` → `Moleculer.Call("$sidecar.utils.parseYAML", Params)`. `mol_Helpers.FromYAMLString` → `$sidecar.parseYAML` has **zero callers** |
| Nothing inside the connector reads YAML | `mol_SchemaFactory.FromString` has no caller in `src/`; it is a public authoring/import API plus a possible body for `Catalog.mol_Services.ServiceConstructor` |
| JSON already works offline | `ParseServiceDefinition` returns `mol_Helpers.FromJSONString(Text)` when the text starts with `{` or `[` |
| A BSL parser existed and was deleted | T024 removed `YAML`, `YAML1`, `YAML2`, `YAML3`: ~3,500 lines, all unreachable |
| Safe mode forbids external components | `УстановитьБезопасныйРежим`: "В безопасном режиме: … запрещены … загрузка и подключение внешних компонентов" |
| Schema compilation runs under safe mode | `mol_SchemaFactory.CompileServiceSchema` does `SetSafeMode(True)` → executes the module's `Constructor` → `SetSafeMode(False)` |
| Parsing is a startup cost | `FromString` is reached from `CompileServiceSchema`, i.e. once per service construction, not per request |

Two tests were added to pin the dependency rather than argue from reading:
`mol_SchemaFactoryTests.FromStringRejectsANonString` and
`FromStringNeedsTheSidecarForAnythingThatIsNotJSON`. Both pass without a sidecar
connected, which is the point: the JSON branch needs nothing, the YAML branch
cannot run at all. Canonical suite: 56/56.

## The three goals, assessed

### 1. Speed — the premise does not hold

Schema text is parsed when a service is constructed. Even a slow parser costs
startup once per service, and a service definition is a few kilobytes. A native
parser would not move request latency at all.

What the sidecar call really costs is different: it is a **cross-process
dependency at construction time**, so a service cannot be defined if the sidecar
is unreachable. That is an availability and diagnosability problem, not a
throughput one — and it is worth fixing on its own terms, with JSON or a clear
error, rather than with a parser written in C.

### 2. Testing — real, but already solvable without a parser

The untestable sliver is narrow and was measured: `CompileServiceSchema` is fully
testable with no sidecar (12 tests), and the code-first authoring surface
(`Action`, `Event`, `Channel`, `Type*`) is testable too. Only "YAML text to
object" is out of reach.

Two existing facts shrink that sliver further:

- `ParseServiceDefinition` already parses **JSON** natively for text starting
  with `{` or `[`, so an offline, testable declarative format exists today.
- `docs/plan/connector-architecture-audit.md` records the canonical authoring
  model: "Code-first builders are the locked canonical authoring model;
  declarative parsing is convenience/import behavior until separately specified."

So a native parser would buy coverage of a convenience path that the project has
already decided is not canonical.

### 3. Sidecar dependency — the gain is much smaller than it looks

The connector calls eight internal sidecar actions: `$sidecar.utils.parseYAML`,
`$sidecar.parseYAML`, `$sidecar.register`, `$sidecar.unregister`,
`$sidecar.updateService`, `$sidecar.callLocalNode`, `$node.services`, `$node.list`.

YAML is two of the eight, and one of those two is dead code. The other six are
broker protocol: registering services, unregistering them, calling a local node.
**No parser change removes any of them.** Replacing YAML parsing does not reduce
sidecar dependence in any meaningful sense; it only makes *declarative* service
definitions work offline.

## Why the external-component route fails

This is the interpretation the request pointed at — a Native API (AddIn)
component, viable only in a full CFE publication, with a compatibility penalty.
Three separate problems, in ascending order of severity:

1. **Delivery.** A CFE carries metadata objects, not process binaries. A `.so`/`.dll`
   would need a separate install step and a version pairing between connector and
   component build.
2. **ABI.** The binary is per operating system, per architecture and tied to the
   platform build it was compiled against. The connector currently ships one CFE
   that works wherever the extension loads.
3. **Safe mode — this one is fatal for the primary path.** `CompileServiceSchema`
   turns safe mode **on** around the service constructor, and safe mode explicitly
   forbids *loading and connecting* external components. `FromString`, the only
   YAML entry point, is reached from that constructor. The connector would be
   forbidding the very thing the parser needs.

   Attaching the component earlier, outside the window, and only *calling* it
   inside is the one escape route, and it is unverified. It would add a lifecycle
   dependency (attach at broker start, handle absence, cope with reconnect) and a
   new failure mode, to speed up a startup-only parse. That is a bad trade even if
   it works.

For the testing goal an AddIn is actively counterproductive: it makes the harness
depend on a binary that must be installed per machine, which is the opposite of
the current container-only, no-licence-needed test story.

## What the recorded owner decision already says

`refactor-backlog.md`, T024: *"the owner confirms YAML is validated and converted
on the Node side on purpose."* The sidecar dependency for YAML is deliberate, and
the BSL parsers were removed as part of that decision, one task ago. Re-opening it
needs a reason that did not exist when it was made. The analysis above does not
supply one; it weakens the case instead.

## Recommendation

Do not build a parser. Take the cheap steps that capture the real benefits:

1. **Document JSON as the offline and test-authoring format.** It is native, it
   needs no sidecar, and it is already testable. This covers the testing goal
   with zero new code.
2. **Stop misdiagnosing the failure.** The `Try` around `ParseServiceDefinition`
   converts a transport failure into "TextDefinition should contain valid YAML or
   JSON", blaming the caller's text for a missing parser. Belongs to the error
   taxonomy work (T023); the new test deliberately asserts only the raise, so the
   message is free to change.
3. **If a consumer needs offline YAML specifically, let it inject one.** The
   project already has the two guard mechanisms the request asks for:
   `providerModule: MoleculerOverridable` for a runtime-selected parser, and the
   standalone builder's `patches` for a build-config choice — and a patch that
   stops matching raises `BuildError` rather than silently doing nothing. That
   gives config/build-config guarding without the connector owning thousands of
   lines of YAML.

## What would change this verdict

- The platform gains a native YAML reader. Re-open immediately; the whole
  compatibility discussion then becomes a version-floor question, and the
  `compatibilityMode` field in the builder profile is the place to express it.
- A consumer requires offline YAML and cannot use JSON, and injection through the
  overridable module proves insufficient.
- Attaching a component outside the safe-mode window is shown to work **and** the
  parse is shown to be a measured bottleneck. Both would have to hold.
