-- Migration 1944 — contradiction check, ROUND THREE: four groups read row by row, 144 rows.
--
-- The instrument/rung contradiction check (PR #1085) groups rows that cite ONE instrument, take the
-- SAME side of it, and sit on DIFFERENT rungs of ONE ladder revision. Migrations 1942 and 1943
-- worked its thirteen largest groups. This file works four more.
--
--   rows  instrument                      ladder             decision                    written
--   ----  ------------------------------  -----------------  --------------------------  -------
--     53  Inflation Reduction Act         climate-change     NOT A MAPPING; fix 4 rows         4
--      +  ... and a 5th the check never saw  climate-change   found by GUARD 6                  1
--     55  Texas HB 3 (89R)                school-vouchers    re-seat the lone dissenter        1
--      7  Texas HB 4 (89R)                school-vouchers    OFF-AXIS GROUPING; fix 2          2
--     29  Texas SB 10 / SB 11 (89R)       religious-freedom  withdraw 28, re-seat 1           29
--
-- 37 rows written: 8 seated, 29 withdrawn. 108 rows are deliberately left alone.
-- Full record: data/stance-research/2026-10-26-contradiction-check-round-three/LEDGER.md
--
-- EVERY TARGET SERVES FROM THE CLOSED SEASON 1, so every write here is an INSERT of a SEASON 2 row.
-- Season 1 is closed and immutable (ADR 0005 section 1.6) and is not touched: no Season 1 value,
-- reasoning or updated_at moves, and the post-flight block below proves it.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- A. WHAT THIS PASS LEARNED ABOUT THE CHECK ITSELF
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- Two of the four groups needed almost no write, for two DIFFERENT reasons, and both reasons are
-- properties of the check rather than of the corpus.
--
-- 🔴 A GROUP IS NOT A MAPPING JUST BECAUSE IT SHARES A CITATION. Measured over the whole queue by
-- the share of rows carrying a byte-identical source set, every mapping-shaped group is a STATE
-- legislature cohort voting on one bill; the large federal `ACT:` groups are rows researched one at
-- a time that happen to cite the same statute. The Inflation Reduction Act group is the latter: its
-- 53 rows carry their own LCV lifetime scores, caucus memberships, co-sponsorships and quotations,
-- and the chair 2 / chair 3 split tracks them faithfully — Dingell "cautious about full fossil fuel
-- phase-outs" for Dearborn and Brownley who "does NOT support the Green New Deal" at chair 3,
-- against Green New Deal co-sponsors citing "50% clean electricity by 2030" at chair 2. That is the
-- ladder working. The Tax Cuts and Jobs Act group in migration 1943 was the same shape.
--
-- 🔴 THE SHARED INSTRUMENT CAN BE OFF-AXIS FOR THE LADDER IT GROUPS. All seven rows of the Texas
-- HB 4 group cite HB 4 (89R), which is the public education ACCOUNTABILITY act and carries no
-- voucher content at all. Their voucher positions come from elsewhere — SB 2, HB 3, a campaign
-- site — so the 1-versus-5 spread the check reports is manufactured by a citation that says nothing
-- about the question. A group keyed on an off-axis instrument is not a contradiction.
--
-- 🔴🔴 AND THE THIRD BLIND SPOT IS THE WORST, BECAUSE IT IS SILENT. A row is only grouped if the
-- check can score which SIDE of the instrument it took; `directionFor` returning null drops the row
-- before any comparison, on the sound principle that an ambiguous side cannot create a
-- contradiction. GUARD 6 of this file asserts that EVERY Season 1 climate row naming the Inflation
-- Reduction Act and still sitting on chair 1 is a target — and the first run of that guard failed,
-- because there were FIVE such rows and the check had reported four. The fifth reads:
--     "His position aligns with stance 2 (rapid renewable transition, phase out fossil fuels by
--      2030) RATHER THAN stance 1 (declaring a climate emergency and banning all carbon-increasing
--      activities)."
-- and it was stored at value 1 — the one stance its own sentence rules out. `directionFor` scored
-- null on "voted for the Inflation Reduction Act" in that sentence, so the check never saw it. A
-- row whose value fights its own reasoning is exactly the kind that scores badly, which makes this
-- blind spot correlated with the defect rather than independent of it.
--
-- ⚖ Neither of the first two findings is a reason to distrust a flag. Both groups still had
-- defective rows inside them, and those rows were only ever going to be found by reading. The third
-- is a reason to distrust a CLEAN run, and it is the reason this file's guards count populations
-- rather than just verifying the targets it was handed.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- B. INFLATION REDUCTION ACT -> climate-change, FOR, 53 rows: 4 written
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- All 53 serve from Season 1, whose climate ladder ranks AMBITION:
--     c1 declare a climate emergency and ban all activities that increase carbon emissions
--     c2 rapidly transition to renewable energy and phase out fossil fuels by 2030
--     c3 invest in clean energy while gradually reducing reliance on fossil fuels
-- Five rows sit at c1 and NONE of them cites an emergency declaration or a ban on anything: a state
-- Attorney General who "supported the Inflation Reduction Act and other climate legislation" and
-- joined multi-state coalitions; two members whose rows rest on an IRA vote plus Green New Deal
-- sympathy; and a Senator whose strongest cited state record is "25% renewable by 2025". The c1
-- text is false of all four, and it is what voters see today.
--
-- The remedy lands on a DIFFERENT QUESTION. Season 1 is closed, so the lever is a Season 2 insert,
-- and by ADR 0006 that row is read against the SEASON 2 ladder, which ranks INSTRUMENTS:
--     c1 Require a shift to clean energy through mandates and firm deadlines.
--     c2 Fund clean energy with major subsidies, tax credits, and public investment.
--     c3 Speed up clean energy by cutting permitting red tape and upgrading the grid.
-- Every one of the four rows cites support for the Inflation Reduction Act, which funds clean
-- energy through tax credits, grants and loans and imposes no economy-wide mandate and no deadline
-- to shift — c2, named by the row's own evidence. No cited evidence in any of the four describes a
-- mandate or a firm deadline, so c1 on the new ladder is not available to them either.
--
-- The fifth row, the one the check never reported, is written for a different reason and carries
-- its own notice: its stored value contradicted its own concluding sentence. It lands on the same
-- chair, and the instrument argument above holds for it independently.
--
-- ⚖ WHY ONLY THESE FIVE AND NOT THE GROUP. The other 49 sit at Season 1 c2 and c3, which their own
-- records support; they are not one vote producing two answers, they are 49 different records. The
-- rule applied is narrower than migration 1943's: FIX THE ROWS WHOSE SERVING TEXT IS FALSE OF THE
-- MEMBER, leave the rows whose serving text is defensible.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- C. TEXAS HB 3 (89R) -> school-vouchers, SPONSOR, 55 rows: 1 written
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 54 co-authors at chair 5, one at chair 4. The bill was read, not the title —
-- capitol.texas.gov/tlodocs/89R/billtext/html/HB00003I.htm:
--   section 29.355(a) "A child is eligible to participate in the program" if the child may attend a
--     public school under section 25.001 or enroll in prekindergarten under section 29.153;
--   section 29.356(b) orders a LOTTERY by household income when applications exceed funding, the
--     lowest priority tier being households "at or above 500 percent of the federal poverty
--     guidelines" — so the income tiers gate nothing, every child is eligible;
--   section 29.361(b) pays up to "$30,000" a year for a child with a disability.
-- Universal eligibility with the money following the child to a private or religious school is
-- chair 5 verbatim. Chair 4 — "most families" — fails on the bill's own text, because nobody is
-- left out.
--
-- 🔑 AND THE REASON THE DISSENTING ROW LOOKED RIGHT HAS BEEN DELETED FROM THE LADDER. It rests on
-- co-authoring HB 2, the public school finance companion, and SEASON 1 chair 4 ended "...while
-- maintaining baseline public school funding". The SEASON 2 rewrite dropped that clause:
--     S1 c4 Expanding voucher eligibility to most families ... while maintaining baseline public
--           school funding
--     S2 c4 Expanding voucher eligibility to most families so parents can choose the school that
--           best fits their child
-- The limb this row satisfied no longer exists, and eight rows in the group cite both HB 3 and
-- HB 2 — the other seven sit at chair 5. The row's remaining distinguishing content is a remark
-- about the politics of the member's district, which is not a position.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- D. TEXAS HB 4 (89R) -> school-vouchers, SPONSOR, 7 rows: 2 written
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- The grouping is off-axis (section A), but two rows are wrong on their own terms.
--
-- WITHDRAWN. One row holds chair 1 — "Eliminating voucher programs that divert taxpayer money from
-- public schools to private institutions" — on three things: that the member did NOT co-author
-- HB 3, that he DID co-author HB 4, and that "as a Rio Grande Valley Democrat, opposition to public
-- school defunding via vouchers is consistent with his district's reliance on public schools". An
-- absence of sponsorship, an off-axis bill and an inference from district demographics are not a
-- position, and chair 1 is an affirmative claim. Blanked.
--
-- RE-SEATED. The other chair 1 row cites a campaign site, fetched 2026-10-26, whose entire voucher
-- commitment is "Opposing the use of public money for private school vouchers". That is opposition,
-- not elimination. Season 2 has a chair for exactly this and Season 1 did not:
--     S1 c2 Prioritizing public school funding while restricting vouchers to low-income families
--     S2 c2 Opposing voucher programs and blocking their expansion, without moving to eliminate
--           existing ones
-- On the Season 1 ladder c1 was the nearest available seat for her, because c2 meant means-tested
-- vouchers. The original answer was not careless; the rewritten ladder finally has her position.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- E. TEXAS SB 10 / SB 11 (89R) -> religious-freedom, SPONSOR, 29 people: 29 written
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- Two overlapping groups, 26 and 23 rows, 29 distinct people, split 4/5. The ladder's chairs 2-5
-- are IDENTICAL in both seasons, so this is the same question it always was:
--     c4 protect religious freedom and allow faith-based exemptions from laws that conflict with
--        sincere religious beliefs.
--     c5 strongly protect religious freedom and allow religious organizations complete autonomy in
--        their operations and hiring practices.
-- SB 10 requires the Ten Commandments displayed in every public school classroom; SB 11 requires a
-- period of prayer and Bible reading in public schools. Both put religious content INTO a public
-- institution. This ladder asks the opposite question — whether religious belief may be excused
-- FROM generally applicable law, and how far a religious organization's internal autonomy runs.
-- A classroom-display mandate evidences neither. By the standing rule, the sponsorship proves the
-- SIDE and not the RUNG, and an off-axis instrument is wrong at EVERY rung.
--
-- The rows say it themselves. One reads "...This pattern strongly supports protecting religious
-- freedom including complete autonomy for religious organizations"; another "mandatory Bible /
-- religious text displays in public schools indicates strong support for religious expression in
-- public institutions and faith-based exemptions". The second clause of each is a leap, and it is
-- the clause that picked the chair. 28 rows are withdrawn.
--
-- ⚖ ONE ROW IS KEPT AND MOVED, NOT BLANKED. A Senator's own Senate biography — a source this row
-- already cites, fetched 2026-10-26 — says he was "instrumental in ... protecting religious
-- organizations and churches from Government shutdown". Excusing churches from a generally
-- applicable closure order IS a faith-based exemption from a law: chair 4, on the record, in his
-- own words. The same page says nothing about operations or hiring, which is what chair 5 claims,
-- so chair 5 is withdrawn from him and chair 4 written in its place.
--
-- ⚠ TWO NEAR MISSES, RECORDED BECAUSE THEY ARE THE SAME TRAP. One row claims its member is "Author
-- of legislation preventing government oversight of religious organizations", which would be chair
-- 5 squarely — but that clause is UNSOURCED, the row's only citations being the SB 10 and SB 11
-- bill pages. It is blanked with the rest. Another member CHAIRS, and a third VICE-CHAIRS, the
-- Senate Religious Liberty Select Committee; a committee assignment is not a position, and it does
-- not say where on this axis they sit.
--
-- ▶ OWED, AND NOT FIXED HERE. 28 Texas legislators are left with no religious-freedom row. That is
-- a coverage debt, not an integrity one, and it is the same debt migration 1943 left behind on
-- school-vouchers for 20 Maryland legislators.

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE TARGETS, FROZEN. Every one of them serves from the CLOSED Season 1 with nothing shadowing
-- it, so every write is an INSERT of a Season 2 row (ADR 0005 section 1.6). By ADR 0006 that row
-- is read against the SEASON 2 ladder, which is resolved from inform.season_questions and never
-- hard-coded. The Season 1 value, reasoning, sources and updated_at are carried along so the
-- guards and the post-flight block can prove nothing in the closed season moved.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
CREATE TEMP TABLE mig1944_ins ON COMMIT DROP AS
SELECT x.politician_id, x.topic_id, x.op, x.value_after,
       sq.topic_revision_id  AS s2_revision,
       pa1.value             AS value_before,
       pa1.topic_revision_id AS s1_revision,
       pa1.updated_at        AS s1_updated_at,
       pc1.reasoning         AS reasoning_before,
       pc1.sources           AS sources_before
  FROM (VALUES
  ('60329719-1d5b-4bb4-8295-38ea18f6f378'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'ira-chair2',2),  -- Anthony G. Brown: was chair 1
  ('c61baf45-dc2a-4d78-b4b7-21b1e9d79464'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'ira-chair2',2),  -- Ayanna Pressley: was chair 1
  ('6ffb9093-7489-4197-aebc-67065c239fc3'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'ira-chair2',2),  -- Suzanne Bonamici: was chair 1
  ('8cffe7a0-b56c-42fe-adbf-f57d63589973'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'ira-chair2',2),  -- Tim Kaine: was chair 1
  ('822966a7-5f09-4151-ba43-630afbd676c2'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'aguilar-chair2',2),  -- Pete Aguilar: was chair 1
  ('4001a833-a971-45ec-a625-cdb206d3c2ed'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'hb3-chair5',5),  -- John Lujan: was chair 4
  ('67a194b0-2584-48c6-a431-7abb70c96288'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'jones-chair2',2),  -- Jolanda Jones: was chair 1
  ('65bdba41-859d-41ba-bb25-65e8ba50f5ad'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'munoz-blank',0),  -- Sergio Munoz: was chair 1
  ('452cad0a-57e0-48fd-893a-4101fc41cd48'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'hall-chair4',4),  -- Bob Hall: was chair 5
  ('02e74087-5a81-474b-9771-62451239007a'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Donna Campbell: was chair 5
  ('183d6ca3-be06-4d4f-a727-103687f80e69'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Kevin Sparks: was chair 5
  ('1d0242ba-f594-4764-b071-22cc86a7cc30'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Denise Villalobos: was chair 5
  ('1ea8b603-7f4d-40e5-b8c7-0ba19af17717'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Robert Nichols: was chair 5
  ('29fcdf7e-e3e2-4463-b461-ffd7a34a8754'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Pete Flores: was chair 5
  ('2db78ab9-242e-46cd-ba95-5c504a2c8892'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Lois Kolkhorst: was chair 5
  ('2f3450e1-7b1c-4ca0-ae62-581bbc2cf606'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Cody Vasut: was chair 5
  ('3b3da471-8c67-4ea5-bb5f-fa1b2c0ce095'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- James Frank: was chair 5
  ('42370d1a-2ffd-480b-a24f-b2a39405c929'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Carrie Isaac: was chair 4
  ('457620ac-d32b-434f-ad00-d860a5615e6d'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Phil King: was chair 5
  ('46e0161a-6512-471a-8f75-945f78f721a0'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Angela Paxton: was chair 5
  ('4f6da77d-f516-4873-b705-3adeb23c1ffb'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Jared Patterson: was chair 5
  ('540628fb-afea-4803-ab8e-abea3d4e603c'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Tan Parker: was chair 4
  ('6c1e1764-f093-44e2-9ec0-90b61457fd45'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Mitch Little: was chair 5
  ('7de0d70b-81ba-484c-aa82-43dfb4dadd0a'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Brian Birdwell: was chair 5
  ('7e85ff40-5ad8-4374-81a9-c18e60fad8b0'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Bryan Hughes: was chair 5
  ('82968d14-f39b-401d-821c-89825a9811ac'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Hillary Hickland: was chair 5
  ('92169386-c7ca-4edb-8446-56b565ad8c02'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Mayes Middleton: was chair 5
  ('9c6b89e7-f71a-4bf7-9a32-d611afe28cb8'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Caroline Harris Davila: was chair 4
  ('ac161830-6b8a-479d-8ef4-c0eb3d93df83'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Shelby Slawson: was chair 5
  ('afdc1bdd-8975-4d9f-9071-ab5065450ea9'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Greg Bonnen: was chair 5
  ('b36348f0-135f-4ea4-983d-70775f71e03e'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Janis Holt: was chair 5
  ('b652c0bb-1dc5-4043-8a2e-9e12ea034dc8'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Giovanni Capriglione: was chair 5
  ('c6dcdb47-9bbd-4c9b-9169-77e6082f17b1'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Cody Harris: was chair 5
  ('cde048d1-a399-46b1-8ceb-2954f2b968c0'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Brent Hagenbuch: was chair 5
  ('df2b0dba-63d7-4f18-b713-7cc0594ec61d'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Janie Lopez: was chair 5
  ('eb7ef2a7-d0bb-475e-b2de-d96e6931932c'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0),  -- Charles Perry: was chair 5
  ('f7f56e38-194a-4cc5-8883-cba2a61a2a62'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid,'rf-blank',0)  -- Paul Bettencourt: was chair 5
  ) AS x(politician_id, topic_id, op, value_after)
  JOIN inform.politician_answers pa1
    ON pa1.politician_id = x.politician_id AND pa1.topic_id = x.topic_id
   AND pa1.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
  JOIN inform.politician_context pc1
    ON pc1.politician_id = x.politician_id AND pc1.topic_id = x.topic_id
   AND pc1.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
  JOIN inform.season_questions sq
    ON sq.topic_id = x.topic_id AND sq.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- GUARD 1 — the target set must be exactly what was read, and every row must have something to keep.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1944_ins;
  IF n <> 37 THEN RAISE EXCEPTION 'migration 1944: expected 37 targets, found % — a Season 1 answer or context row is missing', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins WHERE op = 'ira-chair2';
  IF n <> 4 THEN RAISE EXCEPTION 'migration 1944: ira-chair2 expected 4, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins WHERE op = 'aguilar-chair2';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1944: aguilar-chair2 expected 1, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins WHERE op = 'hb3-chair5';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1944: hb3-chair5 expected 1, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins WHERE op = 'jones-chair2';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1944: jones-chair2 expected 1, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins WHERE op = 'munoz-blank';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1944: munoz-blank expected 1, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins WHERE op = 'hall-chair4';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1944: hall-chair4 expected 1, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins WHERE op = 'rf-blank';
  IF n <> 28 THEN RAISE EXCEPTION 'migration 1944: rf-blank expected 28, found %', n; END IF;
  SELECT count(DISTINCT (politician_id, topic_id)) INTO n FROM mig1944_ins;
  IF n <> 37 THEN RAISE EXCEPTION 'migration 1944: duplicate (person, topic) pairs; % distinct of 37', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins
   WHERE reasoning_before IS NULL OR btrim(reasoning_before) = ''
      OR sources_before IS NULL OR cardinality(sources_before) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % target(s) have no reasoning or no citation to keep', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins WHERE reasoning_before LIKE '%migration 1944%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % target(s) already carry a 1944 notice — this file has run', n; END IF;
END $$;

-- GUARD 2 — every target must TODAY still sit on the chair the queue measured it at. If anything
-- re-researched these rows since 2026-10-26 the adjudication is stale and must not be applied.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1944_ins WHERE op = 'ira-chair2' AND value_before NOT IN (1);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % ira-chair2 row(s) do not sit on the chairs they were read at', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins WHERE op = 'aguilar-chair2' AND value_before NOT IN (1);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % aguilar-chair2 row(s) do not sit on the chairs they were read at', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins WHERE op = 'hb3-chair5' AND value_before NOT IN (4);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % hb3-chair5 row(s) do not sit on the chairs they were read at', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins WHERE op = 'jones-chair2' AND value_before NOT IN (1);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % jones-chair2 row(s) do not sit on the chairs they were read at', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins WHERE op = 'munoz-blank' AND value_before NOT IN (1);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % munoz-blank row(s) do not sit on the chairs they were read at', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins WHERE op = 'hall-chair4' AND value_before NOT IN (5);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % hall-chair4 row(s) do not sit on the chairs they were read at', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins WHERE op = 'rf-blank' AND value_before NOT IN (4,5);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % rf-blank row(s) do not sit on the chairs they were read at', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins WHERE value_before = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % target(s) are already blank', n; END IF;
END $$;

-- GUARD 3 — the reasoning must really name the thing the adjudication turned on. Without this the
-- file is a list of uuids and a clerical slip is undetectable.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1944_ins WHERE op = 'ira-chair2' AND reasoning_before !~ 'Inflation Reduction Act';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % ira-chair2 row(s) do not name the Inflation Reduction Act', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins WHERE op = 'aguilar-chair2' AND reasoning_before !~ 'aligns with stance 2';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % aguilar-chair2 row(s) do not carry the conclusion the stored value contradicted', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins WHERE op = 'hb3-chair5' AND reasoning_before !~ 'HB ?3';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % hb3-chair5 row(s) do not name HB 3', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins WHERE op = 'jones-chair2' AND reasoning_before !~ 'voucher';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % jones-chair2 row(s) do not mention vouchers', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins WHERE op = 'munoz-blank' AND reasoning_before !~ 'HB ?4';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % munoz-blank row(s) do not name HB 4', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins WHERE op = 'hall-chair4' AND reasoning_before !~ '[Gg]overnment shutdown';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % hall-chair4 row(s) do not quote the Senate biography', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins WHERE op = 'rf-blank' AND reasoning_before !~ 'SB ?1[01]';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % rf-blank row(s) do not name SB 10 or SB 11', n; END IF;
END $$;

-- GUARD 4 — THE LADDERS. A rung NUMBER means nothing outside one revision, and a rung_map can lie
-- (climate-change v2r3 and school-vouchers v2r3 both claim IDENTITY over rewritten rungs), so the
-- rung TEXTS are asserted here — including, for school-vouchers chair 4, the clause the Season 2
-- rewrite DELETED, which is the whole reason the Texas HB 3 dissenter moves.
DO $$
DECLARE n int; t text;
BEGIN
  SELECT count(*) INTO n FROM inform.seasons WHERE id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND status = 'open';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1944: Season 2 is not the open season'; END IF;
  SELECT count(*) INTO n FROM inform.seasons WHERE id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid AND status <> 'open';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1944: Season 1 is not closed'; END IF;
  SELECT count(*) INTO n FROM mig1944_ins i WHERE i.topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
     AND (i.s1_revision <> 'da9cf777-0a95-41aa-8775-c5b29528825b'::uuid OR i.s2_revision <> '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % climate-change row(s) are not on the expected revisions', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins i WHERE i.topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
     AND (i.s1_revision <> '835bc8d1-b31b-4fef-9cca-31318cc0f1d6'::uuid OR i.s2_revision <> '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % school-vouchers row(s) are not on the expected revisions', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins i WHERE i.topic_id = '6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid
     AND (i.s1_revision <> '6c4b402f-4d41-42ce-a04c-be17b85f131d'::uuid OR i.s2_revision <> 'dfbd847a-294c-49d2-9ac3-69270ea03054'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % religious-freedom row(s) are not on the expected revisions', n; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = 'da9cf777-0a95-41aa-8775-c5b29528825b'::uuid AND value = 1;
  IF t IS NULL OR t !~* 'ban all activities that increase carbon emissions' THEN RAISE EXCEPTION 'migration 1944: Season 1 climate chair 1 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid AND value = 2;
  IF t IS NULL OR t !~* 'subsidies, tax credits, and public investment' THEN RAISE EXCEPTION 'migration 1944: Season 2 climate chair 2 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid AND value = 1;
  IF t IS NULL OR t !~* 'mandates and firm deadlines' THEN RAISE EXCEPTION 'migration 1944: Season 2 climate chair 1 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = '835bc8d1-b31b-4fef-9cca-31318cc0f1d6'::uuid AND value = 4;
  IF t IS NULL OR t !~* 'maintaining baseline public school funding' THEN RAISE EXCEPTION 'migration 1944: Season 1 voucher chair 4 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = '835bc8d1-b31b-4fef-9cca-31318cc0f1d6'::uuid AND value = 2;
  IF t IS NULL OR t !~* 'restricting vouchers to low-income families' THEN RAISE EXCEPTION 'migration 1944: Season 1 voucher chair 2 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid AND value = 2;
  IF t IS NULL OR t !~* 'without moving to eliminate existing ones' THEN RAISE EXCEPTION 'migration 1944: Season 2 voucher chair 2 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid AND value = 5;
  IF t IS NULL OR t !~* 'universal vouchers' THEN RAISE EXCEPTION 'migration 1944: Season 2 voucher chair 5 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = 'dfbd847a-294c-49d2-9ac3-69270ea03054'::uuid AND value = 4;
  IF t IS NULL OR t !~* 'faith-based exemptions from laws' THEN RAISE EXCEPTION 'migration 1944: Season 2 religious-freedom chair 4 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = 'dfbd847a-294c-49d2-9ac3-69270ea03054'::uuid AND value = 5;
  IF t IS NULL OR t !~* 'complete autonomy in their operations and hiring' THEN RAISE EXCEPTION 'migration 1944: Season 2 religious-freedom chair 5 does not read as recorded: %', t; END IF;

  -- 🔑 THE DELETED CLAUSE. Season 1 voucher chair 4 ended "...while maintaining baseline public
  -- school funding" and the Season 2 chair 4 does NOT. If that clause ever comes back, the reason
  -- the HB 3 dissenter moves to chair 5 evaporates and this file must be re-argued.
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid AND value = 4;
  IF t IS NULL OR t ~* 'baseline public school funding' THEN RAISE EXCEPTION 'migration 1944: Season 2 voucher chair 4 still carries the public-school-funding clause: %', t; END IF;

  -- every chair this file writes must EXIST on the revision it is written against
  SELECT count(*) INTO n FROM mig1944_ins i
   WHERE i.value_after <> 0
     AND NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions cs
                      WHERE cs.topic_revision_id = i.s2_revision AND cs.value = i.value_after);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % row(s) would be seated on a chair that does not exist', n; END IF;
END $$;

-- GUARD 5 — these are inserts, so no target may already hold a Season 2 row; and nobody here may
-- be inactive.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1944_ins i
   WHERE EXISTS (SELECT 1 FROM inform.politician_answers pa
                  WHERE pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id
                    AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % target(s) ALREADY have a Season 2 answer — somebody answered since the read', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins i
   WHERE EXISTS (SELECT 1 FROM inform.politician_context pc
                  WHERE pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id
                    AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % target(s) ALREADY have a Season 2 context row', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins i
    JOIN essentials.politicians p ON p.id = i.politician_id WHERE NOT p.is_active;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % target(s) are on inactive people', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins
   WHERE topic_id NOT IN ('f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'6b9ba6d9-1001-43f5-b073-4d37130696fd'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % target(s) are on an unexpected topic', n; END IF;
END $$;

-- GUARD 6 — THE ROWS THIS FILE DELIBERATELY DOES NOT TOUCH. Each is a decision, so each is pinned.
DO $$
DECLARE n int;
BEGIN
  -- 🔑 EVERY Season 1 climate row that names the Act and still makes the chair 1 claim must be a
  -- target. This guard is not decoration: the first run of it found a FIFTH row the contradiction
  -- check had never reported, because the check could not score a side for the Act in that row and
  -- silently drops what it cannot score. Five rows, five targets, no sixth.
  SELECT count(*) INTO n FROM inform.politician_answers pa
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
    JOIN essentials.politicians p ON p.id = pa.politician_id
   WHERE pa.topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
     AND pa.value = 1 AND p.is_active AND pc.reasoning ~ 'Inflation Reduction Act';
  IF n <> 5 THEN RAISE EXCEPTION 'migration 1944: expected 5 Inflation Reduction Act rows making the chair 1 claim, found % — re-read before writing', n; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers pa
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
    JOIN essentials.politicians p ON p.id = pa.politician_id
   WHERE pa.topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
     AND pa.value = 1 AND p.is_active AND pc.reasoning ~ 'Inflation Reduction Act'
     AND NOT EXISTS (SELECT 1 FROM mig1944_ins i WHERE i.politician_id = pa.politician_id AND i.topic_id = pa.topic_id);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % chair 1 row(s) naming the Act are not targets', n; END IF;

  -- The Inflation Reduction Act rows at chairs 2 and 3, which this file leaves entirely alone: they
  -- sit where their own records put them. If that population has moved, the "not a mapping" finding
  -- was measured against a corpus that no longer exists.
  SELECT count(*) INTO n FROM inform.politician_answers pa
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
    JOIN essentials.politicians p ON p.id = pa.politician_id
   WHERE pa.topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
     AND pa.value IN (2,3) AND p.is_active AND pc.reasoning ~ 'Inflation Reduction Act';
  IF n <> 81 THEN RAISE EXCEPTION 'migration 1944: expected 81 untouched Inflation Reduction Act rows at chairs 2-3, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins WHERE topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND value_before <> 1;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: a climate target is not one of the chair 1 rows'; END IF;

  -- The one religious-freedom row that is KEPT rather than blanked, because his own Senate
  -- biography carries a faith-based exemption. He must be re-seated at chair 4, never withdrawn.
  SELECT count(*) INTO n FROM mig1944_ins
   WHERE politician_id = '452cad0a-57e0-48fd-893a-4101fc41cd48'::uuid AND op = 'hall-chair4' AND value_after = 4;
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1944: the kept religious-freedom row is not being seated at chair 4'; END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE WRITE. Two inserts. The Season 2 reasoning is the migration's notice followed by the ORIGINAL
-- prose, kept verbatim — a reader must be able to see what the row used to claim and why it moved.
-- Sources are carried across byte for byte; this file re-reads evidence, it never re-cites it.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
INSERT INTO inform.politician_answers (politician_id, topic_id, season_id, topic_revision_id, value)
SELECT i.politician_id, i.topic_id, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, i.s2_revision, i.value_after
  FROM mig1944_ins i;

INSERT INTO inform.politician_context
  (politician_id, topic_id, season_id, topic_revision_id, reasoning, sources)
SELECT i.politician_id, i.topic_id, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, i.s2_revision,
       CASE i.op
         WHEN 'ira-chair2' THEN '[migration 1944, 2026-10-26] Re-seated from Season 1 chair 1 — "declare a climate emergency and ban all activities that increase carbon emissions" — which no cited evidence in this row supports. The row''s own instrument, the Inflation Reduction Act, funds clean energy through tax credits, grants and loans and imposes no economy-wide mandate or deadline, which is Season 2 chair 2. Original reasoning kept verbatim below; the Season 1 answer is untouched.

'
         WHEN 'aguilar-chair2' THEN '[migration 1944, 2026-10-26] Re-seated from Season 1 chair 1. The stored value contradicted this row''s own reasoning, which concludes "His position aligns with stance 2 ... rather than stance 1 (declaring a climate emergency and banning all carbon-increasing activities)" — and chair 1 is what voters were shown. On the Season 2 ladder the Act this row cites, the Inflation Reduction Act, funds clean energy through tax credits, grants and loans and imposes no mandate or deadline, which is chair 2 for the instrument reason as well. The contradiction check never flagged this row: it could not score a side for the Act and drops what it cannot score. Original reasoning kept verbatim below; the Season 1 answer is untouched.

'
         WHEN 'hb3-chair5' THEN '[migration 1944, 2026-10-26] Re-seated from Season 1 chair 4 to Season 2 chair 5. Texas HB 3 (89R) §29.355(a) makes every child who may attend a Texas public school eligible; the income tiers in §29.356(b) order a lottery and gate nothing, the lowest tier being households "at or above 500 percent of the federal poverty guidelines". That is universal eligibility, not "most families". Season 1 chair 4 also read "while maintaining baseline public school funding" — the clause this row relied on — and the Season 2 ladder no longer contains it. Seven other co-authors of both HB 3 and HB 2 sit at chair 5. Original reasoning kept below.

'
         WHEN 'jones-chair2' THEN '[migration 1944, 2026-10-26] Re-seated from Season 1 chair 1 to Season 2 chair 2. Her campaign site commits to "Opposing the use of public money for private school vouchers" and says nothing about eliminating an existing programme, which Season 2 chair 1 requires. Season 1 had no chair for opposition-without-elimination — its chair 2 was means-tested vouchers — so chair 1 was the nearest available seat. The Season 2 rewrite created the right one. Original reasoning kept verbatim below; the Season 1 answer is untouched.

'
         WHEN 'munoz-blank' THEN '[migration 1944, 2026-10-26] Withdrawn from Season 1 chair 1. The row rests on not having co-authored HB 3, on co-authoring HB 4 (public education accountability, which carries no voucher content), and on an inference from the district''s demographics. An absence of sponsorship, an off-axis bill and a district inference are not a position, and chair 1 — eliminating voucher programmes — is an affirmative claim. Original reasoning kept verbatim below; the Season 1 answer is untouched.

'
         WHEN 'hall-chair4' THEN '[migration 1944, 2026-10-26] Re-seated from Season 1 chair 5 to Season 2 chair 4. His Senate biography, cited by this row, says he was "instrumental in ... protecting religious organizations and churches from Government shutdown" — an exemption from a generally applicable order, which is chair 4. The page says nothing about religious organizations'' autonomy in operations or hiring, which is what chair 5 claims. Original reasoning kept verbatim below; the Season 1 answer is untouched.

'
         WHEN 'rf-blank' THEN '[migration 1944, 2026-10-26] Withdrawn. This row rests on sponsorship of Texas SB 10 (Ten Commandments displayed in every public school classroom) and/or SB 11 (a prayer and Bible reading period in public schools), 89R, 2025. Those bills put religious content into public institutions. This ladder asks something else: whether religious belief may override generally applicable law — chair 4 is "faith-based exemptions from laws", chair 5 is "religious organizations complete autonomy in their operations and hiring practices". Neither is evidenced by a classroom-display or school-prayer mandate, so the sponsorship proves the side and not the rung. Original reasoning kept verbatim below; the Season 1 answer is untouched.

'
       END || i.reasoning_before,
       i.sources_before
  FROM mig1944_ins i;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- POST-FLIGHT. Everything below runs inside the same transaction, so a failure here rolls the
-- whole file back.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1944_ins i
    JOIN inform.politician_answers pa
      ON pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value = i.value_after AND pa.topic_revision_id = i.s2_revision;
  IF n <> 37 THEN RAISE EXCEPTION 'migration 1944: % of 37 inserted answers are at their chair and revision', n; END IF;

  SELECT count(*) INTO n FROM mig1944_ins i
    JOIN inform.politician_answers pa
      ON pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value <> 0;
  IF n <> 8 THEN RAISE EXCEPTION 'migration 1944: expected 8 seated rows, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins i
    JOIN inform.politician_answers pa
      ON pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value = 0;
  IF n <> 29 THEN RAISE EXCEPTION 'migration 1944: expected 29 withdrawn rows, found %', n; END IF;

  -- the kept prose and the untouched citations
  SELECT count(*) INTO n FROM mig1944_ins i
    JOIN inform.politician_context pc
      ON pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.sources IS DISTINCT FROM i.sources_before;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % row(s) had their citations altered', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins i
    JOIN inform.politician_context pc
      ON pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE strpos(pc.reasoning, i.reasoning_before) = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % row(s) lost their original reasoning', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins i
    JOIN inform.politician_context pc
      ON pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.reasoning NOT LIKE '%migration 1944%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % row(s) carry no notice', n; END IF;

  -- 🔴 SEASON 1 IS CLOSED. Not one value, not one word of reasoning, not one updated_at may move.
  SELECT count(*) INTO n FROM mig1944_ins i
    JOIN inform.politician_answers pa
      ON pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
   WHERE pa.value <> i.value_before OR pa.updated_at IS DISTINCT FROM i.s1_updated_at
      OR pa.topic_revision_id <> i.s1_revision;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % Season 1 answer(s) MOVED — the closed season was written to', n; END IF;
  SELECT count(*) INTO n FROM mig1944_ins i
    JOIN inform.politician_context pc
      ON pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id AND pc.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
   WHERE pc.reasoning IS DISTINCT FROM i.reasoning_before OR pc.sources IS DISTINCT FROM i.sources_before;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1944: % Season 1 context row(s) were rewritten', n; END IF;

  -- and the rows this file promised not to touch are still where they were
  SELECT count(*) INTO n FROM inform.politician_answers pa
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id AND pc.season_id = pa.season_id
    JOIN essentials.politicians p ON p.id = pa.politician_id
   WHERE pa.topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
     AND pa.value IN (2,3) AND p.is_active AND pc.reasoning ~ 'Inflation Reduction Act';
  IF n <> 81 THEN RAISE EXCEPTION 'migration 1944: the 81 untouched Inflation Reduction Act rows moved; found %', n; END IF;
END $$;

COMMIT;
