# T025 — integration test for the inbound transport

Status: verified 2026-09-30
Depends on: none
Recipe: normal
Coordinator: Sol Medium
Worker: Terra Medium
Reviewer: Sol Medium

## Decision card

Outcome: a test sends a sidecar packet to the connector's HTTP service over real HTTP and asserts the
response, covering body parsing, context building, handler dispatch and the error mapping.

Why now: the inbound boundary is what the sidecar actually talks to, and the only place the error mapping
can be observed. `mol_Transport` exports only `ExecuteRequest` and `Transporter_HTTP_Receive`, and
`New HTTPServiceRequest()` fails with `Конструктор не найден` because the platform only builds that class
behind a web publication — so the path is reachable only as integration testing, never from a unit test.

Success: `tests/bsl/http/test-inbound-transport.sh` runs in both modes and reports 12 passed, 0 failed.

## The route, discovered while doing this

The stand-alone server serves the service natively, so no Apache is needed.

```bash
/opt/1cv8/current/ibsrv --config=/workspace/build/ibsrv/publication.yaml --data=/workspace/build/ibsrv
curl -s -o /tmp/resp.txt -w '%{http_code}' -X POST \
  -H 'Content-Type: application/json' --data-binary @packet.json \
  http://localhost:8314/ib/hs/moleculer/sidecar
```

The publication already exists in `build/ibsrv/publication.yaml`: `build/ib` on `localhost:8314`, base
`/ib`, HTTP services published by default. The service is `mol_Moleculer`, root URL `moleculer`, template
`/sidecar`, POST.

Blocker that was solved: the request reached the service and the server answered 503 with
`Недопустимое значение аргумента функции / sessionId != kUUIDNull`
(`ibsrv - src/ib-server-worker/src/serverImpl.cpp(262)`) — the stand-alone server failing to establish a
session, not the connector. Note in passing: that server holds a lock on `build/ib`, so it must be stopped
before any harness run that recreates that base.

## Acceptance and consumer example

- [x] A complete packet POSTed to the published service runs the handler and returns its result
      (`$internal.ping` answers `pong`).
- [x] A payload addressed to an unregistered action is answered with the connector's error envelope
      rather than a platform page.
- [x] A malformed or empty body is recorded as a known gap rather than passing silently.

## Completion evidence / resume point

`tests/bsl/http/test-inbound-transport.sh` — **12 passed, 0 failed**, in both modes. Two gaps are recorded
rather than hidden: a malformed or empty body answers 500 with `text/plain` instead of the JSON envelope.

This route is what T032 and T036 lean on, and it is the only place where the two modes can be asserted
separately.
