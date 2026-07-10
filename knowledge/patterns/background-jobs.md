# Pattern — Background jobs

> How to move slow or unreliable work out of the request path into an
> asynchronous worker, correctly — with retries, idempotency, and visibility.

Cited by: `backend-dev`, `devops-engineer`. Related: `patterns/idempotency.md`,
`patterns/observability.md`, `patterns/error-handling.md`.

## Problem

Sending email, generating a report, calling a slow third party, or processing an
upload inside the HTTP request makes the user wait and couples the response to a
flaky dependency. Move it to a queue + worker — but async introduces its own
failure modes: lost jobs, duplicate execution, silent failures.

## Approach

- **Enqueue, don't block**: the request writes a job (to a queue/table) and
  returns quickly (often `202 Accepted` with a status URL). A worker processes it.
- **Idempotent handlers**: a job WILL run more than once (retries, at-least-once
  delivery). Design the handler so re-running is safe (see `patterns/idempotency.md`)
  — check "already done?" before acting.
- **Retries with backoff**: transient failures retry with exponential backoff +
  jitter, up to a cap. Permanent failures go to a **dead-letter queue** for
  inspection, not infinite retry.
- **Visibility**: jobs have status (queued/running/succeeded/failed), are logged
  with a correlation id, and emit metrics (queue depth, processing time, failure
  rate). A silent job queue is where work goes to die (see `observability.md`).
- **Bounded concurrency + priority**: cap workers so jobs don't overwhelm the DB;
  separate queues/priorities so a flood of low-priority jobs doesn't starve urgent ones.

## Delivery semantics

Most queues are **at-least-once** (a job may be delivered twice) — hence the
idempotency requirement. Exactly-once is largely a myth at the delivery layer;
achieve effectively-once by making handlers idempotent. Don't assume a job runs
once.

## Scheduled and delayed jobs

Two flavors beyond fire-now: **delayed** ("send this reminder in 24h") and
**recurring/cron** ("nightly cleanup"). For cron-style work in a multi-instance
deployment, ensure exactly one instance runs each tick — a naive `cron` on every
box runs the job N times; use a leader-election lock or a scheduler that
guarantees single execution. Delayed jobs need a durable store with a due-time,
not an in-process `setTimeout` (lost on restart). Both still need the idempotency
and monitoring above.

## When to use

Anything slow (>~100ms), unreliable (external calls), bursty, or that can be
deferred: email/notifications, report/export generation, image/file processing,
webhook delivery, data sync, scheduled tasks.

## Pitfalls

- Non-idempotent handler + at-least-once delivery → duplicate side effects.
- No dead-letter queue → a poison job retries forever, clogging the queue.
- Losing jobs on crash (enqueue not durable, or ack-before-work).
- No monitoring → failures invisible until a user complains.
- Doing the work in the request "just this once" because the queue felt heavy.

## Verify

- Handler is idempotent (re-running produces one effect) — test.
- Failed jobs retry with backoff and land in a DLQ after N attempts.
- Queue depth, failures, and processing time are monitored/alerted.
- Enqueue is durable; a crash mid-job doesn't lose or double it.
