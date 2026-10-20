'use strict';
// dashboard-extract.js, private audience: stops, the state folder and
// config.json, commit meta, unfinishedRuns, git, commits.
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const h = require('./helpers');

const EXTRACT = h.script('dashboard-extract.js');
const run = (dir, args) => h.node(dir, [EXTRACT, ...args]);
function extract(dir) {
  const result = run(dir, ['--audience', 'private']);
  if (result.code !== 0) throw new Error(`extract failed: ${result.err}`);
  return JSON.parse(result.out);
}
const STOPPED = '## STOPPED — 2026-09-02 — phase 2 — blocked';
const COMPLETED = '_Completed — 2026-09-03 — HEAD abc1234_';
const NOW = new Date().toISOString();

// 1. The run cannot start.
const plain = path.join(h.ROOT, 'plain');
fs.mkdirSync(plain);
h.eq('not a git repository: exit 2', run(plain, ['--audience', 'private']).code, 2);
h.eq('no commit yet: exit 2', run(h.repo('empty'), ['--audience', 'private']).code, 2);

// 2. Fixture: main, five run branches and 24 more commits on main.
const d = h.repo('core');
h.write(d, 'file.txt', 'base\n');
h.commit(d, 'base', ['file.txt']);
function runBranch(slug, text, date) {
  h.git(d, 'checkout', '-q', '-b', `feature/${slug}`, 'main');
  h.write(d, h.logPath('2026-09-01', slug), text);
  h.commit(d, `${slug} log`, ['docs'], date);
  h.git(d, 'checkout', '-q', 'main');
}
runBranch('stopped', h.runLog('stopped', ['## Phase 1', STOPPED]));
runBranch('old', h.runLog('old', ['## Phase 3 — Batch 1']));
runBranch('fresh', h.runLog('fresh', ['## Phase 3 — Batch 2']), NOW);
runBranch('done', `${h.runLog('done', ['## Phase 1'])}${COMPLETED}\n`);
runBranch('merged', h.runLog('merged', ['## Phase 1']));
h.git(d, 'merge', '-q', '--no-edit', 'feature/merged');
h.git(d, 'checkout', '-q', '-b', 'feature/twin', 'main');
h.write(d, h.logPath('2026-08-01', 'twin'), h.runLog('twin', ['## Phase 1']));
h.write(d, h.logPath('2026-09-10', 'twin'), h.runLog('twin', ['## Phase 2']));
h.commit(d, 'twin logs', ['docs']);
h.git(d, 'checkout', '-q', 'main');
for (let i = 1; i <= 24; i += 1) {
  h.write(d, 'file.txt', `line ${i}\n`);
  h.commit(d, `commit ${i}`, ['file.txt']);
}

let doc = extract(d);
h.eq('document head', [doc.schemaVersion, doc.audience, doc.repo.name, doc.commit.branch, doc.commit.ref, doc.commit.defaultBranch], [1, 'private', 'core', 'main', 'HEAD', 'main']);
h.check('generatedAt is local time with its offset', /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$/.test(doc.generatedAt));
h.check('commit sha and short hash', /^[0-9a-f]{40}$/.test(doc.commit.sha) && doc.commit.short === doc.commit.sha.slice(0, 7));
h.check('commit.date is a date', /^\d{4}-\d{2}-\d{2}$/.test(doc.commit.date || ''), String(doc.commit.date));
h.eq('unfinishedRuns: branches and marks', doc.sections.unfinishedRuns.items.map((i) => [i.branch, i.mark]), [
  ['feature/fresh', 'in progress'],
  ['feature/old', 'no commit since 2026-01-09 — may need resume'],
  ['feature/stopped', 'stopped — waits for you'],
  ['feature/twin', 'ambiguous — waits for you'],
]);
h.eq('a stopped run shows its last heading', doc.sections.unfinishedRuns.items[2].lastHeading, STOPPED);
h.eq('git: unmerged local branches, the default branch excluded', doc.sections.git.items.map((i) => i.name), ['feature/done', 'feature/fresh', 'feature/old', 'feature/stopped', 'feature/twin']);
h.eq('git: with the default branch checked out no item is marked current', doc.sections.git.items.some((i) => 'current' in i), false);
h.eq('git: no upstream gives a null count and a note', [doc.sections.git.ahead, /no upstream/.test(doc.sections.git.note)], [null, true]);
h.eq('git: a clean tree has no uncommitted change', doc.sections.git.dirty, 0);
h.eq('commits: the last 20, newest first', [doc.sections.commits.items.length, doc.sections.commits.items[0].subject, doc.sections.commits.items[19].subject], [20, 'commit 24', 'commit 5']);
h.check('every item has an id and tracked visibility', doc.sections.commits.items.every((i) => /^[0-9a-f]{40}$/.test(i.id) && i.visibility === 'tracked'));
h.check('the JSON holds no absolute path of the fixture', !JSON.stringify(doc).includes(h.ROOT));

// 3. Uncommitted changes: a tracked change counts, an untracked file does not.
h.write(d, 'file.txt', 'changed\n');
h.write(d, 'new.txt', 'untracked\n');
h.eq('git: one tracked file with uncommitted changes', extract(d).sections.git.dirty, 1);
h.git(d, 'checkout', '-q', '--', 'file.txt');
fs.unlinkSync(path.join(d, 'new.txt'));

// 4. The checked-out run branch stays in unfinishedRuns; a detached HEAD.
h.git(d, 'checkout', '-q', 'feature/stopped');
doc = extract(d);
h.eq('the checked-out run branch is still an unfinished run', [doc.commit.branch, doc.sections.unfinishedRuns.items.some((i) => i.branch === 'feature/stopped')], ['feature/stopped', true]);
const currentItems = (sections) => sections.git.items.filter((i) => 'current' in i).map((i) => [i.name, i.current]);
h.eq('git: only the checked-out unmerged branch is marked current', currentItems(doc.sections), [['feature/stopped', true]]);
h.git(d, 'tag', 'feature/stopped');
h.eq('a tag with the name of the branch: the plain name, still current', currentItems(extract(d).sections), [['feature/stopped', true]]);
h.git(d, 'tag', '-d', 'feature/stopped');
h.git(d, 'checkout', '-q', '--detach', 'main');
h.eq('a detached HEAD gives branch null', extract(d).commit.branch, null);
h.git(d, 'checkout', '-q', 'main');

// 5. No default branch.
const t = h.repo('trunk-only', 'trunk');
h.write(t, 'file.txt', 'base\n');
h.commit(t, 'base', ['file.txt']);
const noDefault = extract(t);
h.eq('no default branch: defaultBranch null and two notes', [noDefault.commit.defaultBranch, /no default branch/.test(noDefault.sections.unfinishedRuns.note), /no default branch/.test(noDefault.sections.git.note)], [null, true, true]);

// 6. --out: outside the repository only.
const inside = path.join(d, 'private.json');
h.eq('--out inside the repository stops', [run(d, ['--audience', 'private', '--out', inside]).code, fs.existsSync(inside)], [2, false]);
const outside = path.join(h.ROOT, 'scratch', 'private.json');
const written = run(d, ['--audience', 'private', '--out', outside]);
h.check('--out outside the repository writes the file and names it', written.code === 0 && written.out.startsWith(`written ${outside} `) && JSON.parse(fs.readFileSync(outside, 'utf8')).audience === 'private');

// --out at a symbolic link stops and leaves the link's target untouched.
const linkTarget = path.join(h.ROOT, 'scratch', 'link-target.json');
const linkOut = path.join(h.ROOT, 'scratch', 'link-out.json');
fs.writeFileSync(linkTarget, 'keep');
let haveLink = true;
try { fs.symlinkSync(linkTarget, linkOut); } catch (error) { haveLink = false; console.log('  NOTE: this file system refuses a symbolic link; the --out link case is skipped'); }
if (haveLink) h.eq('--out at a symbolic link stops, the target is untouched', [run(d, ['--audience', 'private', '--out', linkOut]).code, fs.readFileSync(linkTarget, 'utf8')], [2, 'keep']);

// 7. The state folder and config.json.
const data = path.join(h.ROOT, 'plugin-data');
const key = `core-${crypto.createHash('sha1').update(fs.realpathSync(d), 'utf8').digest('hex').slice(0, 12)}`;
const state = run(d, ['--data-dir', data, '--state-dir']);
h.eq('--state-dir prints <data dir>/dashboard/<repo key>', state.out.trim(), path.join(data, 'dashboard', key));
h.check('--state-dir creates the folder', fs.existsSync(path.join(data, 'dashboard', key)));
h.eq('an empty --data-dir stops', run(d, ['--data-dir', '', '--state-dir']).code, 2);
h.eq('an unsubstituted --data-dir stops', run(d, ['--data-dir', '${CLAUDE_PLUGIN_DATA}', '--state-dir']).code, 2);
h.eq('--config with no config.json prints {}', run(d, ['--data-dir', data, '--config']).out.trim(), '{}');
run(d, ['--data-dir', data, '--config-set', 'privateUrl=https://claude.ai/code/artifact/x']);
const set = run(d, ['--data-dir', data, '--config-set', 'sharing=on']);
h.eq('--config-set keeps the earlier keys', JSON.parse(set.out), { privateUrl: 'https://claude.ai/code/artifact/x', sharing: 'on' });
h.eq('an unknown key stops', run(d, ['--data-dir', data, '--config-set', 'colour=red']).code, 2);
h.eq('a sharing value other than on or off stops', run(d, ['--data-dir', data, '--config-set', 'sharing=maybe']).code, 2);
const withDataDir = run(d, ['--data-dir', '', '--audience', 'private', '--out', outside]);
h.check('an extraction that carries --data-dir (even empty) still writes the document', withDataDir.code === 0 && withDataDir.out.startsWith(`written ${outside} `));

// 8. A git command that fails: `git log` of a history whose oldest commit
// object is missing. An alternates entry that names a missing folder inside
// the repository makes git print the repository path on standard error, so
// the note must show it as <repo>.
const broken = h.repo('core-broken');
h.write(broken, 'file.txt', 'one\n');
const lostCommit = h.commit(broken, 'first', ['file.txt']);
h.write(broken, 'file.txt', 'two\n');
h.commit(broken, 'second', ['file.txt']);
fs.unlinkSync(path.join(broken, '.git', 'objects', lostCommit.slice(0, 2), lostCommit.slice(2)));
fs.writeFileSync(path.join(broken, '.git', 'objects', 'info', 'alternates'), `${fs.realpathSync(broken)}/missing-objects\n`);
const brokenCommits = extract(broken).sections.commits;
h.eq('a failed git command gives an error section', brokenCommits.status, 'error');
h.check('the error note names no absolute path of the repository', !brokenCommits.note.includes(broken) && !brokenCommits.note.includes(fs.realpathSync(broken)));
h.check('the error note writes the repository root as <repo>', brokenCommits.note.includes('<repo>/missing-objects'));

// 9. A failed git command inside the run scan: the log blob of a run branch
// is missing, so `git show` fails. The run stays in the list with an empty
// text, and the section must not look healthy.
const lost = h.repo('core-lost-log');
h.write(lost, 'file.txt', 'base\n');
h.commit(lost, 'base', ['file.txt']);
h.git(lost, 'checkout', '-q', '-b', 'feature/lost', 'main');
h.write(lost, h.logPath('2026-09-01', 'lost'), h.runLog('lost', ['## Phase 1']));
h.commit(lost, 'lost log', ['docs']);
h.git(lost, 'checkout', '-q', 'main');
const lostBlob = h.git(lost, 'rev-parse', `feature/lost:${h.logPath('2026-09-01', 'lost')}`).trim();
fs.unlinkSync(path.join(lost, '.git', 'objects', lostBlob.slice(0, 2), lostBlob.slice(2)));
fs.writeFileSync(path.join(lost, '.git', 'objects', 'info', 'alternates'), `${fs.realpathSync(lost)}/missing-objects\n`);
const lostRuns = extract(lost).sections.unfinishedRuns;
h.eq('a failed git command of the run scan gives an error section', lostRuns.status, 'error');
h.check('the scan error note writes the repository root as <repo>', lostRuns.note.includes('<repo>') && !lostRuns.note.includes(fs.realpathSync(lost)));

// 10. Local dates (spec section 4.4): a commit at 23:30 UTC is on the next
// day in Tokyo (UTC+9). `--date=short` would print the committer's date;
// `short-local` prints the local date.
const LATE = '2026-01-09T23:30:00+00:00';
const TOKYO = { TZ: 'Asia/Tokyo' };
const LOCAL_DAY = '2026-01-10';
const tz = h.repo('core-local-dates');
h.write(tz, 'file.txt', 'base\n');
h.commit(tz, 'late base', ['file.txt'], LATE);
h.git(tz, 'checkout', '-q', '-b', 'feature/late');
h.write(tz, 'file.txt', 'late\n');
h.commit(tz, 'late branch', ['file.txt'], LATE);
const tzRun = h.node(tz, [EXTRACT, '--audience', 'private'], TOKYO);
const tzDoc = tzRun.code === 0 ? JSON.parse(tzRun.out) : null;
h.eq('local dates: commit.date, the branch date and the commit dates', tzDoc && [tzDoc.commit.date, tzDoc.sections.git.items.map((i) => i.date), tzDoc.sections.commits.items.map((i) => i.date)], [LOCAL_DAY, [LOCAL_DAY], [LOCAL_DAY, LOCAL_DAY]]);
h.git(tz, 'checkout', '-q', 'main');

// 11. The shared-ref line of the private run (spec section 4.5): read from
// config.json and the state files through --data-dir; never a stop.
const sr = h.repo('core-shared-ref');
h.addRemote(sr, 'core-shared-ref-remote');
h.write(sr, 'file.txt', 'base\n');
h.commit(sr, 'base', ['file.txt'], LATE);
h.git(sr, 'push', '-q', '-u', 'origin', 'main');
const srData = path.join(h.ROOT, 'shared-ref-data');
const REPORT = 'dashboard-extract: shared page: ';
const exits = [];
// One private run in <sr> with <args>, in Tokyo time; gives
// [the sharedRef value, the report lines without their prefix]. A document
// without the key gives a text, so that "absent" never passes as null.
const NO_KEY = 'no sharedRef key';
function sharedRefRun(args) {
  const result = h.node(sr, [EXTRACT, '--audience', 'private', ...args], TOKYO);
  exits.push(result.code);
  const reports = result.err.split('\n').filter((line) => line.startsWith(REPORT)).map((line) => line.slice(REPORT.length));
  if (result.code !== 0) return [`exit ${result.code}: ${result.err}`, reports];
  const parsed = JSON.parse(result.out);
  return [Object.prototype.hasOwnProperty.call(parsed, 'sharedRef') ? parsed.sharedRef : NO_KEY, reports];
}
const withData = () => sharedRefRun(['--data-dir', srData]);
const setKey = (assignment) => run(sr, ['--data-dir', srData, '--config-set', assignment]);
const srState = run(sr, ['--data-dir', srData, '--state-dir']).out.trim();
const stateFile = (name, content) => fs.writeFileSync(path.join(srState, name), content);
const removeState = (...names) => names.forEach((name) => fs.rmSync(path.join(srState, name), { force: true }));
const NEVER = 'Never published from this machine.';

h.eq('no line: no --data-dir', sharedRefRun([]), [null, []]);
h.eq('no line: no config.json', withData(), [null, []]);
stateFile('config.json', 'not json');
h.eq('no line: a config.json that is not valid JSON', withData(), [null, []]);
removeState('config.json');
setKey('sharing=off');
h.eq('no line: sharing off without sharedUrl', withData(), [null, []]);
setKey('sharedUrl=https://claude.ai/code/artifact/shared');
h.eq('sharing off with sharedUrl', withData(), [{ off: true, published: null }, [`Sharing is off. The shared page from an earlier share is still published and is no longer updated. ${NEVER}`]]);
setKey('sharing=on');
setKey('sharedRef=origin/main');
const tip = h.git(sr, 'rev-parse', 'HEAD').slice(0, 7);
let [info, reports] = withData();
const fieldsOf = (value) => [value.name, value.short, value.date, value.notShown, value.oldestNotShown, value.published, value.previousBuild];
h.eq('following, nothing not shown: the fields, in local dates', fieldsOf(info), ['origin/main', tip, LOCAL_DAY, 0, null, null, null]);
h.eq('following, nothing not shown: the report line', reports, [`The shared page follows origin/main, last commit ${LOCAL_DAY}. ${NEVER}`]);
h.write(sr, 'file.txt', 'one\n');
h.commit(sr, 'not shown 1', ['file.txt'], '2026-01-11T23:30:00+00:00');
[info, reports] = withData();
h.eq('one commit not shown, with its local date', [info.notShown, info.oldestNotShown], [1, '2026-01-12']);
h.eq('one commit not shown: the report line', reports, [`The shared page follows origin/main, last commit ${LOCAL_DAY}. 1 commit of this branch is not in origin/main; it is from 2026-01-12. ${NEVER}`]);
h.write(sr, 'file.txt', 'two\n');
h.commit(sr, 'not shown 2', ['file.txt'], '2026-01-14T12:00:00+00:00');
[info, reports] = withData();
h.eq('two commits not shown: the count and the oldest date', [info.notShown, info.oldestNotShown], [2, '2026-01-12']);
h.eq('two commits not shown: the report line', reports, [`The shared page follows origin/main, last commit ${LOCAL_DAY}. 2 commits of this branch are not in origin/main; the oldest is from 2026-01-12. ${NEVER}`]);
// A tag with the same name as the shared value: git resolves a bare
// "origin/main" to the tag (refs/tags comes before refs/remotes), so this
// case fails any command that does not name refs/remotes/origin/main.
h.git(sr, 'tag', 'origin/main', 'HEAD');
[info] = withData();
h.eq('a tag with the same name as the shared value is not followed', [info.short, info.notShown], [tip, 2]);
h.git(sr, 'tag', '-d', 'origin/main');
stateFile('shared.json', JSON.stringify({ generatedAt: '2026-10-01T10:05:00+02:00' }));
stateFile('private.json', JSON.stringify({ generatedAt: '2026-10-15T09:00:00+02:00' }));
[info, reports] = withData();
h.eq('published and previousBuild come from the state files', [info.published, info.previousBuild], ['2026-10-01 10:05', '2026-10-15 09:00']);
h.eq('published: the report line', reports, [`The shared page follows origin/main, last commit ${LOCAL_DAY}. 2 commits of this branch are not in origin/main; the oldest is from 2026-01-12. Last published 2026-10-01 10:05.`]);
stateFile('shared.json', 'not json');
stateFile('private.json', '{');
[info] = withData();
h.eq('state files that are not valid JSON give null', [typeof info, info.published, info.previousBuild], ['object', null, null]);
removeState('shared.json', 'private.json');
setKey('sharedRef=origin/gone');
[info] = withData();
h.eq('a missing ref', [info.name, info.missing, info.published, info.previousBuild, 'error' in info], ['origin/gone', true, null, null, false]);
setKey('sharedRef=main');
h.eq('a value of the wrong form', withData()[0].error, 'main is not of the form <remote>/<branch>');
setKey("sharedRef=origin/a'b");
h.eq('a value with a single quote', withData()[0].error, "origin/a'b is not of the form <remote>/<branch>");
h.git(sr, 'update-ref', 'refs/remotes/origin/tree', h.git(sr, 'rev-parse', 'HEAD^{tree}'));
setKey('sharedRef=origin/tree');
h.eq('a ref that is not a commit', withData()[0].error, 'origin/tree is not a commit');
setKey('sharedRef=origin/main');
// A file in the repository root whose name equals a ref must not make git
// refuse the ref as ambiguous: a file HEAD (commit.date) and a file
// refs/remotes/origin/main (the shared-ref line).
h.write(sr, 'HEAD', 'not a ref\n');
h.write(sr, 'refs/remotes/origin/main', 'not a ref\n');
setKey('sharedRef=origin/main');
const ambiguous = sharedRefRun(['--data-dir', srData]);
h.check('a file named like a ref: the private extract exits 0 and the shared-ref line is normal', typeof ambiguous[0] === 'object' && !('error' in ambiguous[0]) && /^\d{4}-\d{2}-\d{2}$/.test(ambiguous[0].date), JSON.stringify(ambiguous));
const ambiguousDoc = JSON.parse(h.node(sr, [EXTRACT, '--audience', 'private'], TOKYO).out || 'null');
h.check('a file named HEAD: commit.date is a date', /^\d{4}-\d{2}-\d{2}$/.test((ambiguousDoc && ambiguousDoc.commit.date) || ''));
h.eq('a file named HEAD: the commits section is ok', ambiguousDoc && ambiguousDoc.sections.commits.status, 'ok');
fs.rmSync(path.join(sr, 'HEAD'), { force: true });
fs.rmSync(path.join(sr, 'refs'), { recursive: true, force: true });
h.git(sr, 'remote', 'remove', 'origin');
h.eq('a removed remote: the ref is missing', withData()[0].missing, true);
h.check('every private run exits 0', exits.every((code) => code === 0), exits.join(','));

h.finish();
