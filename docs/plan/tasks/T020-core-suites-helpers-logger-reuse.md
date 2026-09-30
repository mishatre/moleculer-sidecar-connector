# T020 — Core unit suites C: helpers, logger, reuse caching, context cleanup

Status: in_progress — the ambient-context lifecycle, the logger mapping and the reuse-caching mechanism are
covered, in both modes. Remaining: `SignV4` determinism and the serialization round-trips. The context
leak's fix is T030 and the builder defect's is T031.
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

### Reuse caching — verified 2026-09-29

`tests/bsl/common/CommonModules/mol_ReuseCachingTests`, four tests, in the shared tree so they run in
both modes. Canonical **128/128**, standalone **24/24**.

Mechanism asserted, which the acceptance requires be stated explicitly: the platform's return-value
reuse, declared as `ReturnValuesReuse = DuringSession` on `mol_Reuse` and `DuringRequest` on
`mol_ReuseCalls`. Every other common module in the extension is `DontUse`, so `mol_Reuse` is the only
place where a returned value is shared between calls — and the reason it forwards to the
forced-recompute entry points.

How it is observed: a reused value is the *same object* on the next call, not merely an equal one. The
HTTP connection cache returns a Map, so writing a marker into it and reading it back through a second
call shows the platform handed the same value over; `RefreshReusableValues()` then drops it. Both are
asserted, so the invalidation path callers are told to use is covered rather than assumed.

A finding from the other mode: the variant has no BSP integration at all. The builder's
`remove_definitions` step removes `BSPVersion` and `BSPVersionAsNumber`, leaving the `BSPIntegration`
region empty, so the mapping exists only in extension mode. The test branches on `IsStandalone()` and
pins the variant's shape — the call fails rather than answering a version it cannot know — instead of
assuming the extension's behaviour.

### Signing and stream reading — verified 2026-09-30

`tests/bsl/canonical/CommonModules/mol_HelpersSigningTests`, six tests. Canonical **134/134**.

`SignV4` builds the AWS4 authorization header, and determinism is the property worth pinning: a
signature that drifted between two identical calls would break every signed request, while one that
ignored an input would not be a signature at all. The suite asserts identical output for identical
inputs, a different output when the region changes, that the ignored headers stay out of
`SignedHeaders` — they are the ones proxies and browsers rewrite, so signing them would make the
signature depend on something the sender does not control — and that an empty credential and a non-`Map`
header collection are refused with the argument named.

The stream reader is covered only for its failure contract: a failed read is caught, logged at Info
level and reported as *nothing*, so a caller cannot tell it from an empty document. That is pinned as
current behaviour and written to be rewritten. The successful path is not asserted, because building a
stream from text needs a `BinaryDataBuffer` — the idiom `mol_Helpers` itself uses — and the round-trip
item is already satisfied through the string reader.

Two things went wrong on the way, and both are worth keeping. The suite first failed to compile because
the framework's collection is `ЮТТесты`, not `ЮТесты`; the harness's load gate then reported "a suite did
not load, so the counters above understate the run" instead of showing a green 128/128, which is exactly
why that gate exists. The second was the stream idiom above, which produced "insufficient actual
parameters" and led to checking how the module itself builds a stream rather than guessing again.

### Still open in this task

Both remaining items need a live sidecar, so neither can be closed in-process:

- the root-call case of the ambient-context item: a call that completes, rather than one that fails
  before the transport, is what actually reaches the push in `mol_Broker`. `tests/bsl/http/` owns that
  path today, but does not observe the stack.
- pinning the `mol_Broker` push-without-pop with a test rather than a description, for the same reason.
  The `mol_Errors` half is pinned by `mol_AmbientContextTests`, and T030 owns the fix.

Everything else the acceptance lists is covered: the validator family and `GetVersionedFullName` by
`mol_HelpersClientServerTests` and `mol_HelpersTests`, the round-trips by `JSONRoundTripPreservesValues`,
`SignV4` and the stream reader by `mol_HelpersSigningTests`, the logger by `mol_LoggerTests`, the caching
mechanism by `mol_ReuseCachingTests`, and the lifecycle by `mol_AmbientContextTests`.

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
