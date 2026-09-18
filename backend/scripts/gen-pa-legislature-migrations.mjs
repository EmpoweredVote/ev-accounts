#!/usr/bin/env node
/**
 * gen-pa-legislature-migrations.mjs — Knight program, wave PA-2.
 *
 * Reads data/pa-legislature-roster.json (written by build-pa-legislature-roster.mjs) and emits
 * the two migrations, so that 253 hand-typed seats are impossible:
 *
 *   migrations/CC_0119_pa_legislature_structure.sql    2 chambers + 253 offices
 *   migrations/CC_0120_pa_legislature_incumbents.sql   253 seated, 252 people created + 1 reused
 *
 * Both slots were RESERVED from the allocator (`steward slot CC`). Numbers are never counted.
 *
 * Reads nothing from the database and writes nothing to it.
 */
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROSTER = path.join(HERE, '..', 'data', 'pa-legislature-roster.json');
const MIGRATIONS = path.join(HERE, '..', 'migrations');

const GOV = 'a3dc099e-039d-4df0-9e83-1bd8f08b09d4'; // 'State of Pennsylvania', type STATE, geo_id 42 — the ONLY such row
const BAND_FROM = -2742260;
const BAND_TO = -2742001;

const SOURCE = 'Pennsylvania General Assembly member lists, '
  + 'https://www.legis.state.pa.us/cfdocs/legis/home/member_information/mbrList.cfm (body=H and body=S); '
  + 'reconciled against Open States, https://data.openstates.org/people/current/pa.csv, and against '
  + 'PennDOT\'\'s own district layers via PASDA; change-checked against all 253 individual member '
  + 'pages, read 2026-09-18 (PA-2)';

/** Seats whose person already exists in production. READ before classified — a shared surname is
 *  never the answer on its own, and 2 of 4 name hits in the Georgia wave were other states'
 *  officials. */
const REUSE = {
  // HD-200 Christopher M. Rabb IS the existing 'Chris Rabb' row: that row is a candidate in the
  // PA 3rd congressional district race, and Rabb is the sitting representative for the 200th
  // running for Congress. A sitting legislator running for a different seat is ONE person with
  // two roles — the MN-2 Eric Pratt / Kaela Berg shape. The existing row also carries a photo,
  // which a second row would not.
  // ⚠ The existing row is named 'Chris Rabb' and the chamber renders him 'Christopher M. Rabb'.
  // The name is NOT changed here: it is a voter-facing field on a row already displayed as a
  // candidate, and a rename is its own decision with its own evidence.
  'H-200': { politician_id: '013bf70b-627c-4699-b11d-67924e6916a2', note: 'Chris Rabb, existing PA-3 congressional candidate row' },
};

/** Seats whose name collides with a DIFFERENT person's active row. The duplicate-name guard is
 *  lifted for THESE ROWS, never for the migration. */
const NAMESAKES = {
  'H-74': 'The existing Dan Williams (external_id -1211107) is a CANDIDATE FOR U.S. REPRESENTATIVE IN FLORIDA\'\'S 11TH DISTRICT, election 2026-11-03. The roster Dan K. Williams is the representative for Pennsylvania House 74. Different state, different office, different person.',
  'H-202': 'The existing Jared Solomon (external_id -2420054) holds DELEGATE, MARYLAND state legislative district 18. The roster Jared G. Solomon is the representative for Pennsylvania House 202, Philadelphia. Two state legislators of the same name in two states.',
};

/** Seats whose arrival date is documented. Everything else is written open-ended at
 *  start_precision 'unknown' — see the migration header. */
const DATED = {
  'H-12': {
    term_start: '2026-09-08',
    precision: 'day',
    how: 'elected',
    note: 'Brandon Dukes won the 2026-08-18 SPECIAL election for the seat Stephenie Scialabba resigned in March 2026, and was sworn in on 2026-09-08. The date is the SWEARING-IN, not the election and not "first elected".',
  },
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
if (seats.length !== 253) throw new Error(`expected 253 seats, roster has ${seats.length}`);

// ── assign external_ids to everyone who is not a reuse ───────────────────────
let next = BAND_TO; // walk downward from -2742001
const created = [];
for (const s of seats) {
  if (REUSE[s.code]) { s.reuse = REUSE[s.code]; continue; }
  s.external_id = next--;
  created.push(s);
}
if (next < BAND_FROM) throw new Error(`external_id band exhausted: needed ${created.length}`);
const armed = created.filter((s) => !NAMESAKES[s.code]);
const lifted = created.filter((s) => NAMESAKES[s.code]);

// ── CC_0119: structure ───────────────────────────────────────────────────────

const structure = `-- CC_0119_pa_legislature_structure.sql
-- Knight Foundation program, wave PA-2 (structure half). Slot RESERVED from the allocator.
--
-- Pennsylvania has NO state legislative offices and NO legislative chambers today: production
-- holds 23 PA offices in total -- 17 US House, 2 US Senate, 4 statewide executives. PA-1 loaded
-- the geography (203 STATE_LOWER + 50 STATE_UPPER, the 2022 LRC Final Plan, vintage-proved
-- against PennDOT on all 253 polygons), so this migration is a clean seed with nothing to
-- repair. It:
--
--   1. creates the two chambers;
--   2. creates 253 offices, one per district PA-1 loaded.
--
-- Creates NO people and NO terms -- CC_0120 does that, and the two are applied back to back.
--
-- 🔴 THE JOIN KEY IS (geo_id, district_type), NEVER geo_id ALONE. '42101' is House District 101
-- AND Philadelphia County: ALL 67 of Pennsylvania's counties share a geo_id string with a House
-- district, 25 also with a Senate district, and every Senate id is also a House id. Nothing here
-- matches on a number or a label; the office insert joins districts by district_type and state.
--
-- 🟢 THE HOST GOVERNMENT IS NOT AMBIGUOUS, AND THAT WAS CHECKED. Production holds exactly ONE
-- 'State of Pennsylvania' row, ${GOV} (type STATE, state PA, geo_id 42).
-- Indiana's 18 indistinguishable government rows do NOT recur here, and the gate below asserts it.
--
-- 🟢 NO SEAT IS VACANT. All 203 House and all 50 Senate districts carry a member: each chamber's
-- own list shows no hole, Open States agrees on all 253, and all 253 individual member pages were
-- read and every one names the member the list assigned to that district. HD-12 turned over six
-- weeks ago (see CC_0120) and the list already carries the successor.
--
-- 🔴 EVERY HOUSE SEAT AND HALF THE SENATE ARE ON THE 2026-11-03 BALLOT. Re-run the change-check
-- before applying if this slips past early November: a certified result is not a fact about who
-- holds a seat, but a sworn-in successor is.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 1. The two chambers ──────────────────────────────────────────────────────
-- term_length: Pa. Const. art. II s 3 -- Representatives two years, Senators four.

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT '${GOV}', 'Pennsylvania House of Representatives', 'Pennsylvania House of Representatives', 203, '2'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = '${GOV}' AND name = 'Pennsylvania House of Representatives');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT '${GOV}', 'Pennsylvania Senate', 'Pennsylvania Senate', 50, '4'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = '${GOV}' AND name = 'Pennsylvania Senate');

-- ─── 2. The 253 offices, one per district PA-1 loaded ─────────────────────────
-- Guarded on district_id: Pennsylvania has no legislative office at all today, so this inserts
-- 253 on a first run and 0 on any re-run.

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, ch.title, 'PA', 1, false, 'full'
FROM essentials.districts d
JOIN (VALUES
  ('STATE_LOWER', 'Pennsylvania House of Representatives', 'Representative'),
  ('STATE_UPPER', 'Pennsylvania Senate', 'Senator')
) AS ch(district_type, chamber_name, title) ON ch.district_type = d.district_type::text
JOIN essentials.chambers c ON c.government_id = '${GOV}' AND c.name = ch.chamber_name
WHERE lower(d.state) = 'pa'
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
   WHERE id = '${GOV}' AND name = 'State of Pennsylvania' AND type = 'STATE' AND state = 'PA';
  IF v_gov <> 1 THEN
    RAISE EXCEPTION 'PA-2 structure: the State of Pennsylvania government row is not what this migration assumed (got %)', v_gov;
  END IF;

  SELECT count(*) FILTER (WHERE name = 'Pennsylvania House of Representatives'),
         count(*) FILTER (WHERE name = 'Pennsylvania Senate')
    INTO v_house_ch, v_senate_ch
  FROM essentials.chambers WHERE government_id = '${GOV}';
  IF v_house_ch <> 1 OR v_senate_ch <> 1 THEN
    RAISE EXCEPTION 'PA-2 structure: expected exactly 1 House chamber (got %) and 1 Senate chamber (got %)',
      v_house_ch, v_senate_ch;
  END IF;

  SELECT count(*) FILTER (WHERE d.district_type::text = 'STATE_LOWER'),
         count(*) FILTER (WHERE d.district_type::text = 'STATE_UPPER')
    INTO v_lower, v_upper
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'pa';
  IF v_lower <> 203 OR v_upper <> 50 THEN
    RAISE EXCEPTION 'PA-2 structure: expected 203 House / 50 Senate offices, got % / %', v_lower, v_upper;
  END IF;

  -- One office per district, and no district left without one. LEFT JOIN so a district with ZERO
  -- offices is caught too — an inner join would drop exactly the row being looked for.
  IF EXISTS (
    SELECT 1 FROM essentials.districts d
    LEFT JOIN essentials.offices o ON o.district_id = d.id
    WHERE lower(d.state) = 'pa' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER')
    GROUP BY d.id HAVING count(o.id) <> 1
  ) THEN
    RAISE EXCEPTION 'PA-2 structure: a Pennsylvania legislative district does not have exactly one office';
  END IF;

  SELECT count(DISTINCT o.chamber_id) INTO v_chambers
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'pa' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_chambers <> 2 THEN
    RAISE EXCEPTION 'PA-2 structure: Pennsylvania legislative offices span % chambers, expected exactly 2', v_chambers;
  END IF;

  SELECT count(*) INTO v_mistitled
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'pa'
    AND ((d.district_type::text = 'STATE_LOWER' AND o.title <> 'Representative')
      OR (d.district_type::text = 'STATE_UPPER' AND o.title <> 'Senator'));
  IF v_mistitled <> 0 THEN
    RAISE EXCEPTION 'PA-2 structure: % legislative office(s) carry the wrong title', v_mistitled;
  END IF;

  -- 🔴 THE COLLISION GATE. If anything in this migration had matched on geo_id alone, a county
  -- would have picked up a legislative office. Pennsylvania's 67 COUNTY districts must still hold
  -- exactly the offices they held before: none of them is a legislative seat.
  SELECT count(*) INTO v_county
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'pa' AND d.district_type::text = 'COUNTY'
    AND o.title IN ('Representative','Senator');
  IF v_county <> 0 THEN
    RAISE EXCEPTION 'PA-2 structure: % Pennsylvania COUNTY district(s) picked up a legislative office — a geo_id-only join', v_county;
  END IF;

  RAISE NOTICE 'PA-2 structure OK: 2 chambers, 203 House + 50 Senate offices, 0 on a county';
END $$;

COMMIT;
`;

// ── CC_0120: occupancy ───────────────────────────────────────────────────────

const peopleRow = (s) => `  (${s.external_id}, '${q(s.full_name)}', '${q(s.first_name)}', '${q(s.last_name)}', '{}'::text[])`;
const termRow = (s) => {
  const dated = DATED[s.code];
  const pid = s.reuse ? `'${s.reuse.politician_id}'::uuid` : 'NULL::uuid';
  const eid = s.reuse ? 'NULL::bigint' : `${s.external_id}::bigint`;
  const start = dated ? `'${dated.term_start}'::date` : 'NULL::date';
  return `  ('${s.geo_id}', '${s.districtType}', ${eid}, ${pid}, ${start}, '${dated ? dated.precision : 'unknown'}', '${dated ? dated.how : 'unknown'}')`;
};

const namesakeNotes = Object.entries(NAMESAKES)
  .map(([code, why]) => `--     ${code.padEnd(6)} ${why}`).join('\n');
const reuseNotes = Object.entries(REUSE)
  .map(([code, r]) => `--     ${code.padEnd(6)} ${r.note} (${r.politician_id})`).join('\n');
const datedNotes = Object.entries(DATED)
  .map(([code, d]) => `--     ${code.padEnd(6)} ${d.term_start} (${d.precision}) — ${d.note}`).join('\n');

const occupancy = `-- CC_0120_pa_legislature_incumbents.sql
-- Knight Foundation program, wave PA-2 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0119, which creates the chambers and the 253 offices.
--
-- Seats all 253 of Pennsylvania's legislative offices:
--    ${created.length} people created here, external_id band ${BAND_FROM} .. ${BAND_TO}
--    ${Object.keys(REUSE).length} person REUSED from a row production already holds
--    0 offices left unseated — neither chamber has a vacancy today
--
-- 🔴 THERE IS NO term_start TO BE HAD FOR 252 SEATS, AND NONE IS INVENTED. Neither chamber
-- publishes service dates: the member pages carry a biography and no dates at all, on a
-- first-term member and on a 26-year veteran alike, and there is no member-history endpoint
-- (four candidate URLs all 404). A constitutional first-Tuesday-in-December date would be
-- positively WRONG for anyone who arrived at a special election — HD-12 is exactly that case —
-- and is not a fact about the others either. Terms are written OPEN-ENDED with start_precision
-- 'unknown', the GA-2 / IN-2 / MN-2 pattern.
-- essentials.seat_officeholder() is NOT used: it refuses a NULL term_start by design.
--
-- 🟢 THE ONE DOCUMENTED ARRIVAL IS WRITTEN AT DAY PRECISION:
${datedNotes}
--
-- 🔴 NO term_end IS WRITTEN. A future term_end makes a seat silently self-vacate.
--
-- 🔴 PARTY IS NOT WRITTEN. All three sources carry it; party lives on races.primary_party.
--
-- 🔴🔴 THREE ROSTER NAMES MATCH AN EXISTING ROW, AND THEY SPLIT TWO WAYS. Each was READ before it
-- was classified.
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
-- 🔴🔴 THE (first_name, last_name) GUARD IS NOT ENOUGH ON ITS OWN, AND THAT IS MEASURED. Matching
-- the roster on the exact pair found TWO existing rows. A second pass matching on SURNAME ALONE,
-- restricted to rows with any Pennsylvania connection, found THREE MORE — and one of them,
-- 'Chris Rabb' against the chamber's 'Christopher M. Rabb', is the same person. A diminutive
-- defeats the pair guard exactly the way MN-2's Steve/Steven did. A punctuation-blind pass over
-- the same population found nothing further.
--
-- Idempotent: people are NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).
-- Ends with a post-verify gate that counts och.politician_id, never count(*), because
-- office_current_holder LEFT JOINs from offices and a vacancy is a NULL politician_id.

BEGIN;

-- ─── ${armed.length} people with no active namesake — guard ARMED ──────────────────────────────

CREATE TEMP TABLE pa_new_people(external_id bigint, full_name text, first_name text, last_name text, alternate_names text[])
  ON COMMIT DROP;
INSERT INTO pa_new_people(external_id, full_name, first_name, last_name, alternate_names) VALUES
${armed.map(peopleRow).join(',\n')};

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, '${SOURCE} (CC_0120, PA-2)', n.alternate_names
FROM pa_new_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── ${lifted.length} people who share a name with a DIFFERENT person — guard lifted ──────────

SET LOCAL essentials.allow_duplicate_name = 'on';

CREATE TEMP TABLE pa_namesake_people(external_id bigint, full_name text, first_name text, last_name text, alternate_names text[])
  ON COMMIT DROP;
INSERT INTO pa_namesake_people(external_id, full_name, first_name, last_name, alternate_names) VALUES
${lifted.map(peopleRow).join(',\n')};

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, '${SOURCE} (CC_0120, PA-2)', n.alternate_names
FROM pa_namesake_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

SET LOCAL essentials.allow_duplicate_name = 'off';

-- ─── 253 terms, one per office ────────────────────────────────────────────────
-- Each row carries EITHER an external_id (a person created above) or a politician_id (a row
-- production already held). The join below accepts one or the other and nothing else.

CREATE TEMP TABLE pa_terms(geo_id text, district_type text, external_id bigint, politician_id uuid,
                           term_start date, start_precision text, how_started text)
  ON COMMIT DROP;
INSERT INTO pa_terms(geo_id, district_type, external_id, politician_id, term_start, start_precision, how_started) VALUES
${seats.map(termRow).join(',\n')};

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, t.term_start, NULL, t.start_precision, t.how_started, '${SOURCE} (CC_0120, PA-2)'
FROM pa_terms t
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.district_type::text = t.district_type AND lower(d.state) = 'pa'
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
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN ${BAND_FROM} AND ${BAND_TO};
  IF v_people <> ${created.length} THEN
    RAISE EXCEPTION 'PA-2 occupancy: expected ${created.length} people in the reserved band, got %', v_people;
  END IF;

  SELECT count(*) INTO v_offices
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'pa' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_offices <> 253 THEN
    RAISE EXCEPTION 'PA-2 occupancy: expected 253 Pennsylvania legislative offices, got %', v_offices;
  END IF;

  SELECT count(*) INTO v_terms
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'pa' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_terms <> 253 THEN
    RAISE EXCEPTION 'PA-2 occupancy: expected 253 terms, got %', v_terms;
  END IF;

  -- 🔴 COUNT och.politician_id, NEVER count(*). office_current_holder LEFT JOINs from offices,
  -- so an unseated office is a row with a NULL politician_id and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_seated
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE lower(d.state) = 'pa' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_seated <> 253 THEN
    RAISE EXCEPTION 'PA-2 occupancy: expected 253 seated offices, got %', v_seated;
  END IF;

  -- Exactly one dated term, and it is HD-12's.
  SELECT count(*) INTO v_dated
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'pa' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER')
    AND ot.term_start IS NOT NULL;
  IF v_dated <> ${Object.keys(DATED).length} THEN
    RAISE EXCEPTION 'PA-2 occupancy: expected ${Object.keys(DATED).length} dated term(s), got %', v_dated;
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE lower(d.state) = 'pa' AND d.district_type::text = 'STATE_LOWER' AND d.geo_id = '42012'
      AND ot.term_start = DATE '2026-09-08' AND ot.start_precision = 'day'
  ) THEN
    RAISE EXCEPTION 'PA-2 occupancy: HD-12 is not seated from 2026-09-08 at day precision';
  END IF;

  SELECT count(*) INTO v_ended
  FROM essentials.office_terms ot
  JOIN essentials.offices o ON o.id = ot.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'pa' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER')
    AND ot.term_end IS NOT NULL;
  IF v_ended <> 0 THEN
    RAISE EXCEPTION 'PA-2 occupancy: % term(s) carry a term_end — a future end date self-vacates a seat', v_ended;
  END IF;

  -- 🔴 NOBODY SEATED HERE HOLDS TWO PENNSYLVANIA LEGISLATIVE SEATS. The exclusion constraint on
  -- office_terms forbids two people on one office; it CANNOT see one person on two, which is the
  -- direction that fans a politician-rooted join out.
  SELECT count(*) INTO v_fanout FROM (
    SELECT ot.politician_id
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE lower(d.state) = 'pa' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER')
    GROUP BY ot.politician_id HAVING count(*) > 1
  ) x;
  IF v_fanout <> 0 THEN
    RAISE EXCEPTION 'PA-2 occupancy: % person(s) hold more than one Pennsylvania legislative seat', v_fanout;
  END IF;

  RAISE NOTICE 'PA-2 occupancy OK: 253 offices, 253 terms, 253 seated, 1 dated, 0 ended';
END $$;

COMMIT;
`;

fs.writeFileSync(path.join(MIGRATIONS, 'CC_0119_pa_legislature_structure.sql'), structure);
fs.writeFileSync(path.join(MIGRATIONS, 'CC_0120_pa_legislature_incumbents.sql'), occupancy);
console.log(`CC_0119: 2 chambers, 253 offices`);
console.log(`CC_0120: ${armed.length} people guard-armed + ${lifted.length} guard-lifted + ${Object.keys(REUSE).length} reused = 253 seats`);
console.log(`         external_id band ${BAND_FROM} .. ${BAND_TO}, ${created.length} used (${next + 1} is the lowest assigned)`);
