-- ============================================================================
-- Migration 530: Alyson Sullivan-Almeida Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Alyson Sullivan-Almeida (MA State Rep,
--          7th Plymouth District, HD-115, external_id=-210155).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Alyson Sullivan-Almeida (HD-115, external_id=-210155, id=7131c893-90fc-4c27-b4f6-e3fc8fcf6ec2) --

-- ----- Alyson Sullivan-Almeida / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7131c893-90fc-4c27-b4f6-e3fc8fcf6ec2',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7131c893-90fc-4c27-b4f6-e3fc8fcf6ec2',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Sullivan-Almeida sponsored H.1661 ("An Act to protect victims of rape and children conceived during the commission of said offense") and H.2546 ("An Act related to unborn victims of Down Syndrome"), which protects pregnancies where a Down syndrome diagnosis is made. Both bills reflect a strong pro-life stance opposing abortion even in difficult circumstances involving disability or rape.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1661', 'https://malegislature.gov/Bills/194/H2546']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alyson Sullivan-Almeida / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7131c893-90fc-4c27-b4f6-e3fc8fcf6ec2',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7131c893-90fc-4c27-b4f6-e3fc8fcf6ec2',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Sullivan-Almeida sponsored H.2009 ("An Act supporting and honoring Immigration and Customs Enforcement lawful detainments" — SHIELD Act), which would require Massachusetts law enforcement to cooperate with ICE detainer requests. This bill is explicitly in support of federal deportation operations and against Massachusetts sanctuary policies.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2009']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alyson Sullivan-Almeida / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7131c893-90fc-4c27-b4f6-e3fc8fcf6ec2',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7131c893-90fc-4c27-b4f6-e3fc8fcf6ec2',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Sullivan-Almeida sponsored H.1999-H.2001 (establishing standards and protections for domestic violence/sexual assault victims), H.2006 (strengthening sexual harassment and discrimination policies), and H.2007 (reforming NDAs in sexual harassment cases). While a Republican, she has been active on gender-based civil rights protections, supporting stronger accountability mechanisms for workplace and sexual violence.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2001', 'https://malegislature.gov/Bills/194/H2006', 'https://malegislature.gov/Bills/194/H2007']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Alyson Sullivan-Almeida / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('7131c893-90fc-4c27-b4f6-e3fc8fcf6ec2',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('7131c893-90fc-4c27-b4f6-e3fc8fcf6ec2',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Sullivan-Almeida sponsored H.1824 (strengthening the definition of attempted murder), H.2003 (relative to possession of a dangerous weapon), H.2005 (correctional personnel safety), and H.2008 (prohibiting sex offenders from changing their names to evade registries). These bills reflect a strong law-and-order, victim-protection approach to public safety.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1824', 'https://malegislature.gov/Bills/194/H2008', 'https://malegislature.gov/Bills/194/H2005']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '7131c893-90fc-4c27-b4f6-e3fc8fcf6ec2';
-- unpaired=0; uncited=0
