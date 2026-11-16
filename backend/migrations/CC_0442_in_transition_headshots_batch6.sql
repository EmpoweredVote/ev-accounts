-- CC_0442 — 2 Indiana legislative headshots for 2026-11-03 winners. Batch 6, after CC_0441.
--
-- WHO. 3 of Indiana's 2026 legislative winners have no photograph on any of the three surfaces
-- a photo can live on. 2 are imported here. The third, Kellie Streeter (House 45), is refused,
-- and the reason is in data/transition-headshots-2026/NOTES.md rather than left to be
-- rediscovered — because the reason is that BOTH of her available sources are fakes.
--
-- 🔴🔴 INDIANA HANDS OUT TWO DIFFERENT FAKE PORTRAITS, AND BOTH READ AS DATA.
--
-- 1. THE LEGISLATURE'S OWN PLACEHOLDER. For a member with no portrait on file, iga.in.gov
--    answers HTTP 200, Content-Type image/jpeg, with 403,152 bytes of the INDIANA STATEHOUSE
--    DOME ON MARBLE — a PNG served as .jpg. It decodes. It is 686x886, portrait-shaped. It
--    comes from the chamber's own domain. It is not a face, and nothing we run would ask:
--    check-headshot-faces.py is SCHEDULE-ONLY, and a seal, a map, a blank or a torso all pass
--    every other gate. Both Streeter and Kippenbrock are served it, BYTE-IDENTICAL.
--    ▶ Pinned by sha256 cc1c59ec61c5be8315015efdd69e6ce3430068f20b5fd579977ca25f9701dba5,
--      because fetching ONE legislator alone catches nothing — it was only visible because two
--      members returned the same bytes.
--    ⚠ Re-checked on 2026-11-16: unchanged. Kippenbrock's real portrait came from elsewhere.
--
-- 2. THE COUNTY'S STOCK PHOTOGRAPHY. Knox County, where Streeter is Commissioner for District 3
--    until 2026-12-31, illustrates its commissioners page with UNSPLASH STOCK IMAGES — and the
--    SAME FILE, annika-palmari-RIt88XBR3G0-unsplash.jpg, stands in for THREE DIFFERENT PEOPLE:
--    T.J. Brink, Tim Ellerman and Kellie Streeter. It is 640x896, portrait-shaped, and sits
--    directly beside her name in the same card. "The image next to the name" would have shipped
--    a stock model as a state representative.
--    ▶ Both fakes were caught the same way: BY COMPARING BYTES ACROSS PEOPLE. Neither is
--      detectable by inspecting a single record, and neither looks wrong on its own.
--
-- 🟢 THE COUNTY PAGE IS STILL WORTH READING — it confirms Streeter's office and district. A
-- source can be authoritative for one field and worthless for another.
--
-- WHERE THE TWO REAL PORTRAITS CAME FROM:
--   Amy Kippenbrock   the INDIANA HOUSE REPUBLICAN CAUCUS member list, as
--                     clientuploads/directory/members/Kippenbrock_Caucus_Photo.png — 500x500.
--                     🟢 The filename carries HER NAME, not a seat number or an opaque id.
--                     ⚠ She is Dubois County Circuit Court Clerk until 2026-12-31, but the
--                     county clerk page does NOT name her, so nothing was taken from it.
--   Jeff Ellington    the IGA official portrait bound to lpid legislator_jeff_ellington_1 —
--                     300x419, the file the chamber served for the 2017–2023 sessions. The
--                     2027 Senate file is a near-identical frame from the same sitting at
--                     279x419 and only 19KB against 83KB, so the larger, less compressed one
--                     was taken. Confirmed a real face and NOT the dome.
--
-- ⚠ THE CAUCUS LIST CARRIES KIPPENBROCK AND NOT STREETER. That matters: it makes Streeter's
-- absence a fact about her, not a broken read of the page.
--
-- 🔴 BOTH SHIP BELOW OUR 600x750 FLOOR, AT NATIVE SIZE, NEVER UPSCALED:
--   Jeff Ellington   300x419 native -> ships 300x375
--   Amy Kippenbrock  500x500 native -> ships 400x500
-- A soft small portrait is honest; an upscaled one invents detail. Operator approved both on
-- the contact sheet, 2026-11-16.
-- ▶ THIS IS NOW THE PATTERN IN FOUR STATES, and it is worth stating plainly: Washington
--   150x200, Wisconsin 150x200, California Assembly 500x500, Indiana 300x419. A LEGISLATURE'S
--   OWN ROSTER PHOTO IS AN EXCELLENT IDENTITY REFERENCE AND A POOR SOURCE. Do not plan a wave
--   around "they will publish portraits when sworn in" without measuring that chamber first.
--
-- SOURCE AND LICENCE, read per site and never inferred from the host. BOTH ARE `unknown`.
-- iga.in.gov publishes NO licence language at all — silence, and Indiana is a STATE, so its work
-- is not public domain (only FEDERAL work is, under 17 USC §105). indianahouserepublicans.com
-- asserts "© Copyright Indiana House Republicans. All Rights Reserved." and grants nothing.
-- SILENCE IS NOT A GRANT, and neither is a blanket copyright notice. Same disposition as
-- CC_0383, CC_0438, CC_0439, CC_0440 and CC_0441.
--
-- EVERY ROW WRITES BOTH SIDES. politicians.photo_custom_url is what the backend read paths
-- render; the politician_images row of type='default' is what the browse grid reads. Writing one
-- without the other renders on one surface and blanks on the other (CC_0195/CC_0196), and it is
-- how CC_0384 found Steve Hobbs showing a real portrait on the grid and the State Seal of
-- Washington everywhere else for three weeks.
--
-- NO ROW OVERWRITES ANYTHING. Both were measured faceless on all three surfaces before this file
-- was written, and both storage objects were measured ABSENT before upload (positive control: a
-- known-good object answered 200 on the same sweep). Both were then verified byte-identical
-- against the PUBLIC CDN URL that goes into the database, and asserted NOT to be the dome.
--
-- ROSTER (name, seat, native -> shipped, source host):
--   Jeff Ellington    Indiana Senate 39   300x419 -> 300x375   iga.in.gov
--   Amy Kippenbrock   Indiana House 63    500x500 -> 400x500   www.indianahouserepublicans.com


BEGIN;

CREATE TEMP TABLE cc_0442_imported (politician_id uuid, name text, url text, origin text, photo_license text) ON COMMIT DROP;
INSERT INTO cc_0442_imported (politician_id, name, url, origin, photo_license) VALUES
  ('6a7a36f8-2fa5-4e1b-bdc6-6df3b63a4ac4'::uuid, 'Jeffrey Ellington',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6a7a36f8-2fa5-4e1b-bdc6-6df3b63a4ac4-headshot.jpg',
   'https://iga.in.gov/legislative/2027/legislators/legislator_jeff_ellington_1', 'unknown'),
  ('d098cb69-71ae-4710-872d-8d43e3f55158'::uuid, 'Amy Kippenbrock',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d098cb69-71ae-4710-872d-8d43e3f55158-headshot.jpg',
   'https://www.indianahouserepublicans.com/members', 'unknown');
-- The DELTA this file creates, captured in its OWN transaction. A total can be moved by
-- another session between the measurement and the write; a before/after pair inside one
-- transaction cannot be.
CREATE TEMP TABLE cc_0442_before ON COMMIT DROP AS
SELECT count(DISTINCT rc.politician_id) AS faceless
  FROM essentials.race_candidates rc
  JOIN essentials.races r ON r.id = rc.race_id
  JOIN essentials.elections e ON e.id = r.election_id
  JOIN essentials.offices o ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.politicians p ON p.id = rc.politician_id
 WHERE e.election_date = DATE '2026-11-03' AND rc.result = 'won'
   AND d.district_type IN ('STATE_LOWER','STATE_UPPER','NATIONAL_LOWER','NATIONAL_UPPER')
   AND btrim(coalesce(p.photo_custom_url, '')) = ''
   AND btrim(coalesce(rc.photo_url, '')) = ''
   AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi
                    WHERE pi.politician_id = p.id AND pi.type = 'default');

-- Guarded, so a re-run is a no-op and the post-verify proves the END STATE, not row counts.
UPDATE essentials.politicians p
   SET photo_custom_url = i.url
  FROM cc_0442_imported i
 WHERE p.id = i.politician_id
   AND p.photo_custom_url IS DISTINCT FROM i.url;

UPDATE essentials.politicians p
   SET photo_origin_url = i.origin
  FROM cc_0442_imported i
 WHERE p.id = i.politician_id
   AND p.photo_origin_url IS DISTINCT FROM i.origin;

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT i.politician_id, i.url, 'default', i.photo_license
  FROM cc_0442_imported i
 WHERE NOT EXISTS (SELECT 1 FROM essentials.politician_images pi
                    WHERE pi.politician_id = i.politician_id AND pi.type = 'default');

DO $$
DECLARE
  imported_n     int;
  missing_scalar int;
  missing_origin int;
  wrong_default  int;
  disagreeing    int;
  third_surface  int;
  before_n       int;
  after_n        int;
BEGIN
  -- 0. the import set is the size this file claims. A VALUES list that lost a row during
  --    editing would otherwise make every "% of 2" gate below count against the wrong total.
  SELECT count(*) INTO imported_n FROM cc_0442_imported;
  IF imported_n <> 2 THEN
    RAISE EXCEPTION 'CC_0442: the import set holds % rows, not the 2 this file documents', imported_n;
  END IF;

  -- 1. every one of the 2 renders from the scalar the backend read paths use
  SELECT count(*) INTO missing_scalar
    FROM cc_0442_imported i JOIN essentials.politicians p ON p.id = i.politician_id
   WHERE btrim(coalesce(p.photo_custom_url, '')) = '';
  IF missing_scalar <> 0 THEN
    RAISE EXCEPTION 'CC_0442: % of 2 carry no photo_custom_url - they would render blank on address search', missing_scalar;
  END IF;

  -- 2. provenance is recorded. An `unknown` licence is only honest if the page it was read
  --    from is written down beside it.
  SELECT count(*) INTO missing_origin
    FROM cc_0442_imported i JOIN essentials.politicians p ON p.id = i.politician_id
   WHERE p.photo_origin_url IS DISTINCT FROM i.origin;
  IF missing_origin <> 0 THEN
    RAISE EXCEPTION 'CC_0442: % of 2 do not carry the source page in photo_origin_url', missing_origin;
  END IF;

  -- 3. EXACTLY ONE default row each. Two make the grid's find() pick an arbitrary one.
  SELECT count(*) INTO wrong_default FROM (
    SELECT i.politician_id FROM cc_0442_imported i
      LEFT JOIN essentials.politician_images pi
        ON pi.politician_id = i.politician_id AND pi.type = 'default'
     GROUP BY i.politician_id HAVING count(pi.*) <> 1) x;
  IF wrong_default <> 0 THEN
    RAISE EXCEPTION 'CC_0442: % of 2 do not have exactly one type=default image row', wrong_default;
  END IF;

  -- 4. THE TWO SIDES AGREE (CC_0195/CC_0196).
  SELECT count(*) INTO disagreeing
    FROM cc_0442_imported i
    JOIN essentials.politicians p ON p.id = i.politician_id
    JOIN essentials.politician_images pi
      ON pi.politician_id = i.politician_id AND pi.type = 'default'
   WHERE pi.url IS DISTINCT FROM p.photo_custom_url;
  IF disagreeing <> 0 THEN
    RAISE EXCEPTION 'CC_0442: % of 2 have a default image row that disagrees with photo_custom_url', disagreeing;
  END IF;

  -- 5. THE THIRD SURFACE. race_candidates.photo_url is swept by nothing and BEATS the fixed
  --    image on ballot pages, so a stale value there outranks everything written above.
  --    CC_0384 had to name it explicitly for exactly this reason.
  SELECT count(*) INTO third_surface
    FROM cc_0442_imported i
    JOIN essentials.race_candidates rc ON rc.politician_id = i.politician_id
   WHERE btrim(coalesce(rc.photo_url, '')) <> ''
     AND rc.photo_url IS DISTINCT FROM i.url;
  IF third_surface <> 0 THEN
    RAISE EXCEPTION 'CC_0442: % race_candidates rows carry a DIFFERENT photo_url and would outrank the import on ballot pages', third_surface;
  END IF;

  -- 6. THE DELTA. Exactly 2 legislative winners must leave the faceless set, measured inside
  --    this transaction against the snapshot taken before the writes.
  SELECT faceless INTO before_n FROM cc_0442_before;
  SELECT count(DISTINCT rc.politician_id) INTO after_n
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.politicians p ON p.id = rc.politician_id
   WHERE e.election_date = DATE '2026-11-03' AND rc.result = 'won'
     AND d.district_type IN ('STATE_LOWER','STATE_UPPER','NATIONAL_LOWER','NATIONAL_UPPER')
     AND btrim(coalesce(p.photo_custom_url, '')) = ''
     AND btrim(coalesce(rc.photo_url, '')) = ''
     AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi
                      WHERE pi.politician_id = p.id AND pi.type = 'default');
  IF before_n - after_n <> 2 THEN
    RAISE EXCEPTION 'CC_0442: the faceless legislative count moved by % (% -> %), not the 2 this file imports', before_n - after_n, before_n, after_n;
  END IF;

  RAISE NOTICE 'CC_0442 ok: 2 headshots, scalar + origin set, exactly one default row each, both sides agree, third surface clear, faceless legislative winners % -> %', before_n, after_n;
END
$$;

COMMIT;
