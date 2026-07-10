# Best practices — Angular

> Modern Angular (standalone components, signals, typed forms, RxJS discipline)
> the way the framework now steers you. Distinct from the JS pitfalls pack.

Cited by: `angular-specialist`. Related: `pitfalls/typescript-javascript.md`,
`review-checklists/frontend.md`.

## Architecture

- **Standalone components** for new code — drop NgModules where the codebase
  allows; import dependencies directly in `imports:`. Match existing structure if
  it's still module-based.
- Feature-first folders; lazy-load feature routes (`loadComponent`/`loadChildren`)
  to keep the initial bundle small.
- Smart (container) vs. presentational split: containers wire services + state,
  presentational components take inputs and emit outputs, use `OnPush`.

## Change detection & signals

- **`ChangeDetectionStrategy.OnPush` by default** — it forces immutable-in,
  event-out data flow and cuts needless checks.
- Prefer **signals** for component state (`signal`, `computed`, `effect`); they
  integrate with OnPush and reduce manual `markForCheck`. Use `toSignal`/
  `toObservable` at the RxJS boundary.
- Avoid function calls in templates (they run every CD cycle) — bind signals or
  memoized values.

## RxJS discipline

- **Unsubscribe or the subscription leaks**: use the `async` pipe (auto-unsub),
  `takeUntilDestroyed()`, or `toSignal`. Manual `.subscribe()` without teardown
  is a finding.
- Compose with operators (`switchMap` to cancel stale requests, `combineLatest`,
  `debounceTime`) instead of nested subscribes. `switchMap` for
  cancel-previous (typeahead), `concatMap` for ordered, `mergeMap` for parallel.
- Keep streams declarative in the component; do side effects in `tap`/`effect`,
  not scattered subscribes.

## Dependency injection

- `providedIn: 'root'` for singletons; provide at the component/route level for
  scoped instances. Use the `inject()` function in modern code.
- Program to abstractions via `InjectionToken` where you need swappable impls;
  don't `new` a service.

## Forms

- **Typed reactive forms** for anything non-trivial — validation, dynamic
  fields, cross-field rules. Template-driven only for the simplest cases.
- Centralize validators; show errors on touched/dirty; disable submit on invalid.

## HTTP & data

- Use `HttpClient` with typed responses and interceptors for auth headers,
  errors, and retries; never hand-build fetch with manual token handling.
- Handle loading/error/empty states explicitly (`review-checklists/frontend.md`).
- Cancel in-flight requests via `switchMap` on rapidly-changing inputs.

## Templates & security

- Angular escapes interpolation by default — don't bypass with
  `bypassSecurityTrustHtml` on untrusted data (XSS). Use the built-in sanitizer.
- Track `@for` with a stable id (`track item.id`) in the new control-flow syntax.

## Performance

- `OnPush` + immutable updates + `trackBy`/`track`; lazy routes; `NgOptimizedImage`.
- Defer non-critical content with `@defer` blocks.

## Testing

- `TestBed` for components with DI; test through the DOM (Testing Library /
  harnesses) and marble-test complex streams; mock HTTP with
  `HttpTestingController`.
