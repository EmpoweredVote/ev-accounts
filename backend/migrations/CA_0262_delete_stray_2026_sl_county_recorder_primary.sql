-- CA_0262_delete_stray_2026_sl_county_recorder_primary.sql
-- Delete the "Salt Lake County Recorder" race from the 2026-06-23 Utah primary. There was no such contest: the seat
-- was on the 2024 ballot and is next up in 2028. The race row is a seeding error.
--
-- Slot CA_0262 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand (pure DML).
--
-- THE EVIDENCE
--   Rashelle Hobbs (b5638977) holds the Recorder seat (office 24d3f2d6). She was re-elected on 2024-11-05, 250,018 to
--   233,025 (51.76%) over Richard Snelgrove (Salt Lake County 2024 general certification; City Journals, 2024-12-13).
--   County recorders serve four-year terms, so the seat is next on the 2028 ballot.
--   Salt Lake County's 2026 candidate list (the clerk's candidate JSON, fetched 2026-09-24) has no Recorder race.
--   CA_0240 held this row (result NULL) for exactly this reason; CA_0253 created no November race for it.
--
-- WHAT IS DELETED
--   race db562de8-3a96-4933-8bca-9be8f14d4566 (election 02dee6b2 "2026 Utah Primary", primary_party 'Democratic',
--     description "SL County Recorder — Democratic", created 2026-05-29), and through ON DELETE CASCADE its one
--     race_candidates row a19f4f6c (Rashelle Hobbs, source county_clerk, result NULL).
--   Counted 2026-09-24, nothing else references the race: candidate_staging, discovered_sources,
--     discovery_race_state, meetings.event_races, readrank_questions, readrank_race_pipeline and
--     readrank_race_topic_questions all 0. The pre-flight re-checks every one.
--   DELETE, not a status: a race that never existed is not history. A result-less row keeps a phantom 2026 contest
--   on her candidacy history, and nothing in the vocabulary ('won', 'lost', 'not_nominated' ...) can describe a
--   contest that did not happen.
--
-- NOT CHANGED: Hobbs's politicians row, seat, office_terms and portrait (her politician_images row is her own file,
--   ut/325622.jpg, not the race row's photo). The race row's photo_url file in Storage is left alone.
--
-- ROLLBACK: re-insert the race and its race_candidates row from the values in the header above (ids, primary_party,
--   description, source 'county_clerk', candidate_status 'active', is_incumbent false).
-- IDEMPOTENT: once the race is gone the pre-flight passes on its "already deleted" branch, the DELETE removes 0 rows,
--   and the gate still passes.

BEGIN;

-- ─── Pre-flight ──────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int; v_gone boolean;
BEGIN
  -- Hobbs holds the Recorder seat (whatever happens to the race, this must be true)
  SELECT count(*) INTO v_n FROM essentials.office_current_holder
   WHERE office_id = '24d3f2d6-694e-4e92-b5b8-67df47c25401' AND politician_id = 'b5638977-3fd9-4adf-b14d-c8e75ae78ee2';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: Rashelle Hobbs does not hold the Salt Lake County Recorder seat'; END IF;

  v_gone := NOT EXISTS (SELECT 1 FROM essentials.races WHERE id = 'db562de8-3a96-4933-8bca-9be8f14d4566');
  IF v_gone THEN RAISE NOTICE 'CA_0262 pre-flight: race already deleted'; RETURN; END IF;

  -- it is the reviewed race
  SELECT count(*) INTO v_n FROM essentials.races
   WHERE id = 'db562de8-3a96-4933-8bca-9be8f14d4566' AND election_id = '02dee6b2-76cd-4aa3-a365-6ee362f8a719'
     AND position_name = 'Salt Lake County Recorder' AND office_id = '24d3f2d6-694e-4e92-b5b8-67df47c25401';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: race db562de8 is not the reviewed 2026 primary Recorder race'; END IF;

  -- exactly one candidate: Hobbs, no result recorded
  SELECT count(*) INTO v_n FROM essentials.race_candidates WHERE race_id = 'db562de8-3a96-4933-8bca-9be8f14d4566';
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: % candidate rows on the race, expected 1', v_n; END IF;
  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE id = 'a19f4f6c-84f4-4db2-8e50-3d4669fd5b02' AND race_id = 'db562de8-3a96-4933-8bca-9be8f14d4566'
     AND politician_id = 'b5638977-3fd9-4adf-b14d-c8e75ae78ee2' AND result IS NULL;
  IF v_n <> 1 THEN RAISE EXCEPTION 'PRE: the candidate row is not Hobbs with no result'; END IF;

  -- nothing else references the race
  SELECT (SELECT count(*) FROM essentials.candidate_staging            WHERE race_id = 'db562de8-3a96-4933-8bca-9be8f14d4566')
       + (SELECT count(*) FROM essentials.discovered_sources           WHERE race_id = 'db562de8-3a96-4933-8bca-9be8f14d4566')
       + (SELECT count(*) FROM essentials.discovery_race_state         WHERE race_id = 'db562de8-3a96-4933-8bca-9be8f14d4566')
       + (SELECT count(*) FROM meetings.event_races                    WHERE race_id = 'db562de8-3a96-4933-8bca-9be8f14d4566')
       + (SELECT count(*) FROM essentials.readrank_questions           WHERE race_id = 'db562de8-3a96-4933-8bca-9be8f14d4566')
       + (SELECT count(*) FROM essentials.readrank_race_pipeline       WHERE race_id = 'db562de8-3a96-4933-8bca-9be8f14d4566')
       + (SELECT count(*) FROM essentials.readrank_race_topic_questions WHERE race_id = 'db562de8-3a96-4933-8bca-9be8f14d4566')
    INTO v_n;
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % other rows reference the race; review them first', v_n; END IF;

  -- no 2026 general race exists for the seat either (CA_0253 made none)
  SELECT count(*) INTO v_n FROM essentials.races r JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.state = 'UT' AND e.election_date = '2026-11-03' AND r.office_id = '24d3f2d6-694e-4e92-b5b8-67df47c25401';
  IF v_n <> 0 THEN RAISE EXCEPTION 'PRE: % 2026 general races exist for the Recorder seat', v_n; END IF;

  RAISE NOTICE 'CA_0262 pre-flight OK';
END $$;

-- ─── 1. Delete the race (its one race_candidates row goes with it: ON DELETE CASCADE) ────────────
DELETE FROM essentials.races
 WHERE id = 'db562de8-3a96-4933-8bca-9be8f14d4566'
   AND election_id = '02dee6b2-76cd-4aa3-a365-6ee362f8a719' AND position_name = 'Salt Lake County Recorder';

-- ─── Post-verify gate ────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM essentials.races WHERE id = 'db562de8-3a96-4933-8bca-9be8f14d4566';
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: the race still exists'; END IF;
  SELECT count(*) INTO v_n FROM essentials.race_candidates WHERE id = 'a19f4f6c-84f4-4db2-8e50-3d4669fd5b02';
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: Hobbs''s race row still exists'; END IF;

  -- no Recorder race is left on any 2026 Utah election
  SELECT count(*) INTO v_n FROM essentials.races r JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.state = 'UT' AND e.election_date BETWEEN '2026-01-01' AND '2026-12-31'
     AND (r.position_name = 'Salt Lake County Recorder' OR r.office_id = '24d3f2d6-694e-4e92-b5b8-67df47c25401');
  IF v_n <> 0 THEN RAISE EXCEPTION 'POST: % 2026 Recorder races remain', v_n; END IF;
  -- the primary keeps its other 138 races
  SELECT count(*) INTO v_n FROM essentials.races WHERE election_id = '02dee6b2-76cd-4aa3-a365-6ee362f8a719';
  IF v_n <> 138 THEN RAISE EXCEPTION 'POST: "2026 Utah Primary" holds % races, expected 138', v_n; END IF;

  -- Hobbs is untouched: still active, still the incumbent, still holding the seat
  SELECT count(*) INTO v_n FROM essentials.politicians p
    JOIN essentials.office_current_holder och ON och.politician_id = p.id
   WHERE p.id = 'b5638977-3fd9-4adf-b14d-c8e75ae78ee2' AND p.is_active AND p.is_incumbent
     AND och.office_id = '24d3f2d6-694e-4e92-b5b8-67df47c25401';
  IF v_n <> 1 THEN RAISE EXCEPTION 'POST: Hobbs no longer an active incumbent holding the Recorder seat'; END IF;

  RAISE NOTICE 'CA_0262 applied: stray 2026 primary Recorder race and its one row deleted; Hobbs keeps the seat';
END $$;

COMMIT;
