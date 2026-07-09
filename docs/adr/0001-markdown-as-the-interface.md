# ADR 0001 — Markdown as the interface

**Date:** 2026-07-09 · **Status:** accepted

## Context

Thekedar needs a format for tasks, project state, changelogs, and config that both an LLM and a human can read, write, and reason about — reliably, across every tool (Claude Code today, Cursor/Codex/others via AGENTS.md, whatever exists in five years).

## Decision

Every artifact Thekedar produces or reads is markdown with lightweight, human-readable structure (headings, checkboxes, `key: value` lines). No JSON state files, no YAML beyond agent frontmatter, no binary or database-backed state.

## Consequences

Easier: any editor opens every file; a human can hand-edit a task or override a decision without tooling; the format survives Thekedar itself becoming obsolete; diffs in `git log` are readable prose, not serialized blobs. Harder: no schema validation beyond convention and doctor.sh's checks; parsing requires `awk`/`sed`/`grep` gymnastics in bash rather than a JSON parser's one-liner (visible in scope-guard.sh's allowlist extraction); malformed markdown fails softly rather than loudly.

## Alternatives considered

- **JSON state files** — rejected: unreadable in a diff, requires a parser dependency to hand-edit safely, and a human reviewing "what did the AI decide and why" reads worse in JSON than prose.
- **SQLite / embedded database** — rejected outright by the zero-dependency, zero-database non-goal (PRD §4) — durability and inspectability matter more than query power at this scale.
