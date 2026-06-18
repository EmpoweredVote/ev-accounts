-- ============================================================================
-- Migration 455: Frank A. Moran Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Frank A. Moran (MA State Rep, HD-40,
--   17th Essex District, Lawrence).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql CLI with DATABASE_URL.
-- ============================================================================

-- Politician UUID: 5729a0a4-40a9-41bd-82a4-9a0bea757567 (external_id=-210080)

BEGIN;

-- ----- Frank A. Moran / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5729a0a4-40a9-41bd-82a4-9a0bea757567',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5729a0a4-40a9-41bd-82a4-9a0bea757567',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Moran co-sponsored the Safe Communities Act as tracked by Act on Mass (green checkmark), the Massachusetts sanctuary bill limiting local law enforcement from assisting with federal immigration enforcement. He also sponsored H.1954 to ensure equitable representation in immigration proceedings — protecting immigrants' access to legal counsel. Representing Lawrence — one of the most immigrant-dense cities in Massachusetts — these bills reflect his core constituency's needs.$$,
        ARRAY['https://actonmass.org/legislators/frank-moran/', 'https://malegislature.gov/Bills/194/H1954']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Frank A. Moran / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5729a0a4-40a9-41bd-82a4-9a0bea757567',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5729a0a4-40a9-41bd-82a4-9a0bea757567',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Moran co-sponsored LGBTQ+ Rights legislation (Act on Mass green checkmark) and sponsored H.650 to affirm and maintain equal access to public education for all students — a civil rights bill protecting educational access regardless of background. He also sponsored a suite of criminal justice reform bills: H.1897 (community corrections), H.1899 (educational programming for incarcerated emerging adults), H.1900 (prevent mandatory minimums based on juvenile adjudications), and H.820 (voting accessibility for people with disabilities).$$,
        ARRAY['https://actonmass.org/legislators/frank-moran/', 'https://malegislature.gov/Bills/194/H650', 'https://malegislature.gov/Bills/194/H1899', 'https://malegislature.gov/Bills/194/H820']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Frank A. Moran / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5729a0a4-40a9-41bd-82a4-9a0bea757567',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5729a0a4-40a9-41bd-82a4-9a0bea757567',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Moran sponsored H.274 to establish a bill of rights for individuals experiencing homelessness — a comprehensive set of legal protections for unhoused people in Massachusetts, covering shelter access, anti-discrimination, and due process rights. He also sponsored H.1901 on protecting titles to real estate and H.1898 on clearing titles to real property. His homelessness bill of rights reflects strong advocacy for housing security and anti-displacement for Lawrence's vulnerable residents.$$,
        ARRAY['https://malegislature.gov/Bills/194/H274', 'https://malegislature.gov/Bills/194/H1901']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Frank A. Moran / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5729a0a4-40a9-41bd-82a4-9a0bea757567',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5729a0a4-40a9-41bd-82a4-9a0bea757567',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Moran sponsored a cluster of gas infrastructure reform bills: H.3530 (safety and transparency in pipeline repair), H.3531 (natural gas workforce safety), H.3533 (field safety in gas infrastructure), and H.3534 (electric ratepayer protections). These bills focus on making fossil fuel infrastructure safer and more accountable rather than ending it — reflecting a reform and worker safety orientation rather than outright anti-fossil position. He also sponsored H.3532 on renewable energy production technologies, signaling support for the transition.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3530', 'https://malegislature.gov/Bills/194/H3531', 'https://malegislature.gov/Bills/194/H3532', 'https://malegislature.gov/Bills/194/H3534']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Frank A. Moran / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5729a0a4-40a9-41bd-82a4-9a0bea757567',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5729a0a4-40a9-41bd-82a4-9a0bea757567',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Moran sponsored H.3532 to support renewable energy production technologies in Massachusetts. Combined with his ratepayer protection bill H.3534 (protecting electricity customers from subsidizing gas infrastructure) and his pipeline reform bills, his legislative portfolio reflects support for the clean energy transition while also ensuring worker safety in the gas sector transition.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3532', 'https://malegislature.gov/Bills/194/H3534']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Frank A. Moran / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5729a0a4-40a9-41bd-82a4-9a0bea757567',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5729a0a4-40a9-41bd-82a4-9a0bea757567',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Moran co-sponsored the THRIVE Act (Act on Mass green checkmark), a bill expanding public health and social support services. He sponsored H.1392 to preserve and protect public health, H.652 for diabetes management in schools, and H.3196 to reform the healthcare cost benchmark. These bills reflect a multi-dimensional healthcare priority covering preventive care, school health access, and cost control for his Lawrence district.$$,
        ARRAY['https://actonmass.org/legislators/frank-moran/', 'https://malegislature.gov/Bills/194/H1392', 'https://malegislature.gov/Bills/194/H652', 'https://malegislature.gov/Bills/194/H3196']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Frank A. Moran / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5729a0a4-40a9-41bd-82a4-9a0bea757567',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5729a0a4-40a9-41bd-82a4-9a0bea757567',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Moran sponsored H.2108 establishing fairness for agricultural laborers in Massachusetts and H.3107 providing overtime pay for agricultural laborers — both directly protecting the wages and working conditions of farm workers, many of whom are immigrants in Essex County. He also sponsored H.651 to improve access, opportunity, and capacity in vocational-technical education for workforce development. These bills reflect a strong worker rights and workforce pipeline economic development stance.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2108', 'https://malegislature.gov/Bills/194/H3107', 'https://malegislature.gov/Bills/194/H651']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Frank A. Moran / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5729a0a4-40a9-41bd-82a4-9a0bea757567',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5729a0a4-40a9-41bd-82a4-9a0bea757567',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Moran sponsored H.3197 to ensure the sustainability of the family child care sector in Massachusetts — a bill to provide support and funding for family-based child care providers who serve working families. This is a direct investment in the childcare supply and workforce for his Lawrence district, which has a high proportion of working parents needing affordable childcare.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3197', 'https://malegislature.gov/Legislators/Profile/FAM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Frank A. Moran / voting-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5729a0a4-40a9-41bd-82a4-9a0bea757567',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5729a0a4-40a9-41bd-82a4-9a0bea757567',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Moran sponsored H.3744 to establish free access to ride-sharing transportation to elections (FARE Act) — removing transportation as a barrier to voting for low-income residents. He also sponsored H.820 to enforce accessibility for voters with disabilities. These two voting access bills reflect a strong pro-voting-rights stance focused on removing practical barriers to ballot access for Lawrence's underserved communities.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3744', 'https://malegislature.gov/Bills/194/H820']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '5729a0a4-40a9-41bd-82a4-9a0bea757567';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '5729a0a4-40a9-41bd-82a4-9a0bea757567'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '5729a0a4-40a9-41bd-82a4-9a0bea757567'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
