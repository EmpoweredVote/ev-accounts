-- 1761_wa_statewide_execs_headshots.sql
-- Headshots for the four statewide executives seeded in migration 1760.
-- Brings Washington to 176 of 176 officials with a portrait.
--
-- Every image is the official agency portrait from the officeholder's own
-- department page — the same page already recorded on politicians.photo_origin_url
-- by 1760, so origin and image agree. All four are .gov works: photo_license
-- 'press_use'.
--
--   Pat McCarthy      sao.wa.gov          683x1024  -> downscaled
--   Patty Kuderer     insurance.wa.gov   3240x3240  -> downscaled
--   Chris Reykdal     ospi.k12.wa.us      400x350   -> upscaled 2.1x  (soft)
--   Dave Upthegrove   dnr.wa.gov          312x312   -> upscaled 2.4x  (soft)
--
-- EVERY IMAGE WAS RENDERED AND LOOKED AT before upload, not just checked for
-- dimensions — see [[feedback_headshot_no_graphics]], where a STATE SEAL once
-- shipped as a politician's face. Two things that only looking would catch:
--
--   1. Upthegrove's DNR file is named "em_cpl_block_312x312.png" and its alt text
--      is a bare "Commissioner Upthegrove". The filename reads exactly like a
--      generic CMS badge or block graphic. It is in fact a real studio portrait.
--   2. It is also an RGBA PNG with a transparent surround. A naive
--      .convert('RGB') turned the alpha into BLACK WEDGES in the corners of the
--      finished crop. Composited onto white before cropping instead.
--
-- The four sha256 digests are mutually distinct, so no single file was
-- accidentally attached to more than one person.
--
-- TWO ARE SOFT AND THAT WAS THE DELIBERATE CHOICE, operator-approved 2026-08-15:
--   Reykdal — the only sharp alternative (Wikimedia, 1716x1965) is a mid-speech
--     shot with a microphone in frame. Resolution is not framing.
--   Upthegrove — the sharp alternative (Wikimedia, 900x1200) is a genuine studio
--     portrait but was taken around 2015, during his King County Council service;
--     his hair is dark in it and grey now. A current likeness beat a sharp one.
--   Precedent: the 9 Seattle councilmembers are 300x300 sources upscaled to
--   600x750 for the same reason. Both are recorded in .planning/WA-GAPS.md so the
--   softness is not mistaken for an unnoticed defect.
--
-- Crops were produced by backend/scripts/headshot-smartcrop.py — crop THEN
-- resize, subject-aware rather than centred, 600x750 JPEG q90.
--
-- Storage: politician_photos bucket, {politician_id}-headshot.jpg (uploaded
-- 2026-08-15, all four HTTP 200). No versioned filename is needed here — these
-- are first imports, so there is no cached predecessor to bust.
--
-- Idempotency: politician_images has no unique index on politician_id, so the
-- insert uses NOT EXISTS. Re-running is a no-op.

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT p.id,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/'
         || p.id || '-headshot.jpg',
       'default',
       'press_use'
FROM essentials.politicians p
WHERE p.external_id IN (-5300006, -5300007, -5300008, -5300009)
  AND NOT EXISTS (
    SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id
  );
