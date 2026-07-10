# Pitfalls — SQL and databases

> Traps in SQL and data-layer code: injection by concatenation, migration
> hazards, N+1 queries, and dialect confusion.

Cited by: `db-specialist`, `backend-dev`, `error-checker`. Related:
`owasp/a03-injection.md`, `security/authz-checklist.md`.

## Injection by string-building (the cardinal sin)

- **Wrong**: `"SELECT * FROM u WHERE email='" + email + "'"` — or f-strings,
  `.format()`, template literals building the query.
- **Right**: parameterized/prepared statements — bind values:
  `db.query("SELECT * FROM u WHERE email = $1", [email])`. Use the ORM's binding,
  not its raw-string escape hatch.
- Identifiers (table/column names) can't be bound as parameters — allowlist them
  against a fixed set; never interpolate user input as an identifier.

## Migration hazards (data doesn't roll back by itself)

- **Never edit an already-applied migration** — write a new one.
- Destructive ops (DROP/rename column, narrow a type) can lose data — must be
  explicitly sanctioned by the task, with a rollback path.
- Adding a NOT NULL column with no default to a populated table fails or locks;
  backfill in batches, then add the constraint.
- Big `UPDATE`/`DELETE` without batching locks the table; batch them.
- A migration that runs in a transaction on one DB may not on another (some DDL
  is non-transactional, e.g. Postgres `CREATE INDEX CONCURRENTLY`).

## Performance traps

- **N+1**: a query per row in a loop (ORM lazy-loading iterated). Use a join or
  a batched `IN (...)` / `dataloader`. This is the most common perf regression.
- **Missing index** on a new WHERE/JOIN/ORDER BY column — the query scans.
  Every new query pattern needs matching index coverage.
- `SELECT *` pulling unused columns/blobs; select what you need.
- Unbounded result sets — paginate; never load a whole large table.

## Correctness footguns

- `NULL` semantics: `x = NULL` is never true (use `IS NULL`); `NOT IN (subquery
  with NULLs)` returns no rows unexpectedly. `COUNT(col)` skips NULLs.
- Floating point for money — use `DECIMAL`/`NUMERIC`.
- Timezones: store UTC (`timestamptz`), convert at the edges.
- Transaction scope: forgetting to commit, or holding a transaction open across
  a network call.

## Dialect / version confusion

- Postgres vs MySQL vs SQLite differ: `RETURNING`, `ILIKE`, `AUTO_INCREMENT` vs
  `SERIAL` vs `AUTOINCREMENT`, `LIMIT`/`OFFSET` syntax, boolean handling,
  upsert (`ON CONFLICT` vs `ON DUPLICATE KEY`). Check which DB the project uses.
- ORM version drift (Prisma/TypeORM/SQLAlchemy/ActiveRecord APIs change).

## Verify

- No string-built queries in the diff; all values bound.
- New query patterns have index coverage; no N+1 in loops.
- Migrations are new (not edited), reversible, and destructive ops sanctioned.
- Money uses DECIMAL; timestamps are UTC; NULL logic is correct.
