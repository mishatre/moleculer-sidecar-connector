# STAND — standalone builder and variant

Scope: `tools/standalone-builder/`, `tests/standalone-builder/`, `tests/bsl/standalone/`, `tests/bsl/http/`.
Next free ID: `STAND-001`
Rules: [tasks](../../conventions/tasks.md) · [domains](../../conventions/domains.md) · [commits](../../conventions/commits.md)

Next recommended task: none. This domain has no open work; the generator, its container-only
tests and the runtime verification are all closed. New work here appears when the standalone
variant has to follow a connector change — the two merge defects found so far came from exactly
that, and both are closed.

## Open

| ID | Outcome | Status | Depends on | File |
|---|---|---|---|---|

## Closed

| ID | Outcome | Closed | File |
|---|---|---|---|
| T015 | Standalone CFE variant is generated from the canonical sources | verified | [Task](history/T015-standalone-builder.md) |
| T016 | Builder transformation and output shape are guarded by container-only tests | verified | [Task](history/T016-builder-transformation-tests.md) |
| T021 | The generated standalone CFE loads and works in a database-free infobase | verified | [Task](history/T021-standalone-runtime-verification.md) |
| T031 | The standalone variant keeps the live branch of a standalone guard | verified | [Task](history/T031-keep-the-live-branch-when-stripping.md) |
| T032 | The connector's own actions work in the standalone variant | verified | [Task](history/T032-connector-actions-over-http.md) |
| T035 | The standalone merge keeps service identities apart | verified | [Task](history/T035-standalone-merge-identities.md) |
