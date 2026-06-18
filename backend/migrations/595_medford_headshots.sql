-- Migration 595: Medford city officials + School Committee headshots (MEDFORD-02)
--
-- Storage bucket: politician_photos
-- CDN base: https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/
--
-- Officials scope: city council (migration 591) + SC elected members (migration 593)
-- Mayor Lungo-Koehn appears once (city external_id -2540115001 only)
-- Total officials attempted: 14 (8 city officials + 6 SC elected members)
-- Uploaded: 1 (Mayor Lungo-Koehn — medfordma.org finalsite.net CDN)
-- Gap count: 13
--
-- Photo processing: crop 4:5 first, then resize 600x750 Lanczos q90
-- type = 'default' (NOT 'headshot') — UI filter uses .find(img => img.type === 'default')
--
-- SOURCE INVESTIGATION:
--   Mayor Lungo-Koehn: official headshot on medfordma.org mayor page
--     https://resources.finalsite.net/images/f_auto,q_auto/v1738600642/medfordmaorg/dpnpz1rl6btoxb6fcfk7/Newheadshot.jpg
--     Confirmed HTTP 200; finalsite.net CDN; original 1800x1200 webp; processed 600x750 JPEG q90.
--   City Councilors (Bears, Lazzaro, Callahan, Leming, Mullane, Scarpelli, Tseng):
--     medfordma.org/citycouncil/ page has only a group selfie (alt="Newly sworn in City Council
--     members pose for a selfie"; Unknown-2.jpg on finalsite.net). No individual bio pages.
--     No Wikipedia articles found for any of the 7 councilors. All 7 are gaps.
--   SC members (Graham, Mastrobuoni, Olapade, Parks, Reinfeld, Ruseau):
--     mps02155.org/about/school-committee has only a group photo (SCWebsitePhoto.png).
--     No individual member headshots. No Wikipedia articles found. All 6 are gaps.
--
-- DOCUMENTED GAPS:
--   City Council:
--     -2540115002 Isaac Bears            — medfordma.org group-photo-only; no Wikipedia
--     -2540115003 Emily Lazzaro          — medfordma.org group-photo-only; no Wikipedia
--     -2540115004 Anna Callahan          — medfordma.org group-photo-only; no Wikipedia
--     -2540115005 Matt Leming            — medfordma.org group-photo-only; no Wikipedia
--     -2540115006 Liz Mullane            — medfordma.org group-photo-only; no Wikipedia
--     -2540115007 George Scarpelli       — medfordma.org group-photo-only; no Wikipedia
--     -2540115008 Justin Tseng           — medfordma.org group-photo-only; no Wikipedia
--   School Committee:
--     -2506600001 Jenny Graham           — mps02155.org group-photo-only; no Wikipedia
--     -2506600002 Mike Mastrobuoni       — mps02155.org group-photo-only; no Wikipedia
--     -2506600003 Aaron Olapade          — mps02155.org group-photo-only; no Wikipedia
--     -2506600004 Jessica Parks          — mps02155.org group-photo-only; no Wikipedia
--     -2506600005 Erika Reinfeld         — mps02155.org group-photo-only; no Wikipedia
--     -2506600006 Paul Ruseau            — mps02155.org group-photo-only; no Wikipedia
--
-- Upload script: C:/EV-Accounts/backend/scripts/_tmp-medford-headshots.py
--   Run date: 2026-06-15
--   Result: 1 uploaded, 13 gaps
--
-- CRITICAL: type = 'default' (not 'headshot') — UI filter .find(img => img.type === 'default')
-- CRITICAL: WHERE NOT EXISTS guard on politician_id makes all blocks idempotent

-- ============================================================
-- CITY OFFICIALS (external_ids -2540115001 through -2540115008)
-- 1 uploaded (Mayor); 7 gaps (councilors)
-- ============================================================

-- Breanna Lungo-Koehn (Mayor) — external_id -2540115001
-- Source: https://resources.finalsite.net/images/f_auto,q_auto/v1738600642/medfordmaorg/dpnpz1rl6btoxb6fcfk7/Newheadshot.jpg
-- medfordma.org official mayor page; finalsite.net CDN; 1800x1200 webp -> 600x750 JPEG q90
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2540115001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a4320764-6ba2-4563-9a58-abb1333c2f40-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2540115001)
);

-- GAP: -2540115002 Isaac Bears (City Councilor, Council President)
--   medfordma.org/citycouncil/ group selfie photo only (Unknown-2.jpg); no individual bio pages; no Wikipedia article
-- GAP: -2540115003 Emily Lazzaro (City Councilor, Council Vice President)
--   medfordma.org/citycouncil/ group-photo-only; no individual bio pages; no Wikipedia article
-- GAP: -2540115004 Anna Callahan (City Councilor)
--   medfordma.org/citycouncil/ group-photo-only; no individual bio pages; no Wikipedia article
-- GAP: -2540115005 Matt Leming (City Councilor)
--   medfordma.org/citycouncil/ group-photo-only; no individual bio pages; no Wikipedia article
-- GAP: -2540115006 Liz Mullane (City Councilor)
--   medfordma.org/citycouncil/ group-photo-only; no individual bio pages; no Wikipedia article
-- GAP: -2540115007 George Scarpelli (City Councilor)
--   medfordma.org/citycouncil/ group-photo-only; no individual bio pages; no Wikipedia article
-- GAP: -2540115008 Justin Tseng (City Councilor)
--   medfordma.org/citycouncil/ group-photo-only; no individual bio pages; no Wikipedia article

-- ============================================================
-- SCHOOL COMMITTEE (external_ids -2506600001 through -2506600006)
-- All 6 elected SC members are gaps
-- ============================================================

-- GAP: -2506600001 Jenny Graham (School Committee Member, Vice Chair)
--   mps02155.org/about/school-committee group photo only (SCWebsitePhoto.png); no individual headshots; no Wikipedia article
-- GAP: -2506600002 Mike Mastrobuoni (School Committee Member)
--   mps02155.org/about/school-committee group photo only; no individual headshots; no Wikipedia article
-- GAP: -2506600003 Aaron Olapade (School Committee Member)
--   mps02155.org/about/school-committee group photo only; no individual headshots; no Wikipedia article
-- GAP: -2506600004 Jessica Parks (School Committee Member)
--   mps02155.org/about/school-committee group photo only; no individual headshots; no Wikipedia article
-- GAP: -2506600005 Erika Reinfeld (School Committee Member)
--   mps02155.org/about/school-committee group photo only; no individual headshots; no Wikipedia article
-- GAP: -2506600006 Paul Ruseau (School Committee Member, Secretary)
--   mps02155.org/about/school-committee group photo only; no individual headshots; no Wikipedia article

-- ============================================================
-- POST-VERIFICATION: Confirm correct type and count for Medford headshots
-- Two checks: city officials + SC members
-- ============================================================

DO $$
DECLARE
  v_city_img_count INTEGER;
  v_sc_img_count INTEGER;
  v_img_count INTEGER;
  v_wrong_type INTEGER;
BEGIN
  -- Count type='default' rows for city officials (external_id range -2540115008..-2540115001)
  SELECT COUNT(*) INTO v_city_img_count
  FROM essentials.politician_images pi
  JOIN essentials.politicians p ON p.id = pi.politician_id
  WHERE p.external_id BETWEEN -2540115008 AND -2540115001
    AND pi.type = 'default';

  -- Count type='default' rows for SC elected members (external_id range -2506600006..-2506600001)
  SELECT COUNT(*) INTO v_sc_img_count
  FROM essentials.politician_images pi
  JOIN essentials.politicians p ON p.id = pi.politician_id
  WHERE p.external_id BETWEEN -2506600006 AND -2506600001
    AND pi.type = 'default';

  v_img_count := v_city_img_count + v_sc_img_count;

  -- Confirm no wrong-type rows exist for any Medford official (city + SC)
  SELECT COUNT(*) INTO v_wrong_type
  FROM essentials.politician_images pi
  JOIN essentials.politicians p ON p.id = pi.politician_id
  WHERE (p.external_id BETWEEN -2540115008 AND -2540115001
      OR p.external_id BETWEEN -2506600006 AND -2506600001)
    AND pi.type != 'default';

  IF v_wrong_type > 0 THEN
    RAISE EXCEPTION 'Migration 595 post-verification FAILED: Medford headshots have wrong type (not default): % rows', v_wrong_type;
  END IF;

  RAISE NOTICE 'Migration 595 post-verification PASSED: % headshots total (% city + % SC) type=default; 13 gaps documented (medfordma.org group-photo-only; mps02155.org group-photo-only)', v_img_count, v_city_img_count, v_sc_img_count;
END $$;

-- ============================================================
-- MIGRATION LEDGER
-- ============================================================

INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('595')
ON CONFLICT (version) DO NOTHING;

COMMIT;
