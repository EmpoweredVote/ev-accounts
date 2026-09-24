-- CA_0272_wi_2026_general_candidate_profiles.sql
--
-- Slot CA_0272 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand.
--
-- Candidate PROFILE enrichment for the 10 bare Wisconsin 2026-11-03 GENERAL-election candidates that
-- CA_0254 (PR #749) added with only a name (external_id -66000301 .. -66000310). Sets, only where empty:
--   * politicians.urls         — the campaign website (6 of 10)
--   * the portrait, as the dual write the read path needs (COALESCE(photo_custom_url,
--     photo_origin_url)): photo_custom_url = hosted bucket image, photo_origin_url = the page the
--     candidate published it on, plus a politician_images row carrying the rights note (5 of 10)
--   * politicians.bio_text     — a short neutral factual bio (8 of 10)
--   * the election-card mirror: race_candidates.photo_url / website_url on the November row
-- Model = CA_0235 (2026 Senate candidate profiles) / CA_0131.
--
-- GENERAL-ELECTION FOCUS: sources are the candidates' November campaign material. Bios describe the
-- person, not how they reached the ballot — Goodwin's write-in primary is deliberately not in his bio.
--
-- NOT in scope: compass stances/chairs (separate step, CLAUDE.md evidence standard), party (never
-- stored on a person — antipartisan model; bios therefore name no party or party office — Becker's
-- former county-party chair role is left out for that reason), politician_sources.
--
-- Portraits were cropped to 4:5 (600x750, ImageMagick) and pre-uploaded to Storage bucket
-- `politician_photos/{politician_id}-headshot.jpg`; every public URL was verified 200 image/jpeg
-- on 2026-09-24 before this file was written. Every portrait is one the candidate published
-- themselves (own campaign site) or, for Tataje, his own party's candidate page; rights reasoning
-- is recorded per image in politician_images.photo_license.
--
-- Sources (all read 2026-09-24; PBS Wisconsin, Ballotpedia and WisPolitics used as leads only):
--   Becker    markforwisconsin.vote (small business owner, lifelong NE Wisconsin resident, father;
--             portrait = the site's speaking photo, cropped); doorcountydailynews.com/news/912705
--             (former Brown County supervisor; host of his own radio show in Green Bay).
--   Ellis     christianellisforwi.com/meet-christian. No portrait: the site's press kit lists a
--             headshot as "COMING SOON" — re-check later.
--   Dean      christopherdeanforwisconsin.com/meet_christopher. No portrait: the only photo is an
--             unlabelled two-person forum picture — not used.
--   Goodwin   goodwinforwi.com (+ /meet_michael). His church is not named on his site (a lead points
--             to Memorial Presbyterian, Appleton) — not stated.
--   Chapman   chapmanforassembly.org (the .com that VOTE411 lists is a blank placeholder). Her
--             headshot's flag-and-Capitol backdrop looks digitally composited; the face is a clear
--             headshot she published. No city/occupation in any reliable source.
--   Tataje    No website. solidarity-party.org/candidates/nathan-tataje (his party's candidate page:
--             bio and portrait). The ballot lists him American Solidarity Party; PBS says Independent.
--   Dowling   dowlingforassembly.com.
--   Brault    No website, no portrait she published. Bio from her 2026-04-22 campaign announcement as
--             printed by KFIZ (kfiz.com/tiffany-brault-announces-run-for-wisconsins-60th-assembly-district/).
--   Kelley    Nothing found: no website, no social accounts, PBS shows a placeholder. Left blank.
--   Weber     Nothing from the candidate: no website, no portrait. Left blank on purpose. News reports
--             (WIZM, WXOW, 2026-07) say he was charged in July 2026; allegations are not a bio fact,
--             and nothing here records them. He is on WEC's November ballot list (CA_0254).
--
-- Idempotent: every write is guarded empty-only / NOT EXISTS, so a re-run changes nothing.

BEGIN;

CREATE TEMP TABLE _prof (
  politician_id uuid PRIMARY KEY,
  external_id   int  NOT NULL,
  full_name     text NOT NULL,
  rc_id         uuid NOT NULL,
  portrait_lic  text,          -- NULL = no portrait
  portrait_src  text,          -- page the candidate published it on (photo_origin_url)
  website       text,          -- NULL = no website
  bio           text           -- NULL = no bio
) ON COMMIT DROP;

INSERT INTO _prof VALUES
 ('13e22b6b-1a25-4f21-90e3-02f099ea9658', -66000301, 'Mark Becker', 'd56b70b3-2184-4dc5-94f4-a7bddc459a35',
  'Campaign photo, markforwisconsin.vote home page (candidate campaign, press_use) — 8104x5403 speaking photo, cropped 4:5 to head and shoulders',
  'https://www.markforwisconsin.vote/',
  'https://www.markforwisconsin.vote/',
  'Mark Becker is a small business owner and a lifelong resident of Northeast Wisconsin. He is a former Brown County supervisor and has hosted his own radio show in Green Bay. He is a father.'),
 ('bb11163b-8ab2-4622-af62-45269e429f1f', -66000302, 'Christian Ellis', '73c4ec33-6166-4908-ab84-42b7ea1a35c4',
  NULL, NULL,
  'https://www.christianellisforwi.com/',
  'Christian Ellis lives in Sheboygan Falls, where he and his wife are raising four children. He grew up near Oostburg and graduated from Oostburg High School in 2000. He served in the U.S. Marine Corps Reserve and deployed to Iraq in 2004. He runs a small recruiting business and is serving his third term on the county board.'),
 ('2c0b813c-67b0-4ed8-b0f1-214bf43d0e37', -66000303, 'Christopher Dean', '36cbdbce-02c7-42b7-8b92-15df35b49866',
  NULL, NULL,
  'https://www.christopherdeanforwisconsin.com/',
  'Christopher Dean served as an infantryman in the U.S. Army and deployed to Iraq. After a medical retirement from the military in 2010, he settled in Center Township. He works in the automotive industry, where he rose from parts delivery driver to automotive parts house manager. He has volunteered as a coach with Parkview Youth Football.'),
 ('2f09bea9-0526-455e-a7b2-9f82a98aa50a', -66000304, 'Michael J. Goodwin', '7a4848d7-a444-4bfc-ae2e-93f9c49d427f',
  'Campaign photo, goodwinforwi.com home page (candidate campaign, press_use) — 1500x2000 source, cropped 4:5',
  'https://goodwinforwi.com/',
  'https://goodwinforwi.com/',
  'Michael J. Goodwin is a pastor whose family has lived on the south side of Appleton for nearly 15 years. He grew up in southern Minnesota. He and his wife raised their three children in Appleton. This is his first run for public office.'),
 ('d8ea103c-8e2a-4caa-9583-d12e1dd71c96', -66000305, 'Shena Chapman', 'baf0f512-5122-446d-80c5-e99ff7dd3f0d',
  'Campaign headshot, chapmanforassembly.org home page (candidate campaign, press_use) — 1023x1537 source, cropped 4:5. The flag-and-Capitol backdrop appears digitally composited',
  'https://www.chapmanforassembly.org/',
  'https://www.chapmanforassembly.org/',
  'Shena Chapman is a mother of four. Over her career she has managed finances, owned a small business, supported students in schools, and cared for vulnerable members of her community. This is her first run for public office.'),
 ('a9e2be91-5254-4b26-9def-2949f785c9c9', -66000306, 'Nathan Tataje', '265c9f44-a20d-4c76-b0f6-3d6335c82fb4',
  'Candidate photo on his own party''s candidate page, solidarity-party.org/candidates/nathan-tataje (press_use) — 793x743 source, cropped 4:5. REPLACE if he publishes his own site',
  'https://www.solidarity-party.org/candidates/nathan-tataje',
  NULL,
  'Nathan Tataje lives in rural Arena, Wisconsin, and previously lived in the Madison area. He is a first-generation American whose parents immigrated from Peru and Nicaragua. He serves as Grand Knight of Knights of Columbus Council 7811.'),
 ('c53de0f4-2bf1-4fd2-a061-ce92239e9023', -66000307, 'Rachael Dowling', 'c66aacb2-202f-4cb5-b196-512633119927',
  'Campaign photo, dowlingforassembly.com home page (candidate campaign, press_use) — 1737x3088 source, cropped 4:5',
  'https://www.dowlingforassembly.com/',
  'https://www.dowlingforassembly.com/',
  'Rachael Dowling lives in Menasha, Wisconsin, where she and her husband homeschool their four sons. She has served on the Winnebago County Board since 2022. She has owned several small businesses since 2007 and works as an FAA Part 107 licensed drone pilot.'),
 ('f4fba542-5572-43d2-b087-7ee8194351f6', -66000308, 'Tiffany Brault', 'f16b60c5-07f5-4a56-b28a-a1aa05769680',
  NULL, NULL, NULL,
  'Tiffany Brault is a Fond du Lac native who attended UW-Fond du Lac and graduated from Marian University. She worked in public and school libraries in Dodge County and now works as a substitute teacher in the Fond du Lac School District. First elected to local office in 2021, she is Vice President of the Fond du Lac City Council and represents District 20 on the Fond du Lac County Board.'),
 ('331eeeaf-ec8f-4df2-bffc-62709bbaba7d', -66000309, 'Josh Kelley', '57d1fb9d-e271-45c9-b32f-02c0956283a5',
  NULL, NULL, NULL, NULL),
 ('b3e9f1c8-95d4-401e-842c-73757f2aaa58', -66000310, 'Paul Michael Weber', 'f4958656-03eb-411f-82df-f70f35707a49',
  NULL, NULL, NULL, NULL);

-- bucket URL derived from politician_id, so it always matches what was uploaded
CREATE TEMP VIEW _profx AS
  SELECT *,
    'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/'
      || politician_id || '-headshot.jpg' AS bucket_url
  FROM _prof;

-- ── pre-flight gate ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n_match int; n_rc int; n_override int; n_bio_override int;
BEGIN
  -- every row is the CA_0254 politician we think it is (id + external_id + name)
  SELECT count(*) INTO n_match FROM _prof t
  JOIN essentials.politicians p
    ON p.id = t.politician_id AND p.external_id = t.external_id AND p.full_name = t.full_name;
  IF n_match <> 10 THEN RAISE EXCEPTION 'aborting: only % of 10 politicians match id/external_id/name', n_match; END IF;

  -- every race_candidate is this person's live row on the WI 2026-11-03 general
  SELECT count(*) INTO n_rc FROM _prof t
  JOIN essentials.race_candidates rc ON rc.id = t.rc_id AND rc.politician_id = t.politician_id
  JOIN essentials.races r ON r.id = rc.race_id
  WHERE r.election_id = '588c66dc-31ef-4bbc-b4f6-6da5876a5a38'
    AND essentials.is_live_candidate(rc.candidate_status, rc.result);
  IF n_rc <> 10 THEN RAISE EXCEPTION 'aborting: only % of 10 race_candidates are the live WI 2026-11-03 general row', n_rc; END IF;

  -- never touch a hand-locked portrait or bio
  SELECT count(*) INTO n_override FROM _prof t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE t.portrait_lic IS NOT NULL AND p.photo_custom_url_manual_override IS TRUE;
  IF n_override <> 0 THEN RAISE EXCEPTION 'aborting: % portrait target(s) are manual-override locked', n_override; END IF;

  SELECT count(*) INTO n_bio_override FROM _prof t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE t.bio IS NOT NULL AND p.bio_text_manual_override IS TRUE;
  IF n_bio_override <> 0 THEN RAISE EXCEPTION 'aborting: % bio target(s) are manual-override locked', n_bio_override; END IF;
END $$;

-- ── 1. portrait: politician_images (once per person) + photo_custom_url + photo_origin_url ──────
INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT x.politician_id, x.bucket_url, 'default', x.portrait_lic
FROM _profx x
WHERE x.portrait_lic IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = x.politician_id);

UPDATE essentials.politicians p
SET photo_custom_url = x.bucket_url,
    photo_origin_url = x.portrait_src
FROM _profx x
WHERE p.id = x.politician_id
  AND x.portrait_lic IS NOT NULL
  AND p.photo_custom_url_manual_override IS NOT TRUE
  AND coalesce(p.photo_custom_url, '') = ''      -- never overwrite an existing portrait
  AND coalesce(p.photo_origin_url, '') = '';

-- ── 2. website: politicians.urls (only when the politician has none) ────────────────────────────
UPDATE essentials.politicians p
SET urls = ARRAY[t.website]
FROM _prof t
WHERE p.id = t.politician_id
  AND t.website IS NOT NULL
  AND coalesce(array_length(p.urls, 1), 0) = 0
  AND coalesce(p.web_form_url, '') = '';

-- ── 3. bio_text (only when empty and not hand-locked) ──────────────────────────────────────────
UPDATE essentials.politicians p
SET bio_text = t.bio
FROM _prof t
WHERE p.id = t.politician_id
  AND t.bio IS NOT NULL
  AND p.bio_text_manual_override IS NOT TRUE
  AND coalesce(btrim(p.bio_text), '') = '';

-- ── 4. mirror portrait/website onto the race_candidate row (the election CARD reads rc.*) ───────
UPDATE essentials.race_candidates rc
SET photo_url = x.bucket_url
FROM _profx x
WHERE rc.id = x.rc_id
  AND x.portrait_lic IS NOT NULL
  AND coalesce(rc.photo_url, '') = '';

UPDATE essentials.race_candidates rc
SET website_url = t.website
FROM _prof t
WHERE rc.id = t.rc_id
  AND t.website IS NOT NULL
  AND coalesce(rc.website_url, '') = '';

-- ── post-verify gate ───────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n_img int; n_custom int; n_render int; n_urls int; n_bio int; n_rcphoto int; n_rcsite int;
        n_untouched int;
BEGIN
  SELECT count(*) INTO n_img FROM _profx x
  JOIN essentials.politician_images pi ON pi.politician_id = x.politician_id AND pi.url = x.bucket_url
  WHERE x.portrait_lic IS NOT NULL;
  IF n_img <> 5 THEN RAISE EXCEPTION 'expected 5 portrait image rows, found %', n_img; END IF;

  SELECT count(*) INTO n_custom FROM _profx x
  JOIN essentials.politicians p ON p.id = x.politician_id
  WHERE x.portrait_lic IS NOT NULL AND p.photo_custom_url = x.bucket_url AND p.photo_origin_url = x.portrait_src;
  IF n_custom <> 5 THEN RAISE EXCEPTION 'expected 5 photo_custom_url/photo_origin_url pairs, found %', n_custom; END IF;

  -- HAS_RENDERABLE_PHOTO_SQL (verbatim shape from backend/src/lib/photoCoverage.ts)
  SELECT count(DISTINCT p.id) INTO n_render FROM _prof t
  JOIN essentials.politicians p ON p.id = t.politician_id
  LEFT JOIN essentials.politician_images img ON img.politician_id = p.id
  WHERE t.portrait_lic IS NOT NULL
    AND ( img.politician_id IS NOT NULL
       OR btrim(coalesce(p.photo_custom_url, '')) <> ''
       OR (btrim(coalesce(p.photo_origin_url, '')) <> '' AND p.photo_origin_url LIKE 'http%') );
  IF n_render <> 5 THEN RAISE EXCEPTION 'only % of 5 satisfy HAS_RENDERABLE_PHOTO_SQL', n_render; END IF;

  SELECT count(*) INTO n_urls FROM _prof t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE t.website IS NOT NULL AND p.urls = ARRAY[t.website];
  IF n_urls <> 6 THEN RAISE EXCEPTION 'expected 6 politicians with the website, found %', n_urls; END IF;

  SELECT count(*) INTO n_bio FROM _prof t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE t.bio IS NOT NULL AND p.bio_text = t.bio;
  IF n_bio <> 8 THEN RAISE EXCEPTION 'expected 8 bios, found %', n_bio; END IF;

  SELECT count(*) INTO n_rcphoto FROM _profx x
  JOIN essentials.race_candidates rc ON rc.id = x.rc_id
  WHERE x.portrait_lic IS NOT NULL AND rc.photo_url = x.bucket_url;
  IF n_rcphoto <> 5 THEN RAISE EXCEPTION 'expected 5 race_candidate.photo_url set, found %', n_rcphoto; END IF;

  SELECT count(*) INTO n_rcsite FROM _prof t
  JOIN essentials.race_candidates rc ON rc.id = t.rc_id
  WHERE t.website IS NOT NULL AND rc.website_url = t.website;
  IF n_rcsite <> 6 THEN RAISE EXCEPTION 'expected 6 race_candidate.website_url set, found %', n_rcsite; END IF;

  -- the honest blanks stay blank (Kelley, Weber: nothing; Ellis, Dean, Brault: no portrait; Tataje, Brault: no website)
  SELECT count(*) INTO n_untouched FROM _prof t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE (t.portrait_lic IS NULL AND p.photo_custom_url IS NOT NULL)
     OR (t.website IS NULL AND coalesce(array_length(p.urls, 1), 0) > 0)
     OR (t.bio IS NULL AND p.bio_text IS NOT NULL);
  IF n_untouched <> 0 THEN RAISE EXCEPTION 'expected blanks to stay blank, % field(s) are set', n_untouched; END IF;

  RAISE NOTICE 'ok CA_0272: 5 portraits renderable, 6 websites, 8 bios, card mirrored';
END $$;

COMMIT;
