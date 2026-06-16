-- ============================================================================
-- Migration 700: Liz Mullane Stances (Medford City Council, At-Large)
-- ============================================================================
-- Purpose: Insert/upsert stance data for Liz Mullane (At-Large City Councilor,
--   Medford MA). politician_id = '5846208f-d354-4e01-aa0c-4328574357f1'
--
-- Context: Migration 680 was applied as an honest-skip (no evidence found at
--   that time). Subsequent research in June 2026 found two real sourced URLs
--   — the Patch candidate profile (Oct 2025) and her campaign website
--   (liz4medford.com/platform) — with attributable policy positions on six topics.
--   This migration supersedes the honest-skip by inserting those stances.
--
-- Topic scope: 6 topics with direct sourced evidence. All other topics omitted
--   (no neutral defaults). Local/city-level topics prioritized given her role as
--   at-large city councilor.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
--
-- Sources used:
--   1. https://patch.com/massachusetts/medford/medford-candidate-profile-liz-mullane-city-council
--      (Oct 31, 2025 candidate profile — direct candidate quotes on housing, ICE, public safety)
--   2. https://liz4medford.com/platform
--      (Campaign platform page — detailed positions on housing, environment, transportation,
--       economic development, public safety, community services)
-- ============================================================================

-- Topic UUID reference (inform.compass_topics):
-- abortion                         af2fdfd6-02c4-49df-b09c-cf8536f4773f
-- ai-regulation                    666bf03d-81fc-4138-ab15-69ae734c9023
-- campaign-finance                 92730f69-ae57-401c-8ad1-2d07834a895d
-- childcare                        c1ac1330-47f7-44ec-baf3-c913d926b97c
-- city-sanitation                  7687de4f-4d0b-462a-b803-bdfb23b16b42
-- civil-rights                     0bc588c6-39e1-4084-b5de-cac909b8b762
-- climate-change                   f1e44d66-5d27-4b51-b54f-b7ace86f6a3c
-- deportation                      44905f3b-e105-4f6c-afc7-5d223813dbac
-- economic-development             eb3d1247-0de1-4b7f-baec-7259861efd53
-- fossil-fuels                     a22215c3-6693-4bc2-b248-01aebba14570
-- growth-and-development           fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4
-- healthcare                       e8dad4a8-eb93-4931-91f5-d8fb5d7dd529
-- homelessness                     4938766b-b45a-46e3-93bd-b8b30651271a
-- homelessness-response            6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- immigration                      4e2c69ce-591e-4197-9cd5-7aceff79d390
-- jail-capacity                    c267e137-0ff9-4e7d-9d13-e3cea1756cd0
-- local-environment                1935979c-b290-42e4-baa5-8cb0138b4ffa
-- local-immigration                b9ccee94-ad96-4f10-b655-889d8e5abe92
-- medicare/aid                     cab61e8a-64fe-4bbd-bc08-fe9914d0091b
-- misinformation                   ddd65d64-9dc7-4208-a30f-59f4b9c0653d
-- public-safety-approach           e9ebefcd-c496-45e8-b816-a79f8442ba85
-- redistricting                    48cc9585-ec22-4f53-8d42-6839828dd36f
-- rent-regulation                  c308e8e8-caac-44f5-ab04-dbfecf40bbe2
-- residential-zoning               d4f18138-a2e0-4110-b925-7387d9d0d16d
-- same-sex-marriage                c5ab4eab-702f-49b8-9277-8ea53f3835c6
-- school-vouchers                  00b95a6a-75db-4521-b523-3326bba938de
-- social-security                  87d20824-a6e9-407b-983c-65440084a0ab
-- tariffs                          683c8084-2281-4920-a07c-18439b2dd413
-- taxes                            f7e5678d-dadd-4556-a2fc-446e24642ceb
-- trans-athletes                   d1618b9c-0b9e-45af-b986-bb33d270b8e4
-- transportation-priorities        ba59337e-30e2-4aba-a39a-426b3366eb27
-- ukraine-support                  24e9212c-b011-422a-865c-093e35050901
-- voting-rights                    d1792200-1d3b-4955-a0b7-0e6980d7a7b2

BEGIN;

-- ============================================================
-- Liz Mullane — 6 sourced stances
-- ============================================================

-- ----- Liz Mullane / housing -----
-- Value 2: "Use rent caps, require new developments to include affordable units, and publicly fund new housing"
-- Mullane explicitly supports the Affordable Housing Trust and Housing Buy-Down program
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5846208f-d354-4e01-aa0c-4328574357f1',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5846208f-d354-4e01-aa0c-4328574357f1',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$Mullane's campaign platform explicitly prioritizes housing affordability as a core issue. On her campaign website she states: "Whether you rent or own in Medford, it is far too difficult to find affordable housing in our community." Her platform calls for "Supporting increased funding for the Affordable Housing Trust" and "Working with the Planning, Development and Sustainability Department to further develop the Housing Buy-Down program." In her Patch candidate profile she noted she "watched our young neighbors move out who wanted to stay in Medford but were unable to due to housing affordability issues." This reflects a publicly-funded subsidy approach (value 2) rather than market-only approaches.$$,
        ARRAY['https://liz4medford.com/platform', 'https://patch.com/massachusetts/medford/medford-candidate-profile-liz-mullane-city-council']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Liz Mullane / local-immigration -----
-- Value 2: "Comply only with court-ordered detainers; protect undocumented crime victims and witnesses from referral"
-- Mullane's direct quote: "I would stand up for our community members against ICE and ensure that all our residents feel safe and heard."
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5846208f-d354-4e01-aa0c-4328574357f1',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5846208f-d354-4e01-aa0c-4328574357f1',
        'b9ccee94-ad96-4f10-b655-889d8e5abe92',
        $$In her Patch candidate profile (Oct 2025), Mullane directly stated: "I would stand up for our community members against ICE and ensure that all our residents feel safe and heard." This is an explicit commitment to protecting undocumented residents from ICE enforcement operations — consistent with sanctuary-city principles and compliance with court orders only, not proactive federal cooperation.$$,
        ARRAY['https://patch.com/massachusetts/medford/medford-candidate-profile-liz-mullane-city-council']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Liz Mullane / local-environment -----
-- Value 2: "Protect existing parks and tree canopy strictly; require developers to fully offset any environmental impact"
-- Platform includes expanding recycling, solar, EV charging stations, and supporting conservation efforts
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5846208f-d354-4e01-aa0c-4328574357f1',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5846208f-d354-4e01-aa0c-4328574357f1',
        '1935979c-b290-42e4-baa5-8cb0138b4ffa',
        $$Mullane's campaign platform includes a "Supporting a Greener Medford" plank that calls for expanding recycling, solar usage, electric vehicle charging stations, bike lanes and bike parking, and supporting the Community Preservation Committee's focus on open and walkable spaces. She states "Our green space is our treasure — and all residents deserve to enjoy our outdoors easily, safely, and comfortably." This reflects a strong environmental protection posture with active city investment.$$,
        ARRAY['https://liz4medford.com/platform']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Liz Mullane / transportation-priorities -----
-- Value 2: "Invest equally in roads and multimodal options; require bike lanes and sidewalks on all new road projects"
-- Platform explicitly calls for pedestrian safety audit, crosswalk restoration, protecting bike lanes
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5846208f-d354-4e01-aa0c-4328574357f1',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        2.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5846208f-d354-4e01-aa0c-4328574357f1',
        'ba59337e-30e2-4aba-a39a-426b3366eb27',
        $$Mullane's "Safer Streets and Improved Infrastructure" platform plank focuses on multimodal improvements: "Championing for a pedestrian safety audit with WalkMassachusetts to identify high incident areas and begin to address specific needs at busiest streets and intersections; Assisting in allocating more funding for repairing potholes, impassable sidewalks and roads in worst condition; Protecting bike lanes and identifying additional bike parking throughout the city." This reflects equal investment in multimodal options alongside road maintenance. In her Patch profile she also cites living near the Fellsway and observing how "difficult it is for pedestrians to cross our roads safely."$$,
        ARRAY['https://liz4medford.com/platform', 'https://patch.com/massachusetts/medford/medford-candidate-profile-liz-mullane-city-council']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Liz Mullane / public-safety-approach -----
-- Value 3: "Keep current public safety funding while adding crisis response teams for mental health and addiction calls"
-- Supports unarmed mental health first responders but not police defunding
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5846208f-d354-4e01-aa0c-4328574357f1',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5846208f-d354-4e01-aa0c-4328574357f1',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$Mullane's platform includes "Expanding our community's mental health support and services, including unarmed mental health first responders" as part of her schools and community services section. This reflects a center approach: adding specialized crisis response capacity without calling for police budget reductions. There is no statement opposing police funding — suggesting she supports maintaining current police staffing while adding mental health co-responders.$$,
        ARRAY['https://liz4medford.com/platform']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Liz Mullane / economic-development -----
-- Value 3: "Targeted incentives for specific industries with community benefit agreements and job quality requirements"
-- Supports small business incentives and streamlining permitting, explicitly not large corporate subsidies
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5846208f-d354-4e01-aa0c-4328574357f1',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5846208f-d354-4e01-aa0c-4328574357f1',
        'eb3d1247-0de1-4b7f-baec-7259861efd53',
        $$Mullane's platform calls for "Championing for more vibrant squares and commercial districts through supporting our small businesses, incentives for small businesses, and streamlining the permitting process." She specifically targets small businesses and nonprofits: "identifying incentives that can make Medford a more affordable option for businesses." Her Patch profile also notes: "I would focus on building our commercial tax base by streamlining the process for more small businesses and nonprofits to enter Medford, as well as identifying incentives that can make Medford a more affordable option for businesses." This is a small-business-targeted incentive approach rather than large corporate subsidy competition.$$,
        ARRAY['https://liz4medford.com/platform', 'https://patch.com/massachusetts/medford/medford-candidate-profile-liz-mullane-city-council']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- Row count (must be >= 6):
-- SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id = '5846208f-d354-4e01-aa0c-4328574357f1';
--
-- Unpaired check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id = '5846208f-d354-4e01-aa0c-4328574357f1' AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id = '5846208f-d354-4e01-aa0c-4328574357f1'
--   AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
