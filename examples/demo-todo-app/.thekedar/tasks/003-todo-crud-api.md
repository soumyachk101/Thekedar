# Task 003 — todo CRUD API

**Status:** DONE
**Depends on:** 002
**Risk:** medium
**Estimated size:** M

## Objective

REST endpoints for listing, creating, completing, and deleting todos, wired into the running server from task 001 on top of the data layer from task 002.

## In scope

- `GET /api/todos` — list all
- `POST /api/todos` — create
- `PATCH /api/todos/:id` — update (title and/or completed)
- `DELETE /api/todos/:id` — remove
- Wiring these into `server.js`

## NOT in scope (the fence — do not cross)

- Any frontend/UI code (tasks 004–005)
- Auth/ownership checks — this is a single-user local demo, not a multi-tenant app
- Pagination — the dataset is small enough that listing everything is fine at this scope

## API contract

<!-- written by api-designer before backend-dev implemented this task -->

**GET /api/todos**
→ 200 `[{ "id": 1, "title": "Buy milk", "completed": false, "createdAt": "2026-07-08T09:00:00.000Z" }, ...]`

**POST /api/todos**
Body: `{ "title": string }` (required, 1–200 chars)
→ 201 with the created todo · 422 `{ "error": "title is required" }` if missing/empty/too long

**PATCH /api/todos/:id**
Body: `{ "title"?: string, "completed"?: boolean }` (at least one field)
→ 200 with the updated todo · 404 `{ "error": "todo not found" }` · 422 if body has neither field

**DELETE /api/todos/:id**
→ 204 no body · 404 `{ "error": "todo not found" }`

No ⚠ BREAKING changes — this is new surface, nothing pre-existing to break.

## Acceptance criteria

- [x] `GET /api/todos` returns `200 []` on an empty table
- [x] `POST /api/todos` with a valid title returns `201` and the row is queryable afterward
- [x] `POST /api/todos` with an empty title returns `422`
- [x] `PATCH /api/todos/:id` on a real id toggles `completed`; on a missing id returns `404`
- [x] `DELETE /api/todos/:id` returns `204`, and a repeat delete returns `404`

## Expected files

- `routes/todos.js` (new)
- `server.js` (modify — mount the router)

## Notes

Fix loop 1/3 used: the first error-checker pass caught that `POST` accepted a whitespace-only title as valid (`"   "` passed the length check but produced a blank-looking todo). backend-dev added a `.trim()` before the length check; re-review passed clean.
