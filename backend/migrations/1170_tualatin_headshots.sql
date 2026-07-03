-- Migration 1170: City of Tualatin City Council Headshots — AUDIT-ONLY (not registered in the ledger)
--
-- Records the essentials.politician_images rows for the Tualatin officials whose 600x750
-- portraits were uploaded to Supabase Storage (politician_photos/{uuid}-headshot.jpg) by
-- _tmp-tualatin-headshots.py. One INSERT per official, guarded by WHERE NOT EXISTS on
-- politician_id (idempotent). type='default'. photo_license='press_use' (all 7 sourced
-- directly from tualatinoregon.gov/app/uploads/ — official city-hosted portraits, no
-- fallback chain needed, the cleanest headshot sourcing situation in the milestone).
--
-- ORCHESTRATOR NOTE: politician UUIDs below are the ones already minted by structural
-- migration 1169 (see 179-02-SUMMARY.md) — the {uuid} segment of each url is pre-filled
-- from that table, NOT from the pipeline manifest (the pipeline resolves the same UUIDs
-- at runtime by external_id and uploads to the identical path). Cross-check the pipeline's
-- printed manifest before applying — every one of the 7 blocks below is expected to
-- succeed (RESEARCH confirmed zero genuine gaps, unlike Tigard). If any official is
-- unexpectedly reported FAILED (GAP) by the pipeline, STOP — re-search that one URL
-- rather than fabricating a row or applying this file with a stale/mismatched url.
--
-- AUDIT-ONLY: this migration intentionally does NOT write a ledger row.

BEGIN;

-- Frank Bubenik (Mayor, -4174951) — tualatinoregon.gov (Home_Mayor.jpg)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4174951),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8fbc9fc7-6840-450f-b490-24c41b2a153f-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4174951)
);

-- María Reyes (Council Member Position 1, -4174952) — tualatinoregon.gov (Council_Maria-Reyes.jpg)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4174952),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f7c39cdd-959c-4ae9-8894-d7dda67fc9e8-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4174952)
);

-- Christen Sacco (Council Member Position 2, -4174953) — tualatinoregon.gov (Council_Christen-Sacco.jpg)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4174953),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/95368151-cddd-4ac4-924d-4a2a1989daf9-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4174953)
);

-- Bridget Brooks (Council Member Position 3, -4174954) — tualatinoregon.gov (Council_Bridget-Brooks.jpg)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4174954),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f0f26baf-1de7-408d-8073-219ad6236dc7-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4174954)
);

-- Cyndy Hillier (Council Member Position 4, -4174955) — tualatinoregon.gov (Council_Cyndy-Hillier.jpg)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4174955),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2c2c74d5-017d-4889-9fad-907f0f556271-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4174955)
);

-- Octavio Gonzalez (Council Member Position 5, -4174956) — tualatinoregon.gov (Council_Octavio-Gonzalez.jpg)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4174956),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/9ac04511-d092-4c6c-becb-4bd333b0999d-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4174956)
);

-- Valerie Pratt (Council Member Position 6, Council President — title-on-seat, -4174957) —
-- tualatinoregon.gov (Council_Valerie-Pratt.jpg)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4174957),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c4fd4fc9-8c63-4711-955f-cbec5e6cc985-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4174957)
);

-- Post-verification gate (WR-02): every INSERT block above must have produced
-- (or found, on re-apply) an image row whose url embeds that politician's own
-- UUID. Catches two silent failure modes: (a) a NULL politician_id from a
-- missing politicians row (orphan insert), and (b) a hand-pasted {uuid} url
-- segment that does not match the politician the row points at (would 404).
-- Expected count is exactly 7 — no "lower the count" caveat, since RESEARCH
-- confirmed zero genuine gaps for Tualatin.
DO $$
DECLARE n INTEGER;
BEGIN
  SELECT COUNT(*) INTO n
  FROM essentials.politician_images pi
  JOIN essentials.politicians p ON p.id = pi.politician_id
  WHERE p.external_id BETWEEN -4174957 AND -4174951
    AND pi.url LIKE '%' || pi.politician_id::text || '%';
  IF n <> 7 THEN
    RAISE EXCEPTION 'Expected 7 Tualatin politician_images rows with url embedding the politician uuid, found %', n;
  END IF;
END $$;

COMMIT;
