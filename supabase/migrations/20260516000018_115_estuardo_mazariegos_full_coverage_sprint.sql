-- Full coverage sprint for Estuardo Mazariegos (politician_id: 92876cb7-9905-4be7-b349-2a4a4ff39846)
-- LA City Council District 9 candidate; ACCE co-director; DSA/UTLA/SEIU-endorsed
-- Guatemalan immigrant; Black-Brown solidarity platform; anti-displacement, anti-gentrification
-- Group A: none needed (all existing rows already have 2+ sources)
-- Group B: 9 new answer+context rows
--          (campaign-finance=1, climate-change=2, deportation=2, growth-and-development=2,
--           immigration=2, jail-capacity=2, local-environment=2, taxes=2,
--           transportation-priorities=2)
-- Skipped: abortion, same-sex-marriage, trans-athletes, religious-freedom, misinformation,
--          fossil-fuels, school-vouchers, childcare, voting-rights — no verifiable evidence
-- NOTE: candidate website unreachable; primary sources: Knock LA voter guide + ACCE + UTLA

-- ── GROUP B: New answer + context rows ───────────────────────────────────────

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('92876cb7-9905-4be7-b349-2a4a4ff39846', '92730f69-ae57-401c-8ad1-2d07834a895d', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('92876cb7-9905-4be7-b349-2a4a4ff39846', '92730f69-ae57-401c-8ad1-2d07834a895d',
  'Pledges no donations from corporations, lobbyists, developers, oil/gas interests, or police associations — consistent with eliminating private money from his campaign; ACCE endorsement criteria explicitly requires candidates to "pledge not to take money from corporations, big real estate or corporate landlords."',
  ARRAY['https://acceaction.org/2026voterguide/','https://knock-la.com/knock-la-progressive-voter-guide-june-2026-primary-election/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('92876cb7-9905-4be7-b349-2a4a4ff39846', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('92876cb7-9905-4be7-b349-2a4a4ff39846', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
  'Platform states his primary goal is to "create green space and climate improvements in CD 9 to overcome decades of environmental injustice and disinvestment" — consistent with rapid clean investment and addressing environmental harm, but framed as a city-level investment/transition approach rather than emergency declaration.',
  ARRAY['https://knock-la.com/knock-la-progressive-voter-guide-june-2026-primary-election/','https://utla.net/2026-endorsements/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('92876cb7-9905-4be7-b349-2a4a4ff39846', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('92876cb7-9905-4be7-b349-2a4a4ff39846', '44905f3b-e105-4f6c-afc7-5d223813dbac',
  'As co-director of ACCE, he led campaigns for ICE-free zones barring ICE agents from public property; his existing local-immigration=1 stance (refusing all ICE detainers) maps to deporting only those who commit serious violent crimes while protecting all others.',
  ARRAY['https://acceaction.org/2026voterguide/','https://knock-la.com/knock-la-progressive-voter-guide-june-2026-primary-election/','https://acceaction.org/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('92876cb7-9905-4be7-b349-2a4a4ff39846', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('92876cb7-9905-4be7-b349-2a4a4ff39846', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
  'Proposes social housing built on city-owned vacant lots to keep housing permanently affordable and off the speculative market; takes an anti-gentrification, anti-displacement stance for CD9 (second-largest unhoused population in LA); development is conditioned on community benefit and anti-displacement outcomes.',
  ARRAY['https://knock-la.com/knock-la-progressive-voter-guide-june-2026-primary-election/','https://acceaction.org/2026voterguide/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('92876cb7-9905-4be7-b349-2a4a4ff39846', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('92876cb7-9905-4be7-b349-2a4a4ff39846', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
  'Devoted two decades to fighting for immigrant communities through ACCE; ACCE ran campaigns to establish ICE-free zones across California; endorsed by DSA-LA and UTLA; supports significantly expanded pathways and protections for immigrants but has not called for open borders.',
  ARRAY['https://knock-la.com/knock-la-progressive-voter-guide-june-2026-primary-election/','https://acceaction.org/','https://utla.net/2026-endorsements/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('92876cb7-9905-4be7-b349-2a4a4ff39846', 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('92876cb7-9905-4be7-b349-2a4a4ff39846', 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
  'Opposes criminalization of poverty and homelessness (contrasted with opponent''s push for more sweeps and LAPD patrols); favors unarmed crisis response over police expansion; does not accept police association donations; aligns with reducing incarcerated population through diversion and alternatives rather than building new capacity.',
  ARRAY['https://knock-la.com/knock-la-progressive-voter-guide-june-2026-primary-election/','https://utla.net/2026-endorsements/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('92876cb7-9905-4be7-b349-2a4a4ff39846', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('92876cb7-9905-4be7-b349-2a4a4ff39846', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
  'Platform explicitly calls for "green space and climate improvements in CD 9 to overcome decades of environmental injustice and disinvestment"; also pledges to "curb pollution" in the district; frames development accountability around environmental harm — consistent with strict developer offset requirements and full environmental impact review.',
  ARRAY['https://knock-la.com/knock-la-progressive-voter-guide-june-2026-primary-election/','https://acceaction.org/2026voterguide/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('92876cb7-9905-4be7-b349-2a4a4ff39846', '45ca4740-a861-4c8c-b3b5-0a49cf953501', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('92876cb7-9905-4be7-b349-2a4a4ff39846', '45ca4740-a861-4c8c-b3b5-0a49cf953501',
  'Messaging explicitly targets "wage and rent exploitation by the billionaire class that extracts wealth from CD 9"; ACCE runs a "Tax the Rich" campaign he leads as co-director; positions align with modestly increasing taxes on high earners/corporations while protecting working families; no flat-tax or across-the-board cut signals.',
  ARRAY['https://knock-la.com/knock-la-progressive-voter-guide-june-2026-primary-election/','https://acceaction.org/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('92876cb7-9905-4be7-b349-2a4a4ff39846', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('92876cb7-9905-4be7-b349-2a4a4ff39846', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Platform calls for "safe, accessible streets" as a primary goal; endorsed by UTLA, DSA-LA, and SEIU which consistently back multimodal infrastructure; environmental justice framing in South Central LA (historically car-dependent, underserved by transit) implies investment in pedestrian/transit options; no car-first or highway-expansion signals in any source.',
  ARRAY['https://knock-la.com/knock-la-progressive-voter-guide-june-2026-primary-election/','https://utla.net/2026-endorsements/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
