-- CC_0254_offsite_render_columns_and_mirrors.sql
--
-- Fixes the 101 active rows whose PROFILE renders an off-site URL, in two parts.
-- Follows CC_0253, which replaced nine headshots containing no face.
--
-- 🔴 WHY THESE WERE NOT FOUND EARLIER: our storage answers to TWO hostnames --
-- <ref>.storage.supabase.co AND <ref>.supabase.co -- and the first sweep's predicate,
-- LIKE '%storage.supabase.co%', matched only the first. It called 1,279 of OUR OWN files
-- "hotlinked to an outside host" and skipped them entirely. Match the PATH both share:
-- '%supabase.co/storage/v1/object/public/%'. Only 102 rows are genuinely off-site.
--
-- ─── PART A: 86 rows that ALREADY HAVE a photo, with nothing pointing at it ────────────────
--
-- These hold a real portrait on our CDN in politician_images (type='default') while
-- photo_custom_url is NULL. The two read paths disagree, so the defect is INVISIBLE on one
-- surface and live on the other:
--   browse grid  -> reads images[] FIRST                          -> renders fine
--   profile      -> COALESCE(photo_custom_url, photo_origin_url)  -> falls through to
--                   photo_origin_url, which holds the PAGE the roster was scraped from,
--                   and hands an HTML document to an <img src>.
--
-- 🔴 82 OF THE 86 SHARE ONE URL: https://apps.arizona.vote/electioninfo/Election/69 -- the
-- Arizona Secretary of State election-info page, written into a photo column for every
-- candidate harvested from it (CA_0282). The other four are 3 ballotpedia.org article URLs
-- and mckenna.vote's site root.
--
-- ⚠ ALL 82 READ "UNREACHABLE / HTTP 403" ON THE FIRST SWEEP, which looks like a dead link.
-- Re-probed with a browser User-Agent they return an HTML page: the URL is not an image at
-- all. A 403 is not evidence a link is broken, only that you have not seen the response.
--
-- This is the orphan cohort of project_photo_custom_url_is_what_renders recurring -- the same
-- importer defect that left 133 rows unrendered on 2026-09-03. No new image is introduced, so
-- there is NO identity risk: the fix only points the render column at the photo the row
-- already owns. All 86 of those CDN photos were face-checked first -- 86 OK, 0 flagged.
--
-- photo_origin_url is LEFT ALONE on purpose. It is provenance, and the page really is where
-- the record came from. Once photo_custom_url is set, the COALESCE never reaches it.
--
-- ─── PART B: 14 genuinely external images, mirrored ────────────────────────────────────────
--
-- Real portraits on outside hosts that were never copied into our bucket. Downloaded, run
-- through the same pipeline the importer now uses (EXIF applied, alpha composited, face
-- asserted at four rotations, crop placed from the measured face box, 600x750 q90), uploaded
-- with x-upsert, and byte-verified served: HTTP 200, image/jpeg, sha256 identical to the
-- local file. Sources: sboe.dc.gov x9, utelection.info x3, evandone.com, squarespace-cdn.
--
-- ⚠ FOURTEEN, NOT FIFTEEN. Tayler Khater is DELIBERATELY EXCLUDED: her live headshot is a
-- FAMILY HOLIDAY PHOTOGRAPH -- two adults and three children in a canyon -- and it is not
-- possible to tell which adult she is. Cropping to a guessed face is precisely the
-- wrong-person error, so her row is untouched and left for a human decision.
-- 🔴 THAT PHOTO PASSES THE FACE GATE, because a group photo has faces in it.
-- check-headshot-faces.py cannot tell a portrait from a snapshot; only looking at it can.
--
-- ⚠ UPSCALES, stated rather than hidden. Eight DC board portraits are 448x600 (1.34x), Paxman
-- 440x440 (1.70x), and BRENT BOWLES IS 136x160 (4.69x) -- visibly soft. That is the largest
-- image of him in policy: his campaign site is a 3KB stub with no portrait, and the only other
-- photograph is a newspaper's. Mirrored anyway, because the live hotlink is that same file and
-- the browser was already enlarging it; flagged here so a better source can replace it.
-- ▶ A placement rule that sizes the frame from the FACE becomes an ENLARGEMENT rule on a small
--   source: unfloored, Khater's crop came out 72px wide for an 8.3x blow-up. The crop width is
--   floored at min(source width, 600).
--
-- 🔴 URLs CARRY ?v=20261019 for the same reason as CC_0253: overwriting a storage object does
-- not change what the public CDN serves.
--
-- 🔴 BOTH SIDES ARE WRITTEN throughout. Idempotent: re-running changes nothing.

BEGIN;

-- ═══ PART A ═══════════════════════════════════════════════════════════════════════════════

CREATE TEMP TABLE _orphan_render AS
SELECT p.id AS politician_id, pi.url
FROM essentials.politicians p
JOIN essentials.politician_images pi ON pi.politician_id = p.id AND pi.type = 'default'
WHERE p.is_active = true
  AND p.photo_custom_url IS NULL
  AND p.photo_origin_url IS NOT NULL AND p.photo_origin_url <> ''
  AND p.photo_origin_url NOT LIKE '%supabase.co/storage/v1/object/public/%'
  AND pi.url LIKE '%supabase.co/storage/v1/object/public/%';

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM _orphan_render;
  IF n <> 86 THEN
    RAISE EXCEPTION 'CC_0254: expected 86 orphaned render columns, found % -- the set moved, re-measure before writing', n;
  END IF;
END $$;

-- ⚠ ALIAS `ren`, DELIBERATELY NOT AN "o" WORD. This temp table was once aliased with a bare
-- "o", and check:occupancy matches the ALIAS SHAPE — any alias beginning with that letter, bar
-- och/ot — so it read a reference to the dropped offices column that was never here, and failed
-- every run of PR #1046. The guard is right to be blunt: it cannot know a temp table from a
-- table. Renaming to a non-matching alias was the cheap fix; renaming to one that still began
-- with that letter was NOT, and cost a second red run. No semantic change, and the migration
-- had already been applied as written. 2026-10-20.
UPDATE essentials.politicians p
SET photo_custom_url = ren.url
FROM _orphan_render ren
WHERE p.id = ren.politician_id AND p.photo_custom_url IS DISTINCT FROM ren.url;

-- ═══ PART B ═══════════════════════════════════════════════════════════════════════════════

CREATE TEMP TABLE _mirrored (
  politician_id uuid PRIMARY KEY,
  name_like     text NOT NULL,
  url           text NOT NULL,
  origin_url    text NOT NULL,
  photo_license text NOT NULL
) ON COMMIT DROP;

INSERT INTO _mirrored (politician_id, name_like, url, origin_url, photo_license) VALUES
  ('55653ccb-75e1-43b7-8de3-0a97c69da52b'::uuid, 'Allister Chang',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/55653ccb-75e1-43b7-8de3-0a97c69da52b-headshot.jpg?v=20261019',
   'https://sboe.dc.gov/sites/default/files/dc/sites/sboe/multimedia_content/images/Chang%20Headshot%202025.jpeg', 'press_use'),
  ('a4d74758-4bdb-4060-a345-763e0a7f54d9'::uuid, 'Ben Williams',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a4d74758-4bdb-4060-a345-763e0a7f54d9-headshot.jpg?v=20261019',
   'https://sboe.dc.gov/sites/default/files/dc/sites/sboe/multimedia_content/images/Williams%20Headshot%202025.jpeg', 'press_use'),
  ('0a03981a-1b37-4596-bab8-1579316ab851'::uuid, 'Brandon Best',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0a03981a-1b37-4596-bab8-1579316ab851-headshot.jpg?v=20261019',
   'https://sboe.dc.gov/sites/default/files/dc/sites/sboe/multimedia_content/images/Best%20Headshot%202025.jpeg', 'press_use'),
  ('b71ec1b6-7d9e-406b-a30a-8c0710278d5e'::uuid, 'Brent Bowles',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b71ec1b6-7d9e-406b-a30a-8c0710278d5e-headshot.jpg?v=20261019',
   'https://utelection.info/wp-content/uploads/2026/03/Brent-Bowles-1.png', 'press_use'),
  ('2ddafa6c-f5b8-40d6-a8d8-fce8f4849463'::uuid, 'Carolina Herrin',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2ddafa6c-f5b8-40d6-a8d8-fce8f4849463-headshot.jpg?v=20261019',
   'https://utelection.info/wp-content/uploads/2026/03/IMG_8940.jpeg1_.jpg', 'press_use'),
  ('7df6901d-af55-4811-9f1d-c03d0b99c52b'::uuid, 'Eboni-Rose Thompson',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7df6901d-af55-4811-9f1d-c03d0b99c52b-headshot.jpg?v=20261019',
   'https://sboe.dc.gov/sites/default/files/dc/sites/sboe/multimedia_content/images/Thompson%20Headshot%202025.jpeg', 'press_use'),
  ('e8d68d3a-62ab-4e10-b93a-e521b131fc50'::uuid, 'Eric Goulet',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e8d68d3a-62ab-4e10-b93a-e521b131fc50-headshot.jpg?v=20261019',
   'https://sboe.dc.gov/sites/default/files/dc/sites/sboe/multimedia_content/images/photobatch-27-2.jpg', 'press_use'),
  ('77dc9a42-5f37-4608-89a1-10e60f86a3a1'::uuid, 'Evan Done',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/77dc9a42-5f37-4608-89a1-10e60f86a3a1-headshot.jpg?v=20261019',
   'https://www.evandone.com/wp-content/uploads/2026/03/Evan-Done-outside-Capitol.png', 'press_use'),
  ('b4aac990-f353-4ea7-bdb3-d5cf2cd232c8'::uuid, 'Isaac Paxman',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b4aac990-f353-4ea7-bdb3-d5cf2cd232c8-headshot.jpg?v=20261019',
   'https://utelection.info/wp-content/uploads/2026/03/Issac-Paxman.jpg', 'press_use'),
  ('9fc8db1d-4fae-40c3-9eb2-cd7da6d4b154'::uuid, 'Jacque Patterson',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9fc8db1d-4fae-40c3-9eb2-cd7da6d4b154-headshot.jpg?v=20261019',
   'https://sboe.dc.gov/sites/default/files/dc/sites/sboe/multimedia_content/images/Patterson%20Headshot%202025.jpeg', 'press_use'),
  ('2c70c489-c12a-4085-b4ba-b697e75f71d9'::uuid, 'LaJoy Johnson-Law',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2c70c489-c12a-4085-b4ba-b697e75f71d9-headshot.jpg?v=20261019',
   'https://sboe.dc.gov/sites/default/files/dc/sites/sboe/multimedia_content/images/Johnson-Law%20Headshot%202025.jpeg', 'press_use'),
  ('43cf9678-cb25-4963-aa52-82e1fb54f2e4'::uuid, 'Robert Henderson',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/43cf9678-cb25-4963-aa52-82e1fb54f2e4-headshot.jpg?v=20261019',
   'https://sboe.dc.gov/sites/default/files/dc/sites/sboe/multimedia_content/images/Henderson%20Headshot%202025.jpeg', 'press_use'),
  ('7cd5d5a4-f308-428d-8b19-57be65bd0340'::uuid, 'T. Michelle Colson',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7cd5d5a4-f308-428d-8b19-57be65bd0340-headshot.jpg?v=20261019',
   'https://sboe.dc.gov/sites/default/files/dc/sites/sboe/multimedia_content/images/Colson%20Headshot%202025.jpeg', 'press_use'),
  ('327298e7-e42c-4dfa-9f1d-55cfd48e0659'::uuid, 'Taylor J. Paden',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/327298e7-e42c-4dfa-9f1d-55cfd48e0659-headshot.jpg?v=20261019',
   'https://images.squarespace-cdn.com/content/v1/6963f876ff6ab07c41a599cf/e4c5e86d-b55d-4832-8748-3adbf56c46ad/EHM00092.png', 'press_use');

-- Guard: every id must still resolve to the person this migration believes it is.
DO $$
DECLARE r record; v_name text;
BEGIN
  FOR r IN SELECT * FROM _mirrored LOOP
    SELECT p.full_name INTO v_name FROM essentials.politicians p WHERE p.id = r.politician_id;
    IF v_name IS NULL THEN
      RAISE EXCEPTION 'CC_0254: % matches no politician row', r.politician_id;
    END IF;
    IF v_name <> r.name_like THEN
      RAISE EXCEPTION 'CC_0254: % resolves to "%", expected "%"', r.politician_id, v_name, r.name_like;
    END IF;
  END LOOP;
END $$;

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT m.politician_id, m.url, 'default', m.photo_license
FROM _mirrored m
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images pi
  WHERE pi.politician_id = m.politician_id AND pi.type = 'default');

UPDATE essentials.politician_images pi
SET url = m.url, photo_license = m.photo_license
FROM _mirrored m
WHERE pi.politician_id = m.politician_id AND pi.type = 'default'
  AND (pi.url IS DISTINCT FROM m.url OR pi.photo_license IS DISTINCT FROM m.photo_license);

UPDATE essentials.politicians p
SET photo_custom_url = m.url
FROM _mirrored m
WHERE p.id = m.politician_id AND p.photo_custom_url IS DISTINCT FROM m.url;

-- ═══ POST-VERIFY ══════════════════════════════════════════════════════════════════════════

DO $$
DECLARE n_a int; n_b int; n_mismatch int; n_multi int; n_left int;
BEGIN
  SELECT count(*) INTO n_a
    FROM _orphan_render ren JOIN essentials.politicians p
      ON p.id = ren.politician_id AND p.photo_custom_url = ren.url;
  IF n_a <> 86 THEN
    RAISE EXCEPTION 'CC_0254 Part A: expected 86 render columns written, found %', n_a;
  END IF;

  SELECT count(*) INTO n_b
    FROM _mirrored m
    JOIN essentials.politicians p ON p.id = m.politician_id AND p.photo_custom_url = m.url
    JOIN essentials.politician_images pi ON pi.politician_id = m.politician_id
     AND pi.type = 'default' AND pi.url = m.url AND pi.photo_license = m.photo_license;
  IF n_b <> 14 THEN
    RAISE EXCEPTION 'CC_0254 Part B: expected 14 mirrored rows on both sides, found %', n_b;
  END IF;

  SELECT count(*) INTO n_mismatch
    FROM essentials.politicians p
    JOIN essentials.politician_images pi ON pi.politician_id = p.id AND pi.type = 'default'
   WHERE p.id IN (SELECT politician_id FROM _orphan_render
                  UNION SELECT politician_id FROM _mirrored)
     AND p.photo_custom_url IS DISTINCT FROM pi.url;
  IF n_mismatch <> 0 THEN
    RAISE EXCEPTION 'CC_0254: scalar and images[] disagree for % row(s)', n_mismatch;
  END IF;

  SELECT count(*) INTO n_multi FROM (
    SELECT pi.politician_id FROM essentials.politician_images pi
    WHERE pi.type = 'default'
      AND pi.politician_id IN (SELECT politician_id FROM _orphan_render
                               UNION SELECT politician_id FROM _mirrored)
    GROUP BY pi.politician_id HAVING count(*) > 1) x;
  IF n_multi <> 0 THEN
    RAISE EXCEPTION 'CC_0254: % politician(s) carry more than one default image row', n_multi;
  END IF;

  -- Exactly ONE active row may still render off-site: Tayler Khater, left by decision.
  SELECT count(*) INTO n_left
    FROM essentials.politicians p
   WHERE p.is_active = true AND p.photo_custom_url IS NULL
     AND p.photo_origin_url IS NOT NULL AND p.photo_origin_url <> ''
     AND p.photo_origin_url NOT LIKE '%supabase.co/storage/v1/object/public/%';
  IF n_left <> 1 THEN
    RAISE EXCEPTION 'CC_0254: expected exactly 1 row still rendering off-site (Khater), found %', n_left;
  END IF;

  RAISE NOTICE 'CC_0254 OK - 86 render columns written, 14 mirrored, 1 left by decision';
END $$;

DROP TABLE _orphan_render;

COMMIT;

-- ───────────────────────────────────────────────────────────────────────────────────────────
-- OWED
--   Tayler Khater (Utah) -- her headshot is a family holiday photograph. Needs a real portrait,
--     or photo_origin_url CLEARED so she reads as "needs a headshot" rather than showing a
--     family snapshot as a civic portrait. A blank beats a link.
--   Brent Bowles -- mirrored at a 4.69x upscale from 136x160. Replace when a better source
--     exists; his campaign site had none on 2026-10-19.
--   🔴 The face gate cannot tell a GROUP PHOTO from a portrait. Khater's passed it.
-- ───────────────────────────────────────────────────────────────────────────────────────────
