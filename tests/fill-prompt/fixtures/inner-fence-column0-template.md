# Inner fence at column 0 with column-0 content (fill-prompt test fixture)

The prompt body contains a fenced example whose opening fence AND whose
content are both written at column 0. The opening fence carries a language
tag, so it can never be chosen as the closing fence; the example's own bare
closing fence is chosen instead, and the indented marker line below it shows
that the chosen fence sits inside the prompt body.

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
