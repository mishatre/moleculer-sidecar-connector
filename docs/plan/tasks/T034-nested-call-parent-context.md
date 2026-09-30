# T034 — make a nested call chain to its parent

Status: withdrawn 2026-09-30 — the mechanism already works, and the finding was wrong.
Depends on: T030, T033
Recipe: normal
Coordinator: Sol Medium
Worker: —
Reviewer: —

## Decision card

Outcome: none. This file is kept as a record of a wrong finding, because the way it was wrong is worth
repeating.

## What it claimed

That `mol_ContextFactory.Call` and `Emit` thread the ambient context into the options as `parentCtx`, that
nothing in `src/` reads that key, and that `mol_Broker.Call` therefore chains through its own `Opts.Context`
key instead.

## Why that was wrong

`mol_ContextFactory.Create` reads `Opts.ParentCtx` and derives requestID, merged meta, tracing, `level + 1`,
parentID and caller from it — the same derivations as Moleculer's `ContextFactory.create` (`context.js`).
`mol_Broker.Call` builds its context through `Create`, so it passes the options along and the parent **is**
honoured. The search behind the finding looked for `parentCtx` and missed `ParentCtx`; BSL structure keys are
case-insensitive, so that spelling reads the same key.

Lesson for the next such search: a case-sensitive grep is not evidence of absence for a BSL structure key.

## What the test pinned

`tests/bsl/canonical/CommonModules/mol_ContextFieldsTests` asserted the threading and then that
`Opts.Context` was absent, calling the second a mismatch. It is now
`TheContextFactoryThreadsItsParentIntoTheNewContext` and asserts the derivation instead, so the chain itself
is covered rather than the absence of a key.

## What remains, as a smaller question

`Opts.Context` — reusing a supplied context and re-stamping its action — has no counterpart in Moleculer,
where a caller passes `parentCtx` and never a context to reuse. It is covered by `mol_AmbientContextTests`,
so it is a documented extension rather than a defect; whoever next touches the broker should decide whether
to keep it or fold it into `parentCtx`. The option list in `MoleculerClientServer` still advertises both
keys.
