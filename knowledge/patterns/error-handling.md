# Pattern — Error handling

> How to handle, propagate, and surface errors so failures are visible,
> debuggable, and safe — without leaking internals to users.

Cited by: `backend-dev`, `error-checker`. Related: `owasp/a09-logging-
monitoring-failures.md`, `pitfalls/api-http.md`.

## Problem

Swallowed errors hide failures; leaked errors expose internals; inconsistent
handling makes every failure a fresh investigation. Async makes it worse — an
unhandled rejection can crash the process or send a half-finished response.

## Approach

- **Fail loud internally, generic externally**: log the full error with context
  server-side; return a generic, stable message + code to the client. Never
  return a stack trace, SQL, or internal id to a user (A09).
- **Distinguish error classes**: expected/operational (bad input, not found,
  conflict → 4xx) vs unexpected/programmer (bug, null deref → 5xx). Map each to
  the right status (see `pitfalls/api-http.md`).
- **Add context as it propagates**: wrap, don't replace — Go `fmt.Errorf("...: %w", err)`,
  JS `new Error("...", { cause })`, Python `raise X from err`. The final log
  should read like a trail, not a mystery.
- **Centralize**: one error-handling middleware / boundary that maps error types
  to responses and logs — not try/catch scattered with divergent behavior.
- **Never swallow**: `catch {}` / `except: pass` hides real failures. If you
  truly intend to ignore, comment why.

## Async specifics

- Every `await`/promise in a request path is caught or handled by a boundary.
  An unhandled rejection is a latent crash/leak.
- `Promise.all` fails fast; use `allSettled` when partial success is valid.
- Set timeouts on I/O; a hung dependency shouldn't hang the request forever.

## Retries and circuit breakers (for transient failures)

Not every error should propagate immediately. A transient downstream failure
(timeout, 503) is often worth a bounded retry — but only for **idempotent**
operations (see `patterns/idempotency.md`), with **exponential backoff + jitter**
so retries don't synchronize into a storm. Cap the attempts. When a dependency is
hard-down, a **circuit breaker** stops calling it for a cooldown (failing fast)
instead of piling up timeouts and exhausting your own threads/connections. The
default for a non-idempotent or business-logic error is still: don't retry,
surface it.

## When to use

Every task that does I/O, calls a dependency, or handles a request. Establish
the boundary once; reuse it.

## Pitfalls

- Returning 200 for a failure (breaks clients that trust the status).
- Catching an error only to re-throw a vaguer one (loses the cause).
- Logging the error AND re-throwing at every level (log spam) — log once, at the
  boundary, with full context.
- Retrying non-idempotent operations on error (see `patterns/idempotency.md`).

## Verify

- A forced failure returns the correct status + generic body, and logs full
  detail server-side (test).
- No swallowed errors in the diff; async paths handle rejection.
- Error messages to users leak no internals.
