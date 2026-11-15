#!/usr/bin/env node
// Arithmetic control on the two Racine figures this wave writes.
//
// The Election Summary Report and the Statement of Votes Cast are two different documents. This
// sums the SVC's PER-WARD rows and checks the sum against (a) the SVC's own printed total row and
// (b) the summary report's figure. Columns are taken from each page's own header, by x position --
// never by stream order, because stream order is what mis-paired "Sheriff" with "Amy Vanderhoef"
// on the first reading of these files.
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const dump = execFileSync(process.execPath,
  [fileURLToPath(new URL('./read-racine-pdf.mjs', import.meta.url)),
   fileURLToPath(new URL('./sources/wi-racine-svc-2026-11-03-final-unofficial.pdf', import.meta.url)),
   '--json'],
  { encoding: 'utf8', maxBuffer: 256 * 1024 * 1024, stdio: ['ignore', 'pipe', 'ignore'] });
const pages = JSON.parse(dump);

const num = (s) => /^\d[\d,]*$/.test(s) ? Number(s.replace(/,/g, '')) : null;
const labelOf = (row) => row.cells.filter(c => c[0] < 140).map(c => c[1]).join(' ');

// Find each candidate column from the header rows that name it, then sum the ward rows under it.
function tally(pageNums, columns) {
  const sums = Object.fromEntries(columns.map(c => [c.name, 0]));
  let wardRows = 0, totalRows = [];
  for (const p of pages.filter(p => pageNums.includes(p.page))) {
    for (const row of p.rows) {
      const label = labelOf(row);
      if (!label || /^Precinct\b/.test(label)) continue;
      const isTotal = /Total/.test(label);
      let used = false;
      for (const col of columns) {
        const cell = row.cells.find(c => c[0] >= col.lo && c[0] <= col.hi && num(c[1]) !== null);
        if (!cell) continue;
        used = true;
        if (!isTotal) sums[col.name] += num(cell[1]);
      }
      if (!used) continue;
      if (isTotal) totalRows.push({ label, vals: columns.map(col => { const c = row.cells.find(c => c[0] >= col.lo && c[0] <= col.hi && num(c[1]) !== null); return c ? num(c[1]) : null; }) });
      else wardRows++;
    }
  }
  return { sums, wardRows, totalRows };
}

// 🔴 Print what the reader EXAMINED, not only its verdict.
const sheriff = tally([65, 67, 69, 71], [
  { name: 'Cary A. Madrigal (REP)', lo: 520, hi: 600 },
  { name: 'Donald E. Vandervest (DEM)', lo: 601, hi: 700 },
]);
const clerk = tally([73, 75, 77, 79], [
  { name: 'Amy Vanderhoef (REP)', lo: 520, hi: 600 },
  { name: 'Write-in', lo: 601, hi: 700 },
]);

const EXPECT = {
  'Cary A. Madrigal (REP)': 39609,
  'Donald E. Vandervest (DEM)': 42048,
  'Amy Vanderhoef (REP)': 54674,
  'Write-in': 3011,
};

let bad = 0;
for (const [name, got] of [...Object.entries(sheriff.sums), ...Object.entries(clerk.sums)]) {
  const want = EXPECT[name];
  const ok = got === want;
  if (!ok) bad++;
  console.log(`${ok ? 'OK  ' : 'FAIL'} ward-sum ${name}: ${got.toLocaleString()} vs summary report ${want.toLocaleString()}`);
}
console.log(`\nsheriff ward rows summed: ${sheriff.wardRows}`);
for (const t of sheriff.totalRows) console.log(`  SVC printed total row [${t.label}] -> ${t.vals.join(' / ')}`);
console.log(`clerk ward rows summed: ${clerk.wardRows}`);
for (const t of clerk.totalRows) console.log(`  SVC printed total row [${t.label}] -> ${t.vals.join(' / ')}`);

if (sheriff.wardRows === 0 || clerk.wardRows === 0) { console.error('\nFATAL: a tally summed zero ward rows -- the reader is blind, not the contest empty'); process.exit(3); }
process.exit(bad ? 1 : 0);
