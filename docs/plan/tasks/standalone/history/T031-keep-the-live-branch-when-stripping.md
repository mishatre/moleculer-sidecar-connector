# T031 — keep the live branch when stripping a standalone guard

Status: verified 2026-09-30
Depends on: T015, T016
Recipe: normal
Coordinator: Sol Medium
Worker: Terra Medium
Reviewer: Sol Medium

## Decision card

Outcome: the generated variant contains the surviving branch of every
`If Not IsStandalone() … Else … EndIf`, instead of losing the mapping that branch holds.

Why: `strip_dead_standalone_branches` walked from a dead `If` to its matching `EndIf` and deleted the whole
statement. That is correct when there is no `Else`: `GetConfig`'s constant block is dead in the variant and
should go. When a live `Else` is present it is the branch the variant depends on, and it was discarded
together with the dead half. Two mappings were lost that way — `LogLevels()` and `AuthTypes()` — leaving
every key `Undefined`.

Success: the variant answers `EventLogLevel` values, dispatches a declared auth type to its own fields, and
refuses an absent one exactly as extension mode does.

## Evidence before the fix

The generated `Moleculer` showed both functions with an empty gap where the `If` was, and
`tests/bsl/standalone/CommonModules/StandaloneRuntimeTests` pinned the consequences: the log level could no
longer select a branch, a declared auth type was refused, and an absent one was answered with token auth.
Those tests were written to be rewritten rather than deleted, and they now assert the mapping.

## How it was fixed

`strip_dead_standalone_branches` now splits the statement into its branches, drops the dead ones and emits
what remains — promoting a surviving `ElsIf` to `If`, inlining a bare `Else` body and dedenting it to the
statement level so the generated module stays readable.

The guard was placed in `tests/standalone-builder/test_standalone_strip.py` rather than in
`validate_merged`, because what needs checking is the transformation's behaviour on shapes rather than the
final text: seven container-only cases cover the surviving `Else`, the promoted `ElsIf`, the nested `If`,
the dropped dead `ElsIf` and the preprocessor case that must not be treated as a branch.

## Completion evidence / resume point

Builder suite green with the seven new strip cases; standalone 26/26; the two tests that used to pin the
absence now pin the mapping and pass. The verification step in the builder still only checks that dead
branches do not survive, which is now the weaker half of the pair rather than the only half.

Next: nothing. The remaining weakness is recorded above and belongs to whoever next touches
`validate_merged`.
