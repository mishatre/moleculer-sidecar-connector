# Commits

Finishing a task means committing it. Nobody has to be asked.

## The shape

```text
CORE-003: stop the error message going blank

NStr returned an empty string, so the caller got no message at all.

Task: docs/plan/tasks/core/CORE-003-error-taxonomy.md
Verified: vrunner test yaxunit canonical -> 68/68
```

Four parts, each doing one job:

1. **The ID** is the first thing on the line, so the commit list reads as a list of tasks.
2. **The outcome** is imperative, lower case, no trailing period, and says what changed for the
   user of the code — "stop the error message going blank", not "fix NStr call". Keep the whole
   subject line under 72 characters.
3. **The body**, optional, one to three sentences of *why*. Skip it when the outcome says it.
4. **The trailers** are what a tool can read, in git trailer format:
   - `Task:` the path to the task file, so the commit and the task point at each other.
   - `Verified:` the one check that proves it, and its result. More than one is allowed; use
     one line per check. Say `Verified: not run` plainly if nothing was run.

## The rules

- **One commit per task.** A task and its commit are the same unit of work.
- **Never mix domains.** If a change needs work in two domains, that is two tasks and two
  commits ([domains.md](domains.md)).
- **Every commit names a task.** If there is no task for it, create the task first — that is
  what `Create a task for…` is for. Old commits in the log use bare subjects and `(T024)`
  suffixes; that history is left alone.
- **The task file travels with the code.** The status, the completion evidence and the move to
  `history/` belong in the same commit as the change they describe, not in a later one.
- **Record the hash in the task file** after committing: add `Commit: <short sha>` to the
  completion evidence section. It is what lets a reader get from the record back to the diff. One
  exception: when the task file itself is part of that same commit, write the commit's subject
  instead of a hash, because the amend that would record the hash changes it — a commit cannot
  name itself. `git log --grep <ID>` finds it.
- **Keep unrelated churn out.** No formatter run, no line-ending flip, no tidy-up of a
  neighbouring file, no generated artifact from `build/` or `out/`. A separate concern is a
  separate task and a separate commit.

## Words to avoid

"Fix", "update", "refactor", "improve", "changes", "wip" on their own, and any subject that
would fit several different commits. The subject should let somebody who has not read the code
tell whether this commit touched their area.
