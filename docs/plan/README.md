# Plan

Project state, task files and the rules for recording them.

This page lists **domains, never tasks**. It changes when a domain is added, which is rare, so
two conversations working on unrelated tasks never edit the same file. Task status lives in the
task file and is mirrored only by that domain's index.

## Start here

| I want to… | Read |
|---|---|
| Know what the project is for and where it is going | [project.md](project.md) |
| Know which commands actually work in this container | [environment.md](environment.md) |
| Create, refine, implement or review a task | [../workflow.md](../workflow.md) and [../workflow-prompts/](../workflow-prompts/) |
| Know how task files, IDs and statuses work | [conventions/tasks.md](conventions/tasks.md) |
| Know which domain a change belongs to | [conventions/domains.md](conventions/domains.md) |
| Write the commit that finishes a task | [conventions/commits.md](conventions/commits.md) |
| See the retired `T000`–`T040` numbers | [notes/legacy-ids.md](notes/legacy-ids.md) |

## Domains

| Prefix | Domain | Index | Scope |
|---|---|---|---|
| `GLOB` | Repository-wide files and hygiene | [index](tasks/global/index.md) | root files, licensing, tree-wide hygiene |
| `STYLE` | Code standards and conformance | [index](tasks/style/index.md) | `docs/code-standards/`, regions, comments, annotations |
| `CORE` | Canonical connector | [index](tasks/core/index.md) | `src/cfe/`, `src/cf/`, canonical suites |
| `STAND` | Standalone builder and variant | [index](tasks/standalone/index.md) | `tools/standalone-builder/`, standalone suites |
| `INST` | Installer | [index](tasks/installer/index.md) | `src/epf/` |
| `TOOLS` | Container and build machinery | [index](tasks/tooling/index.md) | `.devcontainer/`, `tools/`, harness scripts |
| `DOC` | Documentation for readers | [index](tasks/documentation/index.md) | `docs/` minus standards and plan |
| `FLOW` | The working system | [index](tasks/workflow/index.md) | `AGENTS.md`, workflow prompts, `docs/plan/` |

A task file is `tasks/<domain>/<ID>-<slug>.md`, and a finished one sits in
`tasks/<domain>/history/`. Pick the domain before picking the number: the number counts inside
the domain only, so no shared counter needs to be updated.

## Files in this folder

- `project.md` — purpose, current need, architectural boundaries, direction. Read-mostly.
- `environment.md` — the verified commands, their limits and who can run what. Read-mostly.
- `conventions/` — `domains.md`, `tasks.md`, `commits.md`. The rules other domains read.
- `templates/` — `task.md`, `index.md`, `project.md`, `environment.md`.
- `tasks/<domain>/` — the task files and their indexes.
- `notes/` — long-form architecture, research and history that no routine task touches.

## Boundaries

- Planning documents describe and route. They do not authorize application changes; a task does.
- Only a `FLOW` task edits this folder's routers, conventions or templates.
- Only the domain that owns a task edits that task's file, its index row and its history.
- A cross-domain dependency is recorded in the task's `Depends on` line. It blocks that task
  alone, never another domain.
