# T004 — fetch connector versions after explicit GitHub selection

Status: draft
Depends on: T003, T005
Recipe: normal
Coordinator: Sol Medium
Worker: integration specialist, Sol High
Reviewer: Sol Medium

## Decision card

Outcome: after the administrator explicitly selects GitHub as the source, the
installer lists installable connector versions published by this project.
Included: release metadata retrieval, SemVer filtering, prerelease labels,
timeout/error handling, and a normalized version/artifact catalog.
Deferred: artifact installation, signature validation, and generic repository
providers.
Success: no request occurs before GitHub selection; success, timeout/rate-limit,
malformed response, and no-matching-asset cases leave bundled installation usable.
Next: implement after T005 publishes the first contract-compliant release.

## Acceptance and consumer example

- [ ] Use the canonical project repository `mishatre/moleculer-ones`.
- [ ] Before GitHub is explicitly selected, perform no DNS/HTTP/API call; do not
      add a separate enable/disable setting.
- [ ] After selection, fetch with bounded timeout and parse only releases/assets that
      match the documented connector artifact contract.
- [ ] Accept canonical `v{semver}` tags, including prereleases, and match exactly
      `MoleculerSidecarConnector-v{semver}.cfe`.
- [ ] Normalize tag, connector version, prerelease flag, download URL, and asset
      identity without mixing UI logic into transport/parsing.
- [ ] Network, authentication, API limit, and schema failures produce a useful
      nonfatal status; the bundled choice remains available.
- [ ] Never send infobase credentials or connection parameters to GitHub.

## Context and verification

The current download routine is a placeholder returning `Undefined`. Use the
GitHub releases API for `mishatre/moleculer-ones`. Show all matching stable and
prerelease versions with prereleases visibly labeled. Tests use fixed fixtures
for success, malformed data, timeout, rate limit, and missing assets plus one
authorized live integration check; ordinary tests never depend on GitHub.
