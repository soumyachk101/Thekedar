# Task 005 — todo item interactions

**Status:** DONE
**Depends on:** 004
**Risk:** low
**Estimated size:** S

## Objective

Each todo in the list gets a checkbox (toggle complete) and a delete button, both wired to the API from task 003.

## In scope

- Checkbox per todo → `PATCH /api/todos/:id` with `{ completed }`, re-render on response
- Delete button per todo → `DELETE /api/todos/:id`, remove from the list on success
- Completed todos get a visual state (strikethrough) via a CSS class toggle

## NOT in scope (the fence — do not cross)

- Editing a todo's title inline — not requested, out of scope for this demo
- Bulk actions (complete-all, delete-all)
- `public/index.html` structural changes beyond adding the checkbox/button elements per list item

## Acceptance criteria

- [x] Clicking the checkbox marks the todo complete (persists on reload)
- [x] Clicking delete removes the todo (persists on reload)
- [x] Completed todos render with strikethrough styling

## Expected files

- `public/app.js` (modify)
- `public/styles.css` (modify — `.completed` class)

## Notes

None.
