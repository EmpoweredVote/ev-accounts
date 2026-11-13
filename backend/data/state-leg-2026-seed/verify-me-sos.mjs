#!/usr/bin/env node
// A SECOND, INDEPENDENT READING OF MAINE'S BALLOT.
//
// AP is one source. Maine's Secretary of State publishes the official candidate list for the
// 2026 general election as a spreadsheet — "2026 General Candidate List - FINAL.xlsx", linked
// from maine.gov/sos/elections-voting/upcoming-elections — which names every candidate by
// office, district and party. This joins it to AP's ballots, line by line.
//
// 🔴 THE TWO SOURCES ANSWER DIFFERENT QUESTIONS AND ONLY ONE OF THEM IS THE BALLOT WE SEED.
//   The SoS list is the FILING record as of its posting; AP's is the ballot as counted. A
//   candidate who withdrew after the list was posted is on one and not the other. So a
//   difference here is a finding to read, never something to average.
//
// ⚠ MAINE HAS PUBLISHED NO GENERAL-ELECTION RETURN FOR THESE RACES. Its results page carries
//   only the CD-2 ranked-choice tabulation and the June primary files (read 2026-11-13), so
//   this verifies the BALLOT, not the COUNT or the CALL.
import fs from 'node:fs';
import path from 'node:path';

const sosRows = process.argv[2];
const analysisFile = process.argv[3];
if (!sosRows || !analysisFile) { console.error('usage: verify-me-sos.mjs <candidate-rows.json> <analysis.json>'); process.exit(2); }

const rows = JSON.parse(fs.readFileSync(sosRows, 'utf8'));
const header = rows[0];
const COL = Object.fromEntries(header.map((h, i) => [h.trim(), i]));
for (const need of ['Office', 'Dist', 'Party', 'Last Name', 'First Name']) {
  if (COL[need] === undefined) throw new Error(`the SoS sheet has no "${need}" column: ${JSON.stringify(header)}`);
}

const squash = (s) => (s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z0-9]/g, '');
const CHAMBER_OF_OFFICE = { SR: 'STATE_LOWER', SS: 'STATE_UPPER' };

// ── the SoS ballot, keyed the same way the analysis is ────────────────────────────────────────
const sos = new Map();
let sosCount = 0;
for (const r of rows.slice(1)) {
  const chamber = CHAMBER_OF_OFFICE[(r[COL.Office] || '').trim()];
  if (!chamber) continue;
  const dist = String(r[COL.Dist] || '').trim();
  if (!/^\d+$/.test(dist)) throw new Error(`SoS row with a non-numeric district: ${JSON.stringify(r)}`);
  const k = `${chamber}|d${Number(dist)}`;
  if (!sos.has(k)) sos.set(k, []);
  sos.get(k).push({
    last: r[COL['Last Name']], first: r[COL['First Name']],
    middle: r[COL['Middle Name']] || '', suffix: r[COL.Suffix] || '',
    party: r[COL.Party], town: r[COL['Residence Municipality']] || '',
  });
  sosCount++;
}

const analysis = JSON.parse(fs.readFileSync(analysisFile, 'utf8'));
const apRaces = analysis.races.filter((r) => r.state === 'me');

let apCount = 0;
const findings = [];
let racesAgree = 0;
let linesAgree = 0;

for (const race of apRaces) {
  const k = `${race.chamber}|${race.key}`;
  const theirs = sos.get(k) || [];
  const ours = race.lines;
  apCount += ours.length;

  // 🔴 THE TWO SOURCES SPLIT A NAME INTO DIFFERENT FIELDS, SO COMPARING ONE FIELD INVENTS
  //   DIFFERENCES. The SoS keeps "D." in First Name and "Michael" in Middle Name; AP puts
  //   "D. Michael" in `first`. Five Maine candidates read as mismatches on the first-name field
  //   alone and are one person on each side — including the House minority leader, "Billy
  //   Faulkingham" to the SoS and "Billy Bob Faulkingham" to AP. The comparison is therefore on
  //   the WHOLE name with the field boundaries removed, which is still exact.
  // ⚠ A MISSING PART IS NOT THE WORD "null". Template-stringing these fields put `null` into
  //   every AP key and reported 647 differences out of 344 lines — a complete, plausible, wrong
  //   table, for the second time in this wave's tooling. Drop the empty parts, then compare.
  const nameKey = (c) => squash([c.first, c.middle, c.last, c.suffix].filter(Boolean).join(''));
  const theirKeys = theirs.map(nameKey);
  const ourKeys = ours.map(nameKey);

  const missingFromAp = theirs.filter((c, i) => !ourKeys.includes(theirKeys[i]));
  const missingFromSos = ours.filter((c, i) => !theirKeys.includes(ourKeys[i]));

  if (!missingFromAp.length && !missingFromSos.length && theirs.length === ours.length) {
    racesAgree++;
    linesAgree += ours.length;
    continue;
  }
  for (const c of missingFromAp) {
    findings.push(`${race.chamber} ${race.key} (${race.our.district_label}): on the SoS list and NOT on AP's ballot — ${c.first} ${c.last} (${c.party}, ${c.town})`);
  }
  for (const c of missingFromSos) {
    findings.push(`${race.chamber} ${race.key} (${race.our.district_label}): on AP's ballot and NOT on the SoS list — ${c.full_name} (${c.party})`);
  }
}

for (const k of sos.keys()) {
  if (!apRaces.some((r) => `${r.chamber}|${r.key}` === k)) findings.push(`${k}: the SoS list carries a district with no AP race and no race of ours`);
}

console.log(`Maine SoS candidate list : ${sosCount} legislative filings across ${sos.size} districts`);
console.log(`AP ballots               : ${apCount} lines across ${apRaces.length} races`);
console.log(`races where every line agrees on both sources: ${racesAgree} of ${apRaces.length}  (${linesAgree} lines)`);
if (findings.length) {
  console.log(`\n${findings.length} difference(s) — each one is read, not averaged:`);
  for (const f of findings) console.log(`  ${f}`);
} else {
  console.log('\nno differences.');
}

const out = path.join(path.dirname(analysisFile), 'me-sos-crosscheck-2026-11-13.json');
fs.writeFileSync(out, JSON.stringify({ sosCount, apCount, racesAgree, linesAgree, findings }, null, 1));
console.log(`\nwrote ${out}`);
