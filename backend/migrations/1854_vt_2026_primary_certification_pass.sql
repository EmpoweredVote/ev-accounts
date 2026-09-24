-- 1854_vt_2026_primary_certification_pass.sql
--
-- Phase 167 (post-primary reconciliation), cluster 2 of 17: Vermont's U.S. Representative
-- At-Large race on the VT 2026 Statewide General (election a4ed60a8-fdfc-4093-93e3-44799d43f86b).
-- The seeding pass wrote the pre-primary field with provisional_until = 2026-08-11.
--
-- 🔴 THIS CLUSTER FOUND THE OPPOSITE DEFECT FROM THE ONE IT WENT LOOKING FOR.
-- The cull itself is one row. The finding is that OUR FIELD IS MISSING THREE CANDIDATES WHO
-- ARE ON VERMONT'S CERTIFIED GENERAL-ELECTION BALLOT. This migration therefore culls the one
-- row that is settled, records what is verified, and DELIBERATELY LEAVES THE RACE FLAGGED
-- rather than clearing provisional_until on a field it knows to be incomplete. Clearing the
-- flag here would turn "may be out of date" into "verified" on a race missing half its
-- independents, which is the one outcome this whole pass exists to prevent.
--
-- ============================================================================
-- THE SOURCE, AND WHY IT IS BETTER THAN A RESULTS FEED
-- ============================================================================
-- Vermont publishes the general-election field directly, so this cluster did not have to
-- infer it from primary results (fetched 2026-09-11):
--
--   2026_general_election_qualified_candidates.xlsx
--     outside.vermont.gov/dept/sos/Elections_Division/election_info_resources/candidates/
--     The Secretary of State's own list of who qualified for the 2026 General Election.
--     Under contest "REPRESENTATIVE TO CONGRESS" it holds SIX names:
--         PHOENIX K. ALTAIR      INDEPENDENT   Irasburg
--         BECCA BALINT           DEMOCRATIC    Brattleboro
--         GERALD MALLOY          REPUBLICAN    Weathersfield
--         ADAM ORTIZ             INDEPENDENT   Newport City
--         SUZANNE "SUZ" SEYMOUR  INDEPENDENT   Highgate
--         RYAN P. WALTON         INDEPENDENT   Rutland City
--
--   Vermont Election Night Results, AUGUST PRIMARY 2026-08-11, electionGuid
--   a18f77e0-89f8-4a01-8d97-61a7c75ba200, "isOfficial": true, feed lastUpdated
--   09/11/2026 04:36 AM (static.electionresults.vermont.gov/elections/<guid>.json ->
--   <guid>-f-<stamp>.json). Statewide totals aggregated over all 284 town rows:
--         DEMOCRATIC   BECCA BALINT   159,358   (nominee; write-ins Malloy 820, Coester 240)
--         REPUBLICAN   GERALD MALLOY   31,324   (nominee)
--                      MARK COESTER     9,046
--         PROGRESSIVE  no listed candidates; write-ins led by Balint 406
--
-- The two documents agree on the one disposition this migration writes: Coester lost the
-- Republican primary by 22,278 votes AND does not appear on the certified general list.
--
-- ============================================================================
-- WHAT IS MISSING, AND WHY THIS MIGRATION DOES NOT FIX IT
-- ============================================================================
-- Our field holds 4 rows: Ortiz, Balint, Malloy, Coester. Vermont's certified general field
-- holds 6. THREE INDEPENDENTS ARE ABSENT FROM OUR DATA ENTIRELY — Phoenix K. Altair,
-- Suzanne "Suz" Seymour and Ryan P. Walton. Independents never appear in a Vermont primary;
-- they petition straight onto the general ballot, so a pass built around primary results
-- cannot see them, and the seeding pass took the PRE-primary qualified list, which predates
-- their qualification.
--
-- Seeding them is not a cull. It needs politician records, the external_id scheme, headshots
-- and the federal stance set — the seeding methodology, not this one — so it is filed rather
-- than half-done here:
--   .planning/todos/2026-09-11-vt-cd-al-three-missing-independents.md
--
-- ============================================================================
-- DISPOSITION OF ALL 4 ROWS
-- ============================================================================
--   1  result = 'not_nominated'  Coester, and provisional_until cleared: he is settled
--   2  result = 'advanced'       Balint, Malloy — primary winners, on the certified list
--   1  result stays NULL         Ortiz — an independent who ran in no primary, so there is
--                                no primary result to record; his presence on the certified
--                                general list is recorded in last_verified_at instead
--
-- All three surviving rows keep provisional_until = 2026-09-18 BECAUSE THE FIELD IS
-- INCOMPLETE, not because anything about them is in doubt.
--
-- Idempotent: every UPDATE is guarded on the value it is about to write.

BEGIN;

-- ── 1. Mark Coester: lost the Republican primary, absent from the certified general list ────
UPDATE essentials.race_candidates rc
   SET result = 'not_nominated',
       result_source = 'Lost the Republican primary for U.S. Representative At-Large at the '
         || 'Vermont 2026 August Primary (2026-08-11): MALLOY 31,324, COESTER 9,046, statewide '
         || 'totals aggregated over all 284 town rows of the Vermont Election Night Results feed '
         || 'for electionGuid a18f77e0-89f8-4a01-8d97-61a7c75ba200, which carries '
         || '"isOfficial": true (static.electionresults.vermont.gov, feed lastUpdated 09/11/2026 '
         || '04:36 AM; fetched 2026-09-11). Confirmed by absence: he is NOT among the six names '
         || 'under "REPRESENTATIVE TO CONGRESS" in the Secretary of State''s 2026 General '
         || 'Election qualified-candidates list (outside.vermont.gov/dept/sos/Elections_Division/'
         || 'election_info_resources/candidates/2026_general_election_qualified_candidates.xlsx, '
         || 'fetched 2026-09-11).',
       result_recorded_at = now(),
       last_verified_at = now(),
       provisional_until = NULL,
       updated_at = now()
  FROM essentials.races r
 WHERE rc.race_id = r.id
   AND r.election_id = 'a4ed60a8-fdfc-4093-93e3-44799d43f86b'
   AND rc.full_name = 'Mark Coester'
   AND (rc.result IS DISTINCT FROM 'not_nominated' OR rc.provisional_until IS NOT NULL);

-- ── 2. Balint and Malloy: nominated, and on the certified general list ──────────────────────
UPDATE essentials.race_candidates rc
   SET result = 'advanced',
       result_source = v.src,
       result_recorded_at = now(),
       last_verified_at = now(),
       provisional_until = DATE '2026-09-18',
       updated_at = now()
  FROM (VALUES
        ('Becca Balint',
         'Democratic nominee for U.S. Representative At-Large, Vermont 2026 August Primary '
         || '(2026-08-11): BALINT 159,358, the only listed candidate in the Democratic primary. '
         || 'Statewide totals aggregated over all 284 town rows of the Vermont Election Night '
         || 'Results feed for electionGuid a18f77e0-89f8-4a01-8d97-61a7c75ba200, "isOfficial": '
         || 'true (feed lastUpdated 09/11/2026 04:36 AM; fetched 2026-09-11). Listed as '
         || 'DEMOCRATIC under "REPRESENTATIVE TO CONGRESS" in the Secretary of State''s 2026 '
         || 'General Election qualified-candidates list (fetched 2026-09-11).'),
        ('Gerald Malloy',
         'Republican nominee for U.S. Representative At-Large, Vermont 2026 August Primary '
         || '(2026-08-11): MALLOY 31,324 to COESTER 9,046. Statewide totals aggregated over all '
         || '284 town rows of the Vermont Election Night Results feed for electionGuid '
         || 'a18f77e0-89f8-4a01-8d97-61a7c75ba200, "isOfficial": true (feed lastUpdated '
         || '09/11/2026 04:36 AM; fetched 2026-09-11). Listed as REPUBLICAN under '
         || '"REPRESENTATIVE TO CONGRESS" in the Secretary of State''s 2026 General Election '
         || 'qualified-candidates list (fetched 2026-09-11).')
       ) AS v(name, src)
  JOIN essentials.races r ON r.election_id = 'a4ed60a8-fdfc-4093-93e3-44799d43f86b'
 WHERE rc.race_id = r.id
   AND rc.full_name = v.name
   AND (rc.result IS DISTINCT FROM 'advanced'
        OR rc.result_source IS DISTINCT FROM v.src
        OR rc.provisional_until IS DISTINCT FROM DATE '2026-09-18');

-- ── 3. Adam Ortiz: an independent, so no primary result exists to record ────────────────────
-- WA 1842 set the same shape for the four King County offices that held no primary: there is
-- no canvass line to cite, so writing 'advanced' would cite a contest that never happened.
UPDATE essentials.race_candidates rc
   SET last_verified_at = now(),
       provisional_until = DATE '2026-09-18',
       updated_at = now()
  FROM essentials.races r
 WHERE rc.race_id = r.id
   AND r.election_id = 'a4ed60a8-fdfc-4093-93e3-44799d43f86b'
   AND rc.full_name = 'Adam Ortiz'
   AND (rc.provisional_until IS DISTINCT FROM DATE '2026-09-18' OR rc.last_verified_at IS NULL);

-- ── POST-VERIFY ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n_rows int; n_adv int; n_not int; n_null int; n_live int; n_flagged int; n_nosrc int;
BEGIN
  SELECT count(*),
         count(*) FILTER (WHERE rc.result = 'advanced'),
         count(*) FILTER (WHERE rc.result = 'not_nominated'),
         count(*) FILTER (WHERE rc.result IS NULL),
         count(*) FILTER (WHERE essentials.is_live_candidate(rc.candidate_status, rc.result)),
         count(*) FILTER (WHERE rc.provisional_until = DATE '2026-09-18')
    INTO n_rows, n_adv, n_not, n_null, n_live, n_flagged
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'a4ed60a8-fdfc-4093-93e3-44799d43f86b';

  IF n_rows <> 4 THEN RAISE EXCEPTION 'expected 4 rows on this election, found %', n_rows; END IF;
  IF n_adv <> 2 THEN RAISE EXCEPTION 'expected 2 advanced (Balint, Malloy), found %', n_adv; END IF;
  IF n_not <> 1 THEN RAISE EXCEPTION 'expected 1 not_nominated (Coester), found %', n_not; END IF;
  IF n_null <> 1 THEN RAISE EXCEPTION 'expected 1 NULL result (Ortiz, no primary contest), found %', n_null; END IF;
  IF n_live <> 3 THEN RAISE EXCEPTION 'expected 3 live candidates after the cull, found %', n_live; END IF;

  -- 🔴 the field is KNOWN INCOMPLETE, so the three survivors must stay flagged
  IF n_flagged <> 3 THEN
    RAISE EXCEPTION 'expected the 3 surviving rows to stay flagged at 2026-09-18 while three '
      'certified independents are still missing; found % flagged', n_flagged;
  END IF;

  SELECT count(*) INTO n_nosrc
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'a4ed60a8-fdfc-4093-93e3-44799d43f86b'
     AND rc.result IS NOT NULL
     AND (rc.result_source IS NULL OR rc.result_source NOT LIKE '%2026-08-11%');
  IF n_nosrc > 0 THEN RAISE EXCEPTION '% result rows do not cite the 2026-08-11 primary', n_nosrc; END IF;

  RAISE NOTICE 'VT 2026 certification pass OK: % advanced, % not_nominated, % no-primary, % live of 4; '
    'race stays flagged pending 3 missing certified independents', n_adv, n_not, n_null, n_live;
END $$;

COMMIT;

-- ROLLBACK (the rows themselves were never deleted):
--   UPDATE essentials.race_candidates rc
--      SET result = NULL, result_source = NULL, result_recorded_at = NULL,
--          last_verified_at = NULL, provisional_until = DATE '2026-08-11', updated_at = now()
--     FROM essentials.races r
--    WHERE rc.race_id = r.id
--      AND r.election_id = 'a4ed60a8-fdfc-4093-93e3-44799d43f86b';
