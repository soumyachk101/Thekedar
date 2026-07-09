# Task 002 — db schema

**Status:** DONE
**Depends on:** 001
**Risk:** low
**Estimated size:** S

## Objective

A `todos` table and a tiny data-access module that task 003's API will call — no HTTP yet.

## In scope

- SQLite (via `better-sqlite3`) file at `db/todos.sqlite`, created on first run
- `db/schema.sql`: `todos(id INTEGER PRIMARY KEY, title TEXT NOT NULL, completed INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL)`
- `db/todos.js`: `list()`, `create(title)`, `update(id, fields)`, `remove(id)` — plain functions, no ORM

## NOT in scope (the fence — do not cross)

- HTTP routes (task 003 — this task has no `/api` surface at all)
- `server.js` — do NOT wire this into the running app yet, that's 003's job

## Acceptance criteria

- [x] `node -e "require('./db/todos').create('test')"` inserts a row without error
- [x] Schema applies cleanly on a fresh `db/todos.sqlite` (delete file, re-run, table exists)

## Expected files

- `db/schema.sql` (new)
- `db/todos.js` (new)
- `package.json` (modify — add `better-sqlite3`)

## Notes

`better-sqlite3` chosen over an async driver: this is a single-writer demo app, and synchronous calls keep `db/todos.js` free of promise plumbing for a table this small.
