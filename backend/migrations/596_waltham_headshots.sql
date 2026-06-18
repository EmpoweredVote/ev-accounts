-- Migration 596: Waltham city officials headshots (WALTHAM-02)
--
-- Storage bucket: politician_photos
-- CDN base: https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/
--
-- Total officials attempted: 16 (Mayor Donahue + 6 at-large + 9 ward City Councillors)
-- Uploaded: 0
-- Gap count: 16
--
-- Photo processing: crop 4:5 first, then resize 600x750 Lanczos q90
-- type = 'default' (NOT 'headshot') — UI filter uses .find(img => img.type === 'default')
--
-- SOURCE INVESTIGATION:
--   city.waltham.ma.us is behind Cloudflare Managed Challenge. All pages return HTTP 200
--   but the body is a JavaScript challenge page ("Just a moment...", "Enable JavaScript and
--   cookies to continue") that requires browser JS execution to resolve. No image content
--   is accessible via curl/requests without a JS-capable browser.
--   mayor.waltham.ma.us subdomain returns connection timeout (000 / ECONNREFUSED).
--   Wikipedia: "Arthur Donahue (politician)" is a redirect/stub (noarticletext=True;
--   no upload.wikimedia.org image URLs present in the article body).
--   No Wikipedia articles found for any of the 15 councillors.
--   Result: All 16 officials are gaps — honest best-effort per WALTHAM-02 requirement.
--
-- DOCUMENTED GAPS (all 16 officials):
--   -2572600001 Arthur Donahue (Mayor)                   — Cloudflare JS challenge; Wikipedia stub (no headshot)
--   -2572600002 Colleen Bradley-MacArthur (At-Large)     — Cloudflare JS challenge; no Wikipedia article
--   -2572600003 Paul Brasco (At-Large)                   — Cloudflare JS challenge; no Wikipedia article
--   -2572600004 Tim King (At-Large)                      — Cloudflare JS challenge; no Wikipedia article
--   -2572600005 Randall LeBlanc (At-Large, VP)           — Cloudflare JS challenge; no Wikipedia article
--   -2572600006 Emma Tzioumis (At-Large)                 — Cloudflare JS challenge; no Wikipedia article
--   -2572600007 Carlos Vidal (At-Large)                  — Cloudflare JS challenge; no Wikipedia article
--   -2572600008 Anthony LaFauci (Ward 1)                 — Cloudflare JS challenge; no Wikipedia article
--   -2572600009 Caren Dunn (Ward 2)                      — Cloudflare JS challenge; no Wikipedia article
--   -2572600010 Bill Hanley (Ward 3)                     — Cloudflare JS challenge; no Wikipedia article
--   -2572600011 John McLaughlin (Ward 4)                 — Cloudflare JS challenge; no Wikipedia article
--   -2572600012 Joseph LaCava (Ward 5)                   — Cloudflare JS challenge; no Wikipedia article
--   -2572600013 Sean Durkee (Ward 6)                     — Cloudflare JS challenge; no Wikipedia article
--   -2572600014 Paul Katz (Ward 7)                       — Cloudflare JS challenge; no Wikipedia article
--   -2572600015 Cathyann Harris (Ward 8)                 — Cloudflare JS challenge; no Wikipedia article
--   -2572600016 Robert Logan (Ward 9, President)         — Cloudflare JS challenge; no Wikipedia article
--
-- Upload script: C:/EV-Accounts/backend/scripts/_tmp-waltham-headshots.py
--   Run date: 2026-06-15
--   Result: 0 uploaded, 16 gaps
--
-- CRITICAL: type = 'default' (not 'headshot') — UI filter .find(img => img.type === 'default')
-- CRITICAL: WHERE NOT EXISTS guard on politician_id makes all blocks idempotent

-- ============================================================
-- CITY COUNCIL (external_ids -2572600001 through -2572600016)
-- 0 uploaded; 16 gaps
-- ============================================================

-- GAP: -2572600001 Arthur Donahue (Mayor)
--   city.waltham.ma.us Cloudflare JS challenge (HTTP 200, body=JS challenge, no images accessible);
--   Wikipedia "Arthur Donahue (politician)" is a redirect/stub (noarticletext=True; no images)
-- GAP: -2572600002 Colleen Bradley-MacArthur (City Councillor At-Large)
--   city.waltham.ma.us Cloudflare JS challenge; no Wikipedia article found
-- GAP: -2572600003 Paul Brasco (City Councillor At-Large)
--   city.waltham.ma.us Cloudflare JS challenge; no Wikipedia article found
-- GAP: -2572600004 Tim King (City Councillor At-Large)
--   city.waltham.ma.us Cloudflare JS challenge; no Wikipedia article found
-- GAP: -2572600005 Randall LeBlanc (City Councillor At-Large, VP)
--   city.waltham.ma.us Cloudflare JS challenge; no Wikipedia article found
-- GAP: -2572600006 Emma Tzioumis (City Councillor At-Large)
--   city.waltham.ma.us Cloudflare JS challenge; no Wikipedia article found
-- GAP: -2572600007 Carlos Vidal (City Councillor At-Large)
--   city.waltham.ma.us Cloudflare JS challenge; no Wikipedia article found
-- GAP: -2572600008 Anthony LaFauci (City Councillor Ward 1)
--   city.waltham.ma.us Cloudflare JS challenge; no Wikipedia article found
-- GAP: -2572600009 Caren Dunn (City Councillor Ward 2)
--   city.waltham.ma.us Cloudflare JS challenge; no Wikipedia article found
-- GAP: -2572600010 Bill Hanley (City Councillor Ward 3)
--   city.waltham.ma.us Cloudflare JS challenge; no Wikipedia article found
-- GAP: -2572600011 John McLaughlin (City Councillor Ward 4)
--   city.waltham.ma.us Cloudflare JS challenge; no Wikipedia article found
-- GAP: -2572600012 Joseph LaCava (City Councillor Ward 5)
--   city.waltham.ma.us Cloudflare JS challenge; no Wikipedia article found
-- GAP: -2572600013 Sean Durkee (City Councillor Ward 6)
--   city.waltham.ma.us Cloudflare JS challenge; no Wikipedia article found
-- GAP: -2572600014 Paul Katz (City Councillor Ward 7)
--   city.waltham.ma.us Cloudflare JS challenge; no Wikipedia article found
-- GAP: -2572600015 Cathyann Harris (City Councillor Ward 8)
--   city.waltham.ma.us Cloudflare JS challenge; no Wikipedia article found
-- GAP: -2572600016 Robert Logan (City Councillor Ward 9, President)
--   city.waltham.ma.us Cloudflare JS challenge; no Wikipedia article found

-- ============================================================
-- POST-VERIFICATION: Confirm no wrong-type rows for Waltham
-- ============================================================

DO $$
DECLARE
  v_img_count INTEGER;
  v_wrong_type INTEGER;
BEGIN
  -- Count type='default' rows in Waltham external_id range
  SELECT COUNT(*) INTO v_img_count
  FROM essentials.politician_images pi
  JOIN essentials.politicians p ON p.id = pi.politician_id
  WHERE p.external_id BETWEEN -2572600016 AND -2572600001
    AND pi.type = 'default';

  -- Confirm no wrong-type rows exist for Waltham officials
  SELECT COUNT(*) INTO v_wrong_type
  FROM essentials.politician_images pi
  JOIN essentials.politicians p ON p.id = pi.politician_id
  WHERE p.external_id BETWEEN -2572600016 AND -2572600001
    AND pi.type != 'default';

  IF v_wrong_type > 0 THEN
    RAISE EXCEPTION 'Migration 596 post-verification FAILED: Waltham headshots have wrong type (not default): % rows', v_wrong_type;
  END IF;

  RAISE NOTICE 'Migration 596 post-verification PASSED: % headshots (type=default), 16 gaps documented (city.waltham.ma.us Cloudflare JS challenge; no Wikipedia articles)', v_img_count;
END $$;

-- ============================================================
-- MIGRATION LEDGER
-- ============================================================

INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('596')
ON CONFLICT (version) DO NOTHING;

COMMIT;
