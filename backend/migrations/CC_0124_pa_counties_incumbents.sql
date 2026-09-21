-- CC_0124_pa_counties_incumbents.sql
-- Knight Foundation program, wave PA-4 (occupancy half). Slot RESERVED from the allocator.
-- Applied immediately after CC_0123.
--
-- Seats all 20 offices: Philadelphia's 7 row officers and Centre County's 13.
-- external_id band -2744020 .. -2744001. No vacancies.
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
  (-2744001, 'Larry Krasner', 'Larry', 'Krasner'),
  (-2744002, 'Christy Brady', 'Christy', 'Brady'),
  (-2744003, 'Rochelle Bilal', 'Rochelle', 'Bilal'),
  (-2744004, 'John P. Sabatina', 'John', 'Sabatina'),
  (-2744005, 'Omar Sabir', 'Omar', 'Sabir'),
  (-2744006, 'Lisa M. Deeley', 'Lisa', 'Deeley'),
  (-2744007, 'Seth Bluestein', 'Seth', 'Bluestein'),
  (-2744008, 'Mark Higgins', 'Mark', 'Higgins'),
  (-2744009, 'Amber Concepcion', 'Amber', 'Concepcion'),
  (-2744010, 'Steven G. Dershem', 'Steven', 'Dershem'),
  (-2744011, 'Jason Moser', 'Jason', 'Moser'),
  (-2744012, 'Scott A. Sayers', 'Scott', 'Sayers'),
  (-2744013, 'Bernie Cantorna', 'Bernie', 'Cantorna'),
  (-2744014, 'Hope P. Miller', 'Hope', 'Miller'),
  (-2744015, 'Shelley Thompson', 'Shelley', 'Thompson'),
  (-2744016, 'Jeremy S. Breon', 'Jeremy', 'Breon'),
  (-2744017, 'Joseph L. Davidson', 'Joseph', 'Davidson'),
  (-2744018, 'Christine Millinder', 'Christine', 'Millinder'),
  (-2744019, 'Bryan Sampsel', 'Bryan', 'Sampsel'),
  (-2744020, 'Colleen Kennedy', 'Colleen', 'Kennedy');

INSERT INTO essentials.politicians (external_id, full_name, first_name, last_name, source)
SELECT n.external_id, n.full_name, n.first_name, n.last_name, 'Each Philadelphia row office read off its OWN site 2026-09-18 — phillyda.org, controller.phila.gov, phillysheriff.com, phila.gov/departments/register-of-wills, vote.phila.gov/about-us/commissioners; all seven re-verified by build-pa-counties-roster.mjs --verify (PA-4) (CC_0124, PA-4)'
FROM pa4_people n
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = n.external_id);

CREATE TEMP TABLE pa4_terms(ord int, external_id bigint, title text, chamber_name text, gov_geo_id text,
                            district_geo_id text, district_mtfcc text, source text) ON COMMIT DROP;
INSERT INTO pa4_terms VALUES
  (0, -2744001, 'District Attorney', 'City and County Elected Officials', '4260000', '42101', 'G4020', 'Each Philadelphia row office read off its OWN site 2026-09-18 — phillyda.org, controller.phila.gov, phillysheriff.com, phila.gov/departments/register-of-wills, vote.phila.gov/about-us/commissioners; all seven re-verified by build-pa-counties-roster.mjs --verify (PA-4)'),
  (1, -2744002, 'City Controller', 'City and County Elected Officials', '4260000', '42101', 'G4020', 'Each Philadelphia row office read off its OWN site 2026-09-18 — phillyda.org, controller.phila.gov, phillysheriff.com, phila.gov/departments/register-of-wills, vote.phila.gov/about-us/commissioners; all seven re-verified by build-pa-counties-roster.mjs --verify (PA-4)'),
  (2, -2744003, 'Sheriff', 'City and County Elected Officials', '4260000', '42101', 'G4020', 'Each Philadelphia row office read off its OWN site 2026-09-18 — phillyda.org, controller.phila.gov, phillysheriff.com, phila.gov/departments/register-of-wills, vote.phila.gov/about-us/commissioners; all seven re-verified by build-pa-counties-roster.mjs --verify (PA-4)'),
  (3, -2744004, 'Register of Wills', 'City and County Elected Officials', '4260000', '42101', 'G4020', 'Each Philadelphia row office read off its OWN site 2026-09-18 — phillyda.org, controller.phila.gov, phillysheriff.com, phila.gov/departments/register-of-wills, vote.phila.gov/about-us/commissioners; all seven re-verified by build-pa-counties-roster.mjs --verify (PA-4)'),
  (4, -2744005, 'City Commissioner', 'City and County Elected Officials', '4260000', '42101', 'G4020', 'Each Philadelphia row office read off its OWN site 2026-09-18 — phillyda.org, controller.phila.gov, phillysheriff.com, phila.gov/departments/register-of-wills, vote.phila.gov/about-us/commissioners; all seven re-verified by build-pa-counties-roster.mjs --verify (PA-4)'),
  (5, -2744006, 'City Commissioner', 'City and County Elected Officials', '4260000', '42101', 'G4020', 'Each Philadelphia row office read off its OWN site 2026-09-18 — phillyda.org, controller.phila.gov, phillysheriff.com, phila.gov/departments/register-of-wills, vote.phila.gov/about-us/commissioners; all seven re-verified by build-pa-counties-roster.mjs --verify (PA-4)'),
  (6, -2744007, 'City Commissioner', 'City and County Elected Officials', '4260000', '42101', 'G4020', 'Each Philadelphia row office read off its OWN site 2026-09-18 — phillyda.org, controller.phila.gov, phillysheriff.com, phila.gov/departments/register-of-wills, vote.phila.gov/about-us/commissioners; all seven re-verified by build-pa-counties-roster.mjs --verify (PA-4)'),
  (7, -2744008, 'County Commissioner', 'Board of County Commissioners', '42027', '42027', 'G4020', 'Centre County Elected Officials/Offices index, https://centrecountypa.gov/2007/Elected-OfficialsOffices, read 2026-09-18; all thirteen re-verified by build-pa-counties-roster.mjs --verify (PA-4)'),
  (8, -2744009, 'County Commissioner', 'Board of County Commissioners', '42027', '42027', 'G4020', 'Centre County Elected Officials/Offices index, https://centrecountypa.gov/2007/Elected-OfficialsOffices, read 2026-09-18; all thirteen re-verified by build-pa-counties-roster.mjs --verify (PA-4)'),
  (9, -2744010, 'County Commissioner', 'Board of County Commissioners', '42027', '42027', 'G4020', 'Centre County Elected Officials/Offices index, https://centrecountypa.gov/2007/Elected-OfficialsOffices, read 2026-09-18; all thirteen re-verified by build-pa-counties-roster.mjs --verify (PA-4)'),
  (10, -2744011, 'Controller', 'County Elected Officials', '42027', '42027', 'G4020', 'Centre County Elected Officials/Offices index, https://centrecountypa.gov/2007/Elected-OfficialsOffices, read 2026-09-18; all thirteen re-verified by build-pa-counties-roster.mjs --verify (PA-4)'),
  (11, -2744012, 'Coroner', 'County Elected Officials', '42027', '42027', 'G4020', 'Centre County Elected Officials/Offices index, https://centrecountypa.gov/2007/Elected-OfficialsOffices, read 2026-09-18; all thirteen re-verified by build-pa-counties-roster.mjs --verify (PA-4)'),
  (12, -2744013, 'District Attorney', 'County Elected Officials', '42027', '42027', 'G4020', 'Centre County Elected Officials/Offices index, https://centrecountypa.gov/2007/Elected-OfficialsOffices, read 2026-09-18; all thirteen re-verified by build-pa-counties-roster.mjs --verify (PA-4)'),
  (13, -2744014, 'Jury Commissioner', 'County Elected Officials', '42027', '42027', 'G4020', 'Centre County Elected Officials/Offices index, https://centrecountypa.gov/2007/Elected-OfficialsOffices, read 2026-09-18; all thirteen re-verified by build-pa-counties-roster.mjs --verify (PA-4)'),
  (14, -2744015, 'Jury Commissioner', 'County Elected Officials', '42027', '42027', 'G4020', 'Centre County Elected Officials/Offices index, https://centrecountypa.gov/2007/Elected-OfficialsOffices, read 2026-09-18; all thirteen re-verified by build-pa-counties-roster.mjs --verify (PA-4)'),
  (15, -2744016, 'Prothonotary and Clerk of Courts', 'County Elected Officials', '42027', '42027', 'G4020', 'Centre County Elected Officials/Offices index, https://centrecountypa.gov/2007/Elected-OfficialsOffices, read 2026-09-18; all thirteen re-verified by build-pa-counties-roster.mjs --verify (PA-4)'),
  (16, -2744017, 'Recorder of Deeds', 'County Elected Officials', '42027', '42027', 'G4020', 'Centre County Elected Officials/Offices index, https://centrecountypa.gov/2007/Elected-OfficialsOffices, read 2026-09-18; all thirteen re-verified by build-pa-counties-roster.mjs --verify (PA-4)'),
  (17, -2744018, 'Register of Wills and Clerk of the Orphans'' Court', 'County Elected Officials', '42027', '42027', 'G4020', 'Centre County Elected Officials/Offices index, https://centrecountypa.gov/2007/Elected-OfficialsOffices, read 2026-09-18; all thirteen re-verified by build-pa-counties-roster.mjs --verify (PA-4)'),
  (18, -2744019, 'Sheriff', 'County Elected Officials', '42027', '42027', 'G4020', 'Centre County Elected Officials/Offices index, https://centrecountypa.gov/2007/Elected-OfficialsOffices, read 2026-09-18; all thirteen re-verified by build-pa-counties-roster.mjs --verify (PA-4)'),
  (19, -2744020, 'Treasurer', 'County Elected Officials', '42027', '42027', 'G4020', 'Centre County Elected Officials/Offices index, https://centrecountypa.gov/2007/Elected-OfficialsOffices, read 2026-09-18; all thirteen re-verified by build-pa-counties-roster.mjs --verify (PA-4)');

WITH offices_numbered AS (
  SELECT o.id AS office_id, o.title, c.name AS chamber_name, g.geo_id AS gov_geo_id,
         d.geo_id AS district_geo_id, d.mtfcc AS district_mtfcc,
         row_number() OVER (PARTITION BY g.geo_id, c.name, o.title ORDER BY o.id) AS rn
  FROM essentials.offices o
  JOIN essentials.chambers c ON c.id = o.chamber_id
  JOIN essentials.governments g ON g.id = c.government_id
  JOIN essentials.districts d ON d.id = o.district_id
  WHERE g.state = 'PA' AND g.geo_id IN ('4260000','42027')
    AND c.name IN ('City and County Elected Officials', 'Board of County Commissioners', 'County Elected Officials')
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
  SELECT count(*) INTO v_people FROM essentials.politicians WHERE external_id BETWEEN -2744020 AND -2744001;
  IF v_people <> 20 THEN RAISE EXCEPTION 'PA-4 occupancy: expected 20 people in the band, got %', v_people; END IF;

  SELECT count(*) INTO v_off FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','42027')
     AND c.name IN ('City and County Elected Officials', 'Board of County Commissioners', 'County Elected Officials');
  IF v_off <> 20 THEN RAISE EXCEPTION 'PA-4 occupancy: expected 20 offices, got %', v_off; END IF;

  SELECT count(*) INTO v_terms FROM essentials.office_terms ot
   JOIN essentials.offices o ON o.id = ot.office_id
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','42027')
     AND c.name IN ('City and County Elected Officials', 'Board of County Commissioners', 'County Elected Officials');
  IF v_terms <> 20 THEN RAISE EXCEPTION 'PA-4 occupancy: expected 20 terms, got %', v_terms; END IF;

  -- 🔴 count och.politician_id, never count(*).
  SELECT count(och.politician_id) INTO v_seated FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','42027')
     AND c.name IN ('City and County Elected Officials', 'Board of County Commissioners', 'County Elected Officials');
  IF v_seated <> 20 THEN RAISE EXCEPTION 'PA-4 occupancy: expected 20 seated, got %', v_seated; END IF;

  SELECT count(*) INTO v_unfilled FROM essentials.offices o
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   LEFT JOIN essentials.office_terms ot ON ot.office_id = o.id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','42027')
     AND c.name IN ('City and County Elected Officials', 'Board of County Commissioners', 'County Elected Officials')
     AND ot.id IS NULL;
  IF v_unfilled <> 0 THEN RAISE EXCEPTION 'PA-4 occupancy: % office(s) got no term at all', v_unfilled; END IF;

  SELECT count(*) INTO v_ended FROM essentials.office_terms ot
   JOIN essentials.offices o ON o.id = ot.office_id
   JOIN essentials.chambers c ON c.id = o.chamber_id
   JOIN essentials.governments g ON g.id = c.government_id
   WHERE g.state = 'PA' AND g.geo_id IN ('4260000','42027')
     AND c.name IN ('City and County Elected Officials', 'Board of County Commissioners', 'County Elected Officials')
     AND ot.term_end IS NOT NULL;
  IF v_ended <> 0 THEN RAISE EXCEPTION 'PA-4 occupancy: % term(s) carry a term_end', v_ended; END IF;

  SELECT count(*) INTO v_fanout FROM (
    SELECT ot.politician_id FROM essentials.office_terms ot
    WHERE ot.politician_id IN (SELECT id FROM essentials.politicians WHERE external_id BETWEEN -2744020 AND -2744001)
    GROUP BY ot.politician_id HAVING count(*) > 1) x;
  IF v_fanout <> 0 THEN RAISE EXCEPTION 'PA-4 occupancy: % person(s) hold more than one seat', v_fanout; END IF;

  RAISE NOTICE 'PA-4 occupancy OK: 20 offices, 20 terms, 20 seated, 0 ended';
END $$;

COMMIT;
