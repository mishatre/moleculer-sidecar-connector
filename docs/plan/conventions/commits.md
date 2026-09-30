# Commits and pull requests

Finishing a task means merging its pull request. Nobody has to be asked.

## The route

1. **One task, one issue, one branch, one pull request.** Branch from the current `main`:
   `issue-<N>-<short-slug>`, for example `issue-17-stop-the-blank-error`. An Orca worktree created
   for the issue is named after it; the branch keeps the issue number.
2. **Commit as you go.** The subject is `<ID>: <outcome>` where `<ID>` is the issue's task ID.
3. **Open the pull request against `main`** as soon as there is something to review, and keep it the
   record of the work: the PR body starts with `Closes #<N>`, so the merge closes the issue.
4. **Record the evidence in the issue, not only in the PR** — the `Verified:` line, the status
   label, and the PR link in the completion evidence section.
5. **Squash merge.** `main` then carries one commit per task, with the PR title as the subject and
   the PR body as the commit body.

```bash
gh issue view 17
git switch -c issue-17-stop-the-blank-error
git commit -m "CORE-003: stop the error message going blank" ...   # see the shape below
gh pr create --title "CORE-003: stop the error message going blank" --body-file <(printf 'Closes #17\n\n...')
gh pr merge --squash --delete-branch
```

## The shape of a commit

```text
CORE-003: stop the error message going blank

NStr returned an empty string, so the caller got no message at all.

Task: #17
Verified: vrunner test yaxunit canonical -> 68/68
```

Four parts, each doing one job:

1. **The ID** is the first thing on the line, so the commit list reads as a list of tasks.
2. **The outcome** is imperative, lower case, no trailing period, and says what changed for the
   user of the code — "stop the error message going blank", not "fix NStr call". Keep the whole
   subject line under 72 characters.
3. **The body**, optional, one to three sentences of *why*. Skip it when the outcome says it.
4. **The trailers** are what a tool can read, in git trailer format:
   - `Task:` the issue number, `#17`. The PR body's `Closes #17` is what closes it on merge.
   - `Verified:` the one check that proves it, and its result. More than one is allowed; use one
     line per check. Say `Verified: not run` plainly if nothing was run.

## The rules

- **One task per pull request.** A task and its PR are the same unit of work.
- **Never mix domains.** If a change needs work in two domains, that is two issues and two PRs
  ([domains.md](domains.md)).
- **Every PR names an issue.** If there is no issue for it, create one first — that is what
  `Create a task for…` is for. Old commits in the log use bare subjects and `(T024)` suffixes;
  that history is left alone.
- **The issue travels with the code.** The status label, the completion evidence and the PR link
  belong to the same merge as the change they describe, not to a later one. Merging a PR whose
  issue still says `status:draft` is an unfinished task.
- **`main` moves only through merged PRs.** A direct push to `main` is for a true emergency; say so
  in the report and open the issue that records it afterwards.
- **Keep unrelated churn out.** No formatter run, no line-ending flip, no tidy-up of a neighbouring
  file, no generated artifact from `build/` or `out/`. A separate concern is a separate task and a
  separate PR.
- **Never commit a secret.** No 1C licence file, no `GH_TOKEN`, no `.Xauthority` copy, no
  connection string. The ignore rules for those live in `.gitignore`; if one is missing, that is a
  `GLOB` task.

## Words to avoid

"Fix", "update", "refactor", "improve", "changes", "wip" on their own, and any subject that would
fit several different commits. The subject should let somebody who has not read the code tell
whether this commit touched their area.
