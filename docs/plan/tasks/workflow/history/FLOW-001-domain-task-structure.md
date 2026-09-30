# FLOW-001 — Tasks are grouped by domain with per-domain IDs, and every task ends with a commit

Status: verified 2026-09-30 — the layout, the conventions and the commit rule are in place and
mechanically checked. The review was not independent (one agent, documentation only), which is
the one thing left open.
Depends on: none
Recipe: normal
Coordinator: Sol Medium
Worker: Sol Medium
Reviewer: not run — single agent, see Unverified work

## Decision card

Outcome: The task folder is split into eight domains, each with its own prefix, index and
history folder, so two conversations on unrelated work never touch the same file. Every task
now ends with a commit whose subject names the task.
Why now: one flat folder and one global index made every task edit the same page and take the
next global number; the commit step had to be requested in each conversation.
Included: domain folders and moves, conventions for domains/tasks/commits, a router that lists
domains and not tasks, trimmed global documents, agent-usable code standards, updated workflow
prompts, and the path references that the moves invalidated.
Deferred: an automated link/task-header check in `tools/check.sh`; `.github/instructions/`
auto-attach for BSL edits; a full task-ID renumbering.
Success: the index page a task edits is its own domain's, and one commit closes the task.
Next: none.

## Acceptance and consumer example

- [x] Eight domains exist with a folder, an index and a `history/` each, and the domain rules
      are written down once in `conventions/domains.md`.
- [x] Every task file lives in its domain folder; the flat `index.md`, `index.md.orig`, the two
      folder READMEs and the duplicated tables are gone.
- [x] A new task is allocated its number by reading one folder, with no shared counter.
- [x] `T000`–`T040` keep their names and are mapped in `notes/legacy-ids.md`.
- [x] The commit rule is written in `conventions/commits.md` and wired into `AGENTS.md`,
      `workflow.md` and the implement prompt, so it needs no per-conversation request.
- [x] The code standards are citable by rule ID and have a short pre-commit checklist.
- [x] `docs/plan/README.md` lists domains only; a task's own index is the only index it edits.

Consumer example: a conversation asked to "create a task for the installer UI" reads
`docs/plan/README.md`, picks `INST`, opens `docs/plan/tasks/installer/index.md`, sees the next
free `INST-001` (or reuses a T-number still open there), writes the file as a sibling, and adds
one row to that index. No other index changes.

## Implementation context

Entry point and relevant files/symbols:
`docs/plan/` is the whole surface: `README.md` (router), `conventions/`, `tasks/<domain>/`,
`notes/`, `templates/`.
Existing example to follow:
the previous split into `tasks/history/`, which is the same idea applied to status instead of
domain.
Main operations and responsibility boundaries:
`05-create-task.md` picks the domain and number; `03-implement-task.md` finishes with a commit;
`04-review.md` checks the commit and the evidence.
Constraints and current callers:
85 tracked files cite a `T0NN` number, and a handful cite a `docs/plan/...` path. The numbers are
therefore frozen and only paths were updated.
Future extension note (not implementation scope):
a `docs` layer in `tools/check.sh`, and `.github/instructions/*.instructions.md` for BSL.

## Environment and verification

Link: [../../environment.md](../../../environment.md)
Commands and expected results:
`grep -rn` for a stale flat task path returns nothing outside the frozen history files; every
`T000`–`T040` appears exactly once in `notes/legacy-ids.md` and once in a domain index; a
throwaway link check over the changed Markdown finds no unresolved relative link.
Required runtime/manual checks:
none — documentation only.
Unavailable checks and who can perform them:
a permanent link gate does not exist (see Deferred); the throwaway check above is the evidence.

## Delivery and authority

Required destination/artifact:
the restructured `docs/plan/`, `docs/code-standards/`, `docs/README.md`, `AGENTS.md`,
`docs/workflow.md` and the prompts.
Build/output path:
none.
Consumer integration or installation method:
the Codex/Copilot conversations that read `AGENTS.md` and the prompts.
Publication/deployment authorized by this task:
one commit, per `conventions/commits.md`.
Reversal/recovery method where relevant:
the moves are ordinary git renames, so `git revert` restores the flat layout.

## Stop conditions

Stop for an unresolved decision on the domain list or the ID scheme. Routine naming and wording
choices are autonomous. The pre-existing uncommitted work in `src/`, `tests/` and `tools/` is not
part of this task and is not staged by it.

## Completion evidence / resume point

Source checks:

- a throwaway link check (run in the container, not committed) over every `docs/**/*.md`:
  **0 unresolved relative links**, down from 33 after the moves, including two that were already
  broken before this task (the `../../plan/...` link in
  `docs/code-standards/procedure-and-function-description.md` and the two
  `mol_AdminPanel` form paths in `connector-architecture-audit.md`).
- a task inventory check: **42 task files, 42 IDs**, each ID present in exactly one domain index,
  no duplicate filenames; `notes/legacy-ids.md` has **41 rows** covering `T000`–`T040` with no gap
  and no duplicate.
- a rule-ID check: **38 rule IDs** defined across the two reference documents, and no citation in
  `README.md`, `checklist.md` or `provenance.md` pointing at an ID that does not exist.
- a reference sweep for `docs/plan/index.md`, `plan/tasks/README`, `docs/plan/reviews` and
  "five operations" across the tracked tree: no hits outside
  `tasks/workflow/history/T000-verify-workflow.md`, which keeps its historical wording.

Build:
none — documentation, comments and one path string per file. No source file changed, no formatter
ran, and the 1C toolchain was not invoked.

Runtime/consumer check:
not applicable. The consumer is a conversation reading `AGENTS.md` and the prompts; the checks
above stand in for that.

Review findings and dispositions:
no independent review was run: the available subagent is read-only, and this task's edits are
documentation rather than code. The mechanical checks above are the evidence. A reviewer should
still look at the domain split and the commit rule, which is why the status note keeps that open.

Delivered artifact/deployment:
89 files in one commit on `main`: the eight domain folders with their indexes and history,
`conventions/{domains,tasks,commits}.md`, the `docs/plan/README.md` router, `docs/README.md`,
the trimmed `project.md`/`environment.md`, `notes/legacy-ids.md`, the reworked code standards, the
updated `AGENTS.md`, `workflow.md`, `WORKFLOW-START.md` and prompts, and the path references the
moves invalidated in `tests/`, `tools/` and `vendor/`.

Commit:
the one on `main` whose subject is `FLOW-001: split tasks into domains and end each one with a
commit`. No hash is written here on purpose: this file is part of that same commit, and the amend
that would record the hash also changes it. Read the subject in the log; `git log --grep FLOW-001`
finds it.

Unverified work:

- No independent review (see above).
- The pending license-header edits that were already in the working tree stay uncommitted: the
  headers in `tests/standalone-builder/test_builder.py`, `tools/1c-platform/run-bsl-tests.sh` and
  `tools/standalone-builder/build-standalone.py`, the untracked `LICENSE`,
  `tools/bsl-checks/check-headers.py` and `docs/1c-docs/`, and the other ~80 source files. That is
  T038's work and its license choice is still the owner's to confirm; only the documentation-path
  line of those three files was staged here.
- `vendor/YamlParserNative/README.md` and `yp_YAML.bsl` point at `docs/plan/yaml-json-mapping.md`,
  which has never existed. Pre-existing and deliberately not touched; vendor may not be ours to
  edit.

Next action:
none. The two follow-ups this task deferred — a `docs` layer in `tools/check.sh` that would make
the link check permanent, and `.github/instructions/*.instructions.md` that would attach the BSL
checklist to edits automatically — have no task file yet; create them in `FLOW` and `STYLE`
respectively when they are wanted.
