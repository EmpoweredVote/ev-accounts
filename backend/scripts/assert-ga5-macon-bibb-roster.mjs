/**
 * assert-ga5-macon-bibb-roster.mjs
 *
 * Validates backend/data/ga5-macon-bibb-roster.json against every rule the GA-5
 * migrations will rely on, BEFORE a line of SQL is generated. This is GA-4's
 * assertRoster() lifted out so the roster can be checked and committed on its
 * own, ahead of the generator.
 *
 * Wave GA-5 of the Knight Foundation cities program.
 * Roster: backend/data/seed-macon-bibb-2026/ROSTERS.md
 * Slice:  .planning/knight-foundation/ga.md
 *
 * Usage:  node scripts/assert-ga5-macon-bibb-roster.mjs
 *
 * ⚠ Nothing downstream can be more correct than the roster file it is generated
 *   from, which is why this runs first and exits non-zero on any failure.
 */

import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const ROSTER = join(HERE, '..', 'data', 'ga5-macon-bibb-roster.json');
const r = JSON.parse(readFileSync(ROSTER, 'utf8'));

const EXPECT_TOTAL = 15;
const EXPECT_CITY = 10;
const EXPECT_COUNTY = 5;

const problems = [];
const check = (cond, msg) => { if (!cond) problems.push(msg); };

const all = [...r.city.offices, ...r.county.offices];

// ── counts ───────────────────────────────────────────────────────────────────
check(all.length === EXPECT_TOTAL, `expected ${EXPECT_TOTAL} offices, got ${all.length}`);
check(r.city.offices.length === EXPECT_CITY, `expected ${EXPECT_CITY} city offices, got ${r.city.offices.length}`);
check(r.county.offices.length === EXPECT_COUNTY, `expected ${EXPECT_COUNTY} county offices, got ${r.county.offices.length}`);

// ── the id band, scoped to THIS wave's sub-range (the FL-4 correction) ───────
{
  const ids = all.map((o) => o.person.external_id);
  check(new Set(ids).size === ids.length, 'duplicate external_id in the roster');
  const { min, max } = r.id_band;
  for (const id of ids) {
    check(id >= min && id <= max, `external_id ${id} is outside the declared band ${min}..${max}`);
  }
  check(Math.min(...ids) === min, `declared band min ${min} is not the lowest id actually used (${Math.min(...ids)})`);
  check(Math.max(...ids) === max, `declared band max ${max} is not the highest id actually used (${Math.max(...ids)})`);
}

// ── chambers and seat keys ───────────────────────────────────────────────────
for (const side of ['city', 'county']) {
  const names = new Set(r[side].chambers.map((c) => c.name));
  for (const o of r[side].offices) {
    check(names.has(o.chamber), `${side}: office '${o.title}' names unknown chamber '${o.chamber}'`);
  }
  const seats = r[side].offices.map((o) => `${o.district_geo_id}|${o.district_mtfcc}|${o.title}`);
  check(new Set(seats).size === seats.length, `${side}: duplicate seat key`);
}

// ── the nine district seats must line up with the nine loaded boundaries ─────
{
  const want = new Set();
  for (let i = 1; i <= r.city.district_count; i++) want.add(`${r.city.district_geo_id_prefix}${i}`);
  const got = new Set(
    r.city.offices.filter((o) => o.district_mtfcc === r.city.district_mtfcc).map((o) => o.district_geo_id),
  );
  check(got.size === r.city.district_count, `expected ${r.city.district_count} ${r.city.district_mtfcc} seats, got ${got.size}`);
  for (const g of want) check(got.has(g), `no office is seated on district ${g}`);
  for (const g of got) check(want.has(g), `office seated on unknown district ${g}`);
}

// ── the citywide seat ────────────────────────────────────────────────────────
{
  const wide = r.city.citywide_district;
  const on = r.city.offices.filter((o) => o.district_geo_id === wide.geo_id && o.district_mtfcc === wide.mtfcc);
  check(on.length === wide.num_officials,
    `citywide district declares num_officials ${wide.num_officials} but ${on.length} office(s) sit on it — ` +
    `Macon-Bibb has NO at-large commissioners, so this is 1 and not Columbus's 3`);
}

// ── ADR 0003: representation_note is required whenever voting_powers <> 'full' ─
// A CHECK enforces its presence; the READ PATH must not render such a seat
// without it, so a one-liner is not good enough — 1719's own gate wants >= 120.
for (const o of all) {
  if (o.voting_powers !== 'full') {
    check(o.representation_note && o.representation_note.length >= 120,
      `office '${o.title}' is ${o.voting_powers} and carries no substantive representation_note`);
  } else {
    check(!o.representation_note,
      `office '${o.title}' is voting_powers 'full' but carries a representation_note — both read paths HIDE it`);
  }
}

// ── ruling M2: exactly one non_voting seat, and it is the Mayor ──────────────
{
  const nv = all.filter((o) => o.voting_powers === 'non_voting');
  check(nv.length === 1 && nv[0].title === 'Mayor',
    `expected exactly one non_voting office (the Mayor), got [${nv.map((o) => o.title).join(', ') || 'none'}]`);
  const note = nv[0]?.representation_note ?? '';
  check(/9\(c\)/.test(note),
    "the Mayor's representation_note must cite charter Sec. 9(c) — the section was READ, not carried from a summary (the GA-4 Sec. 4-102 defect)");
}

// ── ruling M3: a rotating role is a parenthetical, never an office ───────────
for (const o of all) {
  check(!/pro[- ]tem|chair(?!\b.*court)|vice[- ]/i.test(o.title),
    `office title '${o.title}' names a rotating role — ruling M3 says it is a parenthetical`);
}

// ── the office_terms CHECKs ─────────────────────────────────────────────────
{
  const HOW = new Set(['elected', 'appointed', 'succeeded', 'redistricted', 'unknown']);
  const PREC = new Set(['day', 'month', 'year', 'unknown']);
  for (const o of all) {
    const p = o.person;
    check(HOW.has(p.how_started),
      `${p.full_name}: how_started '${p.how_started}' violates the office_terms CHECK ` +
      `('special election' is NOT a legal value — put the special fact in the source string)`);
    check(PREC.has(p.start_precision), `${p.full_name}: start_precision '${p.start_precision}' violates the CHECK`);
    check(!(p.start_precision === 'unknown' && p.term_start !== null),
      `${p.full_name}: start_precision 'unknown' with a term_start is a contradiction`);
    check(!(p.start_precision !== 'unknown' && p.term_start === null),
      `${p.full_name}: start_precision '${p.start_precision}' with no term_start`);
    check(!!p.source && p.source.length > 20, `${p.full_name}: no substantive source string`);
    check(Array.isArray(p.aliases), `${p.full_name}: aliases must be an array — the column is NOT NULL DEFAULT '{}'`);
  }
}

// ── no term_end anywhere. A future term_end makes a seat silently self-vacate ─
check(!JSON.stringify(r).includes('term_end'), 'the roster carries a term_end — spec §4.1 forbids writing one');

// ── party must not have leaked in. It lives on races.primary_party ──────────
{
  const json = JSON.stringify(r).toLowerCase();
  for (const w of ['"party"', '"republican"', '"democrat"', '"(dem)"', '"(rep)"']) {
    check(!json.includes(w), `the roster carries ${w} — party belongs on races.primary_party only`);
  }
}

// ── the tiers must not cross (GA-4's gate for consolidated jurisdictions) ────
{
  check(r.city.district_type === 'LOCAL', `city district_type is '${r.city.district_type}', expected 'LOCAL'`);
  check(r.county.district_type === 'COUNTY', `county district_type is '${r.county.district_type}', expected 'COUNTY'`);
  check(r.county.countywide_district.create === false,
    'the countywide district must be ASSERTED, not created — the TIGER county load already made 13021/G4020');
  check(r.city.citywide_district.create === true,
    'the citywide district must be CREATED — GA-1 loaded the place BOUNDARY and no place DISTRICT');
  check(r.city.citywide_district.geo_id !== r.county.countywide_district.geo_id,
    'the citywide and countywide districts share a geo_id — they cover identical ground but are different rows');
  check(r.county.shares_government_with === 'city',
    'consolidation means the county officers hang off the SAME government row as the Commission');
}

// ── dated rows are asserted individually below, so make the expected set explicit ─
{
  const dated = all.filter((o) => o.person.term_start !== null)
    .map((o) => `${o.person.external_id}|${o.person.term_start}|${o.person.start_precision}|${o.person.how_started}`)
    .sort();
  const EXPECTED = [
    '-1331036|2021-01-01|day|elected',      // Miller, Mayor
    '-1331037|2018-06-01|month|elected',    // Wynn, D1 — special, oath date unpublished
    '-1331038|2021-01-01|day|elected',      // Bronson, D2
    '-1331039|2024-10-15|day|appointed',    // Stewart, D3 — the OATH, not the appointment vote
    '-1331040|2025-01-01|day|elected',      // Hulett, D4
    '-1331041|2026-04-20|day|elected',      // Cooke, D5 — special; the weekday arbitrates
    '-1331042|2021-01-01|day|elected',      // Wilder, D6
    '-1331043|2021-01-01|day|elected',      // Howell, D7
    '-1331044|2025-01-01|day|elected',      // Bryant, D8
    '-1331045|2024-01-17|day|appointed',    // Bailey, D9 — Commission vote 5-3
    '-1331046|2013-01-01|year|elected',     // Davis, Sheriff
    '-1331049|2013-01-01|year|elected',     // Harris, Probate
  ].sort();
  check(JSON.stringify(dated) === JSON.stringify(EXPECTED),
    `the dated rows changed.\n  got:      ${JSON.stringify(dated, null, 1)}\n  expected: ${JSON.stringify(EXPECTED, null, 1)}\n` +
    `⚠ A COUNT of dated rows cannot see a date that MOVED, and the date most likely to be substituted ` +
    `here is 2025-01-01 for everyone — which is right for exactly two of the ten city seats.`);

  const undatedIds = all.filter((o) => o.person.term_start === null).map((o) => o.person.external_id).sort();
  check(JSON.stringify(undatedIds) === JSON.stringify([-1331050, -1331048, -1331047].sort()),
    `the open-ended rows changed: got ${JSON.stringify(undatedIds)}. ` +
    `Only Woodford, McCord and Jones have no published start.`);
}

// ── report ───────────────────────────────────────────────────────────────────
if (problems.length) {
  console.error(`\nROSTER INVALID — ${problems.length} problem(s):\n`);
  for (const p of problems) console.error(`  ✗ ${p}`);
  process.exit(1);
}

const { min, max } = r.id_band;
console.log(
  `roster OK: ${EXPECT_TOTAL} offices (${EXPECT_CITY} city, ${EXPECT_COUNTY} county), ` +
  `${all.length} unique ids in band ${min}..${max}, ` +
  `${all.filter((o) => o.person.term_start !== null).length} dated rows asserted individually, ` +
  `1 non_voting Mayor citing Sec. 9(c), no party fields, no term_end.`,
);
