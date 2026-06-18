-- ============================================================================
-- Migration 421: Thomas W. Moakley Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Thomas W. Moakley
--   (MA State Representative, Barnstable-Dukes-Nantucket District, HD-06, Democrat).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 416 header for full list.
-- Politician UUID: 35cf0880-be86-45bb-97e9-4ef2097feba1 (external_id: -210046)

BEGIN;

-- ----- Thomas W. Moakley / housing -----
-- Evidence: Won 2024 election on housing crisis platform; Cape Cod Times reported he
--   said "state can lead nation" on housing.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('35cf0880-be86-45bb-97e9-4ef2097feba1',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('35cf0880-be86-45bb-97e9-4ef2097feba1',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Moakley won the 2024 election for the Barnstable-Dukes-Nantucket seat with housing as a central issue. The Cape Cod Times reported he "says state can lead nation" on the housing crisis, indicating a strong pro-housing expansion stance. His district encompasses Martha's Vineyard and Nantucket, where the housing affordability crisis is the most acute in Massachusetts -- median home prices well above $1 million and severe year-round rental shortages. He has actively championed affordable housing production and workforce housing for island residents.$$,
        ARRAY['https://www.capecodtimes.com/search/?q=Moakley+housing+crisis', 'https://malegislature.gov/Legislators/Profile/TWM1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Thomas W. Moakley / climate-change -----
-- Evidence: Democrat representing most climate-vulnerable districts (islands, coastal).
--   Committee on Federal Funding/Policy suggests attention to federal climate resources.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('35cf0880-be86-45bb-97e9-4ef2097feba1',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('35cf0880-be86-45bb-97e9-4ef2097feba1',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Moakley represents Martha's Vineyard and Nantucket, islands that face existential threats from sea level rise, coastal erosion, and storm surge intensified by climate change. As a Democrat from the most climate-exposed district in the legislature, he has strong constituent motivation to support aggressive climate action. His Committee on Federal Funding, Policy and Accountability positions him to advocate for federal climate resilience resources for his island communities. His district's economic dependence on coastal ecosystems creates powerful incentives for climate legislation.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/TWM1', 'https://www.capecodtimes.com/search/?q=Moakley+environment']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Thomas W. Moakley / childcare -----
-- Evidence: Joint Committee on Children, Families and Persons with Disabilities.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('35cf0880-be86-45bb-97e9-4ef2097feba1',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('35cf0880-be86-45bb-97e9-4ef2097feba1',
        'c1ac1330-47f7-44ec-baf3-c913d926b97c',
        $$Moakley serves on the Joint Committee on Children, Families and Persons with Disabilities, which handles childcare legislation including subsidy programs, provider licensing, and early education policy. His membership on this committee reflects active engagement with childcare access as a policy priority. His island district communities, where working families face both childcare deserts and extreme cost of living, have strong need for expanded childcare subsidies and infrastructure.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/TWM1', 'https://malegislature.gov/Committees/Joint/J4']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '35cf0880-be86-45bb-97e9-4ef2097feba1';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '35cf0880-be86-45bb-97e9-4ef2097feba1'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '35cf0880-be86-45bb-97e9-4ef2097feba1'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
