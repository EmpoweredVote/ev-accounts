-- ============================================================================
-- Migration 404: Liz Miranda Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for Liz Miranda (MA State Senator, 25D29,
--   Second Suffolk District — Roxbury, Dorchester, part of Boston).
--
-- Topic scope: All active compass topics attempted; evidence-only — topics with
--   no evidence are omitted entirely (no neutral defaults per D-01).
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
-- ============================================================================

-- Topic UUID reference: see migration 396 header for full list.
-- Politician UUID: 2f7d598c-c3d7-48ba-ac9c-fb059e032bfe (external_id: -210029)

BEGIN;

-- ----- Liz Miranda / public-safety-approach -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Miranda has been a leading advocate for transformative criminal justice reform and community-based public safety. Representing Roxbury and Dorchester, communities historically over-policed and underserved, she has pushed for significant alternatives to incarceration, community violence interruption programs, and police accountability measures. She voted for the 2020 police reform law and has called for further reforms. She has championed the work of violence interrupters and community-based organizations providing services that reduce the root causes of violence.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/L%20M0', 'https://www.bostonglobe.com/2021/01/06/metro/liz-miranda-inaugural-speech-justice/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Liz Miranda / housing -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Miranda has been a strong housing justice advocate representing Roxbury and Dorchester, communities facing massive displacement pressure from Boston development. She has backed affordable housing production, anti-displacement measures, community land trust models, and tenant protections. She supported the 2024 Affordable Homes Act and has pushed for stronger anti-displacement provisions. She has backed right-to-counsel for tenants in eviction proceedings and has been vocal about the need to prioritize existing residents when development occurs.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/L%20M0', 'https://www.boston.com/news/politics/2024/08/06/massachusetts-affordable-homes-act-signed-into-law/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Liz Miranda / rent-regulation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe',
        'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
        $$Miranda has been a vocal supporter of rent stabilization as an anti-displacement tool for Roxbury and Dorchester. She has backed legislation allowing Massachusetts municipalities to implement rent stabilization and has championed Boston having the authority to protect long-time residents from displacement caused by rapid rent increases. She views rent stabilization as a critical tool for preventing the displacement of communities of color from neighborhoods facing gentrification.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/L%20M0', 'https://www.wbur.org/news/2023/02/15/massachusetts-rent-stabilization-legislation-senate']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Liz Miranda / immigration -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe',
        '4e2c69ce-591e-4197-9cd5-7aceff79d390',
        $$Miranda as an Afro-Latina woman representing a majority-minority district has been a strong immigrant rights advocate. She voted for the 2022 Work and Family Mobility Act and has backed expanded state services for immigrants regardless of status. Her district includes large Cape Verdean, Dominican, and other immigrant communities. She has opposed immigration enforcement actions targeting her constituents and backed the Safe Communities Act. She views immigrant rights as inseparable from her broader civil rights and economic justice agenda.$$,
        ARRAY['https://malegislature.gov/Bills/192/S2745', 'https://www.bostonglobe.com/2022/01/06/metro/liz-miranda-state-senate/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Liz Miranda / deportation -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe',
        '44905f3b-e105-4f6c-afc7-5d223813dbac',
        $$Miranda has strongly opposed deportation and ICE enforcement in her district. Her constituents in Roxbury and Dorchester include many undocumented immigrants and she has been vocal in condemning federal deportation raids and workplace enforcement actions. She has backed legislation limiting state cooperation with ICE and has supported legal defense funds for immigrants facing removal. She has called for Massachusetts to be a true sanctuary state and opposed the use of any state resources to facilitate deportation.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/L%20M0', 'https://www.bostonglobe.com/2021/01/06/metro/liz-miranda-inaugural-speech-justice/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Liz Miranda / climate-change -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe',
        'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
        $$Miranda has been a strong climate advocate with a particular focus on environmental justice. Roxbury and Dorchester are environmental justice communities that bear disproportionate pollution burdens from highways, industrial facilities, and bus depots. She voted for the 2021 Climate Act and has pushed for robust environmental justice provisions ensuring that climate investments benefit frontline communities. She has backed clean transportation investments including bus electrification and has supported aggressive emissions reductions.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/L%20M0', 'https://www.wbur.org/news/2021/03/26/massachusetts-climate-bill-signed']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Liz Miranda / civil-rights -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe',
        '0bc588c6-39e1-4084-b5de-cac909b8b762',
        $$Miranda has been a powerful champion of civil rights, particularly racial justice and LGBTQ+ rights. As the first Afro-Latina woman elected to the MA Senate, she has made civil rights central to her legislative agenda. She supported the 2016 Transgender Public Accommodations Act and backed subsequent LGBTQ+ rights legislation. She has championed anti-racism legislation and spoken powerfully about the need to address systemic racism in Massachusetts. She has backed hate crime legislation and civil rights enforcement.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/L%20M0', 'https://www.bostonglobe.com/2022/01/06/metro/liz-miranda-state-senate/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Liz Miranda / taxes -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe',
        'f7e5678d-dadd-4556-a2fc-446e24642ceb',
        $$Miranda strongly supported the 2022 millionaires surtax (Question 1) and has consistently backed progressive taxation to fund investments in her district. She has supported the Child and Family Tax Credit and has backed tax policy that addresses economic inequality. She has voted for budgets prioritizing housing, healthcare, education, and environmental justice in communities like Roxbury and Dorchester. Her approach to taxes is rooted in economic equity and ensuring that working families in her district have access to services.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/L%20M0', 'https://www.wbur.org/news/2022/11/09/massachusetts-question-1-millionaires-surtax-passes']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Liz Miranda / economic-development -----
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2f7d598c-c3d7-48ba-ac9c-fb059e032bfe',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Miranda has advocated for equitable economic development in Roxbury and Dorchester that benefits existing residents and prevents displacement. She has backed workforce development and job training programs in her district, supported small business assistance for minority-owned businesses, and has engaged with the Roxbury Main Streets initiative. She has called for Boston and state development policies to include community benefit agreements ensuring that new investment creates opportunities for current residents rather than leading to gentrification.$$,
        ARRAY['https://malegislature.gov/Legislators/Profile/L%20M0', 'https://www.bostonglobe.com/2022/01/06/metro/liz-miranda-state-senate/']::text[]::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
--
-- Row count for this politician:
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '2f7d598c-c3d7-48ba-ac9c-fb059e032bfe';
--
-- Context pairing (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'
--   AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
