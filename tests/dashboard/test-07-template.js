'use strict';
// skills/dashboard/template.html, the view: placeholders, the page contract,
// text-only insertion (the fake document throws on innerHTML), tabs, the
// as-of line, the lock sign, the audience check of the inline data.
const fs = require('fs');
const path = require('path');
const h = require('./helpers');
const { TEMPLATE, APP, fakeDocument, load, settle } = require('./fake-page');

const PAYLOAD = '</script><img src=x onerror=alert(1)>';
const count = (text, needle) => text.split(needle).length - 1;

const source = (file) => ({ file, heading: null, headingOrdinal: null, line: null, occurrence: null, lineNumber: null });
function sample(audience, branch) {
  return {
    schemaVersion: 1,
    audience,
    generatedAt: '2026-09-29T20:40:00+02:00',
    repo: { name: `repo${PAYLOAD}` },
    commit: { sha: 'a'.repeat(40), short: 'aaaaaaa', date: '2026-09-29', branch, ref: 'HEAD', defaultBranch: 'main' },
    sections: {
      git: { status: 'ok', note: '', ahead: 2, dirty: 1, items: [{ id: '1'.repeat(40), visibility: 'tracked', source: source(null), kind: 'branch', name: `feature/${PAYLOAD}`, date: '2026-01-01' }] },
      sessions: { status: 'ok', note: '', items: [{ id: '2'.repeat(40), visibility: 'private', source: source('session-log.md'), kind: 'session', entry: '## 2026-09-28 10:00 [saved]', goal: PAYLOAD }] },
      commits: { status: 'ok', note: '', items: [{ id: '3'.repeat(40), visibility: 'tracked', source: source(null), kind: 'commit', sha: 'b'.repeat(40), short: 'bbbbbbb', date: '2026-01-01', subject: PAYLOAD }] },
      knownIssues: { status: 'not-found', note: 'known-issues.md not found', items: [] },
    },
  };
}

// 1. The template file.
h.eq('each placeholder appears exactly once', ['__DASHBOARD_AUDIENCE__', '__DASHBOARD_TITLE__', '<!--__DASHBOARD_STATE__-->'].map((p) => count(TEMPLATE, p)), [1, 1, 1]);
h.check('the audience placeholder is the meta tag', TEMPLATE.includes('<meta name="dashboard-audience" content="__DASHBOARD_AUDIENCE__">'));
h.check('the state placeholder stands before the app script', TEMPLATE.indexOf('<!--__DASHBOARD_STATE__-->') < TEMPLATE.indexOf('<script id="dashboard-app">'));
for (const needle of ['prefers-color-scheme: dark', ':root:not([data-theme="light"])', ':root[data-theme="dark"]', 'body {', 'background: var(--bg)', 'padding: 16px', 'overflow-wrap: anywhere']) {
  h.check(`the page contract: ${needle}`, TEMPLATE.includes(needle));
}
h.check('the private banner text', TEMPLATE.includes('Private page — do not make it public'));
h.check('the two fixed tab ids and labels', TEMPLATE.includes('id="tab-waits"') && TEMPLATE.includes('>Waits for me<') && TEMPLATE.includes('id="tab-history"') && TEMPLATE.includes('>History<'));
for (const banned of ['innerHTML', 'outerHTML', 'insertAdjacentHTML', 'document.write', 'DOMParser', 'createContextualFragment', 'srcdoc', 'eval(', 'new Function']) {
  h.check(`the app script does not use ${banned}`, APP.length > 0 && !APP.includes(banned));
}

// 2. Rendering data that holds markup.
const doc = fakeDocument('private');
const app = load(doc).DashboardApp;
app.renderPage({ data: sample('private', 'main'), canEdit: false, proposals: new Map(), store: null });
h.check('no element is created from the text', doc.created.every((node) => !['IMG', 'SCRIPT', 'IFRAME'].includes(node.tagName)));
h.check('the markup is shown as text', doc.getElementById('panel-waits').textContent.includes(PAYLOAD) && doc.getElementById('panel-history').textContent.includes(PAYLOAD));
h.eq('the title line holds the repository name as text', doc.getElementById('page-title').textContent, `repo${PAYLOAD} dashboard`);
const BUILT_PART = ' · built 2026-09-29 20:40';
const asOf = (audience, branch, dirty) => {
  const data = sample(audience, branch);
  data.sections.git.dirty = dirty;
  return app.asOfLine(data);
};
h.eq('the as-of line of the rendered page', doc.getElementById('as-of').textContent, `as of commit aaaaaaa (2026-09-29) on branch main${BUILT_PART} · 1 tracked file changed, not committed`);
h.eq('the as-of line: detached with 2 changed files, a branch with none, the shared page', [asOf('private', null, 2), asOf('private', 'main', 0), asOf('shared', 'origin/main', null)], [
  `as of commit aaaaaaa (2026-09-29), detached HEAD${BUILT_PART} · 2 tracked files changed, not committed`,
  `as of commit aaaaaaa (2026-09-29) on branch main${BUILT_PART}`,
  `as of commit aaaaaaa (2026-09-29) on branch origin/main${BUILT_PART}`,
]);
const order = (panel) => doc.getElementById(panel).children.map((card) => card.getAttribute('data-section'));
h.eq('tab 1 sections, in order', order('panel-waits'), ['unfinishedRuns', 'git', 'activeWorklogs', 'currentGoal']);
h.eq('tab 2 sections, in order', order('panel-history'), ['releases', 'runHistory', 'closedWorklogs', 'commits', 'sessions', 'knownIssues']);
const locks = doc.created.filter((node) => node.getAttribute('class') === 'lock');
h.eq('one lock sign, on the private item only', locks.length, 1);
// The lines under the title of a section card: [class, text] of each one.
const VIEW = { data: sample('private', 'main'), canEdit: false, proposals: new Map(), store: null };
const KNOWN_ISSUES = 'knownIssues';
// children[0] is the title and children[1] the Source line.
const cardLines = (card) => card.children.slice(2).map((line) => [line.getAttribute('class'), line.textContent]);
const sectionLines = (section) => cardLines(app.renderSection(KNOWN_ISSUES, section, VIEW));
const emptySection = (status, note) => ({ status, note, items: [] });
const MUTED = 'muted';
const NOTHING_HERE = 'nothing here';
const missingLines = (section) => [[MUTED, `${NOTHING_HERE} (${section.note})`]];
const missing = VIEW.data.sections[KNOWN_ISSUES];
const history = doc.getElementById('panel-history');
h.eq('the page shows a missing source as an empty section with its note', cardLines(history.children.find((card) => card.getAttribute('data-section') === KNOWN_ISSUES)), missingLines(missing));
h.check('the page shows no status word for a missing source', !history.textContent.includes(missing.status));
h.eq('an empty section that is ok shows one muted line', sectionLines(emptySection('ok', '')), [[MUTED, NOTHING_HERE]]);
h.eq('a missing source with a note shows the same muted line and the note, with no status word', sectionLines(missing), [[MUTED, `${NOTHING_HERE} (known-issues.md not found)`]]);
h.eq('a missing source without a note shows the muted line only', sectionLines(emptySection(missing.status, '')), [[MUTED, NOTHING_HERE]]);
h.eq('an error keeps its status word and the error style', sectionLines(emptySection('error', 'git command failed')), [['status error', 'error: git command failed']]);
// The section that the extractor writes for a missing source is shown that way.
const noIssuesFile = h.repo('template-missing-source');
h.write(noIssuesFile, 'file.txt', 'x\n');
h.commit(noIssuesFile, 'base', ['file.txt']);
const extracted = JSON.parse(h.node(noIssuesFile, [h.script('dashboard-extract.js'), '--audience', 'private']).out).sections[KNOWN_ISSUES];
h.eq('the extractor\'s section of a missing source is shown as an empty section', sectionLines(extracted), missingLines(extracted));
h.check('the git counts are shown', doc.getElementById('panel-waits').textContent.includes('2 commits not pushed'));
// The Git card (spec section 4.6): order, [current], the fold at 90 days.
const DAY_MS = 24 * 60 * 60 * 1000;
const SAMPLE_DAY = Date.UTC(2026, 8, 29);
const daysBefore = (n) => new Date(SAMPLE_DAY - n * DAY_MS).toISOString().slice(0, 10);
const branchItem = (name, date, extra) => Object.assign({ id: `b-${name}`, visibility: 'tracked', source: source(null), kind: 'branch', name }, date === undefined ? {} : { date }, extra || {});
const SHARED_VIEW = { data: sample('shared', 'origin/main'), canEdit: false, proposals: new Map(), store: null };
function gitCard(items, view) {
  const card = app.renderSection('git', { status: 'ok', note: '', ahead: null, dirty: null, items }, view || VIEW);
  const names = (list) => list.children.map((li) => li.children[0].textContent.split(' · ')[0]);
  const list = card.children.find((node) => node.tagName === 'UL');
  const details = card.children.find((node) => node.tagName === 'DETAILS');
  return { shown: list ? names(list) : [], summary: details ? details.children[0].textContent : null, folded: details ? names(details.children[1]) : [] };
}
const BRANCHES = [
  branchItem('x-empty', ''), branchItem('old91', daysBefore(91)), branchItem('b-new', daysBefore(1)), branchItem('y-null', null),
  branchItem('cur', daysBefore(300), { current: true }), branchItem('a-new', daysBefore(1)), branchItem('edge90', daysBefore(90)),
  branchItem('z-missing'), branchItem('older200', daysBefore(200)),
];
const EXPECTED_CARD = {
  shown: ['a-new', 'b-new', 'edge90', 'cur [current]', 'x-empty', 'y-null', 'z-missing'],
  summary: '2 older branches (no commit in the last 90 days)',
  folded: ['old91', 'older200'],
};
h.eq('git card: newest first, then by name; no date last; the current branch never folded; old branches folded in order', gitCard(BRANCHES), EXPECTED_CARD);
h.eq('git card: the shared page sorts and folds the same way', gitCard(BRANCHES, SHARED_VIEW), EXPECTED_CARD);
h.eq('git card: one old branch', gitCard([branchItem('a', daysBefore(1)), branchItem('old', daysBefore(91))]).summary, '1 older branch (no commit in the last 90 days)');
h.eq('git card: no old branch makes no details element', gitCard([branchItem('a', daysBefore(90))]), { shown: ['a'], summary: null, folded: [] });
// The Source line (spec section 4.3): directly after the title, in every state.
const SECTION_IDS = ['unfinishedRuns', 'git', 'activeWorklogs', 'currentGoal', 'releases', 'runHistory', 'closedWorklogs', 'commits', 'sessions', 'knownIssues'];
const SOURCE_STATES = {
  'with items': { status: 'ok', note: '', items: [{ id: 'i'.repeat(40), visibility: 'tracked', source: source(null), kind: 'known-issue', title: 't' }] },
  empty: { status: 'ok', note: '', items: [] },
  'not found': { status: 'not-found', note: 'x not found', items: [] },
  failed: { status: 'error', note: 'git command failed', items: [] },
  absent: undefined,
};
const sourceOf = (id, state, view) => {
  const card = app.renderSection(id, state, view);
  return [card.children[0].tagName, card.children[1].getAttribute('class'), card.children[1].textContent, card.textContent.split('Source: ').length - 1];
};
h.check('every section has a sentence', SECTION_IDS.every((id) => typeof app.SOURCES[id] === 'string' && app.SOURCES[id].length > 0));
for (const id of SECTION_IDS) {
  for (const [label, state] of Object.entries(SOURCE_STATES)) {
    h.eq(`the Source line of ${id}, ${label}`, sourceOf(id, state, VIEW), ['H2', 'muted source', `Source: ${app.SOURCES[id]}`, 1]);
  }
  const sharedSentence = app.SHARED_SOURCES[id] || app.SOURCES[id];
  h.eq(`the shared Source line of ${id}`, sourceOf(id, SOURCE_STATES.empty, SHARED_VIEW), ['H2', 'muted source', `Source: ${sharedSentence}`, 1]);
  if (app.SHARED_SOURCES[id]) h.check(`the shared card of ${id} does not show the private sentence`, !app.renderSection(id, SOURCE_STATES.empty, SHARED_VIEW).textContent.includes(app.SOURCES[id]));
}
h.eq('SHARED_SOURCES replaces the sentences of unfinishedRuns, git and commits', Object.keys(app.SHARED_SOURCES).sort(), ['commits', 'git', 'unfinishedRuns']);
const ALL_SENTENCES = Object.values(app.SOURCES).concat(Object.values(app.SHARED_SOURCES));
h.check('no sentence holds an absolute path or a home folder', ALL_SENTENCES.every((sentence) => !/(^|\s|\()(\/|~|[A-Za-z]:[\\/])/.test(sentence)));
const SESSION = { kind: 'session', goal: 'Rename the RDKit helper' };
h.eq('a session line starts with the date and time of its entry', app.itemLines(Object.assign({ entry: '## 2026-10-14 12:00 [saved]' }, SESSION)), ['2026-10-14 12:00 · Rename the RDKit helper']);
h.eq('an entry with no date and time, or no entry: the goal alone', [app.itemLines(Object.assign({ entry: '## Notes' }, SESSION)), app.itemLines(SESSION)], [['Rename the RDKit helper'], ['Rename the RDKit helper']]);

// 3. Boot with inline data: the audience check and the banner.
async function boot(pageAudience, data) {
  const bootDoc = fakeDocument(pageAudience, JSON.stringify(data));
  load(bootDoc, { DASHBOARD_NO_BOOT: false });
  await settle();
  return bootDoc;
}
(async () => {
  const own = await boot('private', sample('private', 'main'));
  h.eq('a private page shows the banner and its sections', [own.getElementById('private-banner').hidden, own.getElementById('panel-waits').children.length], [false, 4]);
  // A click on the History tab shows its panel and hides the other one.
  own.getElementById('tab-history').listeners.click();
  h.eq('a click on the History tab selects it', [own.getElementById('panel-history').hidden, own.getElementById('panel-waits').hidden, own.getElementById('tab-history').getAttribute('aria-selected'), own.getElementById('tab-waits').getAttribute('aria-selected')], [false, true, 'true', 'false']);
  const shared = await boot('shared', sample('shared', 'origin/main'));
  h.eq('a shared page hides the banner', shared.getElementById('private-banner').hidden, true);
  const wrong = await boot('shared', sample('private', 'main'));
  h.eq('data of another audience: an error line and no section', [wrong.getElementById('load-error').hidden, wrong.getElementById('panel-waits').children.length], [false, 0]);
  const wrongPrivate = await boot('private', sample('shared', 'origin/main'));
  h.eq('a private page keeps its banner when the data is refused', [wrongPrivate.getElementById('load-error').hidden, wrongPrivate.getElementById('private-banner').hidden], [false, false]);
  // 4. Boot with no inline block: the data file is fetched from the page's own origin.
  const renderSource = fs.readFileSync(path.join(h.SCRIPTS, 'dashboard-render.js'), 'utf8');
  const dataFile = renderSource.match(/^const DATA_FILE = '([^']+)';/m)[1];
  async function bootFetch(pageAudience, fakeFetch) {
    const fetchDoc = fakeDocument(pageAudience);
    load(fetchDoc, { DASHBOARD_NO_BOOT: false, fetch: fakeFetch });
    await settle();
    return fetchDoc;
  }
  const requested = [];
  const fetched = await bootFetch('private', async (url) => {
    requested.push(url);
    return { ok: true, status: 200, json: async () => sample('private', 'main') };
  });
  h.eq('the page requests the data file that the renderer publishes', requested, [dataFile]);
  h.eq('the fetched data renders its sections', fetched.getElementById('panel-waits').children.length, 4);
  const notFound = await bootFetch('private', async () => ({ ok: false, status: 404, json: async () => ({}) }));
  h.eq('an HTTP error shows the banner with the status and no section', [notFound.getElementById('load-error').hidden, notFound.getElementById('load-error').textContent.includes('The dashboard data could not be loaded') && notFound.getElementById('load-error').textContent.includes('HTTP 404'), notFound.getElementById('panel-waits').children.length], [false, true, 0]);
  h.eq('a private page keeps its banner on an HTTP error', notFound.getElementById('private-banner').hidden, false);
  const badJson = await bootFetch('private', async () => ({ ok: true, status: 200, json: async () => { throw new Error('bad json'); } }));
  h.eq('a JSON parse failure shows the banner', [badJson.getElementById('load-error').hidden, badJson.getElementById('load-error').textContent.includes('The dashboard data could not be loaded'), badJson.getElementById('panel-waits').children.length], [false, true, 0]);
  h.finish();
})();
