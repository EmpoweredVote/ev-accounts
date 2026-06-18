-- ============================================================================
-- Migration 518: Jeffrey N. Roy Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Jeffrey N. Roy (MA State Rep,
--          10th Norfolk District, HD-103, external_id=-210143).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

BEGIN;

-- Jeffrey N. Roy (HD-103, external_id=-210143, id=4024c884-6627-4496-b3ff-5e91862bf894) --

-- ----- Jeffrey N. Roy / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4024c884-6627-4496-b3ff-5e91862bf894',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4024c884-6627-4496-b3ff-5e91862bf894',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Roy sponsored H.1038 (enhancing circularity in recycling), H.1040 (ban on tire-derived materials in playgrounds), and H.1302 (remediation of home heating oil releases), demonstrating consistent focus on local environmental protection and pollution remediation. He has been an active sponsor of local environmental bills addressing materials safety, contamination cleanup, and recycling infrastructure.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1038', 'https://malegislature.gov/Bills/194/H1040', 'https://malegislature.gov/Bills/194/H1302']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeffrey N. Roy / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4024c884-6627-4496-b3ff-5e91862bf894',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4024c884-6627-4496-b3ff-5e91862bf894',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Roy sponsored H.3230 ("An Act advancing renewable heating solutions for the Commonwealth") and H.3555 (reporting on funds received from the Clean Energy Standard and Clean Heat Standard program). These bills directly address decarbonization of the heating sector and clean energy accountability, showing support for aggressive climate policy action at the state level.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3230', 'https://malegislature.gov/Bills/194/H3555']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeffrey N. Roy / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4024c884-6627-4496-b3ff-5e91862bf894',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4024c884-6627-4496-b3ff-5e91862bf894',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Roy sponsored H.1128 ("An Act preserving access to treatment for patients with serious mental illnesses") and H.2526 (bronchodilators and nebulizers in schools). His bills focus on expanding access to essential healthcare especially for vulnerable populations, consistent with Massachusetts Democratic support for universal and accessible healthcare coverage.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1128', 'https://malegislature.gov/Bills/194/H2526']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeffrey N. Roy / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4024c884-6627-4496-b3ff-5e91862bf894',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4024c884-6627-4496-b3ff-5e91862bf894',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Roy sponsored H.1561 (requiring notice to landlords relating to gas or electric shutoffs), H.1964 (uniform partition of heirs property), and H.1970 (transfer of actions to the housing court for efficiency). His housing bills focus on procedural protections and access to courts rather than direct rent control or large-scale supply mandates.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1561', 'https://malegislature.gov/Bills/194/H1964', 'https://malegislature.gov/Bills/194/H1970']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Jeffrey N. Roy / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4024c884-6627-4496-b3ff-5e91862bf894',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4024c884-6627-4496-b3ff-5e91862bf894',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Roy sponsored H.283 (loan repayment for human services workers), H.2162 (compliance with prevailing wage laws), and H.3411 ("An Act to promote American manufacturing"). His economic bills support labor protections, worker compensation, and domestic manufacturing — a worker-centered approach to economic development.$$,
        ARRAY['https://malegislature.gov/Bills/194/H283', 'https://malegislature.gov/Bills/194/H2162', 'https://malegislature.gov/Bills/194/H3411']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '4024c884-6627-4496-b3ff-5e91862bf894';
-- unpaired must be 0; uncited must be 0.
