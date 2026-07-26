-- 1436_reverify_stale_provisional_candidates.sql
-- Re-verify the 17 candidate rows that migration 1435 exposed as past their provisional_until
-- date, then resolve each. Idempotent.
--
-- These are AZ and MI U.S. House minor-party/independent rows whose provisional window has
-- closed:
--   MI (8) — "provisional -- MI filing deadline 2026-07-16", 9 days past
--   AZ (9) — "provisional -- pre-primary field, cull >= 2026-07-22", 3 days past (AZ's primary
--            was 2026-07-21)
-- Until 1435 they were indistinguishable from settled candidates, because the only record of
-- their expiry was English prose inside race_candidates.source.
--
-- VERIFICATION METHOD: each name checked against its own Ballotpedia district-race page, which
--   publishes both the certified general-election field ("X, Y and Z are running in the general
--   election for ... on November 3, 2026") and a "Withdrawn or disqualified candidates" section.
--   A verdict required POSITIVE evidence in one direction or the other — never an absence.
--   That mattered: Ballotpedia began returning HTTP 202 with an empty body partway through the
--   sweep, and because both KEEP and CULL demanded positive evidence, a throttled empty
--   response could only ever produce "absent", which was then re-checked by hand rather than
--   acted on. Do NOT rewrite this as "not found => cull".
--
-- OUTCOME: 7 of 17 were NOT on the November ballot and were being served as live candidates.
--
--   KEEP (9) — confirmed in the certified general-election field. provisional_until cleared and
--   last_verified_at stamped:
--     Monica Alponte     AZ-1  (Libertarian; won the Libertarian primary)
--     Alan Aversa        AZ-3
--     Jereme Peters      AZ-6
--     Zebulon Featherly  MI-1
--     James Bronke       MI-5
--     Clyde Shabazz      MI-6
--     Fernando Valdez    MI-9
--     Jasen Cartwright   MI-9
--     Maurice Morton     MI-13
--
--   WITHDRAWN (7) — set candidate_status='withdrawn' rather than deleted, because
--   electionService already filters `candidate_status != 'withdrawn'`, so this removes them from
--   every voter-facing surface while preserving the record that they once filed:
--     Christopher Ajluni   AZ-1  listed under "Withdrawn or disqualified" (No Labels Party)
--     David Redkey         AZ-1  listed under "Withdrawn or disqualified" (Green)
--     John Fillmore        AZ-4  listed under "Withdrawn or disqualified"
--     Tisha Benoit         AZ-4  listed under "Withdrawn or disqualified"
--     Iman Bah             AZ-6  listed under "Withdrawn or disqualified"
--     Alexandra Prieditis  MI-7  listed under "Withdrawn or disqualified"
--     Thomas Latza         MI-1  ABSENT from the page entirely; MI's independent filing deadline
--                                (2026-07-16) has passed and the certified MI-1 general field is
--                                Satterla / Hakola / Featherly, so he did not qualify.
--                                Confirmed by a real page load (25.5 KB), not a throttled fetch.
--
--   STILL PROVISIONAL (1) — deliberately left alone, NOT cleared and NOT culled:
--     Curtis Goodwin       AZ-2  He ran in the 2026-07-21 Libertarian primary against Alex
--                                Flores. The AZ-2 page still shows only Crane and Nez in the
--                                general and states "Additional general election candidates will
--                                be added here following the primary" — so the Libertarian result
--                                has not propagated. He is genuinely unresolved, and leaving
--                                provisional_until set is the correct representation of that.
--                                He will keep surfacing in
--                                essentials.stale_provisional_candidates until settled, which is
--                                exactly what that view is for.
--
-- All 17 names were verified unique across essentials.race_candidates before keying on them.
-- last_verified_at is stamped on the culled rows too — the check happened, and the timestamp is
--   what keeps them out of the stale view regardless of provisional_until.
BEGIN;

-- ── 1. KEEP: confirmed on the November ballot ──
UPDATE essentials.race_candidates
   SET provisional_until = NULL,
       last_verified_at  = now(),
       source = source || ' | re-verified 2026-07-25 against the certified general-election field (Ballotpedia district race page); provisional window closed, confirmed on the ballot'
 WHERE full_name IN (
         'Monica Alponte', 'Alan Aversa', 'Jereme Peters',
         'Zebulon Featherly', 'James Bronke', 'Clyde Shabazz',
         'Fernando Valdez', 'Jasen Cartwright', 'Maurice Morton'
       )
   AND provisional_until IS NOT NULL;

-- ── 2. WITHDRAWN: not on the November ballot ──
UPDATE essentials.race_candidates
   SET candidate_status  = 'withdrawn',
       provisional_until = NULL,
       last_verified_at  = now(),
       source = source || ' | re-verified 2026-07-25: NOT on the certified general-election field (listed withdrawn/disqualified, or absent after the filing deadline); status set to withdrawn by migration 1436'
 WHERE full_name IN (
         'Christopher Ajluni', 'David Redkey', 'John Fillmore', 'Tisha Benoit',
         'Iman Bah', 'Alexandra Prieditis', 'Thomas Latza'
       )
   -- NOT just `candidate_status <> 'withdrawn'`. Christopher Ajluni and Iman Bah were ALREADY
   -- withdrawn in the database before this migration, yet still carried the provisional_until
   -- that 1435 backfilled from their prose — so a status-only guard skipped them and left them
   -- stuck in stale_provisional_candidates forever. The guard must also fire on a lingering
   -- provisional_until. (Their pre-existing withdrawn status independently corroborates the
   -- Ballotpedia verdict for those two.) Still idempotent: after this runs both arms are false.
   AND (candidate_status <> 'withdrawn' OR provisional_until IS NOT NULL);

-- ── 3. Curtis Goodwin: intentionally untouched. See header. ──

-- ── 4. Post-verify gate ──
DO $$
DECLARE n_keep int; n_withdrawn int; n_goodwin int; n_stale int;
BEGIN
  SELECT count(*) INTO n_keep FROM essentials.race_candidates
   WHERE full_name IN ('Monica Alponte','Alan Aversa','Jereme Peters','Zebulon Featherly',
                       'James Bronke','Clyde Shabazz','Fernando Valdez','Jasen Cartwright',
                       'Maurice Morton')
     AND provisional_until IS NULL AND candidate_status = 'active' AND last_verified_at IS NOT NULL;
  IF n_keep <> 9 THEN RAISE EXCEPTION 'kept-and-verified rows: got %, want 9', n_keep; END IF;

  SELECT count(*) INTO n_withdrawn FROM essentials.race_candidates
   WHERE full_name IN ('Christopher Ajluni','David Redkey','John Fillmore','Tisha Benoit',
                       'Iman Bah','Alexandra Prieditis','Thomas Latza')
     AND candidate_status = 'withdrawn';
  IF n_withdrawn <> 7 THEN RAISE EXCEPTION 'withdrawn rows: got %, want 7', n_withdrawn; END IF;

  -- Goodwin must remain provisional and active
  SELECT count(*) INTO n_goodwin FROM essentials.race_candidates
   WHERE full_name = 'Curtis Goodwin' AND provisional_until IS NOT NULL
     AND candidate_status = 'active';
  IF n_goodwin <> 1 THEN
    RAISE EXCEPTION 'Curtis Goodwin should stay provisional+active (unresolved AZ-2 Libertarian primary); found %', n_goodwin;
  END IF;

  -- the stale view should now contain ONLY Goodwin
  SELECT count(*) INTO n_stale FROM essentials.stale_provisional_candidates;
  IF n_stale <> 1 THEN
    RAISE EXCEPTION 'stale_provisional_candidates should hold exactly 1 row (Goodwin), holds %', n_stale;
  END IF;

  RAISE NOTICE 'Re-verification PASSED: 9 confirmed on ballot, 7 withdrawn, 1 genuinely unresolved (Goodwin, AZ-2).';
END $$;

COMMIT;
