-- CC_0444 — Wisconsin 2026 transition headshots, batch 2: 11 winners given a face.
--
-- Scope: the 2026-11-03 Wisconsin winners who had NO photo in any of the three places one
-- can live (politicians.photo_custom_url, a politician_images row of type 'default',
-- race_candidates.photo_url). That queue was 26 on 2026-11-08 and 20 when this was measured
-- on 2026-11-16; five had been sourced in between, and Romaine Quinn left it because a
-- duplicate person row was merged into his real one, which already held his portrait.
--
-- Sources: each person's OWN campaign site, read field by field, footer included. No image
-- was taken from an aggregator. Ballotpedia and PBS Wisconsin were used only as POINTERS to
-- find each campaign's address — the rule this repo already wrote for Ballotpedia and then
-- had to write again for BallotReady, whose terms forbid reproducing images outright.
-- Licence 'press_use' here means the site publishes no restriction on the photograph.
--
-- OVERWRITES NOTHING. Every target row had photo_custom_url NULL and zero 'default' image
-- rows at the time of writing; both statements are guarded so a value another session wrote
-- in between is kept, and the post-verify then fails loudly rather than leaving the scalar
-- and the image row disagreeing.
--
-- 🔴 BOTH COLUMNS ARE WRITTEN ON PURPOSE. politicians.photo_custom_url is what the backend
--   reads; the politician_images row of type 'default' is what the grid reads out of
--   images[]. Writing one without the other renders on one surface and blanks on the other,
--   and no gate in this repo sees it. Two rows in production already disagree this way
--   (Mark Teixeira, Vanessa Kritzer) — not touched here.
--
-- NOT IMPORTED, and why, so the next session does not re-derive it:
--   Anthony W. Phillips (AD56) — his own site publishes only a full-length photograph. The
--     one close portrait is PBS Wisconsin's; its licence could not be read. Operator held it.
--   Trevor Jung (SD21) — the available file has a second person partly in frame. Operator
--     held it. His host also refuses every non-browser client (curl and Python both get a
--     dropped connection), so any future pass needs a real browser.
--   Seven more have no usable photograph published at all; see NOTES.md. That is a finding
--     about what those campaigns publish, not a search that stopped early.
--
-- Files: backend/data/wi-transition-headshots-2026/{NOTES.md, manifest-2026-11-16.json,
--        import.py, CC_0444-rows.sql.json}

BEGIN;

DO $$
DECLARE
  v_before_scalar int;
  v_before_images int;
BEGIN
  SELECT count(*) INTO v_before_scalar
    FROM essentials.politicians
   WHERE id = ANY (ARRAY[
      '4892ed26-cdcc-4c88-82a4-b673f0b43bc9',
      'c8205f59-7eb8-444f-80e5-85911b9b99e7',
      'dbdf66f1-2673-4cd2-94cf-d92e45e616b1',
      '011bee3f-2a87-4590-893d-c6be616fa45a',
      'f383f2fd-77aa-4bad-a924-a0a14a5d0bff',
      'f42d0120-f51e-451c-b79e-2a7db2aec953',
      '5241dedb-30c9-49cf-8d0c-f0daafc103f3',
      'b01540ed-5638-4f61-b066-17b27232f4e8',
      'db04f75c-76a9-40dd-a742-e71071117f27',
      'beb7d2dc-1db8-4025-9aa4-032214a71817',
      'c3b22f21-fdef-46a9-bb32-680f08459d91'
    ]::uuid[])
     AND photo_custom_url IS NOT NULL;
  IF v_before_scalar <> 0 THEN
    RAISE EXCEPTION 'CC_0444: % of the 11 targets already carry photo_custom_url. They were all NULL when this was written — re-measure before applying.', v_before_scalar;
  END IF;
END $$;

  -- JoCasta Zamarripa — Secretary of State
  INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
  SELECT '4892ed26-cdcc-4c88-82a4-b673f0b43bc9', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4892ed26-cdcc-4c88-82a4-b673f0b43bc9-headshot.jpg', 'default', 'press_use'
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
                      WHERE politician_id = '4892ed26-cdcc-4c88-82a4-b673f0b43bc9' AND type = 'default');
  UPDATE essentials.politicians
     SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4892ed26-cdcc-4c88-82a4-b673f0b43bc9-headshot.jpg', photo_origin_url = 'https://www.votejocasta.com/'
   WHERE id = '4892ed26-cdcc-4c88-82a4-b673f0b43bc9' AND photo_custom_url IS NULL;

  -- Daniel J. Bukiewicz — Assembly District 21
  INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
  SELECT 'c8205f59-7eb8-444f-80e5-85911b9b99e7', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c8205f59-7eb8-444f-80e5-85911b9b99e7-headshot.jpg', 'default', 'press_use'
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
                      WHERE politician_id = 'c8205f59-7eb8-444f-80e5-85911b9b99e7' AND type = 'default');
  UPDATE essentials.politicians
     SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c8205f59-7eb8-444f-80e5-85911b9b99e7-headshot.jpg', photo_origin_url = 'https://www.danbukiewicz.com'
   WHERE id = 'c8205f59-7eb8-444f-80e5-85911b9b99e7' AND photo_custom_url IS NULL;

  -- Kevin Knoke — Assembly District 30
  INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
  SELECT 'dbdf66f1-2673-4cd2-94cf-d92e45e616b1', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dbdf66f1-2673-4cd2-94cf-d92e45e616b1-headshot.jpg', 'default', 'press_use'
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
                      WHERE politician_id = 'dbdf66f1-2673-4cd2-94cf-d92e45e616b1' AND type = 'default');
  UPDATE essentials.politicians
     SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dbdf66f1-2673-4cd2-94cf-d92e45e616b1-headshot.jpg', photo_origin_url = 'https://www.kevinknoke.com/'
   WHERE id = 'dbdf66f1-2673-4cd2-94cf-d92e45e616b1' AND photo_custom_url IS NULL;

  -- Bill Oemichen — Assembly District 50
  INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
  SELECT '011bee3f-2a87-4590-893d-c6be616fa45a', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/011bee3f-2a87-4590-893d-c6be616fa45a-headshot.jpg', 'default', 'press_use'
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
                      WHERE politician_id = '011bee3f-2a87-4590-893d-c6be616fa45a' AND type = 'default');
  UPDATE essentials.politicians
     SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/011bee3f-2a87-4590-893d-c6be616fa45a-headshot.jpg', photo_origin_url = 'https://www.billforwisconsinassembly.com'
   WHERE id = '011bee3f-2a87-4590-893d-c6be616fa45a' AND photo_custom_url IS NULL;

  -- Ben Gruber — Assembly District 51
  INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
  SELECT 'f383f2fd-77aa-4bad-a924-a0a14a5d0bff', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f383f2fd-77aa-4bad-a924-a0a14a5d0bff-headshot.jpg', 'default', 'press_use'
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
                      WHERE politician_id = 'f383f2fd-77aa-4bad-a924-a0a14a5d0bff' AND type = 'default');
  UPDATE essentials.politicians
     SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f383f2fd-77aa-4bad-a924-a0a14a5d0bff-headshot.jpg', photo_origin_url = 'https://www.ben-gruber.com/'
   WHERE id = 'f383f2fd-77aa-4bad-a924-a0a14a5d0bff' AND photo_custom_url IS NULL;

  -- Becky Nichols — Assembly District 53
  INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
  SELECT 'f42d0120-f51e-451c-b79e-2a7db2aec953', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f42d0120-f51e-451c-b79e-2a7db2aec953-headshot.jpg', 'default', 'press_use'
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
                      WHERE politician_id = 'f42d0120-f51e-451c-b79e-2a7db2aec953' AND type = 'default');
  UPDATE essentials.politicians
     SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f42d0120-f51e-451c-b79e-2a7db2aec953-headshot.jpg', photo_origin_url = 'https://www.beckynicholsforassembly.com/'
   WHERE id = 'f42d0120-f51e-451c-b79e-2a7db2aec953' AND photo_custom_url IS NULL;

  -- Kevin Krentz — Assembly District 57
  INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
  SELECT '5241dedb-30c9-49cf-8d0c-f0daafc103f3', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5241dedb-30c9-49cf-8d0c-f0daafc103f3-headshot.jpg', 'default', 'press_use'
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
                      WHERE politician_id = '5241dedb-30c9-49cf-8d0c-f0daafc103f3' AND type = 'default');
  UPDATE essentials.politicians
     SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5241dedb-30c9-49cf-8d0c-f0daafc103f3-headshot.jpg', photo_origin_url = 'https://www.krentzforassembly.com/'
   WHERE id = '5241dedb-30c9-49cf-8d0c-f0daafc103f3' AND photo_custom_url IS NULL;

  -- Bernie Newman — Assembly District 58
  INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
  SELECT 'b01540ed-5638-4f61-b066-17b27232f4e8', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b01540ed-5638-4f61-b066-17b27232f4e8-headshot.jpg', 'default', 'press_use'
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
                      WHERE politician_id = 'b01540ed-5638-4f61-b066-17b27232f4e8' AND type = 'default');
  UPDATE essentials.politicians
     SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b01540ed-5638-4f61-b066-17b27232f4e8-headshot.jpg', photo_origin_url = 'https://bernienewmanforwi.com/'
   WHERE id = 'b01540ed-5638-4f61-b066-17b27232f4e8' AND photo_custom_url IS NULL;

  -- Bryson Reyes — Assembly District 82
  INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
  SELECT 'db04f75c-76a9-40dd-a742-e71071117f27', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/db04f75c-76a9-40dd-a742-e71071117f27-headshot.jpg', 'default', 'press_use'
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
                      WHERE politician_id = 'db04f75c-76a9-40dd-a742-e71071117f27' AND type = 'default');
  UPDATE essentials.politicians
     SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/db04f75c-76a9-40dd-a742-e71071117f27-headshot.jpg', photo_origin_url = 'https://www.brysonforwisconsin.com/'
   WHERE id = 'db04f75c-76a9-40dd-a742-e71071117f27' AND photo_custom_url IS NULL;

  -- Brandy Tollefson — Assembly District 88
  INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
  SELECT 'beb7d2dc-1db8-4025-9aa4-032214a71817', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/beb7d2dc-1db8-4025-9aa4-032214a71817-headshot.jpg', 'default', 'press_use'
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
                      WHERE politician_id = 'beb7d2dc-1db8-4025-9aa4-032214a71817' AND type = 'default');
  UPDATE essentials.politicians
     SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/beb7d2dc-1db8-4025-9aa4-032214a71817-headshot.jpg', photo_origin_url = 'https://www.brandyforwisconsin.com/'
   WHERE id = 'beb7d2dc-1db8-4025-9aa4-032214a71817' AND photo_custom_url IS NULL;

  -- Jeremiah Fredrickson — Assembly District 92
  INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
  SELECT 'c3b22f21-fdef-46a9-bb32-680f08459d91', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c3b22f21-fdef-46a9-bb32-680f08459d91-headshot.jpg', 'default', 'press_use'
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images
                      WHERE politician_id = 'c3b22f21-fdef-46a9-bb32-680f08459d91' AND type = 'default');
  UPDATE essentials.politicians
     SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c3b22f21-fdef-46a9-bb32-680f08459d91-headshot.jpg', photo_origin_url = 'https://www.jeremiahfredricksonforstateassembly.com/'
   WHERE id = 'c3b22f21-fdef-46a9-bb32-680f08459d91' AND photo_custom_url IS NULL;

DO $$
DECLARE
  v_ids uuid[] := ARRAY[
    '4892ed26-cdcc-4c88-82a4-b673f0b43bc9',
    'c8205f59-7eb8-444f-80e5-85911b9b99e7',
    'dbdf66f1-2673-4cd2-94cf-d92e45e616b1',
    '011bee3f-2a87-4590-893d-c6be616fa45a',
    'f383f2fd-77aa-4bad-a924-a0a14a5d0bff',
    'f42d0120-f51e-451c-b79e-2a7db2aec953',
    '5241dedb-30c9-49cf-8d0c-f0daafc103f3',
    'b01540ed-5638-4f61-b066-17b27232f4e8',
    'db04f75c-76a9-40dd-a742-e71071117f27',
    'beb7d2dc-1db8-4025-9aa4-032214a71817',
    'c3b22f21-fdef-46a9-bb32-680f08459d91'
  ]::uuid[];
  v_scalar   int;
  v_images   int;
  v_agree    int;
  v_bad      text;
BEGIN
  SELECT count(*) INTO v_scalar
    FROM essentials.politicians
   WHERE id = ANY (v_ids) AND photo_custom_url IS NOT NULL;

  SELECT count(*) INTO v_images
    FROM essentials.politician_images
   WHERE politician_id = ANY (v_ids) AND type = 'default';

  -- The two columns must name the SAME file. This is the defect the header describes:
  -- a person whose scalar and image row disagree looks fine on one surface and blank on
  -- the other, and nothing else in this repo would notice.
  SELECT count(*) INTO v_agree
    FROM essentials.politicians p
    JOIN essentials.politician_images i
      ON i.politician_id = p.id AND i.type = 'default'
   WHERE p.id = ANY (v_ids) AND p.photo_custom_url = i.url;

  IF v_scalar <> 11 THEN
    RAISE EXCEPTION 'CC_0444: photo_custom_url set on % of 11', v_scalar;
  END IF;
  IF v_images <> 11 THEN
    RAISE EXCEPTION 'CC_0444: default image rows for % of 11', v_images;
  END IF;
  IF v_agree <> 11 THEN
    SELECT string_agg(p.full_name, ', ') INTO v_bad
      FROM essentials.politicians p
      LEFT JOIN essentials.politician_images i
        ON i.politician_id = p.id AND i.type = 'default'
     WHERE p.id = ANY (v_ids)
       AND (i.url IS NULL OR p.photo_custom_url <> i.url);
    RAISE EXCEPTION 'CC_0444: scalar and default image row disagree for: %', v_bad;
  END IF;

  -- Nobody may have acquired a SECOND default image row: the grid reads images[] and a
  -- duplicate would make which face shows an ordering accident.
  SELECT count(*) INTO v_images FROM (
    SELECT politician_id FROM essentials.politician_images
     WHERE politician_id = ANY (v_ids) AND type = 'default'
     GROUP BY politician_id HAVING count(*) > 1) d;
  IF v_images <> 0 THEN
    RAISE EXCEPTION 'CC_0444: % of the 11 hold more than one default image row', v_images;
  END IF;

  -- Every file must be one we serve ourselves. Match on the PATH, never the host: storage
  -- answers on both <ref>.storage.supabase.co and <ref>.supabase.co, and a host-based LIKE
  -- once classified 1,279 of our own mirrored headshots as hotlinked.
  SELECT count(*) INTO v_images
    FROM essentials.politician_images
   WHERE politician_id = ANY (v_ids) AND type = 'default'
     AND url NOT LIKE '%supabase.co/storage/v1/object/public/politician_photos/%';
  IF v_images <> 0 THEN
    RAISE EXCEPTION 'CC_0444: % of the 11 point outside our own bucket', v_images;
  END IF;

  RAISE NOTICE 'CC_0444 OK: 11 seated, scalar and image row agree, all mirrored.';
END $$;

COMMIT;
