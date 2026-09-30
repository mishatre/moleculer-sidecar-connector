# Tasks

One task is one GitHub issue in `mishatre/moleculer-sidecar-connector`. The issue is the single
source of truth for that task's scope, decisions and evidence. There is no task file, no separate
status page, hand-off note or agent log.

## Where a task lives

An issue, open or closed, in the repository's own tracker:

```bash
gh issue list --label domain:core --state open
gh issue view 12 --comments
```

A closed issue is the history. It answers "what was done and how it was proven" the way the
`history/` folder used to, and the domain index cards under `docs/plan/tasks/` route to the
queries that list it.

## Names and IDs

- The title is `<ID>: <outcome>`, for example `CORE-001: parse service definitions locally`.
- `<ID>` is `<PREFIX>-<NNN>` with `<NNN>` zero-padded to three digits and counted **inside the
  domain only**, starting at `001`.
- **Allocate the number from your own domain**: list that domain's issues in every state, take the
  highest `<PREFIX>-<NNN>` used and add one. No shared counter file exists, which is what keeps two
  domains from colliding.

  ```bash
  gh issue list --label domain:core --state all --search "CORE- in:title" --limit 200 \
    --json title --jq '.[].title' | sort
  ```

- `T000`–`T040` are the retired global series. Those IDs are **never renumbered and never reused**,
  because they are cited in source comments, tests and tools across the repository. Their issues
  keep the `T0NN` title and live in their domain milestone. The full map is
  [../notes/legacy-ids.md](../notes/legacy-ids.md).
- The outcome after the colon describes the result, not the mechanism: `drop the YAML modules`,
  not `change the YAML calls`.

## Labels and milestone

Three label families carry what the old header block used to; the milestone is the domain.

| Family | Values | Meaning |
|---|---|---|
| `domain:` | `glob`, `style`, `core`, `stand`, `inst`, `tools`, `doc`, `flow` | The part of the repository the task changes; see [domains.md](domains.md). |
| `status:` | `draft`, `ready`, `in-progress`, `verified`, `delivered`, `blocked`, `deferred`, `withdrawn` | Where the task stands. |
| `recipe:` | `tiny`, `normal`, `complex` | The execution recipe from [../../workflow.md](../../workflow.md). |

The milestone is the domain prefix (`CORE`, `TOOLS`, …), so a domain's roadmap is one query and
never a counter two conversations share. The model routing for the roles (`Coordinator`, `Worker`,
`Reviewer`) stays in the issue body next to the decision card, because it is read with the task.

## The issue body

Use [`.github/ISSUE_TEMPLATE/task.md`](../../../.github/ISSUE_TEMPLATE/task.md). The sections, in
order: decision card, acceptance and consumer example, implementation context, environment and
verification, delivery and authority, stop conditions, completion evidence. Two rules keep them
useful:

- The decision card is what a reader sees first and stays under about 120 words. Detail goes below.
- The completion evidence section is filled in as work proceeds, with the exact command and its
  result, not a summary of intent.

`Depends on:` lives in the body and names the blocking issues as GitHub references (`#12`). It
blocks that one task, never another domain.

## Status

`draft → ready → in-progress → verified → delivered`

- `blocked` records an unmet prerequisite that is outside the task's control.
- `deferred` records work that is intentionally later.
- `withdrawn` records a task closed because the problem did not exist. The issue stays as the
  record of a wrong finding until the reason is no longer interesting.

**The issue is the authority**, and its `status:` label is the only status. Nothing mirrors it, so
nothing can go stale: change the label in the same operation as the evidence that justifies it.

```bash
gh issue edit 12 --add-label status:in-progress --remove-label status:ready
gh issue comment 12 --body "Verified: vrunner test yaxunit -> 68/68"
```

## Working from an issue

The issue is the delegation packet. A worker reads its own issue plus the project rules
(`AGENTS.md`, the relevant conventions) — not the other domains' cards and not the planning notes.
The coordinator records findings and the final state in the issue, never in chat only.

A task ends with a merged pull request; see [commits.md](commits.md).
