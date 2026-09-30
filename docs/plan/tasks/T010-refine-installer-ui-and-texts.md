# T010 — provide a guided bilingual installer flow

Status: draft
Depends on: T009, T013
Recipe: normal
Coordinator: Sol Medium
Worker: Terra Medium
Reviewer: Sol Medium
Optional QA: Terra Medium

## Decision card

Outcome: Russian- and English-speaking administrators complete a guided installer
flow and recover from errors without reading code.
Included: four guided stages, session-language localization, form information
hierarchy, all state messaging, and concise connector-specific help.
Deferred: visual rebranding and new installer capabilities.
Success: representative users complete status/source, connection, review/install,
and restart stages in Russian and English.
Next: refine wording and layout after backend task contracts stabilize.

## Acceptance and consumer example

- [ ] Use connector source and public behavior as the factual basis for help text;
      do not expose implementation details or stale `MoleculerOneS` wording.
- [ ] Provide equivalent useful Russian and English text for captions, explanations,
      validation errors, confirmations, and recovery guidance, selected
      automatically from the current 1C session language through metadata
      synonyms and `NStr`.
- [ ] Present four stages: status and source; connection settings; review and
      install; result and restart guidance.
- [ ] Distinguish current/selected/bundled/latest versions and active/inactive/
      absent/unknown states without relying on color alone.
- [ ] Make GitHub-unselected, loading, unavailable, empty, and rate-limited states
      understandable while preserving the bundled choice.
- [ ] Keep install, update, downgrade, activation, and removal states and
      confirmations explicit.
- [ ] Exercise the real form in both languages and at relevant width/scaling;
      compilation alone is insufficient UI evidence.

## Context and verification

Primary files are the managed form XML/module and installer metadata. Use the
settled T003–T009 and T013 state contracts and connector terminology. Do not add
a manual language switch. Exercise both session languages, every wizard state,
and representative width/scaling; compilation alone is insufficient UI evidence.
