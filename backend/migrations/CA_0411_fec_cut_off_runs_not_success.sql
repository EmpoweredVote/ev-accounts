-- CA_0411 — FEC runs cut off by the 10-minute limit but recorded as successes: mark them failed, and make
-- each affected source re-read from where its first cut-off run began (ev-cto watchlist #102, 2026-11-22)
--
-- THE DEFECT. Since 2026-08-18 the FEC burst gives each source 10 minutes (076bcbc58). When the limit fires,
-- the FEC adapter stops at a page boundary and returns normally, and runIngestion recorded the run as
-- 'completed' or 'completed_with_warning'. A success moves the source's load-date cursor (getFecLoadCursor:
-- last success - 2 days), so every row the cut-off run never reached was skipped by every later run. FEC
-- returns the largest gifts first, so the rows lost are the smaller ones. Fixed in code by the same PR:
-- runIngestion now fails a run whose signal fired, and the adapter saves its place (CA_0410).
--
-- WHICH RUNS. adapter_name = 'fec', a success status, duration_ms >= 600000, started_at >= 2026-08-18: 129
-- runs over 65 (source, cycle) pairs, all cycle 2026; 15 pairs had no earlier success (the cut-off run was a
-- first load). The limit is 600000 ms and the adapter stops within one page after it, so a success at or
-- over 600000 ms since 2026-08-18 is a cut-off run. Before 2026-08-18 there was no limit; those long runs
-- are genuine and untouched. Marking a run that in fact finished as failed costs only a re-read.
--
-- PART 1 — status. Sets status = 'failed' and prefixes notes on these runs. OLD VALUES (ingestion_runs.id):
--   status 'completed' (19):
--     128403,128405,128417,128418,128429,128638,128645,128721,128824,128847,128874,128909,128914,12909
--     5,129096,131143,131942,160983,319173
--   status 'completed_with_warning' (110):
--     128675,129123,129142,131140,131142,131320,132226,132472,132650,132765,135075,135122,135123,13564
--     4,135878,136401,137070,137073,137074,142583,142647,142831,143151,143339,143348,143933,145650,146
--     026,146779,148024,148105,148768,148771,150016,152011,155321,158360,160465,161410,161489,161556,1
--     63011,164466,164515,164546,164606,164629,167540,167565,167567,176334,179452,179454,181627,181680
--     ,204764,212335,218488,223508,226218,230545,231308,233344,234352,241500,241860,244381,244585,2527
--     84,282655,291909,292253,294690,300761,302971,303105,303343,305841,306233,307909,310173,310214,31
--     0741,310768,311292,311551,314701,314783,314797,314838,315006,315009,315090,315208,315320,315331,
--     317231,317254,317680,317866,317936,319161,319163,319165,319166,319168,319171,319373,319652,31966
--     8
--   notes are kept after the prefix, so the old notes stay readable on each row.
--
-- PART 2 — re-read. A source cut off and then refreshed by a genuine success still has the gap: that later
-- success read only from its own cursor. So for each of the 65 pairs this writes one marker row into
-- fec_fetch_checkpoints (CA_0410): committee_id '*', done = true, chain_started_at = the last genuine success
-- BEFORE the pair's first cut-off run (after part 1), or 2025-01-03 when there is none. An all-done chain is
-- read by planFecFetch as "fresh attempt from chain_started_at - 2 days", which is exactly the min_load_date
-- the first cut-off run used (2025-01-01, the cycle's start, for a first load). The next attempt clears the
-- marker; if it is cut off too, it saves real checkpoints with that same min_load_date and continues over
-- the following days. Overwrites nothing: the table is new and holds no row for these pairs.
--
-- Requires CA_0410 and the code in this PR deployed first; without the code the marker is ignored.

BEGIN;
SET LOCAL lock_timeout = '3s';
SET LOCAL statement_timeout = '2min';

CREATE TEMP TABLE ca0411_runs (id bigint PRIMARY KEY, old_status text NOT NULL) ON COMMIT DROP;
INSERT INTO ca0411_runs SELECT unnest('{128403,128405,128417,128418,128429,128638,128645,128721,128824,128847,128874,128909,128914,129095,129096,131143,131942,160983,319173}'::bigint[]), 'completed';
INSERT INTO ca0411_runs SELECT unnest('{128675,129123,129142,131140,131142,131320,132226,132472,132650,132765,135075,135122,135123,135644,135878,136401,137070,137073,137074,142583,142647,142831,143151,143339,143348,143933,145650,146026,146779,148024,148105,148768,148771,150016,152011,155321,158360,160465,161410,161489,161556,163011,164466,164515,164546,164606,164629,167540,167565,167567,176334,179452,179454,181627,181680,204764,212335,218488,223508,226218,230545,231308,233344,234352,241500,241860,244381,244585,252784,282655,291909,292253,294690,300761,302971,303105,303343,305841,306233,307909,310173,310214,310741,310768,311292,311551,314701,314783,314797,314838,315006,315009,315090,315208,315320,315331,317231,317254,317680,317866,317936,319161,319163,319165,319166,319168,319171,319373,319652,319668}'::bigint[]), 'completed_with_warning';

DO $$
BEGIN
  IF to_regclass('transparent_motivations.fec_fetch_checkpoints') IS NULL THEN
    RAISE EXCEPTION 'CA_0411: apply CA_0410 first';
  END IF;
  -- Every listed run must still be exactly as recorded above, and the list must be the whole class.
  IF (SELECT count(*) FROM ca0411_runs l JOIN transparent_motivations.ingestion_runs r ON r.id = l.id
       WHERE r.status = l.old_status AND r.adapter_name = 'fec' AND r.duration_ms >= 600000
         AND r.started_at >= '2026-08-18') <> 129 THEN
    RAISE EXCEPTION 'CA_0411: the 129 runs are no longer as recorded in this header';
  END IF;
  IF EXISTS (SELECT 1 FROM transparent_motivations.ingestion_runs r
              WHERE r.adapter_name = 'fec' AND r.status IN ('completed', 'completed_with_warning')
                AND r.duration_ms >= 600000 AND r.started_at >= '2026-08-18'
                AND r.id NOT IN (SELECT id FROM ca0411_runs)) THEN
    RAISE EXCEPTION 'CA_0411: a new cut-off success exists that this header does not list — re-measure';
  END IF;
  IF EXISTS (SELECT 1 FROM transparent_motivations.fec_fetch_checkpoints) THEN
    RAISE EXCEPTION 'CA_0411: fec_fetch_checkpoints is not empty — re-measure before writing markers';
  END IF;
END $$;

UPDATE transparent_motivations.ingestion_runs r
   SET status = 'failed',
       notes  = 'CA_0411: cut off by the 10-minute limit, not a success (was ' || l.old_status || ')'
                || CASE WHEN coalesce(r.notes, '') = '' THEN '' ELSE '; ' || r.notes END
  FROM ca0411_runs l
 WHERE r.id = l.id AND r.status = l.old_status;

INSERT INTO transparent_motivations.fec_fetch_checkpoints
  (politician_source_id, election_cycle, committee_id, min_load_date, last_indexes, rows_saved, done, chain_started_at)
SELECT f.politician_source_id, f.election_cycle, '*', NULL, NULL, 0, true,
       coalesce(
         (SELECT max(p.started_at) FROM transparent_motivations.ingestion_runs p
           WHERE p.politician_source_id = f.politician_source_id AND p.election_cycle = f.election_cycle
             AND p.adapter_name = 'fec' AND p.status IN ('completed', 'completed_with_warning')
             AND p.started_at < f.first_cut),
         timestamptz '2025-01-03 00:00:00+00')
  FROM (SELECT r.politician_source_id, r.election_cycle, min(r.started_at) AS first_cut
          FROM ca0411_runs l JOIN transparent_motivations.ingestion_runs r ON r.id = l.id
         GROUP BY 1, 2) f;

DO $$
BEGIN
  IF (SELECT count(*) FROM transparent_motivations.ingestion_runs r JOIN ca0411_runs l ON l.id = r.id
       WHERE r.status = 'failed' AND r.notes LIKE 'CA_0411:%') <> 129 THEN
    RAISE EXCEPTION 'CA_0411 verify: expected 129 runs marked failed';
  END IF;
  IF (SELECT count(*) FROM transparent_motivations.fec_fetch_checkpoints WHERE committee_id = '*' AND done) <> 65 THEN
    RAISE EXCEPTION 'CA_0411 verify: expected 65 re-read markers';
  END IF;
  IF (SELECT count(*) FROM transparent_motivations.fec_fetch_checkpoints
       WHERE chain_started_at = '2025-01-03 00:00:00+00') <> 15 THEN
    RAISE EXCEPTION 'CA_0411 verify: expected 15 first-load markers';
  END IF;
  RAISE NOTICE 'CA_0411 verify OK: 129 runs failed, 65 markers (15 from the cycle start)';
END $$;

COMMIT;
