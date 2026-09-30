# DOC-001 — the two ITS pages the code standards restate are kept as captures

Status: verified 2026-09-30
Depends on: none
Recipe: tiny
Coordinator: Sol Medium
Worker: Sol Medium
Reviewer: not run — captured evidence, see below

## Decision card

Outcome: the two ITS pages behind [docs/code-standards](../../../code-standards/README.md) are
in the repository as they were read, so the English restatement can be checked against its
source without an ITS subscription.
Why now: `provenance.md` refers to captures under `docs/1c-docs/`, and a reference to a folder
that is not in the repository is a dead end.
Included: the two HTML captures and their asset folders.
Deferred: nothing.
Success: the two pages exist where the code-standards documents say they do.
Next: none.

## Acceptance and consumer example

- [x] `docs/1c-docs/` holds the #std455 and #std453 pages with their `_files/` asset folders.
- [x] [provenance.md](../../../code-standards/provenance.md) points at them and states that they
      are evidence, not reading material.
- [x] They are windows-1251 captures of a subscription page, kept unedited.

## Implementation context

The captures were taken while the English restatements were written. Nothing reads them
programmatically; they exist so a claim in `module-structure.md` or
`procedure-and-function-description.md` can be traced back to the text it came from.

They are deliberately not linked from `README.md` files as something to open: the encoding is
windows-1251, the files carry the surrounding site chrome, and they go stale the moment ITS
edits a page. The English documents are what a change should follow.

## Delivery and authority

Required destination/artifact: the captures, in the repository.
Publication/deployment authorized by this task: one commit.

## Completion evidence / resume point

Source checks: the two pages and their asset folders are present; the relative link from
`docs/code-standards/provenance.md` resolves.
Build: none.
Runtime/consumer check: not applicable — static evidence.
Review findings and dispositions: no independent review; the material is third-party text kept
as read, so there is nothing to review beyond its presence and its link.
Commit: the commit whose subject is `DOC-001: keep the two ITS pages the code standards restate`;
no hash is written here because this file is part of that same commit.
Unverified work: none.
Next action: none.
