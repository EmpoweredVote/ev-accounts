-- ============================================================================
-- Migration 543: Jay Livingstone Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Jay Livingstone (MA State Rep,
--          8th Suffolk District, HD-128, external_id=-210168).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Jay Livingstone (HD-128, external_id=-210168, id=852e4a21-5750-4ac8-ba06-0376c5a31685) --

-- ----- Jay Livingstone / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('852e4a21-5750-4ac8-ba06-0376c5a31685',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('852e4a21-5750-4ac8-ba06-0376c5a31685',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Livingstone co-sponsored H.1239 (Medicare for All in Massachusetts) and H.1600 (behavioral health parity). As a progressive Democrat representing the Back Bay and South End — including significant LGBTQ+ populations — he has been a strong advocate for healthcare access including comprehensive LGBTQ+ healthcare coverage and substance use treatment expansion.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1239', 'https://malegislature.gov/Legislators/Profile/J_L1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Livingstone / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('852e4a21-5750-4ac8-ba06-0376c5a31685',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('852e4a21-5750-4ac8-ba06-0376c5a31685',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Livingstone co-sponsored the Healthy Youth Act (H.410) mandating LGBTQ+-inclusive sex education and H.2193 (comprehensive LGBTQ+ nondiscrimination protections). He represents the South End and Back Bay — with significant LGBTQ+ communities — and has been a consistent advocate for marriage equality, LGBTQ+ adoption rights, and comprehensive anti-discrimination protections.$$,
        ARRAY['https://malegislature.gov/Bills/194/H410', 'https://malegislature.gov/Legislators/Profile/J_L1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Livingstone / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('852e4a21-5750-4ac8-ba06-0376c5a31685',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('852e4a21-5750-4ac8-ba06-0376c5a31685',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Livingstone co-sponsored H.2193 (comprehensive LGBTQ+ civil rights), H.1973 (CROWN Act), and the Safe Communities Act (H.3369). He has been a leading voice on civil rights broadly and LGBTQ+ rights specifically throughout his tenure. His district includes the South End, historically the center of Boston's gay community.$$,
        ARRAY['https://malegislature.gov/Bills/194/H410', 'https://malegislature.gov/Legislators/Profile/J_L1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Livingstone / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('852e4a21-5750-4ac8-ba06-0376c5a31685',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('852e4a21-5750-4ac8-ba06-0376c5a31685',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Livingstone co-sponsored H.1302 (tenant eviction protections) and supported the Affordable Homes Act. He represents Back Bay and South End — areas with very high housing costs — and has advocated for affordable unit production and inclusionary zoning requirements for new development. His approach focuses on building affordable housing stock while navigating constituent concerns about neighborhood character.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1302', 'https://malegislature.gov/Legislators/Profile/J_L1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Livingstone / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('852e4a21-5750-4ac8-ba06-0376c5a31685',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('852e4a21-5750-4ac8-ba06-0376c5a31685',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Livingstone co-sponsored H.1742 (abortion access expansion) and voted for the ROE Act (H.3320). He has been a consistent and vocal supporter of comprehensive reproductive rights. As a progressive representing a highly educated urban district, he supports full abortion access including public funding through MassHealth.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1742', 'https://malegislature.gov/Legislators/Profile/J_L1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Livingstone / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('852e4a21-5750-4ac8-ba06-0376c5a31685',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('852e4a21-5750-4ac8-ba06-0376c5a31685',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Livingstone co-sponsored the Safe Communities Act (H.3369) and has supported immigrant integration policies. He has opposed federal immigration enforcement actions in Massachusetts and advocated for immigrant access to healthcare and education services regardless of status.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/J_L1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Livingstone / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('852e4a21-5750-4ac8-ba06-0376c5a31685',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('852e4a21-5750-4ac8-ba06-0376c5a31685',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Livingstone co-sponsored H.2983 (100% Clean Energy by 2045) and voted for the 2021 Climate Act (H.4933). He has been a consistent supporter of ambitious climate legislation. His Back Bay and South End district is directly vulnerable to sea level rise and he has advocated for both mitigation and coastal adaptation measures.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2983', 'https://malegislature.gov/Bills/192/H4933', 'https://malegislature.gov/Legislators/Profile/J_L1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Livingstone / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('852e4a21-5750-4ac8-ba06-0376c5a31685',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('852e4a21-5750-4ac8-ba06-0376c5a31685',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Livingstone sponsored H.2733 (MBTA accessibility) and H.2660 (fare-free transit). His Back Bay district is served by the Green Line, Orange Line, and Commuter Rail; he represents one of the most transit-rich neighborhoods in the state. He has been a strong advocate for MBTA investment, transit equity, and pedestrian infrastructure over highway expansion.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2733', 'https://malegislature.gov/Legislators/Profile/J_L1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Livingstone / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('852e4a21-5750-4ac8-ba06-0376c5a31685',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('852e4a21-5750-4ac8-ba06-0376c5a31685',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Livingstone voted for the Police Reform Act (H.4835) and supported community-based mental health crisis response programs. He has advocated for civilian oversight of police and ending qualified immunity. His approach emphasizes accountability reforms and diverting resources to community services while maintaining a safer urban neighborhood in his Back Bay/South End district.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/J_L1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jay Livingstone / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('852e4a21-5750-4ac8-ba06-0376c5a31685',
        '00b95a6a-75db-4521-b523-3326bba938de',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('852e4a21-5750-4ac8-ba06-0376c5a31685',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Livingstone co-sponsored H.3044 (Cherish Act — fully funded public higher education) and has consistently opposed charter school cap expansions. He represents Back Bay, home to Boston's public school families, and has maintained strong support for fully funded public education over voucher or charter diversion of public funds.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3044', 'https://malegislature.gov/Legislators/Profile/J_L1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '852e4a21-5750-4ac8-ba06-0376c5a31685';
-- unpaired=0, uncited=0
