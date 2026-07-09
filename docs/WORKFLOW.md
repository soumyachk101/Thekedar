# Workflow — one real task, turn by turn

An annotated walkthrough of a single task moving through the full v2 state machine. Fictional feature ("add password reset"), realistic mechanics — every hook call, every file write, every gate verdict shown is what actually happens on disk.

## Setup

```
you: build password reset — request a link by email, token expires in 1 hour, set new password
```

The request is multi-step (new endpoint, email send, token storage, UI form) → the `thekedar` skill activates instead of you getting immediate code.

## 1. PLANNING

Orchestrator invokes **planner** (fresh context: it never saw your conversation, only the request text + whatever it reads from disk).

Planner greps the codebase: finds Express + Prisma + React, an existing `users` table, an existing mailer util in `src/lib/mail.ts`. It writes:

```
.thekedar/tasks/012-reset-token-schema.md      (db-specialist)
.thekedar/tasks/013-reset-request-endpoint.md  (api-designer → backend-dev)
.thekedar/tasks/014-reset-confirm-endpoint.md  (api-designer → backend-dev)
.thekedar/tasks/015-reset-form-ui.md           (frontend-dev)
```

Each has concrete `Expected files`, a `NOT in scope` fence (013 explicitly says "do NOT touch the login endpoint"), 2–5 acceptance checkboxes, Risk, and Estimated size. Planner returns:

```
012 — reset-token-schema — password_reset_tokens table + Prisma model
013 — reset-request-endpoint — POST /auth/reset/request, sends email
014 — reset-confirm-endpoint — POST /auth/reset/confirm, sets new password
015 — reset-form-ui — request + confirm forms
Assumptions: token TTL = 1 hour (industry default); single-use tokens.
```

Under 8 tasks, no BLOCKING questions → orchestrator proceeds without asking you to confirm.

## 2. TASK_ACTIVE — task 012

Orchestrator sets 012's Status to `ACTIVE` (the only ACTIVE task right now) and invokes **db-specialist** with the task file path.

db-specialist reads the task, mirrors the existing schema's snake_case/UUID conventions, writes a migration + Prisma model update. Every `Write`/`Edit` call goes through:

```
PreToolUse → scope-guard.sh:  is prisma/migrations/*_reset_tokens/migration.sql
                               in 012's Expected files? yes → allow
PreToolUse → secret-guard.sh: does the content match a secret pattern? no → allow
[write happens]
PostToolUse → munshi.sh:      appends "| 09:14:02 | Write | prisma/migrations/..._reset_tokens/migration.sql |"
                               to .thekedar/changes/ledger-2026-07-09.md
```

db-specialist writes both the forward migration and its rollback, adds an index on the lookup column, runs `prisma migrate dev` locally, and reports:

```
Files: prisma/migrations/20260709_reset_tokens/migration.sql (new),
       prisma/schema.prisma (modify)
Rollback: tested (migrate down/up/down clean)
Acceptance: 3/3 checked
Test: prisma migrate dev → applied clean
```

## 3. REVIEW — task 012

Orchestrator sets Status to `REVIEW`, spawns **error-checker** and **security-auditor** in parallel (fresh contexts each — neither has seen db-specialist's reasoning, only the diff).

security-auditor's verdict:

```
VERDICT: PASS
SCANNED: 2 files in diff · deps added: none
FINDINGS:
  [WARNING] prisma/schema.prisma:41 — token column has no explicit length cap — condition: unbounded input if ever set outside Prisma's typed layer
```

error-checker's verdict: `PASS`, migration applies cleanly, no test suite regression (none existed for schema yet — noted, not blocking).

Both PASS → proceed. (A FAIL here would re-invoke db-specialist with the verbatim findings — max `fix_loop_cap` loops, default 3, before the task goes `BLOCKED` and you see the raw report.)

## 4. LOG + CHECKPOINT — task 012

Orchestrator runs the drift check:

```
$ bash .claude/hooks/drift-check.sh .thekedar/tasks/012-reset-token-schema.md
DRIFT: none — 2 changed file(s), all within declared scope
```

That line goes verbatim into `.thekedar/changes/task-012.md`, alongside "What changed" / "What was deliberately NOT changed" (e.g. "existing `users` table schema — untouched, no migration needed") / verdicts. PROJECT_STATE.md moves 012 to Done, sets 013 as Up next. Orchestrator commits:

```
git commit -m "thekedar(task-012): password reset token schema"
```

Reports to you in 3 lines: *"Task 012 done. Tests pass, security clean (1 warning: unbounded token length — noted as follow-up), no drift. Starting 013."* Since `auto_continue: true` (the default), it proceeds immediately.

## 5. Task 013 — a scope-guard block, in the wild

api-designer runs first (013 touches an API surface), writing a `## API contract` section into the task file: `POST /auth/reset/request` → 200 (always, to avoid email enumeration) / 422 (malformed email).

backend-dev implements it. Partway through, it decides the mailer needs a new template file — `src/lib/mail-templates/reset.html` — which isn't in 013's Expected files. It tries to write it directly:

```
PreToolUse → scope-guard.sh:
  src/lib/mail-templates/reset.html not in Expected files, no Scope addition entry
  scope_guard: on (default)
  → exit 2, stderr:
    "SCOPE-GUARD: src/lib/mail-templates/reset.html is outside task 013's
     declared files. Either add a "## Scope addition" entry (file + one-line
     reason) to the task file first, or leave this file alone."
```

backend-dev sees the block, appends to the task file:

```
## Scope addition
- `src/lib/mail-templates/reset.html` — new email template needed for the reset link
```

...then retries the write. This time scope-guard finds the entry → allows it. This is the mechanism working as designed — not an error, the intended path for legitimate scope growth.

## 6. Fast-forward to DONE

Tasks 013–015 follow the same PLAN-in-place → BUILD → REVIEW → LOG loop. Task 015 (UI) additionally triggers **frontend-reviewer** at the review gate (UI files touched, per the ledger). All four tasks land as four commits. Final `PROJECT_STATE.md`:

```
## Done
- 012 — reset-token-schema
- 013 — reset-request-endpoint
- 014 — reset-confirm-endpoint
- 015 — reset-form-ui

## Up next
- (none — feature complete)
```

## 7. A week later: resume in a fresh session

You open a new Claude Code session in the same repo. `session-brief.sh` (SessionStart) has already printed PROJECT_STATE + pointers into context before you type anything. You say "what's next" — the orchestrator (or `/thekedar-status` for a pure snapshot) answers from what's already there, no re-reading required:

```
Phase:      Phase 2 — user account features · 4/4 tasks
Active:     none
Last edits: src/components/ResetForm.tsx, src/pages/reset.tsx (2026-07-09)
Commit:     a1b2c3d — thekedar(task-015): password reset UI
Up next:    project done — say what's next
Blockers:   none
```
