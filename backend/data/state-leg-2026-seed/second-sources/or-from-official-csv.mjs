#!/usr/bin/env node
// Oregon's own legislative export, turned into the same shape as the other second sources.
//
// The file is the Secretary of State's "Legislative Export" from
// results.oregonvotes.gov/ResultsExport.aspx (CSV, downloaded 2026-11-13 through Playwright
// because the link is an ASP.NET postback). Columns: ContestID, ContestName, NominatingParty,
// PartyCode, AreaType, AreaNum, OfficeSeqNo, BallotOrder, CandidateID, CandidateName,
// CurrentDateTime, VoteFor, CandidateVotes, CandidatePercentage, PrecinctsReporting.
//
// ⚠ THE EXPORT IS USED INSTEAD OF THE RESULTS PAGES, AND THAT IS NOT A CONVENIENCE. The State
//   Representative page shows districts 1-30 and stops; read as the whole chamber it reports 30
//   contests where Oregon has 60. A count that looks complete is the failure mode here, so the
//   machine-readable export — which carries every contest in one file — is the source.
//
// 🔴 CANDIDATE ID 9901 IS "Write-in", AN AGGREGATE LINE AND NOT A PERSON. It is dropped by ID,
//   never by reading the name.
import fs from 'node:fs';

const [csvPath, out] = process.argv.slice(2);
if (!csvPath || !out) { console.error('usage: or-from-official-csv.mjs <export.csv> <out.tsv>'); process.exit(2); }

const squash = (s) => (s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase().replace(/[^a-z0-9]/g, '');

// A tiny RFC4180 reader: the file quotes any field holding a comma, and contest names all do.
function parseCsv(text) {
  const rows = []; let row = []; let cell = ''; let quoted = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (quoted) {
      if (c === '"' && text[i + 1] === '"') { cell += '"'; i++; }
      else if (c === '"') quoted = false;
      else cell += c;
    } else if (c === '"') quoted = true;
    else if (c === ',') { row.push(cell); cell = ''; }
    else if (c === '\n') { row.push(cell); rows.push(row); row = []; cell = ''; }
    else if (c !== '\r') cell += c;
  }
  if (cell || row.length) { row.push(cell); rows.push(row); }
  return rows.filter((r) => r.some((x) => x !== ''));
}

const rows = parseCsv(fs.readFileSync(csvPath, 'utf8'));
const header = rows[0].map((h) => h.trim());
const col = Object.fromEntries(header.map((h, i) => [h, i]));
for (const need of ['ContestName', 'AreaNum', 'CandidateID', 'CandidateName']) {
  if (col[need] === undefined) throw new Error(`the export has no "${need}" column: ${header.join(',')}`);
}

const byDistrict = new Map();
let dropped = 0; let kept = 0;
for (const r of rows.slice(1)) {
  const area = (r[col.AreaNum] || '').trim();          // "SD 03" / "HD 42"
  const m = area.match(/^(SD|HD)\s*0*(\d+)$/i);
  if (!m) throw new Error(`an export row carries an AreaNum this reader does not understand: ${JSON.stringify(area)}`);
  if (String(r[col.CandidateID]).trim() === '9901') { dropped++; continue; }
  const k = `${m[1].toUpperCase() === 'SD' ? 'U' : 'L'}|${Number(m[2])}`;
  if (!byDistrict.has(k)) byDistrict.set(k, []);
  // A nickname in parentheses — "JACK (JAKE) D HUFF" — is an annotation, not part of the name.
  // ⚠ The parentheses must be ESCAPED. Written `/([^)]*)/g` this matches the empty string
  //   everywhere and erases every name, which the cross-check reported as 146 differences —
  //   loudly, rather than as a quiet pass.
  byDistrict.get(k).push(squash(String(r[col.CandidateName]).replace(/\([^)]*\)/g, ' ')));
  kept++;
}

const lines = [...byDistrict.entries()]
  .sort((a, b) => a[0].localeCompare(b[0], 'en', { numeric: true }))
  .map(([k, names]) => `${k}|${names.join(',')}`);
fs.writeFileSync(out, `${lines.join('\n')}\n`);
console.log(`wrote ${out}: ${byDistrict.size} districts, ${kept} candidates (${dropped} aggregate write-in line(s) dropped by id)`);
