# Moleculer sidecar connector

Status: existing project. The architecture baseline is documented, the connector and the
standalone variant build, and the BSL suites run in both modes. Where the work stands is in the
domain cards under [tasks/](tasks/), which route to the GitHub issues; this page describes the
project, not the task list.

## Known purpose

A 1C extension and integration that exposes Moleculer-style services from 1C infobases through
a sidecar. Development uses a Linux dev container for headless 1C tooling on macOS. Detailed
feature goals are refined from the actual implementation and the approved production-readiness
direction.

## Architecture baseline

- [Connector architecture, public interface and production-readiness audit](notes/connector-architecture-audit.md)
- [Connector and sidecar protocol/interaction baseline](notes/connector-sidecar-protocol.md)
- [Installer baseline and preserved roadmap](notes/installer-baseline.md)

These describe current behaviour separately from target direction. They do not authorize
application changes and they do not define tasks.

## The standalone variant

The canonical CFE is a combined runtime, persistence, administration and developer-tool package.
A committed generator under `tools/standalone-builder/` produces a database-free variant: no
constants, no catalogs, no dynamic services, no admin panel, settings declared only inside
overridable modules, and common modules merged where that is safe.

Agreed shape of the merge: two modules, `Moleculer` (public facade, name preserved) and
`MoleculerOverridable` (settings and the provider seam). Client contexts, the administration and
laboratory UI, the Monaco editor wrapper and the dead YAML parser copies are dropped from the
variant. The generator reads the canonical sources and never rewrites them.

Test hosting follows the variant, not the infobase: `IsStandalone()` depends on which CFE is
loaded, so the suites run in two disposable infobases, one per mode, and the builder's own
transformation logic is tested container-only.

Deliberately out of scope for the variant: publishing artifacts, guiding the installer's
standalone path, and sidecar-to-connector end-to-end integration.

## Current repository facts

- The dev service mounts this repository at `/workspace`, targets `linux/amd64`, and builds from
  `local/vrunner:8.3.24.1667`.
- Each Orca worktree starts its own container through `orca.yaml` →
  `tools/orca/container.sh up`; VS Code's "Reopen in Container" reaches the same container for the
  same worktree. The container carries `DISPLAY=host.docker.internal:0`, so the 1C client draws on
  the host's XQuartz server, and `gh` authenticated from the host token.
- Extension source: `src/cfe/MoleculerSidecarConnector/`. Configuration source: `src/cf/`.
  External processor source: `src/epf/`.
- Generated artifacts and disposable infobases live under `build/`; OneScript dependencies under
  `oscript_modules/`.
- The tasks are GitHub issues in `mishatre/moleculer-sidecar-connector`: one milestone per domain,
  `domain:`/`status:`/`recipe:` labels, one pull request per task.
- The remote still answers to the old repository name `moleculer-ones`, which GitHub redirects.
- `docs/` is tracked by git, including `docs/plan/`. (An earlier revision of this page said it
  was ignored; that was wrong.)
- The root `README.md` still contains bootstrap-template instructions that do not match the
  current files, and the VS Code task and debug entries mix Windows syntax with Linux paths.
  Treat both as unverified until a task checks them.
- `moleculer-sidecar-next/` is a read-only upstream reference copy and is not tracked by git.

## Direction

Near term, the open work sits in three places: the installer roadmap
([INST](tasks/installer/index.md)), the connector refactor cycle
([CORE](tasks/core/index.md)) and bringing the tree to the code standards
([STYLE](tasks/style/index.md)). Longer term, the connector gains local service-definition
parsing and a rebuilt form layer, both waiting on owner decisions recorded in their tasks.

Verified commands, their limits and who can run what are in [environment.md](environment.md) —
that page is the authority for tooling, not this one.
