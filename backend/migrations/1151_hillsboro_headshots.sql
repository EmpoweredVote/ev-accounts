-- Migration 1151: City of Hillsboro City Council Headshots — AUDIT-ONLY (not registered in the ledger)
--
-- Records the essentials.politician_images rows for the 7 Hillsboro officials whose 600x750
-- portraits were uploaded to Supabase Storage (politician_photos/{uuid}-headshot.jpg) by
-- _tmp-hillsboro-headshots.py. One INSERT per official, guarded by WHERE NOT EXISTS on
-- politician_id (idempotent). type='default'. photo_license per actual source
-- (CivicWeb portal images / Ballotpedia-campaign fallback = press_use).
--
-- ORCHESTRATOR NOTE: {uuid} placeholders FILLED 2026-07-01 from the pipeline manifest (7/7 civicweb,
-- politician UUIDs emitted in the pipeline script's SUCCESS manifest lines before this
-- file is applied. Any official the pipeline reports as FAILED (GAP) must have its
-- INSERT block removed entirely from this file prior to apply — never fabricate a row.
--
-- AUDIT-ONLY: this migration intentionally does NOT write a ledger row.

BEGIN;

-- Beach Pace (Mayor, -4134101) — CivicWeb portal / Ballotpedia fallback
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4134101),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/95a6d0c4-2b0e-4c4f-9f53-02eb55543fb7-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4134101)
);

-- Cristian Salgado (Ward 1, Position A, -4134102) — CivicWeb portal
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4134102),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/44d84b41-36f0-4b46-8235-df1ca4ed7da7-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4134102)
);

-- Saba Anvery (Ward 1, Position B, -4134103) — CivicWeb portal
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4134103),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2615c597-7974-441e-a9f1-93616b2da33c-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4134103)
);

-- Kipperlyn Sinclair (Ward 2, Position A, -4134104) — CivicWeb portal
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4134104),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/92ad1ef9-117d-4042-a19e-438c0ec7dea6-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4134104)
);

-- Elizabeth Case (Ward 2, Position B, -4134105) — CivicWeb portal / campaign site fallback
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4134105),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c95bfe4d-65c0-41a2-9c54-21a958f54f58-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4134105)
);

-- Olivia Alcaire (Ward 3, Position A, -4134106) — CivicWeb portal
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4134106),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6f901dde-b4d9-49d9-90ef-f318166664d9-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4134106)
);

-- Rob Harris (Ward 3, Position B, Council President — title-on-seat, -4134107) — CivicWeb portal / Ballotpedia fallback
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4134107),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/38aa9579-5fdf-40a5-8f7a-738f16b3d655-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4134107)
);

COMMIT;
