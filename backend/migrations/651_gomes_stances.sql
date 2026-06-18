-- ============================================================================
-- Migration 651: New Bedford At-Large Councillor Brian Gomes Stances
-- ============================================================================
-- Purpose: Insert/upsert compass stance data for New Bedford At-Large
-- City Councillor Brian Gomes.
--
-- Gomes is a long-serving At-Large councillor who chairs the City Council
-- Committee on Public Safety & Neighborhoods. He voted in favor of overriding
-- Mayor Mitchell's veto on nonbinding ballot questions including rent
-- stabilization, raised homelessness as a citywide concern, and voted for
-- the MBTA Communities Act zoning compliance.
--
-- Total rows: 2
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via psql.
-- ============================================================================

-- Politician UUID reference:
-- Brian Gomes (At-Large)           9a4c4152-70f4-4056-be19-9ff3236e060d

-- Topic UUID reference (inform.compass_topics):
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- rent-regulation                  c308e8e8-caac-44f5-ab04-dbfecf40bbe2
-- (all other topics: no individual evidence found — blank spokes per evidence-only rule)

BEGIN;

-- ----- Brian Gomes / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9a4c4152-70f4-4056-be19-9ff3236e060d',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9a4c4152-70f4-4056-be19-9ff3236e060d',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$The New Bedford City Council, including long-serving At-Large Councillor Gomes, approved Mayor Mitchell's MBTA Communities Act zoning proposal, which required New Bedford to adopt multi-family residential zoning overlays near commuter rail transit stations as a condition of state funding. WBSM reported in 2024 that the City Council Committee on Ordinances was set to take up Mitchell's zoning proposal and the city subsequently achieved compliance. This full-council action demonstrates support for transit-oriented housing density under the state's multi-family zoning mandate.$$,
        ARRAY['https://www.wbsm.com/new-bedford-city-council-mbta-communities-act/', 'https://www.mass.gov/guides/multi-family-zoning-requirement-for-mbta-communities']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Brian Gomes / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9a4c4152-70f4-4056-be19-9ff3236e060d',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9a4c4152-70f4-4056-be19-9ff3236e060d',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$WBSM reported that Gomes, along with Shane Burgo and Council President Linda Morad, voted in favor of overriding Mayor Mitchell's veto on nonbinding ballot questions that included rent stabilization. The rent stabilization ballot question was proposed by Councillor Burgo and asked New Bedford residents whether the city should adopt an ordinance stabilizing rents to prevent unreasonable rent increases. Gomes's vote to override the mayor's veto on this ballot question demonstrates support for letting voters decide on rent regulation. As longtime chair of the City Council Committee on Public Safety & Neighborhoods, Gomes has also addressed housing affordability through the referral of homelessness concerns to the Special Committee on Affordable Housing & Homelessness.$$,
        ARRAY['https://www.wbsm.com/new-bedford-city-council-favors-mayor-mitchells-ballot-question/', 'https://www.wbsm.com/new-bedford-city-council-oks-rent-stabilization-ballot-question/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
