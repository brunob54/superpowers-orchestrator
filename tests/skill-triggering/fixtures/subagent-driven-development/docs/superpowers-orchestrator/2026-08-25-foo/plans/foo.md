# Foo — Implementation Plan

**Spec:** none (fixture plan for a skill-triggering test)

**Global Constraints:**
- Node 18 or later. No new dependencies.
- Every task ends with `npm test` passing.

### Task 1: Add the `slugify` helper

**Contract:** `slugify(s)` returns a lowercase string in which each run of
characters outside `[a-z0-9]` is replaced by a single `-`, with no leading or
trailing `-`.

- [ ] Write a failing test for `slugify("Hello World")` returning `hello-world`
- [ ] Implement `slugify` in `src/text.js`
- [ ] `npm test` passes

### Task 2: Add the `truncate` helper

**Contract:** `truncate(s, n)` returns `s` unchanged when its length is `n` or
less, otherwise the first `n - 1` characters followed by `…`.

- [ ] Write a failing test for the boundary at exactly `n`
- [ ] Implement `truncate` in `src/text.js`
- [ ] `npm test` passes

### Task 3: Export both helpers from the package entry point

**Contract:** `require("./src/index.js")` exposes `slugify` and `truncate`.

- [ ] Write a failing test importing both from the entry point
- [ ] Re-export them in `src/index.js`
- [ ] `npm test` passes

### Task 4: Document both helpers in the README

**Contract:** the README lists each helper with one example call and its result.

- [ ] Add a "Helpers" section to `README.md`
- [ ] `npm test` passes
