# T012 — validate an installed connector beyond version metadata

Status: deferred
Depends on: T003, T008
Recipe: complex; refine when a concrete validation need appears
Coordinator: Sol Medium
Worker: integration specialist, Sol High
Reviewer: Sol Medium

## Decision card

Outcome: a future installer can distinguish a merely registered extension from a
usable, compatible Moleculer sidecar connector.
Included later: explicit integrity/compatibility signals backed by real failure
cases.
Deferred now: all implementation; T003 reports only presence, active state, and
version.
Success: not defined until validation failures and recovery expectations are known.
Next: collect concrete broken/incompatible installation examples.

This task remains intentionally outside the active installer sequence. Presence,
active state, and SemVer normalization belong to T003; do not introduce speculative
integrity checks into T007 or T008.

## Candidate questions for later refinement

- Which required metadata objects, roles, or public connector contracts prove the
  installation is usable without invoking unsafe side effects?
- How should disabled, failed-to-apply, incompatible, partially upgraded, and
  legacy-name installations be classified?
- Which checks are read-only, and which require a controlled runtime probe?
- Should validation block update, recommend repair, or only warn?

Do not turn speculative checks into installation blockers. Validate only properties
that have an observed consumer consequence and a recovery path.
