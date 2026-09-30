# T027 — the form layer is rebuilt

Status: draft — an outline from the cycle's evidence, and it needs the owner before it can be refined.
Depends on: owner decision
Recipe: normal
Coordinator: Sol Medium
Worker: TBD
Reviewer: Sol Medium

## Decision card

Outcome: the admin-panel forms are aimed at reuse rather than recreated one by one.

Why now: the owner reports that almost every form needs recreating. The admin-panel layout defect fixed in
`7af2cd6` was a symptom, not the disease.

Included: to be settled at refinement, after the owner answers the question below.
Deferred: everything — this is the one item the cycle's classification leaves to the owner.
Success: to be settled at refinement.
Next: the owner decides whether this belongs in the current cycle or its own. "Recreate almost every form"
is a different size of job from the rest of the cycle.

## Evidence this rests on

Row 8 of the cycle's evidence table in [refactor-backlog.md](../../notes/refactor-backlog.md):

| # | Finding | Evidence |
|---|---|---|
| 8 | The form layer is not aimed at reuse | the owner reports almost every form needs recreating; the admin-panel layout defect fixed in `7af2cd6` was a symptom, not the disease |

A nearby example of the same layer failing quietly is T036: a form called a method that never existed and
nothing in the toolchain could see it, because the platform reads metadata without compiling form bodies.

## Open question for the owner

Does the form layer belong in this cycle, or in its own? The answer decides whether this file becomes a
refined task or a future cycle's starting point.

## Stop conditions

Stop until the owner answers. Refining this task before that would be guessing at scope.
