# Documentation

What is under `docs/`, and which part to read for what. The rules an agent always needs are in
[`../AGENTS.md`](../AGENTS.md); this page only routes.

## Where to look

| For | Read |
|---|---|
| The durable project rules — scope, readability, entry points | [`../AGENTS.md`](../AGENTS.md) |
| Onboarding a fresh checkout in VS Code | [WORKFLOW-START.md](WORKFLOW-START.md) |
| The process: planning, task creation, refinement, implementation, review | [workflow.md](workflow.md) |
| One prompt per operation | [workflow-prompts/](workflow-prompts/) |
| The task index and current state | [plan/index.md](plan/index.md) |
| Project purpose and boundaries | [plan/project.md](plan/project.md) |
| Reusable document templates | [plan/templates/](plan/templates/) |
| The BSL/1C rules and the pre-commit checklist | [code-standards/README.md](code-standards/README.md) |
| Long-form architecture, research and history | [plan/refactor-backlog.md](plan/refactor-backlog.md) and the other notes in `plan/` |
| Verified commands and environment limits | [plan/environment.md](plan/environment.md) |
| The module as it was before the extension rewrite | [old-code-version/ANALYSIS.md](old-code-version/ANALYSIS.md) |
| Real consumer modules written against the old API | [service-migration/](service-migration/) |
| Raw captures of the 1C ITS standard pages | [1c-docs/](1c-docs/) — provenance only, not for reading |

## How this tree is written

- **One owner per file.** A task owns its file under `plan/tasks/`, the task index routes to them,
  and the code standards own their rules. Two conversations should never need the same file.
- **Describe, do not duplicate.** A fact lives in one place and is linked from the others. The task
  file is the authority for a task; `plan/environment.md` for a command; the code standards for a
  rule.
- **Current behaviour, not history.** Documentation describes what the code does now. The reason a
  decision was taken belongs in the task that took it.
