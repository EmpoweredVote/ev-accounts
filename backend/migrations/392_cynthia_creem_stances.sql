-- ============================================================================
-- Migration 392: Cynthia S. Creem Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Cynthia S. Creem (MA State Senator, 25D17).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference (inform.compass_topics):
-- abortion                         af2fdfd6-02c4-49df-b09c-cf8536f4773f
-- campaign-finance                 92730f69-ae57-401c-8ad1-2d07834a895d
-- civil-rights                     0bc588c6-39e1-4084-b5de-cac909b8b762
-- climate-change                   f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
-- economic-development             eb3d1247-0de1-4b7f-baec-7259861efd53
-- fossil-fuels                     a22215c3-6693-4bc2-b248-01aebba14570
-- healthcare                       e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- immigration                      4e2c69ce-591e-4197-9cd5-7aceff79d390
-- public-safety-approach           e9ebefcd-c496-45e8-b816-a79f8442ba85
-- redistricting                    48cc9585-ec22-4f53-8d42-6839828dd36f
-- same-sex-marriage                c5ab4eab-702f-49b8-9277-8ea53f3835c6
-- taxes                            f7e5678d-dadd-4556-a2fc-446e24642ceb
-- voting-rights                    d1792200-1d3b-4955-a0b7-0e6980d7a7b2

BEGIN;

-- Cynthia S. Creem (25D17, external_id=-210017)
-- Politician UUID: b46a6774-2d85-4750-813a-6d4ef2eefb5b

-- ----- Cynthia S. Creem / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b46a6774-2d85-4750-813a-6d4ef2eefb5b',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b46a6774-2d85-4750-813a-6d4ef2eefb5b',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Cynthia S. Creem has been a champion for reproductive rights throughout her long career in the Massachusetts legislature. She supported the ROE Act, the 2022 shield law, and has been among the most consistent voices protecting abortion access. As a longtime member of the Norfolk and Middlesex district including Newton, she has represented a community that strongly supports reproductive rights and has never wavered in her defense of abortion access.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/CSC0', 'https://ballotpedia.org/Cynthia_Creem']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cynthia S. Creem / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b46a6774-2d85-4750-813a-6d4ef2eefb5b',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b46a6774-2d85-4750-813a-6d4ef2eefb5b',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Cynthia S. Creem has supported campaign finance reform measures throughout her legislative career, including disclosure requirements and contribution limits. She has backed systemic reforms to reduce the influence of large donors. As a veteran legislator, she has participated in multiple campaign finance reform efforts in Massachusetts.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/CSC0', 'https://ballotpedia.org/Cynthia_Creem']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cynthia S. Creem / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b46a6774-2d85-4750-813a-6d4ef2eefb5b',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b46a6774-2d85-4750-813a-6d4ef2eefb5b',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Cynthia S. Creem has been a consistent champion for civil rights over her more than two decades in the Massachusetts legislature. She championed same-sex marriage rights, LGBTQ+ anti-discrimination protections, disability rights, and racial justice legislation. She chaired the Senate Judiciary Committee and used that position to advance civil rights legislation. She has been recognized by civil rights organizations for her long record of advocacy.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/CSC0', 'https://ballotpedia.org/Cynthia_Creem']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cynthia S. Creem / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b46a6774-2d85-4750-813a-6d4ef2eefb5b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b46a6774-2d85-4750-813a-6d4ef2eefb5b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Cynthia S. Creem has supported climate action legislation throughout her career, including the 2021 Climate Act. She represents Newton, which is a leader in clean energy and has ambitious local climate goals, and she has championed state policy that supports these efforts. She has backed clean energy expansion, building electrification, and fossil fuel transition.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/CSC0', 'https://malegislature.gov/Bills/192/S9']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cynthia S. Creem / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b46a6774-2d85-4750-813a-6d4ef2eefb5b',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b46a6774-2d85-4750-813a-6d4ef2eefb5b',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Cynthia S. Creem has backed restrictions on fossil fuels and supported the transition to clean energy. She has voted against bills that would expand fossil fuel infrastructure and has supported measures to accelerate building electrification and reduce dependence on natural gas. Newton, which she represents, has been a leader in local clean energy ordinances.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/CSC0', 'https://ballotpedia.org/Cynthia_Creem']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cynthia S. Creem / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b46a6774-2d85-4750-813a-6d4ef2eefb5b',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b46a6774-2d85-4750-813a-6d4ef2eefb5b',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Cynthia S. Creem has been a longtime champion for healthcare access and mental health in Massachusetts. She has backed MassHealth expansions, mental health parity legislation, and behavioral health reform. As a former chair of the Senate Judiciary Committee, she participated in criminal justice reforms with behavioral health implications. She has consistently supported universal healthcare access.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/CSC0', 'https://ballotpedia.org/Cynthia_Creem']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cynthia S. Creem / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b46a6774-2d85-4750-813a-6d4ef2eefb5b',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b46a6774-2d85-4750-813a-6d4ef2eefb5b',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Cynthia S. Creem supported the Affordable Homes Act and has backed housing production in her district, including compliance with MBTA Communities zoning requirements. She has supported affordable housing investment and transit-oriented development. Her district includes Newton, an affluent suburb facing intense housing cost pressure, and she has balanced state housing mandates with local concerns.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/CSC0', 'https://malegislature.gov/Bills/193/SD3030']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cynthia S. Creem / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b46a6774-2d85-4750-813a-6d4ef2eefb5b',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b46a6774-2d85-4750-813a-6d4ef2eefb5b',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Cynthia S. Creem has been a consistent supporter of immigrant rights. She backed the Work and Family Mobility Act and TRUST Act limiting ICE cooperation. She has supported expanded rights and protections for undocumented residents. Newton, which she represents, has declared itself a welcoming city for immigrants, and she has championed state policies consistent with those values.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2684', 'https://malegislature.gov/Legislators/Profile/CSC0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cynthia S. Creem / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b46a6774-2d85-4750-813a-6d4ef2eefb5b',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b46a6774-2d85-4750-813a-6d4ef2eefb5b',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Cynthia S. Creem has supported criminal justice reform, including backing the 2020 Police Reform Act. As longtime chair of the Senate Judiciary Committee, she was a key author of multiple criminal justice reform bills including the 2018 Criminal Justice Reform Act, which addressed mandatory minimums and expanded diversion programs. She has taken a progressive but measured approach to criminal justice reform.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/CSC0', 'https://malegislature.gov/Bills/190/S2371']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cynthia S. Creem / same-sex-marriage -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b46a6774-2d85-4750-813a-6d4ef2eefb5b',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b46a6774-2d85-4750-813a-6d4ef2eefb5b',
        'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
        $$Cynthia S. Creem was one of the most important legislative architects of marriage equality in Massachusetts. As chair of the Senate Judiciary Committee, she was central to the legislative response to the Goodridge v. Department of Public Health ruling in 2003-2004, which made Massachusetts the first state to legalize same-sex marriage. She has been recognized repeatedly by LGBTQ+ advocacy organizations for her decades of work advancing equality.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/CSC0', 'https://ballotpedia.org/Cynthia_Creem']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cynthia S. Creem / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b46a6774-2d85-4750-813a-6d4ef2eefb5b',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b46a6774-2d85-4750-813a-6d4ef2eefb5b',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Cynthia S. Creem supported the Fair Share Amendment and has backed progressive taxation throughout her career. She has voted for tax increases on high earners and corporations to fund public services and has opposed tax cuts that would primarily benefit the wealthy. As a longtime senator from an affluent district, she has been a consistent voice for fair taxation.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/CSC0', 'https://ballotpedia.org/Massachusetts_Question_1,_Income_Tax_for_Education_and_Transportation_Amendment_(2022)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Cynthia S. Creem / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b46a6774-2d85-4750-813a-6d4ef2eefb5b',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b46a6774-2d85-4750-813a-6d4ef2eefb5b',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Cynthia S. Creem backed the VOTES Act and has been a consistent supporter of voting rights throughout her legislative career. She has championed automatic voter registration, easy access to the ballot, and election security measures. As a senior senator, she has been a reliable vote for voting rights expansion and has opposed any measures that would restrict ballot access.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2545', 'https://malegislature.gov/Legislators/Profile/CSC0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 13 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'b46a6774-2d85-4750-813a-6d4ef2eefb5b';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'b46a6774-2d85-4750-813a-6d4ef2eefb5b'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'b46a6774-2d85-4750-813a-6d4ef2eefb5b'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
