-- 1506_civicpatch_cristina_todd_headshot.sql
--
-- The ONE image out of the CivicPatch batch that survived verification.
-- Cristina Todd, Council Member Place 2, Princeton TX (3c8d7283-2387-47ff-8a29-1ef7a1e2a554),
-- who had no image at all.
--
-- WHY ONLY ONE, OUT OF TEN. CivicPatch offered 10 images for people we hold and lacking a photo.
-- Nine were rejected:
--
--   6 (all of Farmersville) shared ONE file — a 3840x2160 sunset lake photo with a kayaker. Its
--     source URL is a Drupal image style literally named "inner_background": their scraper falls
--     back to the page background when it finds no portrait.
--   3 (Van Alstyne) were genuine professional headshots OF THE WRONG PEOPLE. Verified against the
--     live council page: their images are shifted one position against their names — Lee Thomas
--     was given Ryan T. Neal's face, Neal was given Marla E. Butler's, and so on down the list,
--     with the last falling off the end. Cause is visible in their own data: the Mayor has no
--     image, so their scraper's ordered name list and ordered image list desynchronised by one.
--
-- 🔴 NO CHEAP CHECK CATCHES THE VAN ALSTYNE CLASS. Those three are real headshots of real sitting
-- councilmembers from the right city — correct aspect, distinct URLs, plausible on a contact sheet.
-- The URLs are opaque blob tokens carrying no name, so the correct-person guard is blind. Only
-- cross-referencing the live source page reveals it.
--
-- WHY THIS ONE IS TRUSTWORTHY. Her CivicPatch record cites a PERSON-SPECIFIC source page,
-- princetontx.gov/733/cristina-todd, and documentId=3518 appears on that page. A per-person URL is
-- self-verifying; a roster URL is positional, which is exactly what broke Van Alstyne.
--
-- PROVENANCE. Fetched from princetontx.gov directly, not cdn.civicpatch.org (byte-identical, but we
-- do not take a runtime dependency on their CDN). Cropped 4:5 from the 1733x2600 original at
-- (280,230)-(1320,1530), one ear-length above the hair per house style, resized to 600x750, and
-- copied into our own Storage bucket rather than hotlinked.

BEGIN;

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT '3c8d7283-2387-47ff-8a29-1ef7a1e2a554'::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3c8d7283-2387-47ff-8a29-1ef7a1e2a554-headshot.jpg',
       'default',
       'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
   WHERE politician_id = '3c8d7283-2387-47ff-8a29-1ef7a1e2a554'::uuid);

DO $$
DECLARE
  n int;
BEGIN
  SELECT count(*) INTO n
    FROM essentials.politician_images
   WHERE politician_id = '3c8d7283-2387-47ff-8a29-1ef7a1e2a554'::uuid;
  IF n <> 1 THEN
    RAISE EXCEPTION 'expected exactly 1 image for Cristina Todd, found %', n;
  END IF;
END $$;

COMMIT;
