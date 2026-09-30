# T028 — parse service definitions locally

Status: draft
Depends on: owner decision on safe mode; T025
Recipe: normal
Coordinator: Sol Medium
Worker: TBD
Reviewer: Sol Medium

## Decision card

Outcome: a service constructor written in YAML compiles with **no sidecar node connected**, so the
capability stops depending on connectivity.

Why now: `mol_SchemaFactory.ParseServiceDefinition` sends anything that is not JSON to
`$sidecar.utils.parseYAML`. A YAML constructor therefore works only while a sidecar happens to be up, and a
dynamic-service constructor stored in `Catalog.mol_Services.ServiceConstructor` cannot use YAML for
anything at all — not even to convert it. The component's own speed is not the obstacle: parsing costs
~0.07 ms against ~2.5 ms for connecting it.

Included: the itemised work below.
Deferred: nothing recorded yet; the viability study lists the extensions that are deliberately out of
scope.
Success: a YAML constructor compiles and produces a schema with the sidecar stopped.
Next: refine against [yaml-native-parser-viability.md](../yaml-native-parser-viability.md), which holds
the measurements and the accepted requirement.

## What it involves

- a local parser behind the seams this project already has (`providerModule: MoleculerOverridable` at
  runtime, profile `patches` at build time), reading `vendor/YamlParserNative/`;
- connecting the component once and holding the instance. That also removes the per-call reconnect, and it
  is the same change that clears the safe-mode constraint: `CompileServiceSchema` wraps the service
  constructor in `SetSafeMode(True)`, and the platform forbids connecting an external component while safe
  mode is on;
- the conversions the requirement names, not just parsing: YAML to object, YAML to JSON, object to YAML;
- a bounded YAML subset — mappings, sequences and scalars. Anchors, tags, multiple documents and complex
  keys are needed by nothing in `src/`.

## Implementation context

Relevant files: `src/cfe/MoleculerSidecarConnector/CommonModules/mol_SchemaFactory/Ext/Module.bsl`
(`ParseServiceDefinition`), `MoleculerOverridable`, `tools/standalone-builder/profiles/default.json`, and
the loader path for `vendor/YamlParserNative/`.

Note: the platform has no YAML API, so the choice is a BSL parser or a Native API component. Native is
first-class (`AddInType = { COM, Native }`) and the loader accepts a configuration template, so one CFE can
carry the binary; a BSL parser is the lower-risk route, and a Native component cannot be built in this
container.

## Environment and verification

Link: [environment.md](../environment.md)

Commands: `tools/check.sh`; the canonical suite already carries 68 passing tests against the Native
component from the viability study, which is the starting point rather than a new suite.
Expected: the constructor compiles with no sidecar reachable — that is the whole point, so the check runs
with the sidecar stopped.

## Delivery and authority

Deliverable: source changes in the connector plus the vendored component. Publication of the component
remains a separate action.

## Stop conditions

Stop if the safe-mode constraint cannot be cleared without weakening safe mode for the rest of the
constructor path — record the constraint and hand it back rather than guessing.

## Priority

Low: nothing in `src/` reads YAML today, so this restores a capability rather than unblocking existing
code.
