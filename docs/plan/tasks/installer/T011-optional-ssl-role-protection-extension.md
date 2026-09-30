# T011 — optionally install an SSL/BSP role-protection extension

Status: deferred
Depends on: user-supplied behavior; T005, T008
Recipe: complex; refine before implementation
Coordinator: Sol Medium
Worker: integration specialist, Sol High
Reviewer: Sol Medium

## Decision card

Outcome: placeholder for an optional additional extension intended to prevent
infobases based on SSL/BSP from removing Moleculer roles from a user.
Included: task discovery only until the user supplies the exact library behavior,
affected roles, trigger, artifact, supported versions, and opt-in interaction.
Deferred: all implementation and installation behavior.
Success: not yet defined.
Next: user will add details later.

## Known constraints

- Treat this as a separate optional artifact and explicit user choice.
- Do not infer that “SSL” means a particular 1C library/version until confirmed.
- Do not change roles, users, access groups, or infobase data while refining.
- Later acceptance must cover idempotency, least privilege, upgrade/removal,
  interaction with standard role synchronization, and recovery.
- Coordinate bundling with T005 and installation with T008 only after the artifact
  and its trust/version contract are known.

## Stop conditions

Do not implement, bundle, download, or install this extension before the missing
requirements and an authorized disposable SSL/BSP-based infobase are supplied.
