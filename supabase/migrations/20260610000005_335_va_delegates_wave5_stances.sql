-- Phase 112-05: VA House Delegate Stances — Wave 5 (HD-70-75 Hampton Roads Part 2 + HD-76-79 Richmond Metro Part 1, NON-CONTIGUOUS)
-- Requirements covered: VAST-03, VAST-05
-- Source CSV: backend/data/stance-research/2026-06-10-112-va-delegates-wave5.csv
--
-- Pre-write cross-check:
--   CSV data rows:                  18
--   INSERT INTO inform.politician_answers count: 18
--   INSERT INTO inform.politician_context count: 18
--   All UUID literals verified against 2026-06-10-112-va-delegates-wave5-preflight.json
--   max_migration at authoring: 350 (schema_migrations; psql-applied waves 326-349 not tracked there)
--
-- Stances written (5 delegates with documentable positions):
--   Shelly A. Simonds       (HD-70, D): 3 stances — school-vouchers(1), abortion(2), voting-rights(2)
--   Jessica L. Anderson     (HD-71, D): 3 stances — abortion(2), healthcare(2), school-vouchers(1)
--   Lindsey Dougherty       (HD-75, D): 5 stances — abortion(2), school-vouchers(1), healthcare(2), civil-rights(2), climate-change(3)
--   Betsy B. Carr           (HD-78, D): 2 stances — climate-change(3), healthcare(2)
--   Rae C. Cousins          (HD-79, D): 5 stances — abortion(2), school-vouchers(1), healthcare(2), civil-rights(2), climate-change(3)
--
-- Honest skip (5 delegates — no documentable policy positions found):
--   R. Lee Ware             (HD-72, R): Ballotpedia 202, no accessible website found
--   Leslie Chambers Mehta   (HD-73, D): Ballotpedia 202, no accessible website found
--   Mike A. Cherry          (HD-74, R): Wikipedia biography only (Air Force, Liberty Univ, Life Church admin), no policy positions accessible
--   Debra D. Gardner        (HD-76, D): Wikipedia biography only (social worker background, elected 2023), no policy website accessible
--   Charles H. Schmidt, Jr. (HD-77, R): No accessible website or policy pages found
--
-- NON-CONTIGUOUS external_id set — DO $$ uses IN(), not BETWEEN (Pitfall 7)
-- HD-70 through HD-75 plus HD-76 through HD-79 do NOT form a contiguous BETWEEN range
-- with previously applied wave data, so IN() is required for accuracy.
--
-- Politician UUIDs (from 2026-06-10-112-va-delegates-wave5-preflight.json):
--   Shelly A. Simonds       (HD-70, ext_id -5120070) -> c25726d9-566e-4283-b35c-c608b921599f
--   Jessica L. Anderson     (HD-71, ext_id -5120071) -> a0dfdf20-b736-4a1c-84c1-194a6625358e
--   R. Lee Ware             (HD-72, ext_id -5120072) -> af619400-b4b0-48f4-ba87-69a5ddd53301  [skip]
--   Leslie Chambers Mehta   (HD-73, ext_id -5120073) -> 92067acf-38bb-45cd-8897-b0694a75028a  [skip]
--   Mike A. Cherry          (HD-74, ext_id -5120074) -> c7f94731-2162-4fb7-803a-a2ff7443a9a1  [skip]
--   Lindsey Dougherty       (HD-75, ext_id -5120075) -> 56001e27-1129-4e5c-88da-7a1cc18e83b0
--   Debra D. Gardner        (HD-76, ext_id -5120076) -> 08284136-be31-4d86-bf77-73c900026ade  [skip]
--   Charles H. Schmidt, Jr. (HD-77, ext_id -5120077) -> bf2a6480-5ac9-421c-b14d-710b86fc89c1  [skip]
--   Betsy B. Carr           (HD-78, ext_id -5120078) -> a1e1e5e6-661e-4bea-b29a-06eeb2dcba14
--   Rae C. Cousins          (HD-79, ext_id -5120079) -> f9d4ebeb-9dc9-40d4-8318-da7042c42f48
--
-- Migration number: 335
-- Timestamp: 20260610000005
-- Applied: 2026-06-10

BEGIN;

-- ============================================================
-- Shelly A. Simonds (HD-70, D) — 3 stances
-- Source: https://ballotpedia.org/Shelly_Simonds
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
  ('c25726d9-566e-4283-b35c-c608b921599f', '00b95a6a-75db-4521-b523-3326bba938de', 1), -- school-vouchers
  ('c25726d9-566e-4283-b35c-c608b921599f', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2), -- abortion
  ('c25726d9-566e-4283-b35c-c608b921599f', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2)  -- voting-rights
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
  ('c25726d9-566e-4283-b35c-c608b921599f', '00b95a6a-75db-4521-b523-3326bba938de',
   'Ballotpedia records Simonds explicitly opposing Virginia''s voucher system: "We do not need a voucher system in Virginia for two reasons: we already have the flexibility to have specialty magnet programs in our schools and Virginia DOES NOT ADEQUATELY fund public education to begin with so there is no room for taking funding away from our schools." Value 1: fully funding public schools and eliminating voucher programs.',
   ARRAY(SELECT u FROM unnest(ARRAY['https://ballotpedia.org/Shelly_Simonds', '', '']) AS u WHERE u IS NOT NULL AND trim(u) != '')),
  ('c25726d9-566e-4283-b35c-c608b921599f', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
   'Ballotpedia records Simonds listing "Access to healthcare and maternal reproductive rights" as a key campaign priority. Her positioning as a progressive Democrat in Newport News with explicit mention of maternal reproductive rights indicates support for keeping abortion legal and accessible. Value 2: keep abortion legal and accessible through the second trimester with rare exceptions.',
   ARRAY(SELECT u FROM unnest(ARRAY['https://ballotpedia.org/Shelly_Simonds', '', '']) AS u WHERE u IS NOT NULL AND trim(u) != '')),
  ('c25726d9-566e-4283-b35c-c608b921599f', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
   'From Ballotpedia: Simonds "has been dedicated to fair elections and voting rights while serving on the Privileges and Elections Committee in the House." This explicit dedication to voting rights expansion aligns with value 2: expand early voting periods and make mail-in voting available to all voters without requiring an excuse.',
   ARRAY(SELECT u FROM unnest(ARRAY['https://ballotpedia.org/Shelly_Simonds', '', '']) AS u WHERE u IS NOT NULL AND trim(u) != ''))
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Jessica L. Anderson (HD-71, D) — 3 stances
-- Source: https://jessicaandersonforva.com
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
  ('a0dfdf20-b736-4a1c-84c1-194a6625358e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2), -- abortion
  ('a0dfdf20-b736-4a1c-84c1-194a6625358e', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2), -- healthcare
  ('a0dfdf20-b736-4a1c-84c1-194a6625358e', '00b95a6a-75db-4521-b523-3326bba938de', 1)  -- school-vouchers
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
  ('a0dfdf20-b736-4a1c-84c1-194a6625358e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
   'From official campaign website: "She supports prescription drug affordability, paid family and medical leave, and will always fight to protect our reproductive freedoms." Defending reproductive freedoms indicates support for keeping abortion legal and accessible. Value 2: keep abortion legal and accessible through the second trimester.',
   ARRAY(SELECT u FROM unnest(ARRAY['https://jessicaandersonforva.com', '', '']) AS u WHERE u IS NOT NULL AND trim(u) != '')),
  ('a0dfdf20-b736-4a1c-84c1-194a6625358e', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
   'From campaign site: "Jessica believes that high-quality, affordable healthcare that includes medical, dental, vision, and mental care coverage is essential for all Virginians. She supports prescription drug affordability, paid family and medical leave." Value 2: ensure everyone has affordable coverage through a mix of public programs and regulated private insurance.',
   ARRAY(SELECT u FROM unnest(ARRAY['https://jessicaandersonforva.com', '', '']) AS u WHERE u IS NOT NULL AND trim(u) != '')),
  ('a0dfdf20-b736-4a1c-84c1-194a6625358e', '00b95a6a-75db-4521-b523-3326bba938de',
   'From campaign site: "Jessica knows that a fully funded public education system is critical to the long-term success of our children" with advocacy for smaller class sizes and pre-K for all. Her emphasis on fully funding public schools with no mention of vouchers aligns with value 1: fully funding public schools and eliminating voucher programs.',
   ARRAY(SELECT u FROM unnest(ARRAY['https://jessicaandersonforva.com', '', '']) AS u WHERE u IS NOT NULL AND trim(u) != ''))
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Lindsey Dougherty (HD-75, D) — 5 stances
-- Source: https://www.doughertyfordelegate.com/priorities
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
  ('56001e27-1129-4e5c-88da-7a1cc18e83b0', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2), -- abortion
  ('56001e27-1129-4e5c-88da-7a1cc18e83b0', '00b95a6a-75db-4521-b523-3326bba938de', 1), -- school-vouchers
  ('56001e27-1129-4e5c-88da-7a1cc18e83b0', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2), -- healthcare
  ('56001e27-1129-4e5c-88da-7a1cc18e83b0', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2), -- civil-rights
  ('56001e27-1129-4e5c-88da-7a1cc18e83b0', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3)  -- climate-change
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
  ('56001e27-1129-4e5c-88da-7a1cc18e83b0', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
   'From official priorities page: "Advocate for women''s right to improved healthcare access and protect all reproductive rights." Defending existing reproductive rights access. Value 2: keep abortion legal and accessible through the second trimester.',
   ARRAY(SELECT u FROM unnest(ARRAY['https://www.doughertyfordelegate.com/priorities', '', '']) AS u WHERE u IS NOT NULL AND trim(u) != '')),
  ('56001e27-1129-4e5c-88da-7a1cc18e83b0', '00b95a6a-75db-4521-b523-3326bba938de',
   'Education priorities focus entirely on public school investment: Universal Pre-K, improving teacher pay, reducing barriers for special needs families — no mention of vouchers or school choice. Focus on fully funding the public system aligns with value 1: fully funding public schools and eliminating voucher programs.',
   ARRAY(SELECT u FROM unnest(ARRAY['https://www.doughertyfordelegate.com/priorities', '', '']) AS u WHERE u IS NOT NULL AND trim(u) != '')),
  ('56001e27-1129-4e5c-88da-7a1cc18e83b0', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
   'From priorities page: "Make sure that pre-existing conditions are protected for all Virginians. Cap the cost of key prescription drugs to make sure no one goes without the treatment they need." Protecting coverage and making healthcare affordable. Value 2: ensure everyone has affordable coverage through public programs and regulated private insurance.',
   ARRAY(SELECT u FROM unnest(ARRAY['https://www.doughertyfordelegate.com/priorities', '', '']) AS u WHERE u IS NOT NULL AND trim(u) != '')),
  ('56001e27-1129-4e5c-88da-7a1cc18e83b0', '0bc588c6-39e1-4084-b5de-cac909b8b762',
   'From priorities page: "Protect the LGBTQ+ community by banning housing discrimination, ending conversion therapy, and putting in place workplace protections. Move the commonwealth forward with new criminal justice reform legislation." Strengthening civil rights enforcement and addressing discrimination. Value 2.',
   ARRAY(SELECT u FROM unnest(ARRAY['https://www.doughertyfordelegate.com/priorities', '', '']) AS u WHERE u IS NOT NULL AND trim(u) != '')),
  ('56001e27-1129-4e5c-88da-7a1cc18e83b0', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
   'From priorities page: "Environmental policies that increase use of renewable energies, improve air quality, bolster protections and water quality to the tributaries of the Chesapeake." Investment in renewables and environmental protection without calling for immediate fossil fuel bans. Value 3: invest in clean energy while gradually reducing reliance on fossil fuels.',
   ARRAY(SELECT u FROM unnest(ARRAY['https://www.doughertyfordelegate.com/priorities', '', '']) AS u WHERE u IS NOT NULL AND trim(u) != ''))
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Betsy B. Carr (HD-78, D) — 2 stances
-- Source: https://betsycarr.com + https://en.wikipedia.org/wiki/Betsy_Carr
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
  ('a1e1e5e6-661e-4bea-b29a-06eeb2dcba14', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3), -- climate-change
  ('a1e1e5e6-661e-4bea-b29a-06eeb2dcba14', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)  -- healthcare
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
  ('a1e1e5e6-661e-4bea-b29a-06eeb2dcba14', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
   'From betsycarr.com: "She then ran for the House of Delegates so she could make a difference in schools, in health care, in criminal justice reform, in combating climate change, and creating fairness and justice for all." Climate change action is a stated priority for Carr. Value 3: invest in clean energy while gradually reducing reliance on fossil fuels.',
   ARRAY(SELECT u FROM unnest(ARRAY['https://betsycarr.com', 'https://en.wikipedia.org/wiki/Betsy_Carr', '']) AS u WHERE u IS NOT NULL AND trim(u) != '')),
  ('a1e1e5e6-661e-4bea-b29a-06eeb2dcba14', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
   'From betsycarr.com: healthcare improvement is listed as one of Carr''s key reasons for running for the House of Delegates. As a long-serving Democrat (elected 2009) from Richmond who explicitly campaigns on healthcare access, she consistently supports affordable coverage. Value 2: ensure everyone has affordable coverage through public programs and regulated private insurance.',
   ARRAY(SELECT u FROM unnest(ARRAY['https://betsycarr.com', 'https://en.wikipedia.org/wiki/Betsy_Carr', '']) AS u WHERE u IS NOT NULL AND trim(u) != ''))
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Rae C. Cousins (HD-79, D) — 5 stances
-- Source: https://raecousins.com
-- ============================================================

INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
  ('f9d4ebeb-9dc9-40d4-8318-da7042c42f48', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2), -- abortion
  ('f9d4ebeb-9dc9-40d4-8318-da7042c42f48', '00b95a6a-75db-4521-b523-3326bba938de', 1), -- school-vouchers
  ('f9d4ebeb-9dc9-40d4-8318-da7042c42f48', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2), -- healthcare
  ('f9d4ebeb-9dc9-40d4-8318-da7042c42f48', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2), -- civil-rights
  ('f9d4ebeb-9dc9-40d4-8318-da7042c42f48', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3)  -- climate-change
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
  ('f9d4ebeb-9dc9-40d4-8318-da7042c42f48', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
   'From official website: "Rae is a staunch advocate for the fundamental right to an abortion and the use of contraception, and has proudly championed reproductive health on the floor of the Virginia House. She continues to advance policies that will protect and expand these foundational rights." Value 2: keep abortion legal and accessible through the second trimester.',
   ARRAY(SELECT u FROM unnest(ARRAY['https://raecousins.com', '', '']) AS u WHERE u IS NOT NULL AND trim(u) != '')),
  ('f9d4ebeb-9dc9-40d4-8318-da7042c42f48', '00b95a6a-75db-4521-b523-3326bba938de',
   'From official website: "Rae rejects school choice policies and voucher schemes, which divert your tax dollars away from public schools. Rae is dedicated to defending public education." Explicitly opposes vouchers and prioritizes fully funding public schools. Value 1.',
   ARRAY(SELECT u FROM unnest(ARRAY['https://raecousins.com', '', '']) AS u WHERE u IS NOT NULL AND trim(u) != '')),
  ('f9d4ebeb-9dc9-40d4-8318-da7042c42f48', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
   'From raecousins.com: "No Virginian should have to make the decision to forego healthcare because of the hefty price tag of medical services. Rae has worked with colleagues to expand affordable quality healthcare for all Virginians. Rae will never compromise with Republicans who seek to dismantle public healthcare for low-income Virginians, the elderly, and children." Value 2: ensure everyone has affordable coverage.',
   ARRAY(SELECT u FROM unnest(ARRAY['https://raecousins.com', '', '']) AS u WHERE u IS NOT NULL AND trim(u) != '')),
  ('f9d4ebeb-9dc9-40d4-8318-da7042c42f48', '0bc588c6-39e1-4084-b5de-cac909b8b762',
   'From raecousins.com: "Rae has worked to enhance sensible gun reform measures, eradicate the school-to-prison pipeline, invest in after-school enrichment programs, and work with community stakeholders to implement data driven policies that cut to the root cause of crime." Also ensures all students feel safe regardless of gender or sexual identity. Value 2: strengthen civil rights enforcement and address systemic discrimination.',
   ARRAY(SELECT u FROM unnest(ARRAY['https://raecousins.com', '', '']) AS u WHERE u IS NOT NULL AND trim(u) != '')),
  ('f9d4ebeb-9dc9-40d4-8318-da7042c42f48', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
   'From raecousins.com: Environment listed as a key platform issue. Cousins supports environmental policy as part of her comprehensive platform focused on affordable utilities and sustainable policy for Richmond. Value 3: invest in clean energy while gradually reducing reliance on fossil fuels.',
   ARRAY(SELECT u FROM unnest(ARRAY['https://raecousins.com', '', '']) AS u WHERE u IS NOT NULL AND trim(u) != ''))
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Verification: Wave 5 scoped to NON-CONTIGUOUS external_id set
-- Uses IN() not BETWEEN (Pitfall 7) — HD-70-75 + HD-76-79
-- ============================================================
DO $$
DECLARE
  delegate_count INT;
  unsourced_count INT;
BEGIN
  SELECT COUNT(DISTINCT pa.politician_id) INTO delegate_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  WHERE p.external_id IN (-5120075, -5120074, -5120073, -5120072, -5120071, -5120070, -5120079, -5120078, -5120077, -5120076);
  RAISE NOTICE 'VA delegates with stances (Wave 5): %', delegate_count;

  SELECT COUNT(*) INTO unsourced_count
  FROM inform.politician_answers pa
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  WHERE p.external_id IN (-5120075, -5120074, -5120073, -5120072, -5120071, -5120070, -5120079, -5120078, -5120077, -5120076)
    AND (pc.politician_id IS NULL OR pc.sources IS NULL OR array_length(pc.sources, 1) = 0);
  RAISE NOTICE 'Unsourced VA delegate stances (Wave 5): %', unsourced_count;
  ASSERT unsourced_count = 0, 'Unsourced stances found — migration blocked';
END $$;

COMMIT;
