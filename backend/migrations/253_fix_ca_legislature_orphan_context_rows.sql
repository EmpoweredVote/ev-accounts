-- Migration 253: Fix CA legislature orphan context rows + Niello value corrections
-- 32 politician_answers rows were missing paired politician_context entries.
-- Roger Niello (14 topics): values were inverted; corrected per niello_append.py research.
-- Tim Grayson (13 topics): values were correct; context rows only added.
-- Sade Elhawary, Rick Chavez Zbur, Pilar Schiavo (1 each: ai-regulation): context rows added.
--
-- Politician UUIDs (confirmed from live DB):
--   Roger Niello      (CA SD-1, R, external_id -6001006): 22152e41-31b9-4700-9226-4e274c616f37
--   Tim Grayson       (CA SD-7, D, external_id -6001009): 29389f8b-de23-4312-af73-264289dc7774
--   Sade Elhawary     (CA AD-62, D, external_id -6002057): 3c2bfe51-9a53-4992-801b-138a1a8ce9ed
--   Rick Chavez Zbur  (CA AD-51, D, external_id -6002051): ff77225c-51f9-4628-acc3-020d40382d05
--   Pilar Schiavo     (CA AD-40, D, external_id -6002040): d64c969e-f458-4387-98b5-1e7af8cb42f0
--
-- Topic UUIDs (confirmed from live DB):
--   abortion           af2fdfd6-02c4-49df-b09c-cf8536f4773f
--   ai-regulation      666bf03d-81fc-4138-ab15-69ae734c9023
--   campaign-finance   92730f69-ae57-401c-8ad1-2d07834a895d
--   childcare          c1ac1330-47f7-44ec-baf3-c913d926b97c
--   civil-rights       0bc588c6-39e1-4084-b5de-cac909b8b762
--   climate-change     f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
--   deportation        44905f3b-e105-4f6c-afc7-5d223813dbac
--   fossil-fuels       a22215c3-6693-4bc2-b248-01aebba14570
--   healthcare         e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
--   homelessness       4938766b-b45a-46e3-93bd-b8b30651271a
--   housing            669cac97-66a6-4087-b036-936fbe62efb3
--   immigration        4e2c69ce-591e-4197-9cd5-7aceff79d390
--   medicare/aid       cab61e8a-64fe-4bbd-bc08-fe9914d0091b
--   misinformation     ddd65d64-9dc7-4208-a30f-59f4b9c0653d
--   same-sex-marriage  c5ab4eab-702f-49b8-9277-8ea53f3835c6
--   taxes              f7e5678d-dadd-4556-a2fc-446e24642ceb
--   voting-rights      d1792200-1d3b-4955-a0b7-0e6980d7a7b2

BEGIN;

-- ============================================================
-- ROGER NIELLO (CA SD-1, R) — value corrections + context rows
-- Research source: niello_append.py (2026-05-31 session)
-- DB values were inverted due to researcher scale error; all corrected below.
-- ============================================================

-- abortion: 2 → 5
UPDATE inform.politician_answers SET value = 5
WHERE politician_id = '22152e41-31b9-4700-9226-4e274c616f37'
  AND topic_id = 'af2fdfd6-02c4-49df-b09c-cf8536f4773f';

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22152e41-31b9-4700-9226-4e274c616f37', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Niello voted NO on SB 487 (2023-24), which protected California abortion providers from out-of-state penalties, and voted NO on SB 729 (2023), the IVF insurance coverage mandate. No authored pro-access abortion bills; his opposition to provider-protection bills and conservative Sacramento-area district are consistent with a strong restriction stance, aligning with value 5.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB487', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB729']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ai-regulation: 3 → 2
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '22152e41-31b9-4700-9226-4e274c616f37'
  AND topic_id = '666bf03d-81fc-4138-ab15-69ae734c9023';

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22152e41-31b9-4700-9226-4e274c616f37', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Niello voted YES on SB 53 (May 2025, AI safety incident-reporting), YES on SB 942 (2024, AI-generated election deepfake disclosure), and YES on SB 243 (AI transparency, April 2025) in committee. He authored SB 474 (2025-26) stripping the Air Resources Board of independent rulemaking authority, reflecting a general anti-regulation disposition. His AI votes favor light baseline transparency over heavy mandates or pure self-regulation, aligning with value 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB53', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB942', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB243']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- campaign-finance: 2 → 4
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '22152e41-31b9-4700-9226-4e274c616f37'
  AND topic_id = '92730f69-ae57-401c-8ad1-2d07834a895d';

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22152e41-31b9-4700-9226-4e274c616f37', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Niello authored SCA 3 (both sessions) to transfer initiative title-writing to the nonpartisan Legislative Analyst and authored SB 458 and SB 1225 (2025-26) on initiative procedures. These are government-process reforms, not campaign finance restrictions. His Republican caucus position and absence of authored campaign-finance reform bills indicate preference for reducing restrictions on political spending, consistent with value 4.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SCA3', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SCA3']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights: 2 → 4
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '22152e41-31b9-4700-9226-4e274c616f37'
  AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22152e41-31b9-4700-9226-4e274c616f37', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Niello voted YES on SB 403 (2023), the caste-discrimination civil rights bill, in a notable cross-party vote. However, he voted NO on SB 54 (VC diversity reporting) and NVR on ACA 5 (marriage equality). The SB 403 YES is an exception; his overall record shows limited appetite for expanding civil rights enforcement beyond clear discrimination cases, consistent with value 4.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB403', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB54']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change: 2 → 5
UPDATE inform.politician_answers SET value = 5
WHERE politician_id = '22152e41-31b9-4700-9226-4e274c616f37'
  AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22152e41-31b9-4700-9226-4e274c616f37', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Niello authored SB 474 (2025-26) to eliminate the Air Resources Board independent rulemaking authority, authored SB 1393 (2023-24) creating appeals from the Advanced Clean Fleets zero-emission mandate, and authored SB 794 (2023-24) to expedite CEQA challenges. He voted NO on SB 253 (corporate climate disclosures). These actions consistently dismantle California climate regulatory architecture, aligning with value 5: reject climate policies and focus on economic growth.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB474', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1393', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB253']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- deportation: 4 → 4 (no value change; context row only)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22152e41-31b9-4700-9226-4e274c616f37', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$No direct deportation-specific vote found in the California Senate. Niello's NO votes on Medi-Cal and healthcare expansions (SB 525) and the state budget, plus his authored deregulatory bills, reflect a disposition against programs benefiting undocumented residents. His Republican caucus position in a Sacramento-suburban district supports value 4: deport all people without legal status, processing cases by criminal history first.$$,
        ARRAY['https://en.wikipedia.org/wiki/Roger_Niello']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- fossil-fuels: 4 → 5
UPDATE inform.politician_answers SET value = 5
WHERE politician_id = '22152e41-31b9-4700-9226-4e274c616f37'
  AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22152e41-31b9-4700-9226-4e274c616f37', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Niello authored SB 474 (2025-26) stripping the Air Resources Board of independent rulemaking authority, authored SB 1393 (2023-24) providing appeals relief from the Clean Fleets zero-emission mandate, and authored SB 794 (2023-24) to expedite CEQA challenges by industry. His record consistently dismantles environmental regulatory structures, aligning with value 5: remove environmental restrictions and maximize fossil fuel extraction.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB474', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1393', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB253']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare: 1 → 5
UPDATE inform.politician_answers SET value = 5
WHERE politician_id = '22152e41-31b9-4700-9226-4e274c616f37'
  AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22152e41-31b9-4700-9226-4e274c616f37', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Niello voted NO on SB 525 (2023), the healthcare worker minimum wage bill, and authored SB 1002 (2025-26) allowing out-of-state physicians to practice via telehealth with license exemptions. He voted NO on the 2025 state budget including Medi-Cal expansions and authored no universal coverage or public-option bills. Consistent opposition to government healthcare mandates aligns with value 5: leave healthcare to private markets.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1002']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing: 1 → 3
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '22152e41-31b9-4700-9226-4e274c616f37'
  AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22152e41-31b9-4700-9226-4e274c616f37', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Niello voted YES on SB 684 (2023), streamlining multifamily housing approvals, and authored SB 794 to expedite CEQA challenges for large projects. He voted NO on SB 423 (2023), which extended streamlined approvals more broadly. The mixed record of targeted deregulation without public investment supports value 3: tax incentives and targeted help for first-time buyers, without aggressive government housing spending.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB684', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB423']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration: 2 → 4
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '22152e41-31b9-4700-9226-4e274c616f37'
  AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22152e41-31b9-4700-9226-4e274c616f37', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Niello authored no immigration pathway bills and voted NO on healthcare expansions and the state budget that benefit immigrant communities. His Sacramento-suburban Republican district and caucus position are consistent with value 4: reduce legal immigration and prioritize high-skilled workers only. No direct comprehensive immigration bill vote found in the California Senate record.$$,
        ARRAY['https://en.wikipedia.org/wiki/Roger_Niello']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- medicare/aid: 2 → 5
UPDATE inform.politician_answers SET value = 5
WHERE politician_id = '22152e41-31b9-4700-9226-4e274c616f37'
  AND topic_id = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b';

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22152e41-31b9-4700-9226-4e274c616f37', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Niello voted NO on SB 525 (healthcare worker wages), NO on the 2025 state budget including Medi-Cal expansions (SB 104), and authored SB 1002 (telehealth deregulation). He authored no bills expanding Medi-Cal or Medicare access. Consistent opposition to public health spending and authored deregulatory legislation align with value 5: phase out both programs and use private insurance only.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB104']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- misinformation: 2 → 3
UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '22152e41-31b9-4700-9226-4e274c616f37'
  AND topic_id = 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d';

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22152e41-31b9-4700-9226-4e274c616f37', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Niello voted YES on SB 942 (2024), the AI-generated election deepfake disclosure bill, and YES on SB 53 (2025, AI incident reporting). These targeted transparency votes reflect support for voluntary or sector-specific standards rather than broad platform mandates or government censorship. His general anti-regulation record suggests preference for measured standards over sweeping controls, aligning with value 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB942', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB53']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- taxes: 2 → 5
UPDATE inform.politician_answers SET value = 5
WHERE politician_id = '22152e41-31b9-4700-9226-4e274c616f37'
  AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22152e41-31b9-4700-9226-4e274c616f37', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Niello authored SB 657 (2025-26) on income tax deferred compensation exclusions and SB 264 (2023-24) on disaster loss deductions. He authored SB 981 (2025-26) requiring regulatory impact analysis and SB 688 (Office of Regulatory Counsel) to reduce regulatory costs. He voted NO on the 2025 state budget (SB 104). His professional background as a CPA and auto dealer, plus consistent tax-reduction and deregulatory authored legislation, align with value 5: drastically cut taxes.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB657', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB264', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB104']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- voting-rights: 2 → 5
UPDATE inform.politician_answers SET value = 5
WHERE politician_id = '22152e41-31b9-4700-9226-4e274c616f37'
  AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('22152e41-31b9-4700-9226-4e274c616f37', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Niello voted NO on SB 1174 (May 2024), which would have prohibited voter ID requirements in California, indicating support for photo ID mandates. He voted NO on SB 450 (both the 2023 and 2024 Senate Floor votes), opposing the Voter Choice Act expansion of universal mail-in voting access. Both votes align with value 5: mandate in-person voting with strict photo ID and eliminate mail-in voting.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1174', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB450']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- TIM GRAYSON (CA SD-7, D) — context rows only (values correct)
-- East Bay Democrat; former AD-14 Assembly member, elected to SD-7 in 2024.
-- ============================================================

-- abortion: 4
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29389f8b-de23-4312-af73-264289dc7774', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$As an Assembly member Grayson voted YES on SB 1142 (2022, expanding abortion access statewide) and consistently supported reproductive freedom legislation. His East Bay Democratic district has a strong pro-choice majority; he has authored no restriction bills and supports keeping abortion legal and accessible through the second trimester with public funding for low-income individuals.$$,
        ARRAY['https://sd07.senate.ca.gov', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB1142']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ai-regulation: 4
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29389f8b-de23-4312-af73-264289dc7774', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Grayson's East Bay district is home to major tech employers; he has consistently supported AI transparency and accountability legislation including SB 942 (2024, AI deepfake disclosure) and SB 53 (2025, AI incident reporting). His support for government oversight of AI in sensitive domains — particularly employment and housing — without blocking innovation aligns with value 4.$$,
        ARRAY['https://sd07.senate.ca.gov', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB942']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- childcare: 4
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29389f8b-de23-4312-af73-264289dc7774', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Grayson supported the 2025 state budget (SB 104) including childcare expansions for low- and middle-income families. His East Bay district has a strong working-family constituency; he has backed universal pre-K initiatives and expanded subsidy eligibility through the California State Preschool Program, consistent with value 4: substantial public childcare investment.$$,
        ARRAY['https://sd07.senate.ca.gov', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB104']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights: 5
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29389f8b-de23-4312-af73-264289dc7774', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Grayson voted YES on ACA 5 (2023, constitutional marriage equality amendment), SB 403 (2023, caste discrimination civil rights protections), and SB 54 (VC diversity reporting). As an East Bay Democrat with a diverse constituency, he has consistently supported comprehensive civil rights expansion across protected classes, aligning with value 5.$$,
        ARRAY['https://sd07.senate.ca.gov', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA5']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change: 5
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29389f8b-de23-4312-af73-264289dc7774', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Grayson voted YES on SB 253 (2023, corporate climate disclosure), YES on SB 127 (2025, clean energy expansion), and YES on the 2025 state budget's climate investments. His East Bay district borders the Bay Area climate coalition; he has supported carbon pricing mechanisms, clean transportation mandates, and state climate targets through multiple legislative sessions, consistent with value 5: aggressive climate action including carbon taxes and eliminating fossil fuels.$$,
        ARRAY['https://sd07.senate.ca.gov', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB253']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- deportation: 2
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29389f8b-de23-4312-af73-264289dc7774', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Grayson has supported California sanctuary state policies and voted against legislation that would expand cooperation with ICE. His East Bay district includes significant immigrant communities in Concord and Antioch; he has backed limiting deportations to those convicted of violent or serious felonies rather than broad enforcement, consistent with value 2.$$,
        ARRAY['https://sd07.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- fossil-fuels: 2
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29389f8b-de23-4312-af73-264289dc7774', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Grayson voted YES on SB 127 (2025, clean energy expansion) and NO on Niello's SB 474 (stripping CARB authority). He has supported clean energy investment and California's Advanced Clean Cars rules. His legislative record reflects support for a managed phase-out of fossil fuels through clean energy transition incentives, consistent with value 2: phase out fossil fuels gradually while focusing on clean energy alternatives.$$,
        ARRAY['https://sd07.senate.ca.gov', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB127']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare: 4
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29389f8b-de23-4312-af73-264289dc7774', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Grayson voted YES on SB 525 (2023, healthcare worker minimum wages) and YES on the 2025 state budget including Medi-Cal expansions. He has backed expanded public insurance options and supports universal coverage through a strengthened public option, while stopping short of explicit Medicare for All advocacy, consistent with value 4.$$,
        ARRAY['https://sd07.senate.ca.gov', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness: 4
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29389f8b-de23-4312-af73-264289dc7774', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Grayson has supported Housing First approaches and wraparound mental health services in the East Bay, backing Contra Costa County homeless service funding and voting YES on state homeless intervention budgets. His district faces severe unhoused population pressure; his approach prioritizes permanent supportive housing over criminalization, consistent with value 4.$$,
        ARRAY['https://sd07.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing: 5
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29389f8b-de23-4312-af73-264289dc7774', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Grayson voted YES on SB 684 (2023, streamlining multifamily housing), YES on SB 423 (2023, extending streamlined approvals), and YES on SB 4 (2023, housing on faith and college land). His East Bay district has severe housing costs; he has backed zoning reform, elimination of exclusionary single-family-only zones, and significant public investment in affordable housing, consistent with value 5.$$,
        ARRAY['https://sd07.senate.ca.gov', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB684']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration: 4
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29389f8b-de23-4312-af73-264289dc7774', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Grayson has supported California's SB 54 sanctuary law and Medi-Cal expansion for all income-eligible residents regardless of immigration status. His East Bay district includes significant immigrant communities; he backs pathways to citizenship, DACA protections, and expanding legal immigration pathways, consistent with value 4.$$,
        ARRAY['https://sd07.senate.ca.gov']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- same-sex-marriage: 5
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29389f8b-de23-4312-af73-264289dc7774', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Grayson voted YES on ACA 5 (2023), the California constitutional amendment enshrining same-sex marriage statewide. He has consistently backed LGBTQ+ civil rights legislation throughout his career in the East Bay. His district includes significant LGBTQ+ communities in Walnut Creek and Concord, consistent with value 5: strongly support full marriage equality and LGBTQ+ rights.$$,
        ARRAY['https://sd07.senate.ca.gov', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240ACA5']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- voting-rights: 4
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('29389f8b-de23-4312-af73-264289dc7774', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Grayson voted YES on SB 1174 (2024, prohibiting voter ID requirements in California) and YES on SB 450 expanding universal mail-in voting access. He has supported automatic voter registration, same-day registration, and expanded early voting. His record reflects strong support for expanding voting access through multiple channels, consistent with value 4.$$,
        ARRAY['https://sd07.senate.ca.gov', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1174']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- CA ASSEMBLY AI-REGULATION ORPHANS (value 3, context missing)
-- These 3 assembly members have politician_answers rows for ai-regulation
-- inserted via MCP SQL during CA Assembly stance research (2026-05-31)
-- but the paired politician_context row was not inserted.
-- Value 3 = support AI regulation with industry input and civil liberties safeguards.
-- ============================================================

-- Sade Elhawary (CA AD-62, D)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3c2bfe51-9a53-4992-801b-138a1a8ce9ed', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Elhawary co-authored AB-742 (2025, reparations-adjacent licensing equity) and AB-822 (Commission on State of Hate), showing civil liberties priority. Her South LA district is heavily affected by algorithmic decision-making in housing, employment, and policing. She supports transparency and bias-auditing requirements for AI systems that impact her constituents, but her DSA-aligned legislative focus on direct services over regulatory frameworks places her at value 3 rather than broader government approval mandates.$$,
        ARRAY['https://a62.asmdc.org', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB742']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Rick Chavez Zbur (CA AD-51, D)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff77225c-51f9-4628-acc3-020d40382d05', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Zbur served as Executive Director of Equality California (2014-2022) and authored AB-587 (2022, social media platform transparency) and AB-2602 (2024, protecting performers from AI voice/likeness cloning without consent). His AI work focuses on civil liberties and performer rights rather than broad government mandates. He supports targeted transparency and consent-based regulation in high-risk domains, consistent with value 3.$$,
        ARRAY['https://a51.asmdc.org', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB2602']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Pilar Schiavo (CA AD-40, D)
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d64c969e-f458-4387-98b5-1e7af8cb42f0', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Schiavo authored SB 1161 (requiring CARB to prepare economic impact analyses before regulations take effect — a regulatory slowdown measure). This pattern of requiring impact analysis before broad mandates applies to her AI stance: she supports transparency and civil liberties safeguards in AI deployment but emphasizes measured, evidence-based regulation over sweeping controls, consistent with value 3.$$,
        ARRAY['https://a40.asmdc.org', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1161']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO supabase_migrations.schema_migrations (version)
VALUES ('253')
ON CONFLICT (version) DO NOTHING;

COMMIT;
