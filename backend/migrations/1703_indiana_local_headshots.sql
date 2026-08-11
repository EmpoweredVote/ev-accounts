-- 1703_indiana_local_headshots.sql
--
-- Portraits for the 6 seated Indiana officials for whom one demonstrably exists. That is the
-- entire yield of a sweep over 146 real targets (4.1%), and the low number IS the finding:
-- Indiana county and township governments overwhelmingly do not publish officeholder photos.
-- Owen County is the exception (4 of these came from its roster, 768x1024 with names in the
-- alt text); the others are an Indiana Courts judicial portrait and a township board page.
--
-- Sources tried and empty: Monroe County (expired TLS cert — loads once bypassed, then serves
-- zero images), Brown County (logos only), Morgan County (no images on any roster page),
-- Jackson/Greene/Lawrence/Martin (no portraits; several stored URLs now 404), Ballotpedia (no
-- page, or the "Submit Photo" placeholder). 17 stored URLs are LinkedIn/Facebook and are
-- excluded on licence grounds.
--
-- CONTEXT — Indiana was listed as 810 missing portraits. 664 of those are CANDIDATES, not
-- officials: people who registered a committee with campaignfinance.in.gov, seeded by
-- backend/scripts/discover-indiana-candidates.ts onto placeholder offices that the ADR 0002
-- phase-2 backfill then converted into open tenures. They are legitimate records and are NOT
-- touched here. Migration 1702 added essentials.politician_occupancy_evidence so that class is
-- one column to exclude, and the pre-flight below refuses to run if any target is one.
--
-- Sets BOTH photo_custom_url and photo_origin_url: the read path is
-- COALESCE(photo_custom_url, photo_origin_url, ''), so writing only the origin — a source page,
-- not an image — renders the portrait broken (the defect mig 1475 Part B repaired).
--
-- Idempotent: re-running inserts nothing and updates nothing.

BEGIN;

CREATE TEMP TABLE _in_headshots (
  politician_id uuid PRIMARY KEY,
  bucket_url    text NOT NULL,
  source_page   text NOT NULL,
  license       text NOT NULL
) ON COMMIT DROP;

INSERT INTO _in_headshots (politician_id, bucket_url, source_page, license) VALUES
  ('336b6639-5f09-4705-b410-0f4864e968ca'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/336b6639-5f09-4705-b410-0f4864e968ca-headshot.jpg', 'https://www.in.gov/townships/center49/township-board/', 'press_use'),
  ('abe91d43-ff92-46f8-bb9d-11f19c370a88'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/abe91d43-ff92-46f8-bb9d-11f19c370a88-headshot.jpg', 'https://www.owencounty.in.gov/departments/county-council/', 'press_use'),
  ('e06e291f-5368-4226-915f-4ce11bfa7c54'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e06e291f-5368-4226-915f-4ce11bfa7c54-headshot.jpg', 'https://www.owencounty.in.gov/departments/county-council/', 'press_use'),
  ('0b77f0e5-e1fa-41cd-bdea-a85ddbdb2695'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0b77f0e5-e1fa-41cd-bdea-a85ddbdb2695-headshot.jpg', 'https://www.owencounty.in.gov/departments/county-council/', 'press_use'),
  ('f9f37dd0-e1a9-4fc5-8462-a357ca44718f'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f9f37dd0-e1a9-4fc5-8462-a357ca44718f-headshot.jpg', 'https://www.owencounty.in.gov/departments/county-council/', 'press_use'),
  ('0ddd632f-0ee9-4a56-b0a3-c1c2e7fa4dfd'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0ddd632f-0ee9-4a56-b0a3-c1c2e7fa4dfd-headshot.jpg', 'https://www.in.gov/courts/appeals/judges/patricia-riley/', 'press_use');

DO $$
DECLARE n_missing int; n_override int; n_placeholder int;
BEGIN
  SELECT count(*) INTO n_missing FROM _in_headshots t
  LEFT JOIN essentials.politicians p ON p.id = t.politician_id WHERE p.id IS NULL;
  IF n_missing <> 0 THEN
    RAISE EXCEPTION 'aborting: % target politicians no longer exist', n_missing;
  END IF;

  -- mig 192 / D-08: a hand-picked portrait outranks anything a sweep produces
  SELECT count(*) INTO n_override FROM _in_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE p.photo_custom_url_manual_override IS TRUE;
  IF n_override <> 0 THEN
    RAISE EXCEPTION 'aborting: % target(s) carry photo_custom_url_manual_override', n_override;
  END IF;

  -- never put a face on a discovered candidate
  SELECT count(DISTINCT t.politician_id) INTO n_placeholder
  FROM _in_headshots t
  JOIN essentials.politician_occupancy_evidence e ON e.politician_id = t.politician_id
  WHERE e.is_placeholder_occupancy;
  IF n_placeholder <> 0 THEN
    RAISE EXCEPTION 'aborting: % target(s) are placeholder occupancies, not officeholders',
      n_placeholder;
  END IF;
END $$;

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT t.politician_id, t.bucket_url, 'default', t.license
FROM _in_headshots t
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images pi
                  WHERE pi.politician_id = t.politician_id AND pi.url = t.bucket_url);

UPDATE essentials.politicians p
SET photo_custom_url = t.bucket_url,
    photo_origin_url = t.source_page
FROM _in_headshots t
WHERE p.id = t.politician_id
  AND p.photo_custom_url_manual_override IS NOT TRUE
  AND (p.photo_custom_url IS DISTINCT FROM t.bucket_url
    OR p.photo_origin_url IS DISTINCT FROM t.source_page);

DO $$
DECLARE n_img int; n_custom int; n_render int;
BEGIN
  SELECT count(*) INTO n_img FROM _in_headshots t
  JOIN essentials.politician_images pi
    ON pi.politician_id = t.politician_id AND pi.url = t.bucket_url;
  IF n_img <> 6 THEN RAISE EXCEPTION 'expected 6 image rows, found %', n_img; END IF;

  SELECT count(*) INTO n_custom FROM _in_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE p.photo_custom_url = t.bucket_url
    AND p.photo_custom_url LIKE '%storage.supabase.co%';
  IF n_custom <> 6 THEN
    RAISE EXCEPTION 'expected 6 rows with photo_custom_url on the bucket, found %', n_custom;
  END IF;

  -- HAS_RENDERABLE_PHOTO_SQL, copied from backend/src/lib/photoCoverage.ts verbatim
  SELECT count(*) INTO n_render FROM _in_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  LEFT JOIN essentials.politician_images img ON img.politician_id = p.id
  WHERE ( img.politician_id IS NOT NULL
       OR btrim(coalesce(p.photo_custom_url, '')) <> ''
       OR (btrim(coalesce(p.photo_origin_url, '')) <> '' AND p.photo_origin_url LIKE 'http%') );
  IF n_render < 6 THEN
    RAISE EXCEPTION 'only % of 6 satisfy HAS_RENDERABLE_PHOTO_SQL', n_render;
  END IF;

  RAISE NOTICE 'ok: 6 Indiana officials renderable';
END $$;

COMMIT;
