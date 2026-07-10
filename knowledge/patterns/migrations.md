# Pattern — Database migrations

> How to change a schema safely on a live database, where a mistake loses data
> and can't be undone by a `git revert`.

Cited by: `db-specialist`, `backend-dev`. Related: `pitfalls/sql.md`.

## Problem

Code rolls back with git; data does not. A migration that drops a column,
locks a table, or fails halfway can cause an outage or permanent loss. Migrations
must be reversible, non-locking, and safe to run against existing rows.

## Approach

- **Forward + rollback**: every migration ships with a working `down`. If a
  change is genuinely irreversible (dropping data), that must be explicitly
  sanctioned by the task — not a default.
- **Additive first, destructive later** (expand/contract): to rename or retype,
  (1) add the new column, (2) backfill + dual-write, (3) switch reads, (4) drop
  the old column in a later migration once nothing uses it. Never a single
  breaking step on a live table.
- **Backfill in batches**: a single `UPDATE` over millions of rows locks the
  table; loop in chunks with a bound.
- **Non-locking DDL**: adding a NOT NULL column with no default rewrites/locks —
  add nullable, backfill, then add the constraint (validated). On Postgres,
  `CREATE INDEX CONCURRENTLY` (outside a transaction).
- **Never edit an applied migration** — write a new one. Applied migrations are
  immutable history.

## Zero-downtime deploy ordering

Schema and code deploy at different instants; during the overlap, old code runs
against the new schema (or vice versa). Order changes so every intermediate
state is compatible:

- **Adding** a column/table: migrate first, then deploy code that uses it. Old
  code ignoring a new nullable column is fine.
- **Removing** a column: deploy code that stops using it first, then drop it in a
  later migration — never drop a column the currently-running code still selects.
- **Renaming**: never rename in place. Add-new → backfill → dual-write → switch
  reads → drop-old, each step its own deploy (the expand/contract above).
- Feature-flag the code path when the schema and behavior must change together.

## When to use

Any schema or data-shape change. db-specialist owns it; backend-dev defers
schema work to it.

## Pitfalls

- Dropping/renaming a column the running (old) code still selects → errors
  during deploy. Deploy code and schema in a compatible order.
- A migration wrapped in a transaction that includes non-transactional DDL.
- Long migration blocking the app; run heavy backfills out-of-band.
- No rollback path tested — "reversible" on paper, broken in practice.

## Verify

- `migrate up` → `migrate down` → `migrate up` runs clean on a test DB.
- Destructive operations are explicitly sanctioned by the task.
- Backfills are batched; new constraints validated against existing data.
- New query patterns from the change have index coverage (see `pitfalls/sql.md`).
