-- ============================================================================
-- Migration 506: Paul J. Donato Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Paul J. Donato (MA House HD-91,
--   35th Middlesex District, Medford). External ID: -210131.
--   Donato has served since 1985; long-serving moderate Democrat from Medford.
--   His lengthy record provides evidence on major policy issues.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Paul J. Donato (HD-91, external_id=-210131)
-- Politician UUID: a73b7873-74df-484f-bfab-3b0d905972d9

-- ----- Paul J. Donato / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a73b7873-74df-484f-bfab-3b0d905972d9',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a73b7873-74df-484f-bfab-3b0d905972d9',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Donato voted in favor of the ROE Act's final passage, supporting codification of abortion rights in Massachusetts law. As a longtime Catholic-background Democrat, his record is more moderate than progressive colleagues but he has consistently supported legal abortion access. He has not been a lead sponsor of abortion rights legislation but has voted with the Democratic majority on reproductive rights bills.$$,
        ARRAY['https://actonmass.org/legislators/paul-donato/', 'https://malegislature.gov/Bills/191/H3320'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul J. Donato / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a73b7873-74df-484f-bfab-3b0d905972d9',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a73b7873-74df-484f-bfab-3b0d905972d9',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Donato voted for the 2021 MA climate roadmap bill committing to net-zero emissions by 2050. He has supported clean energy investment and offshore wind development. His climate record reflects mainstream Massachusetts Democratic positions on the state's climate goals.$$,
        ARRAY['https://actonmass.org/legislators/paul-donato/', 'https://malegislature.gov/Bills/192/H4264'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul J. Donato / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a73b7873-74df-484f-bfab-3b0d905972d9',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a73b7873-74df-484f-bfab-3b0d905972d9',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Donato as a long-serving member has been involved in economic development legislation in greater Medford and Middlesex County. He has supported minimum wage increases and worker protections. His moderate Democratic economic record reflects the concerns of his working- and middle-class Medford constituency.$$,
        ARRAY['https://actonmass.org/legislators/paul-donato/', 'https://malegislature.gov/Legislators/Profile/PJD1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul J. Donato / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a73b7873-74df-484f-bfab-3b0d905972d9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a73b7873-74df-484f-bfab-3b0d905972d9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Donato supported the MA healthcare system and has voted for MassHealth expansion. He voted for the 2012 payment reform law and other MA healthcare cost-control measures. As a longtime legislator, his healthcare record reflects support for the MA model of near-universal coverage through a combination of public programs and regulated private insurance.$$,
        ARRAY['https://actonmass.org/legislators/paul-donato/', 'https://malegislature.gov/Legislators/Profile/PJD1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul J. Donato / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a73b7873-74df-484f-bfab-3b0d905972d9',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a73b7873-74df-484f-bfab-3b0d905972d9',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Donato voted for the 2022 MBTA Communities zoning act but has a mixed record on broader housing production mandates, reflecting concerns from Medford constituents about neighborhood character. He supported some affordable housing funding programs but was more cautious than progressive colleagues on aggressive upzoning. His housing record is moderate, balancing development with community concerns.$$,
        ARRAY['https://actonmass.org/legislators/paul-donato/', 'https://malegislature.gov/Legislators/Profile/PJD1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul J. Donato / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a73b7873-74df-484f-bfab-3b0d905972d9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a73b7873-74df-484f-bfab-3b0d905972d9',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Donato voted for the 2022 Millionaires Tax (Fair Share Amendment). As a longtime House Ways and Means-aligned member, he has supported moderate tax increases to fund public services. His decades-long record reflects mainstream Democratic tax policy supporting progressive measures while guarding against tax burdens on working-class constituents.$$,
        ARRAY['https://actonmass.org/legislators/paul-donato/', 'https://www.ballotpedia.org/Massachusetts_Question_1,_Income_Tax_Surtax_for_Education_and_Transportation_Amendment_(2022)'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Paul J. Donato / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a73b7873-74df-484f-bfab-3b0d905972d9',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a73b7873-74df-484f-bfab-3b0d905972d9',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Donato voted for the 2022 VOTES Act making early voting and mail voting permanent. He has generally supported expanded ballot access over his long career, including the adoption of early voting in Massachusetts. His record reflects mainstream Democratic support for voting access measures.$$,
        ARRAY['https://actonmass.org/legislators/paul-donato/', 'https://malegislature.gov/Bills/192/S2977'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'a73b7873-74df-484f-bfab-3b0d905972d9';
-- SELECT COUNT(*) AS unpaired FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id=pa.politician_id AND pc.topic_id=pa.topic_id WHERE pa.politician_id='a73b7873-74df-484f-bfab-3b0d905972d9' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) AS uncited FROM inform.politician_context WHERE politician_id='a73b7873-74df-484f-bfab-3b0d905972d9' AND (sources IS NULL OR array_length(sources,1) IS NULL OR array_length(sources,1)=0);
