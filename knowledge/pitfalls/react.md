# Pitfalls — React

> AI-hallucination traps specific to React: deprecated lifecycle methods still
> emitted, hook rule violations, and state/effect footguns.

Cited by: `frontend-dev`, `error-checker`. Related: `owasp/a03-injection.md`
(XSS via `dangerouslySetInnerHTML`).

## Deprecated / removed lifecycle (still emitted from training data)

- **Wrong**: `componentWillMount`, `componentWillReceiveProps`,
  `componentWillUpdate` — legacy/unsafe, removed or `UNSAFE_`-prefixed.
- **Right**: hooks (`useEffect`, `useMemo`) in function components, or the
  modern class lifecycle (`getDerivedStateFromProps`, `componentDidMount`).
- Don't mix legacy class patterns into a hooks codebase; mirror what's there.

## Hook rules (violations cause real, subtle bugs)

- **Never call hooks conditionally or in loops** — `if (x) useEffect(...)`
  breaks the hook order across renders. Hooks run top-level, same order, always.
- Only call hooks from components or other hooks, never plain functions.
- Verify: `eslint-plugin-react-hooks` catches these; ensure it runs.

## useEffect dependency traps

- **Missing deps**: an effect using `props.id` without `[props.id]` uses a stale
  value. The exhaustive-deps lint rule flags it — don't silence it blindly.
- **Object/array/function deps recreated each render** cause the effect to run
  every render (infinite loops if it sets state). Memoize with `useMemo`/
  `useCallback`, or move the value out.
- **Missing cleanup**: subscriptions/timers/listeners started in an effect must
  be torn down in its return, or they leak and double up.

## State footguns

- **Mutating state**: `state.items.push(x); setItems(state.items)` — React may
  not re-render (same reference). Always replace: `setItems([...items, x])`.
- **Stale closures**: `setCount(count + 1)` twice in one handler adds 1, not 2.
  Use the updater form: `setCount(c => c + 1)`.
- **Derived state in state**: copying a prop into state and not updating it —
  compute during render or use the key/effect pattern deliberately.

## Rendering

- **Missing `key`** on list items, or `key={index}` when the list reorders —
  causes wrong reconciliation and lost input state. Use a stable id.
- **`dangerouslySetInnerHTML`** with unsanitized content = XSS. Render text, or
  sanitize with DOMPurify (see A03).
- Not handling loading / error / empty states — a fetch UI needs all three.

## Version / ecosystem confusion

- `react-router` v5 (`<Switch>`, `useHistory`) vs v6 (`<Routes>`, `useNavigate`).
- Old Context API (`contextTypes`) vs `createContext`/`useContext`.
- Redux classic (`connect`) vs Redux Toolkit (`createSlice`) — mirror the project.
- React 18 concurrent features / `useId` / automatic batching — check the version.

## Performance smells (frontend-reviewer will flag)

- New object/array/function props each render defeating `React.memo`.
- Heavy work in render instead of `useMemo`. Unvirtualized large lists.

## Verify

- `eslint-plugin-react-hooks` (rules-of-hooks + exhaustive-deps) passes.
- No deprecated lifecycle; no state mutation; lists have stable keys.
- Effects clean up; loading/error/empty states handled.
