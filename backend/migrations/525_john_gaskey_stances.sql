-- ============================================================================
-- Migration 525: John R. Gaskey Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for John R. Gaskey (MA State Rep,
--          2nd Plymouth District, HD-110, external_id=-210150).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- John R. Gaskey (HD-110, external_id=-210150, id=08a2dfdf-43fb-408a-b758-aa94497fd871) --

-- ----- John R. Gaskey / trans-athletes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('08a2dfdf-43fb-408a-b758-aa94497fd871',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('08a2dfdf-43fb-408a-b758-aa94497fd871',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Gaskey sponsored H.584 ("An Act to ensure fairness and safety in school sports") and H.737 ("An Act relative to defending the autonomy and integrity of student athletes and coaches"), both of which are designed to restrict transgender girls from competing on female sports teams. These bills directly reflect a position opposing transgender inclusion in sports based on biological sex categories.$$,
        ARRAY['https://malegislature.gov/Bills/194/H584', 'https://malegislature.gov/Bills/194/H737']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John R. Gaskey / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('08a2dfdf-43fb-408a-b758-aa94497fd871',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('08a2dfdf-43fb-408a-b758-aa94497fd871',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Gaskey sponsored H.1508 ("An Act repealing the misused and misguided right to shelter law that is unique to Massachusetts"), which would eliminate the state's legal obligation to provide emergency shelter to homeless families and migrants. This bill targets the state's shelter obligation that was strained by migrant arrivals and reflects a restrictionist immigration/social services position.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1508']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John R. Gaskey / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('08a2dfdf-43fb-408a-b758-aa94497fd871',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('08a2dfdf-43fb-408a-b758-aa94497fd871',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Gaskey sponsored H.1721 ("An Act for informed consent in public health") and H.2431 ("An Act prohibiting the requirement of a COVID-19 vaccine, mRNA vaccine, or gene-altering procedure"). These bills reflect opposition to government-mandated healthcare interventions, particularly vaccine requirements, and a strong individual-choice/anti-mandate position on healthcare policy.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1721', 'https://malegislature.gov/Bills/194/H2431']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John R. Gaskey / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('08a2dfdf-43fb-408a-b758-aa94497fd871',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        5.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('08a2dfdf-43fb-408a-b758-aa94497fd871',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Gaskey sponsored H.2618 ("An Act repealing the misguided, unnecessary, and largely unconstitutional firearms law of 2024") and H.2620 ("An Act repealing red flag laws"), both targeting gun safety legislation passed by the Democratic majority. These bills reflect a strong pro-Second Amendment position opposing firearms restrictions and judicial extreme risk protection orders.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2618', 'https://malegislature.gov/Bills/194/H2620']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- John R. Gaskey / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('08a2dfdf-43fb-408a-b758-aa94497fd871',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('08a2dfdf-43fb-408a-b758-aa94497fd871',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Gaskey sponsored H.948 (protecting public health including the Plymouth Carver Sole Source Aquifer — a critical drinking water source designated under the federal Safe Drinking Water Act) and H.949 (ensuring safe drinking water standards for state funding eligibility). His local environmental action focuses on clean water protection for his Plymouth district.$$,
        ARRAY['https://malegislature.gov/Bills/194/H948', 'https://malegislature.gov/Bills/194/H949']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '08a2dfdf-43fb-408a-b758-aa94497fd871';
-- unpaired=0; uncited=0
