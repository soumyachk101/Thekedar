# Review checklist — error handling

> What to check when reviewing how a change handles failure. Complements the
> `patterns/error-handling.md` design guide; this is the review lens.

Cited by: `error-checker`. Related: `patterns/error-handling.md`,
`owasp/a09-logging-monitoring-failures.md`.

## Are errors caught at all?

- [ ] Every I/O / dependency / parse call that can fail is handled or propagated
      to a boundary that handles it — no path where a throw escapes unhandled.
- [ ] No **swallowed** errors: `catch {}`, `except: pass`, `.catch(() => {})`
      without a comment justifying the intentional ignore.
- [ ] Async: every `await` / promise in a request path is caught or handled by a
      boundary. Unhandled rejections are latent crashes (see `pitfalls/nodejs.md`).
- [ ] `forEach(async ...)` / unawaited async in a loop (errors lost) — flagged.

## Right error, right place

- [ ] Expected/operational errors (bad input, not found, conflict) map to the
      correct 4xx status; unexpected/programmer errors to 5xx (see
      `pitfalls/api-http.md`). No 200-with-error-body.
- [ ] Errors carry context as they propagate (wrapped, not replaced) — the final
      log reads like a trail.
- [ ] Not logged-and-rethrown at every level (log spam) — logged once at the
      boundary with full context.

## Safe surfacing

- [ ] User-facing error messages are generic; no stack trace, SQL, internal id,
      or secret leaked to the client (see A09).
- [ ] Full detail is logged server-side with a correlation id.

## Resource safety on error

- [ ] Files/connections/locks are released on the error path (defer/finally/
      context manager), not just the happy path.
- [ ] Partial writes / multi-step operations don't leave inconsistent state — is
      the operation atomic, or is there compensation?

## Retries

- [ ] Retries only on **idempotent** operations, with backoff + jitter and a cap
      (see `patterns/idempotency.md`) — not blind retry of a POST that charges.

## Edge cases (the usual misses)

- [ ] Empty / null / missing input; empty collection; boundary values.
- [ ] Timeout on external calls (a hung dependency shouldn't hang forever).
- [ ] Concurrent access / race on shared state.

## Observability of failures

- [ ] Handled errors are **visible**, not just recovered silently — they
      increment an error metric and/or log with context so a rise in failures is
      detectable (see `patterns/observability.md`). An error that's caught and
      swallowed with no trace is invisible until a user complains.
- [ ] The error is logged once, at the boundary, with the correlation id — not at
      every layer, and not lost.

## Verify

- A forced failure returns the right status + generic body and logs full detail.
- No swallowed errors in the diff; async paths handle rejection; resources freed.
