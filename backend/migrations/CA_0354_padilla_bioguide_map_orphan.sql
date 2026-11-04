-- CA_0354_padilla_bioguide_map_orphan.sql
-- Author: Chris Andrews (CA_ namespace). Slot reserved from the steward allocator 2026-11-03.
--
-- =============================================================================
-- CA_0354: repoint the bioguide P000145 row in essentials.legislative_politician_id_map from a deleted politician
--          to sitting U.S. Senator Alex Padilla (2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f)
-- =============================================================================
-- WHY: Padilla had 0 rows in essentials.legislative_votes, so the federal Stage 5 lane (#1287) could not see him.
-- Both federal vote loaders (federal_votes_legiscan.py, federal_votes_voteview_senate.py) build
-- bioguide -> {politician ids} from politicians.bioguide_id UNION this map, and skip any bioguide that resolves
-- to more than one id. P000145 resolved to two: his sitting row (politicians.bioguide_id) and, through map row
-- e06883e7-e8a5-4b63-89df-64f5e990e913, politician 647caab8-b8a6-449e-a972-02bf2d135ed5 — which no longer
-- exists (the map has no foreign key, so the delete left the row dangling). Measured 2026-11-03: this is the
-- only map row (of 4,285) whose politician_id points at no politician.
--
-- OVERWRITTEN VALUE: map row e06883e7-e8a5-4b63-89df-64f5e990e913 had
--   politician_id = 647caab8-b8a6-449e-a972-02bf2d135ed5, id_type = 'bioguide', id_value = 'P000145',
--   verified_at = 2026-03-03 19:34:23.106425+00, source = 'congress-legislators-yaml'.
-- Only politician_id changes; verified_at and source are kept.
--
-- NOT A DUPLICATE: the other politician row named Alex Padilla (123c9a42-5715-4ab2-a8bd-76e7adbca27b) holds
-- Inglewood City Council District 2 and is a different person (cityofinglewood.org/587/District-2). Untouched.
--
-- WHAT THIS DOES: one guarded UPDATE of that map row. His votes are loaded afterwards by
-- federal_votes_legiscan.py --congress 117/118/119 (a separate, approved run). Idempotent: a re-run updates
-- 0 rows and the gate still passes.
-- GATE: P000145 resolves to exactly one politician across both sources (the sitting row, still named Alex
-- Padilla), and no map row anywhere points at a missing politician.
--
-- DRY RUN: wrap in BEGIN ... ROLLBACK (replace COMMIT) and confirm afterwards that the row still points at
-- 647caab8-b8a6-449e-a972-02bf2d135ed5.
-- Dry run on prod 2026-11-03 (yes #1 from Chris Andrews): UPDATE 1, gate OK; rolled back; the row still pointed at
-- 647caab8 afterwards. Positive control: the same file pointing the row at the Inglewood record failed the gate
-- ("P000145 resolves to 2 politician ids").
-- APPLIED: 2026-11-03 on production, on yes #2 from Chris Andrews. UPDATE 1, gate OK; the row now points at
-- 2717ff94. Then (yes #3) federal_votes_legiscan.py --congress 117 / 118 / 119 --refresh --commit added 383 + 213
-- + 450 vote rows, all his (rehearsed first; the same counts as Ossoff, Schatz and Warner). He took office
-- 2021-01-20, so the 115th and 116th hold none.
-- =============================================================================

BEGIN;

UPDATE essentials.legislative_politician_id_map
   SET politician_id = '2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f'::uuid
 WHERE id = 'e06883e7-e8a5-4b63-89df-64f5e990e913'::uuid
   AND politician_id = '647caab8-b8a6-449e-a972-02bf2d135ed5'::uuid
   AND id_type = 'bioguide' AND id_value = 'P000145'
   AND NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = '647caab8-b8a6-449e-a972-02bf2d135ed5'::uuid);

DO $$
DECLARE n_ids int; n_named int; n_orphan int;
BEGIN
  SELECT count(DISTINCT pid) INTO n_ids FROM (
    SELECT id AS pid FROM essentials.politicians WHERE bioguide_id = 'P000145'
    UNION ALL
    SELECT politician_id FROM essentials.legislative_politician_id_map WHERE id_type = 'bioguide' AND id_value = 'P000145'
  ) s;
  SELECT count(*) INTO n_named FROM essentials.politicians
   WHERE id = '2717ff94-f7e8-4b39-b6ec-fc3e30f3d46f'::uuid AND bioguide_id = 'P000145'
     AND first_name = 'Alex' AND last_name = 'Padilla';
  SELECT count(*) INTO n_orphan FROM essentials.legislative_politician_id_map m
   WHERE NOT EXISTS (SELECT 1 FROM essentials.politicians p WHERE p.id = m.politician_id);
  IF n_ids <> 1 THEN RAISE EXCEPTION 'CA_0354: P000145 resolves to % politician ids, expected 1', n_ids; END IF;
  IF n_named <> 1 THEN RAISE EXCEPTION 'CA_0354: sitting Padilla row not found carrying P000145'; END IF;
  IF n_orphan <> 0 THEN RAISE EXCEPTION 'CA_0354: % map row(s) still point at a missing politician', n_orphan; END IF;
  RAISE NOTICE 'CA_0354 gate OK: P000145 -> 1 politician, 0 orphan map rows';
END $$;

COMMIT;
