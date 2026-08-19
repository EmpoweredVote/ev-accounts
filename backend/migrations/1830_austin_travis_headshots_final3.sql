-- 1830_austin_travis_headshots_final3.sql
--
-- Austin TX / Travis County wave 1 — the last 3 portraits. Completes the wave at 23 of 23 seats.
-- Follows 1829, which imported 20 and recorded these three as "no portrait found anywhere".
--
-- 🔴 THAT EARLIER FINDING WAS WRONG, AND TWO OF THE THREE WERE MY OWN METHOD'S FAULT.
--    A second sweep found all three. Recording the failure modes because both generalise:
--
--    * Sheriff Sally Hernandez — a 1000x1000 official uniform portrait was sitting on
--      traviscountytx.gov the whole time, at /topics/forensic-mental-health-planning/
--      sheriff-sally-hernandez. The first sweep probed a GUESSED path (/sheriff, which 404s) instead
--      of discovering links from pages that do resolve. A guessed URL that 404s is indistinguishable
--      from an absent portrait.
--    * County Treasurer Dolores Ortega Carter — her official portrait is at
--      /images/county_treasurer/ortega-carter.jpg, linked from /treasurer. Missed TWICE: once by
--      guessing /county-treasurer (404) rather than /treasurer, and once because the probe filtered
--      out anything under 200px and this file is 160x186. 🔴 A SIZE FLOOR IS INDISTINGUISHABLE FROM
--      AN EMPTY SITE. Measure and report, then filter at the decision — never at the fetch.
--    * Tax Assessor-Collector Celia Israel — this one really is absent from every county domain.
--      tax-office.traviscountytx.gov publishes no portrait of the officeholder.
--
-- LICENCE / SOURCE NOTES, one per row:
--   * Hernandez — Travis County official portrait, county government work, press use. 0.75x, clean.
--   * Israel — PUBLIC DOMAIN. LBJ Library photograph DIG13787-071 via Wikimedia Commons; a US
--     government work, the cleanest licence in this whole wave. 0.58x, clean. Two honest caveats
--     recorded in photo_license rather than hidden: it is an EVENT photograph from a library panel
--     rather than an official portrait, and it dates to c.2015-2016, so it predates her 2025 term as
--     Tax Assessor-Collector. A higher-resolution (1451x1927) CC BY-SA 4.0 rally photograph of her
--     was REJECTED: mouth open mid-speech, a microphone in frame, protest banners behind. Resolution
--     and licence were both better; it was not a headshot. Resolution does not outrank composition.
--   * Ortega Carter — Travis County official portrait, but 160x186, so 4.05x. This is the softest
--     image in the wave, past the 3.0x rows in 1829. Flagged REPLACE. Shipped on the standing call
--     that an upscale beats a blank spot; at this factor essentially all detail is interpolated.
--
-- photo_custom_url is set to the BUCKET url as well as photo_origin_url to the source page — the
-- read path is COALESCE(photo_custom_url, photo_origin_url, ''), so a source PAGE alone renders a
-- broken portrait. Same reasoning as 1822 and 1829.
--
-- Every bucket URL was HEAD-checked for a 200 and an image/* content-type before this was written.
--
-- Idempotent. Re-running changes nothing.

BEGIN;

CREATE TEMP TABLE _hs3 (
  pid         uuid PRIMARY KEY,
  full_name   text NOT NULL,
  bucket_url  text NOT NULL,
  source_page text NOT NULL,
  license     text NOT NULL
) ON COMMIT DROP;

INSERT INTO _hs3 (pid, full_name, bucket_url, source_page, license) VALUES
('587479e9-aa7d-4a51-b242-3050a09fcfc6', 'Sally Hernandez', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/587479e9-aa7d-4a51-b242-3050a09fcfc6-headshot.jpg', 'https://www.traviscountytx.gov/topics/forensic-mental-health-planning/sheriff-sally-hernandez', 'Travis County official portrait (traviscountytx.gov, county government work, press use)'),
('2b370605-6808-4678-9f9c-04b26884b93e', 'Celia Israel', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2b370605-6808-4678-9f9c-04b26884b93e-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Celia_Israel_(cropped).jpg', 'LBJ Library photograph DIG13787-071 via Wikimedia Commons — PUBLIC DOMAIN (US government work). Event photograph from a library panel, not an official portrait; c.2015-2016, so it predates her 2025 term as Tax Assessor-Collector.'),
('73d56a1a-3a10-4936-90c8-ef3d689c6462', 'Dolores Ortega Carter', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/73d56a1a-3a10-4936-90c8-ef3d689c6462-headshot.jpg', 'https://www.traviscountytx.gov/treasurer', 'Travis County official portrait (traviscountytx.gov, county government work, press use) — 160x186 source, upscaled x4.05, REPLACE');

-- Identity check before any write: these 3 pids must still be these 3 people.
DO $$
DECLARE bad text;
BEGIN
  SELECT string_agg(h.full_name || ' != ' || coalesce(p.full_name, '<missing>'), '; ') INTO bad
  FROM _hs3 h LEFT JOIN essentials.politicians p ON p.id = h.pid
  WHERE p.id IS NULL OR p.full_name <> h.full_name;
  IF bad IS NOT NULL THEN
    RAISE EXCEPTION 'politician_id/full_name mismatch, refusing to attach photos: %', bad;
  END IF;
END $$;

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT h.pid, h.bucket_url, 'default', h.license
FROM _hs3 h
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images pi
   WHERE pi.politician_id = h.pid AND pi.url = h.bucket_url
);

UPDATE essentials.politicians p
   SET photo_custom_url = h.bucket_url
  FROM _hs3 h
 WHERE p.id = h.pid AND coalesce(p.photo_custom_url, '') <> h.bucket_url;

UPDATE essentials.politicians p
   SET photo_origin_url = h.source_page
  FROM _hs3 h
 WHERE p.id = h.pid AND coalesce(p.photo_origin_url, '') <> h.source_page;

DO $$
DECLARE
  attached   int;
  soft_ct    int;
  pd_ct      int;
  seat_total int;
  seat_photo int;
BEGIN
  SELECT count(*) INTO attached
    FROM essentials.politician_images pi JOIN _hs3 h ON h.pid = pi.politician_id
   WHERE pi.url = h.bucket_url;
  IF attached <> 3 THEN
    RAISE EXCEPTION 'expected 3 new politician_images rows, found %', attached;
  END IF;

  SELECT count(*) INTO soft_ct
    FROM essentials.politician_images pi JOIN _hs3 h ON h.pid = pi.politician_id
   WHERE pi.url = h.bucket_url AND pi.photo_license LIKE '%REPLACE%';
  IF soft_ct <> 1 THEN
    RAISE EXCEPTION 'expected 1 REPLACE-flagged row here, found %', soft_ct;
  END IF;

  -- The public-domain provenance is the reason Israel's row is defensible at all; assert it
  -- survived rather than trusting that the string was written.
  SELECT count(*) INTO pd_ct
    FROM essentials.politician_images pi JOIN essentials.politicians p ON p.id = pi.politician_id
   WHERE p.full_name = 'Celia Israel' AND pi.photo_license LIKE '%PUBLIC DOMAIN%';
  IF pd_ct <> 1 THEN
    RAISE EXCEPTION 'Celia Israel row is missing its PUBLIC DOMAIN provenance (found %)', pd_ct;
  END IF;

  -- THE POINT OF THIS MIGRATION: all 23 Austin/Travis seats must now render a portrait.
  -- Uses the same predicate as photoCoverage.HAS_RENDERABLE_PHOTO_SQL — "a column is non-empty" is
  -- not the same as "a portrait can paint".
  SELECT count(*), count(*) FILTER (WHERE
           img.politician_id IS NOT NULL
        OR btrim(coalesce(p.photo_custom_url, '')) <> ''
        OR (btrim(coalesce(p.photo_origin_url, '')) <> '' AND p.photo_origin_url LIKE 'http%'))
    INTO seat_total, seat_photo
    FROM essentials.office_current_holder och
    JOIN essentials.offices o    ON o.id = och.office_id
    JOIN essentials.districts d  ON d.id = o.district_id
    JOIN essentials.politicians p ON p.id = och.politician_id
    LEFT JOIN essentials.politician_images img ON img.politician_id = p.id
   WHERE (d.geo_id = '4805000' AND d.district_type = 'LOCAL')
      OR (d.geo_id = '48453'   AND d.district_type = 'COUNTY');
  IF seat_total <> 23 THEN
    RAISE EXCEPTION 'expected 23 seated Austin/Travis seats, found %', seat_total;
  END IF;
  IF seat_photo <> 23 THEN
    RAISE EXCEPTION 'only % of 23 Austin/Travis seats render a portrait', seat_photo;
  END IF;

  RAISE NOTICE 'OK: final 3 attached. ALL 23 Austin/Travis seats now render a portrait (15 clean, 8 soft flagged REPLACE).';
END $$;

COMMIT;
