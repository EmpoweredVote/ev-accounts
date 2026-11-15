#!/usr/bin/env node
// Parse LA County RR/CC's "FINAL LIST OF CANCELED ELECTIONS — APPOINTMENT IN LIEU OF ELECTION
// DUE TO INSUFFICIENCY OF CANDIDATES" into one row per SEAT.
//
// 🔴 WHY THIS DOCUMENT IS THE AUTHORITY. Our data cannot tell a cancelled election from a held
// but uncontested one: both are one candidate, one seat, `result` NULL, `candidate_status`
// 'active'. They need OPPOSITE handling — a cancelled election seats the filer with no result
// under Educ. Code 5328, an uncontested one still has to be certified. Only this list says which
// is which, and nothing in our own rows does.
//
// 🔴 BOUND THE PARSE BY THE DOCUMENT'S OWN SECTION HEADINGS, NOT BY A LIST OF THE ONES WE WANT.
// The school seats are NOT all under the school headings: `Pasadena (Pasadena Unified School
// District Board of Education 5)` sits under CITIES, because that seat is consolidated with the
// city's election. A reader that took only the four school sections would silently drop it.
// So every section is parsed and the caller decides what to keep.
//
// 🔴 THE ASTERISK IS A SECOND, OPPOSITE REASON. The footnote reads "*Cancelled Elections Due to
// No Candidates". Insufficiency means someone filed and is appointed in lieu; an asterisk means
// NOBODY filed, so there is no person to seat and the seat becomes a vacancy for the board to
// fill. Seating an asterisked row would invent an officeholder. It is carried through as
// `noCandidates: true` and must never be seated.
//
// ⚠ Read the PDF BY COORDINATES, never by stream order (CLAUDE.md). This file consumes the row
// dump from backend/data/local-races-2026-audit/read-racine-pdf.mjs.
//
//   node backend/data/local-races-2026-audit/read-racine-pdf.mjs <pdf> > rows.txt
//   node parse-la-canceled-elections.mjs rows.txt [--json]
import { readFileSync } from 'node:fs';

const file = process.argv[2];
if (!file) { console.error('usage: parse-la-canceled-elections.mjs <rows.txt> [--json]'); process.exit(2); }

const text = readFileSync(file, 'utf8');

// Each dumped row is "  <y> | <x>:<text>  |  <x>:<text>". Take the text cells, in x order.
const lines = [];
for (const raw of text.split('\n')) {
  const m = raw.match(/^\s*-?\d+(?:\.\d+)?\s\|\s(.*)$/);
  if (!m) continue;
  const cells = m[1].split('|').map(c => c.replace(/^\s*\d+(?:\.\d+)?:/, '').trim()).filter(Boolean);
  if (cells.length) lines.push(cells.join(' '));
}

const SKIP = /^(Page\s|COUNTY OF LOS ANGELES|REGISTRAR-RECORDER|ELECTION INFORMATION|PREPARATION DIVISION|Revised |GENERAL ELECTION|November 3, 2026|FINAL LIST OF|TENTATIVE LIST OF|CANCELED ELECTIONS|APPOINTMENT IN LIEU|Entire jurisdiction|\*Cancelled Elections)/i;

// A heading is a line in capitals (allowing digits, spaces and punctuation) — the document's own
// structure. Anything else under it is an entry.
const isHeading = s => /^[A-Z][A-Z0-9 ,.'\-/&]*$/.test(s) && /[A-Z]{3}/.test(s);

const seats = [];
let section = null;
for (const line of lines) {
  if (SKIP.test(line)) continue;
  if (isHeading(line)) { section = line.trim(); continue; }
  if (!section) continue;

  // "Name (detail)" or bare "Name" (= entire jurisdiction)
  const m = line.match(/^(.*?)\s*\((.*)\)\s*$/);
  const district = (m ? m[1] : line).trim();
  const detail = m ? m[2].trim() : 'Entire jurisdiction';

  // The asterisk can sit on the district or on one seat inside the parenthesis.
  const districtNoCandidates = /\*/.test(district);
  const cleanDistrict = district.replace(/\*/g, '').trim();

  // Split "A, B, and C" / "A and B" into seat tokens, keeping each token's own asterisk.
  // ⚠ The tentative list joins with "&" where the final list writes "and" — the SAME seats.
  //   Without this the two versions diff on four community-college seats that never changed.
  const tokens = detail
    .replace(/\band\b|&/g, ',')
    .split(',')
    .map(t => t.trim())
    .filter(Boolean);

  // A leading token may carry the label ("Trustee Area 5") that later bare tokens inherit ("7").
  let label = null;
  for (const tok of tokens) {
    const noCand = districtNoCandidates || /\*/.test(tok);
    const t = tok.replace(/\*/g, '').trim();
    const lm = t.match(/^(Trustee Area|Division|District|Council|Seat)\s+(.+)$/i);
    let seat;
    if (lm) { label = lm[1]; seat = `${lm[1]} ${lm[2]}`; }
    else if (/^(Full Term|Entire jurisdiction)$/i.test(t)) { seat = t; }
    // ⚠ A bare designator inherits the leading token's label ("Trustee Area 5 and 7" -> "...7").
    //   A WORD does not: "Council 5 and Treasurer" is a council seat AND a treasurer, not a
    //   "Council Treasurer". The first version of this file produced exactly that.
    //   A bare designator is DIGITS or a SINGLE letter ("7", "E", "B U/T ending 12/28").
    //   "Treasurer" starts with a letter too, which is why the test is the word boundary
    //   after it and not merely the first character.
    else if (label && /^(?:\d+|[A-Za-z])(?:\s|$)/.test(t)) { seat = `${label} ${t}`; }
    else { seat = t; }
    seats.push({ section, district: cleanDistrict, seat, noCandidates: noCand, raw: line });
  }
}

if (process.argv.includes('--json')) {
  console.log(JSON.stringify(seats, null, 2));
} else {
  const bySection = new Map();
  for (const s of seats) {
    if (!bySection.has(s.section)) bySection.set(s.section, []);
    bySection.get(s.section).push(s);
  }
  for (const [sec, rows] of bySection) {
    console.log(`\n=== ${sec}  (${rows.length} seat${rows.length === 1 ? '' : 's'})`);
    for (const r of rows) console.log(`   ${r.district} — ${r.seat}${r.noCandidates ? '   🔴 NO CANDIDATES (do not seat)' : ''}`);
  }
  const school = seats.filter(s => /COMMUNITY COLLEGE|HIGH SCHOOL|UNIFIED|ELEMENTARY/i.test(s.section));
  const schoolElsewhere = seats.filter(s => !/COMMUNITY COLLEGE|HIGH SCHOOL|UNIFIED|ELEMENTARY/i.test(s.section)
                                         && /school|board of education/i.test(s.raw));
  console.log(`\nTOTAL seats on the list: ${seats.length}`);
  console.log(`  school-section seats:   ${school.length}`);
  console.log(`  school seats filed under ANOTHER section: ${schoolElsewhere.length}`);
  for (const s of schoolElsewhere) console.log(`     ⚠ ${s.section}: ${s.raw}`);
  console.log(`  flagged NO CANDIDATES (never seatable): ${seats.filter(s => s.noCandidates).length}`);
  for (const s of seats.filter(x => x.noCandidates)) console.log(`     🔴 ${s.section}: ${s.district} — ${s.seat}`);
}
