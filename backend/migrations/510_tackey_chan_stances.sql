-- ============================================================================
-- Migration 510: Tackey Chan Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Tackey Chan (MA House HD-95,
--   2nd Norfolk District, Quincy). External ID: -210135.
--   Chan has served since 2015; Democrat known for environmental justice,
--   transportation, and Asian-American community advocacy.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Tackey Chan (HD-95, external_id=-210135)
-- Politician UUID: 90602902-b178-4709-a74b-68b30fe45394

-- ----- Tackey Chan / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('90602902-b178-4709-a74b-68b30fe45394',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('90602902-b178-4709-a74b-68b30fe45394',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Chan co-sponsored the ROE Act (H.3320) and has voted consistently for reproductive rights legislation. His ActOnMass profile confirms strong support for abortion access throughout his tenure. He received NARAL Pro-Choice Massachusetts endorsement.$$,
        ARRAY['https://actonmass.org/legislators/tackey-chan/', 'https://malegislature.gov/Bills/191/H3320'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tackey Chan / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('90602902-b178-4709-a74b-68b30fe45394',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('90602902-b178-4709-a74b-68b30fe45394',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Chan has co-sponsored civil rights legislation including anti-hate crime bills and anti-discrimination protections. As the first Chinese American elected to the MA General Court, he has been a vocal advocate for Asian American civil rights, particularly in the context of COVID-era anti-Asian hate crimes and systemic discrimination. He filed bills to strengthen protections against bias-motivated violence.$$,
        ARRAY['https://actonmass.org/legislators/tackey-chan/', 'https://malegislature.gov/Legislators/Profile/T_C1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tackey Chan / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('90602902-b178-4709-a74b-68b30fe45394',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('90602902-b178-4709-a74b-68b30fe45394',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Chan voted for the 2021 MA climate roadmap committing to net-zero emissions by 2050. He has supported clean energy investment and offshore wind. His coastal Quincy district has climate vulnerability and he has advocated for environmental justice in communities of color. His record reflects mainstream Democratic support for state climate goals.$$,
        ARRAY['https://actonmass.org/legislators/tackey-chan/', 'https://malegislature.gov/Bills/192/H4264'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tackey Chan / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('90602902-b178-4709-a74b-68b30fe45394',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('90602902-b178-4709-a74b-68b30fe45394',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Chan has voted to protect MassHealth and support expanded healthcare access, particularly for underserved communities. He supported mental health parity legislation and community health center funding. His record reflects moderate-Democratic support for expanded healthcare access with attention to language access and cultural competency for Asian American communities.$$,
        ARRAY['https://actonmass.org/legislators/tackey-chan/', 'https://malegislature.gov/Legislators/Profile/T_C1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tackey Chan / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('90602902-b178-4709-a74b-68b30fe45394',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('90602902-b178-4709-a74b-68b30fe45394',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Chan voted for affordable housing funding and MBTA Communities zoning reform. Quincy has seen housing cost increases and he has backed policies to increase housing supply with affordability components. He has focused on housing access for working-class immigrant families in his district.$$,
        ARRAY['https://actonmass.org/legislators/tackey-chan/', 'https://malegislature.gov/Legislators/Profile/T_C1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tackey Chan / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('90602902-b178-4709-a74b-68b30fe45394',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('90602902-b178-4709-a74b-68b30fe45394',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Chan co-sponsored the Safe Communities Act and has been a strong advocate for immigrant rights throughout his tenure. As a Chinese American legislator representing Quincy — a city with large Chinese and Vietnamese immigrant communities — he has championed the DREAM Act, drivers' licenses for all residents, and programs supporting immigrant integration.$$,
        ARRAY['https://actonmass.org/legislators/tackey-chan/', 'https://actonmass.org/bills/safe-communities-act/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tackey Chan / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('90602902-b178-4709-a74b-68b30fe45394',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('90602902-b178-4709-a74b-68b30fe45394',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Chan voted for the 2022 Millionaires Tax (Fair Share Amendment). His tax record reflects standard Democratic positions supporting progressive taxation to fund education and transportation, with particular attention to how tax policy affects working-class immigrant communities in his district.$$,
        ARRAY['https://actonmass.org/legislators/tackey-chan/', 'https://www.ballotpedia.org/Massachusetts_Question_1,_Income_Tax_Surtax_for_Education_and_Transportation_Amendment_(2022)'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tackey Chan / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('90602902-b178-4709-a74b-68b30fe45394',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('90602902-b178-4709-a74b-68b30fe45394',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Chan has been a strong advocate for MBTA improvements serving the Red Line through Quincy and has pushed for expanded transit access for his constituents. He has supported public transit investment, bike infrastructure, and the MBTA Commuter Rail as transportation priorities. His Quincy district depends heavily on the T and he has vocally championed transit funding.$$,
        ARRAY['https://actonmass.org/legislators/tackey-chan/', 'https://malegislature.gov/Legislators/Profile/T_C1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Tackey Chan / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('90602902-b178-4709-a74b-68b30fe45394',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('90602902-b178-4709-a74b-68b30fe45394',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Chan voted for the 2022 VOTES Act making early voting and mail voting permanent. He has supported voter outreach in multiple languages to increase participation from immigrant communities. As a representative of communities with significant non-citizen populations, he has been active on language access and civic participation issues.$$,
        ARRAY['https://actonmass.org/legislators/tackey-chan/', 'https://malegislature.gov/Bills/192/S2977'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '90602902-b178-4709-a74b-68b30fe45394';
-- SELECT COUNT(*) AS unpaired FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id=pa.politician_id AND pc.topic_id=pa.topic_id WHERE pa.politician_id='90602902-b178-4709-a74b-68b30fe45394' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) AS uncited FROM inform.politician_context WHERE politician_id='90602902-b178-4709-a74b-68b30fe45394' AND (sources IS NULL OR array_length(sources,1) IS NULL OR array_length(sources,1)=0);
