-- CC_0447 — record the five 2026-11-03 U.S. House races AP called after CC_0350
--
-- WHAT THIS DOES
--   Writes result = 'won' / result_certainty = 'called' on exactly five race_candidates rows:
--
--     CA-04  (geo 0604)  Eric Jones        (Dem)  52.53%  called 2026-11-14T01:25:15.131Z
--     CA-23  (geo 0623)  Jay Obernolte     (GOP)  50.83%  called 2026-11-17T01:29:31.253Z
--     CO-04  (geo 0804)  Eileen Laubacher  (Dem)  48.80%  called 2026-11-13T19:53:37.315Z
--     ME-02  (geo 2302)  Paul LePage       (GOP)  49.89%  called 2026-11-12T18:31:29.417Z
--     NC-07  (geo 3707)  David Rouzer      (GOP)  49.87%  called 2026-11-16T20:54:47.014Z
--
--   CC_0350 recorded AP's calls as they stood on 2026-11-04. AP has called five more since.
--   Measured 2026-11-17 03:00Z: AP has called 427 House races, this database held 422.
--
-- 🔴 WHAT IT OVERWRITES — ALL FOUR COLUMNS WERE NULL ON ALL FIVE ROWS.
--   Read from production 2026-11-17 and recorded in backend/data/house-2026-late-calls/
--   before-values.json: result, result_certainty, result_source and result_recorded_at are
--   NULL on every one of the five, and result_source is the empty string on none of them.
--   So unlike CC_0350 — where 51 rows already carried a state ballot-qualification citation
--   that had to be appended rather than replaced — this migration destroys no citation.
--   The rows' `source` column (where the candidacy came from) is NOT touched.
--
-- SOURCE
--   AP's own results feed, no key:
--     https://interactives.apelections.org/election-results/data-live/2026-11-03/results/national/metadata.json
--     https://interactives.apelections.org/election-results/data-live/2026-11-03/results/national/progress.json
--   Captured 2026-11-17 03:00Z into backend/data/house-2026-late-calls/ap-late-calls-2026-11-17.json.
--   🔴 A MEDIA CALL IS NOT A STATE CANVASS. Every row here is `called`. AP reports
--   isCertified = false for all five, and this migration asserts nothing claims certification.
--
-- 🔴 THE TWIN-BROTHER CHECK, AND WHY IT PASSES THIS TIME
--   CC_0350 withheld TX-22 because AP's winner (Trever Nehls, id 170023) shared a surname with
--   the seat's incumbent (Troy Nehls, id 68186) and was a different person — a surname match
--   would have reported the sitting congressman re-elected to a seat he did not run for.
--   Two of these five share a surname with the incumbent: CA-23 Obernolte and NC-07 Rouzer.
--   In BOTH, AP's winner candidateID EQUALS AP's incumbent candidateID — they are the sitting
--   members re-elected, not namesakes. The detector is "surname matches AND id differs"; it
--   returns zero here. ▶ CHECK THE ID, NEVER THE SURNAME.
--
-- 🔴 ME-02 IS A RANKED-CHOICE RACE AND ITS PERCENTAGE IS A FIRST-CHOICE SHARE
--   LePage's 49.89% is his share of all 341,256 ballots cast, 6,021 of which are blank. Nobody
--   cleared 50% on first choices, so Maine ran its ranked-choice tabulation; AP's final round
--   gives LePage 170,890 to Matthew Dunlap 165,432. The citation records both numbers, because
--   "49.89%" beside "won" reads like an error otherwise.
--   ⚠ The same denominator question is live in Alaska's still-uncalled Senate race, where
--   874 aggregate write-ins are the whole difference between a first-round majority and none.
--
-- WHAT IT DELIBERATELY DOES NOT DO
--   * It records NO LOSERS. A loser is recorded because AP's own ballot names them, never
--     because they are not the winner (CC_0351's rule — SC still carries Lindsey Graham, who
--     died before the election and was not on the ballot). The eight other rows in these five
--     races stay NULL, and the gate asserts they are untouched. That pass is owed separately.
--   * It seats nobody. These winners take office 2027-01-03 under US Const. amend. XX § 1.
--   * It creates no person: all five winners already have a politician_id.

BEGIN;

-- The five pins. rc_id is read from production; geo_id and last_name are re-asserted against it,
-- so a mistyped id RAISES instead of silently moving a win onto another seat.
CREATE TEMP TABLE cc0447_pins (
  geo_id       text PRIMARY KEY,
  rc_id        uuid NOT NULL,
  race_id      uuid NOT NULL,
  full_name    text NOT NULL,
  last_name    text NOT NULL,
  ap_race_id   text NOT NULL,
  src          text NOT NULL
) ON COMMIT DROP;

INSERT INTO cc0447_pins VALUES
 ('0604','8dee76aa-6d91-4be8-99cd-a93c7298799f','eabbb909-51bc-4498-ab4f-10b0f1d83ad3',
  'Eric Jones','Jones','20261103CA5694',
  'AP race call, AP race 20261103CA5694 (CA-04). WINNER=Eric Jones; Dem, 133,179 votes, 52.53%, called 2026-11-14T01:25:15.131Z, defeating incumbent Mike Thompson. AP results feed read 2026-11-17 03:00Z. A media call is not the state canvass.'),
 ('0623','f2f352e9-3e8e-4026-967d-4d7b541334c3','7740b4c3-587b-4823-a530-8c229e20debd',
  'Jay Obernolte','Obernolte','20261103CA5713',
  'AP race call, AP race 20261103CA5713 (CA-23). WINNER=Jay Obernolte; GOP, 109,335 votes, 50.83%, called 2026-11-17T01:29:31.253Z. Incumbent re-elected: AP winner candidateID 67998 equals AP incumbent candidateID 67998, so the shared surname is the same person, not a namesake. AP results feed read 2026-11-17 03:00Z. A media call is not the state canvass.'),
 ('0804','178db157-4280-4253-a74f-994364463328','f2a99107-c9b6-4201-8b2c-6548d5969fe1',
  'Eileen Laubacher','Laubacher','20261103CO6616',
  'AP race call, AP race 20261103CO6616 (CO-04). WINNER=Eileen Laubacher; Dem, 187,745 votes, 48.80%, called 2026-11-13T19:53:37.315Z, defeating incumbent Lauren Boebert. AP results feed read 2026-11-17 03:00Z. A media call is not the state canvass.'),
 ('2302','c58647c9-1ac0-43a4-9682-c0c7198631b9','aa63d55d-80b8-42b9-9aa5-0713387f65fb',
  'Paul LePage','LePage','20261103ME20645',
  'AP race call, AP race 20261103ME20645 (ME-02), RANKED CHOICE. WINNER=Paul LePage; GOP, first-choice 170,265 votes, 49.89% of all 341,256 ballots cast, of which 6,021 were blank. No candidate cleared 50% on first choices, so Maine ran its ranked-choice tabulation; AP''s final round gives LePage 170,890 to Matthew Dunlap 165,432. Called 2026-11-12T18:31:29.417Z, defeating incumbent Jared Golden. AP results feed read 2026-11-17 03:00Z. A media call is not the state canvass.'),
 ('3707','fd3fb04f-9df8-41e8-9ca5-377454735364','5be80001-9052-47dd-913d-704685975bb9',
  'David Rouzer','Rouzer','20261103NC34973',
  'AP race call, AP race 20261103NC34973 (NC-07). WINNER=David Rouzer; GOP, 160,702 votes, 49.87%, called 2026-11-16T20:54:47.014Z. Incumbent re-elected: AP winner candidateID 35605 equals AP incumbent candidateID 35605, so the shared surname is the same person, not a namesake. AP results feed read 2026-11-17 03:00Z. A media call is not the state canvass.');

-- Resolve each pin against the live row, re-asserting district and surname.
CREATE TEMP TABLE cc0447_resolved ON COMMIT DROP AS
SELECT p.*, rc.id AS found_rc, rc.result AS result_before, rc.result_source AS source_before
  FROM cc0447_pins p
  JOIN essentials.race_candidates rc ON rc.id = p.rc_id
  JOIN essentials.races r            ON r.id = rc.race_id
  JOIN essentials.elections e        ON e.id = r.election_id
  JOIN essentials.offices o          ON o.id = r.office_id
  JOIN essentials.districts d        ON d.id = o.district_id
 WHERE e.election_date = DATE '2026-11-03'
   AND d.geo_id   = p.geo_id
   AND rc.race_id = p.race_id
   AND rc.last_name = p.last_name
   AND rc.full_name = p.full_name;

-- Baseline for the delta, captured inside this transaction rather than read off a total
-- another session can move while this file is being written.
CREATE TEMP TABLE cc0447_before ON COMMIT DROP AS
SELECT count(*) FILTER (WHERE rc.result = 'won')     AS won_in_the_five,
       count(*) FILTER (WHERE rc.result IS NOT NULL) AS any_result_in_the_five,
       count(*)                                      AS rows_in_the_five
  FROM essentials.race_candidates rc
 WHERE rc.race_id IN (SELECT race_id FROM cc0447_pins);

DO $$
DECLARE v_n bigint; v_names text;
BEGIN
  SELECT count(*) INTO v_n FROM cc0447_resolved;
  IF v_n <> 5 THEN
    -- 🔴 A PIN THAT DOES NOT RESOLVE RETURNS A SMALLER SET, SILENTLY.
    SELECT string_agg(geo_id, ', ' ORDER BY geo_id) INTO v_names
      FROM cc0447_pins WHERE geo_id NOT IN (SELECT geo_id FROM cc0447_resolved);
    RAISE EXCEPTION 'CC_0447 pre-check: % of 5 pins resolved to a row in the stated district carrying the stated name. Unresolved: %', v_n, coalesce(v_names, '(none)');
  END IF;

  SELECT count(*) INTO v_n FROM cc0447_resolved WHERE result_before IS NOT NULL;
  IF v_n <> 0 THEN
    SELECT string_agg(geo_id || ' -> ' || result_before, ', ' ORDER BY geo_id) INTO v_names
      FROM cc0447_resolved WHERE result_before IS NOT NULL;
    RAISE EXCEPTION 'CC_0447 pre-check: % row(s) already carry a result, and this migration''s header states all five were NULL: %', v_n, v_names;
  END IF;

  SELECT count(*) INTO v_n FROM cc0447_resolved WHERE coalesce(source_before, '') <> '';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0447 pre-check: % row(s) already carry a result_source; overwriting one destroys a citation with no history table to recover it', v_n;
  END IF;

  -- No race among the five may already hold a winner.
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
   WHERE rc.race_id IN (SELECT race_id FROM cc0447_pins) AND rc.result = 'won';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0447 pre-check: % winner row(s) already exist in the five races', v_n;
  END IF;

  -- The marker this migration writes must be unseen repo-wide, or the scope-leak gate below
  -- would count somebody else's rows as this migration's.
  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE result_source LIKE '%AP results feed read 2026-11-17 03:00Z%';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0447 pre-check: % row(s) already carry this migration''s marker', v_n;
  END IF;
END $$;

UPDATE essentials.race_candidates rc
   SET result             = 'won',
       result_certainty   = 'called',
       result_source      = p.src,
       result_recorded_at = COALESCE(rc.result_recorded_at, now()),
       updated_at         = now()
  FROM cc0447_resolved p
 WHERE rc.id = p.rc_id;

-- Post-verify. Counting five rows says nothing about whether each row names the right person,
-- so every assertion below names the thing it is about.
DO $$
DECLARE
  v_n bigint; v_before bigint; v_after bigint; v_names text; v_geo text;
BEGIN
  -- 1. exactly five rows written, and they are the five pinned rows
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc JOIN cc0447_pins p ON p.rc_id = rc.id
   WHERE rc.result = 'won';
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CC_0447: % of the 5 pinned rows carry won', v_n;
  END IF;

  -- 2. each race has exactly one winner
  SELECT count(*) INTO v_n FROM (
    SELECT rc.race_id FROM essentials.race_candidates rc
     WHERE rc.race_id IN (SELECT race_id FROM cc0447_pins) AND rc.result = 'won'
     GROUP BY rc.race_id HAVING count(*) > 1) x;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0447: % of the five races resolved more than one winner; each is a one-seat race', v_n;
  END IF;

  -- 3. the winner in each district is the person this migration names, BY NAME
  SELECT count(*), string_agg(geo_id || ': ' || got, ', ' ORDER BY geo_id)
    INTO v_n, v_names
    FROM (
      SELECT p.geo_id, rc.full_name AS got, p.full_name AS want
        FROM cc0447_pins p
        JOIN essentials.race_candidates rc ON rc.race_id = p.race_id AND rc.result = 'won') z
   WHERE got <> want;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0447: % district(s) have a winner this migration did not name: %', v_n, v_names;
  END IF;

  -- 4. every written row cites AP, carries called, and carries a recorded-at stamp
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc JOIN cc0447_pins p ON p.rc_id = rc.id
   WHERE rc.result_source LIKE '%AP race call, AP race ' || p.ap_race_id || '%'
     AND rc.result_source LIKE '%A media call is not the state canvass.%'
     AND rc.result_certainty = 'called'
     AND rc.result_recorded_at IS NOT NULL;
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CC_0447: only % of 5 rows cite their own AP race id with certainty called and a recorded-at stamp', v_n;
  END IF;

  -- 4b. 🔴 THE CITATION MUST NAME THE PERSON IT IS ATTACHED TO.
  --     Assertion 3 compares the winner against the pin's OWN declared name, so a pin
  --     repointed consistently — rc_id, full_name and last_name all moved to the losing
  --     candidate in the same race — agrees with itself and sails through. That is a gate
  --     checking a vocabulary rather than a pairing. Tying the row to its citation text is
  --     what breaks the self-consistency: the source names the winner AP called, so a row
  --     wearing someone else's citation raises. Control A is exactly this tamper.
  --     🔴 AND THE FIRST VERSION OF THIS GATE PASSED CONTROL A, FOR A REASON WORTH KEEPING:
  --     it asked only whether the citation CONTAINED the row's name, and every citation here
  --     also names the defeated incumbent ("defeating incumbent Mike Thompson"). Repointed
  --     onto Thompson, the row's own name was still in the text, so the test was satisfied
  --     by the loser's name. The citations therefore carry an explicit WINNER=<name>; token
  --     and the gate tests THAT position. ▶ A SUBSTRING TEST ASKS "IS THIS NAME ANYWHERE",
  --     WHICH IS NOT THE QUESTION. Name the field you mean.
  SELECT count(*), string_agg(full_name, ', ' ORDER BY full_name) INTO v_n, v_names
    FROM essentials.race_candidates rc
   WHERE rc.id IN (SELECT rc_id FROM cc0447_pins)
     AND rc.result_source NOT LIKE '%WINNER=' || rc.full_name || ';%';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0447: % row(s) carry a result_source that does not name the candidate it is attached to: %', v_n, v_names;
  END IF;

  -- 5. NOTHING may claim certification. AP reports isCertified = false for all five.
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc JOIN cc0447_pins p ON p.rc_id = rc.id
   WHERE rc.result_certainty <> 'called';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0447: % row(s) claim a certainty other than called', v_n;
  END IF;

  -- 6. the DELTA: exactly five rows in these races gained a result, captured in this transaction
  SELECT won_in_the_five INTO v_before FROM cc0447_before;
  SELECT count(*) INTO v_after
    FROM essentials.race_candidates rc
   WHERE rc.race_id IN (SELECT race_id FROM cc0447_pins) AND rc.result = 'won';
  IF v_after - v_before <> 5 THEN
    RAISE EXCEPTION 'CC_0447: the five races went from % winner(s) to %, a delta of %, not 5', v_before, v_after, v_after - v_before;
  END IF;

  -- 7. NO SCOPE LEAK: this migration's marker appears on exactly the five rows it wrote
  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE result_source LIKE '%AP results feed read 2026-11-17 03:00Z%';
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CC_0447: % row(s) repo-wide carry this migration''s marker, expected exactly 5', v_n;
  END IF;

  -- 8. THE LOSERS ARE UNTOUCHED, DELIBERATELY. A loser is recorded because AP's ballot names
  --    them, never because they are not the winner. The other eight rows in these five races
  --    must still carry no result at all.
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
   WHERE rc.race_id IN (SELECT race_id FROM cc0447_pins)
     AND rc.id NOT IN (SELECT rc_id FROM cc0447_pins)
     AND rc.result IS NOT NULL;
  IF v_n <> 0 THEN
    SELECT string_agg(rc.full_name || ' -> ' || rc.result, ', ') INTO v_names
      FROM essentials.race_candidates rc
     WHERE rc.race_id IN (SELECT race_id FROM cc0447_pins)
       AND rc.id NOT IN (SELECT rc_id FROM cc0447_pins)
       AND rc.result IS NOT NULL;
    RAISE EXCEPTION 'CC_0447: % non-winner row(s) in these races gained a result; losers are a separate pass: %', v_n, v_names;
  END IF;

  -- 9. it seats nobody: no term may start 2027-01-03 on these five offices
  SELECT count(*) INTO v_n
    FROM essentials.office_terms ot
    JOIN essentials.races r   ON r.id IN (SELECT race_id FROM cc0447_pins)
    JOIN essentials.offices o ON o.id = r.office_id AND o.id = ot.office_id
   WHERE ot.term_start = DATE '2027-01-03';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0447: % term(s) start 2027-01-03 on these offices; this migration seats nobody', v_n;
  END IF;

  RAISE NOTICE 'CC_0447 OK: 5 House calls recorded (CA-04, CA-23, CO-04, ME-02, NC-07), delta % -> %, 8 non-winner rows untouched', v_before, v_after;
END $$;

COMMIT;
