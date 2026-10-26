-- Migration 1943 — contradiction check, ROUND TWO: the next five groups, read row by row.
--
-- The instrument/rung contradiction check (PR #1085) groups rows that cite ONE instrument, take the
-- SAME side of it, and sit on DIFFERENT rungs of ONE ladder revision. Migration 1942 worked its
-- eight largest groups. This file works the next five, 125 rows, every one of them read.
--
--   rows  instrument                      ladder             decision                    written
--   ----  ------------------------------  -----------------  --------------------------  -------
--     33  Climate Solutions Now Act       climate-change     re-seat all 33, Season 2 c1       33
--     33  Tax Cuts and Jobs Act           taxes              WITHDRAWN FROM THE PASS            0
--     20  Blueprint for Maryland's Future school-vouchers    withdraw all 20                   20
--     20  Respect for Marriage Act (AGST) same-sex-marriage  withdraw 11, keep 9               11
--     19  Opting in on Opportunity Act    school-vouchers    re-seat 18, leave 1               18
--
-- 82 rows written: 51 seated, 31 withdrawn. 43 rows are deliberately left alone.
-- Full record: data/stance-research/2026-10-25-contradiction-check-round-two/LEDGER.md
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- A. CLIMATE SOLUTIONS NOW ACT -> climate-change, FOR, 33 rows (22 at c1, 10 at c2, 1 at c3)
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- Thirty-three Maryland legislators, one vote, three chairs. All 33 serve from the CLOSED Season 1
-- with nothing shadowing them, and the Season 1 ladder ranks AMBITION:
--     c1 declare a climate emergency and ban all activities that increase carbon emissions
--     c2 rapidly transition to renewable energy and phase out fossil fuels by 2030
--     c3 invest in clean energy while gradually reducing reliance on fossil fuels
-- The enacted chapter was read, not the title or a news summary — Chapter 38 of the 2022 Laws of
-- Maryland (Senate Bill 528). Environment section 2-1204.1 as amended: "The State shall reduce
-- statewide greenhouse gas emissions by [40%] 60% from 2006 levels by [2030] 2031." New section
-- 2-1204.2: "THE STATE SHALL ACHIEVE NET-ZERO STATEWIDE GREENHOUSE GAS EMISSIONS BY 2045." New
-- section 2-1602(a): building energy performance standards reaching "NET ZERO DIRECT GREENHOUSE GAS
-- EMISSIONS ON OR BEFORE JANUARY 1, 2040". **No emergency is declared, nothing is banned, and no
-- fossil fuel is phased out by 2030**, so chairs 1 and 2 are both false of a member whose evidence
-- is this vote. 22 people were nevertheless showing voters the ban.
--
-- 🔴🔴 AND THE REMEDY LANDS ON A DIFFERENT QUESTION. Season 1 is closed and immutable (ADR 0005
-- section 1.6), so the only lever is to INSERT a Season 2 row — and by ADR 0006 an answer is read
-- against the ladder it was given against, so the number written here is read against SEASON 2:
--     c1 Require a shift to clean energy through mandates and firm deadlines.
--     c2 Fund clean energy with major subsidies, tax credits, and public investment.
--     c3 Speed up clean energy by cutting permitting red tape and upgrading the grid.
-- That is not a rewording of the Season 1 ladder, it is a different question — and v2r3 carries the
-- IDENTITY rung_map {1:1,2:2,3:3,4:4,5:5} over it. **A rung_map can lie; the rung TEXTS decide.**
--
-- ⚖ WHY CHAIR 1 AND NOT A BLANK. The live alternative was to withdraw all 33 on the ground that a
-- vote for an omnibus act cannot rank instruments — migration 1925's rule for the Respect for
-- Marriage Act. It was rejected because, unlike that Act, this one does NOT carry both limbs:
--   · chair 2 wants MAJOR subsidies, tax credits and public investment. The Climate Catalytic
--     Capital Fund exists to "leverage increased private capital investment", the one recurring
--     appropriation in the chapter is $500,000 a year for the Healthy Soils Program, and the Act
--     creates no significant tax credit. Its money is incidental, not its instrument.
--   · chair 3 wants permitting red tape cut and the grid upgraded. The Act adds an Electric
--     Distribution System PLANNING subtitle and reforms no permitting.
--   · chairs 4 and 5 (market-neutral, end mandates) are the opposite of what it does.
-- One limb matches the statute's spine and the others fail on the statute's own text, which is the
-- same test that seated the For the People Act at redistricting chair 2 in migration 1942.
--
-- ⚠ THE ONE ROW AT SEASON 1 CHAIR 3 IS WRITTEN TOO. Chair 3 is right about her on the ambition
-- ladder, and her Season 1 answer is untouched and stays right. But the live question is the
-- instrument question, 33 people hold identical evidence, and on that question they are one answer.
-- Leaving her out would publish two different positions from one vote, which is the defect this
-- check exists to find.
--
-- ▶ NOT FIXED HERE, AND BIGGER THAN THIS FILE: about 1,100 Season 1 climate answers sit behind that
-- identity rung_map and serve Season 1 ladder text. Whether v2r3 should have reused the numbering
-- at all is a ladder-governance decision, not a stance repair. Recorded, not acted on.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- B. TAX CUTS AND JOBS ACT -> taxes, FOR, 33 rows (27 at c4, 6 at c5) — WITHDRAWN, NOTHING WRITTEN
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔴🔴 THE SECOND TIME `--sole` HAS PROMISED MORE THAN IT CAN DELIVER. It compares rows whose
-- reasoning rests on one KEYED instrument; `extractInstrumentKeys` is lexical, and it cannot see
-- the Taxpayer Protection Pledge, the FairTax, a flat tax, a Club for Growth or Citizens for Tax
-- Justice rating, or an estate-tax repeal vote. Reading all 33 rows, the split is not a
-- contradiction at all — it tracks exactly that unkeyed evidence:
--   · all six rows at chair 5 carry a FairTax, national-sales-tax, abolish-the-IRS or flat-rate
--     commitment in the member's own record — Schweikert, Wilson, Loudermilk, Higgins, Estes and
--     Labrador. Chair 5 is "Drastically cut taxes and shrink government".
--   · the rows at chair 4 stop at rate cuts and pledges, and several say so in terms ("without
--     going as far as a flat tax", "stops short of a drastic flat-tax restructuring").
-- A rung reflects the SUM of a row's evidence, so two rows are only comparable when the sum is the
-- same. It is not here, both readings can be right, and the group is not one unit of defect.
-- ⚠ Separately and NOT acted on: nearly every row in this group cites only ontheissues.org and
-- Wikipedia. That is a sourcing-quality question for the coverage work, not a contradiction.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- C. BLUEPRINT FOR MARYLAND'S FUTURE -> school-vouchers, FOR, 20 rows (15 at c1, 5 at c2)
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- 🔑 AN OFF-AXIS INSTRUMENT IS WRONG AT EVERY RUNG — migration 1942's ruling on Texas HB 229,
-- reached again from the other direction. The Blueprint (House Bill 1300 of 2020, House Bill 1372
-- of 2021) is a PUBLIC SCHOOL FUNDING AND POLICY statute: "Repealing, altering, and adding certain
-- provisions of law to implement The Blueprint for Maryland's Future, which is intended to
-- transform Maryland's education system to the levels of high-performing systems around the world".
-- Neither bill page contains the word voucher, or BOOST, at all. It cannot seat a voucher rung.
-- Season 1 chair 1 asserts "eliminating voucher programs" and chair 2 asserts "restricting vouchers
-- to low-income families"; supporting a school-funding law establishes neither, and the secondary
-- claim that the member "voted against school voucher legislation" names no bill and cites none.
-- All 20 withdrawn. Citations kept, so any of them can be seated the day a voucher instrument is
-- named. ⚠ 15 of the 20 were showing voters a demand to ELIMINATE vouchers.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- D. RESPECT FOR MARRIAGE ACT, **AGAINST** SIDE -> same-sex-marriage, 20 rows (3 at c4, 17 at c5)
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- Migration 1925 blanked 53 rows on the FOR side of this Act, on the rule that the Act carries both
-- chairs' content so a vote for it proves the SIDE and not the RUNG. The against side is NOT the
-- mirror image and was not treated as one: most of these rows carry something beyond the vote.
-- The test applied, row by row: **does a member-specific record beyond the vote describe the
-- chair?** Chair 5 is "Make same-sex marriage illegal and define marriage as only between one man
-- and one woman"; chair 4 is "Recognize civil unions for same-sex couples, but reserve marriage for
-- opposite-sex couples".
--   KEPT at chair 5 — nine rows, each with its own record: a Federal Marriage Amendment
--     co-sponsorship and an anti-Obergefell resolution (Harris); a state constitutional ban and
--     DOMA (Lankford); condemning Obergefell plus "I do not support gay marriage" (Lee); and the
--     member's own definition of marriage in their own words (Banks, Kustoff, Budd, Boebert, Hern,
--     Higgins).
--   WITHDRAWN — eleven rows. Eight at chair 5 whose only marriage evidence is the vote plus a
--     paraphrase or an adjacent claim: "business liberty over gay marriage" (Mann), a 2012
--     objection to a commitment ceremony (Hyde-Smith), a survey answer about not discriminating
--     against people who hold a belief (Carl), "faith-based opposition be respected" (Thompson),
--     bare "opposes gay marriage" (Bergman, Smucker), "sexual preference is not a protected right"
--     (Balderson), and one row reasoning from ABSENCE — "has not made public statements supporting
--     same-sex marriage recognition" (Kennedy).
--   WITHDRAWN — all three at chair 4. **Not one row in the group cites support for civil unions**,
--     which is chair 4's entire content. Two of the three read as leaving marriage to the states
--     (Tuberville, Braun) — and that is Season 1 chair 3, which Season 2 INVALIDATED rather than
--     renumbered, so the position they actually hold has no chair on the live ladder. The third
--     (Grassley) carries votes for a constitutional ban, which is chair 5 evidence, against a 2022
--     statement of personal support: conflicting records on one row, so it declines rather than
--     guesses — and chair 4 was never earned either way.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- E. OPTING IN ON OPPORTUNITY ACT -> school-vouchers, SPONSOR, 19 rows (10 at c4, 9 at c5)
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- Nineteen co-sponsors of ONE bill, with word-for-word identical evidence, split down the middle:
-- the ten whose summary says "tax-credit-funded private school scholarships" sit at chair 4 and the
-- nine whose summary says "private school choice programs" sit at chair 5. The summary chose the
-- chair, not the member — migration 1925's finding, reproduced exactly.
-- The bill was read: Maryland House Bill 455 of 2026, adding Education section 7-137. Subsection
-- (B) states the intent that it be construed "IN A MANNER THAT IS CONSISTENT WITH, AND ENABLES THE
-- STATE TO PARTICIPATE IN, THE FEDERAL TAX CREDIT SCHOLARSHIP PROGRAM ESTABLISHED UNDER SECTION 25F
-- OF THE INTERNAL REVENUE CODE". It creates no State voucher, appropriates nothing, and sets no
-- eligibility of its own — (C)(1)(II) certifies an organisation that scholarships "ELIGIBLE
-- STUDENTS, AS DEFINED IN SECTION 25F OF THE INTERNAL REVENUE CODE". 26 U.S.C. 25F(c)(2) defines
-- that as a household "with an income which ... is not greater than 300 percent of the area median
-- gross income" and 25F(c)(5)(F)(i) makes the organisation verify it.
-- So the programme is INCOME-CAPPED, which is Season 2 chair 3, "Allowing income-based voucher
-- programs, open to a wider range of families under an income cap". Chair 4 expands eligibility
-- past a cap and chair 5 is universal; this bill is neither. All 18 re-seated to chair 3.
-- ⚠ ONE ROW LEFT ALONE. Jim Hinebaugh, Jr.'s row names a SECOND instrument — a bill establishing an
-- Education Savings Account Program — which the lexical keyer never saw and which no citation on
-- the row establishes. Moving him would carry an unverified claim to a new chair, so his row is
-- pinned where it is and owed a one-row read. Same call as Ghrist in migration 1942.
--
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- GATES
-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- · audit-chair-evidence.mjs --csv  BEFORE the write, over the 51 rows this file SEATS, with the
--   reasoning text generated from this file's own notice blocks so the gated text is the written
--   text. The 31 withdrawals set no chair, so that gate has nothing to test on them.
-- · audit-chair-evidence.mjs --check AFTER, carrying season_id — without it the lookup joins every
--   context row of a pair to every answer row, and 51 of these pairs now have a row in each season.
-- · check-stance-sources.mjs on both sides. Live-DB jobs never run on pull requests.
--
-- Applied by hand via psql; no migration runner exists in this repo, so "applied" means its data
-- effects are live. Every guard below fails the whole transaction rather than write a partial.

BEGIN;

-- ─────────────────────────────────────────────────────────────────────────────────────────────
-- THE TARGETS, FROZEN. Two shapes, because the rows live in two places.
--   mig1943_ins  rows that serve from the CLOSED Season 1 with nothing shadowing them. Season 1 is
--                immutable (ADR 0005 section 1.6), so the only lever is to INSERT a Season 2 row,
--                which by ADR 0006 is read against the SEASON 2 ladder. Never hard-code that
--                revision: it is resolved from inform.season_questions.
--   mig1943_upd  rows that already serve from the OPEN Season 2, so they are UPDATEd in place —
--                migration 1925's shape, on the other side of the same Act.
-- ─────────────────────────────────────────────────────────────────────────────────────────────
CREATE TEMP TABLE mig1943_ins ON COMMIT DROP AS
SELECT x.politician_id, x.topic_id, x.op, x.value_after,
       sq.topic_revision_id AS s2_revision,
       pa1.value            AS value_before,
       pa1.topic_revision_id AS s1_revision,
       pa1.updated_at       AS s1_updated_at,
       pc1.reasoning        AS reasoning_before,
       pc1.sources          AS sources_before
  FROM (VALUES
  ('04eb4549-ad64-4ddc-ad53-8f90217f905f'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- N. Scott Phillips: was chair 1
  ('1cc5a555-4b8a-4573-8525-9ad2c7c0bf46'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Debra Davis: was chair 1
  ('2e809682-2d95-480c-885e-d2174b811cfe'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Tiffany T. Alston: was chair 1
  ('338210ee-b9ab-4820-bfce-98f5354837af'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Kent Roberson: was chair 1
  ('38b5030a-aa8b-4363-8b62-3ec384d22088'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Natalie Ziegler: was chair 1
  ('3f45bad5-b856-4d8e-b3d9-8c03623e030a'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Dylan Behler: was chair 1
  ('41749b94-11b8-4047-8421-95db0900d4b2'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Heather Bagnall: was chair 1
  ('4436b432-a63f-4946-919a-f30c41f899e4'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Anne Healey: was chair 1
  ('4a409af4-8568-42c3-bb72-7bb7500c96ce'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Mark S. Chang: was chair 1
  ('5c24446e-c9d6-4dda-9703-e3c049798315'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Nicole A. Williams: was chair 1
  ('631dac5c-fb86-41f5-a82d-5963164a9142'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Jon S. Cardin: was chair 1
  ('9273ed81-2052-428a-b39d-849abeef270b'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Kym Taylor: was chair 1
  ('a4b61b58-9006-4e58-952d-abeb2521cda0'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Courtney Watson: was chair 1
  ('b5aee428-9b2e-4c87-9a5c-63d44f58e1d8'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Cheryl E. Pasteur: was chair 1
  ('b8e331fa-d58e-479f-b076-8fda0b0604c5'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Marvin E. Holmes, Jr.: was chair 1
  ('cd422f8c-913b-4280-987b-9383ead34e85'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Karen Toles: was chair 1
  ('d5999df9-83b8-4870-a170-4d13f40473e2'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Denise Roberts: was chair 1
  ('d61a670a-7626-4464-93dc-c1e21d7b26da'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Andrea Fletcher Harrison: was chair 1
  ('d8eee978-cec3-492d-9867-9d40b2a50a9d'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Ashanti Martinez: was chair 1
  ('f45e2178-2a05-4974-8af8-379662412060'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Jen Terrasa: was chair 1
  ('f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Terri L. Hill: was chair 1
  ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Jessica Feldmark: was chair 1
  ('04e1a744-acf5-4453-9172-7135b6bfce96'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Antonio Hayes: was chair 2
  ('18313901-28d8-464c-9368-2873577e9d44'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Mary-Dulany James: was chair 2
  ('54ea8c48-d8d0-43e2-83fe-2f91cac71fdd'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Cory V. McCray: was chair 2
  ('81b8bae9-0b0f-43de-8079-c0b605e12cec'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Nancy J. King: was chair 2
  ('9d191d69-084f-4941-bc0a-c59d336f032e'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Malcolm Augustine: was chair 2
  ('b9c61fea-fcb1-45cc-8e2c-e5b3046b7266'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Edith J. Patterson: was chair 2
  ('d8eabd9b-2aa8-40de-94ce-06ce6ef167cf'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Dana Jones: was chair 2
  ('ddfd43d3-023d-417e-9b68-af5a693e601e'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Andrew C. Pruski: was chair 2
  ('fb714c92-166f-4cc1-bb6b-19988a81cefe'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Dalya Attar: was chair 2
  ('ff266ecf-9ea5-4282-b729-9830cc8abfa3'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Dawn Gile: was chair 2
  ('e35d5990-55c7-42e2-94bc-27cb1c49b5f1'::uuid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid,'csna-seat',1),  -- Cheryl C. Kagan: was chair 3
  ('00cd05cc-75de-4d9a-ab23-9f53441bc186'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'blueprint-blank',0),  -- Joseline Peña-Melnyk: was chair 1
  ('251a2047-372b-480e-aa09-231f9a5edeca'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'blueprint-blank',0),  -- Mary A. Lehman: was chair 1
  ('2e809682-2d95-480c-885e-d2174b811cfe'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'blueprint-blank',0),  -- Tiffany T. Alston: was chair 1
  ('4436b432-a63f-4946-919a-f30c41f899e4'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'blueprint-blank',0),  -- Anne Healey: was chair 1
  ('5c24446e-c9d6-4dda-9703-e3c049798315'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'blueprint-blank',0),  -- Nicole A. Williams: was chair 1
  ('631dac5c-fb86-41f5-a82d-5963164a9142'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'blueprint-blank',0),  -- Jon S. Cardin: was chair 1
  ('6d95657c-6c46-4aab-886f-f9688adc7b33'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'blueprint-blank',0),  -- Harry Bhandari: was chair 1
  ('a4b61b58-9006-4e58-952d-abeb2521cda0'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'blueprint-blank',0),  -- Courtney Watson: was chair 1
  ('b8e331fa-d58e-479f-b076-8fda0b0604c5'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'blueprint-blank',0),  -- Marvin E. Holmes, Jr.: was chair 1
  ('d5999df9-83b8-4870-a170-4d13f40473e2'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'blueprint-blank',0),  -- Denise Roberts: was chair 1
  ('d61a670a-7626-4464-93dc-c1e21d7b26da'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'blueprint-blank',0),  -- Andrea Fletcher Harrison: was chair 1
  ('e94337e1-4776-4058-87b4-32dfeb7732a0'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'blueprint-blank',0),  -- Dana Stein: was chair 1
  ('f45e2178-2a05-4974-8af8-379662412060'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'blueprint-blank',0),  -- Jen Terrasa: was chair 1
  ('f6a237a0-34ff-4a93-b05a-335ec38b6da3'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'blueprint-blank',0),  -- Terri L. Hill: was chair 1
  ('fdb9f7d3-93db-4436-bd82-5d7fd853f05e'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'blueprint-blank',0),  -- Jessica Feldmark: was chair 1
  ('7a2d1548-3268-4767-97a8-bb8b142d5a33'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'blueprint-blank',0),  -- Benjamin F. Kramer: was chair 2
  ('9aef8bfb-8e0c-4f00-9898-c738abe4970c'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'blueprint-blank',0),  -- Ron Watson: was chair 2
  ('9c400214-f007-4a8d-92fe-5f5d23b3838e'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'blueprint-blank',0),  -- Jim Rosapepe: was chair 2
  ('b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'blueprint-blank',0),  -- William C. Smith, Jr.: was chair 2
  ('cf190bac-9369-4175-bd4b-8ba776697d9c'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'blueprint-blank',0),  -- Nick Charles: was chair 2
  ('0c789b27-d50c-4822-95ff-409ecb7db08a'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'optin-seat',3),  -- Mike Griffith: was chair 4
  ('1eada938-f28c-46b9-bd21-df241656cd2b'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'optin-seat',3),  -- Christopher T. Adams: was chair 4
  ('1ff2bb96-0e55-4893-8a4c-b675dfbb79f6'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'optin-seat',3),  -- Wayne A. Hartman: was chair 4
  ('547841f2-3476-4e83-9344-0cac984d44e8'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'optin-seat',3),  -- Teresa E. Reilly: was chair 4
  ('58d0ff82-631f-475f-889a-9a4ebb39fc07'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'optin-seat',3),  -- Susan K. McComas: was chair 4
  ('8b43dd9c-26c3-48bb-ac60-d95f8a39349a'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'optin-seat',3),  -- Jay A. Jacobs: was chair 4
  ('bc7ee014-a452-4eaf-81e9-2f4c55d3eaea'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'optin-seat',3),  -- Barry Beauchamp: was chair 4
  ('d17104a7-8a35-4bcd-8879-76ceb997df6a'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'optin-seat',3),  -- H. Kevin Anderson: was chair 4
  ('eca530ff-628d-417d-a3dc-b858dc7c2376'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'optin-seat',3),  -- Jefferson L. Ghrist: was chair 4
  ('fee8a413-a3a8-4568-ad9b-db00f94f5ac2'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'optin-seat',3),  -- Steven J. Arentz: was chair 4
  ('00a1eaeb-157c-42f8-a6e5-9a9d02decbe9'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'optin-seat',3),  -- Barrie S. Ciliberti: was chair 5
  ('5260bd6f-e70a-46f1-aa7d-49eaf22192cf'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'optin-seat',3),  -- Jason C. Buckel: was chair 5
  ('5967c703-2583-466f-a438-c3ac182111d5'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'optin-seat',3),  -- April Rose: was chair 5
  ('6e5ac4b7-73fd-497d-a4e9-7d5124c3d904'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'optin-seat',3),  -- Chris Tomlinson: was chair 5
  ('b389687f-817b-4fda-8770-a888029f4629'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'optin-seat',3),  -- April Miller: was chair 5
  ('c12bb600-318a-4541-bcdd-8260f1ba172e'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'optin-seat',3),  -- Christopher Eric Bouchat: was chair 5
  ('ce2fc441-abd5-4d8f-9c56-114e31c4d43c'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'optin-seat',3),  -- Jesse T. Pippy: was chair 5
  ('eadb65c9-74b6-40c3-b9e7-159c5734c59f'::uuid,'00b95a6a-75db-4521-b523-3326bba938de'::uuid,'optin-seat',3)  -- Robert B. Long: was chair 5
  ) AS x(politician_id, topic_id, op, value_after)
  JOIN inform.politician_answers pa1
    ON pa1.politician_id = x.politician_id AND pa1.topic_id = x.topic_id
   AND pa1.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
  JOIN inform.politician_context pc1
    ON pc1.politician_id = x.politician_id AND pc1.topic_id = x.topic_id
   AND pc1.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
  JOIN inform.season_questions sq
    ON sq.topic_id = x.topic_id AND sq.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

CREATE TEMP TABLE mig1943_upd ON COMMIT DROP AS
SELECT x.politician_id, x.topic_id, x.op, x.value_after,
       pa2.topic_revision_id AS s2_revision,
       pa2.value            AS value_before,
       pc2.reasoning        AS reasoning_before,
       pc2.sources          AS sources_before
  FROM (VALUES
  ('7affca4e-db2b-4f7e-b009-9acc6b493139'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'rfma-against-blank',0),  -- Tommy Tuberville: was chair 4
  ('a73e7a2a-48b0-4636-8fa4-5324ede65833'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'rfma-against-blank',0),  -- Mike Braun: was chair 4
  ('dd5d3f6d-fc82-4774-b510-287ec47cbd84'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'rfma-against-blank',0),  -- Chuck Grassley: was chair 4
  ('2855c340-e9c1-478d-9257-ca316f89e82d'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'rfma-against-blank',0),  -- Tracey Mann: was chair 5
  ('4d83f985-9248-4905-a9b6-5742e2df77a8'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'rfma-against-blank',0),  -- Cindy Hyde-Smith: was chair 5
  ('6a04d1f3-1065-45cb-9084-60906a70383b'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'rfma-against-blank',0),  -- Jerry Carl: was chair 5
  ('6cf68d79-f822-47c4-b702-1f14f20270e4'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'rfma-against-blank',0),  -- Glenn Thompson: was chair 5
  ('98c51f29-fa5d-4368-8330-cb2420746f45'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'rfma-against-blank',0),  -- Jack Bergman: was chair 5
  ('a4f800f0-6634-47c6-a340-ca494544d9b5'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'rfma-against-blank',0),  -- Lloyd Smucker: was chair 5
  ('d053e66a-762e-4514-8e16-2ae672ee47e1'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'rfma-against-blank',0),  -- Troy Balderson: was chair 5
  ('ffe3816f-4923-4e10-b71c-8b2590a8f377'::uuid,'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid,'rfma-against-blank',0)  -- John Kennedy: was chair 5
  ) AS x(politician_id, topic_id, op, value_after)
  JOIN inform.politician_answers pa2
    ON pa2.politician_id = x.politician_id AND pa2.topic_id = x.topic_id
   AND pa2.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
  JOIN inform.politician_context pc2
    ON pc2.politician_id = x.politician_id AND pc2.topic_id = x.topic_id
   AND pc2.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- GUARD 1 — the target sets must be exactly what was read, and every row must have something to keep.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1943_ins;
  IF n <> 71 THEN RAISE EXCEPTION 'migration 1943: expected 71 insert targets, found % — a Season 1 answer or context row is missing', n; END IF;
  SELECT count(*) INTO n FROM mig1943_upd;
  IF n <> 11 THEN RAISE EXCEPTION 'migration 1943: expected 11 update targets, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1943_ins WHERE op = 'csna-seat';
  IF n <> 33 THEN RAISE EXCEPTION 'migration 1943: csna-seat expected 33, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1943_ins WHERE op = 'blueprint-blank';
  IF n <> 20 THEN RAISE EXCEPTION 'migration 1943: blueprint-blank expected 20, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1943_ins WHERE op = 'optin-seat';
  IF n <> 18 THEN RAISE EXCEPTION 'migration 1943: optin-seat expected 18, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1943_upd WHERE op = 'rfma-against-blank';
  IF n <> 11 THEN RAISE EXCEPTION 'migration 1943: rfma-against-blank expected 11, found %', n; END IF;
  SELECT count(*) INTO n FROM (
    SELECT politician_id, topic_id FROM mig1943_ins
    UNION ALL SELECT politician_id, topic_id FROM mig1943_upd) s;
  IF n <> 82 THEN RAISE EXCEPTION 'migration 1943: % rows across both sets, want 82', n; END IF;
  SELECT count(*) INTO n FROM (
    SELECT DISTINCT politician_id, topic_id FROM (
      SELECT politician_id, topic_id FROM mig1943_ins
      UNION ALL SELECT politician_id, topic_id FROM mig1943_upd) a) s;
  IF n <> 82 THEN RAISE EXCEPTION 'migration 1943: duplicate (person, topic) pairs; % distinct of 82', n; END IF;
  SELECT count(*) INTO n FROM (
    SELECT 1 FROM mig1943_ins WHERE reasoning_before IS NULL OR btrim(reasoning_before) = '' OR coalesce(cardinality(sources_before), 0) = 0
    UNION ALL
    SELECT 1 FROM mig1943_upd WHERE reasoning_before IS NULL OR btrim(reasoning_before) = '' OR coalesce(cardinality(sources_before), 0) = 0) s;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % target(s) have no reasoning or no citation to keep', n; END IF;
  SELECT count(*) INTO n FROM (
    SELECT 1 FROM mig1943_ins WHERE reasoning_before LIKE '%migration 1943%'
    UNION ALL SELECT 1 FROM mig1943_upd WHERE reasoning_before LIKE '%migration 1943%') s;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % target(s) already carry a 1943 notice — this file has run', n; END IF;
END $$;

-- GUARD 2 — every target must TODAY still sit on the chair the queue measured it at, per op. If a
-- chair has moved since the read, this file is operating on a stale picture and must stop.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1943_ins WHERE op = 'csna-seat' AND value_before NOT IN (1,2,3);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % csna-seat row(s) do not sit on the chairs they were read at', n; END IF;
  SELECT count(*) INTO n FROM mig1943_ins WHERE op = 'blueprint-blank' AND value_before NOT IN (1,2);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % blueprint-blank row(s) do not sit on the chairs they were read at', n; END IF;
  SELECT count(*) INTO n FROM mig1943_ins WHERE op = 'optin-seat' AND value_before NOT IN (4,5);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % optin-seat row(s) do not sit on the chairs they were read at', n; END IF;
  SELECT count(*) INTO n FROM mig1943_upd WHERE op = 'rfma-against-blank' AND value_before NOT IN (4,5);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % rfma-against-blank row(s) do not sit on the chairs they were read at', n; END IF;
  SELECT count(*) INTO n FROM mig1943_ins WHERE value_before = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % insert target(s) are already blank', n; END IF;
  SELECT count(*) INTO n FROM mig1943_upd WHERE value_before = 0;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % update target(s) are already blank', n; END IF;
END $$;

-- GUARD 3 — the reasoning must really name the instrument the adjudication turned on. Without this
-- the file could move a row whose text was rewritten since the queue read it.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1943_ins
   WHERE op = 'csna-seat' AND reasoning_before !~* 'climate solutions now act';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % csna row(s) do not name the Climate Solutions Now Act', n; END IF;
  SELECT count(*) INTO n FROM mig1943_ins
   WHERE op = 'blueprint-blank' AND reasoning_before !~* 'blueprint for maryland';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % blueprint row(s) do not name the Blueprint', n; END IF;
  SELECT count(*) INTO n FROM mig1943_ins
   WHERE op = 'optin-seat' AND reasoning_before !~* 'opting in on opportunity';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % opt-in row(s) do not name the Act', n; END IF;
  SELECT count(*) INTO n FROM mig1943_upd
   WHERE op = 'rfma-against-blank' AND reasoning_before !~* 'respect for marriage act';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % rfma row(s) do not name the Act', n; END IF;
END $$;

-- GUARD 4 — THE LADDERS. A rung NUMBER means nothing outside one revision, and a rung_map can lie:
-- climate-change carries the IDENTITY map {1:1..5:5} over a ladder rewritten from ranking AMBITION
-- to ranking INSTRUMENT. So this file asserts the TEXT of every chair it reasons from, on both
-- sides of the season boundary, and refuses to write if any of it has moved.
DO $$
DECLARE n int; t text;
BEGIN
  SELECT count(*) INTO n FROM inform.seasons WHERE id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND status = 'open';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1943: Season 2 is not the open season'; END IF;
  SELECT count(*) INTO n FROM inform.seasons WHERE id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid AND status = 'closed';
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1943: Season 1 is not closed'; END IF;

  -- the revisions each season pins, named rather than assumed
  SELECT count(*) INTO n FROM mig1943_ins WHERE topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid
     AND (s1_revision <> 'da9cf777-0a95-41aa-8775-c5b29528825b'::uuid OR s2_revision <> '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % climate row(s) are not on the expected revisions', n; END IF;
  SELECT count(*) INTO n FROM mig1943_ins WHERE topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
     AND (s1_revision <> '835bc8d1-b31b-4fef-9cca-31318cc0f1d6'::uuid OR s2_revision <> '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % voucher row(s) are not on the expected revisions', n; END IF;
  SELECT count(*) INTO n FROM mig1943_upd WHERE s2_revision <> '8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f'::uuid;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % same-sex-marriage row(s) are not on the Season 2 revision', n; END IF;

  -- climate, SEASON 1: the ambition ladder the wrong chairs were read from
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = 'da9cf777-0a95-41aa-8775-c5b29528825b'::uuid AND value = 1;
  IF t IS NULL OR t !~* 'ban all activities that increase carbon emissions' THEN RAISE EXCEPTION 'migration 1943: Season 1 climate chair 1 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = 'da9cf777-0a95-41aa-8775-c5b29528825b'::uuid AND value = 2;
  IF t IS NULL OR t !~* 'phase out fossil fuels by 2030' THEN RAISE EXCEPTION 'migration 1943: Season 1 climate chair 2 does not read as recorded: %', t; END IF;
  -- climate, SEASON 2: the instrument ladder the new chair is written against
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid AND value = 1;
  IF t IS NULL OR t !~* 'mandates and firm deadlines' THEN RAISE EXCEPTION 'migration 1943: Season 2 climate chair 1 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = '5f1403f3-90b6-491f-ba54-3c8e46a5ae26'::uuid AND value = 2;
  IF t IS NULL OR t !~* 'subsidies, tax credits, and public investment' THEN RAISE EXCEPTION 'migration 1943: Season 2 climate chair 2 does not read as recorded: %', t; END IF;

  -- school vouchers, SEASON 1: the two chairs the Blueprint rows were split across
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = '835bc8d1-b31b-4fef-9cca-31318cc0f1d6'::uuid AND value = 1;
  IF t IS NULL OR t !~* 'eliminating voucher programs' THEN RAISE EXCEPTION 'migration 1943: Season 1 voucher chair 1 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = '835bc8d1-b31b-4fef-9cca-31318cc0f1d6'::uuid AND value = 2;
  IF t IS NULL OR t !~* 'restricting vouchers to low-income families' THEN RAISE EXCEPTION 'migration 1943: Season 1 voucher chair 2 does not read as recorded: %', t; END IF;
  -- school vouchers, SEASON 2: the chair the opt-in co-sponsors are seated at
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid AND value = 3;
  IF t IS NULL OR t !~* 'income cap' THEN RAISE EXCEPTION 'migration 1943: Season 2 voucher chair 3 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = '88858826-90c0-41c9-a3a4-1d9f5b8c5307'::uuid AND value = 5;
  IF t IS NULL OR t !~* 'universal vouchers' THEN RAISE EXCEPTION 'migration 1943: Season 2 voucher chair 5 does not read as recorded: %', t; END IF;

  -- same-sex marriage, SEASON 2: the two chairs the against-side rows were split across
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = '8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f'::uuid AND value = 4;
  IF t IS NULL OR t !~* 'civil unions' THEN RAISE EXCEPTION 'migration 1943: Season 2 marriage chair 4 does not read as recorded: %', t; END IF;
  SELECT text INTO t FROM inform.compass_stance_revisions WHERE topic_revision_id = '8bc3d240-bfb8-4e4c-b0f1-760e3cdf0c2f'::uuid AND value = 5;
  IF t IS NULL OR t !~* 'only between one man and one woman' THEN RAISE EXCEPTION 'migration 1943: Season 2 marriage chair 5 does not read as recorded: %', t; END IF;

  -- every chair this file writes must EXIST on the revision it is written against
  SELECT count(*) INTO n FROM mig1943_ins i
   WHERE i.value_after <> 0
     AND NOT EXISTS (SELECT 1 FROM inform.compass_stance_revisions cs
                      WHERE cs.topic_revision_id = i.s2_revision AND cs.value = i.value_after);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % row(s) would be seated on a chair that does not exist', n; END IF;
END $$;

-- GUARD 5 — the two shapes must not blur. An insert target must have NO Season 2 row (or the insert
-- violates the pair key and, worse, means somebody already answered); an update target must have one.
-- And nobody here may be inactive.
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1943_ins i
   WHERE EXISTS (SELECT 1 FROM inform.politician_answers pa
                  WHERE pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id
                    AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % insert target(s) ALREADY have a Season 2 answer — they are updates, not inserts', n; END IF;
  SELECT count(*) INTO n FROM mig1943_ins i
   WHERE EXISTS (SELECT 1 FROM inform.politician_context pc
                  WHERE pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id
                    AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % insert target(s) ALREADY have a Season 2 context row', n; END IF;
  SELECT count(*) INTO n FROM mig1943_upd u
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers pa
                      WHERE pa.politician_id = u.politician_id AND pa.topic_id = u.topic_id
                        AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % update target(s) have no Season 1 record behind them — re-measure', n; END IF;
  SELECT count(*) INTO n FROM (
    SELECT politician_id FROM mig1943_ins UNION SELECT politician_id FROM mig1943_upd) s
    JOIN essentials.politicians p ON p.id = s.politician_id WHERE NOT p.is_active;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % target(s) are on inactive people', n; END IF;
END $$;

-- GUARD 6 — THE ROWS THIS FILE DELIBERATELY DOES NOT TOUCH. Each is a decision, so each is pinned.
DO $$
DECLARE n int;
BEGIN
  -- the one Opting-in co-sponsor left alone: his row names an Education Savings Account bill the
  -- keyer never saw and no citation establishes, so it is not part of this unit of defect.
  SELECT count(*) INTO n FROM inform.politician_answers pa
   WHERE pa.politician_id = '3817ad52-3f43-4bd3-8525-e7dcd0816153'::uuid AND pa.topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
     AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid AND pa.value = 5;
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1943: the left-alone opt-in co-sponsor is not where he was read'; END IF;
  SELECT count(*) INTO n FROM mig1943_ins WHERE politician_id = '3817ad52-3f43-4bd3-8525-e7dcd0816153'::uuid;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: the left-alone opt-in co-sponsor must not be written'; END IF;

  -- the nine against-side marriage rows whose chair survives on a member-specific record
  SELECT count(*) INTO n FROM inform.politician_answers pa
   WHERE pa.topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND pa.value = 5
     AND pa.politician_id IN ('023c6644-356e-4afb-925b-e20f9c32209b'::uuid, '0e89ee8b-5e55-4a40-a88e-04f13a012246'::uuid, '2b8d4b89-2d7c-4b67-a5a1-72bd7c766e1e'::uuid, '401f1fab-c996-4b1a-92f7-2817c5dd4619'::uuid, '4f62ca82-fda1-4386-9a4a-62dd84318f83'::uuid, '58c25b43-0ed1-4636-8213-b89a90f7f6a2'::uuid, '96e589b9-d04a-4749-bf9f-9b66eaea5083'::uuid, 'a8a724eb-d7ff-4bd2-8397-560024f478de'::uuid, 'ff596d3f-3056-43e2-a80a-8c4b8fd9abde'::uuid);
  IF n <> 9 THEN RAISE EXCEPTION 'migration 1943: expected 9 kept marriage rows at chair 5, found %', n; END IF;
  SELECT count(*) INTO n FROM mig1943_upd
   WHERE politician_id IN ('023c6644-356e-4afb-925b-e20f9c32209b'::uuid, '0e89ee8b-5e55-4a40-a88e-04f13a012246'::uuid, '2b8d4b89-2d7c-4b67-a5a1-72bd7c766e1e'::uuid, '401f1fab-c996-4b1a-92f7-2817c5dd4619'::uuid, '4f62ca82-fda1-4386-9a4a-62dd84318f83'::uuid, '58c25b43-0ed1-4636-8213-b89a90f7f6a2'::uuid, '96e589b9-d04a-4749-bf9f-9b66eaea5083'::uuid, 'a8a724eb-d7ff-4bd2-8397-560024f478de'::uuid, 'ff596d3f-3056-43e2-a80a-8c4b8fd9abde'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: a kept marriage row is in the write set'; END IF;

  -- the Tax Cuts and Jobs Act group is WITHDRAWN FROM THIS PASS, not adjudicated: its 4/5 split
  -- tracks real extra evidence (the Taxpayer Protection Pledge, the FairTax, flat-tax advocacy)
  -- that the lexical keyer cannot see. Nothing from it may be written here.
  SELECT count(*) INTO n FROM mig1943_ins WHERE topic_id NOT IN ('f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'::uuid, '00b95a6a-75db-4521-b523-3326bba938de'::uuid);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % insert target(s) are on an unexpected topic', n; END IF;
  SELECT count(*) INTO n FROM mig1943_upd WHERE topic_id <> 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % update target(s) are on an unexpected topic', n; END IF;
END $$;

-- ── THE WRITE ────────────────────────────────────────────────────────────────────────────────
-- Season 1 is never touched. Sources are carried across byte for byte and the original reasoning
-- follows the notice verbatim, so nothing researched is lost and every blank is recoverable.

INSERT INTO inform.politician_answers
  (politician_id, topic_id, value, season_id, topic_revision_id)
SELECT i.politician_id, i.topic_id, i.value_after, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, i.s2_revision
  FROM mig1943_ins i;

INSERT INTO inform.politician_context
  (politician_id, topic_id, reasoning, sources, season_id, topic_revision_id)
SELECT i.politician_id, i.topic_id,
       CASE i.op
      WHEN 'csna-seat' THEN $txt$RE-SEATED by migration 1943, contradiction check round two. This row rested on a vote for the Climate Solutions Now Act of 2022 (Maryland Senate Bill 528, Chapter 38) and was seated on the SEASON 1 climate ladder, which ranks AMBITION: its chair 1 is "declare a climate emergency and ban all activities that increase carbon emissions" and its chair 2 is "rapidly transition to renewable energy and phase out fossil fuels by 2030". The enacted chapter does neither. Read, not taken from the title: Environment section 2-1204.1 as amended requires the State to "reduce statewide greenhouse gas emissions by 60% from 2006 levels by 2031"; new section 2-1204.2 provides "THE STATE SHALL ACHIEVE NET-ZERO STATEWIDE GREENHOUSE GAS EMISSIONS BY 2045"; new section 2-1602(a) directs building energy performance standards reaching "NET ZERO DIRECT GREENHOUSE GAS EMISSIONS ON OR BEFORE JANUARY 1, 2040". No emergency is declared, nothing is banned, and no fossil fuel is phased out by 2030, so 33 members split across chairs 1, 2 and 3 on one vote. The SEASON 2 ladder asks a different question - which instrument, not how much ambition - and the Act answers it: its spine is statutory mandates carrying firm deadlines, which is chair 1 ("Require a shift to clean energy through mandates and firm deadlines"). Chair 2 ("major subsidies, tax credits, and public investment") fails on the Act itself: the Climate Catalytic Capital Fund exists to "leverage increased private capital investment", the one recurring appropriation is $500,000 a year for Healthy Soils, and the Act creates no significant tax credit. Chair 3 (permitting and the grid) fails because the Act adds distribution-system PLANNING duties and no permitting reform. Seated at Season 2 chair 1. The Season 1 answer is untouched and the original reasoning and every citation follow. $txt$
      WHEN 'blueprint-blank' THEN $txt$WITHDRAWN by migration 1943, contradiction check round two. This row rested on support for the Blueprint for Maryland’s Future (House Bill 1300, 2020; House Bill 1372, 2021) and was seated on the school-vouchers ladder - 20 members split 15 at chair 1 and 5 at chair 2 on the same evidence. The Blueprint is a PUBLIC SCHOOL FUNDING AND POLICY statute: its synopsis describes implementing a system "intended to transform Maryland’s education system to the levels of high-performing systems around the world", and neither bill page mentions a voucher or the BOOST programme at all. It is OFF THIS LADDER’S AXIS, and an off-axis instrument is wrong at every rung, so the split is not resolved by picking one. Chair 1 asserts "eliminating voucher programs" and chair 2 asserts restricting vouchers to low-income families; the Blueprint establishes neither, and the secondary claim that the member "voted against school voucher legislation" names no bill and cites none. A blank withdraws a claim nobody established; it does not assert that the person holds no view. Every citation is kept, so the row can be seated the moment a voucher instrument is named. $txt$
      WHEN 'optin-seat' THEN $txt$RE-SEATED by migration 1943, contradiction check round two. Nineteen co-sponsors of one bill, with identical evidence, split 10 at chair 4 and 9 at chair 5 - the summary chose the chair, not the member. The bill, read rather than summarised: Maryland House Bill 455 of 2026, Education - Certification of Scholarship Granting Organizations (Opting in on Opportunity Act), adds Education section 7-137, whose subsection (B) states the intent that it "ENABLES THE STATE TO PARTICIPATE IN, THE FEDERAL TAX CREDIT SCHOLARSHIP PROGRAM ESTABLISHED UNDER SECTION 25F OF THE INTERNAL REVENUE CODE". It creates no State voucher, appropriates nothing, and sets no eligibility of its own: subsection (C)(1)(II) certifies an organisation that provides scholarships to "ELIGIBLE STUDENTS, AS DEFINED IN SECTION 25F OF THE INTERNAL REVENUE CODE". Section 25F(c)(2) defines an eligible student as one in "a household with an income which ... is not greater than 300 percent of the area median gross income" who is eligible to enrol in a public school, and section 25F(c)(5)(F)(i) makes the organisation verify household income. So the programme this bill opts Maryland into is INCOME-CAPPED, which is Season 2 chair 3 ("Allowing income-based voucher programs, open to a wider range of families under an income cap"). Chair 4 and chair 5 both fail: the bill expands eligibility no further than the federal cap and is not universal. Seated at Season 2 chair 3. The Season 1 answer is untouched and the original reasoning and every citation follow. $txt$
       END || i.reasoning_before,
       i.sources_before, '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid, i.s2_revision
  FROM mig1943_ins i;

UPDATE inform.politician_answers pa
   SET value = u.value_after, updated_at = now()
  FROM mig1943_upd u
 WHERE pa.politician_id = u.politician_id AND pa.topic_id = u.topic_id
   AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

UPDATE inform.politician_context pc
   SET reasoning = (CASE u.op
      WHEN 'rfma-against-blank' THEN $txt$WITHDRAWN by migration 1943, contradiction check round two, on the rule migration 1925 set for the FOR side of the same Act. Twenty members who voted AGAINST the Respect for Marriage Act split 3 at chair 4 and 17 at chair 5 on that one vote. A vote proves the SIDE and never the RUNG: a No vote establishes opposition to federal codification and cannot choose between chair 4 ("Recognize civil unions for same-sex couples, but reserve marriage for opposite-sex couples") and chair 5 ("Make same-sex marriage illegal and define marriage as only between one man and one woman"). Nine of the twenty are LEFT SEATED because a member-specific record beyond the vote describes chair 5 - a constitutional amendment or State ban, an endorsement of DOMA, a condemnation of Obergefell, or the member’s own words defining marriage. This row carries no such record. Chair 4 is not reachable for any row in the group either: not one cites support for civil unions, which is chair 4’s whole content, and the two rows that read as leaving marriage to the states point at a rung Season 2 INVALIDATED. Every citation is kept, so the row can be re-seated on a member-specific record. $txt$
       END) || u.reasoning_before, updated_at = now()
  FROM mig1943_upd u
 WHERE pc.politician_id = u.politician_id AND pc.topic_id = u.topic_id
   AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid;

-- ── POST-FLIGHT — verify the RESULT, never the absence of an error ───────────────────────────
DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM mig1943_ins i
    JOIN inform.politician_answers pa
      ON pa.politician_id = i.politician_id AND pa.topic_id = i.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value = i.value_after AND pa.topic_revision_id = i.s2_revision;
  IF n <> 71 THEN RAISE EXCEPTION 'migration 1943: expected 71 inserted answers at their chair and revision, found %', n; END IF;

  SELECT count(*) INTO n FROM mig1943_upd u
    JOIN inform.politician_answers pa
      ON pa.politician_id = u.politician_id AND pa.topic_id = u.topic_id
     AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pa.value = 0;
  IF n <> 11 THEN RAISE EXCEPTION 'migration 1943: expected 11 blanked Season 2 answers, found %', n; END IF;

  SELECT count(*) INTO n FROM inform.politician_answers pa
    JOIN mig1943_ins i ON i.politician_id = pa.politician_id AND i.topic_id = pa.topic_id
   WHERE pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND pa.value = 0;
  IF n <> 20 THEN RAISE EXCEPTION 'migration 1943: expected 20 inserted blanks, found %', n; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers pa
    JOIN mig1943_ins i ON i.politician_id = pa.politician_id AND i.topic_id = pa.topic_id
   WHERE pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND pa.value <> 0;
  IF n <> 51 THEN RAISE EXCEPTION 'migration 1943: expected 51 inserted seats, found %', n; END IF;

  -- citations and original prose survive, on both shapes
  SELECT count(*) INTO n FROM mig1943_ins i
    JOIN inform.politician_context pc
      ON pc.politician_id = i.politician_id AND pc.topic_id = i.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.sources IS DISTINCT FROM i.sources_before
      OR strpos(pc.reasoning, i.reasoning_before) = 0
      OR pc.reasoning NOT LIKE '%migration 1943%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % inserted context row(s) lost citations, the original prose, or the notice', n; END IF;
  SELECT count(*) INTO n FROM mig1943_upd u
    JOIN inform.politician_context pc
      ON pc.politician_id = u.politician_id AND pc.topic_id = u.topic_id
     AND pc.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid
   WHERE pc.sources IS DISTINCT FROM u.sources_before
      OR strpos(pc.reasoning, u.reasoning_before) = 0
      OR pc.reasoning NOT LIKE '%migration 1943%';
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % updated context row(s) lost citations, the original prose, or the notice', n; END IF;

  -- SEASON 1 IS IMMUTABLE AND MUST BE PROVED UNMOVED — values and timestamps alike.
  SELECT count(*) INTO n FROM inform.politician_answers pa
    JOIN mig1943_ins i ON i.politician_id = pa.politician_id AND i.topic_id = pa.topic_id
   WHERE pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid
     AND (pa.value <> i.value_before OR pa.updated_at IS DISTINCT FROM i.s1_updated_at);
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % Season 1 answer(s) moved — they must not', n; END IF;
  SELECT count(*) INTO n FROM inform.politician_context pc
    JOIN mig1943_ins i ON i.politician_id = pc.politician_id AND i.topic_id = pc.topic_id
   WHERE pc.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid AND pc.reasoning IS DISTINCT FROM i.reasoning_before;
  IF n <> 0 THEN RAISE EXCEPTION 'migration 1943: % Season 1 context row(s) were rewritten — they must not be', n; END IF;

  -- and the rows this file promised not to touch are still where they were
  SELECT count(*) INTO n FROM inform.politician_answers pa
   WHERE pa.politician_id = '3817ad52-3f43-4bd3-8525-e7dcd0816153'::uuid AND pa.topic_id = '00b95a6a-75db-4521-b523-3326bba938de'::uuid
     AND pa.season_id = '2d5d67d1-2a2a-4c73-88bb-3c2e3e33cba3'::uuid AND pa.value = 5;
  IF n <> 1 THEN RAISE EXCEPTION 'migration 1943: the left-alone opt-in co-sponsor moved'; END IF;
  SELECT count(*) INTO n FROM inform.politician_answers pa
   WHERE pa.topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'::uuid AND pa.season_id = '86d893a1-c1a2-4bbf-b4e5-69ec43221194'::uuid AND pa.value = 5
     AND pa.politician_id IN ('023c6644-356e-4afb-925b-e20f9c32209b'::uuid, '0e89ee8b-5e55-4a40-a88e-04f13a012246'::uuid, '2b8d4b89-2d7c-4b67-a5a1-72bd7c766e1e'::uuid, '401f1fab-c996-4b1a-92f7-2817c5dd4619'::uuid, '4f62ca82-fda1-4386-9a4a-62dd84318f83'::uuid, '58c25b43-0ed1-4636-8213-b89a90f7f6a2'::uuid, '96e589b9-d04a-4749-bf9f-9b66eaea5083'::uuid, 'a8a724eb-d7ff-4bd2-8397-560024f478de'::uuid, 'ff596d3f-3056-43e2-a80a-8c4b8fd9abde'::uuid);
  IF n <> 9 THEN RAISE EXCEPTION 'migration 1943: a kept marriage row moved; % remain at chair 5', n; END IF;
END $$;

COMMIT;
