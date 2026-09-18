#!/usr/bin/env node
/**
 * gen-pa-counties-migrations.mjs — Knight program, wave PA-4.
 *
 * Reads data/pa-counties-roster.json and emits:
 *
 *   migrations/CC_0123_pa_counties_structure.sql    1 government, 3 chambers, 20 offices, 0 districts
 *   migrations/CC_0124_pa_counties_incumbents.sql   20 people, 20 terms
 *
 * Both slots RESERVED from the allocator. Reads nothing from the database.
 */
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROSTER = path.join(HERE, '..', 'data', 'pa-counties-roster.json');
const MIGRATIONS = path.join(HERE, '..', 'migrations');
const BAND_FROM = -2744020;
const BAND_TO = -2744001;

const q = (s) => String(s).replace(/'/g, "''");
const roster = JSON.parse(fs.readFileSync(ROSTER, 'utf8'));
const phl = roster.jurisdictions.philadelphia;
const ctr = roster.jurisdictions.centre;

const SRC_PHL = 'Each Philadelphia row office read off its OWN site 2026-09-18 — phillyda.org, '
  + 'controller.phila.gov, phillysheriff.com, phila.gov/departments/register-of-wills, '
  + 'vote.phila.gov/about-us/commissioners; all seven re-verified by build-pa-counties-roster.mjs --verify (PA-4)';
const SRC_CTR = 'Centre County Elected Officials/Offices index, https://centrecountypa.gov/2007/Elected-OfficialsOffices, '
  + 'read 2026-09-18; all thirteen re-verified by build-pa-counties-roster.mjs --verify (PA-4)';

const seats = [
  ...phl.offices.map((o) => ({ ...o, juris: 'phl', gov_geo_id: '4260000', chamber: phl.chamber,
    district_geo_id: phl.district_geo_id, district_mtfcc: phl.district_mtfcc, src: SRC_PHL })),
  ...ctr.offices.map((o) => ({ ...o, juris: 'ctr', gov_geo_id: '42027',
    chamber: o.title === 'County Commissioner' ? ctr.chambers.board : ctr.chambers.officers,
    district_geo_id: ctr.district_geo_id, district_mtfcc: ctr.district_mtfcc, src: SRC_CTR })),
];
if (seats.length !== 20) throw new Error(`expected 20 seats, built ${seats.length}`);
if (BAND_TO - BAND_FROM + 1 < seats.length) throw new Error('external_id band too small');

let next = BAND_TO;
for (const s of seats) {
  s.external_id = next--;
  s.first_name = s.full_name.split(' ')[0];
  s.last_name = s.full_name.trim().split(' ').slice(-1)[0];
}

const phlCount = seats.filter((s) => s.juris === 'phl').length;
const ctrBoard = seats.filter((s) => s.juris === 'ctr' && s.title === 'County Commissioner').length;
const ctrOfficers = seats.filter((s) => s.juris === 'ctr' && s.title !== 'County Commissioner').length;

const structure = `-- CC_0123_pa_counties_structure.sql
-- Knight Foundation program, wave PA-4 (structure half). Slot RESERVED from the allocator.
--
-- Stage 4 for Pennsylvania, and the two halves of it look nothing alike.
--
-- 🔴 PHILADELPHIA HAS NO COUNTY COMMISSION, BECAUSE THE CITY COUNCIL IS IT. What a consolidated
-- city keeps is its separately elected ROW OFFICES (spec §3.2): District Attorney, City
-- Controller, Sheriff, Register of Wills and THREE City Commissioners — ${phlCount} seats, hung on the
-- SAME government row PA-3 created, exactly as Columbus and Macon-Bibb hang theirs. No second
-- government is invented for a county that is the city.
--
-- 🔴 CENTRE COUNTY IS AN ORDINARY COUNTY AND STILL MATCHES NO TEMPLATE. Read off its own page:
--   · a CONTROLLER, not three Auditors — Pennsylvania counties elect one or the other;
--   · a combined PROTHONOTARY AND CLERK OF COURTS, and a combined REGISTER OF WILLS AND CLERK OF
--     THE ORPHANS' COURT — two offices where a template would write four;
--   · 🔴 TWO JURY COMMISSIONERS. Act 2013-11 let Pennsylvania counties abolish that office and
--     many did. Centre did not, and nothing but the county's own page would have said so.
--   Three commissioners in their own chamber, ten officers in another: ${ctrBoard + ctrOfficers} seats.
--
-- 🔴 ELECTED JUDGES ARE IN SCOPE AND ARE NOT IN THIS MIGRATION. Centre County elects Court of
-- Common Pleas judges and six Magisterial District Judges; Philadelphia elects its judiciary too.
-- Under the NC-3 inclusion ruling they belong in the data — in the JUDGES WAVE that North
-- Carolina already owes. Deferring is a scheduling decision, recorded here, not a ruling that
-- they do not count.
--
-- 🟢 NO DISTRICT IS CREATED. Both countywide polygons already exist: Philadelphia County 42101
-- and Centre County 42027, both G4020. The migration ASSERTS them and fails if either is absent.
-- ⚠ Philadelphia's county polygon and its place polygon measure the same 142.422 sq mi, so the
-- row offices resolve for exactly the addresses the Mayor does. That is a property of a
-- consolidated city, and the probe after the apply checks it rather than assuming it.
--
-- Idempotent: every INSERT is NOT EXISTS-guarded. Ends with a post-verify gate.

BEGIN;

-- ─── 0. Pre-flight: the two countywide polygons and the city government ───────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.geofence_boundaries
   WHERE mtfcc = 'G4020' AND state = '42' AND geo_id IN ('42101','42027');
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'PA-4: expected the Philadelphia and Centre county polygons, found %', v_n;
  END IF;
  SELECT count(*) INTO v_n FROM essentials.districts
   WHERE lower(state) = 'pa' AND mtfcc = 'G4020' AND geo_id IN ('42101','42027');
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'PA-4: expected the two countywide DISTRICT rows, found %', v_n;
  END IF;
  SELECT count(*) INTO v_n FROM essentials.governments WHERE state = 'PA' AND geo_id = '4260000';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'PA-4: the City of Philadelphia government row is missing — run CC_0121 first';
  END IF;
END $$;

-- ─── 1. Centre County's government row ────────────────────────────────────────
INSERT INTO essentials.governments (name, type, state, geo_id)
SELECT '${q(ctr.government_name)}', 'County', 'PA', '42027'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE state = 'PA' AND geo_id = '42027');

-- ─── 2. Three chambers ────────────────────────────────────────────────────────
INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, '${q(phl.chamber)}', '${q(phl.chamber)}', ${phlCount}
FROM essentials.governments g
WHERE g.state = 'PA' AND g.geo_id = '4260000'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = '${q(phl.chamber)}');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, '${q(ctr.chambers.board)}', '${q(ctr.chambers.board)}', ${ctrBoard}
FROM essentials.governments g
WHERE g.state = 'PA' AND g.geo_id = '42027'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = '${q(ctr.chambers.board)}');

INSERT INTO essentials.chambers (government_id, name, name_formal, official_count)
SELECT g.id, '${q(ctr.chambers.officers)}', '${q(ctr.chambers.officers)}', ${ctrOfficers}
FROM essentials.governments g
WHERE g.state = 'PA' AND g.geo_id = '42027'
  AND NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.government_id = g.id AND c.name = '${q(ctr.chambers.officers)}');

-- ─── 3. The 20 offices ────────────────────────────────────────────────────────
-- ⚠ Three City Commissioners share one title on one district, and so do three County
-- Commissioners and two Jury Commissioners. The guard counts how many of that (title, district)
-- pair already exist, so a re-run adds none and a missing one is still added.
INSERT INTO essentials.offices (chamber_id, district_id, title, representing_state, seats, is_vacant, voting_powers)
SELECT c.id, d.id, v.title, 'PA', 1, false, 'full'
FROM (VALUES
${seats.map((s, i) => `  (${i}, '${q(s.title)}', '${q(s.chamber)}', '${s.gov_geo_id}', '${s.district_geo_id}', '${s.district_mtfcc}')`).join(',\n')}
) AS v(ord, title, chamber_name, gov_geo_id, district_geo_id, district_mtfcc)
JOIN essentials.governments g ON g.state = 'PA' AND g.geo_id = v.gov_geo_id
JOIN essentials.chambers c ON c.government_id = g.id AND c.name = v.chamber_name
JOIN essentials.districts d ON d.geo_id = v.district_geo_id AND d.mtfcc = v.district_mtfcc AND lower(d.state) = 'pa'
WHERE (
  SELECT count(*) FROM essentials.offices o WHERE o.chamber_id = c.id AND o.district_id = d.id AND o.title = v.title
) < (
  SELECT count(*) FROM (VALUES
${seats.map((s, i) => `    (${i}, '${q(s.title)}', '${q(s.chamber)}')`).join(',\n')}
  ) AS w(ord, title, chamber_name) WHERE w.title = v.title AND w.chamber_name = v.chamber_name
    AND w.ord <= v.ord
);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────
DO $$
DECLARE v_gov int; v_ch int; v_phl int; v_board int; v_off int; v_jury int; v_dist int; v_orphan int;
BEGIN
  SELECT count(*) INTO v_gov FROM essentials.governments WHERE state = 'PA' AND geo_id = '42027' AND type = 'County';
  IF v_gov <> 1 THEN RAISE EXCEPTION 'PA-4: expected 1 Centre County government row, got %', v_gov; END IF;

  SELECT count(*) INTO v_ch FROM essentials.chambers c JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','42027');
  IF v_ch <> 5 THEN RAISE EXCEPTION 'PA-4: expected 5 chambers across the city and Centre County, got %', v_ch; END IF;

  SELECT count(*) INTO v_phl FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id = '4260000' AND c.name = '${q(phl.chamber)}';
  IF v_phl <> ${phlCount} THEN RAISE EXCEPTION 'PA-4: expected ${phlCount} Philadelphia row offices, got %', v_phl; END IF;

  SELECT count(*) INTO v_board FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id = '42027' AND c.name = '${q(ctr.chambers.board)}';
  IF v_board <> ${ctrBoard} THEN RAISE EXCEPTION 'PA-4: expected ${ctrBoard} Centre County commissioners, got %', v_board; END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id = '42027' AND c.name = '${q(ctr.chambers.officers)}';
  IF v_off <> ${ctrOfficers} THEN RAISE EXCEPTION 'PA-4: expected ${ctrOfficers} Centre County row officers, got %', v_off; END IF;

  -- 🔴 THE OFFICE A TEMPLATE WOULD HAVE DROPPED. Centre kept its jury commissioners; if this
  -- count ever reads 0, someone has "tidied" the roster against a state-wide assumption.
  SELECT count(*) INTO v_jury FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id = '42027' AND o.title = 'Jury Commissioner';
  IF v_jury <> 2 THEN RAISE EXCEPTION 'PA-4: expected 2 Centre County jury commissioners, got %', v_jury; END IF;

  -- 🟢 NO NEW DISTRICT. Pennsylvania's countywide district count must be exactly what it was.
  SELECT count(*) INTO v_dist FROM essentials.districts WHERE lower(state) = 'pa' AND mtfcc = 'G4020';
  IF v_dist <> 67 THEN RAISE EXCEPTION 'PA-4: Pennsylvania should still have 67 county districts, has %', v_dist; END IF;

  SELECT count(*) INTO v_orphan FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   JOIN essentials.districts d ON d.id = o.district_id
   LEFT JOIN essentials.geofence_boundaries b ON b.geo_id = d.geo_id AND b.mtfcc = d.mtfcc
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','42027') AND b.id IS NULL;
  IF v_orphan <> 0 THEN
    RAISE EXCEPTION 'PA-4: % office(s) sit on a district with no polygon — unreachable by any address', v_orphan;
  END IF;

  RAISE NOTICE 'PA-4 structure OK: Centre County created, % Philadelphia row offices, % commissioners, % county officers, 0 new districts',
    v_phl, v_board, v_off;
END $$;

COMMIT;
`;

const occupancy = `-- CC_0124_pa_counties_incumbents.sql
-- Knight Foundation program, wave PA-4 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0123.
--
-- Seats all 20 offices: Philadelphia's ${phlCount} row officers and Centre County's ${ctrBoard + ctrOfficers}.
-- external_id band ${BAND_FROM} .. ${BAND_TO}. No vacancies.
--
-- 🟢 THE DUPLICATE-NAME GUARD STAYS ARMED FOR EVERY ROW, AND THAT IS A MEASUREMENT, NOT A HOPE.
-- The exact (first_name, last_name) pair matched NOTHING in production. A surname-only pass over
-- every row with a Pennsylvania connection returned four — Hope P. Miller against Brett R. Miller
-- and Nick Miller, Shelley Thompson against Glenn Thompson, Joseph L. Davidson against Nathan
-- Davidson — and every one is a different person with a different given name. So unlike PA-2 and
-- PA-3, nothing here needs the guard lifted.
--
-- 🔴 NO ARRIVAL DATE IS INVENTED. Neither publisher gives one: the Centre County index is a list
-- of names, and Philadelphia's row offices publish biographies without a swearing-in date — both
-- were read and searched before this was written. Every term is open-ended at start_precision
-- 'unknown', the GA-2 / IN-2 / MN-2 / PA-2 pattern. ▶ Owed, if it is ever wanted: the terms are
-- four years and the county's own election record would date them.
--
-- 🔴 PARTY IS NOT WRITTEN. It lives on races.primary_party.
--
-- Idempotent: people NOT EXISTS-guarded on external_id, terms on (office_id, politician_id).
-- Ends with a post-verify gate that counts och.politician_id, never count(*).

BEGIN;

CREATE TEMP TABLE pa4_people(external_id bigint, full_name text, first_name text, last_name text) ON COMMIT DROP;
INSERT INTO pa4_people VALUES
${seats.map((s) => `  (${s.external_id}, '${q(s.full_name)}', '${q(s.first_name)}', '${q(s.last_name)}')`).join(',\n')};

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, '${q(SRC_PHL)} (CC_0124, PA-4)'
FROM pa4_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

CREATE TEMP TABLE pa4_terms(ord int, external_id bigint, title text, chamber_name text, gov_geo_id text,
                            district_geo_id text, district_mtfcc text, source text) ON COMMIT DROP;
INSERT INTO pa4_terms VALUES
${seats.map((s, i) => `  (${i}, ${s.external_id}, '${q(s.title)}', '${q(s.chamber)}', '${s.gov_geo_id}', '${s.district_geo_id}', '${s.district_mtfcc}', '${q(s.src)}')`).join(',\n')};

WITH offices_numbered AS (
  SELECT o.id AS office_id, o.title, c.name AS chamber_name, g.geo_id AS gov_geo_id,
         d.geo_id AS district_geo_id, d.mtfcc AS district_mtfcc,
         row_number() OVER (PARTITION BY g.geo_id, c.name, o.title ORDER BY o.id) AS rn
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE g.state = 'PA' AND g.geo_id IN ('4260000','42027')
    AND c.name IN ('${q(phl.chamber)}', '${q(ctr.chambers.board)}', '${q(ctr.chambers.officers)}')
), terms_numbered AS (
  SELECT t.*, row_number() OVER (PARTITION BY t.gov_geo_id, t.chamber_name, t.title ORDER BY t.ord) AS rn
  FROM pa4_terms t
)
INSERT INTO essentials.office_terms (office_id, politician_id, term_start, term_end, start_precision, how_started, source)
SELECT o.office_id, p.id, NULL, NULL, 'unknown', 'unknown', t.source || ' (CC_0124, PA-4)'
FROM terms_numbered t
JOIN offices_numbered o
  ON o.gov_geo_id = t.gov_geo_id AND o.chamber_name = t.chamber_name AND o.title = t.title AND o.rn = t.rn
JOIN essentials.politicians p ON p.external_id = t.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.office_terms ot WHERE ot.office_id = o.office_id AND ot.politician_id = p.id);

-- ─── Post-verify gate ─────────────────────────────────────────────────────────
DO $$
DECLARE v_people int; v_off int; v_terms int; v_seated int; v_ended int; v_fanout int; v_unfilled int;
BEGIN
  SELECT count(*) INTO v_people FROM essentials.politicians WHERE external_id BETWEEN ${BAND_FROM} AND ${BAND_TO};
  IF v_people <> 20 THEN RAISE EXCEPTION 'PA-4 occupancy: expected 20 people in the band, got %', v_people; END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','42027')
     AND c.name IN ('${q(phl.chamber)}', '${q(ctr.chambers.board)}', '${q(ctr.chambers.officers)}');
  IF v_off <> 20 THEN RAISE EXCEPTION 'PA-4 occupancy: expected 20 offices, got %', v_off; END IF;

  SELECT count(*) INTO v_terms FROM essentials.office_terms ot
   JOIN essentials.offices o ON o.id = ot.office_id
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','42027')
     AND c.name IN ('${q(phl.chamber)}', '${q(ctr.chambers.board)}', '${q(ctr.chambers.officers)}');
  IF v_terms <> 20 THEN RAISE EXCEPTION 'PA-4 occupancy: expected 20 terms, got %', v_terms; END IF;

  -- 🔴 count och.politician_id, never count(*).
  SELECT count(och.politician_id) INTO v_seated FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','42027')
     AND c.name IN ('${q(phl.chamber)}', '${q(ctr.chambers.board)}', '${q(ctr.chambers.officers)}');
  IF v_seated <> 20 THEN RAISE EXCEPTION 'PA-4 occupancy: expected 20 seated, got %', v_seated; END IF;

  SELECT count(*) INTO v_unfilled FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   LEFT JOIN essentials.office_terms ot ON ot.office_id = o.id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','42027')
     AND c.name IN ('${q(phl.chamber)}', '${q(ctr.chambers.board)}', '${q(ctr.chambers.officers)}')
     AND ot.id IS NULL;
  IF v_unfilled <> 0 THEN RAISE EXCEPTION 'PA-4 occupancy: % office(s) got no term at all', v_unfilled; END IF;

  SELECT count(*) INTO v_ended FROM essentials.office_terms ot
   JOIN essentials.offices o ON o.id = ot.office_id
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','42027')
     AND c.name IN ('${q(phl.chamber)}', '${q(ctr.chambers.board)}', '${q(ctr.chambers.officers)}')
     AND ot.term_end IS NOT NULL;
  IF v_ended <> 0 THEN RAISE EXCEPTION 'PA-4 occupancy: % term(s) carry a term_end', v_ended; END IF;

  SELECT count(*) INTO v_fanout FROM (
    SELECT ot.politician_id FROM essentials.office_terms ot
    WHERE ot.politician_id IN (SELECT id FROM essentials.politicians WHERE external_id BETWEEN ${BAND_FROM} AND ${BAND_TO})
    GROUP BY ot.politician_id HAVING count(*) > 1) x;
  IF v_fanout <> 0 THEN RAISE EXCEPTION 'PA-4 occupancy: % person(s) hold more than one seat', v_fanout; END IF;

  RAISE NOTICE 'PA-4 occupancy OK: 20 offices, 20 terms, 20 seated, 0 ended';
END $$;

COMMIT;
`;

fs.writeFileSync(path.join(MIGRATIONS, 'CC_0123_pa_counties_structure.sql'), structure);
fs.writeFileSync(path.join(MIGRATIONS, 'CC_0124_pa_counties_incumbents.sql'), occupancy);
console.log(`CC_0123: 1 government, 3 chambers, ${seats.length} offices, 0 districts`);
console.log(`CC_0124: ${seats.length} people (guard armed for every row), 20 terms at 'unknown' precision`);
