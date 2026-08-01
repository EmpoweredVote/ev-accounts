-- 1524_correct_characterisation_reasoning.sql
--
-- Correct the REASONING of 9 published rows from the NO_QUOTE characterisation cohort. NOTHING is
-- retired here and NO stance value changes -- only the text a voter reads. In every case the chair is
-- correctly sourced and one unsourced specific is coming out.
--   Rollback record: data/stance-retirement/2026-08-01-characterisation-remedies-rollback.json
--   Review:          data/stance-retirement/2026-08-01-characterisation-review.md
--
-- Same principle as 1516 and 1518: inform.politician_context.reasoning is VOTER-FACING (Citations.jsx
-- renders it under "Why this position?"), so an invented committee, endorsement or quotation is a
-- fabrication on a live candidate card whether or not the stance itself is right. Every replacement
-- string below was verified verbatim on the live page on 2026-08-01 with scripts/read-site.mjs,
-- searching RAW HTML with the haystack size printed.
--
-- 🔴 THE PATTERN WORTH KEEPING. These are not sloppy rows. In each one the topic is genuinely on the
-- page and the chair is right; what went wrong is an ORNAMENT -- a named committee, a named
-- endorsement, a named bill, a named place -- added to make a sound judgement sound better sourced.
-- A named instrument is a rare token, so its absence is real evidence about that sentence and nothing
-- else. That is why these are corrections and not retirements.

BEGIN;

-- John Nagel / Taxes — the site never uses the word "tax".
-- Row said the site praises the Big Beautiful Bill for "tax relief". The page says "real relief".
-- The BBB is genuinely a tax law, so the position stands; the quoted words must be the page's own.
UPDATE inform.politician_context SET reasoning = 'Nagel''s campaign site says "President Trump''s Big Beautiful Bill brought real relief to hardworking Americans, and in Congress, I will fight to end Washington''s reckless spending." The 2025 law is a tax-and-spending measure, so endorsing it alongside a pledge to cut federal spending is a tax-cutting, smaller-government posture. The site''s own phrase is "real relief"; it does not use the word "tax".'
 WHERE politician_id = '2f570d90-c1e2-45bd-811c-243e92884235' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';

-- Caroline Fairly / Religious Freedom — the "Select Committee on Civil Discourse and Freedom of
-- Speech in Higher Education" is absent from the site. The religious-liberty content is strong.
UPDATE inform.politician_context SET reasoning = 'Fairly''s campaign site states: "Freedom is non-negotiable, specifically when it comes to our right to practice our religion, own guns, educate our children, and work and live without government control or interference." It also states that her "conservative values are rooted in her faith". That is an explicit and strongly worded religious-liberty priority.'
 WHERE politician_id = '0dc7e2da-505d-42b6-af05-a2105ce81379' AND topic_id = '6b9ba6d9-1001-43f5-b073-4d37130696fd';

-- Andy Hopper / Religious Freedom — "Ten Commandments" and the SB10/SB11 attribution are absent.
-- Hopper's own plank is more than enough on its own.
UPDATE inform.politician_context SET reasoning = 'Hopper''s campaign site carries a "Preserve Faith and Freedom" plank: "God—not government—is sovereign. Texans must always be free to pray, speak, and live according to their faith without government interference." That is a religious-liberty position oriented to exemptions from government requirements.'
 WHERE politician_id = 'b266c38d-9763-48d4-bcba-7b44adf79ab9' AND topic_id = '6b9ba6d9-1001-43f5-b073-4d37130696fd';

-- Phil M. Hernandez / Childcare — "Child Tax Credit" is absent; the actual named programme is better.
UPDATE inform.politician_context SET reasoning = 'Hernandez''s issues page records that he helped "improve access to the Child Care Subsidy Program", and pledges to "Pass policies that lower costs for families, including in the areas of housing, life-saving prescription drugs, and childcare." That is targeted subsidy support for childcare costs rather than universal public provision.'
 WHERE politician_id = 'e9cd8a4e-9e2b-4962-be21-7a2f68a650ba' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c';

-- Lana Negrete / Public Safety Approach — THREE named things were absent, not one: "Santa Monica
-- Pier", "DART" and "vending" are all MISS. ⚠ The 2,911c page was flagged as a possible JS shell;
-- re-checked 2026-08-01 with raw=2,902c vs body=2,674c, so the page is genuinely that short and the
-- thin-body warning is cleared. The task force itself is verbatim.
UPDATE inform.politician_context SET reasoning = 'Negrete''s site shows her "with the safe and clean task force (Santa Monica Police, Public Works, Fire, and Code Departments)" and quotes her on "working with constituents in the community to activate our parks and public spaces creating a safer and cleaner environment." Convening police alongside code and public-works enforcement is an enforcement-supportive posture on public safety.'
 WHERE politician_id = '5604c5ae-d10d-4ca3-920d-dd3592278777' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';

-- Brooks Landgraf / Climate Change — chair 5 is RIGHT and the row never cited the sentence that earns
-- it. The old reasoning argued from district geography ("represents Odessa... economy built on fossil
-- fuel extraction") and claimed "his campaign website opposes regulation" -- of the chairman of the
-- Environmental Regulation Committee. The words "climate" and "emissions" are MISS site-wide; the
-- chair survives on substance, not vocabulary.
UPDATE inform.politician_context SET reasoning = 'Landgraf''s campaign biography states that as Chairman of the House Environmental Regulation Committee "he has blocked radical Green New Deal–style proposals that would threaten Permian Basin jobs and raise costs for families", and that his legislative record reflects "a clear priority: protecting the Permian Basin''s energy economy". That is rejection of climate-policy proposals on economic-growth grounds. The site does not use the words "climate" or "emissions".'
 WHERE politician_id = '90d94c32-12a1-433a-8ab4-418cd2f05c01' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';

-- Traci Park / Immigration — 🔴 A PARTY PRIOR IN VOTER-FACING TEXT. The removed clause read "As a
-- former Republican and the most conservative council member, her approach reflects...", alongside an
-- argument from a missing sanctuary vote ("sanctuary" is MISS on a page that would not record votes
-- anyway). All THREE of the row's factual claims verify verbatim and are kept. Feeds
-- data/../todos/2026-07-24-party-prior-stance-contamination-audit.md.
UPDATE inform.politician_context SET reasoning = 'Park''s official site states that she "has supported immigrant communities by expanding Know Your Rights education, providing training for employers and workers, and making legal resources available to at-risk residents", and that her office "partnered with organizations such as SALEF (Salvador American Leadership and Education Fund) to deliver medicine and essential goods and provide rental relief and direct financial support to families". These are service and support measures delivered within existing immigration rules, rather than proposals to change immigration levels in either direction.'
 WHERE politician_id = 'd0977350-df68-4cfe-822e-816ba13f9213' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';

-- Luisa de Paula Santos / School Vouchers — TWO invented specifics. "thriving well-resourced community
-- hub" was presented as her platform statement: MISS. "Endorsed by the Cambridge Education
-- Association": CEA appears exactly once on the cited page, as ANOTHER endorsee's résumé line (Betsy
-- Preval) -- a wrong-person attribution. "Our Revolution Cambridge" appears only in a 2017 election
-- retrospective. All five "voucher" hits on the page are HOUSING vouchers, and the page's education
-- commitments include "improving the school choice system", so the "eliminating voucher programs"
-- half of chair 1 is unevidenced; the public-funding half is verbatim and carries the row.
-- ⚠ ALSO A CITATION PROBLEM, left for a later pass: this row cites a third-party endorser site which
-- itself names her own, luisaforschoolcommittee.org. Re-source candidate in the 1512/1519 shape.
UPDATE inform.politician_context SET reasoning = 'The Cambridge Residents Alliance endorsement page states that de Paula Santos "is a paraprofessional and union organizer" and "the only candidate for Cambridge School Committee who is a current MTA member working inside a public school classroom", and that she "will fight for fully funded schools and reallocate resources to student-facing supports." That is a public-schools-first funding commitment. The cited page does not address school vouchers.'
 WHERE politician_id = 'ca2ff1d9-8ebe-4cf2-a804-27d73c58340b' AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de';

-- Ericka Kopp / School Vouchers — same bundled-chair shape. "voucher" and "private school" are MISS
-- across 14,647c; the public-education half is verbatim and stands on its own.
UPDATE inform.politician_context SET reasoning = 'Kopp''s campaign site lists among her priorities "Establishing universal public education from pre-K through post-secondary education, including public community college, university, and trade school/workforce education settings." That is a public-schools-first funding commitment. The site does not mention vouchers or private-school choice.'
 WHERE politician_id = '372a7e8f-5f5f-4ac0-939d-3d2ca9fee97a' AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de';

DO $$
DECLARE v_n int;
BEGIN
  -- Each removed ornament must actually be gone from voter-facing text.
  --
  -- 🔴 SCOPE EVERY CHECK TO (politician_id, topic_id). The first version of this block matched on
  -- politician alone and failed the dry run for two reasons, both worth recording:
  --   1. It caught Traci Park / TAXES, a row this migration does not touch and which contains the
  --      same party-prior phrasing ("As a former Republican operating in a pro-business coalition",
  --      "No direct city-level income tax vote exists"). A real finding, logged as a lead for the
  --      party-prior audit -- NOT silently fixed here, because it is outside the reviewed cohort.
  --   2. It asserted that Kopp's School Vouchers reasoning must not contain "voucher" -- which the
  --      honest replacement sentence "The site does not mention vouchers" necessarily does. An
  --      assertion that forbids naming the topic is a broken assertion, not a finding.
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE (politician_id = '2f570d90-c1e2-45bd-811c-243e92884235' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb' AND reasoning ILIKE '%tax relief%')
      OR (politician_id = '0dc7e2da-505d-42b6-af05-a2105ce81379' AND topic_id = '6b9ba6d9-1001-43f5-b073-4d37130696fd' AND reasoning ILIKE '%Select Committee%')
      OR (politician_id = 'b266c38d-9763-48d4-bcba-7b44adf79ab9' AND topic_id = '6b9ba6d9-1001-43f5-b073-4d37130696fd' AND reasoning ILIKE '%Ten Commandments%')
      OR (politician_id = 'e9cd8a4e-9e2b-4962-be21-7a2f68a650ba' AND topic_id = 'c1ac1330-47f7-44ec-baf3-c913d926b97c' AND reasoning ILIKE '%Child Tax Credit%')
      OR (politician_id = '5604c5ae-d10d-4ca3-920d-dd3592278777' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85' AND reasoning ILIKE '%Pier%')
      OR (politician_id = 'd0977350-df68-4cfe-822e-816ba13f9213' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390' AND reasoning ILIKE '%former Republican%')
      OR (politician_id = 'ca2ff1d9-8ebe-4cf2-a804-27d73c58340b' AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de' AND reasoning ILIKE '%community hub%')
      OR (politician_id = 'ca2ff1d9-8ebe-4cf2-a804-27d73c58340b' AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de' AND reasoning ILIKE '%Cambridge Education Association%')
      OR (politician_id = '372a7e8f-5f5f-4ac0-939d-3d2ca9fee97a' AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de' AND reasoning ILIKE '%eliminating voucher programs%');
  IF v_n <> 0 THEN RAISE EXCEPTION '% corrected row(s) still contain the unsourced specific', v_n; END IF;

  -- Landgraf/Climate must no longer argue from district geography.
  SELECT count(*) INTO v_n FROM inform.politician_context
   WHERE politician_id = '90d94c32-12a1-433a-8ab4-418cd2f05c01'
     AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'
     AND reasoning ILIKE '%Representing oil country%';
  IF v_n <> 0 THEN RAISE EXCEPTION 'Landgraf/Climate still reasons from district geography'; END IF;

  -- No stance value may have moved in this migration.
  SELECT count(*) INTO v_n FROM inform.politician_answers
   WHERE (politician_id, topic_id) IN (
           ('2f570d90-c1e2-45bd-811c-243e92884235','f7e5678d-dadd-4556-a2fc-446e24642ceb'),
           ('0dc7e2da-505d-42b6-af05-a2105ce81379','6b9ba6d9-1001-43f5-b073-4d37130696fd'),
           ('b266c38d-9763-48d4-bcba-7b44adf79ab9','6b9ba6d9-1001-43f5-b073-4d37130696fd'),
           ('e9cd8a4e-9e2b-4962-be21-7a2f68a650ba','c1ac1330-47f7-44ec-baf3-c913d926b97c'),
           ('5604c5ae-d10d-4ca3-920d-dd3592278777','e9ebefcd-c496-45e8-b816-a79f8442ba85'),
           ('90d94c32-12a1-433a-8ab4-418cd2f05c01','f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'),
           ('d0977350-df68-4cfe-822e-816ba13f9213','4e2c69ce-591e-4197-9cd5-7aceff79d390'),
           ('ca2ff1d9-8ebe-4cf2-a804-27d73c58340b','00b95a6a-75db-4521-b523-3326bba938de'),
           ('372a7e8f-5f5f-4ac0-939d-3d2ca9fee97a','00b95a6a-75db-4521-b523-3326bba938de'));
  IF v_n <> 9 THEN RAISE EXCEPTION 'expected 9 rows intact, found %', v_n; END IF;
END $$;

COMMIT;
