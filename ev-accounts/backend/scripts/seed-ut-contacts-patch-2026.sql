-- =============================================================================
-- PATCH: Utah politician contacts — state exec names + official/campaign websites
--        + county/local official contact info
--
-- Groups covered:
--   1. STATE_EXEC: populate null full_names + add official website contacts
--   2. Federal: add official .gov websites + campaign sites + DC phones
--   3. 2026 primary candidates: add campaign websites (politician_contacts + race_candidates.website_url)
--   4. Cache County: add official department page URLs + email/phone
--   5. Iron County: add official department page URLs + email/phone
--   6. Washington County: add official department page URLs + phone
--   7. Weber County: add official department page URLs + email/phone
--   8. Summit County, Davis County: add official department page URLs + phone
--   9. Local city officials: SLC, Sandy, Layton, West Jordan — email/phone/website
--
-- Sources: official government websites, verified by research agents (2026-06-01)
-- Idempotent: all inserts guarded by WHERE NOT EXISTS (politician_id, contact_type)
-- =============================================================================

BEGIN;

-- =============================================================================
-- SECTION 1: Fix STATE_EXEC null names
-- =============================================================================

UPDATE essentials.politicians
SET full_name = 'Spencer J. Cox', first_name = 'Spencer', last_name = 'Cox', data_source = 'manual'
WHERE id = 'b86213f8-abd8-46e7-80b6-3ae7bd2bf1a6'; -- Utah Governor

UPDATE essentials.politicians
SET full_name = 'Deidre M. Henderson', first_name = 'Deidre', last_name = 'Henderson', data_source = 'manual'
WHERE id = 'f72689da-fe02-4bdd-977f-bb7760a42fb2'; -- Utah Lieutenant Governor

UPDATE essentials.politicians
SET full_name = 'Derek Brown', first_name = 'Derek', last_name = 'Brown', data_source = 'manual'
WHERE id = '1844a5e3-8ea5-4ee5-9377-066378b25b49'; -- Utah Attorney General

UPDATE essentials.politicians
SET full_name = 'Marlo M. Oaks', first_name = 'Marlo', last_name = 'Oaks', data_source = 'manual'
WHERE id = '919b82e8-bac3-428f-9896-423832e4538f'; -- Utah State Treasurer

UPDATE essentials.politicians
SET full_name = 'Tina M. Cannon', first_name = 'Tina', last_name = 'Cannon', data_source = 'manual'
WHERE id = '9eac661a-e4c5-4bdf-9883-ee612dab53a8'; -- Utah State Auditor

-- =============================================================================
-- SECTION 2: STATE_EXEC contacts (official websites + phones)
-- =============================================================================

INSERT INTO essentials.politician_contacts (politician_id, source, contact_type, website_url, phone)
SELECT id, 'manual', 'primary', url, phone FROM (VALUES
  ('b86213f8-abd8-46e7-80b6-3ae7bd2bf1a6'::uuid, 'https://governor.utah.gov',         '801-538-1000'), -- Spencer Cox
  ('f72689da-fe02-4bdd-977f-bb7760a42fb2'::uuid, 'https://ltgovernor.utah.gov',        '801-538-1041'), -- Deidre Henderson
  ('1844a5e3-8ea5-4ee5-9377-066378b25b49'::uuid, 'https://attorneygeneral.utah.gov',   '801-366-0260'), -- Derek Brown
  ('919b82e8-bac3-428f-9896-423832e4538f'::uuid, 'https://treasurer.utah.gov',         '801-538-1042'), -- Marlo Oaks
  ('9eac661a-e4c5-4bdf-9883-ee612dab53a8'::uuid, 'https://auditor.utah.gov',           '801-538-1025')  -- Tina Cannon
) AS v(id, url, phone)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts WHERE politician_id = v.id AND contact_type = 'primary'
);

-- STATE_EXEC emails (AG and Treasurer only — others use web forms)
INSERT INTO essentials.politician_contacts (politician_id, source, contact_type, email)
SELECT id, 'manual', 'office', email FROM (VALUES
  ('1844a5e3-8ea5-4ee5-9377-066378b25b49'::uuid, 'uag@agutah.gov'),       -- Derek Brown, AG
  ('919b82e8-bac3-428f-9896-423832e4538f'::uuid, 'treasurer@utah.gov')    -- Marlo Oaks, Treasurer
) AS v(id, email)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts WHERE politician_id = v.id AND contact_type = 'office'
);

-- =============================================================================
-- SECTION 3: Federal officials — official websites + phones
-- =============================================================================

INSERT INTO essentials.politician_contacts (politician_id, source, contact_type, website_url, phone)
SELECT id, 'manual', 'primary', url, phone FROM (VALUES
  ('b87583fe-2348-4bf3-aba5-12f5f88d3606'::uuid, 'https://curtis.senate.gov',       '(202) 224-5251'), -- John Curtis
  ('4f62ca82-fda1-4386-9a4a-62dd84318f83'::uuid, 'https://www.lee.senate.gov',      '(202) 224-5444'), -- Mike Lee
  ('e365a1d4-2de3-4fb6-b416-d78227836553'::uuid, 'https://blakemoore.house.gov',    '(202) 225-0453'), -- Blake Moore
  ('a7983eb6-bae0-4269-856b-f4554fb5ce29'::uuid, 'https://maloy.house.gov',         '(202) 225-9730'), -- Celeste Maloy
  ('9e3164d5-ce71-4c50-9220-b969265ce551'::uuid, 'https://mikekennedy.house.gov',   '(202) 225-7751'), -- Mike Kennedy
  ('cb87ddbb-5a83-45b7-b67a-789e63f0e58b'::uuid, 'https://owens.house.gov',         NULL)              -- Burgess Owens (retired)
) AS v(id, url, phone)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts WHERE politician_id = v.id AND contact_type = 'primary'
);

-- Federal campaign websites (for those on the 2026 ballot)
INSERT INTO essentials.politician_contacts (politician_id, source, contact_type, website_url)
SELECT id, 'manual', 'campaign', url FROM (VALUES
  ('b87583fe-2348-4bf3-aba5-12f5f88d3606'::uuid, 'https://www.johncurtis.org'),          -- John Curtis
  ('e365a1d4-2de3-4fb6-b416-d78227836553'::uuid, 'https://www.electmoore.com'),           -- Blake Moore
  ('a7983eb6-bae0-4269-856b-f4554fb5ce29'::uuid, 'https://www.celesteforutah.com'),       -- Celeste Maloy
  ('9e3164d5-ce71-4c50-9220-b969265ce551'::uuid, 'https://mikekennedyforutah.com')        -- Mike Kennedy
) AS v(id, url)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts WHERE politician_id = v.id AND contact_type = 'campaign'
);

-- =============================================================================
-- SECTION 4: 2026 primary candidates — campaign websites (politician_contacts)
-- =============================================================================

INSERT INTO essentials.politician_contacts (politician_id, source, contact_type, website_url)
SELECT id, 'manual', 'campaign', url FROM (VALUES
  ('9a171371-be83-456e-acd5-ece936ee84ae'::uuid, 'https://brooksbenson4utah.com'),        -- Brooks Benson SD-11 R
  ('e125bf5b-3e47-49ff-bcdd-07ab8421b54d'::uuid, 'https://www.voteformackenzie.org'),     -- MacKenzie Miller SD-11 D
  ('77dc9a42-5f37-4608-89a1-10e60f86a3a1'::uuid, 'https://www.evandone.com'),             -- Evan Done SD-13 D
  ('b79c73a9-3737-4381-bc2c-d23599095e9c'::uuid, 'https://ryanmahoney4utah.godaddysites.com'), -- Ryan Mahoney SD-13 R
  ('63d60b50-2395-4cde-8999-97a9166d3563'::uuid, 'https://www.silviacatten.com'),         -- Silvia Catten SD-13 D
  ('327298e7-e42c-4dfa-9f1d-55cfd48e0659'::uuid, 'https://www.padenforutah.com'),         -- Taylor J. Paden SD-13 D
  ('28df85e8-73c8-4def-bdd1-6929ff083590'::uuid, 'https://khaterforutah.com'),            -- Tayler Khater SD-14 D
  ('8f3acca8-456d-495a-b3f5-d2dd1669213d'::uuid, 'https://www.andersonforutah.com'),      -- Shana Anderson SD-19 D
  ('92dba8fc-2bd1-4a68-ad69-ada24e3ff6f4'::uuid, 'https://kellyforutah.com'),             -- Kelly Smith SD-21 R
  ('a4aaaa16-4512-4098-bc33-aed05158a651'::uuid, 'https://www.tuckersmithforutah.com'),   -- Tucker Smith SD-23 D
  ('b71ec1b6-7d9e-406b-a30a-8c0710278d5e'::uuid, 'https://brentbowles4ut.com'),           -- Brent Bowles Commission A R
  ('abf34eb9-8b81-4c9f-8db6-25ba036419c9'::uuid, 'https://teamkaufusi.com'),              -- Michelle Kaufusi Commission A R
  ('f43a2014-6b3c-4497-b5bf-c6d04d27ed07'::uuid, 'https://www.davidspencerforutah.com'), -- David Spencer Commission B R
  ('b4aac990-f353-4ea7-bdb3-d5cf2cd232c8'::uuid, 'https://votepaxman.com')               -- Isaac Paxman Commission B R
) AS v(id, url)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts WHERE politician_id = v.id AND contact_type = 'campaign'
);

-- =============================================================================
-- SECTION 5: UPDATE race_candidates.website_url for 2026 primary candidates
-- =============================================================================

UPDATE essentials.race_candidates rc
SET website_url = v.url
FROM (VALUES
  -- Federal (official site)
  ('b87583fe-2348-4bf3-aba5-12f5f88d3606'::uuid, 'https://curtis.senate.gov'),
  ('e365a1d4-2de3-4fb6-b416-d78227836553'::uuid, 'https://blakemoore.house.gov'),
  ('a7983eb6-bae0-4269-856b-f4554fb5ce29'::uuid, 'https://maloy.house.gov'),
  ('9e3164d5-ce71-4c50-9220-b969265ce551'::uuid, 'https://mikekennedy.house.gov'),
  -- State Senate candidates
  ('9a171371-be83-456e-acd5-ece936ee84ae'::uuid, 'https://brooksbenson4utah.com'),
  ('e125bf5b-3e47-49ff-bcdd-07ab8421b54d'::uuid, 'https://www.voteformackenzie.org'),
  ('77dc9a42-5f37-4608-89a1-10e60f86a3a1'::uuid, 'https://www.evandone.com'),
  ('b79c73a9-3737-4381-bc2c-d23599095e9c'::uuid, 'https://ryanmahoney4utah.godaddysites.com'),
  ('63d60b50-2395-4cde-8999-97a9166d3563'::uuid, 'https://www.silviacatten.com'),
  ('327298e7-e42c-4dfa-9f1d-55cfd48e0659'::uuid, 'https://www.padenforutah.com'),
  ('28df85e8-73c8-4def-bdd1-6929ff083590'::uuid, 'https://khaterforutah.com'),
  ('8f3acca8-456d-495a-b3f5-d2dd1669213d'::uuid, 'https://www.andersonforutah.com'),
  ('92dba8fc-2bd1-4a68-ad69-ada24e3ff6f4'::uuid, 'https://kellyforutah.com'),
  ('a4aaaa16-4512-4098-bc33-aed05158a651'::uuid, 'https://www.tuckersmithforutah.com'),
  -- County Commission
  ('b71ec1b6-7d9e-406b-a30a-8c0710278d5e'::uuid, 'https://brentbowles4ut.com'),
  ('abf34eb9-8b81-4c9f-8db6-25ba036419c9'::uuid, 'https://teamkaufusi.com'),
  ('f43a2014-6b3c-4497-b5bf-c6d04d27ed07'::uuid, 'https://www.davidspencerforutah.com'),
  ('b4aac990-f353-4ea7-bdb3-d5cf2cd232c8'::uuid, 'https://votepaxman.com')
) AS v(pid, url),
essentials.races r,
essentials.elections e
WHERE rc.race_id = r.id
  AND r.election_id = e.id
  AND rc.politician_id = v.pid
  AND e.name = '2026 Utah Primary'
  AND rc.website_url IS NULL;

-- =============================================================================
-- SECTION 6: Cache County — official department URLs + email/phone
-- =============================================================================

INSERT INTO essentials.politician_contacts (politician_id, source, contact_type, website_url, email, phone)
SELECT id, 'manual', 'primary', url, email, phone FROM (VALUES
  ('1ada1870-0429-47ea-973e-f7f92adf2f0d'::uuid, 'https://www.cachecounty.gov/assessor/',       'assessment@cachecounty.gov',            '435-755-1590'), -- Bret Robinson
  ('9651210a-f006-4d74-ae2e-88eb682e8199'::uuid, 'https://www.cachecounty.gov/clerk/',           NULL,                                    '435-755-1460'), -- Bryson J. Behm
  ('e16daaea-d057-4935-bf9e-e241d47ee4d0'::uuid, 'https://www.cachecounty.gov/sheriffs-office/', NULL,                                    '435-755-1000'), -- Chad Jensen
  ('d5103d27-4c2e-490b-acf3-04d0a09f3be7'::uuid, 'https://www.cachecounty.gov/treasurer/',      'Cache_County.Treasurer@cachecounty.gov','435-755-1500'), -- Craig McAllister
  ('218899ab-a196-4a6c-b0cd-843235145cae'::uuid, 'https://www.cachecounty.gov/attorney/',        NULL,                                    '435-755-1860'), -- Dane Murray
  ('3d3f3871-11dd-4cc4-b8d5-5b91a87f804f'::uuid, 'https://www.cachecounty.gov/auditor/',         NULL,                                    '435-755-1706'), -- Matthew Funk
  ('cd6e10a8-462c-4bac-955b-7f647e7931ef'::uuid, 'https://www.cachecounty.gov/recorder/',        NULL,                                    '435-755-1530')  -- Tennille Johnson
) AS v(id, url, email, phone)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts WHERE politician_id = v.id AND contact_type = 'primary'
);

-- =============================================================================
-- SECTION 7: Iron County — official department URLs + email/phone
-- =============================================================================

INSERT INTO essentials.politician_contacts (politician_id, source, contact_type, website_url, email, phone)
SELECT id, 'manual', 'primary', url, email, phone FROM (VALUES
  ('9ffed5d4-454d-4346-80bf-73397c25cda9'::uuid, 'https://ironcountyut.gov/recorders',  NULL,                        '435-477-8350'), -- Carri Jeffries
  ('52ac97ce-e347-4d23-a81b-2b513e767b83'::uuid, 'https://ironcountyut.gov/attorney',   'cdotson@ironcounty.net',    '435-865-5310'), -- Chad E. Dotson
  ('1a03e07e-615a-47f9-8377-6afa10fa7dc3'::uuid, 'https://ironcountyut.gov/clerk',      NULL,                        '435-477-8340'), -- Jon Whittaker
  ('06b5d9ab-1db1-4bdb-a13c-029bfc715f65'::uuid, 'https://ironcountyut.gov/assessor',   NULL,                        '435-477-8310'), -- Karsten Reed
  ('e06f35c4-0c6d-4680-a596-155cc6588ec9'::uuid, 'https://www.ironsheriff.net/',         'kcarpenter@ironcounty.net', '435-867-7500'), -- Kenneth Carpenter
  ('96a17beb-bc8a-4778-8f3c-8ad60721a097'::uuid, 'https://ironcountyut.gov/auditor',    NULL,                        '435-477-8330'), -- Lucas Little
  ('97d115c0-1a3d-44b0-a678-928d87ad2b16'::uuid, 'https://ironcountyut.gov/treasurer',  NULL,                        '435-477-8360')  -- Nicole Rosenberg
) AS v(id, url, email, phone)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts WHERE politician_id = v.id AND contact_type = 'primary'
);

-- =============================================================================
-- SECTION 8: Washington County — official department URLs + phone
-- =============================================================================

INSERT INTO essentials.politician_contacts (politician_id, source, contact_type, website_url, email, phone)
SELECT id, 'manual', 'primary', url, email, phone FROM (VALUES
  ('6a3c287a-4474-4dc6-a89b-52e1fe80b86d'::uuid, 'https://news.washeriff.net/',                          'comment@washeriff.net', '(435) 656-6500'), -- Barry Golding
  ('217d471e-c79e-4f26-a270-1d7a3f873791'::uuid, 'https://www.washco.utah.gov/departments/treasurer/',   NULL,                    '(435) 301-7720'), -- David Whitehead
  ('b635c956-430f-432a-b922-72cdf935269e'::uuid, 'https://www.washco.utah.gov/departments/recorder/',    NULL,                    '(435) 301-7680'), -- Gary Christensen
  ('2c52ce5c-64a2-4e13-8e57-3150a414b765'::uuid, 'https://www.washco.utah.gov/departments/attorney/',    NULL,                    '(435) 301-7100'), -- Jerry Jaeger
  ('2daa1ae3-99ac-4534-b981-7f4dcecb8541'::uuid, 'https://www.washco.utah.gov/departments/clerk/',       NULL,                    '(435) 301-7220'), -- Ryan Sullivan
  ('96b9a9f6-515f-4022-96a4-21360f98db67'::uuid, 'https://www.washco.utah.gov/departments/assessor/',   NULL,                    '(435) 301-7020')  -- Tom Durrant
) AS v(id, url, email, phone)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts WHERE politician_id = v.id AND contact_type = 'primary'
);

-- =============================================================================
-- SECTION 9: Weber County — official department URLs + email/phone
-- =============================================================================

INSERT INTO essentials.politician_contacts (politician_id, source, contact_type, website_url, email, phone)
SELECT id, 'manual', 'primary', url, email, phone FROM (VALUES
  ('853e218f-1f95-4148-afe4-bfd34130cdb4'::uuid, 'https://www.webercountyutah.gov/Recorder_Surveyor/',         'recorder@webercountyutah.gov',  '801-399-8441'), -- Bahy Rahimzadegan
  ('6fafb9d5-e223-4c49-b02b-de565c6c547f'::uuid, 'https://www.webercountyutah.gov/Attorney/',                  NULL,                            '801-399-8377'), -- Christopher F. Allred
  ('f9e9df90-5234-4c23-8f70-39d6e812c14a'::uuid, 'https://www.webercountyutah.gov/County_Commission/froerer.php', 'gfroerer@webercountyutah.gov','801-399-8590'), -- Gage Froerer
  ('855978c9-8966-4075-9570-39c34567c34a'::uuid, 'https://www.webercountyutah.gov/County_Commission/harvey.php',  'jharvey@webercountyutah.gov', '801-399-8588'), -- James H. Harvey
  ('a45f2a74-38b5-4178-b379-af98b8c3af74'::uuid, 'https://www.webercountyutah.gov/Assessor/',                  'jpreisler@webercountyutah.gov','801-399-8572'), -- Jared Preisler
  ('bec64cb9-f4b8-4675-b79a-e5c03115fedb'::uuid, 'https://www.webercountyutah.gov/Treasurer/',                 'treasurer@webercountyutah.gov','801-399-8454'), -- Lynelle Jensen
  ('75617174-765b-48dc-8123-8fec80cdfa12'::uuid, 'https://www.webercountyutah.gov/Clerk_Auditor/',             'rhatch@co.weber.ut.us',        '801-399-8400'), -- Ricky Hatch
  ('717f801f-17a6-40c4-9708-279c06f98bea'::uuid, 'https://www.webercountyutah.gov/sheriff/',                   NULL,                            '801-395-8221'), -- Ryan Arbon
  ('4dc660bf-bdf7-402b-a79d-6e733ec87ffd'::uuid, 'https://www.webercountyutah.gov/County_Commission/bolos.php', 'sbolos@webercountyutah.gov',  '801-399-8589')  -- Sharon Bolos
) AS v(id, url, email, phone)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts WHERE politician_id = v.id AND contact_type = 'primary'
);

-- =============================================================================
-- SECTION 10: Summit County + Davis County
-- =============================================================================

INSERT INTO essentials.politician_contacts (politician_id, source, contact_type, website_url, phone)
SELECT id, 'manual', 'primary', url, phone FROM (VALUES
  ('edd7212a-0f23-45a1-9367-afb6ff4dd598'::uuid, 'https://www.summitcountyutah.gov/2635/Attorney', '(435) 336-3206'), -- Margaret Olson
  ('8328c9ef-c1ac-4e35-9d0b-e40a84fc50b8'::uuid, 'https://www.daviscountyutah.gov/surveyor',       '(801) 451-3290')  -- Max B. Elliott
) AS v(id, url, phone)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts WHERE politician_id = v.id AND contact_type = 'primary'
);

-- =============================================================================
-- SECTION 11: Local city officials — SLC, Sandy, Layton, West Jordan
-- =============================================================================

INSERT INTO essentials.politician_contacts (politician_id, source, contact_type, website_url, email, phone)
SELECT id, 'manual', 'primary', url, email, phone FROM (VALUES
  -- SLC Mayor
  ('e5499340-d24d-447c-a7b1-92066319ad6e'::uuid, 'https://www.slc.gov/mayor/',                 NULL,                                  '801-535-7704'),
  -- Sandy Mayor
  ('6a7b2e72-1ea1-4b1c-8227-eb0cc2565227'::uuid, 'https://sandy.utah.gov/1073/Mayors-Office', 'mayor@sandy.utah.gov',                '801-568-7109'),
  -- Layton City Council
  ('053fb431-dc21-4aea-8e10-39e8ec5164d4'::uuid, 'https://www.laytoncityutah.gov/LC/Government/CouncilMember2',  'bedmondson@laytoncity.org', '801-336-3800'),
  ('4ff6cfe5-b5f8-4bdc-b537-529932615347'::uuid, 'https://www.laytoncityutah.gov/LC/Government/CouncilMembers', 'cmorris@laytoncity.org',    '801-336-3800'),
  ('ad3ec089-9df8-4631-8086-e1817a049fe1'::uuid, 'https://www.laytoncityutah.gov/LC/Government/CouncilMembers', 'dthomas@laytoncity.org',    '801-336-3800'),
  ('935135f0-42fb-443f-87e9-c9bb8f140ead'::uuid, 'https://www.laytoncityutah.gov/LC/Government/CouncilMember3', 'mkolendrianos@laytoncity.org', '801-336-3800'),
  ('b07e0062-f896-4d70-ac36-ea950df0ab35'::uuid, 'https://www.laytoncityutah.gov/LC/Government/CouncilMember1', 'zbloxham@laytoncity.org',   '801-336-3800'),
  -- West Jordan City Council
  ('8e0afb85-048d-4f9f-a941-3c124f9dc2bb'::uuid, 'https://www.westjordan.utah.gov/citycouncil/02-councilmember-at-large/', 'annette.harris@westjordan.utah.gov',    '801-569-5205'),
  ('afa590f1-9045-44ec-b8cb-bff45b029d2a'::uuid, 'https://www.westjordan.utah.gov/citycouncil/01-councilmember-at-large/', 'jessica.wignall@westjordan.utah.gov',   '801-569-5206'),
  ('9060140a-b3f7-46b8-a07f-fc9e9ececd94'::uuid, 'https://www.westjordan.utah.gov/citycouncil/03-councilmember-at-large/', 'kayleen.whitelock@westjordan.utah.gov', '801-569-5207'),
  ('0e615a9d-87e0-457a-8b17-ee44d708336e'::uuid, 'https://www.westjordan.utah.gov/citycouncil/district-1-councilmember/', 'chad.lamb@westjordan.utah.gov',         '801-569-5201'),
  ('38fdba8d-38ef-4f4b-949c-087ff970a357'::uuid, 'https://www.westjordan.utah.gov/citycouncil/district-2-councilmember/', 'bob.bedore@westjordan.utah.gov',         '801-569-5202'),
  ('8c90e9f5-f8a2-48e3-9210-e563cf795386'::uuid, 'https://www.westjordan.utah.gov/citycouncil/district-3-councilmember/', 'zach.jacob@westjordan.utah.gov',         '801-755-9628'),
  ('d836f46a-819c-4a59-83b5-23af7ed79fdd'::uuid, 'https://www.westjordan.utah.gov/citycouncil/district-4-councilmember/', 'kent.shelton@westjordan.utah.gov',       '801-569-5204')
) AS v(id, url, email, phone)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_contacts WHERE politician_id = v.id AND contact_type = 'primary'
);

COMMIT;

-- =============================================================================
-- Verification queries:
--
-- Check STATE_EXEC names are populated:
--   SELECT p.full_name, o.title FROM essentials.politicians p
--   JOIN essentials.offices o ON o.politician_id = p.id
--   JOIN essentials.districts d ON d.id = o.district_id
--   WHERE d.district_type = 'STATE_EXEC' ORDER BY o.title;
--
-- Count contacts added:
--   SELECT d.district_type, COUNT(DISTINCT pc.politician_id)
--   FROM essentials.politician_contacts pc
--   JOIN essentials.offices o ON o.politician_id = pc.politician_id
--   JOIN essentials.districts d ON d.id = o.district_id
--   WHERE d.state ILIKE 'ut' GROUP BY d.district_type ORDER BY d.district_type;
--
-- Check race_candidates website_url populated:
--   SELECT rc.full_name, rc.website_url FROM essentials.race_candidates rc
--   JOIN essentials.races r ON r.id = rc.race_id
--   JOIN essentials.elections e ON e.id = r.election_id
--   WHERE e.name = '2026 Utah Primary' AND rc.website_url IS NOT NULL;
-- =============================================================================
