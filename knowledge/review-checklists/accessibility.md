# Review checklist — accessibility (WCAG 2.1 AA)

> What to check when reviewing UI for accessibility. Each finding should name the
> user who's locked out and the flow that breaks — not just a missing attribute.

Cited by: `accessibility-auditor`, `frontend-reviewer`. Related: `pitfalls/react.md`.

## Keyboard

- [ ] Every interactive element is reachable AND operable by keyboard (Tab/Enter/
      Space/arrows as appropriate).
- [ ] Logical tab order; no keyboard traps (can you Tab out of every widget?).
- [ ] Visible focus indicator — not removed with `outline: none` and nothing else.
- [ ] Custom widgets (menus, dialogs, comboboxes) implement the expected keyboard
      interaction, not just mouse.

## Semantics & ARIA

- [ ] Native elements first: `<button>`, `<a>`, `<input>`, `<nav>` over `<div>`
      with `role` + handlers. Native gives keyboard + semantics for free.
- [ ] ARIA roles/states are correct and complete (`aria-expanded`,
      `aria-selected`, `aria-checked`) and updated as state changes.
- [ ] No ARIA that lies (a `role="button"` that isn't focusable/operable is worse
      than nothing).
- [ ] Headings are hierarchical and describe structure; landmarks used.

## Names, labels, text alternatives

- [ ] Every form input has an associated `<label>` (or `aria-label`).
- [ ] Icon-only buttons have an accessible name.
- [ ] Images have meaningful `alt`, or empty `alt=""` when decorative.
- [ ] Link text is meaningful out of context (not "click here").

## Focus management

- [ ] Modals trap focus while open and restore it to the trigger on close.
- [ ] Route changes move focus sensibly (to the new heading/main).
- [ ] Dynamically revealed/removed content manages focus, not left dangling.

## Announcements & feedback

- [ ] Async results and errors reach a live region (`aria-live`) so screen-reader
      users hear them.
- [ ] Form validation errors are associated with fields (`aria-describedby`),
      not conveyed by red color alone.

## Visual

- [ ] Meaning is not conveyed by color alone (add text/icon).
- [ ] Obvious contrast red flags (low-contrast text on background).
- [ ] Touch targets are adequately sized; text survives 200% zoom / reflow.
- [ ] Animations respect `prefers-reduced-motion`.

## Rating & honesty

- **CRITICAL** = a keyboard, screen-reader, or low-vision user cannot complete
  the flow the change built. Name the user and the broken step.
- State which checks are **code-verified** vs need a real browser / assistive
  tech (`UNVERIFIABLE`) — don't claim more certainty than the review method gives.

## Verify

- Keyboard-only walkthrough of the new flow works (or is flagged unverifiable).
- Every interactive element has a name; focus is managed; no color-only meaning.
