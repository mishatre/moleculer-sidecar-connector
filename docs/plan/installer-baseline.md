# MoleculerSidecarConnector installer baseline

Status: documentation baseline, 2026-09-10. The installer is an EPF deployment workstream, separate from the CFE runtime and Node sidecar. This document preserves the approved T002–T013 roadmap; it creates no task and changes no installer behaviour.

## Current implementation

The EPF lives in [src/epf/installer](../../src/epf/installer). Its managed-form module is [installer form module](../../src/epf/installer/installer/Forms/Форма/Ext/Form/Module.bsl); its ordinary form warns that ordinary application is unsupported. The current code identifies the extension as `MoleculerOneS`, uses an embedded template of that name, and sets a version from the EPF comment. This conflicts with the canonical connector identity `MoleculerSidecarConnector` and the release contract in [environment](environment.md).

Observed behaviours and defects:

- The client may load a selected file or call an unimplemented download function, but `УстановитьРасширениеНаСервере` discards its bytes and always loads the legacy embedded template.
- Installation creates/updates an extension, disables safe mode and dangerous-action warnings, then calls an empty rights-grant procedure. It may schedule another client session; approved roadmap direction is to give restart guidance instead.
- Installed-state handling is incomplete and legacy-oriented. Removal executes immediately with no destructive confirmation.
- The form mixes responsibilities and contains dead/unreachable statements after returns. UI text is predominantly Russian despite planned bilingual support.
- No evidence proves an EPF build, connector artifact selection, installation, upgrade, removal, user-rights outcome, or runtime behavior.

## Current UI and callable surface

The managed form is the operational entrypoint. On creation/open it initializes platform/version state and derives installer presentation. `УстановитьРасширение` obtains selected/downloaded bytes on the client and passes them to the server routine; `УдалитьРасширение` immediately invokes server removal. Navigation-link handlers may launch or cancel a new client session. The ordinary form only cancels opening and reports that direct use is unsupported.

Server-side helpers load current extension state through `РасширенияКонфигурации`, set extension properties, install the bundled template, remove the extension, and contain the currently empty rights hook. Platform/compatibility helpers parse and compare version segments. Exported form helpers are `ЭтоПлатформаWindows`, `ЭтоУчебнаяПлатформа`, and `ИмяИсполняемогоФайлаПлатформы`; they are implementation conveniences rather than an installer automation API. There is no documented programmatic EPF contract, machine-readable result, progress model, cancellation result, or structured install/remove error response.

Current installation flow:

```text
Open managed EPF form → inspect platform/current extension → choose install
→ obtain file/template bytes on client → server ignores supplied bytes
→ load embedded MoleculerOneS template → set extension properties
→ empty rights hook → optional new-session launch
```

The target installer should continue to be a guided interactive tool unless a separate automation contract is deliberately specified; internal form exports must not accidentally become that contract.

## Existing roadmap (preserved)

The authoritative task sequence remains [T001](tasks/history/T001-refine-sidecar-connector-installer.md) and [the task index](index.md):

1. T002 refactors the form module without behavior change.
2. T005 reproducibly builds and bundles a traceable connector CFE artifact.
3. T003 detects canonical installed connector presence, active state and SemVer.
4. T004 discovers GitHub releases only after explicit user source selection.
5. T007 selects bundled/GitHub version and recommends update.
6. T008 installs, updates, downgrades or activates the selected artifact.
7. T009 hands off validated initial default connection settings without command-line secrets.
8. T013 removes only the connector after explicit destructive confirmation.
9. T010 completes a useful Russian/English guided UI.

T006 (safe local CFE inspection), T011 (optional SSL/BSP role protection), and T012 (deeper installed validation) remain deferred until their stated prerequisites. The immediate ready tasks are T002 then T005; this baseline does not change their status or scope.

## Target contract and security boundaries

The installer must manage only canonical `MoleculerSidecarConnector`, use the released CFE matching its own declared release contract, and report authoritative installed identity/state/version. Bundled artifact is the default; GitHub is consulted only after the user selects it. Same-version active installations should not be rewritten, inactive same-version installations can be activated, and downgrades need a distinct warning.

Installation/update/removal must be explicit user actions. Removal requires confirmation and must not claim data backup/preservation. Safe mode remains disabled only as required by the connector; dangerous-action warnings remain enabled. Runtime startup must never grant rights. The installer may offer a separately confirmed, audited minimum-role grant to the current platform administrator and explain required session restart. Secrets must never enter command-line arguments; the settled T009 handoff uses a one-time user-scoped identifier only.

Standalone export/integration is a future guided path, not silent host-configuration rewriting. It depends on the connector core/provider design described in [connector architecture audit](connector-architecture-audit.md).

## Artifact and validation contract

Canonical SemVer comes from [CFE Configuration.xml](../../src/cfe/MoleculerSidecarConnector/Configuration.xml). Release names are `MoleculerSidecarConnector-v{semver}.cfe` and `MoleculerSidecarConnectorInstaller-v{semver}.epf`, with `SHA256SUMS.txt`; T005 produces a local draft-release directory. GitHub publishing is not implicitly authorized.

Each future installer task records source/static, build, disposable-infobase runtime and delivery evidence separately. Relevant acceptance coverage includes install, update, activate, downgrade warning, installed-state detection, source selection, secret-safe initial connection handoff, self-grant authorization/restart, bilingual UI, and confirmed removal. `/workspace/build/ib` is mutable only when the selected task explicitly authorizes it.

## Known unknowns

The supported mechanism for read-only local CFE identity inspection is deferred. The optional SSL/BSP artifact has not been supplied. There is no evidence for Web-client support, actual platform-permission behavior, release download/authentication, or preservation behavior after removal. These are tracked by the existing task dependencies rather than assumed here.
