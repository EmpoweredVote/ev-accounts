-- Migration 580: Newton city government + school committee headshots (NEWTON-02)
--
-- Storage bucket: politician_photos
-- CDN base: https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/
--
-- Total officials attempted: 33 (25 city + 8 SC; Mayor Laredo counted once)
-- Uploaded: 0 (all gaps — see documented gaps below)
-- Gap count: 33
--
-- Photo processing: crop 4:5 first, then resize 600x750 Lanczos q90.
-- politician_images.type = 'default' (UI filter: .find(img => img.type === 'default')).
-- politician_images uses the 'url' column for the CDN path.
-- No BEGIN/COMMIT — each INSERT is autocommit (matching migration 356 pattern).
-- photo_license = 'public_domain' for official city website photos.
--
-- Sources attempted:
--   newtonma.gov: HTTP 403 on ALL requests — even with Chrome browser User-Agent.
--     newtonma.gov uses CivicEngage/Revize CMS but blocks all programmatic access entirely.
--     URL pattern tried: /Home/Components/StaffDirectory/StaffDirectory/189/89?&img=N
--     URL pattern tried: /Home/Components/StaffDirectory/StaffDirectory/44/89?&img=1 (Mayor)
--     Result: 403 Forbidden for every councillor (25 officials)
--   laredofornewton.com: Campaign site headshot URL 404 (page removed post-election)
--     URL tried: /wp-content/uploads/Marc-Laredo-headshot.jpg
--     Result: 404 Not Found
--   newton.k12.ma.us: Guessed Centricity CMS path returns 404 for first 3 SC members,
--     then 429 Too Many Requests for remaining 5 (rate limiting triggered)
--     URL pattern tried: /cms/lib/MA01902636/Centricity/Template/GlobalAssets/images///school-committee/{lastname}.jpg
--     Result: 404 for Proia/Swain/Bhardwaj; 429 for Olszewski/Schlesinger/Greene/Piedalue/Lee
--
-- CRITICAL: type = 'default' (not 'headshot') — UI filter .find(img => img.type === 'default')
-- CRITICAL: insert into the url column (CDN path)
-- CRITICAL: WHERE NOT EXISTS guard on politician_id makes all blocks idempotent
--
-- Upload script: C:/EV-Accounts/backend/scripts/_tmp-newton-headshots.py
--   Run date: 2026-06-14
--   Result: 0 uploaded, 33 gaps (all sources blocked)
--
-- DOCUMENTED GAPS (33 officials — all gaps, not blocking):
--
-- CITY COUNCIL (25 officials) — newtonma.gov HTTP 403:
--   -2545560001 Marc C. Laredo (Mayor) — 403 on newtonma.gov; 404 on laredofornewton.com campaign site
--   -2545560002 Susan Albright (Ward 2 AL) — HTTP 403 on newtonma.gov
--   -2545560003 Brittany Hume Charm (Ward 5 AL) — HTTP 403 on newtonma.gov
--   -2545560004 Cyrus Dahmubed (Ward 4 AL) — HTTP 403 on newtonma.gov
--   -2545560005 Rena Getz (Ward 5 AL) — HTTP 403 on newtonma.gov
--   -2545560006 Brian Golden (Ward 7 AL) — HTTP 403 on newtonma.gov
--   -2545560007 Lisa Gordon (Ward 6 AL) — HTTP 403 on newtonma.gov
--   -2545560008 Becky Grossman (Ward 7 AL) — HTTP 403 on newtonma.gov
--   -2545560009 David Kalis (Ward 8 AL) — HTTP 403 on newtonma.gov
--   -2545560010 Andrea Kelley (Ward 3 AL) — HTTP 403 on newtonma.gov
--   -2545560011 Josh Krintzman (Ward 4 AL) — HTTP 403 on newtonma.gov
--   -2545560012 Allison Leary (Ward 1 AL) — HTTP 403 on newtonma.gov
--   -2545560013 Tarik Lucas (Ward 2 AL) — HTTP 403 on newtonma.gov
--   -2545560014 John Oliver (Ward 1 AL) — HTTP 403 on newtonma.gov
--   -2545560015 Sean Roche (Ward 6 AL) — HTTP 403 on newtonma.gov
--   -2545560016 Jacob Silber (Ward 8 AL) — HTTP 403 on newtonma.gov
--   -2545560017 Pamela Wright (Ward 3 AL) — HTTP 403 on newtonma.gov
--   -2545560018 R. Lisle Baker (Ward 7) — HTTP 403 on newtonma.gov
--   -2545560019 Martha Bixby (Ward 6) — HTTP 403 on newtonma.gov
--   -2545560020 Randy Block (Ward 4) — HTTP 403 on newtonma.gov
--   -2545560021 Stephen Farrell (Ward 8) — HTTP 403 on newtonma.gov
--   -2545560022 Maria S. Greenberg (Ward 1) — HTTP 403 on newtonma.gov
--   -2545560023 Julie Irish (Ward 5) — HTTP 403 on newtonma.gov
--   -2545560024 Julia Malakie (Ward 3) — HTTP 403 on newtonma.gov
--   -2545560025 David Micley (Ward 2) — HTTP 403 on newtonma.gov
--
-- SCHOOL COMMITTEE (8 members) — newton.k12.ma.us 404/429:
--   -2508610001 Arrianna Proia (Ward 1) — HTTP 404 on newton.k12.ma.us (no photos posted for new Jan 2026 members)
--   -2508610002 Linda Swain (Ward 2) — HTTP 404 on newton.k12.ma.us
--   -2508610003 Jason Bhardwaj (Ward 3, Vice Chair) — HTTP 404 on newton.k12.ma.us
--   -2508610004 Tamika Olszewski (Ward 4) — HTTP 429 (rate limited) on newton.k12.ma.us
--   -2508610005 Ben Schlesinger (Ward 5) — HTTP 429 (rate limited) on newton.k12.ma.us
--   -2508610006 Jonathan Greene (Ward 6) — HTTP 429 (rate limited) on newton.k12.ma.us
--   -2508610007 Alicia Piedalue (Ward 7, Chair) — HTTP 429 (rate limited) on newton.k12.ma.us
--   -2508610008 Victor Lee (Ward 8) — HTTP 429 (rate limited) on newton.k12.ma.us

-- ============================================================
-- CITY COUNCIL — 25 officials (all gaps)
-- external_id range: -2545560001..-2545560025
-- newtonma.gov blocks all programmatic access (HTTP 403 even with browser User-Agent)
-- ============================================================

-- GAP: -2545560001 Marc C. Laredo (Mayor) — 403 on newtonma.gov; 404 on laredofornewton.com
-- GAP: -2545560002 Susan Albright (Ward 2 AL) — HTTP 403 on newtonma.gov
-- GAP: -2545560003 Brittany Hume Charm (Ward 5 AL) — HTTP 403 on newtonma.gov
-- GAP: -2545560004 Cyrus Dahmubed (Ward 4 AL) — HTTP 403 on newtonma.gov
-- GAP: -2545560005 Rena Getz (Ward 5 AL) — HTTP 403 on newtonma.gov
-- GAP: -2545560006 Brian Golden (Ward 7 AL) — HTTP 403 on newtonma.gov
-- GAP: -2545560007 Lisa Gordon (Ward 6 AL) — HTTP 403 on newtonma.gov
-- GAP: -2545560008 Becky Grossman (Ward 7 AL) — HTTP 403 on newtonma.gov
-- GAP: -2545560009 David Kalis (Ward 8 AL) — HTTP 403 on newtonma.gov
-- GAP: -2545560010 Andrea Kelley (Ward 3 AL) — HTTP 403 on newtonma.gov
-- GAP: -2545560011 Josh Krintzman (Ward 4 AL) — HTTP 403 on newtonma.gov
-- GAP: -2545560012 Allison Leary (Ward 1 AL) — HTTP 403 on newtonma.gov
-- GAP: -2545560013 Tarik Lucas (Ward 2 AL) — HTTP 403 on newtonma.gov
-- GAP: -2545560014 John Oliver (Ward 1 AL) — HTTP 403 on newtonma.gov
-- GAP: -2545560015 Sean Roche (Ward 6 AL) — HTTP 403 on newtonma.gov
-- GAP: -2545560016 Jacob Silber (Ward 8 AL) — HTTP 403 on newtonma.gov
-- GAP: -2545560017 Pamela Wright (Ward 3 AL) — HTTP 403 on newtonma.gov
-- GAP: -2545560018 R. Lisle Baker (Ward 7) — HTTP 403 on newtonma.gov
-- GAP: -2545560019 Martha Bixby (Ward 6) — HTTP 403 on newtonma.gov
-- GAP: -2545560020 Randy Block (Ward 4) — HTTP 403 on newtonma.gov
-- GAP: -2545560021 Stephen Farrell (Ward 8) — HTTP 403 on newtonma.gov
-- GAP: -2545560022 Maria S. Greenberg (Ward 1) — HTTP 403 on newtonma.gov
-- GAP: -2545560023 Julie Irish (Ward 5) — HTTP 403 on newtonma.gov
-- GAP: -2545560024 Julia Malakie (Ward 3) — HTTP 403 on newtonma.gov
-- GAP: -2545560025 David Micley (Ward 2) — HTTP 403 on newtonma.gov

-- ============================================================
-- SCHOOL COMMITTEE — 8 members (all gaps)
-- external_id range: -2508610001..-2508610008
-- newton.k12.ma.us: 404 for first 3 (no photos posted); 429 rate limiting for remaining 5
-- ============================================================

-- GAP: -2508610001 Arrianna Proia (Ward 1) — HTTP 404 on newton.k12.ma.us; new Jan 2026 member, no official photo yet
-- GAP: -2508610002 Linda Swain (Ward 2) — HTTP 404 on newton.k12.ma.us; new Jan 2026 member
-- GAP: -2508610003 Jason Bhardwaj (Ward 3, Vice Chair) — HTTP 404 on newton.k12.ma.us
-- GAP: -2508610004 Tamika Olszewski (Ward 4) — HTTP 429 on newton.k12.ma.us (rate limited; likely also 404)
-- GAP: -2508610005 Ben Schlesinger (Ward 5) — HTTP 429 on newton.k12.ma.us (rate limited)
-- GAP: -2508610006 Jonathan Greene (Ward 6) — HTTP 429 on newton.k12.ma.us (rate limited)
-- GAP: -2508610007 Alicia Piedalue (Ward 7, Chair) — HTTP 429 on newton.k12.ma.us (rate limited)
-- GAP: -2508610008 Victor Lee (Ward 8) — HTTP 429 on newton.k12.ma.us (rate limited)

-- ============================================================
-- POST-VERIFICATION: Confirm 0 wrong-type rows for Newton officials
-- ============================================================

DO $$
DECLARE
  v_img_count INTEGER;
  v_wrong_type INTEGER;
BEGIN
  -- Count existing type='default' rows in Newton range (should be 0 since all gaps)
  SELECT COUNT(*) INTO v_img_count
  FROM essentials.politician_images pi
  JOIN essentials.politicians p ON p.id = pi.politician_id
  WHERE (p.external_id BETWEEN -2545560025 AND -2545560001
      OR p.external_id BETWEEN -2508610008 AND -2508610001)
    AND pi.type = 'default';

  -- Confirm no wrong-type rows exist
  SELECT COUNT(*) INTO v_wrong_type
  FROM essentials.politician_images pi
  JOIN essentials.politicians p ON p.id = pi.politician_id
  WHERE (p.external_id BETWEEN -2545560025 AND -2545560001
      OR p.external_id BETWEEN -2508610008 AND -2508610001)
    AND pi.type != 'default';

  IF v_wrong_type > 0 THEN
    RAISE EXCEPTION 'Migration 580 post-verification FAILED: Newton headshots have wrong type (not default): % rows', v_wrong_type;
  END IF;

  RAISE NOTICE 'Migration 580 post-verification PASSED: % headshots inserted (type=default), 33 gap officials documented (all gaps — newtonma.gov HTTP 403 blocks all programmatic access; newton.k12.ma.us 404/429)', v_img_count;
END $$;

-- ============================================================
-- MIGRATION LEDGER
-- ============================================================

INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('580')
ON CONFLICT (version) DO NOTHING;
