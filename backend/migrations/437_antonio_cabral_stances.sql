-- ============================================================================
-- Migration 437: Antonio F. Cabral Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Antonio F. Cabral (MA State Rep, HD-22,
--   13th Bristol District, New Bedford).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Politician UUID: 5e27127a-4df3-4d16-a1a4-2bf081c92842 (external_id=-210062)

BEGIN;

-- ----- Antonio F. Cabral / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e27127a-4df3-4d16-a1a4-2bf081c92842',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e27127a-4df3-4d16-a1a4-2bf081c92842',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Cabral co-sponsored the Medicare for All bill tracked by Act on Mass, and sponsored H.207 to direct the Department of Transitional Assistance to establish basic needs assistance for residents. He also filed H.1353 directing the Health Policy Commission to study acute care hospital stays exceeding 60 days. His record reflects strong support for universal or expanded public healthcare coverage.$$,
        ARRAY['https://actonmass.org/legislators/antonio-cabral/', 'https://malegislature.gov/Bills/194/H207', 'https://malegislature.gov/Bills/194/H1353']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Antonio F. Cabral / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e27127a-4df3-4d16-a1a4-2bf081c92842',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e27127a-4df3-4d16-a1a4-2bf081c92842',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Cabral sponsored multiple economic development bills for New Bedford: H.297 on neighborhood stabilization and economic development, H.298 on school-centered neighborhood developments, H.299 to further regulate business improvement districts, and H.3038 to establish a downtown vitality fund to strengthen local business districts funded by a portion of the sales tax. He also co-sponsored "Stop Corporate Offshoring" legislation tracked by Act on Mass. His New Bedford focus reflects strong community economic development priority.$$,
        ARRAY['https://malegislature.gov/Bills/194/H297', 'https://malegislature.gov/Bills/194/H298', 'https://malegislature.gov/Bills/194/H3038', 'https://actonmass.org/legislators/antonio-cabral/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Antonio F. Cabral / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e27127a-4df3-4d16-a1a4-2bf081c92842',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e27127a-4df3-4d16-a1a4-2bf081c92842',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Cabral sponsored H.3039 on the housing development incentive program, and H.298 on school-centered neighborhood developments aimed at revitalizing New Bedford neighborhoods. He also co-sponsored the Cherish Act and other education bills, reflecting interest in community investment. His housing work focuses on incentive-based development in gateway municipalities.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3039', 'https://malegislature.gov/Bills/194/H298', 'https://malegislature.gov/Legislators/Profile/AFC1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Antonio F. Cabral / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e27127a-4df3-4d16-a1a4-2bf081c92842',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e27127a-4df3-4d16-a1a4-2bf081c92842',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Cabral sponsored H.3454 relative to offshore wind energy generation — a signature climate bill for New Bedford, which is a hub for offshore wind development. He also sponsored H.3037 to allow taxpayers to voluntarily contribute tax refunds to countries vulnerable to climate change. His bills reflect support for renewable energy transition, particularly offshore wind as an economic and environmental priority for his coastal district.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3454', 'https://malegislature.gov/Bills/194/H3037', 'https://malegislature.gov/Legislators/Profile/AFC1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Antonio F. Cabral / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e27127a-4df3-4d16-a1a4-2bf081c92842',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e27127a-4df3-4d16-a1a4-2bf081c92842',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Cabral sponsored H.3633 for legislation to fund public transit expansion including establishment of certain fees, H.3632 relative to commuter rail service fares (accessibility/affordability), and H.3631 for EV charging stations at municipal parking facilities. This suite of transit bills reflects strong support for public transportation investment and electrification of transportation infrastructure in his New Bedford district.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3633', 'https://malegislature.gov/Bills/194/H3632', 'https://malegislature.gov/Bills/194/H3631']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Antonio F. Cabral / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e27127a-4df3-4d16-a1a4-2bf081c92842',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e27127a-4df3-4d16-a1a4-2bf081c92842',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Cabral co-sponsored the Healthy Youth Act (LGBTQ+ inclusive sex education) as tracked by Act on Mass, and sponsored H.520 relative to training qualified school interpreters in educational settings, reflecting civil rights and equity priorities in education. He also filed H.3301 to further regulate access to public records, supporting government transparency. His overall legislative pattern reflects a consistent civil rights priority.$$,
        ARRAY['https://actonmass.org/legislators/antonio-cabral/', 'https://malegislature.gov/Bills/194/H520', 'https://malegislature.gov/Bills/194/H3301']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Antonio F. Cabral / campaign-finance -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e27127a-4df3-4d16-a1a4-2bf081c92842',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e27127a-4df3-4d16-a1a4-2bf081c92842',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Cabral co-sponsored Stop Corporate Offshoring legislation and the Sunlight Act (government transparency) as tracked by Act on Mass. He also sponsored H.3301 to further regulate access to public records and H.3299 relative to participation in public meetings. As Chair of the Joint Committee on State Administration and Regulatory Oversight, he oversees government transparency and accountability matters, reflecting pro-reform stances.$$,
        ARRAY['https://actonmass.org/legislators/antonio-cabral/', 'https://malegislature.gov/Bills/194/H3301', 'https://malegislature.gov/Legislators/Profile/AFC1/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Antonio F. Cabral / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e27127a-4df3-4d16-a1a4-2bf081c92842',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e27127a-4df3-4d16-a1a4-2bf081c92842',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Cabral sponsored H.3035 relative to the taxation of graduate student loan debt (tax relief for students), H.3036 for a historic building fire prevention tax credit (targeted tax incentive), and H.3038 for a downtown vitality fund funded by a portion of the sales tax. He also co-sponsored Stop Corporate Offshoring, which includes corporate tax provisions. These bills show a moderate tax stance — supportive of targeted tax credits and relief for working families while opposing corporate offshoring.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3035', 'https://malegislature.gov/Bills/194/H3036', 'https://malegislature.gov/Bills/194/H3038']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '5e27127a-4df3-4d16-a1a4-2bf081c92842';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '5e27127a-4df3-4d16-a1a4-2bf081c92842'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '5e27127a-4df3-4d16-a1a4-2bf081c92842'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
