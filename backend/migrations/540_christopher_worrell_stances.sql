-- ============================================================================
-- Migration 540: Christopher J. Worrell Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Christopher J. Worrell (MA State Rep,
--          5th Suffolk District, HD-125, external_id=-210165).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Christopher J. Worrell (HD-125, external_id=-210165, id=bca54df2-f059-44ce-81c3-f208f1e20752) --

-- ----- Christopher J. Worrell / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bca54df2-f059-44ce-81c3-f208f1e20752',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bca54df2-f059-44ce-81c3-f208f1e20752',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Worrell sponsored H.1619 (behavioral health access expansion) and H.1750 (substance use disorder treatment). Representing a district in the Dorchester/South Boston area, he has focused on community health center funding and behavioral health services. His healthcare priorities center on expanding access for working-class communities rather than structural reform to the insurance system.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1619', 'https://malegislature.gov/Legislators/Profile/CJW1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher J. Worrell / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bca54df2-f059-44ce-81c3-f208f1e20752',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bca54df2-f059-44ce-81c3-f208f1e20752',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Worrell co-sponsored H.1302 (tenant protection from unjust eviction) and H.1380 (affordable housing preservation). He represents parts of Dorchester that have experienced rapid gentrification, displacing long-term Black and working-class residents. He has been an advocate for affordable housing production and anti-displacement policies in communities of color in South Suffolk.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1302', 'https://malegislature.gov/Legislators/Profile/CJW1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher J. Worrell / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bca54df2-f059-44ce-81c3-f208f1e20752',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bca54df2-f059-44ce-81c3-f208f1e20752',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Worrell co-sponsored H.1742 (abortion access expansion) and voted for the ROE Act (H.3320). He has maintained a consistent pro-choice voting record and supported comprehensive abortion access including removal of waiting periods and expansion of coverage for low-income patients through MassHealth.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1742', 'https://malegislature.gov/Bills/192/H3320', 'https://malegislature.gov/Legislators/Profile/CJW1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher J. Worrell / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bca54df2-f059-44ce-81c3-f208f1e20752',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bca54df2-f059-44ce-81c3-f208f1e20752',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Worrell co-sponsored H.2093 (juvenile justice reform) and the Safe Communities Act (H.3369). As a Black legislator from Dorchester, he has been a consistent advocate for racial equity, ending systemic discrimination, and reforming the criminal justice system. He supported the 2020 Police Reform Act (H.4835) and has championed anti-racism initiatives in state programs.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/CJW1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher J. Worrell / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bca54df2-f059-44ce-81c3-f208f1e20752',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bca54df2-f059-44ce-81c3-f208f1e20752',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Worrell voted for the Police Reform Act (H.4835) establishing civilian oversight and restricting no-knock warrants. As a representative of communities of color in Dorchester that have experienced police violence, he has strongly advocated for community-based violence prevention and mental health crisis response alternatives. His stance combines accountability reform with investment in community-based public safety alternatives.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4835', 'https://malegislature.gov/Legislators/Profile/CJW1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher J. Worrell / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bca54df2-f059-44ce-81c3-f208f1e20752',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bca54df2-f059-44ce-81c3-f208f1e20752',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Worrell co-sponsored the Safe Communities Act (H.3369) and has advocated for immigrant rights. His district includes immigrant communities in the Dorchester area and he has supported sanctuary policies and access to state services regardless of immigration status.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3369', 'https://malegislature.gov/Legislators/Profile/CJW1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher J. Worrell / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bca54df2-f059-44ce-81c3-f208f1e20752',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bca54df2-f059-44ce-81c3-f208f1e20752',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Worrell voted for the 2021 Climate Act (H.4933) and has supported environmental justice provisions connecting climate action to racial equity in his Dorchester district. He backed clean energy investments and coastal resilience funding for communities facing disproportionate climate impacts.$$,
        ARRAY['https://malegislature.gov/Bills/192/H4933', 'https://malegislature.gov/Legislators/Profile/CJW1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher J. Worrell / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bca54df2-f059-44ce-81c3-f208f1e20752',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bca54df2-f059-44ce-81c3-f208f1e20752',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Worrell sponsored H.1877 (workforce development for communities of color) and has advocated for targeted economic development investment in Dorchester. He has championed minority-owned business support programs and job training for residents of Environmental Justice communities. His economic development approach prioritizes equity-centered investment over general business incentives.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1877', 'https://malegislature.gov/Legislators/Profile/CJW1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher J. Worrell / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bca54df2-f059-44ce-81c3-f208f1e20752',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bca54df2-f059-44ce-81c3-f208f1e20752',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Worrell has supported MBTA service improvements and bus rapid transit expansion in Dorchester. His district relies heavily on MBTA bus routes and the Red Line; he has advocated for fare affordability and service reliability improvements for transit-dependent working-class communities. He supported the MBTA Communities Act as a tool for equitable transit-oriented development.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/CJW1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Christopher J. Worrell / jail-capacity -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bca54df2-f059-44ce-81c3-f208f1e20752',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bca54df2-f059-44ce-81c3-f208f1e20752',
        'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
        $$Worrell co-sponsored H.1795 (prison moratorium) opposing new jail and prison construction. As a representative from Dorchester — a community heavily impacted by mass incarceration — he has consistently argued for redirecting incarceration funding toward community health, housing, and youth development programs rather than expanding carceral capacity.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1795', 'https://malegislature.gov/Legislators/Profile/CJW1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'bca54df2-f059-44ce-81c3-f208f1e20752';
-- unpaired=0, uncited=0
