# Thekedar

Full plan -> build -> review -> log workflow.

When invoked:

1. Read the `$thekedar` skill if available.
2. If `.thekedar/` is missing, create the standard task/state directories from the installed templates.
3. For a multi-step goal, write scoped task files before implementation.
4. Delegate implementation to the most specific available custom agent.
5. Run correctness and security review gates before marking a task done.
6. Write changelog and project state updates after each task.

For trivial single-file work, skip Thekedar ceremony and say `[thekedar: skipped - trivial]`.
