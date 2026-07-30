#!/usr/bin/env node
/**
 * Unit tests for hooks/safety/protect-secrets.js
 *
 * Focus: the cat-env rule must block reads of a real .env file without
 * blocking commands that merely WRITE text containing the token ".env"
 * (heredoc appends, docs generation) or mention it downstream of an
 * unrelated reader.
 */

const assert = require('assert');
const path = require('path');

const { checkBashCommand } = require(path.join(__dirname, '..', '..', 'hooks', 'safety', 'protect-secrets.js'));

let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    console.log(`  ✓ ${name}`);
    passed++;
  } catch (err) {
    console.log(`  ✗ ${name}`);
    console.log(`    ${err.message}`);
    failed++;
  }
}

function blocks(cmd) {
  return checkBashCommand(cmd).blocked;
}

function ruleId(cmd) {
  const r = checkBashCommand(cmd);
  return r.pattern ? r.pattern.id : null;
}

// Built from fragments so this file's own source is never the thing under test.
const ENV = '.' + 'env';

console.log('\nprotect-secrets: cat-env blocks real reads');

const MUST_BLOCK = [
  ['bare read', `cat ${ENV}`],
  ['nested path', `cat config/${ENV}`],
  ['with flags', `cat -n ${ENV}`],
  ['tail with numeric flag', `tail -5 ${ENV}`],
  ['environment-specific file', `cat ${ENV}.local`],
  ['production env file', `cat ${ENV}.production`],
  ['stdin redirect is still a read', `cat < ${ENV}`],
  ['other readers', `less ${ENV}`],
  ['editor', `vim ${ENV}`],
  ['template read (ALLOWLIST is deliberately not applied to bash — see checkBashCommand)',
    `cat ${ENV}.example`],
  ['template does not shield a later real read', `cat ${ENV}.example && cat ${ENV}`],
];

for (const [label, cmd] of MUST_BLOCK) {
  test(label, () => assert.strictEqual(blocks(cmd), true, `expected BLOCK for: ${cmd}`));
}

console.log('\nprotect-secrets: cat-env does not over-match writes and mentions');

const MUST_ALLOW = [
  ['heredoc append whose body mentions the token',
    `cat >> session-log.md <<'EOF'\nWe should document the ${ENV} handling later.\nEOF`],
  ['heredoc append with unrelated prose',
    `cat >> session-log.md <<'EOF'\nGoal: rename shipped\nEOF`],
  ['generating docs that reference the token',
    `cat > docs/setup.md <<'EOF'\nCopy ${ENV}.example to ${ENV}\nEOF`],
  ['heredoc to stdout mentioning the token',
    `cat <<'EOF'\nremember to gitignore ${ENV}\nEOF`],
  ['unrelated read, token mentioned after a command separator',
    `cat README.md && echo "remember to gitignore ${ENV}"`],
  ['no reader command at all', `echo "${ENV} is gitignored"`],
];

for (const [label, cmd] of MUST_ALLOW) {
  test(label, () => assert.strictEqual(
    blocks(cmd), false,
    `expected ALLOW for: ${cmd}\n    (blocked by rule: ${ruleId(cmd)})`
  ));
}

// ── The cp/mv/rm/source family shares cat-env's gap defect ───────────────────
//
// `process.env.X` in a node script contains the env-file token, so any of these
// verbs followed on the same line by such a script used to match. A backslash
// continuation is still ONE command and must keep matching.

console.log('\nprotect-secrets: file-operation family blocks real operations');

const FAMILY_MUST_BLOCK = [
  ['copy the env file', `cp ${ENV} /tmp/steal`],
  ['copy from a nested path', `cp config/${ENV} /tmp/`],
  ['move the env file', `mv ${ENV} /tmp/`],
  ['delete the env file', `rm ${ENV}`],
  ['delete with flags', `rm -f ${ENV}`],
  ['source the env file', `source ${ENV}`],
  ['dot-source the env file', `. ${ENV}`],
  ['truncate the env file', `truncate -s 0 ${ENV}`],
  ['copy a private key', 'cp ~/.ssh/id_rsa /tmp/'],
  ['delete a private key', 'rm ~/.ssh/id_ed25519'],
  ['read the netrc', 'cat ~/.netrc'],
  ['read aws credentials', 'cat ~/.aws/credentials'],
  ['read a secrets json', 'cat config/credentials.json'],
  // Backslash continuation is one command — splitting it must not evade the rule.
  ['copy split over a line continuation', `cp \\\n  ${ENV} /tmp/steal`],
  ['read split over a line continuation', `cat \\\n  ${ENV}`],
];

for (const [label, cmd] of FAMILY_MUST_BLOCK) {
  test(label, () => assert.strictEqual(blocks(cmd), true, `expected BLOCK for: ${cmd}`));
}

console.log('\nprotect-secrets: file-operation family ignores process.env and prose');

// `process` + `.env` + `.HOME`, assembled so the literal never appears here.
const PROC_ENV = 'process' + ENV + '.HOME';

const FAMILY_MUST_ALLOW = [
  ['backup then a node script reading the environment (the live failure)',
    `cp reg.json reg.json.bak\nnode -e "console.log(${PROC_ENV})"`],
  ['move then a node script reading the environment',
    `mv old.md new.md && node -e "console.log(${PROC_ENV})"`],
  ['delete then a node script reading the environment',
    `rm scratch.js && node -e "console.log(${PROC_ENV})"`],
  ['delete then a separate command mentioning the token',
    `rm tmp.txt; echo "the config lives in ${ENV}"`],
  ['copy an unrelated file, token in a later line',
    `cp a.md b.md\n# remember: ${ENV} is gitignored`],
  ['node script alone reading the environment', `node -e "console.log(${PROC_ENV})"`],
];

for (const [label, cmd] of FAMILY_MUST_ALLOW) {
  test(label, () => assert.strictEqual(
    blocks(cmd), false,
    `expected ALLOW for: ${cmd}\n    (blocked by rule: ${ruleId(cmd)})`
  ));
}

// ── Known limitation, pinned deliberately ────────────────────────────────────
//
// The gap fix stops a rule reaching past its own command, but it cannot tell
// prose from shell when a heredoc body contains a line that IS the dangerous
// command verbatim. Distinguishing them needs shell parsing, not a regex.
// Workaround when it bites: `git commit -F <file>`, or write the file with the
// Write tool instead of a heredoc.

console.log('\nprotect-secrets: known limitation — heredoc body quoting a real command');

test('heredoc body containing the literal sourcing command is still blocked', () => {
  const cmd = `cat >> README.md <<'EOF'\nRun \`source ${ENV}\` before starting.\nEOF`;
  assert.strictEqual(blocks(cmd), true);
  assert.strictEqual(ruleId(cmd), 'source-env', 'expected source-env to be the rule that fires');
});

console.log('\nprotect-secrets: unrelated rules still fire');

test('private key read still blocked', () => assert.strictEqual(blocks('cat ~/.ssh/id_rsa'), true));
test('aws credentials read still blocked', () => assert.strictEqual(blocks('cat ~/.aws/credentials'), true));
test('sourcing the env file still blocked', () => assert.strictEqual(blocks(`source ${ENV}`), true));
test('ordinary command allowed', () => assert.strictEqual(blocks('git status --short'), false));

console.log(`\n${'─'.repeat(50)}`);
console.log(`protect-secrets: ${passed} passed, ${failed} failed`);
if (failed > 0) process.exit(1);
