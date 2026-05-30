-- Migration 186: Longview TX city council Local Lens compass stances
-- Researched 2026-05-20
-- Politicians:
--   Kristen Ishihara  (Mayor)      — 5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0
--   Derrick Conley    (District 1) — c723b079-c7db-4376-b8d3-72ac896fefe2
--   Shannon Moore     (District 2) — d55159ff-7c27-4313-b464-722f653fd7b7
--   Wray Wade         (District 3) — ae9c740d-5910-414c-aa3d-7e9bf374a9b7
--   John Nustad       (District 4) — 94957758-20db-4590-8cc9-ce54c24e2449
--   Jody Berryhill    (District 5) — feb872f2-cd11-42bc-8a83-22e12dbc6207
--   Sidney Allen      (District 6) — 2baab241-b3c5-48e9-b9a6-fd29b7b77beb
--
-- Local Lens topic IDs:
--   Affordable Housing              669cac97-66a6-4087-b036-936fbe62efb3
--   Criminalization of Homelessness 4938766b-b45a-46e3-93bd-b8b30651271a
--   Residential Zoning              d4f18138-a2e0-4110-b925-7387d9d0d16d
--   Civil Rights and Social Justice 0bc588c6-39e1-4084-b5de-cac909b8b762
--   Public Safety Approach          e9ebefcd-c496-45e8-b816-a79f8442ba85
--   Local Immigration Enforcement   b9ccee94-ad96-4f10-b655-889d8e5abe92
--   Economic Development Incentives eb3d1247-0de1-4b7f-baec-7259861efd53
--   Transportation Priorities       ba59337e-30e2-4aba-a39a-426b3366eb27
--
-- Research note: Longview council elections are nonpartisan. Most council members
-- (Districts 1-6) were elected in 2024-2025 and have minimal public policy records.
-- Mayor Ishihara has the most documented positions from her 2025 State of the City
-- address, task force creation, and KLTV/news-journal coverage.
-- Sources: kltv.com, news-journal.com, longviewtexas.gov, legistorm.com

BEGIN;

-- ============================================================
-- KRISTEN ISHIHARA — Mayor
-- ID: 5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- Ishihara launched a Housing Action Plan with a resident survey as part of her
-- mayor's agenda. She stated the city faces an affordable housing issue and created
-- a housing task force (June 2025) specifically to identify and advance solutions for
-- affordable, transitional, and group housing. Aligns with value 3: targeted programs,
-- surveys, and public-private coordination rather than large direct subsidies.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from governance: Ishihara acknowledged Longview faces an affordable housing shortage and created a housing task force (June 2025) charged with identifying solutions for affordable, transitional, and group housing. She launched a Housing Action Plan supported by a resident survey. Her 2025 State of the City address emphasized the housing study as a city priority. The coordinated public-private approach and task force structure align with answer 3 (targeted subsidies, vouchers, and programs for affordable projects rather than large-scale public housing).',
  ARRAY['https://www.kltv.com/2025/06/04/longview-mayor-creates-5-new-taskforces-help-homeless-transient-population/',
        'https://www.kltv.com/2025/11/06/longview-mayor-kristen-ishihara-delivers-2nd-state-city/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-...)
-- Ishihara created 5 task forces (June 2025) coordinating police outreach, housing,
-- transportation, mental health, and community engagement for the homeless population.
-- She also signed the May 2024 outdoor sleeping ordinance banning sleeping on private
-- property. Her stated approach: "coordinate those services" and show compassion, not
-- primarily enforce. The task force model combined with the ordinance aligns with value 3:
-- enforcement tied to service availability, directing people to resources.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0', '4938766b-b45a-46e3-93bd-b8b30651271a', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Mixed evidence: Ishihara signed a May 2024 ordinance banning sleeping on private property (which critics noted targeted One Love Longview, a nonprofit providing outdoor shelter). However, she subsequently created 5 task forces (June 2025) emphasizing coordinated services — police outreach, housing, mental health, and community engagement — saying homelessness is "sometimes circumstances, not something someone has done" and that "if given the opportunity and help, people will help." The combination of enforcement tool with service coordination aligns with answer 3 (enforcement tied to availability of adequate shelter, with citations diverting people to services rather than pure criminalization).',
  ARRAY['https://www.kltv.com/2025/06/04/longview-mayor-creates-5-new-taskforces-help-homeless-transient-population/',
        'https://www.kltv.com/2024/05/30/webxtra-longview-homeless-advocate-explains-opposition-outdoor-sleeping-ordinance/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-...)
-- No specific zoning vote or stance documented from Ishihara. Housing Action Plan study
-- is pending; no position on multifamily vs. single-family zoning found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-20 — no public record found. Ishihara is conducting a Housing Action Plan study and survey but has not publicly stated a position on residential zoning philosophy (single-family protection vs. upzoning). Checked: kltv.com, news-journal.com, longviewtexas.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-...)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-20 — no public record found. No statements or votes on civil rights enforcement, equity programs, or social justice policy found. Checked: kltv.com, news-journal.com, legistorm.com, kristenformayor.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-...)
-- Ishihara's 2025 State of the City address highlighted that the police and fire
-- departments are now fully staffed ("no vacancies or one to two vacancies now"
-- vs. double-digit shortages 5 years prior), and the fire department implemented a
-- new 48-96 scheduling system to improve retention. She listed public safety staffing
-- as a governance achievement. Aligns with value 4: increase staffing and pay.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from governance record: Ishihara''s 2025 State of the City address highlighted full staffing of the police and fire departments as a major achievement — "we either have no vacancies or one to two vacancies now" compared to double-digit shortages 5 years prior. She also cited the fire department''s new 48-96 scheduling system as a retention improvement. Full staffing as a key performance indicator and the 5% employee raise in FY2025-26 (including police/fire) align with answer 4 (increase police staffing, equipment, and pay to improve response times).',
  ARRAY['https://www.kltv.com/2025/11/06/longview-mayor-kristen-ishihara-delivers-2nd-state-city/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement (b9ccee94-...)
-- Not found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-20 — no public record found. No statements or votes on ICE detainers, sanctuary policies, or local immigration enforcement found. Checked: kltv.com, news-journal.com, legistorm.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives (eb3d1247-...)
-- Ishihara's 2025 State of the City address highlighted major wins: AAON ($68M capital,
-- 500 jobs), KOMATSU ($104M capital), and Eastman ($1B capital, 200+ jobs). She
-- championed the Longview EDC and these large employer recruitment outcomes.
-- Aligns with value 4: compete actively for major employers with incentives.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from governance record: Ishihara''s 2025 State of the City address prominently highlighted large employer recruitment as a success: AAON ($68M capital investment, 500 jobs), KOMATSU ($104M capital investment), and Eastman ($1B capital investment, 200+ jobs). She actively promotes the Longview EDC as a tool for major employer attraction. This pattern of celebrating large capital investments and job creation aligns with answer 4 (compete actively for major employers with significant tax abatements and infrastructure investment).',
  ARRAY['https://www.kltv.com/2025/11/06/longview-mayor-kristen-ishihara-delivers-2nd-state-city/',
        'https://longviewusa.com/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities (ba59337e-...)
-- Ishihara's 2025 State of the City address cited a 33% efficiency increase in road
-- maintenance crews and 25% improvement in pothole repairs as a governance achievement.
-- Road infrastructure as a priority metric; no transit or bike investment mentioned.
-- Aligns with value 4: focus on road capacity and traffic flow.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('5e24851a-2f6f-4c2a-ba41-20b5c1dca1d0', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from governance record: Ishihara''s 2025 State of the City address cited road maintenance efficiency as a key achievement — 33% efficiency increase in road maintenance crews and 25% improvement in pothole repairs. Road infrastructure improvement is the sole transportation metric highlighted. No mentions of transit investment, bike lanes, or multimodal transportation were found. Aligns with answer 4 (focus on road capacity and traffic flow; transportation investment should serve the majority who drive).',
  ARRAY['https://www.kltv.com/2025/11/06/longview-mayor-kristen-ishihara-delivers-2nd-state-city/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- DERRICK CONLEY — District 1
-- ID: c723b079-c7db-4376-b8d3-72ac896fefe2
-- ============================================================

-- Conley was elected May 2024 and serves as liaison to the Zoning Board of
-- Adjustment. No public policy statements or vote records found beyond council
-- minutes (all votes appear to be unanimous). All 8 topics: not found.

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c723b079-c7db-4376-b8d3-72ac896fefe2', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-20 — no public record found. Conley elected May 2024; no public statements on affordable housing found. Checked: longviewtexas.gov, news-journal.com, kltv.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c723b079-c7db-4376-b8d3-72ac896fefe2', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-20 — no public record found. No specific statements or votes on homelessness criminalization found. Checked: longviewtexas.gov, news-journal.com, kltv.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c723b079-c7db-4376-b8d3-72ac896fefe2', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-20 — no public record found. No statements on zoning philosophy found. Conley serves on Zoning Board of Adjustment liaison but no votes or positions documented.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c723b079-c7db-4376-b8d3-72ac896fefe2', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c723b079-c7db-4376-b8d3-72ac896fefe2', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-20 — no public record found. No statements on public safety approach found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c723b079-c7db-4376-b8d3-72ac896fefe2', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c723b079-c7db-4376-b8d3-72ac896fefe2', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-20 — no public record found. No statements on economic development incentives found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c723b079-c7db-4376-b8d3-72ac896fefe2', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- SHANNON MOORE — District 2
-- ID: d55159ff-7c27-4313-b464-722f653fd7b7
-- ============================================================

-- Moore was elected May 2024 and serves as liaison to the Housing Authority Advisory
-- Committee. No public policy statements or distinct vote records found. All 8 topics: not found.

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d55159ff-7c27-4313-b464-722f653fd7b7', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-20 — no public record found. Moore serves as Housing Authority Advisory Committee liaison, but no public statements on housing policy found. Checked: longviewtexas.gov, news-journal.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d55159ff-7c27-4313-b464-722f653fd7b7', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d55159ff-7c27-4313-b464-722f653fd7b7', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d55159ff-7c27-4313-b464-722f653fd7b7', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d55159ff-7c27-4313-b464-722f653fd7b7', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d55159ff-7c27-4313-b464-722f653fd7b7', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d55159ff-7c27-4313-b464-722f653fd7b7', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d55159ff-7c27-4313-b464-722f653fd7b7', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- WRAY WADE — District 3 (hold-over; June 2026 runoff pending)
-- ID: ae9c740d-5910-414c-aa3d-7e9bf374a9b7
-- ============================================================

-- Wade has served since 2018 and serves as Public Transportation Advisory Committee
-- liaison. He is an entrepreneur (Wray Wade Enterprises, i20 Sports and Entertainment,
-- Barber Institute of Texas). No policy vote record found for the 8 local topics.
-- His Public Transportation liaison role is noted for transportation context.

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae9c740d-5910-414c-aa3d-7e9bf374a9b7', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-20 — no public record found. Wade has served since 2018 but no specific housing policy statements found. Checked: longviewtexas.gov, news-journal.com, kltv.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae9c740d-5910-414c-aa3d-7e9bf374a9b7', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-20 — no public record found. No specific vote record or statement on the 2024 outdoor sleeping ordinance attributed to Wade individually.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae9c740d-5910-414c-aa3d-7e9bf374a9b7', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae9c740d-5910-414c-aa3d-7e9bf374a9b7', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae9c740d-5910-414c-aa3d-7e9bf374a9b7', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae9c740d-5910-414c-aa3d-7e9bf374a9b7', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae9c740d-5910-414c-aa3d-7e9bf374a9b7', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-20 — no public record found. Wade is an entrepreneur who owns Wray Wade Enterprises and i20 Sports and Entertainment, but no specific votes or statements on economic development incentive policy found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ae9c740d-5910-414c-aa3d-7e9bf374a9b7', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-20 — no public record found. Wade serves as Public Transportation Advisory Committee liaison (since at least 2024), suggesting engagement with transit issues, but no specific policy position on road vs. transit priorities documented publicly.',
  ARRAY['https://www.longviewtexas.gov/2204/District-3---Wray-Wade'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- JOHN NUSTAD — District 4 (Mayor ProTem)
-- ID: 94957758-20db-4590-8cc9-ce54c24e2449
-- ============================================================

-- Nustad is a mortgage loan officer and realtor; active with Kilgore College Foundation,
-- Theatre Longview, Longview Area Association of Realtors. Mayor ProTem.
-- His focus: wants Longview to be "somewhere our children want to and are able to live,"
-- with emphasis on education and community investment. Most topics: not found.

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94957758-20db-4590-8cc9-ce54c24e2449', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-20 — no public record found. Nustad is a mortgage loan officer and Realtors Association member, suggesting market-oriented housing views, but no specific votes or statements on affordable housing policy found. Checked: longviewtexas.gov, news-journal.com.',
  ARRAY['https://www.longviewtexas.gov/2205/District-4---John-Nustad'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94957758-20db-4590-8cc9-ce54c24e2449', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94957758-20db-4590-8cc9-ce54c24e2449', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94957758-20db-4590-8cc9-ce54c24e2449', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94957758-20db-4590-8cc9-ce54c24e2449', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-20 — no public record found. Nustad serves on the EMS Advisory Board as liaison, indicating awareness of emergency services, but no specific position on police funding levels found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94957758-20db-4590-8cc9-ce54c24e2449', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94957758-20db-4590-8cc9-ce54c24e2449', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-20 — no public record found. No specific statements on economic development incentive policy found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('94957758-20db-4590-8cc9-ce54c24e2449', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- JODY BERRYHILL — District 5
-- ID: feb872f2-cd11-42bc-8a83-22e12dbc6207
-- ============================================================

-- Berryhill was elected May 2025 (athletic trainer, 25 years at Pine Tree ISD,
-- formerly with Tampa Bay Buccaneers). Liaison: Parks & Rec, Cultural Activities,
-- Senior Advisory. No policy record yet after less than one year in office.

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('feb872f2-cd11-42bc-8a83-22e12dbc6207', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-20 — no public record found. Berryhill elected May 2025; insufficient time in office for documented policy positions. Checked: longviewtexas.gov, news-journal.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('feb872f2-cd11-42bc-8a83-22e12dbc6207', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('feb872f2-cd11-42bc-8a83-22e12dbc6207', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('feb872f2-cd11-42bc-8a83-22e12dbc6207', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('feb872f2-cd11-42bc-8a83-22e12dbc6207', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('feb872f2-cd11-42bc-8a83-22e12dbc6207', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('feb872f2-cd11-42bc-8a83-22e12dbc6207', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('feb872f2-cd11-42bc-8a83-22e12dbc6207', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- SIDNEY ALLEN — District 6
-- ID: 2baab241-b3c5-48e9-b9a6-fd29b7b77beb
-- ============================================================

-- Allen was elected May 2025. He serves as liaison to LEDCO (Longview Economic
-- Development Corp), Historic Preservation Commission, and Planning and Zoning.
-- LEDCO liaison suggests economic development engagement, but no specific votes
-- or statements on incentive policy found.

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2baab241-b3c5-48e9-b9a6-fd29b7b77beb', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-20 — no public record found. Allen elected May 2025; no housing policy statements found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2baab241-b3c5-48e9-b9a6-fd29b7b77beb', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2baab241-b3c5-48e9-b9a6-fd29b7b77beb', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-20 — no public record found. Allen serves as Planning and Zoning Commission liaison but no specific zoning philosophy statements found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2baab241-b3c5-48e9-b9a6-fd29b7b77beb', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2baab241-b3c5-48e9-b9a6-fd29b7b77beb', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2baab241-b3c5-48e9-b9a6-fd29b7b77beb', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2baab241-b3c5-48e9-b9a6-fd29b7b77beb', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-20 — no public record found. Allen serves as LEDCO (Longview Economic Development Corporation) liaison, indicating institutional involvement in economic development, but no specific statements on incentive policy found.',
  ARRAY['https://www.longviewtexas.gov/2207/District-6---Sidney-Allen'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('2baab241-b3c5-48e9-b9a6-fd29b7b77beb', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-20 — no public record found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
