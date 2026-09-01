/**
 * gen-ga4-columbus-migrations.mjs
 *
 * Generates the GA-4 migrations from backend/data/ga4-columbus-roster.json.
 *
 *   CC_wip_columbus_structure.sql   Task 2 — 1 government, 2 city chambers,
 *                                   9 districts (8 x X0044 + 1 citywide), 11 offices
 *
 * Tasks 3 (city occupancy) and 4 (county officers) add their emitters to this
 * file; the roster JSON already carries all 16 people, and assertRoster()
 * validates all 16 today so the two later halves cannot drift from it.
 *
 * Wave GA-4 of the Knight Foundation cities program.
 * Plan:   docs/superpowers/plans/2026-09-01-knight-ga-wave-4-columbus-muscogee.md
 * Roster: backend/data/seed-columbus-2026/ROSTERS.md
 *
 * Usage:  node scripts/gen-ga4-columbus-migrations.mjs
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THE NUMBER IS TAKEN LAST. This emits CC_wip_*.sql. Rename, apply and commit
 *    in one go, after re-counting against EVERY remote ref — not against
 *    PROGRAM.md or ga.md, which record what the LAST wave took, a different
 *    question. Both files have gone stale within hours before.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 COLUMBUS IS ONE GOVERNMENT WITH THREE CHAMBERS, SO THIS MIGRATION'S
 *    POST-VERIFY MUST NOT COUNT CHAMBERS OR OFFICES GOVERNMENT-WIDE.
 *
 * Consolidation means the county officers hang off the SAME government row as
 * the Council. A post-verify asserting "this government has exactly 2 chambers
 * and 11 offices" would pass on the day it applies and then FAIL FOREVER once
 * Task 4 adds the county chamber — which breaks this migration's own re-run.
 * That is the FL-4 correction in a new dress: an assertion scoped wider than the
 * thing the migration owns creates a hidden ordering dependency between two
 * halves of one wave. Every count below is scoped to the TWO CITY CHAMBERS.
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * 🔴 THE CITYWIDE DISTRICT IS CREATED; THE COUNTYWIDE ONE IS ONLY ASSERTED.
 *
 * GA-1 loaded the TIGER place BOUNDARY 1319000/G4110 and created no place
 * DISTRICT, so the citywide LOCAL district is inserted here. The TIGER county
 * load already created 13215/G4020 as a COUNTY district, so Task 4 asserts it
 * and inserts nothing. Inserting it again would lay a second district over the
 * same ground.
 *
 * ⚠ THE TWO COVER IDENTICAL GROUND — 221.011 sq mi each — and that is correct
 *   under consolidation: same ground, two tiers. It is also why the acceptance
 *   probe has to assert each tier separately.
 */

import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const BACKEND = join(HERE, '..');
const ROSTER = join(BACKEND, 'data', 'ga4-columbus-roster.json');
const OUT_DIR = join(BACKEND, 'migrations');

const r = JSON.parse(readFileSync(ROSTER, 'utf8'));

/** SQL single-quoted literal. */
const q = (s) => (s === null || s === undefined ? 'NULL' : `'${String(s).replace(/'/g, "''")}'`);

// ── sanity on the roster itself, before a line of SQL is written ─────────────
function assertRoster() {
  const all = [...r.city.offices, ...r.county.offices];
  if (all.length !== 16) throw new Error(`expected 16 offices in the roster, got ${all.length}`);
  if (r.city.offices.length !== 11) throw new Error(`expected 11 city offices, got ${r.city.offices.length}`);
  if (r.county.offices.length !== 5) throw new Error(`expected 5 county offices, got ${r.county.offices.length}`);

  const ids = all.map((o) => o.person.external_id);
  if (new Set(ids).size !== ids.length) throw new Error('duplicate external_id in the roster');
  const { min, max } = r.id_band;
  for (const id of ids) {
    if (id < min || id > max) throw new Error(`external_id ${id} is outside the declared band ${min}..${max}`);
  }
  if (Math.min(...ids) !== min || Math.max(...ids) !== max) {
    throw new Error(`the declared band ${min}..${max} does not match the ids actually used`);
  }

  for (const side of ['city', 'county']) {
    const names = new Set(r[side].chambers.map((c) => c.name));
    for (const o of r[side].offices) {
      if (!names.has(o.chamber)) throw new Error(`${side}: office '${o.title}' names unknown chamber '${o.chamber}'`);
    }
    const seats = r[side].offices.map((o) => `${o.district_geo_id}|${o.district_mtfcc}|${o.title}`);
    if (new Set(seats).size !== seats.length) throw new Error(`${side}: duplicate seat key`);
  }

  // 🔴 ADR 0003: representation_note is REQUIRED whenever voting_powers <> 'full',
  //    enforced by a CHECK on essentials.offices. Catch it here, where the error
  //    names the office, rather than as a constraint violation mid-transaction.
  //    And the read path must not render such a seat without the note, so a
  //    one-liner is not good enough — 1719's own gate wants >= 120 characters.
  for (const o of [...r.city.offices, ...r.county.offices]) {
    if (o.voting_powers !== 'full') {
      if (!o.representation_note || o.representation_note.length < 120) {
        throw new Error(`office '${o.title}' is ${o.voting_powers} and carries no substantive representation_note`);
      }
    } else if (o.representation_note) {
      throw new Error(`office '${o.title}' is voting_powers 'full' but carries a representation_note — both read paths HIDE it`);
    }
  }

  // 🔴 Ruling R3: a rotating role is a parenthetical on the seat title, never an
  //    office. The generator is exactly where one leaks back in.
  for (const o of [...r.city.offices, ...r.county.offices]) {
    if (/pro[- ]tem|chair|vice/i.test(o.title)) throw new Error(`office title '${o.title}' names a rotating role — ruling R3 says it is a parenthetical`);
  }

  // 🔴 how_started is a CHECKed enum: elected | appointed | succeeded |
  //    redistricted | unknown. 'special election' is NOT a member of it. Barnes
  //    and Cook won specials; that fact lives in the source string, not here.
  const HOW = new Set(['elected', 'appointed', 'succeeded', 'redistricted', 'unknown']);
  const PREC = new Set(['day', 'month', 'year', 'unknown']);
  for (const o of [...r.city.offices, ...r.county.offices]) {
    const p = o.person;
    if (!HOW.has(p.how_started)) throw new Error(`${p.full_name}: how_started '${p.how_started}' violates the office_terms CHECK`);
    if (!PREC.has(p.start_precision)) throw new Error(`${p.full_name}: start_precision '${p.start_precision}' violates the office_terms CHECK`);
    if (p.start_precision === 'unknown' && p.term_start !== null) throw new Error(`${p.full_name}: start_precision 'unknown' with a term_start is a contradiction`);
    if (p.start_precision !== 'unknown' && p.term_start === null) throw new Error(`${p.full_name}: start_precision '${p.start_precision}' with no term_start`);
  }

  // 🔴 Party must not have leaked into a person or an office. It lives on
  //    races.primary_party.
  const json = JSON.stringify(r).toLowerCase();
  for (const w of ['"party"', '"republican"', '"democrat"', '"(dem)"', '"(rep)"']) {
    if (json.includes(w)) throw new Error(`the roster carries ${w} — party belongs on races.primary_party only`);
  }

  console.log(`roster OK: 16 offices (11 city, 5 county), 16 unique ids, band ${min}..${max}, no party fields`);
}

// ── the city structure half ──────────────────────────────────────────────────

const TAG = 'columbus structure';
const city = r.city;
const gov = city.government;
const wide = city.citywide_district;
const DT = city.district_type;

/** Every district this migration creates: the citywide one plus the eight. */
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
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries WHERE mtfcc = ${q(city.district_mtfcc)};
  IF v_n <> ${city.district_count} THEN
    RAISE EXCEPTION '${TAG}: expected ${city.district_count} ${city.district_mtfcc} boundaries, found % -- run scripts/load-columbus-council-boundaries.ts (GA-4 Task 1) first', v_n;
  END IF;

  -- ⚠ A COUNT IS NOT AN IDENTITY CHECK. Eight boundaries under some other slug
  -- would satisfy the count above and then silently produce zero offices,
  -- because the office insert resolves each district by its geo_id.
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries
   WHERE mtfcc = ${q(city.district_mtfcc)}
     AND geo_id IN (${slugs.map(q).join(', ')});
  IF v_n <> ${city.district_count} THEN
    RAISE EXCEPTION '${TAG}: the ${city.district_mtfcc} boundaries are not the % expected slugs (matched %)', ${city.district_count}, v_n;
  END IF;

  -- ⚠ ALWAYS PAIR geo_id WITH mtfcc. Georgia's collision is THREE-WAY: bare
  -- '13215' is Muscogee County, and elsewhere in the same state '13009' is
  -- Baldwin County AND State House District 9 AND State Senate District 9.
  IF NOT EXISTS (
    SELECT 1 FROM essentials.geofence_boundaries
     WHERE geo_id = ${q(wide.geo_id)} AND mtfcc = ${q(wide.mtfcc)}
  ) THEN
    RAISE EXCEPTION '${TAG}: boundary ${wide.geo_id}/${wide.mtfcc} is missing -- GA-1 must be applied first';
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
-- GOVERNMENT. Columbus is consolidated, so Task 4's five county officers join
-- this SAME government row. A government-wide count would pass today and fail
-- forever after that, breaking this migration's own re-run -- the FL-4
-- correction, in a new dress.
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

  -- 🔴 THREE seats hang on the citywide district and none of them is a ninth or
  -- tenth POLYGON. Ruling R1: Posts 9 and 10 are at-large. The city's roster
  -- page numbers all ten "District N" and would have invented two districts;
  -- both GIS layers return 8, which is the independent confirmation.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name IN (${chamberNames})
     AND d.geo_id = ${q(wide.geo_id)} AND d.mtfcc = ${q(wide.mtfcc)} AND d.district_type = ${q(DT)};
  IF v_n <> ${wideOffices.length} THEN RAISE EXCEPTION '${TAG}: expected ${wideOffices.length} office(s) on ${wide.label}, got %', v_n; END IF;

  -- 🔴 Ruling R2 must have SURVIVED generation. The Mayor presides, has a voice,
  -- and votes only to break a tie (charter Sec. 4-201(2) and 4-201(4)), so the
  -- seat is non_voting and ADR 0003 makes the note mandatory -- and both read
  -- paths must render it. A generator that dropped the note would satisfy every
  -- count above and be caught only by the CHECK, or not at all if the seat had
  -- silently been written 'full'.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND o.title = ${q(mayor.title)}
     AND o.voting_powers = ${q(mayor.voting_powers)}
     AND o.representation_note IS NOT NULL AND length(o.representation_note) >= 200;
  IF v_n <> 1 THEN RAISE EXCEPTION '${TAG}: expected 1 ${mayor.voting_powers} ${mayor.title} office carrying a substantive representation_note, got %', v_n; END IF;

  -- And no full-voting city seat carries one: both read paths HIDE the note when
  -- voting_powers is 'full', so writing one there is prose nobody will ever see.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name IN (${chamberNames})
     AND o.voting_powers = 'full' AND o.representation_note IS NOT NULL;
  IF v_n <> 0 THEN RAISE EXCEPTION '${TAG}: % full-voting seat(s) carry a representation_note that no read path renders', v_n; END IF;

  -- No role leaked out as its own office. Mayor Pro Tem is elected annually by
  -- the Council from its own members, charter Sec. 3-103(1) -- ruling R3.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name IN (${chamberNames})
     AND (o.title ILIKE '%pro tem%' OR o.title ILIKE '%pro-tem%' OR o.title ILIKE '%chair%' OR o.title ILIKE '%vice%');
  IF v_n <> 0 THEN RAISE EXCEPTION '${TAG}: % role(s) were created as offices -- ruling R3 says they are parentheticals', v_n; END IF;

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

  RAISE NOTICE '${TAG} OK: ${districtRows().length} districts created, 1 government, ${city.chambers.length} city chambers, ${n} city offices (${city.district_count} district + ${wideOffices.length - 1} at-large + 1 non_voting Mayor)';
END $$;`;
}

function structureFile() {
  return `-- CC_wip_columbus_structure.sql
--
-- Knight Foundation cities program, wave GA-4 Task 2, CITY STRUCTURE half.
--   * 1 government, 2 chambers
--   * 9 districts -- 1 citywide (TIGER place 1319000/G4110) + 8 council (X0044)
--   * 11 offices  -- 1 Mayor + 8 district councilors + 2 at-large (Posts 9, 10)
--
-- Plan:   docs/superpowers/plans/2026-09-01-knight-ga-wave-4-columbus-muscogee.md
-- Roster: backend/data/seed-columbus-2026/ROSTERS.md
-- Generated by scripts/gen-ga4-columbus-migrations.mjs from
-- data/ga4-columbus-roster.json -- edit the roster and regenerate, do not
-- hand-edit this file.
--
-- 🔴 TAKE THE MIGRATION NUMBER LAST. Re-count against EVERY remote ref, not
--    against PROGRAM.md or ga.md. Both have gone stale within hours.
--
-- ---------------------------------------------------------------------------
-- 🔴 COLUMBUS IS THE PROGRAM'S FIRST CONSOLIDATED CITY-COUNTY, AND THE
--    CONSOLIDATION IS COMPLETE.
--
-- TIGER place 1319000 measures 221.011 sq mi, identical to Muscogee County
-- 13215, and Georgia publishes no BALANCE record for it (FUNCSTAT 'A', unlike
-- Augusta-Richmond and Athens-Clarke, which are 'F'). So -- unlike Nashville,
-- whose place polygon excludes six satellite cities whose residents still elect
-- the same council -- the place polygon here is the whole electorate, and the
-- government row can key on it.
--
-- ONE government covers both tiers. Task 4 attaches a THIRD chamber, "Muscogee
-- County Elected Officials", to THIS SAME government row. That is why every
-- count in the post-verify gate below is scoped to the two CITY chambers and
-- never to the government: a government-wide count would pass on the day this
-- applies and fail forever afterwards, breaking this migration's own re-run.
--
-- ---------------------------------------------------------------------------
-- 🔴 RULING R1: TEN COUNCILORS -- EIGHT DISTRICTS AND TWO AT-LARGE POSTS.
--
-- Charter Sec. 3-100(2): "The council shall consist of ten (10) members."
-- Sec. 3-100(3): after the 1994 and 1996 elections "the council shall have
-- eight (8) district councilors and two (2) councilors at large", the at-large
-- members being the designated Post 9 and Post 10 councilors.
--
-- ⚠ THE CITY'S OWN ROSTER PAGE NUMBERS ALL TEN "District N" WITH NO AT-LARGE
--   LABEL, so the page alone would have produced two districts that do not
--   exist. Both GIS layers return exactly 8 polygons, which is the independent
--   confirmation, and the certified ballot names the seat "Council - District 9
--   - At Large". Posts 9 and 10 hang on the citywide district, as Tallahassee's
--   at-large commission does.
--
-- ---------------------------------------------------------------------------
-- 🔴 RULING R2: THE MAYOR IS non_voting, WITH A MANDATORY NOTE.
--
-- Charter Sec. 4-201, "Powers and duties", gives the Mayor the power and duty
-- "(2) To preside at all meetings of the Council and to have a voice in its
-- proceedings" and "(4) To have the right to vote only in the case of a tie,
-- and for such purpose only to be deemed a member of the Council". Sec.
-- 3-103(3) makes six of the ten councilors a quorum, which counts the Mayor out
-- of the body -- so chambers.official_count for the Council is 10, not 11.
--
-- That is Nashville's Vice Mayor ruling exactly: voting_powers 'non_voting'
-- with the tie-break carried in representation_note, which ADR 0003 makes
-- mandatory and both read paths render.
--
-- ⚠ CITATION CORRECTED. ROSTERS.md, ga.md and the plan all cite "Sec. 4-102"
--   for these powers. Sec. 4-102 of the charter on disk is "General provisions
--   concerning departments" and says nothing about the Mayor's vote. The
--   Mayor's powers are Sec. 4-201. The note below cites 4-201, and it is
--   voter-facing prose, so the wrong section number would have shipped to
--   readers.
--
-- ---------------------------------------------------------------------------
-- 🔴 RULING R3: MAYOR PRO TEM IS A PARENTHETICAL, NOT AN OFFICE.
--
-- Charter Sec. 3-103(1): at its organizational meeting the Council "shall elect
-- by six (6) votes one (1) of its members as mayor pro tem to serve until the
-- next organizational meeting." Elected by the body, from the body, annually.
-- Baldwin R2 and the Lawrence County ruling. The post-verify gate refuses any
-- office titled with it.
--
-- ---------------------------------------------------------------------------
-- ⚠ THE EIGHT DISTRICTS DELIBERATELY DO NOT TILE THE CITY, AND THE CITYWIDE
--   DISTRICT DELIBERATELY DOES.
--
-- The eight council districts cover 146.24 of the city's 221.011 sq mi. The
-- 74.79 sq mi remainder is the Fort Benning reservation, which the county's own
-- ballot-building layer records as "Precinct N/A; Council & School Board N/A"
-- (74.767 sq mi, symmetric difference 0.0216 after ST_MakeValid). The charter's
-- own Sec. 1-100 excludes the reservation from the City of Columbus while Sec.
-- 1-102 puts the whole of Muscogee County inside the consolidated government.
--
-- So an address on the reservation returns the Mayor and the two at-large
-- councilors and NO district councilor. That is the county's own record of who
-- represents that ground, not a gap. 🔴 GATE THE STRUCTURE, NOT FULL COVERAGE
-- -- a coverage gate fails here on correct data.
--
-- IDEMPOTENT: every insert is NOT EXISTS-guarded, and every assertion is a
-- statement about the END STATE, not about a delta.

BEGIN;

${preflightSql()}

-- --- 1. Districts -----------------------------------------------------------
-- ⚠ Synthetic districts carry no ocd_id and no government_id, matching X0035,
-- X0042 and X0044's siblings. district state is LOWER case here and UPPER on
-- governments and offices; both conventions are live in prod.
--
-- num_officials on the citywide district is ${wide.num_officials}: three officials really are
-- elected on it -- the Mayor and Posts 9 and 10. Tallahassee wrote 5 because all
-- five of its commissioners are at-large; Miami wrote 1 because only its Mayor
-- is. The column counts officials elected on the district across chambers, not
-- seats within one chamber.

${districtsSql()}

-- --- 2. Government ----------------------------------------------------------
-- ⚠ The charter's corporate name is the bare "Columbus, Georgia" (Sec. 1-100),
-- which is not a usable row label; the government is universally published as
-- the Columbus Consolidated Government.

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

// ── main ─────────────────────────────────────────────────────────────────────
assertRoster();

const out = join(OUT_DIR, 'CC_wip_columbus_structure.sql');
writeFileSync(out, structureFile(), 'utf8');
console.log(`wrote ${out}`);
console.log(
  `  ${districtRows().length} districts, 1 government, ${city.chambers.length} chambers, ${city.offices.length} offices`,
);
console.log('\n🔴 Tasks 3 (city occupancy) and 4 (county officers) are not emitted yet.');
console.log('🔴 The migration NUMBER is taken LAST — re-count against every remote ref.');
