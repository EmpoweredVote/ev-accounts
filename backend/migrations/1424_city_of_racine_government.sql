-- 1424_city_of_racine_government.sql
-- City of Racine: government, 2 chambers, Mayor + 15 aldermen, 16 offices.
-- FIRST municipality in Racine County -- establishes the pattern the other 16 will follow.
-- STRUCTURAL. Idempotent.
--
-- PRECONDITION: the WI place geofences must be loaded (607 G4110 rows) --
--   npx tsx scripts/load-state-tiger-boundaries.ts --state WI --fips 55 --layers place,cousub
--   City of Racine is G4110 geo_id '5566000'. Without it this inserts ZERO offices.
--
-- SOURCE: cityofracinewi.gov, read 2026-07-25 through a browser.
--   Mayor: /government/city-leadership/mayor/  -> Cory Mason
--   Aldermen: /government/city-leadership/common-council/cityalderman/ -> all 15 with districts
--   (note cityofracine.org now redirects to cityofracinewi.gov)
--
-- ROUTING MODEL -- read before copying this to the other 16 municipalities:
--   All 16 officials attach to the CITY polygon (G4110 '5566000'), NOT to per-ward polygons,
--   so a Racine city address surfaces the Mayor plus all 15 aldermen. This mirrors Multnomah
--   County (migration 244), where every commissioner hangs off the single county district.
--   WHY: Racine's 15 aldermanic districts have no usable published geometry. The county's
--   ArcGIS server has only a '2020Reapportionment' folder of DRAFT maps, and the city does not
--   publish ward boundaries. Rather than invent boundaries, aldermen are surfaced city-wide.
--   The aldermanic district NUMBER is preserved in each office title, so upgrading to
--   per-ward routing later is additive: import ward polygons under an X-series mtfcc and
--   re-point each office's district_id. Nothing here has to be undone.
--
--   Tier choice: the 13 INCORPORATED Racine County municipalities (2 cities + 11 villages) use
--   their G4110 place geo_id; the 4 TOWNS have no place row and must use their G4040 cousub
--   geo_id. Attaching a municipality to BOTH its place and cousub geo_id would double-match a
--   resident's address and duplicate every official -- pick exactly one per municipality.
--
-- essentialsService requires mtfcc IN ('G4110','G4120') paired with district_type IN
--   ('LOCAL','LOCAL_EXEC'), so the Mayor gets a LOCAL_EXEC district row and the Council a
--   LOCAL row, both on geo_id '5566000'. districts.state is LOWERCASE 'wi' for this tier;
--   governments.state is UPPERCASE 'WI'.
--
-- CRITICAL (shared district+chamber guard): all 15 aldermen share the SAME district_id AND
--   chamber_id, so the usual (district_id, chamber_id) guard would silently no-op aldermen 2
--   through 15. They are guarded on (district_id, chamber_id, title) -- titles embed the
--   district number and so are unique. Same trap as the 7 countywide officers in 1385.
--
-- !! POSSIBLE DUAL OFFICEHOLDER, deliberately NOT merged: Alderman District 13 is "Renee
--    Kelly", and County Board Supervisor District 2 (seeded in 1385 as -5510102) is also
--    "Renee Kelly". Holding a county supervisor seat and a city alder seat simultaneously is
--    legal in Wisconsin and does happen, but name identity is NOT proof of person identity.
--    A separate politician row (-5511014) is created here. If they are confirmed to be the
--    same person, merge to ONE politician holding two offices -- do not guess either way.
--
-- Terms: the Council has 15 members on staggered 2-year terms -- EVEN-numbered districts are
--   elected in even years, ODD-numbered in odd years (per the city's Common Council page). So
--   roughly half the seats are on any given spring ballot. No races are seeded here; municipal
--   races are filed with the MUNICIPAL clerk and the April 2026 spring election has passed.
--
-- ANTIPARTISAN: Wisconsin municipal offices are NONPARTISAN. party is NULL for all 16 --
--   correct as a matter of fact here, not merely as a display rule.
BEGIN;

-- ── 1. Government ──
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of Racine, Wisconsin, US', 'City', 'WI', 'Racine', '5566000'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of Racine, Wisconsin, US'
);

-- ── 2. Two chambers (slug is GENERATED ALWAYS -- never in the column list) ──
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Mayor', 'City of Racine Mayor',
       (SELECT id FROM essentials.governments WHERE name = 'City of Racine, Wisconsin, US'), 1
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
   WHERE name = 'Mayor'
     AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Racine, Wisconsin, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Common Council', 'City of Racine Common Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Racine, Wisconsin, US'), 15
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers
   WHERE name = 'Common Council'
     AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Racine, Wisconsin, US')
);

-- ── 3. Two district rows on the city polygon: LOCAL_EXEC (Mayor) + LOCAL (Council) ──
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5566000', 'City of Racine', 'LOCAL_EXEC', 'wi', 'G4110', 1
WHERE EXISTS (
  SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = '5566000' AND mtfcc = 'G4110'
) AND NOT EXISTS (
  SELECT 1 FROM essentials.districts
   WHERE geo_id = '5566000' AND district_type = 'LOCAL_EXEC' AND mtfcc = 'G4110'
);

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5566000', 'City of Racine', 'LOCAL', 'wi', 'G4110', 15
WHERE EXISTS (
  SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id = '5566000' AND mtfcc = 'G4110'
) AND NOT EXISTS (
  SELECT 1 FROM essentials.districts
   WHERE geo_id = '5566000' AND district_type = 'LOCAL' AND mtfcc = 'G4110'
);

-- ── 4. 16 politicians (nonpartisan offices -> party NULL) ──
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, is_active, is_incumbent, is_appointed, is_vacant)
SELECT v.external_id, v.full_name, v.first_name, v.last_name, true, true, false, false
FROM (VALUES
    (-5511001::bigint, 'Cory Mason'::text,             'Cory'::text,    'Mason'::text),
    (-5511002,         'Malik Frazier',                'Malik',         'Frazier'),
    (-5511003,         'Alyson Weiss',                 'Alyson',        'Weiss'),
    (-5511004,         'Olivia Turquoise Davis',       'Olivia',        'Davis'),
    (-5511005,         'David L. Maack',               'David',         'Maack'),
    (-5511006,         'Jens Jorgensen',               'Jens',          'Jorgensen'),
    (-5511007,         'Sandy Weidner',                'Sandy',         'Weidner'),
    (-5511008,         'Maurice Horton',               'Maurice',       'Horton'),
    (-5511009,         'Brittany Hodges',              'Brittany',      'Hodges'),
    (-5511010,         'Grace Allen',                  'Grace',         'Allen'),
    (-5511011,         'Sam Peete',                    'Sam',           'Peete'),
    (-5511012,         'Mary Land',                    'Mary',          'Land'),
    (-5511013,         'Rocco DeMark',                 'Rocco',         'DeMark'),
    (-5511014,         'Renee Kelly',                  'Renee',         'Kelly'),
    (-5511015,         'Marlo Harmon',                 'Marlo',         'Harmon'),
    (-5511016,         'Nathan Pabon',                 'Nathan',        'Pabon')
  ) AS v(external_id, full_name, first_name, last_name)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id
);

-- ── 5. Mayor -> LOCAL_EXEC district ──
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, 'Mayor', 'WI', 'Racine', false, false, 1
FROM essentials.districts d
JOIN essentials.chambers c
  ON c.name = 'Mayor'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Racine, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = -5511001
WHERE d.geo_id = '5566000' AND d.district_type = 'LOCAL_EXEC' AND d.mtfcc = 'G4110' AND d.state = 'wi'
  AND NOT EXISTS (
    SELECT 1 FROM essentials.offices o
     WHERE o.district_id = d.id AND o.chamber_id = c.id AND o.title = 'Mayor'
  );

-- ── 6. 15 aldermen -> the LOCAL district, guarded on (district, chamber, TITLE) ──
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, v.title, 'WI', 'Racine', false, false, 1
FROM (VALUES
    (-5511002::bigint, 'Alderman, District 1'::text),
    (-5511003,         'Alderman, District 2'),
    (-5511004,         'Alderman, District 3'),
    (-5511005,         'Alderman, District 4'),
    (-5511006,         'Alderman, District 5'),
    (-5511007,         'Alderman, District 6'),
    (-5511008,         'Alderman, District 7'),
    (-5511009,         'Alderman, District 8'),
    (-5511010,         'Alderman, District 9'),
    (-5511011,         'Alderman, District 10'),
    (-5511012,         'Alderman, District 11'),
    (-5511013,         'Alderman, District 12'),
    (-5511014,         'Alderman, District 13'),
    (-5511015,         'Alderman, District 14'),
    (-5511016,         'Alderman, District 15')
  ) AS v(external_id, title)
JOIN essentials.districts d
  ON d.geo_id = '5566000' AND d.district_type = 'LOCAL' AND d.mtfcc = 'G4110' AND d.state = 'wi'
JOIN essentials.chambers c
  ON c.name = 'Common Council'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Racine, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.offices o
   WHERE o.district_id = d.id AND o.chamber_id = c.id AND o.title = v.title
);

-- ── 7. Post-verify gate ──
DO $$
DECLARE gid uuid; n_ch int; n_d int; n_off int; n_orphan int; n_party int; n_dupe int;
BEGIN
  SELECT id INTO gid FROM essentials.governments WHERE name = 'City of Racine, Wisconsin, US';
  IF gid IS NULL THEN RAISE EXCEPTION 'City of Racine government row missing'; END IF;

  SELECT count(*) INTO n_ch FROM essentials.chambers WHERE government_id = gid;
  IF n_ch <> 2 THEN RAISE EXCEPTION 'City of Racine chambers: got %, want 2', n_ch; END IF;

  SELECT count(*) INTO n_d FROM essentials.districts
   WHERE geo_id = '5566000' AND mtfcc = 'G4110' AND district_type IN ('LOCAL','LOCAL_EXEC');
  IF n_d <> 2 THEN
    RAISE EXCEPTION 'City of Racine districts: got %, want 2 -- are the WI place geofences loaded?', n_d;
  END IF;

  SELECT count(*) INTO n_off FROM essentials.offices o
    JOIN essentials.chambers c ON c.id = o.chamber_id WHERE c.government_id = gid;
  IF n_off <> 16 THEN RAISE EXCEPTION 'City of Racine offices: got %, want 16', n_off; END IF;

  SELECT count(*) INTO n_orphan FROM essentials.politicians p
   WHERE p.external_id BETWEEN -5511016 AND -5511001
     AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.politician_id = p.id);
  IF n_orphan <> 0 THEN RAISE EXCEPTION '% City of Racine officials hold no office', n_orphan; END IF;

  -- nonpartisan offices: no party may be stored
  SELECT count(*) INTO n_party FROM essentials.politicians
   WHERE external_id BETWEEN -5511016 AND -5511001 AND party IS NOT NULL;
  IF n_party <> 0 THEN RAISE EXCEPTION '% city officials carry a party on a nonpartisan office', n_party; END IF;

  -- all 15 alder titles must be distinct (the guard depends on it)
  SELECT count(*) INTO n_dupe FROM (
    SELECT o.title FROM essentials.offices o
      JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE c.government_id = gid AND c.name = 'Common Council'
     GROUP BY o.title HAVING count(*) > 1
  ) x;
  IF n_dupe <> 0 THEN RAISE EXCEPTION '% duplicated alder titles', n_dupe; END IF;

  RAISE NOTICE 'City of Racine verify PASSED: 2 chambers, 2 districts, 16 offices (Mayor + 15 aldermen), 0 orphans.';
END $$;

COMMIT;
