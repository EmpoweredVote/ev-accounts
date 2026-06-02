-- ============================================================================
-- Migration 233: CA Assembly + CA State Senate (batch5) Stances — 34 Politicians
-- ============================================================================
-- Purpose: Insert/upsert stance data from assembly batches 1-5 (researched 2026-05-18).
--
-- Scope: 34 politicians (32 CA Assembly members + 2 CA State Senators from batch5)
--        306 stance rows total
--
-- Idempotency: ON CONFLICT DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

BEGIN;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Voted YES SB-525 (healthcare worker minimum wage 2023), authored AB-483 (Medi-Cal billing for schools, 2023), voted YES AB-1432 (health coverage expansion 2023). Supports expanding coverage through existing programs.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202320240AB483', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1432']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES AB-2223 (reproductive health 2022), YES SB-1375 (nurse practitioners/abortion 2022), YES AB-2099 (crimes: reproductive health services 2024). Consistent support for abortion access and provider protections.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220AB2223', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB1375', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB2099']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Chairs Joint Legislative Committee on Climate Change Policies. Authored AB-605 (lower emissions cargo equipment 2025), AB-1216 (wastewater air monitoring 2023), AB-986 (emergency declarations/climate 2025). Strong track record on climate legislation.$$,
        ARRAY['https://en.wikipedia.org/wiki/Al_Muratsuchi', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202520260AB605', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202320240AB1216']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', 'a22215c3-6693-4bc2-b248-01aebba14570', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Voted YES AB-1167 (oil and gas bonding requirements 2023). Authored AB-605 (lower-emissions port equipment pilot — bridges to zero emission, does not ban). Prior AB-345 oil well setback bill blocked in 2020 session. Maintains current regulations while pushing incremental reductions.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1167', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202520260AB605', 'https://en.wikipedia.org/wiki/Al_Muratsuchi']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Authored and chaptered AB-49 (2025) — Safe Haven Schools Act blocking ICE enforcement at schools without judicial warrant. Voted YES AB-1840 (2024) expanding home purchase assistance regardless of immigration status. Protective of immigrant communities.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202520260AB49', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1840']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Authored AB-49 (2025) expressly prohibiting immigration enforcement access to school grounds without judicial warrant; requires schools to report ICE requests to board. Supports legal pathways and does not support deportation of long-term residents.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202520260AB49']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', '669cac97-66a6-4087-b036-936fbe62efb3', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Voted NO SB-9 (upzoning/lot-splitting 2021). Voted YES SB-423 (multifamily streamlining 2023), YES AB-1287 (density bonus 2023), authored AB-2741 (housing element/affordable overlay zones 2025). Mixed record: opposed blanket upzoning but supports targeted affordable housing tools.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB9', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB423', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202520260AB2741']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Voted YES SB-403 (caste/ancestry discrimination 2023), AB-1078 (curriculum diversity 2023), AB-1955 (LGBTQ student privacy 2024), AB-2326 (higher ed discrimination compliance 2024). Consistent support for strengthening civil rights protections.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB403', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1078', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Voted YES AB-1955 (LGBTQ student privacy/rights 2024), YES AB-1084 (gender neutral retail 2021), YES SB-107 (gender-affirming healthcare 2022). Consistent support for LGBTQ equality measures.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220AB1084', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB107']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Voted YES SB-107 (gender-affirming healthcare 2022), YES AB-1955 (protecting LGBTQ student rights including sports/activities 2024). Supports transgender inclusion without restrictions based on birth sex.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB107', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Voted YES AB-1248 (local independent redistricting commissions 2023). Supports expanding voter participation infrastructure at local level.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1248']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Voted YES AB-1248 (requiring local jurisdictions to use independent redistricting commissions 2023). Supports independent commissions with bipartisan balance over purely partisan legislative control.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1248']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', '00b95a6a-75db-4521-b523-3326bba938de', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Education-focused legislator: authored AB-1825 (CA Freedom to Read Act protecting public library collections 2023), AB-247 (school facilities bond), AB-938 (education staff salaries). Entire legislative record is oriented toward strengthening public schools.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202320240AB1825', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202320240AB938']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Authored AB-1428 (CA Affordable Childcare Act 2025): imposes 0.5% tax on income >$10M to fund licensed childcare subsidies 2026-2030. Bill died in Appropriations but represents strong stance for publicly subsidized childcare expansion.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202520260AB1428']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Voted YES AB-2655 (Defending Democracy from Deepfake Deception Act 2024) requiring platforms to label deepfake political content. Authored AB-1825 (CA Freedom to Read Act) protecting libraries from content censorship.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB2655']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', '666bf03d-81fc-4138-ab15-69ae734c9023', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Voted YES SB-1047 (Safe and Secure Innovation for Frontier AI Models Act 2024) on assembly floor. Supports government oversight and safety testing requirements before deploying advanced AI — aligns with mandatory pre-deployment review.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1047']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Authored AB-1428 (2025) imposing 0.5% supplemental tax on income >$10M to fund childcare — a targeted millionaire tax. Pattern of authored education funding bills (AB-938 teacher salaries, AB-247 school facilities bonds) that rely on increased public revenue.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202520260AB1428']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Authored AB-483 (Medi-Cal billing reform for schools 2023). Voted YES SB-525 (healthcare worker minimum wage 2023). Supports expanding Medi-Cal coverage and improving program administration.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202320240AB483', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ea803096-927f-41fe-98e1-deab56291810', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Voted YES AB-1817 (homeless youth services 2024). 2025-26 session bill list included homelessness courts legislation (AB-1205 died). Supports service-led approaches for unhoused populations.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1817']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Authored AB-1707 (2023 chaptered): prohibits CA licensing boards from disciplining providers based on out-of-state actions for services legal in CA (abortion protection). Voted YES AB-2099 (crimes: reproductive health services 2024). Core champion of reproductive provider protections.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202320240AB1707', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB2099']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Authored AB-1707 (healthcare provider protections 2023). Authored AB-1612 (clinic licensure — vetoed). Voted YES SB-729 (fertility coverage 2024), YES SB-525 (healthcare worker minimum wage 2023). Supports expanding coverage through existing programs.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202320240AB1707', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB729']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Voted YES AB-1078 (curriculum diversity 2023), AB-2326 (higher ed discrimination compliance 2024). Authored AB-2024 (domestic violence restraining orders 2024 chaptered). Consistent support for civil rights enforcement.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1078', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB2326']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Voted YES AB-1840 (2024) expanding home purchase assistance regardless of immigration status. AB-1707 protects CA providers from out-of-state laws restricting services to immigrants. Legal pathways focus.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1840']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Voted YES AB-1840 removing immigration status as disqualifier from homebuying programs (2024). AB-1707 implicitly supports immigrants accessing healthcare without fear of legal exposure. Prioritizes legal pathways over deportation.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1840']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Voted YES SB-4 (housing on religious/educational institution land 2023), YES AB-1287 (density bonus 2023). Authored AB-1852 (Clean Power Alliance meeting reform). Supports expanding housing supply through targeted zoning changes.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB4', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1287']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Voted YES AB-1955 (LGBTQ student privacy and rights 2024). Authored AB-1707 protecting all patients including LGBTQ individuals from out-of-state enforcement. Supports full equality.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Voted YES SB-107 (gender-affirming healthcare 2022) and YES AB-1955 (LGBTQ student rights 2024). Supports transgender student inclusion without restrictions.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB107', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Voted YES AB-1248 (local independent redistricting commissions 2023). Supports independent oversight of elections.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1248']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Voted YES AB-1248 (independent redistricting commissions for local government 2023). Supports independent commissions with bipartisan balance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1248']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Authored AB-324 (renewable gas procurement — died in Appropriations 2023). Authored AB-1912 (electricity mandated programs 3rd-party review — died 2023). Voted YES Cap-and-Invest related measures. Supports clean energy transition but authored oversight/review bill suggesting cost awareness.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1912']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', 'a22215c3-6693-4bc2-b248-01aebba14570', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Authored AB-1912 (requiring 3rd-party review of electricity mandated programs including fossil fuel transition costs 2023). Authored AB-324 (renewable gas procurement). Favors managed transition with cost oversight rather than immediate bans.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1912']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', '666bf03d-81fc-4138-ab15-69ae734c9023', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Voted YES SB-1047 (AI safety bill) in Judiciary Committee (2024). Supports mandatory safety review before releasing advanced AI systems.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB1047']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Voted YES AB-2655 (Defending Democracy from Deepfake Deception Act 2024) requiring labeling of AI-generated political content. Supports platform transparency requirements.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB2655']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Voted YES SB-525 (healthcare worker minimum wage 2023). Authored AB-1707 protecting healthcare providers — indirectly strengthens Medi-Cal provider network. Supports strengthening existing programs.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c9205ba1-d0c8-4f17-a165-fb2a8fdae742', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Voted YES AB-1817 (homeless youth services 2024). Authored AB-695 (Juvenile Detention Facilities Improvement — vetoed 2023). Supports service-based approaches.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1817']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES AB-2223 (reproductive health 2022), YES SB-1375 (nurse practitioners/abortion 2022), YES AB-2099 (reproductive health crimes 8/28/24). Wikipedia notes she has authored bills supporting immigrant communities and domestic violence survivors; all recorded abortion-related votes are in favor.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220AB2223', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB1375', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB2099']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Voted YES SB-729 (fertility coverage 2024), YES SB-525 (healthcare worker minimum wage 2023), YES AB-1432 (health coverage 2023). Consistent support for expanding healthcare access through the existing insured system.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB729', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1432']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Voted YES AB-1078 (curriculum diversity 2023), YES SB-403 (ancestry/caste discrimination 2023), YES AB-2326 (higher ed discrimination 2024). Wikipedia notes she authored bills supporting immigrant communities.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1078', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB403', 'https://en.wikipedia.org/wiki/Blanca_Rubio']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Voted YES AB-1840 (home purchase assistance regardless of immigration status 2024). Wikipedia notes she authored legislation supporting immigrant communities. Supports legal pathways and immigrant integration.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1840', 'https://en.wikipedia.org/wiki/Blanca_Rubio']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Voted YES AB-1840 removing immigration status barrier from homebuying programs. Wikipedia notes authored immigrant community support legislation. Prioritizes legal status pathways over enforcement/deportation.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1840', 'https://en.wikipedia.org/wiki/Blanca_Rubio']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Voted YES SB-423 (multifamily housing streamlining 2023), YES AB-1287 (density bonus 2023), NVR on SB-9 (upzoning 2021). Supports expanding housing supply through zoning reform and density bonuses.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB423', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1287']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Voted YES AB-1955 (LGBTQ student privacy/rights 2024), YES AB-1084 (gender neutral retail 2021), YES SB-107 (gender-affirming healthcare 2022). Consistent support for LGBTQ equality.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220AB1084', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB107']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Voted YES SB-107 (gender-affirming healthcare 2022), YES AB-1955 (LGBTQ student rights 2024). Supports transgender inclusion without restrictions based on assigned sex.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB107', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Voted YES AB-1248 (local independent redistricting commissions 2023). Supports independent oversight of electoral processes.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1248']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Voted YES AB-1248 (independent redistricting commissions for local government 2023). Favors independent commissions with bipartisan equal representation.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1248']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Voted YES AB-2655 (Defending Democracy from Deepfake Deception Act 2024). Supports mandatory fact-labeling and transparency for AI-generated political content.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB2655']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Voted YES SB-525 (healthcare worker minimum wage 2023), YES SB-729 (fertility coverage 2024). Supports expanding Medi-Cal and healthcare program coverage.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB729']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('51d15b77-71bb-475e-b86e-c6e1b37b869d', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Voted YES AB-1817 (homeless youth services 2024). Authored bills supporting domestic violence survivors and vulnerable populations. Supports service-based approaches.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1817']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES AB-2223 (reproductive health 2022), YES SB-1375 (nurse practitioners/abortion 2022), YES AB-2099 (reproductive health crimes 2024). Consistent support for abortion access.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220AB2223', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB1375', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB2099']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Voted YES SB-729 (fertility coverage 2024), YES SB-525 (healthcare worker minimum wage 2023). Voted in Assembly Health Committee on AB-2200 (CalCare single-payer) as NVR but committee member. Supports expanding coverage.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB729', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Voted YES AB-1078 (curriculum diversity 2023), YES AB-2326 (higher ed discrimination 2024). NVR on SB-403 (ancestry discrimination). Supports strengthening civil rights enforcement.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1078', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB2326']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Voted YES AB-1840 (home purchase assistance regardless of immigration status 2024). Voted YES SB-9 (upzoning 2021). Supports immigrant integration and legal pathways.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1840']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Voted YES AB-1840 (removing immigration status as disqualifier for homebuying programs 2024). Consistent with supporting legal pathways over enforcement-first approaches.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1840']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Voted YES SB-9 (upzoning/lot-splitting 2021), YES SB-423 (multifamily streamlining 2023), YES AB-1287 (density bonus 2023). Pro-density record across multiple housing bills.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB9', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB423', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1287']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Voted YES AB-1955 (LGBTQ student privacy/rights 2024), YES AB-1084 (gender neutral retail 2021), YES SB-107 (gender-affirming healthcare 2022). Consistent support for LGBTQ equality.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220AB1084', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB107']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Voted YES SB-107 (gender-affirming healthcare 2022), YES AB-1955 (LGBTQ student rights 2024). Supports transgender inclusion without restrictions.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB107', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Voted YES AB-1248 (local independent redistricting commissions 2023). Supports independent oversight of redistricting.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1248']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Voted YES AB-1248 (independent redistricting commissions for local government 2023). Supports independent commissions with bipartisan balance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1248']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Voted YES AB-2655 (Defending Democracy from Deepfake Deception Act 2024). Supports platform transparency and fact-checking requirements for AI-generated political content.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB2655']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Voted YES SB-525 (healthcare worker minimum wage 2023), YES SB-729 (fertility coverage 2024). NVR on CalCare (AB-2200) Assembly Health Committee 2024 but committee member.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB729']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f9cbe210-a840-4924-b4aa-a5de0dc143ba', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Voted YES AB-1817 (homeless youth services 2024). Supports service-led approaches to homelessness.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1817']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Voted YES SB-525 (healthcare worker minimum wage 2023), YES SB-729 (fertility coverage 2024), YES AB-1432 (health coverage 2023). Supports expanding access through regulated private and public programs.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB729', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1432']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Voted YES AB-2091 (disclosure/reproductive health 2022), YES AB-2099 (crimes: reproductive health services 2024). NVR on SB-1375 but authored AB-932 (sex/gender discrimination in youth sports extending equal protections). Strong reproductive rights record.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220AB2091', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB2099']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Authored and chaptered AB-1207 (2025): extends CA Cap-and-Invest program from 2031 to 2045 — landmark climate legislation maintaining market-based carbon pricing. Authored bills on EV charging networks and methane emissions. Clear commitment to rapid clean energy transition.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202520260AB1207']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', 'a22215c3-6693-4bc2-b248-01aebba14570', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Authored AB-1207 extending Cap-and-Invest through 2045 — a market mechanism allowing continued fossil fuel use with increasing cost. No new drilling ban; authored EV charging and methane bills. Supports market-driven transition, not immediate production bans.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202520260AB1207']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Voted YES AB-1840 (home purchase assistance regardless of immigration status 2024). No evidence of anti-immigration legislation. Supports immigrant integration.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1840']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Voted YES AB-1840 removing immigration status barrier from homebuying assistance (2024). No evidence of support for expanded deportation. Prioritizes legal integration pathways.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1840']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', '669cac97-66a6-4087-b036-936fbe62efb3', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Voted NO SB-9 (upzoning/lot-splitting 2021), YES SB-423 (multifamily streamlining 2023), YES AB-1287 (density bonus). Opposed blanket upzoning but supports targeted housing supply tools — aligns with maintaining current rules while allowing selective increases.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220SB9', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB423', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1287']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Voted YES AB-1078 (curriculum diversity 2023), YES SB-403 (ancestry discrimination 2023), YES AB-2326 (higher ed discrimination 2024). Authored AB-932 (sex/gender discrimination in youth athletics 2025 chaptered). Strong civil rights enforcement record.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1078', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB403', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202520260AB932']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Voted YES AB-1955 (LGBTQ student privacy/rights 2024), YES AB-1084 (gender neutral retail 2021). Authored AB-932 extending sex/gender equal protections in youth sports. Supports full equality.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202120220AB1084', 'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202520260AB932']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$NVR on SB-107 (gender-affirming healthcare 2022). Authored AB-932 (2025) prohibiting sex/gender discrimination in community youth athletics — ensures equal opportunity for girls based on proportionality standard. Supports participation rights with proportionality framework; stops short of full unrestricted access.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202520260AB932', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1955']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Voted YES AB-1248 (local independent redistricting commissions 2023). Supports independent oversight of elections.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1248']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- redistricting
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Voted YES AB-1248 (independent redistricting commissions for local government 2023). Supports bipartisan independent commissions.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1248']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Voted YES AB-2655 (Defending Democracy from Deepfake Deception Act 2024). Cybersecurity background (CCPA amendments, IoT security bills) aligns with platform transparency requirements.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB2655']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', '666bf03d-81fc-4138-ab15-69ae734c9023', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Authored AB-979 (2025 chaptered): requires CA Cybersecurity Integration Center to develop AI Cybersecurity Collaboration Playbook — mandatory contractor/vendor reporting of AI threats, with government oversight framework. Strong government oversight approach to AI security.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202520260AB979']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', '4559b513-0fd8-4ed1-babd-f3b554162f40', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Authored AB-979 (2025) on AI cybersecurity requiring state oversight of AI vendor risk. Prior cybersecurity bills (IoT security, CCPA amendments) show consistent approach: allow development with impact/security assessments and government approval before deployment. Does not ban data centers but requires compliance framework.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202520260AB979']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Voted YES SB-525 (healthcare worker minimum wage 2023), YES SB-729 (fertility coverage 2024). Supports strengthening existing Medicare/Medicaid programs and improving access.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB525', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240SB729']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('97285c92-b664-4687-a1e4-6d88cf9c7fe4', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Voted YES AB-1817 (homeless youth services 2024). Cybersecurity/data-focused legislator with no anti-homeless enforcement votes found. Supports service-expansion approach.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202320240AB1817']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Principal co-author of California constitutional amendment protecting reproductive freedom. DACA attorney who defended immigrants; website states he champions 'reproductive freedom' broadly. Wikipedia confirms co-authored CA constitutional amendment on marriage equality and reproductive rights.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jesse_Gabriel', 'https://www.jessegabriel.com/about-jesse', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB468']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', '666bf03d-81fc-4138-ab15-69ae734c9023', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Voted YES on AB-1018 (Bauer-Kahan, 2025), the automated decision systems oversight bill requiring government-approval-equivalent impact assessments and transparency for AI systems used in employment, housing, and criminal justice contexts. Bill passed 50-16 on June 2, 2025.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260AB1018']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', '4938766b-b45a-46e3-93bd-b8b30651271a', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Authored AB-299 (2025) extending disaster housing protections for displaced wildfire victims in motels; authored AB-468 (2025) strengthening looting penalties in evacuation zones - indicates enforcement dimension alongside housing support. No dedicated anti-criminalization bill found; authored bills suggest balanced enforcement-plus-services approach.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB299', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB468']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Co-authored AB-1806 (2026) on immigration officer shooting investigations; authored AB-2750 on housing preliminary application process; wife is an affordable housing attorney per biography. Website states he 'championed...affordable housing solutions.' Gabriel was not voting on SB-79 transit-oriented housing bill.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jesse_Gabriel', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2750', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB79']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Wikipedia states Gabriel 'championed climate change initiatives, electric vehicle charging infrastructure expansion, and water conservation measures.' Authored AB-794 (2025) strengthening California drinking water standards including PFAS regulations, maintaining stricter federal standards regardless of federal rollback. Former League of Conservation Voters board member.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jesse_Gabriel', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB794']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$As Assembly Budget Committee chair, Gabriel has supported California's clean energy transition. Wikipedia notes he championed climate initiatives. AB-794 (2025) explicitly protects drinking water standards against federal rollback - indicates strong environmental regulatory stance. No bill explicitly stopping new drilling permits found, but his climate record aligns with reducing fossil fuel reliance.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jesse_Gabriel', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB794']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Did not co-author AB-1900 (CalCare single-payer) unlike some colleagues, suggesting he supports expanding coverage without committing to full single-payer. Strong supporter of ACA subsidies as Budget Committee chair. No evidence of private-market-only stance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1900', 'https://en.wikipedia.org/wiki/Jesse_Gabriel']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Co-authored AB-1806 (2026) requiring independent investigations of federal immigration officer-involved shootings of civilians. Wikipedia notes he defended DACA recipients in 2017 as an attorney. These actions indicate strong immigrant protection stance while maintaining legal pathways rather than open borders.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1806', 'https://en.wikipedia.org/wiki/Jesse_Gabriel']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Co-authored AB-1806 (2026) creating accountability for federal immigration officer-involved shootings; DACA legal defender as attorney. Authored AB-421 (2025) immigration enforcement protections near sensitive sites as co-author. These actions suggest he supports only deporting serious violent offenders and protecting communities from aggressive immigration enforcement.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1806', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB421']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Wikipedia confirms Gabriel co-authored California constitutional amendment protecting marriage equality. He is Chair of the California Legislative Jewish Caucus and has a consistent civil rights record. Co-authored full federal protections and rights framework in state constitution.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jesse_Gabriel']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Wikipedia: 'served as principal co-author of constitutional amendments protecting reproductive freedom and marriage equality.' Authored anti-looting bills targeting evacuation zones but also co-authored AB-1806 (immigration officer accountability). Former civil rights attorney who represented domestic abuse victims, Holocaust survivors, and hate crime victims. Strong civil rights enforcement record.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jesse_Gabriel', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1806']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$As Assembly Budget Committee Chair representing a Democratic safe seat, Gabriel has supported expanding voting access. His broader civil rights record - co-authored CA constitutional amendments on reproductive freedom and marriage equality - indicates strong support for voting access expansion. No direct restrictive voting bill found.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jesse_Gabriel']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', '00b95a6a-75db-4521-b523-3326bba938de', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', '00b95a6a-75db-4521-b523-3326bba938de',
        $$No direct bill on vouchers found, but Gabriel authored multiple school food safety bills (AB-1264, AB-1626) investing in public school programs. His strong public education investment through the budget process as Assembly Budget Committee Chair and no endorsement of any private school voucher program indicates strong public school funding priority.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1264', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1626']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f173ce9a-6941-4570-bd3f-97bc1157beaf', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$As Assembly Budget Committee Chair, Gabriel shapes California's progressive budget framework. No evidence of flat-tax support or drastic cuts. His advocacy for gun industry taxes (Gun Violence Prevention and School Safety Act) and support for progressive budget priorities indicate modest increase stance targeting high earners.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jesse_Gabriel']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Campaign website states she 'fought to protect funding for Planned Parenthood and expand access to critical health care services for all women' and 'fought to protect reproductive freedom.' Former Deputy Chief of Staff to AG Rob Bonta - a strong reproductive rights advocate. AB-1500 (Schiavo bill she may have supported) establishes state abortion access website. Consistent with full legal access and public funding.$$,
        ARRAY['https://jessicacaloza.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', '666bf03d-81fc-4138-ab15-69ae734c9023', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Voted YES on AB-1018 (Bauer-Kahan, 2025) on the Assembly floor on June 2, 2025 - the automated decision systems oversight bill requiring impact assessments and government-level approval process for high-risk AI. Bill passed 50-16.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260AB1018']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Campaign website: 'accelerating affordable housing construction, improving resource accountability, and investing in programs connecting unhoused individuals to stable housing, mental health care, and job training.' Approach focuses on services, housing, and accountability - consistent with enforcement only after services are offered.$$,
        ARRAY['https://jessicacaloza.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Authored AB-672 (2025) extending community land trust tax exemptions to support affordable housing development. Website states 'fighting for stronger protections against unlawful evictions, especially for immigrants, seniors, and families.' Voted YES on SB-79 (transit-oriented housing) on Sep 11, 2025.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB672', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB79']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Campaign website states she 'fought for legislation to expand parks and open space, protect clean air and water, and reduce plastic waste' and identifies climate action and environmental justice as a top priority. No direct anti-fossil fuel ban bill found, consistent with rapid transition stance.$$,
        ARRAY['https://jessicacaloza.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Campaign website: 'protect access to healthcare' and protecting reproductive healthcare access. Formerly worked at U.S. Department of Education under Obama and in AG Bonta's office - both strong healthcare access advocates. AB-1750 (school employee sick leave bill she authored) reflects healthcare protection priority. Did not co-author single-payer AB-1900.$$,
        ARRAY['https://jessicacaloza.com/issues', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1750']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Authored AB-1300 (2025) - 'California Data Protection and Privacy for All Communities Act' restricting state/local agencies from collecting or sharing immigration data with federal immigration enforcement without judicial warrants. Worked in Mayor Garcetti's Office of Immigrant Affairs. AB-1650 (police vehicle markings) has civil liberties dimension.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1300']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Authored AB-1300 prohibiting sharing of immigration data with ICE without judicial warrants - a strong sanctuary protection measure. Background in Office of Immigrant Affairs under Garcetti indicates strong immigrant community protection philosophy. AB-1650 (marking of police vehicles for ICE use) also reflects anti-mass-deportation stance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1300']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$No direct bill found. As first Filipina in CA legislature with a strong civil rights and immigrant rights record, and working under AG Bonta (a vocal LGBTQ+ rights supporter), Caloza's progressive alignment indicates full support for same-sex marriage and federal protections.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jessica_Caloza']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Authored AB-1300 (immigrant data protection), AB-1980 (women in construction equity), AB-1650 (police vehicle accountability). Former Commissioner on LA Board of Public Works overseeing infrastructure equity. Strong civil rights enforcement record across multiple bill types.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1300', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1980']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Harabedian website says 'end Citizens United' and 'make voting more accessible and oppose ballot restrictions' - these are Harabedian's positions. For Caloza: strong civil rights record and progressive alignment suggest voting expansion support. No direct restrictive bill found.$$,
        ARRAY['https://jessicacaloza.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', '00b95a6a-75db-4521-b523-3326bba938de', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Website states 'invest in great public schools' and 'raising wages for teachers and school support staff and investing in early childhood education.' No support for voucher programs found. Progressive labor/education record focused exclusively on strengthening public education.$$,
        ARRAY['https://jessicacaloza.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Website: 'fighting to make the minimum wage a living wage and build an economy that works for everyone.' AB-1750 expands school employee compensation. Her former policy advisor role under Obama administration and progressive economic positions indicate modest tax increase on high earners stance.$$,
        ARRAY['https://jessicacaloza.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('685f2150-7b2a-4f94-992c-bf0cf23ffa69', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Website states she fought for 'investing in early childhood education' and authored AB-1980 (women in construction - includes childcare assistance in grant funding). Former Obama education policy advisor with strong early education focus. Consistent with significant expansion of childcare subsidies.$$,
        ARRAY['https://jessicacaloza.com/issues', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1980']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Campaign website: 'Defend access to birth control and abortion healthcare against federal restrictions.' Strong pro-choice language with no trimester limitations stated. Consistent with full legal access and public funding stance.$$,
        ARRAY['https://johnharabedian.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', '666bf03d-81fc-4138-ab15-69ae734c9023', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Voted YES on AB-1018 (Bauer-Kahan, 2025) in both committee (Assembly Judiciary, April 29) and floor vote (June 2, 2025). Co-authored AB-1018 in committee stage. Bill requires impact assessments and government approval before deploying high-risk AI systems.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260AB1018']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Campaign website: 'Declare a State of Emergency...Build affordable housing and increase shelter bed availability...Invest in Mental Healthcare through infrastructure improvements and supportive housing.' Approach prioritizes services, shelter, and mental health investment.$$,
        ARRAY['https://johnharabedian.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Voted YES on SB-79 (transit-oriented housing, Sep 11 2025). Co-authored AB-1806 on immigration officer accountability. Website: 'BUILD AFFORDABLE HOUSING to reduce homelessness and make homeownership possible for young families.' Strong housing expansion stance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB79', 'https://johnharabedian.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Website: 'COMBAT CLIMATE CHANGE by investing in the renewable energy and water infrastructure we urgently need.' Also: 'Fund renewable energy programs to reduce carbon emissions; Incentivize electric vehicle production and charging infrastructure; Safeguard air quality; Protect open space.' Co-authored AB-1960 wildfire resilience bill.$$,
        ARRAY['https://johnharabedian.com/issues', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1960']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Website supports rapid renewable energy transition and reducing carbon emissions. No explicit new-drilling-ban language found, but strong push to 'fund renewable energy programs to reduce carbon emissions' and 'safeguard air quality' aligns with stopping new fossil fuel permits.$$,
        ARRAY['https://johnharabedian.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Co-author of AB-1900 (2026) - the CalCare single-payer universal healthcare bill authored by Kalra, Bryan et al. Co-authorship of a full single-payer bill is the strongest signal for value 1 (free healthcare for all through single-payer).$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1900']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Co-authored AB-1806 (2026) requiring independent investigations of federal immigration officer-involved shootings. Co-authored AB-1650 (police vehicle markings for ICE use). Former deputy DA background combined with immigrant rights co-authorship indicates support for legal immigration pathways and protection of immigrant communities.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1806', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1650']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Co-authored AB-1806 (2026) creating accountability for federal immigration officer shootings - signals strong opposition to aggressive deportation enforcement. No evidence supporting mass deportation; co-authored immigrant protection legislation.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1806']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Website and progressive record indicate full support for same-sex marriage with federal protections. Former mayor of Sierra Madre; strong civil rights record in bills co-authored. No restrictive marriage legislation found.$$,
        ARRAY['https://johnharabedian.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Co-authored AB-1806 (immigration enforcement accountability), AB-1960 (wildfire community protection), AB-1900 (universal healthcare). Website supports 'conflict-of-interest rules' and election transparency. Strong civil rights enforcement record.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1806', 'https://johnharabedian.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Website: 'Make voting more accessible and oppose ballot restrictions.' Also: 'Strengthen conflict-of-interest rules and election reporting requirements' and 'Provide funding and tools for election security against cyberattacks.' Strongly supports expanding voting access.$$,
        ARRAY['https://johnharabedian.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- campaign-finance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', '92730f69-ae57-401c-8ad1-2d07834a895d', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Website explicitly states: 'End Citizens United and Super PACs' and 'Strengthen conflict-of-interest rules and election reporting requirements.' Strongest possible stance - banning private corporate money and publicly funding campaigns.$$,
        ARRAY['https://johnharabedian.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', '00b95a6a-75db-4521-b523-3326bba938de', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Website supports 'expanding college access' and K-12 education with 'competitive teacher compensation and expanded after-school programming.' No voucher support found. Record of supporting public schools exclusively, as former mayor who worked with local schools.$$,
        ARRAY['https://johnharabedian.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0acbacdd-a873-4e5e-aad9-fa5eca6d7b1e', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$No explicit tax position stated on website but authored AB-1950 (LA court mediation - procedural) and co-authored public investment bills including AB-1900 (single-payer healthcare), indicating support for significant public investment funded by progressive taxation. No flat-tax or tax-cut bills found.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1900', 'https://johnharabedian.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1caa9043-2397-4f75-b430-acc0623d64d7', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1caa9043-2397-4f75-b430-acc0623d64d7', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$No explicit abortion position statement found. Wikipedia: 'advocated for lowering college tuition, investing in after school programs, increasing public safety.' Co-authored AB-1806 (immigration accountability) suggesting progressive social values. As a Democrat from southeastern LA County, no evidence of restricting abortion found - likely supports access through second trimester at minimum.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jose_Solache']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1caa9043-2397-4f75-b430-acc0623d64d7', '666bf03d-81fc-4138-ab15-69ae734c9023', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1caa9043-2397-4f75-b430-acc0623d64d7', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Voted YES on AB-1018 (Bauer-Kahan, 2025) on the Assembly floor on June 2, 2025. The bill requires impact assessments and oversight of automated decision systems used in employment, housing, and criminal justice contexts.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260AB1018']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1caa9043-2397-4f75-b430-acc0623d64d7', '669cac97-66a6-4087-b036-936fbe62efb3', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1caa9043-2397-4f75-b430-acc0623d64d7', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Voted NO on SB-79 (transit-oriented housing) on September 11, 2025. SB-79 would allow dense housing near transit stations. Solache was one of 19 Assembly members who voted against this pro-housing bill, suggesting more restrictive stance on housing density despite representing a low-income district.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB79']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1caa9043-2397-4f75-b430-acc0623d64d7', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1caa9043-2397-4f75-b430-acc0623d64d7', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Authored AB-421 (2025) prohibiting law enforcement from sharing immigration information when enforcement could occur within one mile of childcare facilities, hospitals, or religious institutions. Co-authored AB-1806 (investigation of federal immigration officer shootings). Strong immigrant community protection record.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB421', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1806']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1caa9043-2397-4f75-b430-acc0623d64d7', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1caa9043-2397-4f75-b430-acc0623d64d7', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Authored AB-421 (2025) protecting sensitive community locations from immigration enforcement collaboration. Co-authored AB-1806 (accountability for immigration officer shootings). Represents Lynwood - a predominantly Latino Gateway Cities community. Strong anti-mass-deportation stance evidenced by legislation.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB421', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1806']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1caa9043-2397-4f75-b430-acc0623d64d7', '4938766b-b45a-46e3-93bd-b8b30651271a', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1caa9043-2397-4f75-b430-acc0623d64d7', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Wikipedia: 'advocated for increasing public safety.' Voted NO on SB-79 (transit housing) which could indicate concerns about neighborhood impacts. No direct homelessness bill found. Gateway Cities area context suggests some enforcement alongside services, but no criminalization bill either.$$,
        ARRAY['https://en.wikipedia.org/wiki/Jose_Solache', 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB79']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1caa9043-2397-4f75-b430-acc0623d64d7', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1caa9043-2397-4f75-b430-acc0623d64d7', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Authored AB-667 (language access for professional licensing) reflecting commitment to equitable access to services. Wikipedia notes he advocated for community investment. Did not co-author AB-1900 (single-payer). No evidence of private-market-only stance. Consistent with expanding access through public and private insurance mix.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB667']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1caa9043-2397-4f75-b430-acc0623d64d7', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1caa9043-2397-4f75-b430-acc0623d64d7', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Authored AB-421 (immigrant community protection) and AB-667 (language access). Co-authored AB-1806 (immigration officer accountability). Represents majority-Latino district with history of community advocacy dating to 2003 school board service. Strong civil rights enforcement record.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB421', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB667']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('39d99fc2-b8ab-4846-8ff3-bcb65e16bee4', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('39d99fc2-b8ab-4846-8ff3-bcb65e16bee4', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Campaign website: 'protect reproductive freedom' listed as core priority. California Nurses Association endorser (strong reproductive rights advocates). Speaker Pro Tempore with strong progressive record. No evidence of any restrictions on abortion access.$$,
        ARRAY['https://joshlowenthal.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('39d99fc2-b8ab-4846-8ff3-bcb65e16bee4', '666bf03d-81fc-4138-ab15-69ae734c9023', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('39d99fc2-b8ab-4846-8ff3-bcb65e16bee4', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Voted YES on AB-1018 (Bauer-Kahan, 2025) in both Assembly Privacy and Consumer Protection Committee (April 22) and floor vote (June 2, 2025). Also authored AB-1700 (e-Safety Commission for minors online - age verification oversight body), confirming strong tech regulation stance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260AB1018', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1700']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('39d99fc2-b8ab-4846-8ff3-bcb65e16bee4', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('39d99fc2-b8ab-4846-8ff3-bcb65e16bee4', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Campaign website: supports using California budget surplus 'to fund the programs necessary to get people off the streets and into housing and treatment' while also 'enforcing laws against unlawful encampments.' Emphasizes 'housing, mental health services, and addiction treatment' first - shelter expansion as primary strategy.$$,
        ARRAY['https://joshlowenthal.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('39d99fc2-b8ab-4846-8ff3-bcb65e16bee4', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('39d99fc2-b8ab-4846-8ff3-bcb65e16bee4', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Voted YES on SB-79 (transit-oriented housing) on September 11, 2025. Authored AB-1953 (short-term rental during emergencies/Olympics - supports housing flexibility). Campaign emphasizes building solutions to housing shortage alongside homelessness services.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=202520260SB79', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1953']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('39d99fc2-b8ab-4846-8ff3-bcb65e16bee4', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('39d99fc2-b8ab-4846-8ff3-bcb65e16bee4', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Sierra Club endorsement on campaign website - one of the strongest environmental endorsements available. Authored AB-1700 (tech regulation) reflecting broader regulatory stance. Sierra Club endorsement firmly signals rapid renewable energy transition stance.$$,
        ARRAY['https://joshlowenthal.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('39d99fc2-b8ab-4846-8ff3-bcb65e16bee4', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('39d99fc2-b8ab-4846-8ff3-bcb65e16bee4', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$California Nurses Association endorsement (CNA is primary sponsor of CalCare single-payer legislation). Did not directly co-author AB-1900, but CNA endorsement strongly suggests support for expanded coverage. Campaign website focused on public safety, education, and homelessness - healthcare not explicitly addressed but CNA backing is significant.$$,
        ARRAY['https://joshlowenthal.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('39d99fc2-b8ab-4846-8ff3-bcb65e16bee4', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('39d99fc2-b8ab-4846-8ff3-bcb65e16bee4', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$No direct immigration bill authored. As Speaker Pro Tempore and endorsed by California Professional Firefighters and California Nurses Association, aligns with labor-backed immigration policy supporting immigrant workers. No restrictive immigration stance found.$$,
        ARRAY['https://joshlowenthal.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('39d99fc2-b8ab-4846-8ff3-bcb65e16bee4', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('39d99fc2-b8ab-4846-8ff3-bcb65e16bee4', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$No direct deportation bill found. Campaign: 'fight to get our cities and communities the tools they need to crack down on residential crime, gun violence, and organized retail theft' - public safety focus on crimes, not deportation. No support for mass deportation found.$$,
        ARRAY['https://joshlowenthal.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('39d99fc2-b8ab-4846-8ff3-bcb65e16bee4', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('39d99fc2-b8ab-4846-8ff3-bcb65e16bee4', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Authored AB-1700 (2025) establishing e-Safety Commission to oversee age verification and child online safety - requires platforms to meet minimum age guidelines and comply with oversight body. This regulatory approach - mandatory compliance with platform oversight - aligns with mandating fact-checking and transparency standards.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1700']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('39d99fc2-b8ab-4846-8ff3-bcb65e16bee4', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('39d99fc2-b8ab-4846-8ff3-bcb65e16bee4', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$No dedicated civil rights bill authored, but Sierra Club, CNA, and Democratic Party endorsements signal progressive civil rights alignment. Campaign focuses on safe neighborhoods, homelessness, and education. No discriminatory legislation found.$$,
        ARRAY['https://joshlowenthal.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('39d99fc2-b8ab-4846-8ff3-bcb65e16bee4', '00b95a6a-75db-4521-b523-3326bba938de', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('39d99fc2-b8ab-4846-8ff3-bcb65e16bee4', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Campaign website: 'Committed to improving public schools.' Endorsed by Democratic Party (opposes vouchers). California Professional Firefighters and CNA are both union bodies opposing privatization. No voucher support found. Former teacher who has daughters in public schools.$$,
        ARRAY['https://joshlowenthal.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('39d99fc2-b8ab-4846-8ff3-bcb65e16bee4', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('39d99fc2-b8ab-4846-8ff3-bcb65e16bee4', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Website: 'strengthening secondary and higher education to better align with economic opportunities' and emphasis on investing in services. CNA and firefighter union endorsements signal support for progressive taxation to fund public services. No tax-cut advocacy found.$$,
        ARRAY['https://joshlowenthal.com/issues']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b959d608-5674-467e-a1c8-3572c76a729b', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b959d608-5674-467e-a1c8-3572c76a729b', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Co-authored AB-1460 (2025) expanding 340B drug pricing protections for nonprofit community health clinics, ensuring affordable medications reach low-income patients. Bill protects access to discounted drugs via community clinics, consistent with regulated-market public option approach rather than single-payer.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1460']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b959d608-5674-467e-a1c8-3572c76a729b', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b959d608-5674-467e-a1c8-3572c76a729b', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Authored AB-1276 (2025) expanding Housing Accountability Act protections for affordable housing projects, AB-1154 expanding junior ADU options, AB-595 creating homeownership tax credits for historically excluded buyers, and AB-2166 establishing multifamily backstop financing for offsite factory housing. Consistently expands housing supply and affordability across multiple bill vectors.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1276', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB595', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2166']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b959d608-5674-467e-a1c8-3572c76a729b', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b959d608-5674-467e-a1c8-3572c76a729b', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Authored AB-450 (2025) establishing aging immigrant services panel regardless of immigration status, authored AB-2662 creating civil rights accountability working group to monitor ICE enforcement, and co-authored AB-868 expanding voter participation for underrepresented communities. Pattern of expanding legal pathways and protections for immigrants.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB450', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2662']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b959d608-5674-467e-a1c8-3572c76a729b', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b959d608-5674-467e-a1c8-3572c76a729b', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Authored AB-2662 (2025) establishing DOJ working group to track civil rights violations in immigration enforcement, with focus on unlawful detention and enforcement in sensitive locations like schools. Co-authored AB-868 which notes Latino voter turnout disparities. Strongly anti-deportation stance evidenced by monitoring enforcement mechanisms.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2662']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b959d608-5674-467e-a1c8-3572c76a729b', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b959d608-5674-467e-a1c8-3572c76a729b', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Authored AB-2662 creating civil rights accountability group for immigration enforcement, co-authored AB-1650 requiring police vehicle identification. AB-868 specifically addresses racial disparities in Latino voter participation. Focus on civil rights enforcement and accountability, not just maintenance of current laws.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2662', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB868']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b959d608-5674-467e-a1c8-3572c76a729b', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b959d608-5674-467e-a1c8-3572c76a729b', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Authored AB-2505 (2025) expanding hydrogen refueling infrastructure toward zero-emission goals, AB-2310 strengthening illegal dumping penalties, and AB-735 setting environmental warehouse standards. Promotes clean energy transition through specific sector investments rather than fossil fuel bans. AB-982 (idle mine reserve) shows some balancing of economic and environmental priorities.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2505', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB735']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b959d608-5674-467e-a1c8-3572c76a729b', 'a22215c3-6693-4bc2-b248-01aebba14570', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b959d608-5674-467e-a1c8-3572c76a729b', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$No direct fossil fuel legislation found. AB-2505 promotes hydrogen/zero-emission vehicles as clean energy infrastructure. AB-982 allows idle mining reserves to be maintained, showing pragmatic approach. AB-735 warehouse standards require EV charging but do not address fossil fuel extraction. Maintaining current levels of production while supporting alternatives is most consistent reading.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2505', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB982']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b959d608-5674-467e-a1c8-3572c76a729b', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b959d608-5674-467e-a1c8-3572c76a729b', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Authored AB-868 (2025) changing primary election rules to ensure both top candidates go to general election, explicitly motivated by increasing voter participation among underrepresented communities including Latinos with documented primary-general turnout gap. Authored AB-264 expanding veteran dependent education benefits showing broader access orientation.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB868']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b959d608-5674-467e-a1c8-3572c76a729b', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b959d608-5674-467e-a1c8-3572c76a729b', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$No direct childcare bills found. Authored AB-450 supporting aging immigrants and AB-798 (Calderon) supporting emergency food bank including diapers/wipes as proxy. District is Antelope Valley (high-poverty exurban); likely supports targeted subsidies but no direct evidence of comprehensive childcare legislation authored.$$,
        ARRAY[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0afa998d-94e9-4af4-ba00-256c38869398', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0afa998d-94e9-4af4-ba00-256c38869398', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Authored AB-835 (2025) expanding Medi-Cal performance payments to more skilled nursing facilities regardless of network status, improving care access for low-income beneficiaries. This expands public coverage within the current system rather than creating a public option, but represents active expansion of Medi-Cal.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB835']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0afa998d-94e9-4af4-ba00-256c38869398', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0afa998d-94e9-4af4-ba00-256c38869398', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Authored AB-835 (2025) which strengthens Medi-Cal payments for skilled nursing facilities by removing network-provider barriers, effectively expanding Medi-Cal reach. Consistent with lowering eligibility barriers and expanding existing programs rather than restructuring toward privatization.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB835']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0afa998d-94e9-4af4-ba00-256c38869398', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0afa998d-94e9-4af4-ba00-256c38869398', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Authored AB-2647 (2025-26 session) requiring Energy Commission to assess advanced nuclear reactors as a supplement to California's zero-carbon electricity goal. Also authored AB-942 addressing climate credits and AB-1003 on wildfire emergency public health plans. Climate-supportive but focusing on pragmatic market-transition tools rather than immediate bans.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2647', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1003']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0afa998d-94e9-4af4-ba00-256c38869398', 'a22215c3-6693-4bc2-b248-01aebba14570', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0afa998d-94e9-4af4-ba00-256c38869398', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Authored AB-2647 which frames nuclear as complementary to renewables in high-renewable grid scenarios, not as fossil fuel replacement. No bills authored addressing oil/gas drilling directly. Former Edison International lobbyist background suggests utility-sector pragmatism. Supports current environmental regulations with market-based transition.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2647']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0afa998d-94e9-4af4-ba00-256c38869398', '669cac97-66a6-4087-b036-936fbe62efb3', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0afa998d-94e9-4af4-ba00-256c38869398', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$No housing-specific legislation found among authored bills. Key bills are insurance (FAIR Plan), wildfire resilience, and Medi-Cal. AB-888 California Safe Homes Grant Program focuses on wildfire hardening for existing homeowners, not housing supply expansion. Represents maintenance of current programs with targeted assistance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB888']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0afa998d-94e9-4af4-ba00-256c38869398', '4938766b-b45a-46e3-93bd-b8b30651271a', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0afa998d-94e9-4af4-ba00-256c38869398', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$AB-799 (State Emergency Food Bank Reserve adding diapers/wipes) shows safety-net support. No specific homelessness bills authored. Strong focus on wildfire-disaster emergency systems which indirectly address displacement. No evidence of either criminalization approach or major funding expansion.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB798']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0afa998d-94e9-4af4-ba00-256c38869398', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0afa998d-94e9-4af4-ba00-256c38869398', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Authored AB-1940 (2025) expanding FEHA civil rights protections to cover menopause discrimination in the workplace, requiring updated employer notices and public education campaigns. Extends existing civil rights enforcement framework to a new protected category, consistent with strengthening enforcement rather than maintaining status quo.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1940']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- campaign-finance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0afa998d-94e9-4af4-ba00-256c38869398', '92730f69-ae57-401c-8ad1-2d07834a895d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0afa998d-94e9-4af4-ba00-256c38869398', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$No campaign finance legislation found. Former career as Edison International government affairs director (1996-2020) and prior service to Assembly Speaker Willie Brown suggests comfort with existing fundraising systems. No reform bills authored. Most consistent with current disclosure requirements stance.$$,
        ARRAY[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('005d7df1-227e-4110-b254-ec835d5b5e95', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('005d7df1-227e-4110-b254-ec835d5b5e95', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Co-authored AB-380 (2025, price gouging bill, principal author) which expands protections covering all housing regardless of lease length during emergencies, and AB-630 (authored, abandoned RVs in LA) addressing urban quality-of-life. AB-770 (downtown LA advertising) supports economic revitalization. Overall pattern of using government tools to address housing affordability emergencies.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB380', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB630']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('005d7df1-227e-4110-b254-ec835d5b5e95', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('005d7df1-227e-4110-b254-ec835d5b5e95', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Authored AB-630 (2025) creating Alameda and LA County program to dispose of abandoned recreational vehicles with 72-hour notice, owner notification, and hearing rights — directly addressing encampment/RV crisis while including due process protections rather than criminalization. Co-authored AB-2310 strengthening illegal dumping penalties, addressing environmental harms of encampments.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB630', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2310']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('005d7df1-227e-4110-b254-ec835d5b5e95', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('005d7df1-227e-4110-b254-ec835d5b5e95', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Co-authored AB-2721 (2025) requiring hotels to post notices when contracting with ICE/CBP for reservations, protecting immigrant communities. Co-authored AB-380 which explicitly covers all housing including for immigrants. AB-1355 co-author (location privacy) restricts data sharing that could be used for immigration tracking. Consistent pro-immigrant protection pattern.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2721', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1355']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('005d7df1-227e-4110-b254-ec835d5b5e95', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('005d7df1-227e-4110-b254-ec835d5b5e95', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Co-authored AB-2721 (2025) requiring hotel disclosure of ICE contracts, limiting ICE's ability to use commercial lodging for enforcement operations. Co-authored AB-380 expanding emergency housing protections. Prior role as LA Democratic Party chair known for supporting immigrant communities. Pattern of limiting deportation infrastructure rather than stopping all deportations.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2721']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('005d7df1-227e-4110-b254-ec835d5b5e95', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('005d7df1-227e-4110-b254-ec835d5b5e95', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Authored AB-380 (principal author) expanding price-gouging protections during emergencies — this is consumer protection rather than tax policy, but reflects preference for government intervention in markets. No direct tax legislation authored. As new member (Dec 2024) with prior role as Biden state director, consistent with modest tax-increase-on-high-earners Democratic approach.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB380']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('005d7df1-227e-4110-b254-ec835d5b5e95', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('005d7df1-227e-4110-b254-ec835d5b5e95', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Co-authored AB-1355 California Location Privacy Act (2025) restricting government and corporate surveillance that disproportionately impacts communities of color. Co-authored AB-2721 on ICE hotel disclosures protecting immigrant civil rights. Co-authored AB-2310 on illegal dumping enforcement. First openly gay chair of LA County Democratic Party; strongly supports LGBTQ civil rights.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1355', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2721']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('005d7df1-227e-4110-b254-ec835d5b5e95', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('005d7df1-227e-4110-b254-ec835d5b5e95', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Mark González is openly gay and was publicly married; serves openly gay representative in LA. As former LA County Democratic Party chair, strongly supports full federal recognition of same-sex marriage. No bill evidence needed — status as openly gay elected official and Democratic Party leadership role confirms support for stance 1 (full federal recognition and benefits).$$,
        ARRAY['https://en.wikipedia.org/wiki/Mark_Gonzalez_(politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('108dfd2c-571a-4fef-aaf2-621c3238eea6', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('108dfd2c-571a-4fef-aaf2-621c3238eea6', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Wikipedia states Michelle Rodriguez's legislative priorities include 'advancing universal healthcare.' Represents AD-53 (Pomona/Inland Empire area), a working-class district with significant uninsured population. New member (Dec 2024) with no authored bills found in primary search. Prior service on CA Peace Officer Standards Commission does not indicate healthcare stance. Statement of universal healthcare priority suggests public option support.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Rodriguez_(politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('108dfd2c-571a-4fef-aaf2-621c3238eea6', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('108dfd2c-571a-4fef-aaf2-621c3238eea6', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Wikipedia states Michelle Rodriguez's legislative priorities include 'addressing homelessness.' Represents AD-53, a district with significant housing cost burden in San Bernardino/Riverside area. New member (Dec 2024). Her husband Freddie Rodriguez was term-limited Assembly member known for pro-labor/housing positions. Consistent with building affordable housing units and expanding rental assistance.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Rodriguez_(politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('108dfd2c-571a-4fef-aaf2-621c3238eea6', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('108dfd2c-571a-4fef-aaf2-621c3238eea6', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Wikipedia states Michelle Rodriguez's stated legislative priorities include 'addressing homelessness.' Democrat representing a working-class district. No specific authored bills on homelessness found (new member Dec 2024). Consistent with service expansion and shelter investment approach rather than criminalization.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Rodriguez_(politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('108dfd2c-571a-4fef-aaf2-621c3238eea6', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('108dfd2c-571a-4fef-aaf2-621c3238eea6', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$AD-53 covers Pomona and parts of San Bernardino County with large Latino immigrant population. Won 2024 election defeating Republican Nick Wilson with 57.6% — campaign focused on community services for this demographic. No authored bills found. Consistent with significantly expanding legal immigration and citizenship pathways given district demographics.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Rodriguez_(politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('108dfd2c-571a-4fef-aaf2-621c3238eea6', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('108dfd2c-571a-4fef-aaf2-621c3238eea6', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Previously served on California Commission on Peace Officer Standards and Training (POST), suggesting reformist rather than status-quo stance on law enforcement civil rights. Democratic assembly member representing diverse working-class district. Pattern consistent with strengthening civil rights enforcement.$$,
        ARRAY['https://en.wikipedia.org/wiki/Michelle_Rodriguez_(politician)']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$In 2023-24 session authored AB-632 (prostate cancer screening coverage, vetoed) expanding health coverage. Authored AB-835 (Medi-Cal skilled nursing expansion) in current session. Co-authored AB-767 Community Paramedicine Act. Strong pattern of expanding Medi-Cal and public health insurance coverage, consistent with public option alongside private insurance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB835', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB632']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Authored AB-835 (2025) expanding Medi-Cal skilled nursing facility payments to more providers, effectively expanding Medi-Cal reach. Prior AB-632 (vetoed) expanded Medicare-comparable screenings. California Legislative Black Caucus member. Consistent with lowering Medicare age and significant Medicaid expansion approach.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB835', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB632']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Authored AB-1165 California Housing Justice Act (2025) establishing California Housing Justice Fund for rental subsidies, permanent supportive housing, affordable development targeting acutely low-income households, with explicit acknowledgment that housing is a fundamental right. Most robust housing bill found in this research — directly targets homeless and lowest-income Californians.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1165']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$AB-1165 California Housing Justice Act (2025) explicitly states 'Homelessness and housing unaffordability are solvable' and establishes permanent state investment in rental subsidies and supportive housing. Framing as evidence-based, scalable public investment rather than criminalization. Also authored AB-1528 (housing authority property tax) in 2023-24 session.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1165']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- tariffs
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', '683c8084-2281-4920-a07c-18439b2dd413', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', '683c8084-2281-4920-a07c-18439b2dd413',
        $$Authored AJR-14 (2025) — California Assembly Joint Resolution calling on federal agencies to reconsider tariff impacts on CA ports, citing disrupted trade, higher costs, job losses, and infrastructure investment strain. Position: tariffs are harmful and federal agencies should work toward trade stabilization. Consistent with reducing most tariffs stance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AJR14']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Authored AB-2499 (2025) Adrienne's Act addressing extreme heat/climate impacts in California prisons — focuses on adaptation rather than emissions reduction. Authored AB-844 (2023-24) zero-emission trucks insurance. No direct clean energy legislation authored. Co-authored AB-380 (price gouging). Supports clean energy transition through sector-specific legislation without proposing aggressive fossil fuel phase-outs.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2499', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB844']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', 'a22215c3-6693-4bc2-b248-01aebba14570', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Authored AB-844 (2023-24) zero-emission truck insurance supporting clean transportation. AJR-14 opposes tariffs that hurt port/logistics workers who may handle fossil fuel goods. No bills directly addressing fossil fuel drilling or extraction permits. Pattern of supporting zero-emission transition through sector-specific incentives without explicit position on new drilling permits.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB844', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AJR14']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Authored AB-2669 (2025) requiring prosecutors to meet-and-confer on immigration-neutral plea alternatives in criminal proceedings, protecting defendants from adverse immigration consequences. Authored AB-2019 (2025) allowing community college faculty deported or detained to teach remotely. Co-authored AB-2721 (ICE hotel disclosure). Strong pattern of protecting immigrants within the criminal justice and employment systems.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2669', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2019', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2721']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Authored AB-2669 (2025) requiring prosecution to seek immigration-neutral pleas — directly limits deportation pipeline through criminal justice system. Authored AB-2019 allowing deported faculty to teach remotely, acknowledging deportation as reality while mitigating harms. Co-authored AB-2721. Strong deport-only-violent-offenders consistent stance through criminal justice reform.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2669', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2019']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Authored AB-360 (2023-24 chaptered) banning 'excited delirium' as a cause of death or defense in use-of-force cases — landmark police accountability bill. Authored AB-997 (exoneration mental health services). Member of CA Legislative Black Caucus. AB-1263/AB-1089 ghost gun legislation also strengthens civil safety. Multiple bills addressing systemic inequities in criminal justice system.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB360', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1263']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Authored AB-1519 (2025) taxpayer-protective bill limiting interest/penalty collection to base liability period. Authored AB-1498 (2023-24) expanding EITC access — direct subsidy for low-income workers. Pattern of using tax code to help lower-income Californians rather than across-the-board cuts or significant wealth taxes.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1519', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB1498']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Authored AB-1606 (2023-24) driver's license renewal alternatives reducing barriers to accessing government services. Authored AB-3168 (2023-24) expanding DMV confidential record protections. Pattern of expanding access to government systems and reducing barriers for vulnerable populations, consistent with expanding early voting and mail-in voting availability.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB1606']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', '00b95a6a-75db-4521-b523-3326bba938de', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Authored AB-821 (2025 chaptered) expanding high school graduation requirements for career technical education in public schools, AB-291 (teacher apprenticeship programs for public schools), AB-1904 (teacher apprenticeship), AB-857 (cultural competency training for school employees). Entire legislative record focused on strengthening public school institutions with no evidence of supporting voucher programs. Consistently invests in public school systems.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB821', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB291']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6133e73c-4c33-4cfc-9fd3-de1382729f42', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Authored AB-906 (2023-24, died) Local Control Funding Formula for county offices of education, AB-1695 (Nursing Pathway Pilot for community colleges), focused on expanding education access. No direct childcare bills but pattern of using government grants and public education funding to expand access for low-income families. CA Legislative Black Caucus member representing Compton/Carson supports strong safety net.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB906']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cacdb3e3-f716-4914-9e32-a95cc632af42', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cacdb3e3-f716-4914-9e32-a95cc632af42', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Fong has not authored single-payer bills but co-authored AB-1930 (2026) protecting healthcare providers performing legally protected activities from out-of-state investigations; consistently supports Medi-Cal expansion and ACA subsidies. Authored AB-413 (2025) expanding language access for non-English-speaking communities in housing programs. Aligned with public option alongside private insurance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1930', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB413']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cacdb3e3-f716-4914-9e32-a95cc632af42', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cacdb3e3-f716-4914-9e32-a95cc632af42', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Co-authored AB-1930 (2026) to shield CA healthcare providers from out-of-state abortion investigations. Authored AB-695 (2025) protecting deported students' access to education and financial aid. No bills restricting reproductive access authored; represents a majority-minority LA district and votes with CA Legislative Progressive Caucus. Full abortion access record.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1930', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB695']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cacdb3e3-f716-4914-9e32-a95cc632af42', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cacdb3e3-f716-4914-9e32-a95cc632af42', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Authored AB-945 (2025) adding density bonus incentives for all-electric green housing developments with no fossil fuel connections, and AB-893 (2025) streamlining housing near college campuses. Also AB-2329 (2026) creating affordable surplus-property purchasing pathways and tenant rights. Strong pro-supply, pro-affordability record.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB945', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB893', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2329']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cacdb3e3-f716-4914-9e32-a95cc632af42', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cacdb3e3-f716-4914-9e32-a95cc632af42', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Authored AB-695 (2025) — California Community Colleges Access and Continuity for Deported Students Act — protecting deported students' tuition exemptions and financial aid access. Also AB-413 requiring language access in housing guidelines and AB-2341 (2026) mandating emergency services translation for non-English speakers. Consistently protective of immigrant communities.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB695', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB413', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2341']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cacdb3e3-f716-4914-9e32-a95cc632af42', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cacdb3e3-f716-4914-9e32-a95cc632af42', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$AB-695 (2025) specifically protects students who were deported or fled due to immigration enforcement — providing tuition exemptions and financial aid restoration for online enrollment from their country of origin. The bill sets a sunset of 2030 for re-enrollment access. Combined with AB-2341 multilingual emergency services this reflects support for deported individuals.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB695', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2341']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cacdb3e3-f716-4914-9e32-a95cc632af42', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cacdb3e3-f716-4914-9e32-a95cc632af42', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$AB-945 (2025) requires all-electric green housing with no fossil fuel connections and no natural gas hook-ups as a condition for density bonus incentives — directly advancing building electrification. AB-2745 (2026) creates state trade assistance infrastructure referencing tariffs and supply chains as climate/national security policy tools. Consistent CA Democratic climate investment voter.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB945', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2745']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cacdb3e3-f716-4914-9e32-a95cc632af42', 'a22215c3-6693-4bc2-b248-01aebba14570', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cacdb3e3-f716-4914-9e32-a95cc632af42', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$AB-945 prohibits fossil fuel appliances and natural gas connections in green housing receiving density bonuses, pushing electrification in new construction. However Fong has not authored broader drilling permit bans; his energy work is targeted at building electrification incentives. Consistent with maintaining current fossil fuel levels while using market incentives to transition.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB945']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cacdb3e3-f716-4914-9e32-a95cc632af42', '666bf03d-81fc-4138-ab15-69ae734c9023', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cacdb3e3-f716-4914-9e32-a95cc632af42', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Authored AB-2392 (2026) requiring CA community colleges and CSU to establish procurement standards and safety testing protocols before deploying generative AI systems — including risk assessments, student data protections, sycophancy avoidance standards, and vendor labor/privacy screening. This is basic safety-testing-before-deployment regulation aligned with stance 3.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2392']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- tariffs
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cacdb3e3-f716-4914-9e32-a95cc632af42', '683c8084-2281-4920-a07c-18439b2dd413', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cacdb3e3-f716-4914-9e32-a95cc632af42', '683c8084-2281-4920-a07c-18439b2dd413',
        $$AB-2745 (2026) creates a Global Partnership Advisory Body and regional trade assistance hubs to help CA businesses navigate the 2025 federal tariff regime — framing tariffs as creating compliance burdens requiring a coordinated state response. Bill is pragmatic rather than endorsing or opposing specific tariff levels; reflects selective use of trade policy.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2745']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- campaign-finance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('cacdb3e3-f716-4914-9e32-a95cc632af42', '92730f69-ae57-401c-8ad1-2d07834a895d', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('cacdb3e3-f716-4914-9e32-a95cc632af42', '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$AB-775 (2025) strengthens behested payment reporting for elected officials — adds required disclosures of family/staff relationships with nonprofit payees, pending proceedings involving the payer, and quarterly filing rather than per-payment. A transparency and anti-corruption measure targeting dark money flows through charitable vehicles.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB775']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e31e6ebf-91ea-478f-b4dc-6974888bdffa', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e31e6ebf-91ea-478f-b4dc-6974888bdffa', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Co-authored AB-1930 (2026) protecting CA healthcare providers from out-of-state subpoenas for legally protected health care activities. As a CA Democrat representing Burbank (AD-44) he has consistently voted with Democratic majority on Medi-Cal expansion. His housing and criminal justice record signals progressive-moderate positioning, not single-payer advocacy.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1930']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e31e6ebf-91ea-478f-b4dc-6974888bdffa', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e31e6ebf-91ea-478f-b4dc-6974888bdffa', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Co-authored AB-1930 (2026) — prohibits CA entities from complying with out-of-state investigations targeting legally protected healthcare activities including abortion. This is a strong legislative stance protecting providers and patients from cross-state enforcement of abortion restrictions.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1930']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e31e6ebf-91ea-478f-b4dc-6974888bdffa', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e31e6ebf-91ea-478f-b4dc-6974888bdffa', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Authored AB-939 (2025) expanding Density Bonus Law affordability pathways for for-sale units via nonprofit below-market loan programs, and AB-1050 (2025) removing restrictive covenants blocking housing development. Also AB-1229 (2025) transferring Adult Reentry Grant Program to Housing Dept for Housing First permanent supportive housing. Strong affordable housing record.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB939', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1050', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1229']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e31e6ebf-91ea-478f-b4dc-6974888bdffa', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e31e6ebf-91ea-478f-b4dc-6974888bdffa', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$AB-1229 (2025) establishes a Housing First permanent supportive housing program for formerly incarcerated individuals at risk of homelessness — requires Housing First compliance across all providers and braids housing assistance with Medi-Cal and behavioral health services. Decriminalization and services-first approach; Schultz chairs Assembly Public Safety Committee.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1229']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e31e6ebf-91ea-478f-b4dc-6974888bdffa', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e31e6ebf-91ea-478f-b4dc-6974888bdffa', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$AB-2560 (2026) codifies California's Climate Action Plan for Transportation Infrastructure with zero-emission vehicle deployment, active transportation investment, zero-emission freight, and climate risk assessments for all transportation projects. Also authored AB-43 (wild and scenic rivers) and AB-1603 (PFAS). Strong clean energy investment record.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2560', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1603']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e31e6ebf-91ea-478f-b4dc-6974888bdffa', 'a22215c3-6693-4bc2-b248-01aebba14570', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e31e6ebf-91ea-478f-b4dc-6974888bdffa', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$AB-44 (2025) focuses on energy demand forecasting to better integrate renewable energy into grid planning. AB-2560 (2026) prioritizes zero-emission alternatives in transportation funding. Schultz has not authored bills banning new drilling permits; his energy work focuses on demand flexibility and clean transportation, consistent with maintaining current production with incentive-based transition.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB44', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2560']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ai-regulation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e31e6ebf-91ea-478f-b4dc-6974888bdffa', '666bf03d-81fc-4138-ab15-69ae734c9023', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e31e6ebf-91ea-478f-b4dc-6974888bdffa', '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Authored AB-1898 (2026) requiring employers to provide 90-day advance notice before deploying AI tools, disclose AI model training data and surveillance methods, and report annually on job automation impacts. Basic safety and transparency regulation with worker focus — not government pre-approval, but meaningful oversight before deployment.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1898']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e31e6ebf-91ea-478f-b4dc-6974888bdffa', '4559b513-0fd8-4ed1-babd-f3b554162f40', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e31e6ebf-91ea-478f-b4dc-6974888bdffa', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$AB-44 (2025) requires transparent demand forecasting methodologies for load-serving entities to account for behind-the-meter load shifting — directly relevant to managing data center energy demand. AB-1787 and AB-2266 also address load-serving entities and electricity rates. Schultz's energy work suggests allowing data centers with impact assessment and demand management requirements.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB44', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1787']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e31e6ebf-91ea-478f-b4dc-6974888bdffa', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e31e6ebf-91ea-478f-b4dc-6974888bdffa', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$As Chair of Assembly Public Safety Committee Schultz authored AB-1036 (2025) expanding postconviction discovery rights to all felony convictions, AB-321 (2025) allowing pre-trial misdemeanor reductions, and AB-2217 (2026) expanding arrest alternatives program to include disorderly conduct and shoplifting. Criminal justice reform record focused on addressing systemic inequities.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1036', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2217', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB321']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d64c969e-f458-4387-98b5-1e7af8cb42f0', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d64c969e-f458-4387-98b5-1e7af8cb42f0', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Authored AB-1208 (2023) expanding the Health Care Affordability Reserve Fund for cost-sharing subsidies to low- and middle-income Californians. AB-539 (2025) strengthens prior authorization protections. AB-1312 (2025) requires hospitals to auto-screen patients for charity care eligibility. Strong healthcare access record stopping short of single-payer advocacy.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB1208', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB539', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1312']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d64c969e-f458-4387-98b5-1e7af8cb42f0', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d64c969e-f458-4387-98b5-1e7af8cb42f0', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Authored AB-602 (2023) banning deceptive advertising by anti-abortion crisis pregnancy centers, AB-710 (2023) and AB-2670 (2024) requiring state abortion services awareness campaigns, AB-1500 (2025) expanding abortion.ca.gov to comprehensive reproductive health resource. Four distinct bills over three sessions all advancing abortion access and countering misinformation.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB602', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB710', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1500']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d64c969e-f458-4387-98b5-1e7af8cb42f0', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d64c969e-f458-4387-98b5-1e7af8cb42f0', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Authored AB-519 (2023) consolidating affordable housing finance applications, AB-2674 (2024) creating loan guarantee program for affordable and foster youth housing (25% units reserved for former foster youth), AB-301 (2025) extending streamlined permits to state agencies, AB-2390 (2025) further streamlining affordable housing approvals. Consistent supply-and-affordability focus.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB519', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB2674', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2390']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d64c969e-f458-4387-98b5-1e7af8cb42f0', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d64c969e-f458-4387-98b5-1e7af8cb42f0', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$AB-550 (2023) mandates annual homelessness counts and public hearings with action plans in every CA jurisdiction. AB-963 (2023) creates a loan guarantee program to prevent foster care-to-homelessness pipeline. AB-2674 (2024) targets housing finance for at-risk youth. AB-534 (2025) strengthens transitional housing provider contracts. Multiple bills connecting shelter, planning, and systemic prevention.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB550', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB963', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB2674']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d64c969e-f458-4387-98b5-1e7af8cb42f0', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d64c969e-f458-4387-98b5-1e7af8cb42f0', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$AJR-4 (2023) authored by Schiavo opposed the Medicare ACO REACH Model as threatening Traditional Medicare through privatization incentives, requesting President Biden terminate it. AJR-3 (2025) authored by Schiavo urges Congress to protect Social Security, Medicare, and Medicaid from cuts in H.R. 1 and oppose privatization. Calls for expanding and strengthening these programs.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AJR4', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AJR3']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- social-security
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d64c969e-f458-4387-98b5-1e7af8cb42f0', '87d20824-a6e9-407b-983c-65440084a0ab', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d64c969e-f458-4387-98b5-1e7af8cb42f0', '87d20824-a6e9-407b-983c-65440084a0ab',
        $$AJR-3 (2025) authored by Schiavo calls on Congress to protect Social Security from H.R. 1 provisions — opposing staffing reductions, opposing policies that deplete the Trust Fund two years early, and opposing elimination of paper checks. Explicitly calls on the President to disavow privatization and work to strengthen the program.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AJR3']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d64c969e-f458-4387-98b5-1e7af8cb42f0', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d64c969e-f458-4387-98b5-1e7af8cb42f0', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$AB-1132 (2025) requires CA DOT to include community resilience assessments in climate vulnerability reports. AB-2294 (2024) provides employment tax credits for semiconductor, lithium production, and electric airplane manufacturing. AB-823 (2023) for Clean Transportation Program. Multiple sessions of climate-aligned investment bills.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1132', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB2294']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d64c969e-f458-4387-98b5-1e7af8cb42f0', 'a22215c3-6693-4bc2-b248-01aebba14570', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d64c969e-f458-4387-98b5-1e7af8cb42f0', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$AB-1020 (2025) requires investor-owned utilities to report taxpayer funding received for energy projects and deliver ratepayer savings. Clean transportation tax credits (AB-2294) and climate vulnerability planning (AB-1132) focus on transition incentives. No bills authored restricting or expanding drilling permits; Schiavo's energy work is accountability and investment-focused.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1020']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d64c969e-f458-4387-98b5-1e7af8cb42f0', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d64c969e-f458-4387-98b5-1e7af8cb42f0', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Authored AB-681 (2023) establishing childcare bid preferences in state contracting for employers who provide/subsidize employee childcare. AB-2343 (2024) authorizes CalWORKs childcare administrators to provide referral pathways for homeless or domestic violence-impacted families. AB-1914 (2025) requires cities and counties to integrate childcare planning into general plans by 2033.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB681', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB2343', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1914']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d64c969e-f458-4387-98b5-1e7af8cb42f0', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d64c969e-f458-4387-98b5-1e7af8cb42f0', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$AB-1502 (2023) prohibits health plans from discriminating via clinical algorithms by race, national origin, sex, or disability. AB-464 (2023) eliminates vital records and driver's license fees for low-income and homeless individuals. AB-3074 (2024) California Racial Mascots Act for schools. Multiple bills addressing systemic discrimination and economic equity.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB1502', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB464', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB3074']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d64c969e-f458-4387-98b5-1e7af8cb42f0', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d64c969e-f458-4387-98b5-1e7af8cb42f0', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Campaign website (pilar4ca.com) states Schiavo is running to cut taxes for small businesses and the middle class. AB-2294 (2024) expands employment tax credits to incentivize manufacturing jobs. AB-1014 (2023) property tax exemption for disabled veterans. Approach is targeted middle-class and small business relief, not across-the-board cuts.$$,
        ARRAY['https://pilar4ca.com/', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB2294']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff77225c-51f9-4628-acc3-020d40382d05', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff77225c-51f9-4628-acc3-020d40382d05', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Authored AB-1645 (2023) eliminating cost-sharing for preventive care and STI screenings in all insurance plans and AB-2258 (2024) similar cost-sharing expansions. AB-1887 (2025) removes prior authorization requirements for rare disease treatments by specialists. AB-1930 (2026) shields providers from out-of-state healthcare investigations. Consistently expands access within existing system.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB1645', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1887', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1930']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff77225c-51f9-4628-acc3-020d40382d05', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff77225c-51f9-4628-acc3-020d40382d05', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Authored AB-2735 (2025) maintaining CA Reproductive Health Equity Program ensuring abortion and contraception are affordable and accessible regardless of ability to pay. AB-1930 (2026) protects healthcare providers from out-of-state abortion investigations. Former Equality California Executive Director with 8-year record championing reproductive rights alongside LGBTQ+ rights.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2735', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1930']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff77225c-51f9-4628-acc3-020d40382d05', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff77225c-51f9-4628-acc3-020d40382d05', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Authored AB-1431 (2023, California Housing Security Act) — rental subsidy pilot program up to $2,000/month for low-income populations explicitly including undocumented immigrants. AB-1620 (2023) modified Costa-Hawkins to allow disabled tenants to transfer to accessible units with rent control protections. AB-648 (2025) exempts community college housing from local zoning. Expansive affordable housing record.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB1431', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB1620', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB648']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff77225c-51f9-4628-acc3-020d40382d05', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff77225c-51f9-4628-acc3-020d40382d05', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Zbur served as Executive Director of Equality California from 2014 to 2022 — the state's leading LGBTQ+ civil rights organization that fought for and celebrated marriage equality. He is personally gay and has been a leading advocate for full federal recognition of same-sex marriages and equal LGBTQ+ rights. His career is inseparable from marriage equality advocacy.$$,
        ARRAY['https://en.wikipedia.org/wiki/Rick_Zbur']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- trans-athletes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff77225c-51f9-4628-acc3-020d40382d05', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff77225c-51f9-4628-acc3-020d40382d05', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Authored AB-2442 (2024) expediting professional licensure for gender-affirming healthcare providers, AB-1084 (2025) streamlining name and gender-marker court changes with automatic approvals, and AB-5 (2023, Safe and Supportive Schools Act) mandating LGBTQ+ inclusive training for school staff. As former Equality California director he actively championed trans inclusion with no restrictions.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB2442', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1084', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB5']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff77225c-51f9-4628-acc3-020d40382d05', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff77225c-51f9-4628-acc3-020d40382d05', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Authored AB-39 (2025, Local Electrification Planning Act) requiring cities over 75k to develop comprehensive electrification plans. AB-3 (2023) and AB-3006 (2024) on offshore wind energy reports. AB-2208 (2024) CA Ports Offshore Wind Bond Act. AB-1176 (2024) local electrification planning earlier version. AB-2688 (2026) offshore wind infrastructure. Rapid clean energy transition record.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB39', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB3006', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB2208']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff77225c-51f9-4628-acc3-020d40382d05', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff77225c-51f9-4628-acc3-020d40382d05', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$AB-39 (2025) requires local electrification plans identifying opportunities to expand zero-emission and renewable distributed energy resources and electrify carbon-intensive development. AB-2688 (2026) offshore wind infrastructure. AB-729 public utilities climate credits. AB-941 streamlining environmental review for electrical infrastructure. Record reflects stopping new fossil fuel permits in favor of renewables.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB39', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2688']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- data-centers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff77225c-51f9-4628-acc3-020d40382d05', '4559b513-0fd8-4ed1-babd-f3b554162f40', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff77225c-51f9-4628-acc3-020d40382d05', '4559b513-0fd8-4ed1-babd-f3b554162f40',
        $$Authored AB-2383 (2026) creating a separate electricity rate classification for facilities with 20+ MW peak load — explicitly naming data centers housing computing infrastructure. The bill prohibits cost shifting to residential ratepayers and requires minimum 15-year contracts for interconnection services, meaning data centers must fund their own dedicated power arrangements.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2383']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff77225c-51f9-4628-acc3-020d40382d05', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff77225c-51f9-4628-acc3-020d40382d05', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Authored AB-715 (2025) creating a state Office of Civil Rights and Antisemitism Prevention Coordinator. AB-1468 (2025) and AB-2918 (2024) ethnic studies content standards and graduation requirements. AB-2615 (2025) strengthening discrimination complaint procedures in schools. AB-2442 gender-affirming licensure. Former Equality California director. Broad civil rights enforcement record.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB715', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1468', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB2918']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- religious-freedom
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff77225c-51f9-4628-acc3-020d40382d05', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff77225c-51f9-4628-acc3-020d40382d05', '6b9ba6d9-1001-43f5-b073-4d37130696fd',
        $$No bills authored directly on religious exemptions. Zbur's LGBTQ+ record (Equality California director, trans rights bills) implies he opposes religious exemptions overriding anti-discrimination protections, but AB-715 antisemitism bill shows commitment to protecting religious identity from harassment. His framework balances anti-discrimination enforcement with religious protection.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB715', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB5']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ff77225c-51f9-4628-acc3-020d40382d05', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ff77225c-51f9-4628-acc3-020d40382d05', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$AB-1431 (2023, California Housing Security Act) explicitly allows undocumented immigrants meeting income/eligibility criteria to receive rental subsidies up to $2,000/month — a significant pro-immigrant policy inclusion. As former Equality California director his work encompassed immigrant LGBTQ+ communities. No restriction bills authored.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB1431']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3c2bfe51-9a53-4992-801b-138a1a8ce9ed', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3c2bfe51-9a53-4992-801b-138a1a8ce9ed', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Authored AB-2551 (2026) requiring health insurers to conduct annual behavioral health access surveys and report on out-of-network usage barriers to the Legislature. Also AB-37 (2025) providing hypodermic needles/syringes access for harm reduction and AB-1843 (2026) hepatitis B and C communicable disease program. Background working for Mayor Bass in public health policy context.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2551', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1843']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3c2bfe51-9a53-4992-801b-138a1a8ce9ed', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3c2bfe51-9a53-4992-801b-138a1a8ce9ed', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$No abortion-specific bills authored in first session (sworn in Dec 2024), but co-authored AB-742 (reparations-adjacent licensing equity) and AB-822 (Commission on State of Hate) showing progressive civil rights alignment. Elhawary is a DSA-backed South LA legislator who worked for Mayor Bass — a strong abortion-rights mayor and former state legislator with a 100% NARAL record.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB742']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3c2bfe51-9a53-4992-801b-138a1a8ce9ed', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3c2bfe51-9a53-4992-801b-138a1a8ce9ed', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Authored AB-2079 (2026) expanding the Adaptive Reuse Investment Incentive Program to subsidize conversion of buildings to housing and revitalize downtown areas. AB-1275 (2026) reforms regional housing needs allocation to integrate sustainable communities strategy. AB-2755 unlawful detainer definitions provide tenant protections. Proactive housing supply record in first session.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2079', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1275']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3c2bfe51-9a53-4992-801b-138a1a8ce9ed', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3c2bfe51-9a53-4992-801b-138a1a8ce9ed', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$AB-1932 (2026) extends C.R.I.S.E.S. Grant Pilot Program to 2032, prioritizing community-based alternatives to law enforcement over first-responder policing for historically marginalized communities. Background working for Mayor Bass who championed Inside Safe homelessness outreach program. Strong decriminalization and services-first approach.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1932']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3c2bfe51-9a53-4992-801b-138a1a8ce9ed', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3c2bfe51-9a53-4992-801b-138a1a8ce9ed', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$AB-681 (2026) significantly increases California DREAM Loan Program limits for graduate students (from $4,000 to $20,500/year, aggregate to $118,500) — directly supporting undocumented and DACA students in higher education. AB-1231 (2025) creates felony pretrial diversion reducing criminal records that trigger deportation. Both bills benefit immigrant communities.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB681', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1231']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3c2bfe51-9a53-4992-801b-138a1a8ce9ed', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3c2bfe51-9a53-4992-801b-138a1a8ce9ed', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$AB-742 (2025) requires CA licensing boards to expedite applications from descendants of American slaves — a reparations-adjacent economic equity measure. AB-822 (2025) extends the Commission on the State of Hate to 2031 tracking discrimination across all protected classes. AB-1932 targets communities with high rates of racial profiling and police use of force. Strong racial justice record.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB742', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB822', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1932']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3c2bfe51-9a53-4992-801b-138a1a8ce9ed', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3c2bfe51-9a53-4992-801b-138a1a8ce9ed', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Represents South LA (AD-57), worked for Mayor Bass who pursued strong climate and clean energy policies. AB-1380 and AB-2483 address wildland firefighter certification for formerly incarcerated — directly responding to the climate-worsened wildfire crisis. AB-1932 prioritizes community-based services in high-impact areas. Votes with CA Democratic climate consensus.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1380', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2483']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3c2bfe51-9a53-4992-801b-138a1a8ce9ed', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3c2bfe51-9a53-4992-801b-138a1a8ce9ed', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$AB-681 (2026) significantly increases DREAM Loan limits for undocumented graduate students — direct support for those living in the US under DACA or similar status at risk of deportation. AB-1231 (2025) creates felony diversion reducing convictions that trigger deportation under federal law. Both bills protect immigrant residents from enforcement consequences.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB681', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1231']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3c2bfe51-9a53-4992-801b-138a1a8ce9ed', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3c2bfe51-9a53-4992-801b-138a1a8ce9ed', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Elhawary is a former educator who worked in Mayor Bass's office. AB-896 (2025, foster care placement transition planning) and AB-1120 (foster youth rights) address child welfare. AB-1932 prioritizing community-based services includes childcare access for historically marginalized populations. Her education and child welfare legislative focus supports expanded childcare subsidy alignment.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB896', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1120']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e29ce86-9e02-4079-b50d-bb0d039613a2', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e29ce86-9e02-4079-b50d-bb0d039613a2', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Authored AB 923 (2025-26), the California Women's Care Act, creating a rebuttable presumption against detention of pregnant/postpartum defendants and strengthening reproductive rights protections. Consistent with mainstream CA Democratic caucus support for abortion access through all stages with narrow exceptions.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB923']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e29ce86-9e02-4079-b50d-bb0d039613a2', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e29ce86-9e02-4079-b50d-bb0d039613a2', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Authored AB 670 (housing element reporting, converted affordable units), AB 956 (allows two ADUs by-right on single-family lots), AB 1751 (Missing Middle Townhome Ownership Act), and AB 2185/2288 (affordable multifamily housing). Strong affordable housing production record consistent with a value of 2.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB956', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB670', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB670']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e29ce86-9e02-4079-b50d-bb0d039613a2', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e29ce86-9e02-4079-b50d-bb0d039613a2', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Authored AB 1937 expanding Unruh Civil Rights Act protections to early childcare and education settings, prohibiting discrimination based on sex, race, immigration status, and other protected characteristics. Education background and legislative record reflect strong civil rights enforcement stance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1937']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e29ce86-9e02-4079-b50d-bb0d039613a2', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e29ce86-9e02-4079-b50d-bb0d039613a2', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Authored AB 737 (building decarbonization transparency, extending requirements to gas utilities). Supports clean energy transition through regulatory mechanisms. No evidence of extreme position; bill approach is regulatory disclosure and infrastructure, consistent with moderate clean energy investment stance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB737']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e29ce86-9e02-4079-b50d-bb0d039613a2', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e29ce86-9e02-4079-b50d-bb0d039613a2', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Democratic member from a majority-minority LA-area district. AB 1937 explicitly protects against discrimination based on immigration status in childcare settings. No evidence of restrictive immigration positions; district demographics and party caucus (California Legislative Progressive Caucus) indicate supportive stance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB1937']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('522efd15-f5e2-4e1a-8708-aad87410637d', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('522efd15-f5e2-4e1a-8708-aad87410637d', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Member of the California Legislative Progressive Caucus. No authored bill directly on abortion found, but California Democratic caucus members in majority-minority LA districts consistently vote for and co-author abortion access legislation. No evidence of restriction; inference from caucus and district context, confirmed by AB 2186 (reparations tax exclusion) showing civil rights focus. Score of 2 reflects default CA Democratic mainstream stance; not a bill author of abortion legislation so not scored 1.$$,
        ARRAY['https://ballotpedia.org/Tina_McKinnor']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('522efd15-f5e2-4e1a-8708-aad87410637d', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('522efd15-f5e2-4e1a-8708-aad87410637d', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Authored AB 57 (California Dream for All reserved allocation for descendants of formerly enslaved people), AB 62 (Civil Rights Department process for racially motivated eminent domain remediation), and AB 2186 (income tax exclusion for reparations payments). Strongest civil rights/reparations record of any legislator in this batch; warrants value 1.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB62', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB2186', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB57']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('522efd15-f5e2-4e1a-8708-aad87410637d', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('522efd15-f5e2-4e1a-8708-aad87410637d', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Authored AB 663 (tightening hydrofluorocarbon gas sale prohibition, advancing phaseout of high-GWP refrigerants). Addresses one climate-relevant pollutant but no comprehensive clean energy or fossil fuel reduction bill found. Score of 3 reflects targeted action on climate pollutants without sweeping clean energy mandate.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB663']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('522efd15-f5e2-4e1a-8708-aad87410637d', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('522efd15-f5e2-4e1a-8708-aad87410637d', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Authored AB 311 (allows tenants to temporarily house persons at risk of homelessness in their units) and AB 311's related homelessness prevention mechanism. Member of California Legislative Progressive Caucus; district in Inglewood/Hawthorne/Lawndale. Bill focus is on housing insecurity prevention.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB311']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('522efd15-f5e2-4e1a-8708-aad87410637d', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('522efd15-f5e2-4e1a-8708-aad87410637d', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$AJR-30 (gun violence resolution) references Trump statements and federal policy; AB 57's reparations program focus reflects strong advocacy for historically marginalized communities including immigrants. No authored immigration restriction bill; district demographics and Progressive Caucus membership strongly indicate pro-immigrant stance.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB57']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('522efd15-f5e2-4e1a-8708-aad87410637d', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('522efd15-f5e2-4e1a-8708-aad87410637d', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Authored AB 311 (allows tenants to temporarily house homeless individuals, anti-criminalization approach), consistent with a service/shelter expansion stance over enforcement.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260AB311']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e8bdd8a7-a1b2-43e3-afd4-df975980819e', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e8bdd8a7-a1b2-43e3-afd4-df975980819e', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Republican Assemblymember who declined a legislative pay increase when first elected. Wikipedia notes alignment with fiscal conservative values and public safety priorities over spending increases. No authored tax-hike bills; former CHP officer background and Republican affiliation indicate tax-reduction preference.$$,
        ARRAY['https://en.wikipedia.org/wiki/Tom_Lackey']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e8bdd8a7-a1b2-43e3-afd4-df975980819e', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e8bdd8a7-a1b2-43e3-afd4-df975980819e', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Republican representing Antelope Valley/Palmdale area (AD-34). No authored climate bills found. Prior Assembly record focused on public safety, special education, and drugged driving (AB 266). Republican caucus position and Mojave-area district interests (oil/agriculture) indicate skepticism of aggressive climate mandates; scored 4 not 5 as no anti-climate rhetoric confirmed.$$,
        ARRAY['https://en.wikipedia.org/wiki/Tom_Lackey']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e8bdd8a7-a1b2-43e3-afd4-df975980819e', 'a22215c3-6693-4bc2-b248-01aebba14570', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e8bdd8a7-a1b2-43e3-afd4-df975980819e', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Republican from an inland district dependent on oil/gas employment. No authored fossil fuel reduction bills; Republican caucus and district context indicate support for maintaining or expanding extraction rather than restricting it.$$,
        ARRAY['https://en.wikipedia.org/wiki/Tom_Lackey']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e8bdd8a7-a1b2-43e3-afd4-df975980819e', '00b95a6a-75db-4521-b523-3326bba938de', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e8bdd8a7-a1b2-43e3-afd4-df975980819e', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Republican with strong education advocacy background (special education teacher, school board member). Republican caucus in CA consistently supports school choice/vouchers, and Lackey's education focus does not include opposition to private school alternatives.$$,
        ARRAY['https://en.wikipedia.org/wiki/Tom_Lackey']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e8bdd8a7-a1b2-43e3-afd4-df975980819e', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e8bdd8a7-a1b2-43e3-afd4-df975980819e', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Republican representing high-desert CA district. No authored immigration relief bills; Republican caucus stance and district demographics (border-region conservative lean) indicate preference for reduced immigration and stricter enforcement rather than expansion.$$,
        ARRAY['https://en.wikipedia.org/wiki/Tom_Lackey']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd4dc076-4bdd-4e10-be2c-80d998b17c50', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd4dc076-4bdd-4e10-be2c-80d998b17c50', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Authored SB 867 ($10B climate bond signed 2024), SB 54 (Plastic Pollution Prevention Act), SB 601 (clean water protections restoring nexus waters), SB 715 (RHNA climate adaptation), SB 682 (climate stabilization). Co-authored SB 252 (fossil fuel divestment for CalPERS/CalSTRS). Consistently one of the legislature's most prolific climate bill authors.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SB54', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB867', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB601']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd4dc076-4bdd-4e10-be2c-80d998b17c50', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd4dc076-4bdd-4e10-be2c-80d998b17c50', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Co-authored SB 252 (Fossil Fuel Divestment Act requiring CalPERS/CalSTRS to divest from fossil fuel companies by 2031). Authored SB 54 (plastics/single-use reduction). Strong record of restricting fossil fuel influence in state finances but has not authored a full drilling ban.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB252']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd4dc076-4bdd-4e10-be2c-80d998b17c50', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd4dc076-4bdd-4e10-be2c-80d998b17c50', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Authored SCA 2 (2021-22) to repeal Article 34 constitutional barrier to public housing construction, SB 1444 (South Bay Regional Housing Trust), SB 1092 (mobilehome park resident purchase rights), SB 749 (mobilehome preservation as affordable housing). Strong pro-affordable housing record.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SCA2']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd4dc076-4bdd-4e10-be2c-80d998b17c50', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd4dc076-4bdd-4e10-be2c-80d998b17c50', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Authored SB 502 (Medi-Cal vision care alignment) and SB 812 (youth health centers insurance billing). Authored SB 277 (eliminated personal belief vaccine exemptions). No authored single-payer bill, consistent with mainstream Democratic public option/expansion stance.$$,
        ARRAY['https://sd24.senate.ca.gov/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd4dc076-4bdd-4e10-be2c-80d998b17c50', '00b95a6a-75db-4521-b523-3326bba938de', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd4dc076-4bdd-4e10-be2c-80d998b17c50', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Arts education champion — authored SB 933 (Arts for Every Student Act), SB 777 (Arts Education Access), SB 916 (Theatre and Dance Act). Career-long commitment to funding and expanding public school arts/education programs. No support for vouchers; legislative record is entirely about strengthening public school investment.$$,
        ARRAY['https://sd24.senate.ca.gov/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bd4dc076-4bdd-4e10-be2c-80d998b17c50', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bd4dc076-4bdd-4e10-be2c-80d998b17c50', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Authored SB 450 (2019 Elections Reform Act — statewide vote centers and expanded mail-in voting without excuse requirement). This bill was a landmark expansion of California's voting access framework.$$,
        ARRAY['https://sd24.senate.ca.gov/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ed32efa5-b455-4323-a12f-5fe79bc4ffd6', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ed32efa5-b455-4323-a12f-5fe79bc4ffd6', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Authored SB 1028 (Behavioral Health Crisis Response Advisory Group) and SB 374 (local educational agencies annual reporting). Chairs Senate Committee on Military & Veterans Affairs. Democratic senator whose healthcare bills focus on behavioral health access rather than privatization or cuts.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1028']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ed32efa5-b455-4323-a12f-5fe79bc4ffd6', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ed32efa5-b455-4323-a12f-5fe79bc4ffd6', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Authored SB 714 (zero-emission vehicle workforce training) and multiple veteran/social safety net bills. Democratic senator with no authored privatization or cut bills for Medicare/Medicaid; consistent with expanding access through existing programs rather than major structural changes.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB714']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ed32efa5-b455-4323-a12f-5fe79bc4ffd6', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ed32efa5-b455-4323-a12f-5fe79bc4ffd6', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Authored SB 694 (protecting service members/veterans from deceptive practices) and SCA 4 (veterans' property tax exemption). District covers southeast LA and Orange County areas with significant immigrant communities. Democratic senator; no authored immigration restriction bills.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB694']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- social-security
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ed32efa5-b455-4323-a12f-5fe79bc4ffd6', '87d20824-a6e9-407b-983c-65440084a0ab', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ed32efa5-b455-4323-a12f-5fe79bc4ffd6', '87d20824-a6e9-407b-983c-65440084a0ab',
        $$Authored SB 1407 (military retirement pay tax exclusion up to $40,000 for qualifying veterans). While focused on veterans, this reflects a general orientation toward protecting and expanding government benefit programs rather than privatizing them.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1407']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('27a358cd-d4d8-47d6-b2f1-6d984cb46b39', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('27a358cd-d4d8-47d6-b2f1-6d984cb46b39', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Chairs the Senate Health Committee. Authored SB 729 (expanding fertility/infertility insurance coverage including IVF for large group health plans). Secured Prop 1 behavioral health funding. Healthcare expansion focus consistent with broad public access over privatization.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB729', 'https://sd20.senate.ca.gov/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('27a358cd-d4d8-47d6-b2f1-6d984cb46b39', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('27a358cd-d4d8-47d6-b2f1-6d984cb46b39', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Co-authored SB 684 (Polluters Pay Climate Superfund Act — requiring fossil fuel companies to fund climate adaptation) as lead author. Authored SB 526 (aggregate facility pollution accountability). Endorsed by California Environmental Voters for 2022 race.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB684']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('27a358cd-d4d8-47d6-b2f1-6d984cb46b39', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('27a358cd-d4d8-47d6-b2f1-6d984cb46b39', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Lead author of SB 684 (Polluters Pay Climate Superfund Act) which makes fossil fuel companies pay for climate damage. This is a strong anti-fossil fuel stance of stopping new permits and shifting costs; scored 2 as it targets existing industry accountability without a full drilling ban.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB684']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- same-sex-marriage
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('27a358cd-d4d8-47d6-b2f1-6d984cb46b39', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('27a358cd-d4d8-47d6-b2f1-6d984cb46b39', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$First LGBTQ legislator to represent San Fernando Valley. Serves on the board of directors of GLSEN's Los Angeles chapter. Personally represents LGBTQ community; consistent with requiring full federal recognition and protections for same-sex marriages.$$,
        ARRAY['https://en.wikipedia.org/wiki/Caroline_Menjivar']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('27a358cd-d4d8-47d6-b2f1-6d984cb46b39', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('27a358cd-d4d8-47d6-b2f1-6d984cb46b39', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$SB 12 co-author (establishing California Immigrant and Refugee Affairs Agency, restricting immigration enforcement data sharing). Represents San Fernando Valley district with large immigrant population. Consistent with prioritizing legal status pathways over deportation for non-violent community members.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB12']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('27a358cd-d4d8-47d6-b2f1-6d984cb46b39', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('27a358cd-d4d8-47d6-b2f1-6d984cb46b39', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Authored SB 357 (juvenile justice reform improving family stability). Chairs Senate Health Committee; broad healthcare access orientation including fertility services suggests alignment with expanded childcare subsidies for working families. Health/social services budget subcommittee chair reinforces this stance.$$,
        ARRAY['https://sd20.senate.ca.gov/', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB357']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21940b7c-2424-47e9-a649-077b0f827c2c', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21940b7c-2424-47e9-a649-077b0f827c2c', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Environmental attorney background; served as counsel to Rep. Henry Waxman on House Energy & Commerce Committee building clean energy projects. Co-authored SB 252 (CalPERS/CalSTRS fossil fuel divestment), SB 715 (RHNA climate adaptation), SB 684 (Polluters Pay Climate Superfund Act co-author). Vice Chair of Joint Legislative Committee on Climate Change Policies.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB252', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB684', 'https://sd27.senate.ca.gov/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21940b7c-2424-47e9-a649-077b0f827c2c', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21940b7c-2424-47e9-a649-077b0f827c2c', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Co-authored SB 252 (Fossil Fuel Divestment Act for CalPERS/CalSTRS). Authored/co-authored Polluters Pay Climate Superfund Act. Chairs Senate Emergency Management Committee. Acknowledged as 'dedicated environmental champion' on official bio. Co-authored SB 684. Supports ending new fossil fuel investment by state entities.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB252', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB684']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('21940b7c-2424-47e9-a649-077b0f827c2c', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('21940b7c-2424-47e9-a649-077b0f827c2c', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$SB 12 co-author (California Immigrant and Refugee Affairs Agency). Represents a Malibu/Thousand Oaks/Santa Monica Mountains district that includes immigrant agricultural workers. Campaign endorsed by pro-immigrant organizations; no restrictive immigration bill authored.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB12']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6730d01a-e87e-4177-9a2b-876b9c494774', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6730d01a-e87e-4177-9a2b-876b9c494774', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Authored SB 530 (strengthening Medi-Cal provider access, extending time-and-distance standards), SB 535 (Obesity Care Access Act expanding coverage for weight-loss treatments), SB 717 (regional cancer registries). Strong Medi-Cal expansion record consistent with broad public healthcare access approach.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB530', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB535']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- medicare/aid
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6730d01a-e87e-4177-9a2b-876b9c494774', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6730d01a-e87e-4177-9a2b-876b9c494774', 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
        $$Authored SB 530 to strengthen Medi-Cal managed care network adequacy standards, extending provider access requirements to 2029. No authored privatization or cut bills. Prior US House record shows she supported expanding healthcare access programs.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB530']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6730d01a-e87e-4177-9a2b-876b9c494774', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6730d01a-e87e-4177-9a2b-876b9c494774', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Authored SB 510 (requiring K-12 curriculum to address African American historical contributions and discriminatory barriers in California history). Prior US House record includes opposition to Iraq War and immigration enforcement while supporting civil rights measures.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB510']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6730d01a-e87e-4177-9a2b-876b9c494774', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6730d01a-e87e-4177-9a2b-876b9c494774', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Authored SB 611 (pro-housing planning protection for community plan-consistent projects), SB 748 (expands safe parking/RV encampment management options). Prior Long Beach City Council member in a port-district city with significant housing access challenges.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB611', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB748']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6730d01a-e87e-4177-9a2b-876b9c494774', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6730d01a-e87e-4177-9a2b-876b9c494774', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Authored SB 752 (extending EV truck/bus incentive project through 2028), SB 533 (EV charger app payment), SB 767 (oil pipeline monitoring). Supports clean energy transition through incentives and oversight rather than sweeping mandates or fossil fuel bans.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB752']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6730d01a-e87e-4177-9a2b-876b9c494774', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6730d01a-e87e-4177-9a2b-876b9c494774', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Prior US House record: opposed border fence, supported path to citizenship for undocumented immigrants. Press releases show concern about ICE enforcement in her district. Authored SB 34 addressing port emissions and worker concerns (many port workers are immigrants).$$,
        ARRAY['https://en.wikipedia.org/wiki/Laura_Richardson']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8566674a-3a3b-4c88-bba0-c9f42e4ff810', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8566674a-3a3b-4c88-bba0-c9f42e4ff810', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Authored SB 1137 (health protection zones banning new oil/gas wells within 3,200 ft of homes/schools), SB 252 (fossil fuel divestment CalPERS/CalSTRS), SB 1182 (climate resilient schools), SB 674 (refinery pollution reduction), SB 937 (restricting flash-bangs/explosive charges in immigration enforcement). Called 'frequent critic of Big Oil lobby in California' per Wikipedia.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SB1137', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB252']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8566674a-3a3b-4c88-bba0-c9f42e4ff810', 'a22215c3-6693-4bc2-b248-01aebba14570', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8566674a-3a3b-4c88-bba0-c9f42e4ff810', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Lead author of SB 1137 (banning new fossil fuel wells near homes/schools), SB 252 (divesting state pensions from fossil fuels), SJR 2 (endorsing Fossil Fuel Non-Proliferation Treaty). Co-signed SB 684. Authored SB 695 (CA State Highway Transparency Act). Strongest fossil fuel restriction record in this batch of Senators.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SB1137', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB252', 'https://sd33.senate.ca.gov/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- abortion
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8566674a-3a3b-4c88-bba0-c9f42e4ff810', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8566674a-3a3b-4c88-bba0-c9f42e4ff810', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Authored SB 245 (Abortion Accessibility Act — prohibiting cost-sharing for abortion services in health plans), SB 1131 (family planning Medi-Cal enrollment improvements), SB 1146 (preventing misleading AI health ads). Comprehensive pro-choice legislative record.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SB245', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB1131']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8566674a-3a3b-4c88-bba0-c9f42e4ff810', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8566674a-3a3b-4c88-bba0-c9f42e4ff810', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Authored SB 245 (zero cost-sharing for abortion), SB 1016 (Latino/Indigenous health disparities), SB 283 (Equal Insurance HIV Act). Senate Majority Leader. Broad healthcare access expansion through targeted equity-focused bills.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SB245', 'https://sd33.senate.ca.gov/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8566674a-3a3b-4c88-bba0-c9f42e4ff810', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8566674a-3a3b-4c88-bba0-c9f42e4ff810', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Authored SB 12/SB 452 (California Immigrant and Refugee Affairs Agency), SB 937 (restricting explosive devices in immigration enforcement), SJR supporting Fossil Fuel Non-Proliferation. Former Senate Majority Leader. The most comprehensive pro-immigrant legislative record among this group — establishing a dedicated state agency for immigrant inclusion.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB12', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB937']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8566674a-3a3b-4c88-bba0-c9f42e4ff810', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8566674a-3a3b-4c88-bba0-c9f42e4ff810', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Authored SB 12 (restricts immigration data sharing by new state agency), SB 937 (prohibits certain tactical weapons in immigration enforcement). Long Beach-area district has large immigrant working class. Consistent with deporting only serious violent offenders while protecting long-term community members.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB12', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB937']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8566674a-3a3b-4c88-bba0-c9f42e4ff810', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8566674a-3a3b-4c88-bba0-c9f42e4ff810', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Authored SB 939 (COVID-19 commercial evictions moratorium), SB 616 (paid sick days), SB 972 (sidewalk food vending safety). Focus on worker economic security which supports housing affordability indirectly. District includes Long Beach and port communities with severe housing cost burden.$$,
        ARRAY['https://sd33.senate.ca.gov/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('01dd07dc-ded1-4ba5-aff3-2dc2b386af12', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('01dd07dc-ded1-4ba5-aff3-2dc2b386af12', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Authored SB 98 (SAFE Act — schools must notify families when immigration enforcement is on campus), SB 281 (verbatim immigration advisement in plea agreements), SB 805 (No Vigilantes Act — prohibits bail agents from immigration enforcement). Youngest state senator; strong pro-immigrant legislative record.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB98', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB281', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB805']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- deportation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('01dd07dc-ded1-4ba5-aff3-2dc2b386af12', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('01dd07dc-ded1-4ba5-aff3-2dc2b386af12', '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$SB 281 ensures non-citizen defendants fully understand deportation consequences of criminal pleas. SB 805 bars bounty hunters from immigration enforcement. Approach is due process and protection for immigrants rather than enforcement; does not support mass deportation.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB281', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB805']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('01dd07dc-ded1-4ba5-aff3-2dc2b386af12', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('01dd07dc-ded1-4ba5-aff3-2dc2b386af12', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Authored SB 610 (disaster protections for homeowners and renters), SB 634 (prohibiting local ordinances that criminalize providing aid to unhoused), SB 293 (generational homeownership protection for inherited homes). SB 52 (anti-algorithmic rent-hike bill held in committee). Anti-criminalization and tenant protection focus.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB634', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB610']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('01dd07dc-ded1-4ba5-aff3-2dc2b386af12', '4938766b-b45a-46e3-93bd-b8b30651271a', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('01dd07dc-ded1-4ba5-aff3-2dc2b386af12', '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$Authored SB 634 (Unhoused Service Providers Protection Act) which explicitly prohibits local ordinances criminalizing aid to unhoused individuals such as providing food, water, or blankets. Decriminalizing public assistance is the core of this bill.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB634']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- childcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('01dd07dc-ded1-4ba5-aff3-2dc2b386af12', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('01dd07dc-ded1-4ba5-aff3-2dc2b386af12', 'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Authored SB 411 (vetoed) Stop Child Hunger Act 2025. Prior work at Campaign for College Opportunity included Cal Grant financial aid expansion. SB 323 (California Financial Aid Assurance Act) pending. Education access and food security bills indicate support for expanded subsidies for working families.$$,
        ARRAY['https://sd25.senate.ca.gov/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0649630c-bd6d-40fe-8f66-e026e6f6c83e', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0649630c-bd6d-40fe-8f66-e026e6f6c83e', '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Authored SB 273 (Phoenix Act — extending domestic violence statute of limitations, requiring police training), SB 316 (domestic violence hotline on student IDs), SB 1141 (coercive control evidence in family/criminal proceedings). Chairs Senate Select Committee on Domestic Violence; former public school teacher. Strong civil rights/survivor protection record.$$,
        ARRAY['https://en.wikipedia.org/wiki/Susan_Rubio', 'https://sd22.senate.ca.gov/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0649630c-bd6d-40fe-8f66-e026e6f6c83e', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0649630c-bd6d-40fe-8f66-e026e6f6c83e', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Joined California Latino Legislative Caucus press event regarding ICE enforcement impacts on families, specifically opposing 'wrongful detention' and harmful family separations. First Latina to chair Senate Insurance Committee. No authored immigration restriction bills.$$,
        ARRAY['https://sd22.senate.ca.gov/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0649630c-bd6d-40fe-8f66-e026e6f6c83e', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0649630c-bd6d-40fe-8f66-e026e6f6c83e', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Authored SB 1309 (Stop Cancer Early Act — eliminating cost-sharing for lung cancer screenings). Chairs Senate Insurance Committee. Healthcare access through insurance reform is a core legislative focus; consistent with expanding coverage while maintaining insurance-based system.$$,
        ARRAY['https://sd22.senate.ca.gov/press-releases']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Authored SB 17 (co-author — no-tax-on-tips bill for qualifying workers), SB 1137 (state medical expense deduction), SB 1144 (increase dependent tax credit), SB 23 (co-author — property tax exemption for 100% disabled veteran homeowners). Republican senator; all authored tax bills are tax reductions or exemptions, consistent with value 4.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1137', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1144', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB17']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Authored SB 1161 (requiring CARB to prepare economic impact analyses and hold public hearings before regulations take effect — a regulatory slowdown measure for environmental rules). Republican who narrowly lost to Pilar Schiavo in 2022 and won back a senate seat in 2024. Approach is regulatory skepticism and industry transparency requirements over aggressive mandates.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1161']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64', 'a22215c3-6693-4bc2-b248-01aebba14570', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Co-authored SB 1161 (CARB transparency/accountability bill slowing environmental regulations). Republican representing Santa Clarita/Simi Valley area with suburban/exurban constituents. No authored fossil fuel expansion bill confirmed; scored 4 rather than 5 as focus is regulatory slowdown not active expansion.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1161']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64', '00b95a6a-75db-4521-b523-3326bba938de', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Republican founding member of bipartisan Problem Solvers Caucus. No authored anti-voucher bill. Republican caucus in CA supports school choice programs; Santa Clarita district includes many private and charter school families.$$,
        ARRAY['https://en.wikipedia.org/wiki/Suzette_Martinez_Valladares']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c61cd23-68fb-4f1c-8a3c-60da74c86a64', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Republican whose grandfather was a Cesar Chavez farmworker (personal family history of immigration) but who now represents a predominantly Republican suburban/exurban district. No authored immigration relief bills; Republican caucus stance and her conservative voting record indicate reduced immigration preference.$$,
        ARRAY['https://en.wikipedia.org/wiki/Suzette_Martinez_Valladares']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- voting-rights
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bbd7825a-6778-4cca-81c8-8ef3ded55965', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bbd7825a-6778-4cca-81c8-8ef3ded55965', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Authored SB 884 (Protect Our Polls Act — expands mail-in drop boxes, creates 200-foot ICE-free buffer around polling places, extends ballot counting window to 10 days post-election), SB 46 (No Kings Act — barring ineligible presidential candidates), SB 72 (same-day voter registration). Career-long focus on electoral access as Senate Judiciary Committee Chair.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB884', 'https://sd34.senate.ca.gov/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bbd7825a-6778-4cca-81c8-8ef3ded55965', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bbd7825a-6778-4cca-81c8-8ef3ded55965', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Authored SB 884 which includes explicit protections against immigration enforcement near polling places. Issued statement on ICE enforcement in Orange County. Authored SB 918 (requiring social media to cooperate with law enforcement) — indicates law-and-order streak, but immigration enforcement near elections is where he draws a protective line.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB884']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bbd7825a-6778-4cca-81c8-8ef3ded55965', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bbd7825a-6778-4cca-81c8-8ef3ded55965', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Authored SB 91 (permanent CEQA exemption for motel-to-supportive-housing conversions), SB 450 (motel conversion for supportive/transitional housing), AB 2782 (mobilehome parks rent control and change-of-use protections). Consistent supportive housing expansion record, particularly for vulnerable populations.$$,
        ARRAY['https://sd34.senate.ca.gov/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- healthcare
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bbd7825a-6778-4cca-81c8-8ef3ded55965', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bbd7825a-6778-4cca-81c8-8ef3ded55965', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Authored SB 490 (SUD Treatment Safety Act), SB 27/26 (CARE Court programs for mental health), SB 349 (protecting addiction treatment patients). Healthcare focus is mental health and substance use disorder access — consistent with expanding public-program coverage.$$,
        ARRAY['https://sd34.senate.ca.gov/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- misinformation
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bbd7825a-6778-4cca-81c8-8ef3ded55965', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bbd7825a-6778-4cca-81c8-8ef3ded55965', 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d',
        $$Authored SB 678 (mandatory election advertising disclosure requirements for social media influencers) and SB 574 (Court AI Protection Act addressing AI in legal proceedings). Approach is transparency and disclosure requirements rather than heavy content removal mandates — consistent with voluntary standards plus transparency rules.$$,
        ARRAY['https://sd34.senate.ca.gov/legislation']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- taxes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b156be63-59f0-4caa-98d9-44ae7afccf79', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b156be63-59f0-4caa-98d9-44ae7afccf79', 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Authored SB 1035 (Gas Tax Relief Act — suspending motor vehicle fuel tax, Low Carbon Fuel Standard, and cap-and-trade compliance requirements for one year). Authored SB 885 (Restoring Accountability Act — requiring legislative approval for major regulations over $50M). Republican former Assembly member; consistent tax-reduction legislative record.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1035', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB885']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b156be63-59f0-4caa-98d9-44ae7afccf79', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b156be63-59f0-4caa-98d9-44ae7afccf79', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Authored SB 1035 (suspending the gas tax, Low Carbon Fuel Standard, and cap-and-trade compliance — a comprehensive rollback of climate policy). Co-authored SB 1161 (CARB regulatory slowdown). Wikipedia notes he fought state housing mandates in Huntington Beach as mayor, citing 'economic growth' priorities over regulation. Supported Trump as delegate and chaired pro-Trump super PAC.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1035', 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1161']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- fossil-fuels
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b156be63-59f0-4caa-98d9-44ae7afccf79', 'a22215c3-6693-4bc2-b248-01aebba14570', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b156be63-59f0-4caa-98d9-44ae7afccf79', 'a22215c3-6693-4bc2-b248-01aebba14570',
        $$SB 1035 suspends the Low Carbon Fuel Standard (which reduces fossil fuel carbon intensity) and cap-and-trade compliance for fossil fuel suppliers. This is the most direct authored rollback of fossil fuel restrictions of any senator in this batch. Consistent with maximizing energy production over environmental constraints.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1035']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b156be63-59f0-4caa-98d9-44ae7afccf79', '669cac97-66a6-4087-b036-936fbe62efb3', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b156be63-59f0-4caa-98d9-44ae7afccf79', '669cac97-66a6-4087-b036-936fbe62efb3',
        $$As Huntington Beach mayor and council member, fought state housing mandates and was a defendant in a state AG housing enforcement lawsuit. Wikipedia notes he stated the city is '95% built out' and 'resists anything that guts our suburban coastal community.' AG Bonta sued Huntington Beach for violating the California HOME Act under his tenure. Consistent with eliminating housing programs.$$,
        ARRAY['https://en.wikipedia.org/wiki/Tony_Strickland']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- immigration
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b156be63-59f0-4caa-98d9-44ae7afccf79', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b156be63-59f0-4caa-98d9-44ae7afccf79', '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Trump delegate and chair of pro-Trump super PAC (Wikipedia). SB 1035 bill language explicitly suspends climate compliance without any carve-outs for immigrant worker protections. Authored SB 1027 (Street Prostitution Task Force). Consistent with stopping all immigration as a policy priority.$$,
        ARRAY['https://en.wikipedia.org/wiki/Tony_Strickland']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- school-vouchers
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b156be63-59f0-4caa-98d9-44ae7afccf79', '00b95a6a-75db-4521-b523-3326bba938de', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b156be63-59f0-4caa-98d9-44ae7afccf79', '00b95a6a-75db-4521-b523-3326bba938de',
        $$Republican co-authoring SB 1133 (health education curriculum) and SB 1134 (restricting food purchases with CalFresh benefits). No authored universal voucher bill confirmed; scored 4 consistent with expanded school choice eligibility for most families without full universalization.$$,
        ARRAY['https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202520260SB1133']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;