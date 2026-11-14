-- CC_0422: one race per contest for Oregon's multi-seat council elections
--
-- WHAT IS WRONG
-- Seven Oregon contests elect several members at once, and we hold THREE race rows for each of
-- them -- 21 rows for 7 contests. The ballot is a single contest in every case:
--
--   City of Forest Grove, Council Members (Vote For 3)
--   City of Sherwood,     Council Members (Vote For 3)
--   City of Tigard,       Council Members (Vote For 3)
--   City of Maywood Park, Councilor (Vote For 3)
--   City of Troutdale,    Councilor (Vote For 3)
--   City of Portland, Councilor, District 3   -- "3 Seats Up for Election", multi-winner RCV
--   City of Portland, Councilor, District 4   -- "3 Seats Up for Election", multi-winner RCV
--
-- The first five are quoted from the Secretary of State's county exports (Washington and
-- Multnomah, 2026-11-13, committed under backend/data/local-races-2026-audit/sources). The two
-- Portland contests are quoted from Multnomah County's ranked-choice reports at rcvresults.multco.us.
--
-- 🔴🔴 THE COUNTY EXPORT'S `VoteFor` COLUMN IS WRONG FOR THE TWO RCV CONTESTS AND IS NOT USED.
--    It reads 1 for "City of Portland, Councilor, District 3", while the county's own RCV report
--    for that contest says "3 Seats Up for Election ... a multi-winner ranked choice voting contest
--    to elect 3 candidates", and names three winners. A reader that trusted that field would have
--    concluded four of our six Portland rows were off-cycle and deleted live seats -- the mistake
--    CC_0419 was written to correct, run in reverse, from a field that is correct in every ordinary
--    contest in the same file. The visible tell is that every RCV contest in the export carries
--    zero votes for every candidate, because the counts live elsewhere.
--
-- WHAT THIS DOES
-- CLAUDE.md's rule for a multi-member body is ONE RACE CARRYING `seats = N` against N offices. So
-- for each contest one race row is kept, renamed to the contest and given `seats = 3`, and the two
-- surplus rows are archived and deleted. 21 race rows become 7.
--
-- ⚠ THE OFFICES ARE NOT TOUCHED AND NOBODY IS UNSEATED. All 21 offices stay, all 21 keep their
--   holder. What goes is a duplicate representation of one contest, not a seat. The ballot never
--   assigned a candidate to a numbered seat in the first place -- the top three win -- which is
--   precisely why three race rows could not be filled honestly.
--
-- ⚠ THE KEPT RACE POINTS AT ONE OF THE THREE OFFICES, AND THAT CHOICE IS ARBITRARY. `races.office_id`
--   is not null-able and the contest belongs to all three seats equally; the office of the lowest
--   lettered or numbered seat is used. Nothing reads a multi-seat race's office_id as "the seat the
--   winner takes", and seating is a later act that will have to assign winners to offices on
--   evidence this ballot does not carry.
--
-- 🔴 OVERWRITTEN VALUES, RECORDED HERE BECAUSE NOTHING ELSE RECORDS THEM. Each kept race had
--    `seats = 1` and the position_name on the left:
--      17d6cce5-ddac-4127-8d8d-03ddcd2ed9ef  Forest Grove City Council Seat A        -> Forest Grove City Council
--      96757017-1342-445c-bd96-61001665be56  Maywood Park City Council Seat 1        -> Maywood Park City Council
--      ff402093-3aad-4d15-8440-11daf360a7e9  Portland City Council District 3 Seat A -> Portland City Council District 3
--      df1d7c03-3ee0-46c2-9e03-1a5b04629fe0  Portland City Council District 4 Seat A -> Portland City Council District 4
--      2b0e2732-ac82-4815-9ced-ea62980280f7  Sherwood City Council Seat A            -> Sherwood City Council
--      115c8ccb-aa65-4b7d-b323-3d86e8efbd93  Tigard City Council Seat A              -> Tigard City Council
--      0da8e1fd-cb33-4987-a5b1-519f5dbd76db  Troutdale City Council Seat 1           -> Troutdale City Council
--
-- 🔴 A DELETE IS FINAL AND THERE IS NO HISTORY TABLE, so the 14 rows are copied into
--    essentials._retired_cc0422_races first and the migration refuses unless the copy holds all 14.
--    Restore with:  INSERT INTO essentials.races SELECT id, election_id, office_id, position_name,
--                   primary_party, seats, description, created_at, updated_at
--                   FROM essentials._retired_cc0422_races;
--
-- Nothing here seeds a ballot; CC_0423 does that. Measured before applying: these 7 contests carry
-- 21 race rows and no candidate at all.

BEGIN;

-- ---------------------------------------------------------------------------------------------
-- 1. The archive. Guarded on the table not existing, for the reason CC_0419 gives: production
--    authenticates as ev_api, which holds DML on essentials and no DDL, so an unguarded DDL block
--    would make every tamper control die on a permission error instead of on the gate it aims at.
-- ---------------------------------------------------------------------------------------------
DO $ddl$
BEGIN
  IF to_regclass('essentials._retired_cc0422_races') IS NULL THEN
    EXECUTE $sql$
      CREATE TABLE essentials._retired_cc0422_races (
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
      COMMENT ON TABLE essentials._retired_cc0422_races IS
        'CC_0422 (2026-11-14): archive of the 14 surplus Oregon council race rows, two per contest, '
        'for seven 2026-11-03 contests that each elect three members on a single ballot line. The '
        'offices they pointed at were not touched. Nothing reads it. Restore: see the migration header.'
    $sql$;
    -- 🔴 ALTER DEFAULT PRIVILEGES IN SCHEMA essentials GRANTS anon AND authenticated SELECT ON EVERY
    --    NEW TABLE HERE -- measured on CC_0419's archive, which came up anon-readable although its
    --    GRANT named only ev_api. That is the inverse of the public-schema rule in CLAUDE.md. RLS
    --    with no policy is what actually stops the Data API; the revoke makes the intent explicit
    --    and the gate in step 5 asserts the end state.
    EXECUTE 'ALTER TABLE essentials._retired_cc0422_races ENABLE ROW LEVEL SECURITY';
    EXECUTE 'REVOKE ALL ON essentials._retired_cc0422_races FROM anon, authenticated';
    EXECUTE 'GRANT SELECT, INSERT, UPDATE, DELETE ON essentials._retired_cc0422_races TO ev_api';
  END IF;
END $ddl$;

-- ---------------------------------------------------------------------------------------------
-- 2. The 14 surplus rows, named explicitly rather than matched by a pattern.
--    A predicate reads the shape of a value: "position_name LIKE '%Seat%'" would also catch
--    Fairview's and Wood Village's numbered seats, which are SEPARATE contests on this same ballot
--    and must not be collapsed.
-- ---------------------------------------------------------------------------------------------
CREATE TEMP TABLE cc0422_surplus ON COMMIT DROP AS
SELECT id FROM (VALUES
  ('4eb3020a-6de4-453f-a802-022d6648958a'::uuid), ('d9b1ab18-cffd-4b42-830a-8c52a194cec1'::uuid),
  ('1dd1b734-ede3-41ef-ba2a-86514daaa55e'::uuid), ('3c2dc1f0-dca9-4a51-b91c-5c3f798e6188'::uuid),
  ('432fd604-5bfc-40f7-8e7a-0e9ed18542a4'::uuid), ('6859471e-9e32-4189-93b4-18f2110ac932'::uuid),
  ('31c3acde-d565-46de-8f01-1babddb42843'::uuid), ('db62f874-a34a-4131-9fde-f9336adb1944'::uuid),
  ('57f43c84-e807-4e41-a947-ff09bc166ae9'::uuid), ('d4f33c98-e601-4709-9044-dc767b6ad004'::uuid),
  ('e440f9f1-fedf-4376-a9e0-2242709f4c73'::uuid), ('54e778de-d835-40eb-be06-845401b7d9b6'::uuid),
  ('a17b3cae-a805-4e64-8ed1-f3ea8b15a3e7'::uuid), ('21b51712-a3f5-487c-8917-c8e6a4b26301'::uuid)
) AS v(id);

CREATE TEMP TABLE cc0422_keep ON COMMIT DROP AS
SELECT id, new_name FROM (VALUES
  ('17d6cce5-ddac-4127-8d8d-03ddcd2ed9ef'::uuid, 'Forest Grove City Council'),
  ('96757017-1342-445c-bd96-61001665be56'::uuid, 'Maywood Park City Council'),
  ('ff402093-3aad-4d15-8440-11daf360a7e9'::uuid, 'Portland City Council District 3'),
  ('df1d7c03-3ee0-46c2-9e03-1a5b04629fe0'::uuid, 'Portland City Council District 4'),
  ('2b0e2732-ac82-4815-9ced-ea62980280f7'::uuid, 'Sherwood City Council'),
  ('115c8ccb-aa65-4b7d-b323-3d86e8efbd93'::uuid, 'Tigard City Council'),
  ('0da8e1fd-cb33-4987-a5b1-519f5dbd76db'::uuid, 'Troutdale City Council')
) AS v(id, new_name);

-- ---------------------------------------------------------------------------------------------
-- 3. Refuse before touching anything.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE
  v_surplus int; v_keep int; v_cands int; v_deps int; v_sameoffice int;
BEGIN
  SELECT count(*) INTO v_surplus FROM cc0422_surplus s JOIN essentials.races r ON r.id = s.id;
  SELECT count(*) INTO v_keep    FROM cc0422_keep k    JOIN essentials.races r ON r.id = k.id;
  IF v_surplus <> 14 OR v_keep <> 7 THEN
    RAISE EXCEPTION 'CC_0422: found % surplus races and % to keep, expected 14 and 7. Re-measure.', v_surplus, v_keep;
  END IF;

  -- A surplus row carrying a candidacy would mean somebody has already recorded this ballot against
  -- the three-row shape, and collapsing it would destroy that work.
  SELECT count(*) INTO v_cands FROM essentials.race_candidates rc JOIN cc0422_surplus s ON s.id = rc.race_id;
  IF v_cands <> 0 THEN
    RAISE EXCEPTION 'CC_0422: % candidacies sit on the surplus race rows -- stop, somebody has seeded them.', v_cands;
  END IF;

  SELECT (SELECT count(*) FROM essentials.candidate_staging x JOIN cc0422_surplus s ON s.id=x.race_id)
       + (SELECT count(*) FROM essentials.discovered_sources x JOIN cc0422_surplus s ON s.id=x.race_id)
       + (SELECT count(*) FROM essentials.discovery_race_state x JOIN cc0422_surplus s ON s.id=x.race_id)
       + (SELECT count(*) FROM meetings.event_races x JOIN cc0422_surplus s ON s.id=x.race_id)
       + (SELECT count(*) FROM essentials.readrank_questions x JOIN cc0422_surplus s ON s.id=x.race_id)
       + (SELECT count(*) FROM essentials.readrank_race_pipeline x JOIN cc0422_surplus s ON s.id=x.race_id)
       + (SELECT count(*) FROM essentials.readrank_race_topic_questions x JOIN cc0422_surplus s ON s.id=x.race_id)
    INTO v_deps;
  IF v_deps <> 0 THEN
    RAISE EXCEPTION 'CC_0422: the surplus races are referenced % time(s) elsewhere. Deal with those rows first.', v_deps;
  END IF;

  -- Each kept race must share a district with the two it absorbs, or the wrong rows are being
  -- collapsed into one another.
  SELECT count(*) INTO v_sameoffice
    FROM cc0422_surplus s
    JOIN essentials.races rs ON rs.id = s.id
    JOIN essentials.offices os ON os.id = rs.office_id
   WHERE NOT EXISTS (
     SELECT 1 FROM cc0422_keep k JOIN essentials.races rk ON rk.id = k.id
       JOIN essentials.offices ok ON ok.id = rk.office_id
      WHERE ok.district_id = os.district_id);
  IF v_sameoffice <> 0 THEN
    RAISE EXCEPTION 'CC_0422: % surplus race(s) sit on a district no kept race shares.', v_sameoffice;
  END IF;
END $$;

-- ---------------------------------------------------------------------------------------------
-- 4. Archive, delete, then collapse the survivors onto the contest.
-- ---------------------------------------------------------------------------------------------
INSERT INTO essentials._retired_cc0422_races (
  id, election_id, office_id, position_name, primary_party, seats, description,
  created_at, updated_at, retired_note)
SELECT r.id, r.election_id, r.office_id, r.position_name, r.primary_party, r.seats, r.description,
       r.created_at, r.updated_at,
       'CC_0422: a surplus representation of a single multi-member contest. Oregon elected three '
       'members of this body on one ballot line in 2026, and the ballot assigns no candidate to a '
       'numbered seat, so the contest is held as one race with seats = 3. The office this row '
       'pointed at still exists and still has its holder.'
  FROM essentials.races r JOIN cc0422_surplus s ON s.id = r.id
 ON CONFLICT (id) DO NOTHING;

DELETE FROM essentials.races r USING cc0422_surplus s WHERE r.id = s.id;

UPDATE essentials.races r
   SET position_name = k.new_name, seats = 3
  FROM cc0422_keep k
 WHERE r.id = k.id AND (r.position_name <> k.new_name OR r.seats <> 3);

-- ---------------------------------------------------------------------------------------------
-- 5. Post-verify, on the end state.
-- ---------------------------------------------------------------------------------------------
DO $$
DECLARE
  v_archived int; v_kept int; v_stale int; v_offices int; v_held int;
  v_rls boolean; v_policies int; v_public int; v_unflagged int;
BEGIN
  SELECT count(*) INTO v_archived FROM essentials._retired_cc0422_races;
  IF v_archived <> 14 THEN
    RAISE EXCEPTION 'CC_0422: the archive holds % rows, not 14. Rows were deleted without being recorded.', v_archived;
  END IF;

  SELECT count(*) INTO v_kept
    FROM essentials.races r JOIN cc0422_keep k ON k.id = r.id
   WHERE r.position_name = k.new_name AND r.seats = 3;
  IF v_kept <> 7 THEN
    RAISE EXCEPTION 'CC_0422: % of the 7 contests read as one race with seats = 3, expected 7.', v_kept;
  END IF;

  -- No "Seat A/B/C" or "Seat 1/2/3" row may survive for any of the seven bodies.
  SELECT count(*) INTO v_stale
    FROM essentials.races r JOIN essentials.elections e ON e.id = r.election_id
   WHERE e.election_date = '2026-11-03'
     AND (r.position_name LIKE 'Forest Grove City Council Seat%'
       OR r.position_name LIKE 'Sherwood City Council Seat%'
       OR r.position_name LIKE 'Tigard City Council Seat%'
       OR r.position_name LIKE 'Maywood Park City Council Seat%'
       OR r.position_name LIKE 'Troutdale City Council Seat%'
       OR r.position_name LIKE 'Portland City Council District 3 Seat%'
       OR r.position_name LIKE 'Portland City Council District 4 Seat%');
  IF v_stale <> 0 THEN
    RAISE EXCEPTION 'CC_0422: % per-seat race row(s) survive for these bodies.', v_stale;
  END IF;

  -- 🔴 THE OFFICES MUST ALL STILL BE THERE AND ALL STILL BE HELD. 14 from the archive plus the 7
  --    the kept races point at = 21. count(och.politician_id), never count(*): the view LEFT JOINs
  --    from offices, so a vacancy is a row with a NULL politician and count(*) would pass over an
  --    emptied bench.
  SELECT count(*), count(och.politician_id) INTO v_offices, v_held
    FROM (SELECT office_id FROM essentials._retired_cc0422_races
          UNION ALL
          SELECT r.office_id FROM essentials.races r JOIN cc0422_keep k ON k.id = r.id) x
    JOIN essentials.offices o ON o.id = x.office_id
    LEFT JOIN essentials.office_current_holder och ON och.office_id = o.id;
  IF v_offices <> 21 OR v_held <> 21 THEN
    RAISE EXCEPTION 'CC_0422: the 21 council offices read % present / % held. Collapsing races must not touch occupancy.', v_offices, v_held;
  END IF;

  SELECT c.relrowsecurity INTO v_rls FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
   WHERE n.nspname = 'essentials' AND c.relname = '_retired_cc0422_races';
  SELECT count(*) INTO v_policies FROM pg_policies WHERE schemaname='essentials' AND tablename='_retired_cc0422_races';
  SELECT count(*) INTO v_public FROM information_schema.role_table_grants
   WHERE table_schema='essentials' AND table_name='_retired_cc0422_races' AND grantee IN ('anon','authenticated','PUBLIC');
  IF v_rls IS NOT TRUE OR v_policies <> 0 OR v_public <> 0 THEN
    RAISE EXCEPTION 'CC_0422: the archive reads rls=%, policies=%, anon/authenticated grants=% -- expected true / 0 / 0.', v_rls, v_policies, v_public;
  END IF;

  SELECT count(*) FILTER (WHERE NOT o.is_vacant) INTO v_unflagged
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  IF v_unflagged <> 238 THEN RAISE EXCEPTION 'CC_0422: drift baseline reads %, not 238.', v_unflagged; END IF;

  RAISE NOTICE 'CC_0422 OK: 14 surplus race rows archived and deleted, 7 contests now read as one race with seats = 3, 21 council offices all present and all held, drift baseline 238.';
END $$;

COMMIT;
