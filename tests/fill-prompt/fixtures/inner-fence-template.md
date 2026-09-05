# Inner fence (fill-prompt test fixture)

The prompt body contains a fenced example written at column 0. Taking that
example's opening fence as the closing fence of the first block would drop
the marker line below it.

```
Agent tool (general-purpose):
  prompt: |
    Line one [ROUND]
    Example follows:
```bash
    echo hi
```
    Marker line must survive.
```

**Placeholders:** `[ROUND]`.
