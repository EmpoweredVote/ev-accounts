-- CC_0195 — replace the Los Angeles city headshots for Curren D. Price Jr. and Imelda Padilla
--
-- WHY. Audit of everything the Los Angeles browse page renders, 2026-10-07
-- (.planning/todos/2026-10-07-la-headshot-replenish.md). 139 of 612 people render a photograph;
-- 19 fall below the bar. These two are the only ones whose replacement already exists on the
-- council member's own district site, so they go first.
--
--   Curren D. Price Jr. (CD 9) — rendered at 250x333, under the 300px floor. It was also the only
--   Los Angeles city row left on the `politician_photos/<uuid>/default.jpeg` path — the importer
--   that produced every not-a-person image found in the county audit of 2026-09-03 — and it carried
--   photo_origin_url = NULL, so nothing in the record said where the picture came from.
--   cd9.lacity.gov publishes THE SAME PHOTOGRAPH unstyled at 2213x2728. Identity is settled twice
--   over: the city's own alt text reads "Councilman Curren D Price Jr", and the frame matches the
--   one already live pixel for pixel. Crop matches the live framing deliberately (head 48% of frame
--   against 45%, eye line 23% in both), so this is a resolution fix and not a recomposition.
--
--   Imelda Padilla (CD 6) — rendered a full-length photograph taken outside a hot-dog stand, the
--   shop's signage across the top, her head about 15% of the frame. cd6.lacity.gov publishes her
--   official portrait at 1500x1500, alt text "Imelda Padilla Portrait", City Hall behind her.
--
-- Operator approved both crops on the proof sheet before upload, 2026-10-07.
--
-- 🔴 photo_custom_url IS WHAT RENDERS. The read paths build the photo from
-- COALESCE(p.photo_custom_url, p.photo_origin_url, '') — districtQueries.ts (address search),
-- essentialsBrowseService.ts, campaignFinanceSearchService.ts. A politician_images row alone
-- changes nothing a voter sees, so this migration writes photo_custom_url and nothing else is
-- needed. photo_origin_url is set alongside it as PROVENANCE: the city page the file came from.
--
-- The new objects are already uploaded and were read back byte-identical (sha256 prefix
-- ddcd0d82130ad12a and b97d34584cb90ee8). The OLD objects are left in place, so rolling back is
-- one UPDATE and needs no re-upload:
--
--   Price   photo_custom_url was https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/725d4081-e820-4064-83dc-3f8470bd7c2b/default.jpeg
--           photo_origin_url was NULL
--   Padilla photo_custom_url was https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d82a3080-0a11-4d73-bacb-a936e51c9fb3-headshot.jpg
--           photo_origin_url was https://cd6.lacity.gov/wp-content/uploads/2024/04/portrait-imelda-valley.jpg
--           (the hot-dog-stand frame; the city still serves it, so a revert needs no re-upload either)
--
-- Neither person carries a photo_restriction_code and neither has photo_custom_url_manual_override
-- set, so no operator override is being stepped on.
--
-- Idempotent: the UPDATEs are guarded on the value they write. The post-verify gate raises unless
-- both rows end up exactly right.

BEGIN;

-- Curren D. Price Jr. — Los Angeles City Council District 9
UPDATE essentials.politicians
   SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/725d4081-e820-4064-83dc-3f8470bd7c2b.jpg',
       photo_origin_url = 'https://cd9.lacity.gov/sites/g/files/wph2021/files/2022-02/Curren_D_Price_Jr_Portrait.jpg',
       last_update_date = now()
 WHERE id = '725d4081-e820-4064-83dc-3f8470bd7c2b'
   AND full_name = 'Curren D. Price Jr.'
   AND photo_custom_url IS DISTINCT FROM 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/725d4081-e820-4064-83dc-3f8470bd7c2b.jpg';

-- Imelda Padilla — Los Angeles City Council District 6
UPDATE essentials.politicians
   SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/d82a3080-0a11-4d73-bacb-a936e51c9fb3.jpg',
       photo_origin_url = 'https://cd6.lacity.gov/wp-content/uploads/2024/03/photo-imelda-portrait-02.jpg',
       last_update_date = now()
 WHERE id = 'd82a3080-0a11-4d73-bacb-a936e51c9fb3'
   AND full_name = 'Imelda Padilla'
   AND photo_custom_url IS DISTINCT FROM 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/la_city/2026-10-replenish/d82a3080-0a11-4d73-bacb-a936e51c9fb3.jpg';

DO $$
DECLARE
  r              record;
  v_expected     text;
  v_seen         int := 0;
  v_still_legacy int;
BEGIN
  FOR r IN
    SELECT id, full_name, photo_custom_url, photo_origin_url,
           coalesce(photo_custom_url_manual_override, false) AS override
      FROM essentials.politicians
     WHERE id IN ('725d4081-e820-4064-83dc-3f8470bd7c2b',
                  'd82a3080-0a11-4d73-bacb-a936e51c9fb3')
  LOOP
    v_seen := v_seen + 1;

    v_expected := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/'
                  || 'politician_photos/la_city/2026-10-replenish/' || r.id || '.jpg';

    IF r.photo_custom_url IS DISTINCT FROM v_expected THEN
      RAISE EXCEPTION 'CC_0195: % (%) has photo_custom_url %, expected %',
        r.full_name, r.id, coalesce(r.photo_custom_url, '<null>'), v_expected;
    END IF;

    -- Provenance must be the city page, never our own CDN: photo_origin_url answers
    -- "where did this come from", and pointing it at storage erases that answer.
    IF r.photo_origin_url IS NULL OR r.photo_origin_url !~ '^https://cd(6|9)\.lacity\.gov/' THEN
      RAISE EXCEPTION 'CC_0195: % (%) has photo_origin_url %, expected a cd6/cd9.lacity.gov source',
        r.full_name, r.id, coalesce(r.photo_origin_url, '<null>');
    END IF;

    IF r.override THEN
      RAISE EXCEPTION 'CC_0195: % (%) carries photo_custom_url_manual_override — refusing to claim it',
        r.full_name, r.id;
    END IF;
  END LOOP;

  IF v_seen <> 2 THEN
    RAISE EXCEPTION 'CC_0195: matched % of the 2 expected politician rows', v_seen;
  END IF;

  -- The county audit's root cause was the <uuid>/default.jpeg importer. Price was the last
  -- Los Angeles CITY row on it; assert the city is now clear of that path, so a future audit
  -- can tell a regression from the pre-existing backlog.
  SELECT count(*) INTO v_still_legacy
    FROM essentials.politicians p
    JOIN essentials.office_current_holder och ON och.politician_id = p.id
    JOIN essentials.offices o                 ON o.id  = och.office_id
    JOIN essentials.chambers c                ON c.id  = o.chamber_id
    JOIN essentials.governments g             ON g.id  = c.government_id
   WHERE g.geo_id = '0644000'
     AND g.mtfcc  = 'G4110'
     AND p.photo_custom_url LIKE '%/default.jpeg';

  IF v_still_legacy <> 0 THEN
    RAISE EXCEPTION 'CC_0195: % Los Angeles city officeholders still render from a <uuid>/default.jpeg path, expected 0',
      v_still_legacy;
  END IF;

  RAISE NOTICE 'CC_0195: Price and Padilla repointed; Los Angeles city is clear of <uuid>/default.jpeg';
END $$;

COMMIT;
