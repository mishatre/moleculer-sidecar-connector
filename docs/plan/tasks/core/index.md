# CORE — canonical connector

Scope: `src/cfe/MoleculerSidecarConnector/`, `src/cf/`, `tests/bsl/canonical/`, `tests/bsl/common/`.
Next free ID: allocate inside this domain, per [tasks.md](../../conventions/tasks.md)
Roadmap: [open](https://github.com/mishatre/moleculer-sidecar-connector/issues?q=is%3Aissue+milestone%3ACORE+is%3Aopen) · [closed](https://github.com/mishatre/moleculer-sidecar-connector/issues?q=is%3Aissue+milestone%3ACORE+is%3Aclosed) · [all](https://github.com/mishatre/moleculer-sidecar-connector/issues?q=is%3Aissue+milestone%3ACORE)
Rules: [tasks](../../conventions/tasks.md) · [domains](../../conventions/domains.md) · [commits](../../conventions/commits.md)

The tasks of this domain are GitHub issues in the `CORE` milestone; this card only routes to
them. Nothing is listed here, so two conversations never edit the same file.

```bash
gh issue list --milestone CORE --state open
gh issue list --milestone CORE --state all
```

Pick the next one with `status:ready`. A finished issue closes with its pull request.

The evidence and reasoning behind the refactoring work is
[refactor-backlog.md](../../notes/refactor-backlog.md). Protocol behaviour is described in
[connector-sidecar-protocol.md](../../notes/connector-sidecar-protocol.md) and the public interface
audit in [connector-architecture-audit.md](../../notes/connector-architecture-audit.md).
