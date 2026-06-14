-- Migration 588: New Bedford city officials headshots (NEWBED-02)
-- Storage bucket: politician_photos
-- CDN base: https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/
-- Total officials attempted: 12 (city only; SC out of scope for Phase 120)
-- Uploaded: 1 (Mayor Jon Mitchell — Wikipedia Commons)
-- Gap count: 11 (all councilors — newbedford-ma.gov Cloudflare JS challenge; no alternative source found)
-- newbedford-ma.gov: Cloudflare JS challenge — all official city bio pages inaccessible programmatically
-- Photo processing: crop 4:5 first, then resize 600x750 Lanczos q90
-- type = 'default' (NOT 'headshot') — UI filter uses .find(img => img.type === 'default')
-- Upload script: C:/EV-Accounts/backend/scripts/_tmp-new-bedford-headshots.py
--   Run date: 2026-06-14
--   Result: 1 uploaded, 11 gaps

BEGIN;

-- Jon Mitchell (Mayor) — external_id -2545000001
-- Source: https://upload.wikimedia.org/wikipedia/commons/7/79/Jon_Mitchell_22520740514_25f19af20d_k.jpg
-- Wikipedia Commons 2015 speaking engagement photo; 1536x2048 original; cropped 4:5, resized 600x750
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -2545000001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5114097d-c06a-4147-85bc-f9a6646f5c46-headshot.jpg',
       'default', 'public_domain'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -2545000001)
);

-- GAP: -2545000002 Ian Abreu — newbedford-ma.gov Cloudflare JS challenge (bio page inaccessible programmatically); no Wikipedia Commons image found; no confirmed alternative source
-- GAP: -2545000003 Shane Burgo — newbedford-ma.gov Cloudflare JS challenge (bio page inaccessible programmatically); no Wikipedia Commons image found; no confirmed alternative source
-- GAP: -2545000004 Naomi Carney — newbedford-ma.gov Cloudflare JS challenge (bio page inaccessible programmatically); no Wikipedia Commons image found; no confirmed alternative source
-- GAP: -2545000005 Brian Gomes — newbedford-ma.gov Cloudflare JS challenge (bio page inaccessible programmatically); no Wikipedia Commons image found; no confirmed alternative source
-- GAP: -2545000006 James Roy — newbedford-ma.gov Cloudflare JS challenge (bio page inaccessible programmatically); newly elected Nov 2025 (bio page may not exist yet); no confirmed alternative source
-- GAP: -2545000007 Leo Choquette — newbedford-ma.gov Cloudflare JS challenge (bio page inaccessible programmatically); no Wikipedia Commons image found; no confirmed alternative source
-- GAP: -2545000008 Scott Pemberton — newbedford-ma.gov Cloudflare JS challenge (bio page inaccessible programmatically); newly elected Nov 2025 (bio page may not exist yet); no confirmed alternative source
-- GAP: -2545000009 Shawn Oliver — newbedford-ma.gov Cloudflare JS challenge (bio page inaccessible programmatically); no confirmed campaign site or Wikipedia Commons image found (entered MA LG race but no accessible headshot URL)
-- GAP: -2545000010 Derek Baptiste — newbedford-ma.gov Cloudflare JS challenge (bio page inaccessible programmatically); no Wikipedia Commons image found; no confirmed alternative source
-- GAP: -2545000011 Joseph Lopes — newbedford-ma.gov Cloudflare JS challenge (bio page inaccessible programmatically); no Wikipedia Commons image found; no confirmed alternative source
-- GAP: -2545000012 Ryan Pereira — newbedford-ma.gov Cloudflare JS challenge (bio page inaccessible programmatically); no Wikipedia Commons image found; no confirmed alternative source

-- Post-verification DO block
DO $$
DECLARE
  v_img_count   INTEGER;
  v_wrong_type  INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_img_count
  FROM essentials.politician_images pi
  JOIN essentials.politicians p ON p.id = pi.politician_id
  WHERE p.external_id BETWEEN -2545000012 AND -2545000001
    AND pi.type = 'default';

  SELECT COUNT(*) INTO v_wrong_type
  FROM essentials.politician_images pi
  JOIN essentials.politicians p ON p.id = pi.politician_id
  WHERE p.external_id BETWEEN -2545000012 AND -2545000001
    AND pi.type != 'default';

  IF v_wrong_type > 0 THEN
    RAISE EXCEPTION 'Migration 588 post-verification FAILED: New Bedford headshots have wrong type: % rows', v_wrong_type;
  END IF;

  RAISE NOTICE 'Migration 588 post-verification PASSED: % headshots inserted (type=default), % gap officials documented', v_img_count, (12 - v_img_count);
END $$;

INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('588')
ON CONFLICT (version) DO NOTHING;

COMMIT;
