# T037 — the connector calls platform members newer than its compatibility mode

Status: draft — needs one owner decision before it can be fixed.
Depends on: the platform-support decision
Recipe: simple
Coordinator: Sol Medium
Worker: TBD
Reviewer: Sol Medium

## Decision card

Outcome: the code and the declared compatibility mode agree, so no call the connector makes is unavailable in
the mode the extension declares.

Why: `Configuration.xml` declares `ConfigurationExtensionCompatibilityMode` = `Version8_3_21`, while
`mol_Errors` calls `ОшибкаРаботыСРечью` and `ОшибкаТабличногоПространстваБазыДанных`, both of which exist from
8.3.23. The platform installed here is 8.3.24, so the members exist on the image but are hidden from code
running under the lower declared mode.

Success: the two findings disappear from the static gate, and whatever replaces them is verified in the mode
the extension declares.

## Evidence

Two `UnavailableMemberCall` findings — `mol_Errors/Ext/Module.bsl:255` and `:263` — from
`tools/bsl-checks/bsl-language-server.py`, against the manifest line
`src/cfe/MoleculerSidecarConnector/Configuration.xml:47`. Both sit inside error-message construction, taken
only while an error is being reported, which is why they have survived.

One piece of evidence already points at alignment: the generated standalone variant declares `Version8_3_24`
(`build/standalone/default/INSTALL.md`, "Сборка создана для режима совместимости"), so the two halves of the
product disagree about the platform they require, and the code the variant shares already assumes the newer
one.

## Shape, to confirm during refinement

Either raise the declared compatibility mode — a consumer-visible decision, since the extension would then
require a newer platform — or stop using the two members on those paths. That choice belongs with the
platform-support decision, not with the error module.

## Acceptance and consumer example

- [ ] The static gate reports no `UnavailableMemberCall`, and the baseline entry for it is deleted.
- [ ] The declared mode and the members the code uses agree, so the extension cannot fail on a path the
      declaration says it supports.
- [ ] Extension mode and the standalone variant declare the same platform requirement, or the difference is
      documented as deliberate.

## Stop conditions

Stop and ask the owner which platform the extension is allowed to require. Raising the mode restricts who can
install the extension, and dropping the members may weaken error messages — neither is a refactor decision.
