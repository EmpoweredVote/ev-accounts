-- CC_0075_steward_lease_default_24h.sql
--
-- steward.claims: the default lease goes from 8 hours to 24, because 8 was a guess and the
-- guess has now been measured.
--
-- Design: docs/superpowers/specs/2026-09-04-steward-coordination-design.md (§10)
-- Constants: backend/scripts/lib/steward-lease.mjs
-- Creates: nothing. One column default.
--
-- ── WHAT WAS MEASURED ───────────────────────────────────────────────────────────────────────
--
-- CC_0070 shipped `expires_at DEFAULT now() + interval '8 hours'`, and §10 recorded it honestly
-- as an open decision: "Eight hours is a guess. It wants to be longer than a working session and
-- shorter than a weekend."
--
-- Measured 2026-09-04 against 52 real session transcripts for this project
-- (~/.claude/projects/C--EV-Accounts/*.jsonl), taking each session's wall-clock span from its
-- first message to its last:
--
--   sessions of >=200 messages (real work, n=47) that OUTLIVE a lease of...
--      8h -> 28/47  (60%)   <- the shipped guess
--     12h -> 17/47  (36%)
--     16h -> 13/47  (28%)
--     20h ->  4/47   (9%)   <- the overnight cliff
--     24h ->  3/47   (6%)   <- this migration
--     48h ->  0/47   (0%)   <- but no longer "shorter than a weekend"
--
-- 🔴 THE GUESS WAS WRONG IN A DIRECTION NOBODY WOULD HAVE NOTICED. An 8-hour lease expired
--    during 60% of real working sessions. Median session span is 10.2h, p90 is 18.8h. A lease
--    that lapses mid-session fails SILENTLY: the row stops matching, nothing warns anybody, and
--    two sessions write one jurisdiction believing they are alone — the exact failure the claims
--    table exists to prevent.
--
-- ⚠ MEASURED ON ONE AUTHOR'S SESSIONS, on this project only. Andrews' sessions and the laptop's
--   scan runs are not in the sample. Re-measure if either becomes a normal case.
--
-- ── WHY THIS MIGRATION EXISTS AT ALL, GIVEN THE CLI PASSES AN EXPLICIT VALUE ────────────────
--
-- `steward claim` always sends `now() + make_interval(hours => $n)`, so the column default is
-- never used by the CLI. It IS used by any hand-written INSERT — and a schema that answers "how
-- long is a lease?" with 8 while the code answers 24 is two definitions of one fact. The next
-- person to read the table definition would get the wrong answer, in the wrong direction, with
-- nothing to contradict them.
--
-- Idempotent: setting a default to the value it already holds is a no-op, and the post-verify
-- gate asserts the END STATE rather than a delta.

BEGIN;

ALTER TABLE steward.claims
  ALTER COLUMN expires_at SET DEFAULT (now() + interval '24 hours');

COMMENT ON COLUMN steward.claims.expires_at IS
  'Lease expiry. 24h by default — MEASURED, not chosen: 8h (CC_0070) expired during 60% of 52 '
  'real session transcripts, 24h during 6%, and 48h would no longer be "shorter than a '
  'weekend". A lapsed lease frees the scope, so `who` and `claim` report recently-lapsed claims '
  'for 12h rather than dropping them silently. See scripts/lib/steward-lease.mjs.';

-- ─────────────────────────────────────────────────────────────────────────────────────────
-- POST-VERIFY. End state, not delta.
-- ─────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_default text;
  v_probe   timestamptz;
  v_hours   numeric;
BEGIN
  SELECT column_default INTO v_default
    FROM information_schema.columns
   WHERE table_schema = 'steward' AND table_name = 'claims' AND column_name = 'expires_at';

  IF v_default IS NULL THEN
    RAISE EXCEPTION 'steward.claims.expires_at has NO default; CC_0070 set one and this migration '
                    'was supposed to change it, not remove it';
  END IF;
  IF v_default NOT LIKE '%24:00:00%' AND v_default NOT LIKE '%24 hours%' THEN
    RAISE EXCEPTION 'expected a 24-hour default, found: %', v_default;
  END IF;

  -- 🔴 READ THE DEFAULT BY EVALUATING IT, NOT BY TRUSTING ITS TEXT. Postgres normalises an
  --    interval literal when it stores the expression, so a string match alone can pass on a
  --    default that computes something else. Evaluating it is the check that cannot be fooled.
  EXECUTE format('SELECT %s', v_default) INTO v_probe;
  v_hours := round(EXTRACT(EPOCH FROM (v_probe - now())) / 3600.0);
  IF v_hours <> 24 THEN
    RAISE EXCEPTION 'the default EVALUATES to % hours ahead, not 24 (text was: %)', v_hours, v_default;
  END IF;

  -- The column comment is the only place a reader of the schema alone learns the number was
  -- measured. A silently-missing comment would leave 24 looking like another guess.
  IF coalesce(col_description('steward.claims'::regclass,
       (SELECT attnum FROM pg_attribute
         WHERE attrelid = 'steward.claims'::regclass AND attname = 'expires_at')), '')
     NOT LIKE '%MEASURED%' THEN
    RAISE EXCEPTION 'the expires_at comment does not record that the number was measured';
  END IF;

  RAISE NOTICE 'steward.claims.expires_at default is now 24h (evaluated, not just matched), and '
               'the column comment records the measurement.';
END $$;

COMMIT;
