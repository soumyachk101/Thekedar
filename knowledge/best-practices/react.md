# Best practices — React

> Positive guidance for building React the way the ecosystem has settled on:
> composition, colocation, and honest data/effect handling. Distinct from
> `pitfalls/react.md` (which lists the traps) — this is what to do instead.

Cited by: `react-specialist`. Related: `pitfalls/react.md`,
`review-checklists/frontend.md`, `patterns/error-handling.md`.

## Component design

- **Composition over configuration**: build small components and compose them;
  pass `children` and slots instead of a growing pile of boolean props. A
  component with 8 boolean flags wants to be 3 components.
- **Presentational vs. container is a spectrum, not a law**: colocate state with
  the component that needs it; lift it only when two siblings truly share it.
  Premature lifting makes every change a top-down prop drill.
- **One responsibility per component**: if you can't name it without "and", split it.
- **Keys are identity, not index**: use a stable domain id for list keys so React
  reconciles correctly across reorders/inserts.

## State management

- **Derive, don't duplicate**: compute values from existing state/props during
  render instead of mirroring them into another `useState` that can drift.
- **Colocate first, globalize last**: reach for context or a store (Zustand,
  Redux Toolkit, Jotai) only when prop-passing genuinely hurts. Context is for
  low-frequency, wide values (theme, auth), not high-churn state — it re-renders
  every consumer.
- **Server state ≠ client state**: cache remote data with React Query/SWR/RSC,
  not `useEffect` + `useState`. You get caching, dedupe, retries, and
  loading/error states for free.
- **`useReducer` for multi-field, transition-heavy state**; `useState` for simple.

## Effects — the minimum

- **You probably don't need an effect**: for deriving data, formatting, or
  responding to an event, do it in render or in the handler. Effects are for
  synchronizing with an *external* system (DOM, subscription, network).
- **Every effect cleans up**: unsubscribe, abort fetches, clear timers in the
  returned function. An effect that subscribes without cleanup leaks.
- **Split effects by concern**: one effect per independent synchronization, not
  a mega-effect with a 6-item dep array.

## Data fetching

- Prefer the framework's data layer (RSC/loader) or a query library; handle the
  three states explicitly — loading, error, empty — every time
  (`review-checklists/frontend.md`).
- Abort in-flight requests on unmount / param change (`AbortController`) to avoid
  setting state on a gone component and to cancel stale responses.
- Co-locate the query with the component that renders it; avoid waterfalls by
  hoisting parallel fetches or prefetching.

## Performance (measure first)

- Pass stable references: memoize objects/arrays/callbacks passed to memoized
  children, or restructure so they aren't created in render.
- `React.memo` earns its place only when a component is expensive AND re-renders
  with equal props — don't wrap everything.
- Virtualize large lists (`react-window`/`@tanstack/virtual`); code-split routes
  with `lazy` + `Suspense`.
- Reach for the Profiler before optimizing; most "slow" is a missing key or an
  unstable context value, not a missing `useMemo`.

## Accessibility & forms

- Native elements first (`button`, `a`, `label`) before ARIA; wire labels to
  inputs; manage focus on route/modal changes.
- Controlled inputs for validation-heavy forms; uncontrolled + a form library
  (React Hook Form) when re-render cost matters.

## Testing

- Test behavior through the user's lens (React Testing Library): query by role/
  text, assert on outcomes, avoid asserting on internal state or snapshots of
  everything.
- Mock the network at the boundary (MSW), not individual functions.
