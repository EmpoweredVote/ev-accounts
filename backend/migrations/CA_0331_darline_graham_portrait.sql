-- CA_0331 — Darline Graham (SC U.S. Senate, Class II; politician a82fec1e): official portrait.
--
-- CA_0325 seated her and CA_0327 put her on the 2026-11-03 ballot, both with no photo. Every other
-- senator carries the congressional portrait as `politician_photos/{id}/default.jpg` with
-- photo_origin_url pointing at the source (Tim Scott, Ashley Moody: unitedstates.github.io). That
-- set has no G000608 yet (404 on 2026-10-26), so the source here is the Biographical Directory:
--   https://bioguide.congress.gov/photo/G000608.jpg  (read 2026-10-26; 173x216 JPEG)
-- Its EXIF caption: "Senator Darline Graham, Official Portrait in Washington, DC on August 5, 2026.
-- (Official U.S. Senate photo by Rosa Pineda)". A work of the U.S. Government — public domain.
-- Uploaded unchanged to Storage `politician_photos/a82fec1e-3b94-4f7f-8931-fafb9787def3/default.jpg`;
-- the public URL was verified 200 image/jpeg (71,423 bytes) before this file was written.
--
-- Writes, only where empty (same guards as CA_0235):
--   * politician_images: one 'default' row carrying the rights note
--   * politicians.photo_custom_url (bucket) + photo_origin_url (bioguide)
-- The ballot card needs nothing more: electionService reads COALESCE(rc.photo_url, pi.url).
--
-- NOT CHANGED: bio_text — no senator carries one (matching that convention). Party (never stored).
-- No answers are deleted or rewritten by this migration, so no @context-decision declaration is required.
--
-- IDEMPOTENT. Dry run: body wrapped BEGIN; ... ROLLBACK; against prod, applied twice, rollback confirmed.
-- ROLLBACK (once applied): DELETE the politician_images row with this url; clear the two photo columns.

BEGIN;

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT p.id,
       'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/a82fec1e-3b94-4f7f-8931-fafb9787def3/default.jpg',
       'default',
       'Official U.S. Senate portrait (photo by Rosa Pineda, 2026-08-05), bioguide.congress.gov/photo/G000608.jpg — U.S. Government work, public domain (CA_0331)'
  FROM essentials.politicians p
 WHERE p.id = 'a82fec1e-3b94-4f7f-8931-fafb9787def3'
   AND p.photo_custom_url_manual_override IS NOT TRUE
   AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id);

UPDATE essentials.politicians p
   SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/a82fec1e-3b94-4f7f-8931-fafb9787def3/default.jpg',
       photo_origin_url = 'https://bioguide.congress.gov/photo/G000608.jpg'
 WHERE p.id = 'a82fec1e-3b94-4f7f-8931-fafb9787def3'
   AND p.photo_custom_url_manual_override IS NOT TRUE
   AND coalesce(p.photo_custom_url, '') = ''
   AND coalesce(p.photo_origin_url, '') = '';

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians p
                   JOIN essentials.politician_images pi ON pi.politician_id = p.id AND pi.url = p.photo_custom_url
                  WHERE p.id = 'a82fec1e-3b94-4f7f-8931-fafb9787def3'
                    AND p.photo_custom_url LIKE '%/politician_photos/a82fec1e-3b94-4f7f-8931-fafb9787def3/default.jpg'
                    AND p.photo_origin_url = 'https://bioguide.congress.gov/photo/G000608.jpg') THEN
    RAISE EXCEPTION 'POST: Darline Graham portrait not in place';
  END IF;
  IF (SELECT count(*) FROM essentials.politician_images WHERE politician_id = 'a82fec1e-3b94-4f7f-8931-fafb9787def3') <> 1 THEN
    RAISE EXCEPTION 'POST: expected exactly one politician_images row';
  END IF;
END $$;

COMMIT;
