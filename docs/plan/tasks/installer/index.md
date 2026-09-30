# INST — installer

Scope: `src/epf/` — the installer external data processor.
Next free ID: `INST-001`
Rules: [tasks](../../conventions/tasks.md) · [domains](../../conventions/domains.md) · [commits](../../conventions/commits.md)

Next recommended task: **T002**, which unblocks T003, T005, T013. T005 is also ready and
independent of T002's outcome.

The roadmap that produced these tasks, with the reasoning per item, is
[installer-baseline.md](../../notes/installer-baseline.md).

## Open

| ID | Outcome | Status | Depends on | File |
|---|---|---|---|---|
| T002 | Installer form module follows official structure without behavior change | ready | none | [Task](T002-refactor-installer-form-module.md) |
| T003 | Installer reports installed connector presence, state, and version | draft | T002 | [Task](T003-detect-installed-connector.md) |
| T004 | Explicit GitHub source selection returns available connector versions | draft | T003, T005 | [Task](T004-fetch-github-connector-versions.md) |
| T005 | Installer build reproducibly bundles a traceable connector artifact | ready | none | [Task](T005-build-and-bundle-installer.md) |
| T006 | Safe local CFE inspection feasibility is researched | deferred | supported inspection mechanism | [Task](T006-validate-selected-cfe.md) |
| T007 | Installer selects bundled/GitHub version and recommends updates | draft | T003–T005 | [Task](T007-select-version-and-recommend-update.md) |
| T008 | Installer installs, updates, or activates the selected connector | draft | T007 | [Task](T008-install-selected-connector-artifact.md) |
| T009 | Initial Default connection parameters are handed off safely | draft | T008 | [Task](T009-initial-connection-parameters.md) |
| T010 | Guided installer UI is useful in Russian and English | draft | T009, T013 | [Task](T010-refine-installer-ui-and-texts.md) |
| T011 | Optional SSL/BSP role-protection extension is specified | deferred | user details; T005, T008 | [Task](T011-optional-ssl-role-protection-extension.md) |
| T012 | Installed connector receives deeper compatibility validation | deferred | concrete failure cases; T003, T008 | [Task](T012-validate-installed-connector.md) |
| T013 | Installer removes only the connector after destructive confirmation | draft | T003 | [Task](T013-remove-sidecar-connector.md) |

## Closed

| ID | Outcome | Closed | File |
|---|---|---|---|
| T001 | Installer refinement is decomposed into bounded outcomes | verified | [Task](history/T001-refine-sidecar-connector-installer.md) |
