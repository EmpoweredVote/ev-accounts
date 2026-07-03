-- Migration 1160: City of Tigard City Council Headshots — AUDIT-ONLY (not registered in the ledger)
--
-- Records the essentials.politician_images rows for the Tigard officials whose 600x750
-- portraits were uploaded to Supabase Storage (politician_photos/{uuid}-headshot.jpg) by
-- _tmp-tigard-headshots.py. One INSERT per official, guarded by WHERE NOT EXISTS on
-- politician_id (idempotent). type='default'. photo_license='press_use' (tigardlife.com /
-- valleytimes.news local-news photography — no city-portal bulk source exists, unlike
-- Hillsboro's CivicWeb mirror).
--
-- ORCHESTRATOR NOTE: politician UUIDs below are the ones already minted by structural
-- migration 1159 (see 178-02-SUMMARY.md) — the {uuid} segment of each url is pre-filled
-- from that table, NOT from the pipeline manifest (the pipeline resolves the same UUIDs
-- at runtime by external_id and uploads to the identical path). Before applying this file,
-- the orchestrator MUST cross-check the pipeline's printed manifest and DELETE the entire
-- INSERT block for any official reported FAILED (GAP) — do not fabricate a row for an
-- official with no usable photo found. A partial 5/7 or 6/7 outcome is an honest,
-- acceptable result per RESEARCH.
--
-- AUDIT-ONLY: this migration intentionally does NOT write a ledger row.

BEGIN;

-- Yi-Kang Hu (Mayor, -4173651) — tigardlife.com / valleytimes.news / Facebook fallback
-- ORCHESTRATOR: remove this block if no usable photo was found for Hu.
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4173651),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6701cd53-e7fb-491c-9b45-d0474705349e-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4173651)
);

-- Tom Anderson (Councilor, -4173652) — tigardlife.com / valleytimes.news
-- ORCHESTRATOR: remove this block if no usable photo was found for Anderson.
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4173652),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/af1382e1-7b67-4729-8d6c-ec1bab0625bd-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4173652)
);

-- Faraz Ghoddusi (Councilor, -4173653) — tigardlife.com / valleytimes.news / Ballotpedia
-- ORCHESTRATOR: remove this block if no usable photo was found for Ghoddusi.
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4173653),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/53570d0d-30c7-4bd3-8a0e-ac0865d2b15a-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4173653)
);

-- Heather Robbins (Councilor, -4173654) — tigardlife.com / valleytimes.news / Ballotpedia
-- ORCHESTRATOR: remove this block if no usable photo was found for Robbins.
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4173654),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/18896554-4b57-42ee-82b8-9549878959b5-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4173654)
);

-- Jake Schlack (Councilor, -4173655) — tigardlife.com / valleytimes.news / Ballotpedia
-- ORCHESTRATOR: remove this block if no usable photo was found for Schlack.
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4173655),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/ffd6a403-6e6b-428d-8c8d-4a3557be339b-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4173655)
);

-- Jeanette Shaw (Councilor, -4173656) — tigardlife.com (spot-verified in RESEARCH)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4173656),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9e4d8f47-e4d5-4652-8fda-8e19b33bedea-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4173656)
);

-- Maureen Wolf (Councilor, Council President — title-on-seat, -4173657) — tigardlife.com /
-- valleytimes.news / maureenwolf.com campaign site fallback
-- ORCHESTRATOR: remove this block if no usable photo was found for Wolf.
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4173657),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/4994a44e-ea96-4248-a39f-9ebadc5f97ef-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4173657)
);

-- Post-verification gate (WR-02): every INSERT block above must have produced
-- (or found, on re-apply) an image row whose url embeds that politician's own
-- UUID. Catches two silent failure modes: (a) a NULL politician_id from a
-- missing politicians row (orphan insert), and (b) a hand-pasted {uuid} url
-- segment that does not match the politician the row points at (would 404).
-- ORCHESTRATOR: if any INSERT block was deleted for a FAILED (GAP) official,
-- lower the expected count 7 to the number of remaining blocks.
DO $$
DECLARE n INTEGER;
BEGIN
  SELECT COUNT(*) INTO n
  FROM essentials.politician_images pi
  JOIN essentials.politicians p ON p.id = pi.politician_id
  WHERE p.external_id BETWEEN -4173657 AND -4173651
    AND pi.url LIKE '%' || pi.politician_id::text || '%';
  IF n <> 7 THEN
    RAISE EXCEPTION 'Expected 7 Tigard politician_images rows with url embedding the politician uuid, found %', n;
  END IF;
END $$;

COMMIT;
