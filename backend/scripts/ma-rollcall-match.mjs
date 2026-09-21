#!/usr/bin/env node
/**
 * Read a Massachusetts roll-call PDF (already converted with `pdftotext -table`) and decide, for a
 * given list of politicians, how each voted.
 *
 * 🔑 MA IS EASIER AND SAFER THAN MD ON IDENTITY: the sheet prints "Surname, First M.", not a bare
 * surname, so the collision risk that forced roster checks in Maryland largely disappears. Match on
 * surname AND first name; a surname-only match is reported as AMBIGUOUS, never resolved.
 *
 * 🔑 SELF-CHECK, same discipline as MD: each section ends with its own count ("Velis, John C. - 37.").
 * If the parsed name count does not equal the declared count, the parse is VOID and every verdict
 * from it is discarded. Free and decisive.
 *
 * 🔴 Reads only.
 *   node scripts/ma-rollcall-match.mjs --text <rc.txt> --names <names.json> [--out <out.json>]
 */
import fs from 'node:fs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const TEXT = flag('--text'), NAMES = flag('--names'), OUT = flag('--out');
if (!TEXT || !NAMES) { console.error('need --text --names'); process.exit(2); }

const raw = fs.readFileSync(TEXT, 'utf8');

/** Split the sheet into its declared sections. */
function sections(t) {
  const marks = [...t.matchAll(/\n\s*(YEAS|NAYS|ABSENT OR NOT VOTING|NOT VOTING)\.?\s*\n/gi)];
  const out = [];
  for (let i = 0; i < marks.length; i++) {
    const name = marks[i][1].toUpperCase();
    const start = marks[i].index + marks[i][0].length;
    const end = i + 1 < marks.length ? marks[i + 1].index : t.length;
    out.push({ name, body: t.slice(start, end) });
  }
  return out;
}

/** "Surname, First M." possibly followed by " - 37." which declares the section total. */
function parseSection(body) {
  const names = [];
  let declared = null;
  // Cells are separated by 2+ spaces in -table output, so a two-column sheet splits cleanly.
  for (const cell of body.split(/\n|\s{2,}/)) {
    const s = cell.trim();
    if (!s) continue;
    const dec = s.match(/-\s*(\d+)\s*\.?\s*$/);
    if (dec) declared = Number(dec[1]);
    const m = s.replace(/-\s*\d+\s*\.?\s*$/, '').trim()
      .match(/^([A-Z][A-Za-z'’-]+(?:\s+[A-Z][A-Za-z'’-]+)*),\s*([A-Z][A-Za-z'’-]*)(?:\s+([A-Z])\.)?/);
    if (m) names.push({ surname: m[1].trim(), first: m[2].trim(), initial: m[3] || null, raw: s });
  }
  return { names, declared };
}

const secs = sections(raw).map((s) => ({ ...s, ...parseSection(s.body) }));
let void_parse = false;
for (const s of secs) {
  const ok = s.declared !== null && s.names.length === s.declared;
  console.log(`${s.name.padEnd(22)} parsed ${String(s.names.length).padStart(3)}  declared ${s.declared ?? '?'}  ${ok ? 'OK' : '🔴 MISMATCH'}`);
  if (!ok) void_parse = true;
}
if (void_parse) {
  console.error('\n🔴 PARSE VOID -- a declared count was not reproduced. No verdicts issued.');
  process.exit(1);
}

const targets = JSON.parse(fs.readFileSync(NAMES, 'utf8'));
const norm = (s) => s.toLowerCase().replace(/[^a-z]/g, '');
const results = targets.map((full) => {
  const clean = full.replace(/,?\s+(Jr\.|Sr\.|II|III|IV)$/i, '').trim();
  const parts = clean.split(/\s+/);
  const surname = parts[parts.length - 1];
  const first = parts[0];
  let verdict = 'NOT_ON_SHEET', matched = null;
  for (const s of secs) {
    const bySur = s.names.filter((n) => norm(n.surname) === norm(surname));
    if (!bySur.length) continue;
    const exact = bySur.filter((n) => norm(n.first) === norm(first));
    if (exact.length === 1) { verdict = s.name; matched = exact[0].raw; break; }
    if (bySur.length === 1 && !exact.length) { verdict = 'AMBIGUOUS_FIRST_NAME'; matched = bySur[0].raw; break; }
    if (bySur.length > 1 && exact.length !== 1) { verdict = 'AMBIGUOUS_SURNAME'; matched = bySur.map((x) => x.raw).join(' / '); break; }
  }
  return { politician: full, verdict, matched };
});

const tally = results.reduce((m, r) => { m[r.verdict] = (m[r.verdict] || 0) + 1; return m; }, {});
console.log('\n' + JSON.stringify(tally, null, 2) + '\n');
for (const r of results) console.log(`${r.verdict.padEnd(22)} ${r.politician}${r.matched ? '   [' + r.matched + ']' : ''}`);
if (OUT) fs.writeFileSync(OUT, JSON.stringify({ sections: secs.map((s) => ({ name: s.name, n: s.names.length, declared: s.declared })), results }, null, 1));
