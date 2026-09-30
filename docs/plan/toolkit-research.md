# Toolkit research — building and verifying 1C/BSL extensions

Status: research notes, 2026-09-29. Written for T014/T015/T016. Repository facts
were read from the project pages; only the items marked *verified locally* were
exercised in this container.

## Why this exists

Two gaps shaped the standalone-builder work:

1. The merged BSL module cannot be compiled or executed here (no 1C client), so the
   generator relies on its own static checks.
2. The symbol scanner in `tools/standalone-builder/build-standalone.py` is a
   regex-based scanner; a real parser would make the merge provably correct instead
   of heuristically correct.

Both gaps have mature community tools.

## Container repackaging tools (CF / CFE / CFU / EPF / ERF)

`*.cf`, `*.cfe`, `*.cfu`, `*.epf` and `*.erf` are all the **same container family**.
Understanding this is what makes "CFE → EPF" or "CFE → CF" conversion tractable, and
it is why the builder can generate a source tree instead of hand-editing a binary.

How the format works, from the `pfCFTools` documentation:

- A container holds several files with **no hierarchy**; hierarchy is obtained by
  nesting containers inside containers.
- CF/CFE and EPF/ERF additionally store objects **deflate-compressed**.
- CFU update files compress the **whole container** instead of the objects, so
  inflating one yields an ordinary CF.
- A newer container format lifted the original 2 GB limit and usually (not always)
  carries a "stub" — a nearly empty container in the old format.

Consequence: converting between these kinds is **repacking plus a root-metadata
edit**, not a format translation.

| Tool | Notes |
|---|---|
| `pasha1st/pfCFTools` | Pascal (Free Pascal 3.0.2+), 29 stars, built for Win32/64 and Linux/macOS. A V8Unpack analogue. Commands: `list`, `unpack`, `pack`, `test`, `compare`, `convert`, `inflate`, `deflate`, `cfuinfo`, `cfupdate`. Options include `-d <dir>`, `-r` (nested containers as subdirectories), `-c raw\|deflate\|auto`, `-cv`/`-cnv` (input/output container format: auto/classic/new), `-stub`/`-nostub`, and DOS or regex name masks. |
| `e8tools/v8unpack` | The reference unpack/repack tool for `*.cf`, `*.epf`, `*.erf` (95 stars, MPL-2.0, C++, GCC port of `leoniv/v8unpack`; originally by Denis Demidov). |
| `e8tools/e8unpack` | GCC port of the above. |
| `e8tools/V8Unpack.NET` | .NET library for the same container format, for embedding in tooling. |
| `e8tools/v8unpack-rs` | Rust implementation (MIT): "unpack, pack, deflate and inflate 1C v8 file". |
| `e8tools/tool1cd` | 150 stars, GPL-3.0, C++. Database (`1CD`) files rather than containers; the gitsync plugin of the same name uses it. |
| `AlexGroovy/1c-configuration-converter` | MIT, 1C external data processor. Converts a configuration XML dump into an extension XML dump **by rewriting the root `Configuration.xml` only** — "состав объектов трогать не обязательно". The inverse direction of what this project does. |
| `oscript_modules/v8unpack` (local) | *Verified locally*: present, but it is a thin wrapper around `v8unpack.dll` plus components, not an OneScript port — `lib.config` is empty and there is no `src/`. |
| `oscript_modules/v8storage` (local) | *Verified locally*: OneScript classes for the configuration storage; used by `gitsync`. |

### What the inverse converter says about the traps

`AlexGroovy/1c-configuration-converter` documents exactly the failures encountered
while building the standalone variant here:

- The root `Configuration.xml` is the only thing that has to change; the object set
  does not.
- **A language declared in the root breaks the load.** "Язык из корня конфигурации не
  переносится. В корне почти всегда указан «Русский». Загрузка при таком сценарии
  сразу упадёт с ошибкой." This is the same failure the builder hit, and the reason
  objects that exist in the extended configuration must declare
  `ObjectBelonging=Adopted`.
- The compatibility mode usually still needs adjusting after conversion.
- "Расширение как механизм платформы отстаёт от возможностей конфигурации" —
  properties that do not exist in the extension model are silently dropped on
  conversion.

### Saby / SBIS

No public Saby tooling for this was found. The `saby` GitHub organisation has 30
repositories and none relate to 1C containers (they are Wasaby/JS/Python/Android).
The likely candidate for what they ship internally is the `pfCFTools` / `v8unpack`
family, or an in-house tool built on the same container format described above. This
is recorded as **not confirmed** rather than assumed.

### Relevance to this project

The builder does **not** need any of these tools today: `vrunner cfe compile` and
`vrunner cfe decompile` already move between a source tree and a `.cfe` through a
temporary infobase, and both are verified here. They become relevant only if a future
requirement needs to edit a container byte-for-byte — for example emitting an `.epf`
beside the `.cfe`, or producing a variant without invoking the platform at all, which
would also remove the 1C licence requirement from the build.

## Parsing and static analysis

### `1c-syntax/bsl-language-server`

**Adopted 2026-09-29 as the project's BSL syntax and diagnostics gate.**

- Language Server Protocol implementation for BSL (1C and OneScript). Java.
- Latest release `v1.0.7`. GPL-3.0 family; ~485 stars, 148 releases.
- *Verified locally*: the VS Code extension `1c-syntax.language-1c-bsl` 2.1.1 is
  installed in this workspace and has already downloaded the server to
  `/root/.vscode-server/data/User/globalStorage/1c-syntax.language-1c-bsl/bsl-language-server/v1.0.7/bsl-language-server/`.
- The executable jar is present:
  `lib/app/bsl-language-server-1.0.7-exec.jar`.
- A `lib/runtime/` jlink image directory is shipped, but it contains no `bin/java`
  in the layout present here, so a JRE is installed separately
  (`openjdk-21-jre-headless`).

Working command:

```bash
java -jar <path>/bsl-language-server-1.0.7-exec.jar \
  analyze -s <source-dir> -o <report-dir> -r json -q
```

**Why it matters:** it needs no 1C licence, so it verifies BSL that the platform
cannot. It found a defect the platform's own `cfe compile` and `config check` both
missed: the generator had replaced `ReturnValuesReuse` with module variables, and
the platform does not allow module variables in a common module. The compiler loads
the metadata without compiling module bodies, so only a real parser catches this.

Measured on the generated standalone variant versus the canonical sources:

| Error code | Canonical | Variant |
|---|---|---|
| `FunctionShouldHaveReturn` | 41 | 8 |
| `CommonModuleInvalidType` | 18 | 4 |
| `QueryToMissingMetadata` | 1 | 0 |
| `DisableSafeMode` | 2 | 2 |
| `DeletingCollectionItem` | 1 | 1 |
| `UnreachableCode` | 2 | 1 |
| `UnavailableMemberCall` | 2 | 0 |
| everything else | 9 | 0 |
| **total** | **76** | **16** |

Every remaining error is pre-existing in the canonical sources; the merge
introduces none.


### `1c-syntax/bsl-parser`

- ANTLR4 grammars for BSL, the 1C query language (SDBL) and method descriptions.
- Latest release `v0.39.0`. GPL-3.0. ~64 stars.
- Also the parser underneath `bsl-language-server`.

**Why it matters:** the builder's collision detection, export detection and
duplicate-definition checks are regex heuristics. A grammar-accurate parse would
remove the remaining class of merge risk — for example an identifier occurring
inside a construct the scanner does not model. It would also make block-balance
checks unnecessary because balanced input cannot produce an unbalanced merge.

## Configuration and extension container tooling

| Project | Notes |
|---|---|
| `oscript-library/gitsync` | `v3.8.0`, MPL-2.0, ~334 stars. Syncs a 1C configuration repository with git, converting between binary and source formats. Supports extensions (`--ext`). Needs `ring` and uses `v8storage`. |
| `1C-Company/GitConverter` | Vendor tool: repository → git → EDT, preserving history. |
| `xDrivenDevelopment/precommit1c` | `v2.3.0` (7 years old), Apache-2.0, ~244 stars. Unpacks/packs EPF/ERF/CFE on commit. Unpacks `.cfe` with platform tooling and everything else with `v8unpack` + `V8Reader.epf`. |
| `oscript_modules/v8unpack` | *Verified locally*: present. Low-level container pack/unpack. |
| `vanessa-runner` `cfe decompile` / `cfe compile` | *Verified locally*: present in `vrunner` 3.0.0. Already converts `.cfe` ↔ XML sources through a temporary infobase. |

**Why it matters:** the builder does not need a bespoke packer. `vrunner cfe
compile` already assembles a `.cfe` from a source tree, and `vrunner cfe decompile`
goes the other way — which is an alternative starting point if generating a source
tree from scratch ever becomes limiting.

## Testing frameworks

| Project | Notes |
|---|---|
| `vanessa-opensource/add` | *Verified locally*: 6.8.0 installed in `oscript_modules`. Ships `xddTestRunner.epf` and smoke processors. |
| `Pr-Mex/vanessa-automation` | BDD/Gherkin for 1C. `vanessa-automation-single` 1.2.043.1 is installed. |
| `bia-technologies/yaxunit` | Modern 1C unit-test framework; `vrunner test yaxunit` is built into the installed runner. |
| `xDrivenDevelopment/xUnitFor1C` | The original xUnit for 1C; last updated 2018. Superseded by YAxUnit. |

All of these execute inside 1C, so all of them require a licence.

## `md-sparrow` — Designer-XML reader/writer (evaluated 2026-09-29)

`yellow-hammer/md-sparrow` reads and writes `MetaDataObject` XML — the Designer
dump format — through JAXB models generated from the official XSDs, and supports
export format versions **2.10 … 2.21**. Same author as the `1c-platform-tools`
extension already installed in this workspace, and the stated backend for its
metadata editing.

Facts, all *verified locally* unless noted:

- Java, **LGPL-3.0-or-later**. Created 2026-03-19, latest tag `v0.6.3`
  (2026-09-22), ~21 stars — young, but very actively developed.
- Distributed as a fat jar on GitHub Releases **only**; there is no Maven Central
  publication (checked: 0 artifacts). Vendored here at
  `build/vendor/md-sparrow/md-sparrow-0.6.3-all.jar`, 24,958,975 bytes,
  sha256 `c36d4bc28b9a24cd7ffbc52550d41a09eb58ea10370784a6693b2ef43b4ed195`.
  Needs JDK 21 (already present for the BSL language server).
- The XSDs live in a second **public** repo, `yellow-hammer/namespace-forest`
  (`schemas/designer/2.10` … `2.21`). It clones over HTTPS despite the `git@`
  submodule URLs in `.gitmodules`, and serves as the schema root for `validate`.
- NB: the two `fixtures` submodules carry the platform golden dumps and are only
  needed to *rebuild* md-sparrow. The released fat jar already contains them.

Builder-relevant commands (inventory read from `--help`):

| Command | Use for the builder |
|---|---|
| `init-empty-cfe` | Scaffold an empty extension: `--name`, `--name-prefix`, `--purpose`, `--compatibility-mode`, `--interface-compatibility-mode`, and `--from-configuration` to inherit the compatibility modes from the extended configuration. |
| `add-md-object` | Create one metadata object **from a platform-captured golden** and register it in `Configuration.xml` in one step. |
| `validate-dump <root>` | Dump integrity as JSON findings: composition, references, format versions. |
| `transcode` | Rebuild an object's XML from one format version to another. |
| `round-trip` | Read then rewrite a file through the JAXB models. |
| `validate` | Raw XSD validation against a schema root. |
| `project-metadata-tree`, `cf-md-graph` | The whole project's metadata as a JSON tree / typed graph. |
| `serve` | Resident mode: commands from stdin, so a caller pays for one JVM start instead of one per call. |

`add-md-object --type COMMON_MODULE` was exercised: it emits
`CommonModules/Moleculer.xml` and adds the `ChildObjects` entry, which is exactly
the pair of things the builder currently hand-writes.

### What it says about our existing output

Checked against this project's real artifacts, not against the README:

1. `validate-dump build/standalone/default` returns **`[]`** — the generated
   extension tree is composition-consistent.
2. That result is meaningful, not a silent no-op: deleting
   `CommonModules/mol_Reuse.xml` yields a `missing-file` finding, and additionally
   repointing a `ChildObjects` entry produces `missing-file` **and**
   `orphan-file` findings.
3. All seven hand-written builder XML files (`Configuration.xml`, the four common
   modules, the HTTP service, the language) **round-trip** through its JAXB models.
4. Its own `init-empty-cfe` scaffold declares seven `xr:ContainedObject` class ids,
   **the same seven** the builder's `CONTAINED_OBJECTS` carries. That hard-won list
   is confirmed independently.
5. Element order agrees with the platform. For an adopted object the builder puts
   `ObjectBelonging` first (language) and omits it for the HTTP service; the
   platform's own extension dump in `src/cfe/MoleculerSidecarConnector/` does
   exactly the same.

### Caveats

- **`validate` (raw XSD) is not usable as a gate here as-is.** It rejects both the
  builder's files *and* md-sparrow's own golden-derived `CommonModule` with the
  identical `Synonym` error, and it rejects the `ObjectBelonging`-first ordering
  that the platform itself writes for extension dumps. Its README promises an
  adjustment "for the way the platform writes them", but that adjustment is not in
  effect on this path. `validate-dump` and `round-trip` are the usable ones.
- `--type HTTP_SERVICE` is listed in the type table but the enum constant is absent
  in 0.6.3: `No enum constant … MdObjectAddType.HTTP_SERVICE`, and likewise for
  `HTTPService`. The documented table and the implementation disagree.
- LGPL-3.0-or-later. Invoking it as a separate process, or shipping the jar
  unmodified alongside, is the clean boundary; linking it into distributed code
  would need a licence review.
- It is an XML-level tool. It does not build or read `.cfe` containers, so
  `vrunner cfe compile` stays in the pipeline.

## Agent- and editor-side tooling

- `yellow-hammer/vscode-1c-platform-tools` and `yellow-hammer/mcp-1c-platform-tools`
  — *verified locally*: both installed.
- `1C-Company/v8-code-style` — 1C's own code-standard checks for EDT.
- `Nikolay-Shirokov/cc-1c-skills`, `feenlace/mcp-1c`, `DitriXNew/EDT-MCP` — agent
  toolkits that abstract the XML formats and the designer CLI.

## Recommendations

1. **`bsl-language-server` is adopted** as the syntax and diagnostics gate for both
   the canonical sources and the generated variant. It needs no 1C licence, and it
   already caught a real defect that the platform's own checks could not.
2. **Replace the builder's regex scanner with `bsl-parser`.** Keep the declarative
   rename/patch profile, but drive collision detection and definition extraction
   from a real parse. This removes the last correctness risk in the merge. Now that
   a JRE is installed this is straightforward.
3. **Keep `vrunner cfe compile`/`decompile`** rather than adding `v8unpack` or
   `precommit1c`; the runner already does the job and is verified here.
4. **Do not adopt `precommit1c`** for this project: it is unmaintained, aimed at
   commit hooks, and unpacks extensions through the designer.
5. **No existing project does what this builder does.** None of the researched tools
   merges extension modules into a reduced, database-free variant, so that part
   remains project-specific. The parse/unpack/pack/compile steps around it can all be
   delegated to mature tools.
6. **Wire `md-sparrow validate-dump` into the builder as a composition gate.** It is
   free of 1C licensing, returns `[]` on the current variant, and demonstrably
   detects both missing and orphaned object files. It checks a different property
   than the BSL language server (tree structure vs. code), so the two do not overlap.
7. **Treat md-sparrow as an optional external CLI, not a dependency.** It should be
   present-or-skipped, so the builder keeps working without a JRE and without the
   vendored jar. Candidate follow-ups, in descending value:
   - replace the hand-written `Configuration.xml` / object-XML emission with
     `init-empty-cfe` + `add-md-object`, which would delete the maintained
     namespace sets and contained-object lists and pick up format-version support
     for free;
   - use `transcode` for the compatibility-mode/format-version axis, where the
     builder currently only warns;
   - generate the profile's `mergedModules` / `droppedModules` from
     `project-metadata-tree` instead of curating them by hand — which is also the
     most direct answer to the "builder must not be immersed in the source" concern.
8. **Do not adopt md-sparrow's `validate` (XSD) command yet.** It disagrees with the
   platform's own extension writer; adopting it now would produce false failures on
   correct output. Re-check on a later release.
