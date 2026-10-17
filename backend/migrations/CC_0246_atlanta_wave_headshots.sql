-- CC_0246_atlanta_wave_headshots.sql
--
-- Atlanta / Fulton County / DeKalb County wave, stage 5 (assets).
-- Seats 34 headshots for the officials seeded by CC_0238-CC_0245.
--
-- Each image is already uploaded to the politician_photos bucket as
-- <politician_id>-headshot.jpg, rendered to the house geometry: centre 4:5 crop,
-- Lanczos to 600x750, quality 90. Sources are official government pages only.
--
-- 🔴 BOTH SIDES ARE WRITTEN ON PURPOSE. The grid reads images[] first and the
-- backend reads the politicians scalar, so a row in politician_images alone
-- leaves the scalar null and a photo_custom_url alone is invisible to the grid.
-- Writing one and not the other is the failure this migration exists to avoid.
--
-- 7 of the wave's 41 seats are deliberately left WITHOUT an image:
--   Fulton  - Ché Alexander (Clerk): only a circular-framed portrait and a
--             1920x350 banner exist; every 4:5 cut clips her hair.
--           - Arthur E. Ferdinand (Tax): site refuses automated requests.
--           - Kenya M. Johnson (Probate): county probate paths 404.
--           - Fred Quinn, Jr. (Surveyor): no county page exists (open item 8).
--           - District 4 is VACANT, so it has no occupant to picture.
--   DeKalb  - Debra DeBerry (Clerk): no portrait on any reachable path.
--           - Bedelia C. Hargrove (Probate): county probate paths 404.
-- A blank beats a wrong or placeholder face. Do not fill these with a default.
--
-- Idempotent: re-running changes nothing.

BEGIN;

CREATE TEMP TABLE _atl_headshots (
  politician_id uuid PRIMARY KEY,
  url           text NOT NULL,
  origin_url    text NOT NULL,
  photo_license text NOT NULL
) ON COMMIT DROP;

INSERT INTO _atl_headshots (politician_id, url, origin_url, photo_license) VALUES
  ('26412187-e6ed-4cba-82d4-571ed90e3f9c'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/26412187-e6ed-4cba-82d4-571ed90e3f9c-headshot.jpg', 'https://www.atlantaga.gov/government/mayor-s-office/meet-the-mayor', 'press_use'),
  ('4ed0d3db-8276-4ced-8b8a-02beafabe5e1'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4ed0d3db-8276-4ced-8b8a-02beafabe5e1-headshot.jpg', 'https://citycouncil.atlantaga.gov/council-members/council-president-marci-collier-overstreet', 'press_use'),
  ('4c132e4d-c436-40de-86a9-3b3bb7bf7d83'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4c132e4d-c436-40de-86a9-3b3bb7bf7d83-headshot.jpg', 'https://citycouncil.atlantaga.gov/council-members/jason-winston', 'press_use'),
  ('b26ae096-b009-492a-b894-ef0a4d43ae6d'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b26ae096-b009-492a-b894-ef0a4d43ae6d-headshot.jpg', 'https://citycouncil.atlantaga.gov/council-members/kelsea-bond', 'press_use'),
  ('26709210-b7f7-44c9-8f9f-738749725fd3'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/26709210-b7f7-44c9-8f9f-738749725fd3-headshot.jpg', 'https://citycouncil.atlantaga.gov/council-members/byron-amos', 'press_use'),
  ('540cfac1-5eec-48ba-8de0-5dfb8799a2a7'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/540cfac1-5eec-48ba-8de0-5dfb8799a2a7-headshot.jpg', 'https://citycouncil.atlantaga.gov/council-members/jason-s-dozier', 'press_use'),
  ('04ebd79f-3154-4c3a-8a81-eff516ca95bd'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/04ebd79f-3154-4c3a-8a81-eff516ca95bd-headshot.jpg', 'https://citycouncil.atlantaga.gov/council-members/liliana-bakhtiari', 'press_use'),
  ('94acb3ce-4bf8-4a0a-bdc7-22476baeffa5'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/94acb3ce-4bf8-4a0a-bdc7-22476baeffa5-headshot.jpg', 'https://citycouncil.atlantaga.gov/council-members/alex-wan', 'press_use'),
  ('dfe5a9fc-41d6-41e9-94a1-4d01c16d55dc'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dfe5a9fc-41d6-41e9-94a1-4d01c16d55dc-headshot.jpg', 'https://citycouncil.atlantaga.gov/council-members/thomas-worthy', 'press_use'),
  ('2205603a-b8d0-4cdf-ad47-ce6209bfeebf'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2205603a-b8d0-4cdf-ad47-ce6209bfeebf-headshot.jpg', 'https://citycouncil.atlantaga.gov/council-members/mary-norwood', 'press_use'),
  ('6bc5f350-33c0-4473-b5b3-0b377c295720'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6bc5f350-33c0-4473-b5b3-0b377c295720-headshot.jpg', 'https://citycouncil.atlantaga.gov/council-members/dustin-hillis', 'press_use'),
  ('db989770-74a7-46f2-8bae-f2a42dc32978'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/db989770-74a7-46f2-8bae-f2a42dc32978-headshot.jpg', 'https://citycouncil.atlantaga.gov/council-members/andrea-l-boone', 'press_use'),
  ('f6fa161d-8a5a-4d55-900d-c79064bdf8d5'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f6fa161d-8a5a-4d55-900d-c79064bdf8d5-headshot.jpg', 'https://citycouncil.atlantaga.gov/council-members/wayne-martin', 'press_use'),
  ('9542ff9f-4b53-4b27-b750-4d245c270c8a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9542ff9f-4b53-4b27-b750-4d245c270c8a-headshot.jpg', 'https://citycouncil.atlantaga.gov/council-members/antonio-lewis', 'press_use'),
  ('e9717dac-46e1-4a93-811a-b3c427e7b034'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e9717dac-46e1-4a93-811a-b3c427e7b034-headshot.jpg', 'https://citycouncil.atlantaga.gov/council-members/michael-julian-bond', 'press_use'),
  ('5d4f74d3-6712-428f-927e-3f05a8fd77c1'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5d4f74d3-6712-428f-927e-3f05a8fd77c1-headshot.jpg', 'https://citycouncil.atlantaga.gov/council-members/matt-westmoreland', 'press_use'),
  ('e2a48a7d-59e4-42fd-8f3b-6db111275471'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/e2a48a7d-59e4-42fd-8f3b-6db111275471-headshot.jpg', 'https://citycouncil.atlantaga.gov/council-members/esh-collins', 'press_use'),
  ('a63f1576-3e23-4f5b-affa-aaff664b195e'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a63f1576-3e23-4f5b-affa-aaff664b195e-headshot.jpg', 'https://www.fultoncountyga.gov/Commissioners', 'press_use'),
  ('b66591e4-047d-4290-ae82-ab8145744c7e'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b66591e4-047d-4290-ae82-ab8145744c7e-headshot.jpg', 'https://www.fultoncountyga.gov/Commissioners', 'press_use'),
  ('04df22a3-f70c-4141-b140-c78fed92361e'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/04df22a3-f70c-4141-b140-c78fed92361e-headshot.jpg', 'https://www.fultoncountyga.gov/Commissioners', 'press_use'),
  ('477973fe-aa8c-4ee9-a4aa-e2559a23aa0a'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/477973fe-aa8c-4ee9-a4aa-e2559a23aa0a-headshot.jpg', 'https://www.fultoncountyga.gov/Commissioners', 'press_use'),
  ('0f60118c-6e0c-4a31-bdbb-38630106300e'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0f60118c-6e0c-4a31-bdbb-38630106300e-headshot.jpg', 'https://www.fultoncountyga.gov/Commissioners', 'press_use'),
  ('0bbe43f4-639e-4757-8c55-4baaa76468f6'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0bbe43f4-639e-4757-8c55-4baaa76468f6-headshot.jpg', 'https://www.fultoncountyga.gov/Commissioners', 'press_use'),
  ('a1460547-aed5-4a39-acf9-2a6deca404b0'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a1460547-aed5-4a39-acf9-2a6deca404b0-headshot.jpg', 'https://fcsoga.org/our-sheriff/', 'press_use'),
  ('9784a23b-00bc-4006-9115-d3069a5d4a4b'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9784a23b-00bc-4006-9115-d3069a5d4a4b-headshot.jpg', 'https://dekalbcountyga.gov/government/chief-executive-officer', 'press_use'),
  ('017c8d4c-bd0e-438f-a63b-342917602760'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/017c8d4c-bd0e-438f-a63b-342917602760-headshot.jpg', 'https://dekalbcountyga.gov/government/board-of-commissioners', 'press_use'),
  ('ddf2b5d5-e67a-47e5-a01f-579a029102f7'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ddf2b5d5-e67a-47e5-a01f-579a029102f7-headshot.jpg', 'https://dekalbcountyga.gov/government/board-of-commissioners', 'press_use'),
  ('7d375983-3afd-424b-8eca-2ddb1e94cc46'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7d375983-3afd-424b-8eca-2ddb1e94cc46-headshot.jpg', 'https://dekalbcountyga.gov/government/board-of-commissioners', 'press_use'),
  ('7f774f03-a9a6-40b8-8e3e-2d283ecb9878'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7f774f03-a9a6-40b8-8e3e-2d283ecb9878-headshot.jpg', 'https://dekalbcountyga.gov/government/board-of-commissioners', 'press_use'),
  ('babebbc4-6d51-4443-8ab1-3ebcd0b66ee9'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/babebbc4-6d51-4443-8ab1-3ebcd0b66ee9-headshot.jpg', 'https://dekalbcountyga.gov/government/board-of-commissioners', 'press_use'),
  ('a0ab39a0-2b52-4b76-84fe-833cf87857d2'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a0ab39a0-2b52-4b76-84fe-833cf87857d2-headshot.jpg', 'https://dekalbcountyga.gov/government/board-of-commissioners', 'press_use'),
  ('dfa78a1b-63f4-42c8-a4c5-3b5eb5b7bb95'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dfa78a1b-63f4-42c8-a4c5-3b5eb5b7bb95-headshot.jpg', 'https://dekalbcountyga.gov/government/board-of-commissioners', 'press_use'),
  ('7e5c1436-965a-4d33-ad55-01e551b78e47'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7e5c1436-965a-4d33-ad55-01e551b78e47-headshot.jpg', 'https://www.dekalbsheriff.org/about-us/', 'press_use'),
  ('627421dc-538d-4a01-90d0-7a6cda8027a2'::uuid, 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/627421dc-538d-4a01-90d0-7a6cda8027a2-headshot.jpg', 'https://dekalbtaxga.gov/about/tax-commissioner/', 'press_use');

-- Guard: every id must be a live politician. A typo'd uuid would otherwise
-- insert an orphan image row that nothing ever renders.
DO $$
DECLARE missing int;
BEGIN
  SELECT count(*) INTO missing
  FROM _atl_headshots h
  LEFT JOIN essentials.politicians p ON p.id = h.politician_id
  WHERE p.id IS NULL;
  IF missing > 0 THEN
    RAISE EXCEPTION 'CC_0246: % of % politician_id values match no politician row', missing, (SELECT count(*) FROM _atl_headshots);
  END IF;
END $$;

-- 1. the images[] row the grid reads
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT h.politician_id, h.url, 'default', h.photo_license
FROM _atl_headshots h
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images pi
  WHERE pi.politician_id = h.politician_id AND pi.type = 'default'
);

-- 2. the scalar the backend reads, plus provenance
UPDATE essentials.politicians p
SET photo_custom_url = h.url,
    photo_origin_url = h.origin_url
FROM _atl_headshots h
WHERE p.id = h.politician_id
  AND (p.photo_custom_url IS DISTINCT FROM h.url
    OR p.photo_origin_url IS DISTINCT FROM h.origin_url);

-- post-verify: both sides present for all 34, or roll back
DO $$
DECLARE
  n_expected int;
  n_images   int;
  n_scalar   int;
  n_mismatch int;
BEGIN
  SELECT count(*) INTO n_expected FROM _atl_headshots;

  SELECT count(*) INTO n_images
  FROM _atl_headshots h
  JOIN essentials.politician_images pi
    ON pi.politician_id = h.politician_id AND pi.type = 'default' AND pi.url = h.url;

  SELECT count(*) INTO n_scalar
  FROM _atl_headshots h
  JOIN essentials.politicians p
    ON p.id = h.politician_id AND p.photo_custom_url = h.url;

  -- the two sides must agree with each other, not merely both be non-null
  SELECT count(*) INTO n_mismatch
  FROM essentials.politicians p
  JOIN essentials.politician_images pi
    ON pi.politician_id = p.id AND pi.type = 'default'
  JOIN _atl_headshots h ON h.politician_id = p.id
  WHERE p.photo_custom_url IS DISTINCT FROM pi.url;

  IF n_images <> n_expected THEN
    RAISE EXCEPTION 'CC_0246: expected % default image rows, found %', n_expected, n_images;
  END IF;
  IF n_scalar <> n_expected THEN
    RAISE EXCEPTION 'CC_0246: expected % photo_custom_url values, found %', n_expected, n_scalar;
  END IF;
  IF n_mismatch > 0 THEN
    RAISE EXCEPTION 'CC_0246: % rows where photo_custom_url disagrees with the default image url', n_mismatch;
  END IF;

  RAISE NOTICE 'CC_0246 OK: % headshots, images[] and scalar agree', n_expected;
END $$;

COMMIT;
