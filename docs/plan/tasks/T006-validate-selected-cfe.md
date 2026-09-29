# T006 — research safe validation of a user-selected connector CFE

Status: deferred
Depends on: supported read-only CFE identity inspection mechanism
Recipe: complex; research before refinement
Coordinator: Sol Medium
Worker: integration specialist, Sol High
Reviewer: Sol Medium

## Decision card

Outcome: determine whether a supported read-only mechanism can identify and
validate an arbitrary CFE before any extension write.
Included later: documented feasibility evidence and a safe identity/version/
compatibility contract if the platform exposes one.
Deferred: local-file installation and all related installer controls.
Success: not defined until supported inspection is proven.
Next: revisit only when a supported API or tool can inspect CFE metadata safely.

## Acceptance and consumer example

- [ ] Identify an official supported read-only mechanism for extracting CFE
      identity and version, or document that none is available.
- [ ] Never infer identity from a filename or use destructive trial installation.
- [ ] If feasibility is established, create a new implementation-ready task with
      fixtures for valid, wrong, corrupt, empty, and incompatible artifacts.

## Context and verification

The platform can check applicability of binary extension data, but exploration
did not find a supported API that extracts arbitrary CFE identity/version before
write. `ibcmd extension info` applies to an already installed extension. The
active installer therefore offers bundled and GitHub release assets only.
