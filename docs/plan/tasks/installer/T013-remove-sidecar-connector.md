# T013 — remove the Moleculer sidecar connector safely

Status: draft
Depends on: T003
Recipe: normal
Coordinator: Sol Medium
Worker: integration specialist, Sol High
Reviewer: Sol Medium

## Decision card

Outcome: an administrator can explicitly remove only
`MoleculerSidecarConnector` and see the authoritative post-action state.
Included: destructive warning, confirmation, targeted deletion, status refresh,
error/recovery handling, and restart guidance.
Deferred: data backup/restore, legacy-extension removal, and optional companion
extension removal.
Success: cancellation changes nothing; confirmed deletion targets only the current
connector and never reports success when 1C retains it.
Next: refine after T003 stabilizes the installed-state contract.

## Acceptance and consumer example

- [ ] Offer removal only when T003 reports `MoleculerSidecarConnector` installed.
- [ ] Warn that connector-owned settings, including connection data, may be lost;
      require explicit confirmation before the server-side delete.
- [ ] Target the exact current connector identity and ignore legacy
      `MoleculerOneS` and unrelated extensions.
- [ ] On cancellation, perform no write and preserve the displayed state.
- [ ] On success or failure, reload actual 1C state rather than trusting the
      command result; show the platform error when deletion fails.
- [ ] After successful removal, show manual restart guidance without launching a
      new client session automatically.
- [ ] Keep backup/export, restoration, and removal of connector-created user roles
      outside this task until concrete requirements exist.

Consumer example: an administrator selects **Remove connector**, reads the data-
loss warning, and confirms. The installer deletes only
`MoleculerSidecarConnector`, reloads installed state, and shows restart guidance.

## Implementation context and verification

The current form calls the extension delete immediately without confirmation.
Reuse T003's authoritative identity/state loader and T002's `ManageForm` pattern.
Keep removal independent from T008's artifact write path.

Runtime verification in `/workspace/build/ib` must cover cancellation, confirmed
deletion, insufficient permission, platform deletion failure, state refresh, and
restart guidance. Record source, build, runtime, and delivery evidence separately.

## Stop conditions

Stop if implementation would remove another extension, silently delete without a
warning, promise preservation of connector-owned data, or broaden into backup and
restore behavior. Do not mutate a non-disposable infobase.
