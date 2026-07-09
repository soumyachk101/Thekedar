# Task 004 — todo list UI

**Status:** DONE
**Depends on:** 003
**Risk:** low
**Estimated size:** M

## Objective

A static page that lists todos from the API and lets you add new ones — read + create only, no interactions yet.

## In scope

- `public/index.html` — page shell, a list container, an add-todo form
- `public/app.js` — `fetch('/api/todos')` on load, render the list; form submit → `POST /api/todos`, re-render
- `public/styles.css` — minimal readable styling, no framework
- Serving `public/` as static files from `server.js`

## NOT in scope (the fence — do not cross)

- Toggle-complete / delete interactions (task 005)
- Loading/empty/error states beyond the bare minimum (task 006 — polish)
- Any build tooling (bundler, framework) — plain HTML/CSS/JS is the whole frontend stack here

## Acceptance criteria

- [x] Loading the page shows existing todos from the API
- [x] Submitting the add-form creates a todo via `POST /api/todos` and it appears in the list without a full page reload
- [x] `npm start` serves `public/index.html` at `/`

## Expected files

- `public/index.html` (new)
- `public/app.js` (new)
- `public/styles.css` (new)
- `server.js` (modify — `express.static('public')`)

## Notes

frontend-dev checked for an existing design system first per its standard process — none exists yet in this brand-new project, so plain semantic HTML + a small stylesheet is the right call, not a gap.
