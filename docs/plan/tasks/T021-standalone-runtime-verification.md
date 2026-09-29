# T021 — Standalone variant runtime verification

Status: blocked — requires a runnable 1C client for the HTTP round-trip; loading
the artifact itself is already proven possible via ibcmd
Depends on: T015, T017
Recipe: normal
Coordinator: Sol Medium
Worker: Terra Medium
Reviewer: Sol Medium

## Decision card

Outcome: the generated standalone `.cfe` is proven to load and work in an
infobase without the extension's catalogs and constants.
Included: loading the artifact, asserting standalone detection, configuration
resolution through `MoleculerOverridable`, and an inbound HTTP round-trip.
Deferred: sidecar-to-connector end-to-end integration and the manual host-config
migration rehearsal.
Success: the standalone infobase reports `Moleculer.IsStandalone() = True`, a call
uses injected settings, and `POST /moleculer/sidecar` is served.
Next: T022 quality gate and delivery documentation.

## Acceptance and consumer example

- [ ] The generated `.cfe` loads into the standalone-mode infobase without errors.
- [ ] `Moleculer.IsStandalone()` returns `True` and `Moleculer.GetConfig()` returns
      the settings injected by the profile.
- [ ] `Moleculer.GetConnections()` and `GetPublications()` return the provider's
      data, not the stub sample rows.
- [ ] An inbound `POST /moleculer/sidecar` request reaches the transport handler
      and produces the expected response shape for a fixture request.
- [ ] An outbound action call fails in a controlled, documented way when no sidecar
      is reachable, rather than leaking safe-mode state or an unhandled error.
- [ ] The suite runs against `build/ib-standalone`, created by T017.

## Implementation context

Entry point: the T017 harness plus `vrunner` CFE load/compile commands verified in
T014.
Relevant files: `build/standalone/`, the generated `Moleculer` and
`MoleculerOverridable` modules, `build/ib-standalone`.
Constraints: only the disposable standalone base may be mutated. No live sidecar is
assumed; the outbound path is asserted for controlled failure only.
Unknowns: whether the HTTP service publishes in a file infobase in this container.

## Environment and verification

Commands: load the artifact; run the filtered suite; issue the fixture request.
Expected: load exit 0; suite 0 failures; response matches the fixture.

## Delivery and authority

Deliverable: test modules for standalone mode and recorded evidence. Reversal:
delete `build/standalone/` and `build/ib-standalone`.

## Stop conditions

Stop if the artifact does not load; record the compiler or load error and return to
T015 rather than editing the generated tree by hand.

## Completion evidence / resume point

Record: artifact hash, load command and result, suite output, fixture request and
response, and the exact behaviour of the outbound failure path.

## Optional pilot metrics

Actual models/efforts:
Elapsed time / repair rounds / human review minutes:
