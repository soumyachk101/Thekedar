# Task 001 — project setup

**Status:** DONE <!-- TODO | ACTIVE | REVIEW | DONE | BLOCKED -->
**Depends on:** none
**Risk:** low
**Estimated size:** S

## Objective

A running Express server with a health endpoint — the "hello" that proves the scaffold works before any real feature is built.

## In scope

- `package.json` with Express as the only dependency
- `server.js`: Express app, listens on `process.env.PORT || 3000`
- `GET /health` → `200 {"status":"ok"}`
- `.gitignore` for `node_modules/`

## NOT in scope (the fence — do not cross)

- Database setup (task 002)
- Any `/api/*` routes (task 003)
- Frontend files (task 004)

## Acceptance criteria

- [x] `npm install && npm start` boots without error
- [x] `curl localhost:3000/health` returns `200 {"status":"ok"}`

## Expected files

- `package.json` (new)
- `server.js` (new)
- `.gitignore` (new)

## Notes

Plain Express, no framework scaffolding tool — the whole app is small enough that a generator would add more boilerplate than it saves.
