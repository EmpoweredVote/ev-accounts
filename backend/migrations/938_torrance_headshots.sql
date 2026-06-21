-- 938_torrance_headshots.sql
-- Phase 148 (Torrance Deep-Seed), Plan 03 — AUDIT-ONLY (does NOT register in schema_migrations; ledger stays 937).
-- Idempotent. Canonical 600x750 headshots for the 7 CURRENT members (ROSTER OVERRIDE — Chen seated Mayor incl.).
-- Sourcing note: torranceca.gov is WAF-403 (Akamai) for automated fetch (RESEARCH "NO WAF" was wrong); the
-- 6 official council portraits were retrieved in-browser by the operator (the council-listing 150x150 official
-- portraits, Lanczos-upscaled to 600x750 4:5). Sheikh sourced from his high-res SCAG profile (1920x2400).
-- All uploaded to Storage politician_photos/{uuid}-headshot.jpg (x-upsert), verified correct person + clean.
--   external_id -> politician uuid:
--     -201036 Chen 3dfd7349 · 683376 Gerson d8767eea · 683364 Kaji e9af3b91 · 683370 Kalani 0695e308
--     683366 Bridgett-Lewis 9e24181e · -201103 Mattucci 2b4b35a8 · -201102 Sheikh 9ac3ac10

BEGIN;

-- (1) INSERT a single canonical type='default' row for the 4 members with NO existing image (guarded NOT EXISTS).
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT p.id,
       'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/'||p.id||'-headshot.jpg',
       'default', 'press_use'
FROM essentials.politicians p
WHERE p.external_id IN (683364, 683370, 683376, 683366)   -- Kaji, Kalani, Gerson, Bridgett-Lewis
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images i WHERE i.politician_id = p.id AND i.type='default');

-- (2) Normalise ALL 7 current members' default rows to the canonical {uuid}-headshot.jpg url + press_use.
--     This replaces Chen's old cc_by_sa /default.jpeg row (now the official city press_use portrait) and
--     Mattucci's old 200x200 'unknown'-license row; Sheikh/the 4 inserted rows are already compliant (no-op).
UPDATE essentials.politician_images i
SET url = 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/'||i.politician_id||'-headshot.jpg',
    photo_license = 'press_use'
FROM essentials.politicians p
WHERE p.id = i.politician_id
  AND p.external_id IN (-201036, 683376, 683364, 683370, 683366, -201103, -201102)
  AND i.type = 'default';

-- (3) Backfill photo_origin_url for members lacking a real source (Chen NULL; Gerson/Lewis 'searched:no_results').
UPDATE essentials.politicians
SET photo_origin_url = 'https://www.torranceca.gov/government/city-council'
WHERE external_id IN (-201036, 683376, 683366)
  AND (photo_origin_url IS NULL OR photo_origin_url = 'searched:no_results');

-- Mattucci's uploaded portrait is now the official torranceca.gov council photo (not the old vote-usa 200x200);
-- correct his provenance to match the actual image source.
UPDATE essentials.politicians
SET photo_origin_url = 'https://www.torranceca.gov/government/city-council'
WHERE external_id = -201103
  AND photo_origin_url LIKE '%vote-usa.org%';

COMMIT;
