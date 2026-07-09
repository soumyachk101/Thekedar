---
name: thekedar-plan
description: >
  Use when the user invokes /thekedar-plan or asks to "just plan, don't build yet" —
  produce or refresh the task breakdown for cheap human review WITHOUT starting any
  implementation. The review-the-naksha-before-pouring-concrete command.
---

# /thekedar-plan — naksha only, no concrete

## Steps

1. If `.thekedar/` is missing, create `tasks/`, `changes/`, and `PROJECT_STATE.md` from `templates/PROJECT_STATE.md`.
2. Invoke the **planner** subagent with the user's request (plus current PROJECT_STATE for re-plans — planner renumbers nothing that's DONE).
3. Present to the user:
   - one line per task: `NNN — slug — one-phrase objective (size, risk)`
   - phase overview if the planner phased it
   - **BLOCKING questions** first, then **Assumptions** — verbatim from the planner
4. **STOP.** Full stop.

## The stop is the feature

- Do NOT set any task ACTIVE, do NOT invoke doers, do NOT commit, do NOT "just start the easy one".
- Close with exactly: `Plan ready. Say "continue" to start task NNN under the thekedar workflow.`
- User answers a BLOCKING question → re-invoke planner to update the affected task files, re-present, STOP again.
- User edits task files by hand → that's allowed and encouraged; the thekedar skill picks up whatever is on disk when it starts.
