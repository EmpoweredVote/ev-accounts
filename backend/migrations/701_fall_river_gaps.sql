-- ============================================================================
-- Migration 701: Fall River City Council Gap-Fill Stances
-- ============================================================================
-- Purpose: Insert/upsert stance data for 4 Fall River City Council members
--   who had 0 stance rows. 3 officials receive stances with real sourced evidence.
--   1 official (Michael Canuel) is documented as honest-skip — insufficient
--   evidence found to pin a specific value on any topic.
--
-- Officials covered (with stances inserted):
--   Andrew Raposo  — politician_id = '00a6e310-45cc-49ab-a339-fe5bd791319d'
--   Linda Pereira  — politician_id = '23905e23-47f2-40b1-b514-93e9ef4e837f'
--   Paul Hart      — politician_id = '9f4b41dd-e90b-4aa0-b38b-f92cc8fa3de6'
--
-- Officials honest-skipped (no stances inserted):
--   Michael Canuel — politician_id = 'c9d09e1a-82fe-449c-9632-e9ac0134fe1d'
--
-- Already-covered Fall River officials NOT touched by this migration:
--   Christopher Peckham, Cliff Ponte, Joseph Camara, Michelle Dionne,
--   Paul Coogan, Shawn Cadime
--
-- Scope: 1 topic (public-safety-approach) per each of the 3 officials with evidence.
--   All other topics omitted — no neutral defaults inserted.
--   Local/city-level topics prioritized given their role as city councillors.
--
-- Idempotency: ON CONFLICT (politician_id, topic_id) DO UPDATE on both tables.
-- Apply to remote Supabase via Supabase MCP (mcp__supabase-local is remote production).
--
-- Sources used:
--   1. https://fallriverreporter.com/fall-river-police-and-fire-unions-issue-endorsements-for-political-office/
--      (Oct 2023 — police and fire union endorsements with candidate positions on public safety)
--   2. https://fallriverreporter.com/two-fall-river-city-councilors-object-to-second-request-to-make-interim-police-chief-kelly-furtado-permanent-chief/
--      (Voting records — Hart and Raposo voted YES to retain Furtado as permanent chief Apr 8)
--   3. https://fallriverreporter.com/city-council-votes-to-launch-formal-investigation-into-the-fall-river-police-department/
--      (Voting records — Pereira voted present/against the formal police investigation)
-- ============================================================================

-- Topic UUID reference (inform.compass_topics — relevant local topics):
-- city-sanitation                  7687de4f-4d0b-462a-b803-bdfb23b16b42
-- economic-development             eb3d1247-0de1-4b7f-baec-7259861efd53
-- growth-and-development           fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4
-- homelessness-response            6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f
-- housing                          669cac97-66a6-4087-b036-936fbe62efb3
-- local-environment                1935979c-b290-42e4-baa5-8cb0138b4ffa
-- local-immigration                b9ccee94-ad96-4f10-b655-889d8e5abe92
-- public-safety-approach           e9ebefcd-c496-45e8-b816-a79f8442ba85
-- rent-regulation                  c308e8e8-caac-44f5-ab04-dbfecf40bbe2
-- residential-zoning               d4f18138-a2e0-4110-b925-7387d9d0d16d
-- transportation-priorities        ba59337e-30e2-4aba-a39a-426b3366eb27

BEGIN;

-- ============================================================
-- Andrew Raposo — 1 sourced stance
-- politician_id: '00a6e310-45cc-49ab-a339-fe5bd791319d'
-- ============================================================

-- ----- Andrew Raposo / public-safety-approach -----
-- Value 4: "Increase police staffing, equipment, and pay to improve response times and deter crime"
-- FRPA endorsed Raposo for prioritizing public safety and quality-of-life enforcement ordinances;
-- voted YES to retain Chief Furtado as permanent chief.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('00a6e310-45cc-49ab-a339-fe5bd791319d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('00a6e310-45cc-49ab-a339-fe5bd791319d',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$The Fall River Police Association endorsed Raposo in their 2023 election endorsements, stating that he had "proven through their actions that public safety is a priority" and advocating for "creation of ordinance to empower the police to take enforcement action on quality of life issues." He was simultaneously endorsed by the Firefighters union (IAFF Local 1314). Raposo voted YES on April 8, 2024 to retain Interim Chief Kelly Furtado as the permanent police chief — a vote reflecting support for incumbent police leadership and police department continuity. This record of endorsing police-led quality-of-life enforcement and supporting police leadership aligns with value 4: increasing police staffing, equipment, and pay to improve response times and deter crime.$$,
        ARRAY['https://fallriverreporter.com/fall-river-police-and-fire-unions-issue-endorsements-for-political-office/', 'https://fallriverreporter.com/two-fall-river-city-councilors-object-to-second-request-to-make-interim-police-chief-kelly-furtado-permanent-chief/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Linda Pereira — 1 sourced stance
-- politician_id: '23905e23-47f2-40b1-b514-93e9ef4e837f'
-- ============================================================

-- ----- Linda Pereira / public-safety-approach -----
-- Value 4: "Increase police staffing, equipment, and pay to improve response times and deter crime"
-- FRPA endorsed Pereira; she voted against the formal police investigation and initially voted
-- YES to make Furtado permanent chief before later shifting, showing strong deference to police
-- leadership over accountability reforms.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('23905e23-47f2-40b1-b514-93e9ef4e837f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('23905e23-47f2-40b1-b514-93e9ef4e837f',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$The Fall River Police Association endorsed Pereira in their 2023 election endorsements, stating she had "proven through their actions that public safety is a priority." With 25+ years on the council (returning to vice-president in 2024), Pereira has an established track record of alignment with police department leadership. Most directly: when the council voted on a formal investigation into the Fall River Police Department, Pereira "admitted that she hasn't seen the whole report," spoke out against the investigation, and voted present — a posture that reflects deference to existing police structures rather than accountability oversight. This record aligns with value 4: increasing police staffing and pay while prioritizing response times and deterrence over structural reform.$$,
        ARRAY['https://fallriverreporter.com/fall-river-police-and-fire-unions-issue-endorsements-for-political-office/', 'https://fallriverreporter.com/city-council-votes-to-launch-formal-investigation-into-the-fall-river-police-department/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Paul Hart — 1 sourced stance
-- politician_id: '9f4b41dd-e90b-4aa0-b38b-f92cc8fa3de6'
-- ============================================================

-- ----- Paul Hart / public-safety-approach -----
-- Value 4: "Increase police staffing, equipment, and pay to improve response times and deter crime"
-- FRPA explicitly endorsed Hart for plans including quality-of-life enforcement ordinances;
-- voted YES to retain Chief Furtado as permanent chief.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('9f4b41dd-e90b-4aa0-b38b-f92cc8fa3de6',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        4.0)
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('9f4b41dd-e90b-4aa0-b38b-f92cc8fa3de6',
        'e9ebefcd-c496-45e8-b816-a79f8442ba85',
        $$The Fall River Police Association explicitly endorsed Hart in their 2023 election endorsements, noting he "displayed in a variety of ways how public safety within Fall River is a priority" and provided "plans on how they would move public safety forward with the use of sub-committees and working with the Mayor in a legislative way such as the creation of ordinance to empower the police to take enforcement action on quality of life issues." Hart voted YES on April 8, 2024 to retain Interim Chief Kelly Furtado as the permanent police chief — supporting police department continuity and incumbent leadership. This explicit endorsement for police-led quality-of-life enforcement ordinances and support for the permanent appointment of the police chief aligns with value 4: increasing police staffing, equipment, and pay to improve response times and deter crime.$$,
        ARRAY['https://fallriverreporter.com/fall-river-police-and-fire-unions-issue-endorsements-for-political-office/', 'https://fallriverreporter.com/two-fall-river-city-councilors-object-to-second-request-to-make-interim-police-chief-kelly-furtado-permanent-chief/']::text[])
ON CONFLICT (politician_id, topic_id)
DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ============================================================
-- Honest-skip: Michael Canuel (c9d09e1a-82fe-449c-9632-e9ac0134fe1d)
-- ============================================================
-- Attempted sources:
--   1. https://fallriverreporter.com/city-council-votes-to-launch-formal-investigation-into-the-fall-river-police-department/
--      (Canuel voted YES for police investigation — accountability focus, but not sufficient
--       to pin a specific public-safety-approach value on the 1-5 scale)
--   2. https://fallriverreporter.com/complaints-on-snowstorm-response-leads-to-fall-river-city-council-resolution-for-public-works-committee-debriefing/
--      (Canuel co-sponsored snowstorm review — shows infrastructure focus but not specific
--       public safety funding positions)
--   3. https://fallriverreporter.com/fall-river-educators-association-makes-endorsements-for-city-council-school-committee/
--      (Canuel endorsed by educators association for school funding commitments, not public safety)
--   4. https://fallriverreporter.com/fall-river-police-and-fire-unions-issue-endorsements-for-political-office/
--      (Canuel NOT listed in police union endorsements; firefighters union endorsed him with
--       all 9 candidates generically — insufficient specificity for stance assignment)
--   5. https://news.google.com/rss/search (multiple searches for Canuel + housing/zoning/homelessness)
--      (No articles found with specific policy positions on local topics)
-- Reason: Canuel is a new councillor (elected Nov 2023). He was not in the police union
--   endorsees (suggesting less alignment with that bloc), voted for the police investigation
--   (accountability-oriented), but no articles found documenting specific positions on
--   public-safety funding levels, housing, zoning, homelessness, or other topics.
--   Without sufficient evidence, no stance rows are inserted.
--   No stance rows inserted. This comment documents the research attempt.

COMMIT;

-- ============================================================================
-- Verification queries (run after applying):
-- ============================================================================
-- Row count for 3 officials (must be >= 1 each):
-- SELECT politician_id, COUNT(*) FROM inform.politician_answers
-- WHERE politician_id IN (
--   '00a6e310-45cc-49ab-a339-fe5bd791319d',
--   '23905e23-47f2-40b1-b514-93e9ef4e837f',
--   '9f4b41dd-e90b-4aa0-b38b-f92cc8fa3de6'
-- ) GROUP BY politician_id;
--
-- Unpaired check (must return 0):
-- SELECT COUNT(*) FROM inform.politician_answers pa
-- LEFT JOIN inform.politician_context pc
--   ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
-- WHERE pa.politician_id IN (
--   '00a6e310-45cc-49ab-a339-fe5bd791319d',
--   '23905e23-47f2-40b1-b514-93e9ef4e837f',
--   'c9d09e1a-82fe-449c-9632-e9ac0134fe1d',
--   '9f4b41dd-e90b-4aa0-b38b-f92cc8fa3de6'
-- ) AND pc.politician_id IS NULL;
--
-- Canuel check (must return 0 — he is an honest-skip):
-- SELECT COUNT(*) FROM inform.politician_answers
-- WHERE politician_id = 'c9d09e1a-82fe-449c-9632-e9ac0134fe1d';
--
-- All Fall River officials coverage:
-- SELECT p.full_name, COUNT(pa.topic_id) as stances
-- FROM essentials.politicians p
-- JOIN essentials.offices o ON o.politician_id = p.id
-- JOIN essentials.districts d ON d.id = o.district_id
-- LEFT JOIN inform.politician_answers pa ON pa.politician_id = p.id
-- WHERE d.geo_id = '2523000'
-- GROUP BY p.full_name
-- ORDER BY p.full_name;
