-- ============================================================================
-- Migration 420: Steven G. Xiarhos Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Steven G. Xiarhos
--   (MA State Representative, 5th Barnstable District, HD-05, Republican).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 416 header for full list.
-- Politician UUID: 892670a6-f15f-4014-86a8-434090c2a514 (external_id: -210045)

BEGIN;

-- ----- Steven G. Xiarhos / public-safety-approach -----
-- Evidence: Former Yarmouth Police Chief, Joint Committee on Public Safety and Homeland Security,
--   committee member; professional career in law enforcement before election.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('892670a6-f15f-4014-86a8-434090c2a514',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('892670a6-f15f-4014-86a8-434090c2a514',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Xiarhos is a former Yarmouth Police Chief who entered the legislature from a law enforcement career, making public safety his defining legislative identity. He serves on the Joint Committee on Public Safety and Homeland Security. His law enforcement background gives him a strong pro-police, enforcement-first orientation on public safety. He has been a vocal presence on Cape Cod criminal justice issues from the perspective of a career police officer. He did not co-sponsor any criminal justice reform legislation tracked by Act on Mass.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/SGX1', 'https://www.capecodtimes.com/search/?q=Xiarhos']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steven G. Xiarhos / homelessness-response -----
-- Evidence: Op-ed in Cape Cod Times opposing the Right to Shelter law, calling for reform.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('892670a6-f15f-4014-86a8-434090c2a514',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('892670a6-f15f-4014-86a8-434090c2a514',
        '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
        $$Xiarhos authored a Cape Cod Times op-ed titled "Migrant crisis taxes local towns. Right to Shelter law must be reformed," directly criticizing Massachusetts' Right to Shelter mandate. He argued that the law imposes undue costs on local communities and called for reform. This positions him against broad shelter access mandates and indicates a preference for limiting government obligations around emergency shelter, with a focus on fiscal impacts on towns.$$,
        ARRAY['https://www.capecodtimes.com/search/?q=Xiarhos+Right+to+Shelter', 'https://malegislature.gov/Legislators/Profile/SGX1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Steven G. Xiarhos / healthcare -----
-- Evidence: Joint Committee on Mental Health, Substance Use and Recovery assignment.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('892670a6-f15f-4014-86a8-434090c2a514',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('892670a6-f15f-4014-86a8-434090c2a514',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Xiarhos serves on the Joint Committee on Mental Health, Substance Use and Recovery, reflecting engagement with addiction and mental health treatment policy. As a former police chief on Cape Cod -- a region with significant opioid challenges -- he has constituent-based experience with mental health and substance use policy. He did not co-sponsor Medicare for All or other single-payer expansion legislation, but his committee assignment demonstrates active engagement with behavioral health services. His approach is more treatment-focused within the current insurance framework rather than systemic expansion.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/SGX1', 'https://actonmass.org/legislators/steven-xiarhos/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '892670a6-f15f-4014-86a8-434090c2a514';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '892670a6-f15f-4014-86a8-434090c2a514'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '892670a6-f15f-4014-86a8-434090c2a514'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
