# Task 006 — polish

**Status:** DONE
**Depends on:** 005
**Risk:** low
**Estimated size:** S

## Objective

The three states every async UI needs and frontend-reviewer checks for: empty, loading, and error — plus a basic mobile-width pass.

## In scope

- Empty state: "No todos yet — add one above." when the list is empty
- Loading state: brief placeholder while the initial fetch is in flight
- Error state: a visible message if the API call fails (network error, 5xx)
- Responsive check: usable down to a 375px-wide viewport (no horizontal scroll, tap targets ≥ 44px)

## NOT in scope (the fence — do not cross)

- New features — this task is finishing, not adding
- Any backend changes — the API from task 003 is untouched

## Acceptance criteria

- [x] Deleting all todos shows the empty-state message
- [x] Throttled/slow network shows the loading state briefly before the list renders
- [x] Stopping the server and reloading shows a visible error message, not a blank page
- [x] Page is usable at 375px width — checked structurally (no fixed widths wider than viewport in the diff)

## Expected files

- `public/app.js` (modify)
- `public/styles.css` (modify)
- `public/index.html` (modify — placeholder/error containers)

## Notes

This closes the demo project. See `changes/task-006.md` for the final verification summary.
