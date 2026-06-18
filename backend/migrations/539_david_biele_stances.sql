-- ============================================================================
-- Migration 539: David Biele Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for David Biele (MA State Rep,
--          4th Suffolk District, HD-124, external_id=-210164).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- David Biele (HD-124, external_id=-210164, id=f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f) --

-- ----- David Biele / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Biele sponsored H.1623 (An Act relative to behavioral health access) and H.1744 (telehealth expansion for community health centers). He represents a district that includes Chinatown and South Boston communities with underserved healthcare needs. His focus is on community health center funding and behavioral health access rather than single-payer reform.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1623', 'https://malegislature.gov/Legislators/Profile/D_B1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Biele / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Biele sponsored H.1299 (An Act to protect tenants facing eviction) and H.1357 (affordable housing preservation in urban areas). His district includes rapidly gentrifying South Boston and Chinatown neighborhoods facing significant displacement pressures. He has been an advocate for tenant protections and community land trusts to prevent displacement of long-term residents.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1299', 'https://malegislature.gov/Legislators/Profile/D_B1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Biele / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Biele co-sponsored H.3369 (Safe Communities Act) limiting ICE cooperation and protecting immigrant communities. His district includes Chinatown — a predominantly Asian-American immigrant community — and he has been a consistent advocate for immigrant rights and access to state services regardless of immigration status.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/D_B1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Biele / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Biele co-sponsored the Safe Communities Act (H.3369), preventing local police from asking about immigration status or cooperating with ICE. His Chinatown constituency has a high proportion of immigrant residents; he has advocated for local sanctuary policies ensuring all residents can access city services without fear of deportation.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/D_B1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Biele / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Biele voted for the 2021 Climate Act (H.4933) and co-sponsored H.2956 (clean energy transition). His South Boston/Chinatown district includes coastal areas vulnerable to sea level rise and urban heat island effects. He has supported clean energy investment and climate resilience as key priorities for his vulnerable urban communities.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4933', 'https://malegislature.gov/Legislators/Profile/D_B1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Biele / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Biele co-sponsored environmental justice legislation including H.4264 protections for communities of color facing disproportionate pollution. Chinatown — the densest part of his district — is a designated Environmental Justice community surrounded by highway infrastructure (Mass Pike, I-93) and faces significant air quality burdens. He has been an advocate for reducing highway pollution impacts and investing in urban green infrastructure.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4264', 'https://malegislature.gov/Legislators/Profile/D_B1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Biele / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Biele co-sponsored H.1742 (An Act to expand access to abortion care) and voted for the ROE Act (H.3320). He has been a consistent supporter of reproductive rights and comprehensive abortion access in Massachusetts, including expanding access for low-income patients and removing barriers to late-term procedures when medically necessary.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1742', 'https://malegislature.gov/Bills/192/H3320', 'https://malegislature.gov/Legislators/Profile/D_B1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Biele / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Biele co-sponsored H.1693 (anti-discrimination protections) and the Safe Communities Act (H.3369). Representing a district with large Asian-American and immigrant communities, he has been an advocate for anti-discrimination enforcement and equal access to public services. He supported hate crime reporting requirements and anti-Asian discrimination measures introduced after pandemic-era attacks.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/D_B1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Biele / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Biele sponsored H.2733 (MBTA accessibility improvements) and has been a strong advocate for transit investment. South Boston and Chinatown are served by the Red Line, Silver Line, and multiple MBTA bus routes. He has consistently supported MBTA capital investment, fare affordability, and transit-oriented development as his district's primary transportation mode.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2733', 'https://malegislature.gov/Legislators/Profile/D_B1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David Biele / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Biele voted for the 2020 Police Reform Act (H.4835) and has supported community-based violence prevention programs as an alternative to traditional policing for mental health crises. He has advocated for police accountability and community oversight. His overall approach favors accountability reforms and community investment while supporting public safety services for his urban district.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/D_B1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'f5ab360a-7ec0-4af9-8d9a-1eb17e842b9f';
-- unpaired=0, uncited=0
