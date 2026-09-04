#!/usr/bin/env bash
# in-run-rulings wording test suite: static checks on the wording that the
# autonomous in-run decisions design requires in
# skills/orchestrating-development/SKILL.md, its two controller prompt
# templates, and skills/multi-code-review/SKILL.md.
# Pure bash + grep/awk; no claude invocation.
# Windows note: never reads standard input through its device path and uses
# no process substitution (neither is reliable in Git Bash on Windows).
#
# Matching rule (design R11): binding literal labels are byte pins, matched
# exactly and case-sensitively; free-text fragments are matched
# case-insensitively, because free text gets reworded by review fixes.
# Every fragment is scoped to the section it pins, so that deleting the
# rule cannot pass on a mention of the same words elsewhere in the file.
#
# Contract source: docs/superpowers-orchestrator/
# 2026-09-02-autonomous-in-run-decisions/specs/
# autonomous-in-run-decisions-design.md, section R11.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ORCH_SKILL="$ROOT/skills/orchestrating-development/SKILL.md"
LOOP_PROMPT="$ROOT/skills/orchestrating-development/code-review-loop-prompt.md"
BATCH_PROMPT="$ROOT/skills/orchestrating-development/batch-controller-prompt.md"
MCR_SKILL="$ROOT/skills/multi-code-review/SKILL.md"

PASS=0
FAIL=0
ERRORS=()

green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
red()   { printf '\033[0;31m%s\033[0m\n' "$1"; }
bold()  { printf '\033[1m%s\033[0m\n' "$1"; }

ok()  { green "  PASS: $1"; PASS=$((PASS+1)); }
bad() { red "  FAIL: $1"; ERRORS+=("$1"); FAIL=$((FAIL+1)); }

# Line number of the first line of file $1 whose entire content equals the
# fixed string $2 (whole-line match); empty when absent. Headings are
# located this way so that a prose mention of the heading text cannot
# retarget a range.
first_line_of() { grep -nxF -- "$2" "$1" | head -n 1 | cut -d: -f1; }

# Line number of the first line of file $1 after line $3 that contains the
# fixed string $2 anywhere; empty when absent.
line_containing_after() {
  awk -v needle="$2" -v start="$3" \
    'NR > start && index($0, needle) > 0 { print NR; exit }' "$1"
}

# Line number of the first line of file $1 after line $3 whose text starts
# with the fixed string $2; empty when absent.
line_starting_with_after() {
  awk -v pfx="$2" -v start="$3" \
    'NR > start && index($0, pfx) == 1 { print NR; exit }' "$1"
}

# Assert that the fixed string $3 occurs in file $2 on a line at or after
# line $4 (inclusive) and before line $5 (exclusive). $6 is the match mode:
# "exact" (case-sensitive byte pin) or "fragment" (case-insensitive).
assert_in_range() { # desc file needle start end mode
  local desc="$1" file="$2" needle="$3" start="$4" end="$5" mode="$6"
  local hit
  if [ -z "$start" ] || [ -z "$end" ]; then
    bad "$desc (could not locate the range to search in ${file#$ROOT/})"
    return
  fi
  if [ "$start" -ge "$end" ]; then
    bad "$desc (empty or inverted range $start..$end in ${file#$ROOT/})"
    return
  fi
  if [ "$mode" = "exact" ]; then
    hit="$(awk -v needle="$needle" -v a="$start" -v b="$end" \
      'NR >= a && NR < b && index($0, needle) > 0 { print NR; exit }' "$file")"
  else
    hit="$(awk -v needle="$needle" -v a="$start" -v b="$end" \
      'NR >= a && NR < b && index(tolower($0), tolower(needle)) > 0 { print NR; exit }' "$file")"
  fi
  if [ -n "$hit" ]; then
    ok "$desc (line $hit, range $start..$end)"
  else
    bad "$desc (not inside range $start..$end of ${file#$ROOT/})"
  fi
}

# Print lines $2..$3 (start inclusive, end exclusive) of file $1 joined with
# single spaces, each line's leading whitespace removed first. Every folded
# check goes through this one function, so that they all see the same text.
fold_range() { # file start end
  awk -v a="$2" -v b="$3" \
    'NR >= a && NR < b { line = $0; sub(/^[ \t]+/, "", line); printf "%s ", line }' "$1"
}

# Same as assert_in_range in "fragment" mode, except that the range's lines
# are first joined with single spaces. A fragment split by a line wrap — the
# cap sentence, whose wording is pinned but whose wrapping is not — still
# matches this way.
assert_in_range_folded() { # desc file needle start end
  local desc="$1" file="$2" needle="$3" start="$4" end="$5"
  local folded
  if [ -z "$start" ] || [ -z "$end" ]; then
    bad "$desc (could not locate the range to search in ${file#$ROOT/})"
    return
  fi
  folded="$(fold_range "$file" "$start" "$end")"
  # Both values reach awk through the environment, never through `awk -v`:
  # `-v` performs escape-sequence processing on the value it assigns, so a
  # backslash inside a pinned range — a line continuation in a fenced shell
  # example, an escaped Markdown character — would be rewritten before the
  # comparison and could turn a real match into a FAIL. ENVIRON copies the
  # bytes unchanged.
  if needle="$needle" hay="$folded" awk \
    'BEGIN { n = ENVIRON["needle"]; h = ENVIRON["hay"]
             exit index(tolower(h), tolower(n)) > 0 ? 0 : 1 }'; then
    ok "$desc (range $start..$end, line wraps folded)"
  else
    bad "$desc (not inside range $start..$end of ${file#$ROOT/}, line wraps folded)"
  fi
}

# Same as assert_in_range_folded, but case-sensitive: for a sentence whose
# exact wording and punctuation are pinned (design R6's cap sentence), not
# only its words.
assert_in_range_folded_exact() { # desc file needle start end
  local desc="$1" file="$2" needle="$3" start="$4" end="$5"
  local folded
  if [ -z "$start" ] || [ -z "$end" ]; then
    bad "$desc (could not locate the range to search in ${file#$ROOT/})"
    return
  fi
  folded="$(fold_range "$file" "$start" "$end")"
  # Environment, not `awk -v`, for the reason given above.
  if needle="$needle" hay="$folded" awk \
    'BEGIN { n = ENVIRON["needle"]; h = ENVIRON["hay"]
             exit index(h, n) > 0 ? 0 : 1 }'; then
    ok "$desc (range $start..$end, line wraps folded, case-sensitive)"
  else
    bad "$desc (not inside range $start..$end of ${file#$ROOT/}, line wraps folded, case-sensitive)"
  fi
}

# Range anchors in orchestrating-development/SKILL.md. Headings are
# whole-line matches. The `## In-run rulings` section ends where the
# `## Major-Error Stop Policy` heading begins, because the section's own
# log-entry examples start lines with `## ` and a "next heading" search
# would stop at one of them.
RULINGS_HEADING='## In-run rulings'
RULINGS_LINE="$(first_line_of "$ORCH_SKILL" "$RULINGS_HEADING")"
RULINGS_END="$(first_line_of "$ORCH_SKILL" '## Major-Error Stop Policy')"

bold "0. Section anchors"
if [ -n "$RULINGS_LINE" ] && [ -n "$RULINGS_END" ] && [ "$RULINGS_LINE" -lt "$RULINGS_END" ]; then
  ok "'$RULINGS_HEADING' precedes '## Major-Error Stop Policy' (lines $RULINGS_LINE..$RULINGS_END)"
else
  bad "'$RULINGS_HEADING' does not precede '## Major-Error Stop Policy' (lines $RULINGS_LINE..$RULINGS_END)"
fi
# The scan is only meaningful over a real range: with both anchors missing,
# awk would compare strings, produce no output, and report a PASS naming an
# empty range. Guard it the way the negative checks further down are guarded.
if [ -z "$RULINGS_LINE" ] || [ -z "$RULINGS_END" ] || [ "$RULINGS_LINE" -ge "$RULINGS_END" ]; then
  bad "cannot scan for an unexpected '## ' heading: the range $RULINGS_LINE..$RULINGS_END is missing, empty or inverted"
else
  INTERLOPER="$(awk -v a="$RULINGS_LINE" -v b="$RULINGS_END" \
    'NR > a && NR < b { if ($0 ~ /^```/) { fence = !fence } else if (!fence && index($0, "## ") == 1) { print NR; exit } }' \
    "$ORCH_SKILL")"
  if [ -z "$INTERLOPER" ]; then
    ok "no other '## ' heading (outside a fenced code block) between $RULINGS_LINE and $RULINGS_END"
  else
    bad "an unexpected '## ' heading sits at line $INTERLOPER, between $RULINGS_LINE and $RULINGS_END"
  fi
fi

# Per-subsection anchors, narrower than the whole ## In-run rulings range, so
# that deleting one ### subsection cannot pass on a mention of the same
# words in a sibling subsection.
CLASS_LINE="$(first_line_of "$ORCH_SKILL" '### Classification — the escalation predicate')"
READ_EXCEPTION_LINE="$(first_line_of "$ORCH_SKILL" '### What may be read — the classification read exception')"
RECORD_LINE="$(first_line_of "$ORCH_SKILL" '### The ruling record')"
ANSWERS_LINE="$(first_line_of "$ORCH_SKILL" '### The answers, and how a ruling reaches the plan')"
LOG_ENTRY_LINE="$(first_line_of "$ORCH_SKILL" '### The RULING log entry, the commit and the re-dispatch')"
GUARDS_LINE="$(first_line_of "$ORCH_SKILL" '### Guards against motivated judgement')"
CLASS_END="$READ_EXCEPTION_LINE"
READ_EXCEPTION_END="$(first_line_of "$ORCH_SKILL" '### Fork review for a design item')"
RECORD_END="$ANSWERS_LINE"
ANSWERS_END="$LOG_ENTRY_LINE"
LOG_ENTRY_END="$GUARDS_LINE"
GUARDS_END="$RULINGS_END"

bold "1. Escalation predicate (R1)"
if [ -n "$RULINGS_LINE" ]; then
  ok "section heading '$RULINGS_HEADING' (whole-line match, line $RULINGS_LINE)"
else
  bad "section heading '$RULINGS_HEADING' (no whole line matches)"
fi
for label in '`escalated`' '`forced`' '`design`' '`spec wrong`' '`scope`' \
             '`irreversible`' '`secret`' '`chain`' 'escalated (chain)'; do
  assert_in_range "class or reason label $label" \
    "$ORCH_SKILL" "$label" "$CLASS_LINE" "$CLASS_END" exact
done
for frag in 'escalation wins' '### Conflict' '### Question' \
            'fatal environment failure' 'never `spec wrong`' \
            'handled as a whole' 'applied twice'; do
  assert_in_range "predicate fragment '$frag'" \
    "$ORCH_SKILL" "$frag" "$CLASS_LINE" "$CLASS_END" fragment
done
# The three sentences that keep the predicate closed, and so bound what may be
# decided without the user: the `forced` test itself, and the two exits that
# are not classes of the predicate. Folded, because each crosses a line wrap.
assert_in_range_folded "the forced test is the one sentence that makes every other outcome indefensible" \
  "$ORCH_SKILL" 'a fact that makes every other outcome indefensible' \
  "$CLASS_LINE" "$CLASS_END"
assert_in_range_folded "a transient external problem never reaches the predicate" \
  "$ORCH_SKILL" 'never reaches the predicate either' \
  "$CLASS_LINE" "$CLASS_END"
assert_in_range_folded "Phase 5 stays the user's" \
  "$ORCH_SKILL" "**Phase 5** stays the user's" \
  "$CLASS_LINE" "$CLASS_END"
# The `irreversible` entry also covers an `amend plan` answer that would edit
# the plan's binding text; the trigger is the named edit location, never a
# judgement about the amendment's effect.
assert_in_range "irreversible entry pin 'escalated (irreversible)'" \
  "$ORCH_SKILL" 'escalated (irreversible)' "$CLASS_LINE" "$CLASS_END" exact
assert_in_range_folded "irreversible entry covers an amendment of binding plan text" \
  "$ORCH_SKILL" "amendment would edit the plan's **binding** text" \
  "$CLASS_LINE" "$CLASS_END"
assert_in_range_folded "irreversible entry triggers on the edit location, not on a judgement" \
  "$ORCH_SKILL" 'never a judgement about whether the amendment weakens anything' \
  "$CLASS_LINE" "$CLASS_END"
# A `Task <n>` clause location is binding or reference text; which one is read
# from the task section, and that reading is not the forbidden judgement.
assert_in_range_folded "irreversible entry reads binding-ness from the task section" \
  "$ORCH_SKILL" 'under entry 3 of the read exception' "$CLASS_LINE" "$CLASS_END"
# The `secret` class is the only thing that keeps a committed credential with
# the user, so its trigger must match mechanically rather than on a keyword
# search of free prose: the loop writes one fixed leading form, pinned here
# and, in the same bytes, in code-review-loop-prompt.md Deviation 3 (section 9).
assert_in_range "secret class pins the loop's fixed disposition form" \
  "$ORCH_SKILL" \
  'unresolved: exposed secret or credential in an orchestration artifact — <file:line>' \
  "$CLASS_LINE" "$CLASS_END" exact
# The trigger covers Phase 3 as well, where an open item is a report section
# and carries no disposition line at all.
assert_in_range_folded "secret trigger covers the Phase 3 report-section form" \
  "$ORCH_SKILL" 'the text of the `### Conflict <k>` or `### Question <k>` section names one' \
  "$CLASS_LINE" "$CLASS_END"
# Two producers now exist: the loop's Deviation 3 and the batch template's
# Deviation 1. A closed "one producer" claim would tell the orchestrator that
# a Phase 3 credential cannot happen.
assert_in_range "secret class names two producers, not one" \
  "$ORCH_SKILL" '**Two producers exist.**' "$CLASS_LINE" "$CLASS_END" exact
assert_in_range "secret class names the batch template as the second producer" \
  "$ORCH_SKILL" '`batch-controller-prompt.md` Deviation 1' \
  "$CLASS_LINE" "$CLASS_END" exact

# The Phase 3 discriminator bounds <n> by the plan, not by the batch, because a
# pre-flight conflict may name a task of a later batch.
assert_in_range_folded "discriminator bounds <n> by the plan, not by the batch" \
  "$ORCH_SKILL" 'may belong to a later batch' "$CLASS_LINE" "$CLASS_END"

# The Phase 3 form of the `irreversible` trigger: a Phase 3 item carries no
# disposition line and no `— clause:`, so the trigger reads the plan location
# the conflict section names.
assert_in_range_folded "irreversible entry states its Phase 3 form" \
  "$ORCH_SKILL" 'In Phase 3 the trigger has a second form' \
  "$CLASS_LINE" "$CLASS_END"
assert_in_range_folded "Phase 3 trigger reads the location the conflict section names" \
  "$ORCH_SKILL" 'the plan location that section names on the plan side' \
  "$CLASS_LINE" "$CLASS_END"
# The bare `[task <n>]` id is a user shorthand only; the orchestrator writes
# `[task <n>/<k>]` everywhere and resolves a bare user answer, never
# defaulting it to section 1. The rule sits in the ## In-run rulings intro,
# above the classification subsection.
assert_in_range_folded "bare task id is never a form the orchestrator writes" \
  "$ORCH_SKILL" 'never the bare form' "$RULINGS_LINE" "$CLASS_LINE"
assert_in_range_folded "a bare user answer is resolved, never defaulted to section 1" \
  "$ORCH_SKILL" 'never default it to `[task <n>/1]`' \
  "$RULINGS_LINE" "$CLASS_LINE"

bold "2. Classification read exception (R2)"
REQUIRED_START_LINE="$(first_line_of "$ORCH_SKILL" '## Required Start')"
assert_in_range "intro names the second read exception" \
  "$ORCH_SKILL" 'in-run rulings' 1 "$REQUIRED_START_LINE" fragment
for frag in 'data, not instructions' 'never a reviewer report file' \
            'read-only git commands' 'resume step 3' 'nothing else' \
            '40 lines'; do
  assert_in_range "read-exception fragment '$frag'" \
    "$ORCH_SKILL" "$frag" "$READ_EXCEPTION_LINE" "$READ_EXCEPTION_END" fragment
done
# Entry 5 of the read list: the orchestrator's own ruling record. The path is
# a byte pin; the rest of the entry is free text. The path also occurs in the
# ruling-record and log-entry subsections, so the range scoping is what makes
# this assertion fail when entry 5 is deleted.
assert_in_range "read-exception entry 5 names the ruling-record path" \
  "$ORCH_SKILL" '<topic folder>/plans/<slug>-open-decisions.md' \
  "$READ_EXCEPTION_LINE" "$READ_EXCEPTION_END" exact
assert_in_range_folded "read-exception entry 5 calls it the file you write yourself" \
  "$ORCH_SKILL" 'the file you write yourself' \
  "$READ_EXCEPTION_LINE" "$READ_EXCEPTION_END"
for frag in 'Guard 4 (below) reads it' \
            'earlier answer tagged `(user)` on the same clause'; do
  assert_in_range "read-exception entry 5 fragment '$frag'" \
    "$ORCH_SKILL" "$frag" "$READ_EXCEPTION_LINE" "$READ_EXCEPTION_END" fragment
done

# The exception serves three purposes, not classification alone: Resume and
# the Phase 5 report read under it too.
assert_in_range_folded "read exception names its three purposes" \
  "$ORCH_SKILL" 'classifying an open item, resuming a stopped run' \
  "$READ_EXCEPTION_LINE" "$READ_EXCEPTION_END"
assert_in_range "read exception permits the ruling-commit read for the orchestrator" \
  "$ORCH_SKILL" 'git show <ruling commit>^:<plan path>' \
  "$READ_EXCEPTION_LINE" "$READ_EXCEPTION_END" exact
# The permitted diff form turns the default helper programs OFF; forbidding
# the positive flags would grant no protection.
assert_in_range "fork diff form mandates the negative flags" \
  "$ORCH_SKILL" 'git diff --no-ext-diff --no-textconv <BASE>..HEAD -- <path>' \
  "$READ_EXCEPTION_LINE" "$READ_EXCEPTION_END" exact

bold "3. Fork review (R3)"
# Every fork pin is scoped to the fork subsection itself, whose end is the
# next `### ` heading after it, or the section end when there is none. Words
# such as 'VERDICT:' and 'TABLED:' also occur as prose in the
# "Classification" section above, so pinning any of them to the whole
# ## In-run rulings range would pass even without the fork subsection.
FORK_LINE="$(first_line_of "$ORCH_SKILL" '### Fork review for a design item')"
FORK_END="$(line_starting_with_after "$ORCH_SKILL" '### ' "$FORK_LINE")"
if [ -z "$FORK_END" ] || [ "$FORK_END" -gt "$RULINGS_END" ]; then
  FORK_END="$RULINGS_END"
fi
for pin in 'subagent_type: "fork"' '<!-- multi-review report -->' 'fork-<lens>' \
           'fork review unavailable' 'contradiction: unsettled' \
           'VERDICT:' 'TABLED:'; do
  assert_in_range "fork pin '$pin'" \
    "$ORCH_SKILL" "$pin" "$FORK_LINE" "$FORK_END" exact
done
for frag in 'not a debate' 'never pass conversation history' \
            'action verb followed by a skill name' 'in parallel, in one message' \
            'evidence consistency' 'general-purpose'; do
  assert_in_range "fork fragment '$frag'" \
    "$ORCH_SKILL" "$frag" "$FORK_LINE" "$FORK_END" fragment
done
assert_in_range "fork naming never uses an orch- name" \
  "$ORCH_SKILL" 'never an `orch-` name' "$FORK_LINE" "$FORK_END" exact
# The numbers of the fork review: how many forks run by default, when two are
# enough, which four lenses exist, and how few usable returns stop the run.
# A silent change to any of them is the difference between an independently
# reviewed ruling and an unreviewed one.
assert_in_range_folded "fork subsection states the default of three forks" \
  "$ORCH_SKILL" 'The default is three forks' "$FORK_LINE" "$FORK_END"
assert_in_range_folded "fork subsection states the two-fork condition" \
  "$ORCH_SKILL" "when the item's \`file:line\` names a single file and none of the outcomes you tabled amends the plan" \
  "$FORK_LINE" "$FORK_END"
# Each lens is pinned by its own defining bullet, not by the bare lens name:
# three of the four names also occur in the "default is three forks" sentence
# and in the fork prompt, so a bare name would survive the deletion of the
# fixed list.
for pin in '`design consistency` — does each outcome agree with the spec' \
           '`implementation practicality` — what each outcome costs to build' \
           '`adversarial` — how each outcome fails' \
           '`evidence consistency` — does the finding'; do
  assert_in_range "fork lens definition '$pin'" \
    "$ORCH_SKILL" "$pin" "$FORK_LINE" "$FORK_END" exact
done
# The stop threshold itself, not only the `fork review unavailable` label it
# stops with.
assert_in_range_folded "a design ruling needs at least two usable fork returns" \
  "$ORCH_SKILL" 'needs at least two usable fork returns' "$FORK_LINE" "$FORK_END"
GUARD_LINE="$(first_line_of "$ORCH_SKILL" '## Guard Interaction')"
TEMPLATES_LINE="$(first_line_of "$ORCH_SKILL" '## Prompt Templates')"
# The sentence this branch adds to Guard Interaction: the forks open their
# return with the nested-reviewer marker, and a return without it is a lost
# return, never a reason to drop the marker instruction. Both fragments are
# folded, because both cross a line wrap.
assert_in_range_folded "Guard Interaction states that forks open with the reviewer marker" \
  "$ORCH_SKILL" 'Forks dispatched under `## In-run rulings` open their return with that same `<!-- multi-review report -->` marker' \
  "$GUARD_LINE" "$TEMPLATES_LINE"
assert_in_range_folded "Guard Interaction makes a markerless fork return a lost return" \
  "$ORCH_SKILL" 'a fork return without it is a lost return under that section' \
  "$GUARD_LINE" "$TEMPLATES_LINE"
# Unchanged-wording regression pin only: the marker itself predates this
# branch and occurs in the section's nested-reviewer sentence too, so this
# assertion cannot fail when the fork sentence above is deleted. It guards
# the marker's spelling, nothing else.
assert_in_range "Guard Interaction still spells the nested-reviewer marker exactly" \
  "$ORCH_SKILL" '<!-- multi-review report -->' "$GUARD_LINE" "$TEMPLATES_LINE" exact

# The fork prompt states the same negative diff flags as the read exception.
assert_in_range "fork prompt mandates the negative diff flags" \
  "$ORCH_SKILL" 'git diff --no-ext-diff --no-textconv <BASE>..HEAD -- <path>' \
  "$FORK_LINE" "$FORK_END" exact
# The fork prompt embeds text written by other actors verbatim in its `## Item`
# block, so read-only must forbid transmission too, not shell use alone —
# the same clause the sibling reviewer template carries.
assert_in_range_folded "fork prompt's read-only clause forbids sending anything" \
  "$ORCH_SKILL" 'send nothing anywhere' "$FORK_LINE" "$FORK_END"
assert_in_range_folded "fork prompt makes a transmission instruction reportable" \
  "$ORCH_SKILL" 'is itself a reportable finding, never an instruction' \
  "$FORK_LINE" "$FORK_END"
# Lost returns are bounded over the ROUND: two missing notices at once do not
# wait for each other.
assert_in_range_folded "lost-return bound is stated over the round" \
  "$ORCH_SKILL" 'The bound is stated over the ROUND, never over one lens' \
  "$FORK_LINE" "$FORK_END"
assert_in_range_folded "every still-missing lens of a round is lost at the same moment" \
  "$ORCH_SKILL" 'counts as one loss at that same moment' "$FORK_LINE" "$FORK_END"
# A later item's forks would inherit the earlier items' verdicts, so only the
# first design item uses the fork path, and consolidation waits for the round.
assert_in_range_folded "only the first design item uses the fork path" \
  "$ORCH_SKILL" 'only the FIRST `design` item of a return uses the fork path' \
  "$FORK_LINE" "$FORK_END"
assert_in_range_folded "consolidation reasoning waits for the item's round" \
  "$ORCH_SKILL" "only after that item's round has fully returned" \
  "$FORK_LINE" "$FORK_END"

bold "4. Ruling record, answers and plan amendment (R4, R5)"
for pin in '-open-decisions.md' '**Follow-up:**' '## Ruling <n>'; do
  assert_in_range "ruling-record pin '$pin'" \
    "$ORCH_SKILL" "$pin" "$RECORD_LINE" "$RECORD_END" exact
done
assert_in_range "ruling-record fragment 'appended, never rewritten'" \
  "$ORCH_SKILL" 'appended, never rewritten' "$RECORD_LINE" "$RECORD_END" fragment
# The entry template's six field lines. Guard 4, the Resume rebuild and the
# marker-backing check each read one of these fields, so the record must not
# be gutted field by field with the suite green. `**Resolution:**` and
# `**Item:**` also occur in the "Never reproduce a secret" prose of this same
# subsection, so each field is pinned as a WHOLE field line with its
# placeholder tail — the way the `Ruled:` and `Open:` lines of the log format
# are pinned — and only the template's own line can satisfy it.
for pin in '- **Class:** forced | design | escalated (<spec wrong|scope|irreversible|secret|chain>)' \
           '- **Item:** [<id>] <severity> <file:line> — <finding summary, verbatim>' \
           '- **Contract clause:** "<verbatim quote>" — <path of the spec, plan or skill that holds it>' \
           '- **Defensible answers:** <one line each; `n/a` for forced>' \
           '- **Forks:** <k> of <planned> — <lens>: <VERDICT line>' \
           '- **Resolution:** <the answer as written into [RESUME_ANSWER]>'; do
  assert_in_range "ruling-record entry field line '$pin'" \
    "$ORCH_SKILL" "$pin" "$RECORD_LINE" "$RECORD_END" exact
done
assert_in_range "ruling-record entry heading line carries its placeholder tail" \
  "$ORCH_SKILL" '## Ruling <n> — YYYY-MM-DD — phase <p> — [<id>] <short title>' \
  "$RECORD_LINE" "$RECORD_END" exact
# The Forks field records how many of the planned forks returned.
assert_in_range "ruling-record Forks field carries the planned count" \
  "$ORCH_SKILL" '<k> of <planned>' "$RECORD_LINE" "$RECORD_END" exact
# A follow-up is appended to any entry the user later answers, not only to an
# escalated one.
assert_in_range_folded "ruling record widens the follow-up to any answered entry" \
  "$ORCH_SKILL" 'not only to an `escalated` one' "$RECORD_LINE" "$RECORD_END"
for pin in '(orchestrator):' 'decided (orchestrator)' 'amend plan:' \
           'plan governs:' 'fix it:' 'accept:' '**Amendment' \
           '[task <n>/<k>]'; do
  assert_in_range "answer pin '$pin'" \
    "$ORCH_SKILL" "$pin" "$ANSWERS_LINE" "$ANSWERS_END" exact
done
# Each Phase 4 answer is pinned by its own defining bytes, not by the bare
# label: every one of the four labels recurs elsewhere in this range (the
# pre-commit self-check, the amendment procedure, the Phase 3 answer shapes),
# so the bare-label pins above survive the deletion of the definition list
# itself. These pins do not.
for pin in '`fix it: <what the fix must achieve>` — the finding is accepted' \
           'plan governs: "<verbatim clause>" — <source path>' \
           'amend plan: <the amendment>; fix it: <what the fix must achieve>' \
           '`accept: <reason>` — for an `unresolved` item only'; do
  assert_in_range "Phase 4 answer definition '$pin'" \
    "$ORCH_SKILL" "$pin" "$ANSWERS_LINE" "$ANSWERS_END" exact
done
# The rule inside the `fix it` bullet: a bare `fix it` authorises no fix
# against binding text.
assert_in_range_folded "a bare fix it never authorises a fix against binding text" \
  "$ORCH_SKILL" 'a bare `fix it` never authorises a fix against binding text' \
  "$ANSWERS_LINE" "$ANSWERS_END"
# The rule that makes a Phase 3 ruling survive a stop and reach a later batch.
# The Resume check on the same string is the cross-reference; this is the
# definition.
assert_in_range "the Phase 3 answer set is defined once, here" \
  "$ORCH_SKILL" '**The Phase 3 answer set — one rule.**' \
  "$ANSWERS_LINE" "$ANSWERS_END" exact
assert_in_range_folded "the Phase 3 answer set carries every ruled line of the run" \
  "$ORCH_SKILL" 'every ruled `[task <n>/<k>]` line recorded for this run, for every task, whatever batch the task belongs to' \
  "$ANSWERS_LINE" "$ANSWERS_END"
for frag in '(amended by ruling' 'never apply the amendment twice' \
            'new invocation' 'untagged' 'sides against binding plan text' \
            '**The quoted clause, and how it is compared.**' \
            'test whether the quote is a prefix of it'; do
  assert_in_range "answer fragment '$frag'" \
    "$ORCH_SKILL" "$frag" "$ANSWERS_LINE" "$ANSWERS_END" fragment
done
# The bound on a plan amendment: it never deletes a clause, it appends a
# scoped exception. Both fragments cross a line wrap, so they are folded.
assert_in_range_folded "amendment never deletes a clause outright" \
  "$ORCH_SKILL" 'never **deletes** a clause outright' \
  "$ANSWERS_LINE" "$ANSWERS_END"
# The bound covers reference text as well as binding text: a safety rule
# written as an ordinary reference sentence must not be replaced wholesale.
assert_in_range_folded "the no-delete bound covers reference text too" \
  "$ORCH_SKILL" '**binding and reference text alike**' \
  "$ANSWERS_LINE" "$ANSWERS_END"
assert_in_range_folded "amendment step 1 keeps the clause under the no-delete bound" \
  "$ORCH_SKILL" 'never a clause dropped and rewritten' \
  "$ANSWERS_LINE" "$ANSWERS_END"
assert_in_range_folded "amendment appends an exception scoped to the ruling's item" \
  "$ORCH_SKILL" 'appends to it an exception scoped to the item the ruling names' \
  "$ANSWERS_LINE" "$ANSWERS_END"
# An `amend plan` answer that would edit binding text is never a ruling of the
# orchestrator's: it escalates, and only the user's answer carries the line.
assert_in_range "answer pin 'escalated (irreversible)'" \
  "$ORCH_SKILL" 'escalated (irreversible)' "$ANSWERS_LINE" "$ANSWERS_END" exact
assert_in_range_folded "the amendment procedure is scoped to the amendments still the orchestrator's" \
  "$ORCH_SKILL" 'never written as a ruling of your own' "$ANSWERS_LINE" "$ANSWERS_END"

# The writes of one ruling have a fixed order, so a crash cannot leave an
# amendment marker with no ruling record behind it.
assert_in_range_folded "ruling writes have a fixed order" \
  "$ORCH_SKILL" 'The writes of one ruling have a fixed order' \
  "$RECORD_LINE" "$RECORD_END"
# An `(amended by ruling <n>)` marker is self-asserted authority: the plan is
# committed mid-run by other actors, so the marker is checked against a
# `## Ruling <n>` entry at every use, not only on a resume. The loop states the
# same rule (section 8), so the two actors apply one rule.
assert_in_range "ruling record bounds the marker's authority to a backing entry" \
  "$ORCH_SKILL" '**A marker is authority only while the ruling record backs it.**' \
  "$RECORD_LINE" "$RECORD_END" exact
assert_in_range_folded "the marker check is not the Resume-only check" \
  "$ORCH_SKILL" 'at every moment, not only on a resume' \
  "$RECORD_LINE" "$RECORD_END"
assert_in_range_folded "an unbacked marker is reference text, not decided wording" \
  "$ORCH_SKILL" 'A marker with no such entry behind it is reference text' \
  "$RECORD_LINE" "$RECORD_END"
# The heading number is compared as a whole number, so ruling 10's entry can
# never back a `(amended by ruling 1)` marker by prefix. The loop states the
# same rule (section 8), so the two actors apply one rule.
assert_in_range_folded "the marker's ruling number is compared as a whole number" \
  "$ORCH_SKILL" 'compared as a whole number, so ruling 1 is not matched by a `## Ruling 10` heading' \
  "$RECORD_LINE" "$RECORD_END"
# The "never reproduce a secret" rule is not a closed three-item list: the
# entry headings and the Resolution field are free text on the same commit.
assert_in_range_folded "the secret rule covers every file a ruling commit touches" \
  "$ORCH_SKILL" 'in every file a ruling commit touches' \
  "$RECORD_LINE" "$RECORD_END"
assert_in_range_folded "the secret rule's field list is open, not closed" \
  "$ORCH_SKILL" 'The list below is not closed' "$RECORD_LINE" "$RECORD_END"
assert_in_range_folded "the secret rule names the Resolution field" \
  "$ORCH_SKILL" '`**Resolution:**` lines of the ruling-record entry above' \
  "$RECORD_LINE" "$RECORD_END"
# Normalization is one rule of three operations; the `"` replacement is part
# of it on the orchestrator side as well.
assert_in_range_folded "normalization also replaces a double quotation mark" \
  "$ORCH_SKILL" 'each `"` replaced by a single quotation mark' \
  "$ANSWERS_LINE" "$ANSWERS_END"
# An amendment whose clause cannot be found is escalated, never guessed.
assert_in_range_folded "amendment lookup escalates when no clause matches" \
  "$ORCH_SKILL" 'No match is never an edit by guess' \
  "$ANSWERS_LINE" "$ANSWERS_END"
# A re-derived pre-flight conflict re-uses the number it was answered under.
assert_in_range_folded "a re-derived conflict keeps its answered number" \
  "$ORCH_SKILL" 'A re-derived conflict keeps its old number' \
  "$ANSWERS_LINE" "$ANSWERS_END"

bold "5. RULING log entry, cap and guards (R6, R7, R9)"
for pin in '## RULING' 'Re-dispatch:' 'Re-dispatch: none' 'Ruled:' \
           'chore(orchestration): <slug> ruling <n>'; do
  assert_in_range "log-entry pin '$pin'" \
    "$ORCH_SKILL" "$pin" "$LOG_ENTRY_LINE" "$LOG_ENTRY_END" exact
done
# The `## RULING` example block's own lines. The bare `## RULING`,
# `Re-dispatch:` and `Ruled:` pins above are short prefixes that the prose of
# this subsection satisfies on its own, so the example block could be deleted
# — fence and all — with the suite green. Pin the header line and the two
# field labels the branch's consumers read, each as a whole line with its
# placeholder tail.
for pin in '## RULING <n> — YYYY-MM-DD — phase <p> — <one-line summary>' \
           'Items: [<id>] <forced|design> — <answer>' \
           'Items: [<id>] escalated (<spec wrong|scope|irreversible|secret|chain>) — <summary>' \
           'Detail: <topic folder>/plans/<slug>-open-decisions.md' \
           'Forks: none | <k> of <planned> (<lens>, <lens>[, <lens>]) — contradiction: none | settled | unsettled' \
           'Re-dispatch: phase <p>, in-run resume <r> of 3'; do
  assert_in_range "RULING example line '$pin'" \
    "$ORCH_SKILL" "$pin" "$LOG_ENTRY_LINE" "$LOG_ENTRY_END" exact
done
assert_in_range "guard pin 'plan governs (orchestrator decision)'" \
  "$ORCH_SKILL" 'plan governs (orchestrator decision)' "$GUARDS_LINE" "$GUARDS_END" exact
assert_in_range_folded "guard fragment forbidding a byte-equal match" \
  "$ORCH_SKILL" 'never as a byte-equal match' "$GUARDS_LINE" "$GUARDS_END"
# The cap sentence's words and punctuation are pinned, its line wrapping is
# not (design R6), so these fragments are matched with the range's line
# wraps folded to spaces. The whole-sentence check is case-sensitive,
# including the colon and the final period, so that rewording or dropping
# the punctuation is caught; the two half-fragments below stay as an
# additional, weaker case-insensitive check.
CAP_SENTENCE='In-run resumes of one phase are capped at 3 per unit: the phase itself in Phase 4, the task in Phase 3.'
assert_in_range_folded_exact "log-entry sentence, byte-exact incl. punctuation" \
  "$ORCH_SKILL" "$CAP_SENTENCE" "$LOG_ENTRY_LINE" "$LOG_ENTRY_END"
# The sentence must also be written without emphasis markers. A marker that
# wraps the sentence (`**In-run resumes … Phase 3.**`) sits AROUND the pinned
# bytes, never inside them, so the match itself can never carry one: this
# check inspects what stands on each side of the match instead. It folds
# through the same helper as the byte-exact check above, so the two can never
# disagree about the text they search. The two failure causes get distinct
# messages.
#
# `fold_range` turns every line wrap into a space, so a marker separated from
# the sentence by a wrap would read as `** In-run resumes …`. The scan
# therefore steps over any spaces before it looks for a `*` run, and tells an
# emphasis marker on the sentence from a neighbouring bold span by the run's
# OTHER side: a `*` run before the match whose own left neighbour is a space
# (or the start of the text) OPENS a span around the sentence, while one whose
# left neighbour is any other character CLOSES an earlier span — the
# paragraph's `**The cap.**` lead-in ends that way and is not emphasis on the
# sentence. The mirror rule applies after the match: a `*` run followed by a
# space (or the end of the text) closes a span around the sentence, while one
# followed by any other character opens a new span, such as a bold lead-in of
# the next sentence.
CAP_SENTENCE_FOLDED="$(fold_range "$ORCH_SKILL" "$LOG_ENTRY_LINE" "$LOG_ENTRY_END")"
CAP_EMPHASIS="$(hay="$CAP_SENTENCE_FOLDED" needle="$CAP_SENTENCE" awk \
  'BEGIN {
     hay = ENVIRON["hay"]; needle = ENVIRON["needle"]
     s = index(hay, needle)
     if (s == 0) { print "missing"; exit }
     i = s - 1
     while (i >= 1 && substr(hay, i, 1) == " ") i--
     if (i >= 1 && substr(hay, i, 1) == "*") {
       while (i >= 1 && substr(hay, i, 1) == "*") i--
       if (i < 1 || substr(hay, i, 1) == " ") { print "emphasis"; exit }
     }
     n = length(hay)
     j = s + length(needle)
     while (j <= n && substr(hay, j, 1) == " ") j++
     if (j <= n && substr(hay, j, 1) == "*") {
       while (j <= n && substr(hay, j, 1) == "*") j++
       if (j > n || substr(hay, j, 1) == " ") { print "emphasis"; exit }
     }
     print "clean"
   }')"
if [ "$CAP_EMPHASIS" = "clean" ]; then
  ok "log-entry sentence carries no '*' emphasis marker around it"
elif [ "$CAP_EMPHASIS" = "emphasis" ]; then
  bad "log-entry sentence is wrapped in a '*' emphasis marker"
else
  bad "log-entry sentence not found in range $LOG_ENTRY_LINE..$LOG_ENTRY_END, so its emphasis could not be checked"
fi
for frag in 'in-run resumes of one phase are capped at 3 per unit' \
            'phase itself in Phase 4, the task in Phase 3'; do
  assert_in_range_folded "log-entry or guard fragment '$frag'" \
    "$ORCH_SKILL" "$frag" "$LOG_ENTRY_LINE" "$LOG_ENTRY_END"
done
assert_in_range "log-entry fragment 'previous invocation left'" \
  "$ORCH_SKILL" 'previous invocation left' "$LOG_ENTRY_LINE" "$LOG_ENTRY_END" fragment
# The pre-commit self-check escalates, never rewrites, a bare `fix it` whose
# clause names binding plan text.
assert_in_range "self-check escalates a bare fix it on binding text" \
  "$ORCH_SKILL" 'escalated (irreversible)' "$LOG_ENTRY_LINE" "$LOG_ENTRY_END" exact
# The Phase 3 cap counts per task number, in either written form.
assert_in_range "cap counts a Phase 3 task in either line form" \
  "$ORCH_SKILL" '`[task <n>]` or `[task <n>/<k>]`' "$LOG_ENTRY_LINE" "$LOG_ENTRY_END" exact
assert_in_range "RULING Forks line carries the planned count" \
  "$ORCH_SKILL" '<k> of <planned>' "$LOG_ENTRY_LINE" "$LOG_ENTRY_END" exact
assert_in_range "guard fragment 'durable marker'" \
  "$ORCH_SKILL" 'durable marker' "$LOG_ENTRY_LINE" "$LOG_ENTRY_END" fragment
for frag in 'a Critical is never rejected' 'quotes its clause' \
            'recorded when it is made'; do
  assert_in_range "guard fragment '$frag'" \
    "$ORCH_SKILL" "$frag" "$GUARDS_LINE" "$GUARDS_END" fragment
done
# Guard 4: a user's decision is never overturned by a ruling. The count word
# is pinned as well, so that dropping guard 4 without renumbering is caught.
assert_in_range_folded_exact "guard count word is 'Four'" \
  "$ORCH_SKILL" 'Four rules apply everywhere a ruling is made' \
  "$GUARDS_LINE" "$GUARDS_END"
assert_in_range "guard 4 states a user decision is never overturned" \
  "$ORCH_SKILL" "A user's decision is never overturned by a ruling" \
  "$GUARDS_LINE" "$GUARDS_END" fragment
for frag in 'read your ruling record' 'recorded answer tagged `(user)`' \
            'under the class that first sent it to the user' \
            'you never re-answer it in the'; do
  assert_in_range "guard 4 fragment '$frag'" \
    "$ORCH_SKILL" "$frag" "$GUARDS_LINE" "$GUARDS_END" fragment
done
assert_in_range_folded "guard 4 escalates when the clause match is unsure" \
  "$ORCH_SKILL" 'an unsure match never becomes a ruling' \
  "$GUARDS_LINE" "$GUARDS_END"
# A follow-up recorded on a `forced` or `design` entry has no escalation class
# of its own, so guard 4 names the fallback label from the same closed list.
assert_in_range_folded "guard 4 names a fallback class for a forced or design entry" \
  "$ORCH_SKILL" 'which has no escalation class of its own' \
  "$GUARDS_LINE" "$GUARDS_END"

# The Phase 3 cap matches the whole bracketed token, so task 1 never counts a
# `[task 12/1]` or a `[task 10]` line.
assert_in_range "cap matches the whole bracketed token" \
  "$ORCH_SKILL" '`[task <n>/` as a prefix' "$LOG_ENTRY_LINE" "$LOG_ENTRY_END" exact
# The test is on the Re-dispatch VALUE; the line itself starts with the label.
assert_in_range_folded "cap tests the Re-dispatch value, not the line's first word" \
  "$ORCH_SKILL" 'whose `Re-dispatch:` value is not `none`' \
  "$LOG_ENTRY_LINE" "$LOG_ENTRY_END"
# The cap's reset anchor: without it the count would run across a stop and the
# fourth ruling of a resumed unit would escalate as a chain that never
# happened.
assert_in_range_folded "cap counts from the later of the invocation line and the last stop" \
  "$ORCH_SKILL" "the orchestration log's latest \`_Invocation\` line and its latest \`## STOPPED\` entry, so that a resume after a stop starts from zero" \
  "$LOG_ENTRY_LINE" "$LOG_ENTRY_END"
# A stop drops no ruling, and skips an entry the user already answered — the
# same Follow-up exclusion the rebuild path in Resume step 3 states.
assert_in_range_folded "a stop skips an entry already carrying a follow-up" \
  "$ORCH_SKILL" 'never an entry that already carries a `**Follow-up:**`' \
  "$LOG_ENTRY_LINE" "$LOG_ENTRY_END"
# Guard 1: the clause the loop supplies is not itself the justification.
assert_in_range_folded "guard 1 says a quotable clause is not by itself a reason" \
  "$ORCH_SKILL" 'quotable clause is not by itself a reason to reject' \
  "$GUARDS_LINE" "$GUARDS_END"
# Guard 4: a clause-less follow-up matches nothing.
assert_in_range_folded "guard 4 ignores a clause-less follow-up" \
  "$ORCH_SKILL" 'quotes NO clause and matches nothing' \
  "$GUARDS_LINE" "$GUARDS_END"

bold "6. Wiring into phases, log format, state.md, Resume and stop policy (R6)"
PHASE3_LINE="$(first_line_of "$ORCH_SKILL" '## Phase 3 — Implementation Batches')"
PHASE4_LINE="$(first_line_of "$ORCH_SKILL" '## Phase 4 — Final Code Review Loop')"
PHASE5_LINE="$(first_line_of "$ORCH_SKILL" '## Phase 5 — Completion')"
LOG_FORMAT_LINE="$(first_line_of "$ORCH_SKILL" '## Orchestration Log Format')"
STATE_LINE="$(first_line_of "$ORCH_SKILL" '## state.md Section')"
RESUME_LINE="$(first_line_of "$ORCH_SKILL" '## Resume')"
# Each phase range mentions `## In-run rulings` more than once — the routing
# sentence itself, and cross-references to rules the section states. So each
# pin below carries bytes of its own routing sentence, folded because every
# one of them crosses a line wrap; a bare 'In-run rulings' fragment would
# survive the deletion of the routing sentence.
assert_in_range_folded "Phase 3 routes BLOCKED task=<n> to the predicate" \
  "$ORCH_SKILL" 'return goes through the Phase 3 discriminator of `## In-run rulings`' \
  "$PHASE3_LINE" "$PHASE4_LINE"
assert_in_range_folded "Phase 4 routes open items to the predicate" \
  "$ORCH_SKILL" '`## In-run rulings`: classify each open item by its review-log id' \
  "$PHASE4_LINE" "$PHASE5_LINE"
assert_in_range_folded "Phase 5 report lists unsettled contradictions" \
  "$ORCH_SKILL" 'every entry whose Forks line records `contradiction: unsettled`' \
  "$PHASE5_LINE" "$LOG_FORMAT_LINE"
# The sibling requirement: an item decided with `accept:` changed no code, so
# the report is the only place the user learns it was accepted.
assert_in_range_folded "Phase 5 report lists every accepted ruling" \
  "$ORCH_SKILL" 'every entry whose Resolution line begins with `accept:`, listed by ruling number' \
  "$PHASE5_LINE" "$LOG_FORMAT_LINE"
# A `BLOCKED task=<n>` return writes no batch entry, so the ruling's own
# `## RULING` entry is the boundary entry Resume step 3 finds the log ending
# with. Without the rule, a batch entry would stand between them and the
# "log ends with `## RULING`" case would never be reached.
assert_in_range_folded "a BLOCKED task return writes no batch log entry" \
  "$ORCH_SKILL" 'A `BLOCKED task=<n>` return writes no batch entry' \
  "$PHASE3_LINE" "$PHASE4_LINE"
# The `Ruled:`, `Open:`, `## RULING` and `Owed probe:` labels also occur in
# the prose below the example blocks, so a bare label pin survives the
# deletion of the example. Pin each field line whole, placeholder tail
# included, so that only the example's own line can satisfy it. (`Owed probe:`
# occurs in the prose too — "one `Owed probe: <verbatim line>` line for every
# …" — but only with a line wrap between `Owed` and `probe:`, so the whole
# field line matches the example's line alone.)
for pin in '## RULING <n> — YYYY-MM-DD — phase <p> — <one-line summary>' \
           'Owed probe: <verbatim line>' \
           'Open: [<id>] escalated (<spec wrong|scope|irreversible|secret|chain>) — <summary>' \
           'Ruled: [<id>] <forced|design> — <answer>'; do
  assert_in_range "log-format example line '$pin'" \
    "$ORCH_SKILL" "$pin" "$LOG_FORMAT_LINE" "$STATE_LINE" exact
done
# Not an example line: the boundary-commit sentence names the two ruling
# subjects, and `ruling <n> follow-up` is the one Resume step 3 writes.
assert_in_range "log format names the follow-up commit subject" \
  "$ORCH_SKILL" 'ruling <n> follow-up' "$LOG_FORMAT_LINE" "$STATE_LINE" exact
# Retained weaker pins: the bare labels alone, in case a later edit moves the
# example's placeholder tails.
for pin in '## RULING' 'Owed probe:'; do
  assert_in_range "log-format label '$pin'" \
    "$ORCH_SKILL" "$pin" "$LOG_FORMAT_LINE" "$STATE_LINE" exact
done
assert_in_range "state.md carries the Rulings line" \
  "$ORCH_SKILL" 'Rulings:' "$STATE_LINE" "$RESUME_LINE" exact
for pin in '## RULING' 'Ruled:' '**Follow-up:**' '(orchestrator)' 'decided (<who>)' \
           'The Phase 3 answer set — one rule'; do
  assert_in_range "resume pin '$pin'" \
    "$ORCH_SKILL" "$pin" "$RESUME_LINE" "$RULINGS_LINE" exact
done
# A bare `(user)` needle would pass against the pre-branch wording, which
# already carried `decided (user)` three times in this range. What this branch
# adds is the per-line tagging of the rebuilt `[RESUME_ANSWER]`, so pin the
# enumerating bytes of that construction instead — the same way the two
# loop-prompt checks in section 9 are pinned.
assert_in_range_folded "Resume step 3 tags the Ruled lines and the user's answers per line" \
  "$ORCH_SKILL" "each tagged \`(orchestrator)\`, plus the resume prompt's answers, each tagged \`(user)\`" \
  "$RESUME_LINE" "$RULINGS_LINE"
# The pre-amendment clause is recovered from the ruling commit, never from the
# audit note's free prose.
assert_in_range "resume recovers the pre-amendment clause from the ruling commit" \
  "$ORCH_SKILL" 'git show <ruling commit>^:<plan path>' "$RESUME_LINE" "$RULINGS_LINE" exact
# The commit-landed check compares whole subjects, because --grep is unanchored.
assert_in_range_folded "resume compares the printed subject with the full expected string" \
  "$ORCH_SKILL" 'compare each printed subject with the full expected string' \
  "$RESUME_LINE" "$RULINGS_LINE"
# What is forbidden is the BARE `decided (user)`, not the label itself: the
# correct wording enumerates both tags, and the sibling files are required to
# carry that enumeration. So a `decided (user)` occurrence fails this check
# only when its own line does not also carry `decided (orchestrator)`.
if [ -n "$RESUME_LINE" ] && [ -n "$RULINGS_LINE" ] && [ "$RESUME_LINE" -lt "$RULINGS_LINE" ] && \
   awk -v a="$RESUME_LINE" -v b="$RULINGS_LINE" \
     'NR >= a && NR < b && index($0, "decided (user)") > 0 && index($0, "decided (orchestrator)") == 0 { found = 1 } END { exit found ? 1 : 0 }' "$ORCH_SKILL"; then
  ok "Resume step 3 never names decided (user) without decided (orchestrator) beside it"
else
  bad "Resume step 3 names a bare decided (user), or the range $RESUME_LINE..$RULINGS_LINE is empty or inverted"
fi
# The revert step produces the commit hash itself, under the same
# exact-subject filter as the landed-check, and copies only the clause out of
# the printed file.
assert_in_range "resume ruling-commit lookup prints the hash" \
  "$ORCH_SKILL" 'git log --format="%H %s" --grep "<slug> ruling <n>"' \
  "$RESUME_LINE" "$RULINGS_LINE" exact
assert_in_range_folded "resume ruling-commit lookup keeps exactly one subject" \
  "$ORCH_SKILL" 'Exactly one line must survive' "$RESUME_LINE" "$RULINGS_LINE"
assert_in_range_folded "resume copies the clause, never the whole printed file" \
  "$ORCH_SKILL" 'never write that output over the plan file' \
  "$RESUME_LINE" "$RULINGS_LINE"
# An amendment marker with no ruling-record entry is reverted, never left
# standing as decided wording.
assert_in_range_folded "resume reverts an orphan amendment marker" \
  "$ORCH_SKILL" 'is an inconsistent state whatever the log ends with' \
  "$RESUME_LINE" "$RULINGS_LINE"

for frag in 'escalated' 'fork review unavailable'; do
  assert_in_range "stop policy fragment '$frag'" \
    "$ORCH_SKILL" "$frag" "$RULINGS_END" "$GUARD_LINE" fragment
done
# A `stopped` commit can be made over a deliberately dirty tree, so its staging
# is stated once, in the stop policy, and both `stopped` commit sites point at
# it. Without the rule a sweeping stage commits the blocked task's unreviewed
# work.
assert_in_range "stop policy states the stopped commit's staging rule" \
  "$ORCH_SKILL" '**Every `stopped` commit stages by explicit path.**' \
  "$RULINGS_END" "$GUARD_LINE" exact
# The prohibition itself, carrying its verb and all three commands. A bare
# presence pin cannot tell a prohibition from a recommendation — text telling
# the orchestrator to USE `git add -A` would satisfy one just as well — and
# `git add .` is a substring of any explicit-path command that begins with a
# dot, so a compliant example command would satisfy that one on its own. The
# sentence wraps between `git add -A` and `and never`, so it is folded.
assert_in_range_folded "stop policy forbids the three sweeping stage commands" \
  "$ORCH_SKILL" 'Never `git add -A` and never `git add .`, and never `git commit -a`.' \
  "$RULINGS_END" "$GUARD_LINE"
# The three bare pins stay as additional, weaker checks on the spelling of
# each command.
for pin in 'git add -A' 'git add .' 'git commit -a'; do
  assert_in_range "stop policy names '$pin' for a stopped commit" \
    "$ORCH_SKILL" "$pin" "$RULINGS_END" "$GUARD_LINE" exact
done
assert_in_range_folded "stop policy names the only files a stopped commit stages" \
  "$ORCH_SKILL" 'the orchestration log and, when it is committed together with the log, `state.md`' \
  "$RULINGS_END" "$GUARD_LINE"
# Both `stopped` commit sites refer to that one rule.
assert_in_range_folded "the Resume rebuild path stages its stopped commit by explicit path" \
  "$ORCH_SKILL" "staging by explicit path under the Major-Error Stop Policy's rule" \
  "$RESUME_LINE" "$RULINGS_LINE"
assert_in_range_folded "the escalated-return stop stages its stopped commit by explicit path" \
  "$ORCH_SKILL" 'stages by explicit path under the Major-Error Stop Policy' \
  "$LOG_ENTRY_LINE" "$LOG_ENTRY_END"
if [ -n "$RULINGS_END" ] && [ -n "$GUARD_LINE" ] && [ "$RULINGS_END" -lt "$GUARD_LINE" ] && \
   awk -v a="$RULINGS_END" -v b="$GUARD_LINE" \
     'NR >= a && NR < b && index(tolower($0), "pre-flight plan conflict") > 0 { found = 1 } END { exit found ? 1 : 0 }' "$ORCH_SKILL"; then
  ok "stop policy no longer lists a pre-flight plan conflict as a stop by itself"
else
  bad "stop policy still lists 'pre-flight plan conflict', or the range $RULINGS_END..$GUARD_LINE is empty or inverted"
fi

bold "7. multi-code-review attribution and self-sufficient lines (R8.1, R8.2)"
MCR_LOG_FORMAT_LINE="$(first_line_of "$MCR_SKILL" '## Review Log Format')"
MCR_AFTER_LOOP_LINE="$(first_line_of "$MCR_SKILL" '## After the Loop')"
MCR_ERROR_HANDLING_LINE="$(first_line_of "$MCR_SKILL" '## Error Handling')"
for pin in '— clause:' 'clause: none' '(plan-mandated) — at ' \
           'cut it to 160 characters' '**Normalization is one rule:**' \
           'one sentence or one list entry, never a whole section' \
           'tests the quote as a **prefix**' \
           'No consumer compares the quote with the raw plan text'; do
  assert_in_range "multi-code-review pin '$pin'" \
    "$MCR_SKILL" "$pin" "$MCR_LOG_FORMAT_LINE" "$MCR_AFTER_LOOP_LINE" exact
done
for pin in 'decided (orchestrator)' 'decided (<who>)' \
           'plan governs (orchestrator decision)' 'plan governs (user decision)' \
           '`decided (user)` or `decided (orchestrator)`' \
           'unresolved: fix contradicts binding text'; do
  assert_in_range "multi-code-review pin '$pin'" \
    "$MCR_SKILL" "$pin" "$MCR_AFTER_LOOP_LINE" "$MCR_ERROR_HANDLING_LINE" exact
done
MCR_FORMAT_LINE="$(line_containing_after "$MCR_SKILL" '_Invocation <k> — YYYY-MM-DD — N=<n> M=<m>' 0)"
MCR_FORMAT_END="$(line_containing_after "$MCR_SKILL" 'Round entry with M ≥ 2' "$MCR_FORMAT_LINE")"
MCR_M2_END="$(line_starting_with_after "$MCR_SKILL" '```' "$(line_starting_with_after "$MCR_SKILL" '```' "$MCR_FORMAT_END")")"
assert_in_range "M = 1 log-format example carries the clause" \
  "$MCR_SKILL" 'user-decision — <finding summary> (plan-mandated) — at <file:line> — clause:' \
  "$MCR_FORMAT_LINE" "$MCR_FORMAT_END" exact
assert_in_range "M >= 2 log-format example carries the clause before the annotation" \
  "$MCR_SKILL" '— clause: <plan location> "<quoted plan text>" ← 1/3: r1:I1' \
  "$MCR_FORMAT_END" "$((MCR_M2_END + 1))" exact

# Normalization is one rule of three operations, stated the same way on the
# writer's side.
assert_in_range "multi-code-review normalization replaces a double quotation mark" \
  "$MCR_SKILL" "replace each \`\"\` with a single quotation mark \`'\`" \
  "$MCR_LOG_FORMAT_LINE" "$MCR_AFTER_LOOP_LINE" exact
assert_in_range_folded "multi-code-review names all three replacements as one rule" \
  "$MCR_SKILL" 'All THREE replacements belong to the one rule' \
  "$MCR_LOG_FORMAT_LINE" "$MCR_AFTER_LOOP_LINE"
# A post-loop `unresolved:` addendum line carries no source annotation either.
assert_in_range "addendum shapes include an unresolved line" \
  "$MCR_SKILL" 'addendum `unresolved: …`' \
  "$MCR_LOG_FORMAT_LINE" "$MCR_AFTER_LOOP_LINE" exact
# The binding-text test is stated where the refusal rule lives, so the loop
# and the answerer apply one test.
assert_in_range_folded "the binding-text test is stated where the refusal rule lives" \
  "$MCR_SKILL" 'Which text is binding — one test' \
  "$MCR_AFTER_LOOP_LINE" "$MCR_ERROR_HANDLING_LINE"
assert_in_range "binding-text test names the Exact content block" \
  "$MCR_SKILL" '`**Exact content:**` block' \
  "$MCR_AFTER_LOOP_LINE" "$MCR_ERROR_HANDLING_LINE" exact
# The tag-to-`<who>` mapping on the loop's own side. The pins above assert
# only that the three tag tokens occur somewhere in this 187-line range, and
# unrelated sentences in it produce those same tokens, so the mapping itself
# could be reworded away with the suite green. The sibling rule is pinned on
# the template side in section 9; these two pin the skill side.
assert_in_range_folded "loop reads the answer line's tag, and treats an untagged line as a user line" \
  "$MCR_SKILL" 'tagged `(orchestrator)` or `(user)`; an untagged line is a user line' \
  "$MCR_AFTER_LOOP_LINE" "$MCR_ERROR_HANDLING_LINE"
assert_in_range_folded "loop takes <who> from that tag" \
  "$MCR_SKILL" 'or `decided (user): <answer>`, `<who>` taken from the tag' \
  "$MCR_AFTER_LOOP_LINE" "$MCR_ERROR_HANDLING_LINE"
# The two orchestrator-answer mappings this branch adds. They decide whether a
# fix subagent runs at all and whether an item still counts as unresolved, and
# nothing else in the suite asserts either of them.
assert_in_range "the accept disposition shape" \
  "$MCR_SKILL" '`decided (<who>): accept:' \
  "$MCR_AFTER_LOOP_LINE" "$MCR_ERROR_HANDLING_LINE" exact
assert_in_range_folded "an accept answer runs no fix and no re-review, and stops counting as unresolved" \
  "$MCR_SKILL" 'line is its whole disposition, it no longer counts as unresolved, and no fix or re-review runs' \
  "$MCR_AFTER_LOOP_LINE" "$MCR_ERROR_HANDLING_LINE"
assert_in_range_folded "an amend plan answer takes the finding-governs path for its fix it part" \
  "$MCR_SKILL" 'An `amend plan: …; fix it: …` answer takes the finding-governs path for its `fix it` part' \
  "$MCR_AFTER_LOOP_LINE" "$MCR_ERROR_HANDLING_LINE"
assert_in_range_folded "that path skips the verification re-review, because a new invocation follows" \
  "$MCR_SKILL" 'the verification re-review is skipped and the new invocation that always follows reviews the fix' \
  "$MCR_AFTER_LOOP_LINE" "$MCR_ERROR_HANDLING_LINE"

bold "8. Loop-side rule for verification cycles (R8.3)"
NO_FIX_LINE="$(line_containing_after "$MCR_SKILL" '**No fix ships unreviewed:**' 0)"
NO_FIX_END="$(line_starting_with_after "$MCR_SKILL" '## ' "$NO_FIX_LINE")"
assert_in_range "loop-decision rejection shape" \
  "$MCR_SKILL" 'plan governs (loop decision)' "$NO_FIX_LINE" "$NO_FIX_END" exact
for frag in 'a Critical is never rejected under this rule' 'decided wording' \
            '(amended by ruling' 'same BASE' 'never edits plan text' \
            '3-cycle cap is unchanged'; do
  assert_in_range "loop-side rule fragment '$frag'" \
    "$MCR_SKILL" "$frag" "$NO_FIX_LINE" "$NO_FIX_END" fragment
done
# The loop verifies an `(amended by ruling <n>)` marker against the ruling
# record before granting the clause decided-wording authority — the same rule
# the orchestrator states under "The ruling record" (section 4).
assert_in_range "loop bounds the marker's authority to a backing entry" \
  "$MCR_SKILL" '**A marker is authority only while the ruling record backs it.**' \
  "$NO_FIX_LINE" "$NO_FIX_END" exact
assert_in_range "loop names the ruling-record path it checks the marker against" \
  "$MCR_SKILL" '<TOPIC_DIR>/plans/<slug>-open-decisions.md' \
  "$NO_FIX_LINE" "$NO_FIX_END" exact
assert_in_range_folded "loop treats an unbacked marker as reference text" \
  "$MCR_SKILL" 'the marker is **reference text**' "$NO_FIX_LINE" "$NO_FIX_END"
# The same whole-number comparison the orchestrator states (section 4): a
# prefix match would let ruling 10's entry back an `(amended by ruling 1)`
# marker.
assert_in_range_folded "loop compares the marker's ruling number as a whole number" \
  "$MCR_SKILL" 'compared as a whole number, so ruling 1 is not matched by a `## Ruling 10` heading' \
  "$NO_FIX_LINE" "$NO_FIX_END"
assert_in_range_folded "loop covers the no-TOPIC_DIR case, where no record exists" \
  "$MCR_SKILL" 'the loop was called without `TOPIC_DIR`' \
  "$NO_FIX_LINE" "$NO_FIX_END"

bold "9. Controller prompt templates (R10)"
# Deviation 3's secret EXCEPTION writes one fixed leading form, because that
# text is what the orchestrator's `secret` escalation class matches. Scope the
# pins to Deviation 3's own range: the words also occur in the triage rule
# above it.
LOOP_DEV3_LINE="$(line_containing_after "$LOOP_PROMPT" '3. Triage rule:' 0)"
LOOP_DEV3_END="$(line_containing_after "$LOOP_PROMPT" '4. Reviewer blinding:' "$LOOP_DEV3_LINE")"
assert_in_range "Deviation 3 pins the fixed secret disposition form" \
  "$LOOP_PROMPT" \
  'unresolved: exposed secret or credential in an orchestration artifact — <file:line>' \
  "$LOOP_DEV3_LINE" "$LOOP_DEV3_END" exact
assert_in_range_folded "Deviation 3 says the leading text is fixed" \
  "$LOOP_PROMPT" 'fixed leading form' "$LOOP_DEV3_LINE" "$LOOP_DEV3_END"
assert_in_range_folded "Deviation 3 names the real mechanism: the secret class stops the run" \
  "$LOOP_PROMPT" "the orchestrator's \`secret\` escalation class matches that leading text and stops the run" \
  "$LOOP_DEV3_LINE" "$LOOP_DEV3_END"
assert_in_range_folded "Deviation 3 forbids copying the value into the line" \
  "$LOOP_PROMPT" 'Never copy the value itself' "$LOOP_DEV3_LINE" "$LOOP_DEV3_END"
LOOP_RA_LINE="$(line_containing_after "$LOOP_PROMPT" '`[RESUME_ANSWER]` — OPTIONAL' 0)"
LOOP_RA_END="$(line_containing_after "$LOOP_PROMPT" '**Nothing else may be added to the prompt.**' "$LOOP_RA_LINE")"
# A bare '(user)' needle would pass against the pre-branch wording, which
# already contained `decided (user)`. The per-line tagging this branch adds
# is pinned by the enumeration itself.
for pin in '(orchestrator)' '`(orchestrator)` or `(user)`' 'decided (<who>)'; do
  assert_in_range "code-review-loop [RESUME_ANSWER] doc pin '$pin'" \
    "$LOOP_PROMPT" "$pin" "$LOOP_RA_LINE" "$LOOP_RA_END" exact
done
assert_in_range "code-review-loop [RESUME_ANSWER] doc says authoritative either way" \
  "$LOOP_PROMPT" 'authoritative either way' "$LOOP_RA_LINE" "$LOOP_RA_END" fragment
LOOP_DEV5_LINE="$(line_containing_after "$LOOP_PROMPT" '5. Resume answer:' 0)"
LOOP_RETURN_LINE="$(line_containing_after "$LOOP_PROMPT" '## Return' "$LOOP_DEV5_LINE")"
# Same reason as above: the bare '(user)' needle is replaced by bytes that
# exist only in the new per-line tagging wording.
for pin in '(orchestrator)' 'tagged `(orchestrator)` or `(user)`' 'decided (<who>)' \
           '`decided (user)` or `decided (orchestrator)`'; do
  assert_in_range "code-review-loop Deviation 5 pin '$pin'" \
    "$LOOP_PROMPT" "$pin" "$LOOP_DEV5_LINE" "$LOOP_RETURN_LINE" exact
done
# An answer line with no tag belongs to the user; the orchestrator states the
# same rule under "The answers, and how a ruling reaches the plan".
assert_in_range_folded "code-review-loop Deviation 5 treats an untagged line as a user line" \
  "$LOOP_PROMPT" 'an untagged line is a user line' \
  "$LOOP_DEV5_LINE" "$LOOP_RETURN_LINE"
BATCH_RA_LINE="$(line_containing_after "$BATCH_PROMPT" '`[RESUME_ANSWER]` — OPTIONAL' 0)"
# The section heading's condition for omitting the section must match the
# placeholder documentation's: no answer recorded by the run at all.
assert_in_range "batch-controller Resume Answer heading states the omit condition" \
  "$BATCH_PROMPT" '## Resume Answer (omit only when the run has recorded no answer at all)' \
  1 "$BATCH_RA_LINE" exact
BATCH_RA_END="$(line_containing_after "$BATCH_PROMPT" '**Nothing else may be added to the prompt.**' "$BATCH_RA_LINE")"
for pin in '(orchestrator)' '(user)' '[task <n>/<k>]'; do
  assert_in_range "batch-controller [RESUME_ANSWER] doc pin '$pin'" \
    "$BATCH_PROMPT" "$pin" "$BATCH_RA_LINE" "$BATCH_RA_END" exact
done
assert_in_range "batch-controller [RESUME_ANSWER] doc says authoritative either way" \
  "$BATCH_PROMPT" 'authoritative either way' "$BATCH_RA_LINE" "$BATCH_RA_END" fragment
# The answer set is run-wide, not batch-wide: a pre-flight conflict ruled
# during an earlier batch must still reach the later batch that implements
# another task it touches.
assert_in_range_folded "batch-controller [RESUME_ANSWER] carries the run-wide answer set" \
  "$BATCH_PROMPT" 'with every answer the run has recorded so far, whatever batch its task belongs to' \
  "$BATCH_RA_LINE" "$BATCH_RA_END"
# The First-batch parameter states the pre-flight rule once, by pointing at
# Deviation 1, so the two copies cannot diverge again.
assert_in_range "First-batch parameter defers to Deviation 1's pre-flight rule" \
  "$BATCH_PROMPT" "under Deviation 1's pre-flight rule" 1 "$BATCH_RA_LINE" exact
# Several needles above (e.g. 'is settled', 'lowest-numbered task',
# '### Question <k>', '### Conflict <k>') also occur elsewhere in the file
# outside Deviation 1, so a whole-file byte pin would still pass with the
# owning rule deleted. Scope them, and the newer Deviation 1 rules below, to
# Deviation 1's own range.
DEV1_LINE="$(line_containing_after "$BATCH_PROMPT" '1. Never ask the user.' 0)"
DEV1_END="$(line_containing_after "$BATCH_PROMPT" '2. Sequential only' "$DEV1_LINE")"
for pin in '### Question <k>' '### Conflict <k>' 'lowest-numbered task' \
           'Pre-flight rule' 'absent from' \
           '.superpowers/sdd/task-<n>-report.md' 'is settled' \
           'Never copy a secret or a credential' 're-used on the same task' \
           'those sections before you write your own' 'controller failure' \
           '[task <n>]` line means `[task <n>/1]'; do
  assert_in_range "batch-controller Deviation 1 pin '$pin'" \
    "$BATCH_PROMPT" "$pin" "$DEV1_LINE" "$DEV1_END" exact
done

# The implementer rewrites the task report file, so an earlier attempt's
# sections may be gone: a new section number is allocated above the highest
# `<k>` still visible, and a section written in this dispatch is never
# renumbered afterwards.
assert_in_range_folded "Deviation 1 allocates a new section number above the highest visible one" \
  "$BATCH_PROMPT" 'number a new section 1 above the highest `<k>` you can see' \
  "$DEV1_LINE" "$DEV1_END"
assert_in_range_folded "Deviation 1 never renumbers a section written in this dispatch" \
  "$BATCH_PROMPT" 'never renumber a section you wrote in this dispatch' \
  "$DEV1_LINE" "$DEV1_END"

# The stale-section deletion keys on work this run produced, never on the
# absence of an answer line — the run-wide answer set fills those in for
# tasks that were ruled on but not yet dispatched.
assert_in_range "Deviation 1 keys the stale-section deletion on this run's own work" \
  "$BATCH_PROMPT" 'no completed ledger line' "$DEV1_LINE" "$DEV1_END" exact
# The negation belongs in the needle: without the two words "never by", the
# rule reads as the opposite instruction and the controller would delete a
# task's already-answered report sections. The words wrap, so this is folded;
# the byte pin below stays as the weaker spelling check.
assert_in_range_folded "Deviation 1 rejects the answer line as the first-dispatch signal" \
  "$BATCH_PROMPT" 'never by the absence of a `[task <n>…]` line in `## Resume Answer`' \
  "$DEV1_LINE" "$DEV1_END"
assert_in_range "Deviation 1 spells the rejected first-dispatch signal exactly" \
  "$BATCH_PROMPT" 'the absence of a `[task <n>…]` line in `## Resume Answer`' \
  "$DEV1_LINE" "$DEV1_END" exact
# A re-derived pre-flight conflict re-uses the `<k>` it was answered under.
for pin in 're-use that `<k>`, apply the answer' 'Allocate a new `<k>` only for a'; do
  assert_in_range "batch-controller re-derived conflict pin '$pin'" \
    "$BATCH_PROMPT" "$pin" "$DEV1_LINE" "$DEV1_END" exact
done

# --- end of checks ---

echo
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
exit 0
