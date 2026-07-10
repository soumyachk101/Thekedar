# Pattern — Idempotency

> How to make an operation safe to retry, so a network timeout or a double-click
> doesn't create duplicate charges, orders, or records.

Cited by: `backend-dev`, `api-designer`. Related: `patterns/api-design.md`,
`patterns/webhooks.md`.

## Problem

Networks fail after the server acted but before the client got the response. The
client retries. Without idempotency, the retry runs the operation again —
double charge, duplicate order, two emails. GET/PUT/DELETE are naturally
idempotent; POST (create) and side-effecting actions are not.

## Approach — the idempotency key

- The client generates a unique key per logical operation (UUID) and sends it,
  e.g. `Idempotency-Key: <uuid>`.
- The server, on first receipt, records the key with the result (in a store with
  a TTL). On a retry with the same key, it returns the stored result **without
  re-executing**.
- Scope the key to the operation + account so keys can't collide or be replayed
  across users.
- Handle the race: two concurrent requests with the same key — use a unique
  constraint / atomic insert so exactly one executes; the other waits or returns
  the first's result.

## Alternatives / complements

- **Natural idempotency**: design so repeating is harmless — upserts
  (`ON CONFLICT`), set-don't-increment, PUT-to-a-known-id.
- **Dedup on a business key**: reject a second order with the same client order id.
- Make DELETE/PUT return the same result whether or not the row already changed.

## Key lifetime and result storage

Store enough to make the retry correct: the key, a fingerprint of the request
(to detect a key reused with a *different* body — return a 422, don't silently
serve the old result), and the response to replay. Set a TTL that covers the
realistic retry window (minutes to a day), then let keys expire — an idempotency
store is a cache, not a ledger. For long-lived guarantees (no duplicate order
ever), enforce a unique business key in the database instead, and let the
idempotency key handle the short-term retry.

## When to use

Any state-changing operation a client might retry, especially money movement,
resource creation, and outbound side effects (emails, external API calls). Webhook
*consumers* need it too (providers retry — see `patterns/webhooks.md`).

## Pitfalls

- Storing the key but re-executing anyway (the check must gate execution).
- No TTL/cleanup → unbounded key store growth.
- Ignoring the concurrent-duplicate race → both execute.
- Retrying a non-idempotent downstream call inside your handler (see
  `patterns/error-handling.md`).

## Verify

- The same request sent twice (same key) produces one effect and one stored
  result (test).
- Concurrent duplicates result in exactly one execution.
- Keys expire; the store doesn't grow unbounded.
