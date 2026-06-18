-- ============================================================================
-- Migration 534: Rita A. Mendes Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Rita A. Mendes (MA State Rep,
--          11th Plymouth District, HD-119, external_id=-210159).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Rita A. Mendes (HD-119, external_id=-210159, id=042c79d6-2f15-4e90-b672-ce779a53cae0) --

-- ----- Rita A. Mendes / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('042c79d6-2f15-4e90-b672-ce779a53cae0',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('042c79d6-2f15-4e90-b672-ce779a53cae0',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Mendes sponsored H.1263 ("An Act relative to reducing racial and socioeconomic inequities in auto insurance premium pricing"), targeting the use of education and credit scores that perpetuate racial disparities in auto insurance. She also sponsored H.451 (professional licensure access for citizens/non-citizens) and H.2669 (hoisting examinations for foreign language speakers). These bills show deep commitment to racial and socioeconomic equity in government services.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1263', 'https://malegislature.gov/Bills/194/H451', 'https://malegislature.gov/Bills/194/H2669']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rita A. Mendes / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('042c79d6-2f15-4e90-b672-ce779a53cae0',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('042c79d6-2f15-4e90-b672-ce779a53cae0',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Mendes sponsored H.2918 ("An Act relative to mandatory coverage for certain health screenings for firefighters"), expanding health insurance coverage mandates, and H.2498 (addressing conflicts of interest in nursing agency use at skilled nursing facilities — patient protection). Her healthcare bills expand access and protect vulnerable patients.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2918', 'https://malegislature.gov/Bills/194/H2498']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rita A. Mendes / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('042c79d6-2f15-4e90-b672-ce779a53cae0',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('042c79d6-2f15-4e90-b672-ce779a53cae0',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Mendes sponsored H.1552 ("An Act to create an interagency supportive housing finance and strategy board") to coordinate state housing investment, and H.4051 (establishing a municipal tax assessment increase limit to protect homeowners from sharp tax increases). Her housing bills reflect both supply-side coordination and anti-displacement protections.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1552', 'https://malegislature.gov/Bills/194/H4051']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rita A. Mendes / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('042c79d6-2f15-4e90-b672-ce779a53cae0',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('042c79d6-2f15-4e90-b672-ce779a53cae0',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Mendes sponsored H.2080 ("An Act to promote economic mobility through ESOL"), funding English as a Second Language programs as an economic mobility tool for immigrants, and H.4044 (tuition and student loan reimbursement in gateway cities). Her economic development approach centers on workforce investment in gateway cities (like Brockton) with large immigrant populations.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2080', 'https://malegislature.gov/Bills/194/H4044']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '042c79d6-2f15-4e90-b672-ce779a53cae0';
-- unpaired=0; uncited=0
