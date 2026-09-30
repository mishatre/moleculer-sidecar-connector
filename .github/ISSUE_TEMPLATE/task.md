---
name: Task
about: One demonstrable outcome with its acceptance, context and evidence
title: "<ID>: "
labels: status:draft
---

<!--
Title: <ID>: <outcome> — for example `CORE-001: parse service definitions locally`.
The ID is <PREFIX>-<NNN>, counted inside the domain, or a retired `T000`–`T040` number.
Labels: domain:<glob|style|core|stand|inst|tools|doc|flow>, status:<draft|ready|in-progress|verified|delivered|blocked|deferred|withdrawn>, recipe:<tiny|normal|complex>.
Milestone: the domain prefix. Rules: docs/plan/conventions/tasks.md.
Keep the decision card under about 120 words; detail belongs below it.
-->

## Decision card

Outcome: [Who can do what after this?]
Why now: [Immediate need]
Included: [Necessary behaviour]
Deferred: [Future ideas explicitly excluded]
Success: [One concrete demonstration]
Next: [One action or unresolved question]

Depends on: none

## Acceptance and consumer example

- [ ] [Representative successful input → expected result]
- [ ] [Relevant failure → expected handling]
- [ ] [Readable execution path and existing conventions]

[Small actual API/use example; use real identifiers after inspecting the project.]

## Implementation context

Entry point and relevant files/symbols:
Existing example to follow:
Main operations and responsibility boundaries:
Constraints and current callers:
Future extension note (not implementation scope):

## Environment and verification

Link: docs/plan/environment.md
Commands and expected results:
Required runtime/manual checks:
Unavailable checks and who can perform them:

## Delivery and authority

Required destination/artifact:
Build/output path:
Consumer integration or installation method:
Publication/deployment authorized by this task:
Reversal/recovery method where relevant:

## Stop conditions

Stop dependent work for unresolved acceptance semantics, missing required access/tooling, or a necessary
scope change. Routine implementation choices are autonomous. After two failed repairs of the same issue,
diagnose and replan before another attempt.

## Completion evidence / resume point

Source checks:
Build:
Runtime/consumer check:
Review findings and dispositions:
Delivered artifact/deployment:
Pull request:
Unverified work:
Next action:
