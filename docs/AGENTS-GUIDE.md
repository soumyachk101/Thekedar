# Agents Guide — the 15-member crew

Every agent is a markdown file with YAML frontmatter in `.claude/agents/{core,extended}/`. This page is the human-readable index; the file itself is the actual system prompt (read it for the full process/rules — this page summarizes when it fires, what it touches, and what a verdict looks like).

Frontmatter law, mechanically enforced by tool allowlists (verified by `doctor.sh`):
- **Doers & brains** get `Read, Write, Edit, Bash, Grep, Glob` (brains that only edit the task file itself get `Write` without `Edit`/`Bash`).
- **Gates** get `Read, Grep, Glob, Bash` — **never** Write/Edit. Read-only is structural, not a promise.

## Core crew (always installed)

### planner
**Fires:** start of any multi-step request, or "re-plan". **Tools:** Read, Grep, Glob, Write. **Model:** inherit.
Surveys the codebase, decomposes the request into `tasks/NNN-slug.md` files (phases if >12), sorts unknowns into BLOCKING questions vs recorded Assumptions. Never writes implementation code.

### api-designer
**Fires:** a task creates/changes an API surface — runs BEFORE the doer. **Tools:** Read, Grep, Glob, Write. **Model:** inherit.
Writes a `## API contract` section into the task file: method/path, request/response shapes, every error case + status code, authZ. Flags breaking changes with `⚠ BREAKING`. Its only Write target is the task file — never source code.

### backend-dev
**Fires:** server/API/db/script implementation, one task at a time. **Tools:** Read, Write, Edit, Bash, Grep, Glob. **Model:** sonnet.
Reads Expected files, implements to existing conventions, runs tests, self-checks acceptance boxes. Scope-addition protocol: append the entry to the task file, THEN edit — scope-guard.sh enforces the order mechanically.

### frontend-dev
**Fires:** UI/component/style/client-state implementation. **Tools:** Read, Write, Edit, Bash, Grep, Glob. **Model:** sonnet.
Same discipline as backend-dev, plus: design-system-reuse-first (greps for existing components before inventing), loading/error/empty states are part of "done" not polish, accessibility built in (not left for the reviewer to catch).

### error-checker
**Fires:** every task, always, at REVIEW. **Tools:** Read, Bash, Grep, Glob (read-only). **Model:** sonnet.
Runs the test suite, linter, build (whichever exist); reads the diff hostile-reviewer style (broken imports, unhandled rejections, off-by-ones); verifies every acceptance checkbox against reality.

Sample verdict:
```
VERDICT: FAIL
TESTS: npm test → 14 passed / 1 failed
LINT/BUILD: tsc clean
FINDINGS:
  [CRITICAL] src/auth/reset.ts:34 — token comparison uses == not timing-safe compare — timing attack on token guessing
ACCEPTANCE: 2/3 verified; #3 unverified — no test covers expired-token rejection
```

### security-auditor
**Fires:** every task, always, at REVIEW. **Tools:** Read, Grep, Glob, Bash (read-only). **Model:** sonnet.
Hunts in priority order: secrets, injection, authN/authZ gaps, input handling, crypto/storage, dependency red flags. Every CRITICAL needs a one-line exploit scenario or it's downgraded to WARNING.

### frontend-reviewer
**Fires:** UI/frontend files touched (checked via the ledger). **Tools:** Read, Grep, Glob, Bash (read-only). **Model:** sonnet.
Correctness (state mutation, effect deps, race conditions), accessibility, responsiveness, design-system consistency, render-performance smells. Taste is INFO; broken is CRITICAL.

## Extended crew (`install.sh --full`)

### test-writer
**Fires:** test-gap tasks; MUST run before refactor-specialist (behavior-lock). **Tools:** doer set. **Model:** sonnet.
Two modes: behavior-lock (pin current behavior before a refactor, including its quirks) and gap (cover acceptance criteria + edge cases). Never touches production code; never weakens an assertion to make it pass.

### db-specialist
**Fires:** schema/migration/query-layer tasks. **Tools:** doer set. **Model:** sonnet.
Reversible-by-default migrations (forward + rollback), data-safety checklist (destructive ops sanctioned explicitly, backfills batched), indexes for every new query pattern.

### devops-engineer
**Fires:** Dockerfile/CI/env-handling tasks. **Tools:** doer set. **Model:** sonnet.
Boring-reliability defaults: pinned versions everywhere, least privilege, layer-cache-friendly, `set -euo pipefail`. Never runs deploys or registry pushes — build/validate only.

### refactor-specialist
**Fires:** refactor tasks. **Tools:** doer set. **Model:** sonnet.
**Hard precondition:** refuses to start without passing behavior-lock tests from test-writer. Refactors in small reversible steps, re-running the lock suite after each. A red suite means revert the step, never touch the test.

### docs-writer
**Fires:** documentation tasks. **Tools:** Read, Write, Grep, Glob. **Model:** haiku.
Sources are changelogs + actual code, never memory. Matches house style. Every example is verified against the code before being written down.

### performance-auditor
**Fires:** `enable_performance_auditor: true` in config, or task tagged `perf`. **Tools:** gate set. **Model:** sonnet.
N+1 patterns, missing indexes, hot-loop waste, blocking IO, bundle bloat. Every CRITICAL needs a load/cost scenario or it's a WARNING.

### accessibility-auditor
**Fires:** `enable_accessibility_auditor: true`, or task tagged `a11y`. **Tools:** gate set. **Model:** sonnet.
Deep WCAG 2.1 AA pass beyond frontend-reviewer's basics: keyboard flows, ARIA correctness, focus management, live-region announcements. Names the locked-out user per finding; states what it couldn't verify without a real browser.

### dependency-auditor
**Fires:** a manifest or lockfile is in the diff. **Tools:** gate set. **Model:** haiku.
Unsanctioned new deps are an automatic CRITICAL. Typosquat smell, floating versions, license flags (copyleft into permissive codebases), audit-command results if available — never fabricated.

## Custom crew

Scaffold your own with `bash .thekedar/scripts/new-agent.sh <name> --doer|--gate --model <m>` → lands in `.claude/agents/custom/`. See [CUSTOMIZATION.md](CUSTOMIZATION.md).

## The standard verdict shape (every gate)

```
VERDICT: PASS | FAIL
<gate-specific summary line: TESTS / SCANNED / BUILD-TESTS / DEPS>
FINDINGS:
  [CRITICAL] file:line — issue — why it breaks / exploit / cost scenario
  [WARNING]  file:line — issue — condition under which it bites
  [INFO]     suggestion (does not block)
```

`FAIL` = any CRITICAL, or (error-checker/frontend-reviewer specifically) any failing test/broken build/unmet acceptance criterion.
