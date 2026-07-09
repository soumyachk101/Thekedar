# Commands — the 4 skills

Thekedar has one orchestrator skill (auto-triggers on multi-step requests, no invocation needed) and three explicit command skills. All four are markdown files under `.claude/skills/<name>/SKILL.md`, loaded at session start (progressive disclosure — only `name`+`description` load until triggered).

## thekedar (the orchestrator — auto-triggers)

**Triggers on:** "build/create/implement/refactor/plan X" (multi-file or >~30 lines), "continue", "resume", or explicit mention. Does **not** trigger on trivial single-file asks or pure questions — those get answered directly.

**Example:**
```
you:      add rate limiting to the login endpoint

thekedar: [invokes planner]
          016 — rate-limit-middleware — token-bucket limiter, 5 req/min per IP
          017 — apply-to-login — wire the limiter into POST /auth/login
          Starting 016...

          [backend-dev builds, error-checker + security-auditor review, PASS]

          Task 016 done. Tests pass, security clean, no drift. Starting 017.
```

## /thekedar-status

**Triggers on:** `/thekedar-status`, or a pure status question ("where are we", "kahan tak pahunche"). Read-only — touches nothing, spawns no subagents.

**Output is always exactly 6 lines:**
```
Phase:      Phase 2 — user accounts · 3/4 tasks
Active:     017 — apply-rate-limit-to-login
Last edits: src/middleware/rateLimit.ts, src/routes/auth.ts
Commit:     a1b2c3d — thekedar(task-016): rate-limit middleware
Up next:    017 — apply-rate-limit-to-login
Blockers:   none
```

If state and git visibly disagree, a 7th line appears: `⚠ drift: <what's wrong>`. No `.thekedar/` at all → a single line telling you to start a project.

## /thekedar-report

**Triggers on:** `/thekedar-report`, or "generate the project report" / "hisaab do". Runs `scripts/report.sh` (falls back to composing `REPORT.md` by hand if the script isn't installed), then summarizes in ≤5 lines.

**Example summary:**
```
REPORT.md written. 4/4 tasks done, 23 edits logged across 11 files,
1 fix loop used, 0 open follow-ups. See REPORT.md for the full record.
```

`REPORT.md` itself contains: counted stats table, full `PROJECT_STATE.md`, every task changelog in full (what changed / NOT changed / why / verdicts / drift), a per-day ledger edit-count table, and the git checkpoint log.

## /thekedar-plan

**Triggers on:** `/thekedar-plan`, or "just plan, don't build yet". Invokes the planner, presents the task breakdown, then **stops** — no task goes ACTIVE, nothing gets built.

**Example:**
```
you: /thekedar-plan add a public API with rate limiting and API keys

thekedar-plan: Q1: should API keys be per-user or per-organization?

               018 — api-key-schema — key generation + storage (BLOCKED on Q1)
               019 — key-auth-middleware — validates X-API-Key header
               020 — public-endpoints — read-only /api/v1/* surface
               021 — rate-limit-by-key — per-key limits, not per-IP

               Assumptions: keys never expire (revoke-only); rate limit = 100 req/min.

               Plan ready. Say "continue" to start task 019 under the thekedar
               workflow (018 stays BLOCKED until Q1 is answered).
```

Answering the BLOCKING question and re-running `/thekedar-plan` updates only the affected task(s); it never renumbers tasks already `DONE`.
