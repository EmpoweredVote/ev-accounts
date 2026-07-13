-- =====================================================================================
-- Headshot fix: Jose Medina (Riverside County D1, politician ea521b54-...).
--
-- The Phase 201-03 headshot was sourced from the rivcodistrict1.org asset host as a
-- CIRCULAR-CUTOUT PNG; composited onto white it left the face floating small in the
-- 600x750 frame with wide white margins (the crop-into-circle was not applied). Re-sourced
-- from the public-domain 2025 Riverside County official portrait (Wikimedia Commons
-- File:Jose Medina, 2025.jpg), re-cropped head-and-shoulders to 600x750 (Storage overwrite),
-- and corrected the license from us_government_work to public_domain.
--
-- The image bytes live in Storage (politician_photos/ea521b54-...-headshot.jpg); this
-- migration keeps the DB-authoritative photo_license correct on any rebuild. AUDIT-ONLY /
-- unregistered. Idempotent.
-- =====================================================================================

BEGIN;

UPDATE essentials.politician_images
SET photo_license = 'public_domain'
WHERE politician_id = 'ea521b54-7b19-459a-9993-4ce70a84d592'
  AND type = 'default';

COMMIT;
