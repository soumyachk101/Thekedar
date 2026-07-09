---
name: thekedar-report
description: >
  Use when the user invokes /thekedar-report or asks for a full project work report
  ("hisaab do", "what did the AI change this week", "generate the project report") —
  compiles ledgers + task changelogs + git history into REPORT.md and summarizes it.
---

# /thekedar-report — hisaab, on paper

## Steps

1. **Prefer the script** (deterministic, zero tokens): run the first that exists —
   - `bash .thekedar/scripts/report.sh` (installed location)
   - `bash scripts/report.sh` (source repo)
   It writes `REPORT.md` at the project root.
2. **Script missing** (pre-Phase-6 install or partial copy): compose `REPORT.md` yourself from, in order:
   - `.thekedar/PROJECT_STATE.md` — overview, phase, done list, decisions log
   - every `.thekedar/changes/task-*.md` — one section per task: what changed / NOT changed / verdicts / drift line
   - `.thekedar/changes/ledger-*.md` — edit counts per day (count lines, don't paste tables)
   - `git log --oneline` — checkpoint list
   Structure: Overview → Timeline (per task) → Decisions → Known issues / follow-ups → Raw numbers (tasks done, edits logged, fix loops used, files touched).
3. **Summarize to the user in ≤ 5 lines**: tasks done, edits logged, fix-loops used, open follow-ups, where REPORT.md lives.

## Rules

- Numbers come from counting real lines/files — never estimate, never round up.
- Changelog "NOT changed" sections carry over verbatim — that honesty is the product.
- REPORT.md is regenerated whole each run (it's derived data; the sources are the truth).
- Read-only apart from writing REPORT.md itself.
