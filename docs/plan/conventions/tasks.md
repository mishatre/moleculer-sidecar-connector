# Task files

One file per task. The file is the single source of truth for that task's scope, decisions
and evidence. There is no separate status page, hand-off note or agent log.

## Where a task file lives

`docs/plan/tasks/<domain>/<ID>-<slug>.md`, for example
`docs/plan/tasks/core/T023-error-taxonomy.md`. The domain decides the folder; see
[domains.md](domains.md).

`docs/plan/tasks/<domain>/history/` holds the tasks of that domain that are finished. A task
moves there once its acceptance items are evidenced by a recorded command or observation, so
the active folder answers "what is still open" and the history folder answers "what was done
and how it was proven".

## Names and IDs

- A new task is named `<PREFIX>-<NNN>-<short-slug>.md`, for example
  `core/CORE-001-parse-service-definitions.md`. `<NNN>` is zero-padded to three digits and
  counts per domain, starting at `001`.
- **Allocate the number by looking only at your own domain folder**: take the highest number
  already used there and add one. There is no shared counter file, which is what keeps two
  domains from colliding.
- `T000`–`T040` are the retired global series. Those IDs are **never renumbered and never
  reused**, because they are cited in source comments, tests and tools across the
  repository. They keep their names and live in their domain folder like any other task. The
  full map is [../notes/legacy-ids.md](../notes/legacy-ids.md).
- A slug is short and describes the outcome, not the mechanism: `drop-yaml-modules`, not
  `change-yaml-calls`.

## The header block

Every task file opens with the block from [../templates/task.md](../templates/task.md). The
first line is the ID and the outcome. The fields follow:

| Field | Meaning |
|---|---|
| `Status` | The state of the task. |
| `Depends on` | Task IDs or decisions that must land first. `none` when there are none. |
| `Recipe` | `tiny`, `normal` or `complex`, as defined in [../../workflow.md](../../workflow.md). |
| `Coordinator` / `Worker` / `Reviewer` | The model and effort chosen for each role. |

## Status

`draft → ready → in_progress → verified → delivered`

- `blocked` records an unmet prerequisite that is outside the task's control.
- `deferred` records work that is intentionally later.
- `withdrawn` records a task that was closed because the problem did not exist. The file stays
  as the record of a wrong finding until the reason is no longer interesting.

**The task file is the authority.** The domain index mirrors the status and links to the file.
If the two disagree and the file is in the active folder, the index is stale. If the file is in
`history/`, the file is frozen — a finished task file is not rewritten, and a correction to one
is a dated note appended to it.

## What goes in the file

The sections of the template, in order: decision card, acceptance and consumer example,
implementation context, environment and verification, delivery and authority, stop conditions,
completion evidence. Two rules keep them useful:

- The decision card is what a reader sees first and stays under about 120 words. Detail goes
  below it.
- The completion evidence section is filled in as work proceeds, with the exact command and
  its result, not a summary of intent.

## Working from a task file

The task file is the delegation packet. A worker reads its own file plus the project rules
(`AGENTS.md`, the relevant conventions) — not the other domains' indexes and not the planning
notes. The coordinator records findings and the final state in the file, never in chat only.

A task ends with a commit; see [commits.md](commits.md).
