-- CC_0352 - 2026-11-03 federal: seed the four candidates AP names and we did not hold, and
-- retire the Troy Nehls phantom candidacy.
--
-- `CC_0350` and `CC_0351` both ended with the same finding: AP's ballots name people our
-- `race_candidates` does not have, so a result could not be written for them. This closes the
-- four that matter - the TX-22 WINNER, and the three losing candidates who took more than 20%
-- of their district's vote.
--
-- | Seat  | Person            | AP share | What this file does                          |
-- |-------|-------------------|----------|----------------------------------------------|
-- | TX-22 | Trever Nehls      |  51.82%  | new person + candidacy, result 'won'         |
-- | NC-11 | Jennifer Balkcom  |  41.30%  | candidacy only - WE ALREADY HOLD HER         |
-- | LA-01 | Lauren Jewett     |  33.95%  | new person + candidacy, result 'lost'        |
-- | VA-11 | Arthur Purves     |  24.38%  | new person + candidacy, result 'lost'        |
--
-- ⚠ NOTHING HERE IS CERTIFIED and NOTHING HERE SEATS ANYBODY. Trever Nehls won; he takes office
-- on 2027-01-03 by a later migration, and his `politicians.is_incumbent` is therefore FALSE.
-- Troy Nehls still holds the seat until that day and his own politician row is untouched.
--
-- ============================================================================================
-- 🔴 JENNIFER BALKCOM ALREADY EXISTS, AND A SECOND ROW WOULD HAVE BEEN THE REAL DAMAGE
-- ============================================================================================
-- `essentials.politicians` 724dbd0e-5834-4622-8302-bf76c3762d9c - **Jennifer Balkcom, NC State
-- House District 117**, seated 2023-01-01, still serving, `is_incumbent = true`, sourced to
-- ncleg.gov. She holds no candidacy rows at all, which is why the losers pass read her as a
-- person we do not hold: it looked for her in the NC-11 race and she was not there.
--
-- 🔴 ONE ROW PER PERSON. This file creates THREE politicians, not four, and links the fourth.
-- Her row is not edited in any way - not her party (NULL), not her `is_incumbent`, not her
-- state-house term.
--
-- ▶ IDENTITY ESTABLISHED FROM THE PAGE, NOT FROM A SEARCH SUMMARY. WHQR, 2026-08-12:
--   "Republican leaders chose N.C. Rep. Jennifer Balkcom as the new candidate for Congress,
--    opening a spot for a new candidate for the 117th district."
--   https://www.whqr.org/local/2026-08-12/state-rep-jennifer-balkcom-is-taking-u-s-rep-chuck-edwards-place-on-the-nc-11-ticket-heres-what-that-means-for-her-state-house-seat
--   That is our row: NC State House District 117. The NC-11 nominee and the sitting state
--   representative are the same person.
--
-- ============================================================================================
-- 🔴 THE TROY NEHLS ROW IS DELETED, AND THIS IS EVERY VALUE IT HELD
-- ============================================================================================
-- Our TX-22 ballot carried Troy Nehls, the retiring incumbent, who did not seek re-election.
-- His twin brother Trever won the March 2026 primary to succeed him and then the general. No
-- `result` and no `candidate_status` says "this candidacy never existed": `withdrew` would
-- assert he withdrew, and he never filed. So the row goes, and because there is no history
-- table, every column it held is written down here:
--
--   essentials.race_candidates
--     id                       686d5b3a-a7df-4a67-bdba-d6b784181889
--     race_id                  ef2f9063-233b-4a2a-8ded-fea5094cdc98   (TX-22, 2026-11-03)
--     politician_id            a0bc977b-71c6-4973-9082-3cc009445a02   (Troy Nehls - KEPT)
--     full_name                'Troy Nehls'
--     first_name               'Troy'
--     last_name                'Nehls'
--     candidate_status         'active'
--     is_incumbent             true
--     is_write_in              false
--     result                   NULL
--     result_certainty         NULL
--     result_source            NULL
--     result_recorded_at       NULL
--     external_id              NULL
--     photo_url                NULL
--     website_url              NULL
--     occupational_designation NULL
--     provisional_until        NULL
--     last_verified_at         NULL
--     created_at               2026-06-29T20:55:56.714Z
--     source                   'https://en.wikipedia.org/wiki/2026_United_States_House_of_Representatives_elections_in_Texas#District_22'
--     updated_at               ⚠ NOT RECORDED - SEE BELOW. (Comment-only correction, 2026-11-05.)
--
-- 🔴 CORRECTION, 2026-11-05: THE LIST ABOVE SAID "EVERY COLUMN" AND WAS ONE SHORT.
-- `race_candidates` has 22 columns and 21 were written down. `updated_at` was missed, the row
-- was deleted in the same file, and there is no history table - so that one value is GONE and
-- this note is all that can be said about it. It is recorded here rather than quietly fixed,
-- because the omission is the kind of thing this header exists to prevent.
-- ⚠ AND IT CANNOT BE INFERRED FROM `created_at`. No trigger maintains `updated_at` on this
-- table, so an untouched row keeps its insert default - but it is set by hand in some code
-- paths, and 1,060 of the table's 5,175 rows carry a value later than their `created_at`
-- (measured 2026-11-05). Troy Nehls' row may or may not have been one of them. ▶ Writing
-- "probably 2026-06-29T20:55:56.714Z" here would be a guess wearing a timestamp's clothes.
-- Found while writing `CC_0354`, which had to establish what this column can and cannot date.
-- 🟢 Nothing else in this file changes: the SQL that ran against production is untouched, and
-- only these comment lines were added.
--
-- ⚠ DELETING A CANDIDACY IS NOT DELETING A PERSON. `essentials.politicians`
-- a0bc977b-71c6-4973-9082-3cc009445a02 stays exactly as it is - active, incumbent, holding the
-- TX-22 seat until 2027-01-03 - and a gate below re-asserts that.
-- ⚠ Only one foreign key points at `race_candidates` (`candidate_staging.matched_candidate_id`)
-- and this row is referenced by none. A gate asserts that BEFORE the delete runs.
--
-- ============================================================================================
-- 🔴 CHUCK EDWARDS REALLY DID WITHDRAW, AND THAT IS WHY HE IS TREATED DIFFERENTLY
-- ============================================================================================
-- NC-11's ballot carries the sitting incumbent Chuck Edwards with no result. Adding Balkcom
-- without touching him would leave the race showing TWO live Republicans - this migration
-- would make that page worse, not better.
--
-- 🔴 THE TWO CASES LOOK IDENTICAL IN THE DATA AND ARE NOT THE SAME FACT. Troy Nehls never
-- filed, so his row is an error. Chuck Edwards FILED AND THEN WITHDREW, and the NCGOP's 11th
-- District Executive Committee picked Balkcom to replace him on 2026-08-10. `withdrew` is a
-- true statement about him and a false one about Troy Nehls. Same shape, opposite handling.
--
--   OVERWRITTEN: race_candidates 60e3e4d9-d492-4da2-b2c8-86600453d249 (Chuck Edwards, NC-11)
--     candidate_status  'active' -> 'withdrawn'
--     result            NULL     -> 'withdrew'
--     result_source     NULL     -> the citation below
--   His `source` column and his politician row are untouched; he still holds the seat until
--   2027-01-03.
--
-- ============================================================================================
-- WHAT IS STILL MISSING FROM THESE FOUR RACES
-- ============================================================================================
-- After this file, TX-22 and NC-11 match AP's ballot exactly. Two minor candidates remain
-- unheld, and they are part of the 106-row backlog `CC_0351` reported rather than this task:
--   LA-01  E. Liddy Glass   (NPA)  1.62%,  4,279 votes
--   VA-11  Dianne Blais     (Grn)  1.22%,  4,078 votes
-- Each needs its own person record and its own sourcing, so neither is smuggled in here.
--
-- ⚠ FOLLOW-UP, NOT DONE HERE: `CC_0339`, `CC_0350` and `CC_0351` wrote 1,009 result rows and
-- left `result_recorded_at` NULL on every one. This file sets it on the rows it writes. A
-- backfill of those 1,009 is a separate pass; it touches rows two open PRs own.
--
-- ============================================================================================
-- SOURCES
-- ============================================================================================
-- Every vote share, party and AP race id below is read from AP's own feed,
-- https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04),
-- the same source as `CC_0339`, `CC_0350` and `CC_0351`. Each person's identity and candidacy
-- was corroborated separately; the citation travels in the row.

CREATE TEMP TABLE seed_people (
  seat        text,
  geo_id      text,
  race_id     uuid,
  full_name   text,
  first_name  text,
  last_name   text,
  result      text,
  person_src  text,
  result_src  text
) ON COMMIT DROP;

INSERT INTO seed_people VALUES
  ('TX-22', '4822', 'ef2f9063-233b-4a2a-8ded-fea5094cdc98',
   'Trever Nehls', 'Trever', 'Nehls', 'won',
   'AP candidate list for the 2026-11-03 US House general election, TX-22 (AP candidateID 170023), https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). Republican nominee; won the March 2026 primary to succeed his retiring twin brother, Rep. Troy Nehls, who did not seek re-election. Seeded by CC_0352.',
   'AP race call for the 2026-11-03 general election: Trever Nehls (GOP) 51.82%, 150,161 votes - WON. AP race 20261103TX45892, called 2026-11-04T22:12:10.165Z, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). AP distinguishes him (candidateID 170023) from the seat''s incumbent Troy Nehls (candidateID 68186), his twin brother, who was not on the ballot. UNOFFICIAL - this is a race call, not the state canvass.'),

  ('LA-01', '2201', '10a69df9-4fdd-4f33-a6d5-58c6d43d8f03',
   'Lauren Jewett', 'Lauren', 'Jewett', 'lost',
   'AP candidate list for the 2026-11-03 US House general election, LA-01 (AP candidateID 72354), https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). Democratic candidate against incumbent Steve Scalise; a New Orleans special education teacher. Seeded by CC_0352.',
   'AP race call for the 2026-11-03 general election: Lauren Jewett (Dem) 33.95%, 89,428 votes - DID NOT WIN. AP race 20261103LA20556, called 2026-11-04T03:58:50.646Z, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). This person appears on AP''s own candidate list for the race; the loss is not inferred from not being the winner. UNOFFICIAL - this is a race call, not the state canvass.'),

  ('NC-11', '3711', '74af01ff-3f67-4a7c-915c-3a8e85830c0e',
   'Jennifer Balkcom', 'Jennifer', 'Balkcom', 'lost',
   'AP candidate list for the 2026-11-03 US House general election, NC-11 (AP candidateID 136989), https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). Republican nominee, chosen by the NCGOP 11th District Executive Committee on 2026-08-10 to replace Rep. Chuck Edwards, who withdrew. Identity confirmed against our existing politician row (NC State House District 117) from WHQR, 2026-08-12: "Republican leaders chose N.C. Rep. Jennifer Balkcom as the new candidate for Congress, opening a spot for a new candidate for the 117th district." Linked by CC_0352; the person row was NOT created here.',
   'AP race call for the 2026-11-03 general election: Jennifer Balkcom (GOP) 41.3%, 141,427 votes - DID NOT WIN. AP race 20261103NC34977, called 2026-11-04T01:53:13.100Z, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). This person appears on AP''s own candidate list for the race; the loss is not inferred from not being the winner. UNOFFICIAL - this is a race call, not the state canvass.'),

  ('VA-11', '5111', 'bb9b6411-ef5f-4c1a-bab0-046adf472d4e',
   'Arthur Purves', 'Arthur', 'Purves', 'lost',
   'AP candidate list for the 2026-11-03 US House general election, VA-11 (AP candidateID 178105), https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). Republican nominee, advanced unopposed after the party primary was cancelled on 2026-08-04; president of the Fairfax County Taxpayers Alliance. Seeded by CC_0352.',
   'AP race call for the 2026-11-03 general election: Arthur Purves (GOP) 24.38%, 81,357 votes - DID NOT WIN. AP race 20261103VA47021, called 2026-11-04T02:10:56.310Z, https://interactives.apelections.org/election-results/data-live/2026-11-03/ (read 2026-11-04). This person appears on AP''s own candidate list for the race; the loss is not inferred from not being the winner. UNOFFICIAL - this is a race call, not the state canvass.');

-- ─── 1. The people we do not hold ────────────────────────────────────────────────────────────
-- 🔴 Keyed on (first_name, last_name), which is the predicate the repo's duplicate-name guard
-- uses. Jennifer Balkcom matches an existing row and is therefore NOT inserted.
-- 🔴 `is_incumbent` is set EXPLICITLY and is FALSE for all three: a winner who has not taken
-- office is not an incumbent, and the column defaults in a direction that hides people.
INSERT INTO essentials.politicians (full_name, first_name, last_name, source, is_active, is_incumbent)
SELECT n.full_name, n.first_name, n.last_name, n.person_src, true, false
  FROM seed_people n
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.politicians p
    WHERE p.first_name = n.first_name AND p.last_name = n.last_name);

-- ─── 2. The four candidacies ─────────────────────────────────────────────────────────────────
-- `race_candidates.is_incumbent` is FALSE for all four: none of them held the seat they ran for.
INSERT INTO essentials.race_candidates
  (race_id, politician_id, full_name, first_name, last_name, is_incumbent, is_write_in,
   candidate_status, source, result, result_certainty, result_source, result_recorded_at)
SELECT n.race_id, p.id, n.full_name, n.first_name, n.last_name, false, false,
       'active', n.person_src, n.result, 'called', n.result_src, now()
  FROM seed_people n
  JOIN essentials.politicians p
    ON p.first_name = n.first_name AND p.last_name = n.last_name
 WHERE NOT EXISTS (
   SELECT 1 FROM essentials.race_candidates rc
    WHERE rc.race_id = n.race_id AND rc.politician_id = p.id);

-- ─── 3. Chuck Edwards withdrew from NC-11 ────────────────────────────────────────────────────
UPDATE essentials.race_candidates
   SET candidate_status   = 'withdrawn',
       result             = 'withdrew',
       result_source      = 'Withdrew from the 2026-11-03 NC-11 general election before the ballot was set. The NCGOP 11th Congressional District Executive Committee met on 2026-08-10 and selected state Rep. Jennifer Balkcom to replace him; WHQR, 2026-08-12, "State Rep. Jennifer Balkcom is taking U.S. Rep. Chuck Edwards'' place on the NC-11 ticket" (read 2026-11-04). AP''s own NC-11 candidate list for the general does not include him. He continues to hold the seat until 2027-01-03. Recorded by CC_0352.',
       result_recorded_at = now()
 WHERE id = '60e3e4d9-d492-4da2-b2c8-86600453d249'
   AND candidate_status IS DISTINCT FROM 'withdrawn';

-- ─── 4. The Troy Nehls phantom candidacy ─────────────────────────────────────────────────────
-- 🔴 Nothing may reference it. Asserted here, inside the same transaction as the delete.
DO $$
DECLARE v_refs bigint;
BEGIN
  SELECT count(*) INTO v_refs FROM essentials.candidate_staging
   WHERE matched_candidate_id = '686d5b3a-a7df-4a67-bdba-d6b784181889'::uuid;
  IF v_refs <> 0 THEN
    RAISE EXCEPTION 'CC_0352: % candidate_staging row(s) reference the Troy Nehls candidacy; do not delete it', v_refs;
  END IF;
END $$;

DELETE FROM essentials.race_candidates WHERE id = '686d5b3a-a7df-4a67-bdba-d6b784181889';

-- ─── Post-verify ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE
  v_people bigint; v_dupes bigint; v_cands bigint; v_won bigint; v_lost bigint;
  v_troy_row bigint; v_troy_person bigint; v_troy_term bigint; v_edwards text;
  v_tx22 bigint; v_tx22_won text; v_orphans bigint; v_balkcom_terms bigint; v_balkcom_inc boolean;
  v_fed_won bigint; v_fed_lost bigint; v_cert bigint; v_created bigint; v_nc11_pol uuid;
BEGIN
  -- 🔴 THIS FILE MAY CREATE EXACTLY THREE PEOPLE. A typo in a name would quietly create a
  -- fourth instead of reusing somebody, and every other count here would still add up.
  SELECT count(*) INTO v_created FROM essentials.politicians WHERE source LIKE '%CC_0352%';
  IF v_created <> 3 THEN
    RAISE EXCEPTION 'CC_0352: % politician row(s) created by this file, expected exactly 3 (Balkcom must be REUSED)', v_created;
  END IF;

  -- 🔴 AND THE NC-11 CANDIDACY MUST HANG OFF THE ROW WE ALREADY HELD, BY ID.
  SELECT politician_id INTO v_nc11_pol
    FROM essentials.race_candidates
   WHERE race_id = '74af01ff-3f67-4a7c-915c-3a8e85830c0e'::uuid
     AND full_name = 'Jennifer Balkcom';
  IF v_nc11_pol IS DISTINCT FROM '724dbd0e-5834-4622-8302-bf76c3762d9c'::uuid THEN
    RAISE EXCEPTION 'CC_0352: the NC-11 Balkcom candidacy points at %, not the state representative we already hold', coalesce(v_nc11_pol::text, '(none)');
  END IF;

  -- 🔴 EXACTLY ONE PERSON PER NAME. Two would mean this file created a duplicate of somebody.
  SELECT count(*) INTO v_people
    FROM seed_people n JOIN essentials.politicians p
      ON p.first_name = n.first_name AND p.last_name = n.last_name;
  IF v_people <> 4 THEN
    RAISE EXCEPTION 'CC_0352: the four names resolve to % politician row(s), expected 4', v_people;
  END IF;

  -- ⚠ DEFENCE IN DEPTH, AND THE CONTROLS COULD NOT REACH IT. Two tampers tried to create a
  -- second Jennifer Balkcom and both were stopped before this gate ran: first by the
  -- `DUPLICATE_POLITICIAN_NAME` trigger ("a sitting officeholder running for a different seat
  -- is the normal case, not a different person"), and then, with that trigger bypassed, by the
  -- unique constraint `race_candidates_race_name_key_uniq`. So this check is UNTESTED - it sits
  -- behind two stronger guards, which is the right place for it, but do not read it as proven.
  SELECT count(*) INTO v_dupes FROM (
    SELECT n.first_name, n.last_name
      FROM seed_people n JOIN essentials.politicians p
        ON p.first_name = n.first_name AND p.last_name = n.last_name
     GROUP BY 1,2 HAVING count(*) > 1) x;
  IF v_dupes <> 0 THEN
    RAISE EXCEPTION 'CC_0352: % of the four names now has more than one politician row', v_dupes;
  END IF;

  -- 🔴 JENNIFER BALKCOM MUST BE THE ROW WE ALREADY HELD, UNCHANGED.
  SELECT count(*) INTO v_balkcom_terms
    FROM essentials.office_terms ot
    JOIN essentials.offices o ON o.id = ot.office_id
    JOIN essentials.districts d ON d.id = o.district_id
   WHERE ot.politician_id = '724dbd0e-5834-4622-8302-bf76c3762d9c'::uuid
     AND d.geo_id = '37117' AND ot.term_end IS NULL;
  IF v_balkcom_terms <> 1 THEN
    RAISE EXCEPTION 'CC_0352: Jennifer Balkcom holds % open NC House 117 term(s), expected 1 -- wrong person linked', v_balkcom_terms;
  END IF;

  SELECT is_incumbent INTO v_balkcom_inc FROM essentials.politicians
   WHERE id = '724dbd0e-5834-4622-8302-bf76c3762d9c'::uuid;
  IF v_balkcom_inc IS NOT TRUE THEN
    RAISE EXCEPTION 'CC_0352: Jennifer Balkcom is no longer flagged incumbent; her state-house row must not be edited';
  END IF;

  -- The four candidacies, with the results this file claims.
  SELECT count(*) INTO v_cands
    FROM seed_people n
    JOIN essentials.politicians p ON p.first_name = n.first_name AND p.last_name = n.last_name
    JOIN essentials.race_candidates rc ON rc.race_id = n.race_id AND rc.politician_id = p.id
   WHERE rc.result = n.result AND rc.result_certainty = 'called'
     AND rc.result_source IS NOT NULL AND btrim(rc.result_source) <> '';
  IF v_cands <> 4 THEN
    RAISE EXCEPTION 'CC_0352: % of the 4 candidacies carry the expected result, expected 4', v_cands;
  END IF;

  -- 🔴 THE PHANTOM IS GONE AND THE PERSON IS NOT.
  SELECT count(*) INTO v_troy_row FROM essentials.race_candidates
   WHERE id = '686d5b3a-a7df-4a67-bdba-d6b784181889'::uuid;
  IF v_troy_row <> 0 THEN RAISE EXCEPTION 'CC_0352: the Troy Nehls candidacy row still exists'; END IF;

  SELECT count(*) INTO v_troy_person FROM essentials.politicians
   WHERE id = 'a0bc977b-71c6-4973-9082-3cc009445a02'::uuid
     AND is_active = true AND is_incumbent = true;
  IF v_troy_person <> 1 THEN
    RAISE EXCEPTION 'CC_0352: Troy Nehls the person is gone or no longer an active incumbent -- only his candidacy was to be removed';
  END IF;

  SELECT count(*) INTO v_troy_term
    FROM essentials.office_terms ot
   WHERE ot.politician_id = 'a0bc977b-71c6-4973-9082-3cc009445a02'::uuid
     AND ot.office_id = '04cd9897-fb5d-445e-8986-7e5ab448594f'::uuid
     AND ot.term_end IS NULL;
  IF v_troy_term <> 1 THEN
    RAISE EXCEPTION 'CC_0352: Troy Nehls holds % open TX-22 term(s), expected 1 -- he keeps the seat until 2027-01-03', v_troy_term;
  END IF;

  -- 🔴 TX-22 NOW MATCHES AP'S BALLOT: two candidates, Trever won, Greene-Scott lost.
  SELECT count(*) INTO v_tx22 FROM essentials.race_candidates
   WHERE race_id = 'ef2f9063-233b-4a2a-8ded-fea5094cdc98'::uuid;
  IF v_tx22 <> 2 THEN RAISE EXCEPTION 'CC_0352: TX-22 holds % candidate rows, expected 2', v_tx22; END IF;

  SELECT p.full_name INTO v_tx22_won
    FROM essentials.race_candidates rc JOIN essentials.politicians p ON p.id = rc.politician_id
   WHERE rc.race_id = 'ef2f9063-233b-4a2a-8ded-fea5094cdc98'::uuid AND rc.result = 'won';
  IF v_tx22_won IS DISTINCT FROM 'Trever Nehls' THEN
    RAISE EXCEPTION 'CC_0352: TX-22 winner reads %, expected Trever Nehls', coalesce(v_tx22_won, '(none)');
  END IF;

  -- Chuck Edwards.
  SELECT candidate_status || '/' || coalesce(result, '(null)') INTO v_edwards
    FROM essentials.race_candidates WHERE id = '60e3e4d9-d492-4da2-b2c8-86600453d249'::uuid;
  IF v_edwards IS DISTINCT FROM 'withdrawn/withdrew' THEN
    RAISE EXCEPTION 'CC_0352: Chuck Edwards reads %, expected withdrawn/withdrew', coalesce(v_edwards, '(missing)');
  END IF;

  -- 🔴 THE PROGRAMME TOTALS. 410 + Trever = 411 won; 599 + three = 602 lost.
  SELECT count(*) FILTER (WHERE rc.result = 'won'),
         count(*) FILTER (WHERE rc.result = 'lost'),
         count(*) FILTER (WHERE rc.result_certainty = 'certified')
    INTO v_fed_won, v_fed_lost, v_cert
    FROM essentials.races r
    JOIN essentials.elections e ON e.id = r.election_id
    JOIN essentials.offices   o ON o.id = r.office_id
    JOIN essentials.districts d ON d.id = o.district_id
    JOIN essentials.race_candidates rc ON rc.race_id = r.id
   WHERE e.election_date = DATE '2026-11-03'
     AND d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER');
  IF v_fed_won <> 411 THEN RAISE EXCEPTION 'CC_0352: % federal winners, expected 411', v_fed_won; END IF;
  IF v_fed_lost <> 602 THEN RAISE EXCEPTION 'CC_0352: % federal losers, expected 602', v_fed_lost; END IF;
  IF v_cert <> 0 THEN RAISE EXCEPTION 'CC_0352: % federal row(s) claim certification', v_cert; END IF;

  -- 🟢 AND THE ANOMALY CC_0351 PINNED IS NOW CLOSED: no federal race has a loser and no winner.
  SELECT count(*) INTO v_orphans FROM (
    SELECT r.id
      FROM essentials.races r
      JOIN essentials.elections e ON e.id = r.election_id
      JOIN essentials.offices   o ON o.id = r.office_id
      JOIN essentials.districts d ON d.id = o.district_id
      JOIN essentials.race_candidates rc ON rc.race_id = r.id
     WHERE e.election_date = DATE '2026-11-03'
       AND d.district_type IN ('NATIONAL_UPPER','NATIONAL_LOWER')
     GROUP BY r.id
    HAVING count(*) FILTER (WHERE rc.result = 'lost') > 0
       AND count(*) FILTER (WHERE rc.result = 'won')  = 0) x;
  IF v_orphans <> 0 THEN
    RAISE EXCEPTION 'CC_0352: % federal race(s) still carry a loser with no winner, expected 0', v_orphans;
  END IF;

  RAISE NOTICE 'CC_0352 OK: 3 people created, 4 candidacies linked, TX-22 seated with Trever Nehls, Troy Nehls phantom removed, Chuck Edwards withdrawn';
END $$;
