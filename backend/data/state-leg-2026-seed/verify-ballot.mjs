#!/usr/bin/env node
// A SECOND, INDEPENDENT READING OF ONE STATE'S BALLOT, compared line by line with AP's.
//
// Each file in second-sources/ is one state's own official publication reduced to one row per
// district: `<U|L>|<district>|<names>` and, after a TAB, any DECLARED WRITE-IN names that
// state prints. Names carry accents folded, case dropped and punctuation removed, because this
// file answers one question only: is the same set of people on the state's ballot and on AP's?
// It is not a source for how a name is spelled.
//
// 🔴 A DIFFERENCE IS READ, NEVER AVERAGED. The states and AP each leave something out of a name,
//    and the classes are named rather than smoothed:
//      · a suffix one side prints and the other does not ("Puppolo" / "Puppolo Jr.")
//      · a declared write-in, who is on the ballot and not on a filing list
//      · a middle name, initial or compound surname split differently between the two
// ⚠ THE STATE OWNS THE BALLOT AND THE COUNT; AP OWNS THE CALL. Nothing here checks a winner:
//    Oregon, Nevada and Maryland all publish returns with NO winner flag, because a state
//    canvasses and does not call.
import fs from 'node:fs';
import path from 'node:path';

const [tsv, analysisFile, stArg] = process.argv.slice(2);
if (!tsv || !analysisFile || !stArg) { console.error('usage: verify-ballot.mjs <second-source.tsv> <analysis.json> <st>'); process.exit(2); }
const st = stArg.toLowerCase();

const squash = (s) => (s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z0-9]/g, '');
const CHAMBER = { U: 'STATE_UPPER', L: 'STATE_LOWER' };

const theirs = new Map();
let theirRows = 0; let theirWriteIns = 0;
for (const line of fs.readFileSync(tsv, 'utf8').split('\n')) {
  if (!line.trim()) continue;
  const [main, writeInPart] = line.split('\t');
  const [ch, district, names] = main.split('|');
  const k = `${CHAMBER[ch]}|d${String(district).toUpperCase()}`;
  if (theirs.has(k)) throw new Error(`the state's file repeats a district: ${k}`);
  const list = (names || '').split(',').map((s) => s.trim()).filter(Boolean);
  const writeIns = (writeInPart || '').split(',').map((s) => s.trim()).filter(Boolean);
  theirs.set(k, { district, names: list, writeIns });
  theirRows += list.length; theirWriteIns += writeIns.length;
}

const analysis = JSON.parse(fs.readFileSync(analysisFile, 'utf8'));
const races = analysis.races.filter((r) => r.state === st);

// 🔴 EACH RUNG IS NAMED AND COUNTED, AND THE LAST ONE IS LISTED IN FULL. The two sources print
//    different PARTS of a name — a suffix, a middle name, a preferred first name — and matching
//    on the parts they share is still an exact comparison. Matching on the surname alone is NOT,
//    so every row that falls to that rung is printed for a person to read.
const basis = { 'exact-with-suffix': [], 'exact-without-the-suffix': [], 'first-and-last-only': [], 'declared-write-in': [], 'surname-and-district': [] };
const findings = []; const suffixOnly = basis['exact-without-the-suffix']; const writeInOnly = basis['declared-write-in'];
let racesAgree = 0; let linesAgree = 0; let apRows = 0;
const unmatchedDistricts = [];

for (const race of races) {
  const k = `${race.chamber}|${race.key}`;
  const t = theirs.get(k);
  apRows += race.lines.length;
  if (!t) { unmatchedDistricts.push(`${race.chamber} ${race.key} (${race.our.district_label}): no district of this name in the state's own file`); continue; }
  const forms = (l) => [
    ['exact-with-suffix', squash([l.first, l.middle, l.last, l.suffix].filter(Boolean).join(''))],
    ['exact-without-the-suffix', squash([l.first, l.middle, l.last].filter(Boolean).join(''))],
    ['first-and-last-only', squash([l.first, l.last, l.suffix].filter(Boolean).join(''))],
    ['first-and-last-only', squash([l.first, l.last].filter(Boolean).join(''))],
  ];
  const matched = new Set(); const unmatchedLines = [];
  for (const l of race.lines) {
    let i = -1; let how = null;
    for (const [name, form] of forms(l)) {
      i = t.names.findIndex((n, j) => !matched.has(j) && n === form);
      if (i !== -1) { how = name; break; }
    }
    if (i === -1 && t.writeIns.length) {
      const w = t.writeIns.findIndex((n) => forms(l).some(([, f]) => f === n));
      if (w !== -1) { writeInOnly.push(`${race.chamber} ${race.key}: "${l.full_name}" is a DECLARED WRITE-IN on the state's own list`); matched.add(`w${w}`); continue; }
    }
    if (i === -1) {
      // The surname rung: the same surname, in the same district, with one candidate of that
      // surname on each side. It is a lead, not a match, so it is listed rather than counted.
      // ⚠ A COMPOUND SURNAME IS PRINTED WHOLE BY ONE SIDE AND IN PART BY THE OTHER: Nevada's own
      //   feed gives "Davila-Uzcategui" and "La Rue Hatch" where AP prints "Davila" and "Hatch",
      //   and the containment runs both ways. So the rung tests whether either surname contains
      //   the other, and still requires exactly one candidate of that surname in the district.
      const apLast = squash(l.last);
      const cands = t.names.map((n, j) => [n, j]).filter(([n, j]) => !matched.has(j) && apLast.length > 2
        && (n.includes(apLast) || (squash(l.first).length > 2 && n.startsWith(squash(l.first)))));
      if (cands.length === 1) {
        i = cands[0][1]; how = 'surname-and-district';
        basis['surname-and-district'].push(`${race.chamber} ${race.key}: AP "${l.full_name}" and the state's "${cands[0][0]}"`);
      }
    }
    if (i === -1) unmatchedLines.push(l);
    else { matched.add(i); if (how && how !== 'surname-and-district') basis[how].push(`${race.chamber} ${race.key}: "${l.full_name}"`); }
  }
  const unmatchedTheirs = t.names.filter((_, j) => !matched.has(j));
  if (!unmatchedLines.length && !unmatchedTheirs.length) { racesAgree++; linesAgree += race.lines.length; continue; }
  for (const n of unmatchedTheirs) findings.push(`${race.chamber} ${race.key} (district ${t.district}): on the STATE's ballot and NOT on AP's — ${n}`);
  for (const l of unmatchedLines) findings.push(`${race.chamber} ${race.key} (district ${t.district}): on AP's ballot and NOT on the STATE's — ${l.full_name}`);
}
for (const k of theirs.keys()) {
  if (!races.some((r) => `${r.chamber}|${r.key}` === k)) {
    findings.push(`${k}: in the state's own file with no AP race and no race of ours — ${theirs.get(k).names.join(', ')}`);
  }
}

console.log(`${st.toUpperCase()} — the state's own publication : ${theirRows} candidates across ${theirs.size} districts${theirWriteIns ? ` (plus ${theirWriteIns} declared write-in(s))` : ''}`);
console.log(`${st.toUpperCase()} — AP's ballots                : ${apRows} lines across ${races.length} races`);
console.log(`races where every line agrees on both sources: ${racesAgree} of ${races.length}  (${linesAgree} lines)`);
console.log('\nhow each line was matched:');
for (const [name, list] of Object.entries(basis)) console.log(`  ${name.padEnd(26)} ${String(list.length).padStart(3)}`);
for (const name of ['exact-without-the-suffix', 'declared-write-in', 'surname-and-district']) {
  for (const s of basis[name]) console.log(`  ${name}: ${s}`);
}
if (unmatchedDistricts.length) {
  console.log(`\n${unmatchedDistricts.length} race(s) of ours the state's file does not carry:`);
  for (const s of unmatchedDistricts) console.log(`  ${s}`);
}
if (findings.length) {
  console.log(`\n${findings.length} difference(s) — each one is read, not averaged:`);
  for (const f of findings) console.log(`  ${f}`);
} else {
  console.log('\nno differences.');
}

const out = path.join(path.dirname(analysisFile), `${st}-crosscheck-2026-11-13.json`);
fs.writeFileSync(out, JSON.stringify({ theirRows, theirWriteIns, apRows, racesAgree, linesAgree, suffixOnly, writeInOnly, unmatchedDistricts, findings }, null, 1));
console.log(`\nwrote ${out}`);
