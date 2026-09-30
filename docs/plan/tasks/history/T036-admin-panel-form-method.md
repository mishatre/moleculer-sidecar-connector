# T036 — the admin panel form calls a method that does not exist

Status: verified 2026-09-30 — fixed, and the gate that found it no longer reports the rule.
Depends on: none
Recipe: simple
Coordinator: Sol Medium
Worker: Sol Medium
Reviewer: Sol Medium

## Decision card

Outcome: `mol_AdminPanel`'s `ServiceItemForm` works when it is opened.

Why: `UpdateServiceRegistrationAtServer` called `mol_Broker.GetActivePublications()` and `mol_Broker` declares
no such method — its publication surface is `RegisterPublications`, `RegisterPublication`,
`UnregisterPublications`, `UnregisterPublication` and `GetPublicationValidationCode`. The same statement then
read `Publication.Info.Id` from a structure whose field is `Id`.

Success: the form registers each active publication with the sidecar through `$sidecar.updateService`.

## Evidence

`tools/bsl-checks/bsl-language-server.py` reported `MissingCommonModuleMethod` at
`DataProcessors/mol_AdminPanel/Forms/ServiceItemForm/Ext/Form/Module.bsl:60`. Nothing else catches it —
`vrunner cfe compile` and the designer's `/CheckModules` load metadata without compiling form bodies, so the
extension loads and every test passes while the call is broken. It surfaced only when the form ran.

## What was decided and changed

The facade, not a new broker method: `Moleculer.GetPublications()` is what `mol_Broker.RegisterPublications`
and `UnregisterPublications` already call, and it returns exactly the flat structure the form needs
(`id`, `connection`), matching `NewPublicationParams()`. The sibling paths read `Publication.Id` and
`Publication.Connection` the same way.

```bsl
Publications = Moleculer.GetPublications();
...
Params.Insert("publicationID", Publication.Id);
Params.Insert("service"      , FullName);
```

The payload was already right: the sidecar's `updateService` declares `params: {publicationID: "string",
service: "string"}`, which is what the form sends, so only the call and the field name were wrong.

## Verification

- `tools/check.sh --layers static` — the gate now reports **62 diagnostics in 11 recorded rules**, and
  `MissingCommonModuleMethod` is absent entirely; the baseline entry was deleted, and that deletion is the
  proof, since the rule can no longer fire anywhere in the tree.
- `tools/check.sh --layers bsl-canonical` — the extension still compiles and the suites are green,
  **179/179**.
- The diff is two tokens in one form module; nothing else moved.

## Resume point

Next: nothing. Worth remembering for T027: a form body is not compiled by any platform check, so only the
static layer can see this class of defect.
