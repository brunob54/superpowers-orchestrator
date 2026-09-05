# Small template (fill-prompt test fixture)

Prose before the block. The legend below mentions [LEGEND_ONLY], which the
script never scans.

```
Agent tool (general-purpose):
  description: "small round [ROUND]: [LENS_NAME] [WRAPPER_ONLY]"
  model: [MODEL — never a fill value]
  prompt: |
    Round [ROUND] under lens [LENS_NAME].

    [OPTIONAL_LINE]
    Inline: [INLINE_VALUE]
    Body: [BODY_VALUE]
    Shared line with [SHARED] here.
    Report ids such as [C1] and [I1] stay.
```

**Placeholders:** `[ROUND]`, `[LENS_NAME]`, `[WRAPPER_ONLY]`, `[OPTIONAL_LINE]`,
`[INLINE_VALUE]`, `[BODY_VALUE]`, `[SHARED]`, `[LEGEND_ONLY]`.
