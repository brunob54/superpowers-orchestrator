#!/usr/bin/env bash
# measure-context test suite: unit tests on tools/measure-context.js, the
# committed script that takes the acceptance measure of worklist row 13 fix 1
# (docs/orchestration-issues.md, Cases 017 and 018). Pure bash + node; no
# claude invocation.
# Windows note: never reads standard input through its device path and uses
# no process substitution (neither is reliable in Git Bash on Windows) —
# everything goes through temp files.
#
# The fixture `fixtures/synthetic.jsonl` is built so that every class holds a
# different, hand-chosen number of bytes, and so that one requestId is written
# three times with the same usage object. That repetition is the counting trap
# the script exists to avoid: a naive sum over records overcounts tokens by 3
# to 5 times on a real transcript.

set -u
# Stop the suite when a command is not found; the file explains the reason.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/undefined-command-guard.sh"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/tools/measure-context.js"
FIX="$ROOT/tests/measure-context/fixtures"
FIXTURE="$FIX/synthetic.jsonl"
# Row 27 fixtures (see the comment before section 7).
FIX_PAGED_TO_END="$FIX/read-paged-to-end.jsonl"
FIX_PAGED_SHORT="$FIX/read-paged-short.jsonl"
FIX_NOT_PAGED="$FIX/read-not-paged.jsonl"
FIX_CAT_GAPS="$FIX/cat-persisted-gaps.jsonl"
FIX_SKILL="$FIX/skill-call.jsonl"
FIX_OPEN_RANGE="$FIX/open-range.jsonl"
FIX_CAT_THEN_READ="$FIX/cat-then-read-cut.jsonl"
# The on-disk fixture reads two real files from the fixtures directory, so
# the template's @@FIX@@ is replaced with that directory at run time.
FIX_ON_DISK_TEMPLATE="$FIX/pipeline-on-disk.template.jsonl"

# The fixture's hand-chosen byte counts, by class.
EXP_AGENT_PROMPTS=100
EXP_FILL_COMMANDS=48
EXP_VALUE_FILES=50
EXP_OTHER_WRITES=30
EXP_BASH_COMMANDS=20
EXP_READ_RESULTS=40
EXP_BASH_RESULTS=25
EXP_AGENT_REPORTS=15
EXP_ATTACHMENTS=60
EXP_USER_MESSAGES=10
EXP_ASSISTANT_TEXT=12
EXP_CONTENT=459
EXP_PROMPT_MATERIAL=198
# The fixture holds three distinct requests, at 1110, 5000 and 2000 context
# tokens. The peak is the largest single request, never their sum (8110), and
# never inflated by the three records that repeat request 2.
EXP_PEAK=5000
EXP_ASSISTANT_RECORDS=5
EXP_DISTINCT_REQUESTS=3
EXP_SUM_OF_REQUESTS=8110
# The prompt-material line names its three components; the issues log cites it.
EXP_PROMPT_LINE='agent-prompts + fill-commands + value-files'

PASS=0
FAIL=0
ERRORS=()
WORK="$(mktemp -d)"
: "${WORK:?mktemp failed — refusing to run with an empty work path}"
trap 'rm -rf "$WORK"' EXIT
OUTF="$WORK/stdout.txt"
ERRF="$WORK/stderr.txt"
JSONF="$WORK/measure.json"
STATUS=0

green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
red()   { printf '\033[0;31m%s\033[0m\n' "$1"; }
bold()  { printf '\033[1m%s\033[0m\n' "$1"; }

ok()  { green "  PASS: $1"; PASS=$((PASS+1)); }
bad() { red "  FAIL: $1"; ERRORS+=("$1"); FAIL=$((FAIL+1)); }

assert_eq() { # desc actual expected
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi
}
assert_file_contains() { # desc file needle
  if grep -qF -- "$3" "$2"; then ok "$1"; else bad "$1 (missing: $3)"; fi
}
assert_file_has_line() { # desc file line (the whole line, byte-exact)
  if grep -qxF -- "$3" "$2"; then ok "$1"; else bad "$1 (no such line: $3)"; fi
}
assert_file_not_contains() { # desc file needle
  if grep -qF -- "$3" "$2"; then bad "$1 (must not contain: $3)"; else ok "$1"; fi
}

# Read one field out of the JSON report with node, so the test never parses
# JSON with grep.
field() { # dotted-path
  node -e '
    const fs = require("fs");
    const data = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    const value = process.argv[2].split(".").reduce((o, k) => (o === undefined ? o : o[k]), data);
    process.stdout.write(String(value));
  ' "$JSONF" "$1"
}

run_json() { # transcript
  node "$SCRIPT" "$1" --json >"$JSONF" 2>"$ERRF"
  STATUS=$?
}
run_text() { # transcript
  node "$SCRIPT" "$1" >"$OUTF" 2>"$ERRF"
  STATUS=$?
}

bold "1. The script runs on the fixture and reports every class"
run_json "$FIXTURE"
assert_eq "exits 0 on a readable transcript" "$STATUS" "0"
assert_eq "agent-prompts counts the Agent tool's prompt field" "$(field totals.agent-prompts)" "$EXP_AGENT_PROMPTS"
assert_eq "fill-commands counts a Bash command that fills a template" "$(field totals.fill-commands)" "$EXP_FILL_COMMANDS"
assert_eq "value-files counts a Write to a dispatch-<k>- file" "$(field totals.value-files)" "$EXP_VALUE_FILES"
assert_eq "other-writes counts a Write to any other path" "$(field totals.other-writes)" "$EXP_OTHER_WRITES"
assert_eq "bash-commands counts a Bash command that is not a fill" "$(field totals.bash-commands)" "$EXP_BASH_COMMANDS"
assert_eq "read-results are attributed to the Read tool by tool_use_id" "$(field totals.read-results)" "$EXP_READ_RESULTS"
assert_eq "bash-results are attributed to the Bash tool by tool_use_id" "$(field totals.bash-results)" "$EXP_BASH_RESULTS"
assert_eq "agent-reports are attributed to the Agent tool by tool_use_id" "$(field totals.agent-reports)" "$EXP_AGENT_REPORTS"
assert_eq "attachments count the harness attachment records" "$(field totals.attachments)" "$EXP_ATTACHMENTS"
assert_eq "user-messages count a plain string message" "$(field totals.user-messages)" "$EXP_USER_MESSAGES"
assert_eq "assistant-text counts the model's own prose" "$(field totals.assistant-text)" "$EXP_ASSISTANT_TEXT"

bold "2. The classes are a partition: they sum to the reported content"
assert_eq "content equals the sum of every class" "$(field content)" "$EXP_CONTENT"
SUM="$(node -e '
  const fs = require("fs");
  const d = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  process.stdout.write(String(Object.values(d.totals).reduce((a, b) => a + b, 0)));
' "$JSONF")"
assert_eq "the class totals add up to content, with nothing uncounted" "$SUM" "$EXP_CONTENT"

bold "3. Prompt material is the three dispatch classes and nothing else"
assert_eq "prompt material is agent-prompts + fill-commands + value-files" "$(field promptMaterial)" "$EXP_PROMPT_MATERIAL"
PCT="$(node -e '
  const fs = require("fs");
  const d = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  process.stdout.write(d.promptMaterialPercent.toFixed(2));
' "$JSONF")"
assert_eq "the percentage is prompt material over content" "$PCT" "43.14"

bold "4. Token figures deduplicate on requestId — the counting trap"
assert_eq "the fixture really repeats one request across records" "$(field assistantRecords)" "$EXP_ASSISTANT_RECORDS"
assert_eq "distinct requests are counted, not records" "$(field distinctRequests)" "$EXP_DISTINCT_REQUESTS"
assert_eq "peak context is the largest single request" "$(field peakTokens)" "$EXP_PEAK"
# The two numbers the peak must never be: the sum of the distinct requests, and
# anything inflated by the repeated records.
if [ "$(field peakTokens)" = "$EXP_SUM_OF_REQUESTS" ]; then
  bad "peak context must not be the sum of the requests"
else
  ok "peak context is not the sum of the requests"
fi

bold "5. The report names the units and the limits it works under"
run_text "$FIXTURE"
assert_eq "the text report exits 0" "$STATUS" "0"
assert_file_contains "the report says the peak is a maximum, not a sum" "$OUTF" 'a maximum over requests, never a sum'
assert_file_contains "the report says the token figures are deduplicated" "$OUTF" 'deduplicated on requestId'
assert_file_contains "the report names the prompt-material components" "$OUTF" "$EXP_PROMPT_LINE"
# Thinking text is not stored in a transcript (only its signature), so its
# bytes are missing from content and every share is an upper bound. A reader
# who is told this cannot mistake a share for an exact figure.
assert_file_contains "the report warns that thinking text is not stored" "$OUTF" 'thinking blocks carry a signature'
assert_file_contains "the report states the direction of that error" "$OUTF" 'upper bound'

bold "6. Bad input fails loudly, never silently"
run_json "$WORK/does-not-exist.jsonl"
assert_eq "a missing transcript exits 2" "$STATUS" "2"
assert_file_contains "a missing transcript names itself" "$ERRF" 'no such transcript'
node "$SCRIPT" >"$OUTF" 2>"$ERRF"; STATUS=$?
assert_eq "no argument exits 2" "$STATUS" "2"
assert_file_contains "no argument prints the usage line" "$ERRF" 'usage: node tools/measure-context.js'

# --- Worklist row 27: file coverage over both hand-over routes, PARTIAL
# notices, the model-visible denominator, and the skill body.
#
# The Read route: a Read call returns at most about 25,000 tokens, then a
# notice "PARTIAL view — <path>: showing lines A-B of T total" names the
# next offset. The cat route: a Bash `cat <file>` whose output exceeds
# 30,000 characters is persisted to a file; the result holds a 2 KB
# preview and the persisted path, which the agent may read back in ranges.
#
# Line numbering: the Read tool counts the empty line after a file's final
# newline as a line, so its total is one more than sed or wc count. The
# fixtures whose total comes only from Read say "of 7 total" for six lines;
# the tool subtracts that line unless a page shows text on the last line.

# The PARTIAL notices line, from its five counts.
partial_line() { # count paged-to-end paged-short not-paged persisted
  printf 'PARTIAL notices: %s (paged to the end: %s, paged short: %s, not paged: %s; of these on a persisted output file: %s)' "$1" "$2" "$3" "$4" "$5"
}
# The five PARTIAL notice counts of the JSON report.
assert_partial_notices() { # desc count paged-to-end paged-short not-paged persisted
  assert_eq "$1: count" "$(field partialNotices.count)" "$2"
  assert_eq "$1: paged to the end" "$(field partialNotices.pagedToEnd)" "$3"
  assert_eq "$1: paged short" "$(field partialNotices.pagedShort)" "$4"
  assert_eq "$1: not paged" "$(field partialNotices.notPaged)" "$5"
  assert_eq "$1: on a persisted output file" "$(field partialNotices.persistedThenRead)" "$6"
}

bold "7. Read route: a PARTIAL notice, then paged to the end by offset"
run_json "$FIX_PAGED_TO_END"
assert_eq "exits 0" "$STATUS" "0"
assert_partial_notices "one notice counted once, although it sits in an attachment and the Read result also says truncatedByTokenCap" 1 1 0 0 0
assert_eq "one file is listed: the one whose first read was cut" "$(field fileCoverage.length)" "1"
assert_eq "the listed file is the cut one" "$(field fileCoverage.0.path)" "/tmp/mc-fixture/big.md"
assert_eq "the first read's route is Read" "$(field fileCoverage.0.firstRoute)" "Read"
# The last page shows text on line 6, the Read total, so the file has no
# empty final line and the total stays 6.
assert_eq "total lines come from the notice, kept at 6 because the last page shows text on line 6" "$(field fileCoverage.0.totalLines)" "6"
assert_eq "the two pages are merged into one received range" "$(field fileCoverage.0.receivedRanges)" "1-6"
assert_eq "six lines were received" "$(field fileCoverage.0.receivedLines)" "6"
assert_eq "coverage is complete" "$(field fileCoverage.0.coveragePercent)" "100"
assert_eq "nothing is uncovered" "$(field fileCoverage.0.uncoveredRanges)" "none"
assert_eq "the last line was reached" "$(field fileCoverage.0.lastLineReached)" "true"
assert_eq "the small file read whole in one call is counted, not listed" "$(field fullyReceivedFiles)" "1"

bold "8. Read route: paged short by one line, the notice inside the tool result"
run_json "$FIX_PAGED_SHORT"
assert_partial_notices "a notice inside the tool_result text is found and classified as paged short" 1 0 1 0 0
assert_eq "the Read total of 7 is six real lines: no page showed line 7, so the empty final line is subtracted" "$(field fileCoverage.0.totalLines)" "6"
assert_eq "lines 1-5 of 6 were received" "$(field fileCoverage.0.receivedRanges)" "1-5"
assert_eq "coverage is five sixths" "$(field fileCoverage.0.coveragePercent)" "83.3"
assert_eq "the last line is the uncovered range" "$(field fileCoverage.0.uncoveredRanges)" "6"
assert_eq "the last line was not reached" "$(field fileCoverage.0.lastLineReached)" "false"
assert_eq "no file was fully received in one call" "$(field fullyReceivedFiles)" "0"

bold "9. Read route: not paged at all (a grep and a heredoc body are not reads of lines)"
run_json "$FIX_NOT_PAGED"
assert_partial_notices "the notice is classified as not paged" 1 0 0 1 0
# The fixture ends with `cat >> notes.md <<'EOF'` whose body mentions
# `sed -n '1,50p' <the cut file>`: data written by the command, not a read.
assert_eq "only the first page was received; the heredoc body is not a read" "$(field fileCoverage.0.receivedRanges)" "1-3"
assert_eq "coverage is one half" "$(field fileCoverage.0.coveragePercent)" "50"
assert_eq "lines 4-6 are uncovered" "$(field fileCoverage.0.uncoveredRanges)" "4-6"
assert_eq "the last line was not reached" "$(field fileCoverage.0.lastLineReached)" "false"

bold "10. cat route: a persisted cat, then sed ranges and a Read leaving gaps"
run_json "$FIX_CAT_GAPS"
assert_partial_notices "no PARTIAL notice exists on the cat route" 0 0 0 0 0
assert_eq "the file behind the persisted output is listed once" "$(field fileCoverage.length)" "1"
assert_eq "it is listed under its own path, not the persisted path" "$(field fileCoverage.0.path)" "/tmp/mc-fixture/body.md"
assert_eq "the first read's route is cat" "$(field fileCoverage.0.firstRoute)" "cat"
assert_eq "total lines come from the later Read of the persisted path, whose last page shows text on line 12" "$(field fileCoverage.0.totalLines)" "12"
# The preview holds two complete lines and a third cut in the middle; the
# sed ranges go through a shell variable that names the persisted path, one
# as two ranges in one expression (`5,6p;7p`), one as two `-e` expressions;
# the `grep | sed -n '1,2p'` filters grep output and receives no file lines;
# the Read of the persisted path is mapped back to the file.
assert_eq "preview lines, sed ranges and Read range are united" "$(field fileCoverage.0.receivedRanges)" "1-2, 5-8, 10-12"
assert_eq "nine lines were received" "$(field fileCoverage.0.receivedLines)" "9"
assert_eq "coverage is three quarters" "$(field fileCoverage.0.coveragePercent)" "75"
assert_eq "the gaps are named" "$(field fileCoverage.0.uncoveredRanges)" "3-4, 9"
assert_eq "the last line was reached by the Read" "$(field fileCoverage.0.lastLineReached)" "true"

bold "11. Skill body: the usage jump at the Skill call, and skill-directory reads"
run_json "$FIX_SKILL"
assert_eq "one Skill call is counted" "$(field skillBody.calls)" "1"
# The request that made the Skill call held 1000 context tokens; the next
# request held 5000. The jump is the skill body plus whatever else arrived
# with it, which is what the row asks for.
assert_eq "the skill body is the context growth from the Skill call's request to the next" "$(field skillBody.tokens)" "4000"
assert_eq "the Skill call is named" "$(field skillBody.perCall.0.skill)" "plug:foo"
assert_eq "one read under a /skills/ path is counted" "$(field skillDirectoryReads)" "1"

bold "12. Model-visible denominator: hook_success and prompt_snapshot are excluded"
# The fixture's attachments: hook_success 52 bytes, prompt_snapshot 52 bytes,
# one other attachment 30 bytes. Content over every record is 289 bytes.
assert_eq "the existing table still counts every attachment record" "$(field totals.attachments)" "134"
assert_eq "the existing content figure is unchanged" "$(field content)" "289"
assert_eq "the model-visible content excludes the two record kinds" "$(field modelVisible.content)" "185"
assert_eq "the model-visible attachments keep only what the model sees" "$(field modelVisible.totals.attachments)" "30"
assert_eq "the excluded hook_success bytes are reported" "$(field modelVisible.excluded.hook_success)" "52"
assert_eq "the excluded prompt_snapshot bytes are reported" "$(field modelVisible.excluded.prompt_snapshot)" "52"

bold "13. The text report prints the new lines in a fixed format"
run_text "$FIX_CAT_GAPS"
assert_eq "the text report exits 0" "$STATUS" "0"
assert_file_contains "the existing prompt-material line is still printed" "$OUTF" "$EXP_PROMPT_LINE"
assert_file_contains "the two share tables are labelled" "$OUTF" 'Shares over every record'
assert_file_contains "the model-visible table names what it excludes" "$OUTF" 'Model-visible shares (without hook_success and prompt_snapshot attachment records'
assert_file_contains "the PARTIAL notices summary line" "$OUTF" "$(partial_line 0 0 0 0 0)"
assert_file_contains "the file coverage heading" "$OUTF" 'File coverage (files whose first read was cut; lines received over both routes):'
assert_file_contains "one line per cut file" "$OUTF" '/tmp/mc-fixture/body.md | first read: cat, persisted | total lines: 12 (from a Read result) | received: 1-2, 5-8, 10-12 (9 lines) | coverage: 75.0% | uncovered: 3-4, 9 | last line reached: yes'
assert_file_contains "the count of files fully received in one call" "$OUTF" 'Files fully received in one call: 0'
run_text "$FIX_SKILL"
assert_file_contains "the skill body line" "$OUTF" 'Skill body: 4,000 tokens over 1 Skill call'
assert_file_contains "the skill-directory reads count" "$OUTF" 'skill-directory reads: 1'
run_text "$FIX_PAGED_TO_END"
assert_file_contains "a Read-route line names the notice and the source of the total" "$OUTF" '/tmp/mc-fixture/big.md | first read: Read, cut by a PARTIAL notice | total lines: 6 (from a PARTIAL notice) | received: 1-6 (6 lines) | coverage: 100.0% | uncovered: none | last line reached: yes'
assert_file_contains "the PARTIAL notices line counts the paged notice" "$OUTF" "$(partial_line 1 1 0 0 0)"
# Row 28: a file a controller never opened cannot appear in this list, so a
# maintainer checks that a named template was opened by reading the list.
assert_file_contains "the count of files fully received in one call is one" "$OUTF" 'Files fully received in one call: 1'
assert_file_has_line "each file received whole is listed on its own line under the count" "$OUTF" '    /tmp/mc-fixture/small.md'

bold "14. The original fixture is unchanged by the new sections"
run_json "$FIXTURE"
assert_partial_notices "no PARTIAL notice in the original fixture" 0 0 0 0 0
assert_eq "no cut file in the original fixture" "$(field fileCoverage.length)" "0"
assert_eq "no Skill call in the original fixture" "$(field skillBody.calls)" "0"
assert_eq "a string attachment is model-visible" "$(field modelVisible.content)" "$EXP_CONTENT"

bold "15. Pipelines and files on disk: cat | sed, awk patterns, head caps, cd, tail"
# The template names two real files under the fixtures directory, so the
# total comes from the file on disk (the persisted copies do not exist).
ON_DISK="$WORK/pipeline-on-disk.jsonl"
node -e '
  const fs = require("fs");
  const [template, fixtures, out] = process.argv.slice(1);
  const dir = JSON.stringify(fixtures).slice(1, -1);
  fs.writeFileSync(out, fs.readFileSync(template, "utf8").split("@@FIX@@").join(dir));
' "$FIX_ON_DISK_TEMPLATE" "$FIX" "$ON_DISK"
run_json "$ON_DISK"
assert_eq "exits 0" "$STATUS" "0"
assert_eq "two cut files are listed" "$(field fileCoverage.length)" "2"
# six-lines.txt: a persisted cat (one complete preview line), then
# `cat FILE | sed -n '2,3p'`: the range of the second pipe segment applies
# to the file named in the first, so 3 of 6 lines were received.
assert_eq "six-lines: total lines are counted on disk" "$(field fileCoverage.0.totalLines)" "6"
assert_eq "six-lines: the total's source is the disk" "$(field fileCoverage.0.totalLinesSource)" "counted on disk"
assert_eq "six-lines: cat | sed receives the sed range of the file, not the whole file" "$(field fileCoverage.0.receivedRanges)" "1-3"
assert_eq "six-lines: coverage is one half" "$(field fileCoverage.0.coveragePercent)" "50"
assert_eq "six-lines: the last line was not reached" "$(field fileCoverage.0.lastLineReached)" "false"
# sections.txt (10 lines, headings at 2, 6 and 9): preview line 1;
# `awk '/^## A/,/^## B/' | head -2` gives 2-3 (the pattern range 2-6 capped
# by head); `cd <dir> && sed -n '/^## B/,/b2/p' sections.txt` gives 6-8 (the
# relative name resolves through cd; the record has no cwd);
# `awk 'NR>=5 && NR<=5'` gives 5; `tail -n +9 | head -1` gives 9;
# `tail -n 1` gives 10 (its position needs the on-disk total).
assert_eq "sections: total lines are counted on disk" "$(field fileCoverage.1.totalLines)" "10"
assert_eq "sections: pattern ranges, head caps, cd, awk NR and both tail forms are united" "$(field fileCoverage.1.receivedRanges)" "1-3, 5-10"
assert_eq "sections: coverage is nine tenths" "$(field fileCoverage.1.coveragePercent)" "90"
assert_eq "sections: line 4 is the only gap" "$(field fileCoverage.1.uncoveredRanges)" "4"
assert_eq "sections: the last line was reached" "$(field fileCoverage.1.lastLineReached)" "true"

bold "16. An open range (awk 'NR>=N') after a notice counts as paging"
run_json "$FIX_OPEN_RANGE"
assert_eq "the Read total of 7 is six real lines" "$(field fileCoverage.0.totalLines)" "6"
assert_eq "the open range runs to the end of the file" "$(field fileCoverage.0.receivedRanges)" "1-6"
assert_eq "coverage is complete" "$(field fileCoverage.0.coveragePercent)" "100"
assert_partial_notices "the notice is classified as paged to the end although the only later read is an open range" 1 1 0 0 0

bold "17. A persisted cat, then a Read of the persisted path that is cut"
run_json "$FIX_CAT_THEN_READ"
assert_eq "the file is listed under its own path" "$(field fileCoverage.0.path)" "/tmp/mc-fixture/body.md"
assert_eq "the first read's route is cat" "$(field fileCoverage.0.firstRoute)" "cat"
# The preview ends exactly on a newline: both lines are complete.
assert_eq "a preview cut exactly on a newline keeps both complete lines" "$(field fileCoverage.0.events.0)" "cat persisted (2 complete preview lines) -> 1-2"
# The last page shows line 7 empty: the Read total of 7 is six real lines.
assert_eq "the empty final line shown by the last page is subtracted from the total" "$(field fileCoverage.0.totalLines)" "6"
assert_eq "coverage is complete" "$(field fileCoverage.0.coveragePercent)" "100"
assert_eq "the last line was reached" "$(field fileCoverage.0.lastLineReached)" "true"
assert_partial_notices "the notice on the persisted copy is paged to the end and counted as persisted-then-read" 1 1 0 0 1

echo
bold "Results: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then
  for e in "${ERRORS[@]}"; do red "  - $e"; done
  exit 1
fi
exit 0
