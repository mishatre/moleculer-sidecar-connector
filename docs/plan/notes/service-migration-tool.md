# Service module migration — moved to an issue

Status: 2026-09-30. The task definition, its decisions, the two shapes and the open questions now live in
[T029](https://github.com/mishatre/moleculer-sidecar-connector/issues/8), so that a delegated worker has
one packet instead of a plan document and a task list to reconcile.

This page survives only because other documents link to it.

Still separate, and still here:

- the vocabulary specification in [../old-code-version/ANALYSIS.md](../../old-code-version/ANALYSIS.md) — the
  oldest connector parsed the `|`-suffixed parameter vocabulary in BSL, which makes it the written source for
  the mapping table T029 needs;
- the corpus, `docs/service-migration/examples/` and the shape reference `docs/service-migration/ideal.bsl`.
