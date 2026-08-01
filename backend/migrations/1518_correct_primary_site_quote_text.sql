-- 1518_correct_primary_site_quote_text.sql
--
-- Correct the QUOTATIONS in 16 published stance rows whose cited campaign site supports the
-- claim but does not contain the words the row put in quotation marks. NOTHING IS RETIRED HERE
-- and no stance VALUE changes -- only the text a voter reads.
--   Rollback record: data/stance-retirement/2026-08-01-quote-corrections-rollback.json
--   Proposals:       data/stance-retirement/2026-08-01-quote-correction-proposals.json
--   Reading queue:   data/stance-retirement/2026-08-01-quote-corrections.md
--
-- WHY THIS MATTERS MORE THAN THE GATE COUNTS. inform.politician_context.reasoning is VOTER-FACING
-- (Citations.jsx renders it under "Why this position?"). Quotation marks around words the source
-- never said are a fabricated quote on a live candidate card, whether or not the stance is right.
--
-- 🔴 THIS IS A CORRECTION PASS, NOT A RETIREMENT PASS. Every row below KEEPS its stance and its
-- source; all that changes is that the quoted words are now the page's own. Each replacement
-- string was re-fetched and matched against the live site by
-- scripts/emit-quote-correction-migration.mjs, which refuses to emit if any string is absent.

-- Troy Slaten / Court Access: quoted 'money should not be a barrier to justice' — the page says 'never', not 'not'
-- Jamie Joyce / Deportation: quoted 'Get ICE off the Streets' — the page says 'off our streets'
-- Jamie Joyce / Immigration: quoted 'Get ICE off the Streets' — the page says 'off our streets'
-- Shannon Taylor / Medicare/aid: quoted 'protect Social Security and Medicare for seniors' (order reversed on the page) and a second quote about Medicare negotiating drug prices that is NOT on the site at all
-- Derek Merrin / School Vouchers: quoted 'Expand school choice options' as a listed platform priority; the page states it as a past accomplishment in different words
-- Pedro DeSouza / Campaign Finance: quoted 'No AIPAC Money. No Foreign-Interest Lobby Money,' — only the second sentence is on the page; the first is the row's own compression of 'Dissolve AIPAC'
-- Ken Vaz / Immigration: named the plank 'Immigration and Worker Fairness' and quoted two lines that are paraphrases; the plank has a different title and different wording
-- Ken Vaz / Abortion: quoted 'abortion exceptions in cases of rape, incest, fatal fetal abnormalities, and when the life of the mother is at risk' — the page says 'anomalies' and frames the list as protections FOR access
-- Ken Vaz / Taxes: quoted 'the carried interest loophole that lets Wall Street executives pay lower tax rates' — a paraphrase; the page names investment managers, not Wall Street executives
-- Ken Vaz / Healthcare: quoted 'transparency and competition in healthcare markets' — a paraphrase of two separate lines in the plank
-- Jamie Davis / Taxes: quoted 'Roll back the 2025 tax law' — the page says 'Roll back portions of' and names what it funds
-- Rusty MacLachlan / Public Safety Approach: quoted 'defunding police initiatives' and 'committed to supporting officers' — neither phrase is on the page, which states the position in one sentence
-- Missi Hesketh / Healthcare: quoted 'Healthcare For All who Want It' — the page says 'Medicare for all who want it', which is the public-option phrasing the reasoning actually relies on
-- Scott Schwab / Deportation: quoted 'enforce immigration laws in cooperation with federal administration' — a paraphrase; also asserted a criminal-history priority the page does not state
-- Shannon Taylor / Social Security: quoted 'fight to protect Social Security and Medicare for seniors who have paid into them their entire adult life' — the trailing clause appears nowhere on the site
-- Carlton E. Bowen / Taxes: quoted 'end wasteful spending habits' and 'restore policies that reward productive work and saving' — neither phrase is on the site

BEGIN;

-- Troy Slaten / Court Access — https://troyslatenforjudge.com
UPDATE inform.politician_context SET reasoning = 'Slaten''s campaign site quotes him saying "Money should never be a barrier to justice. Empathy is essential in an adversary system, where each side is given an opportunity to present its best arguments." That is a direct position against wealth-based access disparities in the court system.'
 WHERE politician_id = 'e66de256-31e6-45a3-b3a8-a01ade5b79ec' AND topic_id = '9d45acaf-1ba4-4cb8-95e1-5ed985223b91';

-- Jamie Joyce / Deportation — https://jamiejoyce.com
UPDATE inform.politician_context SET reasoning = 'Joyce''s MAD Act platform lists "Get ICE off our streets" among its titles, indicating opposition to broad immigration enforcement sweeps in communities. This positions her against mass deportation and toward protecting long-term residents, consistent with value 2 (deport only serious violent criminals).'
 WHERE politician_id = '580f3720-7990-4a2b-a417-78d90012db93' AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac';

-- Jamie Joyce / Immigration — https://jamiejoyce.com
UPDATE inform.politician_context SET reasoning = 'Joyce''s MAD Act platform calls to "Get ICE off our streets" — opposing community-level immigration enforcement. Her position supports keeping residents regardless of status, consistent with value 2 (keep legal immigration open, most residents use services regardless of status).'
 WHERE politician_id = '580f3720-7990-4a2b-a417-78d90012db93' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';

-- Shannon Taylor / Medicare/aid — https://shannontaylorva.com
UPDATE inform.politician_context SET reasoning = 'Taylor''s campaign site pledges to "Fight to protect Medicare and Social Security for seniors" and to "Lower the cost of prescription drugs." The framing is protecting and improving current programs rather than expanding eligibility age or extending Medicare to all. This aligns with improving current programs while controlling costs.'
 WHERE politician_id = '4b3850c4-debb-4b92-a796-3cf15cf31e80' AND topic_id = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b';

-- Derek Merrin / School Vouchers — https://www.derekmerrin.com
UPDATE inform.politician_context SET reasoning = 'Merrin''s campaign site states that he "successfully led efforts to cut the state''s income tax, reduce regulations, and expand school choice." That is a record of broadening school-choice eligibility, consistent with broad eligibility for school choice while not advocating universal vouchers for all students regardless of circumstance.'
 WHERE politician_id = '4932ca8c-39b5-45a9-8376-cbdbb275d86a' AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de';

-- Pedro DeSouza / Campaign Finance — https://www.voteforpedrori.com
UPDATE inform.politician_context SET reasoning = 'His platform includes a standalone plank, "Dissolve AIPAC. No Foreign-Interest Lobby Money," under which he pledges "I will not take money from AIPAC, foreign-agent PACs, or lobbying groups that put another country''s interests ahead of the American people." That explicit rejection of PAC and lobby money signals support for tightly restricting corporate and dark-money influence, matching stance 2 (strictly limit corporate donations and dark money groups).'
 WHERE politician_id = '19f0df53-1b79-4375-825b-d9350ab92fba' AND topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d';

-- Ken Vaz / Immigration — https://kenvazforwa.com
UPDATE inform.politician_context SET reasoning = 'Vaz''s platform plank "Border Security, Immigration Reform, and American Workers" calls to "Secure the border, enforce immigration law, protect American workers, preserve lawful family unity, and require immigration agencies to operate constitutionally and accountably." He also proposes limiting comprehensive federal benefits to eligible U.S. citizens and qualified lawful residents. That is an enforcement-first posture paired with explicit constitutional limits.'
 WHERE politician_id = '6e357a07-71c7-4654-826a-1e638925777e' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';

-- Ken Vaz / Abortion — https://kenvazforwa.com
UPDATE inform.politician_context SET reasoning = 'Vaz''s platform plank "Abortion and Federalism" would "Establish federal legal protections for abortion access in cases of rape, incest, a life-threatening medical emergency involving the mother, and fatal fetal anomalies," while leaving policy outside those exceptions to the states. Guaranteeing access only in enumerated cases and leaving the remainder to state restriction matches a restrict-with-exceptions position.'
 WHERE politician_id = '6e357a07-71c7-4654-826a-1e638925777e' AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f';

-- Ken Vaz / Taxes — https://kenvazforwa.com
UPDATE inform.politician_context SET reasoning = 'Vaz''s platform calls to "Lower taxes on working- and middle-class Americans" and to "End preferential carried-interest treatment that allows some investment managers to pay capital-gains rates on compensation tied to investment profits." That combines targeted relief with closing a preferential rate rather than a broad cut for all income levels.'
 WHERE politician_id = '6e357a07-71c7-4654-826a-1e638925777e' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';

-- Ken Vaz / Healthcare — https://kenvazforwa.com
UPDATE inform.politician_context SET reasoning = 'Vaz''s "Affordable and Accessible Health Care" plank would "Require meaningful price transparency for hospitals, prescription drugs, and medical equipment" and "Create affordable bridge coverage and faster eligibility reassessments for workers who lose employer-sponsored insurance and cannot reasonably afford COBRA." That is market-based reform plus closing coverage gaps between jobs, rather than a new government program.'
 WHERE politician_id = '6e357a07-71c7-4654-826a-1e638925777e' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';

-- Jamie Davis / Taxes — https://jamieforlouisiana.com
UPDATE inform.politician_context SET reasoning = 'Davis''s campaign site calls to "Roll back portions of the 2025 tax law that added as much as $4 trillion to the debt to cut taxes for the billionaires." Reversing an upper-income tax cut to fund relief for working families maps to value 2 (moderately raise taxes on wealthy people and large companies to fund existing services), not value 1 (significantly raise taxes across the board).'
 WHERE politician_id = '970665b9-a3c1-41b0-9c14-bc954a9a667b' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';

-- Rusty MacLachlan / Public Safety Approach — https://rustymac.com
UPDATE inform.politician_context SET reasoning = 'Under a "Supporting Our Police" heading, MacLachlan''s campaign site states "I will never support initiatives to defund the police or limit their capabilities to arrest criminals." That places him with increasing police staffing, equipment and pay to improve response times and deter crime.'
 WHERE politician_id = 'cd65d355-e307-4ac7-a8b1-5b1638752c89' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';

-- Missi Hesketh / Healthcare — https://www.missiformo.com
UPDATE inform.politician_context SET reasoning = 'Hesketh''s campaign site lists "Medicare for all who want it" under her "Make Healthcare Work" priority, alongside veterans'' healthcare access, rural hospital stabilization and Medicare drug-price negotiation. Opt-in Medicare is a public option expanding access alongside private insurance rather than mandating a single-payer system.'
 WHERE politician_id = 'bc3cfeaa-42b0-4feb-8bd3-5957280917bf' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';

-- Scott Schwab / Deportation — https://www.scottschwab.com
UPDATE inform.politician_context SET reasoning = 'Schwab''s gubernatorial campaign site states that as governor he will "work with the Trump administration on enforcing our immigration laws," alongside fully funding public safety. That is an enforcement-first posture aligned with deporting those without legal status; the site does not set out how enforcement would be prioritised.'
 WHERE politician_id = 'e752a957-c776-4942-9aae-63ebf23174ac' AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac';

-- Shannon Taylor / Social Security — https://shannontaylorva.com
UPDATE inform.politician_context SET reasoning = 'Taylor''s campaign site pledges to "Fight to protect Medicare and Social Security for seniors." The framing is protective rather than expansionary — the site does not mention raising the income cap, expanding benefits, or increasing payroll taxes. This aligns with making small adjustments to keep Social Security stable.'
 WHERE politician_id = '4b3850c4-debb-4b92-a796-3cf15cf31e80' AND topic_id = '87d20824-a6e9-407b-983c-65440084a0ab';

-- Carlton E. Bowen / Taxes — https://bowenforcongress.com
UPDATE inform.politician_context SET reasoning = 'Bowen''s campaign site makes the national debt its central issue: "Washington keeps spending money it does not have, then tells American families to absorb the higher costs caused by irresponsible government," and he pledges to "fight for fiscal responsibility, honest budgeting, and a Congress that remembers it is not authorized to spend without limit." That is a spending-discipline message. ⚠ The site states no tax-rate position of any kind, so the chair here rests on inference from fiscal conservatism rather than on a stated tax plan.'
 WHERE politician_id = '6eccd92f-958a-4ee5-8eb6-f9ca48e41af2' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';

DO $$
DECLARE
  v_bad int;
BEGIN
  -- Every row must now carry its corrected text, and none may be left with the old wording.
  SELECT count(*) INTO v_bad FROM inform.politician_context
   WHERE politician_id = 'e66de256-31e6-45a3-b3a8-a01ade5b79ec' AND topic_id = '9d45acaf-1ba4-4cb8-95e1-5ed985223b91'
     AND reasoning IS DISTINCT FROM 'Slaten''s campaign site quotes him saying "Money should never be a barrier to justice. Empathy is essential in an adversary system, where each side is given an opportunity to present its best arguments." That is a direct position against wealth-based access disparities in the court system.';
  IF v_bad <> 0 THEN RAISE EXCEPTION 'Troy Slaten / Court Access not corrected'; END IF;
  SELECT count(*) INTO v_bad FROM inform.politician_context
   WHERE politician_id = '580f3720-7990-4a2b-a417-78d90012db93' AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac'
     AND reasoning IS DISTINCT FROM 'Joyce''s MAD Act platform lists "Get ICE off our streets" among its titles, indicating opposition to broad immigration enforcement sweeps in communities. This positions her against mass deportation and toward protecting long-term residents, consistent with value 2 (deport only serious violent criminals).';
  IF v_bad <> 0 THEN RAISE EXCEPTION 'Jamie Joyce / Deportation not corrected'; END IF;
  SELECT count(*) INTO v_bad FROM inform.politician_context
   WHERE politician_id = '580f3720-7990-4a2b-a417-78d90012db93' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'
     AND reasoning IS DISTINCT FROM 'Joyce''s MAD Act platform calls to "Get ICE off our streets" — opposing community-level immigration enforcement. Her position supports keeping residents regardless of status, consistent with value 2 (keep legal immigration open, most residents use services regardless of status).';
  IF v_bad <> 0 THEN RAISE EXCEPTION 'Jamie Joyce / Immigration not corrected'; END IF;
  SELECT count(*) INTO v_bad FROM inform.politician_context
   WHERE politician_id = '4b3850c4-debb-4b92-a796-3cf15cf31e80' AND topic_id = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'
     AND reasoning IS DISTINCT FROM 'Taylor''s campaign site pledges to "Fight to protect Medicare and Social Security for seniors" and to "Lower the cost of prescription drugs." The framing is protecting and improving current programs rather than expanding eligibility age or extending Medicare to all. This aligns with improving current programs while controlling costs.';
  IF v_bad <> 0 THEN RAISE EXCEPTION 'Shannon Taylor / Medicare/aid not corrected'; END IF;
  SELECT count(*) INTO v_bad FROM inform.politician_context
   WHERE politician_id = '4932ca8c-39b5-45a9-8376-cbdbb275d86a' AND topic_id = '00b95a6a-75db-4521-b523-3326bba938de'
     AND reasoning IS DISTINCT FROM 'Merrin''s campaign site states that he "successfully led efforts to cut the state''s income tax, reduce regulations, and expand school choice." That is a record of broadening school-choice eligibility, consistent with broad eligibility for school choice while not advocating universal vouchers for all students regardless of circumstance.';
  IF v_bad <> 0 THEN RAISE EXCEPTION 'Derek Merrin / School Vouchers not corrected'; END IF;
  SELECT count(*) INTO v_bad FROM inform.politician_context
   WHERE politician_id = '19f0df53-1b79-4375-825b-d9350ab92fba' AND topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d'
     AND reasoning IS DISTINCT FROM 'His platform includes a standalone plank, "Dissolve AIPAC. No Foreign-Interest Lobby Money," under which he pledges "I will not take money from AIPAC, foreign-agent PACs, or lobbying groups that put another country''s interests ahead of the American people." That explicit rejection of PAC and lobby money signals support for tightly restricting corporate and dark-money influence, matching stance 2 (strictly limit corporate donations and dark money groups).';
  IF v_bad <> 0 THEN RAISE EXCEPTION 'Pedro DeSouza / Campaign Finance not corrected'; END IF;
  SELECT count(*) INTO v_bad FROM inform.politician_context
   WHERE politician_id = '6e357a07-71c7-4654-826a-1e638925777e' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'
     AND reasoning IS DISTINCT FROM 'Vaz''s platform plank "Border Security, Immigration Reform, and American Workers" calls to "Secure the border, enforce immigration law, protect American workers, preserve lawful family unity, and require immigration agencies to operate constitutionally and accountably." He also proposes limiting comprehensive federal benefits to eligible U.S. citizens and qualified lawful residents. That is an enforcement-first posture paired with explicit constitutional limits.';
  IF v_bad <> 0 THEN RAISE EXCEPTION 'Ken Vaz / Immigration not corrected'; END IF;
  SELECT count(*) INTO v_bad FROM inform.politician_context
   WHERE politician_id = '6e357a07-71c7-4654-826a-1e638925777e' AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f'
     AND reasoning IS DISTINCT FROM 'Vaz''s platform plank "Abortion and Federalism" would "Establish federal legal protections for abortion access in cases of rape, incest, a life-threatening medical emergency involving the mother, and fatal fetal anomalies," while leaving policy outside those exceptions to the states. Guaranteeing access only in enumerated cases and leaving the remainder to state restriction matches a restrict-with-exceptions position.';
  IF v_bad <> 0 THEN RAISE EXCEPTION 'Ken Vaz / Abortion not corrected'; END IF;
  SELECT count(*) INTO v_bad FROM inform.politician_context
   WHERE politician_id = '6e357a07-71c7-4654-826a-1e638925777e' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND reasoning IS DISTINCT FROM 'Vaz''s platform calls to "Lower taxes on working- and middle-class Americans" and to "End preferential carried-interest treatment that allows some investment managers to pay capital-gains rates on compensation tied to investment profits." That combines targeted relief with closing a preferential rate rather than a broad cut for all income levels.';
  IF v_bad <> 0 THEN RAISE EXCEPTION 'Ken Vaz / Taxes not corrected'; END IF;
  SELECT count(*) INTO v_bad FROM inform.politician_context
   WHERE politician_id = '6e357a07-71c7-4654-826a-1e638925777e' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'
     AND reasoning IS DISTINCT FROM 'Vaz''s "Affordable and Accessible Health Care" plank would "Require meaningful price transparency for hospitals, prescription drugs, and medical equipment" and "Create affordable bridge coverage and faster eligibility reassessments for workers who lose employer-sponsored insurance and cannot reasonably afford COBRA." That is market-based reform plus closing coverage gaps between jobs, rather than a new government program.';
  IF v_bad <> 0 THEN RAISE EXCEPTION 'Ken Vaz / Healthcare not corrected'; END IF;
  SELECT count(*) INTO v_bad FROM inform.politician_context
   WHERE politician_id = '970665b9-a3c1-41b0-9c14-bc954a9a667b' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND reasoning IS DISTINCT FROM 'Davis''s campaign site calls to "Roll back portions of the 2025 tax law that added as much as $4 trillion to the debt to cut taxes for the billionaires." Reversing an upper-income tax cut to fund relief for working families maps to value 2 (moderately raise taxes on wealthy people and large companies to fund existing services), not value 1 (significantly raise taxes across the board).';
  IF v_bad <> 0 THEN RAISE EXCEPTION 'Jamie Davis / Taxes not corrected'; END IF;
  SELECT count(*) INTO v_bad FROM inform.politician_context
   WHERE politician_id = 'cd65d355-e307-4ac7-a8b1-5b1638752c89' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'
     AND reasoning IS DISTINCT FROM 'Under a "Supporting Our Police" heading, MacLachlan''s campaign site states "I will never support initiatives to defund the police or limit their capabilities to arrest criminals." That places him with increasing police staffing, equipment and pay to improve response times and deter crime.';
  IF v_bad <> 0 THEN RAISE EXCEPTION 'Rusty MacLachlan / Public Safety Approach not corrected'; END IF;
  SELECT count(*) INTO v_bad FROM inform.politician_context
   WHERE politician_id = 'bc3cfeaa-42b0-4feb-8bd3-5957280917bf' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'
     AND reasoning IS DISTINCT FROM 'Hesketh''s campaign site lists "Medicare for all who want it" under her "Make Healthcare Work" priority, alongside veterans'' healthcare access, rural hospital stabilization and Medicare drug-price negotiation. Opt-in Medicare is a public option expanding access alongside private insurance rather than mandating a single-payer system.';
  IF v_bad <> 0 THEN RAISE EXCEPTION 'Missi Hesketh / Healthcare not corrected'; END IF;
  SELECT count(*) INTO v_bad FROM inform.politician_context
   WHERE politician_id = 'e752a957-c776-4942-9aae-63ebf23174ac' AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac'
     AND reasoning IS DISTINCT FROM 'Schwab''s gubernatorial campaign site states that as governor he will "work with the Trump administration on enforcing our immigration laws," alongside fully funding public safety. That is an enforcement-first posture aligned with deporting those without legal status; the site does not set out how enforcement would be prioritised.';
  IF v_bad <> 0 THEN RAISE EXCEPTION 'Scott Schwab / Deportation not corrected'; END IF;
  SELECT count(*) INTO v_bad FROM inform.politician_context
   WHERE politician_id = '4b3850c4-debb-4b92-a796-3cf15cf31e80' AND topic_id = '87d20824-a6e9-407b-983c-65440084a0ab'
     AND reasoning IS DISTINCT FROM 'Taylor''s campaign site pledges to "Fight to protect Medicare and Social Security for seniors." The framing is protective rather than expansionary — the site does not mention raising the income cap, expanding benefits, or increasing payroll taxes. This aligns with making small adjustments to keep Social Security stable.';
  IF v_bad <> 0 THEN RAISE EXCEPTION 'Shannon Taylor / Social Security not corrected'; END IF;
  SELECT count(*) INTO v_bad FROM inform.politician_context
   WHERE politician_id = '6eccd92f-958a-4ee5-8eb6-f9ca48e41af2' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'
     AND reasoning IS DISTINCT FROM 'Bowen''s campaign site makes the national debt its central issue: "Washington keeps spending money it does not have, then tells American families to absorb the higher costs caused by irresponsible government," and he pledges to "fight for fiscal responsibility, honest budgeting, and a Congress that remembers it is not authorized to spend without limit." That is a spending-discipline message. ⚠ The site states no tax-rate position of any kind, so the chair here rests on inference from fiscal conservatism rather than on a stated tax plan.';
  IF v_bad <> 0 THEN RAISE EXCEPTION 'Carlton E. Bowen / Taxes not corrected'; END IF;

  -- No corrected row may have lost its sources or its stance.
  SELECT count(*) INTO v_bad FROM inform.politician_context pc
    JOIN unnest(ARRAY[
      'e66de256-31e6-45a3-b3a8-a01ade5b79ec'::uuid,
      '580f3720-7990-4a2b-a417-78d90012db93'::uuid,
      '580f3720-7990-4a2b-a417-78d90012db93'::uuid,
      '4b3850c4-debb-4b92-a796-3cf15cf31e80'::uuid,
      '4932ca8c-39b5-45a9-8376-cbdbb275d86a'::uuid,
      '19f0df53-1b79-4375-825b-d9350ab92fba'::uuid,
      '6e357a07-71c7-4654-826a-1e638925777e'::uuid,
      '6e357a07-71c7-4654-826a-1e638925777e'::uuid,
      '6e357a07-71c7-4654-826a-1e638925777e'::uuid,
      '6e357a07-71c7-4654-826a-1e638925777e'::uuid,
      '970665b9-a3c1-41b0-9c14-bc954a9a667b'::uuid,
      'cd65d355-e307-4ac7-a8b1-5b1638752c89'::uuid,
      'bc3cfeaa-42b0-4feb-8bd3-5957280917bf'::uuid,
      'e752a957-c776-4942-9aae-63ebf23174ac'::uuid,
      '4b3850c4-debb-4b92-a796-3cf15cf31e80'::uuid,
      '6eccd92f-958a-4ee5-8eb6-f9ca48e41af2'::uuid
    ], ARRAY[
      '9d45acaf-1ba4-4cb8-95e1-5ed985223b91'::uuid,
      '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid,
      '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid,
      'cab61e8a-64fe-4bbd-bc08-fe9914d0091b'::uuid,
      '00b95a6a-75db-4521-b523-3326bba938de'::uuid,
      '92730f69-ae57-401c-8ad1-2d07834a895d'::uuid,
      '4e2c69ce-591e-4197-9cd5-7aceff79d390'::uuid,
      'af2fdfd6-02c4-49df-b09c-cf8536f4773f'::uuid,
      'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid,
      'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid,
      'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid,
      'e9ebefcd-c496-45e8-b816-a79f8442ba85'::uuid,
      'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529'::uuid,
      '44905f3b-e105-4f6c-afc7-5d223813dbac'::uuid,
      '87d20824-a6e9-407b-983c-65440084a0ab'::uuid,
      'f7e5678d-dadd-4556-a2fc-446e24642ceb'::uuid
    ]) AS k(pid, tid) ON pc.politician_id = k.pid AND pc.topic_id = k.tid
   WHERE cardinality(pc.sources) = 0;
  IF v_bad <> 0 THEN RAISE EXCEPTION 'a corrected row lost its sources'; END IF;
END $$;

COMMIT;
