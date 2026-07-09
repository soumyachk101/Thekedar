# Troubleshooting

## Agents don't appear / "what subagents do you have?" shows nothing new

You didn't restart the session. Subagent files (`.claude/agents/**/*.md`) and skills load at session start — editing or installing them mid-session has no effect until you restart. Run `bash .thekedar/scripts/doctor.sh` to confirm the files are actually on disk first; if doctor is green but the agents still don't show, restart.

## No ledger lines appear in `.thekedar/changes/ledger-*.md`

1. `bash .thekedar/scripts/doctor.sh` — checks the hook is present, executable, wired in `settings.json`, and live-tests it.
2. If doctor says wiring is missing: re-run `install.sh` (idempotent, safe).
3. If wiring is present but still no lines: check `.claude/settings.json` is valid JSON — a broken settings file means Claude Code may silently not run hooks. `doctor.sh` checks this too.
4. Manual check: `echo '{"tool_name":"Edit","tool_input":{"file_path":"x.ts"}}' | bash .claude/hooks/munshi.sh && cat .thekedar/changes/ledger-*.md`.

## `settings.json is not valid JSON` warning from the installer

The installer refuses to touch a broken settings file rather than guess at a merge. Fix the JSON by hand (a trailing comma is the usual culprit), then re-run `install.sh`.

## scope-guard.sh blocked an edit I actually wanted

This is the mechanism working, not a bug — but three ways to proceed depending on what you actually want:

1. **The edit is legitimately part of the current task:** add a `## Scope addition` entry to the ACTIVE task file (file path + one-line reason) BEFORE retrying the edit. This is the designed path — doer agents are instructed to do this automatically; if you're editing by hand, do the same.
2. **The task was scoped too narrowly:** update its `## Expected files` section directly (you can always hand-edit task files) and continue.
3. **You want scope-guard to stop blocking entirely for now:** set `scope_guard: off` in `.thekedar/config.md` — switches to advisory mode (logs a `scope-advisory` ledger line instead of blocking). Re-enable once you've past the friction point.

## secret-guard.sh blocked a write that isn't actually a secret

The patterns are high-confidence by design (AWS/PEM/JWT/GitHub/Slack/Stripe/Anthropic/Google formats), so false positives should be rare — but a sufficiently random-looking string (a test fixture, a hash, a generated ID) can coincidentally match. Options:
1. Move the content to a path the guard excludes: anything under `fixtures/`, `__mocks__/`, or named `*.sample`/`*.example`/`*.template`.
2. If it's a real pattern you need to keep in a real file for a legitimate reason (rare), that's a signal to reconsider — secrets belong in env vars, not source, even for "just testing."

There is no config flag to disable secret-guard partially — it's on or removed from `settings.json` entirely (see CUSTOMIZATION.md). That's deliberate: unlike scope, "advisory secrets" isn't a safe middle ground.

## A task is stuck `BLOCKED` after 3 fix loops

By design — `fix_loop_cap` (default 3) exists so a genuinely confused doer doesn't burn unbounded tokens re-attempting the same task. Read the raw reviewer report the orchestrator surfaces; usually either the task was scoped wrong (split it, or fix the NOT-in-scope fence) or the acceptance criteria don't match reality (re-plan that task with the planner). Raise `fix_loop_cap` in config.md only if you've confirmed the doer is making real incremental progress each loop, not repeating the same mistake.

## PROJECT_STATE.md and git history disagree

The orchestrator is instructed to report this and ask, never guess past it. Common causes:
- **Two sessions touched the same repo concurrently** (see below) — the state file one session wrote doesn't match what the other session committed.
- **A crash mid-task** — task shows `ACTIVE` or `REVIEW` but no changelog/commit exists for it. Safe recovery: re-invoke the same doer with the task file; it re-reads current file state and continues from what's actually on disk, not from stale assumptions.
- **Manual edits outside the workflow** — expected and fine; the orchestrator treats disk as truth and reconciles state on the next turn.

## Running two Claude Code sessions on the same Thekedar project at once

**Not supported in v2 — avoid it.** Each session's hooks, task-file edits, and git commits are invisible to the other until a commit lands, so both sessions can mark different tasks `ACTIVE` simultaneously, both can edit `PROJECT_STATE.md`, and commits from one session can strand the other mid-task. If it happens: stop one session, `git status`/`git log` to see what actually landed, let `/thekedar-status` in the surviving session reconcile against disk, and manually fix any task file left in a stale `ACTIVE`/`REVIEW` state. This is a known v2 gap, not a hidden feature — track improvements here on the roadmap.

## Installer says "you're running this inside the thekedar repo itself"

You're trying to `bash install.sh` from within a clone of the Thekedar source repo. `cd` into the project you actually want to install *into*, then run `bash /path/to/thekedar/install.sh` from there.

## `uninstall.sh` didn't remove my custom agent

Correct — it only removes the 15 known core/extended agents by name. Anything in `.claude/agents/custom/` is yours; delete it yourself if you want it gone. Same logic for `.thekedar/` — uninstall keeps it (it's your project history), you decide if it's worth keeping.

## Windows

Use Git Bash or WSL — every hook and script here is bash. Native PowerShell hook variants are on the roadmap (F-tracked), not yet shipped.

## Still stuck

`bash .thekedar/scripts/doctor.sh` first, always — it catches the large majority of "is something actually wrong" questions in one command. If doctor is fully green and you're still seeing a problem, it's likely a Claude Code platform behavior rather than a Thekedar file/hook issue — check the Claude Code docs or open an issue with the doctor output attached.
