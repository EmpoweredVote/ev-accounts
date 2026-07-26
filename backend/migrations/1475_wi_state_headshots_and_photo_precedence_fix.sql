-- Migration 1475: WI state-tier headshots + photo display-precedence fix
--
-- PART A -- 9 new headshots for the State of Wisconsin tier:
--   * All 7 Supreme Court justices, from wicourts.gov official portraits at
--     /courts/supreme/justices/images/{name}lg.jpg (450x550 -> 1.33x upscale).
--   * Ann Roe (AD 44), the single legislator of 132 with no photo:
--     docs.legis.wisconsin.gov/2025/legislators/assembly/2889.jpg. NOTE docs.legis serves
--     150x200 for EVERY legislator, so the 4.0x upscale is the tier norm, not a Roe-specific
--     defect -- same ratio as the approved Maine Phase 52-03 precedent (152x202 -> 600x750).
--   * Chris Taylor, who is NOT among the current 144 because her Supreme Court term starts
--     2026-08-01 (the office_terms handoff from Rebecca Bradley), but who would otherwise be
--     seated with no photo. Sourced from her current Court of Appeals District IV page.
--
-- PART B -- BUG FIX for migrations 1472 / 1473 / 1474.
--   Those migrations set photo_origin_url to the SOURCE PAGE (following the /find-headshots
--   convention) and inserted politician_images rows. But the read path prefers the column:
--     backend:  COALESCE(p.photo_custom_url, p.photo_origin_url, '') AS photo_origin_url
--               (essentialsService.ts and 7 other sites)
--     ev-ui:    imageSrc = politician.photo_origin_url || politician.images[0].url
--               (renderPortrait / renderAvatar); Landing.jsx uses the field directly too
--   so an HTML page URL WINS over the correct bucket image and the portrait renders broken on
--   profile views. Verified against prod before writing this migration:
--     GET /api/essentials/politicians/6c040b24-... (Renee Kelly) returned
--       photo_origin_url = https://www.racinecounty.gov/departments/county-board/...
--       images[0].url    = https://kxsdzaojfaibhuzmclfq.storage.supabase.co/...
--   Fix: populate photo_custom_url with the mirrored bucket URL so the COALESCE resolves to a
--   real image, while photo_origin_url retains its documented provenance-page meaning.
--   PoliticianGrid and Results already prefer images[] and are unaffected either way.
--   Scoped to WI governments, only where photo_custom_url IS NULL, and respecting the
--   photo_custom_url_manual_override flag from migration 192 (D-08).
--
-- Idempotent: every statement guards on current state.

BEGIN;

-- PART A.1: headshot rows --------------------------------------------------
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '76329e1f-a53c-4c23-9fc7-8c36cdd74920', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/76329e1f-a53c-4c23-9fc7-8c36cdd74920-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='76329e1f-a53c-4c23-9fc7-8c36cdd74920');  -- Jill Karofsky (Chief Justice; 450x550 -> 1.33x)

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '0b238307-a895-4c2c-9d18-ba4f89b38b68', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0b238307-a895-4c2c-9d18-ba4f89b38b68-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='0b238307-a895-4c2c-9d18-ba4f89b38b68');  -- Annette Ziegler (450x550 -> 1.33x)

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '784a665f-09ad-44c1-bd7a-d2f9487255be', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/784a665f-09ad-44c1-bd7a-d2f9487255be-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='784a665f-09ad-44c1-bd7a-d2f9487255be');  -- Rebecca Bradley (450x550 -> 1.33x)

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '509215f9-d2c3-450a-b96d-e9df18cb4912', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/509215f9-d2c3-450a-b96d-e9df18cb4912-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='509215f9-d2c3-450a-b96d-e9df18cb4912');  -- Rebecca Dallet (450x550 -> 1.33x)

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT 'fd7a07a3-249b-4da6-84c8-b669e4365cb0', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fd7a07a3-249b-4da6-84c8-b669e4365cb0-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='fd7a07a3-249b-4da6-84c8-b669e4365cb0');  -- Brian Hagedorn (450x550 -> 1.33x)

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '1bad2141-4f57-4c5b-b9d2-a27e0c3b4750', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1bad2141-4f57-4c5b-b9d2-a27e0c3b4750-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='1bad2141-4f57-4c5b-b9d2-a27e0c3b4750');  -- Janet Protasiewicz (450x550 -> 1.33x)

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '9cd560aa-8413-4907-880c-469b8e083474', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9cd560aa-8413-4907-880c-469b8e083474-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='9cd560aa-8413-4907-880c-469b8e083474');  -- Susan M. Crawford (450x550 -> 1.33x)

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '732ee90d-016b-4879-9142-c3583130cf42', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/732ee90d-016b-4879-9142-c3583130cf42-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='732ee90d-016b-4879-9142-c3583130cf42');  -- Ann Roe AD 44 (150x200 -> 4.00x, tier norm)

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '8fbc6ee0-b0e9-400b-9a7a-3283757a07ab', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8fbc6ee0-b0e9-400b-9a7a-3283757a07ab-headshot.jpg', 'default', 'press_use'
WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images WHERE politician_id='8fbc6ee0-b0e9-400b-9a7a-3283757a07ab');  -- Chris Taylor (seats 2026-08-01; 300x366 -> 2.00x)

-- PART A.2: provenance pages -----------------------------------------------
UPDATE essentials.politicians SET photo_origin_url='https://www.wicourts.gov/courts/supreme/justices/karofsky.htm'     WHERE id='76329e1f-a53c-4c23-9fc7-8c36cdd74920' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.wicourts.gov/courts/supreme/justices/ziegler.htm'      WHERE id='0b238307-a895-4c2c-9d18-ba4f89b38b68' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.wicourts.gov/courts/supreme/justices/rbradley.htm'     WHERE id='784a665f-09ad-44c1-bd7a-d2f9487255be' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.wicourts.gov/courts/supreme/justices/dallet.htm'       WHERE id='509215f9-d2c3-450a-b96d-e9df18cb4912' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.wicourts.gov/courts/supreme/justices/hagedorn.htm'     WHERE id='fd7a07a3-249b-4da6-84c8-b669e4365cb0' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.wicourts.gov/courts/supreme/justices/protasiewicz.htm' WHERE id='1bad2141-4f57-4c5b-b9d2-a27e0c3b4750' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.wicourts.gov/courts/supreme/justices/crawford.htm'     WHERE id='9cd560aa-8413-4907-880c-469b8e083474' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://docs.legis.wisconsin.gov/2025/legislators/assembly/2889'   WHERE id='732ee90d-016b-4879-9142-c3583130cf42' AND photo_origin_url IS NULL;
UPDATE essentials.politicians SET photo_origin_url='https://www.wicourts.gov/courts/appeals/judges/taylor.htm'         WHERE id='8fbc6ee0-b0e9-400b-9a7a-3283757a07ab' AND photo_origin_url IS NULL;

-- PART B: make the read path resolve a real image (see header) --------------
-- Sets photo_custom_url from the mirrored bucket image for every WI officeholder that has a
-- politician_images row but no photo_custom_url. Covers the 9 above and repairs the 48
-- officials enriched by 1472/1473/1474.
UPDATE essentials.politicians p
SET photo_custom_url = pi.url
FROM essentials.politician_images pi
WHERE pi.politician_id = p.id
  AND p.photo_custom_url IS NULL
  AND coalesce(p.photo_custom_url_manual_override, false) = false
  AND p.id IN (
    SELECT DISTINCT coh.politician_id
    FROM essentials.office_current_holder coh
    JOIN essentials.offices o     ON o.id = coh.office_id
    JOIN essentials.chambers c    ON c.id = o.chamber_id
    JOIN essentials.governments g ON g.id = c.government_id
    WHERE g.state ILIKE 'WI'
  );

-- Chris Taylor is not a current officeholder until 2026-08-01, so the scoped update above
-- does not reach her; set hers explicitly.
UPDATE essentials.politicians
SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8fbc6ee0-b0e9-400b-9a7a-3283757a07ab-headshot.jpg'
WHERE id = '8fbc6ee0-b0e9-400b-9a7a-3283757a07ab'
  AND photo_custom_url IS NULL
  AND coalesce(photo_custom_url_manual_override, false) = false;

COMMIT;
