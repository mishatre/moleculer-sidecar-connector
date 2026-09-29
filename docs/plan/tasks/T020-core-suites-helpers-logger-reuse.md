# T020 — Core unit suites C: helpers, logger, reuse caching, context cleanup

Status: blocked — requires a runnable 1C client (see T014 completion evidence)
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

Record suite names, command, report path, summary, the mechanism asserted, and the
leak's observed behaviour with the follow-up task reference.

## Optional pilot metrics

Actual models/efforts:
Elapsed time / repair rounds / human review minutes:
