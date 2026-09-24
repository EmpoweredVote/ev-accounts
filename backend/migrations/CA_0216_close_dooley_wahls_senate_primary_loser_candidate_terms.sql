-- CA_0216_close_dooley_wahls_senate_primary_loser_candidate_terms.sql
--
-- Slot CA_0216 reserved via `npm run steward --prefix backend -- slot CA` (author: Chris Andrews).
-- No migration runner exists; this file records SQL applied by hand.
--
-- Close the migration-196 "Candidate for U.S. Senate — <State>" placeholder terms of two 2026 Senate
-- candidates who lost their party's nomination and are not on the November 3, 2026 general ballot:
--
--   Derek Dooley (R, GA)  b841a475-41b4-4f19-9ad1-13769b1f4eef  ext -400110  FEC S6GA00408
--     office 04fad7e8-a9cb-4ec8-9061-b7a9f8c1e0fb "Candidate for U.S. Senate — Georgia"
--   Zach Wahls  (D, IA)   db66036a-2a1f-4bcf-980e-2f29a336dc5f  ext -400115  FEC S6IA00272
--     office ed993f41-39b4-4df3-ae85-deef44ebcab4 "Candidate for U.S. Senate — Iowa"
--
-- Both terms came from the migration-1459 backfill, so both are open-ended with term_start NULL /
-- start_precision 'unknown'. An open term reports its holder as the current occupant for ever
-- (essentials.current_office_holders keeps every row with term_end NULL), so today both men still
-- resolve as live Senate candidates: address search with candidates on lists them for every Georgia /
-- Iowa address, and the FEC auto-match queue and run-fec-finance-summary.ts roster still pick them up.
--
-- ===========================================================================================
-- EVIDENCE (checked 2026-09-24)
-- ===========================================================================================
--
-- Dooley — lost the Republican primary RUNOFF on 2026-06-16.
--   May 19 primary, Georgia Secretary of State results, contest "US Senate - Rep" — no majority, so a
--   runoff: Mike Collins 369,642   Derek Dooley 275,534   Buddy Carter 229,223   (+2 others)
--     https://results.sos.ga.gov/results/public/Georgia/elections/GeneralPrimary51926
--   June 16 runoff, Georgia Secretary of State official results, contest "US Senate - Rep":
--     Mike Collins 390,174   Derek Dooley 312,339
--     https://results.sos.ga.gov/results/public/Georgia/elections/06162026GeneralPrimaryRunoff
--     (export JSON .../cdn/results/Georgia/export-06162026GeneralPrimaryRunoff.json, createdAt 2026-08-20)
--
-- Wahls — lost the Democratic primary on 2026-06-02 (Iowa has no primary runoff; the top vote-getter
--   above 35% is nominated).
--   Iowa Secretary of State election results, 2026 Primary Election (EID 126082), contest
--   "United States Senator - Dem.":  Josh Turek 120,287 (62.6%)   Zach Wahls 71,663 (37.3%)
--     https://electionresults.iowa.gov/IA/126082/
--   Wahls then endorsed Turek for the general (Iowa Capital Dispatch, 2026-06-02).
--
-- The general-election rosters already in prod agree, and are not touched here:
--   essentials.race_candidates "U.S. Senate Georgia" 2026-11-03: Jon Ossoff, Mike Collins
--   essentials.race_candidates "U.S. Senate Iowa"    2026-11-03: Ashley Hinson, Josh Turek, Thomas Laehn
--   (seeded by 1296 from Ballotpedia; neither Dooley nor Wahls has any race_candidates row.)
--
-- FEC agrees, and is what surfaced this (run-fec-finance-summary.ts --candidates-only, 2026-09-23,
--   skipped both). Both candidate IDs now have NO principal campaign committee and no 2025-26
--   candidate totals; each one's only linked committee is its former campaign committee, redesignated
--   as an unauthorized PAC by an amended Form 1 filed AFTER the loss:
--     S6GA00408 -> C00914531 LEADERSHIP MATTERS PAC  designation U, type N  (F1/A 2026-09-04)
--     S6IA00272 -> C00907923 BUILD THE BARN PAC      designation U, type V  (F1/A 2026-07-28, 2026-08-26)
--   Neither filed a withdrawal; each candidacy ended at the election it lost.
--
-- ===========================================================================================
-- WHAT THIS WRITES
-- ===========================================================================================
--
-- 1. office_terms: close each term, and give it a start.
--      term_end   = the day of the contest the candidate lost (Dooley 2026-06-16, Wahls 2026-06-02).
--                   term_end is INCLUSIVE here (current_office_holders tests term_end >= CURRENT_DATE,
--                   office_terms_no_overlap uses daterange(..., '[]')), so it is the LAST day of the
--                   candidacy. Each man was a candidate through election day; the loss is that night.
--      how_ended  = 'defeated' (office_terms_how_ended_check vocabulary).
--      term_start = the receipt date of the candidate's FEC Form 2, Statement of Candidacy — the formal
--                   start of a federal candidacy, a recorded day, not an estimate:
--                     Dooley 2025-08-03  docquery.fec.gov/pdf/128/202508039789385128/202508039789385128.pdf
--                     Wahls  2025-06-10  docquery.fec.gov/pdf/273/202506109762027273/202506109762027273.pdf
--                   start_precision 'day'. Without a start, a closed term with term_start NULL still
--                   answers essentials.office_holders_as_of() for EVERY date before the loss — 1990
--                   included — which is the defect CA_0171 guarded against for placeholder terms.
--      how_started is left NULL: its vocabulary (elected/appointed/succeeded/redistricted/unknown)
--                   describes taking a seat and has no word for filing a candidacy.
--
--    🔴 NOT via essentials.vacate_office(). That helper is for a SEAT: it sets offices.is_vacant = true and
--    vacant_since, and ends the term the day BEFORE p_as_of (the first vacant day). A candidacy
--    placeholder is not a seat, and nothing becomes vacant when a candidate loses. Flagging these offices
--    is_vacant would publish "Candidate for U.S. Senate — Georgia: vacant" to any read that admits
--    vacant offices (the `p.is_active = true OR o.is_vacant = true` gate). Same call, same reason, as
--    1824, which closed six stale terms directly and deliberately left is_vacant false.
--
--    The two placeholder offices are KEPT. Each holds exactly one term row (this one); deleting the
--    office would cascade-delete the term and erase the record that the candidacy happened. Neither
--    office is referenced by essentials.races. offices_missing_terms counts offices with NO term row, so
--    a closed term keeps both offices out of it — the baseline does not move.
--
-- 2. politicians.is_incumbent = false, set explicitly (CLAUDE.md). It is already false on both rows; the
--    write is a guarded no-op that makes the migration say so. Neither man holds any other modelled seat.
--    ⚠ Zach Wahls IS a sitting Iowa state senator (SD-43, since 2019). Prod models no Iowa legislative
--    seat at all (no STATE_UPPER / STATE_LOWER districts for Iowa), so after this he holds no seat in
--    prod and false is the correct cached value. When Iowa's legislature is seeded, he is seated there.
--
-- 3. politicians.finance_summary = NULL for both. The current values are a frozen snapshot written by
--    the deleted scripts/senate-candidate-fec.ts, with no as-of date:
--      Dooley {"cycle": "2026", "source": "FEC", "total_raised": 4175480.91, top_donors: 10 rows}
--      Wahls  {"cycle": "2026", "source": "FEC", "total_raised": 3671205.51, top_donors: 10 rows}
--    Its only writer now, run-fec-finance-summary.ts (PR #676), builds its roster from CURRENT NATIONAL_*
--    offices, so once these terms close it never visits either man again — the snapshot would have no
--    owner and could never be refreshed. It cannot be refreshed correctly from FEC anyway: the
--    committees are PACs now, and a PAC's cycle totals mix campaign money with post-conversion PAC
--    receipts. No frontend renders finance_summary (the profile finance card reads
--    /api/campaign-finance/politician/:id/summary, which sums contributions), so nothing visible
--    changes; the API simply stops shipping a number no one maintains. The campaign record itself lives
--    in transparent_motivations.contributions and is untouched (Dooley 2,821 rows 2025-08-04..2026-06-16,
--    Wahls 8,108 rows 2025-06-07..2026-05-13, at authoring). Guarded on the exact stale total_raised, so
--    a re-run never erases a value someone writes later.
--
-- NOT CHANGED, on purpose:
--   - transparent_motivations.politician_sources: both fec_senate rows stay 'confirmed'. The link is
--     still true — S6GA00408 IS Derek Dooley — and it is what attaches the real campaign contributions to
--     him. 'disputed' would claim the ID is not his. It also cannot import PAC money under his name:
--     fecAdapter resolves a candidate to PRINCIPAL committees only (designation P), and fecBulkLoader
--     defaults to DSGN = 'P'; both candidate IDs now resolve to none, so an FEC run adds nothing.
--   - politicians.is_active stays true. Both rows carry stance research (Dooley 8 answers, Wahls 12) and a
--     portrait. Whether a former candidate stays findable in search and the compass picker is a product
--     call this migration does not make; closing the term already removes them from every
--     office-rooted and address-rooted read. (Precedent is mixed: Gary Crockett and John Fleming are
--     is_active = false with their placeholder terms still OPEN — 1802 deferred Crockett as a judgment
--     call.)
--   - race_candidates: no Georgia or Iowa 2026 Senate PRIMARY race is modelled, and inventing one only to
--     record a loss is out of scope. The general rosters are already right.
--
-- Precedent searched before choosing this: no "Candidate for%" term had ever been closed (0 of 52 rows
-- carried a term_end); the only earlier Senate primary losers on placeholders, Crockett and Fleming,
-- were handled with is_active alone. This is the first placeholder close, so it follows 1824's
-- direct-close shape.
--
-- Dry run: the whole body wrapped BEGIN; ... ROLLBACK; against prod, applied twice in one transaction to
-- prove the re-run is a no-op, then the rollback confirmed by re-reading the rows.

BEGIN;

-- ---------------------------------------------------------------------------
-- Targets, resolved by external_id + name + office title (UUIDs are environment-specific).
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE ca0216_close ON COMMIT DROP AS
SELECT v.person, p.id AS politician_id, t.id AS term_id, o.id AS office_id,
       v.fec_id, v.term_start::date AS term_start, v.term_end::date AS term_end,
       v.stale_total_raised::numeric AS stale_total_raised, v.why
FROM (VALUES
  ('Derek Dooley', -400110::bigint, 'Candidate for U.S. Senate — Georgia', 'S6GA00408',
   '2025-08-03', '2026-06-16', '4175480.91',
   'lost the GOP primary runoff 2026-06-16, Collins 390,174 / Dooley 312,339 (GA SOS results.sos.ga.gov '
   '06162026GeneralPrimaryRunoff); start = FEC Form 2 receipt 2025-08-03'),
  ('Zach Wahls',   -400115::bigint, 'Candidate for U.S. Senate — Iowa',    'S6IA00272',
   '2025-06-10', '2026-06-02', '3671205.51',
   'lost the Democratic primary 2026-06-02, Turek 120,287 / Wahls 71,663 (IA SOS electionresults.iowa.gov '
   'EID 126082); start = FEC Form 2 receipt 2025-06-10')
) AS v(person, ext, title, fec_id, term_start, term_end, stale_total_raised, why)
JOIN essentials.politicians  p ON p.external_id = v.ext AND p.full_name = v.person
JOIN essentials.office_terms t ON t.politician_id = p.id
JOIN essentials.offices      o ON o.id = t.office_id AND o.title = v.title;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM ca0216_close;
  IF n <> 2 THEN
    RAISE EXCEPTION 'PRE: resolved % target term rows, expected 2 — external_id, name or office title changed', n;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- PRE-FLIGHT
-- ---------------------------------------------------------------------------
DO $$
DECLARE r record; n int;
BEGIN
  FOR r IN SELECT * FROM ca0216_close LOOP
    -- The office holds exactly this one term. A second row means a successor or a duplicate appeared
    -- since authoring, and the no-overlap picture has changed — review before closing.
    SELECT count(*) INTO n FROM essentials.office_terms WHERE office_id = r.office_id;
    IF n <> 1 THEN
      RAISE EXCEPTION 'PRE: % office % holds % term rows, expected exactly 1', r.person, r.office_id, n;
    END IF;

    -- The term is either untouched (open, no start) or already closed by THIS migration. Anything else
    -- is a hand edit made since authoring; do not overwrite it.
    IF NOT EXISTS (
      SELECT 1 FROM essentials.office_terms t
       WHERE t.id = r.term_id
         AND (   (t.term_end IS NULL AND t.term_start IS NULL AND t.start_precision = 'unknown')
              OR (t.term_end = r.term_end AND t.term_start = r.term_start AND t.how_ended = 'defeated'
                  AND t.source LIKE '%CA_0216%'))
    ) THEN
      RAISE EXCEPTION 'PRE: % term % is neither the open 1459 backfill row nor the CA_0216-closed row — '
                      'someone changed it; review', r.person, r.term_id;
    END IF;

    -- The candidate holds no OTHER current office, so is_incumbent = false is the right cached value.
    -- (EXISTS, not a counted join: a politician-rooted join over office_current_holder fans out.)
    IF EXISTS (SELECT 1 FROM essentials.office_current_holder och
                WHERE och.politician_id = r.politician_id AND och.office_id <> r.office_id) THEN
      RAISE EXCEPTION 'PRE: % holds another current office — is_incumbent may need to stay true', r.person;
    END IF;

    -- The confirmed FEC link is the one the evidence is about (right person).
    IF NOT EXISTS (SELECT 1 FROM transparent_motivations.politician_sources ps
                    WHERE ps.essentials_politician_id = r.politician_id AND ps.source_system = 'fec_senate'
                      AND ps.external_id = r.fec_id AND ps.research_status = 'confirmed') THEN
      RAISE EXCEPTION 'PRE: % has no confirmed fec_senate source %', r.person, r.fec_id;
    END IF;

    -- A future term_end would leave the row reporting as current and achieve nothing.
    IF r.term_end >= CURRENT_DATE THEN
      RAISE EXCEPTION 'PRE: % term_end % is not in the past', r.person, r.term_end;
    END IF;

    -- The office is not flagged vacant now, and must not be after (see header).
    IF EXISTS (SELECT 1 FROM essentials.offices WHERE id = r.office_id AND is_vacant) THEN
      RAISE EXCEPTION 'PRE: % office % is flagged is_vacant — unexpected for a candidacy placeholder',
                      r.person, r.office_id;
    END IF;
  END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- 1. Close each term, with a sourced start. Guarded on term_end IS NULL: a re-run touches 0 rows and
--    cannot overwrite a date corrected by hand.
-- ---------------------------------------------------------------------------
UPDATE essentials.office_terms t
   SET term_start      = c.term_start,
       start_precision = 'day',
       term_end        = c.term_end,
       how_ended       = 'defeated',
       source          = t.source || ' | candidacy closed by CA_0216 on 2026-09-24: ' || c.why
  FROM ca0216_close c
 WHERE t.id = c.term_id
   AND t.term_end IS NULL;

-- ---------------------------------------------------------------------------
-- 2. is_incumbent, explicitly (already false on both; guarded no-op).
-- ---------------------------------------------------------------------------
UPDATE essentials.politicians p
   SET is_incumbent = false
  FROM ca0216_close c
 WHERE p.id = c.politician_id
   AND p.is_incumbent IS DISTINCT FROM false;

-- ---------------------------------------------------------------------------
-- 3. Drop the ownerless finance_summary snapshot — only the exact stale value.
-- ---------------------------------------------------------------------------
UPDATE essentials.politicians p
   SET finance_summary = NULL
  FROM ca0216_close c
 WHERE p.id = c.politician_id
   AND p.finance_summary IS NOT NULL
   AND (p.finance_summary->>'total_raised')::numeric = c.stale_total_raised;

-- ---------------------------------------------------------------------------
-- VERIFY
-- ---------------------------------------------------------------------------
DO $$
DECLARE r record; n int;
BEGIN
  FOR r IN SELECT * FROM ca0216_close LOOP
    IF NOT EXISTS (
      SELECT 1 FROM essentials.office_terms
       WHERE id = r.term_id AND term_start = r.term_start AND start_precision = 'day'
         AND term_end = r.term_end AND how_ended = 'defeated' AND source LIKE '%CA_0216%'
    ) THEN
      RAISE EXCEPTION 'POST: % term % did not close to % .. % / defeated', r.person, r.term_id,
                      r.term_start, r.term_end;
    END IF;

    -- THE POINT: the candidate no longer resolves as holding anything today.
    IF EXISTS (SELECT 1 FROM essentials.office_current_holder WHERE politician_id = r.politician_id) THEN
      RAISE EXCEPTION 'POST: % still resolves as a current office holder', r.person;
    END IF;

    -- History still answers inside the span, and no longer answers outside it.
    IF NOT EXISTS (SELECT 1 FROM essentials.office_holders_as_of(r.term_end) h
                    WHERE h.office_id = r.office_id AND h.politician_id = r.politician_id) THEN
      RAISE EXCEPTION 'POST: office_holders_as_of(%) lost % — the last day of the candidacy', r.term_end, r.person;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM essentials.office_holders_as_of(r.term_start) h
                    WHERE h.office_id = r.office_id AND h.politician_id = r.politician_id) THEN
      RAISE EXCEPTION 'POST: office_holders_as_of(%) lost % — the first day of the candidacy', r.term_start, r.person;
    END IF;
    IF EXISTS (SELECT 1 FROM essentials.office_holders_as_of(r.term_end + 1) h
                WHERE h.politician_id = r.politician_id) THEN
      RAISE EXCEPTION 'POST: office_holders_as_of(%) still returns % the day after the loss', r.term_end + 1, r.person;
    END IF;
    IF EXISTS (SELECT 1 FROM essentials.office_holders_as_of(r.term_start - 1) h
                WHERE h.politician_id = r.politician_id) THEN
      RAISE EXCEPTION 'POST: office_holders_as_of(%) returns % before the candidacy began', r.term_start - 1, r.person;
    END IF;

    -- The placeholder office is kept, holds its one (closed) term, and is NOT flagged vacant.
    SELECT count(*) INTO n FROM essentials.office_terms WHERE office_id = r.office_id;
    IF n <> 1 THEN
      RAISE EXCEPTION 'POST: % office % holds % term rows, expected 1', r.person, r.office_id, n;
    END IF;
    IF EXISTS (SELECT 1 FROM essentials.offices WHERE id = r.office_id AND (is_vacant OR vacant_since IS NOT NULL)) THEN
      RAISE EXCEPTION 'POST: % office % was flagged vacant', r.person, r.office_id;
    END IF;

    -- Politician row: not an incumbent, snapshot gone, still active (untouched).
    IF NOT EXISTS (SELECT 1 FROM essentials.politicians
                    WHERE id = r.politician_id AND is_incumbent = false AND finance_summary IS NULL AND is_active) THEN
      RAISE EXCEPTION 'POST: % politician row not in the expected state (is_incumbent false, finance_summary '
                      'NULL, is_active true)', r.person;
    END IF;

    -- The FEC link is untouched.
    IF NOT EXISTS (SELECT 1 FROM transparent_motivations.politician_sources ps
                    WHERE ps.essentials_politician_id = r.politician_id AND ps.source_system = 'fec_senate'
                      AND ps.external_id = r.fec_id AND ps.research_status = 'confirmed') THEN
      RAISE EXCEPTION 'POST: % confirmed fec_senate source % changed', r.person, r.fec_id;
    END IF;
  END LOOP;

  -- Georgia / Iowa general rosters untouched.
  SELECT count(*) INTO n
    FROM essentials.race_candidates rc
    JOIN essentials.races ra ON ra.id = rc.race_id
    JOIN essentials.elections e ON e.id = ra.election_id
   WHERE e.election_date = '2026-11-03' AND ra.position_name IN ('U.S. Senate Georgia', 'U.S. Senate Iowa')
     AND rc.candidate_status = 'active';
  IF n <> 5 THEN
    RAISE EXCEPTION 'POST: % active GA/IA general Senate candidates, expected 5 (Ossoff, Collins, Hinson, Turek, Laehn)', n;
  END IF;
END $$;

COMMIT;
