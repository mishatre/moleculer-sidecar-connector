# Review and create follow-up tasks

Review [TASK_ID / ISSUE / PULL REQUEST / BASE COMMIT]. Use Sol Medium as coordinator and one independent Sol Medium reviewer for a substantial change. Read the linked issue and the actual implementation. If the review target is ambiguous, ask one untimed question. Do not modify application source merely because a review found something.

Inspect the pull request with `gh pr view <N> --comments`, `gh pr diff <N>` and `gh pr checks <N>`, and read the linked issue for its scope, decisions and completion evidence. Inspect correctness, the real consumer path, relevant tests, readability and scope. Evaluate security properties relevant to this change. Check that the commit subject and trailers follow docs/plan/conventions/commits.md and that the branch carries no unrelated file. Cite concrete files/symbols and explain observable consequences. Separate actual defects, missing evidence and optional improvements. Report no findings if no actionable issue is supported. Do not demand speculative abstractions or new features.

For a feature involving 1C or integrations, distinguish source, build and runtime evidence. For UI, identify whether real interaction was checked. Use a specialist only for a specific unresolved risk, not a universal checklist.

Record the review as a comment on the issue or the pull request (`gh issue comment <N>`, `gh pr comment <N>`), never a file. Create findings that need work with `gh issue create` as `status:draft` issues in the owning domain, with the `recipe:` label, the domain milestone, the evidence linked and ordered by impact. Optional improvements become `status:deferred` issues. Reuse or link existing issues to avoid duplicates. Leave the reviewed issue's status to the deliverable that owns it.

Return at most three leading findings and the next recommended action; keep the rest in the issues. Review does not authorize fixes or deployment unless explicitly requested.
