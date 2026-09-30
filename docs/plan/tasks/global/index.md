# GLOB — repository-wide

Scope: files that belong to no component — `.gitignore`, `.gitattributes`, `LICENSE`,
`packagedef`, `autumn-properties.json`, the root `README.md` — and hygiene work that spans the
whole tree, such as license and copyright headers.
Next free ID: `GLOB-001`
Rules: [tasks](../../conventions/tasks.md) · [domains](../../conventions/domains.md) · [commits](../../conventions/commits.md)

Next recommended task: **T038**, blocked on one owner decision — the license and the copyright
holder. Everything else in it is implemented and tested.

## Open

| ID | Outcome | Status | Depends on | File |
|---|---|---|---|---|
| T038 | Every first-party source file declares one copyright and license | in_progress | owner confirms license/holder | [Task](T038-license-and-copyright-headers.md) |

Measured 2026-09-30: T038 covers 77 files (63 BSL, 14 scripts) plus the two 1C `<Copyright>`
properties; `moleculer-sidecar-next/` is out of scope. Owner decision pending: **MIT** with
holder **M.Tregub, 2026** is proposed — the connector's `<Vendor>` is already `M.Tregub`.

## Closed

| ID | Outcome | Closed | File |
|---|---|---|---|
