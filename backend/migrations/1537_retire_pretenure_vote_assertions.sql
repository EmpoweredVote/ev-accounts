-- 1537_retire_pretenure_vote_assertions.sql
--
-- Retire 36 stance rows that credit a member of Congress with a vote cast before they held the
-- office, and correct 3 more. A citation change cannot fix a vote that did not happen.
--   Rollback record: data/stance-retirement/2026-08-02-pretenure-rollback.json
--   Reviews:         data/stance-retirement/2026-08-02-landmark-act-tenure.md
--                    data/stance-retirement/2026-08-02-rollcall-audit.md
--                    data/stance-retirement/2026-08-02-term-start-detector.md
--
-- The queue is the UNION of three independent passes keyed on (politician_id, topic_id):
--   roll-call (member absent from the cited record) 20 rows · term-start (year precedes service)
--   12 · landmark-act (18 acts, real floor-vote dates) 32+1. Union = 39 distinct rows.
-- Six rows were found by all three, by three different routes, which is what makes the class
-- trustworthy rather than a single detector's artefact.
--
-- 🔴 PROOF IS INTERNAL, NOT INFERRED. Each cited House roll call lists the WHOLE chamber, so a
-- record naming the 2021-22 Oregon delegation as Bentz/Blumenauer/Bonamici/DeFazio/Schrader is
-- itself the evidence that Hoyle and Salinas were not there. Two rows cite
-- clerk.house.gov/evs/2017/roll699.xml -- the genuine TCJA roll call -- so the refuting evidence
-- was inside the source the row already cited. Service dates: unitedstates/congress-legislators.
--
-- ⚠ ONE ROW SAYS IT OUTRIGHT: "Hoyle voted YES on Inflation Reduction Act (2022) ... as Labor
-- Commissioner advocated for green jobs transition." She was Oregon Labor Commissioner in 2022
-- BECAUSE she was not yet in Congress.
--
-- ⚠ HIGHEST-HARM ROW RETIRED HERE: Mike Collins x2. It credits a conservative Republican with a
-- vote FOR the Respect for Marriage Act -- seated 2023-01-03, final House vote 2022-12-08 -- and
-- editorialises that he "broke with most conservative Republicans" for it. Chair 3.0 rests on it.
--
-- ⚠ ROBERT MENENDEZ IS THE SON, NOT THE FATHER. Ours is NJ-8, seated 2023-01-03 (bioguide
-- M001226); the IRA passed Aug 2022. His father was Senator 1993-2024 (M000639). This is a plain
-- pre-tenure claim that an ambiguous surname concealed -- the row's sources are the son's own
-- Wikipedia page, so it is NOT an identity swap.
--
-- NO TIMESTAMP IS CLEARED. Unlike 1525, nobody here is emptied: every politician keeps other
-- stances (heaviest losses Hoyle 20->8, Salinas 13->7, Van Epps 8->3), so no
-- last_stances_researched_at is asserting "we looked and found nothing" on a corrected pass.
-- ⚠ ALL 39 TOPICS ARE OWED RE-RESEARCH: the chairs may well be right, but the evidence cited for
-- them was not.

BEGIN;

CREATE TEMP TABLE _retire_1537 (politician_id uuid, topic_id uuid) ON COMMIT DROP;
INSERT INTO _retire_1537 (politician_id, topic_id) VALUES
  ('5f6c498b-87dd-48fe-b744-62c8dced2ac3', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),  -- Andrea Salinas: Climate Change and Environmental Protection (chair 1.0) [rollcall+term-start+landmark-act]
  ('f6202cef-4e46-4db5-a9c0-c69ac9a8eccd', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),  -- Val Hoyle: Climate Change and Environmental Protection (chair 1.0) [rollcall+term-start+landmark-act]
  ('5f6c498b-87dd-48fe-b744-62c8dced2ac3', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- Andrea Salinas: Taxation and Public Spending (chair 1.0) [rollcall]
  ('f6202cef-4e46-4db5-a9c0-c69ac9a8eccd', 'a22215c3-6693-4bc2-b248-01aebba14570'),  -- Val Hoyle: Fossil Fuel Policy (chair 1.0) [rollcall+landmark-act]
  ('5f6c498b-87dd-48fe-b744-62c8dced2ac3', 'a22215c3-6693-4bc2-b248-01aebba14570'),  -- Andrea Salinas: Fossil Fuel Policy (chair 1.0) [rollcall+landmark-act]
  ('f6202cef-4e46-4db5-a9c0-c69ac9a8eccd', '48cc9585-ec22-4f53-8d42-6839828dd36f'),  -- Val Hoyle: State Redistricting and Gerrymandering (chair 1.0) [rollcall+landmark-act]
  ('f6202cef-4e46-4db5-a9c0-c69ac9a8eccd', '92730f69-ae57-401c-8ad1-2d07834a895d'),  -- Val Hoyle: Campaign Finance Reform (chair 1.0) [rollcall+landmark-act]
  ('f6202cef-4e46-4db5-a9c0-c69ac9a8eccd', '0bc588c6-39e1-4084-b5de-cac909b8b762'),  -- Val Hoyle: Civil Rights and Social Justice (chair 1.0) [rollcall]
  ('fb00c887-11f5-46f2-b822-f9848368bbd2', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- Cliff Bentz: Taxation and Public Spending (chair 5.0) [rollcall+term-start+landmark-act]
  ('f6202cef-4e46-4db5-a9c0-c69ac9a8eccd', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- Val Hoyle: Taxation and Public Spending (chair 1.0) [rollcall+term-start+landmark-act]
  ('5f6c498b-87dd-48fe-b744-62c8dced2ac3', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'),  -- Andrea Salinas: Voting Rights and Electoral Integrity (chair 1.0) [rollcall+landmark-act]
  ('f6202cef-4e46-4db5-a9c0-c69ac9a8eccd', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2'),  -- Val Hoyle: Voting Rights and Electoral Integrity (chair 1.0) [rollcall+landmark-act]
  ('5f6c498b-87dd-48fe-b744-62c8dced2ac3', 'ba59337e-30e2-4aba-a39a-426b3366eb27'),  -- Andrea Salinas: Transportation Priorities (chair 1.0) [rollcall+term-start+landmark-act]
  ('f6202cef-4e46-4db5-a9c0-c69ac9a8eccd', 'ba59337e-30e2-4aba-a39a-426b3366eb27'),  -- Val Hoyle: Transportation Priorities (chair 1.0) [rollcall+term-start+landmark-act]
  ('f6202cef-4e46-4db5-a9c0-c69ac9a8eccd', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'),  -- Val Hoyle: Same-Sex Marriage (chair 1.0) [rollcall+landmark-act]
  ('5f6c498b-87dd-48fe-b744-62c8dced2ac3', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'),  -- Andrea Salinas: Same-Sex Marriage (chair 1.0) [rollcall+landmark-act]
  ('f6202cef-4e46-4db5-a9c0-c69ac9a8eccd', '4e2c69ce-591e-4197-9cd5-7aceff79d390'),  -- Val Hoyle: Immigration and Treatment of Immigrants (chair 1.0) [rollcall]
  ('f6202cef-4e46-4db5-a9c0-c69ac9a8eccd', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'),  -- Val Hoyle: Reproductive Rights and Abortion Access (chair 1.0) [rollcall]
  ('fb00c887-11f5-46f2-b822-f9848368bbd2', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),  -- Cliff Bentz: Healthcare Access (chair 4.0) [rollcall]
  ('f6202cef-4e46-4db5-a9c0-c69ac9a8eccd', '669cac97-66a6-4087-b036-936fbe62efb3'),  -- Val Hoyle: Affordable Housing (chair 1.0) [rollcall]
  ('a2c6adc7-7689-49b9-964f-8f2aeb243a83', 'c1ac1330-47f7-44ec-baf3-c913d926b97c'),  -- Sydney Kamlager-Dove: Childcare Affordability & Access (chair 2.0) [term-start+landmark-act]
  ('a2c6adc7-7689-49b9-964f-8f2aeb243a83', 'eb3d1247-0de1-4b7f-baec-7259861efd53'),  -- Sydney Kamlager-Dove: Economic Development Incentives (chair 1.0) [term-start+landmark-act]
  ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- Ayanna Pressley: Taxation and Public Spending (chair 1.0) [term-start+landmark-act]
  ('4d83f985-9248-4905-a9b6-5742e2df77a8', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- Cindy Hyde-Smith: Taxation and Public Spending (chair 4.0) [term-start+landmark-act]
  ('6840c7e6-2169-43a4-8490-1e73c8704cbd', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- Guy Reschenthaler: Taxation and Public Spending (chair 4.0) [term-start+landmark-act]
  ('2c71d91b-7ad8-4984-b9a6-81587c41ea0d', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- Joe Neguse: Taxation and Public Spending (chair 1.0) [term-start+landmark-act]
  ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464', '9db07b16-1076-4b7d-ad89-ebe7b51f4336'),  -- Ayanna Pressley: Criminal Justice Approach (chair 1.0) [landmark-act]
  ('6cad043f-a4c0-48d5-af76-fdf70d319920', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'),  -- Greg Landsman: Same-Sex Marriage (chair 1.0) [landmark-act]
  ('a8691db4-7277-40f4-b62f-fec5bb0a84d9', 'f7e5678d-dadd-4556-a2fc-446e24642ceb'),  -- Matt Van Epps: Taxation and Public Spending (chair 4.0) [landmark-act]
  ('a8691db4-7277-40f4-b62f-fec5bb0a84d9', '4e2c69ce-591e-4197-9cd5-7aceff79d390'),  -- Matt Van Epps: Immigration and Treatment of Immigrants (chair 4.0) [landmark-act]
  ('a8691db4-7277-40f4-b62f-fec5bb0a84d9', '44905f3b-e105-4f6c-afc7-5d223813dbac'),  -- Matt Van Epps: Deportation Priorities (chair 4.0) [landmark-act]
  ('a8691db4-7277-40f4-b62f-fec5bb0a84d9', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'),  -- Matt Van Epps: Healthcare Access (chair 4.0) [landmark-act]
  ('a8691db4-7277-40f4-b62f-fec5bb0a84d9', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'),  -- Matt Van Epps: Medicare / Medicaid (chair 4.0) [landmark-act]
  ('b6542655-fc71-4b18-a022-6528522cdcae', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'),  -- Mike Collins: Same-Sex Marriage (chair 3.0) [landmark-act]
  ('b6542655-fc71-4b18-a022-6528522cdcae', '0bc588c6-39e1-4084-b5de-cac909b8b762'),  -- Mike Collins: Civil Rights and Social Justice (chair 3.0) [landmark-act]
  ('fc7a00d6-c552-4627-87f7-b0fc5cfe486c', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c')  -- Robert Menendez: Climate Change and Environmental Protection (chair 2.0) [landmark-act(hand)]
;

DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM inform.politician_answers a
    JOIN _retire_1537 r ON r.politician_id = a.politician_id AND r.topic_id = a.topic_id;
  IF v_n <> 36 THEN RAISE EXCEPTION 'expected 36 targeted answers, found % — target set has moved', v_n; END IF;
END $$;

DELETE FROM inform.politician_context c USING _retire_1537 r
 WHERE c.politician_id = r.politician_id AND c.topic_id = r.topic_id;

DELETE FROM inform.politician_answers a USING _retire_1537 r
 WHERE a.politician_id = r.politician_id AND a.topic_id = r.topic_id;

-- ---- the three corrections -------------------------------------------------------------------

-- Barry Moore / Taxation and Public Spending — MISLABELLED
--   The cited OnTheIssues page reads "One Big Beautiful Bill delivers largest tax cut in history.
--   (Jul 2025)" and contains ZERO occurrences of "TCJA" or "2017". He cast that 2025 vote; only the
--   act name was wrong, and it was supplied by the research pass rather than read from the source.
--   Seated 2021-01-03, so a Dec-2017 vote was impossible.
UPDATE inform.politician_context
   SET reasoning = 'Voted for the largest tax cut in history (One Big Beautiful Bill Act, July 2025); supports making tax cuts permanent; opposes tax increases on businesses and individuals.'
 WHERE politician_id = 'ea4cb6d8-76aa-47f4-a064-babaac0bc436' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'
   AND reasoning = 'Voted for the largest tax cut in history (TCJA); supports making tax cuts permanent; opposes tax increases on businesses and individuals.';

-- Anthony G. Brown / Healthcare Access — PARTLY_FABRICATED
--   Seated 2017-01-03; the ACA passed in 2010, so "voted for the Affordable Care Act ... as a
--   Congressman" cannot stand. The "and its expansions" half is defensible, so only the passage
--   claim is struck. Chair unchanged: the rest of the row (defending the ACA as AG, supporting
--   universal healthcare) carries it.
UPDATE inform.politician_context
   SET reasoning = 'AG Brown voted for expansions of the Affordable Care Act as a Congressman. He has defended the ACA as AG, joining coalitions opposing attempts to overturn it. He supports universal healthcare and has spoken about expanding coverage in Maryland.'
 WHERE politician_id = '60329719-1d5b-4bb4-8295-38ea18f6f378' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'
   AND reasoning = 'AG Brown voted for the Affordable Care Act and its expansions as a Congressman. He has defended the ACA as AG, joining coalitions opposing attempts to overturn it. He supports universal healthcare and has spoken about expanding coverage in Maryland.';

-- Suzanne Bonamici / Healthcare Access — IMPRECISE
--   Seated 2012-02-07, after the ACA's 2010 passage. Her ONLY source is
--   clerk.house.gov/evs/2017/roll256.xml -- the AHCA vote -- which supports "voted NO on AHCA" and
--   nothing about voting for the ACA or expanding Medicare. Reworded to what the cited roll call
--   actually shows. The trailing bare URL is dropped as it duplicates the sources array. ⚠ "Supports
--   Medicare for All concept" is left as-is but is NOT supported by this source; it belongs in the
--   reading queue.
UPDATE inform.politician_context
   SET reasoning = 'Bonamici voted NO on the AHCA (2017), the bill to repeal and replace the Affordable Care Act, and opposes repealing the ACA. Supports Medicare for All concept.'
 WHERE politician_id = '6ffb9093-7489-4197-aebc-67065c239fc3' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'
   AND reasoning = 'Bonamici voted YES on Affordable Care Act protections and Medicare expansion; opposes repealing ACA. Voted NO on AHCA (2017). Supports Medicare for All concept. https://clerk.house.gov/evs/2017/roll256.xml';

DO $$
DECLARE v_left int; v_ctx int; v_bad text;
BEGIN
  SELECT count(*) INTO v_left FROM inform.politician_answers a
    JOIN _retire_1537 r ON r.politician_id = a.politician_id AND r.topic_id = a.topic_id;
  IF v_left <> 0 THEN RAISE EXCEPTION 'expected 0 targeted answers to remain, found %', v_left; END IF;

  SELECT count(*) INTO v_ctx FROM inform.politician_context c
    JOIN _retire_1537 r ON r.politician_id = c.politician_id AND r.topic_id = c.topic_id;
  IF v_ctx <> 0 THEN RAISE EXCEPTION 'expected 0 orphaned context rows, found %', v_ctx; END IF;

  -- 🔴 NOBODY MAY BE EMPTIED BY THIS MIGRATION. Every one of these people keeps other stances;
  -- an empty compass here would mean the retirement went wider than the queue.
  SELECT string_agg(DISTINCT p.full_name, ', ') INTO v_bad
    FROM essentials.politicians p
   WHERE p.id IN ('5f6c498b-87dd-48fe-b744-62c8dced2ac3', 'f6202cef-4e46-4db5-a9c0-c69ac9a8eccd', 'fb00c887-11f5-46f2-b822-f9848368bbd2', 'a2c6adc7-7689-49b9-964f-8f2aeb243a83', 'c61baf45-dc2a-4d78-b4b7-21b1e9d79464', '4d83f985-9248-4905-a9b6-5742e2df77a8', '6840c7e6-2169-43a4-8490-1e73c8704cbd', '2c71d91b-7ad8-4984-b9a6-81587c41ea0d', '6cad043f-a4c0-48d5-af76-fdf70d319920', 'a8691db4-7277-40f4-b62f-fec5bb0a84d9', 'b6542655-fc71-4b18-a022-6528522cdcae', 'fc7a00d6-c552-4627-87f7-b0fc5cfe486c')
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers a WHERE a.politician_id = p.id);
  IF v_bad IS NOT NULL THEN RAISE EXCEPTION 'unexpectedly emptied: %', v_bad; END IF;

  -- All three corrections must have landed; a 0-row UPDATE means the text drifted.
  SELECT count(*) INTO v_left FROM inform.politician_context
   WHERE politician_id = 'ea4cb6d8-76aa-47f4-a064-babaac0bc436' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND reasoning = 'Voted for the largest tax cut in history (One Big Beautiful Bill Act, July 2025); supports making tax cuts permanent; opposes tax increases on businesses and individuals.';
  IF v_left <> 1 THEN RAISE EXCEPTION 'Barry Moore correction did not land (found %)', v_left; END IF;
  SELECT count(*) INTO v_left FROM inform.politician_context
   WHERE politician_id = '60329719-1d5b-4bb4-8295-38ea18f6f378' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'
     AND reasoning = 'AG Brown voted for expansions of the Affordable Care Act as a Congressman. He has defended the ACA as AG, joining coalitions opposing attempts to overturn it. He supports universal healthcare and has spoken about expanding coverage in Maryland.';
  IF v_left <> 1 THEN RAISE EXCEPTION 'Anthony G. Brown correction did not land (found %)', v_left; END IF;
  SELECT count(*) INTO v_left FROM inform.politician_context
   WHERE politician_id = '6ffb9093-7489-4197-aebc-67065c239fc3' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'
     AND reasoning = 'Bonamici voted NO on the AHCA (2017), the bill to repeal and replace the Affordable Care Act, and opposes repealing the ACA. Supports Medicare for All concept.';
  IF v_left <> 1 THEN RAISE EXCEPTION 'Suzanne Bonamici correction did not land (found %)', v_left; END IF;

  -- No corrected row may still assert the impossible vote.
  SELECT count(*) INTO v_left FROM inform.politician_context
   WHERE politician_id = 'ea4cb6d8-76aa-47f4-a064-babaac0bc436'
     AND reasoning ~* 'TCJA';
  IF v_left <> 0 THEN RAISE EXCEPTION 'Barry Moore still cites TCJA'; END IF;
END $$;

COMMIT;
