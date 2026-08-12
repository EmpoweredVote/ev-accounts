-- 1716_md42a_me29_headshots.sql
--
-- Headshots for the two officeholders seated in migration 1715, plus a fix to a defect that
-- migration introduced.
--
-- 🔴 THE DEFECT: 1715 created both politician rows without setting `politicians.is_vacant`, so both
-- carry NULL where all 1,338 seated state legislators carry false. That is not cosmetic — the
-- headshot tooling filters `AND p.is_vacant = false`, and NULL fails it, so both members were
-- INVISIBLE to the very sweep that is supposed to find people without photos. Same family as the
-- missing-office_terms trap in CLAUDE.md: nothing errors, the row simply stops existing as far as
-- the worklist is concerned. Fixed here for both.
--
-- Portraits are the chambers' own official photos, mirrored into the politician_photos bucket at
-- 600x750 (4:5) the same way their seatmates' are:
--   Harlan     mgaleg.maryland.gov/2026RS/images/harlan01.jpg  (250x300, alt "Harlan, Alexander M.")
--   Theriault  legislature.maine.gov/house/Repository/MemberProfiles/
--                c4c60e9c-d3f8-4037-87af-23e5ce8002db_Theriault.jpg  (152x202)
--
-- Both are state-government works, so photo_license 'public_domain', matching the peers
-- (Gifford -232028, White -232030, Guyton -2420125, Stonko -2420126).
--
-- Theriault's source is only 152x202 and the 600x750 render is visibly soft. That is NOT a defect to
-- chase: her seatmate Irene Gifford's source is the SAME 152x202 and is stored at 600x750. Maine
-- publishes portraits at that size, so this matches the chamber rather than falling short of it.
--
-- Identity was established PAGE-BOUND, not by filename: Theriault's image is the one served on her
-- own profile (Details/3142, verified "Nancy J. Theriault, House District 29, Millinocket"). A
-- Timothy Theriault also exists in Maine politics, and filename matching is precisely what fails
-- there. Both renders were then pulled back from the CDN and viewed at the pid they were stored
-- under, because a byte-count match cannot catch a pid-to-face swap.

DO $$
DECLARE
  v_harlan     uuid;
  v_theriault  uuid;
  v_n          int;
  c_harlan_url text := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/'
                       || 'public/politician_photos/2853f276-716f-48ec-a410-7bf54e543c1d-headshot.jpg';
  c_ther_url   text := 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/'
                       || 'public/politician_photos/53d513a4-0725-433f-bc7c-9c1929b6d4d7-headshot.jpg';
BEGIN
  -- Resolve on the synthetic external_id, not on name: %harlan% / %theriault% both match FEC
  -- ALLCAPS committee junk ("HARLAN FOR CAPITOLA CITY COUNCIL 2010").
  SELECT id INTO v_harlan    FROM essentials.politicians WHERE external_id = -2420142;
  SELECT id INTO v_theriault FROM essentials.politicians WHERE external_id = -232029;
  IF v_harlan IS NULL OR v_theriault IS NULL THEN
    RAISE EXCEPTION 'expected the migration 1715 rows to exist (harlan=%, theriault=%)',
                    v_harlan, v_theriault;
  END IF;

  -- Guard the pid-to-URL mapping in SQL too, so a future edit cannot quietly transpose the two
  -- filenames and give each member the other's face.
  IF position(v_harlan::text    in c_harlan_url) = 0
     OR position(v_theriault::text in c_ther_url) = 0 THEN
    RAISE EXCEPTION 'headshot URL does not embed the politician_id it is being attached to';
  END IF;

  -- ---- the 1715 defect: NULL is_vacant hides these rows from the headshot worklist -----------
  UPDATE essentials.politicians
     SET is_vacant = false
   WHERE id IN (v_harlan, v_theriault)
     AND is_vacant IS DISTINCT FROM false;

  -- ---- images (idempotent) -------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM essentials.politician_images
                  WHERE politician_id = v_harlan AND type = 'default') THEN
    INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
    VALUES (v_harlan, c_harlan_url, 'default', 'public_domain');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM essentials.politician_images
                  WHERE politician_id = v_theriault AND type = 'default') THEN
    INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
    VALUES (v_theriault, c_ther_url, 'default', 'public_domain');
  END IF;

  UPDATE essentials.politicians
     SET photo_origin_url = 'https://mgaleg.maryland.gov/mgawebsite/Members/Details/harlan01'
   WHERE id = v_harlan AND photo_origin_url IS DISTINCT FROM
         'https://mgaleg.maryland.gov/mgawebsite/Members/Details/harlan01';

  UPDATE essentials.politicians
     SET photo_origin_url = 'https://legislature.maine.gov/house/MemberProfiles/Details/3142'
   WHERE id = v_theriault AND photo_origin_url IS DISTINCT FROM
         'https://legislature.maine.gov/house/MemberProfiles/Details/3142';

  -- ---- post-verify ---------------------------------------------------------------------------
  SELECT count(*) INTO v_n FROM essentials.politician_images
   WHERE politician_id IN (v_harlan, v_theriault) AND type = 'default';
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'expected exactly 2 default images across the pair, found %', v_n;
  END IF;

  -- Each image is attached to the member whose id its filename carries.
  IF NOT EXISTS (SELECT 1 FROM essentials.politician_images
                  WHERE politician_id = v_harlan AND url = c_harlan_url) THEN
    RAISE EXCEPTION 'Harlan image row is not the Harlan URL';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM essentials.politician_images
                  WHERE politician_id = v_theriault AND url = c_ther_url) THEN
    RAISE EXCEPTION 'Theriault image row is not the Theriault URL';
  END IF;

  IF EXISTS (SELECT 1 FROM essentials.politicians
              WHERE id IN (v_harlan, v_theriault) AND photo_origin_url IS NULL) THEN
    RAISE EXCEPTION 'photo_origin_url not set on both';
  END IF;

  -- License is documented, never left blank.
  IF EXISTS (SELECT 1 FROM essentials.politician_images
              WHERE politician_id IN (v_harlan, v_theriault)
                AND (photo_license IS NULL OR photo_license <> 'public_domain')) THEN
    RAISE EXCEPTION 'photo_license is not public_domain on both image rows';
  END IF;

  -- The 1715 defect is gone: both now match their 1,338 peers and are visible to the worklist.
  IF EXISTS (SELECT 1 FROM essentials.politicians
              WHERE id IN (v_harlan, v_theriault) AND is_vacant IS NOT false) THEN
    RAISE EXCEPTION 'is_vacant still not false on both rows';
  END IF;

  -- And they are still the seated holders of their seats -- nothing here touched occupancy.
  SELECT count(*) INTO v_n
    FROM essentials.office_current_holder och
   WHERE och.politician_id IN (v_harlan, v_theriault);
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'expected both to still hold exactly one seat each, found % rows', v_n;
  END IF;

  RAISE NOTICE 'headshots attached for Harlan and Theriault; is_vacant NULL defect from 1715 fixed';
END $$;
