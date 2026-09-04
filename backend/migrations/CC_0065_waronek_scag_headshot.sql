-- CC_0065_waronek_scag_headshot.sql
--
-- Mark A. Waronek (Lomita) — one headshot, from a source that is not his own city.
-- Apply AFTER CC_0064.
--
-- ── WHY THIS IS A SEPARATE MIGRATION ────────────────────────────────────────────────────
--
-- CC_0064 took every portrait Lomita and La Mirada publish themselves. It deliberately left
-- four Lomita members short: the city publishes them at 150x200, whose 4:5 crop stands
-- 184-188 px tall against a 220 px floor. That is a ceiling in the source, not a fetch
-- failure, and no browser fixes it.
--
-- A sweep of press and official channels for those four found exactly ONE better source, and
-- this migration is it. Segawa, Waite and Gazeley remain short:
--
--   * Ballotpedia holds no page for Segawa and a silhouette placeholder for Waite.
--   * Waite's USC Price faculty page 403s even to real Chrome, and would still have needed
--     an independent check that it is the same Barry Waite.
--   * SBCCOG publishes its board at 152x190 — below the same floor that stopped the city's
--     own files, so it is not an escape from the ceiling.
--   * SCAG carries a profile for Waronek alone; hon-barry-waite, hon-cindy-segawa and
--     hon-james-gazeley all 404.
--   * The city's newsletter PDFs stop at Spring 2022 and carry event photography, not
--     council portraits.
--
-- 🔴 DO NOT RE-RUN THIS SEARCH WITHOUT A NEW LEAD. It is written down so the next pass
--    spends its time somewhere else.
--
-- ── SOURCE AND IDENTITY ─────────────────────────────────────────────────────────────────
--
--   https://scag.ca.gov/profile/hon-mark-waronek
--   https://scag.ca.gov/sites/default/files/2024-08/markwaronek.jpg   (390x460)
--
-- SCAG is the Southern California Association of Governments, an official regional agency
-- Waronek sits on; the profile page names him "Hon. Mark Waronek" over "City of Lomita,
-- South Bay Cities Council of Governments", and the img alt is his name.
--
-- 🔴 AN ALT ALONE IS NOT IDENTITY — the LA audit found a Compton page whose alt named a
--    different person entirely. So this was bound twice: the SCAG portrait was placed beside
--    the portrait on Waronek's own card on lomitacity.com/city-council/ and face-matched.
--    Different sitting, different tie, same man, same city lapel pin. Two independent
--    sources, agreeing.
--
-- The crop keeps 368x460 and enlarges 1.63x to 600x750 — comfortably inside the gate, and a
-- real gain on the 147x184 crop the city file would have produced at 4.08x.
--
-- ROLLBACK: photo_custom_url -> 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/
--           public/politician_photos/9dd2a633-c532-4154-b2b0-9b725fcb292f/default.jpeg',
--           photo_origin_url -> NULL.

BEGIN;

UPDATE essentials.politicians
   SET photo_custom_url = 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/la_county/2026-audit-b/9dd2a633-c532-4154-b2b0-9b725fcb292f.jpg',
       photo_origin_url = 'https://scag.ca.gov/sites/default/files/2024-08/markwaronek.jpg'
 WHERE id = '9dd2a633-c532-4154-b2b0-9b725fcb292f'
   AND photo_custom_url_manual_override IS NOT TRUE;

DO $$
DECLARE
  v_url text;
  v_bad text;
BEGIN
  SELECT photo_custom_url INTO v_url
    FROM essentials.politicians
   WHERE id = '9dd2a633-c532-4154-b2b0-9b725fcb292f';
  IF v_url IS DISTINCT FROM 'https://kxsdzaojfaibhuzmclfq.supabase.co/storage/v1/object/public/politician_photos/la_county/2026-audit-b/9dd2a633-c532-4154-b2b0-9b725fcb292f.jpg' THEN
    RAISE EXCEPTION 'Waronek photo_custom_url is %, not the 2026-audit-b object', coalesce(v_url, 'NULL');
  END IF;

  -- Lomita's remaining shortfall is now exactly three people, all on their small city files
  -- plus Segawa, who has no photo at all. Named individually so that a silent change here —
  -- someone quietly shipping a 4x enlargement — fails instead of passing.
  SELECT string_agg(p.full_name, '; ' ORDER BY p.full_name)
    INTO v_bad
    FROM essentials.districts d
    JOIN essentials.offices o ON o.district_id = d.id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE d.geo_id = '0642468'
     AND (coalesce(p.photo_custom_url, '') = ''
          OR p.photo_custom_url LIKE '%/politician_photos/' || p.id::text || '/default.jpeg');
  IF v_bad IS DISTINCT FROM 'Barry Waite; Cindy Segawa; James Gazeley' THEN
    RAISE EXCEPTION 'expected Lomita''s remaining shortfall to be exactly Waite, Segawa and Gazeley; found: %',
                    coalesce(v_bad, '(none)');
  END IF;

  RAISE NOTICE 'Waronek repointed to the SCAG portrait (368x460 kept, 1.63x); Lomita still short on Waite, Segawa and Gazeley, all at the 150x200 source ceiling';
END $$;

COMMIT;
