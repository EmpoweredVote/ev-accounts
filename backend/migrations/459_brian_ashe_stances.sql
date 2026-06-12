-- ============================================================================
-- Migration 459: Brian M. Ashe Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Brian M. Ashe (MA State Rep, 2nd Hampden District, HD-44).
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
-- Brian M. Ashe (HD-44, external_id=-210084)
-- UUID: 1e83f9fc-43c9-4568-937d-94383acdc117
-- District: 2nd Hampden (Longmeadow area)
-- Democrat; committees: Community Development and Small Businesses, Tourism/Arts.
-- ============================================================================

-- ----- Brian M. Ashe / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e83f9fc-43c9-4568-937d-94383acdc117',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e83f9fc-43c9-4568-937d-94383acdc117',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Ashe sponsored H.200, "An Act establishing the deaf children's bill of rights," which enumerates specific legal rights for deaf and hard-of-hearing children in educational settings. He also sponsored H.511, "An Act ensuring language readiness in deaf, deafblind, and hard-of-hearing children entering kindergarten," expanding accessibility rights. Both bills reflect a pattern of using civil rights legislation to protect marginalized populations including those with disabilities.$$,
        ARRAY['https://malegislature.gov/Bills/194/H200', 'https://malegislature.gov/Bills/194/H511']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian M. Ashe / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e83f9fc-43c9-4568-937d-94383acdc117',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e83f9fc-43c9-4568-937d-94383acdc117',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Ashe co-sponsored H.1080, "An Act relative to copay assistance for certain branded drugs," with Rep. Puppolo — aimed at reducing out-of-pocket costs for patients relying on branded medications. This bill directly expands healthcare affordability by limiting copay burdens, consistent with a pro-access stance on healthcare.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1080']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian M. Ashe / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e83f9fc-43c9-4568-937d-94383acdc117',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e83f9fc-43c9-4568-937d-94383acdc117',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Ashe sponsored H.890, "An Act relative to crumbling concrete foundations," addressing the pyrrhotite contamination crisis affecting thousands of MA homes — a key housing safety and affordability issue in Western MA. This bill seeks state support for homeowners with structurally compromised foundations, reflecting advocacy for housing stability and protection of existing homeowners.$$,
        ARRAY['https://malegislature.gov/Bills/194/H890']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian M. Ashe / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e83f9fc-43c9-4568-937d-94383acdc117',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e83f9fc-43c9-4568-937d-94383acdc117',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Ashe sponsored H.3447, the CLEAN Act ("An Act relative to containers, litter, ecology and nips"), which targets single-use nip bottle litter and container pollution. He also sponsored H.509, establishing a school carbon monoxide safety trust fund to address indoor air quality in schools and public buildings. Both bills reflect active support for local environmental quality and pollution reduction.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3447', 'https://malegislature.gov/Bills/194/H509']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian M. Ashe / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1e83f9fc-43c9-4568-937d-94383acdc117',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1e83f9fc-43c9-4568-937d-94383acdc117',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Ashe serves on the Joint Committee on Community Development and Small Businesses, placing him in a role that shapes economic development policy. His committee also covers Tourism, Arts and Cultural Development. His district-focused legislation (Longmeadow and Springfield area) addresses local community needs, suggesting a pragmatic centrist economic development approach balancing business support with community investment.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/BMA1/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician (should be 5 stances):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '1e83f9fc-43c9-4568-937d-94383acdc117';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '1e83f9fc-43c9-4568-937d-94383acdc117'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '1e83f9fc-43c9-4568-937d-94383acdc117'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
