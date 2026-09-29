# Moleculer sidecar connector

Status: existing project; architecture baseline documented; installer refinement
decomposed and reviewed. A second workstream — a standalone CFE builder plus test
suites — is planned and ready to start at T014.
Immediate next action: independently review the generator and the generated
variant (T015), then resolve the 1C client-library blocker, which gates the BSL
test workstream T017–T022. The installer roadmap T001–T013 is unchanged and
remains an independent workstream.

## Known purpose

The user describes a 1C extension/integration for exposing Moleculer-style
services from 1C infobases through a sidecar. Development uses a Linux dev
container for headless 1C tooling on macOS. Detailed feature goals are refined
from the actual implementation and the approved production-readiness direction.

## Architecture baseline

- [Connector architecture, public interface, and production-readiness audit](connector-architecture-audit.md)
- [Connector and sidecar protocol/interaction baseline](connector-sidecar-protocol.md)
- [Installer baseline and preserved roadmap](installer-baseline.md)

These documents describe current behavior separately from target direction.
They do not authorize application changes or create task IDs. Connector and
sidecar work will be planned as coordinated but separate workstreams only after
this baseline is reviewed; the EPF installer remains a third workstream.

## Standalone builder and test suites (T014–T022)

Two requested results are planned as one workstream with a shared prerequisite:

1. **Standalone builder.** The canonical CFE is a combined runtime, persistence,
   administration and developer-tool package. A committed generator under
   `tools/standalone-builder/` produces a database-free variant: no constants, no
   catalogs, no dynamic services, no admin panel, settings declared only inside
   overrideable modules, and common modules merged where safe. Aggressive merge
   into two modules is agreed: `Moleculer` (public facade, name preserved) and
   `MoleculerOverridable` (settings and provider seam). Client contexts, the
   administration/laboratory UI, the Monaco editor wrapper and the dead YAML
   parser copies are dropped from the variant.
2. **Test suites.** Every critical part of the connector core gains executable
   tests: transport, context factory, errors, broker, schema factory, the public
   facade, the overrideable provider, helpers/logger and the reusable-value and
   ambient-context behaviour. Tests run in two disposable infobases, one in
   extension mode and one in standalone mode, because `IsStandalone()` depends on
   which CFE is loaded, not on the infobase content. The builder's own
   transformation logic is tested container-only.

Deliberately deferred: publishing artifacts, guiding the installer's standalone
path, sidecar-to-connector end-to-end integration, and any change to the canonical
extension sources. The builder reads them and never rewrites them.

Delivered 2026-09-29: `tools/standalone-builder/` (a Python generator, profile and
README) emits the variant and compiles it; the artifact loads, applies and passes
the platform metadata check in a database-free infobase. 30 container-only tests
guard the transformation. The BSL behavioural suites remain blocked by the missing
1C client libraries.

T014 verified the toolchain on 2026-09-29. Available headlessly: `vrunner cfe
compile --ibcmd`, `vrunner infobase init --ibcmd`, `ibcmd config check`, and the
container-only suites. The 1C client's missing libraries were fixed afterwards
(`tools/1c-platform/install-client-runtime.sh`, wired into the devcontainer), so the
binary now loads; what remains is a missing 1C licence, which blocks `1cv8`-based
compilation, `vrunner validate syntax-check` and every
`vrunner test yaxunit|xunit|vanessa` run. The BSL test framework choice therefore
stays open until a licence (or a headless JRE plus `bsl-language-server`) is
available. The installed `vrunner` is 3.0.0, so the 2.x commands still recorded in
T005 and elsewhere are stale.

## Current repository facts

- Dev service mounts this repository at `/workspace`, targets `linux/amd64`,
  and builds from `local/vrunner2:8.3.24.1667`.
- Extension tree: `src/cfe/MoleculerSidecarConnector/`.
- Configuration source: `src/cf/`; external processor source: `src/epf/`.
- Existing work includes source moves/deletions and local editor changes.
- README contains bootstrap guidance that does not fully match current files.
- The current user-owned `.gitignore` ignores `docs/`; planning documents are
  saved in this workspace but are not part of a normal Git diff or clean
  checkout. This documentation operation does not alter that repository policy.

## Scope now / later

Now: implement T014 (toolchain, test runner and test hosting spike), then T015
(standalone builder), then T016/T017. In parallel the installer workstream keeps
T002 then T005 as its ready tasks; T001 has decomposed installer refinement into
form cleanup, reproducible release artifacts, installed-state discovery,
bundled/GitHub version selection, safe installation, initial connection setup,
removal, and bilingual UI.
Later: research safe local CFE inspection (T006), specify optional SSL/BSP role
protection (T011), and add evidence-backed installed validation (T012).
The disposable `/workspace/build/ib` is authorized for runtime mutations only
while implementing a task that explicitly requires those checks. Planning and
read-only setup do not authorize modifying it. A second disposable infobase for
standalone-mode tests is planned by T017 and is not yet created.

See [task index](index.md) and [environment](environment.md).
