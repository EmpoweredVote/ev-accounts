-- ============================================================================
-- Migration 470: Lindsay Sabadosa Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Lindsay Sabadosa (MA State Rep, 1st Hampshire District, HD-55).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Topic UUID reference (inform.compass_topics): See migration 456 for full reference block.

BEGIN;

-- ============================================================================
-- Lindsay Sabadosa (HD-55, external_id=-210095)
-- UUID: 853f0b26-a2b5-48b6-8dd6-f40ca48c87fd
-- District: 1st Hampshire (Northampton area)
-- Democrat; committees: Health Care Financing, Transportation, Ways and Means.
-- Progressive legislator with comprehensive record on reproductive rights, healthcare, climate.
-- ============================================================================

-- ----- Lindsay Sabadosa / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('853f0b26-a2b5-48b6-8dd6-f40ca48c87fd',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('853f0b26-a2b5-48b6-8dd6-f40ca48c87fd',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Sabadosa sponsored H.1308, "An Act relative to protecting reproductive destiny," and H.1311, "An Act ensuring access to full spectrum pregnancy care," both of which expand abortion access and reproductive healthcare rights. She also sponsored H.1117, "An Act promoting and enhancing the sustainability of birth centers and the midwifery workforce," and H.1315, "An Act relative to IUD pain management coverage." Her committee role on Health Care Financing further enables her to shape reproductive healthcare policy.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1308', 'https://malegislature.gov/Bills/194/H1311', 'https://malegislature.gov/Bills/194/H1117']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lindsay Sabadosa / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('853f0b26-a2b5-48b6-8dd6-f40ca48c87fd',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('853f0b26-a2b5-48b6-8dd6-f40ca48c87fd',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Sabadosa sponsored H.1405, "An Act establishing Medicare for All in Massachusetts," the most expansive healthcare coverage proposal possible — universal single-payer coverage. She also sponsored H.1240, "An Act relative to insulin access," H.1309, "An Act assuring prompt access to health care," H.1314, "An Act enhancing post-pregnancy mental health care," and serves on the Joint Committee on Health Care Financing. Her legislative record places her at the strong pro-universal-coverage end of healthcare policy.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1405', 'https://malegislature.gov/Bills/194/H1240', 'https://malegislature.gov/Bills/194/H1309']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lindsay Sabadosa / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('853f0b26-a2b5-48b6-8dd6-f40ca48c87fd',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('853f0b26-a2b5-48b6-8dd6-f40ca48c87fd',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Sabadosa sponsored H.1310, "An Act to incentivize the adoption of local climate resilience policies," which creates financial incentives for municipalities to adopt climate resilience plans. She also sponsored H.463, "An Act to raise awareness of carbon dioxide emissions at gas stations," and H.1041, "An Act to protect pollinators and public health," addressing pesticide use and biodiversity loss as climate-adjacent issues.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1310', 'https://malegislature.gov/Bills/194/H463', 'https://malegislature.gov/Bills/194/H1041']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lindsay Sabadosa / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('853f0b26-a2b5-48b6-8dd6-f40ca48c87fd',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('853f0b26-a2b5-48b6-8dd6-f40ca48c87fd',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Sabadosa sponsored H.1041, "An Act to protect pollinators and public health," targeting pesticide reduction to protect bees and local ecosystems, and H.463, "An Act to raise awareness of carbon dioxide emissions at gas stations," improving local air quality information. Her cannabis sustainability bill (H.165) also addresses local environmental impacts. These bills reflect active local environmental stewardship.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1041', 'https://malegislature.gov/Bills/194/H463']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lindsay Sabadosa / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('853f0b26-a2b5-48b6-8dd6-f40ca48c87fd',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('853f0b26-a2b5-48b6-8dd6-f40ca48c87fd',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Sabadosa sponsored H.1564, "An Act relative to preventing algorithmic rent fixing in the rental housing market," which bans landlords from using AI pricing software (such as RealPage-style algorithms) to coordinate rent increases — a direct rent regulation measure targeting modern algorithmic price-fixing. This bill is one of the most targeted rent regulation bills in the current session.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1564']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lindsay Sabadosa / ai-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('853f0b26-a2b5-48b6-8dd6-f40ca48c87fd',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('853f0b26-a2b5-48b6-8dd6-f40ca48c87fd',
        '666bf03d-81fc-4138-ab15-69ae734c9023',
        $$Sabadosa sponsored H.1564, banning algorithmic rent-fixing AI software from the housing market, and H.461, "An Act relative to consumer health data," protecting personal health information from algorithmic misuse. She also sponsored H.99, "An Act relative to surveillance pricing in grocery stores," targeting dynamic AI pricing. These bills consistently favor strong AI regulation and consumer protection from algorithmic systems.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1564', 'https://malegislature.gov/Bills/194/H461', 'https://malegislature.gov/Bills/194/H99']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Lindsay Sabadosa / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('853f0b26-a2b5-48b6-8dd6-f40ca48c87fd',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('853f0b26-a2b5-48b6-8dd6-f40ca48c87fd',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Sabadosa sponsored H.687, "An Act ensuring high quality pre-kindergarten education," which expands access to and improves quality of pre-K programs — an investment in early childhood education and care. This bill directly addresses childcare access and quality as a state responsibility.$$,
        ARRAY['https://malegislature.gov/Bills/194/H687']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (should be 7 stances):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '853f0b26-a2b5-48b6-8dd6-f40ca48c87fd';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '853f0b26-a2b5-48b6-8dd6-f40ca48c87fd'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '853f0b26-a2b5-48b6-8dd6-f40ca48c87fd'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
