# T007 — select a connector version and recommend updates

Status: draft
Depends on: T003, T004, T005
Recipe: normal
Coordinator: Sol Medium
Worker: integration specialist, Sol High
Reviewer: Sol Medium

## Decision card

Outcome: the installer combines installed, bundled, and GitHub version facts into
an explicit user choice and update recommendation.
Included: source/version model, comparable version rules, default selection,
outdated calculation, prerelease handling, and explanatory state.
Deferred: the extension write itself and deeper installed-content validation.
Success: the same input facts always yield the same choices and recommendation,
including bundled-only, prerelease, downgrade, and unknown-version cases.
Next: implement after T003–T005 stabilize their contracts.

## Acceptance and consumer example

- [ ] Default to the bundled version; show GitHub versions only after the user
      explicitly selects GitHub as the source.
- [ ] Show installed identity/version/state from T003 without calling it current
      merely because it is active.
- [ ] Compare canonical SemVer values and preserve unknown/unparseable versions
      without guessing.
- [ ] Recommend the newest stable GitHub release; if none exists, recommend the
      newest prerelease. Recommend an update only when it is demonstrably newer.
- [ ] Allow an explicit version/source choice; never silently switch sources after
      the user chooses.
- [ ] When GitHub is unselected or unavailable, make a complete decision from the
      bundled artifact and explain the limited comparison.
- [ ] Classify a selected older version as a downgrade requiring T008 confirmation.
- [ ] For the same active version, show “up to date” and disable routine rewrite;
      for the same inactive version, offer activation without artifact rewrite.

## Context and verification

Keep version comparison and selection independent from form controls and HTTP.
Use table-driven cases for absent, current, inactive, outdated, downgrade,
newer-prerelease, bundled-only, and unknown versions. T012 owns possible future
integrity/compatibility validation.
