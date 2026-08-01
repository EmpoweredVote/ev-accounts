-- 1523_correct_characterisation_chairs.sql
--
-- Correct the STANCE VALUE of 3 published rows whose topic IS genuinely on the cited page, but where
-- the page supports a different chair than the one recorded. Nothing is retired.
--   Rollback record: data/stance-retirement/2026-08-01-characterisation-remedies-rollback.json
--   Review:          data/stance-retirement/2026-08-01-characterisation-review.md
--
-- 🔴 A NEW REMEDY CLASS FOR THIS WORKSTREAM, APPLIED ON EXPLICIT OPERATOR DECISION 2026-08-01.
-- Every previous migration here either repointed a citation (1512-1515, 1519), rewrote reasoning
-- (1516, 1518) or retired a row (1517, 1520, 1521, 1522). This one moves the chair itself.
-- The justification is the same in all three cases: retiring would erase a real, sourced position,
-- and leaving it shows a voter a position the source contradicts. Correcting is the only option that
-- is both honest and complete. Each replacement reasoning below quotes ONLY text verified verbatim
-- on the live page on 2026-08-01 via scripts/read-site.mjs (raw HTML, --no-cache).

BEGIN;

-- ---------------------------------------------------------------------------------------------
-- Clyde Welford / Healthcare — chair 1 -> 2.  🔴 THE URGENT ONE: A FABRICATED QUOTATION.
-- The row read: "explicitly advocates for 'free healthcare' for all Americans, citing Israel's
-- universal free healthcare system as a model." Searched across the WHOLE site (5,357c + 1,618c raw):
-- "free healthcare" MISS, "free health care" MISS, universal MISS, "single payer" MISS,
-- "Medicare for All" MISS. "Israel" occurs twice -- both in a FOREIGN-POLICY plank about Israel's
-- right to exist and a two-state peace, nothing to do with healthcare.
-- inform.politician_context.reasoning is VOTER-FACING (Citations.jsx, "Why this position?"), so
-- quotation marks around words the source never said are a live fabrication on a candidate card.
-- What the site actually says supports chair 2 -- affordable coverage via existing public programs
-- alongside private insurance -- not chair 1's publicly run system.
-- ⚠ His other two rows are sound; they cite /melt-ice.html, a real 3,543c issues page.
UPDATE inform.politician_answers SET value = 2.0
 WHERE politician_id = '4782f3f1-c940-47ad-a3ab-a753b8cd719a' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';
UPDATE inform.politician_context SET reasoning = 'Welford''s campaign site lists "Affordable Health Care" among his priorities: "No family should have to choose between paying for medicine and paying the bills. I will fight to protect Medicare and Social Security, lower prescription drug costs, and expand access to quality health care." That is affordable coverage through existing public programs alongside private insurance, rather than a system paid for and run by the public sector.'
 WHERE politician_id = '4782f3f1-c940-47ad-a3ab-a753b8cd719a' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';

-- ---------------------------------------------------------------------------------------------
-- Brooks Landgraf / Fossil Fuels — chair 5 -> 4.
-- The sentence that carried chair 5 was "No evidence of any environmental restrictions he has
-- supported; he would strongly favor removing restrictions and maximizing extraction." His OWN cited
-- site refutes it: the front page carries HB 3866, which bars chemical-container storage within
-- 2,000 feet of existing homes with TCEQ registration and routine periodic inspections, and his bio
-- describes him as Chairman of the House Environmental Regulation Committee, "a leading voice for
-- regulatory certainty and common-sense standards that protect public health".
-- The pro-extraction half is solid and stays: chair 4, expand drilling permits.
UPDATE inform.politician_answers SET value = 4.0
 WHERE politician_id = '90d94c32-12a1-433a-8ab4-418cd2f05c01' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';
UPDATE inform.politician_context SET reasoning = 'On his campaign site''s issues page Landgraf writes that he "co-authored a bill that repealed burdensome anti-fracking regulations in our state" and that "In the next session, I will continue my efforts to keep energy markets open and unimpeded for oil and gas producers." That is an expansion-oriented position on extraction. He does not call for removing environmental restrictions generally: the same site records his HB 3866, which bars chemical container storage within 2,000 feet of existing homes and adds state registration and periodic inspections, and describes him as Chairman of the House Environmental Regulation Committee.'
 WHERE politician_id = '90d94c32-12a1-433a-8ab4-418cd2f05c01' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';

-- ---------------------------------------------------------------------------------------------
-- Ritesh Tandon / Childcare — chair 4 -> 3.  The row pointed the wrong way down the axis.
-- It claimed affordability "through reducing regulatory burdens on providers ... with no proposal for
-- universal subsidies or broad public investment". "regulatory burden" MISS, daycare MISS; there is no
-- childcare deregulation content on the site at all. What is there is subsidy expansion: platform item
-- 7 proposes to "Expand affordable childcare access ... and provide flexible federal support", and
-- item 1 pledges to "protect child tax support".
-- Chair 3 rather than 2 because the site states NO income threshold and no provider grants, so 3 is
-- the least-overclaiming reading of vague expansionary language.
UPDATE inform.politician_answers SET value = 3.0
 WHERE politician_id = '31e72d49-a541-4855-9262-4f5c4abf7b18' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';
UPDATE inform.politician_context SET reasoning = 'Tandon''s platform item 7, "Make Childcare and Elder-Care More Affordable", proposes to "Expand affordable childcare access, strengthen elder-care support systems, and provide flexible federal support that helps families stay in the workforce", and item 1 pledges to "protect child tax support". That is targeted subsidy and tax-credit support for childcare costs. The site sets out no income threshold and no provider grant or training programme.'
 WHERE politician_id = '31e72d49-a541-4855-9262-4f5c4abf7b18' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';

DO $$
DECLARE v_n int;
BEGIN
  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE (politician_id = '4782f3f1-c940-47ad-a3ab-a753b8cd719a' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529' AND value = 2.0)
      OR (politician_id = '90d94c32-12a1-433a-8ab4-418cd2f05c01' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570' AND value = 4.0)
      OR (politician_id = '31e72d49-a541-4855-9262-4f5c4abf7b18' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c' AND value = 3.0);
  IF v_n <> 3 THEN RAISE EXCEPTION 'expected 3 corrected chairs, found %', v_n; END IF;

  -- The old fabricated strings must be gone from voter-facing text.
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE politician_id = '4782f3f1-c940-47ad-a3ab-a753b8cd719a'
     AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'
     AND (reasoning ILIKE '%free healthcare%' OR reasoning ILIKE '%Israel%');
  IF v_n <> 0 THEN RAISE EXCEPTION 'Welford reasoning still contains the fabricated quotation'; END IF;

  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE politician_id = '90d94c32-12a1-433a-8ab4-418cd2f05c01'
     AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570'
     AND reasoning ILIKE '%No evidence of any environmental restrictions%';
  IF v_n <> 0 THEN RAISE EXCEPTION 'Landgraf reasoning still contains the refuted sentence'; END IF;
END $$;

COMMIT;
