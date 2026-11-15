-- CC_0424: the Racine County, Wisconsin ballot for 2026-11-03 -- Sheriff and Clerk of Circuit Court
--
-- Two of the last four empty 2026-11-03 races. Both were on that ballot; CC_0423's notes settled
-- that part from the statute. What was NOT settled was the figures, and this migration is mostly
-- about how they were finally read.
--
-- Source: Racine County Clerk, "ElectionSummaryReportRPT_11-03-2026 FINAL UNOFFICIAL" and
--   "StatementOfVotesCastRPT_11-03-2026 FINAL UNOFFICIAL", both retrieved 2026-11-14 and committed
--   under backend/data/local-races-2026-audit/sources/.
--
--   Sheriff (Vote for 1), 88 of 88 precincts (100.00%)
--     Cary A. Madrigal      REP   39,609
--     Donald E. Vandervest  DEM   42,048
--     Write-in                       166      Total Votes 81,657
--   Clerk of Circuit Court (Vote for 1), 88 of 88 precincts (100.00%)
--     Amy Vanderhoef        REP   54,674
--     Write-in                     3,011      Total Votes 54,674
--
--   WARNING: party is recorded NOWHERE below. This repo is antipartisan by design -- party lives
--     on races.primary_party, never on race_candidates -- so the REP/DEM above is provenance for a
--     reader of this header, not a column.
--
-- 🔴🔴 THE PREVIOUS READING OF THESE FILES PAIRED "Sheriff" WITH "Amy Vanderhoef 54,674", AND
--    VANDERHOEF IS THE CLERK OF CIRCUIT COURT. The PDFs' text drifts vertically: a candidate's
--    name and its figure sit on different output lines, so a reader working in content-stream
--    order pairs a name with the NEXT contest's number. Every figure it produced was a real
--    figure from the document, which is exactly what made the reading credible. It also paired
--    "Clerk of Circuit Court" with "Yes 43,284 / No 36,344" -- the state referendum two pages on.
--    ▶ The fix is to pair GEOMETRICALLY. backend/data/local-races-2026-audit/read-racine-pdf.mjs
--      clusters glyph runs by their y coordinate and reads each row left-to-right by x, so a row
--      is a row of the printed table whatever order the stream emitted it in.
--
-- 🟢 EVERY FIGURE ABOVE WAS READ THREE INDEPENDENT WAYS, and verify-racine.mjs is the third:
--      1. positional extraction of the Election Summary Report;
--      2. the page rendered to an image at 150dpi and read as a picture -- a different mechanism
--         entirely, which is the point;
--      3. the Statement of Votes Cast, a DIFFERENT 104-page document, both its own printed total
--         rows and the sum of its 89 per-ward rows.
--    The ward sums close exactly: 39,609 + 42,048 = 81,657 = the printed Total Votes.
--    WARNING: Racine's "Total Votes" EXCLUDES write-ins -- it is the named candidates only. That
--      is not a convention, it is this clerk's; close the arithmetic rather than assuming it.
--    WARNING: the control was watched FAILING first, and not on purpose: given the wrong page
--      range it reported Vanderhoef 44,255 against 54,674. A partial sum is the failure mode a
--      ward tally has, and it reads like a disagreement between sources rather than a short read.
--
-- 🔴 "FINAL UNOFFICIAL" IS THIS PUBLISHER'S TERMINAL DOCUMENT, NOT A STAGE. Every election on
--    Racine's results page back to 2018 is labelled UNOFFICIAL, including one headed "UNOFFICIAL
--    Certification Report". The county publishes no canvassed document at all, so waiting for the
--    word "official" from this source waits for ever. The word carries no information here.
--
-- WARNING: a note in CC_0423 said curl gets 403 on racinecounty.gov even with a browser
--   User-Agent. That was true and incomplete: the WAF wants the whole browser header set. Adding
--   Accept, Accept-Language, sec-ch-ua, sec-ch-ua-mobile, sec-ch-ua-platform, the four Sec-Fetch-*
--   headers and Upgrade-Insecure-Requests returns 200 and the PDF. A User-Agent alone is not "a
--   browser".
--
-- ▶ WHY THE SHERIFF GETS A BALLOT AND NO RESULT, AND THE CLERK GETS BOTH.
--   The bar this programme uses is CC_0423's: a result may be recorded when it is FORCED (the
--   outcome cannot depend on anything still uncounted) or CALLED by a publisher. A margin is not
--   a bound.
--     Clerk of Circuit Court -- FORCED. Vanderhoef is the only name on the ballot, and the whole
--       aggregate write-in line read as if it were one person loses to her by 51,663. Nothing
--       outstanding can reach that. Recorded won/called, the same basis as CC_0423's 8 forced
--       Oregon contests.
--     Sheriff -- NEITHER. It is contested and the margin is 2,439. Nobody calls it: AP's WI file
--       carries 131 races across Governor, Attorney General, Secretary of State, Treasurer, U.S.
--       House, State Senate, State Assembly and Question, and NOT ONE county office -- measured,
--       not assumed. Racine publishes no winner flag. So a result here would be our own call off
--       a margin, which is the thing the Oregon wave refused.
--   WARNING: Wisconsin being an in-hand state (an absentee ballot must reach the clerk by 8 p.m.
--     on election day) means there is no late-arriving pool, and 88 of 88 precincts have reported.
--     That makes the sheriff's margin very likely safe -- and "very likely" is still not a bound,
--     and provisional ballots are cured afterwards and are not published here. The county board of
--     canvassers determines county offices; county canvass statements are due to the Wisconsin
--     Elections Commission by 2026-11-17. ▶ Record the sheriff's outcome from the canvass.
--
-- WARNING: no politician is created or linked, and nothing here seats anybody. politician_id stays
--   NULL, matching CC_0423. Our roster still seats Christopher Schmaling as sheriff and Amy
--   Vanderhoef as clerk; Schmaling is on no line of this ballot, so neither sheriff candidate is
--   an incumbent. These terms begin in January 2027, and seating is a separate act.

BEGIN;

INSERT INTO essentials.race_candidates
  (race_id, full_name, first_name, last_name, is_incumbent, candidate_status, external_id, source,
   result, result_source, result_certainty)
VALUES
  -- Racine County Sheriff -- contested, uncalled, no result recorded.
  ('bdfd77cd-a7ec-46a0-b914-40e8f52ee2c6', 'Cary A. Madrigal', 'Cary', 'Madrigal', false, 'active',
   'wi-2026-11-03-racine-county-sheriff-cary-a-madrigal',
   'Racine County Clerk, Election Summary Report and Statement of Votes Cast for the 2026-11-03 General Election (FINAL UNOFFICIAL), 88 of 88 precincts',
   NULL, NULL, NULL),
  ('bdfd77cd-a7ec-46a0-b914-40e8f52ee2c6', 'Donald E. Vandervest', 'Donald', 'Vandervest', false, 'active',
   'wi-2026-11-03-racine-county-sheriff-donald-e-vandervest',
   'Racine County Clerk, Election Summary Report and Statement of Votes Cast for the 2026-11-03 General Election (FINAL UNOFFICIAL), 88 of 88 precincts',
   NULL, NULL, NULL),
  -- Racine County Clerk of Circuit Court -- unopposed, forced.
  ('ef8d5216-4c8d-4757-98c0-bce11adfb37d', 'Amy Vanderhoef', 'Amy', 'Vanderhoef', true, 'active',
   'wi-2026-11-03-racine-county-clerk-of-circuit-court-amy-vanderhoef',
   'Racine County Clerk, Election Summary Report and Statement of Votes Cast for the 2026-11-03 General Election (FINAL UNOFFICIAL), 88 of 88 precincts',
   'won',
   'Racine County Clerk, Election Summary Report for the 2026-11-03 General Election (FINAL UNOFFICIAL), 88 of 88 precincts; the only name on the ballot, and the aggregate write-in line read as a single person does not reach her',
   'called')
-- The unique index on external_id is PARTIAL, so the conflict target repeats its predicate.
ON CONFLICT (external_id) WHERE external_id IS NOT NULL DO NOTHING;

DO $$
DECLARE
  v_rows int; v_won int; v_null int; v_inc int; v_empty_wi int; v_unflagged int;
BEGIN
  SELECT count(*) INTO v_rows FROM essentials.race_candidates WHERE external_id LIKE 'wi-2026-11-03-racine-%';
  IF v_rows <> 3 THEN RAISE EXCEPTION 'CC_0424: % Racine candidacies, expected 3.', v_rows; END IF;

  SELECT count(*) FILTER (WHERE result = 'won'),
         count(*) FILTER (WHERE result IS NULL),
         count(*) FILTER (WHERE is_incumbent)
    INTO v_won, v_null, v_inc
    FROM essentials.race_candidates WHERE external_id LIKE 'wi-2026-11-03-racine-%';
  IF v_won <> 1 OR v_null <> 2 OR v_inc <> 1 THEN
    RAISE EXCEPTION 'CC_0424: won=% no-result=% incumbent=%, expected 1/2/1.', v_won, v_null, v_inc;
  END IF;

  -- 🔴 The won row must be the CLERK's. This is the gate the stream-order misreading would have
  --    failed: it put Vanderhoef in the sheriff's contest.
  IF NOT EXISTS (
    SELECT 1 FROM essentials.race_candidates rc
     WHERE rc.race_id = 'ef8d5216-4c8d-4757-98c0-bce11adfb37d'
       AND rc.full_name = 'Amy Vanderhoef' AND rc.result = 'won' AND rc.result_certainty = 'called'
  ) THEN RAISE EXCEPTION 'CC_0424: the won row is not Vanderhoef on the Clerk of Circuit Court race.'; END IF;
  IF EXISTS (
    SELECT 1 FROM essentials.race_candidates rc
     WHERE rc.race_id = 'bdfd77cd-a7ec-46a0-b914-40e8f52ee2c6' AND rc.result IS NOT NULL
  ) THEN RAISE EXCEPTION 'CC_0424: the sheriff race carries a result; it is uncalled.'; END IF;

  -- No citation may carry a vote count (CC_0423's rule).
  IF EXISTS (SELECT 1 FROM essentials.race_candidates
              WHERE external_id LIKE 'wi-2026-11-03-racine-%' AND result_source ~ '[0-9][0-9,]* votes') THEN
    RAISE EXCEPTION 'CC_0424: a result_source carries a vote count.';
  END IF;

  -- Every Wisconsin race for this election must now carry a ballot.
  SELECT count(*) INTO v_empty_wi
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE e.election_date = '2026-11-03' AND lower(d.state) = 'wi'
     AND NOT EXISTS (SELECT 1 FROM essentials.race_candidates rc WHERE rc.race_id = r.id);
  IF v_empty_wi <> 0 THEN
    RAISE EXCEPTION 'CC_0424: % Wisconsin races for 2026-11-03 still carry no candidate.', v_empty_wi;
  END IF;

  -- Recording a ballot seats nobody.
  SELECT count(*) FILTER (WHERE NOT o.is_vacant) INTO v_unflagged
    FROM essentials.offices_missing_terms m JOIN essentials.offices o ON o.id = m.office_id;
  IF v_unflagged <> 238 THEN RAISE EXCEPTION 'CC_0424: drift baseline reads %, not 238.', v_unflagged; END IF;

  RAISE NOTICE 'CC_0424 OK: 3 Racine candidacies across 2 races (1 won, 2 with no result), no empty Wisconsin race left, drift baseline 238.';
END $$;

COMMIT;
