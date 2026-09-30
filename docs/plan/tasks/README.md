# Active tasks

One file per task. This folder is the delegation surface: the coordinator points a worker at exactly one of
these files, and the worker reads that packet plus the project rules — not the index, not a planning
document.

- A file is named `T0NN-<short-slug>.md` and opens with the header block from
  [../templates/task.md](../templates/task.md): `Status`, `Depends on`, `Recipe`, `Coordinator`, `Worker`,
  `Reviewer`.
- `Status` is the only place a task's state is recorded. [../index.md](../index.md) mirrors it and links to
  the file; if the two disagree, the index is the stale one.
- A task moves to [history/](history/) once its acceptance items are evidenced by a recorded command or
  observation — see [history/README.md](history/README.md). Anything still draft, ready, in progress, blocked
  or deferred stays here.
- Task definitions do not live in planning documents. [../refactor-backlog.md](../refactor-backlog.md) keeps
  the evidence and the reasoning that produced this cycle's tasks and links to their files; when a task's
  state changes, the file and the index change, not the backlog.
- The installer roadmap (T002–T013) shares this folder and the same rules.
- T034 is here as the record of a withdrawn finding, not as work to do.
