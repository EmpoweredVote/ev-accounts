/**
 * gen-ga5-macon-bibb-migrations.mjs
 *
 * Generates the GA-5 migrations from backend/data/ga5-macon-bibb-roster.json.
 *
 *   CC_wip_macon_bibb_structure.sql   Task 2 — 1 government, 2 city chambers,
 *                                     10 districts (9 x X0045 + 1 citywide),
 *                                     10 offices
 *
 * Tasks 3 (city occupancy) and 4 (Bibb County officers) are not emitted yet.
 *
 * Everything comes from data/ga5-macon-bibb-roster.json, and the roster is
 * validated by scripts/assert-ga5-macon-bibb-roster.mjs — which this script RUNS
 * FIRST and refuses to emit without. The rules therefore have exactly one
 * definition, the way check-address-reachability.mjs keeps its MTFCC mapping in
 * one place.
 *
 * Wave GA-5 of the Knight Foundation cities program.
 * Roster: backend/data/seed-macon-bibb-2026/ROSTERS.md
 * Slice:  .planning/knight-foundation/ga.md
 *
 * Usage:  node scripts/gen-ga5-macon-bibb-migrations.mjs
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 TAKE THE MIGRATION NUMBER LAST. The file is emitted as CC_wip_*, and the
 *    rename happens at apply time, re-counted across EVERY remote ref — not
 *    against PROGRAM.md or ga.md, which record what the LAST wave took, a
 *    different question, and have gone stale within hours. GA-4's own numbers
 *    collided with a parallel session of the SAME author SIX MINUTES after its
 *    re-count. Re-count immediately before the rename, and again after.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 MACON-BIBB IS ONE GOVERNMENT WITH THREE CHAMBERS, SO THIS MIGRATION'S
 *    POST-VERIFY MUST NOT COUNT CHAMBERS OR OFFICES GOVERNMENT-WIDE.
 *
 * Consolidation means Bibb County's five elected officers hang off the SAME
 * government row as the Commission. A post-verify asserting "this government has
 * exactly 2 chambers and 10 offices" would pass on the day it applies and then
 * FAIL FOREVER once Task 4 adds the county chamber — which breaks this
 * migration's own re-run. That is the FL-4 correction in a new dress: an
 * assertion scoped wider than the thing the migration owns creates a hidden
 * ordering dependency between two halves of one wave. GA-4 proved it by
 * inserting a simulated Task 4 mid-transaction and re-running. Every count below
 * is scoped to the TWO CITY CHAMBERS.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THE CITYWIDE DISTRICT IS CREATED; THE COUNTYWIDE ONE IS ONLY ASSERTED.
 *
 * GA-1 loaded the TIGER place BOUNDARY 1349008/G4110 and created no place
 * DISTRICT — verified in production 2026-09-01 as 0 rows — so the citywide LOCAL
 * district is inserted here. The TIGER county load already created 13021/G4020
 * as a COUNTY district, so Task 4 asserts it and inserts nothing. Inserting it
 * again would lay a second district over the same ground.
 *
 * ⚠ THE TWO COVER IDENTICAL GROUND — 254.906 sq mi each — and that is correct
 *   under consolidation: same ground, two tiers. It is also why this migration
 *   asserts that NO city office landed on a COUNTY district, and why the
 *   acceptance probe has to assert each tier separately.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 WHAT DIFFERS FROM COLUMBUS, AND MUST NOT BE INHERITED FROM IT
 *
 *   Columbus (GA-4)                     Macon-Bibb (GA-5)
 *   8 districts + 2 at-large posts      9 districts, NO at-large seats
 *   citywide num_officials = 3          citywide num_officials = 1 (Mayor only)
 *   Council official_count = 10         Commission official_count = 9
 *   Mayor's note cites Sec. 4-201       Mayor's note cites Sec. 9(c)
 *
 * Ruling M1 is the charter's, and the charter CONTRADICTS ITSELF on it. Sec. 5
 * says the commission is "composed of a mayor and nine commissioners" and then
 * defines every member as a "commissioner"; Sec. 9(c) says "The commission shall
 * consist of nine members" and makes the mayor the presiding officer and
 * expressly not a voting member. Sec. 9(c) governs — and the body's own conduct
 * settles which one it follows: the mayor pro tem was elected 5–4 among NINE in
 * January 2025 and 5–3 among EIGHT on 2026-01-06 with District 5 vacant. Both
 * totals are the commissioner count, never that plus one.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 GEORGIA'S geo_id COLLISION IS THREE-WAY AND IT IS LIVE IN `districts`, NOT
 *    JUST IN BOUNDARIES. Measured in production 2026-09-01, bare '13021'
 *    matches THREE district rows:
 *
 *      COUNTY       13021  G4020  Bibb County
 *      STATE_LOWER  13021  G5220  State House District 21
 *      STATE_UPPER  13021  G5210  State Senate District 21
 *
 * Every lookup here pairs geo_id with mtfcc AND district_type. An unpaired join
 * does not error — it silently returns the wrong tier. The pre-flight asserts
 * the paired lookup finds exactly one row and reports the unpaired count so a
 * reader can see the collision rather than take it on trust.
 */

import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const BACKEND = join(HERE, '..');
const ROSTER = join(BACKEND, 'data', 'ga5-macon-bibb-roster.json');
const VALIDATOR = join(HERE, 'assert-ga5-macon-bibb-roster.mjs');
const OUT_DIR = join(BACKEND, 'migrations');

// 🔴 The roster is validated by ITS OWN script, not by a second copy of the
//    rules here. If it fails, nothing is written.
try {
  const out = execFileSync(process.execPath, [VALIDATOR], { encoding: 'utf8' });
  process.stdout.write(out);
} catch (e) {
  process.stderr.write(e.stdout ?? '');
  process.stderr.write(e.stderr ?? '');
  console.error('\nREFUSING TO GENERATE: the roster does not validate.');
  process.exit(1);
}

const r = JSON.parse(readFileSync(ROSTER, 'utf8'));

/** SQL single-quoted literal. */
const q = (s) => (s === null || s === undefined ? 'NULL' : `'${String(s).replace(/'/g, "''")}'`);

// ── the city structure half (Task 2) ─────────────────────────────────────────

const TAG = 'macon-bibb structure';
const city = r.city;
const county = r.county;
const gov = city.government;
const wide = city.citywide_district;
const DT = city.district_type;
const CDT = county.district_type;

/** Every district this migration creates: the citywide one plus the nine. */
function districtRows() {
  const rows = [{ label: wide.label, geo_id: wide.geo_id, mtfcc: wide.mtfcc, num: String(wide.num_officials) }];
  for (let i = 1; i <= city.district_count; i++) {
    rows.push({
      label: `${city.district_label_prefix}${i}`,
      geo_id: `${city.district_geo_id_prefix}${i}`,
      mtfcc: city.district_mtfcc,
      num: '1',
    });
  }
  return rows;
}

function districtsSql() {
  return districtRows()
    .map(
      (d) => `INSERT INTO essentials.districts (district_type, label, state, geo_id, mtfcc, num_officials)
SELECT ${q(DT)}, ${q(d.label)}, 'ga', ${q(d.geo_id)}, ${q(d.mtfcc)}, ${d.num}
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
   WHERE geo_id = ${q(d.geo_id)} AND mtfcc = ${q(d.mtfcc)} AND district_type = ${q(DT)}
);`,
    )
    .join('\n');
}

function governmentSql() {
  return `INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT ${q(gov.name)}, ${q(gov.type)}, ${q(gov.state)}, ${q(gov.city)}, ${q(gov.geo_id)}
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE geo_id = ${q(gov.geo_id)} AND type = ${q(gov.type)}
);`;
}

function chambersSql() {
  return city.chambers
    .map(
      (c) => `INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT g.id, ${q(c.name)}, ${q(c.name_formal)}, ${c.official_count}, 'full'
FROM essentials.governments g
WHERE g.geo_id = ${q(gov.geo_id)} AND g.type = ${q(gov.type)}
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = ${q(c.name)}
  );`,
    )
    .join('\n\n');
}

function officesSql() {
  return city.offices
    .map((o) => {
      const cols = ['chamber_id', 'district_id', 'title', 'representing_state', 'representing_city', 'voting_powers'];
      const vals = ['c.id', 'd.id', q(o.title), q(gov.state), q(gov.city), q(o.voting_powers)];
      if (o.representation_note) {
        cols.push('representation_note');
        vals.push(q(o.representation_note));
      }
      if (o.description) {
        cols.push('description');
        vals.push(q(o.description));
      }
      return `INSERT INTO essentials.offices
  (${cols.join(', ')})
SELECT ${vals.join(', ')}
FROM essentials.chambers c
JOIN essentials.governments g ON g.id = c.government_id
CROSS JOIN LATERAL (
  SELECT dd.id FROM essentials.districts dd
   WHERE dd.geo_id = ${q(o.district_geo_id)} AND dd.mtfcc = ${q(o.district_mtfcc)}
     AND dd.district_type = ${q(DT)} AND lower(dd.state) = 'ga'
) d
WHERE g.geo_id = ${q(gov.geo_id)} AND g.type = ${q(gov.type)} AND c.name = ${q(o.chamber)}
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = ${q(o.title)}
  );`;
    })
    .join('\n');
}

function preflightSql() {
  const slugs = [];
  for (let i = 1; i <= city.district_count; i++) slugs.push(`${city.district_geo_id_prefix}${i}`);
  return `-- --- 0. Pre-flight: refuse to create offices whose district has no polygon ---
-- 🔴 An office on a district with no boundary is an office NOBODY CAN REACH BY
-- ADDRESS, and nothing else in the system errors. This is the one failure mode
-- CI cannot catch after the fact.
DO $$
DECLARE v_n int; v_unpaired int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries WHERE mtfcc = ${q(city.district_mtfcc)};
  IF v_n <> ${city.district_count} THEN
    RAISE EXCEPTION '${TAG}: expected ${city.district_count} ${city.district_mtfcc} boundaries, found % -- run scripts/load-macon-bibb-commission-boundaries.ts (GA-5 Task 1) first', v_n;
  END IF;

  -- ⚠ A COUNT IS NOT AN IDENTITY CHECK. Nine boundaries under some other slug
  -- would satisfy the count above and then silently produce zero offices,
  -- because the office insert resolves each district by its geo_id.
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries
   WHERE mtfcc = ${q(city.district_mtfcc)}
     AND geo_id IN (${slugs.map(q).join(', ')});
  IF v_n <> ${city.district_count} THEN
    RAISE EXCEPTION '${TAG}: the ${city.district_mtfcc} boundaries are not the % expected slugs (matched %)', ${city.district_count}, v_n;
  END IF;

  -- The citywide district hangs on the TIGER place boundary GA-1 loaded.
  -- ⚠ ALWAYS PAIR geo_id WITH mtfcc.
  IF NOT EXISTS (
    SELECT 1 FROM essentials.geofence_boundaries
     WHERE geo_id = ${q(wide.geo_id)} AND mtfcc = ${q(wide.mtfcc)}
  ) THEN
    RAISE EXCEPTION '${TAG}: boundary ${wide.geo_id}/${wide.mtfcc} is missing -- GA-1 must be applied first';
  END IF;

  -- 🔴 GEORGIA'S geo_id COLLISION IS THREE-WAY AND LIVE IN \`districts\`. The
  -- COUNTY district Task 4 needs must resolve to EXACTLY ONE row when geo_id is
  -- paired with mtfcc and district_type -- and bare '${county.countywide_district.geo_id}' does NOT.
  -- This migration creates nothing on the county tier; it only proves the tier
  -- is reachable and distinguishable before Task 4 relies on it.
  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE geo_id = ${q(county.countywide_district.geo_id)} AND mtfcc = ${q(county.countywide_district.mtfcc)}
     AND district_type = ${q(CDT)};
  IF v_n <> 1 THEN
    RAISE EXCEPTION '${TAG}: expected exactly 1 ${CDT} district ${county.countywide_district.geo_id}/${county.countywide_district.mtfcc}, got % -- the TIGER county load must be applied first, and Task 4 ASSERTS this row rather than inserting it', v_n;
  END IF;

  SELECT count(*) INTO v_unpaired FROM essentials.districts
   WHERE geo_id = ${q(county.countywide_district.geo_id)};
  RAISE NOTICE '${TAG}: bare geo_id ${county.countywide_district.geo_id} matches % district rows across tiers (COUNTY + State House 21 + State Senate 21) -- this is why every join here pairs geo_id with mtfcc AND district_type', v_unpaired;
  IF v_unpaired < 2 THEN
    RAISE EXCEPTION '${TAG}: bare geo_id ${county.countywide_district.geo_id} matched only % row(s). Georgia''s three-way collision is documented as MEASURED; if it has genuinely gone away, re-measure before relaxing any join', v_unpaired;
  END IF;
END $$;`;
}

function verifySql() {
  const n = city.offices.length;
  const wideOffices = city.offices.filter((o) => o.district_geo_id === wide.geo_id && o.district_mtfcc === wide.mtfcc);
  const mayor = city.offices.find((o) => o.voting_powers !== 'full');
  const chamberNames = city.chambers.map((c) => q(c.name)).join(', ');
  const chamberChecks = city.chambers
    .map((c) => `(c.name = ${q(c.name)} AND c.official_count = ${c.official_count})`)
    .join('\n                                       OR ');

  return `-- --- 5. Post-verify gate ----------------------------------------------------
-- 🔴 EVERY COUNT HERE IS SCOPED TO THE TWO CITY CHAMBERS, NEVER TO THE
-- GOVERNMENT. Macon-Bibb is consolidated, so Task 4's five county officers join
-- this SAME government row. A government-wide count would pass today and fail
-- forever after that, breaking this migration's own re-run -- the FL-4
-- correction, in a new dress, proved at GA-4 by simulating Task 4 mid-transaction.
DO $$
DECLARE v_n int; v_gov uuid; v_d text;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE mtfcc = ${q(city.district_mtfcc)} AND district_type = ${q(DT)} AND lower(state) = 'ga';
  IF v_n <> ${city.district_count} THEN RAISE EXCEPTION '${TAG}: expected ${city.district_count} ${city.district_mtfcc} districts, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE geo_id = ${q(wide.geo_id)} AND mtfcc = ${q(wide.mtfcc)} AND district_type = ${q(DT)}
     AND num_officials = ${wide.num_officials};
  IF v_n <> 1 THEN RAISE EXCEPTION '${TAG}: expected exactly 1 ${wide.label} district carrying num_officials = ${wide.num_officials}, got %', v_n; END IF;

  SELECT id INTO v_gov FROM essentials.governments
   WHERE geo_id = ${q(gov.geo_id)} AND type = ${q(gov.type)};
  IF v_gov IS NULL THEN RAISE EXCEPTION '${TAG}: the government row is missing'; END IF;

  -- The two CITY chambers exist and carry the right official_count. Deliberately
  -- NOT "this government has exactly 2 chambers" -- see the header.
  -- 🔴 official_count on the Commission is ${city.chambers[0].official_count}, not 10. Charter Sec. 9(c):
  -- "The commission shall consist of nine members." Sec. 5's "a mayor and nine
  -- commissioners" contradicts it; 9(c) is the provision that sets membership
  -- and voting, and the two mayor pro tem roll calls (5-4 of nine, then 5-3 of
  -- eight with a seat vacant) show which one the body follows.
  SELECT count(*) INTO v_n FROM essentials.chambers c
   WHERE c.government_id = v_gov AND (${chamberChecks});
  IF v_n <> ${city.chambers.length} THEN RAISE EXCEPTION '${TAG}: expected ${city.chambers.length} city chambers with the right official_count, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name IN (${chamberNames});
  IF v_n <> ${n} THEN RAISE EXCEPTION '${TAG}: expected ${n} city offices, got %', v_n; END IF;

  -- Exactly one office per numbered district, counted PER DISTRICT. A single
  -- total can hide two offices on one district and none on another.
  FOR v_d IN SELECT ${q(city.district_geo_id_prefix)} || gs FROM generate_series(1,${city.district_count}) gs LOOP
    SELECT count(*) INTO v_n FROM essentials.offices o
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE d.geo_id = v_d AND d.mtfcc = ${q(city.district_mtfcc)} AND d.district_type = ${q(DT)};
    IF v_n <> 1 THEN RAISE EXCEPTION '${TAG}: district % carries % offices, expected exactly 1', v_d, v_n; END IF;
  END LOOP;

  -- 🔴 EXACTLY ONE seat hangs on the citywide district: the Mayor.
  -- ⚠ THIS IS WHERE COLUMBUS MUST NOT BE COPIED. Columbus expects THREE here --
  -- its Mayor plus at-large Posts 9 and 10. Macon-Bibb has NO at-large seats
  -- (charter Sec. 9(a) and 9(c); all five GIS layers return nine polygons), so
  -- three would mean two commissioners had been hung on the wrong district.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name IN (${chamberNames})
     AND d.geo_id = ${q(wide.geo_id)} AND d.mtfcc = ${q(wide.mtfcc)} AND d.district_type = ${q(DT)};
  IF v_n <> ${wideOffices.length} THEN RAISE EXCEPTION '${TAG}: expected ${wideOffices.length} office(s) on ${wide.label}, got %', v_n; END IF;

  -- 🔴 Ruling M2 must have SURVIVED generation. The Mayor presides, has a voice,
  -- and votes only to break a tie (charter Sec. 9(c)), so the seat is non_voting
  -- and ADR 0003 makes the note mandatory -- and both read paths must render it.
  -- A generator that dropped the note would satisfy every count above and be
  -- caught only by the CHECK, or NOT AT ALL if the seat had silently been
  -- written 'full', because a 'full' seat with no note is legal.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND o.title = ${q(mayor.title)}
     AND o.voting_powers = ${q(mayor.voting_powers)}
     AND o.representation_note IS NOT NULL AND length(o.representation_note) >= 200
     AND o.representation_note LIKE '%9(c)%';
  IF v_n <> 1 THEN RAISE EXCEPTION '${TAG}: expected 1 ${mayor.voting_powers} ${mayor.title} office carrying a substantive representation_note that cites charter Sec. 9(c), got %', v_n; END IF;

  -- And no full-voting city seat carries one: both read paths HIDE the note when
  -- voting_powers is 'full', so writing one there is prose nobody will ever see.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name IN (${chamberNames})
     AND o.voting_powers = 'full' AND o.representation_note IS NOT NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION '${TAG}: % full-voting seat(s) carry a representation_note that no read path renders', v_n; END IF;

  -- No role leaked out as its own office. Mayor Pro Tem is elected annually by
  -- the Commission from its own members, charter Sec. 9(f) -- ruling M3. It moved
  -- from Seth Clark to Valerie Wynn on 2026-01-06, which is exactly why it is a
  -- parenthetical on the District 1 seat title and not a row.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name IN (${chamberNames})
     AND (o.title ILIKE '%pro tem%' OR o.title ILIKE '%pro-tem%' OR o.title ILIKE '%chair%' OR o.title ILIKE '%vice%');
  IF v_n <> 0 THEN RAISE EXCEPTION '${TAG}: % role(s) were created as offices -- ruling M3 says they are parentheticals', v_n; END IF;

  -- 🔴🔴 THE TIERS MUST NOT CROSS, AND A CROSSED TIER IS INVISIBLE HERE.
  -- The citywide LOCAL district and Bibb County's COUNTY district cover the SAME
  -- 254.906 sq mi. A city office hung on the COUNTY district would still resolve
  -- at every address in Macon and look completely correct -- only the tier would
  -- be wrong, and nothing would error. So assert that every city office sits on
  -- a ${DT} district. Task 4 asserts the mirror image for its five officers.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.government_id = v_gov AND c.name IN (${chamberNames})
     AND d.district_type <> ${q(DT)};
  IF v_n <> 0 THEN RAISE EXCEPTION '${TAG}: % city office(s) sit on a district that is not ${DT} -- the tiers have crossed', v_n; END IF;

  -- 🔴 No office may sit on a district with no matching boundary: that is an
  -- office nobody can reach by address, and nothing else errors. Left
  -- government-wide on purpose -- the answer is 0 before and after Task 4.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE c.government_id = v_gov
     AND NOT EXISTS (SELECT 1 FROM essentials.geofence_boundaries gb
                      WHERE gb.geo_id = d.geo_id AND gb.mtfcc = d.mtfcc);
  IF v_n <> 0 THEN RAISE EXCEPTION '${TAG}: % office(s) sit on a district with no matching boundary', v_n; END IF;

  RAISE NOTICE '${TAG} OK: ${districtRows().length} districts created, 1 government, ${city.chambers.length} city chambers, ${n} city offices (${city.district_count} district commissioners + 1 non_voting Mayor, NO at-large seats)';
END $$;`;
}

function structureFile() {
  return `-- CC_wip_macon_bibb_structure.sql
--
-- Knight Foundation cities program, wave GA-5 Task 2, CITY STRUCTURE half.
--   * 1 government, 2 chambers
--   * 10 districts -- 1 citywide (TIGER place ${wide.geo_id}/${wide.mtfcc}) + ${city.district_count} commission (${city.district_mtfcc})
--   * 10 offices   -- 1 Mayor + ${city.district_count} district commissioners, and NO at-large seats
--
-- Roster: backend/data/seed-macon-bibb-2026/ROSTERS.md
-- Slice:  .planning/knight-foundation/ga.md
-- Generated by scripts/gen-ga5-macon-bibb-migrations.mjs from
-- data/ga5-macon-bibb-roster.json -- edit the roster and regenerate, do not
-- hand-edit this file.
--
-- 🔴 TAKE THE MIGRATION NUMBER LAST. This file is CC_wip_ on purpose. Re-count
--    across EVERY remote ref at rename time, and again after: GA-4's numbers
--    collided with a parallel session of the SAME author six minutes after its
--    re-count, and were renumbered after being applied.
--
-- ---------------------------------------------------------------------------
-- 🔴 MACON-BIBB IS THE PROGRAM'S SECOND CONSOLIDATED CITY-COUNTY, AND THE
--    CONSOLIDATION IS COMPLETE.
--
-- TIGER place ${wide.geo_id} measures 254.906 sq mi, identical to Bibb County
-- ${county.countywide_district.geo_id}, and Georgia publishes no BALANCE record for it (FUNCSTAT 'A',
-- unlike Augusta-Richmond and Athens-Clarke, which are 'F' because satellites
-- survive there). So -- unlike Nashville, whose place polygon excludes six
-- satellite cities whose residents still elect the same council -- the place
-- polygon here is the whole electorate, and the government row can key on it.
--
-- ⚠ Charter Sec. 9(a) excludes "the city limits of the City of Payne City" from
--   the districting plan. Payne City was a municipality inside Bibb, and if it
--   still existed the nine districts would not tile the county. It dissolved
--   into the consolidated government and appears nowhere in the TIGER 2024
--   place file; the boundary loader measured the residual at 0.0139 sq mi, far
--   below Payne City's footprint, so the carve-out is spent. That was PROVED,
--   not assumed.
--
-- ONE government covers both tiers. Task 4 attaches a THIRD chamber, "${county.chambers[0].name}",
-- to THIS SAME government row. That is why every count in the post-verify gate
-- below is scoped to the two CITY chambers and never to the government.
--
-- ---------------------------------------------------------------------------
-- 🔴 RULING M1: NINE COMMISSIONERS, NINE SINGLE-MEMBER DISTRICTS, NO AT-LARGE.
--
-- Charter Sec. 9(a): "The territory of the restructured government shall consist
-- of nine election districts to be designated as Commission Districts 1 through
-- 9". Sec. 9(c): "The members shall be elected from the nine districts specified
-- in subsection (a) of this section by a majority of electors voting in such
-- election from such district."
--
-- All five GIS layers that publish these districts return exactly nine polygons,
-- which is the independent confirmation that there is no at-large pair.
--
-- ⚠ THE CHARTER CONTRADICTS ITSELF AND Sec. 9(c) GOVERNS. Sec. 5 says the
--   commission is "composed of a mayor and nine commissioners" and then defines
--   every member as a "commissioner". Sec. 9(c) says "The commission shall
--   consist of nine members" and makes the mayor the presiding officer and
--   expressly not a voting member. Sec. 9(c) is the provision that sets
--   membership and voting, and the body's own conduct settles it: the mayor pro
--   tem was elected 5-4 among NINE in January 2025 and 5-3 among EIGHT on
--   2026-01-06 with District 5 vacant. official_count is 9.
--
-- 🔴 DO NOT COPY COLUMBUS HERE. Columbus is 8 districts + 2 at-large posts, so
--   its citywide district carries num_officials 3. Macon-Bibb's carries 1.
--
-- ---------------------------------------------------------------------------
-- 🔴 RULING M2: THE MAYOR IS non_voting, WITH A MANDATORY NOTE CITING Sec. 9(c).
--
-- Charter Sec. 9(c): "All members of the commission shall be full voting members
-- of the commission. The mayor shall be the presiding officer of the commission
-- but shall not be a voting member of the commission; provided, however, that
-- the mayor may cast a vote on any matter before the commission to break a tie.
-- The mayor may propose ordinances in the same manner as a commissioner."
--
-- That is Nashville's Vice Mayor ruling and Columbus's R2 in a third dress:
-- voting_powers 'non_voting' with the tie-break carried in representation_note,
-- which ADR 0003 makes mandatory and both read paths render.
--
-- ⚠ THE SECTION WAS READ, NOT CARRIED FROM A SUMMARY. GA-4 cited Columbus's
--   "Sec. 4-102" for the same power through three files; 4-102 is "General
--   provisions concerning departments" and the real section was 4-201.
--   representation_note is voter-facing prose, so a wrong section number ships
--   to readers. The post-verify below asserts the note actually contains
--   "9(c)", not merely that a note exists.
--
-- ---------------------------------------------------------------------------
-- 🔴 RULING M3: MAYOR PRO TEM IS A PARENTHETICAL, NOT AN OFFICE.
--
-- Charter Sec. 9(f): "The commission shall elect from among its members in
-- January of each year a member to serve as mayor pro tempore, who shall preside
-- over meetings of the commission in the mayor's absence." Elected by the body,
-- from the body, annually -- and it moved from Seth Clark to Valerie Wynn on
-- 2026-01-06, which is the demonstration. Baldwin R2, the Lawrence County
-- ruling, and Columbus R3. The post-verify gate refuses any office titled with it.
--
-- ---------------------------------------------------------------------------
-- ⚠ THE NINE DISTRICTS DO TILE THE COUNTY, WHICH IS THE OPPOSITE OF COLUMBUS.
--
-- Columbus's eight districts leave 74.79 sq mi (Fort Benning) in no council
-- district, so GA-4's rule was "gate the structure, not full coverage". Bibb's
-- nine cover 254.9060 of the county's 254.9059 sq mi, uncovered 0.0139. Full
-- coverage is gated -- in the BOUNDARY LOADER, where the geometry lives, not
-- here. This migration gates the structure: one office per district, exactly one
-- seat citywide, and no crossed tier.
--
-- IDEMPOTENT: every insert is NOT EXISTS-guarded, and every assertion is a
-- statement about the END STATE, not about a delta.

BEGIN;

${preflightSql()}

-- --- 1. Districts -----------------------------------------------------------
-- ⚠ Synthetic districts carry no ocd_id and no government_id, matching X0035,
-- X0042, X0043 and X0044's siblings. district state is LOWER case here and
-- UPPER on governments and offices; both conventions are live in prod.
--
-- num_officials on the citywide district is ${wide.num_officials}: exactly one official is
-- elected on it, the Mayor. Columbus wrote 3 because its two at-large posts are
-- elected citywide too; Tallahassee wrote 5 because all five of its
-- commissioners are at-large; Miami wrote 1 because only its Mayor is. The
-- column counts officials elected on the district ACROSS CHAMBERS, not seats
-- within one chamber -- and Macon-Bibb has no at-large seats at all.

${districtsSql()}

-- --- 2. Government ----------------------------------------------------------
-- ⚠ The charter's corporate name is the bare "Macon-Bibb County" (Sec. 1(a)),
-- which is not a usable row label; the government publishes itself as the
-- Macon-Bibb County Government.

${governmentSql()}

-- --- 3. Chambers ------------------------------------------------------------
-- ⚠ chambers.slug is GENERATED from name_formal and cannot be inserted.
-- Getting name_formal wrong silently yields a different slug.

${chambersSql()}

-- --- 4. Offices -------------------------------------------------------------
-- Every title is distinct, so a NOT EXISTS-on-title guard cannot collapse rows.
-- ⚠ The CROSS JOIN LATERAL resolves each district by geo_id + mtfcc +
-- district_type. If it matches nothing the row VANISHES and no office is
-- inserted, with no error -- which is what the pre-flight slug check and the
-- per-district post-verify below exist to catch.

${officesSql()}

${verifySql()}

COMMIT;
`;
}

// ── the city occupancy half (Task 3) ─────────────────────────────────────────

const PTAG = 'macon-bibb people';
const SEED = 'mb_seed';

/** SQL text[] literal from a JS array of strings. */
const arr = (a) => (!a || a.length === 0 ? `'{}'::text[]` : `ARRAY[${a.map(q).join(', ')}]::text[]`);

function peopleFile() {
  const offices = city.offices;
  const ids = offices.map((o) => o.person.external_id).sort((a, b) => a - b);
  const bandMin = Math.min(...ids);
  const bandMax = Math.max(...ids);
  const idList = ids.join(', ');
  const dated = offices.filter((o) => o.person.term_start);
  const undated = offices.filter((o) => !o.person.term_start);
  const appointed = offices.filter((o) => o.person.how_started === 'appointed');
  const chamberNames = city.chambers.map((c) => q(c.name)).join(', ');
  const wideOffices = offices.filter((o) => o.district_geo_id === wide.geo_id && o.district_mtfcc === wide.mtfcc);
  const countyIds = county.offices.map((o) => o.person.external_id).sort((a, b) => a - b);

  const seedRows = offices
    .map((o) => {
      const p = o.person;
      return `  (${q(o.district_geo_id)}, ${q(o.district_mtfcc)}, ${q(DT)}, ${q(o.title)}, ${p.external_id}, ${q(p.full_name)}, ${q(p.first_name)}, ${q(p.last_name)}, ${q(p.middle_initial)}, ${q(p.name_suffix)}, ${arr(p.aliases)}, ${p.term_start ? `DATE ${q(p.term_start)}` : 'NULL::date'}, ${q(p.start_precision)}, ${q(p.how_started)}, ${q(p.source)})`;
    })
    .join(',\n');

  /**
   * 🔴 THE PAYLOAD'S OWN (id, date, precision, how_started) TUPLES, ASSERTED IN
   *    SQL BEFORE A SINGLE ROW IS WRITTEN. The roster validator already checks
   *    these in JS; this is the same claim restated where the write happens, and
   *    it is the guard that refuses the single most likely corruption of this
   *    wave -- giving everyone the county's published 2025-01-01.
   */
  const expectedTuples = offices
    .map((o) => {
      const p = o.person;
      return `    (${p.external_id}, ${p.term_start ? `DATE ${q(p.term_start)}` : 'NULL::date'}, ${q(p.start_precision)}, ${q(p.how_started)})`;
    })
    .join(',\n');

  // One explicit assertion per dated row. A generic "some rows are dated" check
  // would pass if a date were silently moved, dropped or added.
  const datedChecks = dated
    .map(
      (o) => `  SELECT count(*) INTO v_n
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE p.external_id = ${o.person.external_id}
     AND t.term_start = DATE ${q(o.person.term_start)}
     AND t.start_precision = ${q(o.person.start_precision)}
     AND t.how_started = ${q(o.person.how_started)}
     AND t.term_end IS NULL;
  IF v_n <> 1 THEN RAISE EXCEPTION '${PTAG}: ${o.person.full_name.replace(/'/g, "''")} (${o.person.external_id}) does not hold exactly one OPEN term starting ${o.person.term_start} at ${o.person.start_precision} precision, how_started ${o.person.how_started}; got %', v_n; END IF;`,
    )
    .join('\n\n');

  return `-- CC_wip_macon_bibb_people.sql
--
-- Knight Foundation cities program, wave GA-5 Task 3, CITY OCCUPANCY half.
--   * ${offices.length} politicians, ${offices.length} terms, 0 vacancies
--   * ALL ${offices.length} seated through essentials.seat_officeholder()
--   * ${dated.filter((o) => o.person.start_precision === 'day').length} at 'day' precision, ${dated.filter((o) => o.person.start_precision === 'month').length} at 'month', ${undated.length} open-ended
--   * ${appointed.length} carry how_started 'appointed'; the other ${offices.length - appointed.length} 'elected'
--
-- Roster: backend/data/seed-macon-bibb-2026/ROSTERS.md
-- Slice:  .planning/knight-foundation/ga.md
-- Generated by scripts/gen-ga5-macon-bibb-migrations.mjs from
-- data/ga5-macon-bibb-roster.json -- edit the roster and regenerate, do not
-- hand-edit this file.
--
-- 🔴 TAKE THE MIGRATION NUMBER LAST. CC_wip_ on purpose.
--
-- ⚠ THIS HALF CANNOT BE DRY-RUN ALONE -- its offices do not exist until the
--   structure half runs. Run both as ONE transaction ending in ROLLBACK and
--   assert the stream holds exactly one BEGIN, one ROLLBACK and ZERO COMMIT,
--   anchored on ^\\s*COMMIT\\s*; -- never a bare substring count of "commit".
--
-- ---------------------------------------------------------------------------
-- 🔴🔴 EVERY ONE OF THESE TEN PEOPLE GOES THROUGH seat_officeholder(), WHICH IS
--      THE HOUSE RULE AND WHICH COLUMBUS COULD NOT DO.
--
-- essentials.seat_officeholder() REFUSES a NULL term_start outright. GA-4 had to
-- direct-insert nine of eleven Columbus rows because Columbus publishes no
-- service-start of any kind. Macon-Bibb publishes enough that ALL TEN carry a
-- real date, so the helper does all ten and this migration hand-rolls nothing.
-- The refusal branch below is kept anyway, so that editing the roster to add an
-- undated person cannot silently bypass the helper.
--
-- ---------------------------------------------------------------------------
-- 🔴🔴 THE DATES ARE NOT UNIFORM, AND THE ONE SENTENCE MOST LIKELY TO CORRUPT
--      THIS MIGRATION IS ONE THE COUNTY ITSELF PUBLISHED.
--
-- Macon-Bibb wrote: "The four-year term of office for each of these officials
-- begins at 12:00 a.m. on January 1, 2025", and listed all ten. IT IS CORRECT
-- FOR TWO OF THEM. term_start is the start of CONTINUOUS OCCUPANCY, which
-- re-election does not end, so the commencement of a TERM is not the start of an
-- OCCUPANCY:
--
--   Lester Miller        Mayor    2021-01-01  day    elected
--   Valerie Wynn         D1       2018-06-01  MONTH  elected   (2018 special)
--   Paul Bronson         D2       2021-01-01  day    elected
--   Stanley Stewart      D3       2024-10-15  day    APPOINTED (the OATH)
--   Joey Hulett          D4       2025-01-01  day    elected   <-- new in 2025
--   Andrea Cooke         D5       2026-04-20  day    elected   (2026 special)
--   Raymond Wilder       D6       2021-01-01  day    elected
--   Bill Howell          D7       2021-01-01  day    elected
--   Donice Bryant        D8       2025-01-01  day    elected   <-- new in 2025
--   Brendalyn Bailey     D9       2024-01-17  day    APPOINTED
--
-- Taking the published sentence at face value would have back-dated three people
-- and forward-dated five. The payload guard below asserts the EXACT
-- (external_id, term_start, start_precision, how_started) tuple set, so a
-- wholesale substitution is refused in SQL and not only in the generator.
--
-- ---------------------------------------------------------------------------
-- 🔴 FOUR ROWS CARRY A DERIVED DATE, AND THE DERIVATION IS IN THE SOURCE STRING
--    RATHER THAN PRESENTED AS A QUOTATION.
--
-- Miller, Bronson, Wilder and Howell all begin 2021-01-01. No source quotes that
-- date. It is the charter's own commencement rule -- Sec. 9(c) and Sec. 10(b),
-- "shall take office on the first day of January immediately following the date
-- of the election" -- applied to a 2020 election that IS sourced, and the county
-- states the identical rule as fact for the 2025 cohort. Ruling recorded
-- 2026-09-01 (Cantrell): write it at 'day', derivation in the source string.
--
-- ⚠ THAT IS NOT THE GA-4 CHAPPLE CASE. There, a swearing-in date was inferred
--   from "Thursday morning" in an article and was correctly refused, written
--   'unknown'. A legal rule applied to a sourced election is a different thing
--   from a guess dressed as a date.
--
-- ---------------------------------------------------------------------------
-- 🔴 WYNN IS 'month', AND THAT IS DELIBERATE.
--
-- Gary Bechtel resigned District 1 to run for the state House. The special
-- election was 2018-05-22, the runoff 2018-06-19, and she won it 677-582 over
-- Lynn Wood. Reporting says she "could be sworn in by Friday" and would vote on
-- the budget in late July. NO SOURCE STATES THE OATH DATE, so the day is not
-- written. 2018-06-01 at 'month' precision is the honest record.
--
-- ---------------------------------------------------------------------------
-- 🔴 TWO ROWS ARE 'appointed', AND THE CHARTER IS WHY.
--
-- Sec. 15(a) orders a SPECIAL ELECTION for the balance of an unexpired term;
-- Sec. 15(b) lets the Commission APPOINT within 20 days if the vacancy falls
-- within 12 months of the term's expiry.
--
--   Stewart  Elaine Lucas stepped down in autumn 2024 to run for the Macon Water
--            Authority. The Commission voted to appoint on 2024-10-01 and he took
--            the OATH on Tuesday 2024-10-15, per the county's own post, with his
--            first Commission meeting that evening. He had already won the seat
--            for the term beginning 2025-01-01, so occupancy is continuous from
--            the oath.
--            ⚠ WGXA headlines this to the APPOINTMENT VOTE, 14 days early. THE
--              OATH IS THE OCCUPANCY, NOT THE VOTE.
--   Bailey   Al Tillman resigned effective immediately on 2024-01-09, inside 12
--            months of expiry. Sworn in 2024-01-17 on a 5-3 vote. She then won
--            the seat outright in May 2024, so occupancy is continuous.
--            ⚠ TWO PRESS ACCOUNTS SAY THE *MAYOR* APPOINTED HER. Sec. 15(b)
--              gives that power to "the commission or those remaining", and a 5-3
--              tally is a commission vote. how_started is 'appointed' either way,
--              but the prose must not repeat the error.
--
-- ---------------------------------------------------------------------------
-- 🔴 how_started 'special election' IS NOT A LEGAL VALUE.
--
-- essentials.office_terms carries
--   CHECK how_started IN ('elected','appointed','succeeded','redistricted','unknown')
-- measured against production 2026-09-01. Wynn and Cooke won SPECIAL elections;
-- a special election is an election, so how_started is 'elected' and the SPECIAL
-- fact lives in the source string and in this header.
--
-- ---------------------------------------------------------------------------
-- 🟢 CHANGE-CHECK RUN LIVE 2026-09-01, AND IT ASKED "HAS THIS PERSON LEFT?"
--
-- Read in BOTH directions. All ten holders below are present on
-- maconbibb.us/commissioners/ and on the county's own voter-facing GIS service.
-- And every one of these eight people who must NOT be present is absent:
--
--   Seth Clark        D5  RESIGNED 2026-01-05 to run for Lieutenant Governor
--   Elaine Lucas      D3  stepped down autumn 2024; term-limited
--   Al Tillman        D9  RESIGNED 2024-01-09, effective immediately
--   Mallory Jones III D4  term-limited, last meeting 2024-12-03
--   Virgil Watkins Jr D8  term-limited, last meeting 2024-12-03
--   Gary Bechtel      D1  resigned 2018 to run for the state House
--   Larry Schlesinger D2  seat vacant at the 2020 qualifying
--   Bert Bivins       D5  seat vacant at the 2020 qualifying
--
-- 🔴 THE CHECK IS NOT UNIFORM, WHICH IS ITS OWN POSITIVE CONTROL. Of the five
--    GIS layers that publish these districts, FOUR DO NOT KNOW ANDREA COOKE
--    EXISTS, and the superseded CountyDistrict layer still names Lucas, Clark
--    and Tillman -- three people who have all left. A roster read from the
--    first-listed layer would have seated three departed officials and missed
--    the only 2026 arrival. This is the check GA-3 ran against its SOURCES
--    instead of its SEATS, which put a retired coroner into production.
--
-- IDEMPOTENT: politicians insert ON CONFLICT DO NOTHING, the occupancy loop
-- skips any office+politician pair that already has a term row, and every
-- assertion is a statement about the END STATE.

BEGIN;

-- --- Politician identity band ----------------------------------------------
-- 🔴 NOBODY ELSE MAY ALREADY OWN THE IDS THIS WAVE IS ABOUT TO INSERT. That is
-- the FL-2 failure exactly: a band collided with 166 existing rows and
-- ON CONFLICT DO NOTHING would have absorbed it in silence, leaving seats held
-- by whoever already owned those ids.
--
-- ⚠ SCOPED TO THIS MIGRATION'S OWN SUB-RANGE ${bandMin}..${bandMax}, NOT to the wave
-- band ${r.id_band.min}..${r.id_band.max}. Task 4 owns ${countyIds[0]}..${countyIds[countyIds.length - 1]}; a guard over the whole
-- wave band would see Task 4's legitimate rows as foreign and break THIS
-- migration's re-run the moment Task 4 applies. That is the FL-4 correction.
DO $$
DECLARE v_n int; v_foreign text;
BEGIN
  SELECT count(*), string_agg(external_id::text, ', ' ORDER BY external_id)
    INTO v_n, v_foreign
    FROM essentials.politicians
   WHERE external_id BETWEEN ${bandMin} AND ${bandMax}
     AND external_id NOT IN (${idList});
  IF v_n <> 0 THEN
    RAISE EXCEPTION '${PTAG}: % row(s) inside this migration''s id range ${bandMin}..${bandMax} are owned by something else (%). Pick another sub-range rather than colliding.', v_n, v_foreign;
  END IF;
END $$;

-- 🔴 IDENTITY IS KEYED ON external_id, NEVER ON NAME. All ${offices.length} names were checked
-- against production 2026-09-01 by exact match and none matched. The surname
-- near misses are FEC committee ALLCAPS junk plus two genuinely different
-- people -- Christina Wynn, a California assessor, and Alexander Cooke. A
-- name-based guard is what seated a Colorado senator and a Utah treasurer in the
-- Georgia General Assembly, caught at GA-2 before it happened.

CREATE TEMP TABLE ${SEED} (
  geo_id          text,
  mtfcc           text,
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

INSERT INTO ${SEED} VALUES
${seedRows};

-- --- Payload guard ----------------------------------------------------------
DO $$
DECLARE v_n int; v_dup int; v_bad text;
BEGIN
  SELECT count(*) INTO v_n FROM ${SEED};
  IF v_n <> ${offices.length} THEN RAISE EXCEPTION '${PTAG} payload: expected ${offices.length} rows, got %', v_n; END IF;

  SELECT count(*) INTO v_dup FROM (SELECT ext_id FROM ${SEED} GROUP BY ext_id HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION '${PTAG} payload: % duplicate external_id(s)', v_dup; END IF;

  SELECT count(*) INTO v_n FROM ${SEED} WHERE ext_id NOT BETWEEN ${r.id_band.min} AND ${r.id_band.max};
  IF v_n <> 0 THEN RAISE EXCEPTION '${PTAG} payload: % out-of-band external_id(s)', v_n; END IF;

  -- Every (geo_id, mtfcc, district_type, title) is a single seat in this wave.
  SELECT count(*) INTO v_dup FROM (
    SELECT geo_id, mtfcc, district_type, office_title FROM ${SEED}
    GROUP BY geo_id, mtfcc, district_type, office_title HAVING count(*) > 1
  ) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION '${PTAG} payload: % duplicate seat key(s)', v_dup; END IF;

  -- 🔴 A DATE AND ITS PRECISION MUST AGREE IN BOTH DIRECTIONS.
  SELECT count(*) INTO v_n FROM ${SEED} WHERE term_start IS NULL AND start_precision <> 'unknown';
  IF v_n <> 0 THEN RAISE EXCEPTION '${PTAG} payload: % row(s) have no term_start but claim a precision', v_n; END IF;
  SELECT count(*) INTO v_n FROM ${SEED} WHERE term_start IS NOT NULL AND start_precision = 'unknown';
  IF v_n <> 0 THEN RAISE EXCEPTION '${PTAG} payload: % row(s) carry a term_start but declare it unknown', v_n; END IF;

  -- 🔴🔴 THE EXACT TUPLE SET, NOT A COUNT. This is the guard that refuses the
  -- single most likely corruption of this wave: giving all ten people the
  -- county's published 2025-01-01, which is right for exactly two of them.
  -- A count of dated rows cannot see a date that MOVED.
  SELECT count(*), string_agg(format('%s->%s/%s/%s', s.ext_id, s.term_start, s.start_precision, s.how_started), ', ' ORDER BY s.ext_id)
    INTO v_n, v_bad
    FROM ${SEED} s
   WHERE NOT EXISTS (
     SELECT 1 FROM (VALUES
${expectedTuples}
     ) AS e(ext_id, term_start, start_precision, how_started)
      WHERE e.ext_id = s.ext_id
        AND e.term_start IS NOT DISTINCT FROM s.term_start
        AND e.start_precision = s.start_precision
        AND e.how_started = s.how_started
   );
  IF v_n <> 0 THEN
    RAISE EXCEPTION '${PTAG} payload: % row(s) do not match the sourced (id, term_start, precision, how_started) tuple: %', v_n, v_bad;
  END IF;

  -- 🔴 EXACTLY ${appointed.length} ROWS ARE 'appointed', AND THEY ARE ${appointed.map((o) => o.person.last_name).join(' AND ')}.
  -- Charter Sec. 15(b): the Commission may appoint only when the vacancy falls
  -- within 12 months of the term's expiry. Everyone else was elected.
  SELECT count(*) INTO v_n FROM ${SEED} WHERE how_started = 'appointed';
  IF v_n <> ${appointed.length} THEN RAISE EXCEPTION '${PTAG} payload: expected ${appointed.length} appointed row(s), got %', v_n; END IF;
  SELECT count(*) INTO v_n FROM ${SEED}
   WHERE how_started = 'appointed' AND ext_id NOT IN (${appointed.map((o) => o.person.external_id).sort((a, b) => a - b).join(', ')});
  IF v_n <> 0 THEN RAISE EXCEPTION '${PTAG} payload: % appointed row(s) are not the expected two', v_n; END IF;

  -- 🔴 how_started IS A CHECKED ENUM. 'special election' is not in it, and Wynn
  -- and Cooke both won specials.
  SELECT count(*) INTO v_n FROM ${SEED}
   WHERE how_started NOT IN ('elected','appointed','succeeded','redistricted','unknown');
  IF v_n <> 0 THEN RAISE EXCEPTION '${PTAG} payload: % row(s) carry a how_started the CHECK will refuse', v_n; END IF;

  -- 🔴 EXACTLY ONE ROW IS 'month' PRECISION, AND IT IS WYNN. Everything else is
  -- 'day'. A wave that "tidied" her to a day would be inventing an oath date.
  SELECT count(*) INTO v_n FROM ${SEED} WHERE start_precision = 'month';
  IF v_n <> 1 THEN RAISE EXCEPTION '${PTAG} payload: expected exactly 1 month-precision row (Wynn), got %', v_n; END IF;

  -- ⚠ alternate_names is NOT NULL DEFAULT '{}'. Emit an empty array, never NULL.
  SELECT count(*) INTO v_n FROM ${SEED} WHERE aliases IS NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION '${PTAG} payload: % row(s) carry a NULL aliases array', v_n; END IF;

  -- And every seat named must resolve to exactly one office in prod.
  SELECT count(*) INTO v_n FROM ${SEED} s
   WHERE (SELECT count(*) FROM essentials.offices o
            JOIN essentials.districts d ON d.id = o.district_id
           WHERE d.geo_id = s.geo_id AND d.mtfcc = s.mtfcc
             AND d.district_type = s.district_type AND lower(d.state) = 'ga'
             AND o.title = s.office_title) <> 1;
  IF v_n <> 0 THEN RAISE EXCEPTION '${PTAG} payload: % seat(s) do not resolve to exactly one office -- run the structure half first', v_n; END IF;
END $$;

-- --- Politicians ------------------------------------------------------------
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, middle_initial, name_suffix,
   alternate_names, is_incumbent, is_active, data_source)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name,
       nullif(s.middle_initial, ''), nullif(s.name_suffix, ''),
       s.aliases, true, true, s.source
FROM ${SEED} s
ON CONFLICT (external_id) DO NOTHING;

-- --- Occupancy --------------------------------------------------------------
-- 🔴 ONE PATH: essentials.seat_officeholder(), for all ${offices.length}. Every person here
-- carries a real term_start, so the helper's refusal of NULL never fires and
-- nothing is hand-rolled. GA-4 had to direct-insert nine of eleven because
-- Columbus publishes no service-start at all; Macon-Bibb does.
--
-- ⚠ THE REFUSAL BRANCH IS KEPT ON PURPOSE. It is unreachable in this migration
--   (the payload guard above proves 0 undated rows), and it exists so that
--   editing the roster to add an undated person cannot silently bypass the
--   helper. An undated open-ended term is a legitimate record -- the ADR 0002
--   phase-2 backfill wrote 81,676 of them -- but it must be a decision, not a
--   side effect.
DO $$
DECLARE r record; v_seated int := 0; v_blank int := 0; v_prior int;
BEGIN
  FOR r IN
    SELECT s.term_start, s.start_precision, s.how_started, s.source,
           o.id AS office_id, p.id AS politician_id
      FROM ${SEED} s
      JOIN essentials.districts d
        ON d.geo_id = s.geo_id AND d.mtfcc = s.mtfcc
       AND d.district_type = s.district_type AND lower(d.state) = 'ga'
      JOIN essentials.offices o ON o.district_id = d.id AND o.title = s.office_title
      JOIN essentials.politicians p ON p.external_id = s.ext_id
     WHERE NOT EXISTS (
       SELECT 1 FROM essentials.office_terms t
        WHERE t.office_id = o.id AND t.politician_id = p.id
     )
  LOOP
    IF r.term_start IS NOT NULL THEN
      PERFORM essentials.seat_officeholder(
        r.office_id, r.politician_id, r.term_start, r.source, r.how_started, r.start_precision
      );
      v_seated := v_seated + 1;
    ELSE
      IF r.start_precision <> 'unknown' THEN
        RAISE EXCEPTION '${PTAG}: office % has no term_start but claims precision % -- refusing', r.office_id, r.start_precision;
      END IF;
      SELECT count(*) INTO v_prior FROM essentials.office_terms t WHERE t.office_id = r.office_id;
      IF v_prior <> 0 THEN
        RAISE EXCEPTION '${PTAG}: office % already carries % term row(s), so an undated open term cannot be inserted directly -- close the predecessor and give this person a real date', r.office_id, v_prior;
      END IF;
      INSERT INTO essentials.office_terms
        (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
      VALUES (r.office_id, r.politician_id, NULL, NULL, 'unknown', r.how_started, r.source);
      v_blank := v_blank + 1;
    END IF;
  END LOOP;
  RAISE NOTICE '${PTAG}: seated % official(s) via seat_officeholder(), % with an honest unknown start', v_seated, v_blank;
END $$;

-- --- Post-verify gate ------------------------------------------------------
-- 🔴 SCOPED TO THE TWO CITY CHAMBERS, NEVER TO THE GOVERNMENT. Macon-Bibb is
-- consolidated: Task 4's five county officers join this SAME government row, so
-- a government-wide seat count would pass today and fail forever afterwards.
DO $$
DECLARE v_gov uuid; v_n int; v_d text;
BEGIN
  SELECT id INTO v_gov FROM essentials.governments
   WHERE geo_id = ${q(gov.geo_id)} AND type = ${q(gov.type)};
  IF v_gov IS NULL THEN RAISE EXCEPTION '${PTAG}: the government row is missing -- apply the structure half first'; END IF;

  -- ⚠ COUNT THIS MIGRATION'S OWN IDS, NOT THE WHOLE BAND. Counting the band is
  -- what made CC_0009 non-idempotent once CC_0010 added its eleven.
  SELECT count(*) INTO v_n FROM essentials.politicians
   WHERE external_id IN (${idList});
  IF v_n <> ${offices.length} THEN RAISE EXCEPTION '${PTAG}: expected ${offices.length} of this migration''s politicians, got %', v_n; END IF;

  -- 🔴 count(och.politician_id), NOT count(*): office_current_holder LEFT JOINs
  -- from offices, so a vacancy is a NULL politician_id, never an absent row, and
  -- count(*) would pass VACUOUSLY on an entirely empty government.
  SELECT count(och.politician_id) INTO v_n
    FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.government_id = v_gov AND c.name IN (${chamberNames});
  IF v_n <> ${offices.length} THEN RAISE EXCEPTION '${PTAG}: expected ${offices.length} seated city officials, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name IN (${chamberNames}) AND o.is_vacant = true;
  IF v_n <> 0 THEN RAISE EXCEPTION '${PTAG}: % city office(s) flagged vacant, expected 0', v_n; END IF;

  -- One seated member per numbered district, counted PER DISTRICT. A single
  -- total can hide two holders on one district and none on another.
  FOR v_d IN SELECT ${q(city.district_geo_id_prefix)} || gs FROM generate_series(1,${city.district_count}) gs LOOP
    SELECT count(och.politician_id) INTO v_n
      FROM essentials.districts d
      JOIN essentials.offices o ON o.district_id = d.id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
     WHERE d.geo_id = v_d AND d.mtfcc = ${q(city.district_mtfcc)} AND d.district_type = ${q(DT)};
    IF v_n <> 1 THEN RAISE EXCEPTION '${PTAG}: district % has % holder(s), expected exactly 1', v_d, v_n; END IF;
  END LOOP;

  -- 🔴 EXACTLY ${wideOffices.length} HOLDER ON THE CITYWIDE DISTRICT: the Mayor. Columbus expects
  -- THREE here -- its Mayor plus at-large Posts 9 and 10 -- and Macon-Bibb has no
  -- at-large seats at all, so three would mean two commissioners had been seated
  -- on the wrong district.
  SELECT count(och.politician_id) INTO v_n
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.government_id = v_gov AND c.name IN (${chamberNames})
     AND d.geo_id = ${q(wide.geo_id)} AND d.mtfcc = ${q(wide.mtfcc)} AND d.district_type = ${q(DT)};
  IF v_n <> ${wideOffices.length} THEN RAISE EXCEPTION '${PTAG}: expected ${wideOffices.length} holder(s) on ${wide.label}, got %', v_n; END IF;

  -- 🔴 NOT ONE OF THESE TERMS CARRIES A term_end. A future term_end makes a seat
  -- silently self-vacate on a date nobody watches (spec §4.1).
  SELECT count(*) INTO v_n
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE p.external_id IN (${idList}) AND t.term_end IS NOT NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION '${PTAG}: % term row(s) carry a term_end -- none may', v_n; END IF;

  -- 🔴 AND EACH DATED ROW CARRIES EXACTLY THE DATE THAT WAS SOURCED, asserted
  -- INDIVIDUALLY by external_id. A count of "how many are dated" cannot see a
  -- date that moved, and the value most likely to be substituted here is
  -- 2025-01-01 for everyone -- the county's own published sentence, which is
  -- right for exactly two of the ten.
${datedChecks}

  -- No city office may be left with no term row at all: that is the
  -- invisible-office failure, and nothing else errors.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name IN (${chamberNames})
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id);
  IF v_n <> 0 THEN RAISE EXCEPTION '${PTAG}: % city office(s) carry no office_terms row and are invisible', v_n; END IF;

  RAISE NOTICE '${PTAG} OK: ${offices.length} politicians, ${offices.length} seated across ${offices.length} city offices, 0 vacancies (${dated.filter((o) => o.person.start_precision === 'day').length} day, ${dated.filter((o) => o.person.start_precision === 'month').length} month, ${appointed.length} appointed), all via seat_officeholder()';
END $$;

COMMIT;
`;
}

// ── the county half (Task 4) ─────────────────────────────────────────────────
//
// 🔴 ONE MIGRATION, per spec §3: offices AND people AND terms together. An office
//    with no office_terms row is INVISIBLE -- no holder, so the official appears
//    nowhere in Essentials, and NOTHING ERRORS. Splitting this would push
//    offices_missing_terms above its 655-unflagged baseline in between.

const CTAG = 'bibb county';
const CSEED = 'bibb_seed';
const wideC = county.countywide_district;

function countyFile() {
  const offices = county.offices;
  const ids = offices.map((o) => o.person.external_id).sort((a, b) => a - b);
  const bandMin = Math.min(...ids);
  const bandMax = Math.max(...ids);
  const idList = ids.join(', ');
  const dated = offices.filter((o) => o.person.term_start);
  const undated = offices.filter((o) => !o.person.term_start);
  const cityIds = city.offices.map((o) => o.person.external_id).sort((a, b) => a - b);
  const ch = county.chambers[0];

  const seedRows = offices
    .map((o) => {
      const p = o.person;
      return `  (${q(o.district_geo_id)}, ${q(o.district_mtfcc)}, ${q(CDT)}, ${q(o.title)}, ${p.external_id}, ${q(p.full_name)}, ${q(p.first_name)}, ${q(p.last_name)}, ${q(p.middle_initial)}, ${q(p.name_suffix)}, ${arr(p.aliases)}, ${p.term_start ? `DATE ${q(p.term_start)}` : 'NULL::date'}, ${q(p.start_precision)}, ${q(p.how_started)}, ${q(p.source)})`;
    })
    .join(',\n');

  const expectedTuples = offices
    .map((o) => {
      const p = o.person;
      return `    (${p.external_id}, ${p.term_start ? `DATE ${q(p.term_start)}` : 'NULL::date'}, ${q(p.start_precision)}, ${q(p.how_started)})`;
    })
    .join(',\n');

  const officeInserts = offices
    .map(
      (o) => `INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, representing_city, voting_powers)
SELECT c.id, d.id, ${q(o.title)}, 'GA', NULL, ${q(o.voting_powers)}
FROM essentials.chambers c
JOIN essentials.governments g ON g.id = c.government_id
CROSS JOIN LATERAL (
  SELECT dd.id FROM essentials.districts dd
   WHERE dd.geo_id = ${q(o.district_geo_id)} AND dd.mtfcc = ${q(o.district_mtfcc)}
     AND dd.district_type = ${q(CDT)} AND lower(dd.state) = 'ga'
) d
WHERE g.geo_id = ${q(gov.geo_id)} AND g.type = ${q(gov.type)} AND c.name = ${q(ch.name)}
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = ${q(o.title)}
  );`,
    )
    .join('\n');

  const datedChecks = dated
    .map(
      (o) => `  SELECT count(*) INTO v_n
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE p.external_id = ${o.person.external_id}
     AND t.term_start = DATE ${q(o.person.term_start)}
     AND t.start_precision = ${q(o.person.start_precision)}
     AND t.how_started = ${q(o.person.how_started)}
     AND t.term_end IS NULL;
  IF v_n <> 1 THEN RAISE EXCEPTION '${CTAG}: ${o.person.full_name.replace(/'/g, "''")} (${o.person.external_id}) does not hold exactly one OPEN term starting ${o.person.term_start} at ${o.person.start_precision} precision, got %', v_n; END IF;`,
    )
    .join('\n\n');

  return `-- CC_wip_bibb_county.sql
--
-- Knight Foundation cities program, wave GA-5 Task 4, BIBB COUNTY --
-- offices AND people AND terms in ONE migration, per spec §3.
--   * 1 chamber on the EXISTING Macon-Bibb County Government
--   * 0 districts created -- the countywide district already exists
--   * ${offices.length} offices, ${offices.length} politicians, ${offices.length} terms, 0 vacancies
--   * ${dated.length} dated at 'year'; ${undated.length} open-ended at 'unknown'
--
-- Roster: backend/data/seed-macon-bibb-2026/ROSTERS.md
-- Slice:  .planning/knight-foundation/ga.md
-- Generated by scripts/gen-ga5-macon-bibb-migrations.mjs from
-- data/ga5-macon-bibb-roster.json -- edit the roster and regenerate, do not
-- hand-edit this file.
--
-- 🔴 TAKE THE MIGRATION NUMBER LAST. CC_wip_ on purpose.
--
-- ⚠ THIS HALF CANNOT BE DRY-RUN ALONE -- its chamber hangs off a government the
--   structure half creates. Run all THREE halves as ONE transaction ending in
--   ROLLBACK and assert the stream holds zero executable COMMIT beforehand.
--   🔴 Assert on \`^\\s*COMMIT\\s*;\`, NOT on a substring count: this file contains
--   the word "commit" legitimately, in prose and in ON COMMIT DROP.
--
-- ---------------------------------------------------------------------------
-- 🔴🔴 CONSOLIDATION MERGES THE LEGISLATIVE BODY ONLY. THERE IS NO COUNTY
--      COMMISSION HERE, AND THAT IS THE WHOLE DIFFERENCE FROM BALDWIN.
--
-- The Macon-Bibb County Commission IS the county legislature, so stage 4 drops
-- the county commission entirely and keeps only the separately elected county
-- officers. This chamber therefore attaches to the SAME government row the
-- structure half created -- one government, three chambers.
--
-- 🔴 EVERY COUNT IN THE POST-VERIFY IS SCOPED TO THIS ONE CHAMBER, never to the
--    government. A government-wide count here would couple this migration to the
--    two city halves in both directions.
--
-- ---------------------------------------------------------------------------
-- 🔴 RULING M4: FIVE OFFICERS, BY THE MIRROR IMAGE OF MUSCOGEE'S ROUTE.
--
-- Charter Sec. 8 preserves FOUR through consolidation, by name: "the duties of
-- the sheriff, the tax commissioner, the coroner, and the clerk of the superior
-- court shall remain as such duties are presently imposed by law for such
-- respective officers as county officers".
--
-- The Judge of Probate Court is NOT in Sec. 8 and comes in the way Muscogee's
-- Clerk of Superior Court did -- Ga. Const. Art. IX, Sec. I, Par. III names it a
-- county officer, and consolidation cannot reach it. 🔴 THAT IS THE MIRROR OF
-- GA-4: at Muscogee the charter named the probate judge and the CLERK arrived by
-- Art. IX. The count matches at five by coincidence, not by inheritance.
--
-- 🟢 THE COUNTY'S OWN OFFICERS CONFIRM THE SET. In December 2025 "Bibb County
--    sheriff David Davis, probate judge Sarah Harris and clerk of court Erica
--    Woodford, along with tax commissioner Wade McCord, another constitutional
--    officer" acted JOINTLY to change the county's legal organ, effective
--    2026-01-01 -- an act only constitutional officers perform. The probate judge
--    is inside that group. The Solicitor of State Court is not.
--
-- 🔴 BIBB ELECTS NO MARSHAL AND NO SURVEYOR. Baldwin elected both and was seated
--    with six officers two waves ago. Neither Baldwin's six nor Muscogee's five
--    was inherited; both were re-derived from this charter.
--
-- EXCLUDED, each for a stated reason:
--   Solicitor of State Court       a prosecutor -- the FL-5 rule against Palm
--   (Rebecca Grist)                Beach's State Attorney, and Baldwin's
--                                  Solicitor General. On the 2024 ballot.
--   Judge, Civil & Magistrate      judicial branch, Ga. Const. Art. VI -- the
--   Court                          line Baldwin drew for its Chief Magistrate.
--                                  On the 2026 ballot.
--   District Attorney,             MULTI-COUNTY circuit -- the FL-5 ruling
--   Macon Judicial Circuit         exactly. On the 2024 ballot.
--   Superior Court judges,         multi-county AND Art. VI
--   Macon Judicial Circuit
--   Macon Water Authority          a separate authority, spec §11. Elaine Lucas
--   (districts 1-3)                left the Commission to run for it.
--   Bibb County Board of Education spec §11
--   Clerk of Commission            APPOINTED by the Commission, not elected
--
-- ✅ RULING M5: GA-4'S MUNICIPAL-COURT QUESTION DOES NOT ARISE HERE. GA-4 ruled
--    that Muscogee's elected Municipal Court Clerk and Judge are excluded, and
--    recorded the counter-argument with the prediction that "Macon-Bibb,
--    Philadelphia and Lexington will each raise it again". Macon-Bibb does not:
--    charter Sec. 7 fills the office of judge of the Municipal Court of
--    Macon-Bibb County "by appointment of the mayor", so there is no elected
--    municipal-court office to include or exclude. Confirmed independently by
--    the ballot enumeration -- no municipal-court contest appears in any Bibb
--    payload. 🔴 THE QUESTION STAYS LIVE FOR PHILADELPHIA AND LEXINGTON.
--
-- ---------------------------------------------------------------------------
-- 🔴 THE COUNTYWIDE DISTRICT IS ASSERTED, NEVER CREATED.
--
-- The TIGER county load already made ${wideC.geo_id}/${wideC.mtfcc} a ${CDT} district -- verified in
-- production 2026-09-01: 1 row, carrying 0 offices. Inserting it again would lay
-- a second district over the same ground. The pre-flight FAILS HARD if it is
-- missing: the five officers have nowhere to sit without it.
--
-- ⚠ It covers the SAME 254.906 sq mi as the citywide LOCAL district the structure
--   half created. That is correct and unavoidable under consolidation: same
--   ground, two tiers. The post-verify asserts the tiers were not crossed, which
--   is the mirror of the gate the structure half applies to the city seats.
--
-- 🔴 AND district_type IS THE ONLY THING SEPARATING THEM, because Georgia's
--    geo_id collision is THREE-WAY: bare '${wideC.geo_id}' matches this COUNTY district AND
--    State House District 21 AND State Senate District 21. Measured in
--    production, not assumed.
--
-- ---------------------------------------------------------------------------
-- 🟢 THE CHANGE-CHECK WAS RUN LIVE AND IT ASKED "HAS THIS PERSON LEFT?"
--
--   Sheriff        David Davis        his own office, live. First elected
--                                     November 2012. ⚠ The same bio still reads
--                                     "re-elected to his third term in November
--                                     of 2020" and has not been updated for
--                                     2024 -- a STALE SENTENCE ON A MAINTAINED
--                                     SITE, used only for the FIRST election.
--   Clerk          Erica Woodford     her own office. ⚠ The 41NBC 2020
--                                     qualifying list spells her "Eric
--                                     Woodford"; that is a TYPO and is NOT
--                                     carried as an alias -- a dropped letter is
--                                     not an alternative rendering, and an alias
--                                     that is a typo can match the wrong person.
--                                     (Contrast GA-4, where the ballot's ASCII
--                                     "Danielle F. Forte" WAS kept as an alias,
--                                     because a diacritic-stripped form is a
--                                     legitimate rendering of the same name.)
--   Tax Comm.      Wade McCord        the county quotes him directly, and also
--                                     writes "Tax Commissioner, S. Wade McCord";
--                                     court captions read "Samuel Wade McCord".
--                                     Both kept as aliases. He succeeded Thomas
--                                     W. Tedders, Jr.
--   Probate Judge  Sarah S. Harris    her own court. Re-elected to her FOURTH
--                                     term in 2024, having been elected
--                                     unopposed in 2012 succeeding retired Judge
--                                     William J. Self.
--   Coroner        Leon Jones         🟢 THE FRESHEST OCCUPANCY EVIDENCE IN THE
--                                     WAVE: reported working a scene in JULY
--                                     2026, and quoted on the county's murder
--                                     count in March 2026. That is precisely
--                                     what Baldwin's coroner lacked in GA-3,
--                                     where every source agreed with every other
--                                     and all of them predated his retirement.
--
-- ▶ RE-RUN THIS CHECK ON THE DAY OF APPLY. A change-check asks whether the
--   person has LEFT, and sources agreeing is not currency.
--
-- ---------------------------------------------------------------------------
-- 🔴 ${undated.length} TERMS ARE OPEN-ENDED AT 'unknown', AND THAT IS THE HONEST RECORD.
--
-- Woodford, McCord and Jones are all confirmed IN OFFICE, but no source examined
-- states when their occupancy began. ⚠ Coroner Jones has "been elected six
-- times" with a term ending 2028, which would arithmetically place him in office
-- from 2005 -- THAT IS ARITHMETIC ON A PRESS PHRASE, NOT A SOURCE, and it is not
-- written. Columbus wrote nine of eleven this way.
--
-- 🔴 THE TWO DATED ROWS ARE 'year', NOT 'day'. Davis was "first elected Sheriff
--    of Bibb County in November of 2012" and Harris elected unopposed in 2012;
--    Georgia county officers take office the following January, so 2013 is
--    sourced and the DAY is not. ⚠ Harris succeeded a RETIRED judge, which leaves
--    open whether she first filled a remainder by appointment -- another reason
--    the day is not written.
--
-- ---------------------------------------------------------------------------
-- ⚠ THIS HALF NEEDS BOTH SEATING PATHS, WHERE TASK 3 NEEDED ONLY ONE.
--
-- All ten city officials carry a real term_start, so Task 3 puts every one of
-- them through seat_officeholder(). Here ${undated.length} of ${offices.length} have no published start of
-- any kind, and the helper REFUSES a NULL term_start outright. So ${dated.length} go through
-- the helper and ${undated.length} are inserted directly -- but ONLY into an office with zero
-- existing term rows. That condition is what makes bypassing the helper safe:
-- the helper's two-step exists to close a predecessor before an open-ended range
-- overlaps it, and with no predecessor there is nothing to close and the
-- exclusion constraint cannot fire. The guard below REFUSES rather than guesses
-- if that stops being true.
--
-- IDEMPOTENT: every insert is NOT EXISTS-guarded or ON CONFLICT DO NOTHING, the
-- occupancy loop skips any office+politician pair that already has a term row,
-- and every assertion is a statement about the END STATE.

BEGIN;

-- --- 0. Pre-flight ----------------------------------------------------------
-- 🔴 THIS MIGRATION CREATES NO GOVERNMENT AND NO DISTRICT. Both must already
-- exist, and their ABSENCE is a hard stop rather than something to insert
-- around.
DO $$
DECLARE v_n int;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM essentials.governments WHERE geo_id = ${q(gov.geo_id)} AND type = ${q(gov.type)}
  ) THEN
    RAISE EXCEPTION '${CTAG}: the ${gov.name} row is missing -- apply the city structure half first';
  END IF;

  -- ⚠ ALWAYS PAIR geo_id WITH mtfcc AND district_type. Georgia's collision is
  -- THREE-WAY, and this wave carries a LOCAL district over the SAME ground as
  -- this COUNTY one -- so district_type is the only thing separating the tiers.
  IF NOT EXISTS (
    SELECT 1 FROM essentials.geofence_boundaries
     WHERE geo_id = ${q(wideC.geo_id)} AND mtfcc = ${q(wideC.mtfcc)}
  ) THEN
    RAISE EXCEPTION '${CTAG}: boundary ${wideC.geo_id}/${wideC.mtfcc} is missing -- the TIGER county load must be applied first';
  END IF;

  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE geo_id = ${q(wideC.geo_id)} AND mtfcc = ${q(wideC.mtfcc)}
     AND district_type = ${q(CDT)} AND lower(state) = 'ga';
  IF v_n <> 1 THEN
    RAISE EXCEPTION '${CTAG}: expected exactly 1 existing ${wideC.mtfcc} ${CDT} district ${wideC.geo_id}, found % -- this migration does not create it', v_n;
  END IF;
END $$;

-- --- 1. Chamber -------------------------------------------------------------
-- ⚠ chambers.slug is GENERATED from name_formal and cannot be inserted.
-- ⚠ The name carries "Bibb County" rather than a bare "Elected Officials",
-- because under consolidation this chamber shares a government row with two CITY
-- chambers and a bare name would read as the city's.

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT g.id, ${q(ch.name)}, ${q(ch.name_formal)}, ${ch.official_count}, 'full'
FROM essentials.governments g
WHERE g.geo_id = ${q(gov.geo_id)} AND g.type = ${q(gov.type)}
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = ${q(ch.name)}
  );

-- --- 2. Offices -------------------------------------------------------------
-- ⚠ representing_city is NULL: these are COUNTY officers, following Baldwin
-- (CC_0029) and Muscogee (CC_0036). Under consolidation they serve the same
-- ground as the city, but the seat is a county seat and the column should not
-- imply otherwise.

${officeInserts}

-- --- 3. Politician identity band --------------------------------------------
-- ⚠ SCOPED TO THIS MIGRATION'S OWN SUB-RANGE ${bandMin}..${bandMax}, NOT to the wave
-- band ${r.id_band.min}..${r.id_band.max}. Task 3 owns ${cityIds[0]}..${cityIds[cityIds.length - 1]}; a guard over the whole
-- wave band would see Task 3's legitimate rows as foreign and break THIS
-- migration's re-run. That is the FL-4 correction.
DO $$
DECLARE v_n int; v_foreign text;
BEGIN
  SELECT count(*), string_agg(external_id::text, ', ' ORDER BY external_id)
    INTO v_n, v_foreign
    FROM essentials.politicians
   WHERE external_id BETWEEN ${bandMin} AND ${bandMax}
     AND external_id NOT IN (${idList});
  IF v_n <> 0 THEN
    RAISE EXCEPTION '${CTAG}: % row(s) inside this migration''s id range ${bandMin}..${bandMax} are owned by something else (%). Pick another sub-range rather than colliding.', v_n, v_foreign;
  END IF;
END $$;

CREATE TEMP TABLE ${CSEED} (
  geo_id          text,
  mtfcc           text,
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

INSERT INTO ${CSEED} VALUES
${seedRows};

-- --- 4. Payload guard -------------------------------------------------------
DO $$
DECLARE v_n int; v_dup int; v_bad text;
BEGIN
  SELECT count(*) INTO v_n FROM ${CSEED};
  IF v_n <> ${offices.length} THEN RAISE EXCEPTION '${CTAG} payload: expected ${offices.length} rows, got %', v_n; END IF;

  SELECT count(*) INTO v_dup FROM (SELECT ext_id FROM ${CSEED} GROUP BY ext_id HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION '${CTAG} payload: % duplicate external_id(s)', v_dup; END IF;

  SELECT count(*) INTO v_n FROM ${CSEED} WHERE ext_id NOT BETWEEN ${r.id_band.min} AND ${r.id_band.max};
  IF v_n <> 0 THEN RAISE EXCEPTION '${CTAG} payload: % out-of-band external_id(s)', v_n; END IF;

  SELECT count(*) INTO v_dup FROM (
    SELECT geo_id, mtfcc, district_type, office_title FROM ${CSEED}
    GROUP BY geo_id, mtfcc, district_type, office_title HAVING count(*) > 1
  ) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION '${CTAG} payload: % duplicate seat key(s)', v_dup; END IF;

  -- 🔴 EVERY ROW IS district_type '${CDT}'. The city half wrote 'LOCAL' over the
  -- SAME 254.906 sq mi, so this is the only column separating the two tiers.
  SELECT count(*) INTO v_n FROM ${CSEED} WHERE district_type <> ${q(CDT)};
  IF v_n <> 0 THEN RAISE EXCEPTION '${CTAG} payload: % row(s) are not district_type ${CDT}', v_n; END IF;

  -- A date and its precision must agree in both directions.
  SELECT count(*) INTO v_n FROM ${CSEED} WHERE term_start IS NULL AND start_precision <> 'unknown';
  IF v_n <> 0 THEN RAISE EXCEPTION '${CTAG} payload: % row(s) have no term_start but claim a precision', v_n; END IF;
  SELECT count(*) INTO v_n FROM ${CSEED} WHERE term_start IS NOT NULL AND start_precision = 'unknown';
  IF v_n <> 0 THEN RAISE EXCEPTION '${CTAG} payload: % row(s) carry a term_start but declare it unknown', v_n; END IF;

  -- 🔴🔴 THE EXACT TUPLE SET, NOT A COUNT -- the same guard Task 3 carries.
  -- Here the likeliest corruption is the opposite of Task 3's: "tidying" the
  -- three open-ended officers into a plausible January, or promoting the two
  -- 'year' rows to 'day'. A count of dated rows cannot see either.
  SELECT count(*), string_agg(format('%s->%s/%s/%s', s.ext_id, s.term_start, s.start_precision, s.how_started), ', ' ORDER BY s.ext_id)
    INTO v_n, v_bad
    FROM ${CSEED} s
   WHERE NOT EXISTS (
     SELECT 1 FROM (VALUES
${expectedTuples}
     ) AS e(ext_id, term_start, start_precision, how_started)
      WHERE e.ext_id = s.ext_id
        AND e.term_start IS NOT DISTINCT FROM s.term_start
        AND e.start_precision = s.start_precision
        AND e.how_started = s.how_started
   );
  IF v_n <> 0 THEN
    RAISE EXCEPTION '${CTAG} payload: % row(s) do not match the sourced (id, term_start, precision, how_started) tuple: %', v_n, v_bad;
  END IF;

  -- 🔴 EXACTLY ${dated.length} ROWS ARE DATED, AND BOTH ARE 'year' -- the Sheriff and the
  -- Judge of Probate Court, each first elected in 2012 and taking office the
  -- following January. NOT ONE is 'day': the day is not sourced for either.
  SELECT count(*) INTO v_n FROM ${CSEED} WHERE term_start IS NOT NULL;
  IF v_n <> ${dated.length} THEN RAISE EXCEPTION '${CTAG} payload: expected ${dated.length} dated row(s), got %', v_n; END IF;
  SELECT count(*) INTO v_n FROM ${CSEED} WHERE term_start IS NOT NULL AND start_precision <> 'year';
  IF v_n <> 0 THEN RAISE EXCEPTION '${CTAG} payload: % dated row(s) claim a precision finer than the sourced year', v_n; END IF;

  -- 🔴 AND EXACTLY ${undated.length} ARE OPEN-ENDED. Promoting one of them to a guessed
  -- January would be a false statement about history that no end_precision
  -- exists to soften.
  SELECT count(*) INTO v_n FROM ${CSEED} WHERE term_start IS NULL;
  IF v_n <> ${undated.length} THEN RAISE EXCEPTION '${CTAG} payload: expected ${undated.length} open-ended row(s), got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM ${CSEED}
   WHERE how_started NOT IN ('elected','appointed','succeeded','redistricted','unknown');
  IF v_n <> 0 THEN RAISE EXCEPTION '${CTAG} payload: % row(s) carry a how_started the CHECK will refuse', v_n; END IF;

  -- ⚠ alternate_names is NOT NULL DEFAULT '{}'. Emit an empty array, never NULL.
  SELECT count(*) INTO v_n FROM ${CSEED} WHERE aliases IS NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION '${CTAG} payload: % row(s) carry a NULL aliases array', v_n; END IF;

  SELECT count(*) INTO v_n FROM ${CSEED} s
   WHERE (SELECT count(*) FROM essentials.offices o
            JOIN essentials.districts d ON d.id = o.district_id
           WHERE d.geo_id = s.geo_id AND d.mtfcc = s.mtfcc
             AND d.district_type = s.district_type AND lower(d.state) = 'ga'
             AND o.title = s.office_title) <> 1;
  IF v_n <> 0 THEN RAISE EXCEPTION '${CTAG} payload: % seat(s) do not resolve to exactly one office', v_n; END IF;
END $$;

-- --- 5. Politicians ---------------------------------------------------------
-- 🔴 IDENTITY IS KEYED ON external_id, NEVER ON NAME. All ${offices.length} were checked against
-- production by EXACT match and none matched. The surname near misses are FEC
-- committee ALLCAPS junk plus genuinely different people. A name-based guard is
-- what seated a Colorado senator and a Utah treasurer in the Georgia General
-- Assembly, caught at GA-2 before it happened.
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, middle_initial, name_suffix,
   alternate_names, is_incumbent, is_active, data_source)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name,
       nullif(s.middle_initial, ''), nullif(s.name_suffix, ''),
       s.aliases, true, true, s.source
FROM ${CSEED} s
ON CONFLICT (external_id) DO NOTHING;

-- --- 6. Occupancy -----------------------------------------------------------
-- 🔴 TWO PATHS, AND THE SECOND ONE IS NOT A SHORTCUT. seat_officeholder()
-- REFUSES a NULL term_start, and ${undated.length} of these ${offices.length} have no published start of
-- any kind. Direct insert is safe ONLY into an office with zero existing term
-- rows; the guard REFUSES rather than guesses if that stops being true.
--
-- ⚠ Task 3 needed only the helper path, because every city official has a real
--   date. That difference is a fact about what Macon-Bibb publishes, not a
--   choice -- and it is why the direct path still has to exist and be guarded.
DO $$
DECLARE r record; v_seated int := 0; v_blank int := 0; v_prior int;
BEGIN
  FOR r IN
    SELECT s.term_start, s.start_precision, s.how_started, s.source,
           o.id AS office_id, p.id AS politician_id
      FROM ${CSEED} s
      JOIN essentials.districts d
        ON d.geo_id = s.geo_id AND d.mtfcc = s.mtfcc
       AND d.district_type = s.district_type AND lower(d.state) = 'ga'
      JOIN essentials.offices o ON o.district_id = d.id AND o.title = s.office_title
      JOIN essentials.politicians p ON p.external_id = s.ext_id
     WHERE NOT EXISTS (
       SELECT 1 FROM essentials.office_terms t
        WHERE t.office_id = o.id AND t.politician_id = p.id
     )
  LOOP
    IF r.term_start IS NOT NULL THEN
      PERFORM essentials.seat_officeholder(
        r.office_id, r.politician_id, r.term_start, r.source, r.how_started, r.start_precision
      );
      v_seated := v_seated + 1;
    ELSE
      IF r.start_precision <> 'unknown' THEN
        RAISE EXCEPTION '${CTAG}: office % has no term_start but claims precision % -- refusing', r.office_id, r.start_precision;
      END IF;
      SELECT count(*) INTO v_prior FROM essentials.office_terms t WHERE t.office_id = r.office_id;
      IF v_prior <> 0 THEN
        RAISE EXCEPTION '${CTAG}: office % already carries % term row(s), so an undated open term cannot be inserted directly -- close the predecessor and give this person a real date', r.office_id, v_prior;
      END IF;
      INSERT INTO essentials.office_terms
        (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
      VALUES (r.office_id, r.politician_id, NULL, NULL, 'unknown', r.how_started, r.source);
      v_blank := v_blank + 1;
    END IF;
  END LOOP;
  RAISE NOTICE '${CTAG}: seated % dated officer(s) via seat_officeholder(), % with an honest unknown start', v_seated, v_blank;
END $$;

-- --- 7. Post-verify gate ----------------------------------------------------
-- 🔴 SCOPED TO THIS ONE CHAMBER, never to the government: the same government
-- row carries the two CITY chambers, and a government-wide count would couple
-- this migration to them in both directions.
DO $$
DECLARE v_gov uuid; v_ch uuid; v_n int;
BEGIN
  SELECT id INTO v_gov FROM essentials.governments
   WHERE geo_id = ${q(gov.geo_id)} AND type = ${q(gov.type)};
  IF v_gov IS NULL THEN RAISE EXCEPTION '${CTAG}: the government row is missing'; END IF;

  SELECT id INTO v_ch FROM essentials.chambers
   WHERE government_id = v_gov AND name = ${q(ch.name)} AND official_count = ${ch.official_count};
  IF v_ch IS NULL THEN RAISE EXCEPTION '${CTAG}: the ${ch.name} chamber is missing or carries the wrong official_count'; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices WHERE chamber_id = v_ch;
  IF v_n <> ${offices.length} THEN RAISE EXCEPTION '${CTAG}: expected ${offices.length} offices in the chamber, got %', v_n; END IF;

  -- 🔴🔴 THE TIERS MUST NOT HAVE CROSSED. The citywide LOCAL district covers the
  -- SAME 254.906 sq mi as this COUNTY one, so an office landing on the wrong one
  -- would still resolve at every address in Macon and look entirely correct --
  -- only the tier would be wrong, and nothing would error. This is the MIRROR of
  -- the gate the structure half applies to the ten city seats.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE o.chamber_id = v_ch
     AND NOT (d.geo_id = ${q(wideC.geo_id)} AND d.mtfcc = ${q(wideC.mtfcc)} AND d.district_type = ${q(CDT)});
  IF v_n <> 0 THEN RAISE EXCEPTION '${CTAG}: % county office(s) do not sit on ${wideC.geo_id}/${wideC.mtfcc} ${CDT} -- the tiers crossed', v_n; END IF;

  -- And the countywide district was not duplicated by this migration.
  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE geo_id = ${q(wideC.geo_id)} AND mtfcc = ${q(wideC.mtfcc)} AND district_type = ${q(CDT)};
  IF v_n <> 1 THEN RAISE EXCEPTION '${CTAG}: expected exactly 1 ${wideC.label} ${CDT} district, got %', v_n; END IF;

  -- ⚠ COUNT THIS MIGRATION'S OWN IDS, NOT THE WHOLE BAND.
  SELECT count(*) INTO v_n FROM essentials.politicians WHERE external_id IN (${idList});
  IF v_n <> ${offices.length} THEN RAISE EXCEPTION '${CTAG}: expected ${offices.length} of this migration''s politicians, got %', v_n; END IF;

  -- 🔴 count(och.politician_id), NOT count(*): office_current_holder LEFT JOINs
  -- from offices, so a vacancy is a NULL politician_id and count(*) passes
  -- VACUOUSLY on an entirely unseated chamber.
  SELECT count(och.politician_id) INTO v_n
    FROM essentials.offices o
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE o.chamber_id = v_ch;
  IF v_n <> ${offices.length} THEN RAISE EXCEPTION '${CTAG}: expected ${offices.length} seated officers, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.offices WHERE chamber_id = v_ch AND is_vacant = true;
  IF v_n <> 0 THEN RAISE EXCEPTION '${CTAG}: % officer seat(s) flagged vacant, expected 0', v_n; END IF;

  -- The ${undated.length} undated terms are open-ended at 'unknown', with NO term_end: a
  -- future term_end makes a seat silently self-vacate on a date nobody watches.
  SELECT count(*) INTO v_n
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE p.external_id IN (${undated.map((o) => o.person.external_id).sort((a, b) => a - b).join(', ')})
     AND (t.start_precision <> 'unknown' OR t.term_start IS NOT NULL OR t.term_end IS NOT NULL);
  IF v_n <> 0 THEN RAISE EXCEPTION '${CTAG}: % term row(s) that should be open-ended unknown are not', v_n; END IF;

  -- 🔴 NOT ONE of this migration's terms carries a term_end.
  SELECT count(*) INTO v_n
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE p.external_id IN (${idList}) AND t.term_end IS NOT NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION '${CTAG}: % term row(s) carry a term_end -- none may', v_n; END IF;

  -- And each dated one carries exactly the date that was sourced, at the
  -- precision the source actually supports, asserted INDIVIDUALLY.
${datedChecks}

  -- No officer seat may be left with no term row: that is the invisible-office
  -- failure, and nothing else errors.
  SELECT count(*) INTO v_n FROM essentials.offices o
   WHERE o.chamber_id = v_ch
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id);
  IF v_n <> 0 THEN RAISE EXCEPTION '${CTAG}: % officer seat(s) carry no office_terms row and are invisible', v_n; END IF;

  RAISE NOTICE '${CTAG} OK: 1 chamber, ${offices.length} offices, ${offices.length} officers seated, 0 vacancies, 0 districts created (${dated.length} dated at year, ${undated.length} open-ended unknown)';
END $$;

COMMIT;
`;
}

// ── emit ─────────────────────────────────────────────────────────────────────

const structOut = join(OUT_DIR, 'CC_wip_macon_bibb_structure.sql');
writeFileSync(structOut, structureFile(), 'utf8');
console.log(`wrote ${structOut}`);
console.log(
  `  Task 2: 1 government, ${city.chambers.length} city chambers, ${districtRows().length} districts ` +
    `(${city.district_count} x ${city.district_mtfcc} + 1 citywide), ${city.offices.length} offices`,
);

const peopleOut = join(OUT_DIR, 'CC_wip_macon_bibb_people.sql');
writeFileSync(peopleOut, peopleFile(), 'utf8');
console.log(`wrote ${peopleOut}`);
{
  const dated = city.offices.filter((o) => o.person.term_start);
  const appointed = city.offices.filter((o) => o.person.how_started === 'appointed');
  console.log(
    `  Task 3: ${city.offices.length} politicians, ${city.offices.length} terms, 0 vacancies — ` +
      `${dated.length} dated (${dated.filter((o) => o.person.start_precision === 'day').length} day, ` +
      `${dated.filter((o) => o.person.start_precision === 'month').length} month), ` +
      `${appointed.length} appointed, ALL via seat_officeholder()`,
  );
}
const countyOut = join(OUT_DIR, 'CC_wip_bibb_county.sql');
writeFileSync(countyOut, countyFile(), 'utf8');
console.log(`wrote ${countyOut}`);
{
  const dated = county.offices.filter((o) => o.person.term_start);
  const undated = county.offices.filter((o) => !o.person.term_start);
  console.log(
    `  Task 4: 1 chamber on the EXISTING government, 0 districts created, ` +
      `${county.offices.length} offices + ${county.offices.length} politicians + ${county.offices.length} terms in ONE migration — ` +
      `${dated.length} dated at year, ${undated.length} open-ended unknown`,
  );
}
console.log('  🔴 All three files are CC_wip_ on purpose — take the numbers LAST, re-counted across every remote ref.');
console.log('  ⚠ Neither the occupancy nor the county half can be dry-run alone.');
console.log('  ⚠ Run all THREE as ONE transaction ending in ROLLBACK, asserting zero ^\\s*COMMIT\\s*; beforehand.');
