# ADR 0002 — Hooks never block, except the two guards

**Date:** 2026-07-09 · **Status:** accepted

## Context

Claude Code hooks can return exit code 2 to block a tool call. That's powerful — but a hook bug that blocks incorrectly can brick an entire coding session, which is a worse outcome than the problem the hook was meant to solve. v1 had one hook (munshi, logging) with no blocking need. v2 introduces two hooks whose entire purpose IS to block (scope-guard, secret-guard).

## Decision

Three hooks (`munshi.sh`, `session-brief.sh`, `drift-check.sh`) are non-negotiably exit-0-always — they observe and record, never gate. Two hooks (`scope-guard.sh`, `secret-guard.sh`) are allowed to exit 2, but **only** on a positive, confirmed match; every other code path in both — parse failure, missing `jq`/`python3`, unreadable task file, any internal doubt — exits 0. "Fail open" is not a fallback behavior bolted on; it's the load-bearing design constraint these two scripts are written around from the first line.

## Consequences

Easier: users can trust that installing Thekedar's hooks will never randomly break their session, even with a hook bug — the blast radius of a bug in the two guards is "this one edit didn't get caught," not "Claude Code is now unusable." Harder: the guards can be defeated by exactly the conditions that make them fail open (no jq/python3 present, for instance) — this is an accepted, documented tradeoff (see TRD §3.6, FAQ.md), not an oversight. Every guard change must pass fixture tests proving both the block path and every fail-open path (CONTRIBUTING.md's hook-test rule extends to both guards, not just munshi).

## Alternatives considered

- **Guards fail closed on doubt** (block unless certain it's safe) — rejected: false positives would erode trust fast, and an installer-adoption non-goal is "don't be the tool that randomly breaks someone's flow." A missed catch is recoverable (drift-check catches it later); a bricked session is not.
- **No blocking hooks at all, log-only like v1** — rejected: this is the exact gap (PRD P5) that motivated v2 — text-only scope fences don't hold under context pressure, and logging after the fact doesn't prevent the edit.
