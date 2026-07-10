# Best practices — Vue

> Building with the Composition API and Vue 3's reactivity the way the ecosystem
> recommends: reactive-by-intent, composables for reuse, Pinia for shared state.

Cited by: `vue-specialist`. Related: `pitfalls/typescript-javascript.md`,
`review-checklists/frontend.md`.

## Composition API & reactivity

- **`<script setup>` + Composition API** for new components — better type
  inference and logic reuse than Options API. Match the existing codebase if it's
  Options-based; don't mix styles within one component.
- **`ref` for primitives, `reactive` for objects** — but prefer `ref`
  consistently to avoid reactivity-loss when destructuring. Never destructure a
  `reactive` object (it breaks reactivity); use `toRefs` if you must.
- **`computed` for derived state**, not a `watch` that writes another ref.
  Computeds are cached and declarative; watchers are for side effects.
- Keep `watch`/`watchEffect` for actual side effects (fetching, DOM, logging).
  Specify sources explicitly; use `{ immediate }`/`{ deep }` intentionally.

## Composables (the reuse unit)

- Extract reusable stateful logic into `useXxx()` composables that return refs +
  functions. This is Vue's answer to mixins — no name collisions, explicit deps.
- A composable owns its lifecycle: register `onMounted`/`onUnmounted` inside it
  and clean up (listeners, intervals, subscriptions).
- Keep composables pure of component specifics; pass inputs as args/refs.

## Component design

- Props down, events up: type props (`defineProps<T>()`), emit typed events
  (`defineEmits`). Don't mutate props — emit and let the parent own the state.
- Use `v-model` with the modern `defineModel()` for two-way binding.
- Prefer slots for composition over prop-driven conditional rendering.
- Stable `:key` on `v-for` (a domain id, not index) so the vDOM diffs correctly.

## State management (Pinia)

- **Pinia over Vuex** for new code — simpler, typed, devtools-friendly. One store
  per domain; keep stores small and focused.
- Getters for derived state, actions for mutations + async. Don't reach into
  another store's internals; call its actions.
- Keep server/cache state (remote data) separate from UI state; consider a query
  layer (`@tanstack/vue-query`) instead of stuffing fetch results into Pinia.

## Performance

- `v-once`/`v-memo` for expensive static subtrees; `shallowRef`/`shallowReactive`
  for large structures you replace wholesale rather than mutate deeply.
- Lazy-load routes and heavy components (`defineAsyncComponent`).
- Avoid `v-if` + `v-for` on the same element; filter in a computed instead.

## Templates & rendering

- Keep template expressions trivial — move logic into computeds/methods.
- Guard against XSS: never `v-html` untrusted content (`pitfalls` / OWASP A03).
- Use `<Suspense>` for async setup + a fallback; handle error states explicitly
  (`review-checklists/frontend.md`).

## Testing

- Vue Test Utils + Testing Library: mount, interact by role/text, assert on
  rendered output and emitted events — not internal refs.
- Test composables in isolation as plain functions where they don't need a
  component context.
