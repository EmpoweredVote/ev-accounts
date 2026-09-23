-- CA_0157_merge_marshall_mckenzie_rehome_ca_governor_readrank.sql
-- Two small data cleanups left over from the LA County 2026 work.
--
-- ═══ A. Merge the duplicate "Patrice Marshall Mckenzie" row into the PUSD District 5 holder ═══
--
-- Two active politician rows describe one person:
--   KEEPER 2518c7a6-f526-4df2-8364-ded34b122f21  'Patrice Marshall McKenzie' (first 'Patrice', last
--          'Marshall McKenzie'), data_source pusd.us board page, created 2026-09-22 by CA_0153. Holds
--          the D5 seat (office_terms) and is the linked incumbent in CA_0155's D5 race.
--   SPARE  87ea3e5b-cf9e-4268-8b69-864aedf78b21  'Patrice Marshall Mckenzie' (first 'Patrice Marshall',
--          last 'Mckenzie'), source 'netfile_laco_2024', created 2026-05-22 by seed-la-county-netfile.ts.
--          Carries ONE thing: the confirmed campaign-finance link politician_sources 262ab47b-...
--          (la_county_netfile committee 1450349 "Patrice Marshall McKenzie for Board of Education 2026",
--          53 contributions, 2 contribution_summary_agg rows). No term, race, image, answer or quote.
-- CA_0153 should have reused the NetFile row (house rule) but the name split differs, so
-- politicians_name_duplicate_guard did not see it. The keeper stays, because it is the row every
-- seat / race / read path already uses; the finance link moves to it. Contributions and the summary
-- agg are keyed by politician_source_id and joined to the politician through
-- politician_sources.essentials_politician_id at read time (campaignFinanceService getSummaryFromAgg),
-- so re-pointing that one column carries all 53 contributions over with nothing to refresh. The
-- spare is then deleted, after the gate re-scans EVERY uuid column named politician_id /
-- essentials_politician_id / essentials_id (FK or not -- essentials.quotes has no FK) and finds none.
-- Deleted row, for the record: full_name 'Patrice Marshall Mckenzie', first 'Patrice Marshall',
-- last 'Mckenzie', source 'netfile_laco_2024', is_active true, all other columns NULL/default.
--
-- ═══ B. Re-home the CA Governor Read & Rank material onto the November general race ═══
--
-- The office-less 'CA Governor' race bc936a36-287c-4ffd-abd8-5e4fd798bae5 carries the 65-name JUNE 2
-- PRIMARY field. CA_0129 (2026-09-21) moved it off 'CA 2026 Statewide General' onto 'CA 2026 Statewide
-- Primary' and seeded the certified top-two race bec5ef3b-095b-4d7d-9117-db81e407cb5e (Becerra v
-- Hilton) in its place. A note from that work said to "fully delete the parked race". THAT IS WRONG
-- and this migration does not do it: the race is the ONLY record of the June governor primary, and it
-- owns 364 candidate_staging rows, 21 meetings.event_races links, 2 discovered_sources, and -- the
-- part that matters -- the whole Read & Rank setup for the seat, which a DELETE would CASCADE away:
--   * readrank_race_pipeline a408f617 (status 'published', label "CA Governor (CA, 2026-11-03)",
--     election_kind 'general', 7 rankable topics, 2 quoted candidates)
--   * 25 confirmed readrank_questions
--   * 2 readrank_race_topic_questions overrides (fossil-fuels, voting-rights)
-- The new general race owns none of it, AND its two candidates were seeded with politician_id NULL,
-- so Read & Rank (which joins quotes on politician_id, readrankService.ts) cannot serve it at all.
--
-- Same defect and same fix as the LA Mayor race in 1803 (pipeline row) and 1813 (questions):
--   B1. Link the general race's Xavier Becerra and Steve Hilton to their existing rows (0f74219c...,
--       9a60d603..., source calmatters_2026 -- the only active row for each name, and the rows the
--       primary race and every quote already use).
--   B2. Repoint the pipeline row, the 25 questions and the 2 topic overrides to the general race.
-- REPOINT, not copy -- 1813's reasoning holds: quotes.question_id points at these question rows, so
-- copies would be empty shells. Nothing is lost: all 97 quotes attached to the 25 questions belong to
-- Becerra (52) or Hilton (45), both live candidates on the general race (asserted below), and the
-- coverage the primary grid showed pre-flight (rankable 7 / surfaced 16 / answering 23) must come
-- out identical on the general.
-- The primary race itself, its 65 candidates, staging rows, event links and discovered_sources are
-- untouched: they describe the June primary. The frontend buckets it as past by election_date.
--
-- IDEMPOTENT: every UPDATE is guarded on the old value; the DELETE runs only while the spare exists.

BEGIN;

-- ─── A1. Move the finance source link to the keeper ────────────────────────────────────
UPDATE transparent_motivations.politician_sources
   SET essentials_politician_id = '2518c7a6-f526-4df2-8364-ded34b122f21'
 WHERE id = '262ab47b-e3e1-4df6-bde2-871181e439cc'
   AND essentials_politician_id = '87ea3e5b-cf9e-4268-8b69-864aedf78b21';

-- ─── A2. Delete the spare once NOTHING references it ───────────────────────────────────
DO $$
DECLARE r record; n bigint; n_refs bigint := 0; hits text := '';
BEGIN
  IF NOT EXISTS (SELECT 1 FROM essentials.politicians WHERE id = '87ea3e5b-cf9e-4268-8b69-864aedf78b21') THEN
    RAISE NOTICE 'CA_0157 A: spare already removed -- no-op';
    RETURN;
  END IF;
  FOR r IN SELECT c.table_schema, c.table_name, c.column_name
             FROM information_schema.columns c
             JOIN information_schema.tables t ON t.table_schema = c.table_schema AND t.table_name = c.table_name
            WHERE t.table_type = 'BASE TABLE' AND c.data_type = 'uuid'
              AND c.column_name IN ('politician_id', 'essentials_politician_id', 'essentials_id')
              AND c.table_schema NOT IN ('pg_catalog', 'information_schema')
  LOOP
    EXECUTE format('SELECT count(*) FROM %I.%I WHERE %I = %L', r.table_schema, r.table_name, r.column_name,
                   '87ea3e5b-cf9e-4268-8b69-864aedf78b21') INTO n;
    IF n > 0 THEN n_refs := n_refs + n; hits := hits || r.table_schema || '.' || r.table_name || '.' || r.column_name || '=' || n || ' '; END IF;
  END LOOP;
  IF n_refs <> 0 THEN
    RAISE EXCEPTION 'aborting: the spare row is still referenced: %', hits;
  END IF;
  DELETE FROM essentials.politicians
   WHERE id = '87ea3e5b-cf9e-4268-8b69-864aedf78b21'
     AND full_name = 'Patrice Marshall Mckenzie' AND source = 'netfile_laco_2024';
END $$;

-- ─── B1. Link the general race's two candidates ────────────────────────────────────────
UPDATE essentials.race_candidates rc
   SET politician_id = v.pid, updated_at = now()
  FROM (VALUES ('489d991b-3491-4140-b8d9-007d633939fa'::uuid, '0f74219c-7d10-4d29-85fe-0f1d834df8a7'::uuid, 'Xavier Becerra'),
               ('b9e15610-016d-4225-b8f5-77f68d155c4f'::uuid, '9a60d603-194d-410f-ae01-85bd6293f1a7'::uuid, 'Steve Hilton')
       ) AS v(rc_id, pid, full_name)
 WHERE rc.id = v.rc_id
   AND rc.race_id = 'bec5ef3b-095b-4d7d-9117-db81e407cb5e'
   AND rc.full_name = v.full_name
   AND rc.politician_id IS NULL;

-- ─── B2. Repoint the Read & Rank material ──────────────────────────────────────────────
UPDATE essentials.readrank_race_pipeline
   SET race_id = 'bec5ef3b-095b-4d7d-9117-db81e407cb5e', updated_at = now()
 WHERE id = 'a408f617-480c-4050-9040-a683ada87eb0'
   AND race_id = 'bc936a36-287c-4ffd-abd8-5e4fd798bae5';

UPDATE essentials.readrank_questions
   SET race_id = 'bec5ef3b-095b-4d7d-9117-db81e407cb5e', updated_at = now(),
       updated_by = 'migration-CA_0157-rehome-ca-governor'
 WHERE race_id = 'bc936a36-287c-4ffd-abd8-5e4fd798bae5';

UPDATE essentials.readrank_race_topic_questions t
   SET race_id = 'bec5ef3b-095b-4d7d-9117-db81e407cb5e', updated_at = now(), updated_by = 'migration:CA_0157'
 WHERE t.race_id = 'bc936a36-287c-4ffd-abd8-5e4fd798bae5'
   AND NOT EXISTS (SELECT 1 FROM essentials.readrank_race_topic_questions g
                    WHERE g.race_id = 'bec5ef3b-095b-4d7d-9117-db81e407cb5e' AND g.topic_key = t.topic_key);

-- ─── Post-verify gate ──────────────────────────────────────────────────────────────────
DO $$
DECLARE
  n_spare int; n_src int; n_contrib int; n_seat int; n_d5 int;
  n_live int; n_linked int; n_pipe int; n_q_old int; n_q_new int; n_t_old int; n_t_new int;
  n_stranded int; n_rankable int; n_surfaced int; n_answering int; n_dupes int; n_parked int;
BEGIN
  -- A
  SELECT count(*) INTO n_spare FROM essentials.politicians WHERE id = '87ea3e5b-cf9e-4268-8b69-864aedf78b21';
  SELECT count(*) INTO n_src FROM transparent_motivations.politician_sources
   WHERE essentials_politician_id = '2518c7a6-f526-4df2-8364-ded34b122f21' AND research_status = 'confirmed';
  SELECT count(*) INTO n_contrib FROM transparent_motivations.contributions c
    JOIN transparent_motivations.politician_sources ps ON ps.id = c.politician_source_id
   WHERE ps.essentials_politician_id = '2518c7a6-f526-4df2-8364-ded34b122f21';
  SELECT count(*) INTO n_seat FROM essentials.office_current_holder
   WHERE office_id = '87635aa2-79bc-4d7d-b087-afb697329210' AND politician_id = '2518c7a6-f526-4df2-8364-ded34b122f21';
  SELECT count(*) INTO n_d5 FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.position_name = 'Pasadena Unified School Board - District 5'
     AND r.election_id = 'd91a20ce-557e-4615-a31b-5b2b3df2ed14'
     AND rc.politician_id = '2518c7a6-f526-4df2-8364-ded34b122f21';

  -- B
  SELECT count(*) FILTER (WHERE essentials.is_live_candidate(rc.candidate_status, rc.result)),
         count(*) FILTER (WHERE (rc.full_name, rc.politician_id) IN
                            (('Xavier Becerra', '0f74219c-7d10-4d29-85fe-0f1d834df8a7'::uuid),
                             ('Steve Hilton', '9a60d603-194d-410f-ae01-85bd6293f1a7'::uuid)))
    INTO n_live, n_linked
    FROM essentials.race_candidates rc WHERE rc.race_id = 'bec5ef3b-095b-4d7d-9117-db81e407cb5e';
  SELECT count(*) INTO n_pipe FROM essentials.readrank_race_pipeline
   WHERE id = 'a408f617-480c-4050-9040-a683ada87eb0' AND race_id = 'bec5ef3b-095b-4d7d-9117-db81e407cb5e';
  SELECT count(*) INTO n_q_old FROM essentials.readrank_questions WHERE race_id = 'bc936a36-287c-4ffd-abd8-5e4fd798bae5';
  SELECT count(*) INTO n_q_new FROM essentials.readrank_questions WHERE race_id = 'bec5ef3b-095b-4d7d-9117-db81e407cb5e';
  SELECT count(*) INTO n_t_old FROM essentials.readrank_race_topic_questions WHERE race_id = 'bc936a36-287c-4ffd-abd8-5e4fd798bae5';
  SELECT count(*) INTO n_t_new FROM essentials.readrank_race_topic_questions WHERE race_id = 'bec5ef3b-095b-4d7d-9117-db81e407cb5e';

  -- every quote on a question the general race now owns belongs to a live general candidate (1813)
  SELECT count(*) INTO n_stranded
    FROM essentials.quotes q JOIN essentials.readrank_questions rq ON rq.id = q.question_id
   WHERE rq.race_id = 'bec5ef3b-095b-4d7d-9117-db81e407cb5e'
     AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc
                      WHERE rc.race_id = 'bec5ef3b-095b-4d7d-9117-db81e407cb5e' AND rc.politician_id = q.politician_id
                        AND essentials.is_live_candidate(rc.candidate_status, rc.result));

  -- coverage carried over intact (listRaceQuestions() predicates, as in 1813)
  SELECT count(*) FILTER (WHERE answering >= 2), count(*) FILTER (WHERE answering >= 1), COALESCE(sum(answering), 0)
    INTO n_rankable, n_surfaced, n_answering
    FROM (SELECT rq.id, count(DISTINCT rc.politician_id) AS answering
            FROM essentials.readrank_questions rq
            LEFT JOIN essentials.quotes q ON q.question_id = rq.id AND q.readrank_selected = true AND q.deidentified_text IS NOT NULL
            LEFT JOIN essentials.race_candidates rc ON rc.race_id = rq.race_id AND rc.politician_id = q.politician_id
                   AND essentials.is_live_candidate(rc.candidate_status, rc.result)
           WHERE rq.race_id = 'bec5ef3b-095b-4d7d-9117-db81e407cb5e' AND rq.status = 'confirmed'
           GROUP BY rq.id) s;

  SELECT count(*) INTO n_dupes FROM (
    SELECT 1 FROM essentials.readrank_questions WHERE race_id = 'bec5ef3b-095b-4d7d-9117-db81e407cb5e'
     GROUP BY topic_key, question_text HAVING count(*) > 1) d;

  -- the June primary race is still there, whole
  SELECT count(*) INTO n_parked FROM essentials.race_candidates WHERE race_id = 'bc936a36-287c-4ffd-abd8-5e4fd798bae5';

  IF n_spare <> 0 THEN RAISE EXCEPTION 'A: spare Marshall Mckenzie row still present'; END IF;
  IF n_src <> 1 OR n_contrib <> 53 THEN RAISE EXCEPTION 'A: keeper has % confirmed source(s) / % contribution(s), expected 1 / 53', n_src, n_contrib; END IF;
  IF n_seat <> 1 OR n_d5 <> 1 THEN RAISE EXCEPTION 'A: keeper no longer holds D5 (%) or is not the D5 candidate (%)', n_seat, n_d5; END IF;
  IF n_live <> 2 OR n_linked <> 2 THEN RAISE EXCEPTION 'B: general Governor race has % live / % correctly linked candidates, expected 2 / 2', n_live, n_linked; END IF;
  IF n_pipe <> 1 THEN RAISE EXCEPTION 'B: pipeline row does not point at the general race'; END IF;
  IF n_q_old <> 0 OR n_q_new <> 25 THEN RAISE EXCEPTION 'B: questions old/new = %/%, expected 0/25', n_q_old, n_q_new; END IF;
  IF n_t_old <> 0 OR n_t_new <> 2 THEN RAISE EXCEPTION 'B: topic overrides old/new = %/%, expected 0/2', n_t_old, n_t_new; END IF;
  IF n_stranded <> 0 THEN RAISE EXCEPTION 'B: % quote(s) belong to someone not live on the general race', n_stranded; END IF;
  IF (n_rankable, n_surfaced, n_answering) <> (7, 16, 23) THEN
    RAISE EXCEPTION 'B: coverage rankable/surfaced/answering = %/%/%, expected 7/16/23', n_rankable, n_surfaced, n_answering;
  END IF;
  IF n_dupes <> 0 THEN RAISE EXCEPTION 'B: % duplicate question group(s) on the general race', n_dupes; END IF;
  IF n_parked <> 65 THEN RAISE EXCEPTION 'B: the June primary race now has % candidates, expected 65 (untouched)', n_parked; END IF;
  RAISE NOTICE 'CA_0157 applied: spare merged (53 contributions on keeper); Governor read-rank re-homed (25 q, 2 overrides, coverage 7/16/23)';
END $$;

COMMIT;
