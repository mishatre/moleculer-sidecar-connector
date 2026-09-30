# Create a task

Create a task for [FEATURE / PROBLEM / REQUEST]. Use Sol Medium. This request
authorizes task documentation, not application implementation or deployment.
Follow the project AGENTS.md; all paths below are relative to this project root.

Read docs/plan/README.md, the target domain's card, the relevant project context and
`.github/ISSUE_TEMPLATE/task.md`. Inspect only the source needed to understand the
request and name useful entry points. Check that domain's issues for related work and
used IDs, in every state — the retired `T0NN` series is still open in places:

```bash
gh issue list --milestone CORE --state all --search "CORE- in:title" --limit 200
```

If an existing issue already covers the same outcome, update or link it instead of
creating a duplicate; preserve its existing scope and evidence, and report what you did.

Identify the immediate useful outcome. Separate required-now behaviour from future ideas.
Create one small, demonstrable issue; if the request spans several independent outcomes,
create a small set of linked draft issues — one per domain — and recommend which comes
first. Do not create a full project roadmap for one feature.

Pick the domain first, following docs/plan/conventions/domains.md, take the next free
`<PREFIX>-<NNN>` from that domain's issues, and file it with the domain label, the draft
status and the domain milestone:

```bash
gh issue create --repo mishatre/moleculer-sidecar-connector \
  --title "CORE-001: parse service definitions locally" \
  --body-file <file> --label domain:core,status:draft,recipe:normal --milestone CORE
```

Use `.github/ISSUE_TEMPLATE/task.md` as the body. Never renumber a closed issue, never
reuse a number, and never add a prefix to a `T0NN`. Record a short decision card, initial
acceptance examples, in/out scope, relevant files, dependencies, delivery target and known
unknowns. Keep unverified commands explicitly unverified. Nothing else needs an edit: the
domain card routes to the issue queries on its own.

Default to draft: creation captures work; refinement makes it implementation-ready. If the
user explicitly asks to create AND refine it, follow
docs/workflow-prompts/02-refine-task.md after filing. Neither operation authorizes
implementation. Do not run worker/reviewer teams just to capture a task.

Save useful context even when something is unclear. Ask one ordinary untimed question only
when a material decision is needed; keep it pending across pauses. Never treat silence as
agreement. Put detailed context in the issue and return only the issue number, short
outcome, URL, and next recommended action.

User request:
[Describe what you need. Include the immediate outcome if known.]
