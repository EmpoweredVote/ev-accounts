/**
 * gen-ga4-columbus-migrations.mjs
 *
 * Generates the GA-4 migrations from backend/data/ga4-columbus-roster.json.
 *
 *   CC_wip_columbus_structure.sql   Task 2 — 1 government, 2 city chambers,
 *                                   9 districts (8 x X0044 + 1 citywide), 11 offices
 *   CC_wip_columbus_people.sql      Task 3 — 11 politicians, 11 terms, 0 vacancies
 *
 * Task 4 (the five county officers, in ONE migration per spec §3) adds its
 * emitter to this file; the roster JSON already carries all 16 people, and
 * assertRoster() validates all 16 so that half cannot drift from it.
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

// ── the city occupancy half (Task 3) ─────────────────────────────────────────

const PTAG = 'columbus people';
const SEED = 'col_seed';

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
  const chamberNames = city.chambers.map((c) => q(c.name)).join(', ');
  const wideOffices = offices.filter((o) => o.district_geo_id === wide.geo_id && o.district_mtfcc === wide.mtfcc);

  const seedRows = offices
    .map((o) => {
      const p = o.person;
      return `  (${q(o.district_geo_id)}, ${q(o.district_mtfcc)}, ${q(DT)}, ${q(o.title)}, ${p.external_id}, ${q(p.full_name)}, ${q(p.first_name)}, ${q(p.last_name)}, ${q(p.middle_initial)}, ${q(p.name_suffix)}, ${arr(p.aliases)}, ${p.term_start ? `DATE ${q(p.term_start)}` : 'NULL::date'}, ${q(p.start_precision)}, ${q(p.how_started)}, ${q(p.source)})`;
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
  IF v_n <> 1 THEN RAISE EXCEPTION '${PTAG}: ${o.person.full_name.replace(/'/g, "''")} (${o.person.external_id}) does not hold exactly one open term starting ${o.person.term_start} at ${o.person.start_precision} precision, got %', v_n; END IF;`,
    )
    .join('\n\n');

  return `-- CC_wip_columbus_people.sql
--
-- Knight Foundation cities program, wave GA-4 Task 3, CITY OCCUPANCY half.
--   * ${offices.length} politicians, ${offices.length} terms, 0 vacancies
--   * ${undated.length} open-ended at start_precision 'unknown'; ${dated.length} dated at 'day'
--
-- Plan:   docs/superpowers/plans/2026-09-01-knight-ga-wave-4-columbus-muscogee.md
-- Roster: backend/data/seed-columbus-2026/ROSTERS.md
-- Generated by scripts/gen-ga4-columbus-migrations.mjs from
-- data/ga4-columbus-roster.json -- edit the roster and regenerate, do not
-- hand-edit this file.
--
-- ⚠ THIS HALF CANNOT BE DRY-RUN ALONE -- its offices do not exist until the
--   structure half runs. Run both as ONE transaction ending in ROLLBACK and
--   assert the stream holds exactly one BEGIN, one ROLLBACK and ZERO COMMIT.
--
-- ---------------------------------------------------------------------------
-- 🔴🔴 A CERTIFIED RESULT IS A FACT ABOUT AN ELECTION, NOT ABOUT WHO HOLDS THE
--      SEAT TODAY. FOUR OF THE SIX PEOPLE COLUMBUS ELECTED IN 2026 ARE NOT HERE.
--
-- Charter Sec. 3-100(2): a councilor's term commences at the Council's regular
-- meeting "within seven (7) days following the first Monday in January next
-- following their election", EXCEPT that "a councilor selected to fill a
-- vacancy shall serve only for the remainder of the unexpired term."
--
-- So the regular winners of the May/June 2026 contests take office in JANUARY
-- 2027 and are NOT seated by this migration:
--
--   Mayor      Isaiah Hugley, Sr.        51.57% runoff, certified 2026-06-16
--   District 3 Sherrie Aaron             56.23% outright, certified 2026-05-19
--   District 7 Rebecca "Becca" Zajac     57.75% runoff, certified 2026-06-16
--   District 1 Simi Barnes  (regular)    60.00% outright -- see below
--   Post 9     Cathy Cook   (regular)    59.90% runoff  -- see below
--
-- Only the winners of the two SPECIAL contests started early, because a special
-- fills an unexpired term. Two seats carried BOTH a regular and a special
-- contest on the same ballot, and that pairing is the only discriminator:
--
--   District 1 SPECIAL  Simi Barnes  59.84% outright  -> sworn in 2026-05-26
--   Post 9     SPECIAL  Cathy Cook   60.22% runoff    -> sworn in 2026-07-14
--
-- Seating the certified winners would have installed a Mayor four months early
-- and replaced two sitting councilors, Huff (D3) and Cogle (D7).
--
-- The two vacancies the specials filled: Judy Thomas resigned Post 9 for health
-- reasons and the Council appointed John Anker 6-3 over the Mayor's objection;
-- Byron Hickey was appointed to District 1 after Jerry "Pops" Barnes and chose
-- not to run for a full term. Simi Barnes is Pops Barnes' daughter. ⚠ NEITHER
-- CURRENT HOLDER WAS APPOINTED -- both were elected, in a special.
--
-- ---------------------------------------------------------------------------
-- 🔴 how_started IS 'elected' FOR ALL ${offices.length}, INCLUDING THE TWO SPECIALS.
--
-- essentials.office_terms carries
--   CHECK how_started IN ('elected','appointed','succeeded','redistricted','unknown')
-- measured against production 2026-09-01. 'special election' is NOT a member of
-- that set and the plan's Task 3 text specifies it. A special election is an
-- election; the SPECIAL fact lives in the source string and in this header.
--
-- ---------------------------------------------------------------------------
-- 🔴 THE OTHER ${undated.length} TERMS ARE OPEN-ENDED AT 'unknown', AND THAT IS THE HONEST
--    RECORD, NOT A GAP.
--
-- Columbus publishes no service-start. The ten councilor pages carry name,
-- phone, email and address, and one bio; not one carries an election year, and
-- the Mayor's page carries none either. term_start is the start of CONTINUOUS
-- occupancy, which re-election does not end, so the charter's January
-- commencement is the start of a TERM and not of an occupancy. No date is
-- invented -- there is no end_precision to soften a wrong start.
--
-- ---------------------------------------------------------------------------
-- 🟢 CHANGE-CHECK RUN LIVE 2026-09-01, AND IT ASKED "HAS THIS PERSON LEFT?"
--
-- columbusga.gov/council/ and /mayor/ were fetched live and read for BOTH
-- directions: all ${offices.length} holders below are present, and all seven people who must NOT
-- be present are absent -- Hickey, Anker and Thomas (departed) and Hugley,
-- Aaron and Zajac (elected, not yet seated). The check is not uniform: it
-- returns 10 of 11 on /council/ because the Mayor is not a councilor, which is
-- its own positive control. This is the check GA-3 failed to run against the
-- SEATS rather than the sources, which put a retired coroner into production.
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
-- band ${r.id_band.min}..${r.id_band.max}. Task 4 owns ${r.county.offices.map((o) => o.person.external_id).sort((a, b) => a - b)[0]}..${r.county.offices.map((o) => o.person.external_id).sort((a, b) => a - b).slice(-1)[0]}; a guard over the whole
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
-- against production 2026-09-01 and none matched. The near misses are all
-- different people -- David Cook (TX), Gary Davis, Gary Garrett (UT), David
-- Smith (FL), Gregory Smith (OR), David K. Thompson (WI), Glenn Thompson (PA).
-- A name-based guard is what seated a Colorado senator and a Utah treasurer in
-- the Georgia General Assembly, caught at GA-2 before it happened.

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
DECLARE v_n int; v_dup int;
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

  -- 🔴 EXACTLY ${dated.length} ROWS ARE DATED, AND THEY ARE THE TWO SPECIAL-ELECTION WINNERS.
  -- A bare "some rows are dated" check would pass if a third date appeared.
  SELECT count(*) INTO v_n FROM ${SEED} WHERE term_start IS NOT NULL;
  IF v_n <> ${dated.length} THEN RAISE EXCEPTION '${PTAG} payload: expected ${dated.length} dated row(s) -- the two special-election winners -- got %', v_n; END IF;
  SELECT count(*) INTO v_n FROM ${SEED}
   WHERE term_start IS NOT NULL AND ext_id NOT IN (${dated.map((o) => o.person.external_id).join(', ')});
  IF v_n <> 0 THEN RAISE EXCEPTION '${PTAG} payload: % dated row(s) are not the expected special-election winners', v_n; END IF;

  -- 🔴 how_started IS A CHECKED ENUM. 'special election' is not in it.
  SELECT count(*) INTO v_n FROM ${SEED}
   WHERE how_started NOT IN ('elected','appointed','succeeded','redistricted','unknown');
  IF v_n <> 0 THEN RAISE EXCEPTION '${PTAG} payload: % row(s) carry a how_started the CHECK will refuse', v_n; END IF;

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
-- 🔴 TWO PATHS, AND THE SECOND ONE IS NOT A SHORTCUT.
--
-- essentials.seat_officeholder() REFUSES a NULL term_start outright: "pass Jan 1
-- with p_start_precision => 'year' rather than NULL." But ${undated.length} of these ${offices.length}
-- people have no published start date of any kind, and inventing Jan 1 of a
-- guessed year would be a false statement about history that no end_precision
-- exists to soften.
--
-- The schema allows the honest record and prod is full of it: the ADR 0002
-- phase-2 backfill wrote 81,676 'unknown'-precision rows with term_start NULL.
-- Only the HELPER refuses it.
--
-- So the ${dated.length} dated rows go through the helper, as the house rule requires, and
-- the undated rows are inserted directly -- but ONLY into an office with zero
-- existing term rows. That condition is what makes bypassing the helper safe:
-- the helper's two-step exists to close a predecessor before an open-ended range
-- overlaps it, and with no predecessor there is nothing to close and the
-- exclusion constraint cannot fire. The guard below REFUSES rather than guesses
-- if that stops being true.
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
  RAISE NOTICE '${PTAG}: seated % dated official(s) via the helper, % with an honest unknown start', v_seated, v_blank;
END $$;

-- --- Post-verify gate ------------------------------------------------------
-- 🔴 SCOPED TO THE TWO CITY CHAMBERS, NEVER TO THE GOVERNMENT. Columbus is
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

  -- One seated member per numbered district, counted PER DISTRICT.
  FOR v_d IN SELECT ${q(city.district_geo_id_prefix)} || gs FROM generate_series(1,${city.district_count}) gs LOOP
    SELECT count(och.politician_id) INTO v_n
      FROM essentials.districts d
      JOIN essentials.offices o ON o.district_id = d.id
      LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
     WHERE d.geo_id = v_d AND d.mtfcc = ${q(city.district_mtfcc)} AND d.district_type = ${q(DT)};
    IF v_n <> 1 THEN RAISE EXCEPTION '${PTAG}: district % has % holder(s), expected exactly 1', v_d, v_n; END IF;
  END LOOP;

  -- And ${wideOffices.length} on the citywide district: the Mayor plus Posts 9 and 10.
  SELECT count(och.politician_id) INTO v_n
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE c.government_id = v_gov AND c.name IN (${chamberNames})
     AND d.geo_id = ${q(wide.geo_id)} AND d.mtfcc = ${q(wide.mtfcc)} AND d.district_type = ${q(DT)};
  IF v_n <> ${wideOffices.length} THEN RAISE EXCEPTION '${PTAG}: expected ${wideOffices.length} holder(s) on ${wide.label}, got %', v_n; END IF;

  -- 🔴 THE ${undated.length} UNDATED TERMS ARE OPEN-ENDED AT 'unknown', WITH NO term_end.
  -- A future term_end makes a seat silently self-vacate on a date nobody watches.
  SELECT count(*) INTO v_n
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE p.external_id IN (${undated.map((o) => o.person.external_id).sort((a, b) => a - b).join(', ')})
     AND (t.start_precision <> 'unknown' OR t.term_start IS NOT NULL OR t.term_end IS NOT NULL);
  IF v_n <> 0 THEN RAISE EXCEPTION '${PTAG}: % term row(s) that should be open-ended unknown are not', v_n; END IF;

  -- 🔴 AND THE ${dated.length} DATED ONES CARRY EXACTLY THE DATE THAT WAS SOURCED, each
  -- asserted individually. A count of "how many are dated" cannot see a date
  -- that moved.
${datedChecks}

  -- No city office may be left with no term row at all: that is the
  -- invisible-office failure, and nothing else errors.
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id
   WHERE c.government_id = v_gov AND c.name IN (${chamberNames})
     AND NOT EXISTS (SELECT 1 FROM essentials.office_terms t WHERE t.office_id = o.id);
  IF v_n <> 0 THEN RAISE EXCEPTION '${PTAG}: % city office(s) carry no office_terms row and are invisible', v_n; END IF;

  RAISE NOTICE '${PTAG} OK: ${offices.length} politicians, ${offices.length} seated across ${offices.length} city offices, 0 vacancies (${dated.length} dated at day, ${undated.length} open-ended unknown)';
END $$;

COMMIT;
`;
}

// ── main ─────────────────────────────────────────────────────────────────────
assertRoster();

const outputs = [
  ['CC_wip_columbus_structure.sql', structureFile()],
  ['CC_wip_columbus_people.sql', peopleFile()],
];
for (const [name, body] of outputs) {
  const path = join(OUT_DIR, name);
  writeFileSync(path, body, 'utf8');
  console.log(`wrote ${path}`);
}
console.log(
  `  structure: ${districtRows().length} districts, 1 government, ${city.chambers.length} chambers, ${city.offices.length} offices`,
);
const nDated = city.offices.filter((o) => o.person.term_start).length;
console.log(
  `  people:    ${city.offices.length} politicians, ${city.offices.length} terms (${nDated} dated at 'day', ${city.offices.length - nDated} open-ended 'unknown')`,
);
console.log('\n🔴 Task 4 (county officers) is not emitted yet.');
console.log('🔴 The migration NUMBERS are taken LAST — re-count against every remote ref.');
