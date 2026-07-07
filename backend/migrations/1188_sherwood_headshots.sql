-- Migration 1188: City of Sherwood City Council Headshots — AUDIT-ONLY (not registered in the ledger)
--
-- Records the essentials.politician_images rows for the Sherwood officials whose 600x750
-- portraits were uploaded to Supabase Storage (politician_photos/{uuid}-headshot.jpg) by
-- _tmp-sherwood-headshots.py. One INSERT per SOURCED official, guarded by WHERE NOT EXISTS
-- on politician_id (idempotent). type='default'. photo_license='press_use' for all 7 — uniform
-- official-site studio-style portraits, uploaded via the CMS's own media library. Sourcing note:
-- sherwoodoregon.gov's council page embeds all 7 headshots as static <img> tags, directly
-- curl-retrievable (HTTP 200, no WAF, no JS/AJAX gate) — the best sourcing outcome of the
-- milestone. No D-16 fallback chain needed; expect a full 7/7 outcome.
--
-- AUDIT-ONLY: this migration intentionally does NOT write a ledger row.
--
-- ORCHESTRATOR NOTE (expected-count kept in sync with the post-verify gate below — D-15 WR-A):
--   The 7 blocks below are pre-filled with the politician UUIDs minted by structural migration
--   1187 (see 181-02-SUMMARY.md) — the same UUIDs the pipeline resolves at runtime by
--   external_id and embeds in each Storage path. Before applying:
--     1. DELETE the entire INSERT block for any official the pipeline manifest does NOT report
--        SUCCESS for (honest gap — no fabrication; not expected here given confirmed sourcing).
--     2. Confirm each remaining block's photo_license is 'press_use' (should be uniform since
--        all sources are the official city site).
--     3. If any block is deleted in step 1, edit the post-verification DO block's expected count
--        below to match the ACTUAL number of INSERT blocks remaining (currently 7, matching the
--        gate's literal `IF n <> 7` check as written in this file today).

BEGIN;

-- Tim Rosener (Mayor, -4167101) — SOURCE: sherwoodoregon.gov official council-page portrait (direct curl, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4167101),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/bdde1b46-d4ff-4409-b215-ee9d4f41be06-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4167101)
);

-- Kim Young (Councilor, Council President — title-on-seat, -4167102) — SOURCE: sherwoodoregon.gov official council-page portrait (direct curl, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4167102),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/66ae4909-109b-4c9c-a16c-a2fa74620a8f-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4167102)
);

-- Renee Brouse (Councilor, -4167103) — SOURCE: sherwoodoregon.gov official council-page portrait (direct curl, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4167103),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/eb246bf6-039f-4ab6-9655-be849339fedd-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4167103)
);

-- Taylor Giles (Councilor, -4167104) — SOURCE: sherwoodoregon.gov official council-page portrait (direct curl, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4167104),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/6427eeca-2e13-4bf8-af28-45e6d1e373ea-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4167104)
);

-- Keith Mays (Councilor — plain title, former Mayor/Council President; do not relabel, -4167105) —
-- SOURCE: sherwoodoregon.gov official council-page portrait (direct curl, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4167105),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/c2a6383a-56e9-4ead-9f22-9a6d3e88f68c-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4167105)
);

-- Doug Scott (Councilor, -4167106) — SOURCE: sherwoodoregon.gov official council-page portrait (direct curl, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4167106),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8bf23d4d-d3e2-4cbd-99ff-863fb80f7ae4-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4167106)
);

-- Dan Standke (Councilor, -4167107) — SOURCE: sherwoodoregon.gov official council-page portrait
-- (direct curl, HTTP 200). NOTE: source filename uses "daniel-standke", not "dan-standke".
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4167107),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/2a58cc49-bef8-4800-a092-4a33e77330fc-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4167107)
);

-- Post-verification gate (url-embeds-uuid): asserts the sourced count of politician_images rows
-- whose url embeds the politician's own uuid. Expected count is 7, matching the confirmed 7/7
-- direct-download sourcing (best in the milestone, no fallback chain needed). Catches two silent
-- failure modes: (a) a NULL politician_id from a missing politicians row (orphan insert), and
-- (b) a url uuid segment that does not match the politician the row points at (would 404).
DO $$
DECLARE n INTEGER;
BEGIN
  SELECT COUNT(*) INTO n
  FROM essentials.politician_images pi
  JOIN essentials.politicians p ON p.id = pi.politician_id
  WHERE p.external_id BETWEEN -4167107 AND -4167101
    AND pi.url LIKE '%' || pi.politician_id::text || '%';
  IF n <> 7 THEN
    RAISE EXCEPTION 'Expected 7 Sherwood politician_images rows with url embedding the politician uuid, found %', n;
  END IF;
END $$;

COMMIT;
