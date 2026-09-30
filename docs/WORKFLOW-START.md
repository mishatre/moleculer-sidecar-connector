# Use this project from Orca or VS Code

The workflow is already copied into this repository. You do not need the
llm-manager repository inside the container.

## Orca

1. Create a worktree for the issue you are working on, for example
   `orca worktree create --issue 4 --agent codex`.
2. Orca reads `orca.yaml` from the primary checkout. Its setup hook runs
   `tools/orca/container.sh up`, which builds and starts that worktree's own dev
   container, and the default tab opens a shell inside it. Setup runs before the
   agent starts.
3. The agent works in the worktree on macOS. Every 1C or OneScript command goes
   through the container:

   ```bash
   tools/orca/container.sh run oscript -version
   tools/orca/container.sh run tools/1c-platform/open-infobase.sh client ib
   tools/orca/container.sh shell
   ```

4. `gh` inside the container is authenticated from `GH_TOKEN`, which the setup
   hook resolves from the host's `gh auth token`. Nothing is written to disk.

## VS Code and the Dev Containers extension

1. Export the GitHub token first, so the container's `gh` is authenticated:
   `export GH_TOKEN=$(gh auth token)`.
2. Open this project in VS Code and run **Dev Containers: Reopen in Container**.
3. In that window, confirm the terminal reports `/workspace` for `pwd`.
4. Open the Codex extension in the container window and sign in if asked.
   The devcontainer already requests `openai.chatgpt`; check that it is installed
   and enabled for this remote window if the panel is missing.
5. Start a new Codex conversation, select **Sol / Medium**, and trust the
   project if prompted and appropriate. Local `.codex/config.toml` supplies
   defaults when supported; check the picker rather than assuming it changed.

VS Code and Orca reach the same container for a worktree: same compose file, same
project name, `<worktree>_devcontainer`.

## Seeing the 1C client

The client is a GUI program and the container has no screen, so it draws on the
macOS host's XQuartz server. Once per X server start, on the host:

```bash
xhost +127.0.0.1
```

Then, inside the container:

```bash
tools/1c-platform/open-infobase.sh client ib      # thin client
tools/1c-platform/open-infobase.sh designer ib    # designer
```

The script fails with the exact host command when the display is not reachable.
Details, including what is verified and what is not, are in
[plan/environment.md](plan/environment.md).

## Ordinary requests

```text
Plan this project. Here is my full description: ...
Create a task for [feature or problem]. Do not implement it yet.
Refine CORE-001 for implementation later.
Implement CORE-001.
Review [feature or task] and create follow-up tasks.
Commit this work.
```

A task is a GitHub issue, so `CORE-001` means the issue with that title; `gh issue
list --search "CORE-001 in:title"` finds it. Implementation ends by opening a pull
request on its own — you do not need to ask for that in every conversation. "Commit
this work" exists for work that is already finished.

Use "Create a task" for a new feature or fix; use "Plan this project" for the
overall roadmap. Creation files a draft issue; refinement makes it
implementation-ready. You can also ask "Create and refine a task for…" to do both.

AGENTS.md tells the agent which LOCAL prompt to read. You need not paste the entire
pipeline or remember its file layout. Planning can use Plan mode; saving the
agreed files may need a normal-mode turn. Implementation uses normal mode.

## Path mapping

| File | In this container |
|---|---|
| Project instruction entry point | `/workspace/AGENTS.md` |
| Pipeline | `/workspace/docs/workflow.md` |
| Operation prompts | `/workspace/docs/workflow-prompts/` |
| Plan, domains and domain cards | `/workspace/docs/plan/README.md` |
| The rules for issues, domains and pull requests | `/workspace/docs/plan/conventions/` |
| Code standards for BSL | `/workspace/docs/code-standards/README.md` |
| Agent configuration | `/workspace/.codex/` |
| Issue and pull request templates | `/workspace/.github/` |

`docs/workflow.md` means "start at the project root and open docs/workflow.md."
A Markdown hyperlink, separately, resolves relative to the Markdown file that
contains it. Instructions explicitly define project-root semantics for bare
paths. On a host checkout use its actual root; do not use `/workspace` there.

This works because Compose mounts the project directory at `/workspace`.
These files appear immediately in a running bind-mounted container. Adding
documentation and project config does not require rebuilding the image; start
a fresh Codex session for instruction/config discovery.

## Current verification limits

The host-side setup validated workflow files, not a 1C build or model routing. The
dev container, the container's `gh`, and the X11 route to XQuartz are verified as
recorded in [plan/environment.md](plan/environment.md); opening a 1C window over
XQuartz is not, because it needs an activated licence. The current devcontainer runs
as root, so user-level Codex files belong inside the container, not in the macOS
home. No host Codex authentication folder is mounted; rebuilds may require
reauthentication depending on how the client stores credentials. The project
workflow survives because it is in the mounted repository. You do not need Graft or
Serena to start this workflow.

[Dev Containers documentation](https://code.visualstudio.com/docs/devcontainers/containers)
· [Orca](https://github.com/stablyai/orca)
· [Codex project configuration](https://learn.chatgpt.com/docs/config-file/config-basic)
