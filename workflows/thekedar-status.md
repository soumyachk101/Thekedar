# Thekedar Status

Return a concise project status snapshot.

When invoked:

1. Read `.thekedar/PROJECT_STATE.md`.
2. Check the active or next task in `.thekedar/tasks/`.
3. Check the most recent `.thekedar/changes/task-*.md`.
4. Return phase, active task, last edits, latest commit, next task, and blockers.
5. Do not edit files.
