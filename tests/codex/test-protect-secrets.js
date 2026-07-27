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

console.log('\nprotect-secrets: unrelated rules still fire');

test('private key read still blocked', () => assert.strictEqual(blocks('cat ~/.ssh/id_rsa'), true));
test('aws credentials read still blocked', () => assert.strictEqual(blocks('cat ~/.aws/credentials'), true));
test('sourcing the env file still blocked', () => assert.strictEqual(blocks(`source ${ENV}`), true));
test('ordinary command allowed', () => assert.strictEqual(blocks('git status --short'), false));

console.log(`\n${'─'.repeat(50)}`);
console.log(`protect-secrets: ${passed} passed, ${failed} failed`);
if (failed > 0) process.exit(1);
