# Review checklist — testing

> What to check about the tests in (or missing from) a change. Good tests fail
> for the right reason and survive refactors; bad tests are furniture.

Cited by: `test-writer`, `error-checker`. Related: `patterns/error-handling.md`.

## Coverage of what matters

- [ ] The change's **behavior** is tested, not just that it compiles — each
      acceptance criterion that mentions behavior has a test naming it.
- [ ] **Edge cases**, not only the happy path: empty/null/missing input, boundary
      values, error paths, unauthorized access (see the relevant checklists).
- [ ] New bug fix comes with a **regression test** that fails without the fix.
- [ ] Critical/complex logic is covered; trivial getters need not be.

## Tests that actually test

- [ ] Assertions are **meaningful** — not `expect(true).toBe(true)`, not a
      snapshot where a real assertion fits, not an assertion that can't fail.
- [ ] A test would **fail** if the behavior broke (mutation intuition: if I
      inverted the logic, does a test go red?).
- [ ] No assertion weakened just to make a failing test pass.

## Isolation & determinism

- [ ] No dependence on test **execution order** or shared mutable state between
      tests.
- [ ] No real network / real clock / real randomness making it **flaky** — time,
      randomness, and I/O are controlled/mocked at the seam.
- [ ] Tests clean up (temp files, DB rows) — the trap the project's own suites
      use `mktemp -d` + `trap rm` for.

## Structure & maintainability

- [ ] Tests exercise **public behavior / seams**, not private internals — so a
      refactor that preserves behavior doesn't break every test.
- [ ] Follows the project's test conventions (runner, naming, fixture patterns) —
      looks native, not imported.
- [ ] Mocks are used at real boundaries, not to mock the thing under test into
      meaninglessness.

## Right level of test

- [ ] The test is at an appropriate level: a **unit** test for isolated logic, an
      **integration** test for the seam between components, an **end-to-end** test
      for a critical user flow — not an expensive E2E test for what a unit test
      covers, nor a unit test mocking so much it tests only the mocks.
- [ ] The suite isn't inverted (mostly slow E2E, few units) — fast tests should
      catch most regressions; slow tests guard the critical flows.

## What NOT to over-test

- [ ] Not testing the framework/library itself (it has its own tests).
- [ ] Not asserting on implementation details that a valid refactor would change.
- [ ] Not duplicating the same assertion across many near-identical tests where a
      parameterized/table test is clearer.

## Behavior-lock before refactor

- [ ] A refactor task has **passing behavior-lock tests** pinning current
      behavior BEFORE the refactor (refactor-specialist refuses without them).

## Verify

- Run the tests: new behavior tests pass; a regression test fails without the fix.
- Inverting the changed logic makes at least one test go red (the test can fail).
- No order-dependence, no flaky real-I/O/clock/random, tests clean up.
