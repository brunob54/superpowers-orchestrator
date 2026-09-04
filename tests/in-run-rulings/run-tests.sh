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
  folded="$(awk -v a="$start" -v b="$end" \
    'NR >= a && NR < b { line = $0; sub(/^[ \t]+/, "", line); printf "%s ", line }' "$file")"
  if awk -v needle="$needle" -v hay="$folded" \
    'BEGIN { exit index(tolower(hay), tolower(needle)) > 0 ? 0 : 1 }'; then
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
  folded="$(awk -v a="$start" -v b="$end" \
    'NR >= a && NR < b { line = $0; sub(/^[ \t]+/, "", line); printf "%s ", line }' "$file")"
  if awk -v needle="$needle" -v hay="$folded" \
    'BEGIN { exit index(hay, needle) > 0 ? 0 : 1 }'; then
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
INTERLOPER="$(awk -v a="$RULINGS_LINE" -v b="$RULINGS_END" \
  'NR > a && NR < b { if ($0 ~ /^```/) { fence = !fence } else if (!fence && index($0, "## ") == 1) { print NR; exit } }' \
  "$ORCH_SKILL")"
if [ -z "$INTERLOPER" ]; then
  ok "no other '## ' heading (outside a fenced code block) between $RULINGS_LINE and $RULINGS_END"
else
  bad "an unexpected '## ' heading sits at line $INTERLOPER, between $RULINGS_LINE and $RULINGS_END"
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
for pin in 'subagent_type: "fork"' '<!-- multi-review report -->' 'fork-<lens>' \
           'fork review unavailable' 'contradiction: unsettled'; do
  assert_in_range "fork pin '$pin'" \
    "$ORCH_SKILL" "$pin" "$RULINGS_LINE" "$RULINGS_END" exact
done
# 'VERDICT:' and 'TABLED:' also occur as prose in the "Classification" section
# above (its escalation-predicate text mentions both words), so pinning them
# to the whole ## In-run rulings range would pass even without the fork
# subsection. Scope them to the fork subsection itself, whose end is the next
# `### ` heading after it, or the section end when there is none.
FORK_LINE="$(first_line_of "$ORCH_SKILL" '### Fork review for a design item')"
FORK_END="$(line_starting_with_after "$ORCH_SKILL" '### ' "$FORK_LINE")"
if [ -z "$FORK_END" ] || [ "$FORK_END" -gt "$RULINGS_END" ]; then
  FORK_END="$RULINGS_END"
fi
for pin in 'VERDICT:' 'TABLED:'; do
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
GUARD_LINE="$(first_line_of "$ORCH_SKILL" '## Guard Interaction')"
TEMPLATES_LINE="$(first_line_of "$ORCH_SKILL" '## Prompt Templates')"
assert_in_range "Guard Interaction names the forks' marker" \
  "$ORCH_SKILL" 'fork' "$GUARD_LINE" "$TEMPLATES_LINE" fragment
assert_in_range "Guard Interaction names the forks' return marker exactly" \
  "$ORCH_SKILL" '<!-- multi-review report -->' "$GUARD_LINE" "$TEMPLATES_LINE" exact

# The fork prompt states the same negative diff flags as the read exception.
assert_in_range "fork prompt mandates the negative diff flags" \
  "$ORCH_SKILL" 'git diff --no-ext-diff --no-textconv <BASE>..HEAD -- <path>' \
  "$FORK_LINE" "$FORK_END" exact
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
for frag in '(amended by ruling' 'never apply the amendment twice' \
            'new invocation' 'untagged' 'sides against binding plan text' \
            '**The quoted clause, and how it is compared.**' \
            'test whether the quote is a prefix of it'; do
  assert_in_range "answer fragment '$frag'" \
    "$ORCH_SKILL" "$frag" "$ANSWERS_LINE" "$ANSWERS_END" fragment
done
# The bound on a plan amendment: it never deletes binding text, it appends a
# scoped exception. Both fragments cross a line wrap, so they are folded.
assert_in_range_folded "amendment never deletes binding text outright" \
  "$ORCH_SKILL" 'never **deletes** binding text outright' \
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
CAP_SENTENCE_FOLDED="$(awk -v a="$LOG_ENTRY_LINE" -v b="$LOG_ENTRY_END" \
  'NR >= a && NR < b { printf "%s ", $0 }' "$ORCH_SKILL")"
if awk -v hay="$CAP_SENTENCE_FOLDED" -v needle="$CAP_SENTENCE" \
  'BEGIN { s = index(hay, needle); if (s == 0) exit 1; span = substr(hay, s, length(needle)); exit index(span, "*") > 0 ? 1 : 0 }'; then
  ok "log-entry sentence carries no '*' emphasis marker"
else
  bad "log-entry sentence carries a '*' emphasis marker, or the sentence could not be located"
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
assert_in_range "Phase 3 routes BLOCKED task=<n> to the predicate" \
  "$ORCH_SKILL" 'In-run rulings' "$PHASE3_LINE" "$PHASE4_LINE" fragment
assert_in_range "Phase 4 routes open items to the predicate" \
  "$ORCH_SKILL" 'In-run rulings' "$PHASE4_LINE" "$PHASE5_LINE" fragment
assert_in_range "Phase 5 report lists unsettled contradictions" \
  "$ORCH_SKILL" 'contradiction: unsettled' "$PHASE5_LINE" "$LOG_FORMAT_LINE" fragment
for pin in '## RULING' 'Ruled:' 'Open:' 'Owed probe:' 'ruling <n> follow-up'; do
  assert_in_range "log-format pin '$pin'" \
    "$ORCH_SKILL" "$pin" "$LOG_FORMAT_LINE" "$STATE_LINE" exact
done
assert_in_range "state.md carries the Rulings line" \
  "$ORCH_SKILL" 'Rulings:' "$STATE_LINE" "$RESUME_LINE" exact
for pin in '## RULING' 'Ruled:' '**Follow-up:**' '(orchestrator)' '(user)' 'decided (<who>)' \
           'The Phase 3 answer set — one rule'; do
  assert_in_range "resume pin '$pin'" \
    "$ORCH_SKILL" "$pin" "$RESUME_LINE" "$RULINGS_LINE" exact
done
# The pre-amendment clause is recovered from the ruling commit, never from the
# audit note's free prose.
assert_in_range "resume recovers the pre-amendment clause from the ruling commit" \
  "$ORCH_SKILL" 'git show <ruling commit>^:<plan path>' "$RESUME_LINE" "$RULINGS_LINE" exact
# The commit-landed check compares whole subjects, because --grep is unanchored.
assert_in_range_folded "resume compares the printed subject with the full expected string" \
  "$ORCH_SKILL" 'compare each printed subject with the full expected string' \
  "$RESUME_LINE" "$RULINGS_LINE"
if [ -n "$RESUME_LINE" ] && [ -n "$RULINGS_LINE" ] && [ "$RESUME_LINE" -lt "$RULINGS_LINE" ] && \
   awk -v a="$RESUME_LINE" -v b="$RULINGS_LINE" \
     'NR >= a && NR < b && index($0, "decided (user)") > 0 { found = 1 } END { exit found ? 1 : 0 }' "$ORCH_SKILL"; then
  ok "Resume step 3 no longer names decided (user) alone"
else
  bad "Resume step 3 still names decided (user) alone, or the range $RESUME_LINE..$RULINGS_LINE is empty or inverted"
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

bold "9. Controller prompt templates (R10)"
LOOP_RA_LINE="$(line_containing_after "$LOOP_PROMPT" '`[RESUME_ANSWER]` — OPTIONAL' 0)"
LOOP_RA_END="$(line_containing_after "$LOOP_PROMPT" '**Nothing else may be added to the prompt.**' "$LOOP_RA_LINE")"
for pin in '(orchestrator)' '(user)' 'decided (<who>)'; do
  assert_in_range "code-review-loop [RESUME_ANSWER] doc pin '$pin'" \
    "$LOOP_PROMPT" "$pin" "$LOOP_RA_LINE" "$LOOP_RA_END" exact
done
assert_in_range "code-review-loop [RESUME_ANSWER] doc says authoritative either way" \
  "$LOOP_PROMPT" 'authoritative either way' "$LOOP_RA_LINE" "$LOOP_RA_END" fragment
LOOP_DEV5_LINE="$(line_containing_after "$LOOP_PROMPT" '5. Resume answer:' 0)"
LOOP_RETURN_LINE="$(line_containing_after "$LOOP_PROMPT" '## Return' "$LOOP_DEV5_LINE")"
for pin in '(orchestrator)' '(user)' 'decided (<who>)' \
           '`decided (user)` or `decided (orchestrator)`'; do
  assert_in_range "code-review-loop Deviation 5 pin '$pin'" \
    "$LOOP_PROMPT" "$pin" "$LOOP_DEV5_LINE" "$LOOP_RETURN_LINE" exact
done
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

# The stale-section deletion keys on work this run produced, never on the
# absence of an answer line — the run-wide answer set fills those in for
# tasks that were ruled on but not yet dispatched.
assert_in_range "Deviation 1 keys the stale-section deletion on this run's own work" \
  "$BATCH_PROMPT" 'no completed ledger line' "$DEV1_LINE" "$DEV1_END" exact
assert_in_range "Deviation 1 rejects the answer line as the first-dispatch signal" \
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
