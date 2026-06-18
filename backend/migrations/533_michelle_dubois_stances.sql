-- ============================================================================
-- Migration 533: Michelle M. DuBois Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Michelle M. DuBois (MA State Rep,
--          10th Plymouth District, HD-118, external_id=-210158).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Michelle M. DuBois (HD-118, external_id=-210158, id=75a2d83f-8db8-478b-a36d-5ecb707b8507) --

-- ----- Michelle M. DuBois / homelessness -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('75a2d83f-8db8-478b-a36d-5ecb707b8507',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('75a2d83f-8db8-478b-a36d-5ecb707b8507',
        '4938766b-b45a-46e3-93bd-b8b30651271a',
        $$DuBois sponsored H.226 ("An Act to end child homelessness") and H.1498 ("An Act to limit criminalization of the homeless"), which opposes using the criminal justice system against people experiencing homelessness. Together these bills reflect a services-first, anti-criminalization approach to addressing homelessness — a consistently progressive housing stance.$$,
        ARRAY['https://malegislature.gov/Bills/194/H226', 'https://malegislature.gov/Bills/194/H1498']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle M. DuBois / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('75a2d83f-8db8-478b-a36d-5ecb707b8507',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('75a2d83f-8db8-478b-a36d-5ecb707b8507',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$DuBois sponsored H.1497 ("An Act relative to avoiding senior homelessness and maintaining senior housing stabilization of rents"), which stabilizes rents for seniors, and H.1145 (regulating certain mortgages) and H.1146 (Resolution Trust Fund for mortgage payments). Her housing bills consistently protect vulnerable homeowners and renters from displacement.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1497', 'https://malegislature.gov/Bills/194/H1145', 'https://malegislature.gov/Bills/194/H226']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle M. DuBois / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('75a2d83f-8db8-478b-a36d-5ecb707b8507',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('75a2d83f-8db8-478b-a36d-5ecb707b8507',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$DuBois sponsored H.1675 (hate crime protections for gender-targeted victims), H.1676 (DV/sexual assault victim protections), H.1674 (protecting rape survivors and their children), and H.2095 (restricting NDAs in discrimination/harassment claims). She has been particularly active on gender-based civil rights and anti-discrimination protections.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1675', 'https://malegislature.gov/Bills/194/H1676', 'https://malegislature.gov/Bills/194/H2095']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle M. DuBois / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('75a2d83f-8db8-478b-a36d-5ecb707b8507',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('75a2d83f-8db8-478b-a36d-5ecb707b8507',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$DuBois sponsored H.3087 ("An Act repealing chapter 62F"), which would repeal Massachusetts's tax cap law (Chapter 62F) that requires the state to refund excess tax revenue. She also sponsored H.3088 studying the fiscal harms of this law. Repealing 62F would allow the state to retain more tax revenue for public spending — a strongly progressive tax position.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3087', 'https://malegislature.gov/Bills/194/H3088']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Michelle M. DuBois / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('75a2d83f-8db8-478b-a36d-5ecb707b8507',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('75a2d83f-8db8-478b-a36d-5ecb707b8507',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$DuBois sponsored H.3086 ("An Act providing tax credits to certain employers that provide affordable, on-site child-care for employees"), using employer tax incentives to expand childcare access. This reflects a market-facilitation approach to childcare alongside her broader progressive economic agenda.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3086']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '75a2d83f-8db8-478b-a36d-5ecb707b8507';
-- unpaired=0; uncited=0
