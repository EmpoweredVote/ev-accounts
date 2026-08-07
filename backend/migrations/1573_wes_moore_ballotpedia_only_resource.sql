-- 1573_wes_moore_ballotpedia_only_resource.sql
--
-- Work the 5 Governor Wes Moore rows that migration 1564 left sole-sourced to Ballotpedia.
-- Outcome: 2 repaired and re-sourced to Maryland primary records, 3 RETIRED as unsupported.
--
--   Rollback: recorded inline at the foot of this file (all 5 rows verbatim).
--   Opened by: 1564 — BALLOTPEDIA_ONLY rose 159 -> 164 because a FABRICATED co-source was removed and
--              the rows underneath were always Ballotpedia-only. A re-sourcing queue, not decay.
--
-- No migration runner exists; this file records SQL applied by hand via
-- `npx tsx scripts/_apply-file.ts migrations/1573_wes_moore_ballotpedia_only_resource.sql`.
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 THE CITED PAGE DOES NOT CARRY THE CLAIMS
-- ---------------------------------------------------------------------------------------------------
-- `ballotpedia.org/Wes_Moore` was fetched with a browser UA (200, 278,847 bytes, 71,715 chars of text —
-- Ballotpedia 403s a plain fetch, so this was classified before being read). Searched in the RAW HTML,
-- not just the extracted body:
--
--   MISS: "undocumented" · "fossil" · "same-sex" · "voucher" · "Election Day" · "automatic voter" ·
--         "homeless" · "EITC" · "independent redistricting"
--   HIT:  "childcare" · "Pre-K" · "Medicaid" · "child tax credit" · "earned income" · "transgender"
--
-- So the specifics several of these rows assert are simply not on the page they cite. ⚠ Note Moore has
-- ELEVEN Ballotpedia-only rows, not five; the other six are pre-existing and out of scope here, but
-- they are the same defect and are listed as a queue at the foot of this file.
--
-- ---------------------------------------------------------------------------------------------------
-- REPAIRED (2) — re-sourced to fetched Maryland primary records, values corrected
-- ---------------------------------------------------------------------------------------------------
-- CHILDCARE  1 -> 2. The row claimed he "supports universal pre-K and government-funded childcare",
--   which is chair 1. What the record shows is a large SUBSIDY expansion, which is chair 2:
--   the FY2027 budget "continues record State funding of $434 million to support the Child Care
--   Scholarship program" plus the ENOUGH Initiative. Verified verbatim on governor.maryland.gov.
--
-- TAXES  1 -> 3. The row claimed his budgets "consistently proposed raising taxes on wealthy
--   Marylanders and corporations", which is chair 1. 🔴 That is CONTRADICTED by the primary source:
--   the FY2027 budget release is headlined "...without Raising Taxes or Fees". What is verified is
--   targeted relief — the Family Prosperity Act of 2023 permanently extended the Earned Income Tax
--   Credit and expanded the Child Tax Credit, ~40,000 taxpayers and as many as 400,000 Marylanders,
--   part of "nearly $200 million reserved for tax relief". That is chair 3.
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 RETIRED (3) — because the CHAIR TEXTS ask a different question than the evidence answers
-- ---------------------------------------------------------------------------------------------------
-- This is the Carson lesson applied to a governor: match the evidence to the five chair texts, not to
-- the topic's title. In each case Moore has a real, verified record — and it does not speak to the
-- question the scale actually poses.
--
-- FOSSIL FUELS. The chairs are entirely about DRILLING AND EXTRACTION permits ("immediately ban all new
--   fossil fuel drilling", "stop issuing new permits", "expand drilling permits"). Moore's verified
--   action is demand-side: his executive order "directs the Maryland Department of the Environment to
--   take immediate action on climate change by proposing a zero-emission heating equipment standard
--   regulation and a clean heat standard regulation", toward 60% below 2006 levels by 2031 and net zero
--   by 2045. Real and substantial — and about heating equipment, not extraction. Maryland has
--   negligible production and banned fracking in 2017, before he took office. No chair fits.
--   ⚠ The retired reasoning also misstated the order as covering "new state buildings by 2030".
--
-- VOTING RIGHTS. The chairs are about REGISTRATION AND VOTING MECHANICS (automatic registration, online
--   voting, early voting, mail-in, voter ID). 🔴 The row's central claim — automatic voter registration
--   — is MISATTRIBUTED: Maryland enacted AVR under Governor Larry Hogan, before Moore took office. The
--   pre-tenure class again, this time at state level. Moore's verified voting action is SB 255, the
--   "Voting Rights Act of 2026 - Counties and Municipal Corporations", "Approved by the Governor -
--   Chapter 157" (mgaleg.maryland.gov), which prohibits local election methods that dilute or abridge a
--   protected class's votes. That is vote dilution, not registration mechanics. No chair fits.
--
-- HEALTHCARE. The row claims he "signed legislation expanding coverage to undocumented immigrants".
--   "undocumented" does not appear anywhere in the cited page's raw HTML, and no primary record of his
--   signature was obtained. The Access to Care Act did pass the General Assembly in 2024, but its
--   implementation has since been delayed to 2028, so even the underlying fact is not what the row
--   asserts. It also credits him with expanding Medicaid, which Maryland did under the ACA years before
--   he took office. Unsupported as written.
--
-- 🔑 Retiring three rows for a sitting governor with an enormous public record is not a failure of
-- sourcing — it is the scale asking about drilling and registration while the governor acted on heating
-- and vote dilution. Those topics should be re-researched against evidence that answers THEIR question.
-- ===================================================================================================

BEGIN;

DO $$
DECLARE v_cnt int;
BEGIN
  -- All five rows exist, are Wes Moore's, and are sole-sourced to Ballotpedia.
  SELECT count(*) INTO v_cnt
  FROM inform.politician_context c
  WHERE c.politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632'
    AND c.topic_id IN ('c1ac1330-47f7-44ec-baf3-c913d926b97c','f7e5678d-dadd-4556-a2fc-446e24642ceb',
                       'a22215c3-6693-4bc2-b248-01aebba14570','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
                       'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529')
    AND NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s NOT ILIKE '%ballotpedia%');
  IF v_cnt <> 5 THEN RAISE EXCEPTION 'PRE: expected 5 Ballotpedia-only Moore rows, found %', v_cnt; END IF;

  -- Every row has its matching answer.
  SELECT count(*) INTO v_cnt
  FROM inform.politician_answers a
  WHERE a.politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632'
    AND a.topic_id IN ('c1ac1330-47f7-44ec-baf3-c913d926b97c','f7e5678d-dadd-4556-a2fc-446e24642ceb',
                       'a22215c3-6693-4bc2-b248-01aebba14570','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
                       'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529');
  IF v_cnt <> 5 THEN RAISE EXCEPTION 'PRE: expected 5 matching answers, found %', v_cnt; END IF;
END $$;

-- --- REPAIR 1: Childcare, 1 -> 2 --------------------------------------------------------------------
UPDATE inform.politician_answers SET value = 2
 WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632'
   AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';

UPDATE inform.politician_context
   SET reasoning = 'Governor Moore''s Fiscal Year 2027 budget continues record state funding of $434 million for the Child Care Scholarship program, which helps families enroll young children in child care, alongside a record $32 million for community-driven anti-poverty work through the ENOUGH Initiative. His administration has substantially expanded childcare subsidies rather than establishing a universal publicly funded system.',
       sources = ARRAY['https://governor.maryland.gov/news/press-releases/governor-moore-signs-fy-2027-budget-delivering-historic-education-and-public-safety-investments']
 WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632'
   AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';

-- --- REPAIR 2: Taxes, 1 -> 3 ------------------------------------------------------------------------
UPDATE inform.politician_answers SET value = 3
 WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632'
   AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';

UPDATE inform.politician_context
   SET reasoning = 'Governor Moore''s first bill signing enacted the Family Prosperity Act of 2023, which permanently extended Maryland''s Earned Income Tax Credit and removed the $530 cap for adults without qualifying children, and expanded the Child Tax Credit to families with children aged six and under. The state estimated the credit expansion would benefit about 40,000 taxpayers and provide relief to as many as 400,000 Marylanders, as part of nearly $200 million reserved for tax relief. He signed the Fiscal Year 2027 budget without raising taxes or fees.',
       sources = ARRAY['https://governor.maryland.gov/news/press-releases/governor-moore-presides-over-first-bill-signing-dedicated-ending-child-poverty-maryland',
                       'https://governor.maryland.gov/news/press-releases/governor-moore-signs-fy-2027-budget-delivering-historic-education-and-public-safety-investments']
 WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632'
   AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';

-- --- RETIRE 3: Fossil Fuels, Voting Rights, Healthcare ----------------------------------------------
DELETE FROM inform.politician_answers
 WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632'
   AND topic_id IN ('a22215c3-6693-4bc2-b248-01aebba14570',
                    'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
                    'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529');

DELETE FROM inform.politician_context
 WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632'
   AND topic_id IN ('a22215c3-6693-4bc2-b248-01aebba14570',
                    'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
                    'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529');

-- --- POST-CONDITIONS ------------------------------------------------------------------------------

DO $$
DECLARE v_cnt int;
BEGIN
  -- The two repaired rows now cite Maryland primary records and no Ballotpedia.
  SELECT count(*) INTO v_cnt
  FROM inform.politician_context c
  WHERE c.politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632'
    AND c.topic_id IN ('c1ac1330-47f7-44ec-baf3-c913d926b97c','f7e5678d-dadd-4556-a2fc-446e24642ceb')
    AND EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s ILIKE '%ballotpedia%');
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'POST: % repaired row(s) still cite Ballotpedia', v_cnt; END IF;

  SELECT count(*) INTO v_cnt
  FROM inform.politician_context c
  WHERE c.politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632'
    AND c.topic_id IN ('c1ac1330-47f7-44ec-baf3-c913d926b97c','f7e5678d-dadd-4556-a2fc-446e24642ceb')
    AND EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE 'https://governor.maryland.gov/%');
  IF v_cnt <> 2 THEN RAISE EXCEPTION 'POST: % of 2 repaired rows cite governor.maryland.gov', v_cnt; END IF;

  -- The three retired topics are gone from both tables.
  SELECT count(*) INTO v_cnt FROM inform.politician_answers
   WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632'
     AND topic_id IN ('a22215c3-6693-4bc2-b248-01aebba14570','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
                      'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529');
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'POST: % retired answers survive', v_cnt; END IF;

  SELECT count(*) INTO v_cnt FROM inform.politician_context
   WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632'
     AND topic_id IN ('a22215c3-6693-4bc2-b248-01aebba14570','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
                      'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529');
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'POST: % retired context rows survive', v_cnt; END IF;

  -- Moore keeps 16 answers, each still paired with its context. He is not emptied, so his
  -- last_stances_researched_at is deliberately left as it is (the 1494 rule applies only at zero).
  SELECT count(*) INTO v_cnt FROM inform.politician_answers
   WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632';
  IF v_cnt <> 16 THEN RAISE EXCEPTION 'POST: Moore holds % answers, expected 16', v_cnt; END IF;

  SELECT count(*) INTO v_cnt
  FROM inform.politician_answers a
  LEFT JOIN inform.politician_context c
    ON c.politician_id = a.politician_id AND c.topic_id = a.topic_id
  WHERE a.politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632' AND c.politician_id IS NULL;
  IF v_cnt <> 0 THEN RAISE EXCEPTION 'POST: % answers left without context', v_cnt; END IF;

  -- BALLOTPEDIA_ONLY for Moore must have fallen by exactly 5 (2 re-sourced + 3 retired): 11 -> 6.
  SELECT count(*) INTO v_cnt
  FROM inform.politician_context c
  WHERE c.politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632'
    AND NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s NOT ILIKE '%ballotpedia%');
  IF v_cnt <> 6 THEN RAISE EXCEPTION 'POST: Moore has % Ballotpedia-only rows, expected 6', v_cnt; END IF;
END $$;

COMMIT;

-- ---------------------------------------------------------------------------------------------------
-- ROLLBACK — all five rows verbatim as they stood before this migration
-- ---------------------------------------------------------------------------------------------------
-- All five had sources = ARRAY['https://ballotpedia.org/Wes_Moore'] and value 1.
--
-- BEGIN;
--   UPDATE inform.politician_answers SET value = 1 WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632'
--     AND topic_id IN ('c1ac1330-47f7-44ec-baf3-c913d926b97c','f7e5678d-dadd-4556-a2fc-446e24642ceb');
--   UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Wes_Moore'],
--     reasoning = 'Governor Moore has prioritized expanding childcare access, signing legislation increasing child care subsidies and expanding pre-K programs. His budget included significant investment in early childhood education. He supports universal pre-K and government-funded childcare for working families.'
--     WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';
--   UPDATE inform.politician_context SET sources = ARRAY['https://ballotpedia.org/Wes_Moore'],
--     reasoning = 'Governor Moore''s budgets have consistently proposed raising taxes on wealthy Marylanders and corporations while cutting taxes for working families. He signed legislation creating a child tax credit and expanding the EITC. He has proposed higher corporate minimum taxes and closing tax loopholes to fu...'
--     WHERE politician_id = '21e534c8-c0c0-42f5-b52b-5eb2f246d632' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';
--   -- Fossil Fuels / Voting Rights / Healthcare: re-insert value 1 + the Ballotpedia source with the
--   -- reasonings quoted in full in the migration header above.
-- COMMIT;
--
-- ---------------------------------------------------------------------------------------------------
-- QUEUE THIS LEAVES: Moore's OTHER SIX Ballotpedia-only rows
-- ---------------------------------------------------------------------------------------------------
-- Civil Rights · Homelessness · Redistricting · Same-Sex Marriage · School Vouchers · Trans Athletes.
-- Same defect, out of scope for the recorded 5-row queue. ⚠ Spot-checked against the cited page's raw
-- HTML: "same-sex", "voucher", "homeless" and "independent redistricting" are all ABSENT, and the only
-- redistricting content is about MID-DECADE redistricting in 2026, not an independent commission. Expect
-- these to need the same treatment.
