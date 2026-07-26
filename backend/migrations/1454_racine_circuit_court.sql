-- 1433_racine_circuit_court.sql
-- Racine County Circuit Court: 1 chamber, 10 judges, Branches 1-10. STRUCTURAL. Idempotent.
--
-- SOURCE: racinecounty.gov/departments/clerk-of-circuit-court/info-resources/court-information/
--   court-officials, read 2026-07-25 via browser (the host 403s plain fetches).
--
-- NO NEW GEOMETRY NEEDED. essentialsService already pairs `gb.mtfcc='G4020'` with
--   `d.district_type IN ('COUNTY','JUDICIAL')`, so a JUDICIAL district on Racine County's
--   existing county polygon (geo_id '55101') routes these judges to every county address.
--   districts.state stays lowercase 'wi', matching the COUNTY/LOCAL tier convention.
--
-- SCOPE — this migration seeds ONLY the circuit court, deliberately. Wisconsin judicial terms
--   begin AUGUST 1, so the two other judicial bodies covering Racine County have winners who
--   are NOT YET SEATED as of 2026-07-25:
--     Wisconsin Supreme Court        — Chris Taylor beat Maria Lazar 905,157-600,044 on
--                                      2026-04-07 (10-year term), flipping the court 4-3 to
--                                      5-2. Sworn in 2026-08-01.
--     Court of Appeals District II   — Anthony LoCoco won unopposed 2026-04-07 for an open
--                                      seat. Term begins 2026-08-01. District II covers Racine.
--   Seeding either today would publish a judge who does not hold office until Saturday;
--   seeding their predecessors would go stale on Saturday. All 10 circuit judges below ARE
--   sitting today, so this tier has no such problem. Add the other two on/after 2026-08-01.
--   (Court of Appeals District II needs no TIGER import either — build its polygon as an
--   ST_Union of its member G4020 county polygons, all 72 of which are already loaded.)
--
-- EXCLUDED, on purpose, from the same source page:
--   - 12 Reserve/Retired judges (Nielsen, Martinez, Constantine, Costello, Flynn, Marik,
--     Mueller, Piontek, Ptacek, Simanek, Torhorst, Vuvunas) — not current officeholders.
--   - All Court Commissioners (Family, Judicial, Deputy, Supplemental) — APPOINTED by the
--     judges, not elected, so out of scope for an elected-officials product.
--
-- CHIEF JUDGE is recorded in essentials.judge_details.court_role, NOT in the office title.
--   In Wisconsin the chief judge of a judicial administrative district is DESIGNATED by the
--   Supreme Court; it is an administrative role layered on top of the elected branch seat, not
--   a separate elected office. So all ten offices carry the same elected title shape and
--   Laufenberg alone gets court_role='Chief Judge'.
--
-- date_seated is left NULL on purpose. The source gives YEARS only ("2017 to Present"), and
--   writing 2017-01-01 would invent a precision we do not have — Wisconsin terms start Aug 1,
--   and at least one of these judges (McClendon, 2025) looks like a mid-term appointment rather
--   than an election. The years are recorded in this header instead:
--     B1 Laufenberg 2017 · B2 Gasiorkiewicz 2010 · B3 Lynott 2024 · B4 Craig 2024
--     B5 Cafferty 2021 · B6 Paulson 2015 · B7 McClendon 2025 · B8 Flancher 2002
--     B9 Repischak 2017 · B10 Boyle 2012
--
-- Judges are elected to 6-year NONPARTISAN terms; party stays NULL and
--   judge_details.election_type='nonpartisan' records it positively.
BEGIN;

-- ── 1. Chamber under the existing Racine County government ──
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count, term_length)
SELECT gen_random_uuid(), 'Circuit Court', 'Racine County Circuit Court',
       (SELECT id FROM essentials.governments WHERE name = 'Racine County, Wisconsin, US'),
       10, '6 years'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
   WHERE name = 'Circuit Court'
     AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Racine County, Wisconsin, US')
);

-- ── 2. JUDICIAL district on the existing Racine County polygon ──
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials, is_judicial)
SELECT '55101', 'Racine County Circuit Court', 'JUDICIAL', 'wi', 'G4020', 10, true
WHERE EXISTS (
  SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = '55101' AND mtfcc = 'G4020'
) AND NOT EXISTS (
  SELECT 1 FROM essentials.districts
   WHERE geo_id = '55101' AND district_type = 'JUDICIAL' AND mtfcc = 'G4020'
);

-- ── 3. 10 judges ──
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, is_active, is_incumbent, is_appointed, is_vacant)
SELECT v.external_id, v.full_name, v.first_name, v.last_name, true, true, false, false
FROM (VALUES
    (-5529001::bigint, 'Wynne P. Laufenberg'::text,     'Wynne'::text,   'Laufenberg'::text),
    (-5529002,         'Eugene A. Gasiorkiewicz',       'Eugene',        'Gasiorkiewicz'),
    (-5529003,         'Jessica E.H. Lynott',           'Jessica',       'Lynott'),
    (-5529004,         'Scott P. Craig',                'Scott',         'Craig'),
    (-5529005,         'Kristin M. Cafferty',           'Kristin',       'Cafferty'),
    (-5529006,         'David W. Paulson',              'David',         'Paulson'),
    (-5529007,         'Jamie M. McClendon',            'Jamie',         'McClendon'),
    (-5529008,         'Faye M. Flancher',              'Faye',          'Flancher'),
    (-5529009,         'Robert S. Repischak',           'Robert',        'Repischak'),
    (-5529010,         'Timothy D. Boyle',              'Timothy',       'Boyle')
  ) AS v(external_id, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id);

-- ── 4. 10 offices, one per branch. Titles are unique, so the title guard is correct. ──
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, v.title, 'WI', NULL, false, false, 1
FROM (VALUES
    (-5529001::bigint, 'Circuit Court Judge, Branch 1'::text),
    (-5529002,         'Circuit Court Judge, Branch 2'),
    (-5529003,         'Circuit Court Judge, Branch 3'),
    (-5529004,         'Circuit Court Judge, Branch 4'),
    (-5529005,         'Circuit Court Judge, Branch 5'),
    (-5529006,         'Circuit Court Judge, Branch 6'),
    (-5529007,         'Circuit Court Judge, Branch 7'),
    (-5529008,         'Circuit Court Judge, Branch 8'),
    (-5529009,         'Circuit Court Judge, Branch 9'),
    (-5529010,         'Circuit Court Judge, Branch 10')
  ) AS v(external_id, title)
JOIN essentials.districts d
  ON d.geo_id = '55101' AND d.district_type = 'JUDICIAL' AND d.mtfcc = 'G4020' AND d.state = 'wi'
JOIN essentials.chambers c
  ON c.name = 'Circuit Court'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Racine County, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
   WHERE o.district_id = d.id AND o.chamber_id = c.id AND o.title = v.title
);

-- ── 5. judge_details: nonpartisan election type for all 10, Chief Judge role for Laufenberg ──
INSERT INTO essentials.judge_details (politician_id, court_role, election_type)
SELECT p.id, v.court_role, 'nonpartisan'
FROM (VALUES
    (-5529001::bigint, 'Chief Judge'::text),
    (-5529002,         NULL),
    (-5529003,         NULL),
    (-5529004,         NULL),
    (-5529005,         NULL),
    (-5529006,         NULL),
    (-5529007,         NULL),
    (-5529008,         NULL),
    (-5529009,         NULL),
    (-5529010,         NULL)
  ) AS v(external_id, court_role)
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.judge_details jd WHERE jd.politician_id = p.id
);

-- ── 6. Post-verify gate ──
DO $$
DECLARE n_ch int; n_d int; n_off int; n_orph int; n_chief int; n_jd int; n_party int; n_retired int;
BEGIN
  SELECT count(*) INTO n_ch FROM essentials.chambers
   WHERE name='Circuit Court'
     AND government_id=(SELECT id FROM essentials.governments WHERE name='Racine County, Wisconsin, US');
  IF n_ch <> 1 THEN RAISE EXCEPTION 'Circuit Court chambers: got %, want 1', n_ch; END IF;

  SELECT count(*) INTO n_d FROM essentials.districts
   WHERE geo_id='55101' AND district_type='JUDICIAL' AND mtfcc='G4020';
  IF n_d <> 1 THEN
    RAISE EXCEPTION 'JUDICIAL district on 55101: got %, want 1 (is the county geofence loaded?)', n_d;
  END IF;

  SELECT count(*) INTO n_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id=o.chamber_id
   WHERE c.name='Circuit Court'
     AND c.government_id=(SELECT id FROM essentials.governments WHERE name='Racine County, Wisconsin, US');
  IF n_off <> 10 THEN RAISE EXCEPTION 'circuit court offices: got %, want 10', n_off; END IF;

  SELECT count(*) INTO n_orph FROM essentials.politicians p
   WHERE p.external_id BETWEEN -5529010 AND -5529001
     AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.politician_id=p.id);
  IF n_orph <> 0 THEN RAISE EXCEPTION '% circuit judges hold no office', n_orph; END IF;

  SELECT count(*) INTO n_jd FROM essentials.judge_details jd
    JOIN essentials.politicians p ON p.id=jd.politician_id
   WHERE p.external_id BETWEEN -5529010 AND -5529001;
  IF n_jd <> 10 THEN RAISE EXCEPTION 'judge_details rows: got %, want 10', n_jd; END IF;

  SELECT count(*) INTO n_chief FROM essentials.judge_details jd
    JOIN essentials.politicians p ON p.id=jd.politician_id
   WHERE p.external_id BETWEEN -5529010 AND -5529001 AND jd.court_role='Chief Judge';
  IF n_chief <> 1 THEN RAISE EXCEPTION 'Chief Judge rows: got %, want exactly 1', n_chief; END IF;

  -- nonpartisan bench: no party may be stored
  SELECT count(*) INTO n_party FROM essentials.politicians
   WHERE external_id BETWEEN -5529010 AND -5529001 AND party IS NOT NULL;
  IF n_party <> 0 THEN RAISE EXCEPTION '% judges carry a party on a nonpartisan office', n_party; END IF;

  -- none of the 12 reserve/retired judges may have been seeded as current
  SELECT count(*) INTO n_retired FROM essentials.politicians
   WHERE external_id BETWEEN -5529010 AND -5529001
     AND full_name IN ('Mark Nielsen','Maureen Martinez','Charles Constantine','Dennis Costello',
                       'Dennis Flynn','Wayne Marik','Emily S. Mueller','Michael J. Piontek',
                       'Gerald P. Ptacek','Stephen Simanek','Allan Torhorst','Emmanuel Vuvunas');
  IF n_retired <> 0 THEN RAISE EXCEPTION '% reserve/retired judges seeded as current', n_retired; END IF;

  RAISE NOTICE 'Racine Circuit Court verify PASSED: 10 judges across Branches 1-10, 1 Chief Judge, 0 orphans, 0 retired.';
END $$;

COMMIT;
