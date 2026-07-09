-- 1283_az_state_exec_headshots.sql
-- Phase 191 (AZ-STATE-01): AUDIT-ONLY — politician_images rows for 6 of the 7 net-new
-- AZ STATE_EXEC officials.
-- NOT registered in the migration ledger; the ledger stays at 1282.
-- Applied via psql (not apply_migration) AFTER the headshot pipeline script
--   (_tmp-az-state-exec-headshots.py) uploaded the images to Storage.
-- Columns: exactly (id, politician_id, url, type, photo_license) — the photo_origin_url
--   column does not exist on this schema (Pitfall 5).
--
-- Les Presmyk (-4004002, State Mine Inspector) is DELIBERATELY OMITTED from this file.
--   No licensed source was found this session (Wikimedia Commons has no portrait under his
--   name — only mineral-specimen photos; en.wikipedia.org/wiki/Les_Presmyk's infobox has NO
--   image; Ballotpedia shows only a "submit photo" placeholder; the AZGOP press-release URL
--   404s; asmi.az.gov/about/team is WAF-403). Deferred to the Plan 03 human-verify checkpoint
--   per the NV 159 Andy Matthews precedent — non-blocking for this migration.
--
-- Sources:
--   Tom Horne (-4004001): Wikimedia Commons Tom_Horne_(52801743945)_(crop).jpg, CC BY-SA 2.0
--     (Gage Skidmore).
--   Nick Myers (-4004003), Rachel Walden (-4004004), Kevin Thompson (-4004006),
--     Rene Lopez (-4004007): azcc.gov official commissioner bio-page portraits, no explicit
--     stated license -> tagged 'press_use' per project convention. Myers/Walden source
--     thumbnails were 133x200 (azcc.gov 'tmb-thumb200' format) — upscaled to 600x750 with
--     Lanczos resampling, matching the NV Henderson/ME legislature low-res-thumbnail
--     upscale precedent.
--   Lea Marquez Peterson (-4004005): Wikimedia Commons Lea_Marquez_Peterson_by_Gage_Skidmore.jpg,
--     CC BY 2.0 (Gage Skidmore).
--
-- ORCHESTRATOR NOTE: the url literals below carry each official's actual politician UUID,
--   captured from migration 1282's actual INSERT output (gen_random_uuid() at write time).
--   If this migration is ever re-run against a DB where a UUID differs, re-derive via:
--   SELECT id FROM essentials.politicians WHERE external_id = <id>; and substitute it.

-- Tom Horne (-4004001) — cc_by_sa_2.0
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4004001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f8c46490-a465-4ec3-a442-1b7f9ea6886c-headshot.jpg',
       'default', 'cc_by_sa_2.0'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4004001)
);

-- Nick Myers (-4004003) — press_use
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4004003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9170233d-a01b-4fd0-bd68-6c961948ab79-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4004003)
);

-- Rachel Walden (-4004004) — press_use
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4004004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d468e390-4d5f-4337-a9e6-ba8c04f9e061-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4004004)
);

-- Lea Marquez Peterson (-4004005) — cc_by_2.0
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4004005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ff600e1c-b748-484f-9607-9c3c300724ec-headshot.jpg',
       'default', 'cc_by_2.0'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4004005)
);

-- Kevin Thompson (-4004006) — press_use
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4004006),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/760f51b2-657e-43b8-9340-038e06b4d9a5-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4004006)
);

-- Rene Lopez (-4004007) — press_use
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4004007),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5561c7ea-d6f5-4b49-9ed9-f61f19ab5b43-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4004007)
);
