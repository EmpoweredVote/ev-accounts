-- ============================================================================
-- Migration 418: David T. Vieira Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for David T. Vieira
--   (MA State Representative, 3rd Barnstable District, HD-03, Republican).
--
-- Topic scope: All active compass topics attempted; evidence-only -- topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 416 header for full list.
-- Politician UUID: 35f10acb-fe09-40eb-a847-195fffee6f25 (external_id: -210043)

BEGIN;

-- ----- David T. Vieira / abortion -----
-- Evidence: Did not co-sponsor Abortion Access Act. Sponsored H.2560 to regulate
--   birth certificate changes (associated with restricting gender-related legal changes).
--   Republican Third Assistant Minority Leader.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('35f10acb-fe09-40eb-a847-195fffee6f25',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('35f10acb-fe09-40eb-a847-195fffee6f25',
        'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
        $$Vieira did not co-sponsor the Abortion Access Act. He sponsored H.2560 to regulate changes to birth certificates, a bill associated with restricting gender-related legal changes, suggesting socially conservative instincts. He serves as Third Assistant Minority Leader in the Republican caucus, a leadership role that aligns with party positions skeptical of expanded abortion access. His record shows no evidence of support for abortion access expansion.$$,
        ARRAY['https://actonmass.org/legislators/david-vieira/', 'https://malegislature.gov/Legislators/Profile/DTV1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David T. Vieira / taxes -----
-- Evidence: Republican who declined all progressive revenue bills. Sponsored H.4082
--   (refundable Title 5 septic tax credit), preferring targeted relief over tax increases.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('35f10acb-fe09-40eb-a847-195fffee6f25',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('35f10acb-fe09-40eb-a847-195fffee6f25',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Vieira declined all progressive revenue bills tracked by Act on Mass, including Stop Corporate Offshoring. He sponsored H.4082 (refundable Title 5 septic tax credit), reflecting a preference for targeted tax relief rather than broad tax increases. As a Republican Third Assistant Minority Leader, he consistently opposes tax hikes and progressive revenue measures. His record indicates a low-tax, tax-relief-focused approach consistent with Republican fiscal positions.$$,
        ARRAY['https://actonmass.org/legislators/david-vieira/', 'https://malegislature.gov/Legislators/Profile/DTV1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David T. Vieira / immigration -----
-- Evidence: Did not co-sponsor Safe Communities Act. Republican caucus leadership.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('35f10acb-fe09-40eb-a847-195fffee6f25',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('35f10acb-fe09-40eb-a847-195fffee6f25',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Vieira did not co-sponsor the Safe Communities Act or any progressive immigration legislation. As Republican Third Assistant Minority Leader, he declines all progressive immigration bills. He sponsored H.3842 (election integrity resolution), suggesting conservative instincts around immigration-adjacent issues. His party position and bill declinations indicate a more restrictive approach to immigration policy.$$,
        ARRAY['https://actonmass.org/legislators/david-vieira/', 'https://malegislature.gov/Legislators/Profile/DTV1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David T. Vieira / trans-athletes -----
-- Evidence: Sponsored H.2560 regulating birth certificate changes. Republican caucus leadership.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('35f10acb-fe09-40eb-a847-195fffee6f25',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('35f10acb-fe09-40eb-a847-195fffee6f25',
        'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
        $$Vieira sponsored H.2560 to regulate changes to birth certificates, a bill associated with restricting gender marker changes. He did not co-sponsor the Healthy Youth Act. As Republican Third Assistant Minority Leader who declines all LGBTQ+ rights legislation, his sponsorship of H.2560 indicates support for requiring athletes to compete based on birth-assigned sex rather than gender identity. This aligns with his socially conservative Republican positioning.$$,
        ARRAY['https://malegislature.gov/Bills/194/H2560', 'https://actonmass.org/legislators/david-vieira/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David T. Vieira / voting-rights -----
-- Evidence: Sponsored H.3842 (election integrity resolution). Did not co-sponsor Voting Rights Restoration.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('35f10acb-fe09-40eb-a847-195fffee6f25',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('35f10acb-fe09-40eb-a847-195fffee6f25',
        'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
        $$Vieira sponsored H.3842 (election integrity resolution) and did not co-sponsor the Voting Rights Restoration Act. His election integrity focus aligns with stricter election requirements rather than expanding voting access. As Republican Third Assistant Minority Leader, he has consistently declined to co-sponsor voting expansion legislation. His bill sponsorship record reflects prioritizing election integrity over access expansion.$$,
        ARRAY['https://malegislature.gov/Bills/194/H3842', 'https://actonmass.org/legislators/david-vieira/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David T. Vieira / housing -----
-- Evidence: Sponsored H.313 (smart growth/starter homes) and H.3931 (Falmouth affordable housing fee).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('35f10acb-fe09-40eb-a847-195fffee6f25',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('35f10acb-fe09-40eb-a847-195fffee6f25',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Vieira sponsored H.313 (smart growth and starter home zoning) and H.3931 (Falmouth real estate transfer fee for affordable housing), showing moderate support for housing access through market-compatible tools. He did not co-sponsor Lift the Ban on Local Tenant Protections (a rent control bill). His approach reflects a market-oriented housing position -- support for increasing supply and targeted affordable housing tools rather than rent control or aggressive public intervention.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/DTV1', 'https://malegislature.gov/Bills/194/H3931']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David T. Vieira / climate-change -----
-- Evidence: Did not co-sponsor 100% Renewable by 2045. Sponsored local base environment bill.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('35f10acb-fe09-40eb-a847-195fffee6f25',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('35f10acb-fe09-40eb-a847-195fffee6f25',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Vieira did not co-sponsor the 100% Renewable Energy by 2045 bill or Environmental Justice legislation. He did sponsor H.1063 on environmental protection at Joint Base Cape Cod, showing local environmental concern without endorsing aggressive climate policy. His pragmatic approach -- local Cape Cod environmental issues yes, state-wide climate mandates no -- reflects a moderate Republican position that distinguishes local environmental quality from statewide climate regulation.$$,
        ARRAY['https://actonmass.org/legislators/david-vieira/', 'https://malegislature.gov/Legislators/Profile/DTV1']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- David T. Vieira / local-immigration -----
-- Evidence: Did not co-sponsor Safe Communities Act. Republican caucus leadership.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('35f10acb-fe09-40eb-a847-195fffee6f25',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('35f10acb-fe09-40eb-a847-195fffee6f25',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$Vieira declined to co-sponsor the Safe Communities Act, the principal sanctuary city/non-cooperation bill in Massachusetts. His Republican caucus leadership position and election integrity bill (H.3842) align with stricter local immigration enforcement cooperation. No evidence of support for sanctuary protections or local policies shielding undocumented immigrants from federal enforcement.$$,
        ARRAY['https://actonmass.org/legislators/david-vieira/', 'https://malegislature.gov/Bills/194/H3842']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '35f10acb-fe09-40eb-a847-195fffee6f25';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '35f10acb-fe09-40eb-a847-195fffee6f25'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '35f10acb-fe09-40eb-a847-195fffee6f25'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
