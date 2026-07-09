# Architecture — Thekedar

How the pieces fit, why they're shaped this way, and what happens turn by turn.

## 1. Four Layers (v2 adds the guard-rail layer)

```
┌──────────────────────────────────────────────────────────┐
│ LAYER 4 · MEMORY (markdown on disk, git-tracked)         │
│   PROJECT_STATE.md · config.md · tasks/*.md · phases/*.md│
│   changes/*.md → survives crashes, /clear, new sessions   │
├──────────────────────────────────────────────────────────┤
│ LAYER 3 · INTELLIGENCE (LLM contexts)                    │
│   orchestrator (main session, thekedar skill)            │
│   planner · api-designer · 6 doers · 6 gates — fresh      │
│   subagent contexts (isolation is the anti-hallucination  │
│   weapon); 4 command skills for status/report/plan        │
├──────────────────────────────────────────────────────────┤
│ LAYER 2 · GUARD-RAILS (bash, PreToolUse, exit-2-capable) │
│   scope-guard.sh  — blocks writes outside the ACTIVE      │
│                      task's declared files                │
│   secret-guard.sh — blocks writes containing              │
│                      high-confidence secret patterns       │
│   (the ONLY layer allowed to say no to a tool call)        │
├──────────────────────────────────────────────────────────┤
│ LAYER 1 · DETERMINISM (bash, never blocks)               │
│   munshi.sh (PostToolUse ledger) · session-brief.sh        │
│   (SessionStart injection) · drift-check.sh (orchestrator- │
│   invoked audit line) · git commits (checkpoints/rollback) │
└──────────────────────────────────────────────────────────┘
```

Design rule: **push work down the stack.** If bash can enforce it, never spend tokens asking nicely. If one small context can do it (implement one scoped task), never use the big polluted one.

The v1→v2 shift lives entirely in Layer 2. v1 had only Layer 1 (log what happened) and Layer 3 (hope the prompt holds). v2 inserts a layer that can say **no** — mechanically, before the write lands — closing the gap PRD calls P5.

## 2. Why Isolation Beats Prompting

A single long session accumulates: stale file contents, abandoned approaches, half-remembered constraints. Hallucination is usually the model pattern-completing against that noise.

Subagents get a **fresh context** containing only: their system prompt + the one task file + the files they actually open. The frontend-reviewer literally cannot "remember" the backend discussion — it never saw it. The error-checker cannot rationalize the author's intent — it only sees code and failing tests.

Tool allowlists make roles structural, not aspirational: gates have no Write/Edit tool, so "read-only" is enforced by the runtime, not the prompt. `doctor.sh` re-verifies this on every health check rather than trusting it was true when someone last read the file.

**But isolation alone has a gap**: a doer subagent, mid-task, under its own context pressure, can still decide an out-of-scope edit is justified — the NOT-in-scope section is text it reads, not a wall it hits. That gap is why Layer 2 exists.

## 3. The Guard-Rail Layer, in Detail

```
 doer subagent calls Write/Edit
        │
        ▼
 PreToolUse: scope-guard.sh
   ACTIVE task? → path in Expected files / Scope addition? ──yes──▶ allow
        │no                                                          │
        ▼                                                            │
   scope_guard: off? ──yes──▶ log to ledger, allow ────────────────┘
        │no
        ▼
   exit 2 — write REJECTED, model sees the SCOPE-GUARD message,
            must add a Scope addition entry or abandon the edit
        │
        ▼
 PreToolUse: secret-guard.sh (independent check, same event)
   content matches a high-confidence secret pattern? ──yes──▶ exit 2, rejected
        │no
        ▼
   allow → tool executes → file written
        │
        ▼
 PostToolUse: munshi.sh → ledger line appended (fact, zero tokens)
```

Both guards share one non-negotiable property: **fail open.** A parse error, a missing `jq`/`python3`, an unreadable task file — any of these makes the guard exit 0, never 2. The only path to exit 2 is a *positive, confirmed* match. This is what lets a mechanism this strict ship without becoming the thing that bricks someone's session (see [ADR-0002](adr/0002-hooks-never-block-except-guards.md)).

## 4. One Task, Turn by Turn

```
 T0  user: "add JWT auth"
 T1  skill: request is multi-step → invoke planner
 T2  planner (fresh ctx): Grep/Read codebase → writes
       tasks/004-jwt-middleware.md   (scope: middleware only,
                                      NOT-scope: login UI, refresh tokens;
                                      Risk: medium, Size: M)
     updates PROJECT_STATE.md → returns 2-line summary
 T3  orchestrator: API surface involved → api-designer writes
       "## API contract" into 004 (POST /auth/verify → 200/401)
 T4  orchestrator: 004 → ACTIVE. invoke backend-dev with task file path
 T5  backend-dev (fresh ctx): reads task, implements middleware
       every Write/Edit → PreToolUse: scope-guard + secret-guard check
       → allowed → PostToolUse: munshi.sh appends:
       | 14:02:11 | Write | src/middleware/auth.ts |
 T6  backend-dev needs src/config/env.ts too (not in Expected files):
       appends "## Scope addition" to 004 FIRST → edits → guard allows
 T7  orchestrator: spawn error-checker + security-auditor (parallel)
 T8  error-checker: npm test → 1 failure → FAIL report (severity, file:line)
 T9  orchestrator: re-invoke backend-dev with the report (fix loop 1/3)
 T10 backend-dev: fixes → munshi logs
 T11 reviewers re-run → PASS + PASS
 T12 orchestrator: drift-check.sh 004 → "DRIFT: none — 3 changed file(s),
       all within declared scope" (the Scope addition covered T6)
     writes changes/task-004.md (what/what-NOT/why/verdicts/drift)
     PROJECT_STATE: 004 → DONE, 005 → up next
     git commit -m "thekedar(task-004): JWT middleware"
 T13 auto_continue: true → T4 with task 005
```

Total reviewer invocations: 2 per task (+re-runs on fix loops), never per edit. Total guard invocations: 2 per Write/Edit (scope + secret), ~12 ms each.

## 5. The Two Records (and why both)

| | Munshi ledger | Task changelog |
|---|---|---|
| Written by | bash hook, automatic | orchestrator, per task |
| Granularity | every single edit | one entry per task |
| Content | time · tool · file path (+ scope-advisory misses) | what changed, what deliberately didn't, why, reviewer verdicts, drift line |
| Cost | 0 tokens | ~200–400 tokens |
| Answers | "what exactly was touched at 14:02?" | "what happened in this task and can I trust it?" |

Per-edit *narrative* logging was rejected: noisy, expensive, and the model narrating its own edits mid-flow degrades the edits. Facts are captured live for free; meaning is written once at the boundary where it exists — task completion.

## 6. Resume Protocol

Fresh session start → `session-brief.sh` (SessionStart hook) auto-injects `PROJECT_STATE.md` + the ACTIVE task pointer + the latest changelog pointer into context, **before the user types anything**. User says "continue" → orchestrator verifies what it was just handed against disk:

1. The ACTIVE (or next TODO) task file — exact scope
2. Most recent `changes/task-*.md` — what just happened
3. `git log --oneline -5` — sanity check that disk matches memory

If state and git disagree (e.g. uncommitted edits, no ACTIVE task, ledger shows edits after the last changelog was written — a sign a second session touched this repo), the orchestrator reports the discrepancy and asks — it never guesses its way past a broken invariant.

## 7. Failure Modes & Containment

| Failure | Containment |
|---|---|
| munshi/session-brief/drift-check crash | always `exit 0`; worst case = a missing ledger line or brief, session unaffected |
| scope-guard/secret-guard internal error | fail-open by design (exit 0); worst case = a guard that doesn't catch this one edit, not a blocked session |
| scope-guard false positive on a legitimate edit | Scope-addition protocol is the designed escape hatch (append reason, then edit); `scope_guard: off` is the panic valve |
| reviewer hallucinates a failure | fix loop capped at `fix_loop_cap` (default 3), then human sees the raw report and decides |
| doer edits out-of-scope files despite the guard | shouldn't happen with scope-guard `on`; drift-check.sh is the second-line audit that catches anything that slips through advisory mode |
| context overflow mid-task | state is already on disk; user compacts/restarts; session-brief + resume protocol recover it |
| user edits files manually | git + resume protocol treat disk as truth; state file reconciled on next turn |
| two sessions edit the same repo concurrently | not solved mechanically in v2 — see TROUBLESHOOTING.md; each session's commits interleave in git history as normal, but state/task files can race |

## 8. Extension Points

- **Add a crew member:** `bash .thekedar/scripts/new-agent.sh <name> --doer\|--gate --model <m>` scaffolds `.claude/agents/custom/<name>.md` from `agent-template.md` with the tool law pre-applied. The orchestrator's delegation is description-driven — no registry to update.
- **Swap models:** edit one frontmatter line per agent, or set `default_doer_model` in config.md as the documented intent.
- **Disable a reviewer:** flip its config.md flag (performance/accessibility auditors) or don't install `--full` (the 9 extended agents are opt-in as a set).
- **Other tools (Cursor/Codex):** `export-agents-md.sh` flattens the workflow into `AGENTS.md` — generated from the same agent files, not a hand-maintained fork. Re-run after any agent/skill change.
- **Custom health checks:** `doctor.sh` is a flat bash script — new checks are new functions in the same file, no framework to learn.
