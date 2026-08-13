-- 1733_pr_alcalde_headshots.sql
--
-- The first 8 portraits for the 78 municipio alcaldes seated by migration 1728. Every one of
-- the 78 had NO photograph of any kind (politician_images 0, photo_custom_url 0,
-- photo_origin_url 0) — re-confirmed against prod immediately before this wave, not carried
-- forward from the todo.
--
-- THIS COHORT HAS NO CONSOLIDATED SOURCE, and that is a property of the data, not a crawler
-- failure. Both mayors' associations are behind login walls; pr.gov's municipio directory
-- publishes escudos, flags and maps but no portraits; only 4 of 78 municipios hold a .gov
-- domain. The verified negatives are recorded in
-- .planning/todos/2026-08-13-pr-alcalde-headshots.md — do not re-hunt them.
--
-- The 8 written here, and why each is trustworthy:
--   Commons, "Public domain / Government of Puerto Rico", credited to the official source —
--     Humacao (senado.pr.gov), San Juan (sanjuan.pr), Gurabo (desarrollo.gurabopr.net).
--     Licenses were READ from the Commons API extmetadata, not assumed from the domain.
--   Ballotpedia S3 — Mayagüez and Ponce, the two that pass a filename-vs-surname guard.
--   The municipality's own alcalde page — Caguas, Naranjito, Guaynabo.
--
-- 🔴 BALLOTPEDIA'S FIRST-IMAGE-ON-PAGE IS THE WRONG PERSON 8 TIMES IN 12 on this cohort: on a
-- BP page that image is often another candidate in the same race (Caguas's mayor resolved to
-- RobertoLopez.jpe). Only 4 of the 12 survive a filename guard and only 2 of those are used
-- here. data/pr-alcaldes/ballotpedia-probe.json's `img` field is NOT trustworthy.
--
-- 🔴 THE TWO-SURNAME TRAP FIRED AGAIN, THREE TIMES. An es.wikipedia sweep scored article
-- titles by surname-token overlap and confidently returned, for three of our alcaldes, three
-- entirely different sitting officials:
--     Carolina  José Carlos Aponte Dalmau   -> "José Luis Dalmau"        (Senate president)
--     Coamo     Juan Carlos García Padilla  -> "Alejandro García Padilla" (former GOVERNOR)
--     Toa Baja  Bernardo Márquez García     -> "José Bernardo Márquez"    (House rep, MVC)
-- Two matching surname tokens is NOT a match when Spanish names carry two surnames drawn from
-- a small pool. All three were dropped. Do not lower that bar.
--
-- 🔴 BAYAMÓN IS A VERIFIED NEGATIVE, not a pending win. The earlier note ("256x256, found on
-- the first pass, re-check") did not reproduce; no such file exists. What the site and Commons
-- actually hold for Ramón Luis Rivera Cruz is: the "Mensaje del Alcalde" letter (a text
-- document), one masked-face photo filed twice, a slideshow banner with his biography set in
-- type over it, a mid-speech podium shot, and Commons' Pedro_P._Ramon_R..jpg — two men at a
-- window, faces in profile. Its FILENAME was the tell, as with Ballotpedia.
-- Separately: bayamonpr.gov IS IN THE CISA .gov REGISTRY BUT HAS NO DNS AT ALL
-- (getaddrinfo failed). Registry presence is not a resolvable host. Bayamón's live site is
-- municipiodebayamon.com.
--
-- Every candidate went on a contact sheet and was looked at before selection, which is the
-- only detector that has ever caught this class of defect. Two upgrades came out of that pass:
-- Humacao moved from the BP image to the Commons official portrait (upscale 3.12x -> 1.99x),
-- and San Juan to Commons' already-cropped head-and-shoulders version (1536x2048, no upscale).
-- Gurabo is a NEW municipio, one Ballotpedia had resolved to Noel Colón García.
--
-- Caguas is knowingly soft: its only source is a genuinely 200x300 file from 2019, so 4.69x
-- upscaling is unavoidable. Accepted deliberately — the seat has been his since 2017 and a
-- soft correct face beats a grey placeholder. Replace it if a better source appears.
--
-- Images are mirrored to storage as politician_photos/<pid>-headshot.jpg (600x750, 4:5,
-- face-anchored via a cascade that only LOCATES; composition was reviewed by eye). Every one
-- was read back through the public CDN asserting HTTP 200 + JPEG magic bytes + identical
-- byte length before this migration was written.
--
-- Sets BOTH photo_custom_url and photo_origin_url on purpose. The read path is
-- COALESCE(photo_custom_url, photo_origin_url, '') — writing only the origin (a source PAGE,
-- not an image) makes the portrait render broken, the defect migration 1475 Part B repaired
-- for 48 Wisconsin profiles.
--
-- Remaining gap after this: 70 of 78. Next steps in the todo.
--
-- Idempotent: re-running inserts nothing and updates nothing.

BEGIN;

CREATE TEMP TABLE _pr_alcalde_headshots (
  politician_id uuid PRIMARY KEY,
  municipio     text NOT NULL,
  bucket_url    text NOT NULL,
  source_page   text NOT NULL,
  license       text NOT NULL
) ON COMMIT DROP;

INSERT INTO _pr_alcalde_headshots (politician_id, municipio, bucket_url, source_page, license) VALUES
  ('fc29e15f-f4eb-4683-bdb7-14d15f3d7dac'::uuid, 'Humacao',   'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fc29e15f-f4eb-4683-bdb7-14d15f3d7dac-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Rosamar_Trujillo_Plumey.jpg', 'public_domain'),
  ('5e9951d6-8108-4cf1-bfe9-092fe3ebe23e'::uuid, 'San Juan',  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5e9951d6-8108-4cf1-bfe9-092fe3ebe23e-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Alcalde_Miguel_Romero_Lugo_(cropped).jpg', 'public_domain'),
  ('d873644c-789f-4b29-8ccd-d4a563827aa0'::uuid, 'Gurabo',    'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d873644c-789f-4b29-8ccd-d4a563827aa0-headshot.jpg', 'https://commons.wikimedia.org/wiki/File:Alcaldesa_Rosachely_Rivera_Santana.jpg', 'public_domain'),
  ('4ef7d70e-bc94-495a-8391-4584cb9e81df'::uuid, 'Mayagüez',  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4ef7d70e-bc94-495a-8391-4584cb9e81df-headshot.jpg', 'https://ballotpedia.org/Jorge_Luis_Ramos_Ruiz', 'press_use'),
  ('338a196f-6cbb-49e8-a08b-79f9c36c46e9'::uuid, 'Ponce',     'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/338a196f-6cbb-49e8-a08b-79f9c36c46e9-headshot.jpg', 'https://ballotpedia.org/Marlese_Sifre', 'press_use'),
  ('3e62dcc4-d036-4d7d-becd-701c706840b0'::uuid, 'Caguas',    'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3e62dcc4-d036-4d7d-becd-701c706840b0-headshot.jpg', 'https://caguas.gov.pr/hon-william-e-miranda-torres-alcalde/', 'press_use'),
  ('ccee89e6-7a44-4127-a198-44d27aaac874'::uuid, 'Naranjito', 'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ccee89e6-7a44-4127-a198-44d27aaac874-headshot.jpg', 'https://municipiodenaranjito.com/', 'press_use'),
  ('044bbc32-2a8b-4dc2-ae34-ec2589a95cf9'::uuid, 'Guaynabo',  'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/044bbc32-2a8b-4dc2-ae34-ec2589a95cf9-headshot.jpg', 'https://www.guaynabocity.gov.pr/oficina-del-alcalde/', 'press_use');

-- Refuse to run against a shifted roster rather than seating a face on the wrong person.
DO $$
DECLARE n_missing int; n_override int; n_notpr int; n_wrongseat int;
BEGIN
  SELECT count(*) INTO n_missing
  FROM _pr_alcalde_headshots t
  LEFT JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE p.id IS NULL;
  IF n_missing <> 0 THEN
    RAISE EXCEPTION 'aborting: % of 8 target politicians no longer exist', n_missing;
  END IF;

  -- Every target must still be in the PR external_id band. If one is not, the roster has
  -- been re-seeded and these pids mean something else now.
  SELECT count(*) INTO n_notpr
  FROM _pr_alcalde_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE p.external_id::text NOT LIKE '-72%';
  IF n_notpr <> 0 THEN
    RAISE EXCEPTION 'aborting: % target(s) are outside the PR -72xxxxx band', n_notpr;
  END IF;

  -- The face and the seat must agree. Each pid must currently hold the LOCAL_EXEC office
  -- for the municipio the photo was sourced for — resolved by office, never by name, since
  -- Florida and San Sebastián resolve off-island. This is the guard that would have caught
  -- the three wrong-person es.wikipedia matches had they not been dropped by hand.
  SELECT count(*) INTO n_wrongseat
  FROM _pr_alcalde_headshots t
  WHERE NOT EXISTS (
    SELECT 1
    FROM essentials.office_current_holder och
    JOIN essentials.offices o   ON o.id = och.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    WHERE och.politician_id = t.politician_id
      AND d.district_type = 'LOCAL_EXEC'
      AND lower(d.state) = 'pr'
      AND d.label = t.municipio || ' Mayor'
  );
  IF n_wrongseat <> 0 THEN
    RAISE EXCEPTION 'aborting: % target(s) do not hold the municipio seat named alongside them', n_wrongseat;
  END IF;

  -- mig 192 / D-08: a hand-picked portrait outranks anything a sweep produces.
  SELECT count(*) INTO n_override
  FROM _pr_alcalde_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE p.photo_custom_url_manual_override IS TRUE;
  IF n_override <> 0 THEN
    RAISE EXCEPTION 'aborting: % target(s) carry photo_custom_url_manual_override', n_override;
  END IF;
END $$;

INSERT INTO essentials.politician_images (politician_id, url, type, photo_license)
SELECT t.politician_id, t.bucket_url, 'default', t.license
FROM _pr_alcalde_headshots t
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images pi
  WHERE pi.politician_id = t.politician_id AND pi.url = t.bucket_url
);

UPDATE essentials.politicians p
SET photo_custom_url = t.bucket_url,
    photo_origin_url = t.source_page
FROM _pr_alcalde_headshots t
WHERE p.id = t.politician_id
  AND p.photo_custom_url_manual_override IS NOT TRUE
  AND (p.photo_custom_url IS DISTINCT FROM t.bucket_url
    OR p.photo_origin_url IS DISTINCT FROM t.source_page);

-- Post-verify. RAISE EXCEPTION on any wrong count.
DO $$
DECLARE n_img int; n_custom int; n_renderable int; n_bad_origin int; n_seated int;
        n_lic int; n_still_bare int;
BEGIN
  SELECT count(*) INTO n_img
  FROM _pr_alcalde_headshots t
  JOIN essentials.politician_images pi
    ON pi.politician_id = t.politician_id AND pi.url = t.bucket_url
  WHERE pi.type = 'default';
  IF n_img <> 8 THEN
    RAISE EXCEPTION 'expected 8 politician_images rows, found %', n_img;
  END IF;

  -- License must be documented, never blank. Only the two vocabulary values this wave uses.
  SELECT count(*) INTO n_lic
  FROM _pr_alcalde_headshots t
  JOIN essentials.politician_images pi
    ON pi.politician_id = t.politician_id AND pi.url = t.bucket_url
  WHERE pi.photo_license IN ('public_domain', 'press_use');
  IF n_lic <> 8 THEN
    RAISE EXCEPTION 'expected 8 documented licenses, found %', n_lic;
  END IF;

  SELECT count(*) INTO n_custom
  FROM _pr_alcalde_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE p.photo_custom_url = t.bucket_url
    AND p.photo_custom_url LIKE '%storage.supabase.co%';
  IF n_custom <> 8 THEN
    RAISE EXCEPTION 'expected 8 rows with photo_custom_url on the bucket, found %', n_custom;
  END IF;

  -- HAS_RENDERABLE_PHOTO_SQL, copied from backend/src/lib/photoCoverage.ts so this
  -- migration cannot disagree with the platform's own coverage numbers.
  SELECT count(*) INTO n_renderable
  FROM _pr_alcalde_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  LEFT JOIN essentials.politician_images img ON img.politician_id = p.id
  WHERE ( img.politician_id IS NOT NULL
       OR btrim(coalesce(p.photo_custom_url, '')) <> ''
       OR (btrim(coalesce(p.photo_origin_url, '')) <> '' AND p.photo_origin_url LIKE 'http%') );
  IF n_renderable < 8 THEN
    RAISE EXCEPTION 'only % of 8 satisfy HAS_RENDERABLE_PHOTO_SQL', n_renderable;
  END IF;

  -- photo_origin_url is a research scratchpad elsewhere in this table (mig 1688 cleaned
  -- 148 breadcrumbs out of it). Every value this migration writes must be a real URL.
  SELECT count(*) INTO n_bad_origin
  FROM _pr_alcalde_headshots t
  JOIN essentials.politicians p ON p.id = t.politician_id
  WHERE p.photo_origin_url NOT LIKE 'http%';
  IF n_bad_origin <> 0 THEN
    RAISE EXCEPTION '% origin url(s) are not http', n_bad_origin;
  END IF;

  -- A portrait is only useful if the person still holds a seat. office_current_holder
  -- LEFT JOINs from offices, so a vacancy is a NULL politician_id and a bare count(*)
  -- would pass vacuously — hence the IS NOT NULL.
  SELECT count(*) INTO n_seated
  FROM _pr_alcalde_headshots t
  JOIN essentials.office_current_holder och ON och.politician_id = t.politician_id
  WHERE och.politician_id IS NOT NULL;
  IF n_seated <> 8 THEN
    RAISE EXCEPTION 'expected 8 still seated, found %', n_seated;
  END IF;

  -- End state, not the delta: exactly 70 of the 78 alcaldes must remain with no photograph
  -- of any kind. A number below 70 means something outside this wave also wrote portraits;
  -- above 70 means one of these 8 did not land.
  SELECT count(*) INTO n_still_bare
  FROM essentials.offices o
  JOIN essentials.districts d ON d.id = o.district_id
  JOIN essentials.office_current_holder och ON och.office_id = o.id
  JOIN essentials.politicians p ON p.id = och.politician_id
  WHERE d.district_type = 'LOCAL_EXEC'
    AND lower(d.state) = 'pr'
    AND och.politician_id IS NOT NULL
    AND btrim(coalesce(p.photo_custom_url, '')) = ''
    AND btrim(coalesce(p.photo_origin_url, '')) = ''
    AND NOT EXISTS (
      SELECT 1 FROM essentials.politician_images pi WHERE pi.politician_id = p.id
    );
  IF n_still_bare <> 70 THEN
    RAISE EXCEPTION 'expected 70 of 78 alcaldes still without any photo, found %', n_still_bare;
  END IF;

  RAISE NOTICE 'ok: 8 PR alcaldes renderable (% images, % custom urls, % seated); % of 78 remain bare',
    n_img, n_custom, n_seated, n_still_bare;
END $$;

COMMIT;
