# Project Core

- 1C extension/integration exposing Moleculer-style services from 1C infobases through a sidecar.
- Repository root is the current checkout; dev-container path is `/workspace`. Run 1C/OneScript commands there.
- Source map: base configuration `src/cf/`; extension `src/cfe/MoleculerSidecarConnector/`; installer external processor `src/epf/installer/`.
- Generated artifacts and disposable infobase belong under `build/`; OneScript dependencies belong under `oscript_modules/`. Do not commit generated build output.
- Working tree contains extensive intentional moves/deletions and editor changes. Preserve unrelated existing changes.
- Root README is inherited bootstrap guidance and references absent scripts; it is not an authoritative command source.
- Project workflow/state lives under `docs/workflow.md` and `docs/plan/`; the selected issue is the source of truth for scope and evidence.
- Read `mem:tech_stack` for platform/tool versions and formats.
- Read `mem:suggested_commands` for verified environment and build command forms.
- Read `mem:conventions` before editing source or workflow documents.
- Read `mem:task_completion` for required evidence and validation boundaries.
- Read `mem:cfe/core` for extension structure and release invariants.
- Read `mem:installer/core` for installer source, bundling, and verification boundaries.