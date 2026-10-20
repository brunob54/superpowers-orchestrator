'use strict';
// dashboard-sync.js --apply and --batches: one write per file, line endings
// and the byte order mark kept, repeated runs, both orders of two rows, a
// file that changes during the write, a sync stopped after the marking, ids
// that were not marked, a removed proposal kind, a held run, batches of at
// most 50 records, and the security cases: a link at a temporary name, bytes
// that are not valid UTF-8, a git failure after a write, and an id with a
// line break.
const fs = require('fs');
const path = require('path');
const h = require('./helpers');

const SYNC = h.script('dashboard-sync.js');
const CREATED = '2026-09-29T00:30:00+02:00';
const SHA = 'c'.repeat(40);
const W = 'docs/worklogs/w.md';
// A second work log, which git does not track.
const U = 'docs/worklogs/u.md';
const WORKLOG_DIR = ['docs', 'worklogs'];
const ROW4 = '| 4 | fourth | in progress | 2026-09-23 | | |';
const ROW5 = '| 5 | fifth | not started | | | |';
const DONE4 = '| 4 | fourth | done | 2026-09-29 |  |  |';
const DONE5 = '| 5 | fifth | done | 2026-09-29 |  |  |';
const WORKLOG = [
  '<!-- Work log: status=active slug=w created=2026-09-21 -->', '', '## Parts', '',
  '| # | Part | Status | Since | Commit | Note |', '|---|------|--------|-------|--------|------|', ROW4, ROW5, '',
].join('\n');
// The line indexes of the two rows in WORKLOG.
const AT4 = 6;
const AT5 = 7;
const ROWS = { 4: ROW4, 5: ROW5 };
const part = (number, fields, extra) => Object.assign({
  kind: 'set-part', file: W, branch: 'main', baseCommit: SHA,
  anchor: { heading: '## Parts', headingOrdinal: 1, line: ROWS[number], occurrence: 1, part: String(number) },
  createdAt: CREATED, state: 'pending', closedAt: null,
}, fields, extra || {});
const done = (number, extra) => part(number, { status: 'done' }, extra);

let folderCount = 0;
function folderOf(docs) {
  folderCount += 1;
  const folder = path.join(h.ROOT, `apply-${folderCount}`);
  Object.entries(docs).forEach(([id, doc], i) => h.proposalFile(folder, id, doc, i + 1));
  return folder;
}
const versionsOf = (folder) => ['--versions', h.versionsFile(folder)];
const apply = (dir, folder, ids, env) => h.node(dir, [SYNC, '--apply', folder, ...ids, ...versionsOf(folder)], env);
const lines = (result) => result.out.trim().split('\n');
const read = (dir, rel) => fs.readFileSync(path.join(dir, ...rel.split('/')), 'utf8');
const rowsOf = (dir) => read(dir, W).split('\n');
const tempFiles = (dir) => fs.readdirSync(path.join(dir, ...WORKLOG_DIR)).filter((name) => name.endsWith('.tmp'));
function freshRepo(name, worklogText) {
  const d = h.repo(name);
  h.write(d, W, worklogText === undefined ? WORKLOG : worklogText);
  h.commit(d, 'base', ['docs']);
  return d;
}

// 1. Two rows of one file in one call; a second run writes nothing.
let d = freshRepo('apply-one');
const both = folderOf({ a: done(4), b: done(5) });
let result = apply(d, both, ['a', 'b']);
h.eq('both rows are written in one call', [rowsOf(d)[AT4], rowsOf(d)[AT5]], [DONE4, DONE5]);
h.eq('the report lines', lines(result), ['proposal a: applied', 'proposal b: applied', `changed ${W} (tracked)`]);
const afterFirst = read(d, W);
result = apply(d, both, ['a', 'b']);
h.check('a second run gives already-applied and writes nothing', lines(result).every((line) => line.includes('already-applied')) && read(d, W) === afterFirst);

// 2. The two rows applied one at a time, in both orders.
for (const order of [['b', 'a'], ['a', 'b']]) {
  d = freshRepo(`apply-order-${order.join('')}`);
  const folder = folderOf({ a: done(4), b: done(5) });
  order.forEach((id) => apply(d, folder, [id]));
  h.eq(`order ${order.join(' then ')}: both rows written, none twice`, [rowsOf(d)[AT4], rowsOf(d)[AT5], read(d, W).split('| done |').length - 1], [DONE4, DONE5, 2]);
}

// 3. A part: status and note on one row, in a tracked file.
d = freshRepo('apply-part');
result = apply(d, folderOf({ p: part(4, { status: 'done', note: 'finished' }) }), ['p']);
h.eq('the row is rewritten', rowsOf(d)[AT4], '| 4 | fourth | done | 2026-09-29 |  | finished |');
h.eq('a tracked file is named as tracked', lines(result)[1], `changed ${W} (tracked)`);

// 4. Carriage returns and a byte order mark are kept.
d = freshRepo('apply-crlf', `\ufeff${WORKLOG.split('\n').join('\r\n')}`);
apply(d, folderOf({ c: done(5) }), ['c']);
const raw = read(d, W);
h.eq('byte order mark, carriage returns, changed line', [raw.startsWith('\ufeff'), raw.split('\n').slice(0, -1).every((line) => line.endsWith('\r')), raw.split('\r\n')[AT5]], [true, true, DONE5]);

// 5. The file changes between the read and the rename: the check runs again.
d = freshRepo('apply-race');
result = apply(d, folderOf({ c: done(5) }), ['c'], { DASHBOARD_SYNC_TEST_CHANGE_ONCE: 'appended line\n' });
h.eq('the change is applied and the other writer\'s line is kept', [lines(result)[0], rowsOf(d)[AT5], read(d, W).includes('appended line')], ['proposal c: applied', DONE5, true]);
h.eq('no temporary file is left', tempFiles(d), []);

// 6. A sync that stopped after the marking: the next check completes it.
d = freshRepo('apply-resume', WORKLOG.replace(ROW4, DONE4));
const marked = folderOf({ a: done(4, { state: 'applying' }), b: done(5, { state: 'applying' }) });
const checked = h.node(d, [SYNC, '--check', marked, ...versionsOf(marked)]);
h.check('check: already-applied for the written row, unique for the other', checked.out.includes('proposal a: already-applied') && checked.out.includes('proposal b: unique'));
h.eq('apply completes it', lines(apply(d, marked, ['a', 'b'])).slice(0, 2), ['proposal a: already-applied — the row already holds this change', 'proposal b: applied']);

// 7. Only the listed ids are written; an unknown id is reported; an invalid
// proposal and a proposal of the kind removed in 7.73.0 write nothing.
d = freshRepo('apply-subset');
result = apply(d, folderOf({ a: done(4), b: done(5) }), ['a', 'zzz']);
h.eq('an id that was not marked is not written', [rowsOf(d)[AT4], rowsOf(d)[AT5]], [DONE4, ROW5]);
h.check('an unknown id is reported', lines(result)[0] === 'proposal zzz: not-found — no file for this id in the folder');
const beforeInvalid = fs.readFileSync(path.join(d, ...W.split('/')));
const invalidRun = apply(d, folderOf({ x: done(5, { file: '../docs/worklogs/w.md' }) }), ['x']);
h.check('an invalid proposal is reported and nothing is written', lines(invalidRun)[0].startsWith('proposal x: invalid') && fs.readFileSync(path.join(d, ...W.split('/'))).equals(beforeInvalid));
const removedKind = {
  kind: 'resolve-open-item', file: 'session-log.md', branch: 'main', baseCommit: SHA,
  anchor: { heading: '## 2026-01-01 [saved]', headingOrdinal: 1, line: '- same', occurrence: 1 },
  createdAt: CREATED, state: 'applying', closedAt: null,
};
const removedRun = apply(d, folderOf({ r: removedKind }), ['r']);
h.eq('an applying proposal of the removed kind: invalid with its reason, nothing written', [lines(removedRun), fs.readFileSync(path.join(d, ...W.split('/'))).equals(beforeInvalid), fs.existsSync(path.join(d, 'session-log.md'))], [['proposal r: invalid — resolve-open-item was removed in 7.73.0; reject this proposal'], true, false]);

// 7b. Two proposals whose anchors name the same row: one is applied, the
// other is refused, and the file holds one change.
d = freshRepo('apply-same-line');
result = apply(d, folderOf({ a: done(4), b: part(4, { note: 'other' }) }), ['a', 'b']);
h.eq('one applied, one refused for the same line', lines(result).slice(0, 2), ['proposal a: applied', 'proposal b: none — another proposal of this sync changes the same line']);
h.eq('the file holds exactly one change', rowsOf(d)[AT4], DONE4);

// 8. A held run: nothing is written.
d = freshRepo('apply-held');
h.git(d, 'checkout', '-q', '-b', 'feature/stopped');
h.write(d, h.logPath('2026-09-21', 'stopped'), h.runLog('stopped', ['## STOPPED — 2026-09-21 — phase 3 — blocked']));
h.commit(d, 'stopped log', ['docs/superpowers-orchestrator']);
h.git(d, 'checkout', '-q', 'main');
result = apply(d, folderOf({ p: done(4) }), ['p']);
h.eq('held-run: the tracked file is not written', [lines(result).length, lines(result)[0].startsWith('proposal p: held-run'), read(d, W)], [1, true, WORKLOG]);

// 9. Batches of at most 50 records, pinned to each file's version.
const many = {};
for (let i = 0; i < 120; i += 1) many[`p${String(i).padStart(3, '0')}`] = done(4);
const manyFolder = folderOf(many);
const manyVersions = versionsOf(manyFolder);
const ids = Object.keys(many);
const batchLines = lines(h.node(d, [SYNC, '--batches', manyFolder, 'applied', ...ids, ...manyVersions])).map((line) => JSON.parse(line));
h.eq('three batches of 50, 50 and 20', batchLines.map((batch) => batch.length), [50, 50, 20]);
const first = batchLines[0][0];
h.eq('one record', [first.op, first.collection, first.doc_id, first.data.state, first.if_version, batchLines[2][19].if_version], ['update', 'proposals', 'p000', 'applied', 1, 120]);
h.check('applied records carry closedAt as local time with its offset', /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$/.test(first.data.closedAt));
h.eq('pending records carry closedAt null', JSON.parse(lines(h.node(d, [SYNC, '--batches', manyFolder, 'pending', 'p000', ...manyVersions]))[0])[0].data.closedAt, null);
h.eq('an unknown state stops', h.node(d, [SYNC, '--batches', manyFolder, 'done', 'p000', ...manyVersions]).code, 2);
h.eq('an id with no file stops', h.node(d, [SYNC, '--batches', manyFolder, 'applied', 'nothing', ...manyVersions]).code, 2);
h.eq('a --data-dir pair is accepted and not read', JSON.parse(lines(h.node(d, [SYNC, '--data-dir', '', '--batches', manyFolder, 'pending', 'p000', ...manyVersions]))[0])[0].doc_id, 'p000');

// A preload module runs in the process of the script before the script
// itself, so it can act at the exact moment that another program would.
function preload(name, code) {
  const file = path.join(h.ROOT, name);
  fs.writeFileSync(file, `'use strict';\nconst fs = require('fs');\nconst path = require('path');\n${code}\n`);
  return file;
}
const applyWith = (module, dir, folder, applyIds) => h.node(dir, ['-r', module, SYNC, '--apply', folder, ...applyIds, ...versionsOf(folder)]);
const DONE_LINES = WORKLOG.split('\n');
DONE_LINES[AT5] = DONE5;

// 10. A symbolic link at the temporary name (the random part is fixed by the
// preload): the create-only write never goes through it.
d = freshRepo('apply-temp-link');
const outside = path.join(h.ROOT, 'outside-apply.txt');
fs.writeFileSync(outside, 'OUTSIDE');
const TEMP_NAME_HEX = '07'.repeat(6);
const plantLink = preload('plant-link.js', `require('crypto').randomBytes = (count) => Buffer.alloc(count, 7);
fs.symlinkSync(${JSON.stringify(outside)}, path.join(process.cwd(), ${WORKLOG_DIR.map((segment) => JSON.stringify(segment)).join(', ')}, '.w.md.dashboard-${TEMP_NAME_HEX}.tmp'));`);
result = applyWith(plantLink, d, folderOf({ c: done(5) }), ['c']);
h.eq('a link at the temporary name: the create-only write stops, the outside file and the target are unchanged', [fs.readFileSync(outside, 'utf8'), result.code !== 0, result.out.includes('proposal c: applied'), read(d, W)], ['OUTSIDE', true, false, WORKLOG]);

// 11. A byte that is not valid UTF-8 on a line that no proposal changes is
// written back as it was.
const LATIN1_LINE = Buffer.from('caf\xE9 (latin-1)\n', 'latin1');
d = freshRepo('apply-bytes', Buffer.concat([Buffer.from(WORKLOG), LATIN1_LINE]));
apply(d, folderOf({ c: done(5) }), ['c']);
h.check('the lines not changed are written back byte for byte', fs.readFileSync(path.join(d, ...W.split('/'))).equals(Buffer.concat([Buffer.from(DONE_LINES.join('\n')), LATIN1_LINE])));

// 12. Git fails after the first file was written: the report of that file
// is printed before the stop. The untracked work log U is written first.
d = freshRepo('apply-git-fails');
h.write(d, U, WORKLOG);
const breakIndex = preload('break-index.js', `const rename = fs.renameSync;
fs.renameSync = (...args) => {
  rename(...args);
  fs.renameSync = rename;
  fs.writeFileSync(path.join(process.cwd(), '.git', 'index'), 'not an index');
};`);
result = applyWith(breakIndex, d, folderOf({ a: done(5, { file: U }), b: done(4) }), ['a', 'b']);
h.eq('the written file is reported, then the git failure stops', [result.code, lines(result)], [2, ['proposal a: applied', `changed ${U} (untracked)`]]);

// 14. The file changes during every attempt (only the modification time, so
// the bytes stay the same): nothing is written, no applied line, exit 1.
d = freshRepo('apply-always-changing');
const touchAlways = preload('touch-always.js', `const stat = fs.statSync;
let tick = 0;
fs.statSync = (target, ...rest) => {
  const result = stat(target, ...rest);
  if (String(target).endsWith('w.md')) { tick += 1; fs.utimesSync(target, 1000 + tick, 1000 + tick); }
  return result;
};`);
result = applyWith(touchAlways, d, folderOf({ c: done(5) }), ['c']);
h.eq('a file that changes 3 times: exit 1, one not-written line, no proposal line, bytes kept', [result.code, lines(result).length, lines(result)[0].startsWith(`not written: ${W} changed 3 times`), result.out.includes('proposal '), read(d, W), tempFiles(d)], [1, 1, true, false, WORKLOG, []]);

// 15. The rename fails: exit 1, one not-written line naming the temporary
// file that keeps the new text, no proposal line, the target unchanged.
d = freshRepo('apply-rename-fails');
const failRename = preload('fail-rename.js', `fs.renameSync = () => { throw new Error('rename refused'); };`);
result = applyWith(failRename, d, folderOf({ c: done(5) }), ['c']);
const kept = (lines(result)[0].match(/the new text is kept in (.+)$/) || [])[1];
h.eq('a failed rename: exit 1, one not-written line, no proposal line, bytes kept', [result.code, lines(result).length, lines(result)[0].startsWith(`not written: ${W}: rename refused`), result.out.includes('proposal '), read(d, W)], [1, 1, true, false, WORKLOG]);
h.check('the printed temporary file exists and holds the new text', Boolean(kept) && fs.existsSync(kept) && fs.readFileSync(kept, 'utf8') === DONE_LINES.join('\n'));
if (kept) fs.rmSync(kept, { force: true });

// 13. An id argument with a line break is printed escaped, on one line.
d = freshRepo('apply-id-escape');
const escapeFolder = folderOf({ a: done(4) });
const FORGED = 'zz\nproposal a: applied';
h.eq('the not-found line holds the escaped id', lines(apply(d, escapeFolder, [FORGED])), [`proposal ${JSON.stringify(FORGED)}: not-found — no file for this id in the folder`]);
result = h.node(d, [SYNC, '--batches', escapeFolder, 'applied', FORGED, ...versionsOf(escapeFolder)]);
h.eq('batches: the stop message holds the escaped id on one line', [result.code, result.out, result.err.trim().split('\n').length, result.err.includes(JSON.stringify(FORGED))], [2, '', 1, true]);

h.finish();
