# Best practices — Express

> Building Express APIs that don't fall over: middleware order that makes sense,
> real async error handling, security hardening. Distinct from `pitfalls/nodejs.md`.

Cited by: `express-specialist`. Related: `pitfalls/nodejs.md`,
`patterns/api-design.md`, `security/owasp/a03-injection.md`.

## Structure & middleware

- **Layered**: routes → controllers → services → data access. Keep route files
  thin (wiring only); business logic in services; no SQL in the route.
- Middleware order matters: security headers and body parsing first, then
  auth, then routes, then the 404 handler, then the **error handler last**.
- Use `express.Router()` per resource; mount with a base path.
- Config + secrets from env (`dotenv` in dev only); never commit secrets
  (`security/secrets-patterns.md`).

## Async error handling (the classic footgun)

- **Express 4 does not catch async errors** — an unhandled rejection in an
  `async` handler hangs the request. Wrap handlers in an async-error adapter
  (`express-async-errors`, or a `wrap(fn)` that `.catch(next)`), or use Express 5
  which awaits handlers.
- **One centralized error-handling middleware** (`(err, req, res, next)`): map
  errors to status + a consistent JSON shape; log with context; never leak stack
  traces / internals to the client (`patterns/error-handling.md`).
- Distinguish operational errors (return 4xx) from programmer errors (500, alert).

## Validation & security

- **Validate every input** (body, params, query, headers) with `zod`/`joi`/
  `express-validator` before it reaches logic. Reject with 400 + details.
- Parameterize all DB queries — never string-concatenate user input
  (`security/owasp/a03-injection.md`).
- `helmet` for security headers, `cors` configured to specific origins (not `*`
  with credentials), rate-limiting on auth/expensive routes
  (`patterns/rate-limiting.md`), body-size limits.
- Auth middleware that sets `req.user`; an authorization layer that checks the
  resource belongs to that user (IDOR; `security/authz-checklist.md`).
- Don't trust `req.body` shape — allow-list fields to prevent mass assignment.

## Performance & reliability

- Never block the event loop: async I/O everywhere; offload CPU-bound work to a
  worker thread / queue (`patterns/background-jobs.md`).
- Reuse DB connection pools; set timeouts on outbound calls; graceful shutdown on
  SIGTERM (drain connections).
- Compression + caching headers where appropriate (`patterns/caching-strategies.md`).

## API design

- REST conventions, correct status codes, pagination on lists, versioned routes,
  consistent error envelope (`patterns/api-design.md`).
- Idempotency keys for retriable unsafe operations (`patterns/idempotency.md`).

## Logging

- Structured logger (`pino`/`winston`) with a request/correlation id; never log
  secrets, tokens, or full request bodies with credentials
  (`review-checklists/logging.md`).

## Testing

- `supertest` against the app instance; test the validation-failure and
  auth-failure paths and the error-handler shape, not only 200s.
