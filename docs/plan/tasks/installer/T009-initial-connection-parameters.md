# T009 — hand off validated initial connection parameters safely

Status: draft
Depends on: T008
Recipe: normal
Coordinator: Sol Medium
Worker: integration specialist, Sol High
Reviewer: Sol Medium

## Decision card

Outcome: an administrator supplies initial parameters that are safely handed to
the restarted session and saved into the connector's predefined Default connection.
Included: essential fields, simple validation, user-scoped one-time handoff,
automatic import, defaults, cleanup, and secret handling.
Deferred: live connection tests, certificate validation, proxy setup, and advanced
authentication.
Success: valid parameters create and enable Default after restart; validation,
import, and cleanup failures are actionable without exposing secrets.
Next: refine storage API details after T008 establishes the restart boundary.

## Acceptance and consumer example

- [ ] Collect endpoint, port, `UseSSL`, access key, and secret key. Remove the old
      split sidecar/node model from this flow.
- [ ] Require endpoint, access key, and secret key; validate port as an integer in
      the supported TCP range; keep TLS explicit.
- [ ] Use timeout 120 and set predefined `Default` enabled without exposing those
      as installer fields.
- [ ] Never include access/secret values in errors, logs, GitHub calls, or ordinary
      form-state diagnostics.
- [ ] Store the payload temporarily for the current 1C user, keyed by a random
      one-time identifier. Pass only that identifier through `/C`.
- [ ] After restart, atomically consume the matching handoff, update predefined
      `Default`, report the result, and delete the handoff on success or terminal
      failure. Reject missing, expired, reused, or wrong-user identifiers.
- [ ] Separate input validation, temporary persistence, import, and connector
      installation responsibilities.
- [ ] Do not claim connectivity from syntactic validation.
- [ ] Save automatically only after the user confirms the destination and install
      review; do not claim connectivity from the successful write.

## Context and verification

The connector stores endpoint, port, TLS, access key, secret key, timeout, and
enabled status in `Catalog.mol_Connections` and defines predefined `Default`.
The existing connector launch parameter handles role recovery only; T009 adds a
separate opaque handoff contract and never places credentials in command lines.
Runtime verification uses `/workspace/build/ib` and covers validation boundaries,
credential non-disclosure, successful import, failure, replay, and cleanup.
