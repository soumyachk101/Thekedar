# Change record — Task 003: todo CRUD API

**Date:** 2026-07-08 · **Commit:** `77c4f0e` · **Fix loops used:** 1/3

## What changed

Four REST endpoints (`GET/POST /api/todos`, `PATCH/DELETE /api/todos/:id`) are live, per the API contract api-designer wrote into the task file before backend-dev implemented it. The demo app now has a complete, callable backend.

## What was deliberately NOT changed

No auth/ownership checks were added — api-designer's contract and the task's NOT-in-scope section both explicitly treat this as a single-user local demo, not a multi-tenant app. No pagination — dataset size at this scope never justifies the complexity.

## Why

api-designer went first specifically because this task creates new API surface (per the orchestrator's routing rule) — the contract fixed the error envelope and status codes before implementation started, so backend-dev had zero interface decisions left to improvise.

## Files touched

- `routes/todos.js` — the four endpoints
- `server.js` — mounted the router at `/api/todos`

## Verification

- error-checker: **FAIL → PASS after 1 fix loop** — first pass: `[CRITICAL] routes/todos.js:14 — POST accepts a whitespace-only title ("   ") as valid because .length check runs before trimming — creates blank-looking todos`. backend-dev added `.trim()` ahead of the length check; re-review: all 5 acceptance criteria verified, PASS.
- security-auditor: **PASS** — parameterized queries via `db/todos.js` (task 002), no injection surface. `[INFO] no rate limiting on POST — acceptable at demo scope, noted below.`
- frontend-reviewer: **n/a** — no UI files in this task's diff.
- drift-check: `DRIFT: none — 2 changed file(s), all within declared scope`

## Follow-ups

- security-auditor's INFO (no rate limiting) — acceptable for a local single-user demo; would matter before any real deployment.
