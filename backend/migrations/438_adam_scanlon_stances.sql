-- ============================================================================
-- Migration 438: Adam J. Scanlon Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Adam J. Scanlon (MA State Rep, HD-23,
--   14th Bristol District, North Attleborough).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Politician UUID: c0852fa6-8184-4f2d-b1cf-fde8cbf3c4b2 (external_id=-210063)

BEGIN;

-- ----- Adam J. Scanlon / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0852fa6-8184-4f2d-b1cf-fde8cbf3c4b2',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0852fa6-8184-4f2d-b1cf-fde8cbf3c4b2',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Scanlon sponsored legislation to establish a missing-middle starter home development and homeownership program, addressing the affordability gap for moderate-income buyers. He also sponsored H.1989 to address discrimination of certain homebuyers and H.307 on economic growth of downtowns and main streets. These bills reflect a pro-housing-supply approach with equity focus on first-time homebuyers and anti-discrimination protections.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/AJS1', 'https://malegislature.gov/Bills/194/H1989', 'https://malegislature.gov/Bills/194/H307']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adam J. Scanlon / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0852fa6-8184-4f2d-b1cf-fde8cbf3c4b2',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0852fa6-8184-4f2d-b1cf-fde8cbf3c4b2',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Scanlon co-sponsored Overdose Prevention Centers legislation (Act on Mass) and sponsored H.1407 on MassHealth rate parity for behavioral health inpatient providers. He filed H.2232 to require network hospitals to be compensated for behavioral health services to MassHealth patients, H.2233 for equitable access to behavioral health services, and H.2234 on alternative transport models for behavioral health patients. This suite of behavioral health bills reflects a strong commitment to expanding public health coverage.$$,
        ARRAY['https://actonmass.org/legislators/adam-scanlon/', 'https://malegislature.gov/Bills/194/H1407', 'https://malegislature.gov/Bills/194/H2232', 'https://malegislature.gov/Bills/194/H2233']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adam J. Scanlon / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0852fa6-8184-4f2d-b1cf-fde8cbf3c4b2',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0852fa6-8184-4f2d-b1cf-fde8cbf3c4b2',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Scanlon serves as Vice-chair of the Joint Committee on Racial Equity, Civil Rights, and Inclusion — a leadership role reflecting civil rights priority. He sponsored H.1989 to address discrimination of certain homebuyers in The Judiciary committee. He also sponsored H.1988 on privacy of sensitive information in legal documents. His committee role and sponsored bills demonstrate a sustained focus on racial equity and anti-discrimination.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/AJS1/Committees', 'https://malegislature.gov/Bills/194/H1989', 'https://actonmass.org/legislators/adam-scanlon/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adam J. Scanlon / school-vouchers -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0852fa6-8184-4f2d-b1cf-fde8cbf3c4b2',
        '00b95a6a-75db-4521-b523-3326bba938de',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0852fa6-8184-4f2d-b1cf-fde8cbf3c4b2',
        '00b95a6a-75db-4521-b523-3326bba938de',
        $$Scanlon sponsored H.692 relative to local approval for charter schools, which would require local community approval before new charter schools can open — a position that limits charter school expansion and reflects opposition to school voucher-style diversion from public schools. He also filed H.694 relative to admissions policies for vocational schools, reflecting a focus on equitable access within the public school system.$$,
        ARRAY['https://malegislature.gov/Bills/194/H692', 'https://malegislature.gov/Bills/194/H694', 'https://malegislature.gov/Legislators/Profile/AJS1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adam J. Scanlon / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0852fa6-8184-4f2d-b1cf-fde8cbf3c4b2',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0852fa6-8184-4f2d-b1cf-fde8cbf3c4b2',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Scanlon sponsored multiple targeted tax relief bills: H.3234/3235 on senior and veteran property tax relief, H.3236 expanding the senior property tax exemption, H.3237 on medical and dental expense deductions, and H.3238 on late payments and interest rates for real estate bills. These bills reflect a moderate tax position focused on targeted relief for seniors and veterans rather than broad tax reform.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3234', 'https://malegislature.gov/Bills/194/H3235', 'https://malegislature.gov/Bills/194/H3236', 'https://malegislature.gov/Bills/194/H3237']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Adam J. Scanlon / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c0852fa6-8184-4f2d-b1cf-fde8cbf3c4b2',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c0852fa6-8184-4f2d-b1cf-fde8cbf3c4b2',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Scanlon sponsored H.307 relative to the economic growth of downtowns and main streets — a community-centered economic development bill. He also co-sponsored the Cherish Act for fully funded higher education (Act on Mass) and sponsored vocational school funding bills H.651 and H.1456/1457 on community college training. His focus is on local economic development through workforce development and education investment.$$,
        ARRAY['https://malegislature.gov/Bills/194/H307', 'https://actonmass.org/legislators/adam-scanlon/', 'https://malegislature.gov/Bills/194/H651']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'c0852fa6-8184-4f2d-b1cf-fde8cbf3c4b2';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'c0852fa6-8184-4f2d-b1cf-fde8cbf3c4b2'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'c0852fa6-8184-4f2d-b1cf-fde8cbf3c4b2'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
