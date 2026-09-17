# Conventions

- Preserve the established 1C export layout and metadata/module pairing; application source lives only under `src/`.
- BSL uses explicit, idiomatic control flow and responsibility-based regions. Existing modules group public/protected/private APIs or Russian form responsibilities such as base parameters, event handlers, command handlers, and service procedures/functions.
- Use descriptive domain names in the module's existing language. Metadata and connector-owned objects commonly use the `mol_` prefix.
- Keep related behavior together; use blank lines between logical steps; avoid compressed one-liners and clever nested expressions.
- Extract operations by responsibility, not arbitrary length. Explain surprising invariants or transformations, not obvious syntax.
- For form work, keep XML event bindings aligned with renamed BSL handlers; treat observable form-state assignments and side-effect order as behavior.
- No unrelated formatting. Preserve CRLF for `*.bsl` and `*.xml` per `.gitattributes`.
- Preserve pre-existing worktree changes and generated/source boundaries.
- Workflow operations are coordinator-routed through `AGENTS.md`, `docs/workflow.md`, and the matching prompt. Implement only the selected ready task; record future ideas in the task index.
- Separate source/static, compilation, runtime, and deployment evidence. Never claim compilation proves runtime behavior.