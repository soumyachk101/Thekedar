# Pitfalls — general AI coding traps

> The failure modes that show up regardless of language: an AI agent writing
> code that is *plausible and wrong*. This pack is the meta-checklist; the
> per-stack packs list the specific invented APIs. Nobody else ships this — it's
> the point of Thekedar's independent review.

Cited by: `backend-dev`, `frontend-dev`, `error-checker`. The doers read it to
avoid the traps; error-checker reads it to catch them.

## 1. Invented APIs and methods

Models complete to a method that *sounds* right but doesn't exist, because a
similar one exists in another language or library.

- **Wrong**: `myList.contains(x)` (JS/TS — no such method) → **Right**: `myList.includes(x)`
- **Wrong**: `myDict.has_key("k")` (Python 3 — removed) → **Right**: `"k" in myDict`
- **Wrong**: `str.format()` invented kwargs, `array.remove(index)` in JS (no such method)
- **Verify**: if you can't point to the method in the official docs, it doesn't
  exist. Grep the codebase for prior usage; check the type/signature.

## 2. Hallucinated packages / imports

An import for a package that doesn't exist, or a submodule path that's wrong.
This is also a *security* risk: attackers register hallucinated package names
(slopsquatting).

- Never add a dependency you haven't verified exists on the registry with a real
  version. Check the manifest; check the import path against the installed lib.
- **Wrong**: `from datetime import timezone_utc` · **Right**: `from datetime import timezone`
- **Verify**: the package is already in the manifest, or the task explicitly
  allows adding it and it resolves to a real, maintained package.

## 3. Version confusion (mixing major versions)

Models blend v2 and v3 APIs of the same library because both are in training data.

- Mixing `openai` v0 (`openai.Completion.create`) with v1 (`client.chat.completions.create`).
- React class-component lifecycle mixed with hooks. Express 4 vs 5 middleware
  signatures. `react-router` v5 (`<Switch>`) vs v6 (`<Routes>`).
- **Verify**: check the installed version (manifest/lockfile) FIRST, then use
  only that version's API. When unsure, read the code already in the repo.

## 4. Deprecated patterns still emitted

Old patterns that are heavily represented in training data and still get written.

- `componentWillMount`, `componentWillReceiveProps` (React — unsafe/removed).
- `var` in JS, `== ` instead of `===`. Python 2 `print` statement, `xrange`.
- Callback pyramids where async/await exists. `moment.js` for new code.
- **Verify**: mirror the conventions already in the file; a linter catches most.

## 5. Confident wrong config / flags

Invented config keys, environment variables, or CLI flags that read plausibly.

- Making up a `tsconfig`/webpack/eslint option, a Docker instruction, or a CLI
  flag that doesn't exist.
- **Verify**: config keys must match the tool's documented schema; grep existing
  config; don't invent.

## 6. Copy-paste security regressions

Reintroducing a vulnerability while pattern-matching to a common (insecure) example.

- String-built SQL, `dangerouslySetInnerHTML`, disabled TLS verification, a
  hardcoded secret in an example — see the `security/` packs.
- **Verify**: run the change past the security checklist, not just "does it work."

## The habit that beats all six

Uncertainty means **check, not guess**: read the installed version, grep for
prior usage, open the manifest, consult the official docs (or the matching
pitfalls pack). A doer that verifies beats a doer that pattern-completes.
