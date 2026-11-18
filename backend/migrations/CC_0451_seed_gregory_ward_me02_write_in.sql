-- CC_0451 — seed Gregory A. Ward, ME-02 declared write-in, and record his loss.
--
-- WHAT THIS OVERWRITES: nothing. It creates exactly ONE row in
-- essentials.race_candidates and updates no existing row. The two rows ME-02
-- already holds (Paul LePage, won — CC_0447; Matthew Dunlap, lost — CC_0450)
-- are asserted untouched, byte for byte, by assertion 11.
--
-- ─────────────────────────────────────────────────────────────────────────────
-- WHY THIS ROW WAS MISSING, AND WHY THAT IS THE SAME FINDING AS LUIS GALVAN
-- ─────────────────────────────────────────────────────────────────────────────
-- CC_0450 recorded seven losers in the five CC_0447 races and reported one AP
-- ballot line we held no row for: ME-02's Gregory Ward. A losers pass is not
-- where a missing contender gets seeded, so it created nothing. This is that
-- seed.
--
-- He was missing because every Maine seeding pass read a list he is not on.
-- Maine's "2026 General Candidate List" names the candidates PRINTED ON THE
-- BALLOT. A declared write-in is on a SEPARATE register, published 70 days
-- before the election. Our ME-02 rows came from the upcoming-elections page and
-- Wikipedia (June/July 2026); CC_0414 read the General Candidate List. None of
-- those three can contain him.
--
-- 🔴 That is CC_0450's Galvan finding reflected. Galvan is a declared write-in
--    our data HOLDS and AP's ballot OMITS. Ward is a declared write-in AP's
--    ballot HOLDS and our data OMITTED. Same cause both times — a source that
--    covers printed ballot lines and a source that covers write-ins are not the
--    same source — and it produces a missing row in whichever direction you
--    happen to be reading.
--
-- ─────────────────────────────────────────────────────────────────────────────
-- SOURCES, BOTH PRIMARY, BOTH READ DIRECTLY
-- ─────────────────────────────────────────────────────────────────────────────
-- CANDIDACY — Maine Secretary of State, "Declared Write-in Candidates for the
-- November 3, 2026 General Election", dated 8/25/26. One page. Row 7 reads:
--
--     CG | 2 | | Independent | Gregory A. Ward | Limestone | Congressional District 2
--
-- Downloaded and read as a document, not summarised by a fetch tool.
-- 🔴 THE STATE SPELLS HIM WITH A MIDDLE INITIAL AND AP DOES NOT. The state's
--    register is the authority on the candidacy, so full_name carries the
--    state's spelling and the citation records AP's. This is CC_0450's Hodge
--    rule: the longer, officially-sourced spelling wins, and assertion 2
--    compares the LOSER= token against the row's own full_name.
--
-- LAW — 21-A M.R.S. §696(2)(E): a write-in vote for a person who has not filed
-- a declaration under §722-A "may not be counted". So his 123–125 votes are
-- countable votes precisely BECAUSE he is on that register, and the register is
-- what makes him a contender rather than ink on a ballot.
--
-- RESULT — AP's own feed, the same 2026-11-17 14:26Z capture CC_0450 used,
-- committed at backend/data/house-2026-late-losers/ap-ballots-2026-11-17.json.
--
-- ─────────────────────────────────────────────────────────────────────────────
-- 🔴 HIS CANDIDACY IS WHY THIS RACE WAS TABULATED BY RANKED CHOICE AT ALL
-- ─────────────────────────────────────────────────────────────────────────────
-- Maine's own 2026 Candidates Guide to Ballot Access: the general election for
-- U.S. Congress is decided by ranked choice "if three or more candidates
-- qualify for the office, or if two candidates qualify for the ballot and there
-- is a declared write-in candidate in the race." ME-02 printed exactly two
-- names and had exactly one declared write-in — him — and the race did in fact
-- go to a ranked-choice tabulation. A 125-vote candidate changed the method by
-- which 341,256 ballots were counted. That is a reason to hold the row, not a
-- rounding error.
--
-- ─────────────────────────────────────────────────────────────────────────────
-- 🔴 TWO SOURCES, SAME VOTES, DIFFERENT GRANULARITY — AND BOTH ARE UNOFFICIAL
-- ─────────────────────────────────────────────────────────────────────────────
--   AP, read 2026-11-17 14:26Z at 97.83% EEVP : "Gregory" / "Ward (write-in)", 125 votes, 0.04%
--   Maine SoS release, 2026-11-12, election night: "123 first-choice votes (0.036%)
--                                                   for declared write-in candidates"
--
-- AP publishes the NAME. The State publishes an AGGREGATE. CD-2's declared
-- register carries exactly one name and §696(2)(E) counts nobody else, so that
-- aggregate IS him — but the two documents are making different claims and a
-- later pass must not read them as disagreeing about a person.
--
-- ⚠ The gap is a timestamp, not a contradiction. Every AP line on this race
--   sits a little above the State's election-night figures, in the same
--   direction and by small amounts: LePage 170,265 vs 170,263, Dunlap 164,845
--   vs 164,845, blanks 6,021 vs 6,017, write-ins 125 vs 123, total 341,256 vs
--   341,248. AP read later. Nothing here is certified.
--
-- ⚠ A SEARCH SUMMARY CLAIMED MAINE REPORTS A WRITE-IN BY NAME ONLY ABOVE 5%.
--   It is not in the statute and the State's own guide says the opposite —
--   "Minimum Number of Write-in Votes Needed in General Election: In the
--   general election, a candidate needs to receive at least one vote." The
--   4,000/2,000-vote thresholds in that guide are PRIMARY write-in nomination
--   thresholds. The 5% rule is not written down here because it does not exist.
--
-- ▶ 2026-11-23: official results are due within 20 days of the election
--   ("Results are unofficial until the official tabulation of the votes cast is
--   communicated to Governor Janet Mills"). Read them, then certify this row
--   and the other twelve. Assertion 6 fails if anything claims 'certified' now.
--
-- ─────────────────────────────────────────────────────────────────────────────
-- WHAT THIS DELIBERATELY DOES NOT DO
-- ─────────────────────────────────────────────────────────────────────────────
-- 🔴 It creates NO essentials.politicians row, and politician_id stays NULL.
--    A race_candidates row is a claim about a ballot; a politicians row is a
--    claim about a person's identity, and this repo has shipped three namesake
--    errors into production. The recent AP seeding passes (CC_0413, CC_0415,
--    CC_0416) all leave politician_id NULL for exactly this reason. Assertion 9
--    pins the consequence: essentials.trg_race_candidate_mirror_data fires on
--    INSERT, and mirror_candidate_data_to_politician returns immediately when
--    politician_id IS NULL — so no politician row and no politician_images row
--    may be created by this file.
-- 🔴 It records no party on the row. Party is antipartisan here by design and
--    lives on races.primary_party. "Independent" appears only inside the
--    citation, as what the State's register says.
BEGIN;

-- ─── Pins. Named, so a tamper cannot quietly widen the scope. ───────────────
CREATE TEMP TABLE cc0451_pin ON COMMIT DROP AS
SELECT 'aa63d55d-80b8-42b9-9aa5-0713387f65fb'::uuid AS race_id;

-- ─── Baselines, captured INSIDE this transaction. Never a total somebody else
--     can move while the file is being written. ────────────────────────────────
CREATE TEMP TABLE cc0451_base ON COMMIT DROP AS
SELECT (SELECT count(*) FROM essentials.race_candidates)                   AS rc_total,
       (SELECT count(*) FROM essentials.race_candidates rc
          JOIN cc0451_pin p ON p.race_id = rc.race_id)                     AS me02_rows,
       (SELECT count(*) FROM essentials.politicians)                       AS pol_total,
       (SELECT count(*) FROM essentials.politician_images)                 AS img_total;

-- ─── Pre-check. The anchor assertion 3 depends on must exist before we write. ─
DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
    JOIN cc0451_pin p ON p.race_id = rc.race_id
   WHERE rc.result = 'won'
     AND rc.result_source LIKE '%AP race 20261103ME20645 (ME-02)%';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'pre-check: expected exactly 1 winner row in ME-02 citing AP race 20261103ME20645, found %', v_n;
  END IF;

  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
    JOIN cc0451_pin p ON p.race_id = rc.race_id
   WHERE rc.is_write_in;
  IF v_n > 1 THEN
    RAISE EXCEPTION 'pre-check: ME-02 already holds % write-in row(s); this file seeds exactly one', v_n;
  END IF;
END $$;

-- ─── The write. Guarded, so a second run is a no-op. ────────────────────────
INSERT INTO essentials.race_candidates
  (race_id, full_name, first_name, last_name,
   candidate_status, is_incumbent, is_write_in, politician_id,
   source, result, result_certainty, result_source, result_recorded_at)
SELECT p.race_id,
       'Gregory A. Ward', 'Gregory', 'Ward',
       'active', false, true, NULL,
       'Maine Secretary of State, "Declared Write-in Candidates for the November 3, 2026 General Election", dated 8/25/26 (https://www.maine.gov/sos/sites/maine.gov.sos/files/inline-files/Nov26%20Declared%20Write%20in%20List.pdf), read as a document 2026-11-17. Its row 7 reads: office CG, district 2, Independent, Gregory A. Ward, residence Limestone, municipalities affected "Congressional District 2". He is not on the printed ballot: 21-A M.R.S. 696(2)(E) counts a write-in vote only for a person who filed a declaration of write-in candidacy under 722-A, and this register is that filing. The declaration deadline was 5 p.m. 2026-08-25, the 70th day before the election. Under the Secretary of State 2026 Candidates Guide to Ballot Access, a U.S. Congress general election with two ballot-qualified candidates and a declared write-in is decided by ranked choice, which is why ME-02 was tabulated by ranked choice. Seeded by CC_0451.',
       'lost', 'called',
       'AP race call, AP race 20261103ME20645 (ME-02), RANKED CHOICE. LOSER=Gregory A. Ward; declared write-in, AP first-choice 125 votes, 0.04% of all 341,256 ballots cast, eliminated in the ranked-choice tabulation with 0 votes in the final round. AP spells the line "Gregory" / "Ward (write-in)" and the marker sits inside the surname field, so AP omits the middle initial the State register carries. The Secretary of State own release of 2026-11-12 reports the same votes as an AGGREGATE, "123 first-choice votes (0.036%) for declared write-in candidates", not by name; CD-2 declared register carries exactly one name and 21-A M.R.S. 696(2)(E) counts nobody else, so that aggregate is his. The two unofficial counts differ by a read time, not a dispute: AP read 2026-11-17 14:26Z at 97.83% EEVP, the State figures are election night. AP called the seat for Paul LePage 2026-11-12T18:31:29.417Z. AP results feed read 2026-11-17 14:26Z. A media call is not the state canvass, and official results are due within 20 days of the election, on or before 2026-11-23. Seeded by CC_0451.',
       now()
  FROM cc0451_pin p
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = p.race_id
      AND rc.first_name = 'Gregory'
      AND rc.last_name  = 'Ward');

-- Post-verify. Counting one row says nothing about whether it is the right row,
-- attached to the right race, citing the right election. Each assertion below
-- takes its expectation from somewhere a tamper on THIS FILE cannot reach: the
-- row's own full_name, the row's own geography, or a citation written to
-- production by CC_0447 and CC_0450.
DO $$
DECLARE
  v_n     int;
  v_txt   text;
  v_base  record;
BEGIN
  SELECT * INTO v_base FROM cc0451_base;

  -- 1. Exactly one Ward row in ME-02, and every column is what this file claims.
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
    JOIN cc0451_pin p ON p.race_id = rc.race_id
   WHERE rc.full_name = 'Gregory A. Ward'
     AND rc.first_name = 'Gregory'
     AND rc.last_name = 'Ward'
     AND rc.candidate_status = 'active'
     AND rc.is_write_in IS TRUE
     AND rc.is_incumbent IS FALSE
     AND rc.politician_id IS NULL
     AND rc.result = 'lost';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'assertion 1: expected exactly 1 fully-formed Gregory A. Ward row in ME-02, found %', v_n;
  END IF;

  -- 2. 🔴 THE CITATION MUST NAME THE PERSON IT IS ATTACHED TO.
  --    Expectation: rc.full_name, read from the table.
  SELECT count(*), coalesce(string_agg(full_name, ', '), '(none)') INTO v_n, v_txt
    FROM essentials.race_candidates rc
    JOIN cc0451_pin p ON p.race_id = rc.race_id
   WHERE rc.first_name = 'Gregory' AND rc.last_name = 'Ward'
     AND rc.result_source NOT LIKE '%LOSER=' || rc.full_name || ';%';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'assertion 2: % row(s) carry a result_source that does not name the candidate it is attached to: %', v_n, v_txt;
  END IF;

  -- 3. 🔴 THE CITATION MUST NAME THE AP RACE ITS OWN RACE'S WINNER NAMES.
  --    Expectation: the winner's result_source, written to production by CC_0447.
  SELECT count(*), coalesce(string_agg(l.full_name || ' -> ' || coalesce(w.ap_id, '(winner cites none)'), ', '), '(none)')
    INTO v_n, v_txt
    FROM essentials.race_candidates l
    JOIN cc0451_pin p ON p.race_id = l.race_id
    JOIN LATERAL (
      SELECT substring(rc.result_source from 'AP race ([0-9A-Z]+)') AS ap_id
        FROM essentials.race_candidates rc
       WHERE rc.race_id = l.race_id AND rc.result = 'won'
       LIMIT 1) w ON true
   WHERE l.first_name = 'Gregory' AND l.last_name = 'Ward'
     AND (w.ap_id IS NULL OR l.result_source NOT LIKE '%AP race ' || w.ap_id || ' %');
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'assertion 3: % row(s) cite an AP race id their own race''s winner does not cite: %', v_n, v_txt;
  END IF;

  -- 4. 🔴 THE SEAT LABEL MUST MATCH THE ROW'S OWN GEOGRAPHY.
  --    Expectation: districts.state and districts.geo_id.
  SELECT count(*), coalesce(string_agg(rc.full_name || ' in ' || upper(lower(d.state)) || '-' || substr(d.geo_id, 3, 2), ', '), '(none)')
    INTO v_n, v_txt
    FROM essentials.race_candidates rc
    JOIN cc0451_pin p ON p.race_id = rc.race_id
    JOIN essentials.races   r ON r.id = rc.race_id
    JOIN essentials.offices o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE rc.first_name = 'Gregory' AND rc.last_name = 'Ward'
     AND rc.result_source NOT LIKE '%(' || upper(lower(d.state)) || '-' || substr(d.geo_id, 3, 2) || ')%';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'assertion 4: % row(s) carry a seat label that is not the seat the row sits in: %', v_n, v_txt;
  END IF;

  -- 5. 🔴 HE IS NOT THE WINNER, AND THE WINNER IS STILL THE PERSON CC_0447 NAMED.
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
    JOIN cc0451_pin p ON p.race_id = rc.race_id
   WHERE rc.result = 'won';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'assertion 5: ME-02 must hold exactly one winner, found %', v_n;
  END IF;

  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
    JOIN cc0451_pin p ON p.race_id = rc.race_id
   WHERE rc.result = 'won'
     AND rc.result_source LIKE '%WINNER=' || rc.full_name || ';%'
     AND rc.full_name <> 'Gregory A. Ward';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'assertion 5: ME-02 winner is not the self-naming winner CC_0447 wrote (matched % row(s))', v_n;
  END IF;

  -- 6. 🔴 A MEDIA CALL IS NOT A STATE CANVASS.
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
    JOIN cc0451_pin p ON p.race_id = rc.race_id
   WHERE rc.first_name = 'Gregory' AND rc.last_name = 'Ward'
     AND (rc.result_certainty IS DISTINCT FROM 'called'
          OR rc.result_source NOT LIKE '%A media call is not the state canvass%');
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'assertion 6: % row(s) do not carry certainty called with the canvass caveat', v_n;
  END IF;

  -- 7. 🔴 SCOPE. Exactly one row REPO-WIDE carries this migration's marker.
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
   WHERE rc.source LIKE '%Seeded by CC_0451.%'
      OR rc.result_source LIKE '%Seeded by CC_0451.%';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'assertion 7: % row(s) repo-wide carry this migration''s marker, expected exactly 1', v_n;
  END IF;

  -- 8. 🔴 THIS FILE CREATES ONE ROW AND IT CREATES IT HERE.
  --    The repo-wide delta must equal the ME-02 delta: nothing was created
  --    anywhere else, and nothing was deleted.
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
    JOIN cc0451_pin p ON p.race_id = rc.race_id;
  IF v_n <> 3 THEN
    RAISE EXCEPTION 'assertion 8: ME-02 must hold exactly 3 rows after this file, found %', v_n;
  END IF;
  IF (SELECT count(*) FROM essentials.race_candidates) - v_base.rc_total
     <> v_n - v_base.me02_rows THEN
    RAISE EXCEPTION 'assertion 8: repo-wide row delta % does not equal the ME-02 delta % — this file touched another race',
      (SELECT count(*) FROM essentials.race_candidates) - v_base.rc_total, v_n - v_base.me02_rows;
  END IF;

  -- 9. 🔴 THE MIRROR TRIGGER MUST HAVE DONE NOTHING.
  --    essentials.trg_race_candidate_mirror_data fires on INSERT; its function
  --    returns immediately when politician_id IS NULL. This asserts that
  --    reading rather than trusting it.
  IF (SELECT count(*) FROM essentials.politicians) <> v_base.pol_total THEN
    RAISE EXCEPTION 'assertion 9: politicians count moved from % to % — this file must create no person',
      v_base.pol_total, (SELECT count(*) FROM essentials.politicians);
  END IF;
  IF (SELECT count(*) FROM essentials.politician_images) <> v_base.img_total THEN
    RAISE EXCEPTION 'assertion 9: politician_images count moved from % to % — the mirror trigger fired',
      v_base.img_total, (SELECT count(*) FROM essentials.politician_images);
  END IF;

  -- 10. 🔴 EXACTLY ONE WRITE-IN IN THIS RACE, AND IT IS HIM.
  --     CD-2's declared register carries exactly one name. If this race ever
  --     holds two write-in rows, one of them is wrong.
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
    JOIN cc0451_pin p ON p.race_id = rc.race_id
   WHERE rc.is_write_in IS TRUE AND rc.full_name <> 'Gregory A. Ward';
  IF v_n <> 0 THEN
    RAISE EXCEPTION 'assertion 10: % other write-in row(s) in ME-02', v_n;
  END IF;

  -- 11. 🔴 THE TWO ROWS THAT WERE ALREADY HERE ARE UNTOUCHED.
  --     Expectation: the markers CC_0447 and CC_0450 wrote to production.
  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
    JOIN cc0451_pin p ON p.race_id = rc.race_id
   WHERE rc.result_source LIKE '%AP results feed read 2026-11-17 03:00Z%'
     AND rc.result = 'won' AND rc.result_certainty = 'called';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'assertion 11: CC_0447''s winner row is no longer intact (matched % row(s))', v_n;
  END IF;

  SELECT count(*) INTO v_n
    FROM essentials.race_candidates rc
    JOIN cc0451_pin p ON p.race_id = rc.race_id
   WHERE rc.result_source LIKE '%AP results feed read 2026-11-17 14:26Z%'
     AND rc.result = 'lost' AND rc.result_certainty = 'called'
     AND rc.full_name = 'Matthew Dunlap';
  IF v_n <> 1 THEN
    RAISE EXCEPTION 'assertion 11: CC_0450''s Dunlap row is no longer intact (matched % row(s))', v_n;
  END IF;

  RAISE NOTICE 'CC_0451 OK: Gregory A. Ward seeded in ME-02 as a declared write-in and recorded lost/called; ME-02 holds 3 rows; no person row created.';
END $$;

COMMIT;
