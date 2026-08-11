#!/usr/bin/env node
/**
 * Look up a named Maryland "Act" against the local bill-title corpus.
 *
 * 🔴 COVERAGE BOUND: the corpus is 2013RS-2026RS. The 2012 session index parses to ZERO rows,
 * so a MISS for anything from 2012 or earlier means UNKNOWN, never "does not exist".
 *
 * Prints nothing but evidence. Proposes no action.
 *   node scripts/lookup-md-act.mjs --corpus <corpus.json> --act "Climate Solutions Now Act" [--act ...]
 */
import fs from 'node:fs';

const argv = process.argv.slice(2);
const many = (n) => argv.reduce((a, v, i) => (v === n && argv[i + 1] ? [...a, argv[i + 1]] : a), []);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };

const corpusPath = flag('--corpus');
const acts = many('--act');
const actsFile = flag('--acts-file');
if (actsFile) acts.push(...JSON.parse(fs.readFileSync(actsFile, 'utf8')));
if (!corpusPath || !acts.length) { console.error('need --corpus and at least one --act'); process.exit(2); }

const { bills } = JSON.parse(fs.readFileSync(corpusPath, 'utf8'));

const norm = (s) => s.toLowerCase()
  .replace(/[‘’']/g, '')
  .replace(/[^a-z0-9 ]+/g, ' ')
  .replace(/\bmarylands?\b/g, ' ')
  .replace(/\bof \d{4}\b/g, ' ')
  .replace(/\s+/g, ' ')
  .trim();

// Index titles once.
const idx = bills.map((b) => ({ ...b, n: norm(b.title) }));

function lookup(act) {
  const a = norm(act);
  if (!a) return { act, verdict: 'EMPTY', hits: [] };
  const exact = idx.filter((b) => b.n.includes(a));
  if (exact.length) return { act, verdict: 'FOUND', hits: exact };
  // token-subset fallback: every token of the act appears in the title
  const toks = a.split(' ').filter((t) => t.length > 2);
  const loose = toks.length >= 2 ? idx.filter((b) => toks.every((t) => b.n.includes(t))) : [];
  if (loose.length) return { act, verdict: 'FOUND_LOOSE', hits: loose };
  return { act, verdict: 'NOT_IN_CORPUS', hits: [] };
}

const results = acts.map(lookup);
for (const r of results) {
  const uniq = [...new Map(r.hits.map((h) => [h.number + h.session, h])).values()];
  const sessions = [...new Set(uniq.map((h) => h.session))].sort();
  console.log(`\n${r.verdict.padEnd(14)} ${r.act}`);
  if (uniq.length) {
    console.log(`   ${uniq.length} bill(s), sessions ${sessions.join(',')}`);
    for (const h of uniq.slice(0, 4)) console.log(`   · ${h.session} ${h.number} ${h.title}  [${h.sponsor}]`);
    if (uniq.length > 4) console.log(`   · …${uniq.length - 4} more`);
  }
}
const tally = results.reduce((m, r) => { m[r.verdict] = (m[r.verdict] || 0) + 1; return m; }, {});
console.log(`\nTALLY ${JSON.stringify(tally)}`);
if (flag('--json-out')) fs.writeFileSync(flag('--json-out'), JSON.stringify(results.map((r) => ({
  act: r.act, verdict: r.verdict,
  hits: [...new Map(r.hits.map((h) => [h.number + h.session, h])).values()].slice(0, 8),
})), null, 1));
