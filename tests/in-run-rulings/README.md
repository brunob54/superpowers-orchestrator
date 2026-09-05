# in-run-rulings wording test suite

`run-tests.sh` is a static wording test suite for the autonomous in-run
decisions design. It protects the wording contracts of the `## In-run
rulings` section in `skills/orchestrating-development/SKILL.md`, the
matching sections of `skills/multi-code-review/SKILL.md`, and the two
controller prompt templates (`code-review-loop-prompt.md` and
`batch-controller-prompt.md`) that this design added or changed.

Run it with:

```bash
bash tests/in-run-rulings/run-tests.sh
```

It is pure bash + grep/awk (no `claude` invocation), so it runs in seconds
and needs no network access.
