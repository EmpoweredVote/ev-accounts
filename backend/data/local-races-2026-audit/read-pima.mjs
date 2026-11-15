#!/usr/bin/env node
// Read one Pima County summary-results CSV and print the county totals for the contests named.
//
// Shape of the file: it is WIDE, not long. Row 0 repeats each contest name once per column it
// occupies; row 1 is the party code; row 2 is the candidate (or YES/NO, OVER VOTES, UNDER VOTES);
// rows 3.. are precincts; the LAST row is `ZZZ / COUNTY TOTALS`.
//
// ⚠ ONLY THE `COUNTY TOTALS` ROW IS READ. Summing the precinct rows by hand would invite the
//   arithmetic errors the Wisconsin and Massachusetts waves paid for, and the county already
//   publishes the sum. The script asserts that row is present and refuses otherwise, so a file
//   whose shape changed cannot quietly return partial totals.
//
// ⚠ `OVER VOTES` and `UNDER VOTES` are ballot statistics, not candidates, and `Write-in` is an
//   aggregate line rather than a person. All three are reported separately and never counted as
//   candidates.
import fs from 'node:fs';

const [csvPath, ...patterns] = process.argv.slice(2);
if (!csvPath || !patterns.length) {
  console.error('usage: read-pima.mjs <summary.csv> <contest regex> [more...]');
  process.exit(2);
}

function parseLine(t) {
  const row = []; let c = '', q = false;
  for (let i = 0; i < t.length; i++) {
    const ch = t[i];
    if (q) { if (ch === '"' && t[i + 1] === '"') { c += '"'; i++; } else if (ch === '"') q = false; else c += ch; }
    else if (ch === '"') q = true;
    else if (ch === ',') { row.push(c); c = ''; }
    else if (ch !== '\r') c += ch;
  }
  row.push(c); return row;
}

const lines = fs.readFileSync(csvPath, 'utf8').split('\n').filter((l) => l.trim() !== '');
const contests = parseLine(lines[0]);
const cands = parseLine(lines[2]);
const last = parseLine(lines[lines.length - 1]);
if (!/COUNTY TOTALS/i.test(last[2] || '')) {
  console.error(`🔴 the last row of ${csvPath} is not COUNTY TOTALS (it is ${JSON.stringify(last.slice(0, 3))}) -- refusing to guess totals`);
  process.exit(1);
}

const res = [];
for (const p of patterns) {
  const re = new RegExp(p, 'i');
  const groups = new Map();
  contests.forEach((name, i) => {
    if (!re.test(name)) return;
    if (!groups.has(name)) groups.set(name, []);
    groups.get(name).push({ who: (cands[i] || '').trim(), votes: Number((last[i] || '').replace(/,/g, '')) || 0 });
  });
  for (const [name, rows] of groups) {
    const stats = rows.filter((r) => /^(OVER VOTES|UNDER VOTES)$/i.test(r.who));
    const writeIn = rows.filter((r) => /^write-?in$/i.test(r.who));
    const people = rows.filter((r) => !/^(OVER VOTES|UNDER VOTES|write-?in)$/i.test(r.who));
    const cast = people.reduce((a, b) => a + b.votes, 0) + writeIn.reduce((a, b) => a + b.votes, 0);
    res.push({
      contest: name,
      candidates: people.sort((a, b) => b.votes - a.votes)
        .map((r) => ({ ...r, share: cast ? +(100 * r.votes / cast).toFixed(2) : null })),
      writeIn: writeIn.map((r) => r.votes),
      ballotStats: Object.fromEntries(stats.map((r) => [r.who, r.votes])),
      totalVotesIncludingWriteIn: cast,
    });
  }
}
console.log(JSON.stringify({ source: csvPath, contests: res }, null, 2));
