#!/usr/bin/env node
// Read a Racine County election PDF BY TEXT POSITION, not by stream order.
//
// 🔴 WHY THIS EXISTS. `pdftotext -layout` on these files drifts vertically: a candidate's name and
//    the number that belongs to it land on different output lines, so a reader that pairs them in
//    stream order pairs a name with the NEXT contest's figure. The first pass at this file did
//    exactly that and reported "Sheriff -- Amy Vanderhoef 54,674"; Vanderhoef is the Clerk of
//    Circuit Court. Nothing errored, and every number in that reading was a real number from the
//    document, which is what made it credible.
//
// ▶ So pairing here is GEOMETRIC. Every glyph run carries an (x, y) from the PDF's own text
//   matrix. Rows are formed by clustering on y within a tolerance, and read left-to-right by x.
//   A row is then a row of the printed table, whatever order the content stream emitted it in.
import { createRequire } from 'node:module';
import { readFileSync } from 'node:fs';
const require = createRequire('C:/EV-Accounts/backend/package.json');
const pdfjs = require('pdfjs-dist/legacy/build/pdf.mjs');

const file = process.argv[2];
if (!file) { console.error('usage: read-racine-pdf.mjs <file.pdf> [--json]'); process.exit(2); }

const data = new Uint8Array(readFileSync(file));
const doc = await pdfjs.getDocument({ data, useSystemFonts: true }).promise;

const Y_TOL = 2.5;           // points; a printed row's glyphs share a baseline to well within this
const pages = [];
let items = 0;
for (let p = 1; p <= doc.numPages; p++) {
  const page = await doc.getPage(p);
  const content = await page.getTextContent();
  const rows = [];
  for (const it of content.items) {
    const s = (it.str ?? '').replace(/\s+/g, ' ').trim();
    if (!s) continue;
    items++;
    const x = it.transform[4], y = it.transform[5];
    let row = rows.find(r => Math.abs(r.y - y) <= Y_TOL);
    if (!row) { row = { y, cells: [] }; rows.push(row); }
    row.cells.push({ x, s });
  }
  rows.sort((a, b) => b.y - a.y);                       // PDF y grows upward
  for (const r of rows) r.cells.sort((a, b) => a.x - b.x);
  pages.push({ page: p, rows });
}

// 🔴 The detector states what it EXAMINED, not just what it found. A run that inflated zero bytes
//    once reported every contest ABSENT -- a perfectly uniform "not found" from a blind reader.
console.error(`[read] ${file}: pages=${doc.numPages} textItems=${items} rows=${pages.reduce((n,p)=>n+p.rows.length,0)}`);
if (items === 0) { console.error('[read] FATAL: zero text items -- the reader is blind, not the document empty'); process.exit(3); }

if (process.argv.includes('--json')) {
  console.log(JSON.stringify(pages.map(p => ({ page: p.page, rows: p.rows.map(r => ({ y: Math.round(r.y*10)/10, cells: r.cells.map(c => [Math.round(c.x*10)/10, c.s]) })) })), null, 1));
} else {
  for (const p of pages) {
    console.log(`\n=== page ${p.page} ===`);
    for (const r of p.rows) console.log(String(Math.round(r.y)).padStart(4) + ' | ' + r.cells.map(c => `${Math.round(c.x)}:${c.s}`).join('  |  '));
  }
}
