-- Migration 1306: Town of Oro Valley Council Headshots — AUDIT-ONLY (not registered in the ledger)
--
-- Records the essentials.politician_images rows for the 7 Oro Valley officials (Mayor + 6
-- at-large council members) whose 600x750 portraits were uploaded to Supabase Storage
-- (politician_photos/{uuid}-headshot.jpg) by _tmp-oro-valley-headshots.py. One INSERT per
-- official, guarded by WHERE NOT EXISTS on politician_id (idempotent). type='default'.
--
-- SOURCE NOTE (RESEARCH § Common Pitfall 5): the official host orovalleyaz.gov is
-- Akamai-WAF-blocked (HTTP 403, X-Reference-Error, identical signature to Tucson), so the
-- source portraits were resolved from NON-WAF hosts (robb4ovcouncil.com / Wikipedia / press
-- coverage) via the /find-headshots Playwright flow — NOT by spoofing headers against the WAF.
--
-- photo_license VARIES per image (Wikimedia/CC terms, campaign press_use, or operator_supplied)
-- — do NOT read these as a uniform value. Each row's photo_license below has been finalized to
-- the actual sourced license (campaign press_use / Tucson Local Media editorial / iloveov.com
-- candidate-submitted) after the Task 3 sourcing pass.
--
-- AUDIT-ONLY: this migration intentionally does NOT write a ledger row (supabase_migrations).

BEGIN;

-- Joseph "Joe" Winfield (Mayor, -4009001) — d3009d53-a6f0-4ea0-b41d-658ce62e3753
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4009001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d3009d53-a6f0-4ea0-b41d-658ce62e3753-headshot.jpg',
       'default', 'campaign photo, joewinfieldmayor.com (candidate campaign, press_use)'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4009001)
);

-- Melanie Barrett (Council Member (Vice Mayor), -4009002) — c33b6be0-1192-4483-9343-28084a0f947d
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4009002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c33b6be0-1192-4483-9343-28084a0f947d-headshot.jpg',
       'default', 'campaign photo, melaniebarrett.org (candidate campaign, press_use)'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4009002)
);

-- Joyce Jones-Ivey (Council Member, -4009003) — d9d52a86-359c-45b0-a2c6-297e67c0e669
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4009003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d9d52a86-359c-45b0-a2c6-297e67c0e669-headshot.jpg',
       'default', 'Tucson Local Media / Explorer News editorial photo (news_press_use)'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4009003)
);

-- Josh Nicolson (Council Member, -4009004) — 889fe40e-425a-44cc-864f-b191d7c226ae
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4009004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/889fe40e-425a-44cc-864f-b191d7c226ae-headshot.jpg',
       'default', 'campaign photo, joshfororovalley.com (candidate campaign, press_use)'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4009004)
);

-- Dr. Harry "Mo" Greene II (Council Member, -4009005) — 4e1a2e41-9e27-42db-8b47-00f697266987
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4009005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4e1a2e41-9e27-42db-8b47-00f697266987-headshot.jpg',
       'default', 'iloveov.com candidate profile (candidate-submitted headshot)'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4009005)
);

-- Mary Murphy (Council Member, -4009006) — aeb4c75b-e4a9-4e94-a7f6-b1d58707d84c
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4009006),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/aeb4c75b-e4a9-4e94-a7f6-b1d58707d84c-headshot.jpg',
       'default', 'iloveov.com candidate profile (candidate-submitted headshot)'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4009006)
);

-- Elizabeth Robb (Council Member, -4009007) — 3bb254c4-0335-4377-b4ae-1313453c8ae9
-- (candidate source host: robb4ovcouncil.com, HTTP 200 confirmed — resolved via Playwright)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4009007),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3bb254c4-0335-4377-b4ae-1313453c8ae9-headshot.jpg',
       'default', 'iloveov.com candidate profile (candidate-submitted headshot)'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4009007)
);

COMMIT;
