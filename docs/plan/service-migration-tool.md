# Service module migration — plan (draft, low priority)

Outcome: a tool that turns a service module written against the removed registration API into a
module written against the current constructor shape, leaving the handler bodies alone.

Why this is not cosmetic: `Moleculer.SchemaAddAction` and `Moleculer.SchemaAddEvent` no longer exist.
They are absent from both `src/` and the generated standalone tree, so a module written in the old
shape does not compile against this connector at all. Migration is mandatory for every deployed
service module, and there is nothing to keep compatible.

Fixtures are the three real modules in `docs/service-migration/examples/`; the target shape is
`docs/service-migration/ideal.bsl`.

## The two shapes

### Old

`Procedure Schema(Schema) Export` declares the service and registers actions and events by name, and
each handler carries its own declaration block, which the framework calls during registration:

| Old construct | Meaning |
|---|---|
| `Procedure Schema(Schema) Export` | service declaration entry point |
| `Schema.Name = "trade.companies"`, `Schema.Version = 1` | service identity |
| `Moleculer.SchemaAddAction(Schema, "getInfo", "GetCompanyInfo")` | action to handler |
| `Moleculer.SchemaAddEvent(Schema, "elact.contract.new", "OnNewContract")` | event to handler |
| `If Context.RegisterSchema Then` … `EndIf` | the declaration branch inside a handler |
| `RegInfo = Context.Registration` | the action's declaration record |
| `RegInfo.Description = "…"` | description |
| `RegInfo.Params.Insert("uuid", "string\|optional\|trim")` | a param and its type |
| `RegInfo.Params.Insert("items", New Structure("type,items", …))` | a nested param type |
| `Return Context.ContextId` | ends the declaration branch |

Two type forms appear in the fixtures: a flat `\|`-suffixed string, and a structured
`"type,…"` descriptor for arrays and objects.

### Target

`Procedure Constructor(Builder, Schema) Export`, with the service expressed as YAML (ideal), JSON
(normal) or builder calls (worst), and handlers reduced to business logic. Regions are Public
(constructor), Protected (Actions, Events) and Private (shared code).

## Facts the plan rests on

- The `\|`-suffixed vocabulary is the **sidecar's**, not the connector's. The connector has no parser
  for it; `mol_SchemaFactory` builds structured descriptors such as `Result.Insert("optional",
  Optional)`, and the only `"any\|optional"` literal in the repo is in
  `moleculer-sidecar-next/src/services/sidecar.service.ts`. So the target vocabulary's authority is
  the sidecar's schema conversion, and the mapping table has to be derived from there.
- `ideal.bsl` is not yet a settled contract: it carries TODOs for the parameter descriptions, says
  the constructor type is still undecided, and keeps an `#If Server And Not Server Then` block purely
  to make the editor infer the builder's type.

## Opinionated decisions

1. **Model first, emit second.** Analyse the module into a schema model — service name and version,
   actions and events, handler names, descriptions, params, types and flags — then serialise that
   model. Do not rewrite code text into code text. The output may be any of three formats, and a text
   rewriter would need three of them and would still corrupt the handler bodies.
2. **Handlers are frozen.** Everything outside the `If Context.RegisterSchema Then … EndIf` block and
   the `Return Context.ContextId` line is copied byte for byte. The handlers hold real business logic,
   and the project's readability rule forbids unrelated reformatting. The consequence is a small,
   reviewable diff.
3. **YAML is the default output; JSON and builder calls are fallbacks.** This follows the ranking
   written into `ideal.bsl`. It has a prerequisite: a YAML constructor needs a sidecar connection
   today, which is what T028 removes. Until T028 lands, the tool must say so rather than emit a
   module that fails at runtime, and `--format json` is the escape.
4. **The old registration branch is deleted outright; no compatibility shim.** The API that served it
   is gone from `src/`, so a shim would reintroduce a dead layer.
5. **Type translation goes through one explicit table, and an unknown suffix fails the module.** The
   old vocabulary carries meaning — `optional`, `no-empty`, `trim` — and a silently dropped `no-empty`
   is a validation regression that no compile check can catch. Refusing the module is the safe
   failure.
6. **Anything computed at runtime is a hard stop, not a guess.** A `RegInfo.Params.Insert` whose value
   is not a literal — a loop, a helper call such as `StrConcat`, a structure built from variables —
   cannot be expressed in the model. The tool marks the module partially migrated and writes a TODO at
   that exact line.
7. **Verify schema equivalence, not just compilation.** The old module cannot run, so there is no
   runtime "before". The tool's own model is the contract, and the verification step compares it
   against the schema the migrated module actually produces at runtime: action and event names, param
   names, types, optionality, and flags such as `Cache`, `Tracing` and the description. Compilation is
   necessary and not sufficient.
8. **One module per commit and per review.** Dotted action names such as `contract.getErrorInfo` and
   event names such as `elact.contract.new` are the wire contract. The tool does not rename, prefix or
   namespace anything.
9. **The tool is Python under `tools/service-migration/` and container-only.** Analysis and emission
   need no 1C platform, which matches `tools/standalone-builder/` and `tools/bsl-checks/`, so its own
   tests run everywhere. Only `--verify` needs the platform, and it stays opt-in.
10. **Pin the constructor contract before writing the emitter.** Decision 1 makes the analyser
    independent of the contract, but the emitter is not: it must not encode a guess about how
    `Builder` and `Schema` arrive. This is a prerequisite of the tool, not part of it.
11. **Idempotent and re-runnable.** Running the tool over already-migrated output changes nothing and
    reports "already current".
12. **The fixtures directory is the corpus.** Expected outputs live beside the examples.
    `ideal.bsl` is the shape reference, not a fixture: it has no old counterpart and its TODOs are
    unresolved.

## Verification

- Analysis is covered by container-only tests over the three fixtures, including the expected refusal
  cases from decisions 5 and 6.
- Emission is covered by comparing generated output against the checked-in expected output.
- The runtime step, when requested, follows the project rule that compilation alone proves nothing:
  load the migrated extension, compile its schema, and compare it against the model from decision 7.
- The handler bodies are proven unchanged by a diff that contains no hunk inside a handler.

## Non-goals

- Converting handler logic, event payload handling or private helpers such as `StrConcat`.
- A repository-wide sweep: one module at a time, reviewed on its own.
- Changing the wire contract: action and event names, and param semantics, must be identical after
  migration.
- Building the compatibility layer the old API would need.

## Open questions for the owner

1. What exactly is the constructor contract — what arrives in `Builder` and `Schema`, and how is the
   `#If Server And Not Server Then` inference trick meant to work in a real module?
2. Where do migrated modules live? This repository hosts the connector and the tool, not the consumer
   services, so delivery and hosting are a consumer-side decision.
3. Is the tool an internal one-off for the current modules, or something shipped to consumers? That
   decides how much of the failure handling becomes user-facing output.

## Priority

Low. Nothing in this repository consumes the tool, and the three examples are the only known inputs.
T028 is a soft prerequisite only for the YAML default.
