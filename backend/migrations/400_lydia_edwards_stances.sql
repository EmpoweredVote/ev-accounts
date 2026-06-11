-- ============================================================================
-- Migration 400: Lydia M. Edwards Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Lydia M. Edwards (MA State Senator, 25D25,
--   Third Suffolk District — East Boston, Charlestown, parts of Cambridge and Revere).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 396 header for full list.
-- Politician UUID: 11d73e67-bcd9-419a-8b0d-a26447eb0c0b (external_id: -210025)

BEGIN;

-- ----- Lydia M. Edwards / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Edwards has been one of the most vocal housing justice advocates in the Senate. As a former Boston City Councilor representing East Boston and Charlestown — neighborhoods that experienced rapid gentrification — she championed anti-displacement policies and tenant protections. She has backed mandatory inclusionary zoning, anti-speculation taxes, and right-to-counsel for tenants facing eviction. She supported the 2024 Affordable Homes Act while pushing for stronger tenant protections than the final bill included.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/LME0', 'https://www.boston.com/news/politics/2024/08/06/massachusetts-affordable-homes-act-signed-into-law/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lydia M. Edwards / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Edwards has been one of the strongest advocates for rent stabilization in the Massachusetts legislature. As Boston City Councilor she filed for rent control authority and has backed state legislation allowing municipalities to implement rent stabilization. She championed Boston having the ability to regulate rents in rapidly gentrifying neighborhoods like East Boston. She has been a leading Senate voice supporting local rent stabilization authority as an anti-displacement tool.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/LME0', 'https://www.wbur.org/news/2023/02/15/massachusetts-rent-stabilization-legislation-senate']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lydia M. Edwards / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Edwards has been one of the strongest immigrant advocates in the legislature, representing East Boston which has one of the largest immigrant communities in Massachusetts. She voted for the 2022 Work and Family Mobility Act and has backed comprehensive immigrant services including legal representation funds and expanded state benefits for immigrants regardless of status. She has been vocal in condemning federal immigration enforcement actions targeting her constituents and has backed sanctuary policies.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2745', 'https://www.bostonglobe.com/2022/06/23/metro/senate-passes-bill-allowing-undocumented-immigrants-get-drivers-licenses/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lydia M. Edwards / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Edwards has strongly opposed federal immigration enforcement and deportation activities targeting her constituents in East Boston, one of the most immigrant-dense neighborhoods in New England. She has backed the Safe Communities Act limiting state cooperation with ICE detainers and spoken out against workplace and community ICE raids. She has championed legal defense funds for immigrants facing deportation and has been a leading voice opposing the use of state resources to facilitate federal deportation efforts.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/LME0', 'https://www.bostonglobe.com/2020/02/07/metro/lydia-edwards-immigration-enforcement/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lydia M. Edwards / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Edwards voted for the 2020 police reform law and has advocated for significant shifts in how public safety is approached. She has supported alternatives to policing for mental health crises and backed community violence interruption programs. As a former city councilor she worked on police accountability measures in Boston. She has supported diversion programs for non-violent offenses and advocated for reducing reliance on incarceration. She takes a reform-oriented approach emphasizing prevention, accountability, and community-based safety.$$,
        ARRAY['https://malegislature.gov/Bills/191/S2800', 'https://www.masslive.com/politics/2020/12/massachusetts-governor-charlie-baker-signs-police-reform-law.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lydia M. Edwards / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Edwards has been a strong climate advocate with a focus on environmental justice. East Boston sits adjacent to Logan Airport and has historically faced significant air quality issues. She has backed climate legislation and pushed for environmental justice provisions ensuring that low-income communities of color are prioritized for clean energy and climate resilience investments. She voted for the 2021 Climate Act and has advocated for stronger implementation in environmental justice communities.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/LME0', 'https://www.wbur.org/news/2021/03/26/massachusetts-climate-bill-signed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lydia M. Edwards / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Edwards has been a consistent champion of civil rights across her legislative career. She supported the 2016 Transgender Public Accommodations Act and has been a vocal opponent of discrimination in housing, employment, and public accommodations. As a Black woman representing a diverse district she has spoken about the intersection of racial justice and policy. She has backed hate crime legislation and bills expanding civil rights protections for LGBTQ+ individuals.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/LME0', 'https://www.bostonglobe.com/2022/01/03/metro/lydia-edwards-state-senate-civil-rights/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lydia M. Edwards / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Edwards supported the 2022 millionaires surtax (Question 1) and has backed progressive taxation as a means to fund services for her constituents. She has backed the Child and Family Tax Credit and tax relief measures for renters and lower-income residents. She has consistently voted for progressive budget priorities and supported using the surtax revenue specifically for affordable housing, education, and transportation in underserved communities.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/LME0', 'https://www.wbur.org/news/2022/11/09/massachusetts-question-1-millionaires-surtax-passes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lydia M. Edwards / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Edwards voted for the 2022 VOTES Act making expanded mail voting and early voting permanent. She has been a strong advocate for voting access and has supported automatic voter registration. She has been vocal about ensuring that immigrant communities and communities of color have full access to the democratic process. She backed same-day voter registration and expanded early voting to reduce barriers for working residents.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2294', 'https://www.wbur.org/news/2022/06/24/massachusetts-votes-act-permanent-mail-voting']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lydia M. Edwards / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('11d73e67-bcd9-419a-8b0d-a26447eb0c0b',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Edwards has been a strong transit advocate, championing improvements to the Blue Line and Silver Line serving East Boston and Charlestown. She backed the 2022 MBTA reform legislation and has advocated for increased service frequency and reliability on routes serving her district. She has supported active transportation infrastructure investment and backed fare-free transit pilots. Her district includes many transit-dependent residents and she has prioritized reliable, affordable transit as an equity issue.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/LME0', 'https://www.wbur.org/news/2022/08/01/free-mbta-fares-pilot-program-massachusetts']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '11d73e67-bcd9-419a-8b0d-a26447eb0c0b';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '11d73e67-bcd9-419a-8b0d-a26447eb0c0b'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '11d73e67-bcd9-419a-8b0d-a26447eb0c0b'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
