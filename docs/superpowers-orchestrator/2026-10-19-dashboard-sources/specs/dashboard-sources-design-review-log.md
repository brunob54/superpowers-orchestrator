# Review log: dashboard-sources-design.md

_Invocation 1 — 2026-10-19 — N=4 M=3 — gate: brainstorming_

## Round 1 — Correctness & completeness — claude-opus-5-5
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 2 Important, 8 Minor | r2: 0 Critical, 2 Important, 5 Minor | r3: 0 Critical, 1 Important, 5 Minor
**Sources mapped:** 23/23
**Reviewer verdict:** 0 Critical, 2 Important, 10 Minor
**Converged:** no

### Dispositions
- [I1] applied — 4.5 Input/Data, 5: "resolved by the same function" contradicts "never stops"; checkSharedName and sharedRemote call stop(); bad form, not-a-commit, removed remote had no case → non-stopping three-check variant, each outcome mapped to missing/error, sharedRemote not used, test-04 row extended ← 3/3: r1:I1, r2:I2, r3:I1
- [I2] applied — 3, 4.1 Parser: RESOLVED_SUFFIX listed as open-item-only but normalizeLine (kept) uses it; item ids depend on it → list corrected (RESOLVED_MARK, ONE_LINE_PREFIX only), normalizeLine/occurrenceOf/lineAtOccurrence/lineItemId byte-for-byte unchanged ← 2/3: r1:I2, r2:I1
- [M1] applied — 4.3 Numbers, 6 test-08: drift test missed SHARED_SOURCES and RELEASE_LIMIT 15 → test covers both constants and all three limits; releases sentence names 15 ← 3/3: r1:M7, r2:M4, r3:M1
- [M2] applied — 4.3 sessions row: "never on the shared page" false when session-log.md is tracked → claim removed; file sentences stated neutral about location ← 3/3: r1:M5, r2:M1, r3:M2
- [M3] applied — 4.5 Page: "This branch has" wrong on detached HEAD; singular forms → detached wording, singular forms, "today" ← 3/3: r1:M2, r2:M2, r3:M3
- [M4] applied — 4.7 guide: new user-visible lines not described in the guide → guide additions listed (also notes the line updates only at refresh) ← 2/3: r2:M5, r3:M5
- [M5] applied — 4.5: share and local behaviour of the line not stated → "When the line appears" paragraph ← 1/3: r1:M3
- [M6] applied — 4.3: Source line in the "not in this data" case unspecified → shown in every state, absent included ← 2/3: r1:M6, r3:M4
- [M7] applied — 4.5, 4.6: committer time zone vs local generatedAt can shift day counts at the 14/90 boundaries → short-local date formats (verified with git 2.50.1) ← 1/3: r2:M3
- [M8] applied — 4.5 warning rule: age-only warns on a quiet, current repository → warning needs days > 14 and notShown > 0; test row extended ← 1/3: r1:M1
- [M9] applied — 4.4: dirty count excludes untracked files while wording said "files not committed" → wording "tracked files changed, not committed" ← 1/3: r1:M4
- [M10] applied — 7 failure mode 4: "exactly what the shared page shows" too strong when step 6 fails → claim weakened, step 6 report named ← 1/3: r1:M8

## Round 2 — Ambiguity & testability — claude-opus-5-5
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 1 Important, 8 Minor | r2: 0 Critical, 1 Important, 10 Minor | r3: 0 Critical, 0 Important, 9 Minor
**Sources mapped:** 29/29
**Reviewer verdict:** 0 Critical, 1 Important, 13 Minor
**Converged:** no

### Dispositions
- [I1] applied — 4.5 Page: detached-HEAD sentence given only as a start and an end; joined text ungrammatical, pinned by tests → table of exact texts for every part, singular and detached forms ← 3/3: r1:I1, r2:I1, r3:M1
- [M1] applied — 4.5 Page: "today" in place of "(0 days ago)" readable two ways → exact text "(today)." in the table ← 3/3: r1:M1, r2:M1, r3:M2
- [M2] applied — 4.3: literal "Source: " prefix and line position not stated → rendered as `Source: <sentence>` (SOURCE_PREFIX), `<p class="muted source">` directly after `<h2>` ← 3/3: r1:M2, r2:M2, r3:M4
- [M3] applied — 4.3: SHARED_SOURCES "second sentence" read as replacement or addition → replacement, never both ← 1/3: r2:M3
- [M4] applied — 4.3: several table sentences break the "names the file or git command" rule; unclear whether table or rule wins → rule relaxed for scans, table declared a proposal, rule wins ← 1/3: r1:M3
- [M5] applied — 4.5 Data: "absolute paths removed" unclear; multi-line git messages vs one-line report → existing sanitize(), first non-empty line kept ← 3/3: r1:M4, r2:M7, r3:M7
- [M6] applied — 4.4: as-of date in committer zone vs short-local elsewhere; one commit could show two dates → short-local in commitMeta too ← 3/3: r1:M5, r2:M9, r3:M9
- [M7] applied — 4.4, 4.6: singular forms of the dirty count and the folded-branch summary missing → "1 tracked file changed, not committed", "1 older branch (...)" ← 3/3: r1:M6, r2:M8, r3:M3
- [M8] applied — 4.6: position of `<details>` vs undated items, order inside it, meaning of "without a date" undefined → explicit order, second list in same sort, "without a date" = missing, null or empty ← 1/3: r3:M5
- [M9] applied — 4.5 Report, 6: "a test compares them" owned by no test row → test-07 row runs the extractor per case and compares page line with the stderr sentence ← 2/3: r1:M7, r2:M6
- [M10] applied — 4.5: warning and information styles named no class → `shared-ref banner warn` / `shared-ref muted`, test-07 checks classes ← 2/3: r1:M8, r2:M4
- [M11] applied — 4.5 Guard: whole refused line vs reasons list joined with "; " → reason text added to the existing list ← 1/3: r2:M5
- [M12] applied — 3, 4.5, 4.6: git claims without source (removed/renamed remote, default sort, -local suffix) → git-remote(1), git-for-each-ref(1), git-log(1) cited; oldest git version labelled unverified ← 2/3: r2:M10, r3:M8
- [M13] applied — 4.5 Data: `<ref>` in date and count commands undefined; bare name could resolve to a local branch → full name refs/remotes/<name> required ← 1/3: r3:M6
- self-review note: r3's uncounted remark applied — releases sentence "last 15" → "first 15, in file order"; source-text test declared an accepted exception to the public-interface rule

## Round 3 — Feasibility & architecture risk — claude-opus-5-5
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 2 Important, 2 Minor | r2: 0 Critical, 3 Important, 2 Minor | r3: 0 Critical, 1 Important, 4 Minor
**Sources mapped:** 14/14
**Reviewer verdict:** 0 Critical, 3 Important, 4 Minor
**Converged:** no

### Dispositions
- [I1] applied — 4.4, 4.6: "same date on every line" false; commits() (:457) and git-runs.js (:143, shared with /pickup) keep committer zone → commits() moves to short-local; git-runs.js left unchanged and stated as an accepted limit (pickup coupling) ← 3/3: r1:I1, r2:I2, r3:I1
- [I2] applied — 4.5 Page, 6: element creation unspecified; renderPage runs several times, an inserted `<p>` duplicates; fake-page.js has fixed STATIC_IDS → static `<p id="shared-ref" hidden>` after #as-of, set by each render; fake-page.js row; render-twice test ← 3/3: r1:I2, r2:I3, r3:M1
- [I3] applied — 4.1 Extractor: KIND.raw removal breaks malformed work-log rows (tableItems :577, test-05 :96) → KIND.raw kept, only the open-item branch removed; search rule extended to every removal list; test-05 row asserts raw rows ← 1/3: r2:I1
- [M1] applied — 3, 4.1 Parser: lineAtOccurrence kept "byte-for-byte" though its only caller is removed; cited range held SUPERSEDED_MARK and ID_SEPARATOR; anchor sentence inaccurate → lineAtOccurrence removed with its test-02 cases; explicit name list; sentence reworded to the page's id match ← 2/3: r1:M1, r3:M2
- [M2] applied — 4.3 Numbers: PART_STATUSES test compares exports, not source text; SOURCES not exported → SOURCES/SHARED_SOURCES added to DashboardApp; only the extractor side reads source text ← 3/3: r1:M2, r2:M1, r3:M3
- [M3] applied — 4.1, 8: "reports sessionOpenItems as removed" does not match diff() output → real lines quoted ← 1/3: r2:M2
- [M4] applied — 4.5, 4.6: day count across daylight-saving change undefined → calendar-day count on YYYY-MM-DD parts with Date.UTC, test row extended ← 1/3: r3:M4

## Round 4 — Adversarial failure modes — claude-opus-5-5
**Reviewers:** M=3, usable 3/3
**Reviewer verdicts:** r1: 0 Critical, 3 Important, 4 Minor | r2: 0 Critical, 0 Important, 5 Minor | r3: 0 Critical, 3 Important, 3 Minor
**Sources mapped:** 18/18
**Reviewer verdict:** 0 Critical, 4 Important, 8 Minor
**Converged:** no

### Dispositions
- [I1] applied — 4.5 warning rule: age of the ref tip (days > 14 and notShown > 0) warns on a feature branch over a quiet shared main and misses recent staleness; "only the age separates the cases" false → rule 1 now uses the age of the oldest commit not in the shared ref (oldestNotShown > 14 days); relative ref age removed from the data and text ← 2/3: r1:I1, r3:I2
- [I2] applied — 4.5, 7 item 4: line describes the ref, not the last published shared page; a step 6 that fails at every refresh stays invisible on the page → `published` from <state>/shared.json and `previousBuild` from <state>/private.json; rule 2 warns when the shared publish lags the previous private publish by more than 14 days or never happened; share step 5 now copies shared.json ← 2/3: r1:I2, r3:I3
- [I3] applied — 4.5 Input: the model must add --shared-ref at every refresh; an omission hides the line silently → no new option; the private run reads sharing/sharedRef/sharedUrl from config.json through --data-dir ← 1/3: r1:I3
- [I4] applied — 4.5 Page: shared data has no sharedRef key (undefined, not null); literal "=== null" shows a broken line on every shared page → hidden when `== null`; test-07 checks hidden and empty on the shared page ← 1/3: r3:I1
- [M1] applied — 4.5 Input: a hand-stored sharedRef with a single quote breaks the step-4 command and stops the private refresh → resolved by I3 (no shell argument); test-04 case with a single quote ← 2/3: r1:M1, r3:M2
- [M2] applied — 4.5: after `share off` the public page stays online and frozen, and the private page drops the line → "sharing off" case with an information line and the last publish time ← 2/3: r1:M2, r2:M5
- [M3] applied — 4.5 Page: "(today)", "(N days ago)" frozen at build time mislead on a page opened later → relative ages removed from the texts; only dates are shown, the rules compare dates at build time ← 2/3: r1:M3, r2:M4
- [M4] rejected: the "as of" part counts tracked files only and says "tracked" (round 1 M9); items read from untracked files already carry the page's lock sign "not committed" (template lock sign, E:230-232/280-284), so the owner is not told they are committed — untracked files not counted in the "as of" line ← 1/3: r1:M4
- [M5] applied — 4.6 Current branch: %(refname:short) prints heads/<name> when a tag has the same name, so [current] and "never folded" fail → name read with %(refname:lstrip=2); test-04 case with a same-name tag ← 2/3: r2:M1, r3:M1
- [M6] applied — 4.5 Page, 7: squash or rebase merges make "commits that the shared page does not show" false → literal wording "commits of this branch are not in <name>"; accepted limit 5 in section 7 ← 1/3: r2:M2
- [M7] applied — 4.5 Page: "is N commits ahead of it" false on a diverged detached HEAD → literal "has N commits that are not in <name>" ← 1/3: r2:M3
- [M8] applied — 4.1, 7 item 3: a resolve proposal left in applying after its write landed becomes invalid; rejecting it does not undo the [resolved mark → stated in section 7 item 3 and for the release notes ← 1/3: r3:M3

## Self-review after the loop — 2026-10-19
- self-review note: section 2 item 5 updated to the round 4 design (shared publish state, two warning rules); grep for stale wording of the removed design ("today", "days ago", "ahead of", "This branch has", --shared-ref, `days`) found no remaining use; no placeholder.
- self-review note: the round 4 redesign of section 4.5 (rules 1 and 2, config read by the extractor, published/previousBuild, share copying shared.json) was made after the last review round and has not been reviewed by an independent reviewer.
