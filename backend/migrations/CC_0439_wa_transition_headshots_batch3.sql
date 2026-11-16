-- CC_0439 — 22 Washington legislative headshots for 2026-11-03 winners. Batch 3, after CC_0438.
--
-- WHO. All 23 of Washington's 2026 legislative winners had no photograph in any of the three
-- places one can live. 22 are imported here. The 23rd, Randi L. Knott (LD 18 Pos 1), is NOT,
-- and the reason is recorded in data/transition-headshots-2026/NOTES.md rather than left to be
-- rediscovered.
--
-- THE SOURCE, AND WHY IT IS ONE SOURCE RATHER THAN 23 HUNTS. leg.wa.gov publishes only SITTING
-- members, and a sweep of its own roster service confirmed that ZERO of these 23 sit today
-- (positive control: Speaker Laurie Jinkins, named from outside that roster, was found; 158
-- members parsed). The district finder returns the OUTGOING member. What does carry them is the
-- Secretary of State's online Voters' Guide, which gives 20 of the 23 a photograph together
-- with the district and position each one ran for.
--
-- 🔴 e=898 IS THE PRIMARY AND e=899 IS THE GENERAL. Sourcing from the primary would have mixed
-- in candidates who lost in August. The election id is not labelled in the URL; config.ashx
-- returns a byte-identical 33,339-byte response for EVERY election id, so it discriminates
-- nothing. voterguide.ashx carries the election's real name and is what settled it.
--
-- 🔴🔴 THE RACE PAGE RENDERS EVERY CANDIDATE, LOSER FIRST. Chelsea Dimas is the SECOND photo on
-- her page; the first is Gloria Mendoza, the incumbent she beat. A positional read of "the
-- candidate photo" ships the defeated opponent under the winner's name, with every gate green.
-- Each photo here was bound to its own BallotName inside the page, never to an index, and the
-- extraction ran a paired control: Mendoza's photo was fetched deliberately and asserted never
-- to reappear under any winner. All 22 images are byte-distinct from each other and from it.
--
-- 🟢 THE GUIDE IS ALSO THE NAMESAKE CHECK, which is why it outranks a campaign site. Each race
-- carries a Jurisdiction ("Legislative District 14") and a position, published by the body that
-- ran the election. All 20 matched our district and position EXACTLY, 20 for 20, no mismatches.
-- That is the check CLAUDE.md asks for — against the body's own roster, not a name search —
-- and it is what a full-name match alone cannot give (this repo shipped Mark Harris as NC-8).
--
-- WHY LD 18 AND LD 49 ARE NOT IN THAT GUIDE. Both are absent from it entirely — checked across
-- every county code, in BOTH the primary and the general. They are not missing candidates; the
-- districts are missing. Clark County carries those two districts in its OWN local voters'
-- pamphlet instead, which its General 2026 PDF confirms by naming Knott/McClintock (18-1),
-- Letinich/Ley (18-2) and Harless/Mittelman (49-1) under "State Legislative Offices". So the
-- three people in those districts were sourced elsewhere, and the county pamphlet supplied the
-- district binding for all three.
--
-- FOUR ROWS DO NOT COME FROM THE GUIDE:
--   Kim D. Harless   City of Vancouver official council portrait (Council Seat 1), 1280x1280.
--                    LD 49 is absent from the state guide; she sits on that council today.
--   Diana H. Perez   City of Vancouver official council portrait (Council Seat 3), 1280x1280.
--                    SUPERSEDES her 563x677 pamphlet photo, which needed a 1.11x upscale.
--   Danica Noble     electdanica.com, 9504x6336 IN COLOUR. Her pamphlet photo measured chroma
--                    EXACTLY 0 — greyscale — which this repo rejects.
--   Deken Letinich   electdeken.com media gallery, 2500x1667, cropped RIGHT-FLUSH. He sits
--                    right of centre, so the default centre crop cuts him in half.
--
-- 🔴 A BARE CDN URL IS NOT THE ORIGINAL, THREE TIMES OVER IN THIS BATCH. cityofvancouver.us
-- serves its portraits at -1024x1024 and holds 1280x1280 at the un-suffixed name (56% more
-- pixels). Squarespace serves ?format=500w over a 2500px original. Wix hides the resize in the
-- PATH (/v1/fill/w_341,h_286,...) over a 4854x3238 original. Every one was re-fetched at native.
--
-- TWO ARE UNDERSIZED, DELIBERATELY IMPORTED, AND SAID SO OUT LOUD:
--   Joshua Thompson  152x183 native, ships 146x183
--   Alan Nolan       293x350 native, ships 280x350
-- Neither has a campaign site; the small file is what they themselves submitted to the state.
-- They are mirrored AT NATIVE SIZE and never upscaled — a soft small portrait is honest, an
-- upscaled one invents detail. Operator approved both on the contact sheet, 2026-11-16.
--
-- SOURCE AND LICENCE, read per site and never inferred from the host. EVERY ONE IS `unknown`,
-- and that is a finding rather than an omission. voter.votewa.gov carries "© Copyright 2023"
-- and publishes no grant, and its photographs are CANDIDATE-SUBMITTED, so they are not the
-- State's to license in the first place. cityofvancouver.us, electdanica.com and electdeken.com
-- publish no photo policy on the pages that carry these portraits. Only FEDERAL US government
-- work is public domain under 17 USC §105 — a state or city portrait is not — and SILENCE IS
-- NOT A GRANT. `unknown` is findable by the query that looks for missing provenance; a guessed
-- `press_use` is not. Same disposition as CC_0383 and CC_0438.
--
-- EVERY ROW WRITES BOTH SIDES. politicians.photo_custom_url is what the backend read paths
-- render; the politician_images row of type='default' is what the browse grid reads. Writing
-- one without the other renders on one surface and blanks on the other (CC_0195/CC_0196), and
-- it is how CC_0384 found Steve Hobbs showing a real portrait on the grid and the State Seal of
-- Washington everywhere else for three weeks.
--
-- NO ROW OVERWRITES ANYTHING. All 22 were measured faceless on all three surfaces before this
-- file was written, and all 22 storage objects were measured ABSENT before upload (positive
-- control: a known-good object answered 200 on the same sweep). So there is no prior value for
-- the header to record. All 22 were then verified byte-identical against the PUBLIC CDN URL
-- that goes into the database — not against the upload call's own 200.
--
-- ROSTER (name, seat, native -> shipped, source host):
--   Luc Jasmin III             LD  3 Pos 2  867x1040 -> 600x750   voter.votewa.gov
--   Hillary Q. Pham            LD  4 Pos 1  1715x2059 -> 600x750  voter.votewa.gov
--   Alan Nolan                 LD  6 Pos 1  293x350 -> 280x350    voter.votewa.gov
--   Jonathan Bingle            LD  6 Pos 2  554x664 -> 531x664    voter.votewa.gov
--   Joshua Thompson            LD 13 Pos 2  152x183 -> 146x183    voter.votewa.gov
--   Chelsea Dimas              LD 14 Pos 1  954x1145 -> 600x750   voter.votewa.gov
--   Ezequiel Morfin            LD 14 Pos 2  637x764 -> 600x750    voter.votewa.gov
--   Reedy Berg                 LD 15 Pos 2  688x825 -> 600x750    voter.votewa.gov
--   Ben Christly               LD 17 Pos 1  622x747 -> 600x750    voter.votewa.gov
--   Diana H. Perez             LD 17 Pos 2  1280x1280 -> 600x750  www.cityofvancouver.us
--   Deken Letinich             LD 18 Pos 2  2500x1667 -> 600x750  www.electdeken.com
--   Kaylee Kuehn               LD 24 Pos 2  715x858 -> 600x750    voter.votewa.gov
--   David Berg                 LD 25 Pos 1  1407x1688 -> 600x750  voter.votewa.gov
--   Renee Hernandez Greenfield LD 26 Pos 2  704x844 -> 600x750    voter.votewa.gov
--   Krista Perez               LD 29 Pos 1  600x720 -> 576x720    voter.votewa.gov
--   Patrick Stickney           LD 29 Pos 2  788x946 -> 600x750    voter.votewa.gov
--   Danica Noble               LD 32 Pos 1  9504x6336 -> 600x750  www.electdanica.com
--   Kelabe Tewolde             LD 37 Pos 1  1229x1475 -> 600x750  voter.votewa.gov
--   Jaelynn Scott              LD 37 Pos 2  1389x1667 -> 600x750  voter.votewa.gov
--   Steve Ewing                LD 39 Pos 2  897x1076 -> 600x750   voter.votewa.gov
--   Michael Alvarez Shepard    LD 42 Senate 832x998 -> 600x750    voter.votewa.gov
--   Kim D. Harless             LD 49 Pos 1  1280x1280 -> 600x750  www.cityofvancouver.us
BEGIN;

CREATE TEMP TABLE cc_0439_imported (politician_id uuid, name text, url text, origin text, photo_license text) ON COMMIT DROP;
INSERT INTO cc_0439_imported (politician_id, name, url, origin, photo_license) VALUES
  ('49b231aa-1fb6-4b06-a448-f566b50dc7df'::uuid, 'Luc Jasmin III',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/49b231aa-1fb6-4b06-a448-f566b50dc7df-headshot.jpg',
   'https://voter.votewa.gov/genericvoterguide.aspx?e=899&c=32', 'unknown'),
  ('3052e007-9a24-40c9-9682-3fdd12009cb3'::uuid, 'Hillary Q. Pham',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3052e007-9a24-40c9-9682-3fdd12009cb3-headshot.jpg',
   'https://voter.votewa.gov/genericvoterguide.aspx?e=899&c=32', 'unknown'),
  ('9a78d751-6285-42f7-88f5-07d91afb5be5'::uuid, 'Alan Nolan',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9a78d751-6285-42f7-88f5-07d91afb5be5-headshot.jpg',
   'https://voter.votewa.gov/genericvoterguide.aspx?e=899&c=32', 'unknown'),
  ('6a1076f3-43ed-4eae-954a-3a26d815000c'::uuid, 'Jonathan Bingle',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6a1076f3-43ed-4eae-954a-3a26d815000c-headshot.jpg',
   'https://voter.votewa.gov/genericvoterguide.aspx?e=899&c=32', 'unknown'),
  ('cee94603-2a88-44e3-9c3d-4823c0f25d7f'::uuid, 'Joshua Thompson',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cee94603-2a88-44e3-9c3d-4823c0f25d7f-headshot.jpg',
   'https://voter.votewa.gov/genericvoterguide.aspx?e=899&c=13', 'unknown'),
  ('daa82515-274f-4552-a478-3ccbce9c6d17'::uuid, 'Chelsea Dimas',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/daa82515-274f-4552-a478-3ccbce9c6d17-headshot.jpg',
   'https://voter.votewa.gov/genericvoterguide.aspx?e=899&c=11', 'unknown'),
  ('4fa0d08a-af4e-43af-bb57-68355528b14a'::uuid, 'Ezequiel Morfin',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4fa0d08a-af4e-43af-bb57-68355528b14a-headshot.jpg',
   'https://voter.votewa.gov/genericvoterguide.aspx?e=899&c=11', 'unknown'),
  ('ea49c7f6-50e8-4c7a-a7bd-b2f1fdbf64ef'::uuid, 'Reedy Berg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ea49c7f6-50e8-4c7a-a7bd-b2f1fdbf64ef-headshot.jpg',
   'https://voter.votewa.gov/genericvoterguide.aspx?e=899&c=39', 'unknown'),
  ('aedb0d7e-8739-4f8e-9451-e495450216f0'::uuid, 'Ben Christly',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/aedb0d7e-8739-4f8e-9451-e495450216f0-headshot.jpg',
   'https://voter.votewa.gov/genericvoterguide.aspx?e=899&c=20', 'unknown'),
  ('8d2c15bc-5a9f-485d-9ba8-6227355da41f'::uuid, 'Diana H. Perez',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8d2c15bc-5a9f-485d-9ba8-6227355da41f-headshot.jpg',
   'https://www.cityofvancouver.us/government/mayor-and-city-council/mayor-and-council-bios/', 'unknown'),
  ('b4cdc7de-58b7-4416-ac4e-9580d34645c6'::uuid, 'Deken Letinich',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b4cdc7de-58b7-4416-ac4e-9580d34645c6-headshot.jpg',
   'https://www.electdeken.com/media', 'unknown'),
  ('9f306adc-241f-4ad7-8991-e56036f3391c'::uuid, 'Kaylee Kuehn',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9f306adc-241f-4ad7-8991-e56036f3391c-headshot.jpg',
   'https://voter.votewa.gov/genericvoterguide.aspx?e=899&c=14', 'unknown'),
  ('cde24c6b-81dd-451d-96ec-d228e653e243'::uuid, 'David Berg',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cde24c6b-81dd-451d-96ec-d228e653e243-headshot.jpg',
   'https://voter.votewa.gov/genericvoterguide.aspx?e=899&c=27', 'unknown'),
  ('5c81fd27-9885-430d-82b4-c6931d143079'::uuid, 'Renee Hernandez Greenfield',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5c81fd27-9885-430d-82b4-c6931d143079-headshot.jpg',
   'https://voter.votewa.gov/genericvoterguide.aspx?e=899&c=18', 'unknown'),
  ('0ec9ff38-9472-46b3-a57a-6cd41957c5af'::uuid, 'Krista Perez',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0ec9ff38-9472-46b3-a57a-6cd41957c5af-headshot.jpg',
   'https://voter.votewa.gov/genericvoterguide.aspx?e=899&c=27', 'unknown'),
  ('68ddd350-1bbd-4783-a70f-0f477028e6bc'::uuid, 'Patrick Stickney',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/68ddd350-1bbd-4783-a70f-0f477028e6bc-headshot.jpg',
   'https://voter.votewa.gov/genericvoterguide.aspx?e=899&c=27', 'unknown'),
  ('51d232bf-7a38-4510-afa8-e31a796694e7'::uuid, 'Danica Noble',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/51d232bf-7a38-4510-afa8-e31a796694e7-headshot.jpg',
   'https://www.electdanica.com/', 'unknown'),
  ('d7015b19-a4ba-46fe-ba04-fa6ada71bffc'::uuid, 'Kelabe Tewolde',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d7015b19-a4ba-46fe-ba04-fa6ada71bffc-headshot.jpg',
   'https://voter.votewa.gov/genericvoterguide.aspx?e=899&c=17', 'unknown'),
  ('54307367-1080-4a1a-b790-c384aa3c22ca'::uuid, 'Jaelynn Scott',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/54307367-1080-4a1a-b790-c384aa3c22ca-headshot.jpg',
   'https://voter.votewa.gov/genericvoterguide.aspx?e=899&c=17', 'unknown'),
  ('4085a1b3-512c-4953-b255-eabc041a2979'::uuid, 'Steve Ewing',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4085a1b3-512c-4953-b255-eabc041a2979-headshot.jpg',
   'https://voter.votewa.gov/genericvoterguide.aspx?e=899&c=29', 'unknown'),
  ('a40d272c-1577-4764-a4ea-b235fabbedc4'::uuid, 'Michael Alvarez Shepard',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a40d272c-1577-4764-a4ea-b235fabbedc4-headshot.jpg',
   'https://voter.votewa.gov/genericvoterguide.aspx?e=899&c=37', 'unknown'),
  ('af474c37-561f-4b61-9e91-f053efca4519'::uuid, 'Kim D. Harless',
   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/af474c37-561f-4b61-9e91-f053efca4519-headshot.jpg',
   'https://www.cityofvancouver.us/government/mayor-and-city-council/mayor-and-council-bios/', 'unknown');
-- The DELTA this file creates, captured in its OWN transaction. A total can be moved by
-- another session between the measurement and the write; a before/after pair inside one
-- transaction cannot be.
CREATE TEMP TABLE cc_0439_before ON COMMIT DROP AS
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
  FROM cc_0439_imported i
 WHERE p.id = i.politician_id
   AND p.photo_custom_url IS DISTINCT FROM i.url;

UPDATE essentials.politicians p
   SET photo_origin_url = i.origin
  FROM cc_0439_imported i
 WHERE p.id = i.politician_id
   AND p.photo_origin_url IS DISTINCT FROM i.origin;

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT i.politician_id, i.url, 'default', i.photo_license
  FROM cc_0439_imported i
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
  --    editing would otherwise make every "% of 22" gate below count against the wrong total.
  SELECT count(*) INTO imported_n FROM cc_0439_imported;
  IF imported_n <> 22 THEN
    RAISE EXCEPTION 'CC_0439: the import set holds % rows, not the 22 this file documents', imported_n;
  END IF;

  -- 1. every one of the 22 renders from the scalar the backend read paths use
  SELECT count(*) INTO missing_scalar
    FROM cc_0439_imported i JOIN essentials.politicians p ON p.id = i.politician_id
   WHERE btrim(coalesce(p.photo_custom_url, '')) = '';
  IF missing_scalar <> 0 THEN
    RAISE EXCEPTION 'CC_0439: % of 22 carry no photo_custom_url - they would render blank on address search', missing_scalar;
  END IF;

  -- 2. provenance is recorded. An `unknown` licence is only honest if the page it was read
  --    from is written down beside it.
  SELECT count(*) INTO missing_origin
    FROM cc_0439_imported i JOIN essentials.politicians p ON p.id = i.politician_id
   WHERE p.photo_origin_url IS DISTINCT FROM i.origin;
  IF missing_origin <> 0 THEN
    RAISE EXCEPTION 'CC_0439: % of 22 do not carry the source page in photo_origin_url', missing_origin;
  END IF;

  -- 3. EXACTLY ONE default row each. Two make the grid's find() pick an arbitrary one.
  SELECT count(*) INTO wrong_default FROM (
    SELECT i.politician_id FROM cc_0439_imported i
      LEFT JOIN essentials.politician_images pi
        ON pi.politician_id = i.politician_id AND pi.type = 'default'
     GROUP BY i.politician_id HAVING count(pi.*) <> 1) x;
  IF wrong_default <> 0 THEN
    RAISE EXCEPTION 'CC_0439: % of 22 do not have exactly one type=default image row', wrong_default;
  END IF;

  -- 4. THE TWO SIDES AGREE (CC_0195/CC_0196).
  SELECT count(*) INTO disagreeing
    FROM cc_0439_imported i
    JOIN essentials.politicians p ON p.id = i.politician_id
    JOIN essentials.politician_images pi
      ON pi.politician_id = i.politician_id AND pi.type = 'default'
   WHERE pi.url IS DISTINCT FROM p.photo_custom_url;
  IF disagreeing <> 0 THEN
    RAISE EXCEPTION 'CC_0439: % of 22 have a default image row that disagrees with photo_custom_url', disagreeing;
  END IF;

  -- 5. THE THIRD SURFACE. race_candidates.photo_url is swept by nothing and BEATS the fixed
  --    image on ballot pages, so a stale value there outranks everything written above.
  --    CC_0384 had to name it explicitly for exactly this reason.
  SELECT count(*) INTO third_surface
    FROM cc_0439_imported i
    JOIN essentials.race_candidates rc ON rc.politician_id = i.politician_id
   WHERE btrim(coalesce(rc.photo_url, '')) <> ''
     AND rc.photo_url IS DISTINCT FROM i.url;
  IF third_surface <> 0 THEN
    RAISE EXCEPTION 'CC_0439: % race_candidates rows carry a DIFFERENT photo_url and would outrank the import on ballot pages', third_surface;
  END IF;

  -- 6. THE DELTA. Exactly 22 legislative winners must leave the faceless set, measured inside
  --    this transaction against the snapshot taken before the writes.
  SELECT faceless INTO before_n FROM cc_0439_before;
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
  IF before_n - after_n <> 22 THEN
    RAISE EXCEPTION 'CC_0439: the faceless legislative count moved by % (% -> %), not the 22 this file imports', before_n - after_n, before_n, after_n;
  END IF;

  RAISE NOTICE 'CC_0439 ok: 22 headshots, scalar + origin set, exactly one default row each, both sides agree, third surface clear, faceless legislative winners % -> %', before_n, after_n;
END
$$;

COMMIT;
