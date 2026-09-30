# Commit this work

Commit [TASK_ID / ISSUE / "the current work"] using docs/workflow.md and the project AGENTS.md.
Use Sol Medium. This request authorizes one pull request, not new implementation or deployment.

Read docs/plan/conventions/commits.md, the issue and the working-tree diff. Confirm which task
the work belongs to. If the task is not finished, commit only the part that is evidenced and say
which part that is, or report why nothing is ready to commit — do not close an issue that is
still open.

Stage the task's files only. Unrelated pre-existing changes in the working tree stay unstaged;
name them in the report. Never commit generated artifacts, secrets or licence files.

Create the branch `issue-<N>-<short-slug>` if it is not the current one, then commit with the
subject `<ID>: <outcome>` — lower case, imperative, under 72 characters. Add a body only when the
reason is not obvious. The trailers are `Task: #<N>` and `Verified: <check> -> <result>`. One task,
one branch, one pull request, and never two domains in one.

Push the branch and open the pull request against `main`, with a body that starts with
`Closes #<N>`:

```bash
gh pr create --title "CORE-003: stop the error message going blank" \
  --body-file <file> --base main --head issue-17-stop-the-blank-error
```

Update the issue in the same operation: the evidence comment, the status label and the PR link.
Do not merge unless the task authorizes the merge, and do not tag, publish or deploy unless the
issue authorizes that.

Return: the subject line, the files committed, the pull request URL, what was deliberately left
out, and the next action.
