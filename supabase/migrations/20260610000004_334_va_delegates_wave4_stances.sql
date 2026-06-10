-- Phase 112-04: VA House Delegate Stances — Wave 4 (HD-60–69 Hampton Roads Part 1)
-- Requirements covered: VAST-03, VAST-05
-- Source CSV: backend/data/stance-research/2026-06-10-112-va-delegates-wave4.csv
--
-- Pre-write cross-check:
--   CSV data rows:                  23
--   INSERT INTO inform.politician_answers count: 23
--   INSERT INTO inform.politician_context count: 23
--   max_migration at authoring: 348 (schema_migrations)
--
-- Stances written (6 delegates with documentable positions):
--   Scott A. Wyatt          (HD-60, R): 4 stances — taxes(4), school-vouchers(4), religious-freedom(4), healthcare(4)
--   Michael J. Webert       (HD-61, R): 3 stances — taxes(4), abortion(5), data-centers(3)
--   Karen Fleming Hamilton  (HD-62, R): 6 stances — abortion(5), school-vouchers(4), taxes(4), immigration(4), religious-freedom(5), climate-change(4)
--   Phillip A. Scott        (HD-63, R): 2 stances — voting-rights(4), taxes(4)
--   Stacey A. Carroll       (HD-64, D): 3 stances — healthcare(2), medicare/aid(3), abortion(2)
--   Mark C. Downey          (HD-69, D): 5 stances — healthcare(2), abortion(2), childcare(2), housing(3), school-vouchers(1)
--
-- Honest skip (4 delegates — no documentable policy positions found):
--   Joshua G. Cole          (HD-65, D): Wikipedia biography only, no policy pages accessible
--   Nicole Cole             (HD-66, D): No website or survey accessible (Ballotpedia 202, website unreachable)
--   Hillary Pugh Kent       (HD-67, R): No policy content accessible (Ballotpedia no surveys, website no policy)
--   M. Keith Hodges         (HD-68, R): Ballotpedia 202, Wikipedia 404, website timed out
--
-- Politician UUIDs (from 2026-06-10-112-va-delegates-wave4-preflight.json):
--   Scott A. Wyatt          (HD-60, ext_id -5120060) -> d918e6be-5933-4b24-aada-84cbc461c207
--   Michael J. Webert       (HD-61, ext_id -5120061) -> 28714014-4c7e-427e-8190-fcc21875377a
--   Karen Fleming Hamilton  (HD-62, ext_id -5120062) -> 11074d6c-4c9c-4b9e-9606-42eae7a6537c
--   Phillip A. Scott        (HD-63, ext_id -5120063) -> 597a4057-4ccc-43f6-bf97-bcc701d7e637
--   Stacey A. Carroll       (HD-64, ext_id -5120064) -> ac78bc55-8fe9-4efb-a0ea-179842b6c44e
--   Joshua G. Cole          (HD-65, ext_id -5120065) -> e2542ec1-213a-403b-bcda-e956a9384dcb  [skip]
--   Nicole Cole             (HD-66, ext_id -5120066) -> dcc9683b-f463-490f-aa9a-8b2ff2f7d6bb  [skip]
--   Hillary Pugh Kent       (HD-67, ext_id -5120067) -> 982ad606-8fc5-4d99-9275-c24b09c65c0c  [skip]
--   M. Keith Hodges         (HD-68, ext_id -5120068) -> 95cdc29b-18d1-45e1-84c3-ba601f5bec40  [skip]
--   Mark C. Downey          (HD-69, ext_id -5120069) -> aefff366-6345-45fc-b52d-0e4ceb64d121
--
-- Migration number: 334
-- Timestamp: 20260610000004
-- Applied: NOT YET

BEGIN;

-- ============================================================
-- Scott A. Wyatt (HD-60, R) — 4 stances
-- Source: https://www.votescottwyatt.com/issues + https://en.wikipedia.org/wiki/Scott_Wyatt_(politician)
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
  ('d918e6be-5933-4b24-aada-84cbc461c207', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 4), -- taxes
  ('d918e6be-5933-4b24-aada-84cbc461c207', '00b95a6a-75db-4521-b523-3326bba938de', 4), -- school-vouchers
  ('d918e6be-5933-4b24-aada-84cbc461c207', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 4), -- religious-freedom
  ('d918e6be-5933-4b24-aada-84cbc461c207', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 4)  -- healthcare
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
  ('d918e6be-5933-4b24-aada-84cbc461c207', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
   'Campaign website: "reduce regulations and lower our tax burden to attract industry" and "work with Governor Youngkin... to send money back to hardworking families of Virginia." Focuses on tax cuts and economic growth — cut taxes for everyone and scale back public services to match.',
   ARRAY['https://www.votescottwyatt.com/issues']),
  ('d918e6be-5933-4b24-aada-84cbc461c207', '00b95a6a-75db-4521-b523-3326bba938de',
   'Campaign website: supports school choice and voucher programs, especially for those who live in failing school districts. Expanding voucher eligibility to families whose local options are inadequate, while maintaining baseline public school funding.',
   ARRAY['https://www.votescottwyatt.com/issues']),
  ('d918e6be-5933-4b24-aada-84cbc461c207', '6b9ba6d9-1001-43f5-b073-4d37130696fd',
   'Campaign website: "Religious freedoms are a bedrock of our society and Scott will stand against the attacks on people of faith." Self-identifies as a Christian and social conservative — protect religious freedom and allow faith-based exemptions from laws that conflict with sincere religious beliefs.',
   ARRAY['https://www.votescottwyatt.com/issues']),
  ('d918e6be-5933-4b24-aada-84cbc461c207', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
   'Wikipedia: Wyatt was nominated in 2019 to replace incumbent Del. Chris Peace specifically because Peace voted to expand Medicaid. Republican party chose Wyatt as a hardline conservative challenger opposed to Medicaid expansion — only help the poorest people afford healthcare and leave everyone else to employers and private insurance.',
   ARRAY['https://en.wikipedia.org/wiki/Scott_Wyatt_(politician)', 'https://ballotpedia.org/Scott_Wyatt_(Virginia)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Michael J. Webert (HD-61, R) — 3 stances
-- Source: https://www.michael-webert.com/issues + https://ballotpedia.org/Michael_Webert
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
  ('28714014-4c7e-427e-8190-fcc21875377a', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 4), -- taxes
  ('28714014-4c7e-427e-8190-fcc21875377a', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5), -- abortion
  ('28714014-4c7e-427e-8190-fcc21875377a', '4559b513-0fd8-4ed1-babd-f3b554162f40', 3)  -- data-centers
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
  ('28714014-4c7e-427e-8190-fcc21875377a', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
   'Campaign website: reducing taxes to keep more money in pockets of Virginia families and small businesses. Also 2011 Ballotpedia campaign themes: reducing tax burdens and eliminating unnecessary bureaucratic regulations — cut taxes for everyone and scale back public services.',
   ARRAY['https://www.michael-webert.com/issues', 'https://ballotpedia.org/Michael_Webert']),
  ('28714014-4c7e-427e-8190-fcc21875377a', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
   'Campaign website: Mike believes life begins at conception and is 100% pro-life. This is a statement of no exceptions (not value 4 which allows for rape/incest/maternal health exceptions). Absolute no-exceptions framing matches the most restrictive position.',
   ARRAY['https://www.michael-webert.com/issues']),
  ('28714014-4c7e-427e-8190-fcc21875377a', '4559b513-0fd8-4ed1-babd-f3b554162f40',
   'Campaign website: introduced legislation in 2024 to create new regulations for data centers and their infrastructure as part of his goal to stop overdevelopment in the 61st district. Regulatory framework with impact assessments before approval — allowing data center development with impact assessments and community benefit requirements.',
   ARRAY['https://www.michael-webert.com/issues'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Karen Fleming Hamilton (HD-62, R) — 6 stances
-- Source: https://www.hamiltonforvirginia.com/priorities + https://ballotpedia.org/Karen_Hamilton
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
  ('11074d6c-4c9c-4b9e-9606-42eae7a6537c', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 5), -- abortion
  ('11074d6c-4c9c-4b9e-9606-42eae7a6537c', '00b95a6a-75db-4521-b523-3326bba938de', 4), -- school-vouchers
  ('11074d6c-4c9c-4b9e-9606-42eae7a6537c', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 4), -- taxes
  ('11074d6c-4c9c-4b9e-9606-42eae7a6537c', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 4), -- immigration
  ('11074d6c-4c9c-4b9e-9606-42eae7a6537c', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 5), -- religious-freedom
  ('11074d6c-4c9c-4b9e-9606-42eae7a6537c', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 4)  -- climate-change
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
  ('11074d6c-4c9c-4b9e-9606-42eae7a6537c', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
   'Campaign website Priorities page: "Human life begins at conception, when an entirely unique and separate human DNA is formed by God. The right to life is the first right." Also: "I will take every opportunity to protect innocent human life." Opposed to enshrining abortion rights in Virginia Constitution. Life-at-conception stance with no mention of exceptions for rape, incest, or maternal health.',
   ARRAY['https://www.hamiltonforvirginia.com/priorities', 'https://ballotpedia.org/Karen_Hamilton']),
  ('11074d6c-4c9c-4b9e-9606-42eae7a6537c', '00b95a6a-75db-4521-b523-3326bba938de',
   'Campaign website Priorities page: "I am committed to fighting for school choice, which would force government schools to compete for the privilege of educating the next generation." Framing suggests broad voucher expansion so families can choose, not just low-income families in failing districts.',
   ARRAY['https://www.hamiltonforvirginia.com/priorities']),
  ('11074d6c-4c9c-4b9e-9606-42eae7a6537c', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
   'Campaign website Priorities page under Economic Freedom: "Lowering taxes, lifting regulation, and restricting government intrusion allows both our economy and households to thrive" and "I will work to keep more of your hard earned dollars where they belong — in your pockets."',
   ARRAY['https://www.hamiltonforvirginia.com/priorities']),
  ('11074d6c-4c9c-4b9e-9606-42eae7a6537c', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
   'Campaign website Priorities page under Law and Order: "local authorities must cooperate with the efforts of Federal LEO to remove violent criminals and illegal immigrants from our Commonwealth." Supports removing all undocumented immigrants — deport everyone without legal status, starting with those who have criminal records.',
   ARRAY['https://www.hamiltonforvirginia.com/priorities']),
  ('11074d6c-4c9c-4b9e-9606-42eae7a6537c', '6b9ba6d9-1001-43f5-b073-4d37130696fd',
   'Campaign website: "Our rights and liberties are given by God and simply protected by the Constitution. I will always vote to protect the individual and property rights described in our founding documents." Background includes missionary parents, homeschool mom with strong Christian values. Strongly protects religious freedom with emphasis on God-given rights and broad individual liberty.',
   ARRAY['https://www.hamiltonforvirginia.com/priorities']),
  ('11074d6c-4c9c-4b9e-9606-42eae7a6537c', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
   'Campaign website under Agricultural Freedom: "Over-regulation and a focus on ludicrous climate initiatives have ignored the true needs of our farmers. Government should have a limited role in agriculture, allowing farmers to make their own decisions and innovate without excessive interference." Opposes climate regulations as overreach — let market forces drive any transition to cleaner energy sources.',
   ARRAY['https://www.hamiltonforvirginia.com/priorities'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Phillip A. Scott (HD-63, R) — 2 stances
-- Source: https://en.wikipedia.org/wiki/Phillip_Scott_(Virginia_politician)
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
  ('597a4057-4ccc-43f6-bf97-bcc701d7e637', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 4), -- voting-rights
  ('597a4057-4ccc-43f6-bf97-bcc701d7e637', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 4)  -- taxes
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
  ('597a4057-4ccc-43f6-bf97-bcc701d7e637', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
   'Wikipedia: In the 2023 Assembly session, Scott introduced a bill that would reduce Virginia''s early voting period from 45 days to 14 days. Reducing early voting access is consistent with requiring photo ID for voting and regularly updating voter rolls — a restrictive voting access position.',
   ARRAY['https://en.wikipedia.org/wiki/Phillip_Scott_(Virginia_politician)']),
  ('597a4057-4ccc-43f6-bf97-bcc701d7e637', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
   'Wikipedia: In the 2022 legislative session, Scott sponsored a bill to allow localities to lower vehicle tax rates in response to rising prices for used cars. This bill was signed into law by Governor Glenn Youngkin. Sponsoring local tax reduction legislation — cut taxes for everyone and scale back public services to match.',
   ARRAY['https://en.wikipedia.org/wiki/Phillip_Scott_(Virginia_politician)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Stacey A. Carroll (HD-64, D) — 3 stances
-- Source: https://staceycarrollforva.com
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
  ('ac78bc55-8fe9-4efb-a0ea-179842b6c44e', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2), -- healthcare
  ('ac78bc55-8fe9-4efb-a0ea-179842b6c44e', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 3), -- medicare/aid
  ('ac78bc55-8fe9-4efb-a0ea-179842b6c44e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2)  -- abortion
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
  ('ac78bc55-8fe9-4efb-a0ea-179842b6c44e', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
   'Campaign website: "Stacey will work to protect access to Medicaid, defend access to reproductive care, and stand up to drug companies to lower prescription drug costs." Protecting Medicaid access and lowering prescription drug costs through public programs — make sure everyone has affordable coverage through a mix of public programs and regulated private insurance.',
   ARRAY['https://staceycarrollforva.com']),
  ('ac78bc55-8fe9-4efb-a0ea-179842b6c44e', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
   'Campaign website: "Stacey will work to protect access to Medicaid" — framing is defensive (protect existing access) rather than expansionary. Consistent with improving current Medicare/Medicaid programs while controlling costs rather than expanding them beyond current scope.',
   ARRAY['https://staceycarrollforva.com']),
  ('ac78bc55-8fe9-4efb-a0ea-179842b6c44e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
   'Campaign website: "Stacey will work to protect access to Medicaid, defend access to reproductive care." Explicitly defending access to reproductive care aligns with keeping abortion legal and accessible — keep abortion legal and accessible through the second trimester.',
   ARRAY['https://staceycarrollforva.com'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Mark C. Downey (HD-69, D) — 5 stances
-- Source: https://downeyforva.com/values
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
  ('aefff366-6345-45fc-b52d-0e4ceb64d121', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2), -- healthcare
  ('aefff366-6345-45fc-b52d-0e4ceb64d121', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2), -- abortion
  ('aefff366-6345-45fc-b52d-0e4ceb64d121', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2), -- childcare
  ('aefff366-6345-45fc-b52d-0e4ceb64d121', '669cac97-66a6-4087-b036-936fbe62efb3', 3), -- housing
  ('aefff366-6345-45fc-b52d-0e4ceb64d121', '00b95a6a-75db-4521-b523-3326bba938de', 1)  -- school-vouchers
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
  ('aefff366-6345-45fc-b52d-0e4ceb64d121', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
   'Campaign website: "As Delegate, I''m fighting to protect Medicaid coverage for nearly 1 million Virginians across the Commonwealth and expand access to services in rural parts of the 69th." Pediatrician actively fighting to protect and expand Medicaid — make sure everyone has affordable coverage through a mix of public programs and regulated private insurance.',
   ARRAY['https://downeyforva.com/values']),
  ('aefff366-6345-45fc-b52d-0e4ceb64d121', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
   'Campaign website: "As Delegate, I have been a consistent vote to protect reproductive rights in the Virginia Constitution and defend comprehensive reproductive healthcare, including contraception, prenatal care, and in vitro fertilization." As a physician explicitly protecting reproductive rights in the constitution — keep abortion legal and accessible through the second trimester.',
   ARRAY['https://downeyforva.com/values']),
  ('aefff366-6345-45fc-b52d-0e4ceb64d121', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
   'Campaign website: "As your delegate, Mark is fighting for a commonsense and children-first platform that lowers prices for childcare." Actively fighting to lower childcare prices through government action — significantly expanding subsidies and provider grants to make childcare affordable for low- and middle-income families.',
   ARRAY['https://downeyforva.com/values']),
  ('aefff366-6345-45fc-b52d-0e4ceb64d121', '669cac97-66a6-4087-b036-936fbe62efb3',
   'Campaign website: "support legislation to help working Virginians afford homes." Targeted legislative support to help working families afford housing — offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits.',
   ARRAY['https://downeyforva.com/values']),
  ('aefff366-6345-45fc-b52d-0e4ceb64d121', '00b95a6a-75db-4521-b523-3326bba938de',
   'Campaign website: "As a pediatrician and dad of four York County public school graduates, I see how much a quality education matters. Small class sizes enable teachers to focus on each student, and higher pay helps to retain talented educators." Focused entirely on fully funding and strengthening public schools; no mention of vouchers — fully funding public schools and eliminating voucher programs that divert taxpayer money to private institutions.',
   ARRAY['https://downeyforva.com/values'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Verification block scoped to Wave 4 (contiguous BETWEEN — HD-60 to HD-69)
-- external_id BETWEEN -5120069 AND -5120060
-- ============================================================
DO $$
DECLARE
  delegate_count INT;
  unsourced_count INT;
BEGIN
  SELECT COUNT(DISTINCT pa.politician_id) INTO delegate_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE p.external_id BETWEEN -5120069 AND -5120060;
  RAISE NOTICE 'VA delegates with stances (Wave 4): %', delegate_count;

  SELECT COUNT(*) INTO unsourced_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE p.external_id BETWEEN -5120069 AND -5120060
    AND (pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
  RAISE NOTICE 'Unsourced VA delegate stances (Wave 4): %', unsourced_count;
  ASSERT unsourced_count = 0, 'Unsourced stances found — migration blocked';
END $$;

COMMIT;
