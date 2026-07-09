# Demo: todo app — real Thekedar output

This is not a template to fill in — it's the **actual `.thekedar/` output** from Thekedar building a small todo app, start to finish, over 6 tasks. Nothing here was written after the fact to look good; every task file, changelog, and the project state below is the shape the workflow really produces on a real (if small) feature build.

## What's here

```
.thekedar/
├── PROJECT_STATE.md      ← final state after all 6 tasks
├── tasks/
│   ├── 001-project-setup.md
│   ├── 002-db-schema.md
│   ├── 003-todo-crud-api.md   ← includes a real "## API contract" from api-designer
│   ├── 004-todo-list-ui.md
│   ├── 005-todo-item-interactions.md
│   └── 006-polish.md
└── changes/
    ├── ledger-sample.md       ← composited sample (see the note inside)
    └── task-001.md … task-006.md
```

The application code itself (`server.js`, `routes/`, `public/`, etc.) isn't included — this directory is about the **process record**, not a runnable app to clone. Reading it top to bottom tells you exactly what an agent did, why, and what it deliberately left alone, at every step.

## How to read it

1. Start with `.thekedar/PROJECT_STATE.md` — the 30-second overview: what this project is, what's done, what decisions got made and why.
2. Read `tasks/001-project-setup.md` through `006-polish.md` in order — notice the `NOT in scope` fence on each one, and how task 003 carries a real `## API contract` section (api-designer wrote that before backend-dev touched any code, because it's the one task that creates new API surface).
3. Read the matching `changes/task-NNN.md` for each — especially `task-003.md`, which shows a real fix loop: error-checker caught a bug (whitespace-only titles), backend-dev fixed exactly that, error-checker re-ran and passed. That loop is the mechanism working, not a scripted example.
4. `changes/ledger-sample.md` shows what the automatic per-edit ledger looks like — contrast its granularity (every single write, zero narrative) against the changelogs' granularity (one rich entry per task).

## The honest parts worth noticing

- **Task 002's fence** explicitly forbids touching `server.js` — the schema/data-layer task doesn't get to "helpfully" wire itself into the running app; that's task 003's job. This is what a NOT-in-scope section earning its keep looks like.
- **Task 003's changelog** doesn't hide the fix loop — it states the exact CRITICAL finding, the exact fix, and that it took one re-review to go green. A trustworthy record shows the messy middle, not just the clean end state.
- **Follow-ups aren't zeroed out by default** — `PROJECT_STATE.md`'s Known Issues section carries one real INFO-level finding (no rate limiting) forward instead of silently dropping it because it didn't block the task.

## Full mechanics

For the turn-by-turn version of how this actually happens — hook calls, guard checks, review gates — see [docs/WORKFLOW.md](../../docs/WORKFLOW.md), which walks through a comparable feature (password reset) with every hook invocation shown explicitly.
