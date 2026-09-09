#!/usr/bin/env bash
# Helper functions for Claude Code skill tests

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/timeout-shim.sh"

# Run Claude Code with a prompt and capture output
# Usage: run_claude "prompt text" [timeout_seconds] [allowed_tools]
run_claude() {
    local prompt="$1"
    local timeout="${2:-60}"
    local allowed_tools="${3:-}"
    local output_file=$(mktemp)

    # Build command
    local cmd="claude -p \"$prompt\""
    if [ -n "$allowed_tools" ]; then
        cmd="$cmd --allowed-tools=$allowed_tools"
    fi

    # Run Claude in headless mode with timeout
    if timeout "$timeout" bash -c "$cmd" > "$output_file" 2>&1; then
        cat "$output_file"
        rm -f "$output_file"
        return 0
    else
        local exit_code=$?
        cat "$output_file" >&2
        rm -f "$output_file"
        return $exit_code
    fi
}

# Check if output contains a pattern
# Usage: assert_contains "output" "pattern" "test name"
assert_contains() {
    local output="$1"
    local pattern="$2"
    local test_name="${3:-test}"

    if echo "$output" | grep -qi "$pattern"; then
        echo "  [PASS] $test_name"
        return 0
    else
        echo "  [FAIL] $test_name"
        echo "  Expected to find: $pattern"
        echo "  In output:"
        echo "$output" | sed 's/^/    /'
        return 1
    fi
}

# Check if output does NOT contain a pattern
# Usage: assert_not_contains "output" "pattern" "test name"
assert_not_contains() {
    local output="$1"
    local pattern="$2"
    local test_name="${3:-test}"

    if echo "$output" | grep -q "$pattern"; then
        echo "  [FAIL] $test_name"
        echo "  Did not expect to find: $pattern"
        echo "  In output:"
        echo "$output" | sed 's/^/    /'
        return 1
    else
        echo "  [PASS] $test_name"
        return 0
    fi
}

# Check if output matches a count
# Usage: assert_count "output" "pattern" expected_count "test name"
assert_count() {
    local output="$1"
    local pattern="$2"
    local expected="$3"
    local test_name="${4:-test}"

    local actual=$(echo "$output" | grep -c "$pattern" || echo "0")

    if [ "$actual" -eq "$expected" ]; then
        echo "  [PASS] $test_name (found $actual instances)"
        return 0
    else
        echo "  [FAIL] $test_name"
        echo "  Expected $expected instances of: $pattern"
        echo "  Found $actual instances"
        echo "  In output:"
        echo "$output" | sed 's/^/    /'
        return 1
    fi
}

# Check if pattern A appears before pattern B
# Usage: assert_order "output" "pattern_a" "pattern_b" "test name"
assert_order() {
    local output="$1"
    local pattern_a="$2"
    local pattern_b="$3"
    local test_name="${4:-test}"

    # Get line numbers where patterns appear
    local line_a=$(echo "$output" | grep -n "$pattern_a" | head -1 | cut -d: -f1)
    local line_b=$(echo "$output" | grep -n "$pattern_b" | head -1 | cut -d: -f1)

    if [ -z "$line_a" ]; then
        echo "  [FAIL] $test_name: pattern A not found: $pattern_a"
        return 1
    fi

    if [ -z "$line_b" ]; then
        echo "  [FAIL] $test_name: pattern B not found: $pattern_b"
        return 1
    fi

    if [ "$line_a" -lt "$line_b" ]; then
        echo "  [PASS] $test_name (A at line $line_a, B at line $line_b)"
        return 0
    else
        echo "  [FAIL] $test_name"
        echo "  Expected '$pattern_a' before '$pattern_b'"
        echo "  But found A at line $line_a, B at line $line_b"
        return 1
    fi
}

# Create a temporary test project directory
# Usage: test_project=$(create_test_project)
create_test_project() {
    local test_dir=$(mktemp -d)
    echo "$test_dir"
}

# Cleanup test project
# Usage: cleanup_test_project "$test_dir"
cleanup_test_project() {
    local test_dir="$1"
    if [ -d "$test_dir" ]; then
        rm -rf "$test_dir"
    fi
}

# Create a simple plan file for testing
# Usage: create_test_plan "$project_dir" "$plan_name"
create_test_plan() {
    local project_dir="$1"
    local plan_name="${2:-test-plan}"
    local plan_file="$project_dir/docs/superpowers-orchestrator/2026-08-25-$plan_name/plans/$plan_name.md"

    mkdir -p "$(dirname "$plan_file")"

    cat > "$plan_file" <<'EOF'
# Test Implementation Plan

## Task 1: Create Hello Function

Create a simple hello function that returns "Hello, World!".

**File:** `src/hello.js`

**Implementation:**
```javascript
export function hello() {
  return "Hello, World!";
}
```

**Tests:** Write a test that verifies the function returns the expected string.

**Verification:** `npm test`

## Task 2: Create Goodbye Function

Create a goodbye function that takes a name and returns a goodbye message.

**File:** `src/goodbye.js`

**Implementation:**
```javascript
export function goodbye(name) {
  return `Goodbye, ${name}!`;
}
```

**Tests:** Write tests for:
- Default name
- Custom name
- Edge cases (empty string, null)

**Verification:** `npm test`
EOF

    echo "$plan_file"
}

# [I2] Detect any of the superpowers session-default variables set in the
# `env` block of a settings file that applies to a `claude -p` run started
# from $plugin_dir: a user-level ~/.claude/settings.json, a user-level
# ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json or settings.local.json
# (relevant only when CLAUDE_CONFIG_DIR points somewhere other than
# ~/.claude), a project-level $plugin_dir/.claude/settings.json or
# $plugin_dir/.claude/settings.local.json, or the enterprise
# managed-settings.json (macOS: /Library/Application Support/ClaudeCode/;
# Linux: /etc/claude-code/), which has the highest precedence of all of them.
# README.md and docs/guide/README.md tell users to set these that way; Claude
# Code applies that env block inside its own process and passes it to hooks,
# so a shell-level `unset` of the same variable does not remove it. Any of
# them reaching hooks/session-start changes the <superpowers-defaults> block
# the session is given, which is what the default cases in these tests
# depend on. Tolerates a missing file. Uses plain grep — no jq dependency.
# Usage: check_no_superpowers_defaults_setting "$PLUGIN_DIR"
check_no_superpowers_defaults_setting() {
    local plugin_dir="$1"
    local config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
    local var f
    for var in SUPERPOWERS_REVIEWERS_PER_LENS SUPERPOWERS_REVIEW_ROUNDS SUPERPOWERS_BATCH_TASK_CAP; do
        for f in "$HOME/.claude/settings.json" \
                 "$HOME/.claude/settings.local.json" \
                 "$config_dir/settings.json" \
                 "$config_dir/settings.local.json" \
                 "$plugin_dir/.claude/settings.json" \
                 "$plugin_dir/.claude/settings.local.json" \
                 "/Library/Application Support/ClaudeCode/managed-settings.json" \
                 "/etc/claude-code/managed-settings.json"; do
            if [ -f "$f" ] && grep -qE "\"$var\"[[:space:]]*:" "$f"; then
                echo "ABORT: $var is set in the env block of $f."
                echo "Claude Code applies that env block inside its own process and passes it to hooks, so the shell-level 'unset $var' in this script does not remove it."
                echo "The default cases in this test cannot be trusted while $var is set there — remove or comment it out in $f before running this test."
                return 1
            fi
        done
    done
    return 0
}

# Export functions for use in tests
export -f run_claude
export -f assert_contains
export -f assert_not_contains
export -f assert_count
export -f assert_order
export -f create_test_project
export -f cleanup_test_project
export -f create_test_plan
export -f check_no_superpowers_defaults_setting

# assert_round_reviewers <log> <round> <m> <findings>
# <m> must be a single digit, 1-9: the function builds character classes like
# "[1-${m}]" from it, which is correct only for a single digit.
# <findings> is 'required' or 'optional' and is NOT optional itself: it says
# whether this round must have consolidated at least one finding.
#   - 'required' — the caller seeded defects the round is expected to find.
#     A '**Sources mapped:** 0/0' entry then FAILS: on an empty set the three
#     numeric checks below compare 0 with 0 and the annotation check is
#     skipped, so all four pass while verifying nothing about M reviewers.
#   - 'optional' — an empty set is a legitimate result for this round (a
#     later round of a converging loop finds nothing, and a round whose
#     reviewers all report nothing correctly writes no annotation).
# A missing or misspelled fourth argument fails: the check must be stated at
# each call site, never defaulted, because the wrong default is silent.
# Checks the reviewers-per-lens lines of one round entry — the lines from
# '^## Round <round> — ' up to the next '^## Round ' or the end of the file.
# The en dash after the round number matches the round header only: a
# '## Round <round> verification <c> — …' header does not match it, so a
# verification-cycle entry ends the extraction instead of being appended.
#   - '**Reviewers:** M=<m>, usable <u>/<m>' with 1 <= u <= m (one unusable
#     reviewer is tolerated, so a rare retry failure does not fail the test)
#   - '**Sources mapped:** k/k' with equal numbers
#   - the counts on the '**Reviewer verdicts:**' line sum to k (the line is
#     not trusted: the sum is recomputed here)
#   - the distinct 'r<j>:<id>' tokens across the source annotations equal k
#   - at least one disposition line ends in ' ← <a>/<m>: <source ids>'
#     (skipped with a 'note:' line when Sources mapped is 0/0 and <findings>
#     is 'optional'; when <findings> is 'required', 0/0 is a failure)
# Prints one FAIL(m) line per failed check; returns the number of failed checks.
assert_round_reviewers() {
    local log="$1" round="$2" m="$3" findings="${4:-}"
    local failures=0
    local entry

    # The fourth argument carries knowledge only the caller has: whether this
    # round ran over a fixture seeded with defects. Refuse to guess it — a
    # default would silently restore the vacuous pass this check exists to
    # prevent, and would also let an un-updated three-argument call through.
    if [ "$findings" != "required" ] && [ "$findings" != "optional" ]; then
        echo "FAIL(m): round $round: assert_round_reviewers needs a fourth argument, 'required' or 'optional' (got '${findings}')"
        return 1
    fi

    # [M4] The character classes built below from $m (e.g. "[1-${m}]") are
    # correct only for a single digit: with m=10 the class silently becomes
    # "[1-1]0" and the checks change meaning instead of failing loudly.
    if ! [[ "$m" =~ ^[1-9]$ ]]; then
        echo "FAIL(m): round $round: assert_round_reviewers needs a single-digit m, 1-9 (got '${m}')"
        return 1
    fi
    entry=$(awk -v r="$round" '
        $0 ~ "^## Round " r " — " { on = 1; print; next }
        /^## Round / { if (on) exit }
        on { print }' "$log")

    # [M4] The round entry is missing entirely (not just malformed) — say so
    # in one clear line instead of falling through to the five generic
    # checks below, which would all fail for the same underlying reason and
    # not tell a maintainer "the round is missing" from "the round is wrong".
    if [ -z "$entry" ]; then
        echo "FAIL(m): round $round: no '## Round $round — ' entry found in the log"
        return 1
    fi

    # Full participation is REQUIRED, not tolerated. The earlier pattern
    # accepted 'usable [1-m]/m' so that one flaky reviewer would not fail the
    # test. But with u = 1 and M = 2 only ONE reviewer ran, so no consolidation
    # happened and the M >= 2 path — the only reason these tests exist — was
    # never exercised, while the suite still reported PASS. These behavioural
    # tests are the sole coverage of that path, so a partial round must fail
    # loudly and be re-run rather than pass silently. For M = 1 this is
    # identical to the old pattern ('1/1' either way).
    local usable_re="^\\*\\*Reviewers:\\*\\* M=${m}, usable ${m}/${m}\$"
    local usable_line
    usable_line=$(printf '%s\n' "$entry" | grep -E "$usable_re" | head -1 || true)
    if [ -z "$usable_line" ]; then
        # Distinguish "the round ran short-handed" from "the line is missing or
        # malformed": the first is a re-run, the second is a real defect.
        local partial_line
        partial_line=$(printf '%s\n' "$entry" \
            | grep -E "^\\*\\*Reviewers:\\*\\* M=${m}, usable [0-9]+/${m}\$" | head -1 || true)
        if [ -n "$partial_line" ]; then
            echo "FAIL(m): round $round: partial round ($partial_line) — fewer than $m reviewers were usable, so the M=$m consolidation path was NOT exercised. Re-run the test; this is not necessarily a defect."
        else
            echo "FAIL(m): round $round has no '**Reviewers:** M=$m, usable $m/$m' line"
        fi
        failures=$((failures+1))
    else
        : # usable_re already guarantees u = m
    fi

    local sources_line k_mapped k_total
    sources_line=$(printf '%s\n' "$entry" | grep -E '^\*\*Sources mapped:\*\* [0-9]+/[0-9]+$' | head -1 || true)
    k_mapped=$(printf '%s' "$sources_line" | sed -nE 's/.* ([0-9]+)\/[0-9]+$/\1/p')
    k_total=$(printf '%s' "$sources_line" | sed -nE 's/.* [0-9]+\/([0-9]+)$/\1/p')
    if [ -z "$sources_line" ] || [ "$k_mapped" != "$k_total" ]; then
        echo "FAIL(m): round $round has no '**Sources mapped:** k/k' line with equal numbers"
        failures=$((failures+1))
    fi

    local verdict_sum
    verdict_sum=$(printf '%s\n' "$entry" | grep -E '^\*\*Reviewer verdicts:\*\*' \
        | grep -oE '[0-9]+ (Critical|Important|Minor)' | awk '{ s += $1 } END { print s + 0 }' || true)
    if [ "$verdict_sum" != "${k_total:-none}" ]; then
        echo "FAIL(m): round $round: Reviewer verdicts counts sum to $verdict_sum, Sources mapped says ${k_total:-none}"
        failures=$((failures+1))
    fi

    local annotation_re=" ← [1-${m}]/${m}: r[1-${m}]:[CIM][0-9]+(, r[1-${m}]:[CIM][0-9]+)*\$"
    local distinct_sources
    distinct_sources=$(printf '%s\n' "$entry" | grep -oE "$annotation_re" \
        | grep -oE "r[1-${m}]:[CIM][0-9]+" | sort -u | wc -l | tr -d ' ' || true)
    if [ "$distinct_sources" != "${k_total:-none}" ]; then
        echo "FAIL(m): round $round: $distinct_sources distinct source ids in annotations, Sources mapped says ${k_total:-none}"
        failures=$((failures+1))
    fi

    # [M3] Per-line check: the agreement count '<a>' in ' ← <a>/<m>: ' must
    # equal the number of DISTINCT reviewer(s) (the distinct 'r<j>' prefixes)
    # among the comma-separated source ids listed after the colon on that
    # same line — not the number of listed ids: one consolidated finding may
    # list two source ids from the SAME reviewer (rule 8 allows a report to
    # enumerate one defect twice), so a correct line like
    # '← 1/3: r1:I1, r1:I4' has agreement count 1 with two listed ids. The
    # distinct-token/k comparison above catches a wrong total across the
    # whole round but not a single line like '← 2/2: r1:C1' (agreement count
    # 2, one distinct reviewer).
    while IFS= read -r annotated_line; do
        [ -z "$annotated_line" ] && continue
        local a ids reviewer_count
        a=$(printf '%s' "$annotated_line" | sed -nE "s/.* ← ([0-9]+)\/${m}: .*/\1/p")
        ids=$(printf '%s' "$annotated_line" | sed -nE "s/.* ← [0-9]+\/${m}: (.*)\$/\1/p")
        reviewer_count=$(printf '%s' "$ids" | grep -oE 'r[0-9]+' | sort -u | wc -l | tr -d ' ')
        if [ -n "$a" ] && [ "$a" != "$reviewer_count" ]; then
            echo "FAIL(m): round $round: disposition line's agreement count $a does not match its $reviewer_count distinct reviewer(s): $annotated_line"
            failures=$((failures+1))
        fi
    done < <(printf '%s\n' "$entry" | grep -E "$annotation_re" || true)

    if [ -n "$sources_line" ] && [ "$k_total" = "0" ]; then
        if [ "$findings" = "required" ]; then
            echo "FAIL(m): round $round: '**Sources mapped:** 0/0' but this round was declared to require findings; the numeric checks compared 0 with 0 and the annotation check was skipped, so nothing about M=$m consolidation was verified"
            failures=$((failures+1))
        else
            echo "note: round $round: Sources mapped is 0/0 (empty consolidated set); annotation check skipped — declared legitimate for this round"
        fi
    elif ! printf '%s\n' "$entry" | grep -qE "$annotation_re"; then
        echo "FAIL(m): round $round: no disposition line ends in a ' ← <a>/$m: <source ids>' annotation"
        failures=$((failures+1))
    fi

    return "$failures"
}
export -f assert_round_reviewers
