# Implement a ready task

Implement only [TASK_ID / ISSUE] using docs/workflow.md and the project AGENTS.md. Use Sol Medium as coordinator; if the main model is different, report it without claiming to switch yourself.

Read the ready issue (`gh issue view <N> --comments`), relevant instructions and environment commands. Inspect working-tree changes and preserve existing work. If the issue is still draft, fill inferable fields from the implementation request and repository evidence and move it to ready when the scope is clear. Ask one ordinary untimed question only for a consequential missing decision before dependent implementation. Otherwise begin without another plan approval.

Work on the issue's own branch, `issue-<N>-<short-slug>`, created from the current `main`. Only the top-level coordinator runs the pipeline; children do not orchestrate it. For a normal task, delegate one bounded implementation to Terra Medium (or the worker recorded in the issue). Worker edits, runs relevant checks and updates current feature documentation. While it works, prepare acceptance/release verification or investigate an independent need; do not duplicate its code exploration. Once edits are stable, delegate a fresh Sol Medium review of the actual diff, relevant contracts and acceptance evidence. Have the worker fix concrete findings and rerun affected checks. The coordinator resolves findings and records them in the issue as comments. Use at most two active subagents, one writer, no nested delegation. Tiny tasks can use a single agent.

Two failed fixes for the same issue trigger diagnosis and a revised bounded approach or one specialist, not a repeating team loop. Never waive failed acceptance checks. Record future improvements as `status:deferred` issues without doing them. Review readability as well as correctness. Do not perform unrelated cleanup.

Complete the task's authorized delivery steps. Distinguish code/source checks, build, runtime tests and deployment. If an environment or approval blocks a required action, save the precise blocker and the next step in the issue, and say which stages remain unverified.

Then finish the task, without being asked: commit as `<ID>: <outcome>` with `Task: #<N>` and `Verified:` trailers, push the branch and open the pull request whose body starts with `Closes #<N>`, exactly as docs/plan/conventions/commits.md specifies. One task, one branch, one pull request. Move the issue to `status:verified` — or `status:delivered` when the task also published or deployed — and record the evidence and the PR link in the issue before the merge. Stage this task's files only; unrelated pre-existing working-tree changes stay where they are. If the work cannot honestly be closed by one pull request, leave the issue `status:in-progress` and report the split instead of opening a PR that claims more.

Return: outcome, evidence, entry point/main flow, remaining limitation or next action. Link detail rather than pasting logs.
