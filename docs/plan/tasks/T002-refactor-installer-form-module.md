# T002 — refactor the installer form module without changing behavior

Status: ready 2026-09-30 — the first attempt was reverted as unsound; the review below is the work list.

The attempt renamed call sites without renaming their definitions (`IsExtensionInstallationPossible`,
`EnsureExtensionDataLoaded`, `InitializeCompatibilityParams`, `SetInstallerParameters` exist nowhere in the
tree), renamed the declarations in `Variables` without updating their uses (`ДанныеРасширения`,
`ДанныеПлатформы`, `Совместимость`), deleted `УстановитьПараметрыУстановщика`'s body so the form attribute
`ПараметрыУстановщика` is now populated nowhere, and renamed procedures without touching `Form.xml` — whose
bindings still name `ПриСозданииНаСервере`, `ДекорацияЗапускНовогоСеансаОбработкаНавигационнойСсылки` and the
`УстановитьРасширение`/`УдалитьРасширение` commands. One wait handler was renamed on one side only
(`"StartThickClientSession"` against `ЗапуститьСеансТолстогоКлиента`), one failure path gained a guard it did
not have, and the module is English only in its first 82 lines.

Lesson for the next attempt: rename a definition together with every call site, region by region, and check
the module for calls to names that do not exist before claiming anything. `vrunner epf compile` cannot see
that, and neither can any platform check — see the note in [environment.md](../environment.md).

Evidence: the review was produced by an independent reviewer over `git diff -- src/epf/` at commit `387bed1`;
the change is reverted and the file is byte-identical to `9182195`.
Depends on: T000
Recipe: normal
Coordinator: Sol Medium
Worker: integration specialist, Sol High
Reviewer: Sol Medium

## Decision card

Outcome: the installer form module has a predictable structure and one clear place
for derived form-state updates, making later installer features safer to add.
Included: syntax cleanup, official form-module regions, event ordering, logical
helper grouping, and centralized form element property updates.
Deferred: changing installation behavior, UI redesign, version sources, and
connection validation.
Success: the existing installer scenarios behave the same after the module is
reorganized and rebuilt.
Next: implement this task without adding later installer behavior.

## Acceptance and consumer example

- [ ] Use English BSL keywords and the official form-module region order:
      `Variables`, `FormEventHandlers`, header/table element handlers,
      `FormCommandHandlers`, and `Private`; include only non-empty regions.
- [ ] Keep platform event handlers in form/event order and related private
      operations together by responsibility, not by client/server directive.
- [ ] Convert procedures/functions to clear English names. Update only their
      corresponding managed-form XML event bindings; do not redesign form XML.
- [ ] Use valid, consistent BSL syntax and naming; fix syntax blockers and remove
      dead comments, but leave behavioral defects for their owning tasks.
- [ ] Introduce `&AtClientAtServerNoContext Procedure ManageForm(Form)` and pass
      form context explicitly.
- [ ] Move derived visibility, availability, captions, and other form element
      property updates into `ManageForm` where practical. Event-specific
      side effects stay in their handlers and documented exceptions stay local.
- [ ] Preserve install/update/remove, unsupported-context, and session-restart
      behavior; no new source or validation logic enters this task.
- [ ] After the pattern is verified, add a compact form-module convention to
      `AGENTS.md` with links to the official 1C standards.

## Context and verification

Intended shared form-state pattern:

```bsl
&AtClientAtServerNoContext
Procedure ManageForm(Form)
    Items = Form.Items;
    Object = Form.Object;
EndProcedure
```

Primary files: `src/epf/installer/installer/Forms/Форма/Ext/Form/Module.bsl`
and its `Form.xml` event bindings.
The current module has duplicate `БазовыеПараметры` regions, nested broad
regions, helpers mixed by technology and responsibility, and initialization
statements outside an explicit initialization region.

Official sources:
- https://its.1c.ru/db/content/v8std/src/400/100/i8100455.htm
- https://its.1c.ru/db/content/v8std/src/1%C2%A0200/700/i8100630.htm

Verification requires a clean diff review, source/static checks, reproducible EPF
build with direct `vrunner compileepf`, and a smoke pass through current form
states in `/workspace/build/ib`. No installation data, embedded binary, or
derived form behavior should change.

Implementation path:

1. Inventory form/module event bindings and observable form-state assignments.
2. Convert keywords, regions, procedure/function names, and matching XML bindings
   without altering conditions or side effects.
3. Route derived item-property changes through `ManageForm(Form)` and review the
   before/after control-flow map.
4. Build from `/workspace`:

   ```bash
   vrunner compileepf src/epf/installer build/out/epf \
     --ibconnection /F./build/ib --v8version 8.3 --root /workspace \
     --ordinaryapp -1 --nocacheuse
   ```

5. Open the built EPF against `/workspace/build/ib` and smoke-test the existing
   absent, installed, unsupported, removal, and restart-related form states
   without deliberately performing those actions.

Expected build result: `build/out/epf/installer.epf` is regenerated without a
compile error. Generated output remains under `build/` and is not committed.

## Delivery and authority

Deliver reviewed module source, required event-binding edits, and the compact
official-style convention in `AGENTS.md`. This task does not publish artifacts or
authorize install/update/removal actions. The compiled EPF is verification output.

## Stop conditions

Stop if the refactor requires a behavior decision or form XML changes beyond
renamed event bindings. Do not use this cleanup to fix feature behavior assigned
to later tasks.

## Completion evidence / resume point

Record source diff review, exact build command/result, manual state coverage,
review findings, and any behavior that could not be exercised. Do not mark
verified from compilation alone.
