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

## Measured: the vendored Native component (2026-09-29)

`vendor/YamlParserNative/` holds it: `YamlParserNative.zip` (`manifest.xml`,
`YamlParser_linux_x86_64.so`, `YamlParser_win_x86_64.dll`), a ready-made extension
`YamlParser.cfe` carrying the module and the archive as a binary template, and the module
source `yp_YAML.bsl`. The archive is a **ZIP**, which matters: `ПодключитьВнешнююКомпоненту`
reads the manifest out of a template that holds a ZIP and picks the library for the OS and
architecture, so the shipped form is the one the platform expects rather than an accident.

### It works on this platform

`tests/bsl/run-tests.sh` now loads the vendored extension in canonical mode, and
`tests/bsl/canonical/CommonModules/yp_YAMLTests` calls it across extensions the way a
consumer would. Canonical suite: **68/68**. The Linux library loads, `ВерсияКомпоненты()`
reports `0.1.0`, mappings/sequences/scalars/booleans arrive as platform values, an
unparsable document raises naming the line, and `duplicateKeys=error` rejects a duplicate
instead of silently letting the last one win.

### Timing

Component 0.1.0, 100 iterations of a 247-byte document — the size and shape a real service
definition has — measured over **three consecutive runs**:

| Measurement | Total, three runs | Per call |
|---|---|---|
| First call of a session (library load) | 3, 8, 3 ms | 3–8 ms, once per session |
| Reused instance: `РазобратьYAML(Текст, "")` | 6, 6, 6 ms | **0.06 ms** |
| `ПодключитьКомпоненту().РазобратьYAML(...)` | 262, 244, 237 ms | 2.37–2.62 ms |
| `yp_YAML.РазобратьYAML(Текст)` — what a caller uses | 258, 238, 271 ms | 2.38–2.71 ms |
| Platform JSON read of the same answer | 1, 2, 1 ms | 0.01–0.02 ms |

The reused-instance figure is the same millisecond in all three runs, which is what makes it
usable: the parse itself is **0.06 ms**, and the 2.4–2.6 ms a caller pays is the reconnect.
The first numbers published here (0.03–0.1 ms per parse, 2.3–4.2 ms per reconnect) came from a
single 30-iteration run and were noise around the same values.

**The rebuild did move the connect — and only the connect.** A first answer here said the rebuild
"did not move the timings". That was wrong, and it was an artefact of the measurement: two
sessions rather than one, one order, and a ±0.5 ms spread in per-call figures against a ~0.3 ms
effect.

Measured properly — both builds loaded from file paths **in one session**, each order measured so a
first-versus-second effect could not be mistaken for a size effect, 30 connects per figure:

| Build | Bytes | Connect ×30 | Per connect |
|---|---|---|---|
| Before rebuild | 732 832 | 67/64, 70/74 ms | ≈ 2.2–2.4 ms |
| After rebuild | 612 264 | 58/59, 64/63 ms | ≈ 1.9–2.1 ms |
| Raw file read (control) | — | 3 ms / 2 ms | 0.10 → 0.07 ms |

So the effect is real and roughly proportional: **16% smaller library, 11–12% faster connect**
(≈0.25 ms per connect). The size reduction is worth having; the first answer was wrong to write
it off.

It remains true that connecting dominates the per-call cost and that the parse is not the cost:
0.06 ms of work sitting behind ~2 ms of connecting. Both statements hold at once. What the size
work buys is a slightly cheaper reconnect — not the main lever. The main lever is holding the
connection instead of reconnecting: 2.4 ms per call becomes 0.06 ms.

One caveat on the production figure: the module loads from a **template** in an infobase, not from
a file path, and the archive shrank 13% as well (1 037 332 → 897 980). That path was not measured
here, so the real gain may be a little larger than the numbers above.

Read plainly: the component is **fast enough held, and fast enough not held**, because
parsing happens once per service at construction rather than per request. What the numbers
rule out is the *per-call reconnect* if a parser is ever put on a hot path.

### The blocker, demonstrated in this project's own terms

The component refuses to connect while safe mode is on, and `CompileServiceSchema` wraps the
service constructor in `SetSafeMode(True)`. So `FromString` cannot reach the component as the
connector stands. `yp_YAMLTests.ItRefusesToRunInsideASafeModeWindow` builds that exact window
and pins the refusal, and the module's own guidance names the fix: connect before entering the
window and hand the connected instance to the code running inside it.

That fix is small but it is not free, because the module's public functions connect for
themselves. A connector that wants the component must either call the component directly with
an instance it holds, or arrange for `CompileServiceSchema` not to hold safe mode across the
constructor. The second option changes the sandboxing of every service constructor, so it is
an owner decision rather than a detail.

### Third build, and a correction to the paragraph above

A third build arrived, aggressively optimised: **255 240 bytes**, 58% smaller than the 612 264 one
and 65% smaller than the original. It does not support the conclusion above.

Same code path as the comparison above (the module connects through the extension's template),
four runs of 100 iterations of the same document:

| Build | Bytes | Reused instance | Component call | Module call |
|---|---|---|---|---|
| 612 264 (previous) | 612 264 | 6, 6, 6 ms | 262, 244, 237 ms | 258, 238, 271 ms |
| 255 240 (this one) | 255 240 | 12, 7, 8, 7 ms | 281, 275, 247, 232 ms | 254, 261, 288, 264 ms |

Per call that is a parse of 0.07–0.12 ms against 0.06 ms, and a connect of 2.3–2.8 ms against
2.4–2.6 ms. **Halving the library again changed nothing measurable.**

So "connect tracks library size" was over-extrapolated from two points, and this third one does not
confirm it. The controlled file-path comparison that produced it also cannot be repeated now: with
this build **every file-path connect is refused**, for relative and for absolute paths alike, while
the same absolute paths connected fine in the earlier session. Until that refusal is understood,
treat "a smaller library loads faster" as **unsupported** rather than established. The refusal is
reported by the probe rather than raised, so it can no longer take the parse measurement down with
it.

What does survive, and is now measured across three builds: connecting dominates the per-call cost
at ~2.5 ms against ~0.07 ms of parsing, and that ratio is insensitive to the library's size. The
lever is holding the connection, not shrinking the binary.

**Connecting is not cached by the platform.** There is a one-time cost of 2–5 ms and then a steady
~2.5 ms on every connect, whether the library is 255 KB or 733 KB. Holding the instance instead
collapses the same work to 0.06–0.12 ms per parse. `yp_YAML` cannot hold it, because an extension
common module cannot declare module variables — so a caller that wants the cached form has to
connect once and keep the instance itself.

## Recipe to integrate it

1. Add a common module `yp_YAML` to the connector extension and a binary template holding
   `YamlParserNative.zip` verbatim (the archive is not unpacked by hand; the platform reads
   the manifest inside it).
2. Connect once per session outside any safe-mode window, and pass the instance to whatever
   parses text; do not call the public functions from inside a safe-mode window.
3. Route `mol_SchemaFactory.ParseServiceDefinition` through the local parser first, with the
   sidecar as the fallback, so the capability no longer depends on connectivity.
4. Keep the guard mechanisms: `MoleculerOverridable` for the runtime choice, the builder
   profile's `patches` for the build-config choice.

Limits to carry into the delivery notes: platform 8.3.24+, x86_64, Linux and Windows only,
**no macOS**; server-side only (web and mobile clients cannot load a Native API component);
the Windows library has never been executed, only checked for exported entry points; merging
keys (`<<`) are not expanded; and reading is supported, not writing.

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
