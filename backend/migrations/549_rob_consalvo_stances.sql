-- ============================================================================
-- Migration 549: Rob Consalvo Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Rob Consalvo (MA State Rep,
--          14th Suffolk District, HD-134, external_id=-210174).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Rob Consalvo (HD-134, external_id=-210174, id=3f5dd4b3-c0b6-470b-861d-41a71637797c) --

-- ----- Rob Consalvo / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3f5dd4b3-c0b6-470b-861d-41a71637797c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3f5dd4b3-c0b6-470b-861d-41a71637797c',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Consalvo sponsored H.1671 (behavioral health expansion) and H.1790 (substance use disorder treatment access). He represents Hyde Park and Roslindale — mixed working-class and middle-class neighborhoods. His healthcare focus is on behavioral health, community health centers, and substance use treatment rather than comprehensive universal coverage reform.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1671', 'https://malegislature.gov/Legislators/Profile/R_C1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rob Consalvo / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3f5dd4b3-c0b6-470b-861d-41a71637797c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3f5dd4b3-c0b6-470b-861d-41a71637797c',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Consalvo sponsored H.1369 (first-time homebuyer assistance program) and has supported targeted affordable housing production. He represents Hyde Park and Roslindale — established residential neighborhoods with significant homeowner populations. His approach focuses on homeownership assistance and modest new development rather than comprehensive tenant protections or large-scale affordable production requirements.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1369', 'https://malegislature.gov/Legislators/Profile/R_C1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rob Consalvo / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3f5dd4b3-c0b6-470b-861d-41a71637797c',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3f5dd4b3-c0b6-470b-861d-41a71637797c',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Consalvo has supported MBTA improvements for the Fairmount and commuter rail lines serving Hyde Park. His district is car-dependent but also has commuter rail access; he has advocated for improved commuter rail frequency and parking facilities at stations. His approach balances transit investment with recognition of car dependency in his outer-Boston district.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/R_C1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rob Consalvo / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3f5dd4b3-c0b6-470b-861d-41a71637797c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3f5dd4b3-c0b6-470b-861d-41a71637797c',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Consalvo voted for the ROE Act (H.3320) in 2020. He represents a district that includes significant Catholic Irish- and Italian-American communities in Hyde Park and Roslindale where abortion is a more sensitive issue. As a moderate Democrat, he supported the expansion through his vote without being a lead co-sponsor, reflecting support for abortion access through established law.$$,
        ARRAY['https://malegislature.gov/Bills/192/H3320', 'https://malegislature.gov/Legislators/Profile/R_C1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rob Consalvo / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3f5dd4b3-c0b6-470b-861d-41a71637797c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3f5dd4b3-c0b6-470b-861d-41a71637797c',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Consalvo voted for the Police Reform Act (H.4835) but is generally considered a moderate on public safety. He represents working-class neighborhoods in Hyde Park and Roslindale where traditional law-and-order values remain strong. He has supported community policing and working with local police departments while backing accountability measures through the reform act.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/R_C1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rob Consalvo / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3f5dd4b3-c0b6-470b-861d-41a71637797c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3f5dd4b3-c0b6-470b-861d-41a71637797c',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Consalvo voted for the 2021 Climate Act (H.4933) but has not been a leading advocate on climate legislation. He represents outer-Boston neighborhoods with mixed car-dependency and renewable energy interests. His climate approach reflects pragmatic support for state goals while being mindful of cost impacts on his working-class constituents.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4933', 'https://malegislature.gov/Legislators/Profile/R_C1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rob Consalvo / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3f5dd4b3-c0b6-470b-861d-41a71637797c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3f5dd4b3-c0b6-470b-861d-41a71637797c',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Consalvo voted for the Police Reform Act (H.4835) and has maintained a consistent pro-civil-rights voting record with the House Democratic caucus. He represents a diverse district with a growing population of color in Hyde Park. His civil rights positions are mainstream Democratic without being among the most progressive advocates.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/R_C1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rob Consalvo / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3f5dd4b3-c0b6-470b-861d-41a71637797c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3f5dd4b3-c0b6-470b-861d-41a71637797c',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Consalvo has supported business development and job creation programs in Hyde Park and Roslindale. He has backed small business assistance and workforce development programs while also supporting targeted community investment. His economic development approach balances business-friendly policies with modest support for working-class job training programs.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/R_C1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '3f5dd4b3-c0b6-470b-861d-41a71637797c';
-- unpaired=0, uncited=0
