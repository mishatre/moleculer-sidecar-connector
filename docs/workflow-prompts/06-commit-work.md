# Commit this work

Commit [TASK_ID / PATH / "the current work"] using docs/workflow.md and the project AGENTS.md.
Use Sol Medium. This request authorizes one commit, not new implementation or deployment.

Read docs/plan/conventions/commits.md, the task file and the working-tree diff. Confirm which
task the work belongs to. If the task is not finished, commit only the part that is evidenced
and say which part that is, or report why nothing is ready to commit — do not close a task that
is still open.

Stage the task's files and its own domain's files only. Unrelated pre-existing changes in the
working tree stay unstaged; name them in the report. Never commit generated artifacts.

The subject is `<ID>: <outcome>` — lower case, imperative, under 72 characters. Add a body only
when the reason is not obvious. The trailers are `Task:` with the task file's path and
`Verified:` with the check and its result. One commit per task, and never two domains in one.

Update the task file in the same commit: its evidence, its status, and its move to the domain's
history/ folder when the task is done. Record the commit hash in the completion evidence. Do
not push, tag or publish unless the task authorizes that.

Return: the subject line, the files committed, what was deliberately left out, and the next
action.
