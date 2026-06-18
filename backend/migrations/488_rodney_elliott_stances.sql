-- ============================================================================
-- Migration 488: Rodney M. Elliott Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Rodney M. Elliott (MA House HD-73,
--   16th Middlesex District). External ID: -210113.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

BEGIN;

-- Rodney M. Elliott (HD-73, external_id=-210113)
-- Politician UUID: 751464b8-069c-4a7e-b21b-06d36c338060

-- ----- Rodney M. Elliott / childcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('751464b8-069c-4a7e-b21b-06d36c338060',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('751464b8-069c-4a7e-b21b-06d36c338060',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Elliott co-sponsored the Cherish Act (H.1260 / S.816) for fully-funded public higher education and serves on the Joint Committee on Higher Education. These roles reflect support for publicly-funded education access.$$,
        ARRAY['https://actonmass.org/bills/cherish-act-fully-funded-public-higher-ed/', 'https://malegislature.gov/Legislators/Profile/RME1/Committees'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rodney M. Elliott / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('751464b8-069c-4a7e-b21b-06d36c338060',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('751464b8-069c-4a7e-b21b-06d36c338060',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Elliott co-sponsored the Climate Superfund Act (H.872 / S.481) and Polluter Pays bill, which would require large fossil fuel companies to pay for climate-related damages in Massachusetts. These co-sponsorships reflect a pro-climate-action legislative stance.$$,
        ARRAY['https://actonmass.org/bills/climate-superfund/', 'https://actonmass.org/bills/polluter-pays/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rodney M. Elliott / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('751464b8-069c-4a7e-b21b-06d36c338060',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('751464b8-069c-4a7e-b21b-06d36c338060',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Elliott co-sponsored the Stop Wage Theft bill (H.1868 / S.1158), the Right to Strike bill (H.1845 / S.1217), and the Stop Corporate Offshoring bill. These three co-sponsorships reflect consistent support for worker-protective economic policies and opposition to practices that disadvantage workers.$$,
        ARRAY['https://actonmass.org/bills/stop-wage-theft/', 'https://actonmass.org/bills/the-right-to-strike/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rodney M. Elliott / fossil-fuels -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('751464b8-069c-4a7e-b21b-06d36c338060',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('751464b8-069c-4a7e-b21b-06d36c338060',
        'a22215c3-6693-4bc2-b248-01aebba14570',
        $$Elliott co-sponsored the Climate Superfund Act and Polluter Pays bill — both of which hold large fossil fuel companies financially responsible for climate damage in Massachusetts. His co-sponsorship of these bills placing liability on fossil fuel producers reflects opposition to continued fossil fuel industry expansion.$$,
        ARRAY['https://actonmass.org/bills/climate-superfund/', 'https://actonmass.org/bills/polluter-pays/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rodney M. Elliott / healthcare -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('751464b8-069c-4a7e-b21b-06d36c338060',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('751464b8-069c-4a7e-b21b-06d36c338060',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Elliott filed H.1148 (acupuncture practice regulation), H.1149 (dental CBCT scan coverage), and co-sponsored the THRIVE Act for comprehensive healthcare access. These bills reflect support for expanded healthcare coverage and access to alternative treatments.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1148', 'https://malegislature.gov/Bills/194/H1149', 'https://actonmass.org/legislators/rodney-elliott/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Rodney M. Elliott / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('751464b8-069c-4a7e-b21b-06d36c338060',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('751464b8-069c-4a7e-b21b-06d36c338060',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Elliott filed H.1500, "An Act addressing affordable housing," which would strengthen affordable housing programs in Massachusetts. This bill directly reflects support for affordable housing access.$$,
        ARRAY['https://malegislature.gov/Bills/194/H1500'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count (should be 6):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '751464b8-069c-4a7e-b21b-06d36c338060';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '751464b8-069c-4a7e-b21b-06d36c338060'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '751464b8-069c-4a7e-b21b-06d36c338060'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
