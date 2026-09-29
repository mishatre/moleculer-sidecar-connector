# T008 — install the explicitly selected connector artifact

Status: draft
Depends on: T007
Recipe: normal
Coordinator: Sol Medium
Worker: integration specialist, Sol High
Reviewer: Sol Medium

## Decision card

Outcome: an administrator explicitly installs, updates, downgrades, or activates
the chosen connector version and sees the refreshed 1C state.
Included: one bundled/GitHub payload contract, confirmation, write/error handling,
status refresh, update/downgrade policy, and inactive activation.
Deferred: source discovery, bundling, local files, removal, and UI polish.
Success: bundled and downloaded artifacts follow the same exact write path, and
failures do not get reported as success.
Next: implement after T007; use `/workspace/build/ib` for runtime evidence.

## Acceptance and consumer example

- [ ] Installation receives the exact artifact and source/version metadata chosen
      in T007; the server does not reselect or replace it.
- [ ] Accept only the bundled artifact or an exact asset selected from T004;
      preserve its source/version metadata and bytes through the write.
- [ ] Confirm the mutating action with source and version visible to the user.
- [ ] On success, reload installed state from 1C and display actual identity,
      version, and active status.
- [ ] On partial/write failure, show the platform error, reload actual state, and
      do not claim rollback unless verified.
- [ ] Require an additional explicit warning before installing an older version.
- [ ] Do not routinely rewrite an active connector at the same version.
- [ ] When the same version is installed but inactive, confirm and activate the
      existing extension without rewriting its artifact.
- [ ] Keep safe mode disabled for connector operation while retaining 1C
      dangerous-action warnings.
- [ ] Show restart guidance after a successful state change; do not launch another
      client automatically.
- [ ] Preserve existing restrictions for web client, ordinary application,
      permissions, compatibility, and connector built into the configuration.

## Context and verification

This is the consumer integration task for T003–T007. Runtime verification in
`/workspace/build/ib` covers install, update, confirmed downgrade, same-version
no-op, inactive activation, retry, and failed-write behavior. Removal belongs to
T013. Publication/deployment remains separately authorized.
