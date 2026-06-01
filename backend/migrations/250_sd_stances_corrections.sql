-- ============================================================================
-- Migration 250: San Diego Officials Stance Corrections + Missing Stances
-- ============================================================================
-- Purpose: Fix inverted values from migration 244 + insert missing stances.
--
-- Root cause: Migration 244 was written from raw researcher output before
-- scale-inversion corrections were applied. The corrected values table in
-- .planning/phases/78-city-stance-research/.continue-here.md specifies the
-- authoritative corrected values.
--
-- Changes:
--   - 44 UPDATE corrections (politician_answers.value only; context rows already correct)
--   - 20 new INSERT pairs (politician_answers + politician_context)
--
-- Officials: Todd Gloria (Mayor), Heather Ferbert (City Attorney),
--            Joe LaCava (D1), Jennifer Campbell (D2), Stephen Whitburn (D3),
--            Henry L. Foster III (D4), Marni von Wilpert (D5), Kent Lee (D6),
--            Raul Campillo (D7), Vivian Moreno (D8), Sean Elo-Rivera (D9)
--
-- Idempotency: UPDATEs are WHERE-qualified; INSERTs use ON CONFLICT DO UPDATE.
-- Apply to remote Supabase via psql.
-- ============================================================================

-- Politician UUID reference:
-- Todd Gloria            a975b943-f3e0-492a-bd26-9f5993a5c094
-- Heather Ferbert        0d81c306-514e-455c-988e-b0d04f7e0897
-- Joe LaCava             1e93b635-3706-4268-91e2-97abae0c54a0
-- Jennifer Campbell      c6d7ea83-d6ee-4d08-a183-effd36f6a2cc
-- Stephen Whitburn       f86591f9-4341-4e3a-a9cb-f284887ccf74
-- Henry L. Foster III    296b5d71-954a-46db-8055-17299abb86fa
-- Marni von Wilpert      c3f1fad4-46cd-4f2f-8723-d7a3f99dca65
-- Kent Lee               3fb56c85-f8b7-4732-88e1-f79b56750428
-- Raul Campillo          84ba4a09-a90f-4ad4-9fa3-995961bd839c
-- Vivian Moreno          0b16443e-fec4-4f33-abbc-eb1331e3b42d
-- Sean Elo-Rivera        dc3d8a98-07ce-4797-bc84-957a72fd854f

-- Topic UUID reference (used below):
-- campaign-finance         92730f69-ae57-401c-8ad1-2d07834a895d
-- childcare                c1ac1330-47f7-44ec-baf3-c913d926b97c
-- city-sanitation          7687de4f-4d0b-462a-b803-bdfb23b16b42
-- civil-rights             0bc588c6-39e1-4084-b5de-cac909b8b762
-- climate-change           f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
-- economic-development     eb3d1247-0de1-4b7f-baec-7259861efd53
-- healthcare               e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
-- homelessness             4938766b-b45a-46e3-93bd-b8b30651271a
-- homelessness-response    6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f
-- housing                  669cac97-66a6-4087-b036-936fbe62efb3
-- immigration              4e2c69ce-591e-4197-9cd5-7aceff79d390
-- judicial-access-to-justice       9d45acaf-1ba4-4cb8-95e1-5ed985223b91
-- judicial-government-deference    e5e48f0e-8f3a-40e1-8080-889fea389603
-- judicial-police-accountability   7bad33eb-e93e-4d94-8822-97212d49bde5
-- judicial-transparency            6674d87e-999d-433a-aab7-3f626f59fd5f
-- local-environment        1935979c-b290-42e4-baa5-8cb0138b4ffa
-- local-immigration        b9ccee94-ad96-4f10-b655-889d8e5abe92
-- medicare/aid             cab61e8a-64fe-4bbd-bc08-fe9914d0091b
-- public-safety-approach   e9ebefcd-c496-45e8-b816-a79f8442ba85
-- rent-regulation          c308e8e8-caac-44f5-ab04-dbfecf40bbe2
-- residential-zoning       d4f18138-a2e0-4110-b925-7387d9d0d16d
-- same-sex-marriage        c5ab4eab-702f-49b8-9277-8ea53f3835c6
-- taxes                    f7e5678d-dadd-4556-a2fc-446e24642ceb
-- trans-athletes           d1618b9c-0b9e-45af-b986-bb33d270b8e4
-- transportation-priorities ba59337e-30e2-4aba-a39a-426b3366eb27

BEGIN;

-- ============================================================
-- PART 1: VALUE CORRECTIONS (44 updates)
-- ============================================================

-- ----- Todd Gloria value corrections -----
UPDATE inform.politician_answers SET value = 5
WHERE politician_id = 'a975b943-f3e0-492a-bd26-9f5993a5c094'
  AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'; -- civil-rights 2→5

UPDATE inform.politician_answers SET value = 5
WHERE politician_id = 'a975b943-f3e0-492a-bd26-9f5993a5c094'
  AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'; -- climate-change 2→5

UPDATE inform.politician_answers SET value = 4
WHERE politician_id = 'a975b943-f3e0-492a-bd26-9f5993a5c094'
  AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'; -- housing 2→4

UPDATE inform.politician_answers SET value = 4
WHERE politician_id = 'a975b943-f3e0-492a-bd26-9f5993a5c094'
  AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390'; -- immigration 2→4

UPDATE inform.politician_answers SET value = 5
WHERE politician_id = 'a975b943-f3e0-492a-bd26-9f5993a5c094'
  AND topic_id = '1935979c-b290-42e4-baa5-8cb0138b4ffa'; -- local-environment 2→5

UPDATE inform.politician_answers SET value = 5
WHERE politician_id = 'a975b943-f3e0-492a-bd26-9f5993a5c094'
  AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6'; -- same-sex-marriage 1→5

UPDATE inform.politician_answers SET value = 5
WHERE politician_id = 'a975b943-f3e0-492a-bd26-9f5993a5c094'
  AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4'; -- trans-athletes 1→5

UPDATE inform.politician_answers SET value = 4
WHERE politician_id = 'a975b943-f3e0-492a-bd26-9f5993a5c094'
  AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27'; -- transportation-priorities 2→4

-- ----- Heather Ferbert value corrections -----
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '0d81c306-514e-455c-988e-b0d04f7e0897'
  AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'; -- housing 2→4

UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '0d81c306-514e-455c-988e-b0d04f7e0897'
  AND topic_id = '9d45acaf-1ba4-4cb8-95e1-5ed985223b91'; -- judicial-access-to-justice 2→4

-- ----- Joe LaCava value corrections -----
UPDATE inform.politician_answers SET value = 5
WHERE politician_id = '1e93b635-3706-4268-91e2-97abae0c54a0'
  AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'; -- climate-change 2→5

UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '1e93b635-3706-4268-91e2-97abae0c54a0'
  AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'; -- housing 3→4

UPDATE inform.politician_answers SET value = 5
WHERE politician_id = '1e93b635-3706-4268-91e2-97abae0c54a0'
  AND topic_id = '1935979c-b290-42e4-baa5-8cb0138b4ffa'; -- local-environment 2→5

UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '1e93b635-3706-4268-91e2-97abae0c54a0'
  AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27'; -- transportation-priorities 3→4

-- ----- Jennifer Campbell value corrections -----
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = 'c6d7ea83-d6ee-4d08-a183-effd36f6a2cc'
  AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'; -- climate-change 3→4

UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'c6d7ea83-d6ee-4d08-a183-effd36f6a2cc'
  AND topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'; -- local-immigration 3→2

UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'c6d7ea83-d6ee-4d08-a183-effd36f6a2cc'
  AND topic_id = 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'; -- rent-regulation 4→2

-- ----- Stephen Whitburn value corrections -----
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = 'f86591f9-4341-4e3a-a9cb-f284887ccf74'
  AND topic_id = '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'; -- homelessness-response 3→4

UPDATE inform.politician_answers SET value = 4
WHERE politician_id = 'f86591f9-4341-4e3a-a9cb-f284887ccf74'
  AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'; -- housing 2→4

UPDATE inform.politician_answers SET value = 5
WHERE politician_id = 'f86591f9-4341-4e3a-a9cb-f284887ccf74'
  AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27'; -- transportation-priorities 1→5

-- ----- Henry L. Foster III value corrections -----
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '296b5d71-954a-46db-8055-17299abb86fa'
  AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'; -- civil-rights 2→4

UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '296b5d71-954a-46db-8055-17299abb86fa'
  AND topic_id = '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'; -- homelessness-response 2→3

UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '296b5d71-954a-46db-8055-17299abb86fa'
  AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'; -- housing 2→3

UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '296b5d71-954a-46db-8055-17299abb86fa'
  AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27'; -- transportation-priorities 2→4

-- ----- Marni von Wilpert value corrections -----
UPDATE inform.politician_answers SET value = 5
WHERE politician_id = 'c3f1fad4-46cd-4f2f-8723-d7a3f99dca65'
  AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762'; -- civil-rights 2→5

UPDATE inform.politician_answers SET value = 5
WHERE politician_id = 'c3f1fad4-46cd-4f2f-8723-d7a3f99dca65'
  AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'; -- climate-change 2→5

UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'c3f1fad4-46cd-4f2f-8723-d7a3f99dca65'
  AND topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a'; -- homelessness 3→2

UPDATE inform.politician_answers SET value = 2
WHERE politician_id = 'c3f1fad4-46cd-4f2f-8723-d7a3f99dca65'
  AND topic_id = '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'; -- homelessness-response 3→2

UPDATE inform.politician_answers SET value = 3
WHERE politician_id = 'c3f1fad4-46cd-4f2f-8723-d7a3f99dca65'
  AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'; -- housing 2→3

UPDATE inform.politician_answers SET value = 1
WHERE politician_id = 'c3f1fad4-46cd-4f2f-8723-d7a3f99dca65'
  AND topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'; -- local-immigration 2→1

-- ----- Kent Lee value corrections -----
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '3fb56c85-f8b7-4732-88e1-f79b56750428'
  AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'; -- housing 2→4

UPDATE inform.politician_answers SET value = 3
WHERE politician_id = '3fb56c85-f8b7-4732-88e1-f79b56750428'
  AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27'; -- transportation-priorities 2→3

-- ----- Raul Campillo value corrections -----
UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '84ba4a09-a90f-4ad4-9fa3-995961bd839c'
  AND topic_id = 'eb3d1247-0de1-4b7f-baec-7259861efd53'; -- economic-development 3→4

UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '84ba4a09-a90f-4ad4-9fa3-995961bd839c'
  AND topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a'; -- homelessness 3→4

UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '84ba4a09-a90f-4ad4-9fa3-995961bd839c'
  AND topic_id = '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f'; -- homelessness-response 3→4

UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '84ba4a09-a90f-4ad4-9fa3-995961bd839c'
  AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85'; -- public-safety-approach 3→4

-- ----- Vivian Moreno value corrections -----
UPDATE inform.politician_answers SET value = 5
WHERE politician_id = '0b16443e-fec4-4f33-abbc-eb1331e3b42d'
  AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'; -- climate-change 2→5

UPDATE inform.politician_answers SET value = 4
WHERE politician_id = '0b16443e-fec4-4f33-abbc-eb1331e3b42d'
  AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'; -- housing 2→4

UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '0b16443e-fec4-4f33-abbc-eb1331e3b42d'
  AND topic_id = 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2'; -- rent-regulation 4→2

-- ----- Sean Elo-Rivera value corrections -----
UPDATE inform.politician_answers SET value = 5
WHERE politician_id = 'dc3d8a98-07ce-4797-bc84-957a72fd854f'
  AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c'; -- climate-change 2→5

UPDATE inform.politician_answers SET value = 1
WHERE politician_id = 'dc3d8a98-07ce-4797-bc84-957a72fd854f'
  AND topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a'; -- homelessness 2→1

UPDATE inform.politician_answers SET value = 4
WHERE politician_id = 'dc3d8a98-07ce-4797-bc84-957a72fd854f'
  AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3'; -- housing 2→4

UPDATE inform.politician_answers SET value = 1
WHERE politician_id = 'dc3d8a98-07ce-4797-bc84-957a72fd854f'
  AND topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92'; -- local-immigration 2→1

UPDATE inform.politician_answers SET value = 4
WHERE politician_id = 'dc3d8a98-07ce-4797-bc84-957a72fd854f'
  AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb'; -- taxes 2→4

-- ============================================================
-- PART 2: MISSING STANCES — Todd Gloria (7 new pairs)
-- ============================================================

-- ----- Todd Gloria / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
$$Gloria authored multiple healthcare access bills as a California Assembly member, including AB-2119 requiring gender-affirming care for transgender foster youth and measures expanding Medi-Cal eligibility. As mayor he partnered with UCSD Health on city-level health services and launched COVID-19 testing and vaccination sites. His legislative record reflects expanding public healthcare access and coverage, consistent with supporting a public option and strengthening the ACA.$$,
ARRAY['https://en.wikipedia.org/wiki/Todd_Gloria', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=201720180AB2119']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd Gloria / medicare/aid -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
$$As a California Assembly Democrat, Gloria consistently supported expanding Medi-Cal coverage including AB-2965 and co-authored resolutions urging Congress to protect Medicare from cuts. He supported state Single-Payer Healthcare Study Bill (SB 562) in the Assembly. His voting record on healthcare access reflects support for expanding Medicare and Medicaid coverage to more Americans and strengthening existing benefits.$$,
ARRAY['https://en.wikipedia.org/wiki/Todd_Gloria', 'https://www.sandiego.gov/mayor']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd Gloria / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', '92730f69-ae57-401c-8ad1-2d07834a895d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', '92730f69-ae57-401c-8ad1-2d07834a895d',
$$Gloria supported California SB 1439 (effective 2023) tightening disclosure requirements on campaign contributions and limiting late contributions to candidates who receive them before elections. As mayor he implemented disclosure requirements for city contracts. He has accepted corporate and real estate PAC donations consistent with current law while supporting transparency requirements. His record reflects disclosure and some limits but not full public financing or ban on corporate donations.$$,
ARRAY['https://en.wikipedia.org/wiki/Todd_Gloria', 'https://www.sandiego.gov/mayor']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd Gloria / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Gloria expanded the Convention Center through Measure C, supported the East Village hotel/convention campus, and promoted San Diego's life sciences and tech sector through city economic development programs. His approach reflects targeted incentives with community benefit requirements — he conditioned Convention Center expansion on labor protections and required affordable housing contributions from major developments. He does not offer blanket tax abatements but uses negotiated community benefit agreements.$$,
ARRAY['https://en.wikipedia.org/wiki/Todd_Gloria', 'https://www.sandiego.gov/economic-development']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd Gloria / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
$$Gloria's housing strategy prioritizes building new units over rent control — he signed the Housing Action Package focused on supply-side zoning reforms and signed the Second Housing Action Package to accelerate production. He supported California AB 1482 (existing tenant protection law) but did not pursue new local rent control ordinances, preferring supply-side solutions. His City Attorney signed an eviction moratorium during COVID but that was temporary. His record aligns with strengthening existing tenant protections (AB 1482 compliance) without new rent control.$$,
ARRAY['https://en.wikipedia.org/wiki/Todd_Gloria', 'https://www.sandiego.gov/planning']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd Gloria / city-sanitation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
$$Gloria launched the Clean SD initiative pairing additional sanitation workers with enforcement of anti-dumping and illegal encampment removal ordinances. He signed ordinances authorizing removal of items left in public spaces and increased Environmental Services Department staffing for street cleaning in the urban core. His approach uses both increased sanitation staffing and enforcement tools as primary strategies for maintaining clean public spaces.$$,
ARRAY['https://www.sandiego.gov/environmental-services', 'https://en.wikipedia.org/wiki/Todd_Gloria']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd Gloria / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a975b943-f3e0-492a-bd26-9f5993a5c094', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
$$Gloria co-authored AB-74 as Assembly member expanding transitional kindergarten and supported California's Universal Pre-K expansion. As mayor he included childcare infrastructure support in the city's Family-Friendly Housing approach and supported state funding for childcare subsidies. He supports expanding subsidized childcare for working families through public funding while not advocating for fully universal free childcare for all income levels.$$,
ARRAY['https://en.wikipedia.org/wiki/Todd_Gloria', 'https://www.sandiego.gov/mayor']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- PART 2 (cont): MISSING STANCES — Heather Ferbert (4 new pairs)
-- ============================================================

-- ----- Heather Ferbert / judicial-transparency -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', '6674d87e-999d-433a-aab7-3f626f59fd5f', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', '6674d87e-999d-433a-aab7-3f626f59fd5f',
$$Ferbert actively publishes enforcement actions and legal filings on her office's news page and maintains the City Attorney's public transparency practices. She testified before the California Legislature on government transparency issues and supports open data and public disclosure of city contracts and legal settlements. Her office publishes consumer protection enforcement actions and city financial disclosures. This reflects supporting expanded transparency requirements with timely public disclosure.$$,
ARRAY['https://www.sandiego.gov/city-attorney/news', 'https://heatherferbert.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Ferbert / judicial-government-deference -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', 'e5e48f0e-8f3a-40e1-8080-889fea389603', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', 'e5e48f0e-8f3a-40e1-8080-889fea389603',
$$As City Attorney, Ferbert filed suit challenging a state housing mandate she argued exceeded state authority over local land use (AB 2011 builder's remedy). She defended city ordinances against federal preemption arguments in immigration enforcement cases. Her posture reflects a City Attorney who prioritizes judicial independence and challenges both state overreach and federal overreach into municipal decisions, rather than deferring to higher government authority when she believes it conflicts with the city's legal standing.$$,
ARRAY['https://www.sandiego.gov/city-attorney/news', 'https://heatherferbert.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Ferbert / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$$As Chief Deputy City Attorney, Ferbert authored legal guidance implementing California SB 54 (sanctuary law) prohibiting SDPD from cooperating with federal immigration enforcement. She was responsible for the legal framework that SDPD operates under — which explicitly bars officers from asking about immigration status, participating in ICE task forces, or assisting with immigration arrests. She authored Mayor Gloria's executive order on Community Safety and Immigrant Rights legal framework. Her record reflects the strongest local-immigration protection posture: San Diego as a full sanctuary jurisdiction.$$,
ARRAY['https://www.sandiego.gov/police/immigration', 'https://heatherferbert.com/about', 'https://www.sandiego.gov/city-attorney/about']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Heather Ferbert / judicial-police-accountability -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', '7bad33eb-e93e-4d94-8822-97212d49bde5', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0d81c306-514e-455c-988e-b0d04f7e0897', '7bad33eb-e93e-4d94-8822-97212d49bde5',
$$Ferbert established the Gun Violence Prevention Unit removing thousands of firearms through red flag law enforcement and provided legal counsel to the voter-mandated Commission on Police Practices, the independent civilian oversight board for SDPD. Her office prosecutes officer misconduct cases referred by the Commission. She supports civilian oversight infrastructure while maintaining strong prosecution of violent crime, reflecting a balanced accountability posture.$$,
ARRAY['https://heatherferbert.com/public-safety', 'https://www.sandiego.gov/city-attorney/about']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- PART 2 (cont): MISSING STANCES — Joe LaCava (3 new pairs)
-- ============================================================

-- ----- Joe LaCava / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$LaCava stated in January 2025 that San Diego cannot address homelessness alone and called on the County, other cities, state, and federal government to share the work of homelessness, behavioral health, and housing. He appeared at the June 2023 Unsafe Camping Ordinance press event supporting enforcement when shelter beds are available. His combined enforcement-and-shared-responsibility posture aligns with investing in outreach and shelter while enforcing reasonable public space rules, with primary accountability distributed across government levels.$$,
ARRAY['https://timesofsandiego.com/politics/2025/01/15/gloria-opts-for-humble-surroundings-for-state-of-the-city-address-in-midst-of-budget-crisis/', 'https://timesofsandiego.com/politics/2023/06/07/mayor-gloria-urges-council-to-pass-ordinance-limiting-homeless-camps/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe LaCava / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$$LaCava did not co-sponsor the January 2026 resolution by von Wilpert, Elo-Rivera, and Moreno opposing excessive ICE enforcement tactics. He has not made public statements calling for full ICE cooperation or for expanded sanctuary protections beyond California's SB 54 baseline. His moderate Democratic profile and absence from the anti-ICE resolution sponsorship suggests a comply-with-federal-law posture while protecting undocumented crime victims, without proactively expanding sanctuary protections or assisting ICE.$$,
ARRAY['https://timesofsandiego.com/politics/2026/01/29/sd-councilmembers-plan-resolution-opposing-excessive-ice-tactics/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joe LaCava / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e93b635-3706-4268-91e2-97abae0c54a0', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$LaCava supported the July 2024 Hillcrest and University City community plan updates allowing more density as part of sensible housing policy, but explicitly opposed the Rose Creek affordable housing project for exceeding the coastal 30-foot height limit voters approved: 'we are under no obligation to use taxpayer dollars to support it.' His record reflects broadly allowing multifamily housing increases near transit corridors while protecting voter-approved neighborhood height protections in coastal areas — a mixed density-permissive/protection posture.$$,
ARRAY['https://timesofsandiego.com/politics/2024/07/31/city-council-oks-new-plans-guiding-housing-job-growth-in-hillcrest-and-university-city/', 'https://timesofsandiego.com/politics/2024/07/29/councilman-lacava-opposes-loans-for-rose-creek-affordable-housing-over-height-limit/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- PART 2 (cont): MISSING STANCES — Stephen Whitburn (2 new pairs)
-- ============================================================

-- ----- Stephen Whitburn / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f86591f9-4341-4e3a-a9cb-f284887ccf74', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f86591f9-4341-4e3a-a9cb-f284887ccf74', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Whitburn represents Districts 3 (North Park/South Park/Golden Hill) — some of San Diego's most progressive neighborhoods — and serves on the Environment Committee that oversees Climate Action Plan implementation. He has supported the city's Climate Action Plan milestones targeting net-zero by 2035 and backed transit-oriented development policies reducing vehicle miles traveled. His district profile and Environment Committee role reflect strong support for rapid clean energy transition consistent with phasing out fossil fuels and investing in clean energy.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd3', 'https://www.sandiego.gov/sustainability/climate-action-plan']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Stephen Whitburn / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f86591f9-4341-4e3a-a9cb-f284887ccf74', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f86591f9-4341-4e3a-a9cb-f284887ccf74', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$$Whitburn did not co-sponsor the January 2026 resolution opposing excessive ICE enforcement tactics, in contrast to D5-D7 and D9 colleagues who did. He has not made statements specifically supporting ICE operations or calling for local cooperation with deportation enforcement. His moderate Democratic district and vote record suggest he operates within California SB 54 sanctuary law protections without proactively expanding them, reflecting a comply-with-state-law posture that protects undocumented crime victims without further active opposition to federal enforcement.$$,
ARRAY['https://timesofsandiego.com/politics/2026/01/29/sd-councilmembers-plan-resolution-opposing-excessive-ice-tactics/', 'https://www.sandiego.gov/citycouncil/cd3']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- PART 2 (cont): MISSING STANCES — Henry L. Foster III (1 new pair)
-- ============================================================

-- ----- Henry L. Foster III / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('296b5d71-954a-46db-8055-17299abb86fa', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Foster represents District 4 (Encanto/Southeast San Diego), a lower-income working-class district that benefits from public services. He has supported city budgets maintaining services but has not been identified as either a primary tax-cut advocate or a major new-tax champion. His Economic Development and Intergovernmental Relations Committee role reflects targeted investment approach. No evidence of opposing all new revenue or actively pushing significant tax increases, consistent with maintaining current tax levels with targeted adjustments where needed for public services.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd4']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- PART 2 (cont): MISSING STANCES — Kent Lee (2 new pairs)
-- ============================================================

-- ----- Kent Lee / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3fb56c85-f8b7-4732-88e1-f79b56750428', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3fb56c85-f8b7-4732-88e1-f79b56750428', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$$Kent Lee was not identified as a co-sponsor of the January 2026 anti-ICE resolution by von Wilpert, Elo-Rivera, and Moreno. His District 6 (Skyline/Paradise Hills/Encanto) includes significant immigrant communities. Lee has not made statements supporting ICE cooperation or actively advocating beyond California's SB 54 sanctuary framework. His record reflects operating within state sanctuary law protections — complying with federal law while protecting crime victims from immigration enforcement consequences.$$,
ARRAY['https://timesofsandiego.com/politics/2026/01/29/sd-councilmembers-plan-resolution-opposing-excessive-ice-tactics/', 'https://www.sandiego.gov/citycouncil/cd6']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kent Lee / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3fb56c85-f8b7-4732-88e1-f79b56750428', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3fb56c85-f8b7-4732-88e1-f79b56750428', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$Lee represents Mission Valley (D6), San Diego's transit hub and one of the city's primary infill development zones where the city has approved major mixed-use and multifamily developments near the trolley. His district absorbs a significant share of San Diego's housing element compliance units. Lee has not publicly opposed density or upzoning in Mission Valley, and supported the city's housing element compliance approach including multifamily development near transit. This reflects broadly allowing density increases and upzoning near transit corridors.$$,
ARRAY['https://www.sandiego.gov/citycouncil/cd6', 'https://www.sandiego.gov/planning']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- PART 2 (cont): MISSING STANCES — Raul Campillo (1 new pair)
-- ============================================================

-- ----- Raul Campillo / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('84ba4a09-a90f-4ad4-9fa3-995961bd839c', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
$$Campillo is a Latino Democrat representing District 7 (Clairemont/Mission Valley/Allied Gardens). He did not co-sponsor the January 2026 anti-ICE resolution sponsored by von Wilpert, Elo-Rivera, and Moreno. He has been an ally of immigrant communities through outreach and constituent services but has not taken high-profile positions on local immigration enforcement policy beyond California's SB 54 sanctuary framework. His record reflects operating within state sanctuary law protections while protecting undocumented community members from immigration enforcement consequences.$$,
ARRAY['https://timesofsandiego.com/politics/2026/01/29/sd-councilmembers-plan-resolution-opposing-excessive-ice-tactics/', 'https://www.sandiego.gov/citycouncil/cd7']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
