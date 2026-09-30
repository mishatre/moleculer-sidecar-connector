# T035 — the standalone merge keeps service identities apart

Status: verified 2026-09-30, implemented through a new profile capability.
Depends on: T015
Recipe: normal
Coordinator: Sol Medium
Worker: Terra Medium
Reviewer: Sol Medium

## Decision card

Outcome: in the standalone variant, code that tells two modules apart by name still tells them apart once
they are merged, so error handling, context stacks and schema compilation stop seeing each other's state.

Why: the builder rewrites every `Metadata.CommonModules.mol_X` reference to `Metadata.CommonModules.Moleculer`
(step 4 of `tools/standalone-builder/build-standalone.py`). That is right for a reference to the module object
and wrong for a key derived from a module's own metadata. `mol_ReuseCalls.GetCacheStack()` is keyed by
`ThisMetadata().Name`, and three modules use it as their own private stack: `mol_Errors`
(`mol_Errors/Ext/Module.bsl:195`, `:292`), `mol_ContextFactory` (`:239`, `:265`) and `mol_SchemaFactory`
(`:161`, `:189`, `:386`). In the variant all three keys were the string `"Moleculer"` — `ErrorsThisMetadata()`
was emitted as `Return Metadata.CommonModules.Moleculer` (`build/standalone/default/CommonModules/Moleculer/Ext/Module.bsl:842-843`),
and twelve references collapsed the same way — so three private stacks became one shared stack.

What that broke, in the variant only: `mol_Errors.GetCurrentError()` could return a build context or an
execution context where extension mode returns Undefined, so the `If Error = Undefined Then ... FromErrorInfo(...)`
recovery was skipped and a structure was formatted as an error; and `mol_Helpers.ClearStack(ThisMetadata().Name)`
inside `mol_SchemaFactory.CompileServiceSchema` cleared the *shared* stack, destroying the ambient context an
inbound request pushed there through `mol_ContextFactory.Handler`.

Success: three modules, three private stacks, in the variant as well as in extension mode.

## How it was fixed

`plan.modulePatches` — optional, `{module: [{description, pattern, replacement}]}` — applies replacements to
one module's own text while the modules are still separate and before anything is renamed. The plan replaces
`ThisMetadata().Name` inside `mol_Errors`, `mol_ContextFactory` and `mol_SchemaFactory` with that module's own
name: twelve sites, which is the identity the merge would otherwise erase. The three private stacks keep three
keys, so a raised error can no longer land on the stack an ambient context was pushed to, and `ClearStack` in
the schema factory can no longer clear the context stack.

Why a new capability rather than a patch: the global `patches` list runs on the merged text, where that
expression is identical in all three modules, so one pattern cannot give three modules three answers. This step
runs before the renames, so its patterns describe the canonical sources. The first attempt did not: it matched
the tail of the renamed `ErrorsThisMetadata` and emitted `PushToStack(Errors"mol_Errors", Error)`, which the
builder suite caught. A module patch that stops matching fails the build, the same guard the global patches
have.

## Completion evidence / resume point

`StandaloneRuntimeTests.TheErrorStackDoesNotDisplaceTheContextStack` pushes a context, raises through
`RaiseError`, and asserts the context is still current. It was **seeded and reverted**: with the capability
disabled it fails on its own message, `провалено 1`, and the harness exits 1, so it proves the fix rather than
merely passing. The builder suite asserts that no bare `ThisMetadata().Name` survives the merge and that all
three modules name their own stack. Builder 54 tests, standalone 26/26, canonical 176/176 unchanged — this fix
touched no canonical source.

Still open, recorded rather than fixed: `ThisMetadata().FullName()` still answers the merged module's full
name, so the stack-trace offset in `mol_Errors`/`mol_Logger` skips every frame of the merged module. That is
diagnostic-only — the trace keeps the caller's frame — and the same mechanism would fix it if the traces came
to matter more than they seem to.

Related: T032 is the same class of defect — one surviving `Constructor` for two services — and T031 was the
third, a strip that took the live branch.
