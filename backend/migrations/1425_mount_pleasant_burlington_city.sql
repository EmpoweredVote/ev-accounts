-- 1425_mount_pleasant_burlington_city.sql
-- Municipalities 2 and 3 of 17 in Racine County, following the 1424 pattern:
--   Village of Mount Pleasant (~28k) -- President + 6 trustees (seats 1-6)
--   City of Burlington (~11k)        -- Mayor + 8 aldermen (TWO per district, 4 districts)
-- STRUCTURAL. Idempotent.
--
-- PRECONDITION: WI place geofences loaded (G4110). Mount Pleasant is '5554875',
--   Burlington city is '5511200'. Without them this inserts ZERO offices.
--
-- SOURCES, both read live 2026-07-25 (NOT from search summaries -- see below):
--   mtpleasantwi.gov/319/Village-Board
--   burlington-wi.gov/112/Mayor-Council + /113/Aldermen (this host 403s plain fetches;
--     read through a browser)
--
-- !! WHY LIVE PAGES MATTER: a web-search snapshot of Burlington's council listed "Tom Vos"
--    and "Corina Kretschmer" as sitting aldermen. The city's own page shows ANDREA BREWER
--    (District 1, term 2026-2028) and KATIE MOONEY (District 3, term 2026-2028) in those
--    seats -- the April 2026 spring election turned them over and the snapshot was stale.
--    Seeding from search results would have published two wrong officials. Always read the
--    municipality's own roster page, and prefer rows whose term string spans 2026-2028.
--
-- BURLINGTON GUARD DIVERGENCE (important -- differs from 1424): Burlington elects TWO
--   aldermen per district, so "Alderman, District 1" is NOT unique and the
--   (district_id, chamber_id, title) guard used for Racine city and Mount Pleasant would
--   silently no-op the second alderman in every district. Burlington is guarded on
--   (district_id, chamber_id, politician_id) instead -- the collegial-body guard AZ 1286
--   established for its 2-per-district House seats. Mount Pleasant's 6 trustees DO have
--   unique seat numbers, so the title guard is correct there.
--
-- !! DUPLICATE PEOPLE, deliberately NOT merged -- needs a product decision:
--    Racine County has a recurring pattern of officials holding a county seat AND a municipal
--    seat, plus candidates who are also sitting municipal officials. Four known collisions:
--      - Renee Kelly           -- City of Racine Alderman D13 (-5511014) AND County Supervisor D2 (-5510102)
--      - Tom Preusker          -- Burlington Alderman D4 (this migration) AND County Supervisor D20 (-5510120)
--      - Gina Cefalu-Paulick   -- Mount Pleasant Trustee Seat 2 (this migration) AND the
--                                 AD-66 Republican candidate seeded by 1422 (-5507092).
--                                 Mount Pleasant sits inside AD 66, so this is very likely one person.
--      - Thomas/Tom Weatherston -- County Supervisor D17 (-5510117) AND, per search, Caledonia
--                                 Village President (Caledonia not yet seeded)
--    This migration creates SEPARATE politician rows, consistent with how 1424 already handled
--    Renee Kelly in prod. Rationale: a matching name is not proof of a matching person, and
--    conflating two real people is worse than a split profile. But the cost is real -- if they
--    ARE the same person, their photo, stances and campaign finance are split across two rows.
--    RESOLVE THIS ONCE for all 17 municipalities, then apply a single dedup migration that
--    re-points offices onto one politician and deletes the orphan. Do not resolve case by case.
--
-- ANTIPARTISAN: Wisconsin municipal offices are genuinely nonpartisan -- party is NULL for all 16.
--
-- No races: municipal races are filed with the MUNICIPAL clerk and the April 2026 spring
--   election has already passed.
BEGIN;

-- =====================  VILLAGE OF MOUNT PLEASANT (G4110 5554875)  =====================

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'Village of Mount Pleasant, Wisconsin, US', 'Village', 'WI', 'Mount Pleasant', '5554875'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'Village of Mount Pleasant, Wisconsin, US'
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Village President', 'Village of Mount Pleasant Village President',
       (SELECT id FROM essentials.governments WHERE name = 'Village of Mount Pleasant, Wisconsin, US'), 1
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers WHERE name = 'Village President'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Mount Pleasant, Wisconsin, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Village Board', 'Village of Mount Pleasant Village Board',
       (SELECT id FROM essentials.governments WHERE name = 'Village of Mount Pleasant, Wisconsin, US'), 6
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers WHERE name = 'Village Board'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Mount Pleasant, Wisconsin, US')
);

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5554875', 'Village of Mount Pleasant', 'LOCAL_EXEC', 'wi', 'G4110', 1
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5554875' AND mtfcc='G4110')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5554875' AND district_type='LOCAL_EXEC' AND mtfcc='G4110');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5554875', 'Village of Mount Pleasant', 'LOCAL', 'wi', 'G4110', 6
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5554875' AND mtfcc='G4110')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5554875' AND district_type='LOCAL' AND mtfcc='G4110');

INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, is_active, is_incumbent, is_appointed, is_vacant)
SELECT v.external_id, v.full_name, v.first_name, v.last_name, true, true, false, false
FROM (VALUES
    (-5512001::bigint, 'David DeGroot'::text,       'David'::text,  'DeGroot'::text),
    (-5512002,         'David Karas',               'David',        'Karas'),
    (-5512003,         'Gina Cefalu-Paulick',       'Gina',         'Cefalu-Paulick'),
    (-5512004,         'Nancy Washburn',            'Nancy',        'Washburn'),
    (-5512005,         'Denise Anastasio',          'Denise',       'Anastasio'),
    (-5512006,         'Ram Bhatia',                'Ram',          'Bhatia'),
    (-5512007,         'Jim Venturini',             'Jim',          'Venturini')
  ) AS v(external_id, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id);

INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, 'Village President', 'WI', 'Mount Pleasant', false, false, 1
FROM essentials.districts d
JOIN essentials.chambers c ON c.name='Village President'
 AND c.government_id=(SELECT id FROM essentials.governments WHERE name='Village of Mount Pleasant, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = -5512001
WHERE d.geo_id='5554875' AND d.district_type='LOCAL_EXEC' AND d.mtfcc='G4110' AND d.state='wi'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.title='Village President');

-- 6 trustees: seat numbers are unique -> title guard is safe here
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, v.title, 'WI', 'Mount Pleasant', false, false, 1
FROM (VALUES
    (-5512002::bigint, 'Village Trustee, Seat 1'::text),
    (-5512003,         'Village Trustee, Seat 2'),
    (-5512004,         'Village Trustee, Seat 3'),
    (-5512005,         'Village Trustee, Seat 4'),
    (-5512006,         'Village Trustee, Seat 5'),
    (-5512007,         'Village Trustee, Seat 6')
  ) AS v(external_id, title)
JOIN essentials.districts d
  ON d.geo_id='5554875' AND d.district_type='LOCAL' AND d.mtfcc='G4110' AND d.state='wi'
JOIN essentials.chambers c ON c.name='Village Board'
 AND c.government_id=(SELECT id FROM essentials.governments WHERE name='Village of Mount Pleasant, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.title=v.title);

-- =====================  CITY OF BURLINGTON (G4110 5511200)  =====================

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'City of Burlington, Wisconsin, US', 'City', 'WI', 'Burlington', '5511200'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.governments WHERE name = 'City of Burlington, Wisconsin, US'
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Mayor', 'City of Burlington Mayor',
       (SELECT id FROM essentials.governments WHERE name = 'City of Burlington, Wisconsin, US'), 1
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers WHERE name = 'Mayor'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Burlington, Wisconsin, US')
);

INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Common Council', 'City of Burlington Common Council',
       (SELECT id FROM essentials.governments WHERE name = 'City of Burlington, Wisconsin, US'), 8
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.chambers WHERE name = 'Common Council'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'City of Burlington, Wisconsin, US')
);

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5511200', 'City of Burlington', 'LOCAL_EXEC', 'wi', 'G4110', 1
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5511200' AND mtfcc='G4110')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5511200' AND district_type='LOCAL_EXEC' AND mtfcc='G4110');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5511200', 'City of Burlington', 'LOCAL', 'wi', 'G4110', 8
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5511200' AND mtfcc='G4110')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5511200' AND district_type='LOCAL' AND mtfcc='G4110');

INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, is_active, is_incumbent, is_appointed, is_vacant)
SELECT v.external_id, v.full_name, v.first_name, v.last_name, true, true, false, false
FROM (VALUES
    (-5513001::bigint, 'Jon Schultz'::text,        'Jon'::text,     'Schultz'::text),
    (-5513002,         'Shad Branen',              'Shad',          'Branen'),
    (-5513003,         'Andrea Brewer',            'Andrea',        'Brewer'),
    (-5513004,         'Judi Adams',               'Judi',          'Adams'),
    (-5513005,         'Phil Hein',                'Phil',          'Hein'),
    (-5513006,         'David K. Thompson',        'David',         'Thompson'),
    (-5513007,         'Katie Mooney',             'Katie',         'Mooney'),
    (-5513008,         'Tom Preusker',             'Tom',           'Preusker'),
    (-5513009,         'Bill Smitz',               'Bill',          'Smitz')
  ) AS v(external_id, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id);

INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, 'Mayor', 'WI', 'Burlington', false, false, 1
FROM essentials.districts d
JOIN essentials.chambers c ON c.name='Mayor'
 AND c.government_id=(SELECT id FROM essentials.governments WHERE name='City of Burlington, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = -5513001
WHERE d.geo_id='5511200' AND d.district_type='LOCAL_EXEC' AND d.mtfcc='G4110' AND d.state='wi'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.title='Mayor');

-- 8 aldermen, TWO per district -> guard on politician_id, NOT title (titles repeat)
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, v.title, 'WI', 'Burlington', false, false, 1
FROM (VALUES
    (-5513002::bigint, 'Alderman, District 1'::text),
    (-5513003,         'Alderman, District 1'),
    (-5513004,         'Alderman, District 2'),
    (-5513005,         'Alderman, District 2'),
    (-5513006,         'Alderman, District 3'),
    (-5513007,         'Alderman, District 3'),
    (-5513008,         'Alderman, District 4'),
    (-5513009,         'Alderman, District 4')
  ) AS v(external_id, title)
JOIN essentials.districts d
  ON d.geo_id='5511200' AND d.district_type='LOCAL' AND d.mtfcc='G4110' AND d.state='wi'
JOIN essentials.chambers c ON c.name='Common Council'
 AND c.government_id=(SELECT id FROM essentials.governments WHERE name='City of Burlington, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id);

-- ── Post-verify gate ──
DO $$
DECLARE mp uuid; bu uuid; n int; n_party int;
BEGIN
  SELECT id INTO mp FROM essentials.governments WHERE name='Village of Mount Pleasant, Wisconsin, US';
  SELECT id INTO bu FROM essentials.governments WHERE name='City of Burlington, Wisconsin, US';
  IF mp IS NULL OR bu IS NULL THEN RAISE EXCEPTION 'a government row is missing'; END IF;

  SELECT count(*) INTO n FROM essentials.offices o JOIN essentials.chambers c ON c.id=o.chamber_id
   WHERE c.government_id = mp;
  IF n <> 7 THEN RAISE EXCEPTION 'Mount Pleasant offices: got %, want 7', n; END IF;

  SELECT count(*) INTO n FROM essentials.offices o JOIN essentials.chambers c ON c.id=o.chamber_id
   WHERE c.government_id = bu;
  IF n <> 9 THEN RAISE EXCEPTION 'Burlington offices: got %, want 9 (Mayor + 8 aldermen)', n; END IF;

  -- Burlington must have exactly 2 aldermen in each of its 4 districts
  SELECT count(*) INTO n FROM (
    SELECT o.title FROM essentials.offices o JOIN essentials.chambers c ON c.id=o.chamber_id
     WHERE c.government_id = bu AND c.name='Common Council'
     GROUP BY o.title HAVING count(*) <> 2
  ) x;
  IF n <> 0 THEN RAISE EXCEPTION '% Burlington districts do not have exactly 2 aldermen', n; END IF;

  SELECT count(*) INTO n FROM essentials.politicians p
   WHERE (p.external_id BETWEEN -5512007 AND -5512001 OR p.external_id BETWEEN -5513009 AND -5513001)
     AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.politician_id=p.id);
  IF n <> 0 THEN RAISE EXCEPTION '% municipal officials hold no office', n; END IF;

  SELECT count(*) INTO n_party FROM essentials.politicians
   WHERE (external_id BETWEEN -5512007 AND -5512001 OR external_id BETWEEN -5513009 AND -5513001)
     AND party IS NOT NULL;
  IF n_party <> 0 THEN RAISE EXCEPTION '% carry a party on a nonpartisan municipal office', n_party; END IF;

  RAISE NOTICE 'Mount Pleasant + Burlington verify PASSED: 7 + 9 offices, 2 aldermen per Burlington district, 0 orphans.';
END $$;

COMMIT;
