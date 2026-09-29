# Viability of a native YAML parser module

Status: analysis, revised after owner review; no implementation authorised yet
Triggered by: a request to consider a native API module for an internal YAML parser,
judged on speed, testing value, sidecar mitigation and build-config guarding.

Short answer, revised after review: **the requirement is legitimate and the
external-component route is workable.** The platform has no YAML API, so a parser is
either BSL or a compiled Native API component. Native components are first-class on
the platform, and the platform's own loader accepts a **configuration template** as
the component location, so a single CFE can carry the binary. Two claims in the
first draft were wrong; they are corrected under "External components: revised
assessment". The requirement that forced the revision is recorded next.

## Requirement

Stated by the owner during review, and the thing this document has to serve:

> this project should be able to process service constructors without any available
> sidecar node connected

Stated as the consequence of not having it:

- sidecar node available: YAML + JSON + internal builder;
- sidecar node unavailable: JSON + internal builder.

and therefore a constructor written in YAML cannot use YAML for any purpose when no
sidecar is up — not parsing, not conversion (YAML -> JSON, YAML -> builder), and not
the reverse.

## What was checked

| Claim | Evidence |
|---|---|
| The platform has no native YAML | `YAML` appears nowhere in `bslGlobals.json` (443 globals, 59 classes, 616 enums, keywords, structure menu) |
| `ЧтениеДанных`/`ЗаписьДанных` are not format parsers | 47 and 32 methods respectively, all stream primitives: `ПрочитатьБайт`, `ПрочитатьСтроку`, `ПрочитатьЦелые16/32/64`, `ПрочитатьВБуферДвоичныхДанных`, `Пропустить`, `РазделитьНаЧастиПо`, plus `...Асинх` variants. No `ПрочитатьYAML`, no `ПрочитатьJSON` |
| YAML is one call site, not a subsystem | `mol_SchemaFactory.ParseServiceDefinition` → `Moleculer.Call("$sidecar.utils.parseYAML", Params)`. `mol_Helpers.FromYAMLString` → `$sidecar.parseYAML` has **zero callers** |
| Nothing inside the connector reads YAML | `mol_SchemaFactory.FromString` has no caller in `src/`; it is a public authoring/import API plus a possible body for `Catalog.mol_Services.ServiceConstructor` |
| JSON already works offline | `ParseServiceDefinition` returns `mol_Helpers.FromJSONString(Text)` when the text starts with `{` or `[` |
| A BSL parser existed and was deleted | T024 removed `YAML`, `YAML1`, `YAML2`, `YAML3`: ~3,500 lines, all unreachable |
| Safe mode forbids **loading and connecting** external components | `УстановитьБезопасныйРежим`: "В безопасном режиме: … запрещены … загрузка и подключение внешних компонентов". It lists COM separately as "операции с COM-объектами", so *using* a connected component is not among the listed restrictions |
| Safe mode does **not** restrict local computation | `mol_SchemaFactoryTests.ASafeModeWindowDoesNotBlockLocalParsing`: `mol_Helpers.FromJSONString` parses correctly with `БезопасныйРежим()` reporting `Истина` |
| Native API is a first-class component kind | `ТипВнешнейКомпоненты` (`AddInType`) has exactly `COM` and `Native`, the latter documented as "Компонент, реализованный с использованием Native API" |
| The loader accepts a configuration template | `ПодключитьВнешнююКомпоненту`: `Местоположение` may be "полное имя макета, хранящего двоичные данные или ZIP-архив", a URL, or a file path (the file path alone is marked "недоступно на веб-клиенте") |
| A component cannot be a declared metadata object | the designer schemas this project already uses (`v8.1c.ru-8.3-MDClasses.xsd`) define no `AddIn` type; `AddInCallUseMode` belongs to the configuration's synchronous-call compatibility mode, not to a component declaration |
| Schema compilation runs under safe mode | `mol_SchemaFactory.CompileServiceSchema` does `SetSafeMode(True)` → executes the module's `Constructor` → `SetSafeMode(False)` |
| Unsafe to "just switch safe mode off" inside the parser | `УстановитьБезопасныйРежим` is accounted per procedure: calling it with `Ложь` in a procedure that did not enable it raises |
| Parsing is a startup cost | `FromString` is reached from `CompileServiceSchema`, i.e. once per service construction, not per request |

Two tests were added to pin the dependency rather than argue from reading:
`mol_SchemaFactoryTests.FromStringRejectsANonString` and
`FromStringNeedsTheSidecarForAnythingThatIsNotJSON`. Both pass without a sidecar
connected, which is the point: the JSON branch needs nothing, the YAML branch
cannot run at all. Two more settle the safe-mode question by measurement rather than
assertion: `TheSafeModeWindowIsReal` and `ASafeModeWindowDoesNotBlockLocalParsing`.
Canonical suite: 58/58.

## The three goals, assessed

### 1. Speed — the premise does not hold

Schema text is parsed when a service is constructed. Even a slow parser costs
startup once per service, and a service definition is a few kilobytes. A native
parser would not move request latency at all.

What the sidecar call really costs is different: it is a **cross-process
dependency at construction time**, so a service cannot be defined if the sidecar
is unreachable. That is an availability and diagnosability problem, not a
throughput one. The speed argument therefore does not justify a parser, but the
availability argument does, which is why this document now turns on the requirement
rather than on performance — with one exception: if the parser runs on every call
rather than at construction, speed becomes a real criterion and the Native route
wins.

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

So the coverage argument alone would not justify a parser — but the requirement above
does, and the parser then pays for itself twice: it restores the missing capability
and it turns `FromString` from the one public entry point no suite can reach into an
ordinary one.

### 3. Sidecar dependency — the first draft measured the wrong thing

The first draft argued that YAML is only two of eight internal sidecar calls, so the
dependency barely shrinks. That counts calls and misses the requirement: the problem
is not how many calls, it is **which capability exists locally**.

- sidecar connected: YAML + JSON + the internal builder;
- sidecar absent: JSON + the internal builder only.

A service whose constructor is written in YAML therefore compiles only while a
sidecar happens to be up, and a dynamic-service constructor stored in
`Catalog.mol_Services.ServiceConstructor` cannot use YAML at all — not even to
convert YAML into something else — regardless of what it is trying to do locally.
That is a capability split inside a single constructor, and it is worse than a
dependency on the broker: a local computation is made to wait for a remote process.

The call count is still worth knowing for a different reason: the six broker calls
mean the connector cannot function without a sidecar anyway. The goal is therefore
not "remove the sidecar" but "stop making local work wait for it", which is what
makes the requirement as narrow and as reasonable as it is.

## External components: revised assessment

The first draft called this route fatal. That was wrong in two places, and the
corrections matter because they invert the conclusion.

**Native API is a first-class kind, not a Windows workaround.**
`ТипВнешнейКомпоненты` (`AddInType`) has exactly two values, `COM` and `Native`, and
`ПодключитьВнешнююКомпоненту` takes the kind as an optional third parameter. A Rust
or C++ component is an explicitly supported thing.

**Delivery inside one CFE is supported** — this is where the first draft was
plainly wrong. `ПодключитьВнешнююКомпоненту(Местоположение, Имя, Тип?)` documents
`Местоположение` as any of:

- a path in the file system — explicitly marked "недоступно на веб-клиенте";
- **"полное имя макета, хранящего двоичные данные или ZIP-архив"**;
- a URL to the component as binary data or a ZIP archive.

A template is a metadata object an extension can carry, so the binary ships inside
the extension and no separate install step is needed. "A CFE carries metadata, not
process binaries" had it backwards: the platform's own loader names the template
form as a supported location, and it is the form that works where a file path does
not.

**Server side — the direct answer to the fear that it cannot work there.** The API
is server-centric rather than client-oriented: `УстановитьВнешнююКомпоненту`
"доставляет объект внешнего компонента **с сервера на клиент**", so the server holds
the component and is the party that supplies it. The template-based loader is
exactly the form that does not depend on a local file system, which is what
server-side and web-client contexts need.

One limit worth recording: the component cannot be a *declared* metadata object.
The designer schemas this project already uses define no `AddIn` metadata type, so a
Native component can only arrive as a template plus a runtime connect call.

**Safe mode is a placement constraint, not a blocker.** Safe mode forbids loading and
connecting external components. It does not list *using* a connected component, and it
lists COM separately as "операции с COM-объектами", which suggests the two are not the
same restriction. Connecting once during connector start-up, outside any safe-mode
window, and calling the parser from inside it is the design that fits.

What does **not** work is the obvious shortcut: `FromString` cannot switch safe mode
off for itself. `УстановитьБезопасныйРежим` is accounted for per procedure, so calling
it with `Ложь` in a procedure that did not enable it raises. The window has to be
placed correctly instead — and for a BSL parser the question never arises, because
safe mode does not restrict local computation (measured; see the table above).

**Remaining unknowns**, both requiring a real component to settle:

1. Whether *calling* an already-connected Native component inside a safe-mode window
   is permitted. The documentation implies yes; nothing in this container can prove
   it.
2. Whether the Native API SDK and per-platform builds can be produced at all here.
   The container has no Native API headers or libraries.

## The recorded owner decision, revisited

`refactor-backlog.md`, T024 records: *"the owner confirms YAML is validated and
converted on the Node side on purpose."* The four BSL parser modules were deleted on
the strength of that decision, one task before this analysis.

That decision is now being revisited **by the owner, deliberately**, for a reason that
did not exist when it was made: constructors must compile with no sidecar connected,
and a constructor written in YAML currently cannot. This document exists to price the
reversal rather than to defend the earlier note.

## Recommendation

Two implementations satisfy the requirement. Choose on toolchain cost rather than on
capability, because both can do the job.

| | BSL parser | Native component (Rust/C++) |
|---|---|---|
| Ships inside the CFE | yes, as source | yes, as a binary template plus a connect call |
| Safe mode | unaffected, safe mode does not restrict local computation | must be connected outside the window; calling inside is unverified |
| Toolchain available in this container | none needed | **none** — no Native API SDK, so nothing can be built or tested here |
| Per-platform artifacts | one | Linux x86-64 and Windows x86-64 at minimum, ABI-bound to the platform build |
| Testable in the existing harness | yes, today | only after each binary is built |
| Speed | slower, at start-up only | faster, at start-up only |

A BSL parser is the lower-risk way to meet the requirement, and the safe-mode
experiment removes the objection that made the first draft doubt it. A Native
component is faster and is the better answer if the parser must handle full YAML or
large documents, but it cannot be built or verified in this container as things
stand.

Either way, the shape should be the same:

1. **One parser for every caller, chosen in one place.** Prefer local and fall back to
   the sidecar, or the reverse — that order is an owner choice, but it must be one
   order rather than two capability sets that depend on connectivity.
2. **Guard it the way the project already guards variants.** `providerModule:
   MoleculerOverridable` for the runtime choice, and the builder profile's `patches`
   for the build-config choice; a stale patch already raises `BuildError` instead of
   silently doing nothing.
3. **Cover the conversions the requirement names**, not just parsing: YAML -> object,
   YAML -> JSON, object -> YAML. The requirement is about a constructor being able to
   use YAML for any local purpose, not only to read a definition.
4. **Keep the parser scope honest.** Service definitions need mappings, sequences and
   scalars. Anchors, tags, multiple documents and complex keys are not needed by
   anything in `src/`, and excluding them keeps a BSL implementation testable.

## Open questions before implementation

- If the Native route is chosen, confirm that calling a connected component inside a
  safe-mode window is permitted. This is the one blocking unknown and it needs a real
  component binary.
- Choose the fallback order: local parser first, or sidecar first. The requirement is
  met either way; the difference is which parser production runs actually exercise.
- Confirm the YAML subset the connector must accept, so the parser is bounded by a
  specification rather than by whatever its author thought of.

## What would change this back

- A consumer needs full YAML (anchors, tags, multiple documents) rather than the
  service-definition subset, which argues for the Native route over a bounded BSL one.
- Measurement shows the start-up parse is a real cost rather than a once-per-service
  rounding error.
- The platform gains a native YAML reader, which makes both options unnecessary; the
  version floor then belongs in the builder profile's `compatibilityMode` field.
