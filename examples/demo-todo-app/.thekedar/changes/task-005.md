# Change record — Task 005: todo item interactions

**Date:** 2026-07-09 · **Commit:** `9e2f71b` · **Fix loops used:** 0/3

## What changed

Every todo in the list now has a working checkbox (toggles complete via `PATCH`) and a delete button (`DELETE`), with completed items visually struck through.

## What was deliberately NOT changed

Inline title editing was NOT added — never requested, and the task's NOT-in-scope section named it explicitly so frontend-dev wouldn't improvise it "while in there." No bulk actions.

## Why

Both interactions were small enough and tightly-enough coupled (both operate per-list-item, both re-render the same way) to ship as one task rather than split further — kept under the ~150-line planner guideline comfortably.

## Files touched

- `public/app.js` — checkbox/delete handlers
- `public/styles.css` — `.completed` strikethrough class

## Verification

- error-checker: **PASS** — toggle and delete both verified to persist across a page reload, per acceptance criteria.
- security-auditor: **PASS** — no new input surface (checkbox/button, not free text); existing parameterized API calls reused.
- frontend-reviewer: **PASS** — checkbox is a real `<input type="checkbox">` (keyboard-operable natively), delete button has an accessible name (not icon-only with no label). No CRITICAL or WARNING findings.
- drift-check: `DRIFT: none — 2 changed file(s), all within declared scope`

## Follow-ups

None.
