# T026 — module surface and naming are consistent

Status: draft — an outline from the cycle's evidence, not yet refined.
Depends on: T023, T025
Recipe: normal
Coordinator: Sol Medium
Worker: TBD
Reviewer: Sol Medium

## Decision card

Outcome: the connector's common modules are named and exposed consistently, so a reader can tell the
facade, the broker and the helpers apart without opening each module.

Why now: the surface grew around the platform's constraints rather than around a design, and the two
findings below are measurable consequences rather than impressions.

Included: to be settled at refinement.
Deferred: renaming anything a consumer calls through the facade — that is an owner decision.
Success: one naming rule applied to every module, and the passthrough predicates either gone or justified.
Next: refine this file from the evidence below.

## Evidence this rests on

Two rows of the cycle's evidence table in [refactor-backlog.md](../../notes/refactor-backlog.md):

| # | Finding | Evidence |
|---|---|---|
| 6 | Every type predicate is a passthrough | `mol_Helpers.IsString/IsMap/…` each forward to `mol_HelpersClientServer`, an indirection with no logic in between |
| 7 | Module naming is inconsistent | `Moleculer*` versus `mol_*` prefixes; `mol_Reuse` and `mol_ReuseCalls` exist only to work around the platform rule that a common module cannot hold module variables |

## Implementation context

Relevant files: `src/cfe/MoleculerSidecarConnector/CommonModules/*/Ext/Module.bsl`, and
`tools/standalone-builder/profiles/default.json`, whose rename maps already encode which names mean the
same thing after the merge — the merge is where the naming question becomes concrete.

Constraint: the standalone merge keys on module names, so a rename moves the builder with it.

## Environment and verification

Link: [environment.md](../../environment.md)

Commands: `tools/check.sh` runs every layer; `tests/standalone-builder` covers the merge by name.
Expected: green, plus the builder suite extended for any rename.

## Stop conditions

Stop if the naming rule cannot be stated in one sentence, or if it would change a name a caller outside the
extension uses — that is an owner decision, not a refactor.
