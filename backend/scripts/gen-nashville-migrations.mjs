#!/usr/bin/env node
/**
 * gen-nashville-migrations.mjs
 *
 * Emits the two Nashville wave 1a migrations from the verified roster:
 *   migrations/CC_0004_nashville_structure.sql    (districts, government, chambers, offices)
 *   migrations/CC_0005_nashville_metro_people.sql (politicians + terms)
 *
 * Roster: data/seed-nashville-davidson-2026/ROSTERS.md
 * Spec:   .planning/todos/2026-08-27-nashville-davidson-deep-seed.md
 * Plan:   docs/superpowers/plans/2026-08-27-nashville-wave-1a.md
 *
 * The migration numbers are deliberately NOT chosen here. The files are written
 * as CC_wip_* and renamed at apply time, so a number is claimed once, at the
 * moment it is used.
 *
 *   cd backend && node scripts/gen-nashville-migrations.mjs
 */
import { readFileSync, writeFileSync } from 'node:fs';

const ROSTER = 'data/seed-nashville-davidson-2026/ROSTERS.md';
const COUNTY_GEO_ID = '47037';
const MTFCC = 'X0035';
const N_DISTRICTS = 35;
const N_AT_LARGE = 5;
const BAND_LO = -4730042;
const BAND_HI = -4730001;

/**
 * 🔴 District 4's member already exists in prod, OUTSIDE our band, at -470405.
 * He is the same person as the TN-04 congressional candidate row — established
 * from his own words in a Nashville Banner questionnaire, not from the fact that
 * both say "district 4", which is a coincidence. See ROSTERS.md identity ruling
 * 2. Every count below therefore expects 41 in-band ids and one outside it.
 */
const REUSED_EXT_IDS = [-470405];

/**
 * The Vice Mayor's voter-facing explanation. Metropolitan Charter sec. 3.03:
 * "The vice county mayor shall be the presiding officer of the council, but
 * without vote therein, except in the event of a tie vote, when he may cast the
 * deciding vote."
 *
 * This is why the seat is voting_powers 'non_voting' rather than 'full': the
 * charter's default is no vote, with a tie as the single exception. Writing
 * 'full' would also hide this text, because both read paths only render
 * representation_note when voting_powers <> 'full'.
 */
const VICE_MAYOR_NOTE =
  'The Vice Mayor is elected countywide and presides over the 40-member Metropolitan Council. ' +
  'Under Section 3.03 of the Metropolitan Charter, the Vice Mayor does not vote on Council ' +
  'business, except to cast the deciding vote when the Council is tied. The Vice Mayor also ' +
  'serves as Mayor if the office of Mayor becomes vacant.';

/** SQL single-quote escape. */
const q = (s) =>
  s === null || s === undefined || s === '' || s === '-' ? 'NULL' : `'${String(s).replace(/'/g, "''")}'`;

/** text[] literal, never NULL — alternate_names is NOT NULL DEFAULT '{}'. */
const arr = (s) =>
  !s || s === '-'
    ? `ARRAY[]::text[]`
    : `ARRAY[${s.split(';').map((x) => q(x.trim())).join(', ')}]::text[]`;

const COLS = [
  'ext_id', 'geo_id', 'district_type', 'office_title', 'full_name', 'first_name', 'last_name',
  'middle_initial', 'name_suffix', 'aliases', 'term_start', 'start_precision', 'how_started', 'source',
];

function readRoster() {
  const rows = readFileSync(ROSTER, 'utf8')
    .split('\n')
    .filter((l) => /^\|\s*-4\d{5,6}\s*\|/.test(l))
    .map((l) => l.trim().replace(/^\|/, '').replace(/\|$/, '').split('|').map((c) => c.trim()));
  const out = rows.map((r) => Object.fromEntries(COLS.map((c, i) => [c, r[i]])));

  if (out.length !== 42) throw new Error(`roster: expected 42 rows, got ${out.length}`);
  const ids = out.map((r) => Number(r.ext_id));
  if (new Set(ids).size !== 42) throw new Error('roster: duplicate ext_id');
  const inBand = ids.filter((i) => i >= BAND_LO && i <= BAND_HI);
  if (inBand.length !== 41) throw new Error(`roster: expected 41 in-band ids, got ${inBand.length}`);
  for (const reused of REUSED_EXT_IDS) {
    if (!ids.includes(reused)) throw new Error(`roster: reused id ${reused} is missing`);
  }
  return out;
}

/**
 * 🔴 THE COUNCIL CHAMBER SPANS 36 DISTRICTS — the 35 council districts plus the
 * county polygon that carries the at-large seats and the Vice Mayor. So every
 * multi-seat top-up counts within (chamber_id, district_id), never chamber_id
 * alone. A chamber-scoped count sees the first district's seat, computes
 * 5 - 1 = 4, and can land those four on any district the join produces while
 * still reporting the right total. That is the CA_0006 bug, and this chamber is
 * exactly the shape its comments warned about.
 */
function structureSql() {
  const p = [];
  p.push(`-- CC_0004_nashville_structure.sql
-- Nashville deep-seed program, WAVE 1a (structure). Companion: CC_0005_nashville_metro_people.sql.
--
-- Creates the geography-and-seats half of the Metropolitan Government of
-- Nashville and Davidson County:
--   * 35 LOCAL districts -- Metro Council districts, mtfcc ${MTFCC}
--   * 1 government, 2 chambers
--   * 42 offices -- 35 district council + 5 at-large + Vice Mayor + Mayor
--
-- Spec: .planning/todos/2026-08-27-nashville-davidson-deep-seed.md
-- Plan: docs/superpowers/plans/2026-08-27-nashville-wave-1a.md
-- Roster: data/seed-nashville-davidson-2026/ROSTERS.md
-- Generated by: scripts/gen-nashville-migrations.mjs
--
-- ---------------------------------------------------------------------------
-- 🔴 NASHVILLE IS A CONSOLIDATED CITY-COUNTY. There is no county commission.
-- The 40-member Metro Council is both the city and the county legislature, so
-- ONE government row covers both tiers, and its geo_id is the COUNTY polygon
-- ${COUNTY_GEO_ID} -- NOT TIGER place 4752006, which is the metropolitan government
-- BALANCE and excludes six satellite cities (Belle Meade, Berry Hill, Forest
-- Hills, Goodlettsville, Oak Hill, Ridgetop) whose residents elect this same
-- council. Measured 2026-08-27: Belle Meade City Hall sits in council district
-- 23, Goodlettsville City Hall in 10. Using the place polygon would return no
-- representative for those addresses and nothing would error.
--
-- ---------------------------------------------------------------------------
-- 🔴 THE MULTI-SEAT TOP-UP IS SCOPED TO (chamber_id, district_id).
-- The Metropolitan Council chamber spans 36 districts. A chamber-scoped count is
-- the CA_0006 bug and would land seats on the wrong districts while reporting
-- the right total. The post-verify gate counts PER DISTRICT for the same reason:
-- a total-only assertion is exactly what the bug satisfies.
--
-- ---------------------------------------------------------------------------
-- 🔴 THE VICE MAYOR IS AN OFFICE, AND IT IS NOT A FULL-VOTING ONE.
-- Metropolitan Charter sec. 3.03: "The vice county mayor shall be the presiding
-- officer of the council, but without vote therein, except in the event of a tie
-- vote, when he may cast the deciding vote."
--
-- So Asheville's rule ("Vice Mayor is only a board role", CA_0009) does NOT
-- apply -- Nashville's Vice Mayor is elected countywide on their own ballot
-- line. But neither is the seat voting_powers 'full': the charter's default is
-- no vote. It is written 'non_voting' with the tie-break carried in
-- representation_note, which ADR 0003 then makes mandatory and both read paths
-- render.
--
-- chambers.official_count for the Council is 40, not 41. Charter sec. 15.01
-- provides for electing "a mayor, vice-mayor, five (5) councilmen-at-large and
-- thirty-five (35) district councilmen" -- the Vice Mayor is elected separately
-- and is not one of the 40.
--
-- IDEMPOTENT: every insert is NOT EXISTS-guarded or a target-count top-up.

BEGIN;

-- --- 0. Precondition: the council boundaries must already be loaded ---------
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries WHERE mtfcc = '${MTFCC}';
  IF v_n <> ${N_DISTRICTS} THEN
    RAISE EXCEPTION 'nashville structure: expected ${N_DISTRICTS} ${MTFCC} boundaries, found % -- run scripts/load-davidson-council-boundaries.ts first', v_n;
  END IF;
END $$;

-- --- 1. Districts -----------------------------------------------------------
-- num_officials = 1: each council district elects one member. The 5 at-large
-- seats, the Vice Mayor and the Mayor hang off the EXISTING county district
-- ${COUNTY_GEO_ID}, which is not created here (verified 2026-08-27: it exists and
-- carries ZERO offices).`);

  for (let d = 1; d <= N_DISTRICTS; d++) {
    const geoId = `nashville-tn-council-district-${d}`;
    p.push(`
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT ${q(geoId)}, ${q(`Nashville Metro Council District ${d}`)}, 'LOCAL', 'tn', '${MTFCC}', 1
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts WHERE geo_id = ${q(geoId)} AND mtfcc = '${MTFCC}'
);`);
  }

  p.push(`

-- --- 2. Government ----------------------------------------------------------
-- ONE row, because the city and the county are one government. type 'City' with
-- city 'Nashville' is the primary label; the name carries both halves. Nothing
-- in the read path branches on governments.type (verified 2026-08-27).

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'Metropolitan Government of Nashville and Davidson County, Tennessee, US', 'City', 'TN', 'Nashville', ${q(COUNTY_GEO_ID)}
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE geo_id = ${q(COUNTY_GEO_ID)} AND type = 'City'
);

-- --- 3. Chambers ------------------------------------------------------------
-- chambers.slug is GENERATED from name_formal and cannot be inserted. Getting
-- name_formal wrong silently yields a different slug.

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT g.id, 'Metropolitan Council', 'Metropolitan Council of Nashville and Davidson County', ${N_DISTRICTS + N_AT_LARGE}, 'full'
FROM essentials.governments g
WHERE g.geo_id = ${q(COUNTY_GEO_ID)} AND g.type = 'City'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
    WHERE c.government_id = g.id AND c.name = 'Metropolitan Council'
  );

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT g.id, 'Office of the Mayor', 'Office of the Mayor of Nashville and Davidson County', 1, 'full'
FROM essentials.governments g
WHERE g.geo_id = ${q(COUNTY_GEO_ID)} AND g.type = 'City'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
    WHERE c.government_id = g.id AND c.name = 'Office of the Mayor'
  );

-- --- 4a. The 35 district council seats --------------------------------------
-- Each title is distinct, because Nashville numbers districts on the ballot. So
-- a NOT EXISTS-on-title guard is correct here and cannot collapse rows.`);

  for (let d = 1; d <= N_DISTRICTS; d++) {
    const geoId = `nashville-tn-council-district-${d}`;
    const title = `Council Member, District ${d}`;
    p.push(`
INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, representing_city)
SELECT c.id, d.id, ${q(title)}, 'TN', 'Nashville'
FROM essentials.chambers c
JOIN essentials.governments g ON g.id = c.government_id
CROSS JOIN LATERAL (
  SELECT dd.id FROM essentials.districts dd
  WHERE dd.geo_id = ${q(geoId)} AND dd.mtfcc = '${MTFCC}' AND dd.district_type = 'LOCAL'
) d
WHERE g.geo_id = ${q(COUNTY_GEO_ID)} AND g.type = 'City' AND c.name = 'Metropolitan Council'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = ${q(title)}
  );`);
  }

  p.push(`

-- --- 4b. The 5 at-large seats, IDENTICAL titles -----------------------------
-- Nashville does not number the at-large seats; the top five vote-getters win,
-- so the five offices are genuinely interchangeable and share one title.
-- Guarded by a target-count top-up, because NOT EXISTS-on-title would collapse
-- five rows to one on a re-run.
--
-- 🔴 The count is scoped to (chamber_id, district_id). This chamber spans 36
-- districts, so a chamber-scoped count here is the CA_0006 bug outright.

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, representing_city)
SELECT c.id, d.id, 'Council Member at-Large', 'TN', 'Nashville'
FROM essentials.chambers c
JOIN essentials.governments g ON g.id = c.government_id
CROSS JOIN LATERAL (
  SELECT dd.id FROM essentials.districts dd
  WHERE dd.geo_id = ${q(COUNTY_GEO_ID)} AND dd.district_type = 'COUNTY' AND lower(dd.state) = 'tn'
) d
CROSS JOIN LATERAL (
  SELECT generate_series(1, ${N_AT_LARGE} - (
    SELECT count(*) FROM essentials.offices o
    WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = 'Council Member at-Large'
  )) AS n
) gs
WHERE g.geo_id = ${q(COUNTY_GEO_ID)} AND g.type = 'City' AND c.name = 'Metropolitan Council';

-- --- 4c. Vice Mayor ---------------------------------------------------------
-- See the header. non_voting + a mandatory note, per Charter sec. 3.03.

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, representing_city, voting_powers, representation_note)
SELECT c.id, d.id, 'Vice Mayor', 'TN', 'Nashville', 'non_voting', ${q(VICE_MAYOR_NOTE)}
FROM essentials.chambers c
JOIN essentials.governments g ON g.id = c.government_id
CROSS JOIN LATERAL (
  SELECT dd.id FROM essentials.districts dd
  WHERE dd.geo_id = ${q(COUNTY_GEO_ID)} AND dd.district_type = 'COUNTY' AND lower(dd.state) = 'tn'
) d
WHERE g.geo_id = ${q(COUNTY_GEO_ID)} AND g.type = 'City' AND c.name = 'Metropolitan Council'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id AND o.title = 'Vice Mayor'
  );

-- --- 4d. Mayor --------------------------------------------------------------

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, representing_city)
SELECT c.id, d.id, 'Mayor', 'TN', 'Nashville'
FROM essentials.chambers c
JOIN essentials.governments g ON g.id = c.government_id
CROSS JOIN LATERAL (
  SELECT dd.id FROM essentials.districts dd
  WHERE dd.geo_id = ${q(COUNTY_GEO_ID)} AND dd.district_type = 'COUNTY' AND lower(dd.state) = 'tn'
) d
WHERE g.geo_id = ${q(COUNTY_GEO_ID)} AND g.type = 'City' AND c.name = 'Office of the Mayor'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id AND o.title = 'Mayor'
  );

-- --- 5. Post-verify gate ----------------------------------------------------
DO $$
DECLARE v_n int; v_d int; v_nogeom int; v_vm int; v_city int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.districts WHERE mtfcc = '${MTFCC}';
  IF v_n <> ${N_DISTRICTS} THEN RAISE EXCEPTION 'nashville structure: expected ${N_DISTRICTS} ${MTFCC} districts, got %', v_n; END IF;

  -- 🔴 PER-DISTRICT, not ${N_DISTRICTS} in total. A total-only assertion is exactly what a
  -- chamber-scoped top-up satisfies while stacking seats on one district.
  FOR v_d IN 1..${N_DISTRICTS} LOOP
    SELECT count(*) INTO v_n FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.geo_id = 'nashville-tn-council-district-' || v_d AND d.mtfcc = '${MTFCC}';
    IF v_n <> 1 THEN RAISE EXCEPTION 'nashville structure: council district % carries % offices, expected exactly 1', v_d, v_n; END IF;
  END LOOP;

  -- The county polygon carries the 5 at-large seats + Vice Mayor + Mayor.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = ${q(COUNTY_GEO_ID)} AND d.district_type = 'COUNTY';
  IF v_n <> ${N_AT_LARGE + 2} THEN RAISE EXCEPTION 'nashville structure: expected ${N_AT_LARGE + 2} offices on the Davidson county polygon, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = ${q(COUNTY_GEO_ID)} AND d.district_type = 'COUNTY' AND o.title = 'Council Member at-Large';
  IF v_n <> ${N_AT_LARGE} THEN RAISE EXCEPTION 'nashville structure: expected ${N_AT_LARGE} at-large offices, got %', v_n; END IF;

  -- 🔴 The Davidson County LABEL exists in TWO states -- NC 37057 and TN ${COUNTY_GEO_ID}.
  -- Assert nothing landed on the North Carolina row, which a label-based join
  -- would have hit and no office count on the TN row would notice.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '37057' AND d.district_type = 'COUNTY';
  IF v_n <> 0 THEN RAISE EXCEPTION 'nashville structure: % office(s) landed on Davidson County, NORTH CAROLINA', v_n; END IF;

  -- The Vice Mayor seat: exactly one, non_voting, and carrying a substantive
  -- note. The note is the whole reason the seat is legible to a voter.
  SELECT count(*) INTO v_vm FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = ${q(COUNTY_GEO_ID)} AND o.title = 'Vice Mayor'
     AND o.voting_powers = 'non_voting'
     AND o.representation_note IS NOT NULL AND length(trim(o.representation_note)) > 80;
  IF v_vm <> 1 THEN RAISE EXCEPTION 'nashville structure: expected 1 non_voting Vice Mayor office with a substantive representation_note, got %', v_vm; END IF;

  -- Every Metro seat must carry the city, or the Nashville banner never
  -- resolves from data.
  SELECT count(*) INTO v_city FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE (d.mtfcc = '${MTFCC}' OR (d.geo_id = ${q(COUNTY_GEO_ID)} AND d.district_type = 'COUNTY'))
     AND (o.representing_city IS DISTINCT FROM 'Nashville' OR o.representing_state IS DISTINCT FROM 'TN');
  IF v_city <> 0 THEN RAISE EXCEPTION 'nashville structure: % Metro office(s) missing representing_city/state', v_city; END IF;

  -- No office may sit on a district with no geometry: unreachable by address,
  -- and nothing else would say so.
  SELECT count(*) INTO v_nogeom FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc = '${MTFCC}'
     AND NOT EXISTS (
       SELECT 1 FROM essentials.geofence_boundaries b
        WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc
     );
  IF v_nogeom <> 0 THEN RAISE EXCEPTION 'nashville structure: % office(s) sit on a district with no matching boundary', v_nogeom; END IF;

  RAISE NOTICE 'nashville structure OK -- 42 offices across 35 council districts and the Davidson county polygon.';
END $$;

COMMIT;
`);
  return p.join('');
}

/**
 * 🔴 ONE GROUP REPEATS A (geo_id, district_type, office_title) TRIPLE: the five
 * 'Council Member at-Large' seats on the county polygon. A title join cannot
 * resolve one person to one office row inside that group, so the pairing is a
 * deterministic row_number() bijection -- offices ORDER BY o.id (stable once the
 * structure migration creates them), roster ORDER BY ext_id (fixed by
 * ROSTERS.md). The structure gate asserts exactly 5 offices in the group and the
 * payload guard below asserts exactly 5 roster rows, so both sides yield 1..5
 * with no gaps: a bijection, and idempotent on re-run.
 *
 * ⚠ Silent about OUT-OF-BAND deletion, exactly as CA_0007 and CA_0010 are. If an
 * at-large office row is deleted outside these migrations and the structure
 * top-up regenerates it, the replacement gets a new UUID that may sort to a
 * different rank. The five seats are interchangeable so no voter-facing label
 * goes wrong -- but seat_officeholder() would then close and reopen terms
 * against the wrong predecessor, fabricating a term_end on a real record.
 *
 * ⚠ The at-large ext_id order is ROSTERS.md's, which follows the council page's
 * own listing. Within an interchangeable group that order is arbitrary and
 * carries no claim: it exists only to make the bijection deterministic.
 */
function peopleSql(roster) {
  const values = roster
    .map(
      (r) =>
        `  (${q(r.geo_id)}, ${q(r.district_type)}, ${q(r.office_title)}, ${r.ext_id}, ${q(r.full_name)}, ` +
        `${q(r.first_name)}, ${q(r.last_name)}, ${q(r.middle_initial)}, ${q(r.name_suffix)}, ${arr(r.aliases)}, ` +
        `${q(r.term_start)}::date, ${q(r.start_precision)}, ${q(r.how_started)}, ${q(r.source)})`,
    )
    .join(',\n');
  const appointed = roster.filter((r) => r.how_started === 'appointed').length;
  const dayPrecision = roster.filter((r) => r.start_precision === 'day').length;
  const reusedList = REUSED_EXT_IDS.join(', ');

  return `-- CC_0005_nashville_metro_people.sql
-- Nashville deep-seed program, WAVE 1a (people). Companion: CC_0004_nashville_structure.sql.
--
-- Inserts 41 politicians, reuses 1 that already exists, and seats all 42 via
-- essentials.seat_officeholder().
--
-- Roster: data/seed-nashville-davidson-2026/ROSTERS.md
-- Generated by: scripts/gen-nashville-migrations.mjs
--
-- ---------------------------------------------------------------------------
-- 🔴 IDENTITY IS KEYED ON external_id, NEVER ON NAME. Two collisions were
-- measured in prod on 2026-08-27 and BOTH are real -- they are not theoretical
-- risks quoted from a previous wave:
--
--   Robert Nash   -5515005  an active Village Trustee in WISCONSIN, with a
--                           photo. NOT District 27. A name-based guard would
--                           have inserted nothing, passed a 1:1 assertion, and
--                           seated a Wisconsin village trustee on the Nashville
--                           Metro Council. This is wave 2's Mike Lee failure,
--                           reproduced exactly, in this roster.
--
--   Mike Cortese   -470405  IS District 4. The row sits in the TN-04
--                           CONGRESSIONAL candidate band (-470401..-470410) and
--                           the obvious reading -- "Nashville is in TN-05/07, so
--                           this is a homonym" -- is WRONG. He told the Nashville
--                           Banner: "I serve as the elected representative for
--                           District 4 on the Davidson County Metro Council."
--                           He filed in TN-05 and moved to TN-04 after
--                           Tennessee's May 2026 redistricting.
--
-- So this migration inserts 41 people and REUSES ${reusedList}. Seeding him fresh
-- would leave prod with two Mike Cortese rows: one holding the council seat, one
-- holding his photo and his 2026 candidacy. ON CONFLICT (external_id) DO NOTHING
-- makes the reuse safe and leaves his existing row untouched.
--
-- ---------------------------------------------------------------------------
-- term_start is the day this person began holding THIS SEAT, continuously.
-- Re-election does not end an occupancy. The dates come from certified election
-- results (2023 vs 2019 vs 2015), NOT from any roster or biography page -- the
-- member pages publish no service-start year at all. 19 of the 42 have held
-- their seat since 2019; 23 began in 2023.
--
-- Terms are computed from 1 September following the August general election
-- (Charter Art. 15, incorporating Tenn. Const. Art. VII sec. 5), so 2023 starts
-- are written 2023-09-01 at MONTH precision -- a runoff winner is sworn in later
-- in the same month and no source gives a per-member day. The Mayor is the one
-- exception, at day precision, because his own page dates it.
--
-- Two members moved between seats in 2023 and their occupancy of the NEW seat
-- therefore begins in 2023, not when they first joined the body:
--   Delishia Porterfield  District 29 (2019) -> at-large (2023)
--   Angie Emery Henderson District 34 (2019) -> Vice Mayor (2023)
--
-- No term_end is written. A future term_end would make all 42 seats silently
-- self-vacate.

BEGIN;

CREATE TEMP TABLE nash_seed (
  geo_id          text,
  district_type   text,
  office_title    text,
  ext_id          bigint,
  full_name       text,
  first_name      text,
  last_name       text,
  middle_initial  text,
  name_suffix     text,
  aliases         text[],
  term_start      date,
  start_precision text,
  how_started     text,
  source          text
) ON COMMIT DROP;

INSERT INTO nash_seed VALUES
${values};

-- --- Payload guard ----------------------------------------------------------
DO $$
DECLARE v_n int; v_dup int; v_grp int;
BEGIN
  SELECT count(*) INTO v_n FROM nash_seed;
  IF v_n <> 42 THEN RAISE EXCEPTION 'seed payload: expected 42 rows, got %', v_n; END IF;

  SELECT count(*) INTO v_dup FROM (SELECT ext_id FROM nash_seed GROUP BY ext_id HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % duplicate external_id(s)', v_dup; END IF;

  SELECT count(*) INTO v_n FROM nash_seed WHERE ext_id BETWEEN ${BAND_LO} AND ${BAND_HI};
  IF v_n <> 41 THEN RAISE EXCEPTION 'seed payload: expected 41 in-band ext_ids, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM nash_seed WHERE ext_id IN (${reusedList});
  IF v_n <> ${REUSED_EXT_IDS.length} THEN RAISE EXCEPTION 'seed payload: the reused ext_id(s) are missing'; END IF;

  -- 🔴 The reused row must already exist AND still be the person we think it is.
  -- If someone renamed or deleted -470405 since 2026-08-27, seating it blind
  -- would attach a Nashville council seat to whoever now holds that id.
  SELECT count(*) INTO v_n
    FROM nash_seed s JOIN essentials.politicians p ON p.external_id = s.ext_id
   WHERE s.ext_id IN (${reusedList}) AND p.full_name = s.full_name;
  IF v_n <> ${REUSED_EXT_IDS.length} THEN RAISE EXCEPTION
    'seed payload: a reused ext_id does not resolve to a prod politician of the same full_name -- re-verify identity ruling 2 before proceeding'; END IF;

  SELECT count(*) INTO v_grp FROM nash_seed
   WHERE geo_id = '${COUNTY_GEO_ID}' AND district_type = 'COUNTY' AND office_title = 'Council Member at-Large';
  IF v_grp <> ${N_AT_LARGE} THEN RAISE EXCEPTION 'seed payload: expected ${N_AT_LARGE} at-large rows, got %', v_grp; END IF;

  SELECT count(*) INTO v_grp FROM nash_seed WHERE office_title LIKE 'Council Member, District %';
  IF v_grp <> ${N_DISTRICTS} THEN RAISE EXCEPTION 'seed payload: expected ${N_DISTRICTS} district rows, got %', v_grp; END IF;

  -- Every OTHER triple must be unique -- the genuinely single-seat titles.
  SELECT count(*) INTO v_dup FROM (
    SELECT geo_id, district_type, office_title FROM nash_seed
    WHERE office_title <> 'Council Member at-Large'
    GROUP BY geo_id, district_type, office_title HAVING count(*) > 1
  ) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % unexpected duplicate single-seat key(s)', v_dup; END IF;
END $$;

-- --- Politicians ------------------------------------------------------------
-- 41 inserts; the reused row conflicts and is left exactly as it is.

INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, middle_initial, name_suffix,
   alternate_names, is_incumbent, is_active, data_source)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.middle_initial, s.name_suffix,
       s.aliases, true, true, s.source
FROM nash_seed s
ON CONFLICT (external_id) DO NOTHING;

-- --- Occupancy, via the helper ----------------------------------------------

DO $$
DECLARE
  r record;
  v_seated int := 0;
BEGIN
  FOR r IN
    WITH office_rank AS (
      SELECT o.id AS office_id, d.geo_id, d.district_type, o.title,
             row_number() OVER (
               PARTITION BY d.geo_id, d.district_type, o.title ORDER BY o.id
             ) AS rn
      FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
      WHERE d.mtfcc = '${MTFCC}'
         OR (d.geo_id = '${COUNTY_GEO_ID}' AND d.district_type = 'COUNTY')
    ),
    seed_rank AS (
      SELECT s.*,
             row_number() OVER (
               PARTITION BY s.geo_id, s.district_type, s.office_title ORDER BY s.ext_id
             ) AS rn
      FROM nash_seed s
    )
    SELECT sr.term_start, sr.start_precision, sr.how_started, sr.source,
           orr.office_id, p.id AS politician_id
    FROM seed_rank sr
    JOIN office_rank orr
      ON orr.geo_id = sr.geo_id
     AND orr.district_type = sr.district_type
     AND orr.title = sr.office_title
     AND orr.rn = sr.rn
    JOIN essentials.politicians p ON p.external_id = sr.ext_id
    WHERE NOT EXISTS (
      SELECT 1 FROM essentials.office_terms t
      WHERE t.office_id = orr.office_id AND t.politician_id = p.id
    )
  LOOP
    PERFORM essentials.seat_officeholder(
      r.office_id, r.politician_id, r.term_start,
      r.source,
      r.how_started,
      r.start_precision
    );
    v_seated := v_seated + 1;
  END LOOP;
  RAISE NOTICE 'seated % Nashville Metro official(s)', v_seated;
END $$;

-- --- Post-verify gate -------------------------------------------------------
DO $$
DECLARE v_pol int; v_seated int; v_appointed int; v_day int; v_homonym int; v_n int; v_d int;
BEGIN
  SELECT count(*) INTO v_pol FROM essentials.politicians
   WHERE external_id BETWEEN ${BAND_LO} AND ${BAND_HI};
  IF v_pol <> 41 THEN RAISE EXCEPTION 'nashville people: expected 41 in-band politicians, got %', v_pol; END IF;

  -- 🔴 And exactly ONE Mike Cortese. A duplicate here is the failure this
  -- migration exists to avoid, and a band count alone cannot see it.
  SELECT count(*) INTO v_n FROM essentials.politicians WHERE full_name = 'Mike Cortese';
  IF v_n <> 1 THEN RAISE EXCEPTION 'nashville people: found % politicians named Mike Cortese, expected exactly 1 -- the reuse failed and prod now holds a duplicate', v_n; END IF;

  -- count(och.politician_id), NOT count(*): office_current_holder LEFT JOINs
  -- from offices, so a vacancy is a NULL politician_id, never an absent row.
  -- count(*) would pass vacuously with every seat empty.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.mtfcc = '${MTFCC}'
      OR (d.geo_id = '${COUNTY_GEO_ID}' AND d.district_type = 'COUNTY');
  IF v_seated <> 42 THEN RAISE EXCEPTION 'nashville people: expected 42 seated officials, found %', v_seated; END IF;

  -- Per district, for the same reason the structure gate counts per district.
  FOR v_d IN 1..${N_DISTRICTS} LOOP
    SELECT count(och.politician_id) INTO v_n
      FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
     WHERE d.geo_id = 'nashville-tn-council-district-' || v_d AND d.mtfcc = '${MTFCC}';
    IF v_n <> 1 THEN RAISE EXCEPTION 'nashville people: council district % has % seated member(s), expected 1', v_d, v_n; END IF;
  END LOOP;

  SELECT count(*) INTO v_appointed
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE (p.external_id BETWEEN ${BAND_LO} AND ${BAND_HI} OR p.external_id IN (${reusedList}))
     AND t.how_started = 'appointed';
  IF v_appointed <> ${appointed} THEN RAISE EXCEPTION 'nashville people: expected ${appointed} appointed term(s), found %', v_appointed; END IF;

  SELECT count(*) INTO v_day
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
    JOIN essentials.offices o ON o.id = t.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE (d.mtfcc = '${MTFCC}' OR (d.geo_id = '${COUNTY_GEO_ID}' AND d.district_type = 'COUNTY'))
     AND t.start_precision = 'day';
  IF v_day <> ${dayPrecision} THEN RAISE EXCEPTION 'nashville people: expected ${dayPrecision} day-precision term(s), found % -- a date was invented or dropped', v_day; END IF;

  -- 🔴 Cross-state homonym assertion: no Nashville seat may resolve to someone
  -- who also holds an office outside Tennessee. Robert Nash is the live case
  -- this exists for.
  SELECT count(*) INTO v_homonym
  FROM essentials.politicians p
  JOIN essentials.office_current_holder och ON och.politician_id = p.id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
   AND (d.mtfcc = '${MTFCC}' OR (d.geo_id = '${COUNTY_GEO_ID}' AND d.district_type = 'COUNTY'))
  JOIN essentials.office_current_holder och2 ON och2.politician_id = p.id
  JOIN essentials.offices o2 ON o2.id = och2.office_id
  JOIN essentials.districts d2 ON d2.id = o2.district_id AND lower(d2.state) <> 'tn';
  IF v_homonym <> 0 THEN RAISE EXCEPTION
    'nashville people: % seat(s) resolved to an out-of-state politician -- the Mike Lee failure', v_homonym; END IF;

  RAISE NOTICE 'nashville people OK -- 42 officials seated, ${appointed} by appointment, 1 Mike Cortese, 0 homonyms.';
END $$;

COMMIT;
`;
}

const roster = readRoster();
writeFileSync('migrations/CC_0004_nashville_structure.sql', structureSql(roster));
writeFileSync('migrations/CC_0005_nashville_metro_people.sql', peopleSql(roster));
console.log(`read ${roster.length} roster rows`);
console.log('wrote migrations/CC_0004_nashville_structure.sql');
console.log('wrote migrations/CC_0005_nashville_metro_people.sql');
