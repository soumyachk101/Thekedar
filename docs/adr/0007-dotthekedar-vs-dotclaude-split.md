# ADR 0007 — `.thekedar/` vs `.claude/` split

**Date:** 2026-07-09 · **Status:** accepted

## Context

Thekedar produces two categories of file: things that only make sense in the context of Claude Code specifically (subagent definitions, skills, hooks, the settings.json wiring that activates them), and things that are pure project record-keeping with no Claude-Code-specific structure at all (what was built, when, and why).

## Decision

`.claude/` holds exclusively Claude-Code-mechanism files: `agents/`, `skills/`, `hooks/`, `settings.json`. `.thekedar/` holds exclusively project-artifact files: `tasks/`, `phases/`, `changes/` (ledger + changelogs), `PROJECT_STATE.md`, `config.md`, and the installed copies of `templates/`/`scripts/`. Nothing in `.thekedar/` requires Claude Code to be meaningful; a human (or a different tool entirely) can read a task file or a changelog with zero Thekedar-specific tooling.

## Consequences

Easier: if Claude Code's subagent/skill/hook mechanism ever changes shape, only `.claude/` needs to move — the actual project history in `.thekedar/` is untouched; a future AGENTS.md-only degraded-mode user (no `.claude/` at all) still gets the full task/state/changelog trail; `uninstall.sh` can cleanly remove `.claude/`'s Thekedar entries while unconditionally preserving `.thekedar/` as "this is your history, not ours to delete." Harder: two directories to explain in onboarding docs instead of one; a few scripts (drift-check, doctor) need to reach into both trees.

## Alternatives considered

- **Everything under `.claude/`** — rejected: conflates tool-specific mechanism with tool-agnostic history; makes the future AGENTS.md degraded mode (F10) awkward, since it would have no natural home for tasks/state/changelogs without Claude Code's directory being present.
- **Everything under `.thekedar/`, including agent/skill/hook definitions** — rejected: Claude Code specifically looks for subagents/skills/hooks under `.claude/` — fighting that convention would mean either symlinks or the installer copying files to two places, more moving parts for no benefit.
