# Static checks

`bsl-language-server.py` runs `1c-syntax/bsl-language-server` over the connector sources and compares the
result with a recorded baseline.

```bash
tools/bsl-checks/bsl-language-server.py                       # the connector, against the baseline
tools/bsl-checks/bsl-language-server.py --source <DIR>        # another tree with the same rule set
tools/bsl-checks/bsl-language-server.py --print-baseline      # observed counts as JSON
```

Exit code is 0 when no rule is above its baseline, 1 when one is. The report lands in
`build/test/reports/bsl-ls/`.

The language server is not vendored: its jar ships inside the `1c-syntax.language-1c-bsl` VS Code
extension, so the runner looks for it under `~/.vscode-server` rather than a repository path. Set
`BSL_LS_JAR` to use another copy. Java is on the image (`/usr/bin/java`, OpenJDK 21), so the analysis
does run in this container — an earlier note in `docs/plan/environment.md` claimed no JRE was
available and is corrected there.

## Why the rule set is selected, not defaulted

With its default set, the connector's 38 modules produce **780** findings:

| Severity | Count |
|---|---|
| Hint | 469 |
| Information | 143 |
| Warning | 133 |
| Error | 35 |

That is far too much to gate on, and most of it is not about correctness. The three largest families are
decisions this repository has already made:

| Rule | Count | Decision |
|---|---|---|
| `Typo` | 214 | spelling of identifiers and comments, in two languages at once |
| `PublicMethodsDescription` | 107 | documentation completeness |
| `IncorrectLineBreak` | 61 | formatting — the connector's aligned `=` and trailing-comment columns are deliberate, and `.vscode/settings.json` turns BSL formatting off for the same reason |

So `.bsl-language-server.json` sets `diagnostics.mode` to `only` and lists twelve rules that catch
defects rather than preferences:

| Rule | What it catches |
|---|---|
| `MissingCommonModuleMethod` | a call to a common-module method that does not exist |
| `UnreachableCode` | statements that can never run |
| `UnavailableMemberCall` | a platform member newer than the declared compatibility mode |
| `FunctionShouldHaveReturn` | a function with no `Return` anywhere |
| `AllFunctionPathMustHaveReturn` | a path through a function that returns nothing |
| `FunctionReturnsSamePrimitive` | a function that always returns the same literal |
| `UnusedLocalMethod` | a local method nothing calls |
| `UnusedLocalVariable` | a local variable nothing reads |
| `DeletingCollectionItem` | deleting from a collection while iterating it |
| `QueryToMissingMetadata` | a query against metadata that does not exist |
| `EmptyCodeBlock` | a branch or loop with no statements |
| `IfElseDuplicatedCodeBlock` | identical `If`/`Else` branches |

That selection takes the count from 780 to **63**, which is small enough to hold in a baseline and read
by hand.

## The baseline, and what a failure means

`bsl-ls-baseline.json` records how many findings each rule had when the selection was fixed. A rule above
its count fails the run; a rule below it is reported so the baseline can be tightened; a rule that has
disappeared is reported so it can be dropped. Verified in both directions on 2026-09-30: the connector
passes at 63, and adding one unused local variable to a copy of the tree fails the run with
`UnusedLocalVariable: 14 -> 15`.

Counts are per rule rather than per finding, so a fix in one file can hide a new occurrence in another.
The per-rule table is the audit trail, and that limitation is the reason the list is kept short.

## What the rule set found on its first run

Three entries are not debt in the ordinary sense:

* **`MissingCommonModuleMethod`** — was a real defect, fixed under T036. `mol_AdminPanel`'s
  `ServiceItemForm` called `mol_Broker.GetActivePublications()`, which never existed, and read
  `Publication.Info.Id` from a structure whose field is `Id`. The facade's `Moleculer.GetPublications()`
  returns exactly the flat structure the sibling paths in `mol_Broker` already use, and the sidecar's
  `updateService` expects the `publicationID` and `service` the form sends, so the payload was right and
  only the call and the field name were wrong. It loaded because the platform reads metadata without
  compiling form bodies, so it surfaced only when that form was opened. The baseline entry is deleted, and
  that deletion is the proof: the rule can no longer fire anywhere in the tree.
* **`UnavailableMemberCall`** — a real defect, twice. `mol_Errors` uses `ОшибкаРаботыСРечью` and
  `ОшибкаТабличногоПространстваБазыДанных`, which exist from 8.3.23, while the extension declares
  `ConfigurationExtensionCompatibilityMode` = `Version8_3_21`. The platform is 8.3.24, so the code cannot
  be exercised in the mode it declares. Both are inside error-message construction, which is why they have
  stayed hidden. Tracked as T037.
* **`QueryToMissingMetadata`** — correct by construction. `mol_Reuse` queries
  `InformationRegister.ВерсииПодсистем`, a register of the host configuration the connector extends, not
  of the extension itself.

The remaining rules are ordinary debt: dead local methods and variables, empty blocks, functions with a
missing `Return`, duplicated `If`/`Else` branches.

## The other check

`find-procedure-as-function.py` looks for a procedure called as a function, the mistake that once stopped
`mol_ContextFactory` from compiling. It is independent of the language server.
