# ADR 0006 — scope-guard as a PreToolUse hook, not a prompt instruction

**Date:** 2026-07-09 · **Status:** accepted

## Context

v1's anti-hallucination fence was the task file's "NOT in scope" section — text a doer agent reads and (usually) respects. Dogfooding v1 surfaced the gap: under context pressure, on a long task, a doer can decide an out-of-scope edit is justified, and nothing catches it until a human notices in `git diff` — the exact P2/P5 failure this project exists to prevent.

## Decision

`scope-guard.sh` runs as a `PreToolUse` hook on `Write|Edit|MultiEdit`, checking the target path against the ACTIVE task's declared Expected-files + Scope-addition allowlist **before the write executes**, and rejecting (`exit 2`) a confirmed miss. This moves scope enforcement from Layer 3 (prompt/intelligence) to Layer 2 (mechanism) in the architecture (see ARCHITECTURE.md) — the same shift, and the same reasoning, as ADR-0004's read-only gates.

## Consequences

Easier: an out-of-scope edit is now impossible to make silently — it either gets blocked with a clear message, or the doer follows the Scope-addition protocol and the addition is visible in the task file and the drift-check report. This is the single biggest reliability improvement in v2 over v1. Harder: the hook needs an escape hatch for legitimate scope growth (the Scope-addition protocol) or it would just convert "silent drift" into "constant blocking friction" — getting that hatch's ergonomics right (append-then-edit, not a permission dialog) took real design work, and it still needs an advisory-mode off-ramp (`scope_guard: off`) for cases where a user's workflow doesn't fit the model.

## Alternatives considered

- **Keep it prompt-only, just phrase the fence more strongly** — rejected: this was tried implicitly in v1; the gap it left is exactly why this ADR exists.
- **PostToolUse block (undo the edit after the fact)** — rejected: Claude Code's blocking hooks are pre-execution by design; reverting a completed write is strictly worse (the file was briefly wrong on disk, and "undo" is a much harder operation to make reliable than "refuse") than preventing it up front.
- **Require human approval on every out-of-scope attempt** — rejected as the default: too much friction for the common, legitimate case (task was slightly under-scoped); the Scope-addition protocol gives the doer a self-serve path, keeping a human in the loop only for genuinely stuck cases (the fix-loop cap).

## Implementation note — path canonicalization (added at v2.0.0 release audit)

The first implementation compared the **raw** `file_path` string against the allowlist. A pre-release security audit (a fresh-context `security-auditor` run over the whole shell surface) found this defeats the entire guarantee: shell `case`/glob matching has no filesystem awareness, so `*` matches a literal `..`, and `file_path = <proj>/src/../outside/x` string-matched a `src/*` allow-entry — a normal, encouraged directory scope — while the OS would resolve the write to `<proj>/outside/x`, fully outside scope, with **no** Scope-addition declared. The `.thekedar/*` universal exemption made it worse: `.thekedar/../src/secret.env` bypassed both this hook and secret-guard.sh unconditionally on any installed project.

Fix: every path is now **lexically canonicalized** (resolve `.`/`..` by string manipulation) before any comparison. Lexical, not `realpath`/`readlink -f`, because the `Write` target frequently doesn't exist yet and those tools are inconsistent across macOS/Linux/WSL/Git Bash — the guard must work portably on a not-yet-created path. A path that canonicalizes outside the project root is treated as a guaranteed miss. The same fix applies to secret-guard.sh's exclusion list and drift-check.sh's `in_scope()` helper. Regression tests for the exact bypass live in `tests/test-scope-guard.sh` and `tests/test-secret-guard.sh`. The lesson reinforces this ADR's own thesis: moving enforcement from prompt to mechanism only helps if the mechanism itself is correct — a guard with a bypass is a false sense of security, arguably worse than an honest prompt.
