# T020 — Core unit suites C: helpers, logger, reuse caching, context cleanup

Status: in_progress — the ambient-context lifecycle is covered and the canonical suite is 120/120. The
logger, `SignV4` and the reuse-caching semantics are still open. The leak's fix is raised as T030, which
this task's delivery note requires.
Depends on: T017
Recipe: normal
Coordinator: Sol Medium
Worker: Terra Medium
Reviewer: Sol Medium

## Decision card

Outcome: the shared helpers and the two mechanisms most likely to regress
silently — reusable values and ambient context — are covered by executable tests.
Included: `mol_Helpers`, `mol_HelpersClientServer` validators, `mol_Logger`, the
`mol_Reuse`/`mol_ReuseCalls` caching semantics, and the ambient-context lifecycle.
Deferred: standalone-mode variants of the same suites (T021).
Success: suites pass, and the context leak in `mol_Broker.Call`/`Emit`/`Broadcast`
is either fixed with a test proving cleanup or pinned with a test that fails when
the leak is fixed.
Next: T021 standalone runtime verification.

## Acceptance and consumer example

- [ ] `mol_Helpers`: the validator family (`IsObject`, `IsStructure`, `IsMap`,
      `IsArray`, `IsString`, `IsNumber`, `IsBinaryData`, `IsValidDate`, `IsStream`,
      `CanBeNumber`) including the duplicated definitions in
      `mol_HelpersClientServer`; `GetVersionedFullName`; `SignV4` determinism for
      fixed inputs; and serialization round-trips.
- [ ] `mol_Logger`: level mapping for both the enum path and the standalone path,
      and a fallback when the enum is unavailable.
- [ ] Reuse caching: `mol_Reuse` session-scoped reuse and `mol_ReuseCalls`
      request-scoped reuse are tested for the behaviour callers depend on,
      including invalidation via `RefreshReusableValues`; if T015 replaced the
      mechanism with an explicit cache, the equivalent invalidation is tested.
- [ ] Ambient context: a root call, a nested call and a failing call each leave
      the ambient context in the documented state, proving or exposing the
      `SetCurrentContext`/pop imbalance in `mol_Broker.Call`, `Emit` and
      `Broadcast`.
- [ ] `GetCurrentContext` and `GetCurrentError` are asserted for staleness across
      two consecutive operations.

## Implementation context

Entry point: the T017 harness.
Relevant files: `.../CommonModules/mol_Helpers/Ext/Module.bsl`,
`.../mol_HelpersClientServer/Ext/Module.bsl`, `.../mol_Logger/Ext/Module.bsl`,
`.../mol_Reuse/Ext/Module.bsl`, `.../mol_ReuseCalls/Ext/Module.bsl`,
`.../mol_Broker/Ext/Module.bsl`.
Reference: `docs/plan/connector-architecture-audit.md`, sections on contexts,
errors and abstraction quality.
Constraints: reuse semantics depend on the module-level `ReturnValuesReuse`
declaration; the suite must state which mechanism is under test.
Unknowns: whether the T015 variant keeps `mol_Reuse`/`mol_ReuseCalls` as separate
modules, which changes what the caching suite asserts.

## Environment and verification

Commands: the harness command filtered to these suites. Expected: report with 0
failures; seeded defects in each mechanism produce failures.

## Delivery and authority

Deliverable: test modules. Any source fix for the context leak is out of scope here
and must be raised as its own task.

## Stop conditions

Stop if the caching mechanism under test is undecided by T015; record the blocker.

## Completion evidence / resume point

### Ambient-context lifecycle — verified 2026-09-29

`tests/bsl/canonical/CommonModules/mol_AmbientContextTests`, four tests, canonical only. The canonical
suite is **120/120** in 44 s.

Mechanism asserted: the ambient context is a named stack in `mol_Helpers`. `mol_ContextFactory`
`GetCurrentContext` reads its top and `SetCurrentContext` pushes onto it. The lifecycle spans three
modules, so the suite is named for the lifecycle and its header lists them:

| Site | Behaviour |
|---|---|
| `mol_ContextFactory.Handler` | pushes the incoming context and pops it again — balanced |
| `mol_Broker.Call`, `Emit`, `Broadcast` | call `SetCurrentContext`, which pushes — never popped |
| `mol_Errors` | pushes the raised error — never popped |

Pinned behaviour: the publish contract of `SetCurrentContext`; that a call which cannot reach a sidecar
leaves the ambient context alone rather than half-publishing; that a nested call stamps the action name
into the caller's context before the transport is attempted; and the staleness the acceptance asks to
expose.

Observed leak behaviour: raising publishes an ambient error and nothing removes it, so an unrelated
successful operation — a `GenerateUid` call — still reads that error afterwards. The test states this
explicitly and is written to be rewritten to the opposite assertion, not deleted, when the lifecycle
changes.

Not reachable here: the broker publishes its context only *after* the transport answers, so its
push-without-pop cannot be triggered without a sidecar. All four sites are recorded in T030, which owns
the fix.

### Still open in this task

- `mol_Logger` — level mapping for the enum path and the standalone path, plus the fallback when the
  enum is unavailable.
- `mol_Helpers` — `SignV4` determinism for fixed inputs, and the serialization round-trips.
- Reuse caching — session-scoped `mol_Reuse` and request-scoped `mol_ReuseCalls`, including
  invalidation through `RefreshReusableValues`.

### Logger level mapping — verified 2026-09-29

`tests/bsl/canonical/CommonModules/mol_LoggerTests`, three tests. The canonical suite is **124/124**.

Mechanism asserted: `LogLevels()` is a mapping, not a stored level. It declares four keys and resolves
them to the `mol_LogLevel` enum in extension mode, or to the platform's `EventLogLevel` values in
standalone, where the enum does not exist. `WriteLogEventSystem` compares the configured level against
those values with `=`, so a mapping that resolves to `Undefined` does not merely lose a label: no
comparison can match.

One assertion was wrong on the first run, and the reason is worth recording because it was wrong about
the *implementation* rather than about the test's subject. The configured level does not come from the
mapping in extension mode: `GetConfig` writes `LogLevels().Info` and then overwrites it from the
`mol_LogLevel` constant, so the constant is the source and the mapping is the fallback. The test now
asserts that provenance directly, which stays valid whether or not the base has a value.

### A builder defect the standalone half exposed

The variant's half of the mapping cannot be asserted as intended, because the mapping is not there: in
the generated `Moleculer`, `LogLevels()` returns all four levels as `Undefined`, and `AuthTypes()` does
the same for all three auth types.

Cause: `strip_dead_standalone_branches` in `tools/standalone-builder/build-standalone.py` deletes
everything from a dead `If` to its matching `EndIf`. That is right when the statement has no `Else` —
`GetConfig`'s `If Not IsStandalone() Then … EndIf` around the constants is correctly removed — but when
a live `Else` is present, that body is the surviving branch and is deleted along with the dead half.

Consequences in the variant, both reachable from a deployment profile:

- the level comparisons in `WriteLogEventSystem` can never match, so the configured level no longer
  selects a log branch;
- `NewPublicationAuthParams` refuses a correctly declared type — a profile's `"UsingPassword"` fails as
  "Unknown auth type" — while an absent type matches `Undefined = Undefined` and is answered with token
  auth.

Why it stayed hidden: the builder's own verification step checks only that dead branches do not
*survive*, and nothing checks that the live branch does. The standalone suite never asserted either
mapping, and the one assertion that would have caught it was skipped here for an unrelated reason — the
type of `LogLevel`. Both mappings are now pinned in `StandaloneRuntimeTests`, written to be rewritten
when the builder is fixed rather than deleted. The fix is T031.

## Optional pilot metrics

Actual models/efforts:
Elapsed time / repair rounds / human review minutes:
