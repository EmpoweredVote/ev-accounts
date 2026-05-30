-- Migration 188: Longview TX extended compass stances (beyond Local Lens)
-- Researched 2026-05-21
-- Covers topics NOT in migration 186 (which handled 8 Local Lens topics)
-- Politicians:
--   Kristen Ishihara  (Mayor)      — 5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0
--   Wray Wade         (District 3) — ae9c740d-5910-414c-aa3d-7e9bf374a9b7
--   Jody Berryhill    (District 5) — feb872f2-cd11-42bc-8a83-22e12dbc6207
--
-- Topics added:
--   Homelessness Response          6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f
--   City Sanitation                7687de4f-4d0b-462a-b803-bdfb23b16b42
--   Local Environment              1935979c-b290-42e4-baa5-8cb0138b4ffa
--   Growth and Development         fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4
--   Transportation Priorities      ba59337e-30e2-4aba-a39a-426b3366eb27  (Wade only)
--
-- All other council members (Conley, Moore, Nustad, Allen) had zero
-- scorable evidence across all 36 remaining topics — confirmed exhaustively.
-- Sources: kltv.com, news-journal.com, longviewtexas.gov, Ballotpedia,
--          Longview City Council meeting minutes (PDF)

BEGIN;

-- ============================================================
-- KRISTEN ISHIHARA — Mayor
-- ID: 5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0
-- ============================================================

-- Homelessness Response (6fbf39ae-...)
-- Five task forces (2025) for service coordination, mental health co-responders,
-- Police Outreach Services Team expansion. Accepted enforcement tied to services
-- (supported 2017 camping ordinance with alternate sentencing into services).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
  'Ishihara created five task forces in 2025 specifically to address homelessness through expanded outreach, data coordination, mental health services, housing, and transportation — not primarily through enforcement. In her 2025 State of the City address she highlighted grant funding to expand the Police Outreach Services Team and add mental health co-responders alongside officers. However, as a councilwoman in 2017 she supported a blend of ordinances banning camping in public spaces with alternate sentencing into services, indicating she accepts reasonable enforcement when adequate shelter/services are offered.',
  ARRAY['https://news-journal.com/2025/11/06/longview-mayor-celebrates-years-successes-urges-residents-to-change-recycling-habits/',
        'https://news-journal.com/2025/12/15/longview-task-force-calls-for-better-data-sharing-among-nonprofits-that-serve-homeless-residents/',
        'https://news-journal.com/2017/10/01/new-laws-targeting-homelessness-spur-questions-concerns/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- City Sanitation (7687de4f-...)
-- $1.2M tree grant, restarted recycling, 2026 Keep Texas Beautiful Governor's Award.
-- Frames sanitation as services/infrastructure, not enforcement.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0', '7687de4f-4d0b-462a-b803-bdfb23b16b42', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0', '7687de4f-4d0b-462a-b803-bdfb23b16b42',
  'In her November 2025 State of the City address Ishihara announced a $1.2 million Texas A&M Forest Service grant to plant 5,000 trees in public and community spaces and led efforts to restart Longview''s curbside recycling program after a facility fire — framing contamination reduction as a civic responsibility. The city received the 2026 Governor''s Community Achievement Award (Keep Texas Beautiful) for Keep Longview Beautiful''s ''Less Littered Longview'' campaign. Her approach consistently treats poor sanitation conditions as a services and infrastructure challenge rather than an enforcement one.',
  ARRAY['https://news-journal.com/2025/11/06/longview-mayor-celebrates-years-successes-urges-residents-to-change-recycling-habits/',
        'https://news-journal.com/2026/05/19/business-digest-city-of-longview-receives-state-beautification-award/',
        'https://www.longviewtexas.gov/2264'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Local Environment (1935979c-...)
-- $1.2M tree grant + Keep Texas Beautiful award. Consistent standards, no bans.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
  'Ishihara secured a $1.2 million grant from the Texas A&M Forest Service in 2025 to plant 5,000 trees across public and private community spaces, demonstrating active investment in environmental preservation alongside development. The city''s ''Less Littered Longview'' campaign won a 2026 Keep Texas Beautiful Governor''s Award, reflecting a strong stewardship ethos championed under her administration. She applies consistent environmental standards rather than offsetting them with fees, though she has not proposed outright development bans.',
  ARRAY['https://news-journal.com/2025/11/06/longview-mayor-celebrates-years-successes-urges-residents-to-change-recycling-habits/',
        'https://news-journal.com/2026/05/19/business-digest-city-of-longview-receives-state-beautification-award/',
        'https://www.longviewtexas.gov/4443/Mayors-Task-Forces'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Growth and Development (fb25c1ac-...)
-- Pushed for consultant-led comprehensive plan with deep community input (2022).
-- Recruits major employers while leading housing surveys and infrastructure planning.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
  'As chair of Longview''s comprehensive planning committee in 2022 Ishihara pushed to hire consultants to update the city''s growth plan with deep community input, stating "It is not sufficient in my mind to use town halls where people come and talk about potholes" — she wanted residents to articulate a long-term vision. She actively champions economic development recruitment (celebrated a $200M+ dairy plant investment in 2025 noting "Longview does well" at bringing partners together) while simultaneously leading housing surveys and infrastructure planning to ensure growth is supported by services. This reflects a proactive invest-ahead-of-growth posture rather than a restrict-or-maximize stance.',
  ARRAY['https://news-journal.com/2022/07/26/proposal-to-pay-consultant-to-update-longviews-comprehensive-plan-draws-opposition/',
        'https://news-journal.com/2025/10/23/dairy-industry-company-to-bring-200m-plus-investment-to-longview/',
        'https://news-journal.com/2025/11/14/city-of-longview-public-survey-to-serve-as-road-map-for-growth-of-housing/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- WRAY WADE — District 3
-- ID: ae9c740d-5910-414c-aa3d-7e9bf374a9b7
-- ============================================================

-- Homelessness Response (6fbf39ae-...)
-- Voted for Community Healthcore MOU embedding mental health co-responders with police.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae9c740d-5910-414c-aa3d-7e9bf374a9b7', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae9c740d-5910-414c-aa3d-7e9bf374a9b7', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
  'Wade voted unanimously in October 2025 to authorize a memorandum of understanding with Community Healthcore to embed grant-funded mental health professionals within multidisciplinary police teams — a co-responder model that adds outreach and services alongside officers without abandoning enforcement. All council votes reviewed from January–April 2026 were unanimous, indicating mainstream-Longview positioning on homelessness: invest in services while maintaining reasonable public space rules.',
  ARRAY['https://www.longviewtexas.gov/AgendaCenter/ViewFile/Minutes/_10232025-2150',
        'https://www.longviewtexas.gov/2204/District-3---Wray-Wade'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Growth and Development (fb25c1ac-...)
-- Voted yes on staff-recommended rezonings; seconded LEDCO budget.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae9c740d-5910-414c-aa3d-7e9bf374a9b7', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae9c740d-5910-414c-aa3d-7e9bf374a9b7', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
  'Wade voted yes on multiple staff-recommended rezoning approvals in early 2026 (SF-4 single-family subdivisions, C-2 commercial warehouse, Planned Development phases), and seconded the LEDCO FY2025-2026 economic development budget in September 2025. These votes reflect a proactive stance on accommodating growth through standard planning channels — approving development where infrastructure and zoning alignment support it — rather than restricting or removing regulatory review.',
  ARRAY['https://www.longviewtexas.gov/AgendaCenter/ViewFile/Minutes/_04092026-2237',
        'https://www.longviewtexas.gov/AgendaCenter/ViewFile/Minutes/_09112025-2113'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Transportation Priorities (ba59337e-...)
-- Public Transportation Advisory Committee liaison; championed bus pass award;
-- supported $200K multimodal corridor study. Upgrades migration 186 "no record" context entry.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ae9c740d-5910-414c-aa3d-7e9bf374a9b7', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae9c740d-5910-414c-aa3d-7e9bf374a9b7', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Wade serves as the City Council liaison to the Public Transportation Advisory Committee and personally presented a constituent with a two-year Longview Transit bus pass in September 2025 for heroic acts on the city bus system — demonstrating active engagement with public transit. The council also approved a $200,000 transportation planning contract with Halff Associates in April 2026 for a multimodal corridor study covering pedestrian, safety, and transit access improvements, which Wade supported unanimously. No evidence of pushing pedestrian or cycling infrastructure overhaul citywide.',
  ARRAY['https://www.longviewtexas.gov/2204/District-3---Wray-Wade',
        'https://www.longviewtexas.gov/AgendaCenter/ViewFile/Minutes/_09112025-2113',
        'https://www.longviewtexas.gov/AgendaCenter/ViewFile/Minutes/_04092026-2237'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- JODY BERRYHILL — District 5
-- ID: feb872f2-cd11-42bc-8a83-22e12dbc6207
-- ============================================================

-- Homelessness Response (6fbf39ae-...)
-- Seconded Community Healthcore MOU motion (co-responder model).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('feb872f2-cd11-42bc-8a83-22e12dbc6207', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('feb872f2-cd11-42bc-8a83-22e12dbc6207', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
  'Berryhill personally seconded the motion on October 23, 2025 authorizing a Memorandum of Understanding with Community Healthcore to embed two grant-funded qualified mental health professionals within the city''s Multidisciplinary Response Team alongside police and fire. This co-responder model invests in outreach and mental health services while maintaining law enforcement as part of the team, consistent with allowing enforcement after services are offered rather than criminalizing homelessness outright or taking a pure housing-first approach.',
  ARRAY['https://www.longviewtexas.gov/AgendaCenter/ViewFile/Minutes/_10232025-2150'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- Growth and Development (fb25c1ac-...)
-- Moved approval of 3 District 5 rezonings through standard planning process (April 2026).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('feb872f2-cd11-42bc-8a83-22e12dbc6207', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('feb872f2-cd11-42bc-8a83-22e12dbc6207', 'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
  'In April 2026 Berryhill personally moved approval of three District 5 rezoning applications through the standard planning process: a 20.92-acre SF-4 single-family subdivision to meet growing housing demand, a neighborhood services rezone for an event venue, and a Planned Development Phase 2 for Rustic Oaks single-family subdivision. All three followed staff and Planning & Zoning Commission recommendation and passed unanimously. This reflects a proactive stance on accommodating growth through established planning channels rather than restricting development or removing regulatory review.',
  ARRAY['https://www.longviewtexas.gov/AgendaCenter/ViewFile/Minutes/_04092026-2237'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
