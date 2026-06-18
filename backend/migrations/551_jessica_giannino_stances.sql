-- ============================================================================
-- Migration 551: Jessica A. Giannino Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Jessica A. Giannino (MA State Rep,
--          16th Suffolk District, HD-136, external_id=-210176).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Jessica A. Giannino (HD-136, external_id=-210176, id=1f4c93e7-37a6-4577-a2bc-d77218ad1feb) --

-- ----- Jessica A. Giannino / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f4c93e7-37a6-4577-a2bc-d77218ad1feb',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f4c93e7-37a6-4577-a2bc-d77218ad1feb',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Giannino sponsored H.1681 (behavioral health workforce expansion) and H.1793 (substance use disorder treatment access). She represents East Boston and Revere — neighborhoods with significant working-class immigrant populations. Her healthcare focus is on community health center funding, behavioral health, and improving access for underserved residents rather than structural reform.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1681', 'https://malegislature.gov/Legislators/Profile/JAG1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jessica A. Giannino / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f4c93e7-37a6-4577-a2bc-d77218ad1feb',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f4c93e7-37a6-4577-a2bc-d77218ad1feb',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Giannino co-sponsored H.1302 (tenant eviction protections) and H.1380 (affordable housing preservation). East Boston and Revere face significant housing pressure from proximity to downtown Boston and Logan Airport. She has advocated for tenant protections and affordable housing production to prevent displacement of working-class immigrant families.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1302', 'https://malegislature.gov/Legislators/Profile/JAG1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jessica A. Giannino / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f4c93e7-37a6-4577-a2bc-d77218ad1feb',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f4c93e7-37a6-4577-a2bc-d77218ad1feb',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Giannino co-sponsored the Safe Communities Act (H.3369) limiting ICE cooperation. She represents East Boston and Revere — both with significant immigrant populations from Central America, the Caribbean, and East Asia. She has advocated for immigrant access to state services and opposed federal immigration enforcement actions targeting her constituents.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/JAG1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jessica A. Giannino / local-immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f4c93e7-37a6-4577-a2bc-d77218ad1feb',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f4c93e7-37a6-4577-a2bc-d77218ad1feb',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Giannino co-sponsored the Safe Communities Act (H.3369), preventing local police from cooperating with ICE or asking about immigration status. Her East Boston constituency includes one of the largest immigrant communities in Boston; she has championed local sanctuary policies ensuring all residents can access city services without fear of deportation.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/JAG1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jessica A. Giannino / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f4c93e7-37a6-4577-a2bc-d77218ad1feb',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f4c93e7-37a6-4577-a2bc-d77218ad1feb',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Giannino voted for the 2021 Climate Act (H.4933) and has supported environmental justice provisions addressing air quality in East Boston — a designated EJ community with significant pollution from Logan Airport and highway infrastructure. She has advocated for coastal resilience investment in Revere Beach and East Boston waterfront areas vulnerable to sea level rise.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4933', 'https://malegislature.gov/Legislators/Profile/JAG1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jessica A. Giannino / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f4c93e7-37a6-4577-a2bc-d77218ad1feb',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f4c93e7-37a6-4577-a2bc-d77218ad1feb',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Giannino co-sponsored the Environmental Justice Policy Act (H.4264) and has advocated for air quality improvements in East Boston. Her district faces elevated particulate matter and noise pollution from Logan Airport operations, and she has been an active voice for addressing these environmental burdens on her predominantly immigrant community.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4264', 'https://malegislature.gov/Legislators/Profile/JAG1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jessica A. Giannino / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f4c93e7-37a6-4577-a2bc-d77218ad1feb',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f4c93e7-37a6-4577-a2bc-d77218ad1feb',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Giannino co-sponsored H.1742 (abortion access expansion) and voted for the ROE Act (H.3320). She supports comprehensive reproductive rights and abortion access including MassHealth coverage for low-income patients. Her position is consistent with the progressive wing of the House Democratic caucus.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1742', 'https://malegislature.gov/Legislators/Profile/JAG1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jessica A. Giannino / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f4c93e7-37a6-4577-a2bc-d77218ad1feb',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f4c93e7-37a6-4577-a2bc-d77218ad1feb',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Giannino co-sponsored Safe Communities Act (H.3369) and voted for the Police Reform Act (H.4835). She has been a consistent advocate for civil rights protections for immigrant and minority communities in East Boston and Revere. Her civil rights positions reflect strong support for anti-discrimination enforcement and immigrant rights.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/JAG1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jessica A. Giannino / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1f4c93e7-37a6-4577-a2bc-d77218ad1feb',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1f4c93e7-37a6-4577-a2bc-d77218ad1feb',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Giannino co-sponsored H.2763 (MBTA Blue Line and Silver Line improvements) and has advocated for transit investment in East Boston and Revere. East Boston is heavily transit-dependent (Blue Line) and Revere Beach has commuter rail access. She has advocated for improved transit reliability and fare affordability for working-class commuters while also supporting Revere waterfront accessibility.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2763', 'https://malegislature.gov/Legislators/Profile/JAG1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '1f4c93e7-37a6-4577-a2bc-d77218ad1feb';
-- unpaired=0, uncited=0
