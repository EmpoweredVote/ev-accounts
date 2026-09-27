#!/usr/bin/env node
/**
 * gen-lexington-migrations.mjs — Knight program, wave KY-3.
 *
 * Emits ROSTERS.md plus the structure (CC_0152) and occupancy (CC_0153) migrations for the
 * Lexington-Fayette Urban County Government.
 *
 * ─────────────────────────────────────────────────────────────────────────────────────────────
 * 🔴🔴 THE CITY'S OWN COUNCILMEMBERS PAGE PRODUCES A WRONG INVENTORY IF READ LITERALLY. Its prose
 * says the Council has 15 members: "The vice mayor / Two at-large councilmembers / 12 district
 * councilmembers". Read as written that creates a separately elected VICE MAYOR office. It does
 * not exist. The city's Government page states the truth plainly -- "There are 12 district council
 * members and three at-large council members" -- and the roster lists Dan Wu as "Council At-Large
 * and Vice Mayor". Voters elect THREE at-large members; the one with the most votes takes the Vice
 * Mayor title. By the inclusion ruling (an office is seated if the VOTERS elect it), Vice Mayor is
 * a title, not an office.
 *
 * So: Mayor (1) + Council At-Large (3) + Council District 1-12 (12) = 16 elected offices.
 * The Mayor gets his own chamber, which is the Duluth/Grand Forks/Macon-Bibb precedent.
 *
 * ⚠ TWO TERM LENGTHS INSIDE ONE BODY: at-large seats run 4 years, district seats 2.
 *
 * 🔴🔴 THE OATH DATE IS NOT A RULE AND MUST NOT BE COMPUTED, AND KENTUCKY PROVED IT AGAIN.
 * Whitney Elliott Baxter assumed office 2021-01-04 (a Monday) and Lisa Higgins-Hord's appointment
 * runs through 2027-01-04 (a Monday), which invites "the first Monday in January". The city's OWN
 * record says the 2025-26 district members took the oath on SUNDAY, JANUARY 12, 2025, at the
 * Lexington Senior Center, administered by Fayette District Judge Denotra Gunther. Computing the
 * first Monday would have written 2025-01-06 for five members -- wrong by six days.
 *
 * ⚠ THAT CEREMONY RE-SWORE ALL TWELVE DISTRICT MEMBERS, INCUMBENTS INCLUDED, so 2025-01-12 is the
 * start of the 2025-26 TERM, not of continuous occupancy. It is used only for the five members the
 * archived-roster timeline shows ARRIVING then (absent 2024-12-22, present 2025-01-17).
 * office_terms carries continuous occupancy -- North Carolina's rows reach back to 1999-01-01 --
 * so an incumbent's re-swearing must not overwrite an earlier start.
 *
 * ⚠ TWO GAP CASES, the same trap KY-2 found at state level: Chuck Ellinger II served at-large
 * 2003-2014 and returned in 2019; James Brown moved from a DISTRICT seat to at-large in 2022.
 * Neither's first year on the Council is the start of the seat they hold now.
 *
 * Party is NOT written. Party is antipartisan and lives on races.primary_party.
 *
 * Usage: node scripts/gen-lexington-migrations.mjs --out-dir data/seed-ky-2026 --mig-dir migrations
 */
import fs from 'fs';
import path from 'path';

const argv = process.argv.slice(2);
const argOf = (f) => { const i = argv.indexOf(f); return i >= 0 ? argv[i + 1] : undefined; };
const OUT = argOf('--out-dir') ?? 'data/seed-ky-2026';
const MIG = argOf('--mig-dir') ?? 'migrations';

const STRUCTURE_SLOT = 'CC_0152';
const OCCUPANCY_SLOT = 'CC_0153';
const EXTERNAL_ID_BASE = -2762800; // block -2762800..-2762785 measured EMPTY 2026-09-26 and clear
                                   // of KY-2's -2763000..-2762863.
const GOVERNMENT = 'Lexington-Fayette Urban County Government, Kentucky, US';
const COUNCIL = 'Lexington-Fayette Urban County Council';
const MAYOR_CHAMBER = 'Office of the Mayor of Lexington-Fayette, Kentucky';
const PLACE_GEO_ID = '2146027';
const MTFCC = 'X0068';
const SWEAR_IN_2025 = '2025-01-12';

/** seat, name, term_start, precision, how_started, why */
const ROSTER = [
  ['MAYOR', 'Linda Gorton',           '2019-01-01', 'year', 'elected',
   'took office January 2019 after the 2018 election'],
  ['AL1',   'Dan Wu',                 '2023-01-01', 'year', 'elected',
   'member page: "elected to office in November of 2022"'],
  ['AL2',   'James Brown',            '2023-01-01', 'year', 'elected',
   'member page: moved from a district seat, "elected to that position in 2022"'],
  ['AL3',   'Chuck Ellinger II',      '2019-01-01', 'year', 'elected',
   'returned to an at-large seat in 2019 after serving 2003-2014 - a GAP, so the earlier stint is not this occupancy'],
  ['D1',    'Tyler Morton',           SWEAR_IN_2025, 'day', 'elected',
   'city swearing-in record; absent from the 2024-12-22 archived roster'],
  ['D2',    'Shayla Lynch',           '2023-01-01', 'year', 'elected',
   'member page: "elected in November 2022"'],
  ['D3',    'Tom Eblen',              '2026-02-03', 'day', 'appointed',
   'city member page: "appointed by Mayor Linda Gorton on Feb. 3, 2026", filling Hannah LeGris’ unexpired term'],
  ['D4',    'Emma Curtis',            SWEAR_IN_2025, 'day', 'elected',
   'city swearing-in record; absent from the 2024-12-22 archived roster'],
  ['D5',    'Liz Sheehan',            '2021-01-01', 'year', 'elected',
   'first elected November 2020'],
  ['D6',    'Lisa Higgins-Hord',      '2025-08-22', 'day', 'appointed',
   'city news and member page: named and sworn in 2025-08-22 after Denise Gray resigned effective 2025-07-31'],
  ['D7',    'Joseph Hale',            SWEAR_IN_2025, 'day', 'elected',
   'city swearing-in record; absent from the 2024-12-22 archived roster'],
  ['D8',    'Amy Beasley',            SWEAR_IN_2025, 'day', 'elected',
   'city swearing-in record; absent from the 2024-12-22 archived roster'],
  ['D9',    'Whitney Elliott Baxter', '2021-01-01', 'year', 'elected',
   'elected November 2020'],
  ['D10',   'Dave Sevigny',           '2023-01-01', 'year', 'elected',
   'elected November 2022'],
  ['D11',   'Jennifer Reynolds',      '2019-01-01', 'year', 'elected',
   'first elected 2018'],
  ['D12',   'Hil Boone',              SWEAR_IN_2025, 'day', 'elected',
   'city swearing-in record; absent from the 2024-12-22 archived roster'],
];

const seatInfo = (seat) => {
  if (seat === 'MAYOR') return { chamber: MAYOR_CHAMBER, title: 'Mayor', geoId: PLACE_GEO_ID, kind: 'citywide' };
  if (seat.startsWith('AL')) return { chamber: COUNCIL, title: 'Council Member, At-Large', geoId: PLACE_GEO_ID, kind: 'citywide' };
  const n = Number(seat.slice(1));
  return { chamber: COUNCIL, title: `Council Member, District ${n}`,
           geoId: `lexington-fayette-ky-council-district-${n}`, kind: 'district', n };
};

const people = ROSTER.map(([seat, name, start, prec, how, why], i) => {
  const info = seatInfo(seat);
  const parts = name.trim().split(/\s+/);
  return { seat, name, start, prec, how, why, ...info,
           externalId: EXTERNAL_ID_BASE + i, first: parts[0], last: parts[parts.length - 1] };
});

const dayCount = people.filter((p) => p.prec === 'day').length;
const yearCount = people.filter((p) => p.prec === 'year').length;
const appointed = people.filter((p) => p.how === 'appointed').length;
if (people.length !== 16) throw new Error(`roster is ${people.length}, expected 16`);
if (new Set(people.map((p) => p.externalId)).size !== 16) throw new Error('external_id collision');
if (new Set(people.map((p) => p.name)).size !== 16) throw new Error('duplicate name inside the wave');

const q = (s) => "'" + String(s).replace(/'/g, "''") + "'";
const SOURCE =
  "Lexington-Fayette Urban County Government. Roster read from the city's own Councilmembers page " +
  'and all 15 individual member pages at lexingtonky.gov, cross-checked against 17 archived copies ' +
  'of the same roster (2024-12 to 2026-06) which supplied the arrival windows. Arrival days from ' +
  "the city's own records: the 2025-01-12 swearing-in announcement, and the two appointment notices " +
  '(Higgins-Hord 2025-08-22, Eblen 2026-02-03). Where no day is published the year of first taking ' +
  'the seat is used at year precision. Read 2026-09-26 (KY-3) (' + OCCUPANCY_SLOT + ', KY-3)';

// ── ROSTERS.md ───────────────────────────────────────────────────────────────
const md = [];
md.push('# Lexington-Fayette Urban County Government — KY-3 roster', '');
md.push('Wave KY-3 of the Knight Foundation cities program. Generated by');
md.push('`scripts/gen-lexington-migrations.mjs`.', '');
md.push(`**16 elected offices — Mayor + 3 at-large + 12 district. ${dayCount} day-precision terms, ${yearCount} year-precision, 0 unknown.**`, '');
md.push('## Sources', '');
md.push('| # | Source | Role |');
md.push('| --- | --- | --- |');
md.push("| A | `lexingtonky.gov` Councilmembers page and 15 member pages | roster + appointment dates |");
md.push('| B | 17 archived copies of the roster, 2024-12 to 2026-06 | arrival windows |');
md.push("| C | City news: swearing-in 2025-01-12, appointments 2025-08-22 and 2026-02-03 | **arrival days** |");
md.push('| D | LFUCG `Council_District` feature service | geometry (`X0068`) |', '');
md.push('## 🔴 Source defects found', '');
md.push('- 🔴🔴 **The Councilmembers page prose produces a wrong inventory.** It describes the Council');
md.push('  as *"The vice mayor / Two at-large councilmembers / 12 district councilmembers"*, which reads');
md.push('  as a separately elected **Vice Mayor** office. There is none. The Government page states');
md.push('  *"There are 12 district council members and three at-large council members"*, and the roster');
md.push('  lists Dan Wu as *"Council At-Large and Vice Mayor"*. **Vice Mayor is a title, not an office.**');
md.push('- 🔴 **Member pages carry no term data** — they are biographies. Only the two APPOINTED members');
md.push('  have a date on their page, in the form *"appointed by Mayor … on <date>"*.');
md.push('- 🔴 **The archived roster lives in an escaped JSON menu blob, not in anchors**, and one snapshot');
md.push('  returned undecoded gzip. A parser that reads anchors scores both as zero.');
md.push('- ⚠ **A name with an embedded comma breaks a naive parser**: `Shayla Lynch, J.D.` was silently');
md.push('  dropped, leaving 14 of 15, until the parser keyed on the `href`. The credential is not part');
md.push('  of the name and is not written.', '');
md.push('## Charter rulings', '');
md.push('- **16 elected offices**: Mayor (1), Council At-Large (3, four-year terms), Council District');
md.push('  1–12 (12, two-year terms). Vice Mayor is the at-large member with the most votes — a title.');
md.push('- **KRS 67A does not set an urban-county council’s structure**; the charter does. But the');
md.push('  statute requires the government to retain the county offices named in the Kentucky');
md.push('  Constitution — that is stage 4, and it is why consolidation does not empty it.');
md.push('- The Mayor heads a separate executive office; the Council is the legislative branch. The Mayor');
md.push('  therefore gets his own chamber, as at Duluth, Grand Forks and Macon-Bibb.', '');
md.push('## 🔴🔴 The oath date is not a rule');
md.push('');
md.push('Whitney Elliott Baxter assumed office 2021-01-04 (a Monday) and Lisa Higgins-Hord’s appointment');
md.push('runs through 2027-01-04 (a Monday), which invites *"the first Monday in January"*. The city’s own');
md.push('record says the 2025-26 district members took the oath on **Sunday, January 12, 2025**.');
md.push('Computing the first Monday would have written **2025-01-06** — wrong by six days.', '');
md.push('⚠ That ceremony **re-swore all twelve district members**, incumbents included, so `2025-01-12` is');
md.push('the start of the 2025-26 *term*, not of continuous occupancy. It is used only for the five whom');
md.push('the archived timeline shows arriving then. `office_terms` carries continuous occupancy.', '');
md.push('## Term dates', '');
md.push('| Seat | Member | Start | Precision | How | Basis |');
md.push('| --- | --- | --- | --- | --- | --- |');
for (const p of people) md.push(`| ${p.seat} | ${p.name} | \`${p.start}\` | ${p.prec} | ${p.how} | ${p.why} |`);
md.push('');
md.push(`**${dayCount} day · ${yearCount} year · 0 unknown · 0 invented. ${appointed} appointed, ${16 - appointed} elected.**`, '');
md.push('⚠ **Two gap cases**, the KY-2 trap again: **Chuck Ellinger II** served at-large 2003–2014 and');
md.push('returned in 2019; **James Brown** moved from a district seat to at-large in 2022. Neither’s');
md.push('first year on the Council starts the seat they hold now.', '');
md.push('## Geometry', '');
md.push('`X0068`, 12 polygons from the LFUCG `Council_District` service. 🔴 The city publishes **four**');
md.push('council-district layers and **all four carry exactly 12 features** — a count cannot tell them');
md.push('apart. A centroid test agrees **11/12** with the 2012 map and is too weak. The discriminator is');
md.push('area: **all 12 districts differ from 2012 by 1.0%–44.9% while the total is preserved to 0.03%**.');
md.push('');
md.push('🟢 The place polygon `2146027` is **exactly coterminous** with Fayette County `21067` — both');
md.push('285.567 sq mi, zero difference either way. The 12 districts cover **99.968%** of it.', '');
md.push('## Roster', '');
md.push('| Seat | Member | Chamber | `geo_id` |');
md.push('| --- | --- | --- | --- |');
for (const p of people) md.push(`| ${p.seat} | ${p.name} | ${p.chamber} | \`${p.geoId}\` |`);
md.push('');
fs.writeFileSync(path.join(OUT, 'ROSTERS-lexington.md'), md.join('\n'));

// ── CC_0152 structure ────────────────────────────────────────────────────────
const districtRows = people
  .filter((p) => p.kind === 'district')
  .map((p) => `  (${q(p.geoId)}, ${q('Lexington-Fayette Urban County Council District ' + p.n)})`);

const S = `-- ${STRUCTURE_SLOT}_lexington_fayette_structure.sql
-- Knight Foundation program, wave KY-3 (structure half). Slot RESERVED from the allocator.
--
-- Production holds NO Lexington or Fayette government row and NO Kentucky LOCAL districts before
-- this migration; measured 2026-09-26. It:
--
--   1. creates the government and its two chambers;
--   2. creates 13 LOCAL districts -- 12 council districts plus one citywide district on the TIGER
--      place GEOID ${PLACE_GEO_ID}, which carries the Mayor and the three at-large seats;
--   3. creates 16 offices -- Mayor (1), Council At-Large (3), Council District 1-12 (12).
--
-- Creates NO people and NO terms -- ${OCCUPANCY_SLOT} does that, and the two are applied back to back.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE CITY'S OWN COUNCILMEMBERS PAGE PRODUCES A WRONG INVENTORY IF READ LITERALLY. Its prose says
-- the Council has 15 members: "The vice mayor / Two at-large councilmembers / 12 district
-- councilmembers". Read as written that creates a separately elected VICE MAYOR office. There is
-- none. The Government page states "There are 12 district council members and three at-large
-- council members", and the roster lists Dan Wu as "Council At-Large and Vice Mayor". Voters elect
-- THREE at-large members and the top vote-getter takes the title. By the inclusion ruling -- an
-- office is seated if the VOTERS elect it -- Vice Mayor is a title, not an office.
--
-- REFUSES TO RUN IF THE ${MTFCC} BOUNDARIES ARE ABSENT. An office on a district with no polygon is
-- unreachable by any address and NOTHING ERRORS. load-lexington-council-boundaries.mjs writes them.
--
-- Two term lengths inside one body: at-large 4 years, district 2 years.
-- Party is NOT written. Party is antipartisan and lives on races.primary_party.
-- ─────────────────────────────────────────────────────────────────────────────────────────────

BEGIN;

-- ─── 0. Refuse to run without the geometry ────────────────────────────────────

DO $$
DECLARE v_b int;
BEGIN
  SELECT count(*) INTO v_b FROM essentials.geofence_boundaries WHERE mtfcc = '${MTFCC}';
  IF v_b <> 12 THEN
    RAISE EXCEPTION '${STRUCTURE_SLOT}: ${MTFCC} holds % boundaries, expected 12. Run load-lexington-council-boundaries.mjs first - an office on a district with no polygon is unreachable and nothing errors.', v_b;
  END IF;
END $$;

-- ─── 1. Government and chambers ───────────────────────────────────────────────

INSERT INTO essentials.governments (name)
SELECT ${q(GOVERNMENT)}
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments g WHERE g.name = ${q(GOVERNMENT)});

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length, staggered_term)
SELECT v.gid, v.nm, v.nm, v.cnt, v.tl, v.stag
FROM (VALUES
  ((SELECT id FROM essentials.governments WHERE name = ${q(GOVERNMENT)}), ${q(COUNCIL)}, 15, 2, true),
  ((SELECT id FROM essentials.governments WHERE name = ${q(GOVERNMENT)}), ${q(MAYOR_CHAMBER)}, 1, 4, false)
) AS v(gid, nm, cnt, tl, stag)
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.name_formal = v.nm);

-- ─── 2. The 13 LOCAL districts ────────────────────────────────────────────────
--
-- 12 council districts on their own polygons, plus ONE citywide district on the TIGER place
-- GEOID. The place polygon was MEASURED exactly coterminous with Fayette County -- both
-- 285.567 sq mi, zero difference in either direction -- so a citywide seat on it reaches every
-- resident of the consolidated government.

CREATE TEMP TABLE lex_districts(geo_id text, label text) ON COMMIT DROP;
INSERT INTO lex_districts(geo_id, label) VALUES
${districtRows.join(',\n')},
  (${q(PLACE_GEO_ID)}, 'Lexington-Fayette Urban County Government (citywide)');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT ld.geo_id, ld.label, 'LOCAL', 'ky',
       CASE WHEN ld.geo_id = ${q(PLACE_GEO_ID)} THEN 'G4110' ELSE ${q(MTFCC)} END
FROM lex_districts ld
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d
   WHERE d.geo_id = ld.geo_id AND d.district_type = 'LOCAL' AND lower(d.state) = 'ky'
);

-- ─── 3. The 16 offices ────────────────────────────────────────────────────────

CREATE TEMP TABLE lex_seats(geo_id text, chamber_formal text, title text, n int) ON COMMIT DROP;
INSERT INTO lex_seats(geo_id, chamber_formal, title, n) VALUES
${people.map((p, i) => `  (${q(p.geoId)}, ${q(p.chamber)}, ${q(p.title)}, ${i})`).join(',\n')};

-- The three at-large seats share one title and one district and are distinguished only by row,
-- which is Arizona's and Duluth's shape: the ballot does not number them.
INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, representing_city, seats, is_vacant)
SELECT c.id, d.id, s.title, 'KY', 'Lexington', 1, false
FROM lex_seats s
JOIN essentials.chambers c ON c.name_formal = s.chamber_formal
JOIN essentials.districts d
  ON d.geo_id = s.geo_id AND d.district_type = 'LOCAL' AND lower(d.state) = 'ky'
LEFT JOIN LATERAL (
  SELECT count(*) AS have FROM essentials.offices o
   WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = s.title
) x ON true
LEFT JOIN LATERAL (
  SELECT count(*) AS want FROM lex_seats s2
   WHERE s2.geo_id = s.geo_id AND s2.chamber_formal = s.chamber_formal AND s2.title = s.title
) y ON true
-- Idempotent by COUNT, not by existence: three at-large rows share one (chamber, district,
-- title), so an EXISTS guard would create one seat instead of three. On a re-run have = want
-- and nothing is inserted.
WHERE x.have < y.want;

-- ─── 4. Post-verify gate ──────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov int; v_ch int; v_dist int; v_off int; v_council int; v_mayor int; v_al int; v_noc int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE name = ${q(GOVERNMENT)};
  IF v_gov <> 1 THEN RAISE EXCEPTION '${STRUCTURE_SLOT}: expected 1 government row, got %', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers WHERE name_formal IN (${q(COUNCIL)}, ${q(MAYOR_CHAMBER)});
  IF v_ch <> 2 THEN RAISE EXCEPTION '${STRUCTURE_SLOT}: expected 2 chambers, got %', v_ch; END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE district_type = 'LOCAL' AND lower(state) = 'ky';
  IF v_dist <> 13 THEN RAISE EXCEPTION '${STRUCTURE_SLOT}: expected 13 Kentucky LOCAL districts, got %', v_dist; END IF;

  SELECT count(*) INTO v_council FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id WHERE c.name_formal = ${q(COUNCIL)};
  SELECT count(*) INTO v_mayor FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id WHERE c.name_formal = ${q(MAYOR_CHAMBER)};
  v_off := v_council + v_mayor;
  IF v_council <> 15 THEN RAISE EXCEPTION '${STRUCTURE_SLOT}: expected 15 council offices, got %', v_council; END IF;
  IF v_mayor <> 1 THEN RAISE EXCEPTION '${STRUCTURE_SLOT}: expected 1 mayor office, got %', v_mayor; END IF;

  -- Exactly three at-large seats, and they must NOT be numbered: the ballot does not number them,
  -- and a "Vice Mayor" office must not exist at all.
  SELECT count(*) INTO v_al FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal = ${q(COUNCIL)} AND o.title = 'Council Member, At-Large';
  IF v_al <> 3 THEN RAISE EXCEPTION '${STRUCTURE_SLOT}: expected 3 at-large offices, got %', v_al; END IF;

  IF EXISTS (SELECT 1 FROM essentials.offices o
               JOIN essentials.chambers c ON c.id = o.chamber_id
              WHERE c.name_formal = ${q(COUNCIL)} AND o.title ILIKE '%vice mayor%') THEN
    RAISE EXCEPTION '${STRUCTURE_SLOT}: a Vice Mayor OFFICE exists. Voters elect three at-large members; the top vote-getter takes the Vice Mayor TITLE. It is not a separate office.';
  END IF;

  -- Every district seat must sit on its own polygon.
  SELECT count(*) INTO v_noc FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.name_formal = ${q(COUNCIL)} AND o.title LIKE 'Council Member, District%'
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries b
                      WHERE b.geo_id = d.geo_id AND b.mtfcc = ${q(MTFCC)});
  IF v_noc <> 0 THEN
    RAISE EXCEPTION '${STRUCTURE_SLOT}: % district office(s) sit on a district with no ${MTFCC} polygon - unreachable by address, and nothing would error', v_noc;
  END IF;

  RAISE NOTICE '${STRUCTURE_SLOT} OK: 1 government, 2 chambers, 13 LOCAL districts, % offices (% council incl 3 at-large, % mayor)', v_off, v_council, v_mayor;
END $$;

COMMIT;
`;

// ── CC_0153 occupancy ────────────────────────────────────────────────────────
const O = `-- ${OCCUPANCY_SLOT}_lexington_fayette_incumbents.sql
-- Knight Foundation program, wave KY-3 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after ${STRUCTURE_SLOT}.
--
-- Seats all 16 elected officials of the Lexington-Fayette Urban County Government: the Mayor, three
-- at-large council members and twelve district council members. 16 people, 16 terms, 0 vacancies.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE OATH DATE IS NOT A RULE AND MUST NOT BE COMPUTED. Whitney Elliott Baxter assumed office
-- 2021-01-04 (a Monday) and Lisa Higgins-Hord's appointment runs through 2027-01-04 (a Monday),
-- which invites "the first Monday in January". The city's OWN record says the 2025-26 district
-- members took the oath on SUNDAY, JANUARY 12, 2025, at the Lexington Senior Center, administered
-- by Fayette District Judge Denotra Gunther. Computing the first Monday would have written
-- 2025-01-06 for five members -- wrong by six days. This is ND-3's finding, reproduced.
--
-- THAT CEREMONY RE-SWORE ALL TWELVE DISTRICT MEMBERS, INCUMBENTS INCLUDED, so ${SWEAR_IN_2025} is the
-- start of the 2025-26 TERM, not of continuous occupancy. It is used only for the five members the
-- archived-roster timeline shows ARRIVING then -- absent 2024-12-22, present 2025-01-17.
-- office_terms carries CONTINUOUS OCCUPANCY (North Carolina's rows reach back to 1999-01-01), so an
-- incumbent's re-swearing must never overwrite an earlier start.
--
-- TWO GAP CASES, the trap KY-2 found at state level: Chuck Ellinger II served at-large 2003-2014 and
-- returned in 2019; James Brown moved from a DISTRICT seat to at-large in 2022. Neither's first year
-- on the Council starts the seat he holds now.
--
-- TWO MEMBERS WERE APPOINTED, NOT ELECTED, and how_started records the difference: Lisa Higgins-Hord
-- (District 6, 2025-08-22, after Denise Gray resigned effective 2025-07-31) and Tom Eblen
-- (District 3, 2026-02-03, filling Hannah LeGris' unexpired term). Both dates come from the city's
-- own publications, which is the only thing that dates an appointed arrival.
--
-- NO NAMESAKES. All 16 names were checked against existing politicians and none collided; the
-- check was CONTROLLED with names known to exist (Steven Rudy and Gary Clemons, both seated by
-- KY-2, each returned 1), so the zero is a real answer and not a broken query.
-- external_id block -2762800..-2762785 measured EMPTY and clear of KY-2's -2763000..-2762863.
--
-- 'Shayla Lynch, J.D.' is published with a credential; the credential is not part of the name and
-- is not written.
-- Party is NOT written. Party is antipartisan and lives on races.primary_party.
-- ─────────────────────────────────────────────────────────────────────────────────────────────

BEGIN;

-- ─── 1. The 16 people ─────────────────────────────────────────────────────────

CREATE TEMP TABLE lex_people(external_id bigint, full_name text, first_name text, last_name text)
  ON COMMIT DROP;

INSERT INTO lex_people(external_id, full_name, first_name, last_name) VALUES
${people.map((p) => `  (${p.externalId}, ${q(p.name)}, ${q(p.first)}, ${q(p.last)})`).join(',\n')};

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, is_incumbent, is_active)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, ${q(SOURCE)}, true, true
FROM lex_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── 2. The 16 terms ──────────────────────────────────────────────────────────
--
-- The three at-large offices are interchangeable rows on one district with one title, so they are
-- matched by ROW NUMBER, not by any distinguishing attribute -- Arizona's and Duluth's shape.

CREATE TEMP TABLE lex_terms(
  external_id bigint, geo_id text, chamber_formal text, title text, slot int,
  term_start date, start_precision text, how_started text
) ON COMMIT DROP;

INSERT INTO lex_terms(external_id, geo_id, chamber_formal, title, slot, term_start, start_precision, how_started) VALUES
${(() => {
  const seen = new Map();
  return people.map((p) => {
    const k = `${p.geoId}|${p.chamber}|${p.title}`;
    const slot = (seen.get(k) ?? 0);
    seen.set(k, slot + 1);
    return `  (${p.externalId}, ${q(p.geoId)}, ${q(p.chamber)}, ${q(p.title)}, ${slot}, DATE ${q(p.start)}, ${q(p.prec)}, ${q(p.how)})`;
  }).join(',\n');
})()};

WITH office_slots AS (
  SELECT o.id AS office_id, c.name_formal AS chamber_formal, d.geo_id, o.title,
         (row_number() OVER (PARTITION BY c.name_formal, d.geo_id, o.title ORDER BY o.id) - 1)::int AS slot
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.name_formal IN (${q(COUNCIL)}, ${q(MAYOR_CHAMBER)})
)
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT os.office_id, p.id, t.term_start, NULL, t.start_precision, t.how_started, ${q(SOURCE)}
FROM lex_terms t
JOIN office_slots os
  ON os.geo_id = t.geo_id AND os.chamber_formal = t.chamber_formal
 AND os.title = t.title AND os.slot = t.slot
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = os.office_id);

-- ─── 3. Post-verify gate ──────────────────────────────────────────────────────

DO $$
DECLARE
  v_people int; v_terms int; v_seated int; v_day int; v_year int; v_unknown int;
  v_appointed int; v_ended int; v_dupes int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN ${EXTERNAL_ID_BASE} AND ${EXTERNAL_ID_BASE + 15};
  IF v_people <> 16 THEN RAISE EXCEPTION '${OCCUPANCY_SLOT}: expected 16 people, got %', v_people; END IF;

  SELECT count(*), count(*) FILTER (WHERE ot.start_precision = 'day'),
         count(*) FILTER (WHERE ot.start_precision = 'year'),
         count(*) FILTER (WHERE ot.start_precision = 'unknown'),
         count(*) FILTER (WHERE ot.how_started = 'appointed'),
         count(*) FILTER (WHERE ot.term_end IS NOT NULL)
    INTO v_terms, v_day, v_year, v_unknown, v_appointed, v_ended
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.name_formal IN (${q(COUNCIL)}, ${q(MAYOR_CHAMBER)});

  IF v_terms <> 16 THEN RAISE EXCEPTION '${OCCUPANCY_SLOT}: expected 16 terms, got %', v_terms; END IF;
  IF v_day <> ${dayCount} THEN RAISE EXCEPTION '${OCCUPANCY_SLOT}: expected ${dayCount} day-precision terms, got %', v_day; END IF;
  IF v_year <> ${yearCount} THEN RAISE EXCEPTION '${OCCUPANCY_SLOT}: expected ${yearCount} year-precision terms, got %', v_year; END IF;
  IF v_unknown <> 0 THEN RAISE EXCEPTION '${OCCUPANCY_SLOT}: % term(s) have unknown precision; this wave dates every seat', v_unknown; END IF;
  IF v_appointed <> ${appointed} THEN RAISE EXCEPTION '${OCCUPANCY_SLOT}: expected ${appointed} appointed arrivals, got %', v_appointed; END IF;
  IF v_ended <> 0 THEN RAISE EXCEPTION '${OCCUPANCY_SLOT}: % term(s) already ended', v_ended; END IF;

  -- Count och.politician_id, never rows: office_current_holder LEFT JOINs from offices.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.name_formal IN (${q(COUNCIL)}, ${q(MAYOR_CHAMBER)});
  IF v_seated <> 16 THEN RAISE EXCEPTION '${OCCUPANCY_SLOT}: expected 16 seated, got %', v_seated; END IF;

  SELECT count(*) INTO v_dupes FROM (
    SELECT ot.politician_id FROM essentials.office_terms ot
      JOIN essentials.offices o ON o.id = ot.office_id
      JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE c.name_formal IN (${q(COUNCIL)}, ${q(MAYOR_CHAMBER)})
     GROUP BY ot.politician_id HAVING count(*) > 1) x;
  IF v_dupes <> 0 THEN RAISE EXCEPTION '${OCCUPANCY_SLOT}: % person/people hold more than one Lexington seat', v_dupes; END IF;

  RAISE NOTICE '${OCCUPANCY_SLOT} OK: 16 people, 16 terms, 16 seated, % day / % year / 0 unknown, % appointed', v_day, v_year, v_appointed;
END $$;

COMMIT;
`;

fs.writeFileSync(path.join(MIG, `${STRUCTURE_SLOT}_lexington_fayette_structure.sql`), S);
fs.writeFileSync(path.join(MIG, `${OCCUPANCY_SLOT}_lexington_fayette_incumbents.sql`), O);
console.log(`ROSTERS-lexington.md written to ${OUT}`);
console.log(`${STRUCTURE_SLOT} and ${OCCUPANCY_SLOT} written to ${MIG}`);
console.log(`  offices: 16 (1 mayor + 3 at-large + 12 district)`);
console.log(`  terms  : ${dayCount} day, ${yearCount} year, 0 unknown; ${appointed} appointed`);
