-- ============================================================================
-- Migration 553: Michael J. Moran Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Michael J. Moran (MA State Rep,
--          18th Suffolk District, HD-138, external_id=-210178).
--          NOTE: Different from John F. Moran (HD-129, -210169, migration 544).
--          Long-serving Brighton/West Roxbury representative.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Michael J. Moran (HD-138, external_id=-210178, id=9b3c9aa8-d22a-4761-93e3-8054c762f4a5) --

-- ----- Michael J. Moran / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Michael J. Moran sponsored H.1699 (behavioral health access) and H.1811 (substance use disorder treatment services). He represents Brighton and West Roxbury — working-class neighborhoods with community health needs. His healthcare focus is on community health center funding, behavioral health expansion, and substance use treatment rather than structural reform.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1699', 'https://malegislature.gov/Legislators/Profile/MJM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Moran / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$M.J. Moran co-sponsored H.1371 (first-time homebuyer assistance) and has supported targeted affordable housing programs. He represents Brighton and West Roxbury — neighborhoods with established homeowner populations and community concerns about overdevelopment. His housing approach focuses on first-time homebuyers and modest affordable unit requirements rather than comprehensive tenant protections or major zoning reform.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1371', 'https://malegislature.gov/Legislators/Profile/MJM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Moran / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$M.J. Moran voted for the Police Reform Act (H.4835) but is generally moderate on public safety. He represents Brighton and West Roxbury — working-class neighborhoods with Irish-American heritage where traditional law-and-order values remain influential. He has supported police accountability reforms while maintaining support for community policing programs and law enforcement partnerships.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/MJM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Moran / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$M.J. Moran voted for the 2021 Climate Act (H.4933) but has not been a leading climate advocate. He represents Brighton and West Roxbury — neighborhoods with mixed car-dependency and energy interests. His climate positions are mainstream Democratic but tempered by concern about utility rate impacts on working-class households in his district.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4933', 'https://malegislature.gov/Legislators/Profile/MJM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Moran / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$M.J. Moran represents a traditionally Catholic Irish-American community in Brighton and West Roxbury. His voting record on the ROE Act reflects complex community values; he has been one of the more moderate Democrats on abortion access. While he has voted for abortion access expansion legislation when required, his position reflects the more conservative cultural values of his Irish-American Brighton constituency.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MJM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Moran / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$M.J. Moran has supported both MBTA improvements and road maintenance for his Brighton and West Roxbury district. West Roxbury is significantly car-dependent with limited transit access; he has advocated for both transit service improvements and highway maintenance. His approach balances transit investment with car-dependent constituency needs.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MJM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Moran / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$M.J. Moran voted for the Police Reform Act (H.4835) and has maintained civil rights voting record in line with House Democratic caucus. He represents a more moderate district culturally and while he supports core civil rights protections, he is not among the most progressive voices on expanding protections. His record reflects mainstream Democratic positions without deep advocacy on civil rights expansion.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/MJM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Moran / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$M.J. Moran co-sponsored the Safe Communities Act (H.3369) and has supported immigrant integration. Brighton has a significant immigrant population, particularly from Brazil and China, and he has advocated for immigrant access to state services. His approach reflects moderate support for immigrant protections while representing a mixed constituency on immigration issues.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/MJM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michael J. Moran / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9b3c9aa8-d22a-4761-93e3-8054c762f4a5',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$M.J. Moran has supported local business development and job creation in Brighton. His approach favors small business assistance and workforce development programs appropriate for his working-class district. He supports economic growth through both business-friendly policies and targeted job training, reflecting a centrist economic development position.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/MJM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '9b3c9aa8-d22a-4761-93e3-8054c762f4a5';
-- unpaired=0, uncited=0
