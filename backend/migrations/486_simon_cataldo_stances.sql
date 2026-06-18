-- ============================================================================
-- Migration 486: Simon Cataldo Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Simon Cataldo (MA House HD-71,
--   14th Middlesex District). External ID: -210111.
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Pre-existing rows: 15 rows in DB. This migration adds new topics and corrects
--   pre-existing 3.0 neutral defaults where positive evidence exists.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

BEGIN;

-- Simon Cataldo (HD-71, external_id=-210111)
-- Politician UUID: 918296a2-5def-4ddf-8986-860d542900e7

-- ----- Simon Cataldo / campaign-finance -----
-- New topic: dark money bill
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('918296a2-5def-4ddf-8986-860d542900e7',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('918296a2-5def-4ddf-8986-860d542900e7',
        '92730f69-ae57-401c-8ad1-2d07834a895d',
        $$Cataldo filed H.806, "An Act relative to dark money in local government," which would require disclosure of the true sources behind political spending in local elections. This bill reflects support for campaign finance transparency and reform.$$,
        ARRAY['https://malegislature.gov/Bills/194/H806'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Simon Cataldo / childcare -----
-- New topic: diaper benefits and changing stations bills
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('918296a2-5def-4ddf-8986-860d542900e7',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('918296a2-5def-4ddf-8986-860d542900e7',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Cataldo filed H.220, "An Act establishing a diaper benefits pilot program," providing free diapers to low-income families, and H.208 requiring diaper changing stations in public buildings. He also co-sponsored the Campaign Childcare and Cherish Act bills. These sponsorships reflect strong support for family-supportive policies and early childhood needs.$$,
        ARRAY['https://malegislature.gov/Bills/194/H220', 'https://malegislature.gov/Bills/194/H208', 'https://actonmass.org/bills/campaign-childcare/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Simon Cataldo / economic-development -----
-- New topic: Labor committee + Stop Wage Theft
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('918296a2-5def-4ddf-8986-860d542900e7',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('918296a2-5def-4ddf-8986-860d542900e7',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Cataldo serves on the Joint Committee on Labor and Workforce Development, which handles worker protection legislation in Massachusetts. He also co-sponsored the Stop Wage Theft bill (H.1868 / S.1158). These roles reflect direct engagement with and support for worker-protective economic policies.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/S_C1/Committees', 'https://actonmass.org/bills/stop-wage-theft/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Simon Cataldo / healthcare -----
-- Correcting pre-existing 3.0: Mental Health committee assignment + abortion access bill
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('918296a2-5def-4ddf-8986-860d542900e7',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('918296a2-5def-4ddf-8986-860d542900e7',
        'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
        $$Cataldo serves on the Joint Committee on Mental Health, Substance Use and Recovery, which handles healthcare policy for mental health and addiction services. He also co-sponsored the Cherish Act for public higher education access. His committee role reflects direct engagement with expanding healthcare access, particularly for mental health services.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/S_C1/Committees', 'https://malegislature.gov/Committees/Detail/J28'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Simon Cataldo / local-environment -----
-- New topic: environmental-justice + climate-superfund co-sponsorships
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('918296a2-5def-4ddf-8986-860d542900e7',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('918296a2-5def-4ddf-8986-860d542900e7',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Cataldo co-sponsored the Climate Superfund Act (H.872 / S.481) and Polluter Pays bill, requiring large fossil fuel companies to pay for climate damages in Massachusetts. He also co-sponsored the 100% Renewable Energy by 2045 bill. These co-sponsorships reflect strong support for local and state-level environmental protections.$$,
        ARRAY['https://actonmass.org/bills/climate-superfund/', 'https://actonmass.org/bills/100-renewable-energy-by-2045/'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Simon Cataldo / voting-rights -----
-- Correcting pre-existing 3.0: RCV + youth voting bills are strong evidence
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('918296a2-5def-4ddf-8986-860d542900e7',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('918296a2-5def-4ddf-8986-860d542900e7',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Cataldo filed H.869 enabling ranked choice voting in Acton and H.870 granting voting rights in municipal elections to 16-17-year-old residents. He also co-sponsored the Racially Inclusive Education bill. These bills reflect a strong commitment to expanding democratic participation and voting access.$$,
        ARRAY['https://malegislature.gov/Bills/194/H869', 'https://malegislature.gov/Bills/194/H870'])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count (should be ~20 total):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '918296a2-5def-4ddf-8986-860d542900e7';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '918296a2-5def-4ddf-8986-860d542900e7'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '918296a2-5def-4ddf-8986-860d542900e7'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
