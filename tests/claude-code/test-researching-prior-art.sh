#!/usr/bin/env bash
# Test: researching-prior-art skill — merged-report contract (behavioral, slow)
#
# Seeds a temp git repo whose package.json names a real small library (ms),
# invokes the skill headlessly with a fixed decision and N=2, and asserts the
# contract from docs/specs/2026-08-22-researching-prior-art-design.md:
#   (a) .superpowers/research/<slug>-research-report.md exists
#   (b) its first line is exactly the research report marker
#   (c) it contains at least one citation (URL or clone file path), and a
#       quoted snippet of 25+ characters INSIDE its "Findings per candidate"
#       section
#   (d) it contains a "Sources fetched" section
#   (e) the plugin dev repo is unmutated (HEAD + status snapshot)
#   (f) the run was not killed by the timeout
#   (g) its "Version facts" section names the version the fixture pins
#   (h) the durable cache entry docs/research/npm-ms.md exists, its commit
#       touches only docs/research/ paths, and a file the user staged before
#       the run is still staged and still uncommitted
# No assertions on hardcoded git history.
#
# (c) and (g) exist because assertions (a)-(f) as originally written passed
# on a run that researched nothing: the quoted-snippet check searched the
# whole report, where the skill's own mandated labels satisfied it, and no
# assertion referred to the pinned version at all.
#
# Requires the INSTALLED plugin to include researching-prior-art — run
# tools/sync-dev-install.sh after editing skills/ before running this.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../lib/timeout-shim.sh"
source "$SCRIPT_DIR/test-helpers.sh"

# The version the fixture pins. Assertion (g) requires the merged report to
# name it in its "Version facts" section.
PINNED_VERSION="2.1.3"

# Print the body of one markdown section: every line after the heading that
# matches the given regular expression, up to the next heading at the same
# level or higher. Deeper sub-headings stay inside the section — the report
# puts one sub-heading per candidate under "Findings per candidate".
# The pattern must be lowercase — headings are lowercased before matching,
# because the macOS awk has no case-insensitive matching option.
section_of() {
    awk -v pat="$2" '
        /^#+[ \t]/ {
            match($0, /^#+/)
            level = RLENGTH
            if (inside && level <= start_level) { inside = 0 }
            if (!inside && tolower($0) ~ pat) { inside = 1; start_level = level }
            next
        }
        inside { print }
    ' "$1"
}

TEST_PROJECT=$(create_test_project)
trap "cleanup_test_project '$TEST_PROJECT'" EXIT

cd "$TEST_PROJECT"
git init --quiet
git config user.email "test@example.com"
git config user.name "Test"

cat > package.json << PKG_EOF
{
  "name": "research-fixture",
  "version": "1.0.0",
  "dependencies": {
    "ms": "$PINNED_VERSION"
  }
}
PKG_EOF
git add package.json
git commit --quiet -m "base: fixture with ms dependency"

# Assertion (h) needs work the user staged but did not commit. The skill's
# cache commit is path-limited, so this file must still be staged and
# uncommitted when the run ends. A bare `git commit` would sweep it in.
UNRELATED_FILE="unrelated-staged-work.js"
echo "// staged by the user before the research run, never committed" > "$UNRELATED_FILE"
git add "$UNRELATED_FILE"

PROMPT="Invoke the superpowers-orchestrator:researching-prior-art skill on the git repository at $TEST_PROJECT. Decision: verify that the npm package ms (pinned at $PINNED_VERSION in package.json) still fits this project's duration-parsing needs — this decision depends on version-sensitive external API behavior. Candidates: ms (npm, canonical name ms). N=2. Topic slug: ms-duration. Do not ask me any questions — proceed to completion."

# Safety net: a misanchored run must not mutate the dev repo.
# --ignored=matching because .superpowers/ (self-.gitignore, written in Task 1
# Step 0) and state.md (committed .gitignore) are excluded here — exactly the
# paths the skill under test writes.
#
# The hash EXCLUDES the plugin's own session-artifact entries. The plugin's
# session-start hooks write git-ignored session state (.omc/, .superpowers/,
# context-snapshot.json, and the memory-stack files) into whatever repo the
# CLI starts in. On a checkout whose first claude session is this test's
# headless run — a fresh git worktree, for example — those entries appear
# MID-RUN and would fail assertion (e) with no misanchored write having
# happened (observed 2026-08-24). Excluding them does not weaken the check:
# writes INSIDE an already-listed ignored directory were never visible to
# this snapshot anyway (a `!!` entry does not change when the directory's
# content does — the documented blind spot), so the filter only removes the
# environment-dependent appearance of the entries themselves. Tracked-file
# changes never match the `^!! ` prefix and always count.
plugin_repo_snapshot() {
    git -C "$PLUGIN_DIR" status --porcelain --ignored=matching \
        | awk '!/^!! (\.omc\/|\.superpowers\/|context-snapshot\.json|state\.md|session-log\.md|known-issues\.md|project-map\.md)$/' \
        | shasum | cut -d' ' -f1
}
PLUGIN_HEAD_BEFORE=$(git -C "$PLUGIN_DIR" rev-parse HEAD)
PLUGIN_STATUS_BEFORE=$(plugin_repo_snapshot)

# Inner budget (1700s) sits below the runner's outer --timeout 1800 so a hang
# is killed here first: the timeout assertion can fire and the keep-project
# trap still runs (the outer timeout would kill this whole script instead).
CLAUDE_STATUS=0
cd "$PLUGIN_DIR" && timeout 1700 claude -p "$PROMPT" \
    --permission-mode bypassPermissions \
    --add-dir "$TEST_PROJECT" \
    2>&1 | tee "$TEST_PROJECT/output.txt" || CLAUDE_STATUS=${PIPESTATUS[0]}

cd "$TEST_PROJECT"
FAILURES=0

# (f) GNU timeout reports 124; the tests/lib/timeout-shim.sh fallback reports 143.
if [ "$CLAUDE_STATUS" -eq 124 ] || [ "$CLAUDE_STATUS" -eq 143 ]; then
    echo "FAIL(f): the claude run was killed by the 1700s inner timeout (exit $CLAUDE_STATUS)"
    FAILURES=$((FAILURES+1))
fi

PLUGIN_HEAD_AFTER=$(git -C "$PLUGIN_DIR" rev-parse HEAD)
PLUGIN_STATUS_AFTER=$(plugin_repo_snapshot)
if [ "$PLUGIN_HEAD_AFTER" != "$PLUGIN_HEAD_BEFORE" ] || [ "$PLUGIN_STATUS_AFTER" != "$PLUGIN_STATUS_BEFORE" ]; then
    echo "FAIL(e): the run mutated the plugin dev repo (misanchored skill?)"
    echo "  Inspect: git -C $PLUGIN_DIR status --porcelain; git -C $PLUGIN_DIR diff"
    FAILURES=$((FAILURES+1))
fi

REPORT="$TEST_PROJECT/.superpowers/research/ms-duration-research-report.md"
if [ ! -f "$REPORT" ]; then
    echo "FAIL(a): merged report not created at $REPORT"
    FAILURES=$((FAILURES+1))
else
    if [ "$(head -1 "$REPORT")" != "<!-- research report -->" ]; then
        echo "FAIL(b): first line of the merged report is not the research report marker"
        FAILURES=$((FAILURES+1))
    fi
    if ! grep -qE 'https?://|\.superpowers/research/clones/' "$REPORT"; then
        echo "FAIL(c): no citation (URL or clone file path) found in the merged report"
        FAILURES=$((FAILURES+1))
    fi
    # (c) The quoted snippet must sit inside the "Findings per candidate"
    # section. Searched over the whole report, this assertion could not
    # fail: the skill's own mandated report labels are quoted strings and
    # satisfied it on their own. The 25-character floor is above every
    # such label.
    FINDINGS=$(section_of "$REPORT" 'findings (per|by) candidate')
    if [ -z "$FINDINGS" ]; then
        echo "FAIL(c): the merged report has no 'Findings per candidate' section"
        FAILURES=$((FAILURES+1))
    elif ! printf '%s\n' "$FINDINGS" | grep -qE '"[^"]{25,}"|`[^`]{25,}`'; then
        echo "FAIL(c): no quoted snippet of 25+ characters inside 'Findings per candidate'"
        FAILURES=$((FAILURES+1))
    fi
    if ! grep -qi 'Sources fetched' "$REPORT"; then
        echo "FAIL(d): merged report has no 'Sources fetched' section"
        FAILURES=$((FAILURES+1))
    fi
    # (g) A real run reports the version this repository pins. A fully
    # degraded run — no registry reached, no documentation fetched —
    # produces the report skeleton without ever establishing it. Without
    # this assertion, (a)-(f) pass on a run that researched nothing.
    VERSION_FACTS=$(section_of "$REPORT" 'version facts')
    if [ -z "$VERSION_FACTS" ]; then
        echo "FAIL(g): the merged report has no 'Version facts' section"
        FAILURES=$((FAILURES+1))
    elif ! printf '%s\n' "$VERSION_FACTS" | grep -qF "$PINNED_VERSION"; then
        echo "FAIL(g): 'Version facts' does not name the pinned version $PINNED_VERSION"
        FAILURES=$((FAILURES+1))
    fi
fi

# (h) The durable cache and its commit — the release's headline behavior, and
# the only place the skill writes to the user's git history. Three checks:
# the cache entry exists, the commit is path-limited, and the user's own
# staged work was left alone.
CACHE_ENTRY="$TEST_PROJECT/docs/research/npm-ms.md"
if [ ! -f "$CACHE_ENTRY" ]; then
    echo "FAIL(h): no durable cache entry at $CACHE_ENTRY"
    FAILURES=$((FAILURES+1))
else
    # Every path in the cache commit must live under docs/research/. A bare
    # `git commit` would also carry package.json or the staged file above.
    CACHE_COMMIT_PATHS=$(git log -1 --name-only --format= -- docs/research/ | grep -v '^$' || true)
    OFF_PATHS=$(git log -1 --name-only --format= | grep -v '^$' | grep -v '^docs/research/' || true)
    if [ -z "$CACHE_COMMIT_PATHS" ]; then
        echo "FAIL(h): the last commit touches no docs/research/ path — the cache was not committed"
        FAILURES=$((FAILURES+1))
    fi
    if [ -n "$OFF_PATHS" ]; then
        echo "FAIL(h): the cache commit is not path-limited; it also carries:"
        printf '  %s\n' $OFF_PATHS
        FAILURES=$((FAILURES+1))
    fi
fi

# The user's staged file must still be staged and still uncommitted.
if ! git diff --cached --name-only | grep -qF "$UNRELATED_FILE"; then
    echo "FAIL(h): $UNRELATED_FILE is no longer staged — the run swept the user's index"
    FAILURES=$((FAILURES+1))
fi
if git log --format= --name-only | grep -qF "$UNRELATED_FILE"; then
    echo "FAIL(h): $UNRELATED_FILE was committed — the cache commit was not path-limited"
    FAILURES=$((FAILURES+1))
fi

if [ "$FAILURES" -eq 0 ]; then
    echo "PASS: researching-prior-art behavioral test"
else
    trap - EXIT
    echo "FAILED: $FAILURES assertion(s); project kept for debugging: $TEST_PROJECT (transcript in output.txt — clean up manually)"
    exit 1
fi
