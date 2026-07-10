# Pitfalls — Go

> Traps in Go: error-handling shortcuts, goroutine/concurrency footguns, and the
> loop-variable capture bug.

Cited by: `backend-dev`, `error-checker`.

## Ignored errors (the most common Go bug)

- **Wrong**: `val, _ := doThing()` discarding an error that mattered · not
  checking `err` after a call that returns one.
- **Right**: `val, err := doThing(); if err != nil { return fmt.Errorf("doing thing: %w", err) }`.
  Wrap with `%w` to preserve the chain; add context to the message.
- `defer f.Close()` on a writable file ignores the close error — check it when
  the write must be durable.

## Loop variable capture (pre-1.22)

- **Wrong** (Go < 1.22): `for _, v := range xs { go func(){ use(v) }() }` — all
  goroutines capture the same `v`, seeing the last value. Same with `defer` in a
  loop.
- **Right**: pass it in — `go func(v T){ use(v) }(v)` — or (Go 1.22+) the loop
  var is per-iteration. Check the `go` directive in `go.mod` before relying on
  the new behavior.

## Goroutine / concurrency footguns

- Goroutine leaks: a goroutine blocked on a channel no one reads never exits.
  Ensure every started goroutine can terminate (context cancellation, closed
  channel, timeout).
- Data races: shared mutable state without a mutex/channel. Run `go test -race`.
- `WaitGroup`: `Add` before starting the goroutine, `Done` in a `defer`; calling
  `Add` inside the goroutine races with `Wait`.
- Sending on a closed channel panics; closing twice panics. The receiver should
  not close.

## nil and interfaces

- A nil pointer inside a non-nil interface is NOT `== nil` — the classic
  "typed nil" trap: returning a `*MyError`(nil) as `error` makes `err != nil` true.
- nil map writes panic (`m["k"]=v` on a nil map); nil slice appends are fine.
- Dereferencing a nil pointer panics — check before `*p`.

## Slice aliasing with append

- `append` may reuse the backing array: appending to a slice of a larger array
  (or a re-sliced slice) can overwrite elements another slice still sees.
- **Wrong**: assuming `b := append(a[:2], x)` leaves `a` untouched — it may
  overwrite `a[2]`. **Right**: copy when you need independence, or full-slice
  `a[:2:2]` to force a new backing array on the next append.
- Returning a sub-slice of an internal buffer lets the caller mutate your state.

## Idiom / stdlib

- `fmt.Errorf("...: %w", err)` for wrapping (1.13+); `errors.Is`/`errors.As` for
  checking, not `==`/type assertions.
- Don't reinvent stdlib: `strings`, `slices` (1.21+), `maps` (1.21+).
- `context.Context` as the first arg for anything I/O or cancellable; don't store
  it in a struct.
- Invented stdlib functions — verify against pkg.go.dev.

## Verify

- Every returned `err` is checked or deliberately handled; wraps add context.
- `go vet` and `go test -race` pass; `golangci-lint` if configured.
- No goroutine without a termination path; no loop-var capture on the module's
  Go version.
