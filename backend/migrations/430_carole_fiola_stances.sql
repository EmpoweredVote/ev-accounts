-- ============================================================================
-- Migration 430: Carole A. Fiola Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Carole A. Fiola
--   (MA State Representative, 6th Bristol District, HD-15, Democrat).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- NOTE: Pre-existing rows with value=3.0 "did not co-sponsor" neutral defaults
--   exist for several topics from a prior AOM agent run. Per scope boundary rules
--   those pre-existing rows are not modified here. This migration UPSERTS topics
--   where direct evidence exists, improving or confirming the record.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 416 header for full list.
-- Politician UUID: 913143ad-c39b-4dde-9a93-8252a98b0181 (external_id: -210055)

BEGIN;

-- ----- Carole A. Fiola / healthcare -----
-- Evidence: Sponsored H.1364 (healthcare access and affordability), H.1157 (prescription
--   medication and community pharmacies), H.1156 (healthcare carrier transparency),
--   H.1363 (extend healthcare coverage), H.367 (increased hearing aid access),
--   H.572 (CPR/defibrillator training), H.1692 (healthcare decisions during incapacity).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('913143ad-c39b-4dde-9a93-8252a98b0181',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('913143ad-c39b-4dde-9a93-8252a98b0181',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Fiola has filed multiple healthcare bills demonstrating a strong pro-access healthcare position. She sponsored H.1364 (healthcare access and affordability for patients), H.1157 (prescription medication and community pharmacy access), H.1156 (requiring healthcare carriers to share account information to improve transparency), H.1363 (extending healthcare coverage), H.367 (increasing access to hearing aids), and H.572 (CPR and defibrillator training). This breadth of healthcare legislation from a Fall River Democrat reflects active commitment to expanding healthcare access and reducing costs for constituents.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1364', 'https://malegislature.gov/Bills/194/H1157', 'https://malegislature.gov/Bills/194/H367', 'https://malegislature.gov/Legislators/Profile/CAF1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Carole A. Fiola / childcare -----
-- Evidence: Co-sponsored Campaign Childcare (H.669/S.422) per AOM tracker,
--   allowing campaign funds to cover childcare for candidates with young children.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('913143ad-c39b-4dde-9a93-8252a98b0181',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('913143ad-c39b-4dde-9a93-8252a98b0181',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Fiola co-sponsored Campaign Childcare (H.669/S.422) per the Act on Mass tracker, legislation to allow campaign funds to cover childcare costs — reducing barriers for parents with young children to run for office. She also sponsored H.573 directing the Department of Elementary and Secondary Education to assess preschool and childcare program quality. Her active engagement with both childcare access and education for young children reflects a pro-childcare policy stance.$$,
        ARRAY['https://actonmass.org/legislators/carole-fiola/', 'https://actonmass.org/bills/campaign-childcare/', 'https://malegislature.gov/Bills/194/H573']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Carole A. Fiola / economic-development -----
-- Evidence: Chair of Joint Committee on Municipalities and Regional Government;
--   represents Fall River, a formerly industrial city with active economic redevelopment.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('913143ad-c39b-4dde-9a93-8252a98b0181',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('913143ad-c39b-4dde-9a93-8252a98b0181',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Fiola chairs the Joint Committee on Municipalities and Regional Government, the primary committee overseeing municipal finances, local economic development programs, and regional planning. She represents Fall River, a formerly industrial city that has undergone significant economic redevelopment. Her committee leadership directly engages with local economic development policy, municipal infrastructure investment, and regional collaboration. As a Democrat from an economically challenged city, her approach reflects a government-active stance on economic development and regional equity.$$,
        ARRAY['https://actonmass.org/legislators/carole-fiola/', 'https://malegislature.gov/Legislators/Profile/CAF1', 'https://malegislature.gov/Committees/Joint/J24']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '913143ad-c39b-4dde-9a93-8252a98b0181';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '913143ad-c39b-4dde-9a93-8252a98b0181'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '913143ad-c39b-4dde-9a93-8252a98b0181'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
