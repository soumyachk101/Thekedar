# Change record — Task 002: db schema

**Date:** 2026-07-08 · **Commit:** `a92e6d1` · **Fix loops used:** 0/3

## What changed

A `todos` table exists (SQLite, via `better-sqlite3`) with a small data-access module (`list`/`create`/`update`/`remove`) that later tasks will call. No HTTP surface yet.

## What was deliberately NOT changed

`server.js` was NOT touched — db-specialist confirmed this task's fence explicitly excludes wiring the database into the running app; that's task 003's job, once the API contract exists to call it correctly.

## Why

Separating schema+data-access from the HTTP layer keeps task 003's diff small and reviewable — it only has to wire routes to already-tested functions, not debug schema and HTTP at once.

## Files touched

- `db/schema.sql` — `todos` table definition
- `db/todos.js` — CRUD functions
- `package.json` — added `better-sqlite3`

## Verification

- error-checker: **PASS** — manual insert/read round-trip confirmed via the acceptance-criteria command; schema applies clean on a fresh file.
- security-auditor: **PASS** — parameterized statements throughout (`better-sqlite3`'s prepared-statement API), no string-built SQL. `deps added: better-sqlite3` — no CRITICAL, native module with no known advisories at review time.
- frontend-reviewer: **n/a**.
- drift-check: `DRIFT: none — 3 changed file(s), all within declared scope`

## Follow-ups

None.
