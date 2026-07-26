-- 1431_caledonia_union_grove.sql
-- The final 2 Racine County municipalities: Caledonia and Union Grove.
-- COMPLETES municipal coverage at 17 of 17. STRUCTURAL. Idempotent.
--
-- PRECONDITION: WI place geofences loaded. Caledonia is G4110 '5511950',
--   Union Grove is G4110 '5581775'.
--
-- Both were listed as unverifiable in 1449/1451. Both are resolved here by the April 7, 2026
-- spring-election results, which is the piece that was missing — the village directories alone
-- were genuinely ambiguous.
--
-- ═══ CALEDONIA — a vacancy, not missing data ═══
-- Sequence, reconstructed and cross-checked:
--   1. April 7 2026: Prescott Balch DEFEATED incumbent Dale Stillman for Trustee Seat #2
--      (3,646 to 2,703). Fran Martin (Seat 4) and Lee Wishau (Seat 6) were re-elected.
--      Source: Racine County Eye, 2026-04-07 Caledonia results.
--   2. Village President Tom Weatherston then RESIGNED, citing "major philosophical
--      differences with the village board" after it voted down a development agreement.
--      Trustee Lee Wishau served as president in the interim while the board decided between
--      a special election and an appointment.
--   3. The village's own current board page now lists PRESCOTT BALCH as Village President —
--      i.e. he moved up from Trustee Seat 2 — and shows NO Trustee 2, leaving that seat VACANT.
--
-- So Caledonia's board is 6 filled seats + 1 vacancy, which is a FACT about the body rather
--   than a gap in our data. Seat 2 is therefore seeded as an explicit vacant office row
--   (politician_id NULL, is_vacant = true). That is the established shape: 155 offices already
--   carry NULL politician_id together with is_vacant.
--
-- !! CONFIDENCE NOTE, worth a phone call to the village (262-835-4451): step 3 rests on the
--    village's own board page, which is the best and most current source available but which
--    could not be machine-read — its roster is rendered by a Munibit component that never
--    hydrates for automated access, so it was transcribed from a screenshot. Press coverage
--    from the moment of resignation still described Wishau as interim president and did not
--    report how the vacancy was finally settled. If Balch is in fact still Trustee 2 with the
--    presidency vacant or interim, swap the President and Trustee-2 rows. Everything else
--    (Pierce 1, Lambrecht 3, Martin 4, McManus 5, Wishau 6) is unaffected either way.
--    This also finally disposes of the earlier claim that Tom Weatherston was Caledonia's
--    president: he WAS, but he resigned, and he is not on the board now.
--
-- ═══ UNION GROVE — the directory's term labels were stale, the PEOPLE were right ═══
-- The village directory shows trustees 2/4/6 with "(2024-2026)" terms, which expired in April
--   and is why 1449 skipped it. The April 7 2026 results resolve it: all three were RETURNED.
--     Seat #2 Kristy Boyle  — unopposed
--     Seat #4 Adam Graf     — unopposed
--     Seat #6 Eugene Bower  — won 706 to Shai Demers' 341
--   (Bower had been APPOINTED in Aug 2025 to finish that seat's term; he then won it outright.)
--   So the roster is correct and only the term STRINGS are unrefreshed. Seeded as-is.
--   Lesson: an expired term label means "verify", not "wrong" — check the election result
--   before discarding a roster.
--
-- !! Steve Wicklund is REUSED, not duplicated. He is both Union Grove's Village President and
--    the AD-33 Republican candidate seeded by 1444 (external_id -5507044, which held a
--    candidacy and no office). Union Grove sits inside Assembly District 33, and the names
--    match exactly. Rather than create a second row and clean it up in a follow-up merge — the
--    mistake 1450 had to repair four times — his existing record simply gains this office.
--    He now holds 1 office + 1 candidacy.
--
-- Out of scope, consistent with the Town of Dover: Union Grove's Municipal Judge (Scott
--   Kasprowicz, 2025-2027) is an ELECTED office in Wisconsin but belongs to the judicial tier,
--   which is not yet built for Racine County.
--
-- Guards: both boards number their seats, so titles are unique and the
--   (district_id, chamber_id, title) guard is correct here — unlike the unnumbered boards in
--   1449/1451, which needed the collegial politician_id guard.
--
-- ANTIPARTISAN: Wisconsin municipal offices are genuinely nonpartisan; party stays NULL. Note
--   Wicklund's existing row also has party NULL even though he is a Republican Assembly
--   candidate — party belongs on races.primary_party, never on the person.
BEGIN;

-- ═════════════════════  VILLAGE OF CALEDONIA (G4110 5511950)  ═════════════════════

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'Village of Caledonia, Wisconsin, US', 'Village', 'WI', 'Caledonia', '5511950'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'Village of Caledonia, Wisconsin, US');

INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Village President', 'Village of Caledonia Village President',
       (SELECT id FROM essentials.governments WHERE name = 'Village of Caledonia, Wisconsin, US'), 1
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Village President'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Caledonia, Wisconsin, US'));

INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Village Board', 'Village of Caledonia Village Board',
       (SELECT id FROM essentials.governments WHERE name = 'Village of Caledonia, Wisconsin, US'), 6
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Village Board'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Caledonia, Wisconsin, US'));

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5511950', 'Village of Caledonia', 'LOCAL_EXEC', 'wi', 'G4110', 1
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5511950' AND mtfcc='G4110')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts WHERE geo_id='5511950' AND district_type='LOCAL_EXEC' AND mtfcc='G4110');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5511950', 'Village of Caledonia', 'LOCAL', 'wi', 'G4110', 6
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5511950' AND mtfcc='G4110')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts WHERE geo_id='5511950' AND district_type='LOCAL' AND mtfcc='G4110');

INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, is_active, is_incumbent, is_appointed, is_vacant)
SELECT v.external_id, v.full_name, v.first_name, v.last_name, true, true, false, false
FROM (VALUES
    (-5526001::bigint, 'Prescott Balch'::text,    'Prescott'::text, 'Balch'::text),
    (-5526002,         'Nancy Pierce',            'Nancy',          'Pierce'),
    (-5526003,         'Michael Lambrecht',       'Michael',        'Lambrecht'),
    (-5526004,         'Fran Martin',             'Fran',           'Martin'),
    (-5526005,         'Holly McManus',           'Holly',          'McManus'),
    (-5526006,         'Lee Wishau',              'Lee',            'Wishau')
  ) AS v(external_id, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id);

-- President (Balch, elevated from Trustee 2)
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, 'Village President', 'WI', 'Caledonia', false, false, 1
FROM essentials.districts d
JOIN essentials.chambers c ON c.name='Village President'
 AND c.government_id=(SELECT id FROM essentials.governments WHERE name='Village of Caledonia, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = -5526001
WHERE d.geo_id='5511950' AND d.district_type='LOCAL_EXEC' AND d.mtfcc='G4110' AND d.state='wi'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.title='Village President');

-- 5 filled trustee seats (1, 3, 4, 5, 6)
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, v.title, 'WI', 'Caledonia', false, false, 1
FROM (VALUES
    (-5526002::bigint, 'Village Trustee, Seat 1'::text),
    (-5526003,         'Village Trustee, Seat 3'),
    (-5526004,         'Village Trustee, Seat 4'),
    (-5526005,         'Village Trustee, Seat 5'),
    (-5526006,         'Village Trustee, Seat 6')
  ) AS v(external_id, title)
JOIN essentials.districts d
  ON d.geo_id='5511950' AND d.district_type='LOCAL' AND d.mtfcc='G4110' AND d.state='wi'
JOIN essentials.chambers c ON c.name='Village Board'
 AND c.government_id=(SELECT id FROM essentials.governments WHERE name='Village of Caledonia, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.title=v.title);

-- Trustee Seat 2: VACANT (Balch vacated it on becoming President). Explicit vacant row rather
-- than an omission, matching the 155 existing offices that pair NULL politician_id with is_vacant.
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, NULL, 'Village Trustee, Seat 2', 'WI', 'Caledonia', false, true, 1
FROM essentials.districts d
JOIN essentials.chambers c ON c.name='Village Board'
 AND c.government_id=(SELECT id FROM essentials.governments WHERE name='Village of Caledonia, Wisconsin, US')
WHERE d.geo_id='5511950' AND d.district_type='LOCAL' AND d.mtfcc='G4110' AND d.state='wi'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.title='Village Trustee, Seat 2');

-- ═════════════════════  VILLAGE OF UNION GROVE (G4110 5581775)  ═════════════════════

INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'Village of Union Grove, Wisconsin, US', 'Village', 'WI', 'Union Grove', '5581775'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'Village of Union Grove, Wisconsin, US');

INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Village President', 'Village of Union Grove Village President',
       (SELECT id FROM essentials.governments WHERE name = 'Village of Union Grove, Wisconsin, US'), 1
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Village President'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Union Grove, Wisconsin, US'));

INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Village Board', 'Village of Union Grove Village Board',
       (SELECT id FROM essentials.governments WHERE name = 'Village of Union Grove, Wisconsin, US'), 6
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Village Board'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Union Grove, Wisconsin, US'));

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5581775', 'Village of Union Grove', 'LOCAL_EXEC', 'wi', 'G4110', 1
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5581775' AND mtfcc='G4110')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts WHERE geo_id='5581775' AND district_type='LOCAL_EXEC' AND mtfcc='G4110');

INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5581775', 'Village of Union Grove', 'LOCAL', 'wi', 'G4110', 6
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5581775' AND mtfcc='G4110')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts WHERE geo_id='5581775' AND district_type='LOCAL' AND mtfcc='G4110');

-- 6 trustees are new; the President (Wicklund) already exists as -5507044 from 1444.
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, is_active, is_incumbent, is_appointed, is_vacant)
SELECT v.external_id, v.full_name, v.first_name, v.last_name, true, true, false, false
FROM (VALUES
    (-5527002::bigint, 'Sara Gloeckler'::text,    'Sara'::text,     'Gloeckler'::text),
    (-5527003,         'Kristy Boyle',            'Kristy',         'Boyle'),
    (-5527004,         'Steve Peterson',          'Steve',          'Peterson'),
    (-5527005,         'Adam Graf',               'Adam',           'Graf'),
    (-5527006,         'Jennifer Ditscheit',      'Jennifer',       'Ditscheit'),
    (-5527007,         'Eugene Bower',            'Eugene',         'Bower')
  ) AS v(external_id, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id);

-- President: REUSES the existing AD-33 candidate record (-5507044), no duplicate created.
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, 'Village President', 'WI', 'Union Grove', false, false, 1
FROM essentials.districts d
JOIN essentials.chambers c ON c.name='Village President'
 AND c.government_id=(SELECT id FROM essentials.governments WHERE name='Village of Union Grove, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = -5507044
WHERE d.geo_id='5581775' AND d.district_type='LOCAL_EXEC' AND d.mtfcc='G4110' AND d.state='wi'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.title='Village President');

INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, v.title, 'WI', 'Union Grove', false, false, 1
FROM (VALUES
    (-5527002::bigint, 'Village Trustee, Seat 1'::text),
    (-5527003,         'Village Trustee, Seat 2'),
    (-5527004,         'Village Trustee, Seat 3'),
    (-5527005,         'Village Trustee, Seat 4'),
    (-5527006,         'Village Trustee, Seat 5'),
    (-5527007,         'Village Trustee, Seat 6')
  ) AS v(external_id, title)
JOIN essentials.districts d
  ON d.geo_id='5581775' AND d.district_type='LOCAL' AND d.mtfcc='G4110' AND d.state='wi'
JOIN essentials.chambers c ON c.name='Village Board'
 AND c.government_id=(SELECT id FROM essentials.governments WHERE name='Village of Union Grove, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.title=v.title);

-- ── Post-verify gate ──
DO $$
DECLARE cal uuid; ug uuid; n int; n_vac int; n_wick int; n_munis int;
BEGIN
  SELECT id INTO cal FROM essentials.governments WHERE name='Village of Caledonia, Wisconsin, US';
  SELECT id INTO ug  FROM essentials.governments WHERE name='Village of Union Grove, Wisconsin, US';
  IF cal IS NULL OR ug IS NULL THEN RAISE EXCEPTION 'a government row is missing'; END IF;

  -- Caledonia: 7 office rows (1 president + 6 trustee seats), of which exactly 1 is vacant
  SELECT count(*) INTO n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id=o.chamber_id WHERE c.government_id=cal;
  IF n <> 7 THEN RAISE EXCEPTION 'Caledonia offices: got %, want 7 (incl. the vacant Seat 2)', n; END IF;

  SELECT count(*) INTO n_vac FROM essentials.offices o
    JOIN essentials.chambers c ON c.id=o.chamber_id
   WHERE c.government_id=cal AND o.is_vacant AND o.politician_id IS NULL;
  IF n_vac <> 1 THEN RAISE EXCEPTION 'Caledonia vacant seats: got %, want exactly 1', n_vac; END IF;

  -- Union Grove: 7 offices, none vacant
  SELECT count(*) INTO n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id=o.chamber_id WHERE c.government_id=ug;
  IF n <> 7 THEN RAISE EXCEPTION 'Union Grove offices: got %, want 7', n; END IF;

  SELECT count(*) INTO n FROM essentials.offices o
    JOIN essentials.chambers c ON c.id=o.chamber_id
   WHERE c.government_id=ug AND (o.is_vacant OR o.politician_id IS NULL);
  IF n <> 0 THEN RAISE EXCEPTION 'Union Grove should have no vacancies, found %', n; END IF;

  -- Wicklund must hold exactly ONE politician row and now 1 office + 1 candidacy
  SELECT count(*) INTO n_wick FROM essentials.politicians WHERE full_name = 'Steve Wicklund';
  IF n_wick <> 1 THEN RAISE EXCEPTION 'Steve Wicklund has % politician rows, want 1 (reuse, not duplicate)', n_wick; END IF;

  SELECT count(*) INTO n FROM essentials.offices o
    JOIN essentials.politicians p ON p.id=o.politician_id WHERE p.external_id = -5507044;
  IF n <> 1 THEN RAISE EXCEPTION 'Wicklund holds % offices, want 1', n; END IF;

  -- no duplicate names among all Racine County seeded officials
  SELECT count(*) INTO n FROM (
    SELECT lower(full_name) FROM essentials.politicians
     WHERE external_id BETWEEN -5527999 AND -5510001
     GROUP BY lower(full_name) HAVING count(*) > 1
  ) x;
  IF n <> 0 THEN RAISE EXCEPTION '% duplicate names among Racine County officials', n; END IF;

  -- all 17 Racine County municipalities must now have a government row
  SELECT count(*) INTO n_munis FROM essentials.governments
   WHERE state='WI' AND type IN ('City','Village','Town');
  IF n_munis <> 17 THEN RAISE EXCEPTION 'WI municipal governments: got %, want 17', n_munis; END IF;

  RAISE NOTICE 'Caledonia + Union Grove verify PASSED: 17 of 17 municipalities, Caledonia Seat 2 vacant, Wicklund reused not duplicated.';
END $$;

COMMIT;
