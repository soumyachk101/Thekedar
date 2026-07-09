# Architecture — Thekedar

How the pieces fit, why they're shaped this way, and what happens turn by turn.

## 1. Three Layers

```
┌──────────────────────────────────────────────────────────┐
│ LAYER 3 · MEMORY (markdown on disk, git-tracked)         │
│   PROJECT_STATE.md · tasks/*.md · changes/*.md           │
│   → survives crashes, /clear, new sessions, new tools    │
├──────────────────────────────────────────────────────────┤
│ LAYER 2 · INTELLIGENCE (LLM contexts)                    │
│   orchestrator (main session, thekedar skill)            │
│   planner · backend-dev · 3 reviewers (fresh subagent    │
│   contexts — isolation is the anti-hallucination weapon) │
├──────────────────────────────────────────────────────────┤
│ LAYER 1 · DETERMINISM (bash + git)                       │
│   munshi.sh hook (per-edit ledger, 0 tokens)             │
│   git commits (checkpoints, rollback)                    │
└──────────────────────────────────────────────────────────┘
```

Design rule: **push work down the stack.** If bash can do it (logging facts, committing), never spend tokens. If one small context can do it (implement one scoped task), never use the big polluted one.

## 2. Why Isolation Beats Prompting

A single long session accumulates: stale file contents, abandoned approaches, half-remembered constraints. Hallucination is usually the model pattern-completing against that noise.

Subagents get a **fresh context** containing only: their system prompt + the one task file + the files they actually open. The frontend-reviewer literally cannot "remember" the backend discussion — it never saw it. The error-checker cannot rationalize the author's intent — it only sees code and failing tests.

Tool allowlists make roles structural, not aspirational: reviewers have no Write/Edit tool, so "read-only" is enforced by the runtime.

## 3. One Task, Turn by Turn

```
 T0  user: "add JWT auth"
 T1  skill: request is multi-step → invoke planner
 T2  planner (fresh ctx): Grep/Read codebase → writes
       tasks/004-jwt-middleware.md   (scope: middleware only,
                                      NOT-scope: login UI, refresh tokens)
       tasks/005-login-endpoint.md
     updates PROJECT_STATE.md → returns 2-line summary
 T3  orchestrator: 004 → ACTIVE. invoke backend-dev with task file path
 T4  backend-dev (fresh ctx): reads task, implements middleware
       every Write/Edit → PostToolUse fires → munshi.sh appends:
       | 14:02:11 | Write | src/middleware/auth.ts |
 T5  orchestrator: spawn error-checker + security-auditor (parallel)
 T6  error-checker: npm test → 1 failure → FAIL report (severity, file:line)
 T7  orchestrator: re-invoke backend-dev with the report (fix loop 1/3)
 T8  backend-dev: fixes → munshi logs
 T9  reviewers re-run → PASS + PASS
 T10 orchestrator: writes changes/task-004.md (what/what-NOT/why/verdicts)
     PROJECT_STATE: 004 → DONE, 005 → up next
     git commit -m "thekedar(task-004): JWT middleware"
 T11 → T3 with task 005
```

Total reviewer invocations: 2 per task (+re-runs on fix loops), never per edit.

## 4. The Two Records (and why both)

| | Munshi ledger | Task changelog |
|---|---|---|
| Written by | bash hook, automatic | orchestrator, per task |
| Granularity | every single edit | one entry per task |
| Content | time · tool · file path | what changed, what deliberately didn't, why, reviewer verdicts |
| Cost | 0 tokens | ~200–400 tokens |
| Answers | "what exactly was touched at 14:02?" | "what happened in this task and can I trust it?" |

Per-edit *narrative* logging was rejected: noisy, expensive, and the model narrating its own edits mid-flow degrades the edits. Facts are captured live for free; meaning is written once at the boundary where it exists — task completion.

## 5. Resume Protocol

Fresh session → user says "continue" → skill triggers → orchestrator reads, in order:

1. `PROJECT_STATE.md` — phase, active/next task, decisions
2. Active task file — exact scope
3. Last `changes/task-*.md` — what just happened
4. `git log --oneline -5` — sanity check that disk matches memory

If state and git disagree (e.g. uncommitted edits, no ACTIVE task), the orchestrator reports the discrepancy and asks — it never guesses its way past a broken invariant.

## 6. Failure Modes & Containment

| Failure | Containment |
|---|---|
| munshi.sh crashes | always `exit 0`; worst case = a missing ledger line, session unaffected |
| reviewer hallucinates a failure | fix loop is capped at 3, then human sees the raw report and decides |
| doer edits out-of-scope files | ledger + git diff expose it; P1 drift-detector automates the check |
| context overflow mid-task | state is already on disk; user compacts/restarts; resume protocol recovers |
| user edits files manually | git + resume protocol treat disk as truth; state file reconciled on next turn |

## 7. Extension Points

- **Add a crew member:** drop `.claude/agents/db-migrator.md` (copy an existing reviewer, adjust tools/prompt). The orchestrator's delegation is description-driven — no registry to update.
- **Swap models:** edit one frontmatter line per agent.
- **Other tools (Cursor/Codex):** P1 `AGENTS.md` export flattens the workflow into sequential rules — same files on disk, same records, single context.
