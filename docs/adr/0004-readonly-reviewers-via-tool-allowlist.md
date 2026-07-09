# ADR 0004 — Read-only reviewers, enforced by tool allowlist

**Date:** 2026-07-09 · **Status:** accepted

## Context

A reviewer that CAN fix what it finds tends to, quietly, even when instructed not to — and once it does, the "independent review" property is gone: the same context that wrote a workaround is now grading its own workaround. This needs to be true structurally, not just as an instruction in the prompt a busy or context-pressured model might deprioritize.

## Decision

Every gate agent's frontmatter `tools:` field excludes `Write`/`Edit`/`MultiEdit` entirely. Claude Code enforces tool allowlists at the runtime layer — a gate agent literally cannot call a tool it wasn't granted, independent of what its prompt says. `doctor.sh` re-verifies this on every health check (grepping the `tools:` line of every gate file) rather than trusting it was set correctly once and never checking again.

## Consequences

Easier: "read-only" is a guarantee you can point to (the frontmatter line), not a hope; a gate that somehow tried to "fix" something would get a tool-not-available error, not a silent edit. Harder: gates cannot even write their own scratch notes to disk — everything must fit in the returned report, which shapes the whole verdict-format convention (compact, structured, no intermediate files).

## Alternatives considered

- **Prompt-only "you are read-only, please don't edit"** — rejected: this is precisely the class of failure (enforcement-by-request) that ADR-0002 and the scope-guard mechanism exist to move away from elsewhere in the system; it would be inconsistent to accept it here.
- **Allow Edit but instruct gates to only use it for their own report file** — rejected: adds a carve-out that's hard to verify mechanically (which edits were "the report" vs. a sneaky fix?) for no real benefit over just returning the report as the subagent's final message.
