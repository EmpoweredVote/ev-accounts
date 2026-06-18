-- ============================================================================
-- Migration 652: New Bedford At-Large Councillor James Roy Stances
-- ============================================================================
-- Purpose: Insert/upsert compass stance data for New Bedford At-Large
-- City Councillor James Roy.
--
-- Roy is a civics teacher and At-Large councillor first elected in 2019.
-- He won his initial election with "a big win" (WBSM, 2019). Individual
-- news coverage of his policy positions on compass topics is limited.
-- The MBTA Communities Act zoning vote is the only documented city-wide
-- action applicable to all council members with available evidence.
--
-- Total rows: 1
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

-- Politician UUID reference:
-- James Roy (At-Large)             73a11a8c-6b57-4803-b786-961e83705fd8

-- Topic UUID reference (inform.compass_topics):
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- (all other topics: no individual evidence found — blank spokes per evidence-only rule)

BEGIN;

-- ----- James Roy / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('73a11a8c-6b57-4803-b786-961e83705fd8',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('73a11a8c-6b57-4803-b786-961e83705fd8',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$The New Bedford City Council, including At-Large Councillor Roy, approved Mayor Mitchell's MBTA Communities Act zoning proposal, which required New Bedford to adopt multi-family residential zoning overlays near commuter rail transit stations as a condition of state funding. WBSM reported in 2024 that the City Council Committee on Ordinances was set to take up Mitchell's zoning proposal and the city subsequently achieved compliance. This full-council action demonstrates support for transit-oriented housing density under the state's multi-family zoning mandate.$$,
        ARRAY['https://www.wbsm.com/new-bedford-city-council-mbta-communities-act/', 'https://www.mass.gov/guides/multi-family-zoning-requirement-for-mbta-communities']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
