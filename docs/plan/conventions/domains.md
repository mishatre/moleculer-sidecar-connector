# Task domains

A task belongs to exactly one **domain**: the part of the repository it changes. Domain membership
decides which label the issue carries, which milestone lists it, which ID it gets, and which index
card routes to it. It is not a size or a priority.

## Why

The task list used to be one flat list with one global index, then one folder per domain. Every new
task had to take the next free number and edit the same page, so two conversations working on
unrelated things collided on the same file and on the same counter. Domains keep each conversation
in its own labels, its own milestone and its own index card.

## The domains

| Prefix | Label | Scope: paths this domain owns |
|---|---|---|
| `GLOB` | `domain:glob` | Repository-wide files that belong to no component: `.gitignore`, `.gitattributes`, `LICENSE`, `packagedef`, `autumn-properties.json`, the root `README.md`, and hygiene work that spans the whole tree such as license and copyright headers. |
| `STYLE` | `domain:style` | `docs/code-standards/` and conformance of source to those standards: regions, module headers, routine comments, the `@internal` marker, reading order. Style work touches many files but is always comment- or layout-only. |
| `CORE` | `domain:core` | The canonical connector: `src/cfe/MoleculerSidecarConnector/`, `src/cf/`, and the suites in `tests/bsl/canonical/` and `tests/bsl/common/`. Protocol and behaviour shared with the sidecar belong here. |
| `STAND` | `domain:stand` | The database-free variant: `tools/standalone-builder/`, `tests/standalone-builder/`, `tests/bsl/standalone/` and `tests/bsl/http/`. |
| `INST` | `domain:inst` | The installer external data processor: `src/epf/`. |
| `TOOLS` | `domain:tools` | The container and the build/test machinery: `.devcontainer/`, `tools/1c-platform/`, `tools/bsl-checks/`, `tools/check.sh`, `tools/md-sparrow/`, and the test harness scripts under `tests/bsl/` (`run-tests.sh`, `tests/README.md`). |
| `DOC` | `domain:doc` | Project documentation written for readers: `docs/` except `docs/code-standards/` and `docs/plan/`, plus feature and user documentation delivered by other domains. |
| `FLOW` | `domain:flow` | The working system itself: `AGENTS.md`, `docs/workflow.md`, `docs/workflow-prompts/`, `.github/`, and everything under `docs/plan/` (this folder, the templates, the index cards, the routers). |

Each domain has a milestone with the same prefix. It lists that domain's issues, open and closed,
which is how `docs/plan/tasks/<domain>/index.md` routes a reader to the roadmap.

Two areas are deliberately out of every domain:

- `moleculer-sidecar-next/` is a read-only reference copy and is not tracked by git. No task targets it.
- `build/` and `out/` are generated. No task targets them.

## Rules of a lane

1. **One conversation works in one domain at a time.** Two conversations in two domains can run at
   once because their labels, their milestone and their files are disjoint.
2. **Write only your own domain's work**: your issues, your `docs/plan/tasks/<domain>/index.md`
   card, and your domain's scratch notes under `docs/plan/notes/` that name the domain.
3. **Shared files change only under a `FLOW` task.** The routers and the conventions in this folder,
   the templates, `docs/plan/README.md`, `AGENTS.md`, the workflow prompts and `.github/` are read by
   everybody, so a normal task never edits them. If a task needs a rule changed, it stops and asks
   for a `FLOW` task.
4. **A dependency never blocks another domain.** `Depends on` records what must land first for
   *that* task. Everything else in the same domain, and every other domain, keeps going.
5. **A cross-domain change is split into one task per domain.** If a feature needs connector source
   and a documentation page, that is two issues with a dependency, not one issue with two owners.

## Choosing a domain for a new task

Pick the domain whose scope contains the files the task will change. When a task spans two, choose
the one that owns the majority of the change and record the other as a dependency.

Add a new domain only when work appears that has no home above and is expected to keep appearing. A
one-off belongs in the closest existing domain. A new domain costs a label, a milestone, an index
card and a prefix, so it needs at least a second task waiting behind it.
