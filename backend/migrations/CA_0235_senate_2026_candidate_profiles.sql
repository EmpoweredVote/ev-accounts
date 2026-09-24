-- CA_0235_senate_2026_candidate_profiles.sql
--
-- Candidate PROFILE enrichment for the 11 bare 2026-11-03 U.S. Senate candidates that CA_0233
-- (PR #728) added with only a name (external_id -66000149 .. -66000159). Sets, only where empty:
--   * politicians.urls         — the campaign website (9 of 11)
--   * the portrait, as the dual write the read path needs (COALESCE(photo_custom_url,
--     photo_origin_url)): photo_custom_url = hosted bucket image, photo_origin_url = the page the
--     candidate published it on, plus a politician_images row carrying the rights note (9 of 11)
--   * politicians.bio_text     — a short neutral factual bio (9 of 11)
--   * the election-card mirror: race_candidates.photo_url / website_url
-- Model = CA_0131 (Monroe 2026 candidate profiles, phase 1).
--
-- NOT in scope: compass stances/chairs (separate step, CLAUDE.md evidence standard), party (never
-- stored on a person — antipartisan model; bios therefore name no party or party office), and
-- politician_sources. The FEC candidate IDs found below are LEADS for the fecResearch auto-match
-- queue, which owns politician_sources; nothing here writes them.
--
-- Portraits were cropped to 4:5 (600x750, ImageMagick) and pre-uploaded to Storage bucket
-- `politician_photos/{politician_id}-headshot.jpg`; every public URL was verified 200 image/jpeg
-- on 2026-09-24 before this file was written. Every portrait is one the candidate published
-- themselves (own campaign site, own press kit, or own party's candidate page); rights reasoning
-- is recorded per image in politician_images.photo_license.
--
-- Sources (all read 2026-09-24; Ballotpedia/Wikipedia used as leads only):
--   Jackson     jacksonformaine.com (+ /about); Maine Senate Legislative Record 2022-12-07.
--               FEC S6ME00464 (cmte C00955609). NOTE: he left the Legislature in Dec 2024; his
--               own site says "six as Senate President" in the past tense — he is a FORMER
--               Senate President, so the bio says so.
--   Gillespie   neilgillespie4senate.blogspot.com; FL DOS candidate page CanDetail.asp?account=89955
--               (Ocala, filed 2026-03-16, qualified 2026-04-24); FEC 2020 presidential candidate
--               P60022993. NO FEC Senate record (none found in FL or nationally).
--   Graham      No 2026 website (graham4senate.com expired, now parked/spam — NOT linked).
--               Portrait from his own 2022 campaign site via the Wayback Machine
--               (web.archive.org/web/20220906132022/https://graham4senate.com/). Bio: that site's
--               About section; lpks.org 2026-08-15 post (attorney, Overland Park); Johnson County
--               Election Office (2022 U.S. Senate candidate). FEC S2KS00154.
--   Christensen lydialynnchristensen.com (+ /press: "High-resolution photo for press use").
--               FEC S6MI00442 (cmte C00903575).
--   Long        No website, no portrait: ustpm.org lists him with an empty profile. FEC S6MI00566
--               (cmte C00957514). No bio — no primary source beyond name and city.
--   Marsh       electmarsh.org; portrait from migreenparty.org/douglas-marsh-u-s-senate/ (his own
--               party's page, which links his site). 2024 candidacy: gpelections.org. FEC S4MI00512.
--   Kristy      Candidate page nlpmi.org/walter/ (no own site); no portrait anywhere. FEC S6MI00590.
--               No bio — the only primary facts are his city and a party office.
--   Laplante    laplante4constitutionalnh.com (+ /about-me); mrsd.org school-board member list.
--               FEC S2NH00223.
--   Bahry       bahryforsenate.com. FEC S6RI00288 (cmte C00949982).
--   Ayyadurai   shiva4senate.com (+ /about-shiva/). FEC S8MA00268 (election years 2018, 2020,
--               2024, 2026; cmte C00936542). A second ID, S4MA00275, is active through 2024 only.
--   Tache       tache4ma.com (+ /about). FEC S6MA00288 (cmte C00920793).
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
 ('aa834f34-1bec-4312-87b9-9bf9ed939456', -66000149, 'Troy D. Jackson', '693e836d-4726-4f3a-b8a1-80e0760cb626',
  'Campaign photo, jacksonformaine.com home page (candidate campaign, press_use) — 1112x972 source, cropped 4:5',
  'https://www.jacksonformaine.com',
  'https://www.jacksonformaine.com',
  'Troy D. Jackson is a logger from Allagash, Maine, who grew up in Aroostook County. He served twenty years in the Maine Legislature, six of them as President of the Maine Senate. He earned an associate''s degree from the University of Maine at Fort Kent in 2000.'),
 ('a8798879-3ea3-46f6-98bd-1a91435b37d0', -66000150, 'Neil J. Gillespie', 'd26b4ccc-f2b4-4938-b1e3-953646b354ee',
  'Campaign photo, neilgillespie4senate.blogspot.com (candidate campaign blog, press_use) — 1158x1544 source',
  'https://neilgillespie4senate.blogspot.com/',
  'https://neilgillespie4senate.blogspot.com/',
  'Neil J. Gillespie runs his Senate campaign from Ocala, Florida. He was a registered candidate for President in 2020, and in May 2026 he suspended a campaign for President in 2028 to run for the U.S. Senate.'),
 ('25ab585b-7769-4264-b8f2-9543cad7f16f', -66000151, 'David C. Graham', 'eaf1a53f-984c-4bc6-9fa7-18186b7c8880',
  'Campaign photo from his own 2022 campaign site graham4senate.com, via the Wayback Machine (candidate campaign, press_use). 2022 image; the domain has since expired. 2560x1707 source, cropped 4:5. REPLACE when a 2026 photo exists',
  'https://web.archive.org/web/20220906132022/https://graham4senate.com/',
  NULL,
  'David C. Graham is an attorney in solo practice in Overland Park, Kansas. He graduated from Shawnee Mission North High School and Washburn University, and earned his law degree at the University of Kansas. He was a candidate for U.S. Senate in Kansas in 2022.'),
 ('e59d0af3-cb03-4ea6-8f2c-504197641d48', -66000152, 'Lydia Christensen', 'dbf60c3e-eb08-410c-b69e-9a3564e89634',
  'Press-kit candidate photo, lydialynnchristensen.com/press ("High-resolution photo for press use") — press_use; 1144x2048 source, cropped 4:5',
  'https://www.lydialynnchristensen.com/press',
  'https://www.lydialynnchristensen.com',
  'Lydia Christensen''s family is from Ironwood, Michigan. She grew up in the foster care system, studied computer science and computer programming, and later founded her own technology company.'),
 ('fb69afee-b966-454d-80a7-13764d436a51', -66000153, 'Tim Long', 'c276e0b5-b11d-44e2-bafd-86f6fa7fb383',
  NULL, NULL, NULL, NULL),
 ('1b59035c-e65a-4ad1-a9d8-ac773abbc2e0', -66000154, 'Douglas P. Marsh', 'c884cd07-10d8-4d6d-a517-ef888939f009',
  'Candidate photo on his own party''s candidate page, migreenparty.org (which links his campaign site; press_use) — 236x312 source, upscaled x2.54, REPLACE',
  'https://migreenparty.org/douglas-marsh-u-s-senate/',
  'https://www.electmarsh.org',
  'Douglas P. Marsh is a community journalist from West Branch, Michigan. He was a candidate for U.S. Senate in Michigan in 2024.'),
 ('bd770a4c-481e-44af-bb10-8c611d2c9b8a', -66000155, 'Walter P. Kristy', 'ac7af974-abec-48b8-9425-dad3ea6eb6f8',
  NULL, NULL,
  'https://nlpmi.org/walter/',
  NULL),
 ('8ea58fae-bd3a-42a8-aa8a-c57b72ce3eb0', -66000156, 'Edmond Laplante', 'f48a51c2-f7fa-4d48-b897-3253db2fe6c7',
  'Campaign photo, laplante4constitutionalnh.com/about-me (candidate campaign, press_use) — 768x768 source, cropped 4:5',
  'https://laplante4constitutionalnh.com/about-me',
  'https://laplante4constitutionalnh.com',
  'Edmond Laplante is a mechanic of more than 40 years and a former U.S. Marine. He serves on the Monadnock Regional School District board for Richmond, New Hampshire, and has run before for U.S. Senate and for Governor.'),
 ('ce340bc9-0c02-4f44-b87d-3758799274fa', -66000157, 'Michael Bahry', 'db3cd4be-88c8-48ae-8523-30e3973d97e4',
  'Campaign headshot, bahryforsenate.com (candidate campaign, press_use) — 832x1248 source, cropped 4:5',
  'https://bahryforsenate.com',
  'https://bahryforsenate.com',
  'Michael Bahry is a native Rhode Islander who has worked as a laborer, carpenter, construction executive and business owner. He founded the nonprofit Fifty-Three: Five. He holds master''s degrees in theological studies (2017) and biblical studies (2022) from Providence College and teaches theology at Salve Regina University.'),
 ('dd3a3a39-6ebc-4782-8f1e-513e25673ddc', -66000158, 'Shiva Ayyadurai', 'e2327ebd-30f2-4c41-bfa9-2748611107bb',
  'Campaign headshot, shiva4senate.com home page (candidate campaign, press_use) — 654x800 source (file uploaded 2019), cropped 4:5',
  'https://shiva4senate.com',
  'https://shiva4senate.com',
  'Shiva Ayyadurai holds four degrees from MIT and is a Fulbright Scholar. He founded EchoMail, CytoSolve and Systems Health, and is the founder and CEO of CytoSolve, Inc. He was a candidate for U.S. Senate in Massachusetts in 2018, 2020 and 2024.'),
 ('fcc032b8-6261-4adb-accd-c97abd77a143', -66000159, 'Joe Tache', '879206f4-cfd5-460b-b169-7cf9e78c0eb7',
  'Campaign photo, tache4ma.com home page (candidate campaign, press_use) — 1920x1280 landscape source, cropped 4:5 around the candidate',
  'https://www.tache4ma.com',
  'https://www.tache4ma.com',
  'Joe Tache is a youth worker and community organizer based in Boston. He graduated from Northeastern University in 2018 and then worked as a HiSET instructor and mentor.');

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
  -- every row is the CA_0233 politician we think it is (id + external_id + name)
  SELECT count(*) INTO n_match FROM _prof t
  JOIN essentials.politicians p
    ON p.id = t.politician_id AND p.external_id = t.external_id AND p.full_name = t.full_name;
  IF n_match <> 11 THEN RAISE EXCEPTION 'aborting: only % of 11 politicians match id/external_id/name', n_match; END IF;

  -- every race_candidate is this person's, on a 2026-11-03 U.S. Senate race
  SELECT count(*) INTO n_rc FROM _prof t
  JOIN essentials.race_candidates rc ON rc.id = t.rc_id AND rc.politician_id = t.politician_id
  JOIN essentials.races r ON r.id = rc.race_id
  JOIN essentials.elections e ON e.id = r.election_id
  WHERE r.position_name LIKE 'U.S. Senate %' AND e.election_date = DATE '2026-11-03';
  IF n_rc <> 11 THEN RAISE EXCEPTION 'aborting: only % of 11 race_candidates are the 2026-11-03 Senate row', n_rc; END IF;

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
  IF n_img <> 9 THEN RAISE EXCEPTION 'expected 9 portrait image rows, found %', n_img; END IF;

  SELECT count(*) INTO n_custom FROM _profx x
  JOIN essentials.politicians p ON p.id = x.politician_id
  WHERE x.portrait_lic IS NOT NULL AND p.photo_custom_url = x.bucket_url AND p.photo_origin_url = x.portrait_src;
  IF n_custom <> 9 THEN RAISE EXCEPTION 'expected 9 photo_custom_url/photo_origin_url pairs, found %', n_custom; END IF;

  -- HAS_RENDERABLE_PHOTO_SQL (verbatim shape from backend/src/lib/photoCoverage.ts)
  SELECT count(DISTINCT p.id) INTO n_render FROM _prof t
  JOIN essentials.politicians p ON p.id = t.politician_id
  LEFT JOIN essentials.politician_images img ON img.politician_id = p.id
  WHERE t.portrait_lic IS NOT NULL
    AND ( img.politician_id IS NOT NULL
       OR btrim(coalesce(p.photo_custom_url, '')) <> ''
       OR (btrim(coalesce(p.photo_origin_url, '')) <> '' AND p.photo_origin_url LIKE 'http%') );
  IF n_render <> 9 THEN RAISE EXCEPTION 'only % of 9 satisfy HAS_RENDERABLE_PHOTO_SQL', n_render; END IF;

  SELECT count(*) INTO n_urls FROM _prof t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE t.website IS NOT NULL AND p.urls = ARRAY[t.website];
  IF n_urls <> 9 THEN RAISE EXCEPTION 'expected 9 politicians with the website, found %', n_urls; END IF;

  SELECT count(*) INTO n_bio FROM _prof t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE t.bio IS NOT NULL AND p.bio_text = t.bio;
  IF n_bio <> 9 THEN RAISE EXCEPTION 'expected 9 bios, found %', n_bio; END IF;

  SELECT count(*) INTO n_rcphoto FROM _profx x
  JOIN essentials.race_candidates rc ON rc.id = x.rc_id
  WHERE x.portrait_lic IS NOT NULL AND rc.photo_url = x.bucket_url;
  IF n_rcphoto <> 9 THEN RAISE EXCEPTION 'expected 9 race_candidate.photo_url set, found %', n_rcphoto; END IF;

  SELECT count(*) INTO n_rcsite FROM _prof t
  JOIN essentials.race_candidates rc ON rc.id = t.rc_id
  WHERE t.website IS NOT NULL AND rc.website_url = t.website;
  IF n_rcsite <> 9 THEN RAISE EXCEPTION 'expected 9 race_candidate.website_url set, found %', n_rcsite; END IF;

  -- the honest blanks stay blank (Long: nothing; Kristy: no portrait/bio; Graham: no website)
  SELECT count(*) INTO n_untouched FROM _prof t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE (t.portrait_lic IS NULL AND p.photo_custom_url IS NOT NULL)
     OR (t.website IS NULL AND coalesce(array_length(p.urls, 1), 0) > 0)
     OR (t.bio IS NULL AND p.bio_text IS NOT NULL);
  IF n_untouched <> 0 THEN RAISE EXCEPTION 'expected blanks to stay blank, % field(s) are set', n_untouched; END IF;

  RAISE NOTICE 'ok CA_0235: 9 portraits renderable, 9 websites, 9 bios, card mirrored';
END $$;

COMMIT;
