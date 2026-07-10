# Pitfalls — REST / HTTP APIs

> Traps in HTTP API design and implementation: wrong status codes, inconsistent
> shapes, missing idempotency, and breaking changes slipped in silently.

Cited by: `api-designer`, `backend-dev`, `error-checker`. Related:
`security/authz-checklist.md`, `owasp/a01-broken-access-control.md`.

## Status codes (return the right one)

- **201** for a created resource (not 200); **204** for a successful delete with
  no body; **202** for accepted-but-async.
- **400** malformed request vs **422** semantically-invalid (validation) vs
  **401** unauthenticated vs **403** authenticated-but-forbidden vs **404** not
  found. Don't return 200 with an `{"error": ...}` body for a failure.
- **409** for a conflict (duplicate, version mismatch); **429** for rate limited.
- **500** only for unexpected server faults — never for a client's bad input.

## Response-shape consistency

- One error envelope across the whole API — don't invent a second shape per
  endpoint. Mirror the existing one.
- Don't leak internals (stack traces, SQL, internal ids) in error bodies (A09).
- Consistent casing (camelCase or snake_case — match the project), consistent
  date format (ISO-8601 UTC), consistent pagination shape.

## Idempotency & safety

- GET/HEAD must be safe (no side effects) and cacheable — don't mutate on a GET.
- PUT/DELETE should be idempotent (repeating them has the same effect).
- Money moves / resource creation from a client retry need an idempotency key,
  or a retry creates duplicates.

## Validation & input

- Validate at the boundary: types, required fields, lengths, ranges, enum
  membership. Don't trust the client shape (see general-ai-coding: `any` from
  `req.body`).
- Bound sizes: max body size, max array length, max page size — unbounded input
  is a DoS and a perf trap.
- Negative/zero/huge numbers where a positive is assumed (quantity, price).

## Auth & access (the big one)

- Every non-public endpoint checks authn AND authz; object access is scoped by
  owner/tenant (IDOR — see authz-checklist).
- Don't rely on the client/UI to enforce permissions.

## Breaking changes (flag loudly)

- Changing a response field's type/name, removing a field, tightening
  validation, or changing a status code **breaks existing clients**. Version the
  API or add, don't change. api-designer must mark these `⚠ BREAKING`.

## CORS & headers

- CORS `*` with credentials is invalid/insecure; use an explicit origin
  allowlist (A05). Set security headers. Content-Type matches the body.

## Verify

- Each endpoint returns the correct status for success, not-found, unauthorized,
  forbidden, and validation-failure — with a test per case.
- One error envelope; no internal detail leaked; consistent casing/dates.
- Mutating endpoints are authz-checked and (where money/creation) idempotent.
- Any shape/status change to an existing endpoint is flagged as breaking.
