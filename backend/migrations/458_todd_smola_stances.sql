-- ============================================================================
-- Migration 458: Todd M. Smola Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Todd M. Smola (MA State Rep, 1st Hampden District, HD-43).
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
-- Todd M. Smola (HD-43, external_id=-210083)
-- UUID: aca1e324-cc09-4492-a2f7-d795beb752ff
-- District: 1st Hampden (Warren/Palmer area)
-- Republican; House Committee on Ways and Means; House Committee on Federal Funding.
-- ============================================================================

-- ----- Todd M. Smola / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aca1e324-cc09-4492-a2f7-d795beb752ff',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aca1e324-cc09-4492-a2f7-d795beb752ff',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Smola sponsored H.2699, "An Act relative to the lawful sale of handguns," reflecting a pro-gun access stance consistent with Republican leanings on firearm rights. He also sponsored H.2700, "An Act relative to firearms and recreational vehicles," further indicating support for expanding firearms access in recreational contexts. These bills place him toward the enforcement/traditional end of public safety policy rather than the reform/treatment end.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2699', 'https://malegislature.gov/Bills/194/H2700']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd M. Smola / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aca1e324-cc09-4492-a2f7-d795beb752ff',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aca1e324-cc09-4492-a2f7-d795beb752ff',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Smola sponsored H.308, "An Act to establish an industrial mill building task force," aimed at revitalizing industrial mill buildings — a business-development approach to economic revival in the Hampden region. His role on the House Committee on Ways and Means further reflects a focus on fiscal and economic policy from a business-friendly, market-oriented perspective.$$,
        ARRAY['https://malegislature.gov/Bills/194/H308', 'https://malegislature.gov/Legislators/Profile/TMS2/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd M. Smola / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aca1e324-cc09-4492-a2f7-d795beb752ff',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aca1e324-cc09-4492-a2f7-d795beb752ff',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Smola sponsored H.2539, "An Act relative to well water disclosures," requiring disclosure of certain hazards in well water — a local environmental transparency measure protecting rural water supplies. This bill reflects a pragmatic local environmental concern without indicating a broad progressive environmental stance; it is consistent with a moderate, community-focused approach to local environmental issues.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2539']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Todd M. Smola / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('aca1e324-cc09-4492-a2f7-d795beb752ff',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('aca1e324-cc09-4492-a2f7-d795beb752ff',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Smola sponsored H.3242, "An Act establishing a property tax exemption for members of the National Guard," and H.3243, "An Act relative to disabled service-connected veterans and the motor vehicle excise tax," both of which reduce tax burdens on specific groups. As a Republican on House Ways and Means, his fiscal approach consistently favors tax relief and limits on tax increases, placing him toward the lower-taxes end of the spectrum.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3242', 'https://malegislature.gov/Bills/194/H3243']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (should be 4 stances):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'aca1e324-cc09-4492-a2f7-d795beb752ff';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'aca1e324-cc09-4492-a2f7-d795beb752ff'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'aca1e324-cc09-4492-a2f7-d795beb752ff'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
