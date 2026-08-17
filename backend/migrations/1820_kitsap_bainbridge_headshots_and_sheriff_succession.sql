-- 1820_kitsap_bainbridge_headshots_and_sheriff_succession.sql
--
-- Bainbridge Island + Kitsap County headshot wave (22 portraits) and the sheriff
-- succession the sweep uncovered while running it.
--
-- WHY THE SHERIFF CHANGE IS IN THE SAME MIGRATION
-- The headshot sweep is a vacancy detector: hunting a portrait for "Sheriff John Gese"
-- is what surfaced that he is no longer sheriff. Gese and four KCSO leaders resigned
-- effective 2026-06-26 ahead of a pension deadline; kitsap.gov's own Administration page
-- now heads its Executive Staff list with "Acting Sheriff Penelope Sapp". Seating Sapp and
-- importing her portrait are the same fact, so they land together rather than leaving a
-- window where prod shows her face under his name.
--
-- 🔴 THE alt TEXT ON THAT PAGE IS SHIFTED BY ONE SLOT. `Chief Penelope Sapp.png` carries
--    alt="Sheriff John Gese" and `Chief Jeff Menge.png` carries alt="Chief Penelope Sapp".
--    The FILENAMES are correct; the alt attributes are stale. Any importer matching on alt
--    would file Sapp's face as Gese. Both images were confirmed by eye before this ran.
--
-- 🔴 NOT FINAL. Sapp is ACTING, pending an interim appointment the Board of Commissioners
--    must make by 2026-08-29 from three names (Brandon Myers, Ken Dickinson, Jeffrey Menge).
--    Myers is simultaneously the Democratic nominee for the seat in November. Re-check after
--    2026-08-29 — see .planning/todos/2026-08-17-kitsap-sheriff-interim-appointment.md
--
-- Sources, one per cohort:
--   *  7 Bainbridge Island councilmembers — bainbridgewa.gov CivicPlus directory pages,
--      each <img alt="Profile picture of <NAME>"> (name in alt = free second factor).
--   *  4 Kitsap officials + 3 commissioners + Sapp — kitsap.gov department / DistNhome pages.
--   * 10 candidates and officials on the 2026 ballot — WA Secretary of State voters'
--      pamphlet, voter.votewa.gov/elections/candidate.ashx?e=898&r=<race>&b=<ballot>&la=en.
--      Every payload was checked for CountyDisplay="Kitsap" AND a matching BallotName, and
--      each pair of opponents shares a RaceID, which is a third guard.
--
-- All 22 staged to 600x750 (4:5), JPEG q90, uploaded to storage bucket politician_photos as
-- <pid>-headshot.jpg, and reviewed by Chris on a contact-sheet Artifact before this ran.
-- No monochrome, no social media, no group crops (both the city council page and the BOC
-- page publish ONLY group photos — the individual portraits came from elsewhere).
--
-- 🔴 photo_custom_url IS SET DELIBERATELY, not just photo_origin_url. The read path is
--    COALESCE(photo_custom_url, photo_origin_url, '') on the backend and
--    photo_origin_url || images[0].url in ev-ui, so a source-PAGE url sitting alone in
--    photo_origin_url WINS over the mirrored image and renders a broken portrait. That
--    silently broke 48 WI profiles (migs 1472-1474) until 1475 Part B repaired it.
--
-- Idempotent. Re-running inserts nothing and changes nothing.

BEGIN;

-- ---------------------------------------------------------------------------
-- 0. Staging table: (pid, name, bucket_url, source_page, license)
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE _hs (
  pid          uuid PRIMARY KEY,
  full_name    text NOT NULL,
  bucket_url   text NOT NULL,
  source_page  text NOT NULL,
  license      text NOT NULL
) ON COMMIT DROP;

INSERT INTO _hs (pid, full_name, bucket_url, source_page, license) VALUES
-- Bainbridge Island City Council (7)
('ac207480-9d05-4680-8ea1-d7e64750dec2','Kirsten Hytopoulos','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ac207480-9d05-4680-8ea1-d7e64750dec2-headshot.jpg','https://www.bainbridgewa.gov/directory.aspx?EID=260','press_use'),
('0b40c9c1-1d14-48d4-8a18-07f3a409f515','Brenda Fantroy-Johnson','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0b40c9c1-1d14-48d4-8a18-07f3a409f515-headshot.jpg','https://www.bainbridgewa.gov/directory.aspx?EID=274','press_use'),
('579f8af4-303c-4a7d-87de-6c473b07d29a','Mike Nelson','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/579f8af4-303c-4a7d-87de-6c473b07d29a-headshot.jpg','https://www.bainbridgewa.gov/Directory.aspx?EID=362','press_use'),
('ae3690f0-7157-4ba9-8bc3-1e6cb9e3a6b9','Leslie Schneider','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ae3690f0-7157-4ba9-8bc3-1e6cb9e3a6b9-headshot.jpg','https://www.bainbridgewa.gov/Directory.aspx?EID=250','press_use'),
('b6521cfc-06f3-4897-9499-73005a8f4ecd','Clarence Moriwaki','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b6521cfc-06f3-4897-9499-73005a8f4ecd-headshot.jpg','https://www.bainbridgewa.gov/directory.aspx?EID=296','press_use'),
('515c527b-c1ab-4b81-82c1-bb5dfc2f1ebd','Ashley Mathews','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/515c527b-c1ab-4b81-82c1-bb5dfc2f1ebd-headshot.jpg','https://www.bainbridgewa.gov/Directory.aspx?EID=338','press_use'),
('6fe01c62-6a73-418c-975c-c59ea55bc61f','Lara Lant','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6fe01c62-6a73-418c-975c-c59ea55bc61f-headshot.jpg','https://www.bainbridgewa.gov/Directory.aspx?EID=363','press_use'),
-- Kitsap County officials (8 seated + Sapp below)
('4033e7e1-c019-4a2c-ac42-b70ba25d867d','Phil Cook','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4033e7e1-c019-4a2c-ac42-b70ba25d867d-headshot.jpg','https://www.kitsap.gov/assessor/Pages/default.aspx','press_use'),
('13974a7b-f137-4f39-a24d-1cb4bd4f4537','Paul Andrews','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/13974a7b-f137-4f39-a24d-1cb4bd4f4537-headshot.jpg','https://www.kitsap.gov/auditor/Pages/default.aspx','press_use'),
('1f8cf1e7-fc37-4309-be1f-0c01455d7976','David Lewis','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1f8cf1e7-fc37-4309-be1f-0c01455d7976-headshot.jpg','https://voter.votewa.gov/GenericVoterGuide.aspx?e=898','press_use'),
('490d55e2-c134-4a01-9c0a-8b45b2d7b8c5','Chad M. Enright','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/490d55e2-c134-4a01-9c0a-8b45b2d7b8c5-headshot.jpg','https://voter.votewa.gov/GenericVoterGuide.aspx?e=898','press_use'),
('c42da229-04c9-48ec-8f35-eb278c9d75de','Pete Boissonneau','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c42da229-04c9-48ec-8f35-eb278c9d75de-headshot.jpg','https://voter.votewa.gov/GenericVoterGuide.aspx?e=898','press_use'),
('8f96526a-f369-4f45-86ba-a2a3a3ea67f8','Christine Rolfes','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8f96526a-f369-4f45-86ba-a2a3a3ea67f8-headshot.jpg','https://www.kitsap.gov/BOC_p/Pages/Dist1home.aspx','press_use'),
('e667feab-5f75-4283-a683-179f6529918f','Oran Root','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e667feab-5f75-4283-a683-179f6529918f-headshot.jpg','https://www.kitsap.gov/BOC_p/Pages/Dist2home.aspx','press_use'),
('c6a92f10-a49c-40b0-90bd-4d12f2ae4a97','Katie Walters','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c6a92f10-a49c-40b0-90bd-4d12f2ae4a97-headshot.jpg','https://voter.votewa.gov/GenericVoterGuide.aspx?e=898','press_use'),
-- Acting Sheriff (new record, created below)
('b9fe1fa9-9d4b-4301-8e43-763951034d64','Penelope Sapp','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b9fe1fa9-9d4b-4301-8e43-763951034d64-headshot.jpg','https://www.kitsap.gov/sheriff/Pages/Admin-Department.aspx','press_use'),
-- 2026 challengers (6)
('5368de18-32c9-4b03-8c10-034514bad2db','Michael Simonds','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5368de18-32c9-4b03-8c10-034514bad2db-headshot.jpg','https://voter.votewa.gov/GenericVoterGuide.aspx?e=898','press_use'),
('3a41aeee-4b2d-4146-8349-e8b3391b596a','Brien Kennedy','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3a41aeee-4b2d-4146-8349-e8b3391b596a-headshot.jpg','https://voter.votewa.gov/GenericVoterGuide.aspx?e=898','press_use'),
('76e6aa72-b87c-4e0a-b1ba-1873e1bec7b8','Joe Lombardi','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/76e6aa72-b87c-4e0a-b1ba-1873e1bec7b8-headshot.jpg','https://voter.votewa.gov/GenericVoterGuide.aspx?e=898','press_use'),
('d9d8c271-0f90-4052-9439-78e02e0dc1b4','Rick Kuss','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d9d8c271-0f90-4052-9439-78e02e0dc1b4-headshot.jpg','https://voter.votewa.gov/GenericVoterGuide.aspx?e=898','press_use'),
('01119ca2-d252-4c9d-8052-57164ace14b8','Brandon L. Myers','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/01119ca2-d252-4c9d-8052-57164ace14b8-headshot.jpg','https://www.kitsap.gov/sheriff/Pages/Admin-Department.aspx','press_use'),
('ff060dd6-8751-401f-b330-8626e21b0dee','Kevin Tisdel','https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ff060dd6-8751-401f-b330-8626e21b0dee-headshot.jpg','https://voter.votewa.gov/GenericVoterGuide.aspx?e=898','press_use');

-- ---------------------------------------------------------------------------
-- 1. Pre-flight: every pid except Sapp's must already exist, and no row may be
--    carrying a manual override we would trample.
-- ---------------------------------------------------------------------------
DO $$
DECLARE missing int; overridden int; n int;
BEGIN
  SELECT count(*) INTO n FROM _hs;
  IF n <> 22 THEN
    RAISE EXCEPTION 'staging table holds % rows, expected 22', n;
  END IF;

  SELECT count(*) INTO missing
  FROM _hs h
  WHERE h.pid <> 'b9fe1fa9-9d4b-4301-8e43-763951034d64'::uuid
    AND NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = h.pid);
  IF missing > 0 THEN
    RAISE EXCEPTION 'aborting: % staged pids do not exist in essentials.politicians', missing;
  END IF;

  SELECT count(*) INTO overridden
  FROM _hs h JOIN essentials.politicians p ON p.id = h.pid
  WHERE p.photo_custom_url_manual_override IS TRUE;
  IF overridden > 0 THEN
    RAISE EXCEPTION 'aborting: % staged rows carry photo_custom_url_manual_override', overridden;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 2. Penelope Sapp — new politician record, explicit id so the storage filename
--    written before this migration ran matches.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.politicians (id, full_name, first_name, last_name, is_active, is_incumbent, source)
SELECT 'b9fe1fa9-9d4b-4301-8e43-763951034d64'::uuid, 'Penelope Sapp', 'Penelope', 'Sapp', true, true,
       'kitsap.gov/sheriff/Pages/Admin-Department.aspx — Executive Staff, "Acting Sheriff Penelope Sapp". '
       'Chief of Corrections since May 2021; KCSO since October 2002. Appointed acting sheriff on '
       'Sheriff John Gese''s departure 2026-06-26. Read 2026-08-17.'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politicians WHERE id = 'b9fe1fa9-9d4b-4301-8e43-763951034d64'::uuid
);

-- ---------------------------------------------------------------------------
-- 3. Sheriff succession. seat_officeholder closes the predecessor's term the day
--    BEFORE p_term_start, which is exactly 2026-06-25, and stamps how_ended on it.
--    Guarded so a re-run is a no-op rather than an exclusion-constraint violation.
-- ---------------------------------------------------------------------------
DO $$
DECLARE v_office uuid := '2314ba12-903a-4492-addf-9d7f9e4a2b75';  -- Kitsap County / Sheriff
        v_sapp   uuid := 'b9fe1fa9-9d4b-4301-8e43-763951034d64';
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM essentials.office_terms
    WHERE office_id = v_office AND politician_id = v_sapp
  ) THEN
    PERFORM essentials.seat_officeholder(
      v_office,
      v_sapp,
      DATE '2026-06-26',
      'kitsap.gov/sheriff/Pages/Admin-Department.aspx lists "Acting Sheriff Penelope Sapp" as of '
      '2026-08-17. Sheriff John Gese resigned effective 2026-06-26 alongside four KCSO leaders '
      '(Kitsap Daily News, 2026-06-09); Sapp, then Chief of Corrections, was appointed acting sheriff '
      'on his departure. ACTING ONLY — the Board of Commissioners must appoint an interim sheriff by '
      '2026-08-29 from three names forwarded by the county Democratic central committee (Brandon '
      'Myers, Ken Dickinson, Jeffrey Menge), and the seat is on the 2026-11-03 ballot.',
      'appointed',   -- how_started
      'day',         -- start_precision
      'resigned'     -- how_ended on Gese's now-closed term
    );
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 4. Portrait rows. type='default' matches the read path's expectation.
-- ---------------------------------------------------------------------------
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT h.pid, h.bucket_url, 'default', h.license
FROM _hs h
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images pi
  WHERE pi.politician_id = h.pid AND pi.url = h.bucket_url
);

-- ---------------------------------------------------------------------------
-- 5. photo_origin_url = the page the portrait was FOUND on (provenance).
--    photo_custom_url = the mirrored bucket url (what actually renders).
--    Both required — see the header note.
-- ---------------------------------------------------------------------------
UPDATE essentials.politicians p
SET photo_origin_url = h.source_page,
    photo_custom_url = h.bucket_url
FROM _hs h
WHERE p.id = h.pid
  AND p.photo_custom_url_manual_override IS NOT TRUE
  AND (p.photo_origin_url IS DISTINCT FROM h.source_page
       OR p.photo_custom_url IS DISTINCT FROM h.bucket_url);

-- ---------------------------------------------------------------------------
-- 6. Post-verify. Re-runs HAS_RENDERABLE_PHOTO_SQL itself rather than a proxy for
--    it, so this gate fails if the read path would still show a broken portrait.
-- ---------------------------------------------------------------------------
DO $$
DECLARE renderable int; imgs int; gese_open int; sapp_seated int; sheriff_holders int;
BEGIN
  SELECT count(*) INTO renderable
  FROM _hs h
  JOIN essentials.politicians p ON p.id = h.pid
  LEFT JOIN essentials.politician_images img ON img.politician_id = p.id
  WHERE (
       img.politician_id IS NOT NULL
    OR btrim(coalesce(p.photo_custom_url, '')) <> ''
    OR (btrim(coalesce(p.photo_origin_url, '')) <> '' AND p.photo_origin_url LIKE 'http%')
  );
  IF renderable <> 22 THEN
    RAISE EXCEPTION 'HAS_RENDERABLE_PHOTO: expected 22 renderable, found %', renderable;
  END IF;

  SELECT count(*) INTO imgs
  FROM _hs h JOIN essentials.politician_images pi
    ON pi.politician_id = h.pid AND pi.url = h.bucket_url;
  IF imgs <> 22 THEN
    RAISE EXCEPTION 'expected 22 politician_images rows, found %', imgs;
  END IF;

  -- every staged row must resolve to the BUCKET, not a source page
  IF EXISTS (
    SELECT 1 FROM _hs h JOIN essentials.politicians p ON p.id = h.pid
    WHERE coalesce(p.photo_custom_url, p.photo_origin_url, '') NOT LIKE '%storage.supabase.co%'
  ) THEN
    RAISE EXCEPTION 'a staged row still resolves to a source page, not the bucket';
  END IF;

  -- Gese's term must be CLOSED AT THE RESIGNATION DATE.
  -- 🔴 Do NOT test `term_end IS NULL` here. Kitsap's row already carried a real
  --    term_end (2026-12-31), so an "open term" test reads 0 BEFORE this migration
  --    runs and passes vacuously — it would go green having verified nothing.
  --    Assert the positive fact instead: the term ends the day before Sapp starts.
  SELECT count(*) INTO gese_open
  FROM essentials.office_terms ot JOIN essentials.politicians p ON p.id = ot.politician_id
  WHERE p.full_name = 'John Gese'
    AND ot.office_id = '2314ba12-903a-4492-addf-9d7f9e4a2b75'::uuid
    AND ot.term_end = DATE '2026-06-25'
    AND ot.how_ended = 'resigned';
  IF gese_open <> 1 THEN
    RAISE EXCEPTION 'expected exactly 1 Gese term closed 2026-06-25 as resigned, found %', gese_open;
  END IF;

  -- and he must not resolve as a current holder of ANY office by date containment
  IF EXISTS (
    SELECT 1 FROM essentials.office_current_holder och
    JOIN essentials.politicians p ON p.id = och.politician_id
    WHERE p.full_name = 'John Gese'
  ) THEN
    RAISE EXCEPTION 'John Gese still resolves as a current officeholder';
  END IF;

  -- Sapp must be the CURRENT holder. politician_id IS NOT NULL matters:
  -- office_current_holder LEFT JOINs from offices, so a vacancy is a NULL row,
  -- and a bare count(*) would pass vacuously.
  SELECT count(*) INTO sapp_seated
  FROM essentials.office_current_holder och
  WHERE och.office_id = '2314ba12-903a-4492-addf-9d7f9e4a2b75'::uuid
    AND och.politician_id = 'b9fe1fa9-9d4b-4301-8e43-763951034d64'::uuid;
  IF sapp_seated <> 1 THEN
    RAISE EXCEPTION 'Penelope Sapp is not the current Kitsap Sheriff (found %)', sapp_seated;
  END IF;

  SELECT count(*) INTO sheriff_holders
  FROM essentials.office_current_holder och
  WHERE och.office_id = '2314ba12-903a-4492-addf-9d7f9e4a2b75'::uuid
    AND och.politician_id IS NOT NULL;
  IF sheriff_holders <> 1 THEN
    RAISE EXCEPTION 'Kitsap Sheriff resolves to % holders, expected exactly 1', sheriff_holders;
  END IF;

  RAISE NOTICE 'OK: 22 renderable portraits, 22 image rows, Gese closed, Sapp seated as acting sheriff.';
END $$;

COMMIT;
