# T038 — every first-party source file declares its copyright and license

Status: in_progress — implemented and tested 2026-09-30 with the proposed MIT / M.Tregub
header; the license choice is still the owner's to confirm before this moves to history.
Depends on: owner decision on license and copyright holder
Recipe: normal; mechanical once the license is confirmed
Coordinator: Sol Medium
Worker: Luna Medium
Reviewer: Sol Medium

## Decision card

Outcome: the repository states one copyright and license — in a root `LICENSE` file
and in a header on every first-party source file — so the terms of reuse are
unambiguous and machine-readable.

Included: the license choice, the root `LICENSE` text, one canonical header block per
language, the 1C `<Copyright>` metadata property, the sidecar `package.json` license
field, and a check that fails when a first-party file has no header.

Deferred: third-party trees keep their own licenses; no relicensing of vendored code,
and no change to generated output under `build/`.

Success: no first-party source file lacks the header, the header matches `LICENSE`,
and the new check catches a file that is missing the header.

Next: the owner confirms the license and holder, then the work is mechanical.

## Proposed decision (needs the owner's confirmation)

The owner asked to be consulted on the license and was not available, so these are
proposals, not settled:

| Item | Proposal | Why |
|---|---|---|
| License | **MIT** | permissive, short, and the common choice for this kind of connector; the 1C default in the example header (CC BY 4.0) is a content license with no patent grant, which fits source poorly |
| Copyright holder | **M.Tregub** | matches `<Vendor>M.Tregub</Vendor>` already in the connector configuration |
| Year | **2026** | current year |

The sidecar subproject `moleculer-sidecar-next/` is out of scope: the owner asked to
skip it. It has its own `package.json`, which currently declares `"license": "ISC"`, and
keeps its own terms. If the owner later wants one repository license, only the license
name, the license URL and the `LICENSE` text change; the header layout and the steps
below do not.

## Canonical header block

Byte-for-byte the same in every file, with the comment prefix of the language. Box
width 80 columns.

BSL and any `//` language:

```bsl
////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////
```

Shell, Python and any `#` language:

```bash
################################################################################
# Copyright (c) 2026, M.Tregub
# SPDX-License-Identifier: MIT
# All rights reserved. This program and its accompanying materials are provided
# under the terms of the MIT License.
# The license text is available at:
# https://opensource.org/licenses/MIT
################################################################################
```

Rules:

- A shebang (`#!/usr/bin/env bash`, `#!/usr/bin/env python3`) stays on line 1; the
  block follows it.
- In a BSL module the block is above the first compilation directive or region, so it
  is the first thing in the file.
- The block is a comment, so it never changes behaviour.

## Scope inventory (measured 2026-09-30)

| Group | Count | Path | Header form |
|---|---:|---|---|
| Connector BSL | 38 | `src/cfe/MoleculerSidecarConnector/**/*.bsl` | `//` block |
| Installer BSL | 2 | `src/epf/installer/**/*.bsl` | `//` block |
| Test BSL | 23 | `tests/bsl/**/*.bsl` | `//` block |
| Scripts | 14 | `tools/**` and `tests/**` (`*.sh`, `*.py`, `*.os`) | `#` block |
| 1C configuration XML | 2 | `src/cf/Configuration.xml`, `src/cfe/MoleculerSidecarConnector/Configuration.xml` | `<Copyright>` property |
| Repository root | 1 | new `LICENSE` | license text |

77 files take a comment header. The two configuration documents take no comment: an
XML comment cannot precede the `<?xml ...?>` declaration, so the copyright goes into
the existing `<Copyright/>` property instead.

## Acceptance and consumer example

- [ ] Add a root `LICENSE` file with the chosen license text, and link it from
      `README.md`.
- [ ] Add the canonical block to all 63 BSL modules.
- [ ] Add the canonical `#` block to the 14 scripts, below the shebang.
- [ ] Fill the `<Copyright>` property in the two `Configuration.xml` files for at
      least `ru` and `en`, matching `<Vendor>M.Tregub</Vendor>`.
- [ ] Leave `oscript_modules/`, `vendor/`, `build/` and the whole
      `moleculer-sidecar-next/` subproject untouched.
- [ ] Add a header check (see below) and wire it into `tools/check.sh` so a missing
      header fails the gate.

## The header check

Add `tools/bsl-checks/check-headers.py` (or an equivalent small script) that:

- walks the same file groups as the inventory table;
- looks only at the first lines of each file, so a copied block in the middle does not
  pass;
- requires the copyright line and the `SPDX-License-Identifier` line;
- reports every offending path and exits non-zero.

Wire it into `tools/check.sh` as a new `headers` layer, first in the layer order
because it is the cheapest, and add it to `ALL_LAYERS`. Update
`tools/bsl-checks/README.md` with the new check.

## Context and verification

- The comment prefix differs by language, so the check must know the language from the
  file extension; do not require the `//` block in a `.sh` file.
- A leading comment must not break any build. Re-run the two build layers and the
  static gate after the change:

  ```bash
  vrunner cfe compile --src src/cfe/MoleculerSidecarConnector --ibcmd --v8version 8.3 build/out/MoleculerSidecarConnector.cfe
  vrunner epf compile --out ./build/out/epf --v8version 8.3 --ibconnection /F./build/ib --src-format xml src/epf/installer
  tools/check.sh --layers static,headers
  ```

- The `<Copyright>` property is a localized string (`v8:item` / `v8:lang` /
  `v8:content`). Confirm the exact shape by compiling the connector after the edit; a
  wrong shape must fail the compile, not the runtime.
- `docs/` is not tracked in Git, so the root `LICENSE` and the source headers are the
  authoritative statements; the code-standards documents only reference them.

## Delivery and authority

Deliver reviewed source changes, the root `LICENSE`, the `package.json` field and the
new check. No artifact is published; the compiled outputs are verification only.

## Stop conditions

- Stop until the license and holder are confirmed; MIT and M.Tregub are proposals.
- Do not add an XML comment before the `<?xml ...?>` declaration.
- Do not modify files under `oscript_modules/`, `vendor/`, `node_modules/` or
  `build/`.
- Do not mix this change with a code change: it is header-only, so the diff stays
  reviewable.

## Completion evidence / resume point

Applied 2026-09-30 with the proposed license. Source, build and check evidence:

| Stage | Result |
|---|---|
| Header coverage | `python3 tools/bsl-checks/check-headers.py` → `checked 77 file(s)`, `PASS` |
| Negative case A | a 79-character box → `first line is not the 80-column '/' box`, exit 1 |
| Negative case B | the `SPDX-License-Identifier` line removed → `missing 'SPDX-License-Identifier:'`, exit 1 |
| Connector build | `vrunner cfe compile --src src/cfe/MoleculerSidecarConnector --ibcmd --v8version 8.3 build/out/MoleculerSidecarConnector.cfe` → exit 0, 1 622 205 bytes |
| Installer build | `vrunner epf compile --out ./build/out/epf --v8version 8.3 --ibconnection /F./build/ib --src-format xml src/epf/installer` → exit 0, 163 496 bytes |
| Gate layer | `tools/check.sh --layers headers` → passed |
| Gate layer | `tools/check.sh --layers static` → **FAILED**, see below |

Files: 77 headers (63 BSL, 14 scripts), the root `LICENSE`, two `<Copyright>`
properties. `git diff --numstat` over `src tests tools` is a clean header-only insert
(11 inserted lines, at most 1 deleted leading blank) for every file except two that
carry concurrent uncommitted work from another session:
`mol_ContextFactory/Ext/Module.bsl` (a `RaiseCustomError("Error"…)` retype) and
`mol_Errors/Ext/Module.bsl` (an added `ElsIf Type = "Error" Then` branch).

The static layer's single regression, `IfElseDuplicatedCodeBlock: 3 -> 4`, is caused by
that concurrent `mol_Errors` edit, not by the headers: a pristine checkout of `HEAD` in
a temporary worktree passes with `3`, and the working tree now has two identical
`ElsIf Type = "Error" Then` branches at lines 53 and 65. Updating the baseline, or
deduplicating the branch, belongs to that workstream.

Not yet done: the owner confirms the license and holder (MIT and `M.Tregub` are
proposals), and the reviewer's note that the check enforces the block's first line and
the four required lines but not the block's interior wording.

Independent review: a subagent reviewed the tree and returned **SOUND**, with two
findings — the stale 76/13 counts (now corrected to 77/14) and the duplicate branch
above. The review session had no shell, so the diff and the negative tests were confirmed
by the coordinator rather than by the reviewer.
