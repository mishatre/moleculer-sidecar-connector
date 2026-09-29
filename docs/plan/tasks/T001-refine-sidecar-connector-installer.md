# T001 — decompose the Moleculer sidecar connector installer refinement

Status: verified
Depends on: T000
Recipe: planning parent; do not implement directly
Coordinator: Sol Medium
Worker: none
Reviewer: none

## Decision card

Outcome: installer refinement is divided into bounded tasks with an explicit
implementation order and deferred-work boundaries.
Included: form structure, installed-state detection, release construction,
GitHub discovery, version choice, installation, initial connection setup,
removal, and bilingual UI.
Deferred: arbitrary local CFE installation, optional SSL/BSP role protection,
and speculative installed-extension integrity checks.
Success: each requested outcome has one owner; T002 and T005 are ready; later
tasks have stable dependencies and recorded product decisions.
Next: implement T002, then T005, in separate conversations.

## Decomposition and order

Active sequence:

1. T002 — behavior-preserving English BSL form-module refactor.
2. T005 — reproducible connector/installer build and draft release.
3. T003 — installed connector identity, active state, and SemVer detection.
4. T004 — GitHub release discovery after explicit source selection.
5. T007 — bundled/GitHub version choice and update recommendation.
6. T008 — install, update, downgrade, or activate the selected connector.
7. T009 — validated initial Default connection and restart handoff.
8. T013 — confirmed connector removal.
9. T010 — final guided bilingual UI and help.

Outside the active sequence:

- T006 — deferred research into supported read-only CFE identity inspection.
- T011 — deferred until the optional role-protection artifact and behavior are supplied.
- T012 — deferred until concrete damaged/incompatible installations are observed.

## Settled cross-task decisions

- The bundled connector is the default source. GitHub is contacted only after
  the user selects it; there is no separate network toggle.
- Arbitrary local CFE selection is removed from the active installer design.
- Releases use canonical SemVer tags and deterministic asset names defined in
  [environment](../environment.md). Prereleases remain visible and labeled.
- The newest stable release is recommended, falling back to the newest
  prerelease when no stable release exists.
- Only `MoleculerSidecarConnector` is detected or removed. Legacy
  `MoleculerOneS` is ignored rather than treated as a migration candidate.
- Same-version active installations are not routinely rewritten. Same-version
  inactive installations can be activated without rewriting the artifact.
- Downgrades require an additional warning. Safe mode remains disabled for the
  connector, while dangerous-action warnings remain enabled.
- The installer gives restart guidance and does not launch another client.
- Initial connection secrets are never placed in command-line arguments; `/C`
  carries only a one-time user-scoped handoff identifier.
- Removal is a separate confirmed destructive action and does not promise data
  backup or preservation.
- Russian and English UI text follows the current 1C session language.

## Evidence and authority

The current installer source was inspected and its legacy identity, discarded
selected bytes, placeholder download, mixed form-module structure, automatic
client launch, and immediate removal behavior were recorded in the child tasks.
No application source, build artifact, or infobase was changed during refinement.

`/workspace/build/ib` is authorized as a disposable target only while implementing
a child task that explicitly requires installation, update, removal, or reset.
T005 may prepare a draft GitHub release; final publication is a separate delivery
action. Every child task records source, build, runtime, and delivery evidence
independently.

## Completion evidence

- Source review: complete for decomposition.
- Build/runtime: not run; outside this planning task.
- Task map: T002–T013 created and reviewed.
- Ready tasks: T002 and T005.
- Deferred tasks: T006, T011, and T012.
