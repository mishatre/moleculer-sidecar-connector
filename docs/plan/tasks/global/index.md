# GLOB — repository-wide

Scope: files that belong to no component — `.gitignore`, `.gitattributes`, `LICENSE`, `packagedef`, `autumn-properties.json`, the root `README.md` — and hygiene work that spans the whole tree, such as license and copyright headers.
Next free ID: allocate inside this domain, per [tasks.md](../../conventions/tasks.md)
Roadmap: [open](https://github.com/mishatre/moleculer-sidecar-connector/issues?q=is%3Aissue+milestone%3AGLOB+is%3Aopen) · [closed](https://github.com/mishatre/moleculer-sidecar-connector/issues?q=is%3Aissue+milestone%3AGLOB+is%3Aclosed) · [all](https://github.com/mishatre/moleculer-sidecar-connector/issues?q=is%3Aissue+milestone%3AGLOB)
Rules: [tasks](../../conventions/tasks.md) · [domains](../../conventions/domains.md) · [commits](../../conventions/commits.md)

The tasks of this domain are GitHub issues in the `GLOB` milestone; this card only routes to
them. Nothing is listed here, so two conversations never edit the same file.

```bash
gh issue list --milestone GLOB --state open
gh issue list --milestone GLOB --state all
```

Pick the next one with `status:ready`. A finished issue closes with its pull request.
