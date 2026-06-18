-- ============================================================================
-- Migration 527: Patrick J. Kearney Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Patrick J. Kearney (MA State Rep,
--          4th Plymouth District, HD-112, external_id=-210152).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Patrick J. Kearney (HD-112, external_id=-210152, id=8c2553dd-437e-4614-89ab-f54031bc418e) --

-- ----- Patrick J. Kearney / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c2553dd-437e-4614-89ab-f54031bc418e',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c2553dd-437e-4614-89ab-f54031bc418e',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Kearney sponsored H.1218 ("An Act relative to access to health care") and H.1446 (clarifying meningococcal vaccine policy in schools). His healthcare bills support access and public health programs rather than comprehensive expansion, consistent with his moderate Democrat orientation representing a coastal South Shore district.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1218', 'https://malegislature.gov/Bills/194/H1446']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patrick J. Kearney / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c2553dd-437e-4614-89ab-f54031bc418e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c2553dd-437e-4614-89ab-f54031bc418e',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Kearney sponsored H.1540 (expanding eligibility for emergency housing assistance) but also H.2338 ("An Act relative to exemptions from MBTA community designations"), which would allow some communities to be exempted from state zoning requirements mandating multifamily housing near transit. This mixed record suggests a moderate position favoring some housing support while preserving local zoning autonomy.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1540', 'https://malegislature.gov/Bills/194/H2338']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Patrick J. Kearney / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8c2553dd-437e-4614-89ab-f54031bc418e',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8c2553dd-437e-4614-89ab-f54031bc418e',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Kearney sponsored H.2177 (economic security for fishing industry workers), H.1810 (protecting honest employers — construction contractor pay enforcement), and H.3367 (requiring procurement of Massachusetts or US-made products). His economic bills reflect a worker-protection and domestic industry focus consistent with representing a coastal fishing and working-class district.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2177', 'https://malegislature.gov/Bills/194/H3367', 'https://malegislature.gov/Bills/194/H1810']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '8c2553dd-437e-4614-89ab-f54031bc418e';
-- unpaired=0; uncited=0
