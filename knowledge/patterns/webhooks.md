# Pattern — Webhooks

> How to send and receive webhooks reliably and securely: signed, verified,
> idempotent, retried, and not a SSRF or DoS vector.

Cited by: `backend-dev`, `api-designer`. Related: `patterns/idempotency.md`,
`owasp/a10-ssrf.md`, `owasp/a08-integrity-failures.md`.

## Problem

Webhooks are HTTP callbacks between systems you don't fully control. Both ends
are hard: the sender must deliver reliably to a possibly-down receiver; the
receiver must verify authenticity, avoid double-processing, and not be tricked
into attacking itself.

## Receiving webhooks (you expose an endpoint)

- **Verify the signature**: providers sign the payload (HMAC with a shared
  secret) — compute and compare (constant-time) before trusting anything. An
  unsigned/unverified webhook is attacker-controlled input (see A08).
- **Idempotency**: providers retry, so the same event arrives more than once.
  Dedupe on the provider's event id; process each event once (see
  `patterns/idempotency.md`).
- **Respond fast, process async**: acknowledge with `2xx` quickly, then do the
  real work in a background job (see `patterns/background-jobs.md`). Slow
  processing inline causes provider timeouts and retries.
- **Validate + bound**: check the payload shape; cap body size; don't trust
  fields (amounts, ids) without re-fetching from the provider's API when it matters.

## Sending webhooks (you call others' endpoints)

- **Sign every payload** (HMAC over the body + a timestamp) so receivers can
  verify; include an event id for their idempotency.
- **Retry with backoff** on failure (their endpoint is down), up to a cap, then
  dead-letter. Make delivery a background job.
- **SSRF guard**: the destination URL is user-configured — an attacker sets it to
  `http://169.254.169.254/...` or an internal host. Validate/allowlist the
  destination and block internal ranges (see `owasp/a10-ssrf.md`).
- Include a timestamp and reject-old-timestamp guidance to prevent replay.

## When to use

Event notifications between services/tenants (payment events, CI results, CRM
updates) where polling is wasteful. Prefer webhooks + a reconciliation poll as
backup (webhooks can be missed).

## Pitfalls

- Trusting an unverified webhook body (forgery — A08).
- Processing the same event twice (no idempotency on event id).
- Slow inline processing → provider timeout → retry storm.
- Sender with no SSRF protection on the target URL.
- No retry/DLQ → a transient receiver outage loses events.

## Verify

- Inbound: signature verified (constant-time) before processing; unsigned rejected.
- Inbound: duplicate event id processed once (test).
- Outbound: payloads signed; delivery retries with backoff + DLQ; target URL
  SSRF-checked.
