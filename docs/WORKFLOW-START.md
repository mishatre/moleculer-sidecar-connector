# Use Codex in this project

The workflow is already copied into this repository. You do not need the
llm-manager repository inside the container.

## Start once

1. Open this project in VS Code and run **Dev Containers: Reopen in Container**.
2. In that window, confirm the terminal reports `/workspace` for `pwd`.
3. Open the Codex extension in the container window and sign in if asked.
   The devcontainer already requests `openai.chatgpt`; check that it is installed
   and enabled for this remote window if the panel is missing.
4. Start a new Codex conversation, select **Sol / Medium**, and trust the
   project if prompted and appropriate. Local `.codex/config.toml` supplies
   defaults when supported; check the picker rather than assuming it changed.
5. Send this exact first request:

```text
Read /workspace/AGENTS.md and docs/plan/tasks/history/T000-verify-workflow.md.
Implement T000 only. Verify the workspace, instructions, tools and model/agent
configuration without changing application source or building/updating an
infobase. Save results in the task. Ask ordinary untimed questions if needed.
```

After T000, use these ordinary chat requests:

```text
Plan this project. Here is my full description: ...
Create a task for [feature or problem]. Do not implement it yet.
Refine task T001 for implementation later.
Implement task T001.
Review [feature or task] and create follow-up tasks.
```

Use “Create a task” for a new feature or fix; use “Plan this project” for the
overall roadmap. Creation saves a draft; refinement prepares it for implementation.
You can also ask “Create and refine a task for…” to do both documentation steps.

AGENTS.md tells Codex which LOCAL prompt to read. You need not paste the entire
pipeline or remember its file layout. Planning can use Plan mode; saving the
agreed files may need a normal-mode turn. Implementation uses normal mode.

## Path mapping

| File | In this container |
|---|---|
| Project instruction entry point | `/workspace/AGENTS.md` |
| Pipeline | `/workspace/docs/workflow.md` |
| Operation prompts | `/workspace/docs/workflow-prompts/` |
| Plan and tasks | `/workspace/docs/plan/` |
| Agent configuration | `/workspace/.codex/` |

`docs/workflow.md` means “start at the project root and open docs/workflow.md.”
A Markdown hyperlink, separately, resolves relative to the Markdown file that
contains it. Instructions explicitly define project-root semantics for bare
paths. On a host checkout use its actual root; do not use `/workspace` there.

This works because Compose mounts the project directory at `/workspace`.
These new files appear immediately in a running bind-mounted container. Adding
documentation and project config does not require rebuilding the image; start
a fresh Codex session for instruction/config discovery.

## Current verification limits

The host-side setup found no running container for this project. It validated
new workflow files, not a 1C build or VS Code model routing. T000 verifies the
container side. Source changes already existed before workflow installation.

The current devcontainer runs as root. User-level Codex files, if using the
default home, belong inside that container, not your macOS home. No host Codex
authentication/config folder was mounted and no persistent credential volume
was added. Rebuilds may require reauthentication depending on how the client
stores credentials; the project workflow survives because it is in the mounted
repository. You do not need Graft or Serena to start this workflow.

[Dev Containers documentation](https://code.visualstudio.com/docs/devcontainers/containers)
· [Codex project configuration](https://learn.chatgpt.com/docs/config-file/config-basic)
