#!/usr/bin/env node
// A SECOND, INDEPENDENT READING OF MASSACHUSETTS' BALLOT.
//
// Massachusetts publishes NO unofficial election return — the Secretary of the Commonwealth
// says so in terms, and `CC_0411` quotes it — so there is no second source for the COUNT or the
// CALL in this state before the cities and towns certify. There IS one for the BALLOT: the
// Secretary's own "2026 State Election Candidates" page, read 2026-11-13 (see
// ma-soc-2026-11-13/README.md for how, and for what in that file is not evidence).
//
// 🔴 THIS ALSO CHECKS THE JOIN KEY, WHICH IS THE PART OF A MASSACHUSETTS PASS THAT GOES WRONG.
//   The Secretary names its districts the same way AP does and the same way we do, so a race
//   whose candidates agree on both sources is a race whose district mapped correctly — and the
//   three reversible senate pairs (Middlesex/Norfolk, Suffolk/Middlesex, Worcester/Middlesex)
//   carry different people, so a transposed key shows up here as two broken races, not as
//   silence.
import fs from 'node:fs';
import path from 'node:path';

const tsv = process.argv[2];
const analysisFile = process.argv[3];
if (!tsv || !analysisFile) { console.error('usage: verify-ma-soc.mjs <candidates.tsv> <analysis.json>'); process.exit(2); }

import { maDistrictKey as maNameKey } from './ma-district-key.mjs';

const squash = (s) => (s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z0-9]/g, '');

const theirs = new Map();
let theirRows = 0;
for (const line of fs.readFileSync(tsv, 'utf8').split('\n')) {
  if (!line.trim()) continue;
  const [ch, district, names] = line.split('|');
  const chamber = ch === 'U' ? 'STATE_UPPER' : 'STATE_LOWER';
  const list = (names || '').split(',').map((s) => s.trim()).filter(Boolean);
  const k = `${chamber}|${maNameKey(district)}`;
  if (theirs.has(k)) throw new Error(`the Secretary's file repeats a district key: ${k}`);
  theirs.set(k, { district, names: list });
  theirRows += list.length;
}

const analysis = JSON.parse(fs.readFileSync(analysisFile, 'utf8'));
const maRaces = analysis.races.filter((r) => r.state === 'ma');

const findings = [];
const suffixOnly = [];
let racesAgree = 0; let linesAgree = 0; let apRows = 0;
for (const race of maRaces) {
  const k = `${race.chamber}|${race.key}`;
  const t = theirs.get(k);
  apRows += race.lines.length;
  if (!t) { findings.push(`${race.chamber} ${race.key} (${race.our.district_label}): no district of this name on the Secretary's page`); continue; }
  // ⚠ THE SECRETARY PRINTS NO SUFFIX AND AP DOES. Ten Massachusetts candidates differ on
  //   nothing else — "Angelo J. Puppolo" against "Angelo J. Puppolo Jr.". Matching with the
  //   suffix first and recording what fell to the second comparison keeps that a NAMED class
  //   rather than a relaxation applied to everybody.
  const withSuffix = (l) => squash([l.first, l.middle, l.last, l.suffix].filter(Boolean).join(''));
  const noSuffix = (l) => squash([l.first, l.middle, l.last].filter(Boolean).join(''));
  const matched = new Set();
  const unmatchedLines = [];
  for (const l of race.lines) {
    let i = t.names.findIndex((n, j) => !matched.has(j) && n === withSuffix(l));
    if (i === -1) {
      i = t.names.findIndex((n, j) => !matched.has(j) && n === noSuffix(l));
      if (i !== -1) suffixOnly.push(`${race.chamber} ${race.key} (${t.district}): "${l.full_name}" on AP, printed without the suffix by the Secretary`);
    }
    if (i === -1) unmatchedLines.push(l); else matched.add(i);
  }
  const unmatchedTheirs = t.names.filter((_, j) => !matched.has(j));
  if (!unmatchedLines.length && !unmatchedTheirs.length) {
    racesAgree++; linesAgree += race.lines.length; continue;
  }
  for (const n of unmatchedTheirs) findings.push(`${race.chamber} ${race.key} (${t.district}): on the Secretary's ballot and NOT on AP's — ${n}`);
  for (const l of unmatchedLines) findings.push(`${race.chamber} ${race.key} (${t.district}): on AP's ballot and NOT on the Secretary's — ${l.full_name}`);
}
for (const k of theirs.keys()) {
  if (!maRaces.some((r) => `${r.chamber}|${r.key}` === k)) findings.push(`${k}: on the Secretary's page with no AP race and no race of ours`);
}

console.log(`MA Secretary of the Commonwealth : ${theirRows} candidates across ${theirs.size} districts`);
console.log(`AP ballots                       : ${apRows} lines across ${maRaces.length} races`);
console.log(`races where every line agrees on both sources: ${racesAgree} of ${maRaces.length}  (${linesAgree} lines)`);
if (suffixOnly.length) {
  console.log(`\n${suffixOnly.length} line(s) agreed only once the suffix was set aside:`);
  for (const s of suffixOnly) console.log(`  ${s}`);
}
if (findings.length) {
  console.log(`\n${findings.length} difference(s) — each one is read, not averaged:`);
  for (const f of findings) console.log(`  ${f}`);
} else {
  console.log('\nno differences.');
}

const out = path.join(path.dirname(analysisFile), 'ma-soc-crosscheck-2026-11-13.json');
fs.writeFileSync(out, JSON.stringify({ theirRows, apRows, racesAgree, linesAgree, suffixOnly, findings }, null, 1));
console.log(`\nwrote ${out}`);
