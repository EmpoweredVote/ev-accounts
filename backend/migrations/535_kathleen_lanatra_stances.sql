-- ============================================================================
-- Migration 535: Kathleen P. LaNatra Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Kathleen P. LaNatra (MA State Rep,
--          12th Plymouth District, HD-120, external_id=-210160).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Kathleen P. LaNatra (HD-120, external_id=-210160, id=bb235d49-c91a-45da-8d91-bf3d5b766196) --

-- ----- Kathleen P. LaNatra / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bb235d49-c91a-45da-8d91-bf3d5b766196',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bb235d49-c91a-45da-8d91-bf3d5b766196',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$LaNatra sponsored H.2218 (behavioral health workforce development), H.2219 (expanding access to mental health services and strengthening risk assessment protocols), H.2220 (access to psychiatric collaborative care), and H.2472 (protecting patient safety regarding non-FDA approved drugs). She has been a consistent advocate for expanding mental health services access and patient safety standards — a strong pro-access healthcare position.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2218', 'https://malegislature.gov/Bills/194/H2219', 'https://malegislature.gov/Bills/194/H2220']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kathleen P. LaNatra / transportation-priorities -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bb235d49-c91a-45da-8d91-bf3d5b766196',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bb235d49-c91a-45da-8d91-bf3d5b766196',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$LaNatra sponsored H.1825 (private railroad workers protections), H.2139 (railroad workers earned sick time), and H.1827 (police reports involving railroad fatalities). Her railroad/transit worker bills show a transit-labor focus for transportation policy, consistent with representing a South Shore district with commuter rail service.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1825', 'https://malegislature.gov/Bills/194/H2139', 'https://malegislature.gov/Bills/194/H1827']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kathleen P. LaNatra / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('bb235d49-c91a-45da-8d91-bf3d5b766196',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('bb235d49-c91a-45da-8d91-bf3d5b766196',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$LaNatra sponsored H.2305 ("An Act reforming the MBTA Communities Act"), which would adjust (rather than repeal) the state's multifamily zoning requirements near transit. This moderate reform position — neither repealing nor unconditionally expanding the mandate — reflects the mixed political pressures in her coastal South Shore district.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2305']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'bb235d49-c91a-45da-8d91-bf3d5b766196';
-- unpaired=0; uncited=0
