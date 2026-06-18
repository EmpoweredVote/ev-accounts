-- ============================================================================
-- Migration 389: Rebecca L. Rausch Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Rebecca L. Rausch (MA State Senator, 25D14).
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
-- data-centers                     4559b513-0fd8-4ed1-babd-f3b554162f40
-- economic-development             eb3d1247-0de1-4b7f-baec-7259861efd53
-- fossil-fuels                     a22215c3-6693-4bc2-b248-01aebba14570
-- healthcare                       e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- immigration                      4e2c69ce-591e-4197-9cd5-7aceff79d390
-- public-safety-approach           e9ebefcd-c496-45e8-b816-a79f8442ba85
-- redistricting                    48cc9585-ec22-4f53-8d42-6839828dd36f
-- taxes                            f7e5678d-dadd-4556-a2fc-446e24642ceb
-- voting-rights                    d1792200-1d3b-4955-a0b7-0e6980d7a7b2

BEGIN;

-- Rebecca L. Rausch (25D14, external_id=-210014)
-- Politician UUID: b7369e32-1916-413e-b0eb-2871a5348470

-- ----- Rebecca L. Rausch / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7369e32-1916-413e-b0eb-2871a5348470',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7369e32-1916-413e-b0eb-2871a5348470',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Rebecca L. Rausch has been an outspoken advocate for reproductive rights in the Massachusetts legislature. She voted for the ROE Act in 2020, backed the 2022 shield law protecting abortion providers after Dobbs, and has consistently championed abortion access as a fundamental healthcare right. She has called for even stronger protections for reproductive healthcare and has been a vocal critic of any restrictions on abortion access.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/RLR0', 'https://ballotpedia.org/Rebecca_Rausch']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rebecca L. Rausch / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7369e32-1916-413e-b0eb-2871a5348470',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7369e32-1916-413e-b0eb-2871a5348470',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Rebecca L. Rausch has advocated for campaign finance reform, including public financing of elections and limits on large donations. She has backed small-dollar democracy programs and transparency requirements. She has expressed concern about the influence of corporate and dark money in elections and has championed systemic reforms to reduce the role of money in politics.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/RLR0', 'https://ballotpedia.org/Rebecca_Rausch']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rebecca L. Rausch / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7369e32-1916-413e-b0eb-2871a5348470',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7369e32-1916-413e-b0eb-2871a5348470',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Rebecca L. Rausch, a former public defender, has been one of the most vocal civil rights advocates in the Massachusetts Senate. She has championed racial justice, LGBTQ+ rights, criminal justice reform, and immigrant rights. She was a key sponsor of the Fair and Impartial Policing Act (TRUST Act) and has backed comprehensive anti-discrimination legislation. She has spoken extensively about systemic racism in the criminal justice system.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/RLR0', 'https://ballotpedia.org/Rebecca_Rausch']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rebecca L. Rausch / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7369e32-1916-413e-b0eb-2871a5348470',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7369e32-1916-413e-b0eb-2871a5348470',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Rebecca L. Rausch has been a strong supporter of climate action and environmental justice. She backed the 2021 Massachusetts Climate Act and has pushed for even more aggressive policies. She has linked climate action with environmental justice, noting that low-income communities and communities of color face disproportionate impacts from climate change and pollution. She has supported clean energy expansion and fossil fuel restrictions.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/RLR0', 'https://malegislature.gov/Bills/192/S9']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rebecca L. Rausch / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7369e32-1916-413e-b0eb-2871a5348470',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7369e32-1916-413e-b0eb-2871a5348470',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Rebecca L. Rausch has strongly opposed fossil fuel expansion and backed restrictions on new natural gas infrastructure. She has supported building electrification mandates and clean energy transition. She has backed fossil fuel divestment for public pension funds and has been a consistent critic of continued dependence on natural gas and oil.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/RLR0', 'https://ballotpedia.org/Rebecca_Rausch']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rebecca L. Rausch / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7369e32-1916-413e-b0eb-2871a5348470',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7369e32-1916-413e-b0eb-2871a5348470',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Rebecca L. Rausch has championed universal healthcare and expanded Medicaid. She has backed mental health parity, behavioral health reform, and addressing healthcare disparities for communities of color. She supports universal coverage as a right and has backed single-payer healthcare studies. She has emphasized that healthcare access is a racial justice issue.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/RLR0', 'https://ballotpedia.org/Rebecca_Rausch']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rebecca L. Rausch / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7369e32-1916-413e-b0eb-2871a5348470',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7369e32-1916-413e-b0eb-2871a5348470',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Rebecca L. Rausch has advocated strongly for affordable housing, tenant protections, and anti-displacement policies. She backed the Affordable Homes Act and has supported rent stabilization legislation. She has emphasized housing as a racial justice issue, noting that Black and Latino residents in her district are disproportionately affected by housing insecurity and displacement.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/RLR0', 'https://malegislature.gov/Bills/193/SD3030']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rebecca L. Rausch / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7369e32-1916-413e-b0eb-2871a5348470',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7369e32-1916-413e-b0eb-2871a5348470',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Rebecca L. Rausch has been one of the strongest advocates for immigrant rights in the Massachusetts legislature. She helped pass the Work and Family Mobility Act and the TRUST Act, and has backed expanded rights and protections for undocumented residents. As a former public defender, she has seen firsthand the impact of immigration enforcement on communities and has been a vocal critic of ICE detainer policies.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2684', 'https://malegislature.gov/Legislators/Profile/RLR0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rebecca L. Rausch / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7369e32-1916-413e-b0eb-2871a5348470',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7369e32-1916-413e-b0eb-2871a5348470',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Rebecca L. Rausch, as a former public defender, has been one of the leading voices for criminal justice reform in Massachusetts. She backed the 2020 Police Reform Act and has pushed for even more comprehensive reforms including ending mandatory minimums, reforming the parole system, and addressing racial disparities. She has championed decarceration, bail reform, and community-based alternatives to incarceration as cornerstones of her legislative work.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/RLR0', 'https://malegislature.gov/Bills/191/H4886']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rebecca L. Rausch / redistricting -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7369e32-1916-413e-b0eb-2871a5348470',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7369e32-1916-413e-b0eb-2871a5348470',
        '48cc9585-ec22-4f53-8d42-6839828dd36f',
        $$Rebecca L. Rausch has been a champion for independent redistricting reform in Massachusetts, backing the establishment of an independent commission to draw legislative district lines instead of the legislature. She has argued this reform is essential for fair representation and has noted that communities of color in Massachusetts have been underrepresented due to politically motivated gerrymandering.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/RLR0', 'https://ballotpedia.org/Rebecca_Rausch']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rebecca L. Rausch / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7369e32-1916-413e-b0eb-2871a5348470',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7369e32-1916-413e-b0eb-2871a5348470',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Rebecca L. Rausch was a vocal supporter of the Fair Share Amendment and has consistently backed progressive taxation. She has supported increased corporate taxes, closing tax loopholes, and ensuring wealthy individuals pay their fair share. She has been among the most progressive voices in the Senate on fiscal policy, advocating for significant state investment funded by progressive taxation.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/RLR0', 'https://ballotpedia.org/Massachusetts_Question_1,_Income_Tax_for_Education_and_Transportation_Amendment_(2022)']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rebecca L. Rausch / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7369e32-1916-413e-b0eb-2871a5348470',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7369e32-1916-413e-b0eb-2871a5348470',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Rebecca L. Rausch has been a champion for voting rights expansion, backing the VOTES Act, automatic voter registration, same-day registration, and legislation to allow municipalities to permit non-citizen voting in local elections. She has framed voting rights as a racial justice issue and has been a vocal critic of voter suppression efforts nationwide. She has pushed Massachusetts to be a model for democratic participation.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2545', 'https://malegislature.gov/Legislators/Profile/RLR0']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (must be >= 12 topics):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'b7369e32-1916-413e-b0eb-2871a5348470';
--
-- Context pairing (must return 0 — every answer must have a context row):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'b7369e32-1916-413e-b0eb-2871a5348470'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0 — every context row must have sources):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'b7369e32-1916-413e-b0eb-2871a5348470'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
