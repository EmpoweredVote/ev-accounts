-- 928_pomona_headshots.sql
-- Phase 147 (Pomona deep-seed) Wave 3 — AUDIT-ONLY (does NOT register in schema_migrations; ledger stays 927)
-- pomonaca.gov is FULLY WAF-403 — NO city-site curl. Portraits sourced from confirmed alt sources:
--   Sandoval/Garcia/Preciado/Ontiveros-Cole/Lustro: Pomona Choice Energy 2020 CivicPlus photos (alt-text verified)
--   Martin: existing good DB photo (1280x1700) reprocessed
--   Canales: existing official city-CMS portrait (showpublishedimage/4845, a woman — NOT the male "Torres" PCE-2025 trap) reprocessed
-- ALL processed crop-4:5-FIRST → 600x750 Lanczos q90 → Storage politician_photos/{politician_id}-headshot.jpg (x-upsert).
-- FORBIDDEN PCE-2025 stale wrong-person URLs (/2025/02/638723568...) were NOT used for anyone.
-- Each member → exactly one type='default' press_use row at the canonical {uuid}-headshot.jpg path.

BEGIN;

-- ---- INSERT new image rows for the 4 previously-imageless members (guarded NOT EXISTS) ----
-- Tim Sandoval (Mayor, -200916, pol 48f36a82) — PCE 2020 MayorSandoval.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), '48f36a82-cb26-4701-ba08-5566533982cb',
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/48f36a82-cb26-4701-ba08-5566533982cb-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='48f36a82-cb26-4701-ba08-5566533982cb' AND type='default');

-- Nora Garcia (D3, -201350, pol 6fa28860) — PCE 2020 Nora_Garcia.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), '6fa28860-c3d6-45bf-8aad-eac353dc4559',
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6fa28860-c3d6-45bf-8aad-eac353dc4559-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='6fa28860-c3d6-45bf-8aad-eac353dc4559' AND type='default');

-- Elizabeth Ontiveros-Cole (D4, -700658, pol b9f58d9e) — PCE 2020 ECole.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), 'b9f58d9e-7741-42a7-9fa2-64fb2f89a2a9',
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b9f58d9e-7741-42a7-9fa2-64fb2f89a2a9-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='b9f58d9e-7741-42a7-9fa2-64fb2f89a2a9' AND type='default');

-- Steve Lustro (D5, -201352, pol 07e0311b) — PCE 2020 Steve_Lustro.jpg
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(), '07e0311b-5013-49ac-849e-7aeaa3402ea2',
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/07e0311b-5013-49ac-849e-7aeaa3402ea2-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='07e0311b-5013-49ac-849e-7aeaa3402ea2' AND type='default');

-- ---- UPDATE existing rows to the canonical {uuid}-headshot.jpg path + press_use ----
-- Debra Martin (D1, 675752, pol db853cfa) — reprocessed existing good photo to canonical path
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/db853cfa-ab6d-4a30-bfbc-fb05b3956970-headshot.jpg',
       photo_license = 'press_use'
 WHERE politician_id='db853cfa-ab6d-4a30-bfbc-fb05b3956970' AND type='default';

-- Victor Preciado (D2, 675753, pol 56cecf7c) — upgraded 150x150 → PCE 2020 600x750 at canonical path
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/56cecf7c-6de0-440f-b8e2-34945ec52333-headshot.jpg',
       photo_license = 'press_use'
 WHERE politician_id='56cecf7c-6de0-440f-b8e2-34945ec52333' AND type='default';

-- Lorraine Canales (D6, 675765, pol 3a578edc) — reprocessed existing official city portrait to canonical path
UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3a578edc-56ad-43cf-ac8f-68d05fd5d7a8-headshot.jpg',
       photo_license = 'press_use'
 WHERE politician_id='3a578edc-56ad-43cf-ac8f-68d05fd5d7a8' AND type='default';

-- ---- photo_origin_url backfill (only where NULL) ----
UPDATE essentials.politicians SET photo_origin_url='https://pomonachoiceenergy.org/wp-content/uploads/2020/06/MayorSandoval.jpg' WHERE external_id=-200916 AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://pomonachoiceenergy.org/wp-content/uploads/2020/06/Nora_Garcia.jpg' WHERE external_id=-201350 AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://pomonachoiceenergy.org/wp-content/uploads/2020/06/ECole.jpg' WHERE external_id=-700658 AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://pomonachoiceenergy.org/wp-content/uploads/2020/06/Steve_Lustro.jpg' WHERE external_id=-201352 AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://pomonachoiceenergy.org/wp-content/uploads/2020/06/Victor-Preciado.jpg' WHERE external_id=675753 AND photo_origin_url IS NULL;

COMMIT;
