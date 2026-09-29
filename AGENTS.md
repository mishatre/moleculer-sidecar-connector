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
| Refine task T001 | `docs/workflow-prompts/02-refine-task.md` |
| Implement task T001 | `docs/workflow-prompts/03-implement-task.md` |
| Review this feature/task | `docs/workflow-prompts/04-review.md` |

Read `docs/workflow.md` when applying the workflow. Project state is in
`docs/plan/project.md`, `docs/plan/index.md`, `docs/plan/environment.md` and
`docs/plan/tasks/`. Reusable document templates live in `docs/plan/templates/`.
Do not read every task or prompt for one operation. A delegated agent reads its
assigned packet and applicable project rules; it does not invoke this router.

For onboarding, read `docs/WORKFLOW-START.md`. For T000, use the task's read-only
setup verification recipe rather than the normal implementation team.

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

# Project working agreement

## Communication

Keep visible planning/status concise; save detail in docs/plan. Show outcome, scope, evidence and next action. Ask ordinary chat questions with no timeout, preferably one at a time. Do not interpret silence as approval. Unanswered required questions remain pending across pauses and resumption. Read only the context needed for the current task; follow relevant links when necessary.

## Scope

Use docs/workflow.md for the five operations: project planning, task creation, refinement, implementation and review. A project plan authorizes documentation, not application implementation. Implement the selected ready task only. Future ideas go to the task index. Preserve simple boundaries for growth without building unused hooks/adapters/frameworks. Favor one demonstrable outcome and the actual consumer integration.

## Readability

Use descriptive names and explicit control flow. In brace-based languages, always use braces for if/else/for/while bodies. Separate logical steps with blank lines. Avoid compressed one-liners, nested ternaries and unnecessarily clever chains. In BSL use idiomatic explicit blocks and the project's naming language. Keep related behavior together; extract operations by responsibility rather than arbitrary size. Follow existing good examples identified in the task; do not preserve unreadable compression merely because it exists nearby. No unrelated reformatting.

## Implementation pipeline

Only the top-level coordinator applies this pipeline. Delegated agents complete their assigned roles and do not orchestrate the task. For normal tasks, explicitly delegate a bounded worker (Terra Medium) and then an independent reviewer (Sol Medium) on stable edits. Coordinator is Sol Medium selected in the client. Luna Medium is for mechanical work; Sol High handles unfamiliar integrations; Astra Medium is a bounded escalation. At most two active children, one writer, no nested delegation. Tiny changes can use one agent. Workers run appropriate checks; reviewers examine actual code and evidence. Two failed repairs of one issue require diagnosis before further attempts. Do not mark unmet requirements complete.

## Context tools

Use Graft for subsystem orientation when its index is available and useful. Use Serena for supported symbol/reference operations. Use targeted text search and source reads for literal/config searches and missing detail. Verify implementation-sensitive claims against current source. Do not perform the same exploration through every tool or treat retrieval savings as measured Codex quota savings. Keep instructions consistent with installed tool capabilities. Do not add tools by default.

## Evidence and delivery

Use the verified commands in docs/plan/environment.md. Run relevant required checks; avoid repeating passing checks without a change or concern. Track source, build, runtime and deployment separately, especially for 1C. Update task evidence and current feature docs. Preserve pre-existing work. Execute authorized delivery actions; report exact blockers and unverified stages. Do not claim compilation proves runtime correctness. Finish with a short entry-point/flow explanation and next action.
