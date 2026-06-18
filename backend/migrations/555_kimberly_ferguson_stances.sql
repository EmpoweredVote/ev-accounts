-- ============================================================================
-- Migration 555: Kimberly N. Ferguson Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Kimberly N. Ferguson (MA State Rep,
--          1st Worcester District, HD-140, external_id=-210180).
--          Republican representative from Holden/Rutland area.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Kimberly N. Ferguson (HD-140, external_id=-210180, id=62aee074-7ed1-45e8-94fc-3b5b5007f85d) --

-- ----- Kimberly N. Ferguson / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62aee074-7ed1-45e8-94fc-3b5b5007f85d',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62aee074-7ed1-45e8-94fc-3b5b5007f85d',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Ferguson sponsored H.2305 (An Act reforming the MBTA Communities Act), which would scale back or modify the state's mandatory multifamily zoning requirements near transit stations. She has represented rural/suburban Worcester County towns (Holden, Rutland, Princeton) where residents oppose state-mandated zoning overrides. Her housing stance prioritizes local control over state-mandated development requirements.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2305', 'https://malegislature.gov/Legislators/Profile/KNF1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kimberly N. Ferguson / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62aee074-7ed1-45e8-94fc-3b5b5007f85d',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62aee074-7ed1-45e8-94fc-3b5b5007f85d',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Ferguson is a lead sponsor of H.2305 (An Act reforming the MBTA Communities Act) and H.2306 (repealing MBTA Communities mandates for small towns). Her rural/suburban Worcester County towns are classified as MBTA Communities but have minimal actual MBTA service; she has argued that one-size-fits-all state zoning mandates undermine local control and character. This reflects a strong preference for local zoning authority over state-mandated upzoning.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2305', 'https://malegislature.gov/Bills/194/H2306', 'https://malegislature.gov/Legislators/Profile/KNF1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kimberly N. Ferguson / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62aee074-7ed1-45e8-94fc-3b5b5007f85d',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62aee074-7ed1-45e8-94fc-3b5b5007f85d',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Ferguson voted against the ROE Act (H.3320) in 2020 and has voted against abortion access expansion bills. As a Republican from rural Worcester County, she aligns with pro-life positions and has opposed expanding abortion access beyond first-trimester protections. Her voting record demonstrates consistent opposition to the most expansive abortion access legislation.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/KNF1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kimberly N. Ferguson / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62aee074-7ed1-45e8-94fc-3b5b5007f85d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62aee074-7ed1-45e8-94fc-3b5b5007f85d',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Ferguson co-sponsored H.1018 (An Act relative to income tax relief for working families) and H.1094 (reducing the income tax rate). As a Republican, she has consistently opposed tax increases including the 2022 millionaires' surtax ballot initiative (Question 1). Her tax positions favor reducing the state income tax burden and opposing new revenue measures on high earners.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1018', 'https://malegislature.gov/Legislators/Profile/KNF1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kimberly N. Ferguson / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62aee074-7ed1-45e8-94fc-3b5b5007f85d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62aee074-7ed1-45e8-94fc-3b5b5007f85d',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Ferguson voted against the 2021 Climate Act (H.4933) and has opposed state mandates requiring electrification and renewable energy transitions. She has raised concerns about energy cost impacts on rural Worcester County residents and opposed natural gas bans. Her climate stance reflects skepticism about aggressive state climate mandates and their cost impacts on constituents.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/KNF1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kimberly N. Ferguson / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62aee074-7ed1-45e8-94fc-3b5b5007f85d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62aee074-7ed1-45e8-94fc-3b5b5007f85d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Ferguson voted against the 2020 Police Reform Act (H.4835) and has consistently opposed measures she views as undermining law enforcement. She has sponsored H.1200 (An Act to protect police officers) and backed legislation increasing protections for first responders. Her public safety stance strongly favors traditional law enforcement funding and personnel over community-based alternatives.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1200', 'https://malegislature.gov/Legislators/Profile/KNF1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kimberly N. Ferguson / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62aee074-7ed1-45e8-94fc-3b5b5007f85d',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62aee074-7ed1-45e8-94fc-3b5b5007f85d',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Ferguson represents rural/suburban Worcester County towns (Holden, Rutland, Princeton, Paxton) that are entirely car-dependent with no MBTA rail service. She has prioritized road maintenance, bridge infrastructure, and highway investments over transit. Her transportation advocacy focuses on rural road quality and has opposed MBTA funding expansions that would direct resources away from her car-dependent district.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/KNF1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kimberly N. Ferguson / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62aee074-7ed1-45e8-94fc-3b5b5007f85d',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62aee074-7ed1-45e8-94fc-3b5b5007f85d',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Ferguson co-sponsored H.3901 (aquifer protection for rural communities) and has supported local water quality protections relevant to her rural district. Her environmental advocacy focuses on protecting local natural resources (aquifers, rural open space) rather than urban EJ community priorities. She supports conservation measures that align with rural property owner interests.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3901', 'https://malegislature.gov/Legislators/Profile/KNF1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kimberly N. Ferguson / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('62aee074-7ed1-45e8-94fc-3b5b5007f85d',
        '00b95a6a-75db-4521-b523-3326bba938de',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('62aee074-7ed1-45e8-94fc-3b5b5007f85d',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Ferguson voted in favor of charter school cap expansion and has expressed support for school choice mechanisms. As a Republican from Worcester County, she has backed education choice policies including expanding access to charter schools and education savings accounts for homeschooling families. Her position reflects Republican support for school choice over traditional public school funding models.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/KNF1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '62aee074-7ed1-45e8-94fc-3b5b5007f85d';
-- unpaired=0, uncited=0
