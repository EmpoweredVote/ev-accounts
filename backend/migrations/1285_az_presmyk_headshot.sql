-- 1285_az_presmyk_headshot.sql
-- Phase 191 Plan 03 (AZ-STATE-01 checkpoint resolution): AUDIT-ONLY — politician_images row
-- for Les Presmyk (State Mine Inspector, external_id -4004002), the sole headshot gap left
-- open by migration 1283.
-- NOT registered in the migration ledger; the ledger stays at 1282.
-- Applied via psql (not apply_migration) AFTER _tmp-az-presmyk-headshot.py cropped/resized/
--   uploaded the operator-supplied local file to Storage.
-- Columns: exactly (id, politician_id, url, type, photo_license) — matches 1283's shape
--   (photo_origin_url does not exist on this schema — Pitfall 5).
--
-- Provenance: the operator supplied this headshot directly as a local file
--   (C:\tmp\Les_Presmyk.jfif, a standard JPEG despite the .jfif extension) during the Plan 03
--   human-verify checkpoint, after exhausting every licensed-source search in Plan 01
--   (Wikimedia Commons, Wikipedia infobox, Ballotpedia, AZGOP press URL, asmi.az.gov — all
--   dead ends; see 191-01-SUMMARY.md Decisions Made). photo_license is recorded as
--   'operator_supplied' — no existing project convention value fits an operator-provided-
--   directly file (closest analog, 'sourced', is ambiguous); this new value is descriptive
--   and self-documenting, matching the precedent of using a free-text descriptive string
--   when no clean CC/press/public-domain tag applies (e.g. the Bellflower "official council
--   portrait" value already in the license column).
--
-- politician_id 8bcdaf44-f392-410d-83c3-7597a52a8140 is DB-confirmed
--   (SELECT id FROM essentials.politicians WHERE external_id = -4004002), matching the
--   ROSTER UUID already captured in migration 1282 / _tmp-az-state-exec-headshots.py.

-- Les Presmyk (-4004002) — operator_supplied
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4004002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8bcdaf44-f392-410d-83c3-7597a52a8140-headshot.jpg',
       'default', 'operator_supplied'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4004002)
);
