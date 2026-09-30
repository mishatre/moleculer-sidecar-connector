# STYLE — code standards and conformance

Scope: `docs/code-standards/` and the conformance of source to those standards — regions,
module headers, routine comments, the `@internal` marker, reading order. Style work touches
many files but is comment- or layout-only and changes no behaviour.
Next free ID: `STYLE-001`
Rules: [tasks](../../conventions/tasks.md) · [domains](../../conventions/domains.md) · [commits](../../conventions/commits.md)

Next recommended task: **T040**, because T039 must mark an internal region that T040 renames.
Either order works, but renaming first avoids touching each mark twice.

The rules themselves are in [docs/code-standards](../../../code-standards/README.md). These two
tasks bring the existing tree to them; each is comment-only and has its own diff so review stays
cheap.

## Open

| ID | Outcome | Status | Depends on | File |
|---|---|---|---|---|
| T039 | The internal API is marked with `// @internal` | draft | none | [Task](T039-mark-internal-api.md) |
| T040 | The internal API region is named `Internal` and holds only its exports | draft | none | [Task](T040-refactor-protected-region.md) |

Measured 2026-09-30: T039 covers 80 exported routines in 15 modules; T040 covers 14 modules and
six non-export routines to relocate.

## Closed

| ID | Outcome | Closed | File |
|---|---|---|---|
