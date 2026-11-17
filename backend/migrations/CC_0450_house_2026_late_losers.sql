-- CC_0450 — 2026-11-03 U.S. House: the losers AP's own ballots name in the five CC_0447 races.
--
-- WHAT THIS DOES
--   CC_0447 recorded five winners and deliberately recorded no losers. This is that pass.
--   It writes result = 'lost' / result_certainty = 'called' on exactly SEVEN race_candidates
--   rows — every non-winner AP's own ballot names in those five races, and no other row.
--
--     CA-04  Mike Thompson      Dem  120,361  47.47%   defeated incumbent
--     CA-23  Tessa Lynn Hodge   Dem  105,783  49.17%
--     CO-04  Lauren Boebert     GOP  184,220  47.89%   defeated incumbent
--     CO-04  Douglas Mangeris   Lib   12,742   3.31%
--     ME-02  Matthew Dunlap     Dem  164,845  48.31%   ranked choice, final round 165,432
--     NC-07  Kimberly Hardy     Dem  158,391  49.15%
--     NC-07  Maad Abu-Ghazalah  Lib    3,173   0.98%
--
-- 🔴 THE RULE: A LOSER IS RECORDED BECAUSE AP'S BALLOT NAMES THEM (CC_0351).
--   "Everyone in a called race who is not the winner lost" is the inference CC_0339, CC_0350
--   and CC_0447 all refused, and CC_0351 wrote down why: our table still carries Lindsey
--   Graham, who died in office 2026-07-11 and was not on the November ballot. A blanket rule
--   would have recorded a dead man as losing an election he was not in.
--   So every row here was matched against AP's own candidate list for its race, one at a time.
--
-- 🔴 EIGHT OF OUR ROWS ARE NON-WINNERS. SEVEN ARE WRITTEN. THE EIGHTH IS THE FINDING.
--   CO-04's Luis Galvan is NOT on AP's ballot, so nothing is written for him, and assertion 7
--   fails if anything is. He is not a stale row and not a primary loser: he is a declared
--   WRITE-IN candidate. Ballotpedia's CO-04 general-election result table lists him as
--   "Luis Galvan (R) (Write-in)" with 0 votes, beside the three printed lines AP carries.
--   That explains both facts about his row at once — why his candidate_status is 'filed'
--   while Douglas Mangeris, seeded from the SAME Colorado Secretary of State list, is
--   'active'; and why AP omits him, because AP's CO-04 ballot carries no write-in line at all.
--   ⚠ His vote total cannot be settled today. Colorado's county abstracts are due to the
--     Secretary of State within 22 days of the general election (C.R.S. 1-10-105), so the
--     document that can confirm a write-in's count publishes on or after 2026-11-25.
--     A 0 on an aggregator before the canvass is not the same fact as a certified 0.
--   ▶ 2026-11-25: read Colorado's abstract, then decide Galvan. See LOSERS.md beside this.
--
-- 🔴 AP'S ME-02 BALLOT CARRIES BOTH KINDS OF "WRITE-IN" AT ONCE, AND A REGEX MERGES THEM.
--     "Blank Votes"              no first name   6,021 votes  -> NOT a person
--     "Gregory Ward (write-in)"  first "Gregory"    125 votes  -> a person
--   CC_0351 met the same shape spelled "Total Write-ins". The discriminator is the ABSENCE
--   of a first name, not the words in the surname. Gregory Ward is a real candidate we hold
--   no row for, so no loss is recorded against him — we cannot mark a row that does not
--   exist. He is the only AP line in these five races we do not hold.
--
-- 🟢 WHAT IT OVERWRITES: NOTHING. All four result columns are NULL on all seven rows, read
--   from production 2026-11-17 and recorded verbatim in
--   backend/data/house-2026-late-losers/before-values.json, which holds all 13 rows in the
--   five races, winners included. Unlike CC_0351 — where 104 of 599 rows already carried a
--   state ballot-qualification citation that had to be appended rather than replaced — this
--   migration destroys no citation. The pre-check refuses if any of the four is non-NULL.
--   The rows' `source` column (where the candidacy came from) is NOT touched.
--
-- SOURCE
--   AP's own results feed, no key:
--     https://interactives.apelections.org/election-results/data-live/2026-11-03/results/national/metadata.json
--     https://interactives.apelections.org/election-results/data-live/2026-11-03/results/national/progress.json
--   Captured 2026-11-17 14:26Z into backend/data/house-2026-late-losers/ap-ballots-2026-11-17.json
--   — AP's FULL ballot for the five races, every line, not just the winner. Re-fetched for this
--   migration rather than reusing CC_0447's 03:00Z capture: every vote count, percentage and
--   lastUpdated stamp came back identical, so the numbers below are measured twice.
--   🔴 A MEDIA CALL IS NOT A STATE CANVASS. Every row here is `called`. AP reports
--   isCertified = false for all five races, and assertion 5 fails if anything claims otherwise.
--
-- ⚠ AP AND WE SPELL ONE NAME DIFFERENTLY, AND OURS IS THE LONGER ONE.
--   AP's CA-23 line reads "Tessa Hodge"; our row reads "Tessa Lynn Hodge". Confirmed from
--   outside AP: Ballotpedia's CA-23 general-election result table also writes "Tessa Lynn
--   Hodge". Same person. The match was made on "our last_name ENDS WITH AP's last, and the
--   first names agree", and control M3 proved that fallback is what carries her — renaming
--   AP's line drops her from the match set rather than leaving her matched by accident.
--   The citation records BOTH spellings, and LOSER= carries OUR spelling, because assertion 2
--   compares that token against the row's own full_name.
--
-- 🔴 THE GATE MUST NOT READ ITS EXPECTATION OUT OF THIS FILE.
--   CC_0447, CC_0448 and CC_0449 each lost a control to the same defect: a check that compares
--   a row against the migration's OWN declared value is satisfied by any pin edited
--   consistently, so it tests a vocabulary instead of a pairing. Three migrations running, so
--   it is treated here as a house rule. All three pairing assertions below take their
--   expectation from somewhere a tamper on this file cannot reach:
--     assertion 2 — the LOSER= token must equal the row's own `full_name`, read from the table;
--     assertion 3 — the AP race id in the citation must equal the AP race id already carried
--                   by THAT RACE'S WINNER, written to production by CC_0447 and not editable
--                   from here;
--     assertion 4 — the (STATE-DD) seat label must be derivable from the row's own district
--                   geography, `d.state` and `substr(d.geo_id, 3, 2)`.
--
-- Applied to production 2026-11-17 after a BEGIN/ROLLBACK dry run.

BEGIN;

-- The seven pins. rc_id is read from production; race_id, geo_id and full_name are re-asserted
-- against the live row, so a mistyped id RAISES instead of silently moving a loss onto someone.
CREATE TEMP TABLE cc0450_pins (
  rc_id      uuid PRIMARY KEY,
  race_id    uuid NOT NULL,
  geo_id     text NOT NULL,
  full_name  text NOT NULL,
  src        text NOT NULL
) ON COMMIT DROP;

INSERT INTO cc0450_pins VALUES
 ('6a13b60d-fa1b-442b-b26c-bd99ab4950ae','eabbb909-51bc-4498-ab4f-10b0f1d83ad3','0604',
  'Mike Thompson',
  'AP race call, AP race 20261103CA5694 (CA-04). LOSER=Mike Thompson; Dem, 120,361 votes, 47.47%, the defeated incumbent. AP called the seat for Eric Jones 2026-11-14T01:25:15.131Z. AP results feed read 2026-11-17 14:26Z. A media call is not the state canvass.'),
 ('b5280412-c7bd-4a0d-ba14-3e74474bb2d3','7740b4c3-587b-4823-a530-8c229e20debd','0623',
  'Tessa Lynn Hodge',
  'AP race call, AP race 20261103CA5713 (CA-23). LOSER=Tessa Lynn Hodge; Dem, 105,783 votes, 49.17%. AP called the seat for Jay Obernolte 2026-11-17T01:29:31.253Z. AP spells the ballot line "Tessa Hodge"; Ballotpedia''s CA-23 result table writes "Tessa Lynn Hodge", as we do. AP results feed read 2026-11-17 14:26Z. A media call is not the state canvass.'),
 ('3adc274f-fb6f-4008-82f7-360bae9e9d94','f2a99107-c9b6-4201-8b2c-6548d5969fe1','0804',
  'Lauren Boebert',
  'AP race call, AP race 20261103CO6616 (CO-04). LOSER=Lauren Boebert; GOP, 184,220 votes, 47.89%, the defeated incumbent. AP called the seat for Eileen Laubacher 2026-11-13T19:53:37.315Z. AP results feed read 2026-11-17 14:26Z. A media call is not the state canvass.'),
 ('7948f0bf-9a41-4e57-b086-2a04b15827d9','f2a99107-c9b6-4201-8b2c-6548d5969fe1','0804',
  'Douglas Mangeris',
  'AP race call, AP race 20261103CO6616 (CO-04). LOSER=Douglas Mangeris; Lib, 12,742 votes, 3.31%. AP called the seat for Eileen Laubacher 2026-11-13T19:53:37.315Z. AP results feed read 2026-11-17 14:26Z. A media call is not the state canvass.'),
 ('9535183c-f26b-449a-ae22-632ff48658dd','aa63d55d-80b8-42b9-9aa5-0713387f65fb','2302',
  'Matthew Dunlap',
  'AP race call, AP race 20261103ME20645 (ME-02), RANKED CHOICE. LOSER=Matthew Dunlap; Dem, first-choice 164,845 votes, 48.31% of all 341,256 ballots cast, of which 6,021 were blank. No candidate cleared 50% on first choices, so Maine ran its ranked-choice tabulation; AP''s final round gives Paul LePage 170,890 to Dunlap 165,432. AP called the seat for LePage 2026-11-12T18:31:29.417Z. AP results feed read 2026-11-17 14:26Z. A media call is not the state canvass.'),
 ('776b8a10-3073-4f26-b9db-d7bd64de39da','5be80001-9052-47dd-913d-704685975bb9','3707',
  'Kimberly Hardy',
  'AP race call, AP race 20261103NC34973 (NC-07). LOSER=Kimberly Hardy; Dem, 158,391 votes, 49.15%. AP called the seat for David Rouzer 2026-11-16T20:54:47.014Z. AP results feed read 2026-11-17 14:26Z. A media call is not the state canvass.'),
 ('1bb83977-f10c-49a5-8c19-3195653d40a6','5be80001-9052-47dd-913d-704685975bb9','3707',
  'Maad Abu-Ghazalah',
  'AP race call, AP race 20261103NC34973 (NC-07). LOSER=Maad Abu-Ghazalah; Lib, 3,173 votes, 0.98%. AP called the seat for David Rouzer 2026-11-16T20:54:47.014Z. AP results feed read 2026-11-17 14:26Z. A media call is not the state canvass.');

-- Resolve each pin against the live row, re-asserting race, district and name.
CREATE TEMP TABLE cc0450_resolved ON COMMIT DROP AS
SELECT p.*,
       rc.result             AS result_before,
       rc.result_certainty   AS certainty_before,
       rc.result_source      AS source_before,
       rc.result_recorded_at AS recorded_before
  FROM cc0450_pins p
  JOIN essentials.race_candidates rc ON rc.id = p.rc_id
  JOIN essentials.races r            ON r.id = rc.race_id
  JOIN essentials.elections e        ON e.id = r.election_id
  JOIN essentials.offices o          ON o.id = r.office_id
  JOIN essentials.districts d        ON d.id = o.district_id
 WHERE e.election_date = DATE '2026-11-03'
   AND rc.race_id   = p.race_id
   AND d.geo_id     = p.geo_id
   AND rc.full_name = p.full_name;

-- The delta baseline, captured INSIDE this transaction rather than read off a total another
-- session can move while this file is being written.
CREATE TEMP TABLE cc0450_before ON COMMIT DROP AS
SELECT count(*) FILTER (WHERE rc.result = 'lost')  AS lost_in_the_five,
       count(*) FILTER (WHERE rc.result = 'won')   AS won_in_the_five,
       count(*) FILTER (WHERE rc.result IS NULL)   AS null_in_the_five,
       count(*)                                    AS rows_in_the_five
  FROM essentials.race_candidates rc
 WHERE rc.race_id IN (SELECT DISTINCT race_id FROM cc0450_pins);

DO $$
DECLARE v_n bigint; v_names text;
BEGIN
  SELECT count(*) INTO v_n FROM cc0450_resolved;
  IF v_n <> 7 THEN
    -- 🔴 A PIN THAT DOES NOT RESOLVE RETURNS A SMALLER SET, SILENTLY.
    SELECT string_agg(full_name, ', ' ORDER BY full_name) INTO v_names
      FROM cc0450_pins WHERE rc_id NOT IN (SELECT rc_id FROM cc0450_resolved);
    RAISE EXCEPTION 'CC_0450 pre-check: % of 7 pins resolved to a row in the stated race and district carrying the stated name. Unresolved: %', v_n, coalesce(v_names, '(none)');
  END IF;

  -- The header claims all four result columns are NULL on all seven. Prove it here.
  SELECT count(*) INTO v_n FROM cc0450_resolved
   WHERE result_before IS NOT NULL OR certainty_before IS NOT NULL
      OR source_before IS NOT NULL OR recorded_before IS NOT NULL;
  IF v_n <> 0 THEN
    SELECT string_agg(full_name || ' -> ' || coalesce(result_before, '(no result)'), ', ' ORDER BY full_name)
      INTO v_names FROM cc0450_resolved
     WHERE result_before IS NOT NULL OR certainty_before IS NOT NULL
        OR source_before IS NOT NULL OR recorded_before IS NOT NULL;
    RAISE EXCEPTION 'CC_0450 pre-check: % row(s) already carry a result value, and this migration''s header states all seven were NULL: %', v_n, v_names;
  END IF;

  -- 🔴 A LOSER WITH NO WINNER IS CC_0351'S TX-22 ANOMALY. These five all have one, and this
  --    migration is not the place to create another.
  SELECT count(*) INTO v_n FROM (
    SELECT p.race_id FROM (SELECT DISTINCT race_id FROM cc0450_pins) p
      LEFT JOIN essentials.race_candidates rc ON rc.race_id = p.race_id AND rc.result = 'won'
     GROUP BY p.race_id HAVING count(rc.id) <> 1) z;
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0450 pre-check: % of the five races do not already hold exactly one winner', v_n;
  END IF;

  -- The marker this migration writes must be unseen repo-wide, or the scope gate below would
  -- count somebody else's rows as this migration's.
  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE result_source LIKE '%AP results feed read 2026-11-17 14:26Z%';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0450 pre-check: % row(s) already carry this migration''s marker', v_n;
  END IF;

  -- Luis Galvan's row must be NULL going IN, or assertion 7 would be asserting a state this
  -- migration did not create.
  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE id = 'cd016abb-5166-4a2c-9e87-50d245bb82dd' AND result IS NULL AND full_name = 'Luis Galvan';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'CC_0450 pre-check: Luis Galvan''s row is not a NULL-result row named Luis Galvan (matched %)', v_n;
  END IF;
END $$;

UPDATE essentials.race_candidates rc
   SET result             = 'lost',
       result_certainty   = 'called',
       result_source      = p.src,
       result_recorded_at = COALESCE(rc.result_recorded_at, now()),
       updated_at         = now()
  FROM cc0450_resolved p
 WHERE rc.id = p.rc_id;

-- Post-verify. Counting seven rows says nothing about whether each row names the right person
-- in the right seat, so every assertion below names the thing it is about.
DO $$
DECLARE
  v_n bigint; v_names text; v_before bigint; v_after bigint; v_rows bigint;
BEGIN
  -- 1. exactly seven rows written, and they are the seven pinned rows
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc JOIN cc0450_pins p ON p.rc_id = rc.id
   WHERE rc.result = 'lost';
  IF v_n <> 7 THEN
    RAISE EXCEPTION 'CC_0450: % of the 7 pinned rows carry lost', v_n;
  END IF;

  -- 2. 🔴 THE CITATION MUST NAME THE PERSON IT IS ATTACHED TO.
  --    The expected name is rc.full_name, read from the table — not the pin's declared name,
  --    which a tamper can edit to agree with itself. This is CC_0447's WINNER= lesson.
  SELECT count(*), string_agg(full_name, ', ' ORDER BY full_name) INTO v_n, v_names
    FROM essentials.race_candidates rc
   WHERE rc.id IN (SELECT rc_id FROM cc0450_pins)
     AND rc.result_source NOT LIKE '%LOSER=' || rc.full_name || ';%';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0450: % row(s) carry a result_source that does not name the candidate it is attached to: %', v_n, v_names;
  END IF;

  -- 3. 🔴 THE CITATION MUST NAME THE AP RACE ITS OWN RACE'S WINNER NAMES.
  --    The expected AP race id is pulled out of the WINNER's result_source, which CC_0447
  --    wrote to production and which nothing in this file can edit. Repoint a loser's pin at
  --    another race and the two ids stop agreeing.
  SELECT count(*), string_agg(l.full_name || ' -> ' || coalesce(w.ap_id, '(winner cites none)'), ', ' ORDER BY l.full_name)
    INTO v_n, v_names
    FROM essentials.race_candidates l
    JOIN LATERAL (
      SELECT substring(rc.result_source from 'AP race ([0-9A-Z]+)') AS ap_id
        FROM essentials.race_candidates rc
       WHERE rc.race_id = l.race_id AND rc.result = 'won'
       LIMIT 1) w ON true
   WHERE l.id IN (SELECT rc_id FROM cc0450_pins)
     AND (w.ap_id IS NULL OR l.result_source NOT LIKE '%AP race ' || w.ap_id || ' %');
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0450: % row(s) cite an AP race id their own race''s winner does not cite: %', v_n, v_names;
  END IF;

  -- 4. 🔴 THE SEAT LABEL MUST MATCH THE ROW'S OWN GEOGRAPHY.
  --    "(CA-04)" is rebuilt here from d.state and the district digits of d.geo_id.
  SELECT count(*), string_agg(rc.full_name, ', ' ORDER BY rc.full_name) INTO v_n, v_names
    FROM essentials.race_candidates rc
    JOIN essentials.races r     ON r.id = rc.race_id
    JOIN essentials.offices o   ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE rc.id IN (SELECT rc_id FROM cc0450_pins)
     AND rc.result_source NOT LIKE '%(' || upper(d.state) || '-' || substr(d.geo_id, 3, 2) || ')%';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0450: % row(s) carry a seat label that is not the seat the row sits in: %', v_n, v_names;
  END IF;

  -- 5. nothing claims certification, and every written row says `called`
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
   WHERE rc.id IN (SELECT rc_id FROM cc0450_pins)
     AND (rc.result_certainty IS DISTINCT FROM 'called'
          OR rc.result_source NOT LIKE '%A media call is not the state canvass.%');
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0450: % row(s) do not carry certainty called with the canvass caveat', v_n;
  END IF;

  -- 6. CC_0447'S FIVE WINNERS ARE UNTOUCHED. A losers pass must not disturb a win.
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
   WHERE rc.race_id IN (SELECT DISTINCT race_id FROM cc0450_pins)
     AND rc.result = 'won'
     AND rc.result_source LIKE '%WINNER=' || rc.full_name || ';%'
     AND rc.result_source LIKE '%AP results feed read 2026-11-17 03:00Z%';
  IF v_n <> 5 THEN
    RAISE EXCEPTION 'CC_0450: only % of the 5 CC_0447 winners still carry their own WINNER= citation and CC_0447''s marker', v_n;
  END IF;

  -- 7. 🔴 LUIS GALVAN IS DELIBERATELY ABSENT. AP's ballot does not name him.
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates
   WHERE id = 'cd016abb-5166-4a2c-9e87-50d245bb82dd'
     AND (result IS NOT NULL OR result_certainty IS NOT NULL OR result_source IS NOT NULL);
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'CC_0450: Luis Galvan was given a result; AP''s CO-04 ballot does not name him and this migration must leave him alone';
  END IF;

  -- 8. exactly one non-winner row in the five races is still NULL, and it is Galvan's
  SELECT count(*), string_agg(full_name, ', ' ORDER BY full_name) INTO v_n, v_names
    FROM essentials.race_candidates
   WHERE race_id IN (SELECT DISTINCT race_id FROM cc0450_pins) AND result IS NULL;
  IF v_n <> 1 OR v_names IS DISTINCT FROM 'Luis Galvan' THEN
    RAISE EXCEPTION 'CC_0450: expected exactly one row left without a result (Luis Galvan), found %: %', v_n, coalesce(v_names, '(none)');
  END IF;

  -- 9. scope: exactly seven rows REPO-WIDE carry this migration's marker
  SELECT count(*) INTO v_n FROM essentials.race_candidates
   WHERE result_source LIKE '%AP results feed read 2026-11-17 14:26Z%';
  IF v_n <> 7 THEN
    RAISE EXCEPTION 'CC_0450: % row(s) repo-wide carry this migration''s marker, expected exactly 7', v_n;
  END IF;

  -- 10. the DELTA, measured against the baseline captured in this transaction
  SELECT lost_in_the_five, rows_in_the_five INTO v_before, v_rows FROM cc0450_before;
  SELECT count(*) FILTER (WHERE result = 'lost'), count(*) INTO v_after, v_n
    FROM essentials.race_candidates
   WHERE race_id IN (SELECT DISTINCT race_id FROM cc0450_pins);
  IF v_after - v_before <> 7 THEN
    RAISE EXCEPTION 'CC_0450: losers in the five races moved % -> %, a delta of %, expected exactly 7', v_before, v_after, v_after - v_before;
  END IF;

  -- 11. 🔴 NO ROW WAS CREATED. Gregory Ward is an AP candidate we hold no row for, and a
  --     losers pass is not where a missing contender gets seeded.
  IF v_n <> v_rows THEN
    RAISE EXCEPTION 'CC_0450: the five races held % rows and now hold % — this migration creates and deletes nothing', v_rows, v_n;
  END IF;
END $$;

COMMIT;
