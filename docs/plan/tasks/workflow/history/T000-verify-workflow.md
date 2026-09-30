# T000 — verify the project-local Codex workflow

Status: verified
Recipe: read-only environment onboarding; coordinator performs checks directly.
Coordinator: Sol Medium (select in client; report actual selection if observable).
Depends on: project opened in its dev container.

## Decision card

Outcome: Codex finds this project's workflow and identifies usable local tools.
Included: path/instruction checks, executable discovery, config inspection.
Deferred: application changes, 1C compilation, infobase mutation, deployment.
Success: checks below have evidence; remaining environment gaps are explicit.
Next: run this task inside the existing VS Code dev-container window.

## Acceptance

- [x] `pwd` and repository-root discovery identify `/workspace` in this container.
- [x] Read `/workspace/AGENTS.md`; confirm the four operation prompts, workflow,
      task index and templates exist inside `/workspace`.
- [x] `oscript --version` and `opm --version` report actual installed versions.
- [x] Identify `vrunner` and 1C executables; record unavailable tools honestly.
- [x] Inspect project model defaults and roles; report whether the client loads
      them. If model/role metadata is unavailable, leave routing unverified.
- [x] Update task and environment documentation with observed results.

If supported, perform ONE optional read-only child routing check with Terra
Medium using the task_worker role: identify the extension Configuration.xml
path and return it without editing. Inspect actual metadata if available;
a child's self-reported model name is not proof. Do not spawn a reviewer merely
to confirm that files exist. Role routing is a distinct evidence item; if it is
unverified, do not claim the multi-agent pipeline was validated.

## Authority and stop rules

Authorized: read local files, tool version/help checks, update workflow evidence.
No application/source/config changes, dependency installs, builds, publication,
new infobases or `--updatedb`. Missing required executable/access is a blocker to
that check, not permission to install/reconfigure everything. Ask one untimed
question when needed; other independent checks may continue.

## Evidence / resume point

Verified on 2026-09-10. Verification covers discovery and observed tools;
model routing remains explicitly unverified as allowed by acceptance.

- `pwd` and `git rev-parse --show-toplevel`: `/workspace`; `/.dockerenv` exists.
- Read root `AGENTS.md`, `docs/workflow.md`, the implementation prompt and
  `docs/WORKFLOW-START.md`. All four routed prompts, task index and four
  templates exist within this repository.
- `oscript --version` prints the 2.1.0 engine banner and usage; this installation
  documents `-version`, not `--version`. `oscript -version` returns `2.1.0`.
  `opm --version` returns `1.4.1`.
- `command -v` finds oscript, opm and vrunner beneath
  `/home/usr1cv8/.local/share/ovm/current/bin/`.
  `vrunner --version` reports an unknown parameter despite exit code 0.
  `vrunner --help` succeeds and identifies vanessa-runner v2.6.1; its documented
  version command is `vrunner version` (not separately run).
- `1cv8`, `1cv8c`, `ibcmd`, `rac`, `ragent`, and `ras` are executable files under
  `/opt/1cv8/current`, resolving to `/opt/1cv8/x86_64/8.3.24.1667`.
  This is filesystem evidence, not platform execution or runtime validation.
  Configured debugger path `/opt/1C/v8.3/x86_64` is absent.
- Inspected `.codex/config.toml` and all six `.codex/agents/*.toml` files.
  Defaults request Sol Medium and Terra Medium children, with concurrency 2.
  Exposed role definitions match the six project roles and their configured
  model/effort pairs. The current session exposes three total agent slots.
  Actual coordinator model/effort and whether project defaults were applied
  are not observable; selection of Sol Medium is not established.
- One optional `task_worker` child (`/root/t000_routing`) completed the read-only
  lookup: `/workspace/src/cfe/MoleculerSidecarConnector/Configuration.xml`.
  Tool metadata defines this role as Terra Medium, but spawn/list results expose
  no actual runtime model/effort. Role invocation works; actual model routing
  and the full implementation/review pipeline remain unverified.
- Graft and Serena tools are not exposed in this session. Local text/file
  inspection is available; no plugins or dependencies were installed.
- Default shell execution failed before the command with bwrap namespace denial.
  Automatically approved escalated execution allowed the read-only checks and
  evidence updates; the sandbox configuration was not changed.
- Existing extensive changes were inspected and preserved. Only this task,
  `docs/plan/environment.md` and `docs/plan/index.md` were edited for evidence.

Source/application changes: none. Build, infobase load/update, runtime and
 deployment: not performed; outside scope. No independent reviewer was needed
for the T000 recipe.

Next: describe the next application task. To verify model routing separately,
inspect the client's selected model/effort and authoritative child runtime
metadata when available; do not infer them from configuration or self-reports.
