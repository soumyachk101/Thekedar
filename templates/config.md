# Thekedar config

> Lives at `.thekedar/config.md`. Parsed as plain `key: value` lines;
> everything after `#` on a line is a comment. Missing file or missing
> key = the default shown here. Keep it boring.

fix_loop_cap: 3                      # max doer fix attempts before BLOCKED + human escalation
auto_continue: true                  # false = pause for user approval between tasks
default_doer_model: sonnet           # model for doer agents unless an agent file overrides
enable_performance_auditor: false    # true = performance-auditor gates every task (or tag a task `perf`)
enable_accessibility_auditor: false  # true = accessibility-auditor gates every task (or tag a task `a11y`)
scope_guard: on                      # off = advisory only (miss logged to ledger, never blocked)
commit_prefix: "thekedar"            # commit message prefix: <prefix>(task-NNN): <title>
