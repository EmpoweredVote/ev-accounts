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

// ── emit ─────────────────────────────────────────────────────────────────────

const out = join(OUT_DIR, 'CC_wip_macon_bibb_structure.sql');
writeFileSync(out, structureFile(), 'utf8');
console.log(`wrote ${out}`);
console.log(
  `  Task 2: 1 government, ${city.chambers.length} city chambers, ${districtRows().length} districts ` +
    `(${city.district_count} x ${city.district_mtfcc} + 1 citywide), ${city.offices.length} offices`,
);
console.log('  🔴 Tasks 3 and 4 are NOT emitted yet.');
console.log('  🔴 The file is CC_wip_ on purpose — take the number LAST, re-counted across every remote ref.');
