# Checklist before committing a BSL module

Read this list first. Open [module-structure.md](module-structure.md) or
[procedure-and-function-description.md](procedure-and-function-description.md) only for the rule
you need to see in full. The IDs are the stable names of the rules: `BSL-455-*` comes from
#std455 (module structure) and `BSL-453-*` from #std453 (routine description).

## Any BSL or script change

- The file opens with the same 80-column copyright and license box as every other first-party
  source file. The only per-file part is the description below it. `BSL-455-4.1`
- That description says what the module is for, in one or two lines. No design decisions, no list
  of regions, no usage examples. `BSL-455-4.1`
- The file uses the English script variant: `Procedure` / `Function`, `#Region` / `#EndRegion`,
  English identifiers. [README](README.md)
- Every module variable has a comment on its own line saying what it is for. `BSL-455-4.2`
- Every exported routine and every overridable connector has a description comment. A private
  routine has one only when its name does not already say what it does. `BSL-453-2`, `BSL-453-3`
- The description does not repeat the routine's own name and does not begin with "Procedure" or
  "Function". It starts with the action: "Returns…", "Checks…", "Creates…". `BSL-453-5.1`
- Each parameter is written as `name - types - description`, and the types are always stated.
  Use `Array of <type>` for arrays and `see <Constructor>` for structures and value tables.
  `BSL-453-5.2.1`, `BSL-453-5.2.3`, `BSL-453-5.2.6`
- Routines are separated by a blank line, and a comment about a compilation directive goes above
  it, not below it. [README](README.md)
- The module's existing column alignment is untouched: the `=` columns and the spaces after `|`
  inside a multi-line string literal stay exactly as the surrounding module has them. Never let a
  formatter left-align either one. [README](README.md)
- This commit contains no unrelated reformatting of the file.

## Common module (server)

- Regions appear in this order, and only the non-empty ones are declared:
  `Public` → `Internal` → `Private`. `BSL-455-3.1`
- An export that only other objects of the same subsystem may call sits in `Internal` and carries
  `// @internal` as the last line of its comment. `BSL-453-5.9`
- A non-global common module declares neither the variable nor the initialization region.
  `BSL-455-1`
- Large modules are split into named sub-sections by responsibility. `BSL-455-2`

## Form module

- Regions appear in this order: `Variables` → `FormEventHandlers` →
  `FormHeaderItemsEventHandlers` → `FormTableItemsEventHandlers<Table>` →
  `FormCommandsEventHandlers` → `Private`. `BSL-455-3.3`
- Every event has its own default-named handler, and the handler calls a named procedure that
  does the work. A handler is not called from other module code. `BSL-455-4.4`
- The handlers of one form item are grouped together, in the order the items appear in the form
  editor's property panel. `BSL-455-4.4`
- `Private` holds no server/client/no-context grouping. `BSL-455-4.6`
- The header description names the form's parameters. `BSL-455-4.1`

## Object, manager, record set, data processor or report module

- Regions appear in this order: `Variables` → `Public` → `EventHandlers` → `Internal` →
  `Private` → `Initialize`. `BSL-455-3.2`
- An export called only from the object's own modules, forms and commands belongs in `Private`,
  not in `Public`. `BSL-455-3.2`
- Handlers are ordered as they appear in the embedded language description, where that is
  practical. `BSL-455-4.5`
- The initialization region contains only what initializes the module variables or the object.
  `BSL-455-4.7`

## Command module

- Regions are `EventHandlers` → `Private`. `BSL-455-3.4`
