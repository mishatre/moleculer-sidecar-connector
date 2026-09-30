# Documentation

What is under `docs/`, and which part to read for what. The rules an agent always needs are in
[`../AGENTS.md`](../AGENTS.md); this page only routes.

## Where to look

| For | Read |
|---|---|
| The durable project rules — scope, readability, domains, pull requests | [`../AGENTS.md`](../AGENTS.md) |
| Onboarding a fresh checkout, in Orca or VS Code | [WORKFLOW-START.md](WORKFLOW-START.md) |
| The process: planning, task creation, refinement, implementation, review, commit | [workflow.md](workflow.md) |
| One prompt per operation | [workflow-prompts/](workflow-prompts/) |
| Project state and the domain list | [plan/README.md](plan/README.md) |
| The tasks themselves | [the issue tracker](https://github.com/mishatre/moleculer-sidecar-connector/issues) — one issue per task, one milestone per domain |
| The BSL/1C rules and the pre-commit checklist | [code-standards/README.md](code-standards/README.md) |
| Long-form architecture, research and history | [plan/notes/](plan/notes/) |
| Verified commands and environment limits | [plan/environment.md](plan/environment.md) |
| The module as it was before the extension rewrite | [old-code-version/ANALYSIS.md](old-code-version/ANALYSIS.md) |
| Real consumer modules written against the old API | [service-migration/](service-migration/) |
| Raw captures of the 1C ITS standard pages | [1c-docs/](1c-docs/) — provenance only, not for reading |

## How this tree is written

- **One owner per file.** A task belongs to its domain's issues, the rules in `plan/conventions/`
  and the routers change only under a `FLOW` task, and the code standards belong to `STYLE`
  work. Two conversations should never need the same file.
- **Describe, do not duplicate.** A fact lives in one place and is linked from the others. The
  issue is the authority for a task; `plan/environment.md` for a command; the code standards for a
  rule.
- **Current behaviour, not history.** Documentation describes what the code does now. The reason a
  decision was taken belongs in the issue that took it.
