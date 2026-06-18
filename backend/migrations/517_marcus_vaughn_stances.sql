-- ============================================================================
-- Migration 517: Marcus S. Vaughn Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Marcus S. Vaughn (MA State Rep,
--          9th Norfolk District, HD-102, external_id=-210142).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference (inform.compass_topics):
-- abortion                         af2fdfd6-02c4-49df-b09c-cf8536f4773f
-- campaign-finance                 92730f69-ae57-401c-8ad1-2d07834a895d
-- civil-rights                     0bc588c6-39e1-4084-b5de-cac909b8b762
-- climate-change                   f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
-- data-centers                     4559b513-0fd8-4ed1-babd-f3b554162f40
-- economic-development             eb3d1247-0de1-4b7f-baec-7259861efd53
-- healthcare                       e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
-- immigration                      4e2c69ce-591e-4197-9cd5-7aceff79d390
-- public-safety-approach           e9ebefcd-c496-45e8-b816-a79f8442ba85
-- taxes                            f7e5678d-dadd-4556-a2fc-446e24642ceb

BEGIN;

-- Marcus S. Vaughn (HD-102, external_id=-210142, id=c9a23774-469d-4c40-b316-7fbd46dab7d9) --

-- ----- Marcus S. Vaughn / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c9a23774-469d-4c40-b316-7fbd46dab7d9',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c9a23774-469d-4c40-b316-7fbd46dab7d9',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Vaughn sponsored H.2034 ("An Act ensuring the enforcement of mandatory minimums for firearm related crimes"), a clearly tough-on-crime measure requiring enforcement of minimum sentences for gun offenses. He also sponsored H.2033 (combating pill press machines used in drug manufacturing). These bills reflect a law-enforcement-first public safety philosophy focused on mandatory sentencing and crime deterrence.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2034', 'https://malegislature.gov/Bills/194/H2033']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marcus S. Vaughn / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c9a23774-469d-4c40-b316-7fbd46dab7d9',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c9a23774-469d-4c40-b316-7fbd46dab7d9',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Vaughn sponsored H.141 ("An Act prohibiting the purchase of farm land by foreign governments"), H.2186 (prevention of unemployment fraud), and H.2555 (relative to food truck licensure streamlining). His approach reflects a business-friendly economic development posture focused on protecting local/American ownership and reducing regulatory burden, consistent with his Republican affiliation.$$,
        ARRAY['https://malegislature.gov/Bills/194/H141', 'https://malegislature.gov/Bills/194/H2186', 'https://malegislature.gov/Bills/194/H2555']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Marcus S. Vaughn / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c9a23774-469d-4c40-b316-7fbd46dab7d9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c9a23774-469d-4c40-b316-7fbd46dab7d9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Vaughn sponsored H.2559 ("An Act to protect a patient's right to a support person at health care facilities"), H.1341 (insurance coverage for medically necessary tattoos), and H.2558 (prescription eyewear). These bills reflect a patient-rights rather than government-expansion approach to healthcare. As a Republican he does not sponsor universal healthcare expansion bills, but supports individual patient protections.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2559', 'https://malegislature.gov/Bills/194/H1341', 'https://malegislature.gov/Bills/194/H2558']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'c9a23774-469d-4c40-b316-7fbd46dab7d9';
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc ON pc.politician_id=pa.politician_id AND pc.topic_id=pa.topic_id
-- WHERE pa.politician_id='c9a23774-469d-4c40-b316-7fbd46dab7d9' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id='c9a23774-469d-4c40-b316-7fbd46dab7d9'
--   AND (sources IS NULL OR array_length(sources,1) IS NULL OR array_length(sources,1)=0);
