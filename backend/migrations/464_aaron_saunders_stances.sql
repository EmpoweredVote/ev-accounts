-- ============================================================================
-- Migration 464: Aaron L. Saunders Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Aaron L. Saunders (MA State Rep, 7th Hampden District, HD-49).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Topic UUID reference (inform.compass_topics): See migration 456 for full reference block.

BEGIN;

-- ============================================================================
-- Aaron L. Saunders (HD-49, external_id=-210089)
-- UUID: e2daa3aa-02b6-4a4d-859b-fb75f674625b
-- District: 7th Hampden (Belchertown/Chicopee area)
-- Democrat; committees: Agriculture, Children/Families/Disabilities, Bonding/Capital.
-- ============================================================================

-- ----- Aaron L. Saunders / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2daa3aa-02b6-4a4d-859b-fb75f674625b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2daa3aa-02b6-4a4d-859b-fb75f674625b',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Saunders sponsored H.3569, "An Act relative to carbon emission reduction and advanced nuclear energy generation," and H.3570, "An Act to update vehicle emissions standards," both targeting reductions in greenhouse gas emissions. He also sponsored H.1426, "An Act to provide green and healthy public colleges and universities," requiring clean energy and sustainability at state college campuses. These bills reflect a consistent climate action stance.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3569', 'https://malegislature.gov/Bills/194/H3570', 'https://malegislature.gov/Bills/194/H1426']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron L. Saunders / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2daa3aa-02b6-4a4d-859b-fb75f674625b',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2daa3aa-02b6-4a4d-859b-fb75f674625b',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Saunders sponsored H.3568, "An Act relative to prohibiting public utility and ratepayer funding of clearcutting forests and woodlands," which blocks ratepayer money from subsidizing fossil fuel-linked biomass clearcutting. He also sponsored H.3567, "An Act relative to energy generation payments," addressing how energy generation is compensated. These bills reflect support for transitioning away from fossil fuels and biomass toward cleaner energy.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3568', 'https://malegislature.gov/Bills/194/H3567']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron L. Saunders / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2daa3aa-02b6-4a4d-859b-fb75f674625b',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2daa3aa-02b6-4a4d-859b-fb75f674625b',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Saunders sponsored H.1042, "An Act relative to the Quabbin Watershed and regional equity," protecting the Quabbin water supply and addressing regional equity in watershed management. He also sponsored H.2331, "An Act allowing municipalities to reasonably regulate solar siting," preserving local environmental control over solar projects. Both bills address local environmental quality and community control.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1042', 'https://malegislature.gov/Bills/194/H2331']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron L. Saunders / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2daa3aa-02b6-4a4d-859b-fb75f674625b',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2daa3aa-02b6-4a4d-859b-fb75f674625b',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Saunders sponsored H.1318, "An Act allowing for increased investment in health care providers," H.2172, "An Act to prevent heat-related illness in public sector outdoor workers" (worker health protection), and H.2393, "An Act authorizing Massachusetts entry into the interstate medical licensure compact" (expanding healthcare access via licensing reciprocity). These bills reflect a pro-access, pro-expansion approach to healthcare.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1318', 'https://malegislature.gov/Bills/194/H2172', 'https://malegislature.gov/Bills/194/H2393']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron L. Saunders / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2daa3aa-02b6-4a4d-859b-fb75f674625b',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2daa3aa-02b6-4a4d-859b-fb75f674625b',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Saunders sponsored H.1565, "An Act providing for pre-service training for members of mobile home rent control boards," which supports the implementation and strengthening of rent control boards in manufactured housing communities — a direct indicator of support for rent regulation policy.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1565']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron L. Saunders / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2daa3aa-02b6-4a4d-859b-fb75f674625b',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2daa3aa-02b6-4a4d-859b-fb75f674625b',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Saunders sponsored H.2330, "An Act relative to equitable representation," which addresses fair representation and redistricting equity. This bill directly supports the expansion of voting rights and fair electoral representation, placing him in favor of stronger voting rights protections.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2330']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Aaron L. Saunders / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e2daa3aa-02b6-4a4d-859b-fb75f674625b',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e2daa3aa-02b6-4a4d-859b-fb75f674625b',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Saunders sponsored H.2171, "An Act to make data on workforce development outcomes public and accessible," which increases transparency in workforce training programs to improve economic mobility. He also serves on the Joint Committee on Agriculture and Fisheries supporting rural economic development. These reflect a pro-labor, pro-transparency approach to economic policy.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2171', 'https://malegislature.gov/Legislators/Profile/ALS1/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (should be 7 stances):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = 'e2daa3aa-02b6-4a4d-859b-fb75f674625b';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = 'e2daa3aa-02b6-4a4d-859b-fb75f674625b'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = 'e2daa3aa-02b6-4a4d-859b-fb75f674625b'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
