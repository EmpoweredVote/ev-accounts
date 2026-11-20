#!/usr/bin/env node
/**
 * Fails if any script sends a personal email address to an external host in a
 * User-Agent header.
 *
 * 🔴 WHY THIS EXISTS. 77 scripts in this directory put a named individual's address in
 * their User-Agent and sent it to Wikimedia, the Internet Archive and state government
 * hosts on every request. Two different people's addresses were involved. Nobody chose
 * that; each script copied the one before it, and nothing was watching.
 *
 * The client name and version are wanted -- Wikimedia 429s a fully anonymous
 * User-Agent, so the fix is to identify the CLIENT, never a person. Use the public
 * project URL. If a host genuinely demands a contact address, read it from an
 * environment variable the operator sets; do not hardcode one.
 *
 *   node backend/scripts/check-user-agent-privacy.mjs
 */
import fs from 'node:fs';
import path from 'node:path';

const ROOT = path.resolve(path.dirname(new URL(import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1')));
const EXTS = new Set(['.py', '.mjs', '.js', '.ts', '.mts', '.cjs']);
const EMAIL = /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/;

/**
 * Role mailboxes are allowed; a person's address is not.
 *
 * Wikimedia's User-Agent policy asks for a way to contact the operator, and an
 * organisational mailbox answers that without naming anybody. The addresses this check
 * was written to stop were two individuals'.
 */
const ROLE_MAILBOX = /^(info|contact|abuse|admin|webmaster|support|noreply|hello)@/i;
// A User-Agent assignment, in any of the shapes this repo actually uses.
// 🔴 `user[-_]?agent` and not `user-agent`: the constant is spelled USER_AGENT with an
// underscore, and an earlier version of this check missed every one of them. Its control
// looked like it fired only because unrelated files happened to be reported at the time.
const UA_LINE = /user[-_]?agent|^\s*(const\s+)?UA\s*[=:]|CONTACT\s*=/i;

function* walk(dir) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    if (e.name === 'node_modules' || e.name.startsWith('.')) continue;
    const p = path.join(dir, e.name);
    if (e.isDirectory()) yield* walk(p);
    else if (EXTS.has(path.extname(e.name))) yield p;
  }
}

const offences = [];
for (const file of walk(ROOT)) {
  if (path.basename(file) === path.basename(new URL(import.meta.url).pathname)) continue;
  const lines = fs.readFileSync(file, 'utf8').split('\n');
  lines.forEach((line, i) => {
    if (!UA_LINE.test(line)) return;
    const m = line.match(EMAIL);
    if (m && !ROLE_MAILBOX.test(m[0])) {
      offences.push(`${path.relative(ROOT, file)}:${i + 1}  ${m[0].replace(/^[^@]*/, '<address>')}`);
    }
  });
}

if (offences.length > 0) {
  console.error(`\n🔴 ${offences.length} User-Agent line(s) carry an email address:\n`);
  for (const o of offences) console.error(`   ${o}`);
  console.error('\nUse a generic client name and the public project URL. Never a person.\n');
  process.exit(1);
}
console.log(`user-agent privacy: clean (${[...walk(ROOT)].length} scripts scanned)`);
