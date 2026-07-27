---
description: Thekedar workflow discipline for scoped AI coding work.
alwaysApply: false
---

Use Thekedar for non-trivial coding work. For any request bigger than one file or roughly 30 lines, follow the same loop every time:

1. Plan into `.thekedar/tasks/NNN-slug.md`.
2. Mark exactly one task `ACTIVE`.
3. Implement only files declared in `## Expected files`; if another file is genuinely needed, append a `## Scope addition` entry before editing it.
4. Review as independent gates: correctness first, security second, UI/accessibility/dependency gates when relevant.
5. Write `.thekedar/changes/task-NNN.md`, update `.thekedar/PROJECT_STATE.md`, and make a git checkpoint.

For Antigravity, prefer the installed custom agents in `.agents/agents/` when delegating with `invoke_subagent`. If a matching specialist exists, use it instead of a generic doer.
