-- 1477: Bend / Deschutes headshot wave 2 — 6 of the 13 outstanding pins
--
-- The Bend deep seed (migrations 1414/1415) imported 25 of 38 headshots and left 13 pinned with a
-- documented burned-search trail. This clears 6: one sitting official and five 2026 candidates.
-- All six are 600x750 JPEG q90, mirrored into politician_photos as <politician_id>-headshot.jpg,
-- licensed press_use on the 2026-07-08 policy basis (campaign sites + official rosters, good
-- faith, takedown on request, correct-person guard applied).
--
-- WHAT UNBLOCKED THEM — the previous sweep recorded these sites as dead ends because their
-- og:image was a placeholder, logo or theme asset. That was a rendering artefact, not the truth:
--   1. Scrolling the page forces lazy-loaded <img> elements to resolve; a bare fetch sees none.
--   2. Every platform then hands over the FULL-RESOLUTION original once its render directive is
--      stripped from the URL:
--        Wix           static.wixstatic.com/media/<id>~mv2.<ext>/v1/fill|crop/...  -> cut at /v1/
--        GoDaddy       img1.wsimg.com/isteam/ip/<id>/<file>/:/rs=...               -> cut at /:/
--        Squarespace   images.squarespace-cdn.com/.../<file>?format=750w           -> ?format=2500w
--        Next.js       /_next/image?url=%2Fimages%2F...&w=640                      -> fetch /images/... raw
--      Connally's "blank Wix placeholder" is a 512x512 studio headshot; Reinholtz's optimiser
--      rendition was 464px against an 1350x1800 asset; Summers' is 2705x3500.
--
-- CORRECT-PERSON GUARD, two live catches:
--   * bobbiforbend.com's other portrait is a separate file named Ariel.webp — an ENDORSER
--     (Ariel Mendez), not the candidate. The earlier trail flagged the same trap with a different
--     endorser, so the site has had at least two.
--   * macforsheriff.com has been REPURPOSED and now serves "Wyatt McIntyre for Sebastian County
--     Sheriff" (Arkansas). McLaughlin is not imported here; anyone trusting the old note that its
--     og:image was merely "a theme asset" would have imported a photo of the wrong person.
--
-- PHOTO PRECEDENCE — this migration deliberately does NOT repeat the 1472/1474 bug that
-- migration 1475 Part B had to repair. The /find-headshots convention sets photo_origin_url to the
-- SOURCE PAGE, but the read path is
--     backend: COALESCE(p.photo_custom_url, p.photo_origin_url, '')
--     ev-ui:   photo_origin_url || images[0].url
-- so an HTML page URL WINS over the mirrored image and the portrait renders broken. Both columns
-- are therefore set: photo_origin_url keeps its provenance meaning, photo_custom_url carries the
-- bucket URL so the COALESCE resolves to a real image. Respects the
-- photo_custom_url_manual_override flag from migration 192 (D-08).
--
-- STILL PINNED (7) — reasons and unlocks in
-- .planning/todos/2026-07-24-bend-or-postfiling-recheck.md section 3. Two are sitting officials
-- (Kuhn, Tintle), which is the more awkward gap; the November county voters' pamphlet is the
-- realistic unlock for four of them.
--
-- Idempotent: the insert is NOT EXISTS-guarded and both updates guard on current state.

BEGIN;

-- ── Part A: headshot rows ──
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT v.pid::uuid,
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/'
         || v.pid || '-headshot.jpg',
       'default',
       'press_use'
FROM (VALUES
  -- politician_id                          person              source page
  ('f4cf3fb7-879e-482d-b1fc-be8fbd4d7e28'), -- Ty Rupert        oregonsheriffs.org
  ('1fc9d1aa-ec7c-41a6-a205-3693c6656fab'), -- Lauren Connally  connally4deschutes.com
  ('6f66ac9f-bb58-48e5-b2a0-e94b62349d44'), -- Amy Sabbadini    vote4sabbadini.com
  ('3168649a-56ce-4d5b-afe9-e2cf1b14997a'), -- Bobbi Cummiskey  bobbiforbend.com
  ('f9416fcf-cb43-42fc-909d-fdfa744cf6a2'), -- Elana Reinholtz  elanaforbend.com
  ('408ba201-7ac6-4c7d-9612-5952d7bfb3ca')  -- Michael Summers  electsummers.com
) AS v(pid)
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images pi
   WHERE pi.politician_id = v.pid::uuid AND pi.type = 'default'
);

-- ── Part B: provenance page ──
UPDATE essentials.politicians p
   SET photo_origin_url = v.src
  FROM (VALUES
  ('f4cf3fb7-879e-482d-b1fc-be8fbd4d7e28', 'https://oregonsheriffs.org/sheriff/deschutes/'),
  ('1fc9d1aa-ec7c-41a6-a205-3693c6656fab', 'https://www.connally4deschutes.com/'),
  ('6f66ac9f-bb58-48e5-b2a0-e94b62349d44', 'https://www.vote4sabbadini.com/'),
  ('3168649a-56ce-4d5b-afe9-e2cf1b14997a', 'https://bobbiforbend.com/'),
  ('f9416fcf-cb43-42fc-909d-fdfa744cf6a2', 'https://www.elanaforbend.com/'),
  ('408ba201-7ac6-4c7d-9612-5952d7bfb3ca', 'https://www.electsummers.com/meet-michael')
) AS v(pid, src)
 WHERE p.id = v.pid::uuid
   AND p.photo_origin_url IS DISTINCT FROM v.src;

-- ── Part C: make the read path resolve a real image (see header) ──
UPDATE essentials.politicians p
   SET photo_custom_url = pi.url
  FROM essentials.politician_images pi
 WHERE pi.politician_id = p.id
   AND pi.type = 'default'
   AND p.photo_custom_url IS NULL
   AND coalesce(p.photo_custom_url_manual_override, false) = false
   AND p.id IN (
     'f4cf3fb7-879e-482d-b1fc-be8fbd4d7e28'::uuid,
     '1fc9d1aa-ec7c-41a6-a205-3693c6656fab'::uuid,
     '6f66ac9f-bb58-48e5-b2a0-e94b62349d44'::uuid,
     '3168649a-56ce-4d5b-afe9-e2cf1b14997a'::uuid,
     'f9416fcf-cb43-42fc-909d-fdfa744cf6a2'::uuid,
     '408ba201-7ac6-4c7d-9612-5952d7bfb3ca'::uuid
   );

-- ── Gate ──
DO $$
DECLARE
  v_ids uuid[] := ARRAY[
    'f4cf3fb7-879e-482d-b1fc-be8fbd4d7e28','1fc9d1aa-ec7c-41a6-a205-3693c6656fab',
    '6f66ac9f-bb58-48e5-b2a0-e94b62349d44','3168649a-56ce-4d5b-afe9-e2cf1b14997a',
    'f9416fcf-cb43-42fc-909d-fdfa744cf6a2','408ba201-7ac6-4c7d-9612-5952d7bfb3ca']::uuid[];
  v_imgs int; v_dupes int; v_broken int; v_unlicensed int;
BEGIN
  SELECT count(*) INTO v_imgs
    FROM essentials.politician_images
   WHERE politician_id = ANY(v_ids) AND type = 'default';
  IF v_imgs <> 6 THEN
    RAISE EXCEPTION '1477 gate: expected 6 default headshot rows, found %', v_imgs;
  END IF;

  -- no person may end up with two default headshots (the dual-PID hazard from mig 1415)
  SELECT count(*) INTO v_dupes FROM (
    SELECT politician_id FROM essentials.politician_images
     WHERE politician_id = ANY(v_ids) AND type = 'default'
     GROUP BY politician_id HAVING count(*) > 1) x;
  IF v_dupes <> 0 THEN
    RAISE EXCEPTION '1477 gate: % of these politicians have duplicate default headshots', v_dupes;
  END IF;

  -- the 1472/1474 failure mode: an HTML page winning the COALESCE over the bucket image
  SELECT count(*) INTO v_broken
    FROM essentials.politicians
   WHERE id = ANY(v_ids)
     AND coalesce(photo_custom_url, photo_origin_url, '') NOT LIKE '%storage.supabase.co%';
  IF v_broken <> 0 THEN
    RAISE EXCEPTION '1477 gate: % row(s) resolve to a page URL, not an image (the 1475 Part B bug)', v_broken;
  END IF;

  SELECT count(*) INTO v_unlicensed
    FROM essentials.politician_images
   WHERE politician_id = ANY(v_ids) AND type = 'default'
     AND coalesce(photo_license, '') = '';
  IF v_unlicensed <> 0 THEN
    RAISE EXCEPTION '1477 gate: % headshot(s) have no photo_license', v_unlicensed;
  END IF;

  RAISE NOTICE '1477 PASSED: 6 headshots imported, licensed, and resolving to bucket images.';
END $$;

COMMIT;
