-- ============================================================================
-- Migration 648: New Bedford At-Large Councillor Ian Abreu Stances
-- ============================================================================
-- Purpose: Insert/upsert compass stance data for New Bedford At-Large
-- City Councillor Ian Abreu.
--
-- Abreu is an At-Large councillor representing the Clark's Point (South End)
-- neighborhood. Individual news quotes and voting records are limited;
-- the MBTA Communities Act zoning vote is the only city-wide vote with
-- documented council approval applicable to all members.
--
-- Total rows: 1
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

-- Politician UUID reference:
-- Ian Abreu (At-Large)             f4eabcb1-33d0-4150-a2de-597014f1186b

-- Topic UUID reference (inform.compass_topics):
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- (all other topics: no individual evidence found — blank spokes per evidence-only rule)

BEGIN;

-- ----- Ian Abreu / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f4eabcb1-33d0-4150-a2de-597014f1186b',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f4eabcb1-33d0-4150-a2de-597014f1186b',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$The New Bedford City Council, including At-Large Councillor Abreu, approved Mayor Mitchell's MBTA Communities Act zoning proposal, which required New Bedford to adopt multi-family residential zoning overlays near commuter rail transit stations as a condition of state funding. WBSM reported in 2024 that the City Council Committee on Ordinances was set to take up Mitchell's zoning proposal and the city subsequently achieved compliance. This full-council action demonstrates support for transit-oriented housing density under the state's multi-family zoning mandate.$$,
        ARRAY['https://www.wbsm.com/new-bedford-city-council-mbta-communities-act/', 'https://www.mass.gov/guides/multi-family-zoning-requirement-for-mbta-communities']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
