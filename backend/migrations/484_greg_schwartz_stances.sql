-- ============================================================================
-- Migration 484: Greg Schwartz Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Greg Schwartz (MA House HD-69,
--   12th Middlesex District). External ID: -210109.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Pre-existing rows: 11 rows in DB, several are 3.0 neutral defaults.
--   This migration corrects 3 topics with positive evidence.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

BEGIN;

-- Greg Schwartz (HD-69, external_id=-210109)
-- Politician UUID: 8167ef8d-b8c8-44aa-86a2-9128c9078547

-- ----- Greg Schwartz / climate-change -----
-- Correcting pre-existing 3.0: House Climate Action Committee membership is strong evidence
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8167ef8d-b8c8-44aa-86a2-9128c9078547',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8167ef8d-b8c8-44aa-86a2-9128c9078547',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Schwartz serves on the House Committee on Climate Action and Sustainability — a direct assignment to the committee responsible for advancing Massachusetts climate legislation. His committee assignment demonstrates direct engagement with climate policy and reflects a pro-climate-action position.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/G_S1/Committees', 'https://malegislature.gov/Committees/Detail/H51'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Greg Schwartz / fossil-fuels -----
-- Correcting pre-existing 3.0: Climate committee + CSO/clean water bill indicate anti-fossil stance
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8167ef8d-b8c8-44aa-86a2-9128c9078547',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8167ef8d-b8c8-44aa-86a2-9128c9078547',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Schwartz's membership on the House Committee on Climate Action and Sustainability reflects engagement with transitioning away from fossil fuels. He also filed H.1046, "An Act to eliminate combined sewer overflows in Massachusetts waterways," addressing pollution from aging fossil-fuel era infrastructure. These activities indicate support for moving toward clean energy.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/G_S1/Committees', 'https://malegislature.gov/Bills/194/H1046'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Greg Schwartz / healthcare -----
-- Correcting pre-existing 3.0: multiple healthcare bills filed
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8167ef8d-b8c8-44aa-86a2-9128c9078547',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8167ef8d-b8c8-44aa-86a2-9128c9078547',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Schwartz filed H.285 (healthcare quality for children), H.1321 (consumer health insurance rights transparency), H.2229 (equity in substance abuse care), H.2535 (Naloxone trust fund), H.2536 (psychologist integration in healthcare), and H.2537 (primary care access). This extensive portfolio of healthcare bills reflects strong support for expanded, accessible, equitable healthcare services.$$,
        ARRAY['https://malegislature.gov/Bills/194/H285', 'https://malegislature.gov/Bills/194/H2537', 'https://malegislature.gov/Bills/194/H2229'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Greg Schwartz / local-environment -----
-- New topic: CSO elimination bill is direct local-environment evidence
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8167ef8d-b8c8-44aa-86a2-9128c9078547',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8167ef8d-b8c8-44aa-86a2-9128c9078547',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Schwartz filed H.1046, "An Act to eliminate combined sewer overflows in Massachusetts waterways," which would require municipalities to remediate CSO systems that discharge raw sewage into rivers and bays during rain events. He also serves on the House Climate Action and Sustainability Committee. These activities reflect strong support for local environmental quality.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1046', 'https://malegislature.gov/Legislators/Profile/G_S1/Committees'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Greg Schwartz / economic-development -----
-- New topic: Joint Committee on Economic Development assignment
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8167ef8d-b8c8-44aa-86a2-9128c9078547',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('8167ef8d-b8c8-44aa-86a2-9128c9078547',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Schwartz serves on the Joint Committee on Economic Development and Emerging Technologies, which oversees economic development legislation in Massachusetts. His committee role reflects direct engagement with economic development policy.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/G_S1/Committees', 'https://malegislature.gov/Committees/Detail/J12'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count (should be ~13 total):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '8167ef8d-b8c8-44aa-86a2-9128c9078547';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '8167ef8d-b8c8-44aa-86a2-9128c9078547'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '8167ef8d-b8c8-44aa-86a2-9128c9078547'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
