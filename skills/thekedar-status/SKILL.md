---
name: thekedar-status
description: >
  Use when the user invokes /thekedar-status or asks a status-only question about the
  Thekedar-managed project ("status", "where are we", "kahan tak pahunche") — a quick
  read-only snapshot WITHOUT resuming work. To actually continue building, use the
  thekedar skill instead.
---

# /thekedar-status — the 6-line site report

Read-only. Touch nothing, change nothing, spawn no subagents.

## Sources (read in this order, skip what's missing)

1. `.thekedar/PROJECT_STATE.md` — phase, active task, done list, up next, known issues
2. Today's ledger `.thekedar/changes/ledger-<today>.md` — last 3 entries
3. `git log --oneline -3` and `git status --porcelain | head -5`

## Output — EXACTLY these 6 lines, nothing else

```
Phase:      <current phase> · <n done>/<n total> tasks
Active:     <NNN — title | none>
Last edits: <up to 3 file paths from today's ledger | none today>
Commit:     <short-hash — message | no commits yet>
Up next:    <NNN — title | project done>
Blockers:   <BLOCKED tasks + top known issue | none>
```

## Rules

- No prose before or after the block. No advice, no offers to continue.
- One exception: if state and git visibly disagree (uncommitted changes but no ACTIVE task, ledger edits newer than the last changelog), append ONE warning line starting `⚠ drift:` describing the mismatch.
- `.thekedar/` missing entirely → single line: `No Thekedar state here — run the thekedar skill to start a project.`
