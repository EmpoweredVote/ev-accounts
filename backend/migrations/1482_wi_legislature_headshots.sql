-- Migration 1482: Wisconsin State Legislature headshots (AUDIT-ONLY)
--
-- AUDIT-ONLY, matching the 1054 (NV legislature) precedent: applied via the SQL exec path AFTER the
-- gitignored pipeline (_tmp-wi-legislature-headshots.py) downloads each official portrait, crops to
-- 4:5, resizes to 600x750 Lanczos q90, and uploads to the politician_photos Storage bucket.
--
-- 132 sitting WI legislators (99 Assembly + 33 Senate). All 132 files uploaded to Storage.
--   56 from the member's own legis.wisconsin.gov site (Umbraco media at ?width=1600)
--   76 from the official docs.legis roster portrait (150x200 source, ~4x upscale — visibly softer)
--
-- Why the split: filename-based portrait discovery on member sites had a 29% defect rate (23 of 79
-- hits were signature graphics, district wordmarks, family photos, or press-conference shots). Those
-- 23 were rejected by visual inspection of contact sheets and fall back to the roster portrait, which
-- is always a genuine tight headshot of the right person. The reject list, with a reason and the
-- offending source filename per seat, is tracked at
-- data/stance-research/wi-2026-state-leg/wi-headshot-visual-rejects.json and is read by
-- scripts/discover-wi-legis-portraits.mjs.
--
-- Correct-person guard: every seat was matched on (chamber, district) via office_current_holder and
-- confirmed on FIRST AND LAST name against the official roster — 132/132.
-- One documented override: Assembly 55, where prod holds "Gus Gustafson" but the official roster and
-- his own page say "Nate L. Gustafson" (district + surname + party agree; prod's first name looks
-- wrong). The photo is correct; prod's NAME is a separate data fix and is NOT changed here.
--
-- Columns are exactly (id, politician_id, url, type, photo_license); type='default'.
-- photo_license = 'us_government_work' (state-legislature official portraits), matching mig 1054.
-- politician_id is resolved by the stable external_id — never a hardcoded UUID.
-- Each INSERT is idempotent via NOT EXISTS on (politician_id, type='default'), so the one legislator
-- who already had an image (Assembly 44, Ann Roe) is left untouched.
-- focal_point is deliberately NOT set: the official focal point was already applied at crop time, so
-- storing it again would double-apply the offset.

-- Assembly District 82 — Scott Allen
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506082),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f08a79e9-42fe-4047-b7b1-ba5da9b31018-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506082)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'http://legis.wisconsin.gov/assembly/82/allen'
 WHERE external_id = -5506082 AND photo_origin_url IS NULL;

-- Assembly District 45 — Clint Anderson
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506045),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ad36a437-2193-4725-806b-d9d678579f00-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506045)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/assembly/45/anderson'
 WHERE external_id = -5506045 AND photo_origin_url IS NULL;

-- Assembly District 23 — Deb Andraca
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506023),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3736286a-44fb-42ad-8cd0-bcb6a4b985ea-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506023)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/assembly/23/andraca'
 WHERE external_id = -5506023 AND photo_origin_url IS NULL;

-- Assembly District 67 — Dave Armstrong
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506067),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/374fcadb-a124-4a02-b529-5a63ec494bbf-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506067)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/assembly/67/armstrong'
 WHERE external_id = -5506067 AND photo_origin_url IS NULL;

-- Assembly District 18 — Margaret Arney
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506018),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fc46160a-cc85-44b2-a28b-dc7a40a37e8c-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506018)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/assembly/18/arney'
 WHERE external_id = -5506018 AND photo_origin_url IS NULL;

-- Assembly District 31 — Tyler August [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506031),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dfa3c0a6-c750-4b80-9b60-34689836ad32-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506031)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2853'
 WHERE external_id = -5506031 AND photo_origin_url IS NULL;

-- Assembly District 80 — Mike Bare [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506080),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/79760db0-6741-4290-b4ab-b0de68df3ed3-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506080)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2712'
 WHERE external_id = -5506080 AND photo_origin_url IS NULL;

-- Assembly District 6 — Elijah Behnke
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506006),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d68b3730-048f-4cb5-a952-104dd75409df-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506006)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/assembly/06/behnke'
 WHERE external_id = -5506006 AND photo_origin_url IS NULL;

-- Assembly District 95 — Jill Billings [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506095),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7b6ec364-24fc-446e-91e2-617c91d14b8f-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506095)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2714'
 WHERE external_id = -5506095 AND photo_origin_url IS NULL;

-- Assembly District 37 — Mark Born
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506037),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1351c459-aa30-45bb-abe9-feca27e78d92-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506037)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'http://legis.wisconsin.gov/assembly/37/born'
 WHERE external_id = -5506037 AND photo_origin_url IS NULL;

-- Assembly District 27 — Lindee Brill [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506027),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a5f74fc0-4809-40e6-b52f-0bd1e2e86fc5-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506027)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2884'
 WHERE external_id = -5506027 AND photo_origin_url IS NULL;

-- Assembly District 59 — Rob Brooks
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506059),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9419fa91-b7e4-48df-a00b-fc10d225f321-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506059)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'http://legis.wisconsin.gov/assembly/59/brooks'
 WHERE external_id = -5506059 AND photo_origin_url IS NULL;

-- Assembly District 43 — Brienne Brown [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506043),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/77707b96-8245-4013-843c-12181ad35ff8-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506043)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2888'
 WHERE external_id = -5506043 AND photo_origin_url IS NULL;

-- Assembly District 35 — Calvin Callahan
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506035),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1073fd5c-0bac-4f03-8254-892351795937-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506035)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/assembly/35/callahan'
 WHERE external_id = -5506035 AND photo_origin_url IS NULL;

-- Assembly District 19 — Ryan Clancy [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506019),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0207b7d2-1195-4672-bb1e-767b00d3f6e4-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506019)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2721'
 WHERE external_id = -5506019 AND photo_origin_url IS NULL;

-- Assembly District 62 — Angelina Cruz [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506062),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/11c8f424-55d1-4e28-b297-d6a670a033d6-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506062)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2893'
 WHERE external_id = -5506062 AND photo_origin_url IS NULL;

-- Assembly District 39 — Alex Dallman
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506039),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/20411352-5cd8-49fe-9510-838900689b6a-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506039)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/assembly/39/dallman'
 WHERE external_id = -5506039 AND photo_origin_url IS NULL;

-- Assembly District 40 — Karen DeSanto
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506040),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5277f1a1-99be-4736-8096-07f36833a5cb-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506040)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/assembly/40/desanto'
 WHERE external_id = -5506040 AND photo_origin_url IS NULL;

-- Assembly District 65 — Ben DeSmidt [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506065),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1646f089-0f51-45f8-b893-c5886a0e1a69-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506065)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2894'
 WHERE external_id = -5506065 AND photo_origin_url IS NULL;

-- Assembly District 99 — Barbara Dittrich
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506099),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/81359937-26c3-4cda-a621-c678457c85a6-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506099)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'http://legis.wisconsin.gov/assembly/99/Dittrich'
 WHERE external_id = -5506099 AND photo_origin_url IS NULL;

-- Assembly District 61 — Bob Donovan [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506061),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c864b687-0f0d-468d-a674-9e72aee3f8f2-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506061)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2864'
 WHERE external_id = -5506061 AND photo_origin_url IS NULL;

-- Assembly District 94 — Steve Doyle
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506094),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d08c31db-7c13-4e19-871d-47c76100867d-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506094)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'http://legis.wisconsin.gov/assembly/94/doyle'
 WHERE external_id = -5506094 AND photo_origin_url IS NULL;

-- Assembly District 97 — Cindi Duchow [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506097),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9fe7f550-979e-47d1-befe-667bbadf3018-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506097)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2876'
 WHERE external_id = -5506097 AND photo_origin_url IS NULL;

-- Assembly District 91 — Jodi Emerson [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506091),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/74f9f4da-7fa4-4b49-899f-ab6ebf7ca1e0-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506091)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2731'
 WHERE external_id = -5506091 AND photo_origin_url IS NULL;

-- Assembly District 46 — Joan Fitzgerald
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506046),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/26902147-6244-4c6e-959b-14a08eb1b56f-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506046)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/assembly/46/fitzgerald'
 WHERE external_id = -5506046 AND photo_origin_url IS NULL;

-- Assembly District 88 — Ben Franklin
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506088),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8edbab4d-f89d-4dc2-b558-00f85f4d349a-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506088)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/assembly/88/franklin'
 WHERE external_id = -5506088 AND photo_origin_url IS NULL;

-- Assembly District 5 — Joy Goeben [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3d9e1ffb-1e2e-445a-a86d-259c630360aa-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506005)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2732'
 WHERE external_id = -5506005 AND photo_origin_url IS NULL;

-- Assembly District 12 — Russell Goodwin [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506012),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cdd84abe-0a61-40bb-ba3f-6bf7fab74ba3-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506012)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2906'
 WHERE external_id = -5506012 AND photo_origin_url IS NULL;

-- Assembly District 74 — Chanz Green [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506074),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5c631466-ba33-4731-89a3-ca017444cf78-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506074)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2734'
 WHERE external_id = -5506074 AND photo_origin_url IS NULL;

-- Assembly District 58 — Rick Gundrum
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506058),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fff18b53-315b-4091-81ca-6f96d881613f-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506058)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'http://legis.wisconsin.gov/assembly/58/gundrum'
 WHERE external_id = -5506058 AND photo_origin_url IS NULL;

-- Assembly District 55 — Gus Gustafson [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506055),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c2a96302-5df2-4f6c-a96a-0a56b466a604-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506055)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2736'
 WHERE external_id = -5506055 AND photo_origin_url IS NULL;

-- Assembly District 16 — Kalan Haywood
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506016),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6d736e91-2652-401c-b642-09de30f22a09-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506016)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'http://legis.wisconsin.gov/assembly/16/haywood'
 WHERE external_id = -5506016 AND photo_origin_url IS NULL;

-- Assembly District 76 — Francesca Hong
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506076),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f1212497-7049-413a-ac19-81c5baba900d-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506076)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/assembly/76/hong'
 WHERE external_id = -5506076 AND photo_origin_url IS NULL;

-- Assembly District 69 — Karen Hurd [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506069),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/86c404da-e255-4944-af23-113ad077092d-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506069)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2868'
 WHERE external_id = -5506069 AND photo_origin_url IS NULL;

-- Assembly District 48 — Andrew Hysell [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506048),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/674b7c37-fd85-46e7-9087-3fefde2666a4-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506048)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2892'
 WHERE external_id = -5506048 AND photo_origin_url IS NULL;

-- Assembly District 87 — Brent Jacobson [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506087),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1adb3e54-9f6d-475c-9c4b-9a499f7a9f29-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506087)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2899'
 WHERE external_id = -5506087 AND photo_origin_url IS NULL;

-- Assembly District 50 — Jenna Jacobson
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506050),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1fbf690b-01c5-4d20-a938-de0c56f2e4a8-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506050)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/assembly/50/jacobson/'
 WHERE external_id = -5506050 AND photo_origin_url IS NULL;

-- Assembly District 81 — Alex Joers [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506081),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8e804443-d7ac-4103-943f-546a76c4c8bf-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506081)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2871'
 WHERE external_id = -5506081 AND photo_origin_url IS NULL;

-- Assembly District 96 — Tara Johnson
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506096),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/94b1866a-cc0a-409a-bd21-367abf8be938-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506096)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/assembly/96/johnson'
 WHERE external_id = -5506096 AND photo_origin_url IS NULL;

-- Assembly District 53 — Dean Kaufert [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506053),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/726ef0a3-e1b4-4bc7-a301-54f4d1d42918-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506053)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2852'
 WHERE external_id = -5506053 AND photo_origin_url IS NULL;

-- Assembly District 7 — Karen Kirsch [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506007),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0543aef9-357e-4337-8cb2-51c2e1531fea-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506007)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2878'
 WHERE external_id = -5506007 AND photo_origin_url IS NULL;

-- Assembly District 1 — Joel Kitchens [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/450a9dfb-a01f-4ad1-b660-517e519c9c0e-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506001)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2744'
 WHERE external_id = -5506001 AND photo_origin_url IS NULL;

-- Assembly District 24 — Dan Knodl [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506024),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5cf0f099-b460-40f4-9e1a-0663315da02d-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506024)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2849'
 WHERE external_id = -5506024 AND photo_origin_url IS NULL;

-- Assembly District 28 — Rob Kreibich [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506028),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6b10e440-3ab9-4e5e-be02-c61616ea4cf0-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506028)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2885'
 WHERE external_id = -5506028 AND photo_origin_url IS NULL;

-- Assembly District 72 — Scott Krug [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506072),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/28d9e7b4-9922-4b53-8def-25f779d2e4d2-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506072)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2745'
 WHERE external_id = -5506072 AND photo_origin_url IS NULL;

-- Assembly District 41 — Tony Kurtz [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506041),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6576be0a-2c3c-403a-b311-7d652b267aec-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506041)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2858'
 WHERE external_id = -5506041 AND photo_origin_url IS NULL;

-- Assembly District 10 — Darrin Madison
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506010),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/aac79124-dd42-4aef-b5a1-73c53ced448f-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506010)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/assembly/10/madison/'
 WHERE external_id = -5506010 AND photo_origin_url IS NULL;

-- Assembly District 83 — Dave Maxey [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506083),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1d1a1f40-a1e4-4208-bdc0-810571bd11a9-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506083)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2873'
 WHERE external_id = -5506083 AND photo_origin_url IS NULL;

-- Assembly District 77 — Renuka Mayadev
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506077),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7d91fee1-7c0c-41e5-b1f2-fa93849c772c-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506077)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/assembly/77/mayadev'
 WHERE external_id = -5506077 AND photo_origin_url IS NULL;

-- Assembly District 42 — Maureen McCarville
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506042),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/21265ed4-0d98-4eb4-b9ea-85821a247d2f-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506042)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/assembly/42/mccarville'
 WHERE external_id = -5506042 AND photo_origin_url IS NULL;

-- Assembly District 64 — Tip McGuire [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506064),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c7f2ee81-9cdc-4b21-8b1b-9a78c75663ac-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506064)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2751'
 WHERE external_id = -5506064 AND photo_origin_url IS NULL;

-- Assembly District 22 — Paul Melotik
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506022),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7c2df740-4334-4ac4-9a4d-3c82031df5fd-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506022)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/assembly/22/melotik/'
 WHERE external_id = -5506022 AND photo_origin_url IS NULL;

-- Assembly District 71 — Vinnie Miresse
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506071),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7c0b6fe8-da1a-45d8-8732-a411915c0d32-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506071)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/assembly/71/miresse'
 WHERE external_id = -5506071 AND photo_origin_url IS NULL;

-- Assembly District 17 — Supreme Moore Omokunde [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506017),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/125031ca-566f-4f10-a25d-80e3a7866da4-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506017)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2754'
 WHERE external_id = -5506017 AND photo_origin_url IS NULL;

-- Assembly District 92 — Clint Moses [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506092),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/aa5b5294-df1a-47dd-bca9-1d7672d29417-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506092)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2875'
 WHERE external_id = -5506092 AND photo_origin_url IS NULL;

-- Assembly District 56 — Dave Murphy
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506056),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3d3b7e41-b4d9-44e9-940e-e65fa85489b7-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506056)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'http://legis.wisconsin.gov/assembly/56/murphy'
 WHERE external_id = -5506056 AND photo_origin_url IS NULL;

-- Assembly District 36 — Jeff Mursau
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506036),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/58b777cf-d5d6-436b-9229-93ab72d783fb-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506036)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'http://legis.wisconsin.gov/assembly/36/mursau/'
 WHERE external_id = -5506036 AND photo_origin_url IS NULL;

-- Assembly District 32 — Amanda Nedweski [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506032),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b4e7d7f1-34fb-468e-9f0a-e9e8975d5397-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506032)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2854'
 WHERE external_id = -5506032 AND photo_origin_url IS NULL;

-- Assembly District 66 — Greta Neubauer
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506066),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4e65b04a-e607-4905-93ef-1e6ec0552fb6-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506066)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/assembly/66/neubauer'
 WHERE external_id = -5506066 AND photo_origin_url IS NULL;

-- Assembly District 15 — Adam Neylon [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506015),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8ec2e2fd-f691-4e2c-8b0b-17563155c843-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506015)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2847'
 WHERE external_id = -5506015 AND photo_origin_url IS NULL;

-- Assembly District 51 — Todd Novak
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506051),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/a84e1f91-5598-46b3-9a90-6d77cf71083c-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506051)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'http://legis.wisconsin.gov/assembly/51/novak'
 WHERE external_id = -5506051 AND photo_origin_url IS NULL;

-- Assembly District 60 — Jerry O'Connor [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506060),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dc5e0433-fd54-4c33-8d2f-f166834fa023-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506060)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2863'
 WHERE external_id = -5506060 AND photo_origin_url IS NULL;

-- Assembly District 8 — Sylvia Ortiz-Velez [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506008),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/546a57e6-05eb-4d59-ae6e-292c886c277a-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506008)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2766'
 WHERE external_id = -5506008 AND photo_origin_url IS NULL;

-- Assembly District 54 — Lori Palmeri [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506054),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5ace10bc-ca43-4165-abf5-c52c5bb1ef01-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506054)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2767'
 WHERE external_id = -5506054 AND photo_origin_url IS NULL;

-- Assembly District 38 — Will Penterman
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506038),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6293d49b-6a86-41c1-9e2e-5f9ec8188924-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506038)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/assembly/38/penterman'
 WHERE external_id = -5506038 AND photo_origin_url IS NULL;

-- Assembly District 57 — Kevin Petersen [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506057),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bfba6969-db1a-4506-8940-530518b6c907-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506057)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2861'
 WHERE external_id = -5506057 AND photo_origin_url IS NULL;

-- Assembly District 93 — Christian Phelps [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506093),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2de7b0f1-8e48-439b-a9ec-5f2b2b3ce90f-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506093)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2903'
 WHERE external_id = -5506093 AND photo_origin_url IS NULL;

-- Assembly District 98 — Jim Piwowarczyk [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506098),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1e6711f8-190e-4edd-a2d7-75584e192ce9-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506098)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2905'
 WHERE external_id = -5506098 AND photo_origin_url IS NULL;

-- Assembly District 9 — Priscilla Prado
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506009),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ea15032b-96a6-4135-bf29-a7e60a2c7153-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506009)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/assembly/09/prado'
 WHERE external_id = -5506009 AND photo_origin_url IS NULL;

-- Assembly District 29 — Treig Pronschinske
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506029),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/59538da9-a7ca-4e7d-a57b-e576c7d66621-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506029)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'http://legis.wisconsin.gov/assembly/29/Pronschinske'
 WHERE external_id = -5506029 AND photo_origin_url IS NULL;

-- Assembly District 90 — Amaad Rivera-Wagner [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506090),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c2eecef6-b969-43d0-9d19-7d048bf412e5-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506090)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2902'
 WHERE external_id = -5506090 AND photo_origin_url IS NULL;

-- Assembly District 21 — Jessie Rodriguez
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506021),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9931d562-9502-474b-bb10-911134b2c0f0-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506021)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'http://legis.wisconsin.gov/assembly/21/rodriguez'
 WHERE external_id = -5506021 AND photo_origin_url IS NULL;

-- Assembly District 44 — Ann Roe [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506044),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/732ee90d-016b-4879-9142-c3583130cf42-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506044)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2889'
 WHERE external_id = -5506044 AND photo_origin_url IS NULL;

-- Assembly District 26 — Joe Sheehan
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506026),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9d545fd6-2ce1-49a1-bf29-ed77bf7b7f06-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506026)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/assembly/26/sheehan'
 WHERE external_id = -5506026 AND photo_origin_url IS NULL;

-- Assembly District 20 — Christine Sinicki [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506020),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1c73491e-50bd-4a4f-ac7b-b8e65acdd2bb-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506020)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2784'
 WHERE external_id = -5506020 AND photo_origin_url IS NULL;

-- Assembly District 52 — Lee Snodgrass
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506052),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/352ced5f-5466-407c-a839-256de6542b8c-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506052)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'http://legis.wisconsin.gov/assembly/52/snodgrass'
 WHERE external_id = -5506052 AND photo_origin_url IS NULL;

-- Assembly District 85 — Pat Snyder [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506085),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f59396a3-66bf-481d-8180-0cf1cfea5280-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506085)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2786'
 WHERE external_id = -5506085 AND photo_origin_url IS NULL;

-- Assembly District 2 — Shae Sortwell [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9f534346-6384-4fac-be10-a040ea62c664-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506002)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2787'
 WHERE external_id = -5506002 AND photo_origin_url IS NULL;

-- Assembly District 89 — Ryan Spaude [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506089),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3ab564b4-5b6e-4c25-8ea1-6d85583ef2bf-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506089)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2901'
 WHERE external_id = -5506089 AND photo_origin_url IS NULL;

-- Assembly District 86 — John Spiros [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506086),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/94794832-a1f2-475f-93eb-2e8d896fd8be-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506086)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2788'
 WHERE external_id = -5506086 AND photo_origin_url IS NULL;

-- Assembly District 4 — David Steffen [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6a2b1e44-55d7-4f9d-b179-d4522bf78e98-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506004)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2789'
 WHERE external_id = -5506004 AND photo_origin_url IS NULL;

-- Assembly District 73 — Angela Stroud
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506073),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4ab2cafc-8eca-4cef-b301-830441a22e75-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506073)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/assembly/73/stroud'
 WHERE external_id = -5506073 AND photo_origin_url IS NULL;

-- Assembly District 78 — Shelia Stubbs
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506078),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/b4c1f85b-4fd7-4faf-9198-1dfcbc955941-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506078)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'http://legis.wisconsin.gov/assembly/78/stubbs'
 WHERE external_id = -5506078 AND photo_origin_url IS NULL;

-- Assembly District 79 — Lisa Subeck [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506079),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dc0e341f-b827-45f7-bcc6-35b8376979b3-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506079)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2870'
 WHERE external_id = -5506079 AND photo_origin_url IS NULL;

-- Assembly District 68 — Rob Summerfield
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506068),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fa25d156-89a7-4a29-ade3-e55688cfcee5-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506068)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'http://legis.wisconsin.gov/assembly/68/summerfield'
 WHERE external_id = -5506068 AND photo_origin_url IS NULL;

-- Assembly District 34 — Rob Swearingen
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506034),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0404c82e-7503-4b12-b44d-49d2c990a5a9-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506034)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'http://legis.wisconsin.gov/assembly/34/swearingen'
 WHERE external_id = -5506034 AND photo_origin_url IS NULL;

-- Assembly District 11 — Sequanna Taylor [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506011),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3afc572b-7a49-4cb8-9edd-b57c936cea7b-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506011)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2880'
 WHERE external_id = -5506011 AND photo_origin_url IS NULL;

-- Assembly District 14 — Angelito Tenorio [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506014),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/57f9eb3c-0554-43ed-b93b-c1ecfbb269fe-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506014)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2881'
 WHERE external_id = -5506014 AND photo_origin_url IS NULL;

-- Assembly District 25 — Paul Tittl [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506025),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0d122b39-f293-465a-8d3c-bfde10471705-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506025)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2794'
 WHERE external_id = -5506025 AND photo_origin_url IS NULL;

-- Assembly District 49 — Travis Tranel [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506049),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/99444f5f-9093-4d8a-b7bd-1fb6a4157409-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506049)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2795'
 WHERE external_id = -5506049 AND photo_origin_url IS NULL;

-- Assembly District 75 — Duke Tucker [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506075),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/00d0e0fc-ac5d-4610-bf25-d858a85a4b80-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506075)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2897'
 WHERE external_id = -5506075 AND photo_origin_url IS NULL;

-- Assembly District 3 — Ron Tusler [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/62d727b1-8ea6-4607-8759-1db943de2c05-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506003)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2796'
 WHERE external_id = -5506003 AND photo_origin_url IS NULL;

-- Assembly District 47 — Randy Udell [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506047),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/79744617-8efa-439f-86fe-b13c253c6cdb-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506047)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2891'
 WHERE external_id = -5506047 AND photo_origin_url IS NULL;

-- Assembly District 70 — Nancy VanderMeer [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506070),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cff417b2-5774-4295-beac-151d5015feb6-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506070)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2797'
 WHERE external_id = -5506070 AND photo_origin_url IS NULL;

-- Assembly District 13 — Robyn Vining [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506013),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/99443b59-c422-43c4-98ba-070cc2c97491-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506013)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2846'
 WHERE external_id = -5506013 AND photo_origin_url IS NULL;

-- Assembly District 33 — Robin Vos [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506033),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/07e3c239-1edf-47c5-8666-cdc7b8ef52ae-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506033)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2844'
 WHERE external_id = -5506033 AND photo_origin_url IS NULL;

-- Assembly District 84 — Chuck Wichgers [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506084),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3db74c79-d91c-4bfb-9d1e-7cfc022cde25-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506084)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2874'
 WHERE external_id = -5506084 AND photo_origin_url IS NULL;

-- Assembly District 63 — Bob Wittke [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506063),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7c8a7cd3-ac60-4292-81c8-11f1946fb9e0-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506063)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/assembly/2865'
 WHERE external_id = -5506063 AND photo_origin_url IS NULL;

-- Assembly District 30 — Shannon Zimmerman
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5506030),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/842f6e36-3ffa-423c-b445-f38f63060de6-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5506030)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'http://legis.wisconsin.gov/assembly/30/zimmerman'
 WHERE external_id = -5506030 AND photo_origin_url IS NULL;

-- Senate District 28 — Julian Bradley
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505028),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7fdcb712-d201-49d4-9d2b-c28bfa780702-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505028)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/senate/28/bradley'
 WHERE external_id = -5505028 AND photo_origin_url IS NULL;

-- Senate District 19 — Rachael Cabral-Guevara
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505019),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/1cdcaa5d-8576-44d4-8d9f-34f321924898-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505019)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/senate/19/cabral-guevara'
 WHERE external_id = -5505019 AND photo_origin_url IS NULL;

-- Senate District 3 — Tim Carpenter [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505003),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/5130ee75-9b4e-4095-8a78-245f7402d287-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505003)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/senate/2807'
 WHERE external_id = -5505003 AND photo_origin_url IS NULL;

-- Senate District 18 — Kristin Dassler-Alfheim [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505018),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/41359981-e7a3-4d8f-820a-c1a42f4e395a-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505018)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/senate/2841'
 WHERE external_id = -5505018 AND photo_origin_url IS NULL;

-- Senate District 4 — Dora Drake
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505004),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c52c5db1-44b8-4658-b0d3-07406c63366e-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505004)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/senate/04/drake'
 WHERE external_id = -5505004 AND photo_origin_url IS NULL;

-- Senate District 12 — Mary Felzkowski [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505012),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d36c9fc0-3aef-4cb7-8e0f-e8d7a4f5576b-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505012)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/senate/2809'
 WHERE external_id = -5505012 AND photo_origin_url IS NULL;

-- Senate District 20 — Dan Feyen [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505020),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8ebb711d-55b2-49f6-ad4c-ea9c0ff066ca-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505020)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/senate/2838'
 WHERE external_id = -5505020 AND photo_origin_url IS NULL;

-- Senate District 8 — Jodi Habush Sinykin
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505008),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/dc8045d4-65e6-4b35-a0ec-ce410b091649-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505008)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/senate/08/habush-sinykin'
 WHERE external_id = -5505008 AND photo_origin_url IS NULL;

-- Senate District 27 — Dianne Hesselbein [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505027),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/171dbfaa-58dd-45f4-8526-231d78530461-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505027)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/senate/2811'
 WHERE external_id = -5505027 AND photo_origin_url IS NULL;

-- Senate District 5 — Rob Hutton [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505005),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/80dec07a-0ae9-4512-8d04-4134c11a4af1-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505005)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/senate/2812'
 WHERE external_id = -5505005 AND photo_origin_url IS NULL;

-- Senate District 1 — André Jacque [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505001),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/d677bfee-6bc5-4ad1-bb6a-fb6e5b6fe284-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505001)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/senate/2813'
 WHERE external_id = -5505001 AND photo_origin_url IS NULL;

-- Senate District 13 — John Jagler
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505013),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6500d1e2-b7f3-4df4-9ca9-c973d91dd573-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505013)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/senate/13/jagler'
 WHERE external_id = -5505013 AND photo_origin_url IS NULL;

-- Senate District 23 — Jesse James
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505023),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/36251ed2-2cbb-4450-92d5-c95b1a5aa808-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505023)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/senate/23/james'
 WHERE external_id = -5505023 AND photo_origin_url IS NULL;

-- Senate District 6 — LaTonya Johnson
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505006),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/7660721c-b379-48ea-a286-f6ce60a22af4-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505006)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'http://legis.wisconsin.gov/senate/06/johnson'
 WHERE external_id = -5505006 AND photo_origin_url IS NULL;

-- Senate District 33 — Chris Kapenga [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505033),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/fc2aa973-5043-47bc-9bfc-28ed52594724-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505033)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/senate/2817'
 WHERE external_id = -5505033 AND photo_origin_url IS NULL;

-- Senate District 14 — Sarah Keyeski
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505014),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8e5bf4e2-d027-4a15-844d-601c8e0179ab-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505014)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/senate/14/keyeski'
 WHERE external_id = -5505014 AND photo_origin_url IS NULL;

-- Senate District 7 — Chris Larson [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505007),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/76a1c7f6-4493-462a-aabd-2307c7cda820-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505007)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/senate/2819'
 WHERE external_id = -5505007 AND photo_origin_url IS NULL;

-- Senate District 9 — Devin LeMahieu
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505009),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/67637e5a-0268-4440-a38f-2b57f2b27a43-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505009)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'http://legis.wisconsin.gov/senate/09/LeMahieu'
 WHERE external_id = -5505009 AND photo_origin_url IS NULL;

-- Senate District 17 — Howard Marklein
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505017),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/18528793-98ff-447e-80a1-78c6f4edef10-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505017)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'http://legis.wisconsin.gov/senate/17/marklein'
 WHERE external_id = -5505017 AND photo_origin_url IS NULL;

-- Senate District 11 — Steve Nass
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505011),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f8901d87-cb68-480a-84cd-b40290c1bb8b-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505011)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'http://legis.wisconsin.gov/senate/11/nass'
 WHERE external_id = -5505011 AND photo_origin_url IS NULL;

-- Senate District 32 — Brad Pfaff
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505032),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/02b0598e-5409-4f01-93ee-9ee2cb8ac015-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505032)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/senate/32/pfaff'
 WHERE external_id = -5505032 AND photo_origin_url IS NULL;

-- Senate District 25 — Romaine Quinn [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505025),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2dbf3032-65b1-4898-813b-0f62dac0192e-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505025)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/senate/2824'
 WHERE external_id = -5505025 AND photo_origin_url IS NULL;

-- Senate District 16 — Melissa Ratcliff
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505016),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/248b06ce-21fc-4a94-b808-5ad3656be0a0-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505016)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/senate/16/ratcliff'
 WHERE external_id = -5505016 AND photo_origin_url IS NULL;

-- Senate District 26 — Kelda Roys
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505026),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3079710f-a2bc-4e9d-a72a-69ba41722966-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505026)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/senate/26/roys'
 WHERE external_id = -5505026 AND photo_origin_url IS NULL;

-- Senate District 31 — Jeff Smith
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505031),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/0d156e09-417d-450a-b757-d44171336fed-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505031)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/senate/31/smith/'
 WHERE external_id = -5505031 AND photo_origin_url IS NULL;

-- Senate District 15 — Mark Spreitzer
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505015),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9767d4aa-c6d5-43be-90b9-e619893b535c-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505015)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://legis.wisconsin.gov/senate/15/spreitzer'
 WHERE external_id = -5505015 AND photo_origin_url IS NULL;

-- Senate District 10 — Rob Stafsholt [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505010),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/31542340-858b-49de-8f46-f3054f00709d-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505010)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/senate/2828'
 WHERE external_id = -5505010 AND photo_origin_url IS NULL;

-- Senate District 24 — Patrick Testin [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505024),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/469b863b-fe92-484a-a442-24f28c88ccb6-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505024)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/senate/2830'
 WHERE external_id = -5505024 AND photo_origin_url IS NULL;

-- Senate District 29 — Cory Tomczyk [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505029),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/10ec6e28-7666-4f86-9f52-9fa4b35d6d6d-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505029)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/senate/2831'
 WHERE external_id = -5505029 AND photo_origin_url IS NULL;

-- Senate District 30 — Jamie Wall [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505030),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/3f0a1c1d-d3f2-41df-87c0-41e9be3659c7-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505030)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/senate/2842'
 WHERE external_id = -5505030 AND photo_origin_url IS NULL;

-- Senate District 21 — Van Wanggaard [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505021),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/908761b2-ab7f-4307-a073-a5a00e220b43-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505021)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/senate/2832'
 WHERE external_id = -5505021 AND photo_origin_url IS NULL;

-- Senate District 2 — Eric Wimberger [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505002),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/47addb29-85ad-4c09-8886-7e5e224da353-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505002)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/senate/2835'
 WHERE external_id = -5505002 AND photo_origin_url IS NULL;

-- Senate District 22 — Bob Wirch [roster fallback, 150x200 source]
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -5505022),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6e3e9f2e-c393-45ef-b702-8bba4c209220-headshot.jpg',
       'default', 'us_government_work'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -5505022)
    AND type = 'default'
);
UPDATE essentials.politicians SET photo_origin_url = 'https://docs.legis.wisconsin.gov/2025/legislators/senate/2834'
 WHERE external_id = -5505022 AND photo_origin_url IS NULL;

-- Post-verify gate: every sitting WI legislator must now have a default image.
DO $$
DECLARE missing int;
BEGIN
  SELECT count(*) INTO missing
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'wi'
     AND d.district_type IN ('STATE_LOWER','STATE_UPPER')
     AND NOT EXISTS (
       SELECT 1 FROM essentials.politician_images pi
        WHERE pi.politician_id = och.politician_id AND pi.type = 'default'
     );
  IF missing <> 0 THEN
    RAISE EXCEPTION 'migration 1482: % sitting WI legislator(s) still have no default image', missing;
  END IF;
END $$;
