# Security Policy

## Reporting a vulnerability

Open a [private security advisory](https://github.com/soumyachk101/Thekedar/security/advisories/new) on this repository rather than a public issue. Include: what you found, the affected file(s) (hook, script, or agent prompt), reproduction steps, and impact. Expect an initial response within a few days.

Please don't open a public issue for anything that could be actively exploited against someone running Thekedar before a fix ships (e.g. a way to make a guard hook fail open when it shouldn't, or a command-injection path in any script).

## What's in scope

- `hooks/*.sh` — especially anything that would make `scope-guard.sh` or `secret-guard.sh` fail to block a write they're supposed to block, or make any hook execute attacker-controlled input
- `install.sh` / `uninstall.sh` / `update.sh` — anything that writes outside the intended project directory, or that mishandles `settings.json` in a way that could inject arbitrary commands
- `scripts/*.sh` — the same class of issue: path handling, command construction, anything fed attacker-controlled strings
- Agent prompts (`.claude/agents/*.md`) that could be tricked into exfiltrating secrets, running destructive commands, or bypassing the "reviewers are read-only" guarantee

## What munshi and the guard hooks can and cannot touch

**Can:** read the PreToolUse/PostToolUse event JSON from stdin; read files under the project directory to check task scope; append to `.thekedar/changes/*.md`; read `.thekedar/config.md`.

**Cannot, by design:** make network calls (none of the 5 hooks contain any), run `eval` on stdin content, write outside `.thekedar/` and the file the triggering tool call already targets, or escalate privileges beyond the user's own shell session — every hook runs with exactly the user's permissions, nothing more.

**Guarantee boundaries:** `munshi.sh`, `session-brief.sh`, and `drift-check.sh` always exit 0 — a bug in them can cause a missing log line or brief, never a blocked session. `scope-guard.sh` and `secret-guard.sh` can exit 2, but only on a positive, confirmed match; every parse failure or missing dependency makes them fail open (exit 0) rather than guess. See [ADR-0002](docs/adr/0002-hooks-never-block-except-guards.md) for the full reasoning. A vulnerability report that scope-guard or secret-guard fails to block something they should is valid and welcome — but note that both are a defense-in-depth layer, not the only one; `security-auditor` and human review remain necessary.

## Threat model — what the guards are, and are NOT

`scope-guard.sh` and `secret-guard.sh` reduce the chance that the **model's own file-edit tool calls** (Write/Edit/MultiEdit) drift out of the active task's scope or commit an obvious secret. That is their job, and within it they are held to a real bar (the two pre-2.0.0 path-traversal bypasses found in the release audit — raw `..` and glob-expansion — were treated as blockers and fixed).

They are **not** a sandbox against a hostile or prompt-injected agent that has the `Bash` tool. Two explicit non-goals, both consequences of the same fact — Bash is intentionally ungated (doers need it to run tests and builds):

1. **Shell writes are unguarded.** An agent that can run Bash can write anywhere already (`echo secret > /etc/…`, `cp`, `dd`) without ever touching Write/Edit. The guards do not, and cannot, constrain that.
2. **Symlinks are not resolved.** Path matching is lexical (no `realpath`/`readlink -f` — required so the guards work on not-yet-created targets, portably across macOS/Linux/WSL/Git Bash). If an in-scope path component is a symlink pointing outside the repo, a Write through it lands outside, and secret-guard likewise skips a secret written through a symlinked excluded path. Reaching that state requires **first creating the symlink** — a Bash call, i.e. the same already-unguarded capability from (1). We deliberately do not add symlink resolution: it would reintroduce filesystem dependence and portability/false-positive problems (legit monorepo symlinks) to close a door Bash already leaves open. See [ADR-0006](docs/adr/0006-scope-guard-as-pretooluse.md).

Bottom line: treat these guards as a seatbelt against the model's honest mistakes, not a cage around a malicious one. If you are running an untrusted agent against sensitive paths, the OS/container boundary — not a bash hook — is the control you want.

## Supported versions

Only the latest tagged release receives security fixes. This is a young project without a long-term-support branch policy yet.
