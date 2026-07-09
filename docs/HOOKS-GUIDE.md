# Hooks Guide — the 5 hooks

All hooks live in `.claude/hooks/*.sh`, pure bash, zero required dependencies (`jq`/`python3` used if present, with a further grep fallback on the two guards' path/file parsing). Wired in `.claude/settings.json`, merged there by `install.sh` — never hand-edit that wiring; re-run the installer if it's missing.

| Hook | Event | Matcher | Can it block? | Budget |
|---|---|---|---|---|
| `session-brief.sh` | `SessionStart` | — | No — always exit 0 | n/a (one-shot at start) |
| `scope-guard.sh` | `PreToolUse` | `Write\|Edit\|MultiEdit` | **Yes** — exit 2 on confirmed out-of-scope | < 50 ms |
| `secret-guard.sh` | `PreToolUse` | `Write\|Edit\|MultiEdit` | **Yes** — exit 2 on confirmed secret pattern | < 50 ms |
| `munshi.sh` | `PostToolUse` | `Write\|Edit\|MultiEdit` | No — always exit 0 | < 50 ms |
| `drift-check.sh` | *(not a hook event)* | called by the orchestrator at task end | No — always exit 0 | — |

## session-brief.sh

**I/O:** no stdin needed; reads `.thekedar/PROJECT_STATE.md` from `$CLAUDE_PROJECT_DIR`. Writes to **stdout**, which Claude Code injects into the new session's context automatically.

**Output shape:**
```
=== THEKEDAR SESSION BRIEF (auto-injected by session-brief.sh) ===
<first 8000 bytes of PROJECT_STATE.md>
ACTIVE task file: .thekedar/tasks/013-reset-request-endpoint.md
Latest changelog: .thekedar/changes/task-012.md
=== END BRIEF — say "continue" to resume via the thekedar workflow ===
```
No `PROJECT_STATE.md` → silent, no output, exit 0.

**Disable:** remove its entry from `settings.json`'s `SessionStart` array, or delete `.thekedar/PROJECT_STATE.md` (loses the resume benefit).

## scope-guard.sh

**I/O:** stdin = the PreToolUse event JSON; reads `tool_input.file_path`. No stdout on allow; **stderr** on block (exit 2) — Claude Code shows this to the model as the reason its tool call failed.

**Exit codes:** `0` = allowed (includes: no task system, no ACTIVE task, path matches the allowlist, path under `.thekedar/**`, or advisory mode). `2` = blocked (a confirmed out-of-scope write while a task is ACTIVE and `scope_guard` is not `off`).

**Block message:**
```
SCOPE-GUARD: <path> is outside task NNN's declared files. Either add a
"## Scope addition" entry (file + one-line reason) to the task file first,
or leave this file alone.
```

**Disable:** set `scope_guard: off` in `.thekedar/config.md` for advisory-only (logs a `scope-advisory` ledger line instead of blocking), or remove its `PreToolUse` entry from `settings.json` to disable entirely.

## secret-guard.sh

**I/O:** stdin = the PreToolUse event JSON; reads `tool_input.content` / `.new_string` / `.edits[].new_string` — never `old_string`, never the raw event (both would false-positive). Requires jq or python3 to isolate content safely; without either, fails open.

**Exit codes:** `0` = allowed (clean content, excluded path, or content isolation unavailable). `2` = blocked (a high-confidence pattern matched in content being written).

**Patterns:** AWS access key, PEM private key block, JWT, GitHub PAT (classic + fine-grained), Slack token, Stripe live secret key, Anthropic API key, Google API key.

**Path exclusions:** `.thekedar/**`, `**/fixtures/**`, `**/__mocks__/**`, `*.sample`, `*.example`, `*.template`.

**Disable:** remove its `PreToolUse` entry from `settings.json`. There is no advisory mode by design — a secret write is never "log it and continue."

## munshi.sh

**I/O:** stdin = the PostToolUse event JSON; reads `tool_name` + `tool_input.file_path`. Writes to `.thekedar/changes/ledger-YYYY-MM-DD.md`.

**Output format:**
```
| Time | Tool | File |
|------|------|------|
| 14:02:11 | Edit | src/auth/login.ts |
```

**Exit codes:** always `0`, unconditionally — every failure path (missing dir, unparseable JSON, read-only filesystem) is swallowed.

**Disable:** remove its `PostToolUse` entry from `settings.json`. You lose the per-edit ledger; task changelogs are unaffected.

## drift-check.sh

Not a Claude Code hook — a plain script the orchestrator invokes explicitly:

```
bash .claude/hooks/drift-check.sh .thekedar/tasks/NNN-slug.md
```

**Output:** one line, always:
```
DRIFT: none — 3 changed file(s), all within declared scope
DRIFT: 2 file(s) outside declared scope: src/a.ts, src/b.ts
DRIFT: n/a — <task file not found | git unavailable | not a repository>
```

This line is copied verbatim into the task's changelog. Compares `git status --porcelain` (excluding `.thekedar/**`) against the same Expected-files/Scope-addition allowlist scope-guard uses — so it audits everything scope-guard's advisory mode chose not to block, plus anything committed by a route that bypassed the guard entirely (e.g. hooks disabled).

**Disable:** nothing to disable — it's just a script; stop calling it if you don't want the changelog line (not recommended, it's the honesty check).

## Fixture tests

Every hook has a dedicated suite in `tests/test-<hook>.sh`, run via `tests/run-all.sh`. Each asserts: valid input behaves correctly, malformed/empty/oversized input fails open (or the guard's designed block still fires only on a genuine match), and permission-denied writes don't escalate to a blocked session. See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) if a hook misbehaves in practice.
