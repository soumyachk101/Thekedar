# Review checklist — frontend / UI

> What to check when reviewing UI code beyond accessibility (which has its own
> checklist): correctness, states, consistency, and responsiveness.

Cited by: `frontend-reviewer`. Related: `review-checklists/accessibility.md`,
`pitfalls/react.md`.

## Correctness

- [ ] State updates **replace**, not mutate (`setItems([...items, x])`, not
      `items.push`) — mutation may not re-render (see `pitfalls/react.md`).
- [ ] Effects have correct dependencies (no stale values, no missing deps the
      lint rule flags); effects clean up subscriptions/timers/listeners.
- [ ] Hooks called unconditionally, top-level (rules of hooks).
- [ ] Lists have **stable keys** (not array index when the list reorders).
- [ ] No race on async UI (a slow response overwriting a newer one; cancel or
      guard stale responses).

## The three states (every async UI)

- [ ] **Loading** state while data is in flight.
- [ ] **Error** state when the call fails (network / 5xx) — a visible message,
      not a blank screen or a silent failure.
- [ ] **Empty** state when there's no data ("No items yet"), distinct from loading.

## Consistency with the design system

- [ ] Reuses existing components / tokens / spacing rather than inventing a
      parallel one-off. A new one-off where a system component exists is a finding.
- [ ] Follows the project's styling approach (CSS modules / Tailwind / styled) and
      naming, not a new style imported wholesale.

## Responsiveness

- [ ] No fixed pixel widths where the codebase is fluid; usable at small
      (~375px) widths without horizontal scroll.
- [ ] Overflow handled (long text, wide tables scroll in their own container).
- [ ] Touch targets adequately sized.

## Security (client side)

- [ ] No secrets/API keys in client code or the bundle (see `security/secrets-
      patterns.md`).
- [ ] User content rendered as text, or sanitized — no `dangerouslySetInnerHTML`
      / `v-html` with unsanitized input (XSS, see `owasp/a03-injection.md`).
- [ ] Authorization not enforced only in the UI (the API must re-check; hiding a
      button is not access control).

## Performance smells

- [ ] New object/array/function props each render defeating `memo`.
- [ ] Heavy work in render; unvirtualized large lists (see performance checklist).

## Rating

- **CRITICAL** = broken (crash on empty state, unusable on keyboard, XSS, data
  loss). **Taste** ("I'd style it differently") is INFO, never a blocker.

## Verify

- Loading / error / empty states all present and distinct.
- No state mutation; lists keyed; effects clean up; no client secrets or XSS sink.
- Reuses the design system; usable at mobile width.
