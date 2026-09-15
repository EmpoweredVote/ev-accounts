#!/usr/bin/env node
/**
 * gen-mn-legislature-migrations.mjs
 *
 * Emits the two MN-2 migrations from data/mn-legislature-roster.json, so the 201-row payload
 * carries no transcription risk:
 *
 *   migrations/CC_0107_mn_legislature_structure.sql    2 chambers + 201 offices, HD-21A vacant
 *   migrations/CC_0108_mn_legislature_incumbents.sql   198 people + 2 reused + 200 terms
 *
 * Both slots were RESERVED from the allocator (`steward slot CC`), never counted.
 * Reads nothing from the database and writes nothing to it.
 *
 *   node scripts/gen-mn-legislature-migrations.mjs
 */
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROSTER = path.join(HERE, '..', 'data', 'mn-legislature-roster.json');
const MIG = path.join(HERE, '..', 'migrations');

const GOV_ID = 'b610e3f3-0ffa-4450-9ce8-f695ce7926a0'; // the ONE 'State of Minnesota' row
const CHAMBERS = {
  STATE_LOWER: { name: 'Minnesota House of Representatives', title: 'Representative', seats: 134, term_length: '2' },
  STATE_UPPER: { name: 'Minnesota Senate', title: 'Senator', seats: 67, term_length: '4' },
};

/** Free band, measured 2026-09-14: 0 rows between -2732001 and -2732999. */
const BAND_LO = -2732201;
const BAND_HI = -2732001;

/**
 * Production already holds an ACTIVE politician with each of these (first_name, last_name)
 * pairs, and essentials.politician_name_duplicate_guard blocks the insert. Every one was read
 * before it was classified; "same surname" is never the answer on its own.
 */
const NAMESAKES = {
  // SAME PERSON -> reuse the existing row, create nothing.
  reuse: {
    '55B': {
      id: 'a89ba4b9-a684-40a6-b5ec-db0876a65b8d',
      name: 'Kaela Berg',
      why: 'The existing row is a candidate in the MN 2nd congressional district race (external_id -270203). Kaela Berg represents Burnsville in the Minnesota House (55B) and ran in the MN-02 DFL primary on 2026-08-11. A sitting legislator running for a different seat is one person with two roles.',
    },
    '54': {
      id: 'fa8d5cfb-5feb-4112-b68b-f1c2de963dc3',
      name: 'Eric Pratt',
      why: 'The existing row is a candidate in the same MN-02 race (external_id -270201). Eric Pratt is the sitting Minnesota senator for district 54 and the Republican nominee for MN-02. One person.',
    },
  },
  // DIFFERENT PEOPLE -> insert anyway, with the guard deliberately lifted for these rows only.
  distinct: {
    '20B': {
      collides_with: 'a969d5c4-056e-4f6d-b765-f656fbbb3a1a',
      why: 'The existing Steven Jacob (external_id -200105) is the LIBERTARIAN candidate for KANSAS 1st congressional district, from Lawrence, Kansas. The roster Steven Jacob is the Republican representative for Minnesota House 20B. Different state, different party, different person.',
    },
    '9B': {
      collides_with: 'f32cba1e-d672-440a-9a18-41a312119f40',
      why: 'The existing Tom Murphy (external_id -4014001) holds Mayor of the Town of Sahuarita, ARIZONA. The roster Tom Murphy is the representative for Minnesota House 9B.',
    },
    '64': {
      collides_with: 'c9419f85-8e38-4b64-a816-7b3caba5c674',
      why: 'The existing Erin J. Murphy (external_id -2507000004) holds City Councillor At-Large in Boston, MASSACHUSETTS. The roster Erin P. Murphy is the senator for Minnesota Senate 64. Different middle initial, different state, different office.',
    },
  },
};

/** '2026-06-22' -> '2026-06-21'. UTC arithmetic only; these are plain calendar dates. */
const dayBefore = (iso) => new Date(Date.parse(iso + 'T00:00:00Z') - 86400000).toISOString().slice(0, 10);

const sql = (v) => (v === null || v === undefined ? 'NULL' : `'${String(v).replace(/'/g, "''")}'`);
const arr = (a) => (a && a.length ? `ARRAY[${a.map(sql).join(', ')}]::text[]` : `'{}'::text[]`);

const roster = JSON.parse(fs.readFileSync(ROSTER, 'utf8'));
const seats = roster.roster;
const vacant = seats.filter((s) => s.vacant);
const seated = seats.filter((s) => !s.vacant);

const SOURCE = [
  'Minnesota House of Representatives member list, https://www.house.mn.gov/members/',
  'Minnesota Senate, https://www.senate.mn/api/members',
  'reconciled against Open States, https://data.openstates.org/people/current/mn.csv',
  'change-checked against all 201 individual member pages, read 2026-09-14 (MN-2)',
].join('; ');

// ── who gets a new row, and which id ──────────────────────────────────────────
const reuseByDistrict = NAMESAKES.reuse;
const newPeople = [];
let next = BAND_HI;
for (const s of seated) {
  if (reuseByDistrict[s.district]) continue;
  newPeople.push({ ...s, external_id: next-- });
}
if (next < BAND_LO - 1) throw new Error(`external_id band exhausted: needed ${newPeople.length}`);

// ═══════════════════════════════════════════════════════════════════════════════
// CC_0107 -- structure
// ═══════════════════════════════════════════════════════════════════════════════
const structure = `-- CC_0107_mn_legislature_structure.sql
-- Knight Foundation program, wave MN-2 (structure half). Slot RESERVED from the allocator.
--
-- Minnesota has NO state legislative offices and NO legislative chambers today. MN-1 loaded the
-- geography -- 67 STATE_UPPER and 134 STATE_LOWER districts, plan L2022, vintage-proved -- so
-- this migration is a clean seed with nothing to repair. It:
--
--   1. creates the two chambers;
--   2. creates 201 offices, one per existing district;
--   3. flags HD-21A vacant through essentials.vacate_office().
--
-- Creates NO people and NO terms -- CC_0108 does that, and the two are applied back to back.
--
-- 🔴 MINNESOTA HOUSE DISTRICTS ARE NOT INTEGERS. Each Senate district holds exactly two House
-- districts labelled \`NA\` and \`NB\`. The join key here is the TIGER geo_id -- \`2721A\` for House
-- 21A, \`27035\` for Senate 35 -- paired with district_type, never a number and never a label.
--
-- 🟢 THE HOST GOVERNMENT IS NOT AMBIGUOUS, AND THAT WAS CHECKED. Production holds exactly ONE
-- 'State of Minnesota' row, ${GOV_ID} (type STATE, state MN, geo_id 27).
-- Indiana's 22 indistinguishable government rows do NOT recur here.
--
-- 🔴 HD-21A IS VACANT AND THE DATE IS KNOWN. Joe Schomacker resigned effective 11:59 p.m. on
-- Sunday 2026-06-21, so the first vacant day is 2026-06-22. The House's own Session Daily
-- reports that no special election will be called; the seat is filled at the 2026-11-03 general.
-- vacate_office() is used rather than a hand-written UPDATE: with no open term it writes no span,
-- sets is_vacant and vacant_since, and is idempotent. NO vacancy span and NO person row is
-- written for Schomacker -- this wave seats who holds a seat today.
-- ⚠ GEORGIA'S SD-12 was flagged with a NULL vacant_since because only the ANNOUNCEMENT was
-- documented. Minnesota's date is documented, so it is written.
--
-- 🔴🔴 NEITHER CHAMBER'S ROSTER PAGE IS A CHANGE-CHECK. house.mn.gov/members/ still lists
-- Schomacker for 21A on 2026-09-14, three months after he left, and neither chamber publishes a
-- vacancy marker anywhere. The change-check is the 201 individual member pages.
--
-- 🔴 ALL 201 SEATS ARE ON THE 2026-11-03 BALLOT -- every House seat every two years, and the
-- Senate class elected in 2022 serves through 2026. Re-run the change-check before applying if
-- this slips past early November; a certified result is not a fact about who holds the seat.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded and vacate_office() is idempotent by
-- construction. Ends with a post-verify gate.

BEGIN;

-- ─── 1. The two chambers ──────────────────────────────────────────────────────
-- term_length: the House is two years. The Senate is four, except for the term beginning in the
-- year after a decennial census, which is two (Minn. Const. art. IV, s 4). The column records
-- the ordinary term.

${Object.values(CHAMBERS).map((c) => `INSERT INTO essentials.chambers (government_id, name, name_formal, official_count, term_length)
SELECT ${sql(GOV_ID)}, ${sql(c.name)}, ${sql(c.name)}, ${c.seats}, ${sql(c.term_length)}
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
  WHERE government_id = ${sql(GOV_ID)} AND name = ${sql(c.name)});`).join('\n\n')}

-- ─── 2. The 201 offices, one per district MN-1 loaded ─────────────────────────
-- Guarded on district_id: Minnesota has no legislative office at all today, so this inserts 201
-- on a first run and 0 on any re-run.

INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, ch.title, 'MN', 1, false, 'full'
FROM essentials.districts d
JOIN (VALUES
  ('STATE_LOWER', ${sql(CHAMBERS.STATE_LOWER.name)}, ${sql(CHAMBERS.STATE_LOWER.title)}),
  ('STATE_UPPER', ${sql(CHAMBERS.STATE_UPPER.name)}, ${sql(CHAMBERS.STATE_UPPER.title)})
) AS ch(district_type, chamber_name, title) ON ch.district_type = d.district_type::text
JOIN essentials.chambers c ON c.government_id = ${sql(GOV_ID)} AND c.name = ch.chamber_name
WHERE lower(d.state) = 'mn'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id);

-- ─── 3. HD-21A is vacant ──────────────────────────────────────────────────────
${vacant.map((v) => `-- ${v.district}: ${v.departed} left at the end of ${dayBefore(v.first_vacant_day)}, so ${v.first_vacant_day} is the first vacant day.
--   ${v.evidence.join('\n--   ')}
SELECT essentials.vacate_office(
         o.id,
         ${sql(v.first_vacant_day)}::date,
         ${sql(`${v.departed} resigned; ${v.evidence[1]} (CC_0107, MN-2)`)},
         ${sql(v.how_ended)})
FROM essentials.districts d
JOIN essentials.offices o ON o.district_id = d.id
WHERE lower(d.state) = 'mn' AND d.district_type::text = ${sql(v.chamber)} AND d.geo_id = ${sql(v.geo_id)};`).join('\n\n')}

-- ─── Post-verify gate ─────────────────────────────────────────────────────────

DO $$
DECLARE
  v_house_ch   int;
  v_senate_ch  int;
  v_lower      int;
  v_upper      int;
  v_chambers   int;
  v_mistitled  int;
  v_vacant     int;
  v_vsince     date;
BEGIN
  SELECT count(*) FILTER (WHERE name = ${sql(CHAMBERS.STATE_LOWER.name)}),
         count(*) FILTER (WHERE name = ${sql(CHAMBERS.STATE_UPPER.name)})
    INTO v_house_ch, v_senate_ch
  FROM essentials.chambers WHERE government_id = ${sql(GOV_ID)};
  IF v_house_ch <> 1 OR v_senate_ch <> 1 THEN
    RAISE EXCEPTION 'MN-2 structure: expected exactly 1 House chamber (got %) and 1 Senate chamber (got %)',
      v_house_ch, v_senate_ch;
  END IF;

  SELECT count(*) FILTER (WHERE d.district_type::text = 'STATE_LOWER'),
         count(*) FILTER (WHERE d.district_type::text = 'STATE_UPPER')
    INTO v_lower, v_upper
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'mn';
  IF v_lower <> ${CHAMBERS.STATE_LOWER.seats} OR v_upper <> ${CHAMBERS.STATE_UPPER.seats} THEN
    RAISE EXCEPTION 'MN-2 structure: expected ${CHAMBERS.STATE_LOWER.seats} House / ${CHAMBERS.STATE_UPPER.seats} Senate offices, got % / %', v_lower, v_upper;
  END IF;

  -- One office per district, and no district left without one. LEFT JOIN so a district with
  -- ZERO offices is caught too -- an inner join would drop exactly the row being looked for.
  IF EXISTS (
    SELECT 1 FROM essentials.districts d
    LEFT JOIN essentials.offices o ON o.district_id = d.id
    WHERE lower(d.state) = 'mn' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER')
    GROUP BY d.id HAVING count(o.id) <> 1
  ) THEN
    RAISE EXCEPTION 'MN-2 structure: a Minnesota legislative district does not have exactly one office';
  END IF;

  SELECT count(DISTINCT o.chamber_id) INTO v_chambers
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'mn' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_chambers <> 2 THEN
    RAISE EXCEPTION 'MN-2 structure: Minnesota legislative offices span % chambers, expected exactly 2', v_chambers;
  END IF;

  SELECT count(*) INTO v_mistitled
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'mn'
    AND ((d.district_type::text = 'STATE_LOWER' AND o.title <> ${sql(CHAMBERS.STATE_LOWER.title)})
      OR (d.district_type::text = 'STATE_UPPER' AND o.title <> ${sql(CHAMBERS.STATE_UPPER.title)}));
  IF v_mistitled <> 0 THEN
    RAISE EXCEPTION 'MN-2 structure: % Minnesota legislative offices carry a non-standard title', v_mistitled;
  END IF;

  -- Exactly one vacancy, on 21A, carrying the documented date.
  SELECT count(*) INTO v_vacant
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'mn' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER') AND o.is_vacant;
  IF v_vacant <> ${vacant.length} THEN
    RAISE EXCEPTION 'MN-2 structure: expected ${vacant.length} vacant Minnesota legislative office(s), got %', v_vacant;
  END IF;

  SELECT o.vacant_since::date INTO v_vsince
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'mn' AND d.geo_id = ${sql(vacant[0].geo_id)} AND d.district_type::text = ${sql(vacant[0].chamber)};
  IF v_vsince IS DISTINCT FROM ${sql(vacant[0].first_vacant_day)}::date THEN
    RAISE EXCEPTION 'MN-2 structure: HD-21A vacant_since is %, expected %', v_vsince, ${sql(vacant[0].first_vacant_day)}::date;
  END IF;

  -- A vacancy flag must not have written a span: nothing seats 21A, and no term row exists.
  IF EXISTS (
    SELECT 1 FROM essentials.office_terms t
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE lower(d.state) = 'mn' AND d.geo_id = ${sql(vacant[0].geo_id)} AND d.district_type::text = ${sql(vacant[0].chamber)}
  ) THEN
    RAISE EXCEPTION 'MN-2 structure: HD-21A carries an office_terms row; this migration writes none';
  END IF;

  RAISE NOTICE 'MN-2 structure OK: 2 chambers, % House + % Senate offices, % vacant (21A since %)',
    v_lower, v_upper, v_vacant, v_vsince;
END $$;

COMMIT;
`;

// ═══════════════════════════════════════════════════════════════════════════════
// CC_0108 -- occupancy
// ═══════════════════════════════════════════════════════════════════════════════
const distinctRows = seated.filter((s) => NAMESAKES.distinct[s.district]);
const plainRows = newPeople.filter((s) => !NAMESAKES.distinct[s.district]);
const distinctNew = newPeople.filter((s) => NAMESAKES.distinct[s.district]);

const peopleValues = (rows) => rows.map((r) =>
  `  (${r.external_id}, ${sql(r.full_name)}, ${sql(r.first_name)}, ${sql(r.last_name)}, ${arr(r.alternate_names)})`).join(',\n');

const termValues = seated.map((s) => {
  const reuse = reuseByDistrict[s.district];
  const person = newPeople.find((n) => n.district === s.district && n.chamber === s.chamber);
  return `  (${sql(s.geo_id)}, ${sql(s.chamber)}, ${reuse ? 'NULL::bigint' : `${person.external_id}::bigint`}, ${reuse ? `${sql(reuse.id)}::uuid` : 'NULL::uuid'})`;
}).join(',\n');

const occupancy = `-- CC_0108_mn_legislature_incumbents.sql
-- Knight Foundation program, wave MN-2 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0107, which creates the chambers and the 201 offices.
--
-- Seats ${seated.length} of Minnesota's 201 legislative offices:
--    ${newPeople.length} people created here, external_id band ${BAND_LO} .. ${BAND_HI}
--    ${Object.keys(reuseByDistrict).length} people REUSED from rows production already holds
--    ${vacant.length} office left unseated -- HD-21A, flagged vacant by CC_0107
--
-- 🔴 THERE IS NO term_start TO BE HAD, AND NONE IS INVENTED. The richest per-member pages either
-- chamber publishes give "Elected: 2010 / Term: 8th" (House) and "re-elected 2020, 2022 / Term:
-- 4th" (Senate) -- an election YEAR and an ordinal, never a date. The Legislative Reference
-- Library's legislator database gives biennia ("House 1971-72"), also not a date. At least six
-- sitting members took their seats at a 2025 SPECIAL election rather than at the start of the
-- biennium, so the constitutional first-Monday-in-January date would be positively wrong for
-- them and is not a fact about anyone else either. Every term is therefore written OPEN-ENDED
-- with start_precision 'unknown' -- the GA-2 and IN-2 pattern.
-- essentials.seat_officeholder() is NOT used: it refuses a NULL term_start by design.
--
-- 🔴 NO term_end IS WRITTEN. A future term_end makes a seat silently self-vacate.
--
-- 🔴 PARTY IS NOT WRITTEN. All three sources carry it; party lives on races.primary_party.
--
-- 🔴🔴 FIVE ROSTER NAMES COLLIDE WITH AN ACTIVE POLITICIAN ROW, AND THEY SPLIT TWO WAYS. Each was
-- READ before it was classified -- 2 of 4 name hits in the Georgia wave were a Colorado senator
-- and a Utah treasurer, so a shared surname is never the answer on its own.
--
--   SAME PERSON, ROW REUSED (no insert):
${Object.entries(reuseByDistrict).map(([d, r]) => `--     ${d.padEnd(4)} ${r.name} -- ${r.why}`).join('\n')}
--
--   DIFFERENT PEOPLE, INSERTED WITH THE GUARD DELIBERATELY LIFTED:
${Object.entries(NAMESAKES.distinct).map(([d, r]) => `--     ${d.padEnd(4)} -- ${r.why}`).join('\n')}
--
-- ⚠ THE GUARD IS LIFTED FOR THREE ROWS, NOT FOR THE MIGRATION. essentials.politicians carries a
-- BEFORE INSERT trigger that refuses a name an active row already holds. The ${plainRows.length} rows with no
-- namesake are inserted with it ARMED, so a namesake nobody anticipated still stops this
-- migration. Only then is essentials.allow_duplicate_name set to 'on', for the three rows named
-- above, and set back to 'off' immediately afterwards.
--
-- 🟢 first_name AND full_name COME FROM THE SAME SOURCE, WHICH IS LOAD-BEARING HERE. An earlier
-- draft of the roster builder took full_name from the chamber and first_name from Open States,
-- writing "Steven Jacob" with first_name "Steve". The guard keys on (first_name, last_name), so
-- that mismatch hid the Kansas Steven Jacob from the reuse search entirely.
--
-- 🟢 NAMES ARE HTML-DECODED. house.mn.gov encodes eight member names; \`Mar&#237;a Isa
-- P&#233;rez-Vega\` reaches a voter-facing field as mojibake if it is captured raw.
--
-- Idempotent: people are NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).
-- Ends with a post-verify gate that counts och.politician_id, never count(*), because
-- office_current_holder LEFT JOINs from offices and a vacancy is a NULL politician_id.

BEGIN;

-- ─── ${plainRows.length} people with no active namesake -- guard ARMED ──────────────────────────────

CREATE TEMP TABLE mn_new_people(external_id bigint, full_name text, first_name text, last_name text, alternate_names text[])
  ON COMMIT DROP;
INSERT INTO mn_new_people(external_id, full_name, first_name, last_name, alternate_names) VALUES
${peopleValues(plainRows)};

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, ${sql(SOURCE)}, n.alternate_names
FROM mn_new_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

-- ─── ${distinctNew.length} people who share a name with a DIFFERENT person -- guard lifted ──────────

SET LOCAL essentials.allow_duplicate_name = 'on';

CREATE TEMP TABLE mn_namesake_people(external_id bigint, full_name text, first_name text, last_name text, alternate_names text[])
  ON COMMIT DROP;
INSERT INTO mn_namesake_people(external_id, full_name, first_name, last_name, alternate_names) VALUES
${peopleValues(distinctNew)};

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source, alternate_names)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, ${sql(SOURCE)}, n.alternate_names
FROM mn_namesake_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

SET LOCAL essentials.allow_duplicate_name = 'off';

-- ─── ${seated.length} terms, one per seated office ────────────────────────────────────────

CREATE TEMP TABLE mn_terms(geo_id text, district_type text, external_id bigint, politician_id uuid)
  ON COMMIT DROP;
INSERT INTO mn_terms(geo_id, district_type, external_id, politician_id) VALUES
${termValues};

INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.id, p.id, NULL, NULL, 'unknown', 'unknown', ${sql(`${SOURCE} (CC_0108, MN-2)`)}
FROM mn_terms t
JOIN essentials.districts d
  ON d.geo_id = t.geo_id AND d.district_type::text = t.district_type AND lower(d.state) = 'mn'
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
  v_terms    int;
  v_seated   int;
  v_offices  int;
  v_dated    int;
  v_ended    int;
  v_vacseat  int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians
   WHERE external_id BETWEEN ${BAND_LO} AND ${BAND_HI};
  IF v_people <> ${newPeople.length} THEN
    RAISE EXCEPTION 'MN-2 occupancy: expected ${newPeople.length} people in the reserved band, got %', v_people;
  END IF;

  SELECT count(*) INTO v_offices
  FROM essentials.offices o JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'mn' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_offices <> ${seats.length} THEN
    RAISE EXCEPTION 'MN-2 occupancy: expected ${seats.length} Minnesota legislative offices, got %', v_offices;
  END IF;

  -- och.politician_id, never count(*): office_current_holder LEFT JOINs from offices, so a
  -- vacancy is a NULL politician_id and count(*) would pass vacuously.
  SELECT count(och.politician_id) INTO v_seated
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE lower(d.state) = 'mn' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_seated <> ${seated.length} THEN
    RAISE EXCEPTION 'MN-2 occupancy: expected ${seated.length} seated Minnesota legislative offices, got %', v_seated;
  END IF;

  SELECT count(*) INTO v_terms
  FROM essentials.office_terms t
  JOIN essentials.offices o ON o.id = t.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'mn' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_terms <> ${seated.length} THEN
    RAISE EXCEPTION 'MN-2 occupancy: expected ${seated.length} term rows, got %', v_terms;
  END IF;

  SELECT count(*) FILTER (WHERE t.term_start IS NOT NULL),
         count(*) FILTER (WHERE t.term_end IS NOT NULL)
    INTO v_dated, v_ended
  FROM essentials.office_terms t
  JOIN essentials.offices o ON o.id = t.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE lower(d.state) = 'mn' AND d.district_type::text IN ('STATE_LOWER','STATE_UPPER');
  IF v_dated <> 0 OR v_ended <> 0 THEN
    RAISE EXCEPTION 'MN-2 occupancy: % dated and % ended terms; every Minnesota term is open-ended and unknown', v_dated, v_ended;
  END IF;

  -- The vacant seat must still be vacant and still unseated.
  SELECT count(och.politician_id) INTO v_vacseat
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  WHERE lower(d.state) = 'mn' AND d.geo_id = ${sql(vacant[0].geo_id)} AND d.district_type::text = ${sql(vacant[0].chamber)};
  IF v_vacseat <> 0 THEN
    RAISE EXCEPTION 'MN-2 occupancy: HD-21A is seated by % holder(s); it is vacant', v_vacseat;
  END IF;

  RAISE NOTICE 'MN-2 occupancy OK: % people in band, % offices, % seated, % terms, % dated, % ended, 21A vacant',
    v_people, v_offices, v_seated, v_terms, v_dated, v_ended;
END $$;

COMMIT;
`;

fs.writeFileSync(path.join(MIG, 'CC_0107_mn_legislature_structure.sql'), structure);
fs.writeFileSync(path.join(MIG, 'CC_0108_mn_legislature_incumbents.sql'), occupancy);

console.log(`CC_0107_mn_legislature_structure.sql   2 chambers, ${seats.length} offices, ${vacant.length} vacant`);
console.log(`CC_0108_mn_legislature_incumbents.sql  ${plainRows.length} + ${distinctNew.length} people created, ` +
  `${Object.keys(reuseByDistrict).length} reused, ${seated.length} terms`);
console.log(`external_id band used: ${newPeople[newPeople.length - 1].external_id} .. ${newPeople[0].external_id}`);
