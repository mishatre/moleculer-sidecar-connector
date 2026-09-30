# T021 — Standalone variant runtime verification

Status: verified. Every acceptance item is covered by the evidence below: standalone mode is 18/18 in
YAxUnit, and the inbound HTTP round-trip passes against both bases, each confirmed to have been
answered by the artifact under test rather than by whatever else the base happens to contain.
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

- [x] The generated `.cfe` loads into the standalone-mode infobase without errors. Verified in
      `build/ib-tests`, the base this path actually uses; `build/ib-standalone` is named by the
      original wording but is not that base.
- [x] `Moleculer.IsStandalone()` returns `True` and `Moleculer.GetConfig()` returns
      the settings injected by the profile.
- [x] `Moleculer.GetConnections()` and `GetPublications()` return the provider's
      data, not the stub sample rows.
- [x] An inbound `POST /moleculer/sidecar` request reaches the transport handler
      and produces the expected response shape for a fixture request.
- [x] An outbound action call fails in a controlled, documented way when no sidecar
      is reachable, rather than leaking safe-mode state or an unhandled error.
- [x] The suite runs against the standalone base the harness uses (`build/ib-tests`, created by T017).

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

Verified 2026-09-29:

- artifact regenerated from current sources by `tools/standalone-builder/build-standalone.py`:
  `build/standalone/MoleculerSidecarConnectorStandalone.cfe`, 38 587 bytes, sha256
  `8f826b30c5e832d6ad42b9c40a818173340f3ea165df0210e7830357d2322376`;
- standalone suite green against `build/ib-tests`: **14/14**, exit 0
  (`tests/bsl/run-tests.sh --mode standalone`).
- These numbers describe the state at the moment of verification and are not maintained afterwards:
  the artifact has been regenerated more than once since, after the T023 `NStr` fix and after the
  `mol_Broker.Broadcast` fix, and the standalone suite stayed green through those rebuilds. Treat the
  hash above as the record of what was verified, not as a value to keep in sync with every rebuild.

Covered since, by `tests/bsl/standalone/CommonModules/StandaloneRuntimeTests` (4 tests), taking
standalone mode to **18/18** in 41 s:

- `TheVariantKnowsItIsStandalone` — `IsStandalone()` is
  `Metadata.FindByFullName("Catalog.mol_Services") = Undefined`, so this asserts the builder dropped
  the catalog rather than that a flag is set;
- `ConfigurationComesFromTheProvider` — `ExtVersion = "0.2.0 beta 4"`, `Namespace = ""`,
  `ExtAdminRole = ""`, `ModulePrefix = "Service"`. The first three are assigned **only** by
  `MoleculerOverridable`, so they show the provider seam is wired up;
- `TheProviderDeclaresNoConnectionsOrPublications` — empty through both the provider
  (`GetConnections(Истина)`) and the reuse-cached entry point the runtime actually calls;
- `AnOutboundCallWithoutASidecarFailsControlled` — the call raises, the session is not left in safe
  mode, and the message is `MoleculerServerError: Нет доступных подключений к sidecar. Невозможно
  отправить запрос` raised from `ОбщийМодуль.Moleculer.Модуль(654)`. That is the controlled,
  documented failure the acceptance asks for.

The inbound `POST /moleculer/sidecar` round-trip now runs against both bases.
`tests/bsl/http/test-inbound-transport.sh` takes `--mode canonical|standalone` and, with no argument,
verifies both as separate child invocations, so each base keeps its own server lifecycle and its own
counters. Both report **9 passed, 0 failed**, with the same two recorded gaps: a malformed and an
empty body are answered by the platform's own 500 page instead of the error envelope. That defect
belongs to the error taxonomy work, not here, and it reproduces identically in both variants.

Each mode also proves that *its* artifact answered. The platform's error page names the extension, so
the run asserts that it names `MoleculerSidecarConnector` for `build/ib` and
`MoleculerSidecarConnectorStandalone` for `build/ib-tests`. Without that check a pass could come from
the wrong extension: both variants declare an HTTP service with the same metadata name and root.

Generator facts the assertions should use: the builder emits `MoleculerOverridable` with
`ModulePrefix = "Service"`, `LogLevel = "Info"`, `ExtVersion = "0.2.0 beta 4"` and no connections or
publications; `Moleculer.IsStandalone()` is
`Metadata.FindByFullName("Catalog.mol_Services") = Undefined`, so asserting it also asserts that the
builder dropped the catalog. `Moleculer.Call(ActionName, Params, Opts)` is the outbound entry point.

## Optional pilot metrics

Actual models/efforts:
Elapsed time / repair rounds / human review minutes:
