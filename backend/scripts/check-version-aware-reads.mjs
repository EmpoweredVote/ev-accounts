#!/usr/bin/env node
/**
 * CI gate: a voter read that collapses `inform.politician_answers` to the newest season must also apply
 * the version rule — a chair shows only on the ladder version it was written for.
 * Design: docs/superpowers/specs/2026-10-07-version-aware-reads-design.md.
 *
 * WHY. Every read inlines its own `DISTINCT ON … ORDER BY s.number DESC`. A new read that forgets the
 * version predicate shows a Season 1 chair against Season 2's rewritten ladder — silently, with no
 * error. The same drift happened to the zero guard (`@zero-scope`) and the season predicate
 * (`check-answer-season-consumers`), so this gate is the third in the family and has the same shape.
 *
 * THE UNIT IS THE SQL LITERAL (a backtick template). A literal is SUBJECT when it names
 * `inform.politician_answers` AND collapses by season (`s.number DESC`). It PASSES when it carries
 *   - `writtenForServedVersion(` (the shared predicate, from seasonService), or
 *   - `@version-scope: <reason>` with a stated reason of 20+ characters (a judged exception).
 * A bare marker is refused, like `@season-scope`.
 *
 * ⚠ IT READS TEXT, NOT MEANING. A literal that calls the helper but applies it INSIDE the collapse
 * passes; the tests in compassService.test.ts pin the placement for the voter reads. Read a green run
 * as "no collapsing read forgot the question".
 *
 * Usage (from backend/): node scripts/check-version-aware-reads.mjs [--verbose]
 */
import { readFileSync, readdirSync } from 'node:fs';
import { join, relative, sep } from 'node:path';

const VERBOSE = process.argv.includes('--verbose');
const ROOT = 'src';

const TABLE = /\binform\.politician_answers\b/i;
const COLLAPSE = /\bs\.number\s+DESC\b/i;
const HELPER = /writtenForServedVersion\s*\(/;
const MARKER = /@version-scope:\s*(\S[^\n]*)/i;

const stripBlockAndJsComments = (t) => t.replace(/\/\*[\s\S]*?\*\//g, ' ').replace(/(^|[^:])\/\/[^\n]*/g, '$1 ');
const stripSqlComments = (t) => t.replace(/--[^\n]*/g, ' ');

function files(root) {
  return readdirSync(root, { recursive: true, encoding: 'utf8' })
    .filter((f) => f.endsWith('.ts') && !f.endsWith('.test.ts'))
    .filter((f) => f.split(sep).join('/') !== 'types/database.types.ts')
    .map((f) => join(root, f));
}

function literals(text) {
  const out = [];
  const re = /`(?:[^`\\]|\\[\s\S])*`/g;
  let m;
  while ((m = re.exec(text)) !== null) out.push({ body: m[0], line: text.slice(0, m.index).split('\n').length });
  return out;
}

const offenders = [];
const judged = [];
let passing = 0;
for (const path of files(ROOT)) {
  const raw = readFileSync(path, 'utf8');
  const rel = relative(ROOT, path).split(sep).join('/');
  for (const { body, line } of literals(raw)) {
    const code = stripSqlComments(body);
    if (!TABLE.test(code) || !COLLAPSE.test(code)) continue;
    if (HELPER.test(code)) { passing++; continue; }
    const m = MARKER.exec(body);
    if (m) {
      const reason = m[1].replace(/^[—–-]+\s*/, '').trim();
      if (reason.length >= 20 || /^written-for-served/.test(reason)) { judged.push({ rel, line, reason }); continue; }
      offenders.push({ rel, line, why: '@version-scope with no stated reason — say why, in the literal' });
      continue;
    }
    offenders.push({ rel, line, why: 'collapses politician_answers to the newest season without the version rule (writtenForServedVersion) or an @version-scope: reason' });
  }
}

if (VERBOSE) {
  console.log(`using the helper: ${passing}`);
  for (const j of judged) console.log(`  judged  ${j.rel}:${j.line}  ${j.reason}`);
}
if (offenders.length) {
  console.error('check-version-aware-reads: FAIL');
  for (const o of offenders) console.error(`  ${o.rel}:${o.line}  ${o.why}`);
  console.error('\nA read that shows a newest-season chair must apply writtenForServedVersion (seasonService.ts) AFTER the collapse,');
  console.error('or declare why not:  -- @version-scope: <reason, 20+ chars>');
  process.exit(1);
}
console.log(`check-version-aware-reads: OK (${passing} read(s) use the helper, ${judged.length} judged exception(s))`);
