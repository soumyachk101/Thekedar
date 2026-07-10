# Pattern — Caching strategies

> How to cache without serving stale or wrong data. Caching is easy to add and
> hard to invalidate — the classic "two hard things" trap.

Cited by: `backend-dev`, `performance-auditor`. Related: `pitfalls/sql.md`
(N+1), `patterns/observability.md`.

## Problem

The same expensive work (a query, a computation, an upstream call) repeated per
request wastes resources; but a cache that returns stale data causes subtle,
hard-to-reproduce correctness bugs. Add a cache only where the same expensive
call is provably repeated.

## Approach — read strategies

- **Cache-aside (lazy)**: app checks cache; on miss, loads from source and
  populates. Most common. Handle the miss stampede (many concurrent misses) with
  a lock or single-flight.
- **Read-through**: the cache layer loads on miss transparently.
- **Write-through / write-behind**: writes go through the cache to the store
  (through = synchronous, behind = async/batched) — keeps cache warm, adds
  complexity.

## Invalidation (the hard part)

- **TTL**: expire after N seconds. Simplest; bounds staleness. Pick a TTL the
  data's freshness tolerates.
- **Explicit invalidation**: delete/update the key on write. Correct but easy to
  miss a path — every writer must invalidate.
- **Versioned keys**: include a version/updated-at in the key so a new write
  yields a new key and the old falls out.
- Prefer TTL + explicit invalidation together; never assume "it'll be fine."

## Levels

HTTP caching (Cache-Control/ETag) · CDN · application cache (Redis/memcached) ·
in-process memo. Cache at the level that matches the data's scope and lifetime.

## When to use

A measured hot path where the same expensive result is repeatedly recomputed.
Don't cache speculatively — an unneeded cache is pure invalidation risk.

## Pitfalls

- Caching user-specific/authorized data under a shared key → leaking one user's
  data to another. Key by the principal.
- No invalidation on write → stale reads. No TTL → stale forever.
- Cache stampede on expiry of a hot key → thundering herd to the source.
- Caching error/empty responses and serving them.
- Unbounded cache → memory blow-up; set eviction (LRU) and size limits.

## Measure before and after

Caching is a performance optimization, so justify it with numbers, not vibes:
confirm the path is actually hot (repeated identical expensive calls) before
adding a cache, and check the hit rate after. A cache with a low hit rate adds
invalidation risk and memory cost for little gain — remove it. `performance-
auditor` should see a measured repeated cost, not a speculative "might be slow."

## Verify

- Keys include everything that varies the result (user/tenant, params, version).
- A write invalidates or re-populates the relevant keys (test).
- TTL and eviction bounds are set; no user data under a shared key.
- The cached path was measured as genuinely hot; hit rate justifies the cache.
