# Pattern — Pagination

> How to return large collections in bounded pages, correctly and efficiently.

Cited by: `backend-dev`, `api-designer`. Related: `patterns/api-design.md`,
`pitfalls/sql.md`.

## Problem

Returning a whole collection is a performance and DoS trap and a bad client
experience. But naive pagination (`OFFSET`) degrades on large datasets and can
skip or duplicate rows when data changes between pages.

## Approach — two main styles

**Offset/limit** (`?page=3&pageSize=20` → `LIMIT 20 OFFSET 40`)
- Simple; supports jump-to-page and total counts.
- Degrades: large `OFFSET` scans and discards all skipped rows. Rows shifting
  between requests cause skips/dupes.
- Use for small/bounded datasets or admin tables where jump-to-page matters.

**Cursor/keyset** (`?after=<opaque cursor>&limit=20` →
`WHERE (sort_key, id) > (:k, :id) ORDER BY sort_key, id LIMIT 20`)
- Stable under inserts/deletes; O(limit) not O(offset); scales.
- No random page access; total count is extra work.
- Use for feeds, infinite scroll, large or fast-changing datasets. **Preferred
  default** for public list endpoints.

## Rules

- Always enforce a **max page size** (e.g. cap at 100) and a sensible default.
  An unbounded `pageSize` is the DoS you were avoiding.
- Order by a **stable, unique** key (include a tiebreaker like `id`) — ordering
  by a non-unique column alone makes cursors ambiguous.
- Return pagination metadata consistently: `nextCursor`/`hasMore`, or
  `page/pageSize/total`. Keep one shape across the API.
- Index the sort key(s) — pagination without an index scans (see `pitfalls/sql.md`).

## Total counts are expensive

Clients often want a total ("page 3 of 47"). On a large table, `COUNT(*)` with
the same filters can cost as much as the page query itself, every request.
Options: omit the exact total (cursor APIs usually do — just `hasMore`); return
an approximate count (`reltuples`/table stats) when "about 40k" is enough; or
cache the count with a short TTL. Don't run an exact filtered COUNT on every
list request by reflex.

## When to use

Any endpoint returning a list that can grow. If it can ever be large, paginate
from day one — retrofitting pagination is a breaking change.

## Pitfalls

- `OFFSET` on a huge table (slow) or across changing data (skips/dupes).
- Ordering by a non-unique column → cursor instability.
- No max page size → a client requests `pageSize=1000000`.
- Exposing a raw DB offset/id as the cursor when opaque is safer.

## Verify

- Max page size enforced (test with an over-large request).
- Order key is unique/tiebroken and indexed.
- Cursor paging returns each row exactly once across inserts (test).
