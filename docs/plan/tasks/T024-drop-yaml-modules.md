# T024 — Delete the four dead YAML modules

Status: ready
Depends on: none
Recipe: simple
Coordinator: Sol Medium
Worker: Terra Medium
Reviewer: Sol Medium

## Decision card

Outcome: `YAML`, `YAML1`, `YAML2` and `YAML3` are gone from the extension, and the
configuration stops declaring modules nobody calls.

Included: the four module directories and their descriptors, their four
`Configuration.xml` entries, their four subsystem items, and their
`ConfigDumpInfo.xml` rows. Also the unreachable lines left behind in
`mol_SchemaFactory`.

Deferred: everything else in the refactoring cycle
([refactor-backlog.md](../refactor-backlog.md)).

Success: the canonical extension still builds, both suites stay green, and no
reference to the removed modules remains.

Next: T025, the inbound transport integration test.

## Why it is safe

The owner states YAML is validated and converted on the Node side on purpose,
because the BSL side was not fast enough. The code confirms it:

```bsl
Return Moleculer.Call("$sidecar.utils.parseYAML", Params);
Definition = StrReplace(Text, Chars.Tab, "    ");   // unreachable
Return YAML.ToObject(Text);                         // unreachable
```

`mol_SchemaFactory.ParseServiceDefinition` returns the sidecar call first, so the
local parser is never reached. `mol_Helpers.FromYAMLString` likewise calls
`$sidecar.parseYAML`. Nothing executes these modules, so there is no behaviour to
preserve.

## Acceptance and consumer example

- [ ] `CommonModules/YAML`, `YAML1`, `YAML2`, `YAML3` and their `.xml`
      descriptors are deleted.
- [ ] `Configuration.xml` declares no removed module.
- [ ] `Subsystems/Moleculer.xml` lists no removed module.
- [ ] `ConfigDumpInfo.xml` carries no row for a removed module.
- [ ] `mol_SchemaFactory.ParseServiceDefinition` no longer contains unreachable
      statements.
- [ ] `vrunner cfe compile --src src/cfe/MoleculerSidecarConnector` succeeds.
- [ ] `tests/bsl/run-tests.sh` is green, so the removal did not disturb anything
      the suites cover.
- [ ] `tools/bsl-checks/find-procedure-as-function.py` reports no candidates.

## Stop conditions

Stop if anything outside the four modules turns out to reference them: that would
mean the code is reachable after all and the premise is wrong. Record it and hand
it back rather than deleting a caller.
