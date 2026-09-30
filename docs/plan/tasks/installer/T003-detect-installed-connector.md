# T003 — detect the installed connector and its version

Status: draft
Depends on: T002
Recipe: normal
Coordinator: Sol Medium
Worker: integration specialist, Sol High
Reviewer: Sol Medium

## Decision card

Outcome: the installer reports whether `MoleculerSidecarConnector` is installed,
active, and which version 1C reports.
Included: current extension identity, read-only lookup, normalized state, and
status refresh after form opening or an installer action.
Deferred: update recommendations and deep compatibility/integrity validation.
Success: absent, installed-inactive, and installed-active states are distinguished
without mutating the infobase.
Next: implement after T005 establishes the release/version contract.

## Acceptance and consumer example

- [ ] Query `РасширенияКонфигурации` for `MoleculerSidecarConnector` and return
      one normalized state containing presence, active flag, and version.
- [ ] Render “not installed” without dereferencing a missing extension.
- [ ] Refresh from 1C after install/update/remove rather than trusting cached form
      attributes.
- [ ] Treat detection as read-only and keep “outdated” outside this task.
- [ ] Ignore legacy `MoleculerOneS`; do not display or classify it as the current
      connector or a migration candidate.
- [ ] Normalize valid 1C version text to canonical SemVer for downstream
      comparison; preserve an explicit unknown/unparseable state.

## Context and verification

Relevant routines are the current installed-state loader and `ManageForm` after
T002. Current lookup uses the legacy name. Verify absent, installed-inactive, and
installed-active states in `/workspace/build/ib`; record the exact raw and
normalized version values. Deeper validation belongs to T012.
