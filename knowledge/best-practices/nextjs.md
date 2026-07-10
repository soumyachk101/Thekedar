# Best practices — Next.js

> How to build on the App Router the way it's designed: server-first, cached
> deliberately, secrets on the server. Distinct from `pitfalls/react.md` — this
> is Next-specific architecture and data-flow guidance.

Cited by: `nextjs-specialist`. Related: `pitfalls/react.md`,
`patterns/caching-strategies.md`, `security/secrets-patterns.md`.

## Server vs. client components

- **Server components by default**; add `'use client'` only when you need
  interactivity, state, effects, or browser APIs. Push the boundary as far down
  the tree as possible — a client leaf, not a client page.
- **Never pass secrets or server-only data as props into a client component** —
  they ship to the browser. Fetch and use them in the server component; pass down
  only what the client legitimately needs.
- Keep heavy dependencies (markdown, date libs, ORMs) in server components so
  they stay out of the client bundle.

## Data fetching & mutations

- Fetch in server components with `async`/`await` directly; parallelize
  independent fetches (`Promise.all`) to avoid request waterfalls.
- **Mutations via Server Actions or Route Handlers**, not client-side writes with
  exposed credentials. Validate + authorize inside the action — it's a public
  endpoint even when called from your own form.
- Revalidate precisely after a mutation: `revalidatePath`/`revalidateTag`, not a
  full-app bust.

## Caching (know which layer you're in)

- App Router caches at several layers (request memoization, Data Cache, Full
  Route Cache, Router Cache). Be explicit: `fetch(..., { next: { revalidate }})`
  or `cache: 'no-store'` for per-request data (`patterns/caching-strategies.md`).
- Mark dynamic data dynamic — an accidentally static route serving per-user data
  is a correctness AND privacy bug. Use `revalidate`/`dynamic` intentionally.
- Tag cached data (`next: { tags }`) so mutations can invalidate exactly what
  changed.

## Routing & rendering

- Use the file conventions: `loading.tsx` (Suspense boundary), `error.tsx`
  (error boundary), `not-found.tsx`, `layout.tsx` for shared shells. Don't
  hand-roll what the router gives you.
- Stream with Suspense to send the shell fast and fill slots as data arrives.
- Choose SSG/ISR for shareable/cacheable pages, SSR for per-request, client
  fetch only for truly interactive/private-after-load data.

## Environment & secrets

- Only `NEXT_PUBLIC_`-prefixed env vars reach the browser — everything else is
  server-only. Never prefix a secret with `NEXT_PUBLIC_`
  (`security/secrets-patterns.md`). The secret-guard hook blocks obvious leaks;
  don't rely on it as the only line.
- Access secrets in server components / actions / route handlers only.

## Images, fonts, performance

- `next/image` for automatic sizing/lazy-loading; `next/font` to self-host fonts
  and kill layout shift.
- Analyze the bundle (`@next/bundle-analyzer`); keep client components lean.
- Set `metadata`/`generateMetadata` for SEO and social cards.

## API routes / route handlers

- Validate input, authenticate, and authorize in every handler — treat it as a
  public API. Return correct status codes and a consistent error shape.
- Keep handlers thin; put business logic in shared server modules reused by both
  actions and handlers.

## Testing

- Unit-test server logic as plain async functions; e2e the routes (Playwright)
  since so much behavior is the framework's rendering + caching, not your code.
