-- CC_0446 — Racine County, Wisconsin: record the 2026-11-03 Sheriff result.
--
-- WHY
-- The Sheriff race was the last Wisconsin candidacy row of this election with no result.
-- `CC_0445` gave the office a swearing-in date (2027-01-04, Wis. Stat. § 59.20(2)(b)) while
-- the race still named no winner, so the seat had a handover date and nobody to hand over to.
-- The Clerk of Circuit Court race beside it, loaded from the same report in the same pass,
-- already carried its result — so this was a gap in one race, not in the county.
--
-- SOURCE — read, not inferred
-- Racine County Clerk, "Election Summary Report", November 03, 2026 General Election,
-- Summary for: All Contests, All Districts, All Tabulators, All Counting Groups,
-- printed 11/4/2026 12:45:20 AM, page 5 of 6, FINAL UNOFFICIAL:
--
--     Cary A. Madrigal      REP    39,609
--     Donald E. Vandervest  DEM    42,048
--     Write-in                        166
--     Total Votes                  81,657
--     Precincts Reported: 88 of 88 (100.00%)
--     Sheriff (Vote for 1)
--
--   https://www.racinecounty.gov/departments/county-clerk/election-information/election-results
--   → "ElectionSummaryReportRPT_11-03-2026 FINAL UNOFFICIAL" (document 55460)
--
-- ⚠ IN THIS REPORT THE CONTEST TITLE IS PRINTED *AFTER* THE BLOCK OF CANDIDATES IT NAMES.
-- Reading it the other way round attaches every result to the wrong contest. Two independent
-- checks fix the reading: the arithmetic inside the block (39,609 + 42,048 = 81,657, the block's
-- own "Total Votes"), and the Clerk of Circuit Court block below it, whose single name —
-- Amy Vanderhoef — is already recorded as that race's winner in our data from an earlier pass.
--
-- CERTAINTY
-- 'called', not 'certified'. The county has published no certified canvass for 2026-11-03; this
-- is its own final unofficial return with every precinct in. That matches the Clerk of Circuit
-- Court row sourced from the same document, and all 263 other Wisconsin rows for this election.
--
-- THE AGGREGATE WRITE-IN LINE IS NOT A CANDIDATE. 166 write-ins, unresolved and unallocated,
-- cannot reach 42,048 even read as one person, so they do not disturb the result.
--
-- VALUES OVERWRITTEN (there is no history table; this is the only record of what was here)
--   Both rows, before this migration:
--     result = NULL, result_source = NULL, result_certainty = NULL, result_recorded_at = NULL
--   Nothing else on either row is touched. `source`, which already cites this same report,
--   `candidate_status`, `is_incumbent` and `politician_id` are all left as they are.
--
-- NOT DONE HERE, ON PURPOSE
--   * NOBODY IS SEATED. Sheriff Christopher Schmaling holds the seat until 2027-01-04. See
--     backend/data/wi-2026-swearing-in/RULES.md.
--   * Neither row carries a `politician_id`, so the winner has no person record yet. That is
--     the same shape as the Clerk of Circuit Court winner and is an occupancy act, owed before
--     the January seating pass, not now.

BEGIN;

-- ---------------------------------------------------------------------------
-- Pre-check: the rows are the ones we think they are, and they are unwritten.
-- ---------------------------------------------------------------------------
CREATE TEMP TABLE cc0446_before ON COMMIT DROP AS
SELECT count(*) AS wi_2026_unresolved
  FROM essentials.race_candidates rc
  JOIN essentials.races r      ON r.id = rc.race_id
  JOIN essentials.elections e  ON e.id = r.election_id
  JOIN essentials.offices o    ON o.id = r.office_id
 WHERE e.election_date = DATE '2026-11-03'
   AND o.representing_state = 'WI'
   AND rc.result IS NULL;

DO $$
DECLARE
  v_race_id   uuid;
  v_office_id uuid;
  v_n         int;
  v_names     text;
BEGIN
  SELECT r.id, r.office_id
    INTO v_race_id, v_office_id
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices   o ON o.id = r.office_id
   WHERE e.election_date = DATE '2026-11-03'
     AND o.representing_state = 'WI'
     AND r.position_name = 'Racine County Sheriff';

  IF v_race_id IS NULL THEN
    RAISE EXCEPTION 'CC_0446 pre-check: no 2026-11-03 WI race named "Racine County Sheriff"';
  END IF;

  SELECT count(*) INTO v_n FROM essentials.race_candidates rc WHERE rc.race_id = v_race_id;
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'CC_0446 pre-check: expected 2 candidacy rows on the sheriff race, found %', v_n;
  END IF;

  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
   WHERE rc.race_id = v_race_id AND rc.result IS NOT NULL;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0446 pre-check: % row(s) already carry a result — somebody else wrote this race; stop and read it', v_n;
  END IF;

  -- A full name is not an identity, and an external_id collision writes onto the wrong person.
  -- Assert the pairing of the two, not either one alone.
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
   WHERE rc.race_id = v_race_id
     AND (rc.full_name, rc.external_id) IN (
           ('Donald E. Vandervest', 'wi-2026-11-03-racine-county-sheriff-donald-e-vandervest'),
           ('Cary A. Madrigal',     'wi-2026-11-03-racine-county-sheriff-cary-a-madrigal'));
  IF v_n <> 2 THEN
    SELECT string_agg(format('%s / %s', rc.full_name, coalesce(rc.external_id, '<null>')), ' | ' ORDER BY rc.full_name)
      INTO v_names
      FROM essentials.race_candidates rc WHERE rc.race_id = v_race_id;
    RAISE EXCEPTION 'CC_0446 pre-check: the two rows are not the two candidates this migration names. Found: %', v_names;
  END IF;

  -- The office must be the one CC_0445 dated, or this race is hung on a different seat.
  SELECT count(*) INTO v_n
    FROM essentials.office_swearing_in sw
   WHERE sw.office_id = v_office_id
     AND sw.election_date = DATE '2026-11-03'
     AND sw.swearing_in_date = DATE '2027-01-04';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0446 pre-check: the sheriff office has no 2027-01-04 swearing-in row from CC_0445 (found %)', v_n;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- The winner.
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
   SET result            = 'won',
       result_certainty  = 'called',
       result_source     = 'Racine County Clerk, Election Summary Report for the 2026-11-03 General Election (FINAL UNOFFICIAL), page 5, 88 of 88 precincts: Donald E. Vandervest (DEM) 42,048 to Cary A. Madrigal (REP) 39,609, write-in 166, total votes 81,657',
       result_recorded_at = COALESCE(rc.result_recorded_at, now()),
       updated_at        = now()
  FROM essentials.races r
  JOIN essentials.elections e ON e.id = r.election_id
  JOIN essentials.offices   o ON o.id = r.office_id
 WHERE rc.race_id = r.id
   AND e.election_date = DATE '2026-11-03'
   AND o.representing_state = 'WI'
   AND r.position_name = 'Racine County Sheriff'
   AND rc.external_id = 'wi-2026-11-03-racine-county-sheriff-donald-e-vandervest'
   AND rc.full_name   = 'Donald E. Vandervest';

-- ---------------------------------------------------------------------------
-- The loser. Recorded, never inferred from "not the winner".
-- ---------------------------------------------------------------------------
UPDATE essentials.race_candidates rc
   SET result            = 'lost',
       result_certainty  = 'called',
       result_source     = 'Racine County Clerk, Election Summary Report for the 2026-11-03 General Election (FINAL UNOFFICIAL), page 5, 88 of 88 precincts: Cary A. Madrigal (REP) 39,609 to Donald E. Vandervest (DEM) 42,048, write-in 166, total votes 81,657',
       result_recorded_at = COALESCE(rc.result_recorded_at, now()),
       updated_at        = now()
  FROM essentials.races r
  JOIN essentials.elections e ON e.id = r.election_id
  JOIN essentials.offices   o ON o.id = r.office_id
 WHERE rc.race_id = r.id
   AND e.election_date = DATE '2026-11-03'
   AND o.representing_state = 'WI'
   AND r.position_name = 'Racine County Sheriff'
   AND rc.external_id = 'wi-2026-11-03-racine-county-sheriff-cary-a-madrigal'
   AND rc.full_name   = 'Cary A. Madrigal';

-- ---------------------------------------------------------------------------
-- Post-verify. Counting two rows says nothing about whether each row says the
-- right thing, so every assertion below names the row it is about.
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  v_race_id   uuid;
  v_office_id uuid;
  v_n         int;
  v_before    int;
  v_after     int;
  v_detail    text;
BEGIN
  SELECT r.id, r.office_id INTO v_race_id, v_office_id
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices   o ON o.id = r.office_id
   WHERE e.election_date = DATE '2026-11-03'
     AND o.representing_state = 'WI'
     AND r.position_name = 'Racine County Sheriff';

  -- 1. Nothing in this race is left unresolved.
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
   WHERE rc.race_id = v_race_id AND rc.result IS NULL;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0446: % sheriff candidacy row(s) still carry no result', v_n;
  END IF;

  -- 2. Exactly one winner, and it is Vandervest BY NAME.
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
   WHERE rc.race_id = v_race_id AND rc.result = 'won';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0446: the sheriff race has % winner(s); a one-seat race has exactly one', v_n;
  END IF;

  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
   WHERE rc.race_id = v_race_id AND rc.result = 'won'
     AND rc.full_name = 'Donald E. Vandervest';
  IF v_n <> 1 THEN
    SELECT string_agg(format('%s -> %s', rc.full_name, rc.result), ' | ' ORDER BY rc.full_name)
      INTO v_detail FROM essentials.race_candidates rc WHERE rc.race_id = v_race_id;
    RAISE EXCEPTION 'CC_0446: the winner is not Donald E. Vandervest. Rows: %', v_detail;
  END IF;

  -- 3. Exactly one loser, and it is Madrigal BY NAME.
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
   WHERE rc.race_id = v_race_id AND rc.result = 'lost'
     AND rc.full_name = 'Cary A. Madrigal';
  IF v_n <> 1 THEN
    SELECT string_agg(format('%s -> %s', rc.full_name, rc.result), ' | ' ORDER BY rc.full_name)
      INTO v_detail FROM essentials.race_candidates rc WHERE rc.race_id = v_race_id;
    RAISE EXCEPTION 'CC_0446: the loser is not Cary A. Madrigal. Rows: %', v_detail;
  END IF;

  -- 4. Both rows cite the county's own report, and both are 'called'.
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
   WHERE rc.race_id = v_race_id
     AND rc.result_certainty = 'called'
     AND rc.result_source LIKE 'Racine County Clerk, Election Summary Report%'
     AND rc.result_source LIKE '%88 of 88 precincts%'
     AND rc.result_recorded_at IS NOT NULL;
  IF v_n <> 2 THEN
    RAISE EXCEPTION 'CC_0446: % of 2 rows carry the county report as their result_source, certainty "called" and a recorded-at stamp', v_n;
  END IF;

  -- 5. The delta, captured in this transaction — not a total another session can move.
  SELECT wi_2026_unresolved INTO v_before FROM cc0446_before;
  SELECT count(*) INTO v_after
    FROM essentials.race_candidates rc
    JOIN essentials.races r     ON r.id = rc.race_id
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices   o ON o.id = r.office_id
   WHERE e.election_date = DATE '2026-11-03'
     AND o.representing_state = 'WI'
     AND rc.result IS NULL;
  IF v_before - v_after <> 2 THEN
    RAISE EXCEPTION 'CC_0446: expected to resolve exactly 2 Wisconsin rows, resolved % (% before, % after)',
      v_before - v_after, v_before, v_after;
  END IF;

  -- 6. No scope leak: this migration writes to one race and nowhere else.
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
   WHERE rc.result_source LIKE 'Racine County Clerk, Election Summary Report for the 2026-11-03 General Election (FINAL UNOFFICIAL), page 5%'
     AND rc.race_id <> v_race_id;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0446: % row(s) outside the sheriff race carry this migration''s result_source', v_n;
  END IF;

  -- 7. Nobody was seated. The handover is 2027-01-04 and the incumbent still holds the seat.
  SELECT count(*) INTO v_n
    FROM essentials.office_terms ot
   WHERE ot.office_id = v_office_id
     AND ot.term_start = DATE '2027-01-04';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0446: % term(s) start 2027-01-04 on the sheriff seat — this migration must seat nobody', v_n;
  END IF;

  RAISE NOTICE 'CC_0446 OK: Racine County Sheriff — Vandervest won, Madrigal lost; Wisconsin 2026 unresolved % -> %', v_before, v_after;
END $$;

COMMIT;
