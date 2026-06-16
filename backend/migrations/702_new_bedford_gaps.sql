-- ============================================================================
-- Migration 702: New Bedford Gap-Fill Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for 3 New Bedford City Council members
--   who had zero rows in inform.politician_answers as of June 2026.
--   This migration supersedes prior honest-skip migrations 654 (Pemberton),
--   656 (Baptiste), and 657 (Lopes), which recorded no inserts because the
--   NB Light parking-minimums article and candidate interview pages had not
--   yet been consulted. Migrations 654/656/657 remain in sequence as historical
--   records; this migration (702) adds the stances discovered in June 2026.
--
-- Officials covered:
--   Derek Baptiste  (Ward 4)  93d505e0-01b6-412c-9e07-4c491bdab866  → 1 stance
--   Joseph Lopes    (Ward 5)  122c551d-7d99-496c-b3ce-62a5117bc0ab  → 2 stances
--   Scott Pemberton (Ward 2)  6b22e04a-a302-4de6-b13f-9d1f6ec8e6b4  → honest-skip
--
-- Geo scope: New Bedford city council, geo_id = '2545000' (LOCAL district)
-- No stances for the 9 already-covered NB officials are modified.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP apply_migration.
--
-- Sources used for Baptiste:
--   1. https://newbedfordlight.org/city-council-passes-lower-parking-minimums-for-new-housing-8-3/
--      (Feb 13 2026 — Baptiste voted against 8-3, direct quote "you gotta be crazy")
--   2. https://wbsm.com/new-bedford-council-budget-cuts-zeiterion/
--      (Budget session — Baptiste among 6 yes votes to cut Zeiterion to $0)
--
-- Sources used for Lopes:
--   1. https://newbedfordlight.org/election-2025-candidate-interviews/
--      (Oct 2025 — direct quotes on public safety and budget priorities)
--   2. https://newbedfordlight.org/issues-2025-council-candidates-talk-new-bedfords-housing-crisis/
--      (Oct 28 2025 — Lopes on housing: expand building dept to speed permits,
--       preferred 1.5 spaces/unit parking standard)
--
-- Scott Pemberton (654) — honest-skip: see comment block below.
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
-- Derek Baptiste (Ward 4) — 1 sourced stance
-- ============================================================

-- ----- Derek Baptiste / residential-zoning -----
-- Value 1: "Protect existing neighborhood character strictly; require community votes before any rezoning"
-- Baptiste voted against reducing parking minimums (8-3 vote, Feb 13 2026), citing
-- neighborhood character concerns. Direct quote: "you gotta be crazy" to think
-- tenant households will only have one car. Opposed lower-density-friendly zoning changes.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('93d505e0-01b6-412c-9e07-4c491bdab866',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        1.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('93d505e0-01b6-412c-9e07-4c491bdab866',
        'd4f18138-a2e0-4110-b925-7387d9d0d16d',
        $$In the New Bedford City Council's Feb 13 2026 vote to reduce parking minimums for new housing, Baptiste was one of three dissenting votes (8-3). He explicitly stated that residents of Ward 4 already find it hard to locate parking spots and said "you gotta be crazy" to think that tenant households will only have one car. He argued the ordinance was "unrealistic" because apartment-dwellers would bring more cars than city planners anticipated, causing overflow into surrounding neighborhoods. Ward 4 residents had raised concerns about a nearby nine-unit development. This reflects a strong preference for protecting existing neighborhood character over density-friendly zoning reforms.$$,
        ARRAY['https://newbedfordlight.org/city-council-passes-lower-parking-minimums-for-new-housing-8-3/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- Joseph Lopes (Ward 5) — 2 sourced stances
-- ============================================================

-- ----- Joseph Lopes / public-safety-approach -----
-- Value 4: "Increase police staffing, equipment, and pay to improve response times and deter crime"
-- Lopes has explicitly stated he has never supported cuts to public safety or education.
-- He calls police/fire/EMS "the greatest insurance policy we can give" to residents.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('122c551d-7d99-496c-b3ce-62a5117bc0ab',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('122c551d-7d99-496c-b3ce-62a5117bc0ab',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$In his October 2025 New Bedford Light candidate interview, Lopes stated that his platform rests on three pillars: "Taxes, public safety, and education — and I base my campaign on understanding each one of those." He explicitly said he has "never supported cuts to public safety or education" during his council tenure. He described police, fire, and emergency medical services as "the greatest insurance policy we can give" to residents and "the lifeblood of people being safe." This strong, unqualified pro-public-safety investment position — with no mention of reallocation toward social services — places him at value 4 (increase police staffing, equipment, and pay).$$,
        ARRAY['https://newbedfordlight.org/election-2025-candidate-interviews/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ----- Joseph Lopes / housing -----
-- Value 3: "Offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits"
-- Lopes proposed expanding the building department to speed up permits for housing developers.
-- He advocated for a 1.5 spaces/unit parking standard (compromise, not rent caps or public housing).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('122c551d-7d99-496c-b3ce-62a5117bc0ab',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        3.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('122c551d-7d99-496c-b3ce-62a5117bc0ab',
        '669cac97-66a6-4087-b036-936fbe62efb3',
        $$In the Oct 28 2025 New Bedford Light housing crisis article, Lopes proposed expanding the city's building department to speed up routine construction permits for renovations and new developments, saying it would "lower the financial burden on developers as they wait for permits." He also stated he would support requiring 1.5 spaces per unit parking standard for new housing — a middle-ground position that is more permissive than the existing 2-space minimum but more cautious than the 1-space ordinance that ultimately passed (he ultimately voted for that ordinance). His approach centers on streamlining the permitting process rather than large public investment or rent mandates, placing him at value 3: targeted help through easier building permits and process improvements.$$,
        ARRAY['https://newbedfordlight.org/issues-2025-council-candidates-talk-new-bedfords-housing-crisis/', 'https://newbedfordlight.org/election-2025-candidate-interviews/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- Scott Pemberton (Ward 2) — HONEST-SKIP
-- ============================================================
-- politician_id: 6b22e04a-a302-4de6-b13f-9d1f6ec8e6b4
--
-- Attempted sources:
--   1. https://newbedfordlight.org/election-2025-candidate-interviews/
--      → Pemberton profile found; stated priorities: "Family, Ward 2, City of NB";
--        "no department off limits" for budget cuts; promised a parking ordinance
--        "on day one" but gave no specifics. Did not clarify what ordinance would
--        accomplish. No compass-topic-mappable policy positions found.
--   2. https://newbedfordlight.org/issues-2025-council-candidates-talk-new-bedfords-housing-crisis/
--      → Pemberton declined the housing interview request. Not quoted.
--   3. https://newbedfordlight.org/city-council-passes-lower-parking-minimums-for-new-housing-8-3/
--      → Pemberton was one of the 8 yes votes on the Feb 2026 parking minimums
--        ordinance, but no attributed statement from Pemberton was found in the
--        article explaining his reasoning. A vote without stated reasoning does
--        not satisfy the evidence-only rule for a compass value placement.
--   4. https://wbsm.com/new-bedford-election-results-2025/
--      → Confirmed Pemberton won Ward 2 (453 vs 436) in November 2025. No policy
--        content.
--   5. https://wbsm.com/new-bedford-council-committee-assignments-2026/
--      → Committee assignments listed. No policy positions.
--
-- Reason: All sources confirmed Pemberton holds office but no individual public
--   statements on compass-topic areas were found. His campaign was community-
--   engagement oriented ("for the people") without specific policy positions.
--   Evidence-only rule applies — blank spokes are honest.
-- No stance rows inserted for Scott Pemberton.

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- Row count per official:
-- SELECT p.full_name, COUNT(pa.topic_id) as stances
-- FROM essentials.politicians p
-- LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id
-- WHERE p.id IN (
--   '93d505e0-01b6-412c-9e07-4c491bdab866',  -- Baptiste (expect 1)
--   '122c551d-7d99-496c-b3ce-62a5117bc0ab',  -- Lopes (expect 2)
--   '6b22e04a-a302-4de6-b13f-9d1f6ec8e6b4'   -- Pemberton (expect 0, honest-skip)
-- )
-- GROUP BY p.full_name;
--
-- Unpaired check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id IN (
--   '93d505e0-01b6-412c-9e07-4c491bdab866',
--   '122c551d-7d99-496c-b3ce-62a5117bc0ab',
--   '6b22e04a-a302-4de6-b13f-9d1f6ec8e6b4'
-- ) AND pc.politician_id IS NULL;
--
-- Citation check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_context
-- WHERE politician_id IN (
--   '93d505e0-01b6-412c-9e07-4c491bdab866',
--   '122c551d-7d99-496c-b3ce-62a5117bc0ab'
-- )
-- AND (sources IS NULL OR array_length(sources, 1) IS NULL OR array_length(sources, 1) = 0);
