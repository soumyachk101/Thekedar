# Pattern — API design

> Reusable conventions for designing a REST/HTTP API surface that stays
> consistent and doesn't break clients. The reference api-designer writes a
> contract against.

Cited by: `api-designer`, `backend-dev`. Related: `pitfalls/api-http.md`,
`patterns/pagination.md`, `patterns/idempotency.md`.

## Problem

Every endpoint invented ad hoc drifts: mismatched casing, three error shapes,
inconsistent status codes, breaking changes shipped silently. Clients pay for it.

## Approach

- **Resources, not verbs**: `POST /orders`, `GET /orders/{id}`, not
  `POST /createOrder`. Use HTTP methods for the verb (GET/POST/PUT/PATCH/DELETE).
- **One error envelope** for the whole API. A common shape:
  `{ "error": { "code": "invalid_email", "message": "...", "details": [...] } }`.
  Never a second shape per endpoint; never a 200 with an error body.
- **Status codes carry meaning**: 200/201/204 success; 400/422 client input;
  401/403 auth; 404 missing; 409 conflict; 429 rate limited; 5xx server faults
  only (see `pitfalls/api-http.md`).
- **Consistent naming**: pick camelCase or snake_case for payloads and hold it.
  ISO-8601 UTC for timestamps. Plural collection nouns.
- **Explicit versioning**: `/v1/...` or a header. Add fields, don't change or
  remove them; a shape/type/status change to an existing endpoint is BREAKING.
- **Pagination, filtering, sorting** as query params with a documented default
  and cap (see `patterns/pagination.md`).

## Contract per endpoint (what api-designer writes into the task)

method + path · request (params/query/body schema, types, required) · success
response (shape + status) · every error case (status + envelope) · authN/authZ
(who may call, what ownership check).

## Bulk and partial responses

- **Bulk**: for operations over many items, offer a batch endpoint
  (`POST /orders/batch`) rather than forcing N round-trips — but define partial-
  failure semantics (all-or-nothing vs per-item status array). Ambiguous bulk
  error handling is worse than none.
- **Field selection**: for heavy resources, allow the client to request a subset
  (`?fields=id,name`) or provide a summary vs detail representation, so lists
  don't ship every column of every row.

## When to use

Any task that creates or changes an API surface — api-designer runs before the
doer, so the doer implements a spec, not a vibe.

## Pitfalls

- Leaking internal representation (DB column names, internal ids) into the API.
- Chatty designs forcing N calls where one resource would do; or god-endpoints
  returning everything.
- Unbounded list responses (no pagination) — a perf and DoS trap.
- Breaking changes shipped without a version bump or a `⚠ BREAKING` flag.
- Auth checked in the UI but not the API.

## Verify

- Error envelope identical across endpoints; casing/date format consistent.
- Each endpoint documents success + every error status; authz stated.
- Changes to existing endpoints are additive or versioned; breaks flagged.
