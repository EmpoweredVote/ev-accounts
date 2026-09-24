-- CA_0268_utah_2026_candidate_profiles.sql
--
-- Slot CA_0268 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand (pure DML).
-- ✅ APPLIED to prod 2026-09-24 (approval Chris Andrews): INSERT 9, UPDATE 9 / 7 / 8 / 9 / 7, both gates green. Re-read: 9
--   photos, 7 websites, 8 bios, 9 images, 9 card photos; live API serves the profiles.
--
-- Candidate PROFILE enrichment for the 11 bare 2026-11-03 Utah general-election candidates that CA_0253
-- (PR #751) added with only a name (external_id -66000160 .. -66000170). Same model as CA_0235 / CA_0131.
-- Sets, only where empty:
--   * politicians.urls         — the campaign website (7 of 11)
--   * the portrait, as the dual write the read path needs (COALESCE(photo_custom_url,
--     photo_origin_url)): photo_custom_url = hosted bucket image, photo_origin_url = the page the
--     candidate (or their party) published it on, plus a politician_images row carrying the rights note (9 of 11)
--   * politicians.bio_text     — a short neutral factual bio (8 of 11)
--   * the election-card mirror: race_candidates.photo_url / website_url
--
-- NOT in scope: compass stances/chairs (separate step, CLAUDE.md evidence standard), party (never stored on a
-- person — antipartisan model; the bios name no party, party office or party-adjacent organisation), and
-- politician_sources (no FEC — these are state and county races).
--
-- Portraits were cropped to 4:5 (600x750, ImageMagick; transparent backgrounds flattened on white) and
-- pre-uploaded to Storage `politician_photos/{politician_id}-headshot.jpg`; every public URL was verified
-- 200 image/jpeg on 2026-09-24 before this file was written. Each source image was confirmed present on the
-- page recorded as photo_origin_url (Julie Smith's Google Sites image by pixel comparison, RMSE 0, because
-- Google Sites rotates its image URLs on every load).
--
-- SOURCES (all read 2026-09-24; Ballotpedia / news used as leads only):
--   Millburn    bretmillburn.com (+ /about). Portrait headshot-transparency.png (3454x5128, waist-up) cropped to
--               head and shoulders. /about: grew up in Bountiful, lives in Centerville, "previously served as
--               Davis County Commissioner", Utah State Auditor's Office, Draper assistant city manager, 2002
--               Olympic Winter Games, Weber State B.S. Psychology, Ricks College associate degree.
--   Beglarian   NOTHING. No campaign site or social page; his party's pages list only his name and race. The
--               county list gives only his city. Name-only profile.
--   Poe         No campaign site (the county list's url field is null). Portrait from his own party's home page
--               libertarianutah.org (Casey-1.jpg, 625x625, beside the "Casey Poe - Salt Lake County Council
--               District 1" section). No bio: no primary fact beyond his city.
--   Andersen    No campaign site. Portrait and facts from his own party's candidate page iaput.org/candidates/
--               ("Utah County Auditor ... Hans Andersen is a practicing CPA ... his public service on the Orem City
--               Council"). That page is a shared candidate list, so it is not stored as his website.
--   Rampton     russjrampton.com (+ /about). Portrait Rampton_FWD.png (512x512 campaign card): cropped to the
--               photo half so no printed text shows; small source, upscaled. /about (written about 2022): Clerk's
--               office "for the past five years", began in the Elections Division, then supervisor in the Marriage License
--               and Passport office; two decades in higher education before that; lives in Provo. The bio uses the
--               past-perfect "has worked" because the page's "currently" is dated.
--   Oaks        Campaign Facebook page "OAKS For UT County Commission" (read in a browser 2026-09-24, posts that
--               day; stored as the website, as CA_0131 did for Trimble). Portrait and facts from his party's
--               candidate page iaput.org/candidates/ (jacob-oaks.jpg, 800x800): Utah County native, marketing
--               professional, manages the Revive music label, earlier campaign for Utah County Clerk (2022: his
--               county financial disclosure). The founder-of-Liberty-United line is left out (party-adjacent).
--   Hinckley    davidhinckley.com. Portrait campaign-hero.jpg (1200x800). "He lives in Orem ... and works in
--               analytics and leadership."
--   Townsend    blakeforhouse36.com (+ /about). Portrait IMG_1214 (1512x2016, full-length) cropped to head and
--               shoulders. /about: West Jordan home since 2021, Political Science degree from Utah State
--               University, began in tech recruiting, now the nonprofit labor sector.
--   Doud        NOTHING. No campaign site, social page or photo; her party lists only name and race. Her
--               declaration gives only her city. Name-only profile.
--   Smith       juliesmith4utah.com (Google Sites; linked from her party's candidate page, which confirms HD63).
--               Portrait 1280x941 from the site. "As a US History teacher ..." Only that fact is used.
--   Wessman     electawessman.com. Portrait Wessman-headshot.jpeg (1031x1031). "Alan has lived in Spanish Fork for
--               20 years ... bachelor's and master's degrees in computer science from BYU and works as a software
--               engineer for a cybersecurity firm." Same person as the 2024 Utah County Commission candidate.
--
-- Personal data: several declarations and disclosures show home addresses, phones and emails. None is stored.
--
-- ROLLBACK (once applied): for the 11 politician_ids, set urls = NULL, bio_text = NULL, photo_custom_url = NULL,
-- photo_origin_url = NULL where they equal the values below; delete their politician_images rows whose url is the
-- bucket URL; set race_candidates.photo_url / website_url back to NULL on the 11 rc rows.
-- IDEMPOTENT: every write is guarded empty-only / NOT EXISTS, so a re-run changes nothing.

BEGIN;

CREATE TEMP TABLE _prof (
  politician_id uuid PRIMARY KEY,
  external_id   bigint NOT NULL,
  full_name     text NOT NULL,
  rc_id         uuid NOT NULL,
  portrait_lic  text,          -- NULL = no portrait
  portrait_src  text,          -- page the candidate published it on (photo_origin_url)
  website       text,          -- NULL = no website
  bio           text           -- NULL = no bio
) ON COMMIT DROP;

INSERT INTO _prof VALUES
 ('cfb2852b-bb06-44e0-b81b-472ff7d0b70b', -66000160, 'Bret Millburn', '299c2f7b-c7fb-4751-bcc6-d04d932b4766',
  'Campaign headshot, bretmillburn.com home page (candidate campaign, press_use) — 3454x5128 transparent PNG, flattened on white and cropped 4:5 to head and shoulders',
  'https://www.bretmillburn.com/',
  'https://www.bretmillburn.com/',
  'Bret Millburn grew up in Bountiful and lives in Centerville. He is a former Davis County Commissioner. He has also worked in the Utah State Auditor''s Office, as assistant city manager of Draper, and in several positions for the 2002 Olympic Winter Games. He holds a bachelor''s degree in psychology from Weber State University and an associate degree from Ricks College.'),
 ('a7781a85-2f61-4d0b-a273-45a5fa1bf2cf', -66000161, 'Gregory Beglarian', '5bf0a6dd-160b-4fd0-be72-d75c28e6a7f5',
  NULL, NULL, NULL, NULL),
 ('4be5b0d6-468c-4305-a517-19d2d2bd5d27', -66000162, 'Casey Poe', '4c1a1192-2134-4dc9-a053-8ef69056daf6',
  'Candidate photo on his own party''s home page, libertarianutah.org (Casey-1.jpg beside his candidate section; party-published, press_use) — 625x625 source, cropped 4:5',
  'https://www.libertarianutah.org/',
  NULL,
  NULL),
 ('b8405dd2-5979-40dc-b285-cb4e42c2049a', -66000163, 'Hans V. Andersen', '54ea229c-560a-4d95-9db4-0193200ad44d',
  'Candidate photo on his own party''s candidate page, iaput.org/candidates/ (hans-andersen.jpg; party-published, press_use) — 800x800 source, cropped 4:5',
  'https://iaput.org/candidates/',
  NULL,
  'Hans V. Andersen is a certified public accountant. He has served on the Orem City Council.'),
 ('0a443f97-e040-439b-8837-ac793dc764f0', -66000164, 'Russ J. Rampton', 'f16369f0-22ba-4062-b705-180a53a5774a',
  'Campaign card photo, russjrampton.com home page (Rampton_FWD.png; candidate campaign, press_use) — 512x512 source, cropped to the photo half so no printed text shows, upscaled to 4:5',
  'https://www.russjrampton.com/',
  'https://www.russjrampton.com/',
  'Russ J. Rampton lives in Provo. He has worked in the Utah County Clerk''s office, first in the Elections Division and then as a supervisor in the Marriage License and Passport office. Before that he spent two decades in higher education, studying, teaching and administering subjects that include organizational leadership and technical writing.'),
 ('dc70f6a1-27b8-4646-bf6a-60054f06765a', -66000165, 'Jacob D. Oaks', '9649e924-58ac-4df4-8380-a6f533153f67',
  'Candidate photo on his own party''s candidate page, iaput.org/candidates/ (jacob-oaks.jpg; party-published, press_use) — 800x800 source, cropped 4:5',
  'https://iaput.org/candidates/',
  'https://www.facebook.com/p/OAKS-For-UT-County-Clerk-100079181097531/',
  'Jacob D. Oaks is a Utah County native and a marketing professional. He manages the Revive music label. He ran for Utah County Clerk in 2022.'),
 ('ef1ecd08-27e8-4d81-bb20-42694093f739', -66000166, 'David Hinckley', '8a9ae674-5b8a-412e-8b83-6297629780bf',
  'Campaign photo, davidhinckley.com home page (campaign-hero.jpg; candidate campaign, press_use) — 1200x800 source, cropped 4:5',
  'https://www.davidhinckley.com/',
  'https://www.davidhinckley.com/',
  'David Hinckley lives in Orem and works in analytics and leadership.'),
 ('2c8bfdb1-cee3-4138-bdea-e944f9fa7dce', -66000167, 'Blake Townsend', 'fdbfc055-57f0-475a-8fee-14aa183daa5b',
  'Campaign photo, blakeforhouse36.com/about (IMG_1214; candidate campaign, press_use) — 1512x2016 full-length source, cropped 4:5 to head and shoulders',
  'https://www.blakeforhouse36.com/about',
  'https://www.blakeforhouse36.com/',
  'Blake Townsend lives in West Jordan. He earned a degree in political science from Utah State University. He began his career in technology recruiting and now works in the nonprofit labor sector.'),
 ('c706334f-a803-4aed-8fe1-6dd704d076c1', -66000168, 'Jennifer K. Doud', '680213cd-e5f8-4b0b-a15d-600229e8d29e',
  NULL, NULL, NULL, NULL),
 ('16a7fe4c-4410-42e3-83e9-3ece4f88608b', -66000169, 'Julie Smith', 'b4a3b10c-b827-4d57-b7d2-29a448fd4296',
  'Campaign photo, juliesmith4utah.com home page (Google Sites image; candidate campaign, press_use) — 1280x941 source, cropped 4:5',
  'https://www.juliesmith4utah.com/',
  'https://www.juliesmith4utah.com/',
  'Julie Smith is a U.S. history teacher.'),
 ('22932c75-aa30-4654-bfec-7f4433c708d2', -66000170, 'Alan Wessman', '2dc31910-c8b1-4966-8091-4320d8f69548',
  'Campaign headshot, electawessman.com home page (Wessman-headshot.jpeg; candidate campaign, press_use) — 1031x1031 source, cropped 4:5',
  'https://electawessman.com/',
  'https://electawessman.com/',
  'Alan Wessman has lived in Spanish Fork for 20 years. He works as a software engineer for a cybersecurity firm. He earned bachelor''s and master''s degrees in computer science from Brigham Young University.');

-- bucket URL derived from politician_id, so it always matches what was uploaded
CREATE TEMP VIEW _profx AS
  SELECT *,
    'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/'
      || politician_id || '-headshot.jpg' AS bucket_url
  FROM _prof;

-- ── pre-flight gate ──────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM _prof; IF n <> 11 THEN RAISE EXCEPTION 'aborting: % profile rows, expected 11', n; END IF;
  SELECT count(*) INTO n FROM _prof WHERE portrait_lic IS NOT NULL; IF n <> 9 THEN RAISE EXCEPTION 'aborting: % portraits, expected 9', n; END IF;
  SELECT count(*) INTO n FROM _prof WHERE website IS NOT NULL;      IF n <> 7 THEN RAISE EXCEPTION 'aborting: % websites, expected 7', n; END IF;
  SELECT count(*) INTO n FROM _prof WHERE bio IS NOT NULL;          IF n <> 8 THEN RAISE EXCEPTION 'aborting: % bios, expected 8', n; END IF;

  -- every row is the CA_0253 politician we think it is (id + external_id + name), still active, not an incumbent
  SELECT count(*) INTO n FROM _prof t
  JOIN essentials.politicians p
    ON p.id = t.politician_id AND p.external_id = t.external_id AND p.full_name = t.full_name
   AND p.is_active AND NOT p.is_incumbent AND p.source LIKE 'CA_0253 (2026-09-24):%';
  IF n <> 11 THEN RAISE EXCEPTION 'aborting: only % of 11 politicians match id/external_id/name/CA_0253', n; END IF;

  -- every race_candidate is this person's live row on the 2026-11-03 Utah general
  SELECT count(*) INTO n FROM _prof t
  JOIN essentials.race_candidates rc ON rc.id = t.rc_id AND rc.politician_id = t.politician_id
  JOIN essentials.races r ON r.id = rc.race_id
  WHERE r.election_id = '1f4a8e7e-cf91-438a-8b1d-b2c944b97aea'
    AND essentials.is_live_candidate(rc.candidate_status, rc.result);
  IF n <> 11 THEN RAISE EXCEPTION 'aborting: only % of 11 race_candidates are the live 2026 Utah general row', n; END IF;

  -- never touch a hand-locked portrait or bio
  SELECT count(*) INTO n FROM _prof t JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE (t.portrait_lic IS NOT NULL AND p.photo_custom_url_manual_override IS TRUE)
      OR (t.bio IS NOT NULL AND p.bio_text_manual_override IS TRUE);
  IF n <> 0 THEN RAISE EXCEPTION 'aborting: % target(s) are manual-override locked', n; END IF;

  RAISE NOTICE 'CA_0268 pre-flight OK';
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
-- The race_candidate_mirror_data trigger fires on these UPDATEs; it writes nothing here, because steps 1-2 already
-- gave each person an image, a photo_custom_url and urls.
UPDATE essentials.race_candidates rc
SET photo_url = x.bucket_url, updated_at = now()
FROM _profx x
WHERE rc.id = x.rc_id
  AND x.portrait_lic IS NOT NULL
  AND coalesce(rc.photo_url, '') = '';

UPDATE essentials.race_candidates rc
SET website_url = t.website, updated_at = now()
FROM _prof t
WHERE rc.id = t.rc_id
  AND t.website IS NOT NULL
  AND coalesce(rc.website_url, '') = '';

-- ── post-verify gate ───────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM _profx x
  JOIN essentials.politician_images pi ON pi.politician_id = x.politician_id AND pi.url = x.bucket_url
  WHERE x.portrait_lic IS NOT NULL;
  IF n <> 9 THEN RAISE EXCEPTION 'expected 9 portrait image rows, found %', n; END IF;
  -- exactly one image each (the mirror trigger added none)
  SELECT count(*) INTO n FROM _prof t JOIN essentials.politician_images pi ON pi.politician_id = t.politician_id;
  IF n <> 9 THEN RAISE EXCEPTION 'expected 9 image rows across the 11 people, found %', n; END IF;

  SELECT count(*) INTO n FROM _profx x
  JOIN essentials.politicians p ON p.id = x.politician_id
  WHERE x.portrait_lic IS NOT NULL AND p.photo_custom_url = x.bucket_url AND p.photo_origin_url = x.portrait_src;
  IF n <> 9 THEN RAISE EXCEPTION 'expected 9 photo_custom_url/photo_origin_url pairs, found %', n; END IF;

  -- HAS_RENDERABLE_PHOTO_SQL (verbatim shape from backend/src/lib/photoCoverage.ts)
  SELECT count(DISTINCT p.id) INTO n FROM _prof t
  JOIN essentials.politicians p ON p.id = t.politician_id
  LEFT JOIN essentials.politician_images img ON img.politician_id = p.id
  WHERE t.portrait_lic IS NOT NULL
    AND ( img.politician_id IS NOT NULL
       OR btrim(coalesce(p.photo_custom_url, '')) <> ''
       OR (btrim(coalesce(p.photo_origin_url, '')) <> '' AND p.photo_origin_url LIKE 'http%') );
  IF n <> 9 THEN RAISE EXCEPTION 'only % of 9 satisfy HAS_RENDERABLE_PHOTO_SQL', n; END IF;

  SELECT count(*) INTO n FROM _prof t JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE t.website IS NOT NULL AND p.urls = ARRAY[t.website];
  IF n <> 7 THEN RAISE EXCEPTION 'expected 7 politicians with the website, found %', n; END IF;

  SELECT count(*) INTO n FROM _prof t JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE t.bio IS NOT NULL AND p.bio_text = t.bio;
  IF n <> 8 THEN RAISE EXCEPTION 'expected 8 bios, found %', n; END IF;

  SELECT count(*) INTO n FROM _profx x JOIN essentials.race_candidates rc ON rc.id = x.rc_id
  WHERE x.portrait_lic IS NOT NULL AND rc.photo_url = x.bucket_url;
  IF n <> 9 THEN RAISE EXCEPTION 'expected 9 race_candidate.photo_url set, found %', n; END IF;

  SELECT count(*) INTO n FROM _prof t JOIN essentials.race_candidates rc ON rc.id = t.rc_id
  WHERE t.website IS NOT NULL AND rc.website_url = t.website;
  IF n <> 7 THEN RAISE EXCEPTION 'expected 7 race_candidate.website_url set, found %', n; END IF;

  -- the honest blanks stay blank (Beglarian, Doud: nothing; Poe: portrait only; Andersen: no website)
  SELECT count(*) INTO n FROM _prof t
  JOIN essentials.politicians p ON p.id = t.politician_id
  JOIN essentials.race_candidates rc ON rc.id = t.rc_id
  WHERE (t.portrait_lic IS NULL AND (p.photo_custom_url IS NOT NULL OR rc.photo_url IS NOT NULL))
     OR (t.website IS NULL AND (coalesce(array_length(p.urls, 1), 0) > 0 OR rc.website_url IS NOT NULL))
     OR (t.bio IS NULL AND p.bio_text IS NOT NULL);
  IF n <> 0 THEN RAISE EXCEPTION 'expected blanks to stay blank, % row(s) have a field set', n; END IF;

  RAISE NOTICE 'ok CA_0268: 9 portraits renderable, 7 websites, 8 bios, card mirrored';
END $$;

COMMIT;
