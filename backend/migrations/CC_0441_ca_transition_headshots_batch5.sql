-- CC_0441 — 5 California legislative headshots for 2026-11-03 winners. Batch 5, after CC_0440.
--
-- WHO. 12 of California's 2026 legislative winners have no photograph on any of the three
-- surfaces a photo can live on. 5 are imported here, ALL AT FULL SIZE WITH NO UPSCALING. The
-- other 7 stay open with a reason each, in data/transition-headshots-2026/NOTES.md.
--
-- 🔴🔴 FIVE FALSE LICENCE CLAIMS IN ONE COHORT OF TWELVE. Five of these people have a Wikipedia
-- lead image, and EVERY ONE is tagged "Public domain" on Wikimedia Commons with a CITY
-- GOVERNMENT named as the artist:
--   File:Andrae Gonzales-City Council (cropped).jpg   artist "City of Bakersfield"
--   File:Clarissa Cervantes-Square.jpg                artist "City of Riverside"
--   File:Scott Sakakihara, 2020s.jpg                  artist "Union City Council"
--   File:Dom Belza, 2021.jpg                          artist "Marysville City Council"
--   File:CityAttorneyMaraElliott.jpg                  artist "MEStaff", credit sandiego.gov
-- Only FEDERAL US government work is public domain under 17 USC §105. A city's work is NOT, so
-- all five tags are wrong. This is the same failure CC_0440 proved by byte-diff on a Wisconsin
-- portrait, here at scale. ▶ NOTHING in this file records a public-domain or Creative Commons
-- licence; every row is `unknown`, which is what the sources actually support.
-- 🟢 The credit lines were still worth reading: each named the official city page the photo came
-- from, and that is where these were re-sourced AT NATIVE SIZE (the Commons copies are mostly
-- far smaller — Elliott 250x278, Belza 156x207, Cervantes 190x190).
--
-- 🔴🔴 "CHRIS DUNCAN" ON WIKIPEDIA IS A BASEBALL PLAYER WHO DIED IN 2019, AND HE HAS A PHOTO.
-- Taking that lead image would have put a dead athlete on a California State Senate seat, which
-- is the Mark Harris / Ali Saleh failure exactly. He is NOT imported. Reading each article's
-- intro is what caught it; "Charles Hughes" is likewise a disambiguation page, not our winner.
--
-- 🔴 A DEPARTED OFFICIAL'S URL SERVES THEIR SUCCESSOR, CAUGHT LIVE. Mara Elliott left the San
-- Diego City Attorney's office in 2024. Commons credits her portrait to sandiego.gov/cityattorney
-- — and that page NO LONGER NAMES HER. Every official page used here was asserted to contain the
-- person's surname before anything was taken from it, and that assertion is the only reason this
-- did not become a wrong-person import.
--
-- 🔴 A RELATIVE SHARING A SURNAME IS THE WORST NAMESAKE CASE. Sabrina Cervantes sits in Senate
-- District 31. Our Assembly 58 winner is Clarissa Cervantes — HER SISTER. The surname sweep over
-- the sitting roster surfaced it; a full-name match never would have.
--
-- 🔴 UNION CITY SERVES PORTRAITS AS BARE NUMERIC IDS, AND THEY ARE ADJACENT.
-- documentId=10181 is MAYOR GARY SINGH, 10183 is Sakakihara, 10185 is Councilmember Jeff Wang.
-- An off-by-one ships the Mayor. Only the alt text ("Portrait of Councilmember Scott Sakakihara")
-- binds an id to a person, and the binding was confirmed by looking at the rendered card with his
-- name beside it. ⚠ A proximity match on surrounding text is NOT enough here: the container holds
-- the whole council list, so it marks the Mayor and Wang as matches too.
--
-- 🔴 BAKERSFIELD'S PORTRAIT URL IS A BARE UUID WITH alt="a file". That is the positional-filename
-- class with no name anywhere in it, so it was opened and looked at rather than trusted.
--
-- MEASURED BEFORE ANY OF THIS: 0 of the 12 currently sit in the legislature, verified against a
-- COMPLETE roster — 80 Assembly and 40 Senate, which are exactly the chamber sizes — with Rivas,
-- McGuire and Wiener as positive controls. ⚠ An earlier parse of the same pages returned "0 of
-- 12" with a FAILED control (Speaker Rivas missing); that was a broken regex, not a finding, and
-- the number only means something because the control now passes.
--
-- SOURCE AND LICENCE, read per site and never inferred from the host. EVERY ONE IS `unknown`.
-- bakersfieldcity.us publishes no photo policy on the page that carries the portrait;
-- unioncityca.gov refuses non-browser clients and publishes no grant on the rendered page;
-- votepaulaswift.com, ayannadavis.com and maraelliott.com carry only a "Paid for by ..."
-- campaign-finance disclaimer, which is required by law and grants nothing. SILENCE IS NOT A
-- GRANT. Same disposition as CC_0383, CC_0438, CC_0439 and CC_0440.
--
-- ONE SHIPS FLAGGED: Mara Elliott's is a CANDID, not a studio portrait — she is alone and
-- face-forward at a table. Her site carries nothing else of her alone; the alternative on it is a
-- group scene. Operator approved on the contact sheet, 2026-11-16.
--
-- ⚠ maraelliott.com REFUSES NODE ENTIRELY (TLS handshake), pages and files alike. Her portrait
-- was recovered by rendering the image at natural size in an oversized browser viewport and
-- screenshotting to disk: the trimmed capture is exactly 2000x1334, the file's own resolution,
-- so there is no resampling. It is a re-encode of the original pixels, not the original bytes,
-- and that is recorded here rather than glossed.
--
-- EVERY ROW WRITES BOTH SIDES. politicians.photo_custom_url is what the backend read paths
-- render; the politician_images row of type='default' is what the browse grid reads. Writing one
-- without the other renders on one surface and blanks on the other (CC_0195/CC_0196), and it is
-- how CC_0384 found Steve Hobbs showing a real portrait on the grid and the State Seal of
-- Washington everywhere else for three weeks.
--
-- NO ROW OVERWRITES ANYTHING. All 5 were measured faceless on all three surfaces before this
-- file was written, and all 5 storage objects were measured ABSENT before upload (positive
-- control: a known-good object answered 200 on the same sweep). All 5 were then verified
-- byte-identical against the PUBLIC CDN URL that goes into the database.
--
-- ROSTER (name, seat, native -> cropped -> shipped, source host):
--   Andrae Gonzales   Assembly 35   1500x1500 -> 1200x1500 -> 600x750 www.bakersfieldcity.us
--   Ayanna Davis      Assembly 65   6000x4000 -> 1920x2400 -> 600x750 ayannadavis.com
--   Paula Swift       Assembly 70   2048x2239 -> 1791x2239 -> 600x750 votepaulaswift.com
--   Scott Sakakihara  Senate 10     2043x2600 -> 2043x2554 -> 600x750 www.unioncityca.gov
--   Mara Elliott      Senate 40     2000x1334 -> 1067x1334 -> 600x750 maraelliott.com

BEGIN;

CREATE TEMP TABLE cc_0441_imported (politician_id uuid, name text, url text, origin text, photo_license text) ON COMMIT DROP;
INSERT INTO cc_0441_imported (politician_id, name, url, origin, photo_license) VALUES
  ('804ca377-f124-4ece-84ee-ca2616372216'::uuid, 'Andrae Gonzales',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/804ca377-f124-4ece-84ee-ca2616372216-headshot.jpg',
   'https://www.bakersfieldcity.us/484/Andrae-Gonzales', 'unknown'),
  ('22854534-cb46-4a66-9d62-3df99c7a4b43'::uuid, 'Ayanna Davis',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/22854534-cb46-4a66-9d62-3df99c7a4b43-headshot.jpg',
   'https://ayannadavis.com/', 'unknown'),
  ('16e44d2d-83b5-424d-bcbd-d1544899a33e'::uuid, 'Paula Swift',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/16e44d2d-83b5-424d-bcbd-d1544899a33e-headshot.jpg',
   'https://votepaulaswift.com/', 'unknown'),
  ('afb73624-a48b-4224-922a-1de864dfc653'::uuid, 'Scott Sakakihara',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/afb73624-a48b-4224-922a-1de864dfc653-headshot.jpg',
   'https://www.unioncityca.gov/202/Mayor-City-Council', 'unknown'),
  ('6cc169ff-f305-4742-9aa2-94ed7935de02'::uuid, 'Mara Elliott',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6cc169ff-f305-4742-9aa2-94ed7935de02-headshot.jpg',
   'https://maraelliott.com/', 'unknown');
-- The DELTA this file creates, captured in its OWN transaction. A total can be moved by
-- another session between the measurement and the write; a before/after pair inside one
-- transaction cannot be.
CREATE TEMP TABLE cc_0441_before ON COMMIT DROP AS
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
  FROM cc_0441_imported i
 WHERE p.id = i.politician_id
   AND p.photo_custom_url IS DISTINCT FROM i.url;

UPDATE essentials.politicians p
   SET photo_origin_url = i.origin
  FROM cc_0441_imported i
 WHERE p.id = i.politician_id
   AND p.photo_origin_url IS DISTINCT FROM i.origin;

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT i.politician_id, i.url, 'default', i.photo_license
  FROM cc_0441_imported i
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
  --    editing would otherwise make every "% of 5" gate below count against the wrong total.
  SELECT count(*) INTO imported_n FROM cc_0441_imported;
  IF imported_n <> 5 THEN
    RAISE EXCEPTION 'CC_0441: the import set holds % rows, not the 5 this file documents', imported_n;
  END IF;

  -- 1. every one of the 5 renders from the scalar the backend read paths use
  SELECT count(*) INTO missing_scalar
    FROM cc_0441_imported i JOIN essentials.politicians p ON p.id = i.politician_id
   WHERE btrim(coalesce(p.photo_custom_url, '')) = '';
  IF missing_scalar <> 0 THEN
    RAISE EXCEPTION 'CC_0441: % of 5 carry no photo_custom_url - they would render blank on address search', missing_scalar;
  END IF;

  -- 2. provenance is recorded. An `unknown` licence is only honest if the page it was read
  --    from is written down beside it.
  SELECT count(*) INTO missing_origin
    FROM cc_0441_imported i JOIN essentials.politicians p ON p.id = i.politician_id
   WHERE p.photo_origin_url IS DISTINCT FROM i.origin;
  IF missing_origin <> 0 THEN
    RAISE EXCEPTION 'CC_0441: % of 5 do not carry the source page in photo_origin_url', missing_origin;
  END IF;

  -- 3. EXACTLY ONE default row each. Two make the grid's find() pick an arbitrary one.
  SELECT count(*) INTO wrong_default FROM (
    SELECT i.politician_id FROM cc_0441_imported i
      LEFT JOIN essentials.politician_images pi
        ON pi.politician_id = i.politician_id AND pi.type = 'default'
     GROUP BY i.politician_id HAVING count(pi.*) <> 1) x;
  IF wrong_default <> 0 THEN
    RAISE EXCEPTION 'CC_0441: % of 5 do not have exactly one type=default image row', wrong_default;
  END IF;

  -- 4. THE TWO SIDES AGREE (CC_0195/CC_0196).
  SELECT count(*) INTO disagreeing
    FROM cc_0441_imported i
    JOIN essentials.politicians p ON p.id = i.politician_id
    JOIN essentials.politician_images pi
      ON pi.politician_id = i.politician_id AND pi.type = 'default'
   WHERE pi.url IS DISTINCT FROM p.photo_custom_url;
  IF disagreeing <> 0 THEN
    RAISE EXCEPTION 'CC_0441: % of 5 have a default image row that disagrees with photo_custom_url', disagreeing;
  END IF;

  -- 5. THE THIRD SURFACE. race_candidates.photo_url is swept by nothing and BEATS the fixed
  --    image on ballot pages, so a stale value there outranks everything written above.
  --    CC_0384 had to name it explicitly for exactly this reason.
  SELECT count(*) INTO third_surface
    FROM cc_0441_imported i
    JOIN essentials.race_candidates rc ON rc.politician_id = i.politician_id
   WHERE btrim(coalesce(rc.photo_url, '')) <> ''
     AND rc.photo_url IS DISTINCT FROM i.url;
  IF third_surface <> 0 THEN
    RAISE EXCEPTION 'CC_0441: % race_candidates rows carry a DIFFERENT photo_url and would outrank the import on ballot pages', third_surface;
  END IF;

  -- 6. THE DELTA. Exactly 5 legislative winners must leave the faceless set, measured inside
  --    this transaction against the snapshot taken before the writes.
  SELECT faceless INTO before_n FROM cc_0441_before;
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
  IF before_n - after_n <> 5 THEN
    RAISE EXCEPTION 'CC_0441: the faceless legislative count moved by % (% -> %), not the 5 this file imports', before_n - after_n, before_n, after_n;
  END IF;

  RAISE NOTICE 'CC_0441 ok: 5 headshots, scalar + origin set, exactly one default row each, both sides agree, third surface clear, faceless legislative winners % -> %', before_n, after_n;
END
$$;

COMMIT;
