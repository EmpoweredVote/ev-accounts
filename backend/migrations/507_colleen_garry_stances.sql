-- ============================================================================
-- Migration 507: Colleen M. Garry Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Colleen M. Garry (MA House HD-92,
--   36th Middlesex District, Dracut/Tyngsborough). External ID: -210132.
--   Garry has served since 1993; Democrat with moderate record from a
--   suburban/rural Merrimack Valley district.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- ============================================================================

BEGIN;

-- Colleen M. Garry (HD-92, external_id=-210132)
-- Politician UUID: c8f917f9-f6c4-49f8-b5a4-c330b07f90d2

-- ----- Colleen M. Garry / abortion -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c8f917f9-f6c4-49f8-b5a4-c330b07f90d2',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c8f917f9-f6c4-49f8-b5a4-c330b07f90d2',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Garry voted for the final passage of the ROE Act to codify abortion rights in Massachusetts law. Her record on reproductive rights is moderate — she has voted for major abortion access bills but is not among the progressive champions on this issue. Her long tenure and moderate district reflect cautious but generally supportive votes on reproductive rights.$$,
        ARRAY['https://actonmass.org/legislators/colleen-garry/', 'https://malegislature.gov/Bills/191/H3320'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Colleen M. Garry / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c8f917f9-f6c4-49f8-b5a4-c330b07f90d2',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c8f917f9-f6c4-49f8-b5a4-c330b07f90d2',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Garry voted for the 2021 climate roadmap bill overall but has a more moderate record on aggressive climate mandates than her Cambridge and Somerville colleagues. Her Merrimack Valley district has concerns about energy costs and manufacturing impacts of rapid climate policy changes. Her record reflects a balanced approach supporting climate goals while being cautious about economic impacts on her district.$$,
        ARRAY['https://actonmass.org/legislators/colleen-garry/', 'https://malegislature.gov/Bills/192/H4264'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Colleen M. Garry / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c8f917f9-f6c4-49f8-b5a4-c330b07f90d2',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c8f917f9-f6c4-49f8-b5a4-c330b07f90d2',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Garry has voted to protect MassHealth and support expanded healthcare access throughout her long tenure. She supported the 2012 healthcare cost reform law and mental health parity legislation. Her record reflects mainstream Massachusetts Democratic support for the state's near-universal healthcare framework.$$,
        ARRAY['https://actonmass.org/legislators/colleen-garry/', 'https://malegislature.gov/Legislators/Profile/CMG1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Colleen M. Garry / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c8f917f9-f6c4-49f8-b5a4-c330b07f90d2',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c8f917f9-f6c4-49f8-b5a4-c330b07f90d2',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Garry has a mixed housing record. She voted for some affordable housing funding programs but her Dracut/Tyngsborough district is suburban with different housing dynamics than Boston suburbs. ActOnMass has noted that she did not co-sponsor the rent stabilization bill and has taken moderate positions on zoning reform. Her housing policy reflects the priorities of a suburban Merrimack Valley constituency.$$,
        ARRAY['https://actonmass.org/legislators/colleen-garry/', 'https://malegislature.gov/Legislators/Profile/CMG1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Colleen M. Garry / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c8f917f9-f6c4-49f8-b5a4-c330b07f90d2',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c8f917f9-f6c4-49f8-b5a4-c330b07f90d2',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Garry voted for the Work and Family Mobility Act (drivers' licenses for all residents) after initial hesitation, and she voted for the DREAM Act. However, her Merrimack Valley district includes communities with immigration enforcement concerns and her overall immigration record is more moderate than progressive colleagues. She did not co-sponsor the Safe Communities Act.$$,
        ARRAY['https://actonmass.org/legislators/colleen-garry/', 'https://malegislature.gov/Legislators/Profile/CMG1'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Colleen M. Garry / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c8f917f9-f6c4-49f8-b5a4-c330b07f90d2',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c8f917f9-f6c4-49f8-b5a4-c330b07f90d2',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Garry voted for the 2022 Millionaires Tax (Fair Share Amendment). Her tax record over decades reflects moderate Democratic positions: support for progressive taxation to fund public services while being attentive to the concerns of middle-class constituents in her district about tax burdens.$$,
        ARRAY['https://actonmass.org/legislators/colleen-garry/', 'https://www.ballotpedia.org/Massachusetts_Question_1,_Income_Tax_Surtax_for_Education_and_Transportation_Amendment_(2022)'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Colleen M. Garry / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c8f917f9-f6c4-49f8-b5a4-c330b07f90d2',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c8f917f9-f6c4-49f8-b5a4-c330b07f90d2',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Garry voted for the 2022 VOTES Act making early voting and mail voting permanent. She has supported voting access expansion throughout her career, including the adoption of early voting in Massachusetts. Her record reflects standard Democratic support for ballot access measures.$$,
        ARRAY['https://actonmass.org/legislators/colleen-garry/', 'https://malegislature.gov/Bills/192/S2977'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Verification:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'c8f917f9-f6c4-49f8-b5a4-c330b07f90d2';
-- SELECT COUNT(*) AS unpaired FROM inform.politician_answers pa LEFT JOIN inform.politician_context pc ON pc.politician_id=pa.politician_id AND pc.topic_id=pa.topic_id WHERE pa.politician_id='c8f917f9-f6c4-49f8-b5a4-c330b07f90d2' AND pc.politician_id IS NULL;
-- SELECT COUNT(*) AS uncited FROM inform.politician_context WHERE politician_id='c8f917f9-f6c4-49f8-b5a4-c330b07f90d2' AND (sources IS NULL OR array_length(sources,1) IS NULL OR array_length(sources,1)=0);
