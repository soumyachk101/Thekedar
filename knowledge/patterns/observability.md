# Pattern — Observability

> How to make a running system explain itself: logs, metrics, and traces that
> let you answer "what is it doing and why is it slow/broken" in production.

Cited by: `backend-dev`, `devops-engineer`. Related: `owasp/a09-logging-
monitoring-failures.md`, `patterns/error-handling.md`.

## Problem

When something breaks in production, you have only what you recorded. No
correlation, no metrics, no traces → you're guessing. Too much of the wrong
thing (secrets in logs, unbounded cardinality) is its own failure.

## The three pillars

- **Logs** — discrete events. **Structured** (JSON, key-value), not free text,
  so they're queryable. Include a correlation/request id, actor, and outcome.
  Log at the right level (error/warn/info/debug); don't log secrets/PII (A09).
- **Metrics** — aggregated numbers over time: request rate, error rate, latency
  (p50/p95/p99), saturation (the RED / USE methods). Cheap to store, great for
  alerting and dashboards. Beware high-cardinality labels (user id, raw path).
- **Traces** — the path of one request across services, with timing per span.
  Answers "where did the 800ms go." Propagate a trace/correlation id end to end.

## Approach

- Assign a **correlation id** per request at the edge; thread it through logs,
  responses, and downstream calls so one request is reconstructable.
- Emit the golden signals (rate, errors, duration, saturation) as metrics; alert
  on symptoms users feel (error rate, latency), not just causes (CPU).
- Instrument boundaries (inbound handler, DB, external calls) with spans.
- Make errors observable: every handled error increments an error metric and
  logs with context (see `patterns/error-handling.md`).

## SLOs and error budgets

Turn metrics into decisions. Define a Service Level Objective — a target on a
user-facing signal (e.g. "99.9% of requests succeed", "p95 latency < 300ms" over
a rolling window). The gap between the target and 100% is the **error budget**:
how much unreliability you can spend. Alert when the budget burns fast, not on
every blip. SLOs keep alerting tied to what users feel instead of raw resource
noise, and give an objective bar for "is this good enough to ship."

## When to use

Any service that runs unattended. Build in the correlation id + structured
logging + basic metrics from the start; retrofitting during an incident is too late.

## Pitfalls

- Free-text logs you can't query; or logging so much it's noise and cost.
- Secrets/PII/whole request bodies in logs (A09).
- High-cardinality metric labels (user id, unbounded path) exploding storage.
- Metrics/traces with no alerting — data nobody watches.
- No correlation id → logs from one request scattered and unlinkable.

## Verify

- One request is reconstructable end-to-end via a correlation id (check logs).
- Rate/error/latency metrics exist and drive at least one alert.
- No secret/PII in log output for a request carrying one.
