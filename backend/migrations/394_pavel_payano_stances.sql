-- ============================================================================
-- Migration 394: Pavel M. Payano Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Pavel M. Payano (MA State Senator, 25D19).
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
-- healthcare                       e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- immigration                      4e2c69ce-591e-4197-9cd5-7aceff79d390
-- public-safety-approach           e9ebefcd-c496-45e8-b816-a79f8442ba85
-- taxes                            f7e5678d-dadd-4556-a2fc-446e24642ceb
-- transportation-priorities        ba59337e-30e2-4aba-a39a-426b3366eb27
-- voting-rights                    d1792200-1d3b-4955-a0b7-0e6980d7a7b2

BEGIN;

-- Pavel M. Payano (25D19, external_id=-210019)
-- Politician UUID: 756f9e6b-5286-4a9e-9d05-f6341830bd12

-- ----- Pavel M. Payano / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('756f9e6b-5286-4a9e-9d05-f6341830bd12',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('756f9e6b-5286-4a9e-9d05-f6341830bd12',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Pavel M. Payano has supported reproductive rights legislation in Massachusetts. He backed the 2022 shield law protecting Massachusetts abortion providers and patients following the Dobbs decision. As a Democrat representing Lawrence and North Andover in Essex County, he has aligned with the majority caucus protecting abortion access as a fundamental healthcare right, particularly important for the diverse Latino community in Lawrence.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PMP0', 'https://ballotpedia.org/Pavel_Payano']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pavel M. Payano / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('756f9e6b-5286-4a9e-9d05-f6341830bd12',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('756f9e6b-5286-4a9e-9d05-f6341830bd12',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Pavel M. Payano has been an advocate for civil rights and equity in his community. As a Dominican-American senator representing Lawrence, one of the most diverse cities in Massachusetts, he has championed racial justice, immigrant rights, and anti-discrimination protections. He has backed LGBTQ+ protections and police accountability legislation and has been a voice for communities of color in the Senate.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PMP0', 'https://ballotpedia.org/Pavel_Payano']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pavel M. Payano / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('756f9e6b-5286-4a9e-9d05-f6341830bd12',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('756f9e6b-5286-4a9e-9d05-f6341830bd12',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Pavel M. Payano backed the 2021 Massachusetts Climate Act and has supported clean energy investments. He has framed climate action as an environmental justice issue, noting that Lawrence and similar communities bear disproportionate pollution burdens. He has backed clean energy jobs and investments that benefit working-class communities in Essex County.$$,
        ARRAY['https://malegislature.gov/Bills/192/S9', 'https://malegislature.gov/Legislators/Profile/PMP0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pavel M. Payano / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('756f9e6b-5286-4a9e-9d05-f6341830bd12',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('756f9e6b-5286-4a9e-9d05-f6341830bd12',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Pavel M. Payano has focused on economic development that creates opportunity for working families in his district. Lawrence is one of Massachusetts' most economically challenged cities with high poverty rates and a large immigrant workforce. He has backed workforce development, small business support, and community investment. He has advocated for state investment in the Mill Cities region of Essex County.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PMP0', 'https://ballotpedia.org/Pavel_Payano']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pavel M. Payano / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('756f9e6b-5286-4a9e-9d05-f6341830bd12',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('756f9e6b-5286-4a9e-9d05-f6341830bd12',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Pavel M. Payano has championed healthcare access for underserved communities in Lawrence, which has significant health disparities. He has backed expanded MassHealth, community health center funding, mental health services, and language-accessible healthcare. He has advocated addressing social determinants of health in low-income communities and has supported maternal health equity legislation.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PMP0', 'https://ballotpedia.org/Pavel_Payano']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pavel M. Payano / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('756f9e6b-5286-4a9e-9d05-f6341830bd12',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('756f9e6b-5286-4a9e-9d05-f6341830bd12',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Pavel M. Payano backed the Affordable Homes Act and has advocated strongly for affordable housing in Lawrence and the surrounding Essex County communities. He has supported tenant protections, emergency rental assistance, and deeply affordable housing production. Lawrence faces extreme housing cost burden, and he has been a leading voice for housing investments that keep working families housed.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PMP0', 'https://malegislature.gov/Bills/193/SD3030']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pavel M. Payano / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('756f9e6b-5286-4a9e-9d05-f6341830bd12',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('756f9e6b-5286-4a9e-9d05-f6341830bd12',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Pavel M. Payano, as a Dominican-American senator representing Lawrence where over 75% of residents are Latino and many are immigrants, has been a fierce advocate for immigrant rights. He backed the Work and Family Mobility Act and has supported the TRUST Act limiting ICE cooperation. He has advocated for language access, expanded services for undocumented residents, and protections from federal immigration enforcement raids in his community.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2684', 'https://malegislature.gov/Legislators/Profile/PMP0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pavel M. Payano / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('756f9e6b-5286-4a9e-9d05-f6341830bd12',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('756f9e6b-5286-4a9e-9d05-f6341830bd12',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Pavel M. Payano backed the 2020 Police Reform Act and has supported criminal justice reform and community-based approaches to public safety in Lawrence. He has advocated for violence prevention programs, mental health intervention, and addressing root causes of crime in his district. He has also supported addressing racial disparities in policing and the criminal justice system.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PMP0', 'https://malegislature.gov/Bills/191/H4886']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pavel M. Payano / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('756f9e6b-5286-4a9e-9d05-f6341830bd12',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('756f9e6b-5286-4a9e-9d05-f6341830bd12',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Pavel M. Payano supported the Fair Share Amendment and has backed progressive taxation to fund public services for low-income communities. He represents one of the state's most economically challenged communities, and he has championed tax policies that invest in education, healthcare, and housing for working families in Lawrence and surrounding Essex County.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PMP0', 'https://ballotpedia.org/Massachusetts_Question_1,_Income_Tax_for_Education_and_Transportation_Amendment_(2022)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pavel M. Payano / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('756f9e6b-5286-4a9e-9d05-f6341830bd12',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('756f9e6b-5286-4a9e-9d05-f6341830bd12',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Pavel M. Payano has advocated for transportation improvements in Lawrence, including bus rapid transit and commuter rail access. Lawrence is transit-dependent, with many residents relying on public transportation, and he has supported MBTA bus improvements, Haverhill Line commuter rail enhancements, and regional transit funding. He has backed transportation as a social equity issue.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/PMP0', 'https://ballotpedia.org/Pavel_Payano']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Pavel M. Payano / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('756f9e6b-5286-4a9e-9d05-f6341830bd12',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('756f9e6b-5286-4a9e-9d05-f6341830bd12',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Pavel M. Payano backed the VOTES Act and has supported voting rights expansion, particularly for his Latino and immigrant constituency. He has supported automatic voter registration, language access in voting, and measures to increase participation in communities that face systemic barriers to voting. He has advocated for non-citizen resident voting in local elections to give immigrants a voice in their communities.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2545', 'https://malegislature.gov/Legislators/Profile/PMP0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 11 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '756f9e6b-5286-4a9e-9d05-f6341830bd12';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '756f9e6b-5286-4a9e-9d05-f6341830bd12'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '756f9e6b-5286-4a9e-9d05-f6341830bd12'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
