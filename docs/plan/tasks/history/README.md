# Task history

Completed task files live here, moved out of `docs/plan/tasks/` so that the active folder answers "what is
still open" and this one answers "what was done and how was it proven".

Rules that keep this folder useful:

- `docs/plan/index.md` stays the entry point and keeps a link to every task, including these.
- A task moves here only when its acceptance items are evidenced by a recorded command or observation.
  A file that is still `draft`, `ready`, `in_progress`, `blocked` or `deferred` is not history.
- A completed task file is not rewritten after it moves, except to correct something that is wrong. If a
  file here disagrees with the index, the file is the stale one, and the correction is worth a dated note
  in the file rather than a quiet edit.

| Task | Outcome it closed |
|---|---|
| T000 | Codex can find the local workflow files and identify real tooling |
| T001 | Installer refinement is decomposed into bounded outcomes |
| T014 | Container toolchain, test runner and test hosting are verified |
| T015 | Standalone CFE variant is generated from the canonical sources |
| T016 | Builder transformation and output shape are guarded by container-only tests |
| T017 | A BSL suite runs and reports in extension and standalone modes |
| T019 | Broker, schema factory, facade and provider are covered by executable tests |
| T021 | The generated standalone CFE loads and works in a database-free infobase |

Still active in `docs/plan/tasks/`: T002–T013 (installer roadmap), T018 and T020 (suite work), T022
(blocked on T018–T020) and T023. The refactoring cycle's drafts, T024–T035, live in
[refactor-backlog.md](../../refactor-backlog.md).
