/**
 * gen-1414-bend-records.mjs — emits migrations/1414_bend_or_deep_seed_records.sql
 *
 * Generator (not a runtime script): 26 officials across 4 governments produce ~26 near-identical
 * politician+office blocks. Hand-writing them invites copy-paste drift, so they are generated from
 * the ROSTER table below, which mirrors data/stance-research/bend-or/00-ROSTER-RESEARCH.md.
 *
 * Run: node scripts/gen-1414-bend-records.mjs
 */
import { writeFileSync } from 'fs';

const MIG = '1414';

// ---------------------------------------------------------------------------
// Governments / chambers / districts
// ---------------------------------------------------------------------------
const CITY_GOV = 'City of Bend, Oregon, US';
const COUNTY_GOV = 'Deschutes County, Oregon, US';
const SCHOOL_GOV = 'Bend-La Pine Administrative School District 1, Oregon, US';
const PARK_GOV = 'Bend Metro Park & Recreation District, Oregon, US';

const CITY_GEO = '4105800';
const COUNTY_GEO = '41017';
const SCHOOL_GEO = '4101980';
const PARK_GEO = 'bend-or-park-rec-district';

/** district selector: [geo_id, district_type, state] */
const D_CITY_EXEC = [CITY_GEO, 'LOCAL_EXEC'];
const D_CITY = [CITY_GEO, 'LOCAL'];
const D_COUNTY = [COUNTY_GEO, 'COUNTY'];
const D_SCHOOL = [SCHOOL_GEO, 'SCHOOL'];
const D_PARK = [PARK_GEO, 'LOCAL'];

const CH_CITY = ['City Council', CITY_GOV];
const CH_COMM = ['Board of County Commissioners', COUNTY_GOV];
const CH_ROW = ['Countywide Elected Officials', COUNTY_GOV];
const CH_SCHOOL = ['School Board', SCHOOL_GOV];
const CH_PARK = ['Board of Directors', PARK_GOV];

// ---------------------------------------------------------------------------
// ROSTER — every row is sourced in 00-ROSTER-RESEARCH.md
// ---------------------------------------------------------------------------
const ROSTER = [
  // --- City of Bend: Mayor + 6 at-large numbered positions (bendoregon.gov/city-council/) ---
  { ext: -4105801, name: 'Melanie Kebler', title: 'Mayor', d: D_CITY_EXEC, ch: CH_CITY, city: 'Bend',
    email: 'mkebler@bendoregon.gov', url: 'https://bendoregon.gov/city-council/melanie-kebler/',
    note: 'Mayor of Bend; directly elected Nov 2022, term through January 2027. Filed for re-election Nov 3, 2026.' },
  { ext: -4105802, name: 'Megan Norris', title: 'Councilor, Position 1', d: D_CITY, ch: CH_CITY, city: 'Bend',
    email: 'mnorris@bendoregon.gov', url: 'https://bendoregon.gov/city-council/megan-norris/',
    note: 'Re-elected Nov 2024 (73.0%), term through January 2029.' },
  { ext: -4105803, name: 'Gina Franzosa', title: 'Councilor, Position 2', d: D_CITY, ch: CH_CITY, city: 'Bend',
    email: 'gfranzosa@bendoregon.gov', url: 'https://bendoregon.gov/city-council/gina-franzosa/',
    note: 'Elected unopposed Nov 2024, term through January 2029.' },
  { ext: -4105804, name: 'Megan Perkins', title: 'Councilor, Position 3', d: D_CITY, ch: CH_CITY, city: 'Bend',
    email: 'mperkins@bendoregon.gov', url: 'https://bendoregon.gov/city-council/megan-perkins/',
    note: 'Mayor Pro Tem (chosen by the Council, not a separate office). Re-elected Nov 2024, term through January 2029.' },
  { ext: -4105805, name: 'Steve Platt', title: 'Councilor, Position 4', d: D_CITY, ch: CH_CITY, city: 'Bend',
    email: 'splatt@bendoregon.gov', url: 'https://bendoregon.gov/city-council/steve-platt/',
    note: 'Elected Nov 2024 (58.3%), term through January 2029.' },
  { ext: -4105806, name: 'Ariel Méndez', title: 'Councilor, Position 5', d: D_CITY, ch: CH_CITY, city: 'Bend',
    email: 'amendez@bendoregon.gov', url: 'https://bendoregon.gov/city-council/ariel-mendez/',
    note: 'Elected Nov 2022, term through January 2027. Filed for re-election Nov 3, 2026.' },
  { ext: -4105807, name: 'Mike Riley', title: 'Councilor, Position 6', d: D_CITY, ch: CH_CITY, city: 'Bend',
    email: 'mriley@bendoregon.gov', url: 'https://bendoregon.gov/city-council/mike-riley/',
    note: 'Elected Nov 2022, term through January 2027. Had NOT filed for re-election as of 2026-07-24 (city filing closes Aug 25, 2026).' },

  // --- Deschutes County: 3 at-large commissioners (deschutescounty.gov/275) ---
  { ext: -4101701, name: 'Anthony (Tony) DeBone', first: 'Anthony', last: 'DeBone',
    title: 'Commissioner, Position 1 (Vice Chair)', d: D_COUNTY, ch: CH_COMM,
    note: 'Term expires January 2027. Lost the May 19, 2026 primary for Position 1 to Jamie Collins (38% to 55%).' },
  { ext: -4101702, name: 'Phil Chang', title: 'Commissioner, Position 2 (Chair)', d: D_COUNTY, ch: CH_COMM,
    note: 'Board Chair. Re-elected 2024, term expires January 2029 — not on the 2026 ballot.' },
  { ext: -4101703, name: 'Patti Adair', title: 'Commissioner, Position 3', d: D_COUNTY, ch: CH_COMM,
    note: 'Term expires January 2027; not seeking re-election. Republican nominee for U.S. House OR-05 in Nov 2026.' },

  // --- Deschutes County: countywide elected row officers ---
  { ext: -4101711, name: 'Steve Dennison', title: 'County Clerk', d: D_COUNTY, ch: CH_ROW,
    note: 'Appointed 2021-08-01, elected Nov 2022; term expires January 2027. Running for re-election Nov 3, 2026.' },
  { ext: -4101712, name: 'Scot Langton', title: 'County Assessor', d: D_COUNTY, ch: CH_ROW,
    note: 'In office since 2001; term expires January 2027. Retiring — not seeking re-election.' },
  { ext: -4101713, name: 'Bill Kuhn', title: 'County Treasurer', d: D_COUNTY, ch: CH_ROW,
    note: 'Elected Nov 2022; term expires January 2027. Not running in 2026.' },
  { ext: -4101714, name: 'Ty Rupert', title: 'County Sheriff', d: D_COUNTY, ch: CH_ROW, appointed: true,
    note: 'Appointed interim Sheriff 2025-07-29 (effective Aug 1, 2025) after Kent van der Kamp resigned; serves through January 2027. Candidate in the Nov 3, 2026 Sheriff election.' },

  // --- Bend-La Pine Schools: 7 zone directors (blschools.org) ---
  { ext: -4101981, name: 'Jenn Lynch', title: 'Director, Zone 1', d: D_SCHOOL, ch: CH_SCHOOL },
  { ext: -4101982, name: 'Marcus LeGrand', title: 'Director, Zone 2', d: D_SCHOOL, ch: CH_SCHOOL },
  { ext: -4101983, name: 'Cameron Fischer', title: 'Director, Zone 3 (Vice Chair)', d: D_SCHOOL, ch: CH_SCHOOL },
  { ext: -4101984, name: 'Shirley Olson', title: 'Director, Zone 4', d: D_SCHOOL, ch: CH_SCHOOL },
  { ext: -4101985, name: 'Amy Tatom', title: 'Director, Zone 5 (Chair)', d: D_SCHOOL, ch: CH_SCHOOL },
  { ext: -4101986, name: 'Ross Tomlin', title: 'Director, Zone 6', d: D_SCHOOL, ch: CH_SCHOOL },
  { ext: -4101987, name: 'Kina Chadwick', title: 'Director, Zone 7', d: D_SCHOOL, ch: CH_SCHOOL },

  // --- Bend Metro Park & Recreation District: 5 directors (bendparksandrec.org) ---
  { ext: -4105821, name: 'Cary Schneider', title: 'Director (Chair)', d: D_PARK, ch: CH_PARK, city: 'Bend',
    note: 'Board Chair; term through June 30, 2029.' },
  { ext: -4105822, name: 'Deb Schoen', title: 'Director (Vice Chair)', d: D_PARK, ch: CH_PARK, city: 'Bend',
    note: 'Board Vice-Chair; term through June 30, 2029.' },
  { ext: -4105823, name: 'Nathan Hovekamp', title: 'Director', d: D_PARK, ch: CH_PARK, city: 'Bend',
    note: 'Legislative Liaison; on the board since 2015; term through June 30, 2029.' },
  { ext: -4105824, name: 'Jodie Schiffman', title: 'Director', d: D_PARK, ch: CH_PARK, city: 'Bend',
    note: 'Joined the board by appointment in January 2023; term through June 30, 2027. Former Bend city councilor and Mayor Pro Tem.' },
  { ext: -4105825, name: 'Donna Owens', title: 'Director', d: D_PARK, ch: CH_PARK, city: 'Bend',
    note: 'Joined the board by appointment in January 2023; term through June 30, 2027.' },
];

// ---------------------------------------------------------------------------
// SQL emit helpers
// ---------------------------------------------------------------------------
const q = (s) => `'${String(s).replace(/'/g, "''")}'`;
const arr = (items) => (items.length ? `ARRAY[${items.map(q).join(', ')}]::text[]` : 'NULL');

function splitName(r) {
  if (r.first && r.last) return [r.first, r.last];
  const parts = r.name.split(' ');
  return [parts[0], parts[parts.length - 1]];
}

function govSel(gov) {
  return `(SELECT id FROM essentials.governments WHERE name = ${q(gov)})`;
}
/** Chamber lookup is ALWAYS scoped by (name, government_id) — never by slug.
 *  See migration 1049 / Springfield MO: 'springfield-city-council' resolved to the
 *  Massachusetts chamber and silently mis-attached offices. */
function chSel([name, gov]) {
  return `(SELECT id FROM essentials.chambers WHERE name = ${q(name)} AND government_id = ${govSel(gov)})`;
}

function officialBlock(r, i) {
  const [first, last] = splitName(r);
  const [geo, dtype] = r.d;
  const emails = r.email ? arr([r.email]) : 'NULL';
  const urls = r.url ? arr([r.url]) : 'NULL';
  const notes = r.note ? arr([r.note]) : 'NULL';
  const appointed = r.appointed ? 'true' : 'false';
  const city = r.city ? q(r.city) : 'NULL';
  return `
-- Official ${i + 1}/${ROSTER.length}: ${r.name} — ${r.title} (external_id ${r.ext})
WITH ins_p AS (
  INSERT INTO essentials.politicians
    (id, full_name, first_name, last_name, party, is_active, is_appointed,
     is_vacant, is_incumbent, external_id, email_addresses, urls, notes)
  VALUES (gen_random_uuid(), ${q(r.name)}, ${q(first)}, ${q(last)}, NULL,
          true, ${appointed}, false, true, ${r.ext}, ${emails}, ${urls}, ${notes})
  ON CONFLICT (external_id) DO UPDATE
    SET is_active = EXCLUDED.is_active
  RETURNING id
)
INSERT INTO essentials.offices
  (id, district_id, chamber_id, politician_id, title, representing_state,
   representing_city, is_appointed_position, is_vacant, role_canonical)
SELECT gen_random_uuid(),
       d.id,
       ${chSel(r.ch)},
       p.id,
       ${q(r.title)}, 'OR', ${city}, ${appointed}, false, NULL
FROM essentials.districts d
CROSS JOIN ins_p p
WHERE d.geo_id = ${q(geo)}
  AND d.district_type = ${q(dtype)}
  AND d.state = 'or'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
    WHERE o.district_id = d.id AND o.politician_id = p.id
  );
`;
}

const allExt = ROSTER.map((r) => r.ext);
const extList = (rows) => rows.map((r) => r.ext).join(',');
const inCh = (ch) => ROSTER.filter((r) => r.ch === ch);

const sql = `-- Migration ${MIG}: Bend, OR deep seed — records
--
-- Purpose: seeds every locally-elected body a Bend resident votes for, across FOUR governments:
--   1. City of Bend                                  geo_id '${CITY_GEO}'   — 7 officials (Mayor + 6 councilors)
--   2. Deschutes County                               geo_id '${COUNTY_GEO}'      — 7 officials (3 commissioners + 4 row officers)
--   3. Bend-La Pine Administrative School District 1  geo_id '${SCHOOL_GEO}'   — 7 directors (Zones 1-7)
--   4. Bend Metro Park & Recreation District          geo_id '${PARK_GEO}' — 5 directors
-- Total: 4 governments, 5 chambers, 5 districts (1 pre-existing), ${ROSTER.length} politicians, ${ROSTER.length} offices.
--
-- Every roster row is sourced in backend/data/stance-research/bend-or/00-ROSTER-RESEARCH.md.
-- This file is GENERATED by scripts/gen-1414-bend-records.mjs — edit the generator, not the SQL.
--
-- FORM OF GOVERNMENT (research-confirmed against primary sources):
--   City of Bend: council-manager. 6 councilors + a directly-elected Mayor, ALL AT-LARGE but with
--     NUMBERED POSITIONS (1-6, Mayor = Position 7 on the ballot). Per bendoregon.gov/city-council/
--     elections/: "All positions are elected at-large and are not tied to any specific geographic
--     areas." So: numbered titles, but NO ward districts/geofences of any kind. Differs from Tigard
--     (mig 1159, pure at-large plain 'Councilor') and Hillsboro (mig 1150, real wards).
--     Mayor Pro Tem (Perkins) is chosen BY the council — a note on her seat, NOT a separate office.
--   Deschutes County: 3 commissioners elected AT LARGE to numbered positions; all county offices
--     are NONPARTISAN. Chair/Vice Chair rotate among the three — annotated in the title, not
--     separate offices. Voters approved expansion to 5 seats effective with the 2026 election;
--     the two new seats (Positions 4 and 5) are NOT seeded as officeholders because nobody holds
--     them until January 2027 — they exist only as 2026 races (see the races migration).
--   Bend-La Pine Schools: 7 directors, elected district-wide but each resident in a zone (1-7).
--   BPRD: 5 directors, ORS ch. 198/266, 4-year terms ending June 30.
--
-- CRITICAL / traps this migration deliberately handles:
--   * chambers.slug is GENERATED — never INSERT it. Every chamber lookup is scoped by
--     (name, government_id), NEVER by slug (Springfield MO mig 1049: 'springfield-city-council'
--     silently resolved to the MASSACHUSETTS chamber and mis-attached offices).
--   * districts.state must be lowercase 'or'; governments.state and offices.representing_state
--     are uppercase 'OR'.
--   * geo_id '${COUNTY_GEO}' is ALSO used by OR "State House District 17" (G5220) and "State Senate
--     District 17" (G5210) district rows. Every county district lookup here is scoped by
--     district_type='COUNTY' — geo_id alone is ambiguous.
--   * The Deschutes County COUNTY district row ALREADY EXISTS (census_tiger_2024) with
--     government_id NULL — this migration ADOPTS it (UPDATE) rather than inserting a duplicate.
--   * Both Deschutes chambers share that one COUNTY district. That is the established
--     multi-chamber-county pattern (see Brown/Greene/Jackson County IN, where Assessor, Sheriff,
--     Treasurer... chambers all hang off the single COUNTY district row), so the section-split
--     detector below is scoped to the CITY geo_id only.
--   * The two geofences this seed needs beyond what TIGER already loaded (Bend-La Pine G5420 and
--     BPRD X0024) are imported by scripts/import-bend-geofences.ts, which MUST run first — gate
--     (c) asserts all four boundaries are present and rolls back if not.
--   * essentials.governments has no unique constraint on geo_id — all inserts use NOT EXISTS.

BEGIN;

-- =============================================================================
-- Pre-flight: hard abort if this migration was already applied
-- =============================================================================
DO $$
BEGIN
  IF (SELECT COUNT(*) FROM essentials.governments
      WHERE name IN (${q(CITY_GOV)}, ${q(COUNTY_GOV)},
                     ${q(SCHOOL_GOV)},
                     ${q(PARK_GOV)})) > 0 THEN
    RAISE EXCEPTION 'Migration ${MIG} already applied (a Bend/Deschutes government row exists) — aborting re-run';
  END IF;
END $$;


-- =============================================================================
-- Step 1: Government rows (4)
-- =============================================================================
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), ${q(CITY_GOV)}, 'LOCAL', 'OR', 'Bend', ${q(CITY_GEO)}
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = ${q(CITY_GOV)});

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), ${q(COUNTY_GOV)}, 'County', 'OR', NULL, ${q(COUNTY_GEO)}
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = ${q(COUNTY_GOV)});

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), ${q(SCHOOL_GOV)}, 'LOCAL', 'OR', NULL, ${q(SCHOOL_GEO)}
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = ${q(SCHOOL_GOV)});

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), ${q(PARK_GOV)}, 'LOCAL', 'OR', 'Bend', ${q(PARK_GEO)}
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = ${q(PARK_GOV)});


-- =============================================================================
-- Step 2: Chambers (5) — generated slug column intentionally omitted
-- =============================================================================
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count, election_method)
SELECT gen_random_uuid(), 'City Council', 'Bend City Council', ${govSel(CITY_GOV)}, 7, 'at-large numbered positions'
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers
                  WHERE name = 'City Council' AND government_id = ${govSel(CITY_GOV)});

INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count, election_method)
SELECT gen_random_uuid(), 'Board of County Commissioners', 'Deschutes County Board of County Commissioners',
       ${govSel(COUNTY_GOV)}, 3, 'at-large numbered positions, nonpartisan'
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers
                  WHERE name = 'Board of County Commissioners' AND government_id = ${govSel(COUNTY_GOV)});

INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count, election_method)
SELECT gen_random_uuid(), 'Countywide Elected Officials', 'Deschutes County Countywide Elected Officials',
       ${govSel(COUNTY_GOV)}, 4, 'countywide, nonpartisan'
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers
                  WHERE name = 'Countywide Elected Officials' AND government_id = ${govSel(COUNTY_GOV)});

INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count, election_method)
SELECT gen_random_uuid(), 'School Board', 'Bend-La Pine Administrative School District 1 School Board',
       ${govSel(SCHOOL_GOV)}, 7, 'district-wide vote, zone residency'
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers
                  WHERE name = 'School Board' AND government_id = ${govSel(SCHOOL_GOV)});

INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count, election_method)
SELECT gen_random_uuid(), 'Board of Directors', 'Bend Metro Park & Recreation District Board of Directors',
       ${govSel(PARK_GOV)}, 5, 'district-wide, nonpartisan'
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers
                  WHERE name = 'Board of Directors' AND government_id = ${govSel(PARK_GOV)});


-- =============================================================================
-- Step 3: Districts
--   City:   LOCAL_EXEC (Mayor, citywide) + LOCAL (at-large councilors) at the place FIPS
--   County: ADOPT the pre-existing COUNTY/G4020 row (set government_id) — do NOT insert
--   School: SCHOOL/G5420 at the TIGER unified-school-district GEOID
--   Park:   LOCAL/X0024 at the synthetic park-district geo_id
-- =============================================================================
INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc, government_id)
SELECT gen_random_uuid(), 'LOCAL_EXEC', 'or', ${q(CITY_GEO)}, 'Bend (Mayor, Citywide)', NULL, ${govSel(CITY_GOV)}
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts
                  WHERE geo_id = ${q(CITY_GEO)} AND district_type = 'LOCAL_EXEC' AND state = 'or');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc, government_id)
SELECT gen_random_uuid(), 'LOCAL', 'or', ${q(CITY_GEO)}, 'Bend (At-Large)', NULL, ${govSel(CITY_GOV)}
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts
                  WHERE geo_id = ${q(CITY_GEO)} AND district_type = 'LOCAL' AND state = 'or');

-- ADOPT the existing Deschutes County district (created by the TIGER county load with a NULL
-- government_id). Scoped by district_type='COUNTY' because geo_id '${COUNTY_GEO}' also names OR
-- State House/Senate District 17 rows.
UPDATE essentials.districts
SET government_id = ${govSel(COUNTY_GOV)},
    label = 'Deschutes County',
    city = NULL
WHERE geo_id = ${q(COUNTY_GEO)} AND district_type = 'COUNTY' AND state = 'or'
  AND government_id IS NULL;

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc, government_id)
SELECT gen_random_uuid(), 'SCHOOL', 'or', ${q(SCHOOL_GEO)},
       'Bend-La Pine Administrative School District 1', 'G5420', ${govSel(SCHOOL_GOV)}
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts
                  WHERE geo_id = ${q(SCHOOL_GEO)} AND district_type = 'SCHOOL' AND state = 'or');

INSERT INTO essentials.districts (id, district_type, state, geo_id, label, mtfcc, government_id)
SELECT gen_random_uuid(), 'LOCAL', 'or', ${q(PARK_GEO)},
       'Bend Metro Park & Recreation District', 'X0024', ${govSel(PARK_GOV)}
WHERE NOT EXISTS (SELECT 1 FROM essentials.districts
                  WHERE geo_id = ${q(PARK_GEO)} AND district_type = 'LOCAL' AND state = 'or');


-- =============================================================================
-- Step 4: Officials — ${ROSTER.length} politician + office pairs
-- =============================================================================
${ROSTER.map(officialBlock).join('')}

-- =============================================================================
-- Step 5: office_id back-fill (all ${ROSTER.length}); WHERE office_id IS NULL for idempotency
-- =============================================================================
UPDATE essentials.politicians p
SET office_id = o.id
FROM essentials.offices o
WHERE o.politician_id = p.id
  AND p.external_id IN (${allExt.join(',')})
  AND p.office_id IS NULL;


-- =============================================================================
-- Post-verification — raises EXCEPTION on any failure, rolling back the whole seed
--   (a) 4 governments present
--   (b) per-chamber office counts land in the INTENDED chamber (Springfield slug-collision trap)
--   (c) all four geofence boundaries present (import-bend-geofences.ts ran)
--   (d) section-split detector for the CITY geo_id (county intentionally exempt — shared district)
--   (e) office_id back-fill: 0 nulls
--   (f) representing_city='Bend' on the 12 city + park offices
--   (g) the pre-existing Deschutes COUNTY district is now owned by the county government
-- =============================================================================
DO $$
DECLARE
  v_gov       INTEGER;
  v_city      INTEGER;
  v_comm      INTEGER;
  v_row       INTEGER;
  v_school    INTEGER;
  v_park      INTEGER;
  v_geo       INTEGER;
  v_split     INTEGER;
  v_nulls     INTEGER;
  v_repcity   INTEGER;
  v_countydis INTEGER;
BEGIN
  -- (a)
  SELECT COUNT(*) INTO v_gov FROM essentials.governments
  WHERE name IN (${q(CITY_GOV)}, ${q(COUNTY_GOV)},
                 ${q(SCHOOL_GOV)}, ${q(PARK_GOV)});
  IF v_gov <> 4 THEN
    RAISE EXCEPTION 'FAILED (a): governments=%, expected 4', v_gov;
  END IF;

  -- (b) office counts BY CHAMBER — asserts offices landed in the intended chamber, not a
  --     same-named chamber belonging to another government
  SELECT COUNT(*) INTO v_city FROM essentials.offices o
  WHERE o.chamber_id = ${chSel(CH_CITY)};
  IF v_city <> 7 THEN RAISE EXCEPTION 'FAILED (b): Bend City Council offices=%, expected 7', v_city; END IF;

  SELECT COUNT(*) INTO v_comm FROM essentials.offices o
  WHERE o.chamber_id = ${chSel(CH_COMM)};
  IF v_comm <> 3 THEN RAISE EXCEPTION 'FAILED (b): Deschutes commissioner offices=%, expected 3', v_comm; END IF;

  SELECT COUNT(*) INTO v_row FROM essentials.offices o
  WHERE o.chamber_id = ${chSel(CH_ROW)};
  IF v_row <> 4 THEN RAISE EXCEPTION 'FAILED (b): Deschutes row-officer offices=%, expected 4', v_row; END IF;

  SELECT COUNT(*) INTO v_school FROM essentials.offices o
  WHERE o.chamber_id = ${chSel(CH_SCHOOL)};
  IF v_school <> 7 THEN RAISE EXCEPTION 'FAILED (b): Bend-La Pine board offices=%, expected 7', v_school; END IF;

  SELECT COUNT(*) INTO v_park FROM essentials.offices o
  WHERE o.chamber_id = ${chSel(CH_PARK)};
  IF v_park <> 5 THEN RAISE EXCEPTION 'FAILED (b): BPRD board offices=%, expected 5', v_park; END IF;

  -- (c) geofence presence — independent of anything this migration inserts
  SELECT COUNT(*) INTO v_geo FROM essentials.geofence_boundaries
  WHERE (geo_id = ${q(CITY_GEO)} AND mtfcc = 'G4110')
     OR (geo_id = ${q(COUNTY_GEO)} AND mtfcc = 'G4020')
     OR (geo_id = ${q(SCHOOL_GEO)} AND mtfcc = 'G5420')
     OR (geo_id = ${q(PARK_GEO)} AND mtfcc = 'X0024');
  IF v_geo <> 4 THEN
    RAISE EXCEPTION 'FAILED (c): Bend-area geofence rows=%, expected 4 — run scripts/import-bend-geofences.ts first', v_geo;
  END IF;

  -- (d) one chamber per district, city only
  SELECT COUNT(*) INTO v_split FROM (
    SELECT o.district_id
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE d.geo_id = ${q(CITY_GEO)}
    GROUP BY o.district_id
    HAVING COUNT(DISTINCT o.chamber_id) > 1
  ) x;
  IF v_split <> 0 THEN RAISE EXCEPTION 'FAILED (d): city section-split rows=%', v_split; END IF;

  -- (e)
  SELECT COUNT(*) INTO v_nulls FROM essentials.politicians
  WHERE external_id IN (${allExt.join(',')}) AND office_id IS NULL;
  IF v_nulls <> 0 THEN RAISE EXCEPTION 'FAILED (e): % politicians with NULL office_id', v_nulls; END IF;

  -- (f)
  SELECT COUNT(*) INTO v_repcity FROM essentials.offices o
  JOIN essentials.politicians p ON p.id = o.politician_id
  WHERE p.external_id IN (${ROSTER.filter((r) => r.city).map((r) => r.ext).join(',')})
    AND o.representing_city = 'Bend';
  IF v_repcity <> ${ROSTER.filter((r) => r.city).length} THEN
    RAISE EXCEPTION 'FAILED (f): representing_city=Bend on % offices, expected ${ROSTER.filter((r) => r.city).length}', v_repcity;
  END IF;

  -- (g)
  SELECT COUNT(*) INTO v_countydis FROM essentials.districts d
  WHERE d.geo_id = ${q(COUNTY_GEO)} AND d.district_type = 'COUNTY' AND d.state = 'or'
    AND d.government_id = ${govSel(COUNTY_GOV)};
  IF v_countydis <> 1 THEN
    RAISE EXCEPTION 'FAILED (g): Deschutes COUNTY district rows owned by the county gov=%, expected 1', v_countydis;
  END IF;

  RAISE NOTICE 'Post-verification PASSED: govs=4, offices 7/3/4/7/5=${ROSTER.length}, geofences=4, split=0, office_id nulls=0, representing_city=${ROSTER.filter((r) => r.city).length}, county district adopted';
END $$;


-- NOTE: the supabase_migrations.schema_migrations ledger entry is deliberately NOT written here.
-- This file is applied with psql over the Session pooler, whose role has no privileges on the
-- supabase_migrations schema; including the INSERT aborts the transaction and rolls back the whole
-- seed (observed 2026-07-24). Ledger registration for version '${MIG}' is done separately as the
-- postgres role:  INSERT INTO supabase_migrations.schema_migrations (version) VALUES ('${MIG}')
--                 ON CONFLICT (version) DO NOTHING;

COMMIT;
`;

const out = `${import.meta.dirname}/../migrations/${MIG}_bend_or_deep_seed_records.sql`;
writeFileSync(out, sql);
console.log(`wrote ${out}\n  officials: ${ROSTER.length}`);
console.log(`  city=${inCh(CH_CITY).length} comm=${inCh(CH_COMM).length} row=${inCh(CH_ROW).length} school=${inCh(CH_SCHOOL).length} park=${inCh(CH_PARK).length}`);
console.log(`  external_ids: ${extList(ROSTER)}`);
