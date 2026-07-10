# Pitfalls — Python

> AI-hallucination traps specific to Python: Python-2-isms that still get
> emitted, invented stdlib, and the language's own footguns.

Cited by: `backend-dev`, `db-specialist`, `error-checker`.

## Python 2 leftovers (still emitted from training data)

- **Wrong**: `print "x"` · `except Exception, e:` · `xrange()` · `dict.has_key(k)`
  · `raw_input()` · `mydict.iteritems()`
- **Right**: `print("x")` · `except Exception as e:` · `range()` · `k in d`
  · `input()` · `d.items()`
- Verify: the file targets Python 3 (it does); a linter (ruff/flake8) flags these.

## Mutable default arguments (the classic)

- **Wrong**: `def add(item, bucket=[]): bucket.append(item); return bucket` — the
  default list is created once and shared across calls, accumulating forever.
- **Right**: `def add(item, bucket=None): bucket = [] if bucket is None else bucket`
- Same trap with `={}` and any mutable default.

## Invented stdlib / wrong module paths

- No `list.contains()` — use `x in list`. No `str.contains()` — use `in` or
  `.find()`. No `os.path.exists_dir` — it's `os.path.isdir`.
- **Wrong**: `from collections import OrderedDict` then treating a plain dict as
  unordered (dicts are insertion-ordered since 3.7).
- Verify: if it's not in the official stdlib docs, it doesn't exist.

## async/await confusion

- **Wrong**: calling an `async def` without `await` (returns a coroutine, does
  nothing) · mixing `asyncio.get_event_loop().run_until_complete()` (legacy)
  with `asyncio.run()` in the same code.
- **Right**: `await coro()` inside async; `asyncio.run(main())` at the top level
  (3.7+). Don't call `asyncio.run()` from inside a running loop.
- Blocking calls (requests, time.sleep, sync DB drivers) inside async handlers
  stall the loop — use async libraries or run in an executor.

## Type & equality footguns

- `is` vs `==`: `is` compares identity, not value. `x is None` is correct;
  `x is 0` / `x is "s"` is a bug (works by CPython interning accident).
- Truthiness: `if not x` is true for `0`, `""`, `[]`, `None` — often not what's
  meant. Use `if x is None` when you mean None.
- Integer division `/` vs `//`; `/` is float division in Python 3.

## Packaging & imports

- Relative-import confusion (`from .mod import x` only works inside a package).
- Invented pip package names — verify on PyPI; slopsquatting risk.
- `requirements.txt` unpinned vs `poetry.lock`/`Pipfile.lock` — mirror what the
  project uses; don't introduce a second tool.

## Modern idioms to prefer (mirror the codebase first)

- `pathlib.Path` over string `os.path` munging (if the project already uses it).
- f-strings over `%`/`.format()` (Python 3.6+). Walrus `:=` where it clarifies.
- `dataclasses` / `pydantic` per the project's convention, not invented.

## Verify

- ruff/flake8 + mypy (if configured) pass on the change.
- No Python-2 syntax; no mutable default args; no un-awaited coroutines.
- Every import resolves against an installed, real package.
