# Task Completion

- Start from the selected task card in `docs/plan/tasks/`; its acceptance examples, verification commands, release target, and stop conditions are authoritative.
- Review `git diff`/status without disturbing unrelated pre-existing changes.
- Run the task's relevant source/static checks. No repository-wide formatter, linter, type checker, or generic automated test command is currently verified.
- For installer source changes, reproducibly compile with the direct `vrunner compileepf` command recorded in `mem:suggested_commands`.
- For extension artifacts, compile with direct `vrunner compileexttocfe`; keep output under `build/`.
- If the task requires real behavior evidence, load/open against the authorized disposable `/workspace/build/ib` and exercise the specified scenario. Do not mutate that infobase during onboarding/planning or a task that does not authorize it.
- Record exact commands, results, tool/platform versions, artifact paths, and limitations in the task file.
- Track source reviewed, compiled, runtime checked, and delivered as separate states. Required missing checks prevent `verified` status.
- Normal implementation requires a bounded worker and an independent reviewer on stable edits; tiny changes may use one agent. Resolve reviewer findings before completion.
- Delivery is task-specific. GitHub publication is separate from producing local draft-release artifacts and currently lacks authenticated CLI tooling.