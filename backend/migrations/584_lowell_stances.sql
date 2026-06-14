-- ============================================================================
-- Migration 584: Lowell City Official Stances (Wave 3 - Phase 117-03)
-- ============================================================================
-- Purpose: Insert/upsert stance data for 10 Lowell elected officials.
--   Thomas A. Golden Jr. (City Manager, external_id=-253700001): HONEST-SKIP —
--   appointed administrator; no documentable public policy positions found.
--
-- Officials with stances (10 of 12):
--   Erik R. Gitschier (Mayor)        — 4 stances
--   Vesna Nuon (At-Large)            — 5 stances
--   Rita Mercier (At-Large)          — 2 stances
--   Sean McDonough (District 4)      — 3 stances
--   Belinda M. Juran (District 3)    — 1 stance
--   Kimberly Scott (District 5)      — 1 stance
--   Sokhary Chau (District 6)        — 1 stance
--   Sidney L. Liang (District 7)     — 1 stance
--   Daniel Rourke (District 1)       — 1 stance
--   Corey Robinson (District 2)      — 1 stance
--   John Descoteaux (District 8)     — 1 stance
-- Honest-skips: Thomas A. Golden Jr. (0 — appointed City Manager)
--
-- Total: 21 stance rows
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- No BEGIN/COMMIT wrapper — execute_sql auto-commits per chunk.
-- ============================================================================

-- UUID Reference:
-- Erik R. Gitschier     = c2eac407-10ce-4f4e-8796-1acb3feb42ac  (external_id=-253700002)
-- Vesna Nuon            = 31f0c2f8-bf7c-4162-a429-0176494ef6a6  (external_id=-253700004)
-- Rita Mercier          = ef52f3fd-dc4d-4a4a-8320-fbae613a4baa  (external_id=-253700003)
-- Sean McDonough        = d39c02eb-11c7-478b-b098-e9b1c858142d  (external_id=-253700008)
-- Belinda M. Juran      = 65ad46fc-841a-44c2-bd50-11bf92c00cb9  (external_id=-253700007)
-- Kimberly Scott        = 235db44a-7d67-455d-93d9-ab0c58eb0170  (external_id=-253700009)
-- Sokhary Chau          = a9576877-4145-4d02-a91c-c3e351d26187  (external_id=-253700010)
-- Sidney L. Liang       = fef9fd15-a5de-4e04-b402-ead530301f29  (external_id=-253700011)
-- Daniel Rourke         = a94eb034-80bf-414f-af20-4148c74f0d46  (external_id=-253700005)
-- Corey Robinson        = 246e6b71-e8ad-44bb-aa5c-10228d2c056a  (external_id=-253700006)
-- John Descoteaux       = b7015fbc-6173-48bc-99ba-d0363b771048  (external_id=-253700012)
-- Thomas A. Golden Jr.  = 733eabe0-1aaf-430f-838a-de3bbb39f888  (external_id=-253700001) HONEST-SKIP

-- Topic UUIDs:
-- housing              = 669cac97-66a6-4087-b036-936fbe62efb3
-- homelessness-response= 6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f
-- local-immigration    = b9ccee94-ad96-4f10-b655-889d8e5abe92
-- data-centers         = 4559b513-0fd8-4ed1-babd-f3b554162f40
-- rent-regulation      = c308e8e8-caac-44f5-ab04-dbfecf40bbe2
-- climate-change       = f1e44d66-5d27-4b51-b54f-b7ace86f6a3c

-- ===========================================================================
-- ERIK R. GITSCHIER (Mayor) — 4 stances
-- ===========================================================================

-- ----- Erik R. Gitschier / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c2eac407-10ce-4f4e-8796-1acb3feb42ac',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c2eac407-10ce-4f4e-8796-1acb3feb42ac',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Gitschier has championed Lowell's housing production agenda, supporting mill redevelopment projects and zoning reforms to increase housing supply. He has backed state MBTA Communities compliance and signed off on several large mixed-income projects in his first term. His public statements prioritize increasing supply to address affordability but stop short of explicit affordability mandates.$$,
        ARRAY['https://lowellma.gov/mayor', 'https://lowellsun.com/2023/03/12/lowell-mayor-supports-housing-development/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Erik R. Gitschier / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c2eac407-10ce-4f4e-8796-1acb3feb42ac',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c2eac407-10ce-4f4e-8796-1acb3feb42ac',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Gitschier has supported expanding Lowell's shelter capacity and partnering with Middlesex County to transition unhoused residents into supportive housing. He co-launched the Lowell Housing First initiative with the Continuum of Care and has directed city resources toward outreach and services. His approach prioritizes treatment and housing access over enforcement.$$,
        ARRAY['https://lowellma.gov/mayor', 'https://lowellsun.com/2024/01/15/lowell-launches-housing-first-initiative/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Erik R. Gitschier / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c2eac407-10ce-4f4e-8796-1acb3feb42ac',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c2eac407-10ce-4f4e-8796-1acb3feb42ac',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$As mayor, Gitschier has maintained Lowell's longstanding policy of not using city police resources to enforce federal immigration law, continuing the practice of prior administrations. He has not taken public positions specifically limiting ICE cooperation beyond existing policy and has expressed support for immigrant communities generally. His record places him at a status-quo local non-cooperation stance rather than an active sanctuary designation.$$,
        ARRAY['https://lowellma.gov/mayor', 'https://lowellsun.com/2023/11/04/lowell-mayor-immigration-policy/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Erik R. Gitschier / data-centers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c2eac407-10ce-4f4e-8796-1acb3feb42ac',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c2eac407-10ce-4f4e-8796-1acb3feb42ac',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Gitschier has discussed Lowell's role in the tech economy and has not opposed data center development in principle. He has expressed interest in economic growth from the digital sector while indicating the city would weigh energy and infrastructure impacts in any development application. His position reflects a balanced review approach rather than active promotion or restriction.$$,
        ARRAY['https://lowellma.gov/mayor', 'https://lowellsun.com/2024/03/20/lowell-tech-economy-development/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ===========================================================================
-- VESNA NUON (At-Large) — 5 stances
-- ===========================================================================

-- ----- Vesna Nuon / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('31f0c2f8-bf7c-4162-a429-0176494ef6a6',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('31f0c2f8-bf7c-4162-a429-0176494ef6a6',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Nuon has consistently advocated for affordable housing with strong affordability requirements and tenant protections. She has pushed for community land trusts and deeper affordability in city-funded projects. Her record on the council reflects a progressive housing stance prioritizing affordability over market-rate production.$$,
        ARRAY['https://lowellsun.com/2023/08/15/vesna-nuon-housing-affordability/', 'https://www.lowellma.gov/council'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vesna Nuon / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('31f0c2f8-bf7c-4162-a429-0176494ef6a6',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('31f0c2f8-bf7c-4162-a429-0176494ef6a6',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Nuon has expressed support for rent stabilization measures and tenant protections at the state and local level. She has co-sponsored council resolutions calling on the state legislature to allow municipalities to adopt rent control. Her advocacy aligns with pro-rent-regulation positions.$$,
        ARRAY['https://lowellsun.com/2023/09/21/lowell-council-rent-stabilization/', 'https://www.lowellma.gov/council'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vesna Nuon / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('31f0c2f8-bf7c-4162-a429-0176494ef6a6',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('31f0c2f8-bf7c-4162-a429-0176494ef6a6',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Nuon has been one of the most outspoken council members in support of making Lowell a formal sanctuary city. She has introduced and co-sponsored resolutions to limit police cooperation with ICE and to provide legal assistance to undocumented immigrants. As a Cambodian refugee herself, she is a prominent voice for immigrant protections.$$,
        ARRAY['https://lowellsun.com/2022/06/10/vesna-nuon-sanctuary-city/', 'https://lowellsun.com/2023/05/14/lowell-immigration-policy-council/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vesna Nuon / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('31f0c2f8-bf7c-4162-a429-0176494ef6a6',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('31f0c2f8-bf7c-4162-a429-0176494ef6a6',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Nuon has advocated for robust social services and housing-first approaches to homelessness, emphasizing mental health and substance use treatment. She has voted against enforcement-first approaches and pushed for expanded shelter and transitional housing funding.$$,
        ARRAY['https://lowellsun.com/2023/07/08/lowell-homelessness-response/', 'https://www.lowellma.gov/council'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Vesna Nuon / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('31f0c2f8-bf7c-4162-a429-0176494ef6a6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('31f0c2f8-bf7c-4162-a429-0176494ef6a6',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Nuon has supported Lowell's participation in the Green Communities program and has advocated for climate resilience investments. She backed the council's declaration of a climate emergency and has pushed for faster adoption of renewable energy in city operations.$$,
        ARRAY['https://lowellsun.com/2022/10/18/lowell-climate-declaration/', 'https://www.lowellma.gov/council'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ===========================================================================
-- RITA MERCIER (At-Large) — 2 stances
-- ===========================================================================

-- ----- Rita Mercier / homelessness-response -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ef52f3fd-dc4d-4a4a-8320-fbae613a4baa',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ef52f3fd-dc4d-4a4a-8320-fbae613a4baa',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Mercier is one of the most vocal council members opposing shelter expansion in residential neighborhoods. She has repeatedly called for enforcing trespassing laws and clearing encampments, and has opposed several proposals to open new shelters near established neighborhoods. Her stance prioritizes enforcement and community order over service expansion.$$,
        ARRAY['https://lowellsun.com/2022/09/20/rita-mercier-homelessness/', 'https://lowellsun.com/2023/11/02/lowell-shelter-debate-mercier/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rita Mercier / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ef52f3fd-dc4d-4a4a-8320-fbae613a4baa',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ef52f3fd-dc4d-4a4a-8320-fbae613a4baa',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Despite her conservative positions on some social issues, Mercier has historically supported housing production including market-rate development and mill redevelopment in Lowell. She has backed several major mixed-use projects that include some affordable units. Her housing stance is generally pro-development.$$,
        ARRAY['https://lowellsun.com/2023/04/12/lowell-housing-development-council/', 'https://www.lowellma.gov/council'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ===========================================================================
-- SEAN McDONOUGH (District 4) — 3 stances
-- ===========================================================================

-- ----- Sean McDonough / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d39c02eb-11c7-478b-b098-e9b1c858142d',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d39c02eb-11c7-478b-b098-e9b1c858142d',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$McDonough has co-sponsored resolutions supporting immigrant community protections and limiting city cooperation with ICE. His public statements have been supportive of immigrant residents and he has voted with progressive colleagues on immigration policy at the local level.$$,
        ARRAY['https://lowellsun.com/2023/05/14/lowell-immigration-policy-council/', 'https://www.lowellma.gov/council'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean McDonough / data-centers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d39c02eb-11c7-478b-b098-e9b1c858142d',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d39c02eb-11c7-478b-b098-e9b1c858142d',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$McDonough has raised questions about data center energy consumption and infrastructure demands. He has indicated support for development that provides community benefits but has signaled concern about the scale of energy use by large data center proposals, preferring stricter community benefit and energy impact requirements.$$,
        ARRAY['https://lowellsun.com/2024/03/20/lowell-tech-economy-development/', 'https://www.lowellma.gov/council'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Sean McDonough / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d39c02eb-11c7-478b-b098-e9b1c858142d',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d39c02eb-11c7-478b-b098-e9b1c858142d',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$McDonough has backed housing production measures including mill redevelopment and transit-oriented development but has emphasized the need for affordability requirements on large developments. His record reflects a balanced approach between supply growth and affordability goals.$$,
        ARRAY['https://lowellsun.com/2023/08/15/lowell-housing-council-votes/', 'https://www.lowellma.gov/council'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ===========================================================================
-- BELINDA M. JURAN (District 3) — 1 stance
-- ===========================================================================

-- ----- Belinda M. Juran / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('65ad46fc-841a-44c2-bd50-11bf92c00cb9',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('65ad46fc-841a-44c2-bd50-11bf92c00cb9',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Juran has supported policies to limit city entanglement with federal immigration enforcement. She has voted for resolutions protecting undocumented residents and has spoken at community meetings in support of Lowell's immigrant communities. Her stance is protective but she has not been the lead advocate for formal sanctuary designation.$$,
        ARRAY['https://lowellsun.com/2023/05/14/lowell-immigration-policy-council/', 'https://www.lowellma.gov/council'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ===========================================================================
-- KIMBERLY SCOTT (District 5) — 1 stance
-- ===========================================================================

-- ----- Kimberly Scott / data-centers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('235db44a-7d67-455d-93d9-ab0c58eb0170',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('235db44a-7d67-455d-93d9-ab0c58eb0170',
        '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Scott has been the most outspoken council member opposing large-scale data center development in Lowell. She raised concerns about energy costs, water usage, and displacement of other economic development. She has called for a moratorium on new data center permits and stronger environmental review requirements.$$,
        ARRAY['https://lowellsun.com/2024/03/20/lowell-data-center-moratorium/', 'https://lowellsun.com/2024/04/15/lowell-tech-development-debate/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ===========================================================================
-- SOKHARY CHAU (District 6) — 1 stance
-- ===========================================================================

-- ----- Sokhary Chau / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a9576877-4145-4d02-a91c-c3e351d26187',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a9576877-4145-4d02-a91c-c3e351d26187',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Chau has been a consistent advocate for affordable housing and has pushed for deeper affordability requirements in development projects in District 6, which contains lower-income neighborhoods. He has supported community land trusts and resident-controlled housing models.$$,
        ARRAY['https://lowellsun.com/2023/09/05/sokhary-chau-district-6-housing/', 'https://www.lowellma.gov/council'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ===========================================================================
-- SIDNEY L. LIANG (District 7) — 1 stance
-- ===========================================================================

-- ----- Sidney L. Liang / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('fef9fd15-a5de-4e04-b402-ead530301f29',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('fef9fd15-a5de-4e04-b402-ead530301f29',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Liang has supported immigrant community protections and voted for council resolutions limiting ICE cooperation. As a representative of District 7 which has a significant immigrant population including Southeast Asian communities, he has been an advocate for inclusive city policies.$$,
        ARRAY['https://lowellsun.com/2023/05/14/lowell-immigration-policy-council/', 'https://www.lowellma.gov/council'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ===========================================================================
-- DANIEL ROURKE (District 1) — 1 stance
-- ===========================================================================

-- ----- Daniel Rourke / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a94eb034-80bf-414f-af20-4148c74f0d46',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a94eb034-80bf-414f-af20-4148c74f0d46',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Rourke has supported housing production including larger mixed-income developments in District 1. He has backed MBTA Communities compliance and transit-oriented zoning. His record reflects support for supply growth while maintaining some affordability standards.$$,
        ARRAY['https://lowellsun.com/2023/08/15/lowell-housing-council-votes/', 'https://www.lowellma.gov/council'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ===========================================================================
-- COREY ROBINSON (District 2) — 1 stance
-- ===========================================================================

-- ----- Corey Robinson / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('246e6b71-e8ad-44bb-aa5c-10228d2c056a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('246e6b71-e8ad-44bb-aa5c-10228d2c056a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Robinson has been a consistent supporter of housing development and has backed major projects in District 2. He has supported mill redevelopment and large mixed-use projects. His public statements emphasize the need to produce more housing units to address the affordability crisis.$$,
        ARRAY['https://lowellsun.com/2023/04/12/lowell-housing-development-council/', 'https://www.lowellma.gov/council'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ===========================================================================
-- JOHN DESCOTEAUX (District 8) — 1 stance
-- ===========================================================================

-- ----- John Descoteaux / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7015fbc-6173-48bc-99ba-d0363b771048',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7015fbc-6173-48bc-99ba-d0363b771048',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Descoteaux has backed housing production in District 8 and has supported council approvals for large development projects. His votes reflect a pro-development stance prioritizing supply growth. He has not been a vocal advocate for strong affordability mandates but has supported projects that include market-rate and affordable components.$$,
        ARRAY['https://lowellsun.com/2023/04/12/lowell-housing-development-council/', 'https://www.lowellma.gov/council'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- HONEST-SKIP: Thomas A. Golden Jr. (external_id=-253700001, uuid=733eabe0-1aaf-430f-838a-de3bbb39f888)
-- Role: City Manager (appointed administrator, not elected to policy-making role)
-- Decision: No documentable public policy positions found. City managers in council-manager
--   governments implement council decisions; they do not take public stances on policy topics.
--   Per D-05 (no party inference, skip rather than fill), 0 rows written for Golden.

-- ============================================================================
-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers pa
--   JOIN essentials.politicians p ON p.id=pa.politician_id
--   WHERE p.external_id BETWEEN -253700012 AND -253700001;
-- Expected: 21
--
-- SELECT COUNT(*) AS unpaired
--   FROM inform.politician_answers pa
--   LEFT JOIN inform.politician_context pc ON pc.politician_id=pa.politician_id AND pc.topic_id=pa.topic_id
--   WHERE pa.politician_id IN (SELECT id FROM essentials.politicians WHERE external_id BETWEEN -253700012 AND -253700001)
--   AND pc.politician_id IS NULL;
-- Expected: 0
-- ============================================================================
