-- CA_0131_monroe_2026_candidate_profiles_phase1.sql
--
-- Candidate PROFILE enrichment (portraits + websites ONLY) for the "well-sourced" first slice of
-- the Monroe County, Indiana Nov 3 2026 ballot: the 3 statewide execs, U.S. House IN-9, the four
-- Indiana House seats (46/60/61/62), and the Monroe County row offices/council/judges.
-- Election `21190350-91e3-4c2c-938d-9cf8f4ac9d5c` (IN 2026 Statewide General).
--
-- SCOPE (operator decision 2026-09-21): portraits + websites only. NO bio, NO occupation.
-- Party is never stored (antipartisan model).
--
-- WHAT THIS DOES, for 17 candidates who were missing a portrait and/or a website:
--   1. Creates 5 minimal politician records (Bailey, Schick, Ballard, Engling, Trimble) that had
--      no DB record at all, and links their race_candidate row.
--   2. Links 4 already-existing empty `indiana_discovery` stubs (Bayh, Kebe, Pittsford, Shillings)
--      to their race_candidate row instead of creating duplicates (collision guard run 2026-09-21:
--      each had 0 answers / 0 images / 0 office_terms).
--   3. Sets the portrait for 12 of them via the DUAL WRITE required by the read path
--      (COALESCE(photo_custom_url, photo_origin_url)): photo_custom_url = the hosted bucket image,
--      photo_origin_url = the source page, PLUS a politician_images row. Model = migration 1703.
--   4. Sets the website on 15 of them (politicians.urls) and mirrors portrait/website onto the
--      race_candidate row (photo_url / website_url) so the election CARD shows them too.
--
-- Images were pre-uploaded to Storage bucket `politician_photos/{politician_id}-headshot.jpg`
-- (4:5, 600x750) and their public URLs verified 200 before this migration was authored.
--
-- Portrait licences: press_use (campaign/party sites), public_domain (Wikimedia Ballard, Monroe
-- County .gov Hawk), unknown (Bayh + Schick — only a ballot-info aggregator headshot exists; the
-- operator approved importing them recorded as 'unknown').
--
-- Ordering matters: politician photo/urls are set BEFORE the race_candidate is linked, so the
-- migration-775 mirror trigger (AFTER INSERT OR UPDATE OF politician_id, photo_url, website_url)
-- finds the politician already populated and no-ops — we keep the real licence + source page.
--
-- Idempotent: guards on NOT EXISTS / IS DISTINCT / empty-only, so re-running changes nothing.

BEGIN;

CREATE TEMP TABLE _prof (
  rc_id         uuid PRIMARY KEY,
  politician_id uuid NOT NULL,
  is_new        boolean NOT NULL,
  full_name     text NOT NULL,
  first_name    text NOT NULL,
  last_name     text NOT NULL,
  portrait_lic  text,          -- NULL = no portrait for this person
  portrait_src  text,          -- source page for photo_origin_url
  website       text           -- NULL = no website found
) ON COMMIT DROP;

INSERT INTO _prof (rc_id, politician_id, is_new, full_name, first_name, last_name, portrait_lic, portrait_src, website) VALUES
 -- ── statewide execs ──────────────────────────────────────────────────────────────────────────
 ('58ed48f9-ec36-48e7-97b4-0102b979af23','fcddc6fe-4ae7-4c22-970d-8022f59b4905', true,  'Jessica Bailey','Jessica','Bailey','press_use',    'https://baileyforindiana.com/',                                   'https://baileyforindiana.com/'),
 ('8c4d3563-58e4-4b69-8d5c-ffef2e93ce29','bc54f404-d2d3-4fba-b2c4-94a65d6d4db7', true,  'John Schick','John','Schick','unknown',              'https://www.ballotready.org/in/indiana-indiana-state-auditor/john-schick', NULL),
 ('5bb6c9fe-c171-4fb8-b8ed-04f0808de70d','8cd8842e-5162-4f60-b8bd-d10eca847785', true,  'Greg Ballard','Greg','Ballard','public_domain',      'https://commons.wikimedia.org/wiki/File:GregBallard.jpg',         'https://gregballard.com/'),
 ('3e9c137c-32c2-4ea2-ae4e-fad908d20d8c','f7ab655e-48bd-4e51-b22f-5ca6128f2f66', true,  'Max Engling','Max','Engling','press_use',            'https://maxforindiana.com/',                                      'https://maxforindiana.com/'),
 ('8a4406a2-f473-4b44-9333-4caa2993a4a0','d213077c-770a-4fcd-8e53-08133a8b7789', false, 'Beau Bayh','Beau','Bayh','unknown',                   'https://www.ballotready.org/people/beau-bayh',                    'https://beaubayh.com/'),
 ('8effd903-9ccf-451e-a7d4-44e213c1d06b','573f8e55-bf3b-4c12-8377-20941b60196f', false, 'Lauri A. Shillings','Lauri','Shillings','press_use',  'https://www.lauriforliberty.com/',                                'https://www.lauriforliberty.com/'),
 ('cb1562c5-66ff-44d1-98e3-436cc3413228','7eb64d2a-2e0a-477e-b3fd-50c26809838c', false, 'Coumba Kebe','Coumba','Kebe','press_use',            'https://www.hamcodemsin.org/candidates/coumba-kebe',              'https://www.kebeforindiana.com/'),
 -- ── Indiana House 46/60/62 ───────────────────────────────────────────────────────────────────
 ('b6a442c8-f286-4438-88e0-e9900d7e42f6','6b3fad05-cc7e-4d4f-aff7-a7959d60722c', false, 'James H. Pittsford III','James','Pittsford','press_use','https://www.pittsford4indiana.com',                              'https://www.pittsford4indiana.com'),
 ('ca3a0f51-5087-4735-84e8-f85b881236a6','a6926086-aa11-4f42-bcd7-bf74c1e1a540', false, 'Amy Huffman Oliver','Amy','Oliver','press_use',       'https://www.voteamyoliver.com/',                                  'https://www.voteamyoliver.com/'),
 ('19c86d18-86b5-4e31-aa75-d84b5286c9c8','35392708-1b50-48e0-a62d-b09c61a25192', false, 'Carrie L. Syczylo','Carrie','Syczylo','press_use',    'https://www.carriecareshd60.com/meet-carrie',                     'https://www.carriecareshd60.com/'),
 -- ── U.S. House IN-9 (websites only; portraits already on file) ────────────────────────────────
 ('d278a287-7d6a-4c73-931a-729d2c12a164','926943ad-ee64-4ddb-b9e7-6475a6a2d087', false, 'Brad Meyer','Brad','Meyer', NULL, NULL,               'https://bradmeyer.org/'),
 ('56d27871-8a5d-4ab4-a8ff-ac744ce959dc','8f08a551-71c8-43c4-9bcc-b18fd3ac0abc', false, 'Tonya Hudson','Tonya','Hudson', NULL, NULL,           'https://tonyaforcongress.com/'),
 -- ── Monroe County offices ────────────────────────────────────────────────────────────────────
 ('39cdf69e-556c-4504-9671-aa60237b602e','ba1e0001-2026-4000-8000-000000000013', false, 'Judith A. Sharp','Judith','Sharp', NULL, NULL,        'https://www.in.gov/counties/monroe/Departments/assessor'),
 ('e2e4bf3c-f33f-46c5-b696-93e88a934911','ba1e0001-2026-4000-8000-000000000008', false, 'Julie M. Hays','Julie','Hays', NULL, NULL,            NULL),
 ('20687493-05ec-4a05-bbbc-6ecf08c45972','ba1e0001-2026-4000-8000-000000000010', false, 'Tree Martin-Lucas','Tree','Lucas','press_use',        'https://treeforclerk.org/',                                       'https://treeforclerk.org/'),
 ('c126cf5c-5721-47fb-b360-ca71bebe8971','6972209b-13b7-4595-b7f1-8f6df06de1e9', false, 'Martha Hawk','Martha','Hawk','public_domain',         'https://www.in.gov/counties/monroe/Departments/council/',         'https://www.in.gov/counties/monroe/Departments/council/'),
 ('7a1b9567-52eb-4e4a-80ef-da397134d8d2','43c7e0fa-ef31-44b5-8044-75f351e83af8', true,  'Lisa Jeneé Trimble','Lisa','Trimble', NULL, NULL,     'https://www.facebook.com/profile.php?id=61579213137075');

-- bucket URL derived from politician_id, so it always matches what was uploaded
CREATE TEMP VIEW _profx AS
  SELECT *,
    'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/'
      || politician_id || '-headshot.jpg' AS bucket_url
  FROM _prof;

-- ── pre-flight gate ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n_badrc int; n_override int; n_reuse_missing int;
BEGIN
  -- every race_candidate must exist on THIS election
  SELECT count(*) INTO n_badrc FROM _prof t
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    WHERE rc.id = t.rc_id AND r.election_id = '21190350-91e3-4c2c-938d-9cf8f4ac9d5c');
  IF n_badrc <> 0 THEN RAISE EXCEPTION 'aborting: % race_candidate(s) not on the target election', n_badrc; END IF;

  -- every reuse target politician must already exist
  SELECT count(*) INTO n_reuse_missing FROM _prof t
  WHERE t.is_new = false
    AND NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = t.politician_id);
  IF n_reuse_missing <> 0 THEN RAISE EXCEPTION 'aborting: % reuse-target politician(s) missing', n_reuse_missing; END IF;

  -- never touch a hand-locked portrait
  SELECT count(*) INTO n_override FROM _prof t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE t.portrait_lic IS NOT NULL AND p.photo_custom_url_manual_override IS TRUE;
  IF n_override <> 0 THEN RAISE EXCEPTION 'aborting: % portrait target(s) are manual-override locked', n_override; END IF;
END $$;

-- ── 1. create the 5 new politician records ─────────────────────────────────────────────────────
INSERT INTO essentials.politicians (id, full_name, first_name, last_name, is_active, is_incumbent, source)
SELECT t.politician_id, t.full_name, t.first_name, t.last_name, true, false, 'CA_0131_monroe_2026_candidate_profiles'
FROM _prof t
WHERE t.is_new = true
ON CONFLICT (id) DO NOTHING;

-- ── 2. portrait: politician_images (once per person) + photo_custom_url + photo_origin_url ──────
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT x.politician_id, x.bucket_url, 'default', x.portrait_lic
FROM _profx x
WHERE x.portrait_lic IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = x.politician_id);

UPDATE essentials.politicians p
SET photo_custom_url = x.bucket_url,
    photo_origin_url = x.portrait_src
FROM _profx x
WHERE p.id = x.politician_id
  AND x.portrait_lic IS NOT NULL
  AND p.photo_custom_url_manual_override IS NOT TRUE
  AND coalesce(p.photo_custom_url, '') = ''      -- never overwrite an existing portrait
  AND coalesce(p.photo_origin_url, '') = '';

-- ── 3. website: politicians.urls (only when the politician has none) ────────────────────────────
UPDATE essentials.politicians p
SET urls = ARRAY[t.website]
FROM _prof t
WHERE p.id = t.politician_id
  AND t.website IS NOT NULL
  AND coalesce(array_length(p.urls, 1), 0) = 0
  AND coalesce(p.web_form_url, '') = '';

-- ── 4. link the 9 unlinked race_candidates (politician already populated -> mirror trigger no-ops)
UPDATE essentials.race_candidates rc
SET politician_id = t.politician_id
FROM _prof t
WHERE rc.id = t.rc_id
  AND rc.politician_id IS NULL
  AND rc.politician_id IS DISTINCT FROM t.politician_id;

-- ── 5. mirror portrait/website onto the race_candidate row (the election CARD reads rc.*) ───────
UPDATE essentials.race_candidates rc
SET photo_url = x.bucket_url
FROM _profx x
WHERE rc.id = x.rc_id
  AND x.portrait_lic IS NOT NULL
  AND coalesce(rc.photo_url, '') = '';

UPDATE essentials.race_candidates rc
SET website_url = t.website
FROM _prof t
WHERE rc.id = t.rc_id
  AND t.website IS NOT NULL
  AND coalesce(rc.website_url, '') = '';

-- ── post-verify gate ───────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n_linked int; n_img int; n_custom int; n_urls int; n_render int; n_rcphoto int; n_rcsite int;
BEGIN
  -- all 9 formerly-unlinked candidates are now linked to the intended politician
  SELECT count(*) INTO n_linked FROM _prof t
  JOIN essentials.race_candidates rc ON rc.id = t.rc_id
  WHERE rc.politician_id = t.politician_id;
  IF n_linked <> 17 THEN RAISE EXCEPTION 'expected 17 candidates linked to intended politician, found %', n_linked; END IF;

  -- 12 portrait people each have their bucket image row + photo_custom_url on the bucket
  SELECT count(*) INTO n_img FROM _profx x
  JOIN essentials.politician_images pi ON pi.politician_id = x.politician_id AND pi.url = x.bucket_url
  WHERE x.portrait_lic IS NOT NULL;
  IF n_img <> 12 THEN RAISE EXCEPTION 'expected 12 portrait image rows, found %', n_img; END IF;

  SELECT count(*) INTO n_custom FROM _profx x
  JOIN essentials.politicians p ON p.id = x.politician_id
  WHERE x.portrait_lic IS NOT NULL AND p.photo_custom_url = x.bucket_url;
  IF n_custom <> 12 THEN RAISE EXCEPTION 'expected 12 photo_custom_url on bucket, found %', n_custom; END IF;

  -- HAS_RENDERABLE_PHOTO_SQL (verbatim from backend/src/lib/photoCoverage.ts) for the 12
  SELECT count(*) INTO n_render FROM _prof t
  JOIN essentials.politicians p ON p.id = t.politician_id
  LEFT JOIN essentials.politician_images img ON img.politician_id = p.id
  WHERE t.portrait_lic IS NOT NULL
    AND ( img.politician_id IS NOT NULL
       OR btrim(coalesce(p.photo_custom_url, '')) <> ''
       OR (btrim(coalesce(p.photo_origin_url, '')) <> '' AND p.photo_origin_url LIKE 'http%') );
  IF n_render <> 12 THEN RAISE EXCEPTION 'only % of 12 satisfy HAS_RENDERABLE_PHOTO_SQL', n_render; END IF;

  -- 15 website people have a non-empty urls[]
  SELECT count(*) INTO n_urls FROM _prof t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE t.website IS NOT NULL AND coalesce(array_length(p.urls, 1), 0) > 0;
  IF n_urls <> 15 THEN RAISE EXCEPTION 'expected 15 politicians with a website, found %', n_urls; END IF;

  -- card mirror
  SELECT count(*) INTO n_rcphoto FROM _profx x
  JOIN essentials.race_candidates rc ON rc.id = x.rc_id
  WHERE x.portrait_lic IS NOT NULL AND rc.photo_url = x.bucket_url;
  IF n_rcphoto <> 12 THEN RAISE EXCEPTION 'expected 12 race_candidate.photo_url set, found %', n_rcphoto; END IF;

  SELECT count(*) INTO n_rcsite FROM _prof t
  JOIN essentials.race_candidates rc ON rc.id = t.rc_id
  WHERE t.website IS NOT NULL AND coalesce(rc.website_url,'') <> '';
  IF n_rcsite <> 15 THEN RAISE EXCEPTION 'expected 15 race_candidate.website_url set, found %', n_rcsite; END IF;

  RAISE NOTICE 'ok CA_0131: 17 linked, 12 portraits renderable, 15 websites, card mirrored';
END $$;

COMMIT;
