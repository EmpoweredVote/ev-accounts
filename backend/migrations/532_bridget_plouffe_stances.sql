-- ============================================================================
-- Migration 532: Bridget M. Plouffe Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Bridget M. Plouffe (MA State Rep,
--          9th Plymouth District, HD-117, external_id=-210157).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Bridget M. Plouffe (HD-117, external_id=-210157, id=63df70bd-91d8-4576-8136-d2128ea5e9b9) --

-- ----- Bridget M. Plouffe / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('63df70bd-91d8-4576-8136-d2128ea5e9b9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('63df70bd-91d8-4576-8136-d2128ea5e9b9',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Plouffe sponsored H.280 (insurance coverage for children's vision screening), H.1402 (protecting MassHealth applicants facing undue hardship), H.2513 (healthcare transparency requirements), and H.2514 (defining disclosure and early offer programs in medical malpractice). Her pattern of bills reflects a pro-access, pro-transparency stance on healthcare expansion and consumer protection.$$,
        ARRAY['https://malegislature.gov/Bills/194/H280', 'https://malegislature.gov/Bills/194/H1402', 'https://malegislature.gov/Bills/194/H2513']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Bridget M. Plouffe / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('63df70bd-91d8-4576-8136-d2128ea5e9b9',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('63df70bd-91d8-4576-8136-d2128ea5e9b9',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Plouffe sponsored H.1289 ("An Act requiring reimbursement for the costs of providing competent interpreter services"), ensuring language access for non-English speakers in public services, and H.3212 (ensuring fairness and equity in property value assessments). These bills reflect civil rights protections for immigrant communities and equitable treatment in government services.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1289', 'https://malegislature.gov/Bills/194/H3212']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '63df70bd-91d8-4576-8136-d2128ea5e9b9';
-- unpaired=0; uncited=0
