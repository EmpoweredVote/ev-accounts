-- Migration 594: Fall River city officials headshots (FALLRIV-02)
--
-- Storage bucket: politician_photos
-- CDN base: https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/
--
-- Total officials attempted: 10 (Mayor Coogan + 9 at-large City Councilors)
-- Uploaded: 0
-- Gap count: 10
--
-- Photo processing: crop 4:5 first, then resize 600x750 Lanczos q90
-- type = 'default' (NOT 'headshot') — UI filter uses .find(img => img.type === 'default')
--
-- SOURCE INVESTIGATION:
--   fallriverma.org uses Revize CMS. The city council page
--   (https://www.fallriverma.org/government/city_council/current_council.php)
--   returns HTTP 200 but contains only a group photo:
--     "Document Center/City Council/Group Photo 26-27/Group photo - All Councilors - Copy.jpg"
--   No individual bio pages or headshot images are available anywhere on fallriverma.org.
--   Mayor page (https://www.fallriverma.org/government/mayor/index.php) also has no headshot
--   (Revize CMS — only site navigation icons, no person photo).
--   Wikipedia: no article found for Paul Coogan (politician) or any Fall River councilors
--   tested (Coogan, Ponte, Dionne, Hart, Camara, Pereira, Raposo, Cadime, Canuel, Peckham).
--   Result: All 10 officials are gaps — honest best-effort per FALLRIV-02 requirement.
--
-- DOCUMENTED GAPS (all 10 officials):
--   -2523000001 Paul Coogan (Mayor)        — fallriverma.org Revize CMS group-photo-only; no Wikipedia article
--   -2523000002 Cliff Ponte (Councilor)    — fallriverma.org Revize CMS group-photo-only; no Wikipedia article
--   -2523000003 Michelle Dionne (Councilor)— fallriverma.org Revize CMS group-photo-only; no Wikipedia article
--   -2523000004 Paul Hart (Councilor)      — fallriverma.org Revize CMS group-photo-only; no Wikipedia article
--   -2523000005 Joseph Camara (Councilor)  — fallriverma.org Revize CMS group-photo-only; no Wikipedia article
--   -2523000006 Linda Pereira (Councilor)  — fallriverma.org Revize CMS group-photo-only; no Wikipedia article
--   -2523000007 Andrew Raposo (Councilor)  — fallriverma.org Revize CMS group-photo-only; no Wikipedia article
--   -2523000008 Shawn Cadime (Councilor)   — fallriverma.org Revize CMS group-photo-only; no Wikipedia article
--   -2523000009 Michael Canuel (Councilor) — fallriverma.org Revize CMS group-photo-only; no Wikipedia article
--   -2523000010 Christopher Peckham (Councilor) — fallriverma.org Revize CMS group-photo-only; no Wikipedia article
--
-- Upload script: C:/EV-Accounts/backend/scripts/_tmp-fall-river-headshots.py
--   Run date: 2026-06-15
--   Result: 0 uploaded, 10 gaps
--
-- CRITICAL: type = 'default' (not 'headshot') — UI filter .find(img => img.type === 'default')
-- CRITICAL: WHERE NOT EXISTS guard on politician_id makes all blocks idempotent

-- ============================================================
-- CITY COUNCIL (external_ids -2523000001 through -2523000010)
-- 0 uploaded; 10 gaps
-- ============================================================

-- GAP: -2523000001 Paul Coogan (Mayor)
--   fallriverma.org (Revize CMS) has no individual headshots on mayor page or council page;
--   Wikipedia has no article for "Paul Coogan (politician)"
-- GAP: -2523000002 Cliff Ponte (City Councilor, Council President 2026-2027)
--   fallriverma.org (Revize CMS) group-photo-only council page; no Wikipedia article found
-- GAP: -2523000003 Michelle Dionne (City Councilor, Council Vice President 2026-2027)
--   fallriverma.org (Revize CMS) group-photo-only council page; no Wikipedia article found
-- GAP: -2523000004 Paul Hart (City Councilor)
--   fallriverma.org (Revize CMS) group-photo-only council page; no Wikipedia article found
-- GAP: -2523000005 Joseph Camara (City Councilor)
--   fallriverma.org (Revize CMS) group-photo-only council page; no Wikipedia article found
-- GAP: -2523000006 Linda Pereira (City Councilor)
--   fallriverma.org (Revize CMS) group-photo-only council page; no Wikipedia article found
-- GAP: -2523000007 Andrew Raposo (City Councilor)
--   fallriverma.org (Revize CMS) group-photo-only council page; no Wikipedia article found
-- GAP: -2523000008 Shawn Cadime (City Councilor)
--   fallriverma.org (Revize CMS) group-photo-only council page; no Wikipedia article found
-- GAP: -2523000009 Michael Canuel (City Councilor)
--   fallriverma.org (Revize CMS) group-photo-only council page; no Wikipedia article found
-- GAP: -2523000010 Christopher Peckham (City Councilor)
--   fallriverma.org (Revize CMS) group-photo-only council page; no Wikipedia article found

-- ============================================================
-- POST-VERIFICATION: Confirm no wrong-type rows for Fall River
-- ============================================================

DO $$
DECLARE
  v_img_count INTEGER;
  v_wrong_type INTEGER;
BEGIN
  -- Count type='default' rows in Fall River external_id range
  SELECT COUNT(*) INTO v_img_count
  FROM essentials.politician_images pi
  JOIN essentials.politicians p ON p.id = pi.politician_id
  WHERE p.external_id BETWEEN -2523000010 AND -2523000001
    AND pi.type = 'default';

  -- Confirm no wrong-type rows exist for Fall River officials
  SELECT COUNT(*) INTO v_wrong_type
  FROM essentials.politician_images pi
  JOIN essentials.politicians p ON p.id = pi.politician_id
  WHERE p.external_id BETWEEN -2523000010 AND -2523000001
    AND pi.type != 'default';

  IF v_wrong_type > 0 THEN
    RAISE EXCEPTION 'Migration 594 post-verification FAILED: Fall River headshots have wrong type (not default): % rows', v_wrong_type;
  END IF;

  RAISE NOTICE 'Migration 594 post-verification PASSED: % headshots (type=default), 10 gaps documented (fallriverma.org Revize CMS group-photo-only; no Wikipedia articles found)', v_img_count;
END $$;

-- ============================================================
-- MIGRATION LEDGER
-- ============================================================

INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('594')
ON CONFLICT (version) DO NOTHING;

COMMIT;
