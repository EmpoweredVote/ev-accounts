-- CC_0419: remove the 15 Oregon State Senate races for seats that were never on the 2026 ballot
--
-- WHAT IS WRONG
-- We hold a 2026-11-03 race for all 30 Oregon Senate districts. Oregon elects half its Senate at a
-- time, so only 15 of those seats were on the ballot. The other 15 races assert an election that
-- did not take place: each has existed since 2026-05-30 with zero candidates, and after the
-- MA/ME/MD/OR/NV seeding wave they are the ENTIRE remaining unseeded-legislative backlog in the
-- country -- not a gap in our seeding, a claim about the world that is false.
--
-- WHY IT HAPPENED, IN ONE LINE
-- backend/migrations/generate_or_legislative_races.ps1 says so itself:
--     "# 30 Senate districts x 1 election + 60 House districts x 1 election = 90 rows"
--     for ($n = 1; $n -le 30; $n++) { ... }
-- It fans out one race per SEAT IN THE CHAMBER and has no notion of which seats are up. The House
-- loop is correct, because all 60 Oregon House seats are elected every two years. The Senate loop
-- is wrong by exactly half. That generator and migration 239 now carry a warning header; they are
-- NOT otherwise changed, and re-running either after this migration would recreate these 15 rows.
--
-- THE EVIDENCE -- THREE INDEPENDENT SOURCES THAT AGREE, NONE OF THEM AP'S SILENCE
--  1. THE RULE. Oregon Constitution, Article IV, Section 4, as published by the Legislature at
--     oregonlegislature.gov/bills_laws/Pages/OrConst.aspx:
--        "(1) The Senators shall be elected for the term of four years ...
--         (2) The Senators shall continue to be divided into two classes ... so that one-half, as
--             nearly as possible, of the number of Senators shall be elected biennially."
--  2. THE 2024 BALLOT. Oregon Secretary of State, "2024 November General Election Official
--     Results" (records.sos.state.or.us RecordViewer uri=13735458, 35pp). Its State Senator
--     section carries contests for districts
--        1, 2, 5, 9, 12, 14, 18, 21, 22, 23, 25, 27, 28, 29, 30
--     -- exactly the 15 deleted here. Reader and controls:
--     backend/data/or-senate-off-cycle/parse-2024-abstract.mjs.
--  3. THE 2026 BALLOT. AP's race feed and the Secretary of State's own Legislative Export both
--     carry 15 senate contests, for districts 3, 4, 6, 7, 8, 10, 11, 13, 15, 16, 17, 19, 20, 24,
--     26 -- seeded by CC_0416 and untouched here.
--  The two ballots PARTITION the chamber: 15 + 15 = 30, no district on both, none on neither.
--  That is a positive finding about which election each seat had, not an inference from an absence.
--
-- 🔴 THE DELETION IS BY AN EXPLICIT LIST OF DISTRICTS, NOT BY "HAS NO CANDIDATES".
--    A predicate reads the shape of a value, never what it is: "no candidates" is also the shape of
--    a race we simply have not seeded yet, and there are 50 such local races in production today.
--    The list below is the evidenced set. The zero-candidate condition is asserted as a GUARD on
--    top of it, so a district that turns out to carry a candidacy aborts the migration.
--
-- 🔴 A DELETE IS FINAL AND THERE IS NO HISTORY TABLE, so the rows are copied first into
--    essentials._retired_cc0419_races and the migration refuses unless the copy holds all 15.
--    Restore with:  INSERT INTO essentials.races SELECT id, election_id, office_id, position_name,
--                   primary_party, seats, description, created_at, updated_at
--                   FROM essentials._retired_cc0419_races;
--
-- THE ROWS REMOVED (race id / office id as they stood on 2026-11-13):
--   SD 1   race d7bc262e-27d6-441a-85c3-4cf65ef6d88e  office e319ea99-cbf5-40b3-a848-184c06e19f64  OR State Senate District 1
--   SD 2   race 9ab59dc2-5397-496d-9590-db42ed02cd65  office 5aba3d46-837e-414f-a543-e628464305d0  OR State Senate District 2
--   SD 5   race 6d1168b0-c679-4324-8430-d42cd1df91a8  office 8f73802b-4605-4b8a-9498-1300c3850d6e  OR State Senate District 5
--   SD 9   race bec4883b-f36c-499c-aadd-c1fda3df04cf  office 885d1897-c982-4fa2-bb3e-8d7245458699  OR State Senate District 9
--   SD 12  race ae58a527-28a6-4370-8431-5147332d60bb  office 3232f184-6046-44eb-872a-9a803e7fd52a  OR State Senate District 12
--   SD 14  race 27f04c74-71a2-4f2f-9de6-e90338bfad20  office 06c7c414-7a70-4663-bf00-d680b47da2a6  OR State Senate District 14
--   SD 18  race 34cc43fd-fa0d-4633-a021-76f68b24007d  office d5437527-9778-4266-a3ff-76ad667b3b67  OR State Senate District 18
--   SD 21  race 37b05113-ab91-4c89-abb6-3e247dc1b1cd  office 060a6033-0d01-4841-a284-7291d2b599b0  OR State Senate District 21
--   SD 22  race 9fb3f523-1f0b-4185-8ab6-b8de3c7f0ec8  office 77267bf2-d9ec-4823-a0d5-c450b407b6a2  OR State Senate District 22
--   SD 23  race 8f52c620-30ac-47ab-be3c-de4c18a6312d  office 96116c84-30e1-4c3c-a2b3-d317e5e358a5  OR State Senate District 23
--   SD 25  race 474e71cf-7af4-4404-a38a-d8e96f287227  office cd60a68c-b3ff-46db-ac5d-7e5a07d8a3a8  OR State Senate District 25
--   SD 27  race fb1d3005-2706-4478-bd18-b9294bfe9b24  office e7dc0d87-9c50-43af-abe1-5a4de7f8bb0b  OR State Senate District 27
--   SD 28  race fe2cb778-7b7c-4b14-8eee-f8a32e8523a6  office 47c4701c-9aaf-46b7-8e70-c50562bb7019  OR State Senate District 28
--   SD 29  race 13fe5c7d-a408-4e35-acd0-295a387a0b16  office e20be619-3175-4485-951e-02ca34e42992  OR State Senate District 29
--   SD 30  race afa74305-ade8-4902-8edd-e26fc03b6481  office 0a4e04b0-b975-496d-9d81-33e9bfa80aee  OR State Senate District 30
--
-- ⚠ NOBODY IS UNSEATED AND NO OFFICE IS TOUCHED. All 30 Oregon Senate offices stay, all 30 keep
--   their current holder, and all 15 of these seats are held by the person Oregon's own 2024
--   abstract records winning them. Occupancy is a dated row in office_terms and knows nothing
--   about races; the gates below assert that, and the drift baseline of 238 unflagged.
--   What changes is that these seats leave the race-keyed reads -- the 2026 transition tracker,
--   the headshot and stance counts, check:incumbency -- which is correct, because they are not in
--   the 2026 transition.

BEGIN;

-- ---------------------------------------------------------------------------------------------
-- 1. The archive. Same shape as essentials.races, plus why the row left.
--
-- ⚠ THE WHOLE DDL BLOCK IS GUARDED ON THE TABLE NOT EXISTING, AND THAT IS NOT DECORATION.
--   Production authenticates as ev_api, which holds DML on essentials and NO DDL at all -- measured:
--   `CREATE TABLE essentials._cc0419_ddl_probe (id int)` returns 42501, permission denied for
--   schema essentials. So this file can only be APPLIED through a privileged connection. Guarding
--   the four privileged statements on to_regclass means that once the archive exists the file
--   re-runs end to end as ev_api, which is how the tamper controls in
--   backend/data/or-senate-off-cycle/controls.mjs reach the gates below. Unguarded, every control
--   would die at this line on a permission error and prove nothing about the gate it aimed at --
--   a control that fails correctly, for the wrong reason.
-- ---------------------------------------------------------------------------------------------
DO $ddl$
BEGIN
  IF to_regclass('essentials._retired_cc0419_races') IS NULL THEN
    EXECUTE $sql$
      CREATE TABLE essentials._retired_cc0419_races (
        id            uuid PRIMARY KEY,
        election_id   uuid,
        office_id     uuid,
        position_name text,
        primary_party text,
        seats         integer,
        description   text,
        created_at    timestamptz,
        updated_at    timestamptz,
        retired_note  text NOT NULL
      )
    $sql$;
    EXECUTE $sql$
      COMMENT ON TABLE essentials._retired_cc0419_races IS
        'CC_0419 (2026-11-13): archive of the 15 OR State Senate races for 2026-11-03 held on '
        'districts 1,2,5,9,12,14,18,21,22,23,25,27,28,29,30, which Oregon did not put on the 2026 '
        'ballot (Or Const art IV s4: four-year terms, half the Senate elected biennially; those 15 '
        'were elected in 2024). Nothing reads it. Restore: see the migration header.'
    $sql$;
    -- RLS on with no policy, and a grant to ev_api only: the same shape as the other
    -- essentials._retired_* archives (CA_0206, CA_0286, CA_0287). Nothing voter-facing reads it,
    -- so anon and authenticated get nothing.
    --
    -- 🔴 THE REVOKE IS NOT BELT AND BRACES. `ALTER DEFAULT PRIVILEGES ... IN SCHEMA essentials`
    --    grants `anon=r, authenticated=r, ev_api=arwd` on EVERY new table in this schema --
    --    measured on this very table, which came up carrying anon SELECT although the GRANT below
    --    names only ev_api. The same default sits on civic, connect, meetings, treasury and
    --    transparent_motivations. So a new table here is anon-readable the moment it exists, and
    --    enabling RLS with no policy is the only thing standing between it and the Data API.
    --    That is the inverse of the `public`-schema rule in CLAUDE.md, and it is easy to read the
    --    wrong way round. The end state is asserted by the gate in step 5, which is what makes
    --    this true in an environment where the guard above was skipped.
    EXECUTE 'ALTER TABLE essentials._retired_cc0419_races ENABLE ROW LEVEL SECURITY';
    EXECUTE 'REVOKE ALL ON essentials._retired_cc0419_races FROM anon, authenticated';
    EXECUTE 'GRANT SELECT, INSERT, UPDATE, DELETE ON essentials._retired_cc0419_races TO ev_api';
  END IF;
END $ddl$;

-- ---------------------------------------------------------------------------------------------
-- 2. The target set, named once and used by every step below.
-- ---------------------------------------------------------------------------------------------
CREATE TEMP TABLE cc0419_target ON COMMIT DROP AS
SELECT r.id AS race_id,
       (regexp_replace(d.ocd_id, '^.*sldu:', ''))::int AS district
  FROM essentials.races r
  JOIN essentials.elections e ON e.id = r.election_id
  JOIN essentials.offices   o ON o.id = r.office_id
  JOIN essentials.districts d ON d.id = o.district_id
 WHERE lower(d.state) = 'or'
   AND d.district_type = 'STATE_UPPER'
   AND e.election_date = '2026-11-03'
   AND (regexp_replace(d.ocd_id, '^.*sldu:', ''))::int
       IN (1, 2, 5, 9, 12, 14, 18, 21, 22, 23, 25, 27, 28, 29, 30);

-- ---------------------------------------------------------------------------------------------
-- 3. Refuse before touching anything: the set must be the one that was measured.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE
  v_n            int;
  v_cands        int;
  v_staging      int;
  v_sources      int;
  v_discovery    int;
  v_events       int;
  v_rr_questions int;
  v_rr_pipeline  int;
  v_rr_topics    int;
BEGIN
  SELECT count(*) INTO v_n FROM cc0419_target;
  IF v_n <> 15 THEN
    RAISE EXCEPTION 'CC_0419: expected 15 off-cycle OR senate races, found %. Re-measure before deleting anything.', v_n;
  END IF;

  -- 🔴 The guard that makes the explicit list safe. A district on this list that turns out to
  --    carry a candidacy means the premise is wrong, and the migration stops rather than deleting
  --    a real ballot.
  SELECT count(*) INTO v_cands
    FROM essentials.race_candidates rc JOIN cc0419_target t ON t.race_id = rc.race_id;
  IF v_cands <> 0 THEN
    RAISE EXCEPTION 'CC_0419: % candidacies sit on races this migration would delete. Oregon put a candidate on a seat we believe was not up -- stop and re-read the ballot.', v_cands;
  END IF;

  -- Every other inbound foreign key, named one at a time. Two of them (candidate_staging,
  -- meetings.event_races) are NO ACTION and would raise anyway; the other five would cascade or
  -- null out in silence, which is the failure this block exists to prevent.
  SELECT count(*) INTO v_staging      FROM essentials.candidate_staging x JOIN cc0419_target t ON t.race_id = x.race_id;
  SELECT count(*) INTO v_sources      FROM essentials.discovered_sources x JOIN cc0419_target t ON t.race_id = x.race_id;
  SELECT count(*) INTO v_discovery    FROM essentials.discovery_race_state x JOIN cc0419_target t ON t.race_id = x.race_id;
  SELECT count(*) INTO v_events       FROM meetings.event_races x JOIN cc0419_target t ON t.race_id = x.race_id;
  SELECT count(*) INTO v_rr_questions FROM essentials.readrank_questions x JOIN cc0419_target t ON t.race_id = x.race_id;
  SELECT count(*) INTO v_rr_pipeline  FROM essentials.readrank_race_pipeline x JOIN cc0419_target t ON t.race_id = x.race_id;
  SELECT count(*) INTO v_rr_topics    FROM essentials.readrank_race_topic_questions x JOIN cc0419_target t ON t.race_id = x.race_id;

  IF v_staging + v_sources + v_discovery + v_events + v_rr_questions + v_rr_pipeline + v_rr_topics <> 0 THEN
    RAISE EXCEPTION 'CC_0419: these races are referenced elsewhere (staging %, sources %, discovery %, events %, readrank q/pipeline/topics %/%/%). Deal with those rows first.',
      v_staging, v_sources, v_discovery, v_events, v_rr_questions, v_rr_pipeline, v_rr_topics;
  END IF;
END $$;

-- ---------------------------------------------------------------------------------------------
-- 4. Archive, then delete. Both idempotent.
-- ---------------------------------------------------------------------------------------------
INSERT INTO essentials._retired_cc0419_races (
  id, election_id, office_id, position_name, primary_party, seats, description,
  created_at, updated_at, retired_note)
SELECT r.id, r.election_id, r.office_id, r.position_name, r.primary_party, r.seats, r.description,
       r.created_at, r.updated_at,
       'CC_0419: Oregon did not elect this seat on 2026-11-03. Or Const art IV s4 elects half the '
       'Senate biennially, and the Secretary of State''s 2024 November General Election Official '
       'Results carry this district''s contest. Scaffolded 2026-05-30 by migration 239, which '
       'created one race per seat in the chamber.'
  FROM essentials.races r
  JOIN cc0419_target t ON t.race_id = r.id
 ON CONFLICT (id) DO NOTHING;

DELETE FROM essentials.races r USING cc0419_target t WHERE r.id = t.race_id;

-- ---------------------------------------------------------------------------------------------
-- 5. Post-verify. Gated on the END STATE and on the delta, in this transaction.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE
  v_archived     int;
  v_rls          boolean;
  v_policies     int;
  v_public_grants int;
  v_left         int;
  v_left_set     int[];
  v_offices      int;
  v_held         int;
  v_vacant       int;
  v_unflagged    int;
  k_expected_2026 int[] := ARRAY[3, 4, 6, 7, 8, 10, 11, 13, 15, 16, 17, 19, 20, 24, 26];
BEGIN
  SELECT count(*) INTO v_archived FROM essentials._retired_cc0419_races;
  IF v_archived <> 15 THEN
    RAISE EXCEPTION 'CC_0419: the archive holds % rows, not 15. The rows were deleted without being recorded.', v_archived;
  END IF;

  -- The archive must not be reachable from the Data API. See the note in step 1: this schema hands
  -- anon a SELECT on every new table by default, so "I did not grant it" is not the same as
  -- "nobody has it".
  SELECT c.relrowsecurity INTO v_rls
    FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'essentials' AND c.relname = '_retired_cc0419_races';
  SELECT count(*) INTO v_policies
    FROM pg_policies WHERE schemaname = 'essentials' AND tablename = '_retired_cc0419_races';
  SELECT count(*) INTO v_public_grants
    FROM information_schema.role_table_grants
   WHERE table_schema = 'essentials' AND table_name = '_retired_cc0419_races'
     AND grantee IN ('anon', 'authenticated', 'PUBLIC');
  IF v_rls IS NOT TRUE OR v_policies <> 0 OR v_public_grants <> 0 THEN
    RAISE EXCEPTION 'CC_0419: the archive reads rls=%, policies=%, anon/authenticated grants=% -- expected true / 0 / 0.',
      v_rls, v_policies, v_public_grants;
  END IF;

  -- What is left must be the 2026 ballot, exactly -- not merely "fewer than before".
  SELECT count(*), array_agg((regexp_replace(d.ocd_id, '^.*sldu:', ''))::int ORDER BY (regexp_replace(d.ocd_id, '^.*sldu:', ''))::int)
    INTO v_left, v_left_set
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices   o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE lower(d.state) = 'or' AND d.district_type = 'STATE_UPPER' AND e.election_date = '2026-11-03';
  IF v_left <> 15 OR v_left_set IS DISTINCT FROM k_expected_2026 THEN
    RAISE EXCEPTION 'CC_0419: % OR senate races remain for 2026-11-03, districts % -- expected the 15 that were on the ballot, %.',
      v_left, v_left_set, k_expected_2026;
  END IF;

  -- Not one of them may now be empty: the whole point is that a 2026 senate race has a ballot.
  IF EXISTS (
    SELECT 1 FROM essentials.races r
      JOIN essentials.elections e ON e.id = r.election_id
      JOIN essentials.offices   o ON o.id = r.office_id
      JOIN essentials.districts d ON d.id = o.district_id
     WHERE lower(d.state) = 'or' AND d.district_type = 'STATE_UPPER' AND e.election_date = '2026-11-03'
       AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id)
  ) THEN
    RAISE EXCEPTION 'CC_0419: an OR senate race for 2026-11-03 still carries no candidate.';
  END IF;

  -- The chamber is untouched: 30 offices, 30 held, 0 flagged vacant.
  -- 🔴 count(och.politician_id), never count(*): office_current_holder LEFT JOINs from offices,
  --    so a vacancy is a row with a NULL politician and count(*) would pass over an empty chamber.
  SELECT count(*), count(och.politician_id), count(*) FILTER (WHERE o.is_vacant)
    INTO v_offices, v_held, v_vacant
    FROM essentials.offices o
    JOIN essentials.districts d ON d.id = o.district_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id
   WHERE lower(d.state) = 'or' AND d.district_type = 'STATE_UPPER';
  IF v_offices <> 30 OR v_held <> 30 OR v_vacant <> 0 THEN
    RAISE EXCEPTION 'CC_0419: the Oregon Senate reads % offices / % held / % flagged vacant -- expected 30 / 30 / 0. Deleting a race must not touch occupancy.',
      v_offices, v_held, v_vacant;
  END IF;

  -- The occupancy drift baseline, asserted rather than assumed.
  SELECT count(*) FILTER (WHERE NOT o.is_vacant) INTO v_unflagged
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  IF v_unflagged <> 238 THEN
    RAISE EXCEPTION 'CC_0419: the unflagged offices_missing_terms baseline reads %, not 238.', v_unflagged;
  END IF;

  RAISE NOTICE 'CC_0419 OK: 15 off-cycle OR senate races archived and deleted; 15 remain for 2026-11-03, all with candidates; Oregon Senate 30 offices / 30 held / 0 vacant; drift baseline 238.';
END $$;

COMMIT;
