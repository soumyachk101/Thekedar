# Change record — Task 004: todo list UI

**Date:** 2026-07-09 · **Commit:** `1d5b8a3` · **Fix loops used:** 0/3

## What changed

A page exists at `/` that loads and displays existing todos, and a form that creates new ones — the first visible, usable slice of the app.

## What was deliberately NOT changed

Toggle-complete and delete are NOT wired yet (task 005 — the checkbox/button markup this task adds is inert until then). No loading/empty/error state handling yet beyond the bare list render — that's task 006's explicit job, not squeezed in early.

## Why

Read + create first, as its own reviewable slice, before layering update/delete interactions on task 005 — a smaller diff for frontend-reviewer to check against the design/a11y checklist each time.

## Files touched

- `public/index.html` — page shell, list container, add-form
- `public/app.js` — initial fetch + render, form submit handler
- `public/styles.css` — base layout and type
- `server.js` — serves `public/` statically

## Verification

- error-checker: **PASS** — manual load + submit flow confirmed against both acceptance criteria; no test framework configured yet for this demo (noted, not blocking at this scope).
- security-auditor: **PASS** — todo titles rendered via safe DOM text APIs, not `innerHTML` with raw user content — no XSS surface introduced.
- frontend-reviewer: **PASS** — form has a proper `<label>`, add-button is a real `<button>`, list uses a semantic `<ul>`. `[INFO] the add-input doesn't auto-focus on load — nice-to-have, not blocking.`
- drift-check: `DRIFT: none — 4 changed file(s), all within declared scope`

## Follow-ups

- frontend-reviewer's auto-focus INFO — deferred, cosmetic.
