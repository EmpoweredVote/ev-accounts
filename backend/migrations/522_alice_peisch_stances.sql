-- ============================================================================
-- Migration 522: Alice H. Peisch Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Alice H. Peisch (MA State Rep,
--          14th Norfolk District, HD-107, external_id=-210147).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Alice H. Peisch (HD-107, external_id=-210147, id=ac853e6e-d419-4d05-b89c-77d11bb68fb2) --

-- ----- Alice H. Peisch / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac853e6e-d419-4d05-b89c-77d11bb68fb2',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac853e6e-d419-4d05-b89c-77d11bb68fb2',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Peisch sponsored H.3210 ("An Act making the fair share tax more equitable"), which addresses the administration of Massachusetts's millionaires surtax (Question 1, 2022). This bill reflects support for progressive taxation while also seeking to improve equity in how the 4% surcharge on incomes over $1M is applied, indicating a nuanced progressive-leaning tax position.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3210']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alice H. Peisch / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac853e6e-d419-4d05-b89c-77d11bb68fb2',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac853e6e-d419-4d05-b89c-77d11bb68fb2',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Peisch sponsored H.1399 ("An Act relative to an individual Medicare marketplace option"), which would create a public Medicare-based insurance option for MA residents. This bill demonstrates strong support for expanding government-provided healthcare coverage through a public option mechanism beyond existing ACA marketplaces.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1399']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alice H. Peisch / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac853e6e-d419-4d05-b89c-77d11bb68fb2',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac853e6e-d419-4d05-b89c-77d11bb68fb2',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Peisch sponsored H.3265 ("An Act to establish an employer-provided childcare tax credit pilot program"), using a tax credit mechanism to incentivize employer childcare benefits. This reflects a market-facilitation rather than direct public funding approach to childcare access, consistent with her moderate-Democrat profile.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3265']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alice H. Peisch / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac853e6e-d419-4d05-b89c-77d11bb68fb2',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac853e6e-d419-4d05-b89c-77d11bb68fb2',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Peisch sponsored H.650 ("An Act relative to affirming and maintaining equal access to public education for all children"), which affirms non-discrimination in school enrollment regardless of immigration status or other characteristics. This strong civil rights bill ensures all children have equal educational access under Massachusetts law.$$,
        ARRAY['https://malegislature.gov/Bills/194/H650']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alice H. Peisch / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ac853e6e-d419-4d05-b89c-77d11bb68fb2',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ac853e6e-d419-4d05-b89c-77d11bb68fb2',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Peisch sponsored H.1018 ("An Act updating the management of the Commonwealth's water resources") and H.3544 (energy efficiency funds in municipal light plants). These bills reflect support for government-managed environmental resource protection and clean energy efficiency, consistent with Massachusetts Democratic positions on local environmental stewardship.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1018', 'https://malegislature.gov/Bills/194/H3544']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'ac853e6e-d419-4d05-b89c-77d11bb68fb2';
-- unpaired=0; uncited=0
