# Implement a ready task

Implement only [TASK_ID / PATH] using docs/workflow.md and the project AGENTS.md. Use Sol Medium as coordinator; if the main model is different, report it without claiming to switch yourself.

Read the ready task, relevant instructions and environment commands. Inspect working-tree changes and preserve existing work. If the task is still draft, fill inferable fields from the implementation request and repository evidence and mark it ready when the scope is clear. Ask one ordinary untimed question only for a consequential missing decision before dependent implementation. Otherwise begin without another plan approval.

Only the top-level coordinator runs the pipeline; children do not orchestrate it. For a normal task, delegate one bounded implementation to Terra Medium (or the worker specified in the ready task). Worker edits, runs relevant checks and updates current feature documentation. While it works, prepare acceptance/release verification or investigate an independent need; do not duplicate its code exploration. Once edits are stable, delegate a fresh Sol Medium review of actual diff, relevant contracts and acceptance evidence. Have the worker fix concrete findings and rerun affected checks. The coordinator resolves findings and records evidence. Use at most two active subagents, one writer, no nested delegation. Tiny tasks can use a single agent.

Two failed fixes for the same issue trigger diagnosis and a revised bounded approach or one specialist, not a repeating team loop. Never waive failed acceptance checks. Record future improvements without doing them. Review readability as well as correctness. Do not perform unrelated cleanup.

Complete the task's authorized delivery steps. Distinguish code/source checks, build, runtime tests and deployment. If an environment or approval blocks a required action, save the precise blocker and the next step. Update the task file and its domain's index honestly. Do not proceed into the next roadmap task.

Then commit the task, without being asked: `<ID>: <outcome>` with `Task:` and `Verified:` trailers, exactly as docs/plan/conventions/commits.md specifies. One commit per task. Stage this task's files and its own domain's files only — unrelated pre-existing working-tree changes stay where they are. Move the task file to that domain's history/ folder and record the commit hash in its completion evidence, in the same commit. If the work cannot honestly be closed by one commit, leave the task in_progress and report the split instead of committing something else.

Return: outcome, evidence, entry point/main flow, remaining limitation or next action. Link detail rather than pasting logs.
