-- ============================================================================
-- Migration 649: New Bedford At-Large Councillor Shane Burgo Stances
-- ============================================================================
-- Purpose: Insert/upsert compass stance data for New Bedford At-Large
-- City Councillor Shane Burgo.
--
-- Burgo is an At-Large councillor and 2025 Council President. He proposed
-- and championed a non-binding rent stabilization ballot question in 2023
-- and chaired the Special City Council Committee on Affordable Housing &
-- Homelessness. The city council also adopted MBTA Communities Act zoning.
--
-- Total rows: 2
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

-- Politician UUID reference:
-- Shane Burgo (At-Large)           4b0e72f4-15f8-495a-b90a-e5b8b987cd63

-- Topic UUID reference (inform.compass_topics):
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- rent-regulation                  c308e8e8-caac-44f5-ab04-dbfecf40bbe2
-- (all other topics: no individual evidence found — blank spokes per evidence-only rule)

BEGIN;

-- ----- Shane Burgo / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4b0e72f4-15f8-495a-b90a-e5b8b987cd63',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4b0e72f4-15f8-495a-b90a-e5b8b987cd63',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$The New Bedford City Council, including At-Large Councillor Burgo, approved Mayor Mitchell's MBTA Communities Act zoning proposal, which required New Bedford to adopt multi-family residential zoning overlays near commuter rail transit stations as a condition of state funding. WBSM reported in 2024 that the City Council Committee on Ordinances was set to take up Mitchell's zoning proposal and the city subsequently achieved compliance. This full-council action demonstrates support for transit-oriented housing density under the state's multi-family zoning mandate.$$,
        ARRAY['https://www.wbsm.com/new-bedford-city-council-mbta-communities-act/', 'https://www.mass.gov/guides/multi-family-zoning-requirement-for-mbta-communities']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Shane Burgo / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('4b0e72f4-15f8-495a-b90a-e5b8b987cd63',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('4b0e72f4-15f8-495a-b90a-e5b8b987cd63',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Burgo proposed and championed a non-binding rent stabilization ballot question that appeared on the November 2023 New Bedford municipal election ballot: "Should the City of New Bedford adopt an ordinance stabilizing rents, to prevent unreasonable rent increases?" The New Bedford City Council voted to approve this ballot question. Burgo argued on WBSM that "New Bedford residents should have a say in how the city should address unaffordable rents" and later chaired the Special City Council Committee on Affordable Housing & Homelessness. He also attempted to persuade residents in 2023 to back the rent stabilization referendum. This represents direct, individually-attributed advocacy for rent stabilization (value 2: support stabilization/light controls).$$,
        ARRAY['https://www.wbsm.com/what-a-massachusetts-landlord-can-charge-a-tenant/', 'https://www.wbsm.com/search/?s=burgo+rent+stabilization']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
