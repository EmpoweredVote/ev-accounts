/**
 * Generates the VALUES blocks pasted into CC_0316 (structure) and CC_0317 (occupancy)
 * from `roster-final.json`, which `build-roster.mjs` produced from the two independent
 * sources. Run from this directory:
 *
 *   node gen-migration-values.mjs
 *
 * Nothing here invents a value. Every column traces to a named source — see ROSTERS.md.
 */
import fs from 'fs';

const roster = JSON.parse(fs.readFileSync(new URL('./roster-final.json', import.meta.url), 'utf8'));
const q = (s) => (s === null || s === undefined ? 'NULL' : `'${String(s).replace(/'/g, "''")}'`);

if (roster.length !== 60) throw new Error(`expected 60 roster rows, got ${roster.length}`);
const house = roster.filter((r) => r.chamber === 'House');
const senate = roster.filter((r) => r.chamber === 'Senate');
if (house.length !== 40) throw new Error(`expected 40 House rows, got ${house.length}`);
if (senate.length !== 20) throw new Error(`expected 20 Senate rows, got ${senate.length}`);

// ── CC_0316: one office per district ────────────────────────────────────────
// (mtfcc, geo_id, district_type, title, district_code)
const offices = roster
  .map((r) => `    (${q(r.mtfcc)}, ${q(r.geo_id)}, ${q(r.chamber === 'Senate' ? 'STATE_UPPER' : 'STATE_LOWER')}, ` +
               `${q(r.chamber === 'Senate' ? 'Senator' : 'Representative')}, ${q(r.district_code)})`)
  .join(',\n');

// ── CC_0317: the people and their seatings ──────────────────────────────────
// Names are split the way the Legislature prints them: everything before the final
// token is the given/middle part, the final token is the surname. The two members whose
// published name carries an Alaska Native middle name (Frier, Jimmie) keep it in
// first_name rather than losing it.
// ── how_started ─────────────────────────────────────────────────────────────
// 🔴 READ FROM BALLOTPEDIA INFOBOXES ONE AT A TIME ON 2026-10-30, not inferred from the date.
// Four members carry an explicit "Appointed <date>" line: Tilton and Rauscher (both 2025-11-26)
// and St. Clair and Nelson (both 2025-12-24). Ballotpedia demonstrably records appointments in
// that infobox, so its ABSENCE is evidence too — which is why the rule below splits on it.
//
// ⚠ THE APPOINTMENT DATE IS NOT THE TERM START, AND BALLOTPEDIA PUBLISHES BOTH. The infobox says
//   Tilton was appointed 2025-11-26; the chamber roster says she assumed office 2025-11-29. They
//   are different events three days apart. term_start is when the seat was HELD, so the roster
//   date is the one used and the appointment date is deliberately NOT written anywhere.
const APPOINTED = new Set(["ttn", "rac", "stc", "neg"]);
// 🔴 NOT GUESSED. Neal Foster arrived 2009-11-16 — mid-term, on no election day — and his
//    infobox carries NO appointment line, so the mechanism is simply not published. That is
//    "unknown", not "elected".
const MECHANISM_UNPUBLISHED = new Set(["fon"]);
function howStarted(r) {
  if (APPOINTED.has(r.member_code)) return "appointed";
  if (MECHANISM_UNPUBLISHED.has(r.member_code)) return "unknown";
  return "elected";
}

function splitName(full) {
  const parts = full.trim().split(/\s+/);
  // 'Steve St. Clair' — 'St.' is part of the surname, not a middle name.
  if (parts.length >= 3 && /^(St\.|Van|Von|De|Del|La|Le|Mc|Mac|O')$/i.test(parts[parts.length - 2])) {
    return { first: parts.slice(0, -2).join(' '), last: parts.slice(-2).join(' ') };
  }
  return { first: parts.slice(0, -1).join(' '), last: parts[parts.length - 1] };
}

const people = roster
  .map((r) => {
    const { first, last } = splitName(r.full_name);
    const alts = r.alternate_names.length
      ? `ARRAY[${r.alternate_names.map(q).join(', ')}]::text[]`
      : `'{}'::text[]`;
    return `    (${q(r.chamber)}, ${q(r.district_code)}, ${q(r.full_name)}, ${q(first)}, ${q(last)}, ` +
           `${alts}, ${q(r.term_start)}::date, ${q(r.start_precision)}, ${q(howStarted(r))}, ` +
           `${q(r.member_code)}, ${q(r.home_city)})`;
  })
  .join(',\n');

// ── CC_0318: portraits ──────────────────────────────────────────────────────
// Each row carries the MIRRORED storage path, the ORIGIN url it came from, and the NAME the file
// was generated against — so the migration can assert it painted the face onto the person it was
// built for, rather than onto whoever happens to hold the seat on the day it runs.
const slugOf = (r) => r.chamber === 'Senate'
  ? 'sen-' + String(r.district_code).toLowerCase()
  : 'hse-' + String(r.district_code).padStart(2, '0');
const portraits = roster
  .map((r) => `    (${q(r.chamber === 'Senate' ? 'Alaska Senate' : 'Alaska House of Representatives')}, ` +
              `${q(r.geo_id)}, ${q(r.mtfcc)}, ${q(r.chamber === 'Senate' ? 'Senator' : 'Representative')}, ` +
              `${q(r.full_name)}, ${q('ak-legislature-2026/' + slugOf(r) + '.jpg')}, ${q(r.portrait)})`)
  .join(',\n');

fs.writeFileSync(new URL('./_cc0316_offices.sql', import.meta.url), offices + '\n');
fs.writeFileSync(new URL('./_cc0317_people.sql', import.meta.url), people + '\n');
fs.writeFileSync(new URL('./_cc0318_portraits.sql', import.meta.url), portraits + '\n');

// Counts printed so a reader can check the files rather than trust this script.
const prec = {};
roster.forEach((r) => { prec[r.start_precision] = (prec[r.start_precision] || 0) + 1; });
console.log(`offices:   60 rows  (${senate.length} STATE_UPPER + ${house.length} STATE_LOWER)`);
console.log(`people:    60 rows  start_precision ${JSON.stringify(prec)}`);
console.log(`portraits: 60 rows  all https://akleg.gov/images/legislators/450x600/<CODE>.jpg`);
console.log(`alternate names on ${roster.filter((r) => r.alternate_names.length).length} rows`);
console.log('surnames needing the multi-token rule:',
  roster.map((r) => splitName(r.full_name)).filter((n) => n.last.includes(' ')).map((n) => n.last).join(', ') || 'none');
