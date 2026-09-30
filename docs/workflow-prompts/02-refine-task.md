# Refine a task

Refine [TASK_ID / ISSUE] for future implementation. Use Sol Medium. Read the project brief, the issue and relevant source; do not implement application changes.

The issue is the authority: its body and comments carry the scope, decisions and evidence, so refine it in place with `gh issue edit <N> --body-file <file>` and `gh issue comment <N>` instead of restating it elsewhere.

Turn the issue into one small demonstrable outcome with explicit in/out scope, consumer example, acceptance cases, relevant files and existing patterns, dependencies, verification commands, delivery target and stop conditions; the issue template already orders these sections. Check the environment's actual capabilities. Split the issue if it contains independently deliverable outcomes; a split across domains becomes one issue per domain, and each new issue links the others and records `Depends on:` as issue references (`#12`). Keep successor ideas as `status:deferred` issues in that domain.

Show the intended execution path and any proposed abstraction. Explain which current requirement needs it. Choose the execution recipe, record the recipe label and the worker in the issue, and use Sol High for unfamiliar 1C/integration reasoning, Terra Medium for ordinary bounded implementation, Luna Medium for mechanical work.

Move `status:draft` → `status:ready` only when material scope decisions and prerequisites are settled:

```bash
gh issue edit 12 --add-label recipe:normal,status:ready --remove-label status:draft
```

If a required decision remains, keep `status:draft`, ask one untimed chat question with your recommendation, and record the pending decision in the issue. Keep the visible decision card short; the detailed context belongs in the issue. Refinement does not authorize implementation.
