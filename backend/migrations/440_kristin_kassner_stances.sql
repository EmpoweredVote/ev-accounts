-- ============================================================================
-- Migration 440: Kristin Kassner Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Kristin Kassner (MA State Rep, HD-25,
--   2nd Essex District, Hamilton).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Politician UUID: 36343ab4-817f-44eb-9221-15eb338af57a (external_id=-210065)

BEGIN;

-- ----- Kristin Kassner / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36343ab4-817f-44eb-9221-15eb338af57a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36343ab4-817f-44eb-9221-15eb338af57a',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Kassner serves on the House Committee on Global Warming and Climate Change — a committee specifically focused on climate action — and the Joint Committee on Environment and Natural Resources. She also sponsored H.490 for a special commission relative to preparing the built environment for the next economy, including infrastructure and land use regulations, reflecting a climate adaptation and resilience focus for her coastal Essex district.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/K_K2/Committees', 'https://malegislature.gov/Bills/194/H490', 'https://actonmass.org/legislators/kristin-kassner/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kristin Kassner / local-environment -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36343ab4-817f-44eb-9221-15eb338af57a',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36343ab4-817f-44eb-9221-15eb338af57a',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Kassner sponsored H.975 restricting second-generation anticoagulant rodenticides in Newbury, H.976 relative to water supplies and the environment, H.977 on data collection for below-threshold wells, and H.1052 on wetlands restoration. Multiple local pesticide restriction bills reflect a strong local environmental protection stance for her North Shore Essex district, which includes sensitive coastal wetlands and water resources.$$,
        ARRAY['https://malegislature.gov/Bills/194/H975', 'https://malegislature.gov/Bills/194/H976', 'https://malegislature.gov/Bills/194/H977', 'https://malegislature.gov/Bills/194/H1052']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kristin Kassner / residential-zoning -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36343ab4-817f-44eb-9221-15eb338af57a',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36343ab4-817f-44eb-9221-15eb338af57a',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$Kassner sponsored five zoning-related bills: H.2298 on site plan zoning review, H.2299 on education for planning board members, H.2300 local option for associate planning board members, H.2301 on zoning voting thresholds, and H.2302 to expand designation of priority development sites. She also sponsored H.4163 to include accessory dwelling units (ADUs) in the subsidized housing inventory. This zoning reform package reflects a pro-reform approach to enable more housing through streamlined permitting.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2298', 'https://malegislature.gov/Bills/194/H2301', 'https://malegislature.gov/Bills/194/H4163', 'https://malegislature.gov/Bills/194/H2302']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kristin Kassner / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36343ab4-817f-44eb-9221-15eb338af57a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36343ab4-817f-44eb-9221-15eb338af57a',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Kassner sponsored H.4163 to include accessory dwelling units in the subsidized housing inventory — expanding what counts as affordable housing. She also sponsored H.1807 on foreclosure mediation to protect homeowners, and filed multiple zoning reform bills (H.2298-2302) designed to make it easier to build housing. Her approach focuses on expanding housing supply through zoning reform and protecting existing homeowners.$$,
        ARRAY['https://malegislature.gov/Bills/194/H4163', 'https://malegislature.gov/Bills/194/H1807', 'https://malegislature.gov/Bills/194/H2302']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Kristin Kassner / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('36343ab4-817f-44eb-9221-15eb338af57a',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('36343ab4-817f-44eb-9221-15eb338af57a',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Kassner co-sponsored Campaign Childcare legislation as tracked by Act on Mass, reflecting support for affordable and accessible childcare. She also serves on the Joint Committee on Public Health, which oversees early childhood health and wellness issues.$$,
        ARRAY['https://actonmass.org/legislators/kristin-kassner/', 'https://malegislature.gov/Legislators/Profile/K_K2/Committees']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '36343ab4-817f-44eb-9221-15eb338af57a';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '36343ab4-817f-44eb-9221-15eb338af57a'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '36343ab4-817f-44eb-9221-15eb338af57a'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
