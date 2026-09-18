#!/usr/bin/env node
/**
 * gen-pa-cities-migrations.mjs — Knight program, wave PA-3.
 *
 * Reads data/pa-cities-roster.json and emits:
 *
 *   migrations/CC_0121_pa_cities_structure.sql     2 governments, 4 chambers, 12 districts, 26 offices
 *   migrations/CC_0122_pa_cities_incumbents.sql    26 people, 26 terms
 *
 * Both slots RESERVED from the allocator. Reads nothing from the database.
 */
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROSTER = path.join(HERE, '..', 'data', 'pa-cities-roster.json');
const MIGRATIONS = path.join(HERE, '..', 'migrations');

const BAND_FROM = -2743026;
const BAND_TO = -2743001;
const MTFCC_DISTRICTS = 'X0058';

const SRC_PHL = 'Philadelphia City Council, https://phlcouncil.com/council-members/ (the CURRENT section only — '
  + 'the same page lists past members in the identical format); Mayor from https://www.phila.gov/departments/mayor/; '
  + 'all 17 council members change-checked against their own member page 2026-09-18 (PA-3)';
const SRC_SC = 'Borough of State College, https://statecollegepa.us/603/Borough-Council-Mayor, read 2026-09-18; '
  + 'the borough publishes NO per-member page, so the change-check is the certified Centre County 2025 municipal '
  + 'result (the three seats up were won by the three sitting incumbents, unopposed) plus the documented '
  + 'February 2026 appointment (PA-3)';

/** Documented arrivals. Everything else is open-ended at 'unknown' — see the migration header. */
const DATED = {
  'PHL|Mayor': { start: '2024-01-01', precision: 'day', how: 'elected',
    note: 'Cherelle L. Parker took the oath privately on Monday 2024-01-01 and was publicly sworn in as the city\'\'s 100th mayor on 2024-01-02. The tenure starts at the oath; the ceremony is a ceremony.' },
  'PHL|D6': { start: '2022-06-10', precision: 'day', how: 'elected',
    note: 'Michael Driscoll won the May 2022 special election for the 6th District, resigned his PA House seat and, in his own page\'\'s words, "was sworn in as a member of Philadelphia City Council on June 10, 2022".' },
  'PHL|D9': { start: '2022-01-01', precision: 'year', how: 'elected',
    note: 'Anthony Phillips won a 2022 SPECIAL election to complete the term Cherelle Parker resigned, and was returned in 2023. His page gives the year and no date, so the year is what is written.' },
  'SC|Susan Venegoni': { start: '2026-02-01', precision: 'month', how: 'appointed',
    note: 'Council APPOINTED Susan Venegoni on Monday 2026-02-09 to serve the remainder of Josh Portney\'\'s term (to 2027-12-31). Her oath is reported only as "as early as Tuesday", so the day is not known and month precision is the honest floor. ▶ A day is available from the borough\'\'s own minutes if it is ever wanted.' },
};

const q = (s) => String(s).replace(/'/g, "''");
const roster = JSON.parse(fs.readFileSync(ROSTER, 'utf8'));
const phl = roster.jurisdictions.philadelphia;
const sc = roster.jurisdictions.state_college;

const seats = [];
seats.push({ key: 'PHL|Mayor', juris: 'phl', full_name: phl.mayor.full_name, chamber: 'Office of the Mayor',
  title: 'Mayor', district_geo_id: phl.place_geo_id, district_mtfcc: 'G4110' });
for (const m of phl.council.filter((x) => x.seat_kind === 'district').sort((a, b) => a.district - b.district)) {
  seats.push({ key: `PHL|D${m.district}`, juris: 'phl', full_name: m.full_name, chamber: 'Philadelphia City Council',
    title: `Councilmember, District ${m.district}`, district_geo_id: `phl-council-district-${m.district}`,
    district_mtfcc: MTFCC_DISTRICTS });
}
for (const m of phl.council.filter((x) => x.seat_kind === 'at_large')) {
  seats.push({ key: `PHL|AL|${m.full_name}`, juris: 'phl', full_name: m.full_name, chamber: 'Philadelphia City Council',
    title: 'Councilmember, At Large', district_geo_id: phl.place_geo_id, district_mtfcc: 'G4110' });
}
const scMayor = sc.members.find((m) => m.seat_kind === 'mayor');
seats.push({ key: 'SC|Mayor', juris: 'sc', full_name: scMayor.full_name, chamber: 'Office of the Mayor',
  title: 'Mayor', district_geo_id: sc.place_geo_id, district_mtfcc: 'G4110' });
for (const m of sc.members.filter((x) => x.seat_kind === 'at_large')) {
  seats.push({ key: `SC|${m.full_name}`, juris: 'sc', full_name: m.full_name, chamber: 'State College Borough Council',
    title: 'Council Member, At Large', district_geo_id: sc.place_geo_id, district_mtfcc: 'G4110' });
}
if (seats.length !== 26) throw new Error(`expected 26 seats, built ${seats.length}`);

/** 🔴 A name that an active row already holds, READ before it was classified. */
const NAMESAKES = {
  'PHL|D9': 'The existing Anthony W. Phillips (external_id -5507073) is a CANDIDATE FOR THE WISCONSIN ASSEMBLY, district 56, election 2026-08-11. The roster Anthony Phillips is the Councilmember for Philadelphia\'\'s 9th District. Different state, different office, different person.',
};

let next = BAND_TO;
for (const s of seats) {
  s.external_id = next--;
  s.first_name = s.full_name.split(' ')[0];
  s.last_name = s.full_name.replace(/,\s*(Jr|Sr|II|III)\.?$/, '').trim().split(' ').slice(-1)[0];
  const dateKey = DATED[s.key] ? s.key : DATED[`SC|${s.full_name}`] ? `SC|${s.full_name}` : null;
  s.dated = dateKey ? DATED[dateKey] : null;
}
// The band is INCLUSIVE at both ends; `next` legitimately lands one past it after the last
// assignment, so the size is checked rather than the cursor.
if (BAND_TO - BAND_FROM + 1 < seats.length) {
  throw new Error(`external_id band holds ${BAND_TO - BAND_FROM + 1} ids, ${seats.length} needed`);
}
const armed = seats.filter((s) => !NAMESAKES[s.key]);
const lifted = seats.filter((s) => NAMESAKES[s.key]);

const GOVS = [
  { code: 'phl', name: 'City of Philadelphia, Pennsylvania, US', type: 'City', geo_id: '4260000',
    chambers: [{ name: 'Philadelphia City Council', count: 17 }, { name: 'Office of the Mayor', count: 1 }] },
  { code: 'sc', name: 'Borough of State College, Pennsylvania, US', type: 'City', geo_id: '4273808',
    chambers: [{ name: 'State College Borough Council', count: 7 }, { name: 'Office of the Mayor', count: 1 }] },
];

// ── CC_0121 structure ────────────────────────────────────────────────────────

const structure = `-- CC_0121_pa_cities_structure.sql
-- Knight Foundation program, wave PA-3 (structure half). Slot RESERVED from the allocator.
--
-- Seats nobody. Creates the two city governments, their four chambers, the twelve districts they
-- need and the 26 offices. CC_0122 puts people in them, and the two are applied back to back.
--
-- 🔴 THE TWO JURISDICTIONS ARE NOT MADE UNIFORM, AND THE DIFFERENCE IS THE POINT:
--   Philadelphia — Mayor + a Council of SEVENTEEN: 10 district seats on the ten council-district
--   polygons, and 7 AT-LARGE seats which are UNNUMBERED and sit on the citywide polygon (the
--   Fort Wayne and Duluth convention).
--   State College — Mayor + SEVEN council members, "elected at large" in the words of the Home
--   Rule Charter quoted on the borough's own page. NO ward layer exists and none is invented:
--   all eight offices sit on the borough's citywide polygon. Tallahassee and Boulder again.
--
-- 🔴 PHILADELPHIA'S ROW OFFICERS ARE NOT HERE. District Attorney, City Controller, Sheriff,
-- Register of Wills and the three City Commissioners are the county officers a consolidated
-- city keeps, and they belong to stage 4 (spec §3.2). Its elected JUDGES belong to the judges
-- wave, as North Carolina's do.
--
-- 🔴 THE TEN DISTRICT POLYGONS MUST ALREADY EXIST. scripts/load-phl-council-boundaries.mjs loads
-- them as ${MTFCC_DISTRICTS}; this migration ABORTS if they are absent, because an office on a district with
-- no polygon is unreachable by any address and NOTHING ERRORS.
--
-- 🔴 WHICH ten polygons was proved, not read off a service name. The city publishes FIVE
-- council-district layers and all five have ten features numbered 1-10. A city-wide spread of
-- addresses cannot separate them — all 54 Free Library branches agree with the superseded 2016
-- map as well. Only the ~4% of addresses the 2022 remap moved can: on those the loaded layer
-- matches the City's own address service 6/6 and the 2016 layer 0/6.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 0. Pre-flight: the council-district polygons ─────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries WHERE mtfcc = '${MTFCC_DISTRICTS}' AND state = '42';
  IF v_n <> 10 THEN
    RAISE EXCEPTION 'PA-3 structure: expected 10 ${MTFCC_DISTRICTS} council-district boundaries, found % — run scripts/load-phl-council-boundaries.mjs first', v_n;
  END IF;
  -- The two TIGER place polygons carry every citywide office in this wave.
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries
   WHERE mtfcc = 'G4110' AND state = '42' AND geo_id IN ('4260000','4273808');
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'PA-3 structure: expected the Philadelphia and State College place polygons, found %', v_n;
  END IF;
END $$;

-- ─── 1. The two governments ───────────────────────────────────────────────────
${GOVS.map((g) => `INSERT INTO essentials.governments (name, type, state, geo_id)
SELECT '${q(g.name)}', '${g.type}', 'PA', '${g.geo_id}'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE geo_id = '${g.geo_id}' AND state = 'PA');`).join('\n\n')}

-- ─── 2. The four chambers ─────────────────────────────────────────────────────
${GOVS.flatMap((g) => g.chambers.map((c) => `INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT gov.id, '${q(c.name)}', '${q(c.name)}', ${c.count}
FROM essentials.governments gov
WHERE gov.geo_id = '${g.geo_id}' AND gov.state = 'PA'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = gov.id AND c.name = '${q(c.name)}');`)).join('\n\n')}

-- ─── 3. The twelve districts ──────────────────────────────────────────────────
-- Ten council districts on the loaded polygons, plus one citywide district per jurisdiction.
-- 🔴 (geo_id, mtfcc) IS THE KEY. '42101' is Philadelphia County AND State House District 101,
-- and all 67 PA counties collide with a House district this way. Nothing here matches on a
-- number, a name or a geo_id alone.
INSERT INTO essentials.districts (geo_id, mtfcc, district_type, label, state, government_id)
SELECT v.geo_id, v.mtfcc, 'LOCAL', v.label, 'pa', gov.id
FROM (VALUES
${Array.from({ length: 10 }, (_, i) => `  ('phl-council-district-${i + 1}', '${MTFCC_DISTRICTS}', 'Philadelphia City Council District ${i + 1}', '4260000')`).join(',\n')},
  ('4260000', 'G4110', 'Philadelphia Citywide', '4260000'),
  ('4273808', 'G4110', 'State College Borough Citywide', '4273808')
) AS v(geo_id, mtfcc, label, gov_geo_id)
JOIN essentials.governments gov ON gov.geo_id = v.gov_geo_id AND gov.state = 'PA'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.districts d WHERE d.geo_id = v.geo_id AND d.mtfcc = v.mtfcc);

-- ─── 4. The 26 offices ────────────────────────────────────────────────────────
-- ⚠ The at-large seats are UNNUMBERED: seven Philadelphia offices share the title
-- 'Councilmember, At Large' and seven State College offices share 'Council Member, At Large',
-- all on their own citywide district. The count is what distinguishes them, not a seat number
-- the city does not use.
INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, v.title, 'PA', 1, false, 'full'
FROM (VALUES
${seats.map((s, i) => `  (${i}, '${q(s.title)}', '${q(s.district_geo_id)}', '${s.district_mtfcc}', '${q(s.chamber)}', '${GOVS.find((g) => g.code === s.juris).geo_id}')`).join(',\n')}
) AS v(ord, title, district_geo_id, district_mtfcc, chamber_name, gov_geo_id)
JOIN essentials.governments gov ON gov.geo_id = v.gov_geo_id AND gov.state = 'PA'
JOIN essentials.chambers c ON c.government_id = gov.id AND c.name = v.chamber_name
JOIN essentials.districts d ON d.geo_id = v.district_geo_id AND d.mtfcc = v.district_mtfcc AND lower(d.state) = 'pa'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
  WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = v.title
  GROUP BY o.chamber_id, o.district_id, o.title
  HAVING count(*) >= (SELECT count(*) FROM (VALUES
${seats.map((s, i) => `    (${i}, '${q(s.title)}', '${q(s.district_geo_id)}')`).join(',\n')}
  ) AS w(ord, title, district_geo_id) WHERE w.title = v.title AND w.district_geo_id = v.district_geo_id));

-- ─── Post-verify gate ─────────────────────────────────────────────────────────
DO $$
DECLARE
  v_gov int; v_ch int; v_dist int; v_off int; v_phl int; v_sc int; v_al int; v_orphan int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments
   WHERE state = 'PA' AND geo_id IN ('4260000','4273808');
  IF v_gov <> 2 THEN RAISE EXCEPTION 'PA-3 structure: expected 2 city governments, got %', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','4273808');
  IF v_ch <> 4 THEN RAISE EXCEPTION 'PA-3 structure: expected 4 chambers, got %', v_ch; END IF;

  SELECT count(*) INTO v_dist FROM essentials.districts
   WHERE lower(state) = 'pa' AND (mtfcc = '${MTFCC_DISTRICTS}' OR (mtfcc = 'G4110' AND geo_id IN ('4260000','4273808')));
  IF v_dist <> 12 THEN RAISE EXCEPTION 'PA-3 structure: expected 12 districts, got %', v_dist; END IF;

  SELECT count(*) INTO v_phl FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id = '4260000' AND g.state = 'PA';
  SELECT count(*) INTO v_sc FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.geo_id = '4273808' AND g.state = 'PA';
  IF v_phl <> 18 THEN RAISE EXCEPTION 'PA-3 structure: expected 18 Philadelphia offices (Mayor + 17), got %', v_phl; END IF;
  IF v_sc <> 8 THEN RAISE EXCEPTION 'PA-3 structure: expected 8 State College offices (Mayor + 7), got %', v_sc; END IF;
  v_off := v_phl + v_sc;

  -- 🔴 EXACTLY SEVEN at-large seats in Philadelphia and SEVEN in State College. An unnumbered
  -- seat is the one shape where a re-run can quietly add an extra office, so it is counted.
  SELECT count(*) INTO v_al FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id = '4260000' AND o.title = 'Councilmember, At Large';
  IF v_al <> 7 THEN RAISE EXCEPTION 'PA-3 structure: expected 7 Philadelphia at-large offices, got %', v_al; END IF;
  SELECT count(*) INTO v_al FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id = '4273808' AND o.title = 'Council Member, At Large';
  IF v_al <> 7 THEN RAISE EXCEPTION 'PA-3 structure: expected 7 State College at-large offices, got %', v_al; END IF;

  -- 🔴 NO OFFICE ON A DISTRICT WITH NO POLYGON. That is the one failure CI cannot catch: the
  -- office exists, the official is invisible to every address, and nothing errors.
  SELECT count(*) INTO v_orphan FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   JOIN essentials.districts d ON d.id = o.district_id
   LEFT JOIN essentials.geofence_boundaries b ON b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','4273808') AND b.id IS NULL;
  IF v_orphan <> 0 THEN
    RAISE EXCEPTION 'PA-3 structure: % office(s) sit on a district with no polygon — unreachable by any address', v_orphan;
  END IF;

  RAISE NOTICE 'PA-3 structure OK: 2 governments, 4 chambers, 12 districts, % offices (PHL 18 + SC 8)', v_off;
END $$;

COMMIT;
`;

// ── CC_0122 occupancy ────────────────────────────────────────────────────────

const peopleRow = (s) => `  (${s.external_id}, '${q(s.full_name)}', '${q(s.first_name)}', '${q(s.last_name)}')`;
const termRow = (s, i) => {
  const d = s.dated;
  return `  (${i}, ${s.external_id}::bigint, '${q(s.title)}', '${q(s.district_geo_id)}', '${s.district_mtfcc}', `
    + `'${GOVS.find((g) => g.code === s.juris).geo_id}', ${d ? `'${d.start}'::date` : 'NULL::date'}, `
    + `'${d ? d.precision : 'unknown'}', '${d ? d.how : 'unknown'}', '${s.juris === 'phl' ? q(SRC_PHL) : q(SRC_SC)}')`;
};

const datedNotes = seats.filter((s) => s.dated)
  .map((s) => `--   ${s.full_name} (${s.title}) — ${s.dated.start} at ${s.dated.precision} precision, how_started '${s.dated.how}'.\n--     ${s.dated.note}`)
  .join('\n');
const namesakeNotes = Object.entries(NAMESAKES).map(([k, why]) => `--   ${k}: ${why}`).join('\n');

const occupancy = `-- CC_0122_pa_cities_incumbents.sql
-- Knight Foundation program, wave PA-3 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0121.
--
-- Seats all 26 offices: Philadelphia 18 (Mayor + 10 district + 7 at-large) and State College 8
-- (Mayor + 7 at-large). ${armed.length} people created with the duplicate-name guard ARMED, ${lifted.length} with it lifted,
-- 0 reused. external_id band ${BAND_FROM} .. ${BAND_TO}. NO vacancies — every seat is filled today.
--
-- 🟢 FOUR ARRIVALS ARE DOCUMENTED AND ARE WRITTEN AT THE PRECISION THE SOURCE SUPPORTS:
${datedNotes}
--
-- 🔴 THE OTHER 22 ARE OPEN-ENDED AT 'unknown', AND NO CONSTITUTIONAL DATE IS INVENTED. Members
-- elected in 2023 took office on 2024-01-01 — but writing that for everyone would be positively
-- WRONG for the incumbents among them, whose occupancy is CONTINUOUS from an earlier swearing-in
-- (CO-3's rule), and for the two who arrived at 2022 special elections. "First elected" is not a
-- term start and fails in both directions.
--
-- 🔴 A NAME THAT AN ACTIVE ROW ALREADY HOLDS, READ BEFORE IT WAS CLASSIFIED:
${namesakeNotes}
-- ⚠ The guard is lifted for that row ALONE. The other ${armed.length} are inserted with it ARMED, so a namesake
-- nobody anticipated still stops this migration.
-- ⚠ A surname-only pass over every production row with a Pennsylvania connection returned eight
-- more matches — Kendra Brooks against Michele Brooks (PA SD-50) and Bob Brooks, Curtis Jones Jr.
-- against Tom and Mike Jones, Jeffery Young Jr. against Regina G. Young (PA HD-185) and Marty
-- Young, Cherelle L. Parker against Darisha K. Parker (PA HD-198), John Hayes against James
-- Hayes. Every one is a different person, and three of them are rows THIS PROGRAM seated a few
-- hours earlier in PA-2. A shared surname is never the answer on its own.
--
-- Idempotent: people NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).
-- Ends with a post-verify gate that counts och.politician_id, never count(*).

BEGIN;

CREATE TEMP TABLE pa3_people(external_id bigint, full_name text, first_name text, last_name text) ON COMMIT DROP;
INSERT INTO pa3_people(external_id, full_name, first_name, last_name) VALUES
${armed.map(peopleRow).join(',\n')};

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, '${q(SRC_PHL)} (CC_0122, PA-3)'
FROM pa3_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

SET LOCAL essentials.allow_duplicate_name = 'on';

CREATE TEMP TABLE pa3_namesakes(external_id bigint, full_name text, first_name text, last_name text) ON COMMIT DROP;
INSERT INTO pa3_namesakes(external_id, full_name, first_name, last_name) VALUES
${lifted.map(peopleRow).join(',\n')};

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, '${q(SRC_PHL)} (CC_0122, PA-3)'
FROM pa3_namesakes n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

SET LOCAL essentials.allow_duplicate_name = 'off';

-- ─── 26 terms ─────────────────────────────────────────────────────────────────
-- ⚠ The at-large seats are interchangeable: seven offices share one title on one district. Each
-- person is matched to the Nth such office by a deterministic row number, so a re-run pairs the
-- same person with the same office rather than shuffling them.
CREATE TEMP TABLE pa3_terms(ord int, external_id bigint, title text, district_geo_id text, district_mtfcc text,
                            gov_geo_id text, term_start date, start_precision text, how_started text, source text)
  ON COMMIT DROP;
INSERT INTO pa3_terms VALUES
${seats.map(termRow).join(',\n')};

WITH offices_numbered AS (
  SELECT o.id AS office_id, o.title, d.geo_id AS district_geo_id, d.mtfcc AS district_mtfcc,
         g.geo_id AS gov_geo_id,
         row_number() OVER (PARTITION BY g.geo_id, o.title, d.geo_id, d.mtfcc ORDER BY o.id) AS rn
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE g.state = 'PA' AND g.geo_id IN ('4260000','4273808')
), terms_numbered AS (
  SELECT t.*, row_number() OVER (PARTITION BY t.gov_geo_id, t.title, t.district_geo_id, t.district_mtfcc ORDER BY t.ord) AS rn
  FROM pa3_terms t
)
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.office_id, p.id, t.term_start, NULL, t.start_precision, t.how_started, t.source || ' (CC_0122, PA-3)'
FROM terms_numbered t
JOIN offices_numbered o
  ON o.gov_geo_id = t.gov_geo_id AND o.title = t.title
 AND o.district_geo_id = t.district_geo_id AND o.district_mtfcc = t.district_mtfcc AND o.rn = t.rn
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.office_id AND ot.politician_id = p.id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────
DO $$
DECLARE v_people int; v_off int; v_terms int; v_seated int; v_dated int; v_ended int; v_fanout int; v_unfilled int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians WHERE external_id BETWEEN ${BAND_FROM} AND ${BAND_TO};
  IF v_people <> 26 THEN RAISE EXCEPTION 'PA-3 occupancy: expected 26 people in the band, got %', v_people; END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','4273808');
  IF v_off <> 26 THEN RAISE EXCEPTION 'PA-3 occupancy: expected 26 offices, got %', v_off; END IF;

  SELECT count(*) INTO v_terms FROM essentials.office_terms ot
   JOIN essentials.offices o ON o.id = ot.office_id
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','4273808');
  IF v_terms <> 26 THEN RAISE EXCEPTION 'PA-3 occupancy: expected 26 terms, got %', v_terms; END IF;

  -- 🔴 COUNT och.politician_id, NEVER count(*) — office_current_holder LEFT JOINs from offices.
  SELECT count(och.politician_id) INTO v_seated FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','4273808');
  IF v_seated <> 26 THEN RAISE EXCEPTION 'PA-3 occupancy: expected 26 seated offices, got %', v_seated; END IF;

  SELECT count(*) INTO v_unfilled FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   LEFT JOIN essentials.office_terms ot ON ot.office_id = o.id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','4273808') AND ot.id IS NULL;
  IF v_unfilled <> 0 THEN RAISE EXCEPTION 'PA-3 occupancy: % office(s) got no term at all', v_unfilled; END IF;

  SELECT count(*) INTO v_dated FROM essentials.office_terms ot
   JOIN essentials.offices o ON o.id = ot.office_id
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','4273808') AND ot.term_start IS NOT NULL;
  IF v_dated <> ${seats.filter((s) => s.dated).length} THEN
    RAISE EXCEPTION 'PA-3 occupancy: expected ${seats.filter((s) => s.dated).length} dated terms, got %', v_dated;
  END IF;

  SELECT count(*) INTO v_ended FROM essentials.office_terms ot
   JOIN essentials.offices o ON o.id = ot.office_id
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','4273808') AND ot.term_end IS NOT NULL;
  IF v_ended <> 0 THEN RAISE EXCEPTION 'PA-3 occupancy: % term(s) carry a term_end', v_ended; END IF;

  SELECT count(*) INTO v_fanout FROM (
    SELECT ot.politician_id FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    WHERE g.state = 'PA' AND g.geo_id IN ('4260000','4273808')
    GROUP BY ot.politician_id HAVING count(*) > 1) x;
  IF v_fanout <> 0 THEN RAISE EXCEPTION 'PA-3 occupancy: % person(s) hold two city seats', v_fanout; END IF;

  RAISE NOTICE 'PA-3 occupancy OK: 26 offices, 26 terms, 26 seated, % dated, 0 ended', v_dated;
END $$;

COMMIT;
`;

fs.writeFileSync(path.join(MIGRATIONS, 'CC_0121_pa_cities_structure.sql'), structure);
fs.writeFileSync(path.join(MIGRATIONS, 'CC_0122_pa_cities_incumbents.sql'), occupancy);
console.log(`CC_0121: 2 governments, 4 chambers, 12 districts, ${seats.length} offices`);
console.log(`CC_0122: ${armed.length} guard-armed + ${lifted.length} guard-lifted = ${seats.length} people, ${seats.filter((s) => s.dated).length} dated terms`);
