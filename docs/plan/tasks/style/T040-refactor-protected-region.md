# T040 — the internal API region is named `Internal` and holds only its exports

Status: draft
Depends on: none
Recipe: normal; mechanical rename plus a small content decision
Coordinator: Sol Medium
Worker: Luna Medium
Reviewer: Sol Medium

## Decision card

Outcome: every module uses the standard's `Internal` region name, and that region
contains only the export routines that belong to the subsystem's internal API.

Included: renaming `#Region Protected` to `#Region Internal`, and moving the internal-only
(non-export) routines that sit in those regions out to `Private`.

Deferred: any other region renaming (`#Region Constructors`, `#Region HTTP` and the like
stay as they are), and the `// @internal` markers (T039).

Success: no module declares `#Region Protected`; every `Internal` region holds only
export routines that another subsystem object may call; the static gate and the suites
pass unchanged.

Next: apply the rename, then relocate the six non-export routines.

## Context and measured scope

The standard's region for a subsystem's internal API is `Internal`
([module structure § 3.1](../../../code-standards/module-structure.md)). The tree mostly calls
it `Protected`, which is not a 1C standard region name. Measured 2026-09-30 with nested
regions tracked:

| Finding | Count |
|---|---:|
| Modules with `#Region Protected` | 14 |
| Modules with `#Region Internal` (already correct) | 1 |
| Exported routines inside those regions | 80 |
| Non-export routines that should not be there | 6 |

The 14 modules using `#Region Protected`:

```text
src/cfe/MoleculerSidecarConnector/CommonModules/Moleculer
src/cfe/MoleculerSidecarConnector/CommonModules/mol_Broker
src/cfe/MoleculerSidecarConnector/CommonModules/mol_Client
src/cfe/MoleculerSidecarConnector/CommonModules/mol_ContextFactory
src/cfe/MoleculerSidecarConnector/CommonModules/mol_Errors
src/cfe/MoleculerSidecarConnector/CommonModules/mol_Helpers
src/cfe/MoleculerSidecarConnector/CommonModules/mol_HelpersClientServer
src/cfe/MoleculerSidecarConnector/CommonModules/mol_Internal
src/cfe/MoleculerSidecarConnector/CommonModules/mol_Logger
src/cfe/MoleculerSidecarConnector/CommonModules/mol_Reuse
src/cfe/MoleculerSidecarConnector/CommonModules/mol_ReuseCalls
src/cfe/MoleculerSidecarConnector/CommonModules/mol_SchemaFactory
src/cfe/MoleculerSidecarConnector/CommonModules/mol_Server
src/cfe/MoleculerSidecarConnector/CommonModules/mol_Transport
```

The non-export routines to relocate:

- `mol_Errors` — `Error` (line 408)
- `mol_SchemaFactory` — `EvaluateServiceConstructor`, `GetDynamicServiceConstructor`,
  `FillServiceSchema`, `ProcessElements`, `CreateElement` (lines 224–344)

## Acceptance and consumer example

- [ ] Rename `#Region Protected` to `#Region Internal` in the 14 modules; the matching
      `#EndRegion` needs no change, and nested sub-regions keep their names and order.
- [ ] Move each non-export routine out of the internal region and into `Private`, keeping
      related routines together and changing no code.
- [ ] If a non-export routine must stay, record the reason in the task evidence rather
      than moving it silently.
- [ ] Do not rename any other region; only `Protected` → `Internal` is in scope.
- [ ] Do not add `// @internal` markers here; that is T039.
- [ ] Confirm no module still declares `#Region Protected`:

  ```bash
  grep -rn '#Region Protected' --include=*.bsl src tests
  ```

## Context and verification

- A region directive is only a comment-level construct, so the rename cannot change
  behaviour; moving a routine to `Private` also cannot, because `Private` routines are
  still callable from the same module.
- Re-run the static gate and the full suite after the change, because the move changes
  module layout that the language server checks:

  ```bash
  tools/check.sh --layers static
  tools/check.sh --layers bsl-canonical,bsl-standalone
  vrunner cfe compile --src src/cfe/MoleculerSidecarConnector --ibcmd --v8version 8.3 build/out/MoleculerSidecarConnector.cfe
  ```

- The standalone builder merges modules by name; a region rename does not affect it, but
  re-run the builder layer (`tools/check.sh --layers builder`) to prove it.

## Delivery and authority

Deliver reviewed source changes only; no artifact is published.

## Stop conditions

- Stop if moving a routine would change who can call it; report instead of moving.
- Do not combine this with the `@internal` markers (T039) or the license headers (T038).
- Do not introduce new regions or reorder unrelated code.

## Completion evidence / resume point

Record the module list before and after, the six moved routines with their new region,
the grep proving `#Region Protected` is gone, and the gate results.
