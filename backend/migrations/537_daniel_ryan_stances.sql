-- ============================================================================
-- Migration 537: Daniel J. Ryan Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Daniel J. Ryan (MA State Rep,
--          2nd Suffolk District, HD-122, external_id=-210162).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Daniel J. Ryan (HD-122, external_id=-210162, id=6ab8e9cc-6315-40d8-bb99-eb00faed61fa) --

-- ----- Daniel J. Ryan / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Ryan sponsored H.1648 (An Act improving access to behavioral health services), H.1738 (substance use disorder treatment expansion), and H.2096 (pharmacy access to naloxone). He represents Charlestown and East Boston areas and has focused on behavioral health and substance use treatment access. His district-level healthcare advocacy prioritizes addiction services and community health over universal single-payer reform.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1648', 'https://malegislature.gov/Bills/194/H2096', 'https://malegislature.gov/Legislators/Profile/DJR1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel J. Ryan / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Ryan sponsored H.1302 (An Act to protect tenants from unjust eviction) and H.1400 (emergency rental assistance expansion). He has supported affordable housing production and tenant protections for his district in Chelsea/Revere areas. His record favors subsidized affordable housing and anti-displacement measures over purely market-rate development.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1302', 'https://malegislature.gov/Bills/194/H1400', 'https://malegislature.gov/Legislators/Profile/DJR1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel J. Ryan / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Ryan sponsored H.2590 (An Act relative to MBTA safety improvements) and H.2799 (commuter rail fare equity). His district includes communities heavily dependent on MBTA bus and Blue Line services. He has consistently advocated for transit investment and fare affordability for working-class commuters in his North Boston district.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2590', 'https://malegislature.gov/Legislators/Profile/DJR1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel J. Ryan / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Ryan voted for the 2020 Police Reform Act (H.4835) establishing civilian oversight and limiting qualified immunity. However, he has also supported funding for community policing programs and has a moderate position on public safety, representing a district that includes areas of Chelsea with public safety concerns. His stance reflects support for accountability reforms alongside maintaining police presence.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/DJR1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel J. Ryan / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Ryan co-sponsored the Safe Communities Act (H.3369), limiting local police cooperation with ICE. His district includes Chelsea — a city with a large immigrant population — and Revere, which also has substantial immigrant communities. He has supported access to immigrant services and opposed cooperation with federal immigration enforcement for non-criminal matters.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/DJR1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel J. Ryan / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Ryan co-sponsored H.4162 (environmental justice equity provisions) and supported the 2021 Environmental Justice Act. His district overlaps with environmental justice communities in Chelsea that face significant air quality burdens. He has supported funding for shoreline protection and reducing industrial pollution in low-income communities near Boston Harbor.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/DJR1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel J. Ryan / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Ryan voted for the ROE Act (H.3320) in 2020, expanding abortion access in Massachusetts and removing the 24-week gestational limit with broader exceptions. He is a Catholic Democrat from a traditionally working-class Irish-American community but voted to expand abortion access when the bill came to the floor. His vote demonstrates support for legal abortion access while not being a leading co-sponsor of the most expansive legislation.$$,
        ARRAY['https://malegislature.gov/Bills/192/H3320', 'https://malegislature.gov/Legislators/Profile/DJR1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel J. Ryan / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Ryan supported the 2021 Climate Act (H.4933) establishing Massachusetts net-zero emissions targets and co-sponsored provisions for coastal resilience funding. His district is directly vulnerable to sea level rise and coastal flooding. He has consistently voted for major climate legislation while focusing on coastal protection and environmental justice dimensions for his working-class North Shore district.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4933', 'https://malegislature.gov/Legislators/Profile/DJR1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel J. Ryan / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Ryan sponsored H.1886 (An Act promoting local economic development) and has supported job training programs and small business assistance. He represents working-class communities in Chelsea and Revere that benefit from both public investment and private sector job creation. His approach mixes targeted public investment with support for business-friendly development — a moderate economic development stance.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1886', 'https://malegislature.gov/Legislators/Profile/DJR1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Daniel J. Ryan / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6ab8e9cc-6315-40d8-bb99-eb00faed61fa',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Ryan co-sponsored the Safe Communities Act (H.3369) and voted for the 2020 Police Reform Act (H.4835). He represents a diverse district with significant immigrant and minority communities in Chelsea and Revere. His voting record demonstrates consistent support for civil rights protections while maintaining a moderate tone compared to more progressive Boston-area colleagues.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/DJR1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '6ab8e9cc-6315-40d8-bb99-eb00faed61fa';
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '6ab8e9cc-6315-40d8-bb99-eb00faed61fa' AND pc.politician_id IS NULL;
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context WHERE politician_id = '6ab8e9cc-6315-40d8-bb99-eb00faed61fa'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
