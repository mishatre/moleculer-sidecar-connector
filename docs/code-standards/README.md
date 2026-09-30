# Code standards

The 1C:Enterprise development standards (`v8std`) that shape this repository's BSL, in English
and shaped for this project.

## Who reads what

- **Changing BSL?** Start with the [checklist](checklist.md). It is one page and it cites a rule
  ID for every line. Open a reference document only for the rule you need in full.
- **Reviewing a change?** Cite the rule ID — `BSL-455-4.4`, `BSL-453-5.9` — instead of a
  paragraph, so the finding is unambiguous and survives rewording of the documents.
- **Writing a task?** Point at the rule ID or the checklist rather than restating a rule.

| Document | Rule IDs | Covers |
|---|---|---|
| [checklist.md](checklist.md) | — | the pre-commit list, by module kind |
| [module-structure.md](module-structure.md) | `BSL-455-*` | #std455: sections, regions, region order, module header, variables, initialization |
| [procedure-and-function-description.md](procedure-and-function-description.md) | `BSL-453-*` | #std453: when and how to write the comment above a routine |
| [provenance.md](provenance.md) | — | where the rules come from, what was changed, what is not authoritative |

## How this project applies them

- **The script variant is English.** The connector declares `<ScriptVariant>English</ScriptVariant>`,
  so code uses `Procedure`/`Function`, `#Region`/`#EndRegion` and English identifiers.
- **Region order is the standard's order.** A form module is `Variables → FormEventHandlers →
  FormHeaderItemsEventHandlers → FormTableItemsEventHandlers<FormTableName> →
  FormCommandsEventHandlers → Private`; an object, manager or data processor module adds `Public`,
  `EventHandlers` and `Initialize` in the standard's positions. Only non-empty regions are
  declared.
- **One handler per event.** Duplicated work belongs in a named procedure that each
  default-named handler calls; a handler is not called from other module code.
- **The module header is two parts.** Every first-party source file outside
  `moleculer-sidecar-next/` opens with the same 80-column copyright and license box, then a
  description compressed to one or two lines — no design decisions, no list of sections, no
  examples. Each module variable carries a same-line comment. See
  [module structure § 4.1](module-structure.md#41-module-header).
- **Document the program interface.** Export procedures and functions, and the overridable
  connectors that other subsystems call, get a standard description comment. Private routines get
  one only when their purpose is not obvious from the name.
- **The internal API is marked.** An exported routine in an `Internal` region (named `Protected`
  in some modules today) is not public API, so it carries a `// @internal` line as the last line
  of its comment. See
  [procedure and function description § 5.9](procedure-and-function-description.md#59-marking-the-internal-api).
- **Routines are separated by blank lines**, and a comment sits above the compilation directive,
  not below it.

## Relationship to the other rules

- [`AGENTS.md`](../../AGENTS.md) keeps the durable, always-read rules, including the BSL
  column-alignment and no-formatter policy; its Readability section points here.
- [`../workflow.md`](../workflow.md) keeps the process rules; readability is part of acceptance
  there.
- These documents say nothing about *what* the code does. Behaviour, contracts and evidence stay
  in the task files under [`../plan/`](../plan/).

## Project-specific exceptions

- The module kinds that #std455 excludes — non-global common modules, manager modules, record set
  modules, constant value modules and the session module — simply omit the variable and the
  initialization sections.
- BSL is column-aligned on purpose. Keep the surrounding module's aligned `=` and
  trailing-comment columns, and keep the leading spaces after `|` inside a multi-line string
  literal. The BSL formatter is disabled for that reason.

A rule that a task cannot follow is a decision recorded in that task, not a silent exception here.
