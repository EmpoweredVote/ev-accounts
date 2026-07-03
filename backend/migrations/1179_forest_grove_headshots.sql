-- Migration 1179: City of Forest Grove City Council Headshots — AUDIT-ONLY (not registered in the ledger)
--
-- Records the essentials.politician_images rows for the Forest Grove officials whose 600x750
-- portraits were uploaded to Supabase Storage (politician_photos/{uuid}-headshot.jpg) by
-- _tmp-forest-grove-headshots.py. One INSERT per SOURCED official, guarded by WHERE NOT EXISTS
-- on politician_id (idempotent). type='default'. photo_license set per actual source (press_use
-- ONLY for government-hosted photography — verify per source for any Ballotpedia/Wikimedia/
-- local-news image; never assume press_use for a non-government host, per D-09).
--
-- Source note: forestgrove-or.gov's Meet the Council / Staff Directory pages are NO-WAF for
-- text but the photo widget is JS/AJAX-loaded and not curl-visible, and Wave-0's JS-capable
-- fetch (real browser, 4s render wait) confirmed NO usable photo for any of the 7 officials on
-- the city site — a JS-rendering gap, a different failure mode than a WAF block. The D-16
-- fallback chain (Ballotpedia -> Wikimedia -> local news: forestgrovenewstimes.com /
-- newsinthegrove.com) is therefore the source path for every official. A partial N/7 outcome
-- is an honest, acceptable result per RESEARCH — do NOT fabricate a row for any official with
-- no usable photo found.
--
-- AUDIT-ONLY: this migration intentionally does NOT write a ledger row.
--
-- ORCHESTRATOR NOTE (fail-closed template — MUST be edited before applying):
--   The 7 blocks below are pre-filled with the politician UUIDs minted by structural migration
--   1178 (see 180-02-SUMMARY.md) — the same UUIDs the pipeline resolves at runtime by
--   external_id and embeds in each Storage path. Before applying:
--     1. DELETE the entire INSERT block for any official the pipeline manifest does NOT report
--        SUCCESS for (honest gap — no fabrication).
--     2. Replace each remaining SET-PER-ACTUAL-SOURCE license placeholder with the verified
--        license for that official's actual source (press_use only if government-hosted).
--     3. Update each remaining block's source comment with the actual source site.
--     4. Set the post-verification DO block's expected count (currently 0) to the ACTUAL number
--        of INSERT blocks remaining.
--   Applied UNEDITED, this file fails closed: the 7 INSERTs would make the post-verify count 7
--   while the gate expects 0, so the DO block RAISEs and the whole transaction rolls back.

BEGIN;

-- Malynda Wenzl (Mayor, -4126201) — SOURCE: News-Times file photo via NewsBreak syndication (D-16 local-news tier)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4126201),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/749da610-7755-4c36-8f2d-efdacc522b2c-headshot.jpg',
       'default', 'sourced'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4126201)
);

-- Michael Marshall (Councilor, -4126202) — SOURCE: candidate courtesy photo, News-Times Sept-2022 roundup via NewsBreak (D-16 local-news tier)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4126202),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/acef8291-5eeb-43b9-905d-ac5ede610223-headshot.jpg',
       'default', 'sourced'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4126202)
);

-- Karen Martinez (Councilor, -4126203) — SOURCE: candidate courtesy photo, News-Times Sept-2022 roundup via NewsBreak (D-16 local-news tier; orchestrator re-crop for eye-line framing)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4126203),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/cdc010a8-66d5-4cd6-ab5f-ca10f5101e88-headshot.jpg',
       'default', 'sourced'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4126203)
);

-- Mariana Valenzuela (Councilor, Council President — title-on-seat, -4126204) —
-- SOURCE: candidate courtesy photo, News-Times Sept-2022 roundup via NewsBreak (D-16 local-news tier)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4126204),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/93e6276a-4206-46d1-8e31-a7403e1aae14-headshot.jpg',
       'default', 'sourced'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4126204)
);

-- Donna Gustafson (Councilor, -4126205) — SOURCE: campaign courtesy photo, her Sept-2024 News-Times reelection announcement (D-16 local-news tier)
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4126205),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/47f5c014-2100-45cf-a4c7-da6b6782b6e5-headshot.jpg',
       'default', 'sourced'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4126205)
);

-- Angel Falconer (Councilor, -4126206) — SOURCE: her own campaign-site portrait, angelfalconer.com (identity cross-verified vs WashCo Dems endorsement graphic)
-- Identity note: her pre-2022 record is Milwaukie, OR — verify any sourced photo depicts the
-- Forest Grove councilor, not an unrelated Milwaukie-era image of a different person.
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4126206),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/8a09c44f-b45f-4ece-9636-4d49b4a09679-headshot.jpg',
       'default', 'sourced'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4126206)
);

-- Brian Schimmel (Councilor, -4126207) — SOURCE: campaign courtesy photo, his Sept-2024 News-Times candidacy announcement (D-16 local-news tier)
-- Identity note: do NOT use a photo of Peter Truax (lost the close 2024 race) for this seat.
INSERT INTO essentials.politician_images (id, politician_id, url, type, photo_license)
SELECT gen_random_uuid(),
       (SELECT id FROM essentials.politicians WHERE external_id = -4126207),
       'https://kxsdzaojfaibhuzmclfq.storage.supabase.co/storage/v1/object/public/politician_photos/01e1da66-778b-4bac-9a41-9c7fa9f3bbc3-headshot.jpg',
       'default', 'sourced'
WHERE NOT EXISTS (
  SELECT 1 FROM essentials.politician_images
  WHERE politician_id = (SELECT id FROM essentials.politicians WHERE external_id = -4126207)
);

-- Post-verification gate (url-embeds-uuid, adapted for an honest partial outcome): asserts the
-- ACTUAL sourced count of politician_images rows whose url embeds the politician's own uuid —
-- NOT a hard 7, since a genuine partial (or zero) outcome is an acceptable result for this
-- phase given the confirmed city-site JS-rendering sourcing gap. Catches two silent failure
-- modes: (a) a NULL politician_id from a missing politicians row (orphan insert), and (b) a
-- url uuid segment that does not match the politician the row points at (would 404).
--
-- ORCHESTRATOR: set the expected count below (currently 0, the fail-closed template default)
-- to the ACTUAL number of INSERT blocks remaining above before applying.
DO $$
DECLARE n INTEGER;
BEGIN
  SELECT COUNT(*) INTO n
  FROM essentials.politician_images pi
  JOIN essentials.politicians p ON p.id = pi.politician_id
  WHERE p.external_id BETWEEN -4126207 AND -4126201
    AND pi.url LIKE '%' || pi.politician_id::text || '%';
  IF n <> 7 THEN
    RAISE EXCEPTION 'Expected 7 Forest Grove politician_images rows with url embedding the politician uuid, found %', n;
  END IF;
END $$;

COMMIT;
