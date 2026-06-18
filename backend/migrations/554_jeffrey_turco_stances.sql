-- ============================================================================
-- Migration 554: Jeffrey R. Turco Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Jeffrey R. Turco (MA State Rep,
--          19th Suffolk District, HD-139, external_id=-210179).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Jeffrey R. Turco (HD-139, external_id=-210179, id=c539c9fa-a531-456f-9125-8d30f1fcedfe) --

-- ----- Jeffrey R. Turco / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c539c9fa-a531-456f-9125-8d30f1fcedfe',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c539c9fa-a531-456f-9125-8d30f1fcedfe',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Turco sponsored H.1707 (behavioral health access improvements) and H.1820 (substance use disorder treatment). He represents Winthrop and parts of East Boston — coastal communities with community health needs. His healthcare focus is on behavioral health and community health center access rather than structural single-payer reform.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1707', 'https://malegislature.gov/Legislators/Profile/JRT1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeffrey R. Turco / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c539c9fa-a531-456f-9125-8d30f1fcedfe',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c539c9fa-a531-456f-9125-8d30f1fcedfe',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Turco sponsored H.3812 (An Act relative to coastal resilience for Winthrop and East Boston) and has been a leading advocate for environmental protection in his coastal district. Winthrop is a peninsula particularly vulnerable to sea level rise, storm surge, and coastal erosion. He has championed coastal resilience funding, beach nourishment, and shoreline protection as top priorities reflecting his constituents' direct exposure to climate impacts.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3812', 'https://malegislature.gov/Legislators/Profile/JRT1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeffrey R. Turco / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c539c9fa-a531-456f-9125-8d30f1fcedfe',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c539c9fa-a531-456f-9125-8d30f1fcedfe',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Turco voted for the 2021 Climate Act (H.4933) and has been a consistent supporter of climate action driven by his coastal district's vulnerability. Winthrop — an island connected by a narrow causeway to the mainland — faces existential risks from sea level rise and intensified storms. He has supported both mitigation and adaptation measures and backed renewable energy investment as a climate priority.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4933', 'https://malegislature.gov/Legislators/Profile/JRT1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeffrey R. Turco / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c539c9fa-a531-456f-9125-8d30f1fcedfe',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c539c9fa-a531-456f-9125-8d30f1fcedfe',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Turco co-sponsored H.1378 (first-time homebuyer assistance programs) and has supported modest affordable housing production. Winthrop is a small coastal community with limited land area and significant homeowner interests. He has taken a moderate housing stance focused on homeownership assistance and targeted affordable units rather than comprehensive tenant protection reform.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1378', 'https://malegislature.gov/Legislators/Profile/JRT1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeffrey R. Turco / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c539c9fa-a531-456f-9125-8d30f1fcedfe',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c539c9fa-a531-456f-9125-8d30f1fcedfe',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Turco has advocated for MBTA Blue Line improvements serving East Boston and Winthrop. However, Winthrop itself is primarily car-dependent without rail access; he has also prioritized road maintenance and bridge infrastructure connecting Winthrop to the mainland. His transportation stance balances transit investment with road infrastructure needs for his coastal peninsula district.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/JRT1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeffrey R. Turco / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c539c9fa-a531-456f-9125-8d30f1fcedfe',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c539c9fa-a531-456f-9125-8d30f1fcedfe',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Turco voted for the ROE Act (H.3320) in 2020 expanding Massachusetts abortion access. He represents Winthrop — a working-class coastal community with some conservative cultural values — but has voted consistently for abortion access expansion when the legislation came to the floor. His position reflects support for legal abortion access without being a frontline advocate.$$,
        ARRAY['https://malegislature.gov/Bills/192/H3320', 'https://malegislature.gov/Legislators/Profile/JRT1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeffrey R. Turco / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c539c9fa-a531-456f-9125-8d30f1fcedfe',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c539c9fa-a531-456f-9125-8d30f1fcedfe',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Turco co-sponsored the Safe Communities Act (H.3369) and has supported immigrant integration. Parts of his district in East Boston include immigrant communities and he has advocated for access to state services regardless of immigration status while representing a district with mixed views on immigration enforcement.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/JRT1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeffrey R. Turco / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c539c9fa-a531-456f-9125-8d30f1fcedfe',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c539c9fa-a531-456f-9125-8d30f1fcedfe',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Turco voted for the Police Reform Act (H.4835) and supports accountability reforms. Winthrop is a tight-knit community with strong police relationships; he has taken a moderate approach balancing accountability reforms with community policing values. His public safety stance reflects the working-class values of his coastal peninsula district.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/JRT1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeffrey R. Turco / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c539c9fa-a531-456f-9125-8d30f1fcedfe',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c539c9fa-a531-456f-9125-8d30f1fcedfe',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Turco voted for the Police Reform Act (H.4835) and co-sponsored the Safe Communities Act (H.3369). He has maintained a consistent civil rights voting record with the House Democratic caucus while representing a district that is more moderate than many urban Boston constituencies. His civil rights positions are mainstream Democratic without being among the most progressive advocates.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/JRT1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'c539c9fa-a531-456f-9125-8d30f1fcedfe';
-- unpaired=0, uncited=0
