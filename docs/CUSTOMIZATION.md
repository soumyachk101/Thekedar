# Customization

## Config: `.thekedar/config.md`

Plain `key: value` lines. `#` starts a trailing comment. A missing file, or a missing key within an existing file, falls back to the default — you only need to write the keys you want to change.

```
fix_loop_cap: 3                      # max doer fix attempts before BLOCKED + human escalation
auto_continue: true                  # false = pause for user approval between tasks
default_doer_model: sonnet           # model for doer agents unless an agent file overrides
enable_performance_auditor: false    # true = performance-auditor gates every task (or tag a task `perf`)
enable_accessibility_auditor: false  # true = accessibility-auditor gates every task (or tag a task `a11y`)
scope_guard: on                      # off = advisory only (miss logged to ledger, never blocked)
commit_prefix: "thekedar"            # commit message prefix: <prefix>(task-NNN): <title>
```

### Common tweaks

**"The fix loop gives up too fast on hard bugs."** Raise `fix_loop_cap` to 5–6. Cost: more tokens burned per stuck task before you see the raw report.

**"I want to approve every task manually."** Set `auto_continue: false`. The orchestrator stops after every LOG+CHECKPOINT and waits for your go-ahead instead of rolling to the next TODO task automatically.

**"scope-guard is blocking legitimate work too often."** First choice: teach the doer to declare `## Scope addition` entries (that's the intended mechanism, not a bug). If it's still too strict for how you work, set `scope_guard: off` — misses get logged to the ledger as `scope-advisory` lines instead of blocked, so you keep visibility without the friction.

**"Every task should get a performance/accessibility pass."** Flip `enable_performance_auditor` / `enable_accessibility_auditor` to `true`. Costs one extra gate invocation per task either way; per-task opt-in via a `perf`/`a11y` tag on individual tasks is cheaper if only some tasks need it.

**"Our commit convention isn't `thekedar(task-NNN): ...`."** Change `commit_prefix`. Note: this is presentation only — the changelog/task-file contracts don't change.

## Adding a custom agent

```
bash .thekedar/scripts/new-agent.sh db-migrator --doer --model sonnet
bash .thekedar/scripts/new-agent.sh license-auditor --gate --model haiku
```

Scaffolds `.claude/agents/custom/<name>.md` from `templates/agent-template.md` with the tool allowlist pre-applied:
- `--doer` → `Read, Write, Edit, Bash, Grep, Glob`
- `--gate` → `Read, Grep, Glob, Bash` (no Write/Edit — the read-only guarantee is structural, keep it that way)

Then hand-edit the scaffold: replace `{{TRIGGER}}` in the description (this is what drives auto-delegation — write it as "MUST BE USED when...", not a bio) and fill in the `<placeholders>` in the Process/Rules sections. **Restart your Claude Code session** — agents load at session start. The orchestrator's routing is description-driven, so a well-written trigger is enough; no registry file to update.

Naming rule: kebab-case, globally unique across `core/`, `extended/`, and `custom/` — `new-agent.sh` refuses collisions and invalid names.

## Swapping models

Two levers, pick based on scope:
- **One agent:** edit its frontmatter `model:` line directly (`sonnet` / `haiku` / `opus` / `inherit`).
- **Project-wide intent:** set `default_doer_model` in `config.md` — this documents the intent for anyone reading the config, but the actual per-agent model still comes from that agent's frontmatter. Update both together if you want the change to actually take effect across all doers.

## Disabling reviewers

- **The whole extended set:** don't install with `--full`, or `bash uninstall.sh` then reinstall without the flag.
- **One extended gate:** delete its file from `.claude/agents/extended/` (or move it out) and restart the session. `error-checker` and `security-auditor` are core — removing them isn't supported; they're the two non-negotiable gates every task passes through.
- **The two conditional auditors:** their `enable_*` config flags default `false` — they're opt-in, not opt-out.

## For prototyping / throwaway scripts

Thekedar is explicitly not for everything (see FAQ.md). For a genuinely disposable script, just... don't invoke the workflow — ask directly and the orchestrator's own triage rule skips ceremony for trivial asks. For a slightly bigger throwaway you still want *some* speed on: `auto_continue: true` (default) + skip `--full` (core crew only, fewer gate round-trips) gets you the fastest orchestrated path.

## Monorepos

Thekedar has no built-in multi-package awareness in v2 — `.thekedar/` and `.claude/` live at whatever directory you run `install.sh` from, and task/Expected-files paths are relative to that root. For a monorepo, install at the repo root and let task files scope to `packages/<name>/...` paths; scope-guard and drift-check work on those paths exactly the same way. Running fully independent Thekedar instances per package (separate `.thekedar/` in each) is possible but untested — each would need its own git checkpoint discipline to not fight over commits.
