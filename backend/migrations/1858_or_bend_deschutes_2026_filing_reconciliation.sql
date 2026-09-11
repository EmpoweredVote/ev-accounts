-- 1858_or_bend_deschutes_2026_filing_reconciliation.sql
--
-- Phase 167 (post-primary reconciliation), cluster 5 of 17: the 15 provisional rows in Oregon,
-- on the OR 2026 General (election de10e3a7-f5c2-47e6-acd7-ee87be9413db).
--
-- 🔴 OREGON IS NOT A POST-PRIMARY CULL AT ALL, AND THE SEEDING NOTE SAID SO.
-- Every provisional row here is a Bend city or Deschutes County nonpartisan race, seeded
-- 2026-07-24 with the source string "provisional -- pre-deadline field ... cull >= 2026-08-29
-- (OR filing closed 2026-08-25 / 2026-08-18 elected incumbents; withdrawals 2026-08-28)".
-- The field was captured BEFORE filing closed. So the job is not to remove primary losers —
-- there was no primary — it is to re-read the final filed field and reconcile both directions.
--
-- Reconciling it that way found FOUR CANDIDATES MISSING FROM OUR DATA and TWO WITHDRAWALS WE
-- WERE STILL SHOWING. The worst single row: the only candidate we carry for Deschutes County
-- Treasurer withdrew on 2026-08-05, while the two people actually running are absent.
--
-- ============================================================================
-- SOURCES (both the elections officials for these contests; fetched 2026-09-11)
-- ============================================================================
--   Deschutes County Clerk, "November 3, 2026 General Election", section "Filed Candidates
--   (Nonpartisan Positions)"  —  deschutes.org/1593/November-3-2026-General-Election
--       County Clerk, 4 year term (moved to the General Election as fewer than three
--         candidates filed for the Primary):  Jonathan Curtis, Steve Dennison
--       County Commissioner Position #3, 4 year term:  Lauren Connally, Amy Sabbadini
--       County Commissioner Position #5, 2 year term:  Rob Imhoff, Morgan Schmidt
--       County Sheriff, 4 year term (also moved to the General):  James (Mac) McLaughlin,
--         Ty Rupert
--       County Treasurer, 4 year term (vacancy in nomination, OAR 165-010-0110; filing period
--         2026-08-12 to 2026-08-25):  Jana Cain, Cam Sparks,
--         "Robert Tintle (Withdrew candidacy 8/5/2026)"
--
--   City of Bend, "Bend City Council Elections - November 3, 2026"  —  bendoregon.gov
--       "Candidate filings closed at 5:00 p.m. on August 25, 2026 and the deadline to withdraw
--        was August 28, 2026."  Status column, verbatim:
--         #5     Ariel Mendez          "Eligible, Qualified & Certified for Ballot - will be on Nov. 3 ballot"
--         #6     Bobbi Cummiskey       "Eligible, Qualified & Certified for Ballot - withdrew"
--         #6     Elana Reinholtz       "Eligible, Qualified & Certified for Ballot - will be on Nov. 3 ballot"
--         #6     Dan Sorrells          "Eligible & Qualified"
--         #6     Nic Tarter            "Eligible & Qualified"
--         #7 Mayor  Melanie Kebler     "Eligible, Qualified & Certified for Ballot - will be on Nov. 3 ballot"
--         #7 Mayor  Ron (Rondo) Boozell "Eligible & Qualified"
--         #7 Mayor  Bernadette Strome  "Eligible, Qualified & Certified for Ballot - will be on Nov. 3 ballot"
--
-- ============================================================================
-- 🔴 WHAT IS MISSING FROM OUR FIELD (none of it fixable by a cull)
-- ============================================================================
--   Bernadette Strome   Bend Mayor          CERTIFIED FOR THE BALLOT and absent from our data
--   Nic Tarter          Bend Council #6     "Eligible & Qualified", absent from our data
--   Jana Cain           Deschutes Treasurer filed in the 08/12-08/25 vacancy window, absent
--   Cam Sparks          Deschutes Treasurer filed in the same window, absent
--   .planning/todos/2026-09-11-or-bend-deschutes-four-missing-candidates.md
--
-- ⚠ AFTER THIS MIGRATION, DESCHUTES COUNTY TREASURER RENDERS WITH NO CANDIDATES AT ALL. Its
-- one row is the withdrawal. That is better than publishing a withdrawn candidate as the only
-- name in a race, but it is not good: the staleness flag lives on candidate rows, so a race
-- with no live rows has no way to say "we are missing everyone". Recorded, not worked around.
--
-- ============================================================================
-- 🔴 THE ONE JUDGEMENT CALL: "Eligible & Qualified" WITHOUT "Certified for Ballot"
-- ============================================================================
-- Three Bend candidates sit in that state: Dan Sorrells and Nic Tarter (#6) and Ron (Rondo)
-- Boozell (Mayor). Filing closed 2026-08-25 and withdrawals closed 2026-08-28, both weeks ago,
-- so the distinction is not a timing artefact of an un-updated page — but the page does not
-- say what it means, and the county defers to the city for these contests rather than
-- publishing its own Bend list. It could mean certification is outstanding, or that they will
-- not appear on the ballot.
-- OUR TWO ROWS IN THAT STATE (Sorrells, Boozell) ARE HELD, NOT CULLED: result stays NULL,
-- provisional_until 2026-09-25. Removing a qualified candidate from a ballot view on an
-- unexplained status word is exactly the call 1842 refused to make for LD 42.
--
-- ============================================================================
-- DISPOSITION OF ALL 15 ROWS
-- ============================================================================
--    2  result = 'withdrew'    Cummiskey (Bend #6) and Tintle (Treasurer), both by name in
--                              the election official's own list, with dates
--   11  result stays NULL      confirmed present on the filed/certified list. These are
--                              nonpartisan races with no primary contest, so there is no
--                              primary outcome to record — the same shape 1842 used for the
--                              four King County offices that held no primary
--    2  result stays NULL      Sorrells and Boozell, HELD on the status question above
-- Live field afterwards: 13 of 15.
--
-- Flags: cleared on the four races that reconcile exactly (Bend #5, County Clerk,
-- Commissioner #3, Commissioner #5, Sheriff — five races). KEPT at 2026-09-18 on Bend #6 and
-- Bend Mayor, which are missing certified or qualified candidates.
--
-- Nothing is hard-deleted and no politician row is deactivated.
-- Idempotent: every UPDATE is guarded on the value it is about to write.

BEGIN;

CREATE TEMP TABLE or_target (
  position_name text NOT NULL,
  our_name      text NOT NULL,
  disposition   text NOT NULL CHECK (disposition IN ('withdrew','confirmed','held')),
  keep_flag     boolean NOT NULL,
  why           text NOT NULL
) ON COMMIT DROP;

INSERT INTO or_target (position_name, our_name, disposition, keep_flag, why) VALUES
  -- Bend City Council Position 5 — reconciles exactly, flag cleared
  ('Bend City Council Position 5', 'Ariel Méndez', 'confirmed', false,
   'City of Bend candidate list: Position #5, Ariel Mendez, "Eligible, Qualified & Certified for Ballot - will be on Nov. 3 ballot". He is the only filer for the position, so this race reconciles exactly.'),

  -- Bend City Council Position 6 — Cummiskey withdrew; Tarter missing; Sorrells held
  ('Bend City Council Position 6', 'Bobbi Cummiskey', 'withdrew', false,
   'City of Bend candidate list: Position #6, Bobbi Cummiskey, "Eligible, Qualified & Certified for Ballot - withdrew". Bend states filings closed 5:00 p.m. 2026-08-25 and the withdrawal deadline was 2026-08-28.'),
  ('Bend City Council Position 6', 'Elana Reinholtz', 'confirmed', true,
   'City of Bend candidate list: Position #6, Elana Reinholtz, "Eligible, Qualified & Certified for Ballot - will be on Nov. 3 ballot". The race stays flagged because Nic Tarter, listed "Eligible & Qualified" for the same position, is absent from our field.'),
  ('Bend City Council Position 6', 'Dan Sorrells', 'held', true,
   'HELD. City of Bend lists him "Eligible & Qualified" without the "Certified for Ballot" clause the three ballot-bound candidates carry. The page does not define the difference and the county defers to the city for Bend contests, so this row is not culled on an unexplained status word.'),

  -- Bend Mayor — Strome missing; Boozell held
  ('Bend Mayor', 'Melanie Kebler', 'confirmed', true,
   'City of Bend candidate list: Position #7, Mayor, Melanie Kebler, "Eligible, Qualified & Certified for Ballot - will be on Nov. 3 ballot". The race stays flagged because Bernadette Strome, carrying the SAME certified status, is absent from our field.'),
  ('Bend Mayor', 'Ron (Rondo) Boozell', 'held', true,
   'HELD. City of Bend lists him "Eligible & Qualified" without the "Certified for Ballot" clause. Same unresolved status question as Dan Sorrells.'),

  -- Deschutes County Clerk — reconciles exactly
  ('Deschutes County Clerk', 'Jonathan Curtis', 'confirmed', false,
   'Deschutes County Clerk''s filed-candidate list for the 2026-11-03 General: "County Clerk, 4 year term (This contest moved to the General Election as fewer than three candidates filed for the Primary Election): Jonathan Curtis, Steve Dennison". Both filers are in our field.'),
  ('Deschutes County Clerk', 'Steve Dennison', 'confirmed', false,
   'Deschutes County Clerk''s filed-candidate list for the 2026-11-03 General: "County Clerk, 4 year term ...: Jonathan Curtis, Steve Dennison". Both filers are in our field.'),

  -- Deschutes County Commissioner Position 3 — reconciles exactly
  ('Deschutes County Commissioner Position 3', 'Lauren Connally', 'confirmed', false,
   'Deschutes County Clerk''s filed-candidate list: "County Commissioner Position #3, 4 year term: Lauren Connally, Amy Sabbadini". Both filers are in our field.'),
  ('Deschutes County Commissioner Position 3', 'Amy Sabbadini', 'confirmed', false,
   'Deschutes County Clerk''s filed-candidate list: "County Commissioner Position #3, 4 year term: Lauren Connally, Amy Sabbadini". Both filers are in our field.'),

  -- Deschutes County Commissioner Position 5 — reconciles exactly
  ('Deschutes County Commissioner Position 5', 'Rob Imhoff', 'confirmed', false,
   'Deschutes County Clerk''s filed-candidate list: "County Commissioner Position #5, 2 year term: Rob Imhoff, Morgan Schmidt". Both filers are in our field.'),
  ('Deschutes County Commissioner Position 5', 'Morgan Schmidt', 'confirmed', false,
   'Deschutes County Clerk''s filed-candidate list: "County Commissioner Position #5, 2 year term: Rob Imhoff, Morgan Schmidt". Both filers are in our field.'),

  -- Deschutes County Sheriff — reconciles exactly
  ('Deschutes County Sheriff', 'James (Mac) McLaughlin', 'confirmed', false,
   'Deschutes County Clerk''s filed-candidate list: "County Sheriff, 4 year term (This contest moved to the General Election as fewer than three candidates filed for the Primary Election): James (Mac) McLaughlin, Ty Rupert". Both filers are in our field.'),
  ('Deschutes County Sheriff', 'Ty Rupert', 'confirmed', false,
   'Deschutes County Clerk''s filed-candidate list: "County Sheriff, 4 year term ...: James (Mac) McLaughlin, Ty Rupert". Both filers are in our field.'),

  -- Deschutes County Treasurer — the only row we hold is the withdrawal
  ('Deschutes County Treasurer', 'Robert Tintle', 'withdrew', false,
   'Deschutes County Clerk''s filed-candidate list, County Treasurer, 4 year term: "Jana Cain, Cam Sparks, Robert Tintle (Withdrew candidacy 8/5/2026)". He is named as withdrawn by the election official. NOTE: Cain and Sparks, who filed in the 2026-08-12 to 2026-08-25 vacancy-in-nomination window under OAR 165-010-0110, are ABSENT from our field — so this race renders with no candidates until they are seeded.');

CREATE TEMP TABLE or_resolved AS
SELECT rc.id AS rc_id, t.disposition, t.keep_flag,
       'Reconciled against the election officials'' own filed-candidate lists for the '
       || '2026-11-03 Oregon General, fetched 2026-09-11: Deschutes County Clerk '
       || '(deschutes.org/1593/November-3-2026-General-Election, section "Filed Candidates '
       || '(Nonpartisan Positions)") for the county contests, and the City of Bend '
       || '(bendoregon.gov/city-council/elections/) for the Bend contests, which states '
       || '"Candidate filings closed at 5:00 p.m. on August 25, 2026 and the deadline to '
       || 'withdraw was August 28, 2026". Our field was seeded 2026-07-24, before filing '
       || 'closed, which is why it needed reconciling in both directions. ' || t.why
       AS result_source
  FROM or_target t
  JOIN essentials.races r
    ON r.election_id = 'de10e3a7-f5c2-47e6-acd7-ee87be9413db'
   AND r.position_name = t.position_name
  JOIN essentials.race_candidates rc
    ON rc.race_id = r.id AND rc.full_name = t.our_name;

DO $$
DECLARE n_t int; n_m int; n_prov int;
BEGIN
  SELECT count(*) INTO n_t FROM or_target;
  SELECT count(*) INTO n_m FROM or_resolved;
  SELECT count(*) INTO n_prov
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'de10e3a7-f5c2-47e6-acd7-ee87be9413db'
     AND rc.provisional_until IS NOT NULL;
  IF n_t <> 15 THEN RAISE EXCEPTION 'target holds % rows, expected 15', n_t; END IF;
  IF n_m <> n_t THEN RAISE EXCEPTION 'only % of % names matched a row', n_m, n_t; END IF;
  IF n_prov <> 15 THEN RAISE EXCEPTION 'expected 15 provisional rows on this election, found %', n_prov; END IF;
END $$;

-- ── 1. the two withdrawals. BOTH columns, or is_live_candidate keeps them in the field ──────
UPDATE essentials.race_candidates rc
   SET result = 'withdrew',
       candidate_status = 'withdrawn',
       result_source = t.result_source,
       result_recorded_at = now(),
       last_verified_at = now(),
       provisional_until = NULL,
       updated_at = now()
  FROM or_resolved t
 WHERE rc.id = t.rc_id
   AND t.disposition = 'withdrew'
   AND (rc.result IS DISTINCT FROM 'withdrew'
        OR rc.candidate_status IS DISTINCT FROM 'withdrawn'
        OR rc.result_source IS DISTINCT FROM t.result_source
        OR rc.provisional_until IS NOT NULL);

-- ── 2. confirmed present, and the two held rows ─────────────────────────────────────────────
-- No result is written for either: these are nonpartisan contests with no primary, so there is
-- no primary outcome to record. What changes is that they are now verified against the closed
-- filing field, and whether the race still carries a flag.
UPDATE essentials.race_candidates rc
   SET last_verified_at = now(),
       provisional_until = CASE WHEN t.keep_flag THEN DATE '2026-09-18' ELSE NULL END,
       updated_at = now()
  FROM or_resolved t
 WHERE rc.id = t.rc_id
   AND t.disposition IN ('confirmed','held')
   AND (rc.provisional_until IS DISTINCT FROM (CASE WHEN t.keep_flag THEN DATE '2026-09-18' ELSE NULL END)
        OR rc.last_verified_at IS NULL);

-- ── POST-VERIFY ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n_wd int; n_live int; n_flag int; n_stale int; n_treas int; n_mayor int; n_p6 int;
BEGIN
  SELECT count(*) FILTER (WHERE rc.result = 'withdrew'),
         count(*) FILTER (WHERE essentials.is_live_candidate(rc.candidate_status, rc.result)),
         count(*) FILTER (WHERE rc.provisional_until = DATE '2026-09-18')
    INTO n_wd, n_live, n_flag
    FROM essentials.race_candidates rc
    JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'de10e3a7-f5c2-47e6-acd7-ee87be9413db'
     AND rc.id IN (SELECT rc_id FROM or_resolved);

  IF n_wd <> 2 THEN RAISE EXCEPTION 'expected 2 withdrawals (Cummiskey, Tintle), found %', n_wd; END IF;
  IF n_live <> 13 THEN RAISE EXCEPTION 'expected 13 live of the 15 reconciled rows, found %', n_live; END IF;
  IF n_flag <> 4 THEN
    RAISE EXCEPTION 'expected 4 rows still flagged (Bend #6 Reinholtz+Sorrells, Mayor Kebler+Boozell), found %', n_flag;
  END IF;

  -- the Treasurer race must end with NO live candidate: the only row we hold withdrew
  SELECT count(*) INTO n_treas
    FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'de10e3a7-f5c2-47e6-acd7-ee87be9413db'
     AND r.position_name = 'Deschutes County Treasurer'
     AND essentials.is_live_candidate(rc.candidate_status, rc.result);
  IF n_treas <> 0 THEN RAISE EXCEPTION 'Deschutes Treasurer should carry 0 live rows, found %', n_treas; END IF;

  -- the two incomplete Bend races must still be flagged
  SELECT count(*) INTO n_mayor
    FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'de10e3a7-f5c2-47e6-acd7-ee87be9413db'
     AND r.position_name = 'Bend Mayor' AND rc.provisional_until = DATE '2026-09-18';
  IF n_mayor <> 2 THEN RAISE EXCEPTION 'Bend Mayor should keep 2 flagged rows while Strome is missing, found %', n_mayor; END IF;

  SELECT count(*) INTO n_p6
    FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'de10e3a7-f5c2-47e6-acd7-ee87be9413db'
     AND r.position_name = 'Bend City Council Position 6' AND rc.provisional_until = DATE '2026-09-18';
  IF n_p6 <> 2 THEN RAISE EXCEPTION 'Bend #6 should keep 2 flagged rows while Tarter is missing, found %', n_p6; END IF;

  SELECT count(*) INTO n_stale
    FROM essentials.race_candidates rc JOIN essentials.races r ON r.id = rc.race_id
   WHERE r.election_id = 'de10e3a7-f5c2-47e6-acd7-ee87be9413db'
     AND rc.provisional_until IS NOT NULL AND rc.provisional_until <= CURRENT_DATE
     AND (rc.last_verified_at IS NULL OR rc.last_verified_at < rc.provisional_until);
  IF n_stale > 0 THEN RAISE EXCEPTION '% rows left stale on this election', n_stale; END IF;

  RAISE NOTICE 'OR Bend/Deschutes reconciliation OK: % withdrawn, % live of 15, % rows still '
    'flagged; 4 candidates still missing from our field', n_wd, n_live, n_flag;
END $$;

COMMIT;

-- ROLLBACK (restores the pre-deadline field):
--   UPDATE essentials.race_candidates rc
--      SET result = NULL, result_source = NULL, result_recorded_at = NULL,
--          candidate_status = 'active', last_verified_at = NULL,
--          provisional_until = DATE '2026-08-29', updated_at = now()
--     FROM essentials.races r
--    WHERE rc.race_id = r.id
--      AND r.election_id = 'de10e3a7-f5c2-47e6-acd7-ee87be9413db'
--      AND r.position_name IN ('Bend City Council Position 5','Bend City Council Position 6',
--            'Bend Mayor','Deschutes County Clerk','Deschutes County Commissioner Position 3',
--            'Deschutes County Commissioner Position 5','Deschutes County Sheriff',
--            'Deschutes County Treasurer');
