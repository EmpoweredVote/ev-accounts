-- CA_0134_monroe_2026_candidate_profiles_phase2.sql
--
-- Candidate PROFILE enrichment (portraits + websites ONLY) for the LOCAL slice of the Monroe
-- County, Indiana Nov 3 2026 ballot: townships, school boards, Ellettsville (52 candidates).
-- Election `21190350-91e3-4c2c-938d-9cf8f4ac9d5c`. Scope: portraits + websites only (operator
-- decision). Party is never stored.
--
-- Low yield is expected and correct here: Indiana township/school candidates overwhelmingly have
-- no published photo or website (Ballotpedia = photoless stubs; confirmed across the field). A
-- blank is the honest result. Six research agents + a manual pass produced enrichments for 8 of
-- the 52; the rest stay name-only. (The Greater Bloomington Chamber 2026 candidate page was behind
-- a Cloudflare human-check and could not be read — a possible future source.)
--
-- WHAT THIS DOES:
--   1. Links 3 unlinked race_candidates to the person's EXISTING politician record (no duplicates):
--        Sean McInerney -> 327c1877 (already has a portrait + a website; verified same person),
--        Ashley Pirani  -> 556a7d23 (already has a portrait + a website; verified same person),
--        Rachael Himsel -> 4f56cccb (empty active stub; adds a campaign-Facebook website).
--   2. Uploads + sets ONE new portrait: Michelle Bright (dual write photo_custom_url +
--        politician_images + card photo_url), image pre-hosted in the bucket.
--   3. Sets a website (politicians.urls, only where empty) for 6 people, and mirrors portrait +
--        website onto race_candidates (photo_url / website_url) so the election CARD shows them.
--
-- McInerney/Pirani already carry their own portrait + urls; those are NOT overwritten. Their card
-- fields are mirrored from their existing politician row. Ordering: politician photo/urls set
-- BEFORE the race_candidate is linked, so the mig-775 mirror trigger no-ops.
--
-- Idempotent: guards on NOT EXISTS / empty-only / IS DISTINCT. Re-running changes nothing.

BEGIN;

-- ── pre-flight gate ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n_badrc int; n_missing int; n_override int;
BEGIN
  -- the 8 race_candidates must be on the target election
  SELECT count(*) INTO n_badrc FROM (VALUES
    ('6bfaecc9-6a8d-4d8f-993d-f50ed6fad763'::uuid),('d296e0d3-74ec-4a10-916f-16a4406ec645'),
    ('742dc5b4-24bd-4091-849e-ead6aecbf8a1'),('45ca64d3-9d3d-4d85-8bb0-ea0b80960bbf'),
    ('88bb2862-33c3-456d-89a6-fb2a11c4ca9f'),('19485c80-b2c1-49da-8c52-3c1bcd1376c2'),
    ('25529a25-d3be-41b9-adcc-74ad1b9b2897'),('96603469-1699-46e5-b083-3ea804cee737')
  ) t(rc)
  WHERE NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc JOIN essentials.races r ON r.id=rc.race_id
                    WHERE rc.id=t.rc AND r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c');
  IF n_badrc <> 0 THEN RAISE EXCEPTION 'aborting: % race_candidate(s) not on target election', n_badrc; END IF;

  -- the 3 link-target politicians must exist
  SELECT count(*) INTO n_missing FROM (VALUES
    ('327c1877-4b56-4fbe-bb06-0720cb656b4b'::uuid),('556a7d23-3acb-4068-a7bc-cecf5194296c'),
    ('4f56cccb-0e22-4f55-a237-a4e5fe0f5772')
  ) t(id) WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id=t.id);
  IF n_missing <> 0 THEN RAISE EXCEPTION 'aborting: % link-target politician(s) missing', n_missing; END IF;

  -- Bright's portrait target must not be hand-locked
  SELECT count(*) INTO n_override FROM essentials.politicians
   WHERE id='c096fd15-2656-4e1c-bf86-beb506d472d7' AND photo_custom_url_manual_override IS TRUE;
  IF n_override <> 0 THEN RAISE EXCEPTION 'aborting: Bright portrait is manual-override locked'; END IF;
END $$;

-- ── 1. Bright portrait (dual write) ────────────────────────────────────────────────────────────
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'c096fd15-2656-4e1c-bf86-beb506d472d7',
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c096fd15-2656-4e1c-bf86-beb506d472d7-headshot.jpg',
       'default','press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images pi
                  WHERE pi.politician_id='c096fd15-2656-4e1c-bf86-beb506d472d7');

UPDATE essentials.politicians
SET photo_custom_url='https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c096fd15-2656-4e1c-bf86-beb506d472d7-headshot.jpg',
    photo_origin_url='https://demsforbenton.com/about-michelle/'
WHERE id='c096fd15-2656-4e1c-bf86-beb506d472d7'
  AND photo_custom_url_manual_override IS NOT TRUE
  AND coalesce(photo_custom_url,'')='' AND coalesce(photo_origin_url,'')='';

-- ── 2. websites on politician (only where the politician has none) ───────────────────────────────
UPDATE essentials.politicians p
SET urls = ARRAY[v.web]
FROM (VALUES
  ('c096fd15-2656-4e1c-bf86-beb506d472d7'::uuid,'https://demsforbenton.com/about-michelle/'),
  ('04d2e529-5456-44bb-a20f-b1ec676c2c22','https://demsforbenton.com/about-joe/'),
  ('6775a8e6-37cb-437b-923b-5f664f6b3b5d','https://www.in.gov/townships/saltcreek53/'),
  ('7f3c23d7-3878-4735-9e2c-a805413a9c6b','https://www.in.gov/townships/perry53/'),
  ('be355b0e-79a9-4af2-9926-d5bee7ae2515','http://www.washtownship-in.org/'),
  ('4f56cccb-0e22-4f55-a237-a4e5fe0f5772','https://facebook.com/rachaelhimsel')
) v(pid, web)
WHERE p.id=v.pid AND coalesce(array_length(p.urls,1),0)=0 AND coalesce(p.web_form_url,'')='';

-- ── 3. link the 3 unlinked race_candidates (politician already populated -> mirror trigger no-ops)
UPDATE essentials.race_candidates rc
SET politician_id = v.pid
FROM (VALUES
  ('25529a25-d3be-41b9-adcc-74ad1b9b2897'::uuid,'327c1877-4b56-4fbe-bb06-0720cb656b4b'::uuid),
  ('96603469-1699-46e5-b083-3ea804cee737','556a7d23-3acb-4068-a7bc-cecf5194296c'),
  ('19485c80-b2c1-49da-8c52-3c1bcd1376c2','4f56cccb-0e22-4f55-a237-a4e5fe0f5772')
) v(rc, pid)
WHERE rc.id=v.rc AND rc.politician_id IS NULL;

-- ── 4. card photo_url ────────────────────────────────────────────────────────────────────────
-- Bright: her freshly-hosted bucket image
UPDATE essentials.race_candidates
SET photo_url='https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c096fd15-2656-4e1c-bf86-beb506d472d7-headshot.jpg'
WHERE id='6bfaecc9-6a8d-4d8f-993d-f50ed6fad763' AND coalesce(photo_url,'')='';
-- McInerney / Pirani: mirror their EXISTING politician portrait onto the card
UPDATE essentials.race_candidates rc
SET photo_url = coalesce(p.photo_custom_url,
      (SELECT pi.url FROM essentials.politician_images pi WHERE pi.politician_id=p.id AND pi.type='default' LIMIT 1))
FROM essentials.politicians p
WHERE rc.id IN ('25529a25-d3be-41b9-adcc-74ad1b9b2897','96603469-1699-46e5-b083-3ea804cee737')
  AND rc.politician_id=p.id AND coalesce(rc.photo_url,'')=''
  AND coalesce(p.photo_custom_url, (SELECT pi.url FROM essentials.politician_images pi WHERE pi.politician_id=p.id AND pi.type='default' LIMIT 1)) IS NOT NULL;

-- ── 5. card website_url ──────────────────────────────────────────────────────────────────────
-- the 6 people who got a fresh politician url (and Himsel's FB)
UPDATE essentials.race_candidates rc
SET website_url = v.web
FROM (VALUES
  ('6bfaecc9-6a8d-4d8f-993d-f50ed6fad763'::uuid,'https://demsforbenton.com/about-michelle/'),
  ('d296e0d3-74ec-4a10-916f-16a4406ec645','https://demsforbenton.com/about-joe/'),
  ('742dc5b4-24bd-4091-849e-ead6aecbf8a1','https://www.in.gov/townships/saltcreek53/'),
  ('45ca64d3-9d3d-4d85-8bb0-ea0b80960bbf','https://www.in.gov/townships/perry53/'),
  ('88bb2862-33c3-456d-89a6-fb2a11c4ca9f','http://www.washtownship-in.org/'),
  ('19485c80-b2c1-49da-8c52-3c1bcd1376c2','https://facebook.com/rachaelhimsel')
) v(rc, web)
WHERE rc.id=v.rc AND coalesce(rc.website_url,'')='';
-- McInerney / Pirani: mirror their EXISTING first url onto the card
UPDATE essentials.race_candidates rc
SET website_url = p.urls[1]
FROM essentials.politicians p
WHERE rc.id IN ('25529a25-d3be-41b9-adcc-74ad1b9b2897','96603469-1699-46e5-b083-3ea804cee737')
  AND rc.politician_id=p.id AND coalesce(rc.website_url,'')='' AND coalesce(array_length(p.urls,1),0)>0;

-- ── post-verify gate ───────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n_link int; n_bright_img int; n_bright_custom int; n_polurl int; n_rcphoto int; n_rcsite int;
BEGIN
  SELECT count(*) INTO n_link FROM (VALUES
    ('25529a25-d3be-41b9-adcc-74ad1b9b2897'::uuid,'327c1877-4b56-4fbe-bb06-0720cb656b4b'::uuid),
    ('96603469-1699-46e5-b083-3ea804cee737','556a7d23-3acb-4068-a7bc-cecf5194296c'),
    ('19485c80-b2c1-49da-8c52-3c1bcd1376c2','4f56cccb-0e22-4f55-a237-a4e5fe0f5772')
  ) v(rc,pid) JOIN essentials.race_candidates rc ON rc.id=v.rc WHERE rc.politician_id=v.pid;
  IF n_link <> 3 THEN RAISE EXCEPTION 'expected 3 linked, found %', n_link; END IF;

  SELECT count(*) INTO n_bright_img FROM essentials.politician_images
   WHERE politician_id='c096fd15-2656-4e1c-bf86-beb506d472d7' AND url LIKE '%c096fd15-2656-4e1c-bf86-beb506d472d7-headshot.jpg';
  IF n_bright_img <> 1 THEN RAISE EXCEPTION 'expected Bright image row, found %', n_bright_img; END IF;

  SELECT count(*) INTO n_bright_custom FROM essentials.politicians
   WHERE id='c096fd15-2656-4e1c-bf86-beb506d472d7' AND photo_custom_url LIKE '%storage.supabase.co%';
  IF n_bright_custom <> 1 THEN RAISE EXCEPTION 'expected Bright photo_custom_url, found %', n_bright_custom; END IF;

  SELECT count(*) INTO n_polurl FROM (VALUES
    ('c096fd15-2656-4e1c-bf86-beb506d472d7'::uuid),('04d2e529-5456-44bb-a20f-b1ec676c2c22'),
    ('6775a8e6-37cb-437b-923b-5f664f6b3b5d'),('7f3c23d7-3878-4735-9e2c-a805413a9c6b'),
    ('be355b0e-79a9-4af2-9926-d5bee7ae2515'),('4f56cccb-0e22-4f55-a237-a4e5fe0f5772')
  ) v(pid) JOIN essentials.politicians p ON p.id=v.pid WHERE coalesce(array_length(p.urls,1),0)>0;
  IF n_polurl <> 6 THEN RAISE EXCEPTION 'expected 6 politician urls set, found %', n_polurl; END IF;

  SELECT count(*) INTO n_rcphoto FROM essentials.race_candidates
   WHERE id IN ('6bfaecc9-6a8d-4d8f-993d-f50ed6fad763','25529a25-d3be-41b9-adcc-74ad1b9b2897','96603469-1699-46e5-b083-3ea804cee737')
     AND coalesce(photo_url,'')<>'';
  IF n_rcphoto <> 3 THEN RAISE EXCEPTION 'expected 3 rc.photo_url set, found %', n_rcphoto; END IF;

  SELECT count(*) INTO n_rcsite FROM essentials.race_candidates
   WHERE id IN ('6bfaecc9-6a8d-4d8f-993d-f50ed6fad763','d296e0d3-74ec-4a10-916f-16a4406ec645',
     '742dc5b4-24bd-4091-849e-ead6aecbf8a1','45ca64d3-9d3d-4d85-8bb0-ea0b80960bbf',
     '88bb2862-33c3-456d-89a6-fb2a11c4ca9f','19485c80-b2c1-49da-8c52-3c1bcd1376c2',
     '25529a25-d3be-41b9-adcc-74ad1b9b2897','96603469-1699-46e5-b083-3ea804cee737')
     AND coalesce(website_url,'')<>'';
  IF n_rcsite <> 8 THEN RAISE EXCEPTION 'expected 8 rc.website_url set, found %', n_rcsite; END IF;

  RAISE NOTICE 'ok CA_0134: 3 linked, 1 new portrait (Bright) + 2 mirrored, 6 politician urls, 8 cards';
END $$;

COMMIT;
