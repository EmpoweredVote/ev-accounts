-- CC_0418 — City of Santa Cruz, Mayor: Fred Keeley was NOT defeated. Replace the false clause
--            CC_0405 wrote into this term row's `source`.
--
-- ── WHAT IS WRONG, AND IT IS LIVE ──────────────────────────────────────────────────────────
-- CC_0405 (applied 2026-11-12) wrote this onto Keeley's open term row on the Mayor's office:
--
--     "... DEFEATED FOR RE-ELECTION: Ryan Coonerty won the 2026-11-03 runoff (unofficial),
--      taking office at the December certification meeting"
--
-- Two of those claims do not survive their own sources.
--
-- 1. 🔴 **KEELEY WAS NEVER ON THE BALLOT.** The county's certified Statement of Vote for the
--    June 2, 2026 primary — `lww.votescount.com/Portals/16/jun26/Complete SOV.pdf`, 5.9 MB,
--    read with `pdftotext -layout` on 2026-11-13, contest "City of Santa Cruz Mayor
--    (Vote for 1)", 27 of 27 precincts reported, timestamped 6/26/2026 2:09:19 PM — lists the
--    field as exactly:
--
--        Ryan Coonerty        9,300   47.80%
--        Ami Chen Mills       3,991   20.51%
--        Joy Schendledecker   2,435   12.52%
--        Gillian Greensite    2,161   11.11%
--        Chris Krohn          1,466    7.54%
--        Write-In               102    0.52%
--                            ──────
--        Total Votes         19,455     (9,300+3,991+2,435+2,161+1,466+102 = 19,455, exact)
--
--    No Keeley. An incumbent who did not file cannot have been "defeated for re-election",
--    and the word asserts something about him that no source says. The close, when it comes,
--    is therefore `term_expired`.
--    ⚠ NOT `retired`: that asserts a MOTIVE, and the evidence supports only "was not on the
--    ballot". A person's reason for not filing is not in any document read here.
--
-- 2. ⚠ "taking office at the December certification meeting" is a prediction, not a reading.
--    Charter § 601(c), as enacted by Measure E (June 2022) and published by the county at
--    `votescount.santacruzcountyca.gov/.../E-SCDistElectionsText.aspx` (codepublishing.com is
--    Cloudflare-walled and answers 403 to every automated client), says:
--
--      "The term of Mayor shall commence on the date of the City Council meeting, following
--       his or her election, at which the Council receives the certification of election
--       results from the City Clerk."
--
--    The trigger is the **MEETING**, not the certification. Cal. Elections Code § 15372(a)
--    puts the certified statement before the governing body "within 30 days of the election",
--    i.e. by 2026-12-03 for a 2026-11-03 election — but the receiving meeting is a separate,
--    later, unpublished date. santacruzca.gov answers Akamai 403 to automated clients down to
--    its own robots.txt and the agenda portal is primegov (robots-disallowed), so **that date
--    has to be read by hand.** The succession migration is drafted and waiting on it.
--
-- One claim in the old note DOES survive and is kept, now with its evidence: "runoff" is
-- correct. A majority of 19,455 is 9,728; Coonerty's 9,300 fell 428 short, so no outright win
-- happened in June and the top two advanced to the November general. That is the same
-- majority rule that let CC_0412 seat a county supervisor off a June primary — there it was
-- cleared by five votes, here it was missed by 428.
--
-- ── WHAT THIS MIGRATION DOES NOT DO ────────────────────────────────────────────────────────
-- It does not seat anyone and it does not close anything. `term_start`, `term_end`,
-- `how_started`, `how_ended` and `start_precision` are untouched, and the post-conditions
-- below assert that. Keeley's row has NULL on both dates, so `essentials.current_office_holders`
-- still resolves this seat to him — which is correct: Charter § 601 holds an officer in place
-- "until their successors have been elected and qualified". Nothing here races the handover.
--
-- There is therefore NO incumbency gate in this file, and that is not an omission.
-- `check-office-terms-incumbency-guards.mjs` says so in its own words: an UPDATE trips the
-- rule only when it ASSIGNS term_start or term_end, because "appending provenance to `source`
-- ... cannot change who held a seat on a date". This migration writes one text column.
--
-- Applied as `postgres` over the supabase-local MCP, verified on row counts and on the
-- resulting text, never on the absence of an error.

BEGIN;

-- ── Pre-condition: exactly one term row on this office, it is Keeley's, and it still carries
-- the false clause. If CC_0405's text has already been edited by something else, stop rather
-- than overwrite whatever that was.
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n
    FROM essentials.office_terms t
   WHERE t.office_id = '1b17729f-1712-477a-8734-b86fae7cfed1';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0418 pre: expected exactly 1 term row on the Santa Cruz Mayor office, got %', v_n;
  END IF;

  SELECT count(*) INTO v_n
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE t.office_id = '1b17729f-1712-477a-8734-b86fae7cfed1'
     AND p.full_name = 'Fred Keeley'
     AND t.source LIKE 'CC_0405 %'
     AND t.source LIKE '%DEFEATED FOR RE-ELECTION%'
     AND t.term_start IS NULL
     AND t.term_end IS NULL
     AND t.how_ended IS NULL;
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0418 pre: the row to correct is not in the shape CC_0405 left it (Keeley, open dates, CC_0405 source carrying the false clause); found % matching', v_n;
  END IF;
END $$;

-- ── The correction. Provenance for the row's EXISTENCE stays attributed to CC_0405 — that is
-- where the row came from — and the correction is attributed to this migration and dated, so
-- a reader can tell which sentence was written when.
UPDATE essentials.office_terms t
   SET source =
       'CC_0405 santacruzca.gov Meet the Mayor and City Council + votescount.santacruzcountyca.gov city roster, read 2026-11-11 — Mayor, elected at large, first elected 2022; the city roster gives the term as expiring December 2026. '
       || 'CC_0418 CORRECTION 2026-11-13: NOT DEFEATED. Keeley did not appear on the ballot. '
       || 'The county''s certified Statement of Vote for the June 2, 2026 primary (lww.votescount.com/Portals/16/jun26/Complete SOV.pdf, contest "City of Santa Cruz Mayor (Vote for 1)", 27 of 27 precincts, 6/26/2026 2:09:19 PM) gives the field as exactly Ryan Coonerty 9,300 / Ami Chen Mills 3,991 / Joy Schendledecker 2,435 / Gillian Greensite 2,161 / Chris Krohn 1,466 / write-in 102 = 19,455 total. '
       || 'A majority was 9,728, so Coonerty fell 428 short and the top two advanced to the 2026-11-03 general as a runoff, which Coonerty leads on UNOFFICIAL returns (county header -Unofficial Results- 11/10/2026 4:30 PM; 188 challenged ballots curable to 11/25). '
       || 'Keeley holds over under Charter § 601 ("until their successors have been elected and qualified"); this term will close as term_expired, not defeated. '
       || 'The successor''s term does not begin at certification: Charter § 601(c) (Measure E, June 2022) commences the Mayor''s term "on the date of the City Council meeting, following his or her election, at which the Council receives the certification of election results from the City Clerk" — the MEETING, which is not yet published. Cal. Elec. Code § 15372(a) puts the certified statement before the Council within 30 days of the election (by 2026-12-03).'
 WHERE t.office_id = '1b17729f-1712-477a-8734-b86fae7cfed1'
   AND t.source LIKE 'CC_0405 %';

-- ── Post-conditions.
DO $$
DECLARE v_n int; v_src text;
BEGIN
  SELECT count(*) INTO v_n
    FROM essentials.office_terms t
   WHERE t.office_id = '1b17729f-1712-477a-8734-b86fae7cfed1';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0418 post: the office no longer holds exactly 1 term row (%)', v_n;
  END IF;

  SELECT t.source INTO v_src
    FROM essentials.office_terms t
   WHERE t.office_id = '1b17729f-1712-477a-8734-b86fae7cfed1';

  IF v_src LIKE '%DEFEATED FOR RE-ELECTION%' THEN
    RAISE EXCEPTION 'CC_0418 post: the false clause is still in the note';
  END IF;
  IF v_src NOT LIKE '%CC_0418 CORRECTION 2026-11-13%' THEN
    RAISE EXCEPTION 'CC_0418 post: the correction clause is not in the note';
  END IF;
  IF v_src NOT LIKE 'CC_0405 %' THEN
    RAISE EXCEPTION 'CC_0418 post: the row lost its CC_0405 provenance prefix';
  END IF;

  -- Nothing about occupancy moved.
  SELECT count(*) INTO v_n
    FROM essentials.office_terms t
    JOIN essentials.politicians p ON p.id = t.politician_id
   WHERE t.office_id = '1b17729f-1712-477a-8734-b86fae7cfed1'
     AND p.full_name = 'Fred Keeley'
     AND t.term_start IS NULL
     AND t.term_end IS NULL
     AND t.how_started = 'elected'
     AND t.how_ended IS NULL
     AND t.start_precision = 'unknown';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0418 post: the term row is no longer Keeley''s open, untouched tenure';
  END IF;

  -- And the seat still resolves to Keeley today, through the view the app actually reads.
  SELECT count(*) INTO v_n
    FROM essentials.current_office_holders c
    JOIN essentials.politicians p ON p.id = c.politician_id
   WHERE c.office_id = '1b17729f-1712-477a-8734-b86fae7cfed1'
     AND p.full_name = 'Fred Keeley';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0418 post: the Santa Cruz Mayor seat no longer resolves to Fred Keeley today (% rows)', v_n;
  END IF;

  RAISE NOTICE 'CC_0418 ok: Keeley''s Santa Cruz Mayor note corrected; occupancy unchanged.';
END $$;

COMMIT;
