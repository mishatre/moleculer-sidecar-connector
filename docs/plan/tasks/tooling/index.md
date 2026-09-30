# TOOLS — container and build/test machinery

Scope: `.devcontainer/`, `tools/1c-platform/`, `tools/bsl-checks/`, `tools/check.sh`, `tools/md-sparrow/`, and the harness scripts under `tests/bsl/`.
Next free ID: allocate inside this domain, per [tasks.md](../../conventions/tasks.md)
Roadmap: [open](https://github.com/mishatre/moleculer-sidecar-connector/issues?q=is%3Aissue+milestone%3ATOOLS+is%3Aopen) · [closed](https://github.com/mishatre/moleculer-sidecar-connector/issues?q=is%3Aissue+milestone%3ATOOLS+is%3Aclosed) · [all](https://github.com/mishatre/moleculer-sidecar-connector/issues?q=is%3Aissue+milestone%3ATOOLS)
Rules: [tasks](../../conventions/tasks.md) · [domains](../../conventions/domains.md) · [commits](../../conventions/commits.md)

The tasks of this domain are GitHub issues in the `TOOLS` milestone; this card only routes to
them. Nothing is listed here, so two conversations never edit the same file.

```bash
gh issue list --milestone TOOLS --state open
gh issue list --milestone TOOLS --state all
```

Pick the next one with `status:ready`. A finished issue closes with its pull request.

Verified commands and the known limits of this toolchain are recorded in
[environment.md](../../environment.md); that page is the authority, not this card.
