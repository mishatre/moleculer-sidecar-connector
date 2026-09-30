# Plan

Project state, the task tracker and the rules for recording work.

This page lists **domains, never tasks**. It changes when a domain is added, which is rare, so two
conversations working on unrelated tasks never edit the same file. Task state lives on GitHub, in
the domain's milestone.

## Start here

| I want to… | Read |
|---|---|
| Know what the project is for and where it is going | [project.md](project.md) |
| Know which commands actually work in this container | [environment.md](environment.md) |
| Create, refine, implement or review a task | [../workflow.md](../workflow.md) and [../workflow-prompts/](../workflow-prompts/) |
| Know how issues, IDs, labels and statuses work | [conventions/tasks.md](conventions/tasks.md) |
| Know which domain a change belongs to | [conventions/domains.md](conventions/domains.md) |
| Write the branch, commit and pull request that finish a task | [conventions/commits.md](conventions/commits.md) |
| See the retired `T000`–`T040` numbers | [notes/legacy-ids.md](notes/legacy-ids.md) |

## Domains

A task is a GitHub issue in `mishatre/moleculer-sidecar-connector`, labelled `domain:<x>` and filed
in the milestone with the same prefix. Each domain has a card that routes to those queries.

| Prefix | Domain | Issues | Scope |
|---|---|---|---|
| `GLOB` | Repository-wide files and hygiene | [card](tasks/global/index.md) | root files, licensing, tree-wide hygiene |
| `STYLE` | Code standards and conformance | [card](tasks/style/index.md) | `docs/code-standards/`, regions, comments, annotations |
| `CORE` | Canonical connector | [card](tasks/core/index.md) | `src/cfe/`, `src/cf/`, canonical suites |
| `STAND` | Standalone builder and variant | [card](tasks/standalone/index.md) | `tools/standalone-builder/`, standalone suites |
| `INST` | Installer | [card](tasks/installer/index.md) | `src/epf/` |
| `TOOLS` | Container and build machinery | [card](tasks/tooling/index.md) | `.devcontainer/`, `tools/`, harness scripts |
| `DOC` | Documentation for readers | [card](tasks/documentation/index.md) | `docs/` minus standards and plan |
| `FLOW` | The working system | [card](tasks/workflow/index.md) | `AGENTS.md`, workflow prompts, `.github/`, `docs/plan/` |

## Files in this folder

- `project.md` — purpose, current need, architectural boundaries, direction. Read-mostly.
- `environment.md` — the verified commands, their limits and who can run what. Read-mostly.
- `conventions/` — `domains.md`, `tasks.md`, `commits.md`. The rules other domains read.
- `templates/` — `project.md` and `environment.md`, for planning a new project.
- `tasks/<domain>/index.md` — a card that routes to that domain's issues. It holds no state.
- `notes/` — long-form architecture, research and history that no routine task touches.

## Boundaries

- Planning documents describe and route. They do not authorize application changes; an issue does.
- Only a `FLOW` task edits this folder's routers, conventions or templates.
- Only the domain that owns a task edits that task's issue, its card and its notes.
- A cross-domain dependency is recorded in the issue's `Depends on` line. It blocks that task alone,
  never another domain.
