#!/usr/bin/env node
/**
 * gen-sc-legislature-migrations.mjs — Knight program, wave SC-2.
 *
 * Reads data/sc-legislature-roster.json (written by build-sc-legislature-roster.mjs) and emits
 * the two migrations, so that 170 hand-typed seats are impossible:
 *
 *   migrations/CC_0125_sc_legislature_structure.sql    2 chambers + 170 offices
 *   migrations/CC_0126_sc_legislature_incumbents.sql   170 seated, 169 created + 1 reused
 *
 * Both slots were RESERVED from the allocator (`steward slot CC`). Numbers are never counted.
 *
 * Reads nothing from the database and writes nothing to it.
 */
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROSTER = path.join(HERE, '..', 'data', 'sc-legislature-roster.json');
const MIGRATIONS = path.join(HERE, '..', 'migrations');

const GOV = 'daccc0ea-eafb-4962-ba00-2ee043fa6709'; // 'State of South Carolina', type STATE, geo_id 45 — the ONLY such row
const BAND_FROM = -2745200;
const BAND_TO = -2745001;

const SOURCE =
  'South Carolina General Assembly member lists, https://www.scstatehouse.gov/member.php?chamber=H ' +
  'and ?chamber=S; reconciled against Open States, https://data.openstates.org/people/current/sc.csv, ' +
  "and against the state's own RFA district layers at gis.state.sc.us; change-checked against all 170 " +
  "individual member pages; arrivals dated from the chambers' own journals, read 2026-09-20 (SC-2)";

/** Seats whose person already exists in production. READ before classified — a shared surname is
 *  never the answer on its own. */
const REUSE = {
  // SD-15 Wes Climer IS the existing 'Wes Climer' row: that row is a candidate in the SC 5th
  // congressional district race (external_id -450501, carrying a headshot), and Climer is the
  // sitting senator for District 15 running for Congress. A sitting legislator running for a
  // different seat is ONE person with two roles — the PA-2 Chris Rabb and MN-2 Eric Pratt shape.
  'S-15': {
    politician_id: '4c07dfea-0219-410e-a1f8-baf079c012d4',
    note: 'Wes Climer, existing SC-5 congressional candidate row (external_id -450501, has a headshot)',
  },
};

/** Seats whose name collides with a DIFFERENT person's active row. The duplicate-name guard is
 *  lifted for THESE ROWS, never for the migration. */
const NAMESAKES = {
  'H-49': "The existing John King holds COUNCIL MEMBER in CALIFORNIA (data_source: the California Secretary of State's cities-and-towns roster). The roster John Richard C. King is the representative for South Carolina House 49, Rock Hill. Different state, different office, different person.",
  // 🔴🔴 THIS COLLISION IS INSIDE THE WAVE, NOT AGAINST PRODUCTION. Two sitting South Carolina
  // legislators are both (first, last) = (Luke, Rankin), and the guard keys on that pair — so the
  // House row inserted first made the Senate row a duplicate of a person who did not exist when
  // this wave began. A pre-flight that compares the roster only against PRODUCTION is blind to it.
  // They are different people, read from their own pages:
  //   HD-14 Luke S. Rankin — born 1997-08-16 in Greenville, son of Gregory Rankin and Kari Joy,
  //                          health insurance advisor, LAURENS County, member code 1510227092
  //   SD-33 Luke A. Rankin — born 1962-04-09 in Horry County, son of O. A. and Dorothy S. Rankin,
  //                          attorney, chairman of Senate Judiciary, HORRY County, code 1511363455
  // Different births, different parents, different counties, different chambers, different codes.
  'S-33': 'HD-14 Luke S. Rankin (born 1997-08-16, Laurens County, code 1510227092) and SD-33 Luke A. Rankin (born 1962-04-09, Horry County, chairman of Senate Judiciary, code 1511363455) are TWO DIFFERENT SITTING LEGISLATORS who share a first and last name. Both are created by this migration; the House row is inserted with the guard armed and this one with it lifted.',
};

const q = (s) => String(s).replace(/'/g, "''");

const roster = JSON.parse(fs.readFileSync(ROSTER, 'utf8'));
const seats = [];
for (const [key, chamber] of Object.entries(roster.chambers)) {
  for (const m of chamber.members) {
    seats.push({
      ...m,
      chamberKey: key,
      code: `${key === 'house' ? 'H' : 'S'}-${m.district}`,
      districtType: chamber.district_type,
    });
  }
}
if (seats.length !== 170) throw new Error(`expected 170 seats, roster has ${seats.length}`);

const DATED = Object.fromEntries(
  seats.filter((s) => s.term_start).map((s) => [s.code, { term_start: s.term_start, precision: s.start_precision, how: s.how_started, source: s.term_source }]),
);

// ── assign external_ids to everyone who is not a reuse ───────────────────────
let next = BAND_TO; // walk downward from -2745001
const created = [];
for (const s of seats) {
  if (REUSE[s.code]) {
    s.reuse = REUSE[s.code];
    continue;
  }
  s.external_id = next--;
  created.push(s);
}
if (next < BAND_FROM) throw new Error(`external_id band exhausted: needed ${created.length}`);
const armed = created.filter((s) => !NAMESAKES[s.code]);
const lifted = created.filter((s) => NAMESAKES[s.code]);

// 🔴 THE ARMED SET MUST NOT COLLIDE WITH ITSELF. The duplicate-name trigger keys on
// (first_name, last_name), so two rows of THIS wave sharing that pair make the second one a
// duplicate of a person who did not exist when the wave began — and the dry-run is where that is
// discovered unless it is asserted here. Fail loudly at generation time instead.
const pairs = new Map();
for (const s of armed) {
  const key = `${s.first_name} ${s.last_name}`.toLowerCase();
  if (pairs.has(key)) {
    throw new Error(
      `two ARMED rows share (first_name, last_name) "${key}": ${pairs.get(key)} and ${s.code}. ` +
        'Read both members, then put ONE of them in NAMESAKES with the evidence — or reuse a row if ' +
        'they are the same person.',
    );
  }
  pairs.set(key, s.code);
}

// The dated term the occupancy gate names explicitly: the widest election-to-oath gap in the
// wave, and the one that proves the date is the OATH and not the election.
const ANCHOR = seats.find((s) => s.code === 'H-50');

// ── CC_0125: structure ───────────────────────────────────────────────────────

const structure = `-- CC_0125_sc_legislature_structure.sql
-- Knight Foundation program, wave SC-2 (structure half). Slot RESERVED from the allocator.
--
-- South Carolina has NO state legislative offices and NO legislative chambers today: production
-- holds 15 SC offices in total -- 7 US House, 2 US Senate, 5 statewide executives, plus one US
-- Senate CANDIDATE office. SC-1 loaded the geography (124 STATE_LOWER + 46 STATE_UPPER, vintage
-- proved on all 170 polygons against the state's own RFA layer), so this migration is a clean
-- seed with nothing to repair. It:
--
--   1. creates the two chambers;
--   2. creates 170 offices, one per district SC-1 loaded.
--
-- Creates NO people and NO terms -- CC_0126 does that, and the two are applied back to back.
--
-- 🔴 THE JOIN KEY IS (geo_id, district_type), NEVER geo_id ALONE. '45079' is House District 79
-- AND RICHLAND COUNTY, which is Columbia's county; '45051' is House District 51 AND HORRY COUNTY,
-- which is Myrtle Beach's. ALL 46 of South Carolina's counties share a geo_id string with a House
-- district and 23 with a Senate district. Nothing here matches on a number or a label; the office
-- insert joins districts by district_type and state, and the gate below asserts that no COUNTY
-- district picked up a legislative office.
--
-- 🟢 THE HOST GOVERNMENT IS NOT AMBIGUOUS, AND THAT WAS CHECKED. Production holds exactly ONE
-- 'State of South Carolina' row, ${GOV} (type STATE, state SC, geo_id 45).
-- Indiana's 18 indistinguishable government rows do NOT recur here, and the gate asserts it.
--
-- 🟢 NO SEAT IS VACANT. All 124 House and all 46 Senate districts carry a member: each chamber's
-- own list shows no hole, Open States agrees on all 170 by name AND by member code, all 170
-- individual member pages were read and every one names the member the list assigned to that
-- district and states that district, and 273 sitting days of both chambers' journals report no
-- unfilled seat.
--
-- 🔴 SD-15 IS A KNOWN FUTURE VACANCY AND IS DELIBERATELY SEATED ANYWAY. Wes Climer signed an
-- irrevocable resignation under S.C. Code s 8-1-145 effective 2026-11-03, so his successor is
-- elected at the November general election. He holds the seat until that date. No term_end is
-- written (a future term_end self-vacates a seat); the debt is recorded in ROSTERS.md and sc.md.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 1. The two chambers ──────────────────────────────────────────────────────
-- term_length: S.C. Const. art. III s 3 and s 6 -- Representatives two years, Senators four.

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT '${GOV}', 'South Carolina House of Representatives', 'South Carolina House of Representatives', 124, '2'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = '${GOV}' AND name = 'South Carolina House of Representatives');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT '${GOV}', 'South Carolina Senate', 'South Carolina Senate', 46, '4'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = '${GOV}' AND name = 'South Carolina Senate');

-- ─── 2. The 170 offices, one per district SC-1 loaded ─────────────────────────
-- Guarded on district_id: South Carolina has no legislative office at all today, so this inserts
-- 170 on a first run and 0 on any re-run.

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, ch.title, 'SC', 1, false, 'full'
FROM essentials.districts d
JOIN (VALUES
  ('STATE_LOWER', 'South Carolina House of Representatives', 'Representative'),
  ('STATE_UPPER', 'South Carolina Senate', 'Senator')
) AS ch(district_type, chamber_name, title) ON ch.district_type = d.district_type::text
JOIN essentials.chambers c ON c.government_id = '${GOV}' AND c.name = ch.chamber_name
WHERE lower(d.state) = 'sc'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_gov        int;
  v_house_ch   int;
  v_senate_ch  int;
  v_lower      int;
  v_upper      int;
  v_chambers   int;
  v_mistitled  int;
  v_county     int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE id = '${GOV}' AND name = 'State of South Carolina' AND type = 'STATE' AND state = 'SC';
  IF v_gov <> 1 THEN
    RAISE EXCEPTION 'SC-2 structure: the State of South Carolina government row is not what this migration assumed (got %)', v_gov;
  END IF;

  SELECT count(*) FILTER (WHERE name = 'South Carolina House of Representatives'),
         count(*) FILTER (WHERE name = 'South Carolina Senate')
    INTO v_house_ch, v_senate_ch
  FROM essentials.chambers WHERE government_id = '${GOV}';
  IF v_house_ch <> 1 OR v_senate_ch <> 1 THEN
    RAISE EXCEPTION 'SC-2 structure: expected exactly 1 House chamber (got %) and 1 Senate chamber (got %)',
      v_house_ch, v_senate_ch;
  END IF;

  SELECT count(*) FILTER (WHERE d.district_type::text = 'STATE_LOWER'),
         count(*) FILTER (WHERE d.district_type::text = 'STATE_UPPER')
    INTO v_lower, v_upper
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'sc';
  IF v_lower <> 124 OR v_upper <> 46 THEN
    RAISE EXCEPTION 'SC-2 structure: expected 124 House / 46 Senate offices, got % / %', v_lower, v_upper;
  END IF;

  -- One office per district, and no district left without one. LEFT JOIN so a district with ZERO
  -- offices is caught too — an inner join would drop exactly the row being looked for.
  IF EXISTS (
    SELECT 1 FROM essentials.districts d
    LEFT JOIN essentials.offices o ON o.district_id = d.id
    WHERE lower(d.state) = 'sc' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER')
    GROUP BY d.id HAVING count(o.id) <> 1
  ) THEN
    RAISE EXCEPTION 'SC-2 structure: a South Carolina legislative district does not have exactly one office';
  END IF;

  SELECT count(DISTINCT o.chamber_id) INTO v_chambers
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'sc' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_chambers <> 2 THEN
    RAISE EXCEPTION 'SC-2 structure: South Carolina legislative offices span % chambers, expected exactly 2', v_chambers;
  END IF;

  SELECT count(*) INTO v_mistitled
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'sc'
    AND ((d.district_type::text = 'STATE_LOWER' AND o.title <> 'Representative')
      OR (d.district_type::text = 'STATE_UPPER' AND o.title <> 'Senator'));
  IF v_mistitled <> 0 THEN
    RAISE EXCEPTION 'SC-2 structure: % legislative office(s) carry the wrong title', v_mistitled;
  END IF;

  -- 🔴 THE COLLISION GATE. If anything here had matched on geo_id alone, a county would have
  -- picked up a legislative office. South Carolina's 46 COUNTY districts -- Richland '45079' and
  -- Horry '45051' among them -- must still hold exactly the offices they held before.
  SELECT count(*) INTO v_county
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'sc' AND d.district_type::text = 'COUNTY'
    AND o.title IN ('Representative','Senator');
  IF v_county <> 0 THEN
    RAISE EXCEPTION 'SC-2 structure: % South Carolina COUNTY district(s) picked up a legislative office — a geo_id-only join', v_county;
  END IF;

  RAISE NOTICE 'SC-2 structure OK: 2 chambers, 124 House + 46 Senate offices, 0 on a county';
END $$;

COMMIT;
`;

// ── CC_0126: occupancy ───────────────────────────────────────────────────────

const peopleRow = (s) =>
  `  (${s.external_id}, '${q(s.full_name)}', '${q(s.first_name)}', '${q(s.last_name)}', '{}'::text[])`;
const termRow = (s) => {
  const dated = DATED[s.code];
  const pid = s.reuse ? `'${s.reuse.politician_id}'::uuid` : 'NULL::uuid';
  const eid = s.reuse ? 'NULL::bigint' : `${s.external_id}::bigint`;
  const start = dated ? `'${dated.term_start}'::date` : 'NULL::date';
  return `  ('${s.geo_id}', '${s.districtType}', ${eid}, ${pid}, ${start}, '${dated ? dated.precision : 'unknown'}', '${dated ? dated.how : 'unknown'}')`;
};

const namesakeNotes = Object.entries(NAMESAKES)
  .map(([code, why]) => `--     ${code.padEnd(6)} ${why}`)
  .join('\n');
const reuseNotes = Object.entries(REUSE)
  .map(([code, r]) => `--     ${code.padEnd(6)} ${r.note} (${r.politician_id})`)
  .join('\n');
const datedList = seats
  .filter((s) => s.term_start)
  .map((s) => `--     ${s.code.padEnd(6)} ${s.term_start}  ${s.full_name}`)
  .join('\n');

const occupancy = `-- CC_0126_sc_legislature_incumbents.sql
-- Knight Foundation program, wave SC-2 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0125, which creates the chambers and the 170 offices.
--
-- Seats all 170 of South Carolina's legislative offices:
--    ${created.length} people created here, external_id band ${BAND_FROM} .. ${BAND_TO}
--    ${Object.keys(REUSE).length} person REUSED from a row production already holds
--    0 offices left unseated — neither chamber has a vacancy today
--
-- 🔴🔴 ${Object.keys(DATED).length} TERMS ARE DATED, AND THE DATE IS THE OATH, NOT THE ELECTION. A member page that
-- says "Elected in Special Election June 3, 2025" is not saying when that person took the seat:
-- HD-50's oath was administered on 2026-01-13, SEVEN MONTHS later, because the House was not
-- sitting in between. A member-elect is not a member. Every date below was read out of that
-- chamber's own journal by scripts/find-sc-oath-dates.mjs:
${datedList}
--
-- 🔴 THE REMAINING ${seats.length - Object.keys(DATED).length} SEATS HAVE NO term_start TO BE HAD, AND NONE IS INVENTED. Neither
-- chamber publishes a service-start date for a member who arrived at a general election, and
-- "first elected" is not a term start in either direction. Those terms are written OPEN-ENDED
-- with start_precision 'unknown', the GA-2 / IN-2 / MN-2 / PA-2 pattern.
-- essentials.seat_officeholder() is NOT used: it refuses a NULL term_start by design.
--
-- ⚠ SD-26's page carries an arrival line too — "Elected in Special Election October 29, 2013" —
-- and it is NOT used. That line dates a HOUSE seat he held ten years before entering the Senate;
-- 78 Senate journal days record no oath for him. An arrival line on a member page can belong to
-- the other chamber, and running the search against the chamber the member sits in TODAY is what
-- catches it.
--
-- 🔴 NO term_end IS WRITTEN. A future term_end makes a seat silently self-vacate. SD-15's holder
-- has signed an irrevocable resignation effective 2026-11-03; he is seated here without an end
-- date, and closing that term on the day is a recorded debt, not a thing to write early.
--
-- 🔴 PARTY IS NOT WRITTEN. All three sources carry it; party lives on races.primary_party.
--
-- 🔴🔴 THREE NAME COLLISIONS, AND ONE OF THEM IS INSIDE THIS WAVE. Each was READ before it was
-- classified. TWO roster names match a row production already held; the THIRD is a collision
-- between two rows this migration creates — HD-14 Luke S. Rankin and SD-33 Luke A. Rankin are two
-- different sitting legislators who share a first and last name, so the House row makes the
-- Senate row a duplicate of a person who did not exist when this wave began. A pre-flight that
-- compares the roster only against PRODUCTION cannot see that; the generator now asserts the
-- armed set does not collide with itself.
--
--   SAME PERSON, ROW REUSED (no insert):
${reuseNotes}
--
--   DIFFERENT PEOPLE, INSERTED WITH THE GUARD DELIBERATELY LIFTED:
${namesakeNotes}
--
-- ⚠ THE GUARD IS LIFTED FOR ${lifted.length} ROWS, NOT FOR THE MIGRATION. essentials.politicians carries a
-- BEFORE INSERT trigger that refuses a name an active row already holds. The ${armed.length} rows with no
-- namesake are inserted with it ARMED, so a namesake nobody anticipated still stops this
-- migration. Only then is essentials.allow_duplicate_name set to 'on', for the rows named above.
--
-- 🔴 THE (first_name, last_name) PAIR IS NOT THE ONLY PASS RUN. Matching the roster on the exact
-- pair found TWO existing rows. A second pass on SURNAME ALONE, restricted to rows with any South
-- Carolina connection, found three more -- James E. Clyburn, Lindsey Graham and Tim Scott, all
-- federal officials and all different people from the state legislators who share those surnames.
-- PA-2 paid for this pass: there, one of the surname-only hits WAS the same person.
--
-- Idempotent: people are NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).
-- Ends with a post-verify gate that counts och.politician_id, never count(*), because
-- office_current_holder LEFT JOINs from offices and a vacancy is a NULL politician_id.

BEGIN;

-- ─── ${armed.length} people with no active namesake — guard ARMED ──────────────────────────────

CREATE TEMP TABLE sc_new_people(external_id bigint, full_name text, first_name text, last_name text, alternate_names text[])
  ON COMMIT DROP;
INSERT INTO sc_new_people(external_id, full_name, first_name, last_name, alternate_names) VALUES
${armed.map(peopleRow).join(',\n')};

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, '${q(SOURCE)} (CC_0126, SC-2)', n.alternate_names
FROM sc_new_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── ${lifted.length} people who share a name with a DIFFERENT person — guard lifted ─────────

SET LOCAL essentials.allow_duplicate_name = 'on';

CREATE TEMP TABLE sc_namesake_people(external_id bigint, full_name text, first_name text, last_name text, alternate_names text[])
  ON COMMIT DROP;
INSERT INTO sc_namesake_people(external_id, full_name, first_name, last_name, alternate_names) VALUES
${lifted.map(peopleRow).join(',\n')};

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, '${q(SOURCE)} (CC_0126, SC-2)', n.alternate_names
FROM sc_namesake_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

SET LOCAL essentials.allow_duplicate_name = 'off';

-- ─── 170 terms, one per office ────────────────────────────────────────────────
-- Each row carries EITHER an external_id (a person created above) or a politician_id (a row
-- production already held). The join below accepts one or the other and nothing else.

CREATE TEMP TABLE sc_terms(geo_id text, district_type text, external_id bigint, politician_id uuid,
                           term_start date, start_precision text, how_started text)
  ON COMMIT DROP;
INSERT INTO sc_terms(geo_id, district_type, external_id, politician_id, term_start, start_precision, how_started) VALUES
${seats.map(termRow).join(',\n')};

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, t.how_started, '${q(SOURCE)} (CC_0126, SC-2)'
FROM sc_terms t
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.district_type::text = t.district_type AND lower(d.state) = 'sc'
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.politicians p
  ON (t.politician_id IS NOT NULL AND p.id = t.politician_id)
  OR (t.external_id  IS NOT NULL AND p.external_id = t.external_id)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.id AND ot.politician_id = p.id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_people   int;
  v_offices  int;
  v_terms    int;
  v_seated   int;
  v_dated    int;
  v_ended    int;
  v_fanout   int;
  v_reuse    int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN ${BAND_FROM} AND ${BAND_TO};
  IF v_people <> ${created.length} THEN
    RAISE EXCEPTION 'SC-2 occupancy: expected ${created.length} people in the reserved band, got %', v_people;
  END IF;

  SELECT count(*) INTO v_offices
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'sc' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_offices <> 170 THEN
    RAISE EXCEPTION 'SC-2 occupancy: expected 170 South Carolina legislative offices, got %', v_offices;
  END IF;

  SELECT count(*) INTO v_terms
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'sc' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_terms <> 170 THEN
    RAISE EXCEPTION 'SC-2 occupancy: expected 170 terms, got %', v_terms;
  END IF;

  -- 🔴 COUNT och.politician_id, NEVER count(*). office_current_holder LEFT JOINs from offices,
  -- so an unseated office is a row with a NULL politician_id and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_seated
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE lower(d.state) = 'sc' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_seated <> 170 THEN
    RAISE EXCEPTION 'SC-2 occupancy: expected 170 seated offices, got %', v_seated;
  END IF;

  SELECT count(*) INTO v_dated
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'sc' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER')
    AND ot.term_start IS NOT NULL;
  IF v_dated <> ${Object.keys(DATED).length} THEN
    RAISE EXCEPTION 'SC-2 occupancy: expected ${Object.keys(DATED).length} dated term(s), got %', v_dated;
  END IF;

  -- The anchor: HD-50, elected 2025-06-03 and sworn 2026-01-13. If this row ever carries the
  -- ELECTION date, the wave has written a seven-month overstatement.
  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE lower(d.state) = 'sc' AND d.district_type::text = 'STATE_LOWER' AND d.geo_id = '${ANCHOR.geo_id}'
      AND ot.term_start = DATE '${ANCHOR.term_start}' AND ot.start_precision = 'day'
  ) THEN
    RAISE EXCEPTION 'SC-2 occupancy: HD-50 is not seated from ${ANCHOR.term_start} at day precision — the OATH date, not the election';
  END IF;

  SELECT count(*) INTO v_ended
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'sc' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER')
    AND ot.term_end IS NOT NULL;
  IF v_ended <> 0 THEN
    RAISE EXCEPTION 'SC-2 occupancy: % term(s) carry a term_end — a future end date self-vacates a seat', v_ended;
  END IF;

  -- 🔴 NOBODY SEATED HERE HOLDS TWO SOUTH CAROLINA LEGISLATIVE SEATS. The exclusion constraint on
  -- office_terms forbids two people on one office; it CANNOT see one person on two, which is the
  -- direction that fans a politician-rooted join out.
  SELECT count(*) INTO v_fanout FROM (
    SELECT ot.politician_id
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE lower(d.state) = 'sc' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER')
    GROUP BY ot.politician_id HAVING count(*) > 1
  ) x;
  IF v_fanout <> 0 THEN
    RAISE EXCEPTION 'SC-2 occupancy: % person(s) hold more than one South Carolina legislative seat', v_fanout;
  END IF;

  -- The reuse actually reused: SD-15 must be held by the EXISTING row, not by a second Wes Climer.
  SELECT count(*) INTO v_reuse
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'sc' AND d.district_type::text = 'STATE_UPPER' AND d.geo_id = '45015'
    AND ot.politician_id = '${REUSE['S-15'].politician_id}';
  IF v_reuse <> 1 THEN
    RAISE EXCEPTION 'SC-2 occupancy: SD-15 is not held by the existing Wes Climer row (got %)', v_reuse;
  END IF;

  RAISE NOTICE 'SC-2 occupancy OK: 170 offices, 170 terms, 170 seated, ${Object.keys(DATED).length} dated, 0 ended, 1 reused';
END $$;

COMMIT;
`;

fs.writeFileSync(path.join(MIGRATIONS, 'CC_0125_sc_legislature_structure.sql'), structure);
fs.writeFileSync(path.join(MIGRATIONS, 'CC_0126_sc_legislature_incumbents.sql'), occupancy);
console.log('CC_0125: 2 chambers, 170 offices');
console.log(
  `CC_0126: ${armed.length} people guard-armed + ${lifted.length} guard-lifted + ${Object.keys(REUSE).length} reused = ${seats.length} seats`,
);
console.log(
  `         external_id band ${BAND_FROM} .. ${BAND_TO}, ${created.length} used (${next + 1} is the lowest assigned)`,
);
console.log(`         ${Object.keys(DATED).length} dated terms, anchored on ${ANCHOR.code} = ${ANCHOR.term_start}`);
