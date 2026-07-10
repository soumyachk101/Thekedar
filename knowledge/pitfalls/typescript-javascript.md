# Pitfalls — TypeScript / JavaScript

> AI-hallucination traps specific to TS/JS: invented Array/String methods, type-
> system escape hatches, and async footguns.

Cited by: `backend-dev`, `frontend-dev`, `error-checker`.

## Invented Array / String / Object methods

- **No** `Array.prototype.contains` → use `.includes(x)`.
- **No** `Array.prototype.remove(i)` → use `.splice(i, 1)` or `.filter(...)`.
- **No** `String.prototype.format` → template literals `` `${x}` ``.
- **No** `Object.prototype.forEach` → `Object.entries(o).forEach(...)`.
- `.includes` exists on Array and String (ES2016+); confirm the target supports it.
- Verify: if MDN doesn't list the method, it doesn't exist.

## Equality and truthiness

- `==` does type coercion (`0 == ""` is true, `null == undefined` is true).
  Use `===`/`!==` except the deliberate `== null` (matches null AND undefined).
- Falsy values `0`, `""`, `NaN`, `null`, `undefined`, `false` all fail `if (x)`
  — a bug when `0` or `""` is valid. Prefer `if (x == null)` / explicit checks.
- `??` (nullish) vs `||`: `0 || 5` is `5` (bug if 0 is valid); `0 ?? 5` is `0`.

## Async footguns

- **Forgotten await**: `const u = getUser()` where `getUser` is async returns a
  Promise, not the user. `if (getUser())` is always truthy.
- `forEach` does NOT await: `arr.forEach(async x => await f(x))` runs them
  unawaited. Use `for...of` with `await`, or `await Promise.all(arr.map(...))`.
- Unhandled rejections: every `await` in a path that can throw needs a
  `try/catch` or a caller that handles it.
- Mixing `.then()` chains with `await` in a way that drops errors.

## TypeScript-specific

- **`as any` / `as unknown as T`**: escape hatches that disable the checker;
  each one is a place a runtime bug hides. Flag overuse.
- **Non-null `!`**: `user!.name` asserts non-null without proof — crashes if
  wrong. Prefer a real check.
- `interface` vs `type`: mostly interchangeable; don't rewrite one to the other
  for no reason. `enum` has runtime cost and quirks — const unions often better.
- `namespace` / triple-slash directives — legacy; modules are the norm.
- Trusting `any` from `JSON.parse` / `res.json()` — validate at the boundary
  (zod/io-ts per project), don't assume the shape.

## Version / ecosystem confusion

- ESM vs CommonJS: `import` vs `require`, `"type": "module"`, `.mjs`/`.cjs` —
  mirror the project's module system; mixing them breaks the build.
- `react-router` v5 `<Switch>` vs v6 `<Routes>`; Express 4 vs 5; `node:`-prefixed
  builtins. Check installed versions before using an API.
- Node vs browser globals (`process`, `Buffer` vs `window`, `document`).

## Deprecated / discouraged

- `var` → `const`/`let`. `arguments` object → rest params. `moment.js` for new
  code → `Temporal`/`date-fns`/`Intl`. `==` → `===`.

## Verify

- `tsc --noEmit` and eslint pass; no new `as any`/`!` without justification.
- Every `async` call in the diff is awaited or deliberately fire-and-forget.
- Module system and library versions match the project's manifest.
