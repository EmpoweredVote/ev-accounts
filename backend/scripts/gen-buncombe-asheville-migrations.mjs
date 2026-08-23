#!/usr/bin/env node
/**
 * gen-buncombe-asheville-migrations.mjs
 *
 * Emits the two wave-3 migrations of the NC deep-seed program:
 *
 *   migrations/CA_0009_asheville_buncombe_structure.sql
 *   migrations/CA_0010_asheville_buncombe_incumbents.sql
 *
 * Roster:  data/seed-buncombe-asheville-2026/ROSTERS.md  (mirrored in ROSTER below)
 * Plan:    docs/superpowers/plans/2026-08-23-nc-wave-3-asheville-buncombe.md
 * Modelled on: scripts/gen-durham-migrations.mjs, CA_0006, CA_0007
 *
 * Usage: node scripts/gen-buncombe-asheville-migrations.mjs
 */
import { writeFileSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const HERE = dirname(fileURLToPath(import.meta.url));
const MIGRATIONS = join(HERE, '..', 'migrations');

// ─── Constants shared by both files ──────────────────────────────────────────
const AVL_GEO = '3702140';           // Asheville city TIGER place, mtfcc G4110
const BUN_GEO = '37021';             // Buncombe County TIGER county, mtfcc G4020
const X_MTFCC = 'X0034';             // synthetic mtfcc for the commission districts
const CD = (n) => `buncombe-nc-commissioner-district-${n}`;

/**
 * The statutory coupling, rendered per district as a voter-facing note.
 * `representation_note` on a voting_powers='full' seat is permitted -- the CHECK
 * requires it only when powers are not full -- and there are existing precedents
 * (Durham's ward seats, CA_0006).
 */
const HOUSE_TWIN = { 1: '114', 2: '115', 3: '116' };
const couplingNote = (n) =>
  `District ${n}'s boundaries are, by a 2011 local act of the North Carolina General Assembly, ` +
  `identical to those of NC House District ${HOUSE_TWIN[n]}. Buncombe is the only one of North ` +
  `Carolina's 100 counties whose commission districts are defined this way, so a redraw of the ` +
  `state House district also moves this county district. Two commissioners are elected from each ` +
  `district. (Buncombe County GIS layer bcmap_VotingDistricts3/7, cross-checked against TIGER ` +
  `2024, retrieved 2026-08-23.)`;

/**
 * ROSTERS.md, as data. 17 rows.
 *
 * `geo_id` + `district_type` + `office_title` is the join key into the office
 * rows CA_0009 creates -- the same triple CA_0007 used, because four of these
 * groups contain MORE THAN ONE identically-titled office and must be paired by
 * rank rather than by title.
 *
 * 🔴 term_start is the day this person began holding THIS SEAT. Continuous
 * service through a re-election is ONE term row. Reading Buncombe's published
 * term-EXPIRY year as "elected four years earlier" is wrong for five of these
 * people -- see ROSTERS.md "Source defects found".
 */
const SRC_AVL = 'ashevillenc.gov/government/meet-city-council/ (retrieved 2026-08-23)';
const SRC_BUN = 'media.buncombenc.gov/common/election/elected-officials.pdf (Buncombe County Election Services, retrieved 2026-08-23)';

const ROSTER = [
  // ── City of Asheville: 7, all at-large on the citywide place polygon ──────
  { geo: AVL_GEO, dt: 'LOCAL', title: 'Mayor',
    ext: -3740001, full: 'Esther E. Manheimer', first: 'Esther', last: 'Manheimer', mi: 'E',
    start: '2013-12-10', prec: 'day', how: 'elected', src: SRC_AVL },
  { geo: AVL_GEO, dt: 'LOCAL', title: 'Council Member',
    ext: -3740002, full: 'S. Antanette Mosley', first: 'S. Antanette', last: 'Mosley',
    aliases: ['Antanette'],
    start: '2020-09-01', prec: 'month', how: 'appointed', src: SRC_AVL },
  { geo: AVL_GEO, dt: 'LOCAL', title: 'Council Member',
    ext: -3740003, full: 'Sheneika Smith', first: 'Sheneika', last: 'Smith',
    start: '2017-12-01', prec: 'month', how: 'elected', src: SRC_AVL },
  { geo: AVL_GEO, dt: 'LOCAL', title: 'Council Member',
    ext: -3740004, full: 'Kim Roney', first: 'Kim', last: 'Roney',
    start: '2020-12-01', prec: 'month', how: 'elected', src: SRC_AVL },
  { geo: AVL_GEO, dt: 'LOCAL', title: 'Council Member',
    ext: -3740005, full: 'Sage Turner', first: 'Sage', last: 'Turner',
    start: '2020-12-01', prec: 'month', how: 'elected', src: SRC_AVL },
  { geo: AVL_GEO, dt: 'LOCAL', title: 'Council Member',
    ext: -3740006, full: 'Maggie Ullman', first: 'Maggie', last: 'Ullman',
    start: '2022-12-01', prec: 'month', how: 'elected', src: SRC_AVL },
  { geo: AVL_GEO, dt: 'LOCAL', title: 'Council Member',
    ext: -3740007, full: 'Bo Hess', first: 'Bo', last: 'Hess', aliases: ['Roberto'],
    start: '2024-12-01', prec: 'month', how: 'elected', src: SRC_AVL },

  // ── Buncombe County: chair + 3 row offices on the county polygon ──────────
  { geo: BUN_GEO, dt: 'COUNTY', title: 'Chair, Board of Commissioners',
    ext: -3740008, full: 'Amanda Edwards', first: 'Amanda', last: 'Edwards',
    start: '2024-12-01', prec: 'month', how: 'elected', src: SRC_BUN },
  { geo: BUN_GEO, dt: 'COUNTY', title: 'Sheriff',
    ext: -3740015, full: 'Quentin E. Miller', first: 'Quentin', last: 'Miller', mi: 'E',
    start: '2018-01-01', prec: 'year', how: 'elected',
    src: 'buncombenc.gov/568/Sheriffs-Office ("since taking office in 2018"), retrieved 2026-08-23' },
  { geo: BUN_GEO, dt: 'COUNTY', title: 'Register of Deeds',
    ext: -3740016, full: 'Drew Reisinger', first: 'Drew', last: 'Reisinger',
    start: '2012-01-01', prec: 'year', how: 'elected', src: SRC_BUN },
  { geo: BUN_GEO, dt: 'COUNTY', title: 'Clerk of Superior Court',
    ext: -3740017, full: 'Jean Marie Christy', first: 'Jean Marie', last: 'Christy',
    start: '2023-01-01', prec: 'year', how: 'appointed',
    src: "Appointed 2023 on Steven Cogburn's retirement; elected in the November 2024 special election. " + SRC_BUN },

  // ── Buncombe commission districts: 2 identical seats each ────────────────
  { geo: CD(1), dt: 'COUNTY', title: 'Commissioner, District 1',
    ext: -3740009, full: 'Al Whitesides', first: 'Al', last: 'Whitesides', aliases: ['Alfred'],
    start: '2016-12-01', prec: 'month', how: 'appointed',
    src: 'Appointed December 2016 to the District 1 seat vacated when Brownie Newman became Chair; elected 2018 and 2022. ' + SRC_BUN },
  { geo: CD(1), dt: 'COUNTY', title: 'Commissioner, District 1',
    ext: -3740010, full: 'Jennifer Horton', first: 'Jennifer', last: 'Horton',
    start: '2024-12-01', prec: 'month', how: 'elected', src: SRC_BUN },
  { geo: CD(2), dt: 'COUNTY', title: 'Commissioner, District 2',
    ext: -3740011, full: 'Martin Moore', first: 'Martin', last: 'Moore',
    start: '2022-12-01', prec: 'month', how: 'elected', src: SRC_BUN },
  { geo: CD(2), dt: 'COUNTY', title: 'Commissioner, District 2',
    ext: -3740012, full: 'Terri Wells', first: 'Terri', last: 'Wells',
    start: '2020-12-01', prec: 'month', how: 'elected', src: SRC_BUN },
  { geo: CD(3), dt: 'COUNTY', title: 'Commissioner, District 3',
    ext: -3740013, full: 'Parker Sloan', first: 'Parker', last: 'Sloan',
    start: '2020-12-01', prec: 'month', how: 'elected', src: SRC_BUN },
  { geo: CD(3), dt: 'COUNTY', title: 'Commissioner, District 3',
    ext: -3740014, full: 'Drew Ball', first: 'Drew', last: 'Ball', aliases: ['Daryl'],
    start: '2025-01-01', prec: 'month', how: 'appointed',
    src: 'Appointed January 2025 to the District 3 seat vacated when Amanda Edwards became Chair (sworn 2025-01-07 per contemporaneous press; the county news release is no longer reachable, so recorded at month precision). ' + SRC_BUN },
];

// ─── Derived expectations. Every count the migrations assert comes from HERE, ──
// ─── so the SQL and the roster can never disagree about how many of anything. ─
const MULTI_GROUPS = [
  { geo: AVL_GEO, dt: 'LOCAL', title: 'Council Member', n: 6 },
  { geo: CD(1), dt: 'COUNTY', title: 'Commissioner, District 1', n: 2 },
  { geo: CD(2), dt: 'COUNTY', title: 'Commissioner, District 2', n: 2 },
  { geo: CD(3), dt: 'COUNTY', title: 'Commissioner, District 3', n: 2 },
];
const SINGLE_TITLES = ['Mayor', 'Chair, Board of Commissioners', 'Sheriff', 'Register of Deeds', 'Clerk of Superior Court'];

const TOTAL = ROSTER.length;
const N_AVL = ROSTER.filter((r) => r.geo === AVL_GEO).length;
const N_BUN_COUNTY = ROSTER.filter((r) => r.geo === BUN_GEO).length;
const N_APPOINTED = ROSTER.filter((r) => r.how === 'appointed').length;
const EXT_LO = Math.min(...ROSTER.map((r) => r.ext));
const EXT_HI = Math.max(...ROSTER.map((r) => r.ext));

// ─── Self-checks on the payload, before a byte of SQL is written ─────────────
{
  const errs = [];
  if (TOTAL !== 17) errs.push(`expected 17 roster rows, got ${TOTAL}`);
  if (N_AVL !== 7) errs.push(`expected 7 Asheville rows, got ${N_AVL}`);
  if (N_BUN_COUNTY !== 4) errs.push(`expected 4 Buncombe county-polygon rows, got ${N_BUN_COUNTY}`);
  const ids = new Set(ROSTER.map((r) => r.ext));
  if (ids.size !== TOTAL) errs.push('duplicate external_id in roster');
  for (const r of ROSTER) {
    if (r.ext > -3740001 || r.ext < -3749999) errs.push(`external_id ${r.ext} outside the wave-3 band`);
    if (!['day', 'month', 'year', 'unknown'].includes(r.prec)) errs.push(`bad start_precision ${r.prec}`);
    if (!['elected', 'appointed', 'succeeded', 'redistricted', 'unknown'].includes(r.how)) errs.push(`bad how_started ${r.how}`);
  }
  for (const g of MULTI_GROUPS) {
    const got = ROSTER.filter((r) => r.geo === g.geo && r.dt === g.dt && r.title === g.title).length;
    if (got !== g.n) errs.push(`group ${g.title} on ${g.geo}: expected ${g.n} roster rows, got ${got}`);
  }
  for (const t of SINGLE_TITLES) {
    const got = ROSTER.filter((r) => r.title === t).length;
    if (got !== 1) errs.push(`single-seat title '${t}': expected 1 roster row, got ${got}`);
  }
  if (errs.length) {
    console.error('ROSTER payload is invalid:\n  - ' + errs.join('\n  - '));
    process.exit(1);
  }
}

const q = (s) => (s === undefined || s === null ? 'NULL' : `'${String(s).replace(/'/g, "''")}'`);
// 🔴 essentials.politicians.alternate_names is NOT NULL DEFAULT '{}'::text[].
// Emitting NULL for a person with no recorded alias violates the constraint --
// caught by the CA_0009+CA_0010 rehearsal on 2026-08-23, which aborted on
// Manheimer (the very first row). An EMPTY ARRAY is the correct "no aliases",
// and it is not the same value as NULL to this column.
const arr = (a) => (a && a.length ? `ARRAY[${a.map(q).join(', ')}]::text[]` : `ARRAY[]::text[]`);

// ═══════════════════════════════════════════════════════════════════════════════
// CA_0009 — structure
// ═══════════════════════════════════════════════════════════════════════════════
const structure = `-- CA_0009_asheville_buncombe_structure.sql
-- NC deep-seed program, WAVE 3 (structure). Companion: CA_0010 (incumbents).
--
-- Creates the geography-and-seats half of Asheville + Buncombe County:
--   * 1 LOCAL district  -- 'Asheville Citywide' on TIGER place ${AVL_GEO}
--   * 3 COUNTY districts -- Buncombe's commission districts, mtfcc ${X_MTFCC}
--   * 2 governments, 3 chambers
--   * ${TOTAL} offices -- ${N_AVL} Asheville, ${N_BUN_COUNTY} on the county polygon, 6 on the commission districts
--
-- Spec: .planning/todos/2026-08-21-nc-durham-asheville-deep-seed.md (wave 3)
-- Plan: docs/superpowers/plans/2026-08-23-nc-wave-3-asheville-buncombe.md
-- Roster: data/seed-buncombe-asheville-2026/ROSTERS.md
-- Generated by: scripts/gen-buncombe-asheville-migrations.mjs
--
-- ─────────────────────────────────────────────────────────────────────────────
-- 🔴 THE MULTI-SEAT TOP-UP MUST BE SCOPED TO (chamber_id, district_id).
--
-- CA_0006 tops up identically-titled seats with
-- generate_series(1, N - (SELECT count(*) ... WHERE chamber_id = c.id AND title = ...)),
-- scoped to chamber_id ALONE, and says in its own comments that this is correct
-- only because Durham's chamber maps to exactly ONE district.
--
-- Buncombe is the case CA_0006 predicted. Its Board of Commissioners chamber
-- spans THREE districts with two seats each. A chamber-scoped count would see
-- the first district's 2 seats, compute 6 - 2 = 4, and keep topping up until the
-- chamber held 6 -- landing them on whichever district the join produced, while
-- still reporting "6 offices created". Nothing errors.
--
-- Two changes below, and BOTH are required:
--   1. the count subquery is scoped to (chamber_id, district_id);
--   2. the top-up runs PER DISTRICT (3 x 2), never once for 6.
-- The post-verify gate counts PER DISTRICT for the same reason: a total-only
-- assertion of 6 is exactly what the chamber-scoped bug satisfies.
--
-- ─────────────────────────────────────────────────────────────────────────────
-- 🔴 'Chair' IS AN OFFICE HERE. Durham's chairmanship rotates by board vote
-- among 5 at-large seats, so CA_0006 correctly refused to create one. A 2011
-- local act seats SEVEN commissioners in Buncombe: the chair elected COUNTYWIDE
-- plus six by district. Amanda Edwards ran for Chair as its own ballot line, and
-- her move from a District 3 seat to Chair is what created the vacancy Drew Ball
-- was appointed to fill. Do not carry CA_0006's rule across.
--
-- Conversely, Asheville's "Vice Mayor" is only a board role -- CA_0006's rule
-- DOES apply there. Asheville gets Mayor + 6 'Council Member', not 7 + a Vice
-- Mayor.
--
-- ─────────────────────────────────────────────────────────────────────────────
-- 🔴 geo_id '${BUN_GEO}' IS CLAIMED BY THREE DISTRICTS. Measured in prod 2026-08-23:
--     COUNTY      | Buncombe County           | ${BUN_GEO}
--     STATE_UPPER | State Senate District 21  | ${BUN_GEO}
--     STATE_LOWER | State House District 21   | ${BUN_GEO}
-- Every county join below pairs geo_id with district_type = 'COUNTY'. A bare
-- geo_id join would attach the Chair, Sheriff, Register of Deeds and Clerk to a
-- state legislative district while an "offices created" count still looked
-- right. The post-verify gate asserts both legislative rows are untouched.
--
-- The three ${X_MTFCC} districts are loaded by
-- scripts/load-buncombe-commissioner-boundaries.ts and verified by
-- scripts/verify-buncombe-commission-coupling.sql. This migration does NOT
-- create geometry; it fails if the boundaries are absent.
--
-- IDEMPOTENT: every insert is NOT EXISTS-guarded or a target-count top-up.

BEGIN;

-- ─── 0. Precondition: the commission boundaries must already be loaded ───────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries WHERE mtfcc = '${X_MTFCC}';
  IF v_n <> 3 THEN
    RAISE EXCEPTION 'CA_0009: expected 3 ${X_MTFCC} boundaries, found % -- run scripts/load-buncombe-commissioner-boundaries.ts first', v_n;
  END IF;
END $$;

-- ─── 1. Districts ────────────────────────────────────────────────────────────
-- Asheville's citywide district. Follows the 'Durham Citywide' / 'Bainbridge
-- Island Citywide' precedent: ALL council seats hang off ONE district because
-- every seat is elected citywide. Not Austin's one-district-per-seat shape.

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc)
SELECT '${AVL_GEO}', 'Asheville Citywide', 'LOCAL', 'nc', 'G4110'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = '${AVL_GEO}' AND district_type = 'LOCAL'
);

-- Buncombe's 3 commission districts. district_type 'COUNTY' matches the Kitsap
-- (X0027) and Washington County (X0027-era) precedents and is semantically right
-- for county offices; it was verified harmless on both read paths that branch on
-- district_type -- campaignFinanceSearchService.ts puts LOCAL and COUNTY in one
-- tier, and inform.compass_lenses auto-applies the 'local' lens to
-- {LOCAL,LOCAL_EXEC,COUNTY,SCHOOL}.
--
-- num_officials = 2: each district elects two commissioners. This is a measured
-- fact, not a template default.
${[1, 2, 3]
  .map(
    (n) => `
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT ${q(CD(n))}, ${q(`Buncombe County Commissioner District ${n}`)}, 'COUNTY', 'nc', '${X_MTFCC}', 2
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts
  WHERE geo_id = ${q(CD(n))} AND mtfcc = '${X_MTFCC}'
);`,
  )
  .join('')}

-- 🔴 Buncombe County's own COUNTY district (${BUN_GEO}) ALREADY EXISTS and is NOT
-- created here. Measured 2026-08-23: it exists and carries ZERO offices.

-- ─── 2. Governments ──────────────────────────────────────────────────────────
-- Neither exists yet (verified against prod 2026-08-23: zero rows in
-- essentials.governments for geo_id '${AVL_GEO}' or '${BUN_GEO}').

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'City of Asheville, North Carolina, US', 'City', 'NC', 'Asheville', '${AVL_GEO}'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE geo_id = '${AVL_GEO}' AND type = 'City'
);

INSERT INTO essentials.governments (name, type, state, city, geo_id)
SELECT 'Buncombe County, North Carolina, US', 'County', 'NC', NULL, '${BUN_GEO}'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE geo_id = '${BUN_GEO}' AND type = 'County'
);

-- ─── 3. Chambers ─────────────────────────────────────────────────────────────
-- Buncombe follows Durham's (and Travis County's) shape: one chamber for the
-- elected legislative board, one for the countywide elected executive officials.

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT g.id, 'City Council', 'Asheville City Council', 7, 'full'
FROM essentials.governments g
WHERE g.geo_id = '${AVL_GEO}' AND g.type = 'City'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
    WHERE c.government_id = g.id AND c.name = 'City Council'
  );

-- official_count 7 = chair + 6 district commissioners.
INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT g.id, 'Board of County Commissioners', 'Buncombe County Board of Commissioners', 7, 'full'
FROM essentials.governments g
WHERE g.geo_id = '${BUN_GEO}' AND g.type = 'County'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
    WHERE c.government_id = g.id AND c.name = 'Board of County Commissioners'
  );

INSERT INTO essentials.chambers
  (government_id, name, name_formal, official_count, policy_engagement_level)
SELECT g.id, 'Elected Officials', 'Buncombe County Elected Officials', 3, 'full'
FROM essentials.governments g
WHERE g.geo_id = '${BUN_GEO}' AND g.type = 'County'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.chambers c
    WHERE c.government_id = g.id AND c.name = 'Elected Officials'
  );

-- ─── 4a. Asheville: Mayor, a genuine single seat ─────────────────────────────

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, representing_city)
SELECT c.id, d.id, 'Mayor', 'NC', 'Asheville'
FROM essentials.chambers c
JOIN essentials.governments g ON g.id = c.government_id
CROSS JOIN LATERAL (
  SELECT dd.id FROM essentials.districts dd
  WHERE dd.geo_id = '${AVL_GEO}' AND dd.district_type = 'LOCAL' AND lower(dd.state) = 'nc'
) d
WHERE g.geo_id = '${AVL_GEO}' AND g.type = 'City' AND c.name = 'City Council'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id AND o.title = 'Mayor'
  );

-- ─── 4b. Asheville: 6 IDENTICAL 'Council Member' rows ────────────────────────
-- All six are elected at-large; no numbered seat exists on Asheville's ballot,
-- so the six offices are genuinely interchangeable and share one title. Guarded
-- by a target-count top-up rather than NOT EXISTS-on-title, which would collapse
-- six rows to one on a re-run.
--
-- The count is scoped to (chamber_id, district_id) even though this chamber maps
-- to a single district. It costs nothing and it means this block cannot become
-- the CA_0006 bug if Asheville ever districts its council.

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, representing_city)
SELECT c.id, d.id, 'Council Member', 'NC', 'Asheville'
FROM essentials.chambers c
JOIN essentials.governments g ON g.id = c.government_id
CROSS JOIN LATERAL (
  SELECT dd.id FROM essentials.districts dd
  WHERE dd.geo_id = '${AVL_GEO}' AND dd.district_type = 'LOCAL' AND lower(dd.state) = 'nc'
) d
CROSS JOIN LATERAL (
  SELECT generate_series(1, 6 - (
    SELECT count(*) FROM essentials.offices o
    WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = 'Council Member'
  )) AS n
) gs
WHERE g.geo_id = '${AVL_GEO}' AND g.type = 'City' AND c.name = 'City Council';

-- ─── 5a. Buncombe: Chair, countywide on the EXISTING county district ─────────
-- A real single-seat office -- see header.

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state)
SELECT c.id, d.id, 'Chair, Board of Commissioners', 'NC'
FROM essentials.chambers c
JOIN essentials.governments g ON g.id = c.government_id
CROSS JOIN LATERAL (
  SELECT dd.id FROM essentials.districts dd
  WHERE dd.geo_id = '${BUN_GEO}' AND dd.district_type = 'COUNTY' AND lower(dd.state) = 'nc'
) d
WHERE g.geo_id = '${BUN_GEO}' AND g.type = 'County' AND c.name = 'Board of County Commissioners'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.chamber_id = c.id AND o.title = 'Chair, Board of Commissioners'
  );

-- ─── 5b. Buncombe: 6 district commissioners, 2 PER DISTRICT ──────────────────
-- 🔴 THE BLOCK CA_0006 WARNED ABOUT. One top-up per district, each counting
-- within (chamber_id, district_id). See header for why a chamber-scoped count
-- silently creates 2 of 6.
${[1, 2, 3]
  .map(
    (n) => `
INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state, representation_note)
SELECT c.id, d.id, ${q(`Commissioner, District ${n}`)}, 'NC', ${q(couplingNote(n))}
FROM essentials.chambers c
JOIN essentials.governments g ON g.id = c.government_id
CROSS JOIN LATERAL (
  SELECT dd.id FROM essentials.districts dd
  WHERE dd.geo_id = ${q(CD(n))} AND dd.mtfcc = '${X_MTFCC}'
) d
CROSS JOIN LATERAL (
  SELECT generate_series(1, 2 - (
    SELECT count(*) FROM essentials.offices o
    WHERE o.chamber_id = c.id AND o.district_id = d.id
      AND o.title = ${q(`Commissioner, District ${n}`)}
  )) AS nn
) gs
WHERE g.geo_id = '${BUN_GEO}' AND g.type = 'County' AND c.name = 'Board of County Commissioners';
`,
  )
  .join('')}

-- ─── 5c. Buncombe: 3 countywide row offices ──────────────────────────────────

INSERT INTO essentials.offices
  (chamber_id, district_id, title, representing_state)
SELECT c.id, d.id, v.title, 'NC'
FROM (VALUES
  ('Sheriff'),
  ('Register of Deeds'),
  ('Clerk of Superior Court')
) AS v(title)
CROSS JOIN LATERAL (
  SELECT ch.id FROM essentials.chambers ch
  JOIN essentials.governments g ON g.id = ch.government_id
  WHERE g.geo_id = '${BUN_GEO}' AND g.type = 'County' AND ch.name = 'Elected Officials'
) c
CROSS JOIN LATERAL (
  SELECT dd.id FROM essentials.districts dd
  WHERE dd.geo_id = '${BUN_GEO}' AND dd.district_type = 'COUNTY' AND lower(dd.state) = 'nc'
) d
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o WHERE o.chamber_id = c.id AND o.title = v.title
);

-- ─── 6. Post-verify gate ─────────────────────────────────────────────────────
DO $$
DECLARE
  v_n int; v_hd21 int; v_sd21 int; v_nogeom int; v_notes int;
BEGIN
  -- Districts
  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE geo_id = '${AVL_GEO}' AND district_type = 'LOCAL';
  IF v_n <> 1 THEN RAISE EXCEPTION 'CA_0009: expected 1 Asheville LOCAL district, got %', v_n; END IF;

  SELECT count(*) INTO v_n FROM essentials.districts WHERE mtfcc = '${X_MTFCC}';
  IF v_n <> 3 THEN RAISE EXCEPTION 'CA_0009: expected 3 ${X_MTFCC} districts, got %', v_n; END IF;

  -- Asheville offices
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '${AVL_GEO}' AND d.district_type = 'LOCAL';
  IF v_n <> ${N_AVL} THEN RAISE EXCEPTION 'CA_0009: expected ${N_AVL} Asheville offices, got %', v_n; END IF;

  -- Buncombe county-polygon offices (chair + 3 row offices)
  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '${BUN_GEO}' AND d.district_type = 'COUNTY';
  IF v_n <> ${N_BUN_COUNTY} THEN RAISE EXCEPTION 'CA_0009: expected ${N_BUN_COUNTY} offices on the Buncombe county polygon, got %', v_n; END IF;

  -- 🔴 PER-DISTRICT, not 6 in total. A total-only assertion is precisely what a
  -- chamber-scoped top-up satisfies while putting every seat on one district.
${[1, 2, 3]
  .map(
    (n) => `  SELECT count(*) INTO v_n FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = ${q(CD(n))} AND d.mtfcc = '${X_MTFCC}';
  IF v_n <> 2 THEN RAISE EXCEPTION 'CA_0009: commission district ${n} carries % offices, expected exactly 2', v_n; END IF;`,
  )
  .join('\n')}

  -- The coupling note is required on all 6 district commissioner seats.
  SELECT count(*) INTO v_notes FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.mtfcc = '${X_MTFCC}' AND o.representation_note IS NOT NULL;
  IF v_notes <> 6 THEN RAISE EXCEPTION 'CA_0009: expected 6 commissioner offices carrying a representation_note, got %', v_notes; END IF;

  -- 🔴 The assertions that actually catch the geo_id collision. Counting offices
  -- on the county row alone would NOT notice offices landing on either
  -- legislative district.
  SELECT count(*) INTO v_hd21 FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '${BUN_GEO}' AND d.district_type = 'STATE_LOWER';
  IF v_hd21 <> 1 THEN RAISE EXCEPTION
    'CA_0009: NC House District 21 carries % offices, expected 1 -- county offices cross-wired onto the house district', v_hd21; END IF;

  SELECT count(*) INTO v_sd21 FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE d.geo_id = '${BUN_GEO}' AND d.district_type = 'STATE_UPPER';
  IF v_sd21 <> 1 THEN RAISE EXCEPTION
    'CA_0009: NC Senate District 21 carries % offices, expected 1 -- county offices cross-wired onto the senate district', v_sd21; END IF;

  -- No office may sit on a district with no geometry: it would be unreachable by
  -- address and nothing else would say so.
  SELECT count(*) INTO v_nogeom FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE (d.geo_id = '${AVL_GEO}' AND d.district_type = 'LOCAL' OR d.mtfcc = '${X_MTFCC}')
     AND NOT EXISTS (
       SELECT 1 FROM essentials.geofence_boundaries b
        WHERE b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc
     );
  IF v_nogeom <> 0 THEN RAISE EXCEPTION 'CA_0009: % office(s) sit on a district with no matching boundary', v_nogeom; END IF;

  RAISE NOTICE 'CA_0009 OK -- ${TOTAL} offices across 1 city district, 3 commission districts and the Buncombe county polygon.';
END $$;

COMMIT;
`;

// ═══════════════════════════════════════════════════════════════════════════════
// CA_0010 — incumbents
// ═══════════════════════════════════════════════════════════════════════════════
const seedRows = ROSTER.map(
  (r) =>
    `  (${q(r.geo)}, ${q(r.dt)}, ${q(r.title)}, ${r.ext}, ${q(r.full)}, ${q(r.first)}, ${q(r.last)}, ` +
    `${q(r.mi)}, ${q(r.suffix)}, ${arr(r.aliases)}, ${q(r.start)}::date, ${q(r.prec)}, ${q(r.how)}, ${q(r.src)})`,
).join(',\n');

const groupGuards = MULTI_GROUPS.map(
  (g) => `  SELECT count(*) INTO v_grp FROM wave3_seed
   WHERE geo_id = ${q(g.geo)} AND district_type = ${q(g.dt)} AND office_title = ${q(g.title)};
  IF v_grp <> ${g.n} THEN RAISE EXCEPTION 'seed payload: expected ${g.n} ${g.title.replace(/'/g, "''")} rows, got %', v_grp; END IF;`,
).join('\n\n');

const incumbents = `-- CA_0010_asheville_buncombe_incumbents.sql
-- NC deep-seed program, WAVE 3 (incumbents). Companion: CA_0009 (structure).
--
-- Inserts ${TOTAL} politicians and seats each one, via essentials.seat_officeholder().
--
-- Roster: data/seed-buncombe-asheville-2026/ROSTERS.md
-- Generated by: scripts/gen-buncombe-asheville-migrations.mjs
--
-- ─────────────────────────────────────────────────────────────────────────────
-- 🔴 term_start IS THE DAY THIS PERSON BEGAN HOLDING THIS SEAT, and Buncombe's
-- published year is TERM EXPIRY. Reading it as "elected four years earlier" is
-- wrong for FIVE of these ${TOTAL} people, because this board fills vacancies by
-- appointment repeatedly:
--
--   Whitesides  naive 2022 -> appointed 2016-12 (filled Newman's seat)
--   Wells       naive 2024 -> elected   2020-12
--   Sloan       naive 2024 -> elected   2020-12
--   Ball        naive 2022 -> appointed 2025-01 (filled Edwards' seat; the naive
--                                                read credits him with HER election)
--   Christy     naive 2022 -> appointed 2023    (on Cogburn's retirement)
--
-- Asheville has the mirror defect: its council page's "Term:" start is service
-- on the BODY, so the Mayor row reads December 2009 -- Manheimer's COUNCIL
-- start. She became Mayor 2013-12-10.
--
-- how_started: ${TOTAL - N_APPOINTED} 'elected', ${N_APPOINTED} 'appointed' (Mosley, Whitesides, Ball, Christy).
-- Passed to p_how_started EXPLICITLY -- never left to seat_officeholder()'s
-- 'elected' default, which would misclassify all ${N_APPOINTED}.
--
-- start_precision is per-source, not uniform: 'day' for Manheimer alone (a
-- documented swearing-in), 'month' for the 13 whose sources publish month and
-- year, 'year' for the three row officers. Where precision is 'year' the date is
-- written YYYY-01-01 and carries NO claim about the month -- the flag is what is
-- load-bearing.
--
-- ─────────────────────────────────────────────────────────────────────────────
-- IDENTITY. Guarded on external_id -- band -(3740000+n), n=1..${TOTAL} -- never on
-- full_name. Verified 2026-08-23: all ${TOTAL} names return ZERO rows in prod, and
-- the band ${EXT_HI}..${EXT_LO} is empty.
--
-- This is wave 2's Mike Lee lesson: prod holds three distinct people named some
-- variant of Michael Lee, and a bare-name guard would have inserted nothing,
-- passed a 1:1 assertion, and seated a sitting US Senator on the Durham County
-- Commission. A surname sweep for this wave surfaced three real but distinct
-- people -- Chaney Mosley, George Whitesides, Steve Christy -- plus FEC ALLCAPS
-- committee junk matching 'CHRISTY'. All separable by FIRST name.
--
-- ─────────────────────────────────────────────────────────────────────────────
-- FOUR GROUPS CONTAIN MORE THAN ONE IDENTICALLY-TITLED OFFICE:
--   6 x 'Council Member'            on ${AVL_GEO}
--   2 x 'Commissioner, District 1'  on ${CD(1)}
--   2 x 'Commissioner, District 2'  on ${CD(2)}
--   2 x 'Commissioner, District 3'  on ${CD(3)}
--
-- A title join cannot resolve one person to one office row inside those groups,
-- so the pairing is CA_0007's deterministic row_number() bijection, partitioned
-- by (geo_id, district_type, office_title): offices ORDER BY o.id (stable once
-- CA_0009 creates them), roster ORDER BY ext_id (fixed by ROSTERS.md). CA_0009's
-- gate asserts the exact office count per group and the guard below asserts the
-- exact roster count per group, so both sides yield 1..N with no gaps -- a
-- bijection, and idempotent on re-run.
--
-- 🔴 Same caveat as CA_0007: this is silent about OUT-OF-BAND deletion. If an
-- office row is deleted outside these two migrations and CA_0009's top-up
-- regenerates it, the replacement gets a new UUID that may sort to a different
-- rank. Within a group the seats are interchangeable, so no voter-facing label
-- goes wrong -- but seat_officeholder() would close and reopen terms against the
-- wrong predecessor, fabricating a term_end on a real person's record.
--
-- Joins key on (geo_id, district_type) together -- '${BUN_GEO}' is NOT unique across
-- Buncombe County (COUNTY), Senate District 21 (STATE_UPPER) and House District
-- 21 (STATE_LOWER).

BEGIN;

CREATE TEMP TABLE wave3_seed (
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

INSERT INTO wave3_seed VALUES
${seedRows};

-- ─── Payload guard ───────────────────────────────────────────────────────────
-- Four groups legitimately repeat a (geo_id, district_type, office_title) triple,
-- so this checks per-group COUNTS rather than rejecting any duplicate.
DO $$
DECLARE v_n int; v_dup int; v_grp int;
BEGIN
  SELECT count(*) INTO v_n FROM wave3_seed;
  IF v_n <> ${TOTAL} THEN RAISE EXCEPTION 'seed payload: expected ${TOTAL} rows, got %', v_n; END IF;

  SELECT count(*) INTO v_dup FROM (SELECT ext_id FROM wave3_seed GROUP BY ext_id HAVING count(*) > 1) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % duplicate external_id(s)', v_dup; END IF;

${groupGuards}

  -- Every OTHER triple must be unique -- the genuinely single-seat titles.
  SELECT count(*) INTO v_dup FROM (
    SELECT geo_id, district_type, office_title FROM wave3_seed
    WHERE office_title NOT IN (${MULTI_GROUPS.map((g) => q(g.title)).join(', ')})
    GROUP BY geo_id, district_type, office_title HAVING count(*) > 1
  ) x;
  IF v_dup <> 0 THEN RAISE EXCEPTION 'seed payload: % unexpected duplicate single-seat key(s)', v_dup; END IF;
END $$;

-- ─── Politicians ─────────────────────────────────────────────────────────────

INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, middle_initial, name_suffix,
   alternate_names, is_incumbent, is_active, data_source)
SELECT s.ext_id, s.full_name, s.first_name, s.last_name, s.middle_initial, s.name_suffix,
       s.aliases, true, true, s.source
FROM wave3_seed s
ON CONFLICT (external_id) DO NOTHING;

-- ─── Occupancy, via the helper ───────────────────────────────────────────────

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
      WHERE (d.geo_id = '${AVL_GEO}' AND d.district_type = 'LOCAL')
         OR (d.geo_id = '${BUN_GEO}' AND d.district_type = 'COUNTY')
         OR (d.mtfcc = '${X_MTFCC}')
    ),
    seed_rank AS (
      SELECT s.*,
             row_number() OVER (
               PARTITION BY s.geo_id, s.district_type, s.office_title ORDER BY s.ext_id
             ) AS rn
      FROM wave3_seed s
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
  RAISE NOTICE 'seated % Asheville/Buncombe official(s)', v_seated;
END $$;

-- ─── Post-verify gate ────────────────────────────────────────────────────────
DO $$
DECLARE
  v_pol int; v_seated int; v_appointed int; v_homonym int; v_n int;
BEGIN
  SELECT count(*) INTO v_pol
  FROM essentials.politicians WHERE external_id BETWEEN ${EXT_LO} AND ${EXT_HI};
  IF v_pol <> ${TOTAL} THEN RAISE EXCEPTION 'CA_0010: officials inserted: expected ${TOTAL}, got %', v_pol; END IF;

  -- count(och.politician_id), NOT count(*): office_current_holder LEFT JOINs from
  -- offices, so a vacancy is a NULL politician_id, never an absent row. count(*)
  -- would pass vacuously with every seat empty.
  SELECT count(och.politician_id) INTO v_seated
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE (d.geo_id = '${AVL_GEO}' AND d.district_type = 'LOCAL')
      OR (d.geo_id = '${BUN_GEO}' AND d.district_type = 'COUNTY')
      OR (d.mtfcc = '${X_MTFCC}');
  IF v_seated <> ${TOTAL} THEN RAISE EXCEPTION 'CA_0010: expected ${TOTAL} seated officials, found %', v_seated; END IF;

  -- Exactly 2 SEATED commissioners per district -- again per-district, because a
  -- total of 6 is what the chamber-scoped top-up bug would also produce.
${[1, 2, 3]
  .map(
    (n) => `  SELECT count(och.politician_id) INTO v_n
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE d.geo_id = ${q(CD(n))} AND d.mtfcc = '${X_MTFCC}';
  IF v_n <> 2 THEN RAISE EXCEPTION 'CA_0010: commission district ${n} has % seated commissioner(s), expected 2', v_n; END IF;`,
  )
  .join('\n')}

  SELECT count(*) INTO v_appointed
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE p.external_id BETWEEN ${EXT_LO} AND ${EXT_HI} AND t.how_started = 'appointed';
  IF v_appointed <> ${N_APPOINTED} THEN RAISE EXCEPTION 'CA_0010: expected ${N_APPOINTED} appointed term(s), found %', v_appointed; END IF;

  -- 🔴 Cross-state homonym assertion: no wave-3 seat may resolve to someone who
  -- also holds an office outside NC. This is the Mike Lee guard.
  SELECT count(*) INTO v_homonym
  FROM essentials.politicians p
  JOIN essentials.office_current_holder och ON och.politician_id = p.id
  JOIN essentials.offices o ON o.id = och.office_id
  JOIN essentials.districts d ON d.id = o.district_id
   AND ((d.geo_id = '${AVL_GEO}' AND d.district_type = 'LOCAL')
     OR (d.geo_id = '${BUN_GEO}' AND d.district_type = 'COUNTY')
     OR (d.mtfcc = '${X_MTFCC}'))
  JOIN essentials.office_current_holder och2 ON och2.politician_id = p.id
  JOIN essentials.offices o2 ON o2.id = och2.office_id
  JOIN essentials.districts d2 ON d2.id = o2.district_id AND lower(d2.state) <> 'nc';
  IF v_homonym <> 0 THEN RAISE EXCEPTION
    'CA_0010: % wave-3 seat(s) resolved to an out-of-state politician -- the Mike Lee failure', v_homonym; END IF;

  RAISE NOTICE 'CA_0010 OK -- ${TOTAL} officials seated, ${N_APPOINTED} by appointment, 0 homonyms.';
END $$;

COMMIT;
`;

// ─── Emit ────────────────────────────────────────────────────────────────────
const outStructure = join(MIGRATIONS, 'CA_0009_asheville_buncombe_structure.sql');
const outIncumbents = join(MIGRATIONS, 'CA_0010_asheville_buncombe_incumbents.sql');
writeFileSync(outStructure, structure, { encoding: 'utf8' });
writeFileSync(outIncumbents, incumbents, { encoding: 'utf8' });

// ─── Verify the emitted bytes ────────────────────────────────────────────────
// A mojibaked or BOM-prefixed name is voter-facing. Check both.
let bad = 0;
for (const [label, path] of [['structure', outStructure], ['incumbents', outIncumbents]]) {
  const buf = readFileSync(path);
  if (buf[0] === 0xef && buf[1] === 0xbb && buf[2] === 0xbf) {
    console.error(`FAIL: ${label} was written with a UTF-8 BOM`);
    bad++;
  }
  const text = buf.toString('utf8');
  for (const r of ROSTER) {
    if (!text.includes(r.full) && label === 'incumbents') {
      console.error(`FAIL: ${label} does not contain '${r.full}' verbatim`);
      bad++;
    }
  }
  // The emitted SQL is deliberately all-ASCII outside comments: no name and no
  // source string carries a smart quote, so there is nothing in a VALUE for a
  // mis-decode to corrupt. Assert that rather than trusting it -- a mojibaked
  // name is voter-facing. (Comment lines are exempt: they use box-drawing rules
  // and emoji markers, matching the house style of CA_0006/CA_0007.)
  const nonAsciiInValues = text
    .split(/\r?\n/)
    .filter((l) => !l.trimStart().startsWith('--'))
    .filter((l) => /[^\x00-\x7F]/.test(l));
  if (nonAsciiInValues.length) {
    console.error(
      `FAIL: ${label} has non-ASCII outside comments: ${nonAsciiInValues.slice(0, 3).join(' | ')}`,
    );
    bad++;
  }
  console.log(`  wrote ${path} (${buf.length} bytes)`);
}

console.log(
  `\n${TOTAL} roster rows -> ${N_AVL} Asheville + ${N_BUN_COUNTY} Buncombe countywide + 6 commission-district offices` +
    `\n${N_APPOINTED} appointed, ${TOTAL - N_APPOINTED} elected; external_id ${EXT_LO}..${EXT_HI}`,
);
if (bad > 0) {
  console.error(`\n${bad} emitted-byte check(s) failed.`);
  process.exit(1);
}
console.log('OK');
