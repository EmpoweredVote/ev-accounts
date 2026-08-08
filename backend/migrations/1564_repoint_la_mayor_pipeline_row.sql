-- 1564_repoint_la_mayor_pipeline_row.sql
--
-- The Read & Rank pipeline row labelled "Los Angeles Mayor (CA, 2026-11-03)" carried the race_id
-- of the JUNE 2 PRIMARY race (24bc3631, 14 candidates, 12 of them eliminated) instead of the
-- November general/runoff (9e888818, Bass v Raman).
--
-- Consequence: on-the-record's src/discovery/db.py::fetch_tracked_candidates joins the pipeline to
-- race_candidates on race_id, so source discovery would have hunted quotes for the eliminated
-- primary field and skipped the two candidates actually on the November ballot.
-- refresh_readrank_pipeline_counters() also counted rankable_topics against the wrong roster.
--
-- Nothing user-visible: the frontend buckets races upcoming/past by election_date
-- (read-rank src/utils/raceGrouping.ts), so the June primary was already out of the default view.

BEGIN;

UPDATE essentials.readrank_race_pipeline
   SET race_id = '9e888818-c50b-4c61-a106-a0839ff2479d'
 WHERE id = '9612b60a-ca29-4da4-9dda-8ff34baf7d9e'
   AND race_id = '24bc3631-22cf-41ab-a731-672481502214';

-- Guard: exactly one row must now point at the general. Aborts if the row moved underneath us
-- or was already repointed to something else.
DO $$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n
    FROM essentials.readrank_race_pipeline
   WHERE id = '9612b60a-ca29-4da4-9dda-8ff34baf7d9e'
     AND race_id = '9e888818-c50b-4c61-a106-a0839ff2479d';
  IF n <> 1 THEN
    RAISE EXCEPTION
      'Aborting: expected the LA Mayor pipeline row to point at the general race, found % row(s).', n;
  END IF;
END $$;

-- Guard: the general race must carry exactly the two runoff candidates. If this row now resolves
-- to a 14-candidate roster, something is wrong with the repoint and discovery must not run on it.
DO $$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN essentials.readrank_race_pipeline p ON p.race_id = rc.race_id
   WHERE p.id = '9612b60a-ca29-4da4-9dda-8ff34baf7d9e'
     AND COALESCE(rc.candidate_status, 'active') NOT IN ('withdrawn', 'removed');
  IF n <> 2 THEN
    RAISE EXCEPTION
      'Aborting: expected 2 active candidates (Bass, Raman) on the repointed race, found %.', n;
  END IF;
END $$;

COMMIT;
