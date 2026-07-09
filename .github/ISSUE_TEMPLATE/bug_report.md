---
name: Bug report
about: Something in the workflow, a hook, or the installer misbehaved
title: ""
labels: bug
---

## What happened

<Plain description. Include the exact command/message if a hook blocked something.>

## Expected

<What should have happened instead.>

## Environment

- OS: <macOS / Linux / WSL / Git Bash>
- Claude Code version: <output of `claude --version` if available>
- `jq` present? <yes/no> · `python3` present? <yes/no>
- Thekedar install mode: <core / --full>

## Doctor output

<!-- Run this first — it catches most issues on its own: -->
```
$ bash .thekedar/scripts/doctor.sh
<paste output here>
```

## Steps to reproduce

1.
2.
3.

## Anything else

<Ledger/changelog excerpts, task file content, whatever's relevant. Redact secrets.>
