# Review checklist — performance

> What to check when reviewing a diff for performance regressions. A checklist,
> not a mandate to optimize everything — flag what measurably hurts under
> realistic load; speculative micro-optimizations are noise.

Cited by: `performance-auditor`. Related: `pitfalls/sql.md`,
`patterns/caching-strategies.md`.

## Database & data access

- [ ] **N+1 queries**: any query/fetch inside a loop, or an ORM lazy-load being
      iterated? Replace with a join or a batched `IN (...)`.
- [ ] **Missing index**: does a new WHERE / JOIN / ORDER BY column have index
      coverage? A new query pattern without an index scans.
- [ ] **`SELECT *`** pulling unused columns/blobs where specific columns suffice.
- [ ] **Unbounded result set**: is a list query paginated and capped? (see
      `patterns/pagination.md`)
- [ ] Query in a hot path that could be cached (only if *provably* repeated).

## Algorithms & hot paths

- [ ] O(n²) or worse on input that can be large (nested loops over collections).
- [ ] Repeated computation of a loop-invariant — hoist it out.
- [ ] Repeated work that a memo/cache would remove (measured, not assumed).
- [ ] Synchronous/blocking I/O on a request or event-loop path (see
      `pitfalls/nodejs.md`).

## Memory

- [ ] Unbounded accumulator/cache/collection that grows with traffic.
- [ ] Reading a whole file/table into memory where streaming exists.
- [ ] A cache with no eviction or size bound.

## Frontend (if applicable)

- [ ] New heavyweight dependency in the client bundle (check the size).
- [ ] New object/array/function props each render defeating memoization.
- [ ] Unvirtualized long list when data can be large.
- [ ] Work in the render path that belongs in a memo/effect.

## Network & external calls

- [ ] Chatty pattern making N calls where one would do.
- [ ] External call with no timeout (a slow dependency stalls the caller).
- [ ] Missing backoff on retries (retry storm) (see `patterns/rate-limiting.md`).

## Rating

- **CRITICAL** = a regression that measurably degrades under realistic load
  (N+1 on a list endpoint, quadratic on user-sized data, blocking I/O in a
  handler). Every CRITICAL needs a **cost scenario**: what load makes it hurt.
- **WARNING** = bites under a condition worth noting.
- Speculative "could be faster" with no load story = **INFO**, not a blocker.

## Concurrency & contention

- [ ] A new lock / mutex / transaction held across a slow operation (I/O, network)
      that serializes requests and becomes a bottleneck under load.
- [ ] Connection-pool exhaustion: work that holds a DB/HTTP connection longer than
      needed, starving concurrent requests.

## Verify

- The concern is tied to a concrete input size / load, not a hunch.
- New query patterns have index coverage; no N+1 in the diff.
- No lock/connection held across slow I/O in a hot path.
