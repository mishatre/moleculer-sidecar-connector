# T022 — Static quality gate and standalone delivery documentation

Status: blocked — but no longer on client availability: the designer runs, since `vrunner`
drives it for compile and load, so the BSL syntax-check half is feasible. What blocks it
now is its own dependencies: T018–T020 are unfinished suite work. T021 is verified.
Depends on: T018, T019, T020, T021
Recipe: normal
Coordinator: Sol Medium
Worker: Luna Medium
Reviewer: Sol Medium

## Decision card

Outcome: the repository has a repeatable static gate and a user-facing guide for
the standalone variant.
Included: BSL Language Server diagnostics enabled for the connector and the
generated tree, a syntax-check command, a single entry point that runs all layers,
and the install/manual-migration documentation.
Deferred: CI wiring on a remote service and any release publication.
Success: one documented command runs static checks and all test layers and reports
a clear pass/fail; `INSTALL.md` is validated against a real manual migration.
Next: publish or hand the artifact to its consumer as a separate delivery action.

## Acceptance and consumer example

- [ ] `.bsl-language-server.json` enables diagnostics for `src/cfe` and the
      generated tree, and the selected rule set is justified rather than defaulted.
- [ ] `vrunner validate syntax-check` runs with the recorded command and an
      exception file, or the reason it cannot run is recorded.
- [ ] One entry point runs the OneScript suites, the BSL suites for both modes, and
      the static checks, and returns non-zero on any failure.
- [ ] `tests/README.md` and the standalone `INSTALL.md` describe the commands, the
      two infobases and the expected output.
- [ ] `INSTALL.md` covers both routes: install the `.cfe` as an extension, or move
      the two common modules and the HTTP service into a host configuration by
      hand, including the compatibility-mode limitation and the server-only
      execution-context change.
- [ ] Repeated runs are not required where a clean run is already recorded, unless
      a relevant change occurred.

## Implementation context

Entry point: the commands verified in T014 and the harness from T017.
Relevant files: `.bsl-language-server.json` (currently only language and
formatting settings), `.vscode/settings.json`, `tests/README.md`, the emitted
`INSTALL.md`, `docs/plan/environment.md`.
Constraints: mechanical and documentation work with clear examples; do not
reformat unrelated BSL.
Unknowns: the achievable diagnostics set without a full BSL LS analysis pass.

## Environment and verification

Commands: the static-check command, the syntax-check command, and the combined
entry point. Expected: clean diagnostics on changed files, or an explicitly
recorded exclusion with justification.

## Delivery and authority

Deliverable: configuration, entry point and documentation. Publication of any
artifact remains a separate, separately authorized action.

## Stop conditions

Stop if the diagnostics run produces an unmanageable pre-existing warning volume;
record the counts and propose a bounded rule set instead of disabling the gate.

## Completion evidence / resume point

Record: rule set and rationale, commands, observed output, the combined entry-point
result, and the `INSTALL.md` validation notes including which step was rehearsed.

## Optional pilot metrics

Actual models/efforts:
Elapsed time / repair rounds / human review minutes:
