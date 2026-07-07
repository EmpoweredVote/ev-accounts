-- Migration 1197: City of Cornelius City Council Headshots — AUDIT-ONLY (not registered in the ledger)
--
-- Records the essentials.politician_images rows for the 4 FILLED Cornelius officials whose
-- 600x750 portraits were uploaded to Supabase Storage (politician_photos/{uuid}-headshot.jpg) by
-- _tmp-cornelius-headshots.py. One INSERT per SOURCED official, guarded by WHERE NOT EXISTS on
-- politician_id (idempotent). type='default'. photo_license='press_use' for all 4 — uniform
-- official-site studio-style portraits, uploaded via the CMS's own media library. Sourcing note:
-- corneliusor.gov's ImageRepository endpoint (documentID=2325/1977/2324/1979) is directly
-- curl-retrievable (HTTP 200, no WAF, no JS/AJAX gate) — the best sourcing outcome of the
-- milestone. No fallback chain needed; expect a full 4/4 outcome. The 5th councilor seat is
-- genuinely VACANT with NO photo — its leftover directory image (documentID=1975, still
-- alt-tagged with the former occupant's name) is confirmed blank (a plain solid-blue background,
-- no person in it) and must NEVER be used; do not force a former officeholder's image onto the
-- vacancy. Every source PNG is a circular photo cutout composited on a fully transparent
-- background, requiring a white-background composite step before resize (the pipeline's primary
-- exercised step this phase); because the canvas is already exactly 1600x2000 (exact 4:5), no crop
-- judgment was needed.
--
-- AUDIT-ONLY: this migration intentionally does NOT write a ledger row.
--
-- ORCHESTRATOR NOTE (expected-count kept in sync with the post-verify gate below — WR-A):
--   The 4 blocks below are pre-filled with the politician UUIDs minted by structural migration
--   1196 (see 182-02-SUMMARY.md) — the same UUIDs the pipeline resolves at runtime by
--   external_id and embeds in each Storage path. Before applying:
--     1. DELETE the entire INSERT block for any official the pipeline manifest does NOT report
--        SUCCESS for (honest gap — no fabrication; not expected here given confirmed sourcing).
--     2. Confirm each remaining block's photo_license is 'press_use' (should be uniform since
--        all sources are the official city site).
--     3. If any block is deleted in step 1, edit the post-verification DO block's expected count
--        below to match the ACTUAL number of INSERT blocks remaining (currently 4, matching the
--        gate's literal `IF n <> 4` check as written in this file today).

BEGIN;

-- Jeffrey C. Dalin (Mayor, elected, -4115551) — SOURCE: corneliusor.gov ImageRepository documentID=2325 (direct curl, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4115551),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/856f7e70-a846-4ba3-a0df-e7d8146ed11a-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4115551)
);

-- Angeles Godinez Valencia (Councilor, elected, Council President — title-on-seat, -4115552) —
-- SOURCE: corneliusor.gov ImageRepository documentID=1977 (direct curl, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4115552),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/f75a20a9-1a22-4d23-ac9c-ac1040e27754-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4115552)
);

-- Edgar Baker (Councilor, appointed, -4115553) — SOURCE: corneliusor.gov ImageRepository documentID=2324 (direct curl, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4115553),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/31df8939-d8ba-4b54-9c69-18317d7096ee-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4115553)
);

-- Edén López (Councilor, appointed, -4115554) — SOURCE: corneliusor.gov ImageRepository documentID=1979 (direct curl, HTTP 200)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4115554),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/18d8515e-3b3e-4d53-a1a3-4eece6e17dcc-headshot.jpg',
       'default', 'press_use'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4115554)
);

-- The 5th councilor seat (-4115555) is genuinely VACANT — no politician row exists for it, and
-- it correctly has NO politician_images row here. Do not add one.

-- Post-verification gate (url-embeds-uuid): asserts EVERY politician uuid this migration's
-- INSERTs target has a politician_images row whose url embeds that same uuid. The gate derives
-- its identity set from the SAME uuid literals the INSERTs use (the VALUES list below) rather
-- than a hardcoded external_id range — a clone that edits the INSERT uuids but forgets the gate
-- now fails loudly instead of passing vacuously against the previous city's rows (182-REVIEW
-- WR-04). Catches: (a) a missing/orphaned insert for any targeted uuid, and (b) a url uuid
-- segment that does not match the politician the row points at (would 404).
-- WHEN CLONING FOR A NEW CITY: replace the uuid VALUES list below with the new city's uuids —
-- it is the same list as the INSERT blocks above; keep them in sync.
DO $$
DECLARE missing INTEGER;
BEGIN
  SELECT COUNT(*) INTO missing
  FROM (VALUES
    ('856f7e70-a846-4ba3-a0df-e7d8146ed11a'::uuid),  -- Jeffrey C. Dalin
    ('f75a20a9-1a22-4d23-ac9c-ac1040e27754'::uuid),  -- Angeles Godinez Valencia
    ('31df8939-d8ba-4b54-9c69-18317d7096ee'::uuid),  -- Edgar Baker
    ('18d8515e-3b3e-4d53-a1a3-4eece6e17dcc'::uuid)   -- Edén López
  ) AS expected(pid)
  WHERE NOT EXISTS (
    SELECT 1 FROM essentials.politician_images pi
    WHERE pi.politician_id = expected.pid
      AND pi.url LIKE '%' || expected.pid::text || '%'
  );
  IF missing <> 0 THEN
    RAISE EXCEPTION 'Cornelius headshot gate: % targeted politician uuid(s) lack a politician_images row with a uuid-embedding url', missing;
  END IF;
END $$;

COMMIT;
