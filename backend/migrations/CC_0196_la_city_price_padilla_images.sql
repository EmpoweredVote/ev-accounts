-- CC_0196 — repoint essentials.politician_images for Curren D. Price Jr. and Imelda Padilla
--
-- 🔴 WHY THIS EXISTS, AND WHY CC_0195 WAS NOT ENOUGH.
--
-- The standing rule in this repo is "photo_custom_url is what renders; a politician_images row
-- alone changes nothing a voter sees". That rule is about the BACKEND, and it is still true there:
-- districtQueries.ts, essentialsBrowseService.ts and campaignFinanceSearchService.ts all build the
-- scalar photo from COALESCE(p.photo_custom_url, p.photo_origin_url, '').
--
-- It is NOT true of the browse grid the voter actually looks at. The essentials frontend's
-- PoliticianGrid.getImageData() reads the OTHER way round:
--
--     if (pol.images && pol.images.length > 0) {
--       const defaultImg = pol.images.find((img) => img.type === "default");
--       return { url: (defaultImg || pol.images[0]).url, ... };
--     }
--     return { url: pol.photo_origin_url, focalPoint: null };
--
-- So wherever a politician_images row EXISTS, it wins, and the scalar is only the fallback. The
-- API serves `images` alongside the scalar, which is how both values reach the page.
--
-- Measured on production 2026-10-07, immediately after CC_0195: the API returned the new
-- la_city/2026-10-replenish URLs in photo_origin_url for both people, and the live page kept
-- rendering the old files at 250x333 and 600x750 — because each still had a type='default'
-- politician_images row pointing at the old object. Repointing the scalar alone moved nothing a
-- voter sees. ⚠ Any future headshot replacement must write BOTH, or check that no images row
-- exists first.
--
-- photo_license is corrected at the same time, because the new files have a different provenance
-- from the old ones:
--   * Price's row claimed cc_by_sa_4.0 while his photo_origin_url was NULL — a licence asserted
--     with no source recorded behind it. The file now comes from the council district's own site.
--   * The City of Los Angeles publishes no photo-use policy. Its only notice, at
--     disclaimer.lacity.gov/disclaimer.htm, reads "© Copyright City of Los Angeles. All rights
--     reserved." Both rows therefore record the source and that absence, and assert no permission.
--     This does not change house practice: Padilla's existing row already served a cd6.lacity.gov
--     file under 'scraped_no_license'.
--
-- Exactly one type='default' row exists per person; neither is created here. The post-verify gate
-- raises unless both end up on the new object, and unless the grid's own resolution rule — the
-- type='default' row — agrees with photo_custom_url.
--
-- Rollback, if wanted, is one UPDATE back to:
--   Price   https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/725d4081-e820-4064-83dc-3f8470bd7c2b/default.jpeg         licence cc_by_sa_4.0
--   Padilla https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d82a3080-0a11-4d73-bacb-a936e51c9fb3-headshot.jpg  licence scraped_no_license
-- Both old objects are still in the bucket.
--
-- Idempotent: each UPDATE is guarded on the value it writes.

BEGIN;

UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/725d4081-e820-4064-83dc-3f8470bd7c2b.jpg',
       photo_license = 'City of Los Angeles Council District 9 official portrait (cd9.lacity.gov). The city publishes no photo-use policy; its only notice is "© Copyright City of Los Angeles. All rights reserved." (disclaimer.lacity.gov/disclaimer.htm).'
 WHERE politician_id = '725d4081-e820-4064-83dc-3f8470bd7c2b'
   AND type = 'default'
   AND url IS DISTINCT FROM 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/725d4081-e820-4064-83dc-3f8470bd7c2b.jpg';

UPDATE essentials.politician_images
   SET url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/d82a3080-0a11-4d73-bacb-a936e51c9fb3.jpg',
       photo_license = 'City of Los Angeles Council District 6 official portrait (cd6.lacity.gov). The city publishes no photo-use policy; its only notice is "© Copyright City of Los Angeles. All rights reserved." (disclaimer.lacity.gov/disclaimer.htm).'
 WHERE politician_id = 'd82a3080-0a11-4d73-bacb-a936e51c9fb3'
   AND type = 'default'
   AND url IS DISTINCT FROM 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/d82a3080-0a11-4d73-bacb-a936e51c9fb3.jpg';

DO $$
DECLARE
  r          record;
  v_expected text;
  v_seen     int := 0;
  v_defaults int;
BEGIN
  FOR r IN
    SELECT p.id, p.full_name, p.photo_custom_url,
           (SELECT count(*) FROM essentials.politician_images i
             WHERE i.politician_id = p.id AND i.type = 'default')             AS n_default,
           (SELECT i.url FROM essentials.politician_images i
             WHERE i.politician_id = p.id AND i.type = 'default' LIMIT 1)     AS default_url,
           (SELECT count(*) FROM essentials.politician_images i
             WHERE i.politician_id = p.id AND i.url LIKE '%/default.jpeg')    AS n_legacy
      FROM essentials.politicians p
     WHERE p.id IN ('725d4081-e820-4064-83dc-3f8470bd7c2b',
                    'd82a3080-0a11-4d73-bacb-a936e51c9fb3')
  LOOP
    v_seen := v_seen + 1;

    v_expected := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/'
                  || 'politician_photos/la_city/2026-10-replenish/' || r.id || '.jpg';

    -- Exactly one default row. Two would make the grid's find() pick an arbitrary one.
    IF r.n_default <> 1 THEN
      RAISE EXCEPTION 'CC_0196: % (%) has % rows of type=default, expected exactly 1',
        r.full_name, r.id, r.n_default;
    END IF;

    IF r.default_url IS DISTINCT FROM v_expected THEN
      RAISE EXCEPTION 'CC_0196: % (%) default image is %, expected %',
        r.full_name, r.id, coalesce(r.default_url, '<null>'), v_expected;
    END IF;

    -- 🔴 THE POINT OF THIS MIGRATION: the grid reads the images row, the backend reads the
    -- scalar. If they disagree, the voter and the API are looking at different photographs.
    IF r.photo_custom_url IS DISTINCT FROM r.default_url THEN
      RAISE EXCEPTION 'CC_0196: % (%) renders % in the grid but % through the API — they must agree',
        r.full_name, r.id, r.default_url, coalesce(r.photo_custom_url, '<null>');
    END IF;

    IF r.n_legacy <> 0 THEN
      RAISE EXCEPTION 'CC_0196: % (%) still has % image row(s) on a <uuid>/default.jpeg path',
        r.full_name, r.id, r.n_legacy;
    END IF;
  END LOOP;

  IF v_seen <> 2 THEN
    RAISE EXCEPTION 'CC_0196: matched % of the 2 expected politician rows', v_seen;
  END IF;

  -- No Los Angeles city officeholder should now render from the legacy importer path by EITHER
  -- route. This is the assertion CC_0195 could only make for half the problem.
  SELECT count(*) INTO v_defaults
    FROM essentials.politicians p
    JOIN essentials.office_current_holder och ON och.politician_id = p.id
    JOIN essentials.offices o                 ON o.id  = och.office_id
    JOIN essentials.chambers c                ON c.id  = o.chamber_id
    JOIN essentials.governments g             ON g.id  = c.government_id
   WHERE g.geo_id = '0644000'
     AND g.mtfcc  = 'G4110'
     AND (p.photo_custom_url LIKE '%/default.jpeg'
          OR EXISTS (SELECT 1 FROM essentials.politician_images i
                      WHERE i.politician_id = p.id AND i.url LIKE '%/default.jpeg'));

  IF v_defaults <> 0 THEN
    RAISE EXCEPTION 'CC_0196: % Los Angeles city officeholders still reach a <uuid>/default.jpeg object, expected 0',
      v_defaults;
  END IF;

  RAISE NOTICE 'CC_0196: grid and API agree for Price and Padilla; Los Angeles city is clear of <uuid>/default.jpeg by both routes';
END $$;

COMMIT;
