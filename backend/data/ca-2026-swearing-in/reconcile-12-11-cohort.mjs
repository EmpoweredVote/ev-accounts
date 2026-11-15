#!/usr/bin/env node
// Reconcile the 2026-12-11 California school-board cohort against LA County's FINAL LIST OF
// CANCELED ELECTIONS, one row at a time.
//
// 🔴 THE QUESTION THIS ANSWERS, AND WHY A COUNT CANNOT. 96 of our 197 offices have
// `candidates <= seats` and no recorded winner. That is the shape of a CANCELLED election
// (Elec. Code 10515; the filer is appointed in lieu and seated as if elected, Educ. Code 5328)
// and it is EQUALLY the shape of a held, uncontested one that simply has not been certified yet.
// The two need opposite handling and nothing in our data distinguishes them: `description` is
// NULL, `result` is NULL and `candidate_status` is 'active' on both. The county's list is the
// only thing that says which is which, so each office is matched to it BY NAME, and whatever
// fails to match is reported rather than assumed.
//
// 🔴 A ROW THE LIST MARKS WITH AN ASTERISK IS NOT SEATABLE AT ALL. The footnote reads
// "*Cancelled Elections Due to No Candidates" — nobody filed, so there is no person to appoint
// and the seat becomes a vacancy for the board to fill. Seating one would invent an
// officeholder out of an empty race.
//
//   node reconcile-12-11-cohort.mjs <final.json>
import 'dotenv/config';
import { readFileSync } from 'node:fs';
import { Pool } from 'pg';

const listPath = process.argv[2];
if (!listPath) { console.error('usage: reconcile-12-11-cohort.mjs <final.json>'); process.exit(2); }

const seats = JSON.parse(readFileSync(listPath, 'utf8'));
// Every school seat on the list, wherever it was filed. Pasadena USD's sits under CITIES.
const schoolSeats = seats.filter(s =>
  /COMMUNITY COLLEGE|HIGH SCHOOL|UNIFIED|ELEMENTARY/i.test(s.section) ||
  /school|board of education/i.test(s.raw));

// 🔴🔴 THE BODY TYPE IS PART OF THE KEY, AND DROPPING IT MATCHES DIFFERENT BODIES.
// The first version of this file stripped "Community College", "Joint Union" and "Unified" as
// noise so that district names would compare cleanly. In one county that silently matched
// `Antelope Valley Community College Board` to the list's `Antelope Valley Joint Union` (a HIGH
// SCHOOL district) and `Pasadena Unified School Board` to `Pasadena Area` (a COMMUNITY COLLEGE).
// One of those already carried a recorded winner, so the reconciliation would have called a
// contested, decided race "cancelled" and seated against it. A name that matches is not a BODY
// that matches. The list's own section headings carry the type, so they are used as the key.
const typeOfSection = sec => /COMMUNITY COLLEGE/i.test(sec) ? 'cc'
  : /HIGH SCHOOL/i.test(sec) ? 'hs'
  : /UNIFIED/i.test(sec) ? 'unified'
  : /ELEMENTARY/i.test(sec) ? 'elem'
  : null;                            // CITIES etc. — typed from the entry's own text below

const typeOfName = n => /community college/i.test(n) ? 'cc'
  : /union high school|high school/i.test(n) ? 'hs'
  : /unified/i.test(n) ? 'unified'
  : 'elem';

// Strip only AFTER the type is known, so the discriminating words do their job first.
const norm = s => s.toLowerCase()
  .replace(/\bjoint\b|\bunion\b|\bcity\b|\bunified\b|\belementary\b|\bhigh school\b|\bschool\b|\bdistrict\b|\bboard of education\b|\bboard\b|\bcommunity college\b|\barea\b/g, ' ')
  .replace(/[^a-z0-9]+/g, ' ').trim();

// The seat designator as a comparable token: "Trustee Area 5" -> "5", "District 7" -> "7".
// ⚠ An at-large board has NO designator in our title and the county writes it "Full Term";
//   both must land on the same token or every at-large board reads as unmatched.
// ⚠ ORDER AND SHAPE BOTH MATTER HERE. "Pasadena Unified School DISTRICT Board of Education 5"
//   contains the word "District" followed by "Board", so a loose alternation captured "board"
//   as the seat number and the row read as unmatched. "Board of Education" is tried first, and
//   the capture must look like a designator (digits, or a single letter) rather than any word.
const seatToken = s => {
  const m = s.match(/(?:Board of Education|Trustee Area|Division|District|Area)\s+(\d+[A-Za-z]?|[A-Za-z])(?=\s|$|,)/i);
  if (m) return m[1].toLowerCase();
  if (/full term|entire jurisdiction/i.test(s)) return 'full';
  const n = s.match(/\b([0-9]+)\b/);
  if (n) return n[1];
  return 'full';
};

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const { rows } = await pool.query(`
  SELECT si.office_id, r.id AS race_id, r.position_name, r.seats,
         (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.race_id = r.id)::int AS cands,
         (SELECT count(*) FROM essentials.race_candidates rc WHERE rc.race_id = r.id AND rc.result = 'won')::int AS won
    FROM essentials.office_swearing_in si
    JOIN essentials.races r ON r.office_id = si.office_id
     AND r.election_id IN (SELECT id FROM essentials.elections WHERE election_date = '2026-11-03')
   WHERE si.election_date = '2026-11-03' AND si.swearing_in_date = '2026-12-11'
   ORDER BY r.position_name`);
await pool.end();

const used = new Set();
const out = { cancelled: [], cancelledNoCandidates: [], notOnList: [], listUnmatched: [] };

for (const r of rows) {
  const head = r.position_name.split(' - ')[0];
  const ourType = typeOfName(head);
  const ourDistrict = norm(head);
  const ourSeat = seatToken(r.position_name);
  const hit = schoolSeats.find((s, i) => {
    if (used.has(i)) return false;
    const theirType = typeOfSection(s.section) ?? typeOfName(s.raw);
    if (theirType !== ourType) return false;          // 🔴 the key that stops cross-body matches
    const d = norm(s.district);
    if (!(ourDistrict.startsWith(d) || d.startsWith(ourDistrict))) return false;
    return seatToken(s.seat) === ourSeat;
  });
  if (hit) {
    used.add(schoolSeats.indexOf(hit));
    (hit.noCandidates ? out.cancelledNoCandidates : out.cancelled).push({ ...r, listed: `${hit.district} — ${hit.seat}` });
  } else {
    out.notOnList.push(r);
  }
}
schoolSeats.forEach((s, i) => { if (!used.has(i)) out.listUnmatched.push(s); });

const shape = rows.filter(r => r.won === 0 && r.cands <= r.seats).length;
console.log(`cohort offices: ${rows.length}`);
console.log(`  'candidates <= seats and no winner' (the SHAPE):        ${shape}`);
console.log(`  on the county's FINAL cancelled list (the FACT):        ${out.cancelled.length + out.cancelledNoCandidates.length}`);
console.log(`     of those, appointable in lieu (someone filed):       ${out.cancelled.length}`);
console.log(`     🔴 of those, NO CANDIDATES — never seatable:          ${out.cancelledNoCandidates.length}`);
for (const r of out.cancelledNoCandidates) console.log(`        ${r.position_name}  [${r.listed}]`);

const shapeButNotListed = out.notOnList.filter(r => r.won === 0 && r.cands <= r.seats);
console.log(`\n🔴 LOOK LIKE CANCELLED BUT ARE NOT ON THE LIST: ${shapeButNotListed.length}`);
for (const r of shapeButNotListed) console.log(`   ${r.position_name}  (${r.cands} cand / ${r.seats} seat)`);

const listedButContested = out.cancelled.filter(r => r.cands > r.seats || r.won > 0);
console.log(`\n⚠ ON THE LIST BUT OUR ROWS DISAGREE: ${listedButContested.length}`);
for (const r of listedButContested) console.log(`   ${r.position_name}  (${r.cands} cand / ${r.seats} seat / ${r.won} won)  [${r.listed}]`);

console.log(`\n⚠ ON THE LIST, NO OFFICE MATCHED IN OUR COHORT: ${out.listUnmatched.length}`);
for (const s of out.listUnmatched) console.log(`   ${s.section}: ${s.district} — ${s.seat}`);
