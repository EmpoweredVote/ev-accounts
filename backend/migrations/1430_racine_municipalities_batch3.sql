-- 1430_racine_municipalities_batch3.sql
-- 4 more Racine County municipalities (24 officials), following the 1424/1425/1426 pattern.
-- Brings municipal coverage to 15 of 17. GENERATED -- regenerate, do not hand-edit.
-- STRUCTURAL. Idempotent.
--
-- PRECONDITION: WI place + cousub geofences loaded (607 G4110 + 1243 G4040).
--   The 3 villages here use their G4110 place geo_id; the Town of Waterford uses its G4040
--   cousub geo_id because towns have no place row at all. Never attach one municipality to
--   both -- that double-matches an address and duplicates every official.
--
-- Each municipality: 1 government + 2 chambers (executive + legislative body) + 2 districts
--   (LOCAL_EXEC + LOCAL on the same geo_id) + officials + offices. Members surface
--   municipality-wide; none of these publish ward geometry.
--
-- SOURCES (all 2026-07-25). These four were UNBLOCKED by URLs the user supplied -- three of
--   them are hosts/paths that earlier attempts never reached, which is why the batch-2 header
--   listed them as unverifiable:
--   Village of Wind Point    windpoint.org/government/village_board.php
--       The path matters: /government/board_committees.php gives SURNAMES ONLY. This page has
--       full names and current terms, and its surnames agree with that page exactly.
--   Village of Elmwood Park  elmwoodparkwi.gov/1197/Board-of-Trustees
--       A DIFFERENT DOMAIN from the vil.ep.wi.us page used earlier, which was stale: it showed
--       terms expiring 2025 and listed "Lynda Studey" where the current board has MATT SEIVERT.
--   Town of Waterford        tn.waterford.wi.gov/town-board
--       403s on plain fetch and the host failed a TLS handshake earlier; readable via browser.
--       Note /administration lists only appointed staff (clerk/treasurer) -- not the board.
--   Village of Raymond       raymondwi.com/board
--       Roster is rendered by the same dynamic component that defeats Caledonia. Transcribed
--       from a screenshot of the live page supplied by the user -- the ONLY row in this
--       migration not machine-read. It also corrects search, which had "Keith Kastenson" as
--       Trustee #3 where the live page shows RICHARD PAAP.
--
-- !! STILL ABSENT -- 2 of the 17, deliberately. Seeding a guess into a voter-facing product is
--    worse than an absent body:
--      Caledonia (~25k)  -- 6 of 7 seats known from a user screenshot (President Prescott
--                           Balch; Trustees 1 Nancy Pierce, 3 Michael Lambrecht, 4 Fran
--                           Martin, 5 Holly McManus, 6 Lee Wishau) but TRUSTEE 2 is not shown
--                           and the page will not render for automated access. A 6-of-7 board
--                           would misrepresent the body, so Caledonia waits for that one seat.
--      Union Grove       -- directory still shows expired 2024-2026 terms for trustees 2/4/6,
--                           i.e. not updated after the April 2026 election (a trustee was also
--                           appointed mid-term in Aug 2025 to a seat expiring April 2026).
--                           The president + trustees 1/3/5 (2025-2027) are current, but a
--                           partial 7-member board is the same misrepresentation problem.
--
-- LESSON, reconfirmed twice more here: NEVER seed a municipal roster from a web-search summary,
--   and never trust a municipal domain without checking it is the CURRENT one. Search or a
--   stale host was wrong for Sturtevant (3 of 6 trustees), Burlington city (2 of 8), Waterford
--   village (a phantom vacancy), Raymond (Trustee #3) and Elmwood Park (a trustee + all terms).
--
-- GUARD CHOICE: every legislative body here uses the (district_id, chamber_id, politician_id)
--   collegial guard rather than a title guard. Most of these boards do NOT number their
--   seats, so titles legitimately repeat ("Village Trustee" x6) and a title guard would
--   silently no-op all but the first member. Seat numbers are preserved in the title only
--   where the source actually published them (North Bay, Dover, Burlington town).
--
-- ANTIPARTISAN: Wisconsin municipal offices are genuinely nonpartisan -- party is NULL
--   throughout, a matter of fact here rather than only a display rule.
--
-- North Bay note: its contact page calls the Clerk and Treasurer "elected administrative
--   positions" but lists only the President + 3 Trustees under "Executive Board (Elected
--   Officials)". Only the 4 unambiguous board seats are seeded.
--
-- No races: municipal races are filed with the MUNICIPAL clerk and the April 2026 spring
--   election has already passed.
BEGIN;

-- ═══════════════  VILLAGE OF RAYMOND  (G4110 5566350)  ═══════════════
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'Village of Raymond, Wisconsin, US', 'Village', 'WI', 'Raymond', '5566350'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'Village of Raymond, Wisconsin, US');
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Village President', 'Village of Raymond Village President',
       (SELECT id FROM essentials.governments WHERE name = 'Village of Raymond, Wisconsin, US'), 1
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Village President'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Raymond, Wisconsin, US'));
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Village Board', 'Village of Raymond Village Board',
       (SELECT id FROM essentials.governments WHERE name = 'Village of Raymond, Wisconsin, US'), 4
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Village Board'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Raymond, Wisconsin, US'));
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5566350', 'Village of Raymond', 'LOCAL_EXEC', 'wi', 'G4110', 1
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5566350' AND mtfcc='G4110')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5566350' AND district_type='LOCAL_EXEC' AND mtfcc='G4110');
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5566350', 'Village of Raymond', 'LOCAL', 'wi', 'G4110', 4
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5566350' AND mtfcc='G4110')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5566350' AND district_type='LOCAL' AND mtfcc='G4110');
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, is_active, is_incumbent, is_appointed, is_vacant)
SELECT v.external_id, v.full_name, v.first_name, v.last_name, true, true, false, false
FROM (VALUES
    (-5522001::bigint, 'Douglas White'::text, 'Douglas'::text, 'White'::text),
    (-5522002, 'Mike Thelen', 'Mike', 'Thelen'),
    (-5522003, 'Mark Gelhaus', 'Mark', 'Gelhaus'),
    (-5522004, 'Richard Paap', 'Richard', 'Paap'),
    (-5522005, 'Doug Schwartz', 'Doug', 'Schwartz')
  ) AS v(external_id, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id);
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, 'Village President', 'WI', 'Raymond', false, false, 1
FROM essentials.districts d
JOIN essentials.chambers c ON c.name = 'Village President'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Raymond, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = -5522001
WHERE d.geo_id = '5566350' AND d.district_type = 'LOCAL_EXEC' AND d.mtfcc = 'G4110' AND d.state = 'wi'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id);
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, v.title, 'WI', 'Raymond', false, false, 1
FROM (VALUES
    (-5522002::bigint, 'Village Trustee, Seat 1'::text),
    (-5522003, 'Village Trustee, Seat 2'),
    (-5522004, 'Village Trustee, Seat 3'),
    (-5522005, 'Village Trustee, Seat 4')
  ) AS v(external_id, title)
JOIN essentials.districts d
  ON d.geo_id = '5566350' AND d.district_type = 'LOCAL' AND d.mtfcc = 'G4110' AND d.state = 'wi'
JOIN essentials.chambers c ON c.name = 'Village Board'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Raymond, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id);

-- ═══════════════  VILLAGE OF WIND POINT  (G4110 5587700)  ═══════════════
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'Village of Wind Point, Wisconsin, US', 'Village', 'WI', 'Wind Point', '5587700'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'Village of Wind Point, Wisconsin, US');
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Village President', 'Village of Wind Point Village President',
       (SELECT id FROM essentials.governments WHERE name = 'Village of Wind Point, Wisconsin, US'), 1
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Village President'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Wind Point, Wisconsin, US'));
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Village Board', 'Village of Wind Point Village Board',
       (SELECT id FROM essentials.governments WHERE name = 'Village of Wind Point, Wisconsin, US'), 6
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Village Board'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Wind Point, Wisconsin, US'));
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5587700', 'Village of Wind Point', 'LOCAL_EXEC', 'wi', 'G4110', 1
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5587700' AND mtfcc='G4110')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5587700' AND district_type='LOCAL_EXEC' AND mtfcc='G4110');
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5587700', 'Village of Wind Point', 'LOCAL', 'wi', 'G4110', 6
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5587700' AND mtfcc='G4110')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5587700' AND district_type='LOCAL' AND mtfcc='G4110');
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, is_active, is_incumbent, is_appointed, is_vacant)
SELECT v.external_id, v.full_name, v.first_name, v.last_name, true, true, false, false
FROM (VALUES
    (-5523001::bigint, 'Alison McCulloch'::text, 'Alison'::text, 'McCulloch'::text),
    (-5523002, 'Carmen Gaspero', 'Carmen', 'Gaspero'),
    (-5523003, 'Mary Kay Hall', 'Mary', 'Hall'),
    (-5523004, 'Linda Johnson', 'Linda', 'Johnson'),
    (-5523005, 'Michael Fox', 'Michael', 'Fox'),
    (-5523006, 'Charlie Manning', 'Charlie', 'Manning'),
    (-5523007, 'James Westfall', 'James', 'Westfall')
  ) AS v(external_id, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id);
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, 'Village President', 'WI', 'Wind Point', false, false, 1
FROM essentials.districts d
JOIN essentials.chambers c ON c.name = 'Village President'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Wind Point, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = -5523001
WHERE d.geo_id = '5587700' AND d.district_type = 'LOCAL_EXEC' AND d.mtfcc = 'G4110' AND d.state = 'wi'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id);
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, v.title, 'WI', 'Wind Point', false, false, 1
FROM (VALUES
    (-5523002::bigint, 'Village Trustee'::text),
    (-5523003, 'Village Trustee'),
    (-5523004, 'Village Trustee'),
    (-5523005, 'Village Trustee'),
    (-5523006, 'Village Trustee'),
    (-5523007, 'Village Trustee')
  ) AS v(external_id, title)
JOIN essentials.districts d
  ON d.geo_id = '5587700' AND d.district_type = 'LOCAL' AND d.mtfcc = 'G4110' AND d.state = 'wi'
JOIN essentials.chambers c ON c.name = 'Village Board'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Wind Point, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id);

-- ═══════════════  VILLAGE OF ELMWOOD PARK  (G4110 5523725)  ═══════════════
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'Village of Elmwood Park, Wisconsin, US', 'Village', 'WI', 'Elmwood Park', '5523725'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'Village of Elmwood Park, Wisconsin, US');
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Village President', 'Village of Elmwood Park Village President',
       (SELECT id FROM essentials.governments WHERE name = 'Village of Elmwood Park, Wisconsin, US'), 1
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Village President'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Elmwood Park, Wisconsin, US'));
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Village Board', 'Village of Elmwood Park Village Board',
       (SELECT id FROM essentials.governments WHERE name = 'Village of Elmwood Park, Wisconsin, US'), 6
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Village Board'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Elmwood Park, Wisconsin, US'));
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5523725', 'Village of Elmwood Park', 'LOCAL_EXEC', 'wi', 'G4110', 1
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5523725' AND mtfcc='G4110')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5523725' AND district_type='LOCAL_EXEC' AND mtfcc='G4110');
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5523725', 'Village of Elmwood Park', 'LOCAL', 'wi', 'G4110', 6
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5523725' AND mtfcc='G4110')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5523725' AND district_type='LOCAL' AND mtfcc='G4110');
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, is_active, is_incumbent, is_appointed, is_vacant)
SELECT v.external_id, v.full_name, v.first_name, v.last_name, true, true, false, false
FROM (VALUES
    (-5524001::bigint, 'Ali Gasser'::text, 'Ali'::text, 'Gasser'::text),
    (-5524002, 'Ken Hinkle', 'Ken', 'Hinkle'),
    (-5524003, 'Brian Johnson', 'Brian', 'Johnson'),
    (-5524004, 'Laura Rude', 'Laura', 'Rude'),
    (-5524005, 'Kelli Stein', 'Kelli', 'Stein'),
    (-5524006, 'Matt Seivert', 'Matt', 'Seivert'),
    (-5524007, 'Barb Witek', 'Barb', 'Witek')
  ) AS v(external_id, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id);
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, 'Village President', 'WI', 'Elmwood Park', false, false, 1
FROM essentials.districts d
JOIN essentials.chambers c ON c.name = 'Village President'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Elmwood Park, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = -5524001
WHERE d.geo_id = '5523725' AND d.district_type = 'LOCAL_EXEC' AND d.mtfcc = 'G4110' AND d.state = 'wi'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id);
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, v.title, 'WI', 'Elmwood Park', false, false, 1
FROM (VALUES
    (-5524002::bigint, 'Village Trustee'::text),
    (-5524003, 'Village Trustee'),
    (-5524004, 'Village Trustee'),
    (-5524005, 'Village Trustee'),
    (-5524006, 'Village Trustee'),
    (-5524007, 'Village Trustee')
  ) AS v(external_id, title)
JOIN essentials.districts d
  ON d.geo_id = '5523725' AND d.district_type = 'LOCAL' AND d.mtfcc = 'G4110' AND d.state = 'wi'
JOIN essentials.chambers c ON c.name = 'Village Board'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Elmwood Park, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id);

-- ═══════════════  TOWN OF WATERFORD  (G4040 5510183850)  ═══════════════
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'Town of Waterford, Wisconsin, US', 'Town', 'WI', 'Waterford', '5510183850'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'Town of Waterford, Wisconsin, US');
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Town Chairperson', 'Town of Waterford Town Chairperson',
       (SELECT id FROM essentials.governments WHERE name = 'Town of Waterford, Wisconsin, US'), 1
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Town Chairperson'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Town of Waterford, Wisconsin, US'));
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Town Board', 'Town of Waterford Town Board',
       (SELECT id FROM essentials.governments WHERE name = 'Town of Waterford, Wisconsin, US'), 4
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Town Board'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Town of Waterford, Wisconsin, US'));
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5510183850', 'Town of Waterford', 'LOCAL_EXEC', 'wi', 'G4040', 1
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5510183850' AND mtfcc='G4040')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5510183850' AND district_type='LOCAL_EXEC' AND mtfcc='G4040');
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5510183850', 'Town of Waterford', 'LOCAL', 'wi', 'G4040', 4
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5510183850' AND mtfcc='G4040')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5510183850' AND district_type='LOCAL' AND mtfcc='G4040');
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, is_active, is_incumbent, is_appointed, is_vacant)
SELECT v.external_id, v.full_name, v.first_name, v.last_name, true, true, false, false
FROM (VALUES
    (-5525001::bigint, 'Tim Szeklinski'::text, 'Tim'::text, 'Szeklinski'::text),
    (-5525002, 'Bill McCormick', 'Bill', 'McCormick'),
    (-5525003, 'Robert Ulander', 'Robert', 'Ulander'),
    (-5525004, 'Andrew Handeland', 'Andrew', 'Handeland'),
    (-5525005, 'Tom Mroczkowski', 'Tom', 'Mroczkowski')
  ) AS v(external_id, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id);
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, 'Town Chairperson', 'WI', 'Waterford', false, false, 1
FROM essentials.districts d
JOIN essentials.chambers c ON c.name = 'Town Chairperson'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Town of Waterford, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = -5525001
WHERE d.geo_id = '5510183850' AND d.district_type = 'LOCAL_EXEC' AND d.mtfcc = 'G4040' AND d.state = 'wi'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id);
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, v.title, 'WI', 'Waterford', false, false, 1
FROM (VALUES
    (-5525002::bigint, 'Town Supervisor'::text),
    (-5525003, 'Town Supervisor'),
    (-5525004, 'Town Supervisor'),
    (-5525005, 'Town Supervisor')
  ) AS v(external_id, title)
JOIN essentials.districts d
  ON d.geo_id = '5510183850' AND d.district_type = 'LOCAL' AND d.mtfcc = 'G4040' AND d.state = 'wi'
JOIN essentials.chambers c ON c.name = 'Town Board'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Town of Waterford, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id);

-- ── Post-verify gate ──
DO $$
DECLARE r record; n int; n_party int; n_orph int;
BEGIN
  FOR r IN SELECT * FROM (VALUES
    ('Village of Raymond, Wisconsin, US', 5),
    ('Village of Wind Point, Wisconsin, US', 7),
    ('Village of Elmwood Park, Wisconsin, US', 7),
    ('Town of Waterford, Wisconsin, US', 5)
  ) AS t(gname, want) LOOP
    SELECT count(*) INTO n FROM essentials.offices o
      JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE c.government_id = (SELECT id FROM essentials.governments WHERE name = r.gname);
    IF n <> r.want THEN
      RAISE EXCEPTION '% offices: got %, want % (are the WI place/cousub geofences loaded?)', r.gname, n, r.want;
    END IF;
  END LOOP;

  SELECT count(*) INTO n_orph FROM essentials.politicians p
   WHERE p.external_id BETWEEN -5525999 AND -5522001
     AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.politician_id = p.id);
  IF n_orph <> 0 THEN RAISE EXCEPTION '% batch-3 officials hold no office', n_orph; END IF;

  SELECT count(*) INTO n_party FROM essentials.politicians
   WHERE external_id BETWEEN -5525999 AND -5522001 AND party IS NOT NULL;
  IF n_party <> 0 THEN RAISE EXCEPTION '% carry a party on a nonpartisan municipal office', n_party; END IF;

  RAISE NOTICE 'Racine municipalities batch 3 verify PASSED: 4 municipalities, 24 officials, 0 orphans.';
END $$;

COMMIT;
