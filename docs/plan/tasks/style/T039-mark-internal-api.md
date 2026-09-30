# T039 — the internal API is marked with `// @internal`

Status: draft
Depends on: none — T040 renames the region; either order works
Recipe: normal; mechanical once the region inventory is taken
Coordinator: Sol Medium
Worker: Luna Medium
Reviewer: Sol Medium

## Decision card

Outcome: an exported routine that is not part of a module's public interface is
findable by a plain text search for `// @internal`.

Included: the marker on every exported routine inside an `Internal` region, the
documenting-comment placement rule, and a check that keeps the marker and the region
in step.

Deferred: renaming the region to `Internal` (T040) and restructuring the module
sections; no behaviour changes.

Success: the 80 exported routines in the internal regions carry the marker, no public
or overridable routine does, and a check fails when one is missing.

Next: apply after the region inventory is confirmed against the tree.

## Context and measured scope

The standard's `Internal` region (СлужебныйПрограммныйИнтерфейс) holds export routines
that are callable only from other objects of the same subsystem. The project's
requirement is that each of them carries the `// @internal` line, defined in
[procedure and function description § 5.9](../../../code-standards/procedure-and-function-description.md#59-marking-the-internal-api).

Measured 2026-09-30 over `src/**/*.bsl` and `tests/**/*.bsl`, with nested regions
taken into account:

| Region name in the tree | Modules | Exported routines inside |
|---|---:|---:|
| `#Region Protected` | 14 | 76 |
| `#Region Internal` | 1 | 4 |
| **Total** | **15** | **80** |

The region name is `Protected` today in most modules and `Internal` in
`MoleculerClientServer`; T040 renames them all to `Internal`. This task accepts either
name, so it is independent of T040.

The six non-export routines currently inside an internal region belong to T040, not
here:

- `mol_Errors` — `Error` (line 408)
- `mol_SchemaFactory` — `EvaluateServiceConstructor`, `GetDynamicServiceConstructor`,
  `FillServiceSchema`, `ProcessElements`, `CreateElement` (lines 224–344)

## Acceptance and consumer example

- [ ] Add `// @internal` as the last line of the documenting comment of every exported
      routine that sits in an `Internal`/`Protected` region.
- [ ] Where the routine has no other comment, the marker is the whole comment and still
      sits above the compilation directive.
- [ ] Do not add the marker to routines in a `Public` region or to the overridable
      connectors; those are public by design.
- [ ] Keep the marker a plain `// @internal` line, so `grep -rn '@internal'` finds it.
- [ ] Extend `tools/bsl-checks/check-headers.py` (added by
      [T038](../global/T038-license-and-copyright-headers.md)) or add a sibling check that fails
      when an exported routine in an `Internal`/`Protected` region has no marker, and
      when the marker appears outside one.
- [ ] Change no code other than comments; no region, name or body changes.

## Context and verification

- The region stack must be tracked with nesting, because `mol_Broker` and others put
  sub-regions inside `Protected`. A flat scan misses their routines.
- The check is comment-only, so it cannot change behaviour, but re-run the static layer
  and one compile to prove the files still load:

  ```bash
  tools/check.sh --layers static,headers
  vrunner cfe compile --src src/cfe/MoleculerSidecarConnector --ibcmd --v8version 8.3 build/out/MoleculerSidecarConnector.cfe
  ```

- The reference XML is not touched: `@internal` is an embedded-language comment, and the
  YAxUnit suites do not read it.

## Delivery and authority

Deliver reviewed comment-only source changes and the check. No artifact is published.

## Stop conditions

- Stop if a routine's region is ambiguous; report it rather than guessing.
- Do not mark overridable connectors or public-interface routines.
- Do not combine this with T040's rename in one diff; each stays reviewable on its own.

## Completion evidence / resume point

Record the counts before and after (exported in internal regions), the check output, and
the compile result.
