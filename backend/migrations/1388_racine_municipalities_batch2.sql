-- 1388_racine_municipalities_batch2.sql
-- 8 more Racine County municipalities (43 officials), following the 1386/1387 pattern.
-- Brings municipal coverage to 11 of 17. GENERATED -- regenerate, do not hand-edit.
-- STRUCTURAL. Idempotent.
--
-- PRECONDITION: WI place + cousub geofences loaded (607 G4110 + 1243 G4040).
--   The 5 villages here use their G4110 place geo_id; the 3 TOWNS use their G4040 cousub
--   geo_id because towns have no place row at all. Never attach one municipality to both --
--   that double-matches an address and duplicates every official.
--
-- Each municipality: 1 government + 2 chambers (executive + legislative body) + 2 districts
--   (LOCAL_EXEC + LOCAL on the same geo_id) + officials + offices. Members surface
--   municipality-wide; none of these publish ward geometry.
--
-- SOURCES -- every roster read from the municipality's OWN live page (dates 2026-07-25):
--   Village of Sturtevant      sturtevant-wi.gov/villageboard/page/village-board-members
--   Village of Waterford       waterfordwi.gov/171/Village-Board-of-Trustees
--   Village of Rochester       rochesterwi.gov/village-board/
--   Village of Yorkville       villageofyorkville.com/government/elected-and-appointed-officials/town-and-board-plan-commission/
--   Village of North Bay       northbay-wi.us/contacts/
--   Town of Norway             townofnorwaywi.gov/government/elected_officials.php
--   Town of Dover              townofdoverwi.com/town-board-other-important-contacts/
--   Town of Burlington         townofburlingtonwi.gov/town-board/
--
-- !! 6 of the 17 municipalities are DELIBERATELY ABSENT because their rosters could not be
--    verified. Seeding a guess into a voter-facing product is worse than an absent body:
--      Caledonia (~25k)  -- roster rendered by a Munibit <mwjspeople-obj> component; absent
--                           from static HTML, innerText and network XHR alike
--      Raymond           -- same dynamic-component problem
--      Union Grove       -- directory still shows 2024-2026 terms for trustees 2/4/6, i.e.
--                           not updated after the April 2026 election (a trustee was also
--                           appointed mid-term in Aug 2025 to a seat expiring April 2026)
--      Elmwood Park      -- page shows terms expiring 2025; name variants across sources
--      Wind Point        -- official page lists SURNAMES ONLY (McCulloch, Gaspero, Fox,
--                           Johnson, Hall, Manning, Westfall); the only full-name source is a
--                           2016 page naming a completely different board
--      Waterford (town)  -- tn.waterford.wi.gov fails the TLS handshake and browser
--                           navigation is denied
--
-- LESSON, learned the hard way in 1387 and reconfirmed here: NEVER seed a municipal roster
--   from a web-search summary. Search was materially stale for Sturtevant (3 of 6 trustees
--   wrong), Waterford village (listed a vacancy that no longer exists) and Burlington city.
--   Always read the municipality's own page and prefer terms spanning 2026-2028.
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

-- ═══════════════  VILLAGE OF STURTEVANT  (G4110 5577925)  ═══════════════
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'Village of Sturtevant, Wisconsin, US', 'Village', 'WI', 'Sturtevant', '5577925'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'Village of Sturtevant, Wisconsin, US');
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Village President', 'Village of Sturtevant Village President',
       (SELECT id FROM essentials.governments WHERE name = 'Village of Sturtevant, Wisconsin, US'), 1
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Village President'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Sturtevant, Wisconsin, US'));
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Village Board', 'Village of Sturtevant Village Board',
       (SELECT id FROM essentials.governments WHERE name = 'Village of Sturtevant, Wisconsin, US'), 6
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Village Board'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Sturtevant, Wisconsin, US'));
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5577925', 'Village of Sturtevant', 'LOCAL_EXEC', 'wi', 'G4110', 1
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5577925' AND mtfcc='G4110')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5577925' AND district_type='LOCAL_EXEC' AND mtfcc='G4110');
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5577925', 'Village of Sturtevant', 'LOCAL', 'wi', 'G4110', 6
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5577925' AND mtfcc='G4110')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5577925' AND district_type='LOCAL' AND mtfcc='G4110');
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, is_active, is_incumbent, is_appointed, is_vacant)
SELECT v.external_id, v.full_name, v.first_name, v.last_name, true, true, false, false
FROM (VALUES
    (-5514001::bigint, 'Mike Rosenbaum'::text, 'Mike'::text, 'Rosenbaum'::text),
    (-5514002, 'Walter Davis', 'Walter', 'Davis'),
    (-5514003, 'Jason Ingle', 'Jason', 'Ingle'),
    (-5514004, 'Ryan Nelson', 'Ryan', 'Nelson'),
    (-5514005, 'Janet Ruffolo', 'Janet', 'Ruffolo'),
    (-5514006, 'Kari Villalpando', 'Kari', 'Villalpando'),
    (-5514007, 'Brittany Welch', 'Brittany', 'Welch')
  ) AS v(external_id, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id);
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, 'Village President', 'WI', 'Sturtevant', false, false, 1
FROM essentials.districts d
JOIN essentials.chambers c ON c.name = 'Village President'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Sturtevant, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = -5514001
WHERE d.geo_id = '5577925' AND d.district_type = 'LOCAL_EXEC' AND d.mtfcc = 'G4110' AND d.state = 'wi'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id);
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, v.title, 'WI', 'Sturtevant', false, false, 1
FROM (VALUES
    (-5514002::bigint, 'Village Trustee'::text),
    (-5514003, 'Village Trustee'),
    (-5514004, 'Village Trustee'),
    (-5514005, 'Village Trustee'),
    (-5514006, 'Village Trustee'),
    (-5514007, 'Village Trustee')
  ) AS v(external_id, title)
JOIN essentials.districts d
  ON d.geo_id = '5577925' AND d.district_type = 'LOCAL' AND d.mtfcc = 'G4110' AND d.state = 'wi'
JOIN essentials.chambers c ON c.name = 'Village Board'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Sturtevant, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id);

-- ═══════════════  VILLAGE OF WATERFORD  (G4110 5583825)  ═══════════════
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'Village of Waterford, Wisconsin, US', 'Village', 'WI', 'Waterford', '5583825'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'Village of Waterford, Wisconsin, US');
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Village President', 'Village of Waterford Village President',
       (SELECT id FROM essentials.governments WHERE name = 'Village of Waterford, Wisconsin, US'), 1
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Village President'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Waterford, Wisconsin, US'));
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Village Board', 'Village of Waterford Village Board',
       (SELECT id FROM essentials.governments WHERE name = 'Village of Waterford, Wisconsin, US'), 6
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Village Board'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Waterford, Wisconsin, US'));
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5583825', 'Village of Waterford', 'LOCAL_EXEC', 'wi', 'G4110', 1
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5583825' AND mtfcc='G4110')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5583825' AND district_type='LOCAL_EXEC' AND mtfcc='G4110');
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5583825', 'Village of Waterford', 'LOCAL', 'wi', 'G4110', 6
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5583825' AND mtfcc='G4110')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5583825' AND district_type='LOCAL' AND mtfcc='G4110');
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, is_active, is_incumbent, is_appointed, is_vacant)
SELECT v.external_id, v.full_name, v.first_name, v.last_name, true, true, false, false
FROM (VALUES
    (-5515001::bigint, 'Adam Jaskie'::text, 'Adam'::text, 'Jaskie'::text),
    (-5515002, 'Kelli Dunham', 'Kelli', 'Dunham'),
    (-5515003, 'Troy McReynolds', 'Troy', 'McReynolds'),
    (-5515004, 'Tamara Pollnow', 'Tamara', 'Pollnow'),
    (-5515005, 'Robert Nash', 'Robert', 'Nash'),
    (-5515006, 'Pat Goldammer', 'Pat', 'Goldammer'),
    (-5515007, 'John Todryk', 'John', 'Todryk')
  ) AS v(external_id, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id);
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, 'Village President', 'WI', 'Waterford', false, false, 1
FROM essentials.districts d
JOIN essentials.chambers c ON c.name = 'Village President'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Waterford, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = -5515001
WHERE d.geo_id = '5583825' AND d.district_type = 'LOCAL_EXEC' AND d.mtfcc = 'G4110' AND d.state = 'wi'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id);
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, v.title, 'WI', 'Waterford', false, false, 1
FROM (VALUES
    (-5515002::bigint, 'Village Trustee'::text),
    (-5515003, 'Village Trustee'),
    (-5515004, 'Village Trustee'),
    (-5515005, 'Village Trustee'),
    (-5515006, 'Village Trustee'),
    (-5515007, 'Village Trustee')
  ) AS v(external_id, title)
JOIN essentials.districts d
  ON d.geo_id = '5583825' AND d.district_type = 'LOCAL' AND d.mtfcc = 'G4110' AND d.state = 'wi'
JOIN essentials.chambers c ON c.name = 'Village Board'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Waterford, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id);

-- ═══════════════  VILLAGE OF ROCHESTER  (G4110 5568550)  ═══════════════
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'Village of Rochester, Wisconsin, US', 'Village', 'WI', 'Rochester', '5568550'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'Village of Rochester, Wisconsin, US');
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Village President', 'Village of Rochester Village President',
       (SELECT id FROM essentials.governments WHERE name = 'Village of Rochester, Wisconsin, US'), 1
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Village President'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Rochester, Wisconsin, US'));
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Village Board', 'Village of Rochester Village Board',
       (SELECT id FROM essentials.governments WHERE name = 'Village of Rochester, Wisconsin, US'), 6
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Village Board'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Rochester, Wisconsin, US'));
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5568550', 'Village of Rochester', 'LOCAL_EXEC', 'wi', 'G4110', 1
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5568550' AND mtfcc='G4110')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5568550' AND district_type='LOCAL_EXEC' AND mtfcc='G4110');
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5568550', 'Village of Rochester', 'LOCAL', 'wi', 'G4110', 6
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5568550' AND mtfcc='G4110')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5568550' AND district_type='LOCAL' AND mtfcc='G4110');
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, is_active, is_incumbent, is_appointed, is_vacant)
SELECT v.external_id, v.full_name, v.first_name, v.last_name, true, true, false, false
FROM (VALUES
    (-5516001::bigint, 'Nick Ahlers'::text, 'Nick'::text, 'Ahlers'::text),
    (-5516002, 'Pat Nannemann', 'Pat', 'Nannemann'),
    (-5516003, 'Gary Beck, Jr.', 'Gary', 'Beck'),
    (-5516004, 'Russ Kumbier', 'Russ', 'Kumbier'),
    (-5516005, 'Adam Schaefer', 'Adam', 'Schaefer'),
    (-5516006, 'Jeff Sterling', 'Jeff', 'Sterling'),
    (-5516007, 'Doug Webb', 'Doug', 'Webb')
  ) AS v(external_id, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id);
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, 'Village President', 'WI', 'Rochester', false, false, 1
FROM essentials.districts d
JOIN essentials.chambers c ON c.name = 'Village President'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Rochester, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = -5516001
WHERE d.geo_id = '5568550' AND d.district_type = 'LOCAL_EXEC' AND d.mtfcc = 'G4110' AND d.state = 'wi'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id);
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, v.title, 'WI', 'Rochester', false, false, 1
FROM (VALUES
    (-5516002::bigint, 'Village Trustee'::text),
    (-5516003, 'Village Trustee'),
    (-5516004, 'Village Trustee'),
    (-5516005, 'Village Trustee'),
    (-5516006, 'Village Trustee'),
    (-5516007, 'Village Trustee')
  ) AS v(external_id, title)
JOIN essentials.districts d
  ON d.geo_id = '5568550' AND d.district_type = 'LOCAL' AND d.mtfcc = 'G4110' AND d.state = 'wi'
JOIN essentials.chambers c ON c.name = 'Village Board'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Rochester, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id);

-- ═══════════════  VILLAGE OF YORKVILLE  (G4110 5589550)  ═══════════════
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'Village of Yorkville, Wisconsin, US', 'Village', 'WI', 'Yorkville', '5589550'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'Village of Yorkville, Wisconsin, US');
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Village President', 'Village of Yorkville Village President',
       (SELECT id FROM essentials.governments WHERE name = 'Village of Yorkville, Wisconsin, US'), 1
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Village President'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Yorkville, Wisconsin, US'));
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Village Board', 'Village of Yorkville Village Board',
       (SELECT id FROM essentials.governments WHERE name = 'Village of Yorkville, Wisconsin, US'), 4
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Village Board'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Yorkville, Wisconsin, US'));
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5589550', 'Village of Yorkville', 'LOCAL_EXEC', 'wi', 'G4110', 1
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5589550' AND mtfcc='G4110')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5589550' AND district_type='LOCAL_EXEC' AND mtfcc='G4110');
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5589550', 'Village of Yorkville', 'LOCAL', 'wi', 'G4110', 4
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5589550' AND mtfcc='G4110')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5589550' AND district_type='LOCAL' AND mtfcc='G4110');
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, is_active, is_incumbent, is_appointed, is_vacant)
SELECT v.external_id, v.full_name, v.first_name, v.last_name, true, true, false, false
FROM (VALUES
    (-5517001::bigint, 'Douglas Nelson'::text, 'Douglas'::text, 'Nelson'::text),
    (-5517002, 'Cory Bartlett', 'Cory', 'Bartlett'),
    (-5517003, 'Robert Funk', 'Robert', 'Funk'),
    (-5517004, 'Daniel Maurice', 'Daniel', 'Maurice'),
    (-5517005, 'Steve Nelson', 'Steve', 'Nelson')
  ) AS v(external_id, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id);
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, 'Village President', 'WI', 'Yorkville', false, false, 1
FROM essentials.districts d
JOIN essentials.chambers c ON c.name = 'Village President'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Yorkville, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = -5517001
WHERE d.geo_id = '5589550' AND d.district_type = 'LOCAL_EXEC' AND d.mtfcc = 'G4110' AND d.state = 'wi'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id);
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, v.title, 'WI', 'Yorkville', false, false, 1
FROM (VALUES
    (-5517002::bigint, 'Village Trustee'::text),
    (-5517003, 'Village Trustee'),
    (-5517004, 'Village Trustee'),
    (-5517005, 'Village Trustee')
  ) AS v(external_id, title)
JOIN essentials.districts d
  ON d.geo_id = '5589550' AND d.district_type = 'LOCAL' AND d.mtfcc = 'G4110' AND d.state = 'wi'
JOIN essentials.chambers c ON c.name = 'Village Board'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of Yorkville, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id);

-- ═══════════════  VILLAGE OF NORTH BAY  (G4110 5557700)  ═══════════════
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'Village of North Bay, Wisconsin, US', 'Village', 'WI', 'North Bay', '5557700'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'Village of North Bay, Wisconsin, US');
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Village President', 'Village of North Bay Village President',
       (SELECT id FROM essentials.governments WHERE name = 'Village of North Bay, Wisconsin, US'), 1
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Village President'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of North Bay, Wisconsin, US'));
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Village Board', 'Village of North Bay Village Board',
       (SELECT id FROM essentials.governments WHERE name = 'Village of North Bay, Wisconsin, US'), 3
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Village Board'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of North Bay, Wisconsin, US'));
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5557700', 'Village of North Bay', 'LOCAL_EXEC', 'wi', 'G4110', 1
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5557700' AND mtfcc='G4110')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5557700' AND district_type='LOCAL_EXEC' AND mtfcc='G4110');
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5557700', 'Village of North Bay', 'LOCAL', 'wi', 'G4110', 3
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5557700' AND mtfcc='G4110')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5557700' AND district_type='LOCAL' AND mtfcc='G4110');
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, is_active, is_incumbent, is_appointed, is_vacant)
SELECT v.external_id, v.full_name, v.first_name, v.last_name, true, true, false, false
FROM (VALUES
    (-5518001::bigint, 'Roger Mellem'::text, 'Roger'::text, 'Mellem'::text),
    (-5518002, 'Paul Schroeder', 'Paul', 'Schroeder'),
    (-5518003, 'Rick Cermak', 'Rick', 'Cermak'),
    (-5518004, 'Rocco Castellano', 'Rocco', 'Castellano')
  ) AS v(external_id, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id);
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, 'Village President', 'WI', 'North Bay', false, false, 1
FROM essentials.districts d
JOIN essentials.chambers c ON c.name = 'Village President'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of North Bay, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = -5518001
WHERE d.geo_id = '5557700' AND d.district_type = 'LOCAL_EXEC' AND d.mtfcc = 'G4110' AND d.state = 'wi'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id);
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, v.title, 'WI', 'North Bay', false, false, 1
FROM (VALUES
    (-5518002::bigint, 'Village Trustee, Seat 1'::text),
    (-5518003, 'Village Trustee, Seat 2'),
    (-5518004, 'Village Trustee, Seat 3')
  ) AS v(external_id, title)
JOIN essentials.districts d
  ON d.geo_id = '5557700' AND d.district_type = 'LOCAL' AND d.mtfcc = 'G4110' AND d.state = 'wi'
JOIN essentials.chambers c ON c.name = 'Village Board'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Village of North Bay, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id);

-- ═══════════════  TOWN OF NORWAY  (G4040 5510158600)  ═══════════════
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'Town of Norway, Wisconsin, US', 'Town', 'WI', 'Norway', '5510158600'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'Town of Norway, Wisconsin, US');
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Town Chairperson', 'Town of Norway Town Chairperson',
       (SELECT id FROM essentials.governments WHERE name = 'Town of Norway, Wisconsin, US'), 1
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Town Chairperson'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Town of Norway, Wisconsin, US'));
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Town Board', 'Town of Norway Town Board',
       (SELECT id FROM essentials.governments WHERE name = 'Town of Norway, Wisconsin, US'), 4
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Town Board'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Town of Norway, Wisconsin, US'));
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5510158600', 'Town of Norway', 'LOCAL_EXEC', 'wi', 'G4040', 1
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5510158600' AND mtfcc='G4040')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5510158600' AND district_type='LOCAL_EXEC' AND mtfcc='G4040');
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5510158600', 'Town of Norway', 'LOCAL', 'wi', 'G4040', 4
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5510158600' AND mtfcc='G4040')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5510158600' AND district_type='LOCAL' AND mtfcc='G4040');
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, is_active, is_incumbent, is_appointed, is_vacant)
SELECT v.external_id, v.full_name, v.first_name, v.last_name, true, true, false, false
FROM (VALUES
    (-5519001::bigint, 'Jean Jacobson'::text, 'Jean'::text, 'Jacobson'::text),
    (-5519002, 'Robert Helback', 'Robert', 'Helback'),
    (-5519003, 'Timothy Hansen', 'Timothy', 'Hansen'),
    (-5519004, 'Michael Lyman', 'Michael', 'Lyman'),
    (-5519005, 'Ralph Schopp', 'Ralph', 'Schopp')
  ) AS v(external_id, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id);
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, 'Town Chairperson', 'WI', 'Norway', false, false, 1
FROM essentials.districts d
JOIN essentials.chambers c ON c.name = 'Town Chairperson'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Town of Norway, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = -5519001
WHERE d.geo_id = '5510158600' AND d.district_type = 'LOCAL_EXEC' AND d.mtfcc = 'G4040' AND d.state = 'wi'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id);
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, v.title, 'WI', 'Norway', false, false, 1
FROM (VALUES
    (-5519002::bigint, 'Town Supervisor'::text),
    (-5519003, 'Town Supervisor'),
    (-5519004, 'Town Supervisor'),
    (-5519005, 'Town Supervisor')
  ) AS v(external_id, title)
JOIN essentials.districts d
  ON d.geo_id = '5510158600' AND d.district_type = 'LOCAL' AND d.mtfcc = 'G4040' AND d.state = 'wi'
JOIN essentials.chambers c ON c.name = 'Town Board'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Town of Norway, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id);

-- ═══════════════  TOWN OF DOVER  (G4040 5510120625)  ═══════════════
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'Town of Dover, Wisconsin, US', 'Town', 'WI', 'Dover', '5510120625'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'Town of Dover, Wisconsin, US');
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Town Chairperson', 'Town of Dover Town Chairperson',
       (SELECT id FROM essentials.governments WHERE name = 'Town of Dover, Wisconsin, US'), 1
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Town Chairperson'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Town of Dover, Wisconsin, US'));
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Town Board', 'Town of Dover Town Board',
       (SELECT id FROM essentials.governments WHERE name = 'Town of Dover, Wisconsin, US'), 2
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Town Board'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Town of Dover, Wisconsin, US'));
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5510120625', 'Town of Dover', 'LOCAL_EXEC', 'wi', 'G4040', 1
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5510120625' AND mtfcc='G4040')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5510120625' AND district_type='LOCAL_EXEC' AND mtfcc='G4040');
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5510120625', 'Town of Dover', 'LOCAL', 'wi', 'G4040', 2
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5510120625' AND mtfcc='G4040')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5510120625' AND district_type='LOCAL' AND mtfcc='G4040');
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, is_active, is_incumbent, is_appointed, is_vacant)
SELECT v.external_id, v.full_name, v.first_name, v.last_name, true, true, false, false
FROM (VALUES
    (-5520001::bigint, 'Sam Stratton'::text, 'Sam'::text, 'Stratton'::text),
    (-5520002, 'Mike Shenkenberg', 'Mike', 'Shenkenberg'),
    (-5520003, 'Jared Guillien', 'Jared', 'Guillien')
  ) AS v(external_id, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id);
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, 'Town Chairperson', 'WI', 'Dover', false, false, 1
FROM essentials.districts d
JOIN essentials.chambers c ON c.name = 'Town Chairperson'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Town of Dover, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = -5520001
WHERE d.geo_id = '5510120625' AND d.district_type = 'LOCAL_EXEC' AND d.mtfcc = 'G4040' AND d.state = 'wi'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id);
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, v.title, 'WI', 'Dover', false, false, 1
FROM (VALUES
    (-5520002::bigint, 'Town Supervisor, Seat 1'::text),
    (-5520003, 'Town Supervisor, Seat 2')
  ) AS v(external_id, title)
JOIN essentials.districts d
  ON d.geo_id = '5510120625' AND d.district_type = 'LOCAL' AND d.mtfcc = 'G4040' AND d.state = 'wi'
JOIN essentials.chambers c ON c.name = 'Town Board'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Town of Dover, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id);

-- ═══════════════  TOWN OF BURLINGTON  (G4040 5510111225)  ═══════════════
INSERT INTO essentials.governments (id, name, type, state, city, geo_id)
SELECT gen_random_uuid(), 'Town of Burlington, Wisconsin, US', 'Town', 'WI', 'Burlington', '5510111225'
WHERE NOT EXISTS (SELECT 1 FROM essentials.governments WHERE name = 'Town of Burlington, Wisconsin, US');
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Town Chairperson', 'Town of Burlington Town Chairperson',
       (SELECT id FROM essentials.governments WHERE name = 'Town of Burlington, Wisconsin, US'), 1
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Town Chairperson'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Town of Burlington, Wisconsin, US'));
INSERT INTO essentials.chambers (id, name, name_formal, government_id, official_count)
SELECT gen_random_uuid(), 'Town Board', 'Town of Burlington Town Board',
       (SELECT id FROM essentials.governments WHERE name = 'Town of Burlington, Wisconsin, US'), 4
WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers WHERE name = 'Town Board'
   AND government_id = (SELECT id FROM essentials.governments WHERE name = 'Town of Burlington, Wisconsin, US'));
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5510111225', 'Town of Burlington', 'LOCAL_EXEC', 'wi', 'G4040', 1
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5510111225' AND mtfcc='G4040')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5510111225' AND district_type='LOCAL_EXEC' AND mtfcc='G4040');
INSERT INTO essentials.districts (geo_id, label, district_type, state, mtfcc, num_officials)
SELECT '5510111225', 'Town of Burlington', 'LOCAL', 'wi', 'G4040', 4
WHERE EXISTS (SELECT 1 FROM essentials.geofence_boundaries WHERE geo_id='5510111225' AND mtfcc='G4040')
  AND NOT EXISTS (SELECT 1 FROM essentials.districts
                   WHERE geo_id='5510111225' AND district_type='LOCAL' AND mtfcc='G4040');
INSERT INTO essentials.politicians
  (external_id, full_name, first_name, last_name, is_active, is_incumbent, is_appointed, is_vacant)
SELECT v.external_id, v.full_name, v.first_name, v.last_name, true, true, false, false
FROM (VALUES
    (-5521001::bigint, 'Neal Czaplewski'::text, 'Neal'::text, 'Czaplewski'::text),
    (-5521002, 'Jeff Rice', 'Jeff', 'Rice'),
    (-5521003, 'Steve Swantz', 'Steve', 'Swantz'),
    (-5521004, 'Jason Ketterhagen', 'Jason', 'Ketterhagen'),
    (-5521005, 'Paul Kobernick', 'Paul', 'Kobernick')
  ) AS v(external_id, full_name, first_name, last_name)
WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.external_id = v.external_id);
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, 'Town Chairperson', 'WI', 'Burlington', false, false, 1
FROM essentials.districts d
JOIN essentials.chambers c ON c.name = 'Town Chairperson'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Town of Burlington, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = -5521001
WHERE d.geo_id = '5510111225' AND d.district_type = 'LOCAL_EXEC' AND d.mtfcc = 'G4040' AND d.state = 'wi'
  AND NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id);
INSERT INTO essentials.offices
  (district_id, chamber_id, politician_id, title, representing_state, representing_city,
   is_appointed_position, is_vacant, seats)
SELECT d.id, c.id, p.id, v.title, 'WI', 'Burlington', false, false, 1
FROM (VALUES
    (-5521002::bigint, 'Town Supervisor, Seat 1'::text),
    (-5521003, 'Town Supervisor, Seat 2'),
    (-5521004, 'Town Supervisor, Seat 3'),
    (-5521005, 'Town Supervisor, Seat 4')
  ) AS v(external_id, title)
JOIN essentials.districts d
  ON d.geo_id = '5510111225' AND d.district_type = 'LOCAL' AND d.mtfcc = 'G4040' AND d.state = 'wi'
JOIN essentials.chambers c ON c.name = 'Town Board'
 AND c.government_id = (SELECT id FROM essentials.governments WHERE name = 'Town of Burlington, Wisconsin, US')
JOIN essentials.politicians p ON p.external_id = v.external_id
WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o
                   WHERE o.district_id=d.id AND o.chamber_id=c.id AND o.politician_id=p.id);

-- ── Post-verify gate ──
DO $$
DECLARE r record; n int; n_party int; n_orph int;
BEGIN
  FOR r IN SELECT * FROM (VALUES
    ('Village of Sturtevant, Wisconsin, US', 7),
    ('Village of Waterford, Wisconsin, US', 7),
    ('Village of Rochester, Wisconsin, US', 7),
    ('Village of Yorkville, Wisconsin, US', 5),
    ('Village of North Bay, Wisconsin, US', 4),
    ('Town of Norway, Wisconsin, US', 5),
    ('Town of Dover, Wisconsin, US', 3),
    ('Town of Burlington, Wisconsin, US', 5)
  ) AS t(gname, want) LOOP
    SELECT count(*) INTO n FROM essentials.offices o
      JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE c.government_id = (SELECT id FROM essentials.governments WHERE name = r.gname);
    IF n <> r.want THEN
      RAISE EXCEPTION '% offices: got %, want % (are the WI place/cousub geofences loaded?)', r.gname, n, r.want;
    END IF;
  END LOOP;

  SELECT count(*) INTO n_orph FROM essentials.politicians p
   WHERE p.external_id BETWEEN -5521999 AND -5514001
     AND NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.politician_id = p.id);
  IF n_orph <> 0 THEN RAISE EXCEPTION '% batch-2 officials hold no office', n_orph; END IF;

  SELECT count(*) INTO n_party FROM essentials.politicians
   WHERE external_id BETWEEN -5521999 AND -5514001 AND party IS NOT NULL;
  IF n_party <> 0 THEN RAISE EXCEPTION '% carry a party on a nonpartisan municipal office', n_party; END IF;

  RAISE NOTICE 'Racine municipalities batch 2 verify PASSED: 8 municipalities, 43 officials, 0 orphans.';
END $$;

COMMIT;
