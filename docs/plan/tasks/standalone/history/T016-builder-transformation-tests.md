# T016 — OneScript test suite for the standalone builder

Status: verified — 30 container-only tests pass
Depends on: T015
Recipe: tiny
Coordinator: Sol Medium
Worker: Terra Medium
Reviewer: Sol Medium

## Decision card

Outcome: the builder's transformation and the shape of its output are guarded by
fast container-only tests that need no 1C platform.
Included: OneScript suites for profile validation, the collision rename map, the
call-site rewrite, the removal list, the generated-tree file set, and the
manifest.
Deferred: any behavioural test of the connector itself (T018–T020) and any test
that requires the platform.
Success: `oscript tests/run.os` executes the suites and fails when the builder
emits a dropped module, leaves a `mol_` qualifier, or writes an unexpected file.
Next: run alongside T018–T020; extend after the T015 PoC decisions.

## Completion evidence / resume point

Delivered 2026-09-29 as `tests/standalone-builder/test_builder.py` (30 tests).

Deviation from this card's original plan, recorded deliberately: the suites are
Python `unittest` rather than OneScript `1testrunner`, because the builder itself is
Python. `1testrunner` remains available and is still the route for any future
OneScript-level suite; `1bdd` is unusable as installed.

Covered: scanner safety (quotes in comments, escaped quotes, directives not matched
mid-line), definition scanning, profile validation and overrides, the real canonical
merge (no duplicates, no qualifiers, no removed-module references, explicit caches,
applied patches, balanced blocks), tree emission (exactly eight files, seven
contained objects, no infobase objects, adopted language, provider without the
standalone guard) and the command line (emit without compiling, replace on re-run,
unknown profile fails).

The suite found real defects during development: the scanner desynchronised on a
quote inside a comment, and the inbound-request patch assumed a parameter name.
Both are fixed.

Command: `python3 -m unittest discover -s tests/standalone-builder -t tests/standalone-builder`
Result: `Ran 30 tests, OK`.

Next action: extend when the merge gains behaviour that the static checks cannot
cover, and add a BSL-facing suite once a 1C client can run.

## Optional pilot metrics

Actual models/efforts: coordinator only
Elapsed time / repair rounds / human review minutes: 1 repair round
Quota before/after, observation times, concurrent-work caveat: not observable

## Original card (for reference)

### Acceptance and consumer example

- [ ] `tests/standalone-builder/*.os` covers: profile parsing and validation
      errors; the rename map applied per source module; `mol_X.` call-site
      rewriting with `Moleculer.` self-reference preserved; the removal list; the
      generated tree file set; and the manifest contents.
- [ ] Tests run through `oscript_modules/1testrunner` or `1bdd`, both already on
      disk, with no platform launch and no network access.
- [ ] A deliberately broken profile or an unexpected leftover in the merged module
      makes the suite fail with a message naming the offending file or symbol.
- [ ] `tests/run.os` is the single documented entry point.

## Implementation context

Entry point: `tools/standalone-builder/build-standalone.os` from T015.
Relevant files: `tools/standalone-builder/`, `tests/`, `tests/README.md`.
Existing example to follow: `oscript_modules/1testrunner/tests/*.os` for runner
conventions; `oscript_modules/1bdd/features/core/*.feature` if BDD is preferred.
Constraints: container-only; assert on generated text and file lists rather than
on compiler behaviour.
Unknowns: whether the project prefers 1testrunner or 1bdd for these suites.

## Environment and verification

Commands: `oscript tests/run.os`, plus the individual suite command. Expected: all
suites pass; a seeded defect produces a named failure.

## Delivery and authority

Deliverable: source tests plus the runner entry point. No artifact publication.
Reversal: delete `tests/standalone-builder/` and `tests/run.os`.

## Stop conditions

Stop if the builder is not yet stable enough to assert against; record the blocker
and resume after T015.
