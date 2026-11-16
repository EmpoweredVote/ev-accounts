-- CC_0440 — 5 Wisconsin legislative headshots for 2026-11-03 winners. Batch 4, after CC_0439.
--
-- WHO. 23 of Wisconsin's 2026 legislative winners have no photograph on any of the three
-- surfaces a photo can live on. These are the first 5 for whom a portrait could be found AND
-- the person in it could be established. The other 18 stay open, each with its reason recorded
-- in data/transition-headshots-2026/NOTES.md.
--
-- 🔴 WISCONSIN IS THE OPPOSITE OF WASHINGTON, AND THAT SHAPES EVERYTHING HERE. CC_0439 sourced
-- 20 people from ONE state publication. Wisconsin publishes NO state voters' pamphlet at all,
-- so there is no equivalent. Three things were measured before concluding that:
--   * The legislature's own roster DOES publish portraits — and every one of them is 150x200.
--     That is not a thumbnail hiding a larger file: the member detail pages carry the same
--     150x200 image and nothing else, and _large/@2x/static variants all 404. It is the
--     published size for all 132 members, so it cannot meet the 600x750 floor for ANYONE.
--   * 0 of the 23 currently sit. Verified against the chamber's own roster — 99 Assembly and
--     33 Senate parsed, which are exactly the chamber sizes — with Speaker Robin Vos as the
--     positive control and Melissa Agard (left for Dane County Executive) correctly absent.
--   * Only 3 of the 23 ever served, so even the past-session rosters reach almost none of them.
-- ▶ So each of these is an individual hunt on a campaign site, which is where the risk is.
--
-- 🔴🔴 A CAMPAIGN SITE CARRIES OTHER PEOPLE, AND THE BIGGEST PHOTO IS OFTEN NOT THE CANDIDATE.
-- On severson4senate.com the highest-scoring portrait by size and aspect ratio is A WOMAN, and
-- a second man appears against a US flag. "Take the best image on the candidate's own site"
-- would have shipped a stranger under his name, with every gate in this file still green.
-- ismaelluna.com carries three other people; krollforwi.com is mostly STOCK photography (a
-- stock doctor, stock hands holding a phone). Every pick here was looked at beside the others
-- on its own site before being chosen.
--
-- 🟢 HOW IDENTITY WAS ESTABLISHED, PER PERSON. The legislature's 150x200 portraits are too
-- small to publish but they are an AUTHORITATIVE picture of the right person, so for anyone who
-- served they are the identity reference:
--   Amy Binsfeld   CONFIRMED against her own official 2023 Assembly portrait (D27, R-Sheboygan).
--                  Sheboygan sits in Senate 9, which she just won.
--   Erik Severson  CONFIRMED against his own official 2013 Assembly portrait (D28, R-Star
--                  Prairie). Star Prairie is in St Croix County, inside Senate 25.
--   Ismael Luna    solo portrait; the same young man recurs elsewhere on his site. The three
--                  OTHER people on it each appear once, as supporters.
--   Amy Zimmerman  solo portrait; the same woman recurs, including in a group carrying AMY signs.
--   John Kroll     the only photograph of a person on a site otherwise built from stock imagery.
--
-- 🔴 A WIKIPEDIA ARTICLE EXISTING FOR A NAME IS NOT EVIDENCE ABOUT THAT PERSON. 17 of the 23
-- names resolved to an en.wikipedia article; reading each intro showed 2 were somebody else
-- entirely — "Ben Gruber" is a television producer, and "Bernie Newman" redirects to a
-- disambiguation page of Canadian politicians. The remaining 15 are genuinely these people and
-- were used only as LEADS to campaign sites, never as a source.
--
-- 🔴🔴 AND A COMMONS LICENCE CLAIM CAN BE FALSE IN A WAY THAT IS CHEAP TO PROVE. The only one
-- of the 23 with a Wikipedia lead image was Ellen Schutt: commons File:Ellen Schutt Official.jpg,
-- uploaded as "Own work" under CC BY-SA 4.0 by a username. It is BYTE-FOR-BYTE IDENTICAL to the
-- Wisconsin Legislature's official portrait of her (same sha256, 150x200, 41,489 bytes). The
-- uploader did not create that photograph and cannot license it. ▶ When a Commons file looks
-- like an official portrait, fetch the official one and diff the bytes. This repo already
-- carries 184 rows with an unverifiable CC BY-SA claim; this is how that happens, and it is why
-- NOTHING in this file records a Creative Commons licence.
--
-- SOURCE AND LICENCE, read per site and never inferred from the host. EVERY ONE IS `unknown`.
-- All five sites carry only a campaign-finance disclaimer ("Paid for by ..."), which is required
-- by law and is not a grant of anything; severson4senate.com and krollforwi.com additionally
-- assert "©". None publishes a press kit, a media page or any photo policy. SILENCE IS NOT A
-- GRANT, and only FEDERAL US government work is public domain under 17 USC §105. Same
-- disposition as CC_0383, CC_0438 and CC_0439.
--
-- ONE SHIPS UNDERSIZED, DELIBERATELY: John Kroll's source is 714x542, so a 4:5 window is
-- 434x543 and it is mirrored AT THAT SIZE, never upscaled. His site holds no larger file. A
-- soft small portrait is honest; an upscaled one invents detail. Operator approved on the
-- contact sheet, 2026-11-16.
--
-- EVERY ROW WRITES BOTH SIDES. politicians.photo_custom_url is what the backend read paths
-- render; the politician_images row of type='default' is what the browse grid reads. Writing
-- one without the other renders on one surface and blanks on the other (CC_0195/CC_0196), and
-- it is how CC_0384 found Steve Hobbs showing a real portrait on the grid and the State Seal of
-- Washington everywhere else for three weeks.
--
-- NO ROW OVERWRITES ANYTHING. All 5 were measured faceless on all three surfaces before this
-- file was written, and all 5 storage objects were measured ABSENT before upload (positive
-- control: a known-good object answered 200 on the same sweep). So there is no prior value for
-- this header to record. All 5 were then verified byte-identical against the PUBLIC CDN URL
-- that goes into the database — not against the upload call's own 200.
--
-- ROSTER (name, seat, native -> shipped, source host):
--   Amy Zimmerman   Assembly 13   2500x1407 -> 600x750  amyforwi.com
--   Ismael Luna     Assembly 8    960x1200 -> 600x750   ismaelluna.com
--   John Kroll      Assembly 85   714x542 -> 434x543    krollforwi.com
--   Erik Severson   Senate 25     1443x2048 -> 600x750  severson4senate.com
--   Amy Binsfeld    Senate 9      8256x5504 -> 600x750  binsfeldforwi.com

BEGIN;

CREATE TEMP TABLE cc_0440_imported (politician_id uuid, name text, url text, origin text, photo_license text) ON COMMIT DROP;
INSERT INTO cc_0440_imported (politician_id, name, url, origin, photo_license) VALUES
  ('7c8dea94-8ba3-4f11-b9cb-28ead6724977'::uuid, 'Amy Zimmerman',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7c8dea94-8ba3-4f11-b9cb-28ead6724977-headshot.jpg',
   'https://amyforwi.com/', 'unknown'),
  ('c20da1c7-53b8-41b8-8e18-293de23a7b4e'::uuid, 'Ismael Luna',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c20da1c7-53b8-41b8-8e18-293de23a7b4e-headshot.jpg',
   'https://ismaelluna.com/', 'unknown'),
  ('6796601f-fc5e-429b-af63-9ca320047270'::uuid, 'John Kroll',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6796601f-fc5e-429b-af63-9ca320047270-headshot.jpg',
   'https://krollforwi.com/', 'unknown'),
  ('a1f81b63-9c6f-4eb6-bcf7-e3e0d4bd91b5'::uuid, 'Erik Severson',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a1f81b63-9c6f-4eb6-bcf7-e3e0d4bd91b5-headshot.jpg',
   'https://severson4senate.com/', 'unknown'),
  ('918c8f91-bd25-448e-994d-cb783150b219'::uuid, 'Amy Binsfeld',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/918c8f91-bd25-448e-994d-cb783150b219-headshot.jpg',
   'https://binsfeldforwi.com/', 'unknown');
-- The DELTA this file creates, captured in its OWN transaction. A total can be moved by
-- another session between the measurement and the write; a before/after pair inside one
-- transaction cannot be.
CREATE TEMP TABLE cc_0440_before ON COMMIT DROP AS
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
  FROM cc_0440_imported i
 WHERE p.id = i.politician_id
   AND p.photo_custom_url IS DISTINCT FROM i.url;

UPDATE essentials.politicians p
   SET photo_origin_url = i.origin
  FROM cc_0440_imported i
 WHERE p.id = i.politician_id
   AND p.photo_origin_url IS DISTINCT FROM i.origin;

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT i.politician_id, i.url, 'default', i.photo_license
  FROM cc_0440_imported i
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
  SELECT count(*) INTO imported_n FROM cc_0440_imported;
  IF imported_n <> 5 THEN
    RAISE EXCEPTION 'CC_0440: the import set holds % rows, not the 5 this file documents', imported_n;
  END IF;

  -- 1. every one of the 5 renders from the scalar the backend read paths use
  SELECT count(*) INTO missing_scalar
    FROM cc_0440_imported i JOIN essentials.politicians p ON p.id = i.politician_id
   WHERE btrim(coalesce(p.photo_custom_url, '')) = '';
  IF missing_scalar <> 0 THEN
    RAISE EXCEPTION 'CC_0440: % of 5 carry no photo_custom_url - they would render blank on address search', missing_scalar;
  END IF;

  -- 2. provenance is recorded. An `unknown` licence is only honest if the page it was read
  --    from is written down beside it.
  SELECT count(*) INTO missing_origin
    FROM cc_0440_imported i JOIN essentials.politicians p ON p.id = i.politician_id
   WHERE p.photo_origin_url IS DISTINCT FROM i.origin;
  IF missing_origin <> 0 THEN
    RAISE EXCEPTION 'CC_0440: % of 5 do not carry the source page in photo_origin_url', missing_origin;
  END IF;

  -- 3. EXACTLY ONE default row each. Two make the grid's find() pick an arbitrary one.
  SELECT count(*) INTO wrong_default FROM (
    SELECT i.politician_id FROM cc_0440_imported i
      LEFT JOIN essentials.politician_images pi
        ON pi.politician_id = i.politician_id AND pi.type = 'default'
     GROUP BY i.politician_id HAVING count(pi.*) <> 1) x;
  IF wrong_default <> 0 THEN
    RAISE EXCEPTION 'CC_0440: % of 5 do not have exactly one type=default image row', wrong_default;
  END IF;

  -- 4. THE TWO SIDES AGREE (CC_0195/CC_0196).
  SELECT count(*) INTO disagreeing
    FROM cc_0440_imported i
    JOIN essentials.politicians p ON p.id = i.politician_id
    JOIN essentials.politician_images pi
      ON pi.politician_id = i.politician_id AND pi.type = 'default'
   WHERE pi.url IS DISTINCT FROM p.photo_custom_url;
  IF disagreeing <> 0 THEN
    RAISE EXCEPTION 'CC_0440: % of 5 have a default image row that disagrees with photo_custom_url', disagreeing;
  END IF;

  -- 5. THE THIRD SURFACE. race_candidates.photo_url is swept by nothing and BEATS the fixed
  --    image on ballot pages, so a stale value there outranks everything written above.
  --    CC_0384 had to name it explicitly for exactly this reason.
  SELECT count(*) INTO third_surface
    FROM cc_0440_imported i
    JOIN essentials.race_candidates rc ON rc.politician_id = i.politician_id
   WHERE btrim(coalesce(rc.photo_url, '')) <> ''
     AND rc.photo_url IS DISTINCT FROM i.url;
  IF third_surface <> 0 THEN
    RAISE EXCEPTION 'CC_0440: % race_candidates rows carry a DIFFERENT photo_url and would outrank the import on ballot pages', third_surface;
  END IF;

  -- 6. THE DELTA. Exactly 5 legislative winners must leave the faceless set, measured inside
  --    this transaction against the snapshot taken before the writes.
  SELECT faceless INTO before_n FROM cc_0440_before;
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
    RAISE EXCEPTION 'CC_0440: the faceless legislative count moved by % (% -> %), not the 5 this file imports', before_n - after_n, before_n, after_n;
  END IF;

  RAISE NOTICE 'CC_0440 ok: 5 headshots, scalar + origin set, exactly one default row each, both sides agree, third surface clear, faceless legislative winners % -> %', before_n, after_n;
END
$$;

COMMIT;
