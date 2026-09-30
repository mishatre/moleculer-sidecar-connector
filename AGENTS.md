# Start here: project-local Codex workflow

All bare paths in these instructions are relative to THIS repository root, not
the llm-manager kit. Resolve the repository root from the current workspace
(or `git rev-parse --show-toplevel`) before opening paths. In the dev container
it is `/workspace`; on a host use the actual checkout path. Do not prefix host
paths onto container commands. This project copy is self-contained.

## Request routing — coordinator only

For workflow requests, follow the matching local prompt, interpreting user-supplied
task IDs/paths as its arguments. These phrases are natural-language requests,
not installed slash commands. Explicit user instructions take precedence.

| Request | Read from repository root |
|---|---|
| Plan this project | `docs/workflow-prompts/01-plan-project.md` |
| Create a task for… | `docs/workflow-prompts/05-create-task.md` |
| Refine task CORE-001 | `docs/workflow-prompts/02-refine-task.md` |
| Implement task CORE-001 | `docs/workflow-prompts/03-implement-task.md` |
| Review this feature/task | `docs/workflow-prompts/04-review.md` |
| Commit this work | `docs/workflow-prompts/06-commit-work.md` |

Read `docs/workflow.md` when applying the workflow. Project state is in
`docs/plan/project.md` and `docs/plan/environment.md`; the tasks are GitHub issues in
`mishatre/moleculer-sidecar-connector`, and `docs/plan/README.md` routes to both. The rules
for issues, domains and pull requests are in `docs/plan/conventions/`. Do not read every
issue or prompt for one operation. A delegated agent reads its assigned packet and
applicable project rules; it does not invoke this router.

For onboarding, read `docs/WORKFLOW-START.md`. The retired `T000` workflow check is issue
#43 in the `FLOW` milestone; use its read-only setup verification recipe rather than the
normal implementation team.

## Tasks, domains and pull requests

A task is one GitHub issue: titled `<ID>: <outcome>`, labelled `domain:`/`status:`/`recipe:`
and filed in the milestone named after its domain. The eight domains, the ID scheme and the
rules of a lane are in `docs/plan/conventions/domains.md` and
`docs/plan/conventions/tasks.md`. `T000`–`T040` are the retired global series and keep their
names. The cards under `docs/plan/tasks/` only route to a domain's issue queries.

Work in one domain per conversation and touch only that domain's work: its issues, its
`index.md` card and its notes. The routers, the conventions, `.github/`, `AGENTS.md` and
`docs/workflow-prompts/` are read by everyone and change only under a `FLOW` task. A
`Depends on` line blocks that one task, never another domain.

Finish every task with a merged pull request: branch `issue-<N>-<slug>`, commit subject
`<ID>: <outcome>` with `Task: #<N>` and `Verified:` trailers, a PR body that starts with
`Closes #<N>`, squash merged, and the issue's status label and evidence updated in the same
merge — exactly as `docs/plan/conventions/commits.md` specifies. Opening the pull request is
the last step of the task, not a separate request.

## This project's current boundaries

1C/BSL source lives under `src/`; extension source is currently
`src/cfe/MoleculerSidecarConnector/`. There are extensive pre-existing changes,
including moves/deletions. Preserve them. Generated files and infobases live
under `build/`; OneScript dependencies live under `oscript_modules/`.

Run 1C/OneScript commands in the dev container, from `/workspace`, after
verifying the environment. Do not assume the host has these tools. The root
README contains bootstrap-template instructions and is not proof that its
referenced scripts still exist. Existing VS Code tasks/debug entries contain
Windows syntax mixed with Linux paths. Check the actual command and target
before using them. In particular, do not run `--updatedb` as a read-only setup
check or mutate an infobase without an authorized task targeting it.

Orca runs the project through `orca.yaml`, which has no dev-container support of its
own: it calls `tools/orca/container.sh up` as the worktree setup hook and opens a shell
inside the container as the default tab. The container is per worktree, so
`tools/orca/container.sh run <command>` reaches the toolchain from the host and
`container.sh down` removes it. VS Code's "Reopen in Container" reaches the same container
through the same compose file.

The 1C client is a GUI program, and it draws on the macOS host's XQuartz server: the
container carries `DISPLAY=host.docker.internal:0`. The host must allow that connection
once per X server start with `xhost +127.0.0.1`; without it, `1cv8c` reports that it
cannot connect to the windowing system and `tools/1c-platform/open-infobase.sh` says so
explicitly. `gh` inside the container authenticates from `GH_TOKEN`, which
`container.sh` resolves from the host login and `docker-compose.yml` passes through.

# Project working agreement

## Communication

Keep visible planning/status concise; save detail in docs/plan. Show outcome, scope, evidence and next action. Ask ordinary chat questions with no timeout, preferably one at a time. Do not interpret silence as approval. Unanswered required questions remain pending across pauses and resumption. Read only the context needed for the current task; follow relevant links when necessary.

## Scope

Use docs/workflow.md for the six operations: project planning, task creation, refinement, implementation, review and commit. A project plan authorizes documentation, not application implementation. Implement the selected ready issue only. Future ideas become `status:deferred` issues in their domain. Preserve simple boundaries for growth without building unused hooks/adapters/frameworks. Favor one demonstrable outcome and the actual consumer integration.

## Readability

Use descriptive names and explicit control flow. In brace-based languages, always use braces for if/else/for/while bodies. Separate logical steps with blank lines. Avoid compressed one-liners, nested ternaries and unnecessarily clever chains. In BSL use idiomatic explicit blocks and the project's naming language. Keep related behavior together; extract operations by responsibility rather than arbitrary size. Follow existing good examples identified in the task; do not preserve unreadable compression merely because it exists nearby. No unrelated reformatting.

BSL also follows the 1C standards collected in [docs/code-standards](docs/code-standards/README.md): the #std455 module-section and region order, and the #std453 comment above a procedure or function. In short: one handler per event, each calling a named operation rather than each other; no empty regions; a short module header; a same-line comment for every module variable; document the program interface and the overridable connectors, and do not restate a routine's own name in its comment; a blank line between routines; and a comment above a compilation directive, not below it.

BSL is aligned in columns on purpose. Match the surrounding module's aligned `=` and trailing-comment columns instead of letting a formatter left-align them, and treat the leading spaces after `|` in a multi-line string literal as message text rather than layout. Keep formatter output out of a commit that carries a change, and treat a repo-wide reformat as its own decision.

## Implementation pipeline

Only the top-level coordinator applies this pipeline. Delegated agents complete their assigned roles and do not orchestrate the task. For normal tasks, explicitly delegate a bounded worker (Terra Medium) and then an independent reviewer (Sol Medium) on stable edits. Coordinator is Sol Medium selected in the client. Luna Medium is for mechanical work; Sol High handles unfamiliar integrations; Astra Medium is a bounded escalation. At most two active children, one writer, no nested delegation. Tiny changes can use one agent. Workers run appropriate checks; reviewers examine actual code and evidence. Two failed repairs of one issue require diagnosis before further attempts. Do not mark unmet requirements complete.

## Context tools

Use Graft for subsystem orientation when its index is available and useful. Use Serena for supported symbol/reference operations. Use targeted text search and source reads for literal/config searches and missing detail. Verify implementation-sensitive claims against current source. Do not perform the same exploration through every tool or treat retrieval savings as measured Codex quota savings. Keep instructions consistent with installed tool capabilities. Do not add tools by default.

## Evidence and delivery

Use the verified commands in docs/plan/environment.md. Run relevant required checks; avoid repeating passing checks without a change or concern. Track source, build, runtime and deployment separately, especially for 1C. Update the issue's evidence and the current feature docs. Preserve pre-existing work. Execute authorized delivery actions; report exact blockers and unverified stages. Do not claim compilation proves runtime correctness. Finish with a short entry-point/flow explanation and next action.
