-- ============================================================================
-- Migration 647: New Bedford Mayor Jon Mitchell Stances
-- ============================================================================
-- Purpose: Insert/upsert compass stance data for New Bedford Mayor Jon Mitchell.
--
-- Mayor since January 2012 (long-serving); former federal AUSA (Whitey Bulger
-- task force); key policy record: offshore wind economy champion, port/waterfront
-- development, crime reduction via police appointments, South Coast Rail advocate.
--
-- Total rows: 6
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

-- Politician UUID reference:
-- Jon Mitchell (Mayor)             5114097d-c06a-4147-85bc-f9a6646f5c46

-- Topic UUID reference (inform.compass_topics):
-- abortion                         af2fdfd6-02c4-49df-b09c-cf8536f4773f
-- ai-regulation                    666bf03d-81fc-4138-ab15-69ae734c9023
-- campaign-finance                 92730f69-ae57-401c-8ad1-2d07834a895d
-- childcare                        c1ac1330-47f7-44ec-baf3-c913d926b97c
-- city-sanitation                  7687de4f-4d0b-462a-b803-bdfb23b16b42
-- civil-rights                     0bc588c6-39e1-4084-b5de-cac909b8b762
-- climate-change                   f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
-- deportation                      44905f3b-e105-4f6c-afc7-5d223813dbac
-- economic-development             eb3d1247-0de1-4b7f-baec-7259861efd53
-- fossil-fuels                     a22215c3-6693-4bc2-b248-01aebba14570
-- growth-and-development           fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4
-- healthcare                       e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
-- homelessness                     4938766b-b45a-46e3-93bd-b8b30651271a
-- homelessness-response            6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- immigration                      4e2c69ce-591e-4197-9cd5-7aceff79d390
-- jail-capacity                    c267e137-0ff9-4e7d-9d13-e3cea1756cd0
-- judicial-access-to-justice       9d45acaf-1ba4-4cb8-95e1-5ed985223b91
-- judicial-bail-pretrial           1fab5edf-6151-4da0-9704-a7f2113ba54c
-- judicial-criminal-justice        9db07b16-1076-4b7d-ad89-ebe7b51f4336
-- judicial-government-deference    e5e48f0e-8f3a-40e1-8080-889fea389603
-- judicial-interpretation          448b1c9a-b6f3-42b8-8f39-d3bbb5bfa9ee
-- judicial-police-accountability   7bad33eb-e93e-4d94-8822-97212d49bde5
-- judicial-prosecution-priorities  abb99d95-cbb1-4617-8f8b-f220ef6028ca
-- judicial-transparency            6674d87e-999d-433a-aab7-3f626f59fd5f
-- local-environment                1935979c-b290-42e4-baa5-8cb0138b4ffa
-- local-immigration                b9ccee94-ad96-4f10-b655-889d8e5abe92
-- medicare/aid                     cab61e8a-64fe-4bbd-bc08-fe9914d0091b
-- misinformation                   ddd65d64-9dc7-4208-a30f-59f4b9c0653d
-- public-safety-approach           e9ebefcd-c496-45e8-b816-a79f8442ba85
-- redistricting                    48cc9585-ec22-4f53-8d42-6839828dd36f
-- religious-freedom                6b9ba6d9-1001-43f5-b073-4d37130696fd
-- rent-regulation                  c308e8e8-caac-44f5-ab04-dbfecf40bbe2
-- residential-zoning               d4f18138-a2e0-4110-b925-7387d9d0d16d
-- same-sex-marriage                c5ab4eab-702f-49b8-9277-8ea53f3835c6
-- school-vouchers                  00b95a6a-75db-4521-b523-3326bba938de
-- social-security                  87d20824-a6e9-407b-983c-65440084a0ab
-- tariffs                          683c8084-2281-4920-a07c-18439b2dd413
-- taxes                            f7e5678d-dadd-4556-a2fc-446e24642ceb
-- trans-athletes                   d1618b9c-0b9e-45af-b986-bb33d270b8e4
-- transportation-priorities        ba59337e-30e2-4aba-a39a-426b3366eb27
-- ukraine-support                  24e9212c-b011-422a-865c-093e35050901
-- voting-rights                    d1792200-1d3b-4955-a0b7-0e6980d7a7b2

BEGIN;

-- ----- Jon Mitchell / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5114097d-c06a-4147-85bc-f9a6646f5c46',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5114097d-c06a-4147-85bc-f9a6646f5c46',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Mitchell has made economic development through the offshore wind industry his signature policy priority. New Bedford became the staging port for Vineyard Wind (the first commercial-scale offshore wind project in the US), and Mitchell established the New Bedford Marine Commerce Terminal for the wind industry. He secured multi-million dollar federal grants to improve port infrastructure and is pursuing a second terminal at a former Eversource power plant site. He stated New Bedford's goal is to become "the top blue economy on the East Coast." He actively recruited European wind companies and led delegations to Bremerhaven and Cuxhaven to attract investment. This reflects a strong government-investment and public-partnership approach to economic development.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jon_Mitchell_(politician)', 'https://newbedfordlight.org/tag/mayor-mitchell/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon Mitchell / growth-and-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5114097d-c06a-4147-85bc-f9a6646f5c46',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5114097d-c06a-4147-85bc-f9a6646f5c46',
        'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
        $$Under Mitchell, New Bedford has invested in major waterfront development including the New Bedford Marine Commerce Terminal, a second offshore wind terminal at the former Eversource site, and upgrades to parks, streets and sidewalks. Mitchell's 2022 State of the City address cited "economic development that is taking place on the waterfront" as a signature accomplishment. He has advocated for waterfront investment to prepare for the offshore wind industry similar to European port cities. This reflects a strongly pro-growth, pro-development agenda focused on industrializing and modernizing the city's working waterfront.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jon_Mitchell_(politician)', 'https://newbedfordlight.org/new-spending-will-include-5-million-for-zeiterion-renovations-mitchell-announces-in-speech/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon Mitchell / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5114097d-c06a-4147-85bc-f9a6646f5c46',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5114097d-c06a-4147-85bc-f9a6646f5c46',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Mitchell has been a prominent champion of offshore wind energy development, positioning New Bedford as a hub for the East Coast's clean energy transition. He hosted Governor Maura Healey's first official event as Governor — a climate summit at UMass Dartmouth in January 2023 — and endorsed Healey's 2022 gubernatorial campaign. Healey ran explicitly on climate action and renewable energy. Mitchell's entire economic development strategy is built around transitioning the port to serve the offshore wind industry, aligning city investment with the clean energy sector.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jon_Mitchell_(politician)', 'https://www.nbcboston.com/news/local/maura-healey-first-official-event-new-bedford-climate-summit/2924753/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon Mitchell / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5114097d-c06a-4147-85bc-f9a6646f5c46',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5114097d-c06a-4147-85bc-f9a6646f5c46',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Mitchell is a former Assistant United States Attorney who served as lead prosecutor for the federal task force that located Boston mob boss Whitey Bulger. His law enforcement background shapes his public safety philosophy. As mayor, he appointed Police Chief Joseph Cordeiro in 2016 and then appointed Cordeiro's deputy Paul Oliveira as successor in 2021, maintaining continuity of enforcement leadership. Under this approach, overall crime dropped 39% from 2016 to 2021 with violent crimes dropping below 600 in FBI verified reports. His public safety strategy emphasizes professional law enforcement and crime reduction through traditional policing rather than social service-first approaches.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jon_Mitchell_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon Mitchell / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5114097d-c06a-4147-85bc-f9a6646f5c46',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5114097d-c06a-4147-85bc-f9a6646f5c46',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Mitchell has been a consistent advocate for the South Coast Rail project, which restored commuter rail service from New Bedford and Fall River to Boston after decades of absence. New Bedford's South Station stop is part of Phase 1 which opened in 2023-2024. Mitchell also advocated through the New Bedford Port Authority for federal grants to improve port infrastructure for both the commercial fishing fleet and the offshore wind industry. His transportation stance favors public transit investment and port/freight infrastructure over auto-centric development.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jon_Mitchell_(politician)', 'https://en.wikipedia.org/wiki/South_Coast_Rail']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jon Mitchell / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5114097d-c06a-4147-85bc-f9a6646f5c46',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5114097d-c06a-4147-85bc-f9a6646f5c46',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$New Bedford, under Mitchell's administration, complied with the Massachusetts MBTA Communities Act by adopting multi-family zoning overlays near commuter rail transit stations. The law requires MBTA communities to zone for higher-density residential development near transit as a condition of state funding. Mitchell's city government passed the required zoning changes, reflecting support for transit-oriented housing density. New Bedford as a Gateway City with a high renter population and affordability challenges benefits from increased housing supply.$$,
        ARRAY['https://www.mass.gov/guides/multi-family-zoning-requirement-for-mbta-communities', 'https://en.wikipedia.org/wiki/Jon_Mitchell_(politician)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
