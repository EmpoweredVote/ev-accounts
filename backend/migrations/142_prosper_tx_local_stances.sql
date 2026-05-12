-- Migration 142: Prosper TX town council Local Lens compass stances
-- Researched 2026-05-11
-- Politicians: David Bristol (Mayor), Craig Andres (Place 2), Amy Bartley (Place 3/Mayor Pro-Tem),
--              Chris Kern (Place 4/Deputy Mayor Pro-Tem), Jeff Hodges (Place 5),
--              Cameron Reeves (Place 6), Marcus Ray (Place 1)
-- Town: Prosper, TX — ~40,000 pop., Collin/Denton counties; fast-growing wealthy suburb N of Dallas;
--   Pro-growth, low-tax conservative values; active EDC; major issues: rapid growth management,
--   infrastructure (US 380, BNSF rail, Dallas North Tollway), economic development, quality-of-life.
-- Sources consulted: davidfbristol.com, prosperedc.com, prospertx.gov, communityimpact.com,
--   craigandresforprosper.com, kernforprosper.com, weareprosper.com, starlocalmedia.com,
--   therealdeal.com (Texas), citylifestyle.com, eaglenationonline.com, legistorm.com,
--   citizenportal.ai, eu.prosperpressnews.com, localprofile.com, candysdirt.com

BEGIN;

-- ============================================================
-- DAVID BRISTOL — Mayor
-- ID: d65e3760-95f3-4ad5-ba29-be01a76ae23b
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- No public record found. Prosper is a high-income suburb; affordable housing is not a
-- stated policy priority for Bristol. His housing references focus on market-rate growth.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d65e3760-95f3-4ad5-ba29-be01a76ae23b', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. Checked: davidfbristol.com, communityimpact.com Prosper coverage, weareprosper.com, citylifestyle.com mayor profile, starlocalmedia.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-...)
-- No public record found. Prosper has essentially no visible homelessness; topic has not
-- surfaced in any public statements or council records.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d65e3760-95f3-4ad5-ba29-be01a76ae23b', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Prosper has essentially no visible homelessness; topic has not surfaced in any mayor statements, council meetings, or local press coverage reviewed.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-...)
-- Bristol has publicly stated that council policy is to approve additional multifamily
-- ONLY along the Dallas North Tollway corridor, reinforced by the Feb 2026 DNT zoning
-- standards. He oversees a soft cap of ~7,000 multifamily units and frames all multifamily
-- approvals around commercial corridor access. This matches answer 3: allow multifamily
-- and mixed-use near commercial corridors while protecting most residential zones.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d65e3760-95f3-4ad5-ba29-be01a76ae23b', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d65e3760-95f3-4ad5-ba29-be01a76ae23b', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from direct statement: Bristol publicly stated that "council''s philosophy is to only approve additional multifamily along Dallas North Tollway," reinforced by the Feb 2026 DNT zoning standards adopted under his leadership. The town maintains a soft cap of ~7,000 multifamily units and frames all multifamily through corridor access requirements. This directly matches answer 3: allow multifamily and mixed-use near commercial corridors while protecting most residential zones.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2026/01/02/a-completely-different-town-prosper-looks-to-balance-growth-with-small-town-roots/',
        'https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2026/03/16/prosper-plans-for-mixed-use-multifamily-areas-ahead-of-2027-tollway-expansion/',
        'https://candysdirt.com/2024/09/05/garden-style-apartments-banned-in-prosper-under-new-zoning-regulations/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-...)
-- No public record found. Topic has not surfaced in mayor statements, campaign materials,
-- or local coverage.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d65e3760-95f3-4ad5-ba29-be01a76ae23b', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: davidfbristol.com, communityimpact.com, weareprosper.com, citylifestyle.com. Topic has not surfaced in any mayor public statements or council records.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-...)
-- Bristol chaired the 2020 Bond Committee which included $210M for public safety,
-- infrastructure, and parks. As mayor he endorsed the Prosper Police Department''s
-- first-in-Texas drone program and the Special Purpose District renewals for police/fire
-- funding. He has consistently supported adding police staffing, equipment (AED grants,
-- Flock camera networks), and pay to improve response. Matches answer 4: increase police
-- staffing, equipment, and pay to improve response times and deter crime.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d65e3760-95f3-4ad5-ba29-be01a76ae23b', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d65e3760-95f3-4ad5-ba29-be01a76ae23b', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from record: Bristol chaired the 2020 $210M bond committee that funded police and fire expansion. As mayor he publicly endorsed the Prosper PD''s first-in-Texas Flock Aerodome drone program and the Special Purpose District renewals securing long-term police/fire funding. He has supported police equipment grants (AED, Flock cameras) and infrastructure improvements. No evidence of redirecting police budgets to social services or adding mental health co-responders. Consistent with answer 4: increase police staffing, equipment, and pay to improve response times and deter crime.',
  ARRAY['https://www.prospertx.gov/m/newsflash/home/detail/144',
        'https://davidfbristol.com/',
        'https://starlocalmedia.com/checkout/prosper/news/three-takeaways-from-prosper-mayor-david-bristol-s-state-of-the-community-address/article_40b622fa-cad1-11ee-ab28-67360121190b.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives (eb3d1247-...)
-- Bristol has served as PEDC president since 2017; the EDC explicitly uses grants,
-- tax abatements, and infrastructure incentives to attract major employers (healthcare,
-- tech). He specifically advocates for healthcare hub incentives, tech infrastructure
-- investment to attract employers, and creation of Prosper Exchange (business recruitment).
-- This matches answer 4: compete actively for major employers with significant tax
-- abatements and infrastructure investment.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d65e3760-95f3-4ad5-ba29-be01a76ae23b', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d65e3760-95f3-4ad5-ba29-be01a76ae23b', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from record: Bristol is President of the Prosper Economic Development Corporation (PEDC), a 4A sales tax corporation that issues grants and tax abatements to attract major employers. He has explicitly advocated for technology infrastructure incentives to attract tech-dependent businesses and creating healthcare hub incentives for pediatric facilities (Cook Children''s). He co-founded Prosper Exchange (SMU Cox partnership) for business recruitment. The PEDC actively competes for major employers with financial agreements and infrastructure investment, consistent with answer 4: compete actively for major employers with significant tax abatements and infrastructure investment.',
  ARRAY['https://prosperedc.com/index.php/about/board-of-directors/david-bristol/',
        'https://davidfbristol.com/',
        'https://prosperedc.com/site-selection/incentives/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities (ba59337e-...)
-- Bristol has consistently prioritized road widening and capacity: US 380 as the
-- "primary conduit," widening First Street, Coit Road, Gee Road; the $136M US 380
-- overpass project. He frames transportation investment around the majority who drive
-- ("primary conduit for travel") and student road safety. No evidence of transit,
-- bike lanes, or pedestrian-first priorities. Matches answer 4: focus on road capacity
-- and traffic flow; transportation investment should serve the majority who drive.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('d65e3760-95f3-4ad5-ba29-be01a76ae23b', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d65e3760-95f3-4ad5-ba29-be01a76ae23b', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from record: Bristol called US 380 the "primary conduit" for travel and has made road widening/capacity the centerpiece of Prosper''s infrastructure investment — First Street (2→4 lanes), Coit Road, Gee Road widening, Godwin Parkway, and the $136M US 380 overpass project. His State of the Community address highlighted accelerating road infrastructure for the driving majority. No evidence of investment priorities for transit, bike lanes, or pedestrian-first infrastructure. Matches answer 4: focus on road capacity and traffic flow; transportation investment should serve the majority who drive.',
  ARRAY['https://starlocalmedia.com/checkout/prosper/news/three-takeaways-from-prosper-mayor-david-bristol-s-state-of-the-community-address/article_40b622fa-cad1-11ee-ab28-67360121190b.html',
        'https://communityimpact.com/dallas-fort-worth/prosper-celina/transportation/2026/04/22/relieving-the-pressure-136m-us-380-project-adds-overpasses-reduces-congestion/',
        'https://davidfbristol.com/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement (b9ccee94-...)
-- No public record found. Topic has not surfaced in mayor statements or local press.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('d65e3760-95f3-4ad5-ba29-be01a76ae23b', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: davidfbristol.com, communityimpact.com, weareprosper.com, prospertx.gov. Topic has not surfaced in any mayor public statements or council records reviewed.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- CRAIG ANDRES — Council Member Place 2
-- ID: e4e763ca-14f6-4e19-98e7-6ab2d2c972bf
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- No public record found. Andres focuses on commercial development to lower property
-- taxes; no statements on affordable housing policy.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e4e763ca-14f6-4e19-98e7-6ab2d2c972bf', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. Checked: craigandresforprosper.com, communityimpact.com, weareprosper.com, starlocalmedia.com. Andres focuses on commercial development and infrastructure; no affordable housing policy statements found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-...)
-- No public record found. Topic has not surfaced for Andres in any coverage reviewed.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e4e763ca-14f6-4e19-98e7-6ab2d2c972bf', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Prosper has essentially no visible homelessness; topic has not surfaced in any Andres statements or local press coverage reviewed.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-...)
-- Andres has served on the Planning and Zoning Commission and supports commercial growth
-- along key corridors (DNT, US 380) to lower residential taxes, while balancing "small
-- town feel." As Deputy Mayor Pro-Tem he voiced that developer Toll Brothers had "come a
-- long way in addressing" council concerns, and voted to approve 775-home neighborhood.
-- His stated philosophy of corridor-focused commercial/mixed development with quality
-- standards aligns with the council mainstream (answer 3), but specific zoning votes are
-- not individually well-documented enough to distinguish from the group position.
-- Placing at 3 based on consistent corridor-focused philosophy and participation in
-- unanimous Aug 2024 vote banning garden-style apartments (restricting low-density
-- sprawl to push denser corridor multifamily).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4e763ca-14f6-4e19-98e7-6ab2d2c972bf', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e4e763ca-14f6-4e19-98e7-6ab2d2c972bf', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from record: Andres served on Planning and Zoning Commission before election, and consistently advocates corridor-focused commercial/residential development along Dallas North Tollway and US 380 to lower residential taxes. He voiced approval of Toll Brothers''s revised housing development, and participated in the unanimous Aug 2024 council vote banning garden-style apartments (pushing density toward denser corridor multifamily while protecting low-density residential areas). His stated philosophy of "balance between community and the growth" with quality corridors matches answer 3: allow multifamily and mixed-use near commercial corridors while protecting most residential zones.',
  ARRAY['https://craigandresforprosper.com/',
        'https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2025/10/16/prosper-council-approves-775-home-neighborhood-off-parvin-road/',
        'https://therealdeal.com/texas/2024/09/06/prosper-bans-new-garden-apartments-in-density-push/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e4e763ca-14f6-4e19-98e7-6ab2d2c972bf', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: craigandresforprosper.com, communityimpact.com, weareprosper.com. Topic has not surfaced in any Andres statements or council records.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-...)
-- Andres cited the $210M bond (including first responder funding) as a key priority and
-- advocates "responsible financial management" for first responder needs. No evidence of
-- redirecting police budgets or adding co-responders. Consistent with maintaining/adding
-- public safety funding but not specific enough for a placement beyond the general council
-- consensus position.
-- Not placed — not enough individual-specific evidence to distinguish from group position.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e4e763ca-14f6-4e19-98e7-6ab2d2c972bf', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no individual-specific placement. Andres cited the $210M bond (including first responder funding) as a priority. Statement covers public safety generally but does not distinguish his position from the broader council consensus. No individual votes or quotes specific to police staffing levels or budget allocation found.',
  ARRAY['https://craigandresforprosper.com/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives (eb3d1247-...)
-- Andres explicitly states commercial development is needed to "hold or reduce property
-- taxes" and supports corridors along DNT and US 380 for "corporate office" attraction.
-- He supported the Cook Children''s development agreement as Deputy Mayor Pro-Tem (made
-- the motion to approve). EDC incentive use is core to Prosper''s strategy which Andres
-- has consistently championed. Consistent with answer 4: compete actively for major
-- employers with significant tax abatements and infrastructure investment.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e4e763ca-14f6-4e19-98e7-6ab2d2c972bf', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e4e763ca-14f6-4e19-98e7-6ab2d2c972bf', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from record: Andres explicitly stated that commercial development is needed to "hold or reduce property taxes" and cited the DNT and US 380 corridors as key targets for "corporate office along with quality shopping, restaurants, and entertainment venues." As Deputy Mayor Pro-Tem he made the motion to approve the First Amendment to the Development Agreement with Cook Children''s Health Care System. Prosper''s EDC strategy of tax abatements and infrastructure agreements, which Andres has consistently championed, matches answer 4: compete actively for major employers with significant tax abatements and infrastructure investment.',
  ARRAY['https://craigandresforprosper.com/',
        'https://weareprosper.com/2021/04/15/meet-the-prosper-town-council-candidates-may-1-2021/',
        'https://prosperedc.com/site-selection/incentives/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities (ba59337e-...)
-- Andres has highlighted road transportation challenges with TXDOT, NTTA, Collin/Denton
-- counties as a top issue, and his campaign focuses on road coordination. No evidence of
-- transit, cycling, or pedestrian priorities beyond the general town context.
-- Not placed — road focus is documented but not specific enough to distinguish answer 3 vs 4.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e4e763ca-14f6-4e19-98e7-6ab2d2c972bf', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no specific placement. Andres cited road transportation coordination with TXDOT, NTTA, Collin and Denton counties as a major issue, but statements focus on funding/coordination rather than specific investment priorities between road capacity vs. multimodal options. Not enough individual-specific evidence to place.',
  ARRAY['https://craigandresforprosper.com/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement (b9ccee94-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e4e763ca-14f6-4e19-98e7-6ab2d2c972bf', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: craigandresforprosper.com, communityimpact.com, weareprosper.com. Topic has not surfaced in any Andres statements or council records.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- AMY BARTLEY — Council Member Place 3 (Mayor Pro-Tem)
-- ID: 3631dd31-cb1a-46e1-ae2d-da54ea911411
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3631dd31-cb1a-46e1-ae2d-da54ea911411', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. Checked: communityimpact.com, weareprosper.com, eu.prosperpressnews.com, prospertx.gov. Topic has not surfaced in any Bartley statements or council records.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-...)
-- No public record found. Topic has not surfaced for Bartley in any coverage reviewed.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3631dd31-cb1a-46e1-ae2d-da54ea911411', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Prosper has essentially no visible homelessness; topic has not surfaced in any Bartley statements or local press coverage reviewed.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-...)
-- Bartley led the adoption of the Feb 2026 DNT Design Guidelines (tollway zoning
-- standards) splitting Prosper''s 3 miles of tollway into seven districts with
-- mixed-use/multifamily-in-corridors and mixed-density villages. She stated the
-- standards represent "the will of our neighbors" and guide "thoughtful" development.
-- She required upscale hospitality/retail tenants for Pradera mixed-use (for-sale and
-- for-rent condos). This directly matches answer 3: allow multifamily and mixed-use
-- near commercial corridors while protecting most residential zones.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3631dd31-cb1a-46e1-ae2d-da54ea911411', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3631dd31-cb1a-46e1-ae2d-da54ea911411', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from direct statements: Mayor Pro-Tem Bartley led adoption of Prosper''s Feb 2026 DNT Design Guidelines, splitting the tollway into seven mixed-use/multifamily districts while protecting remaining residential zones. She stated the standards represent "the will of our neighbors" and will guide "thoughtful" development along the tollway. On Pradera development, she required upscale hospitality/retail and a mix of for-rent and for-sale condos, saying "I wanted people to be able to purchase condos or other kinds of lifestyle housing and live here and be invested here." This matches answer 3: allow multifamily and mixed-use near commercial corridors while protecting most residential zones.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2026/03/16/prosper-plans-for-mixed-use-multifamily-areas-ahead-of-2027-tollway-expansion/',
        'https://localprofile.com/news/35-acre-development-prosper-zoning-7507148',
        'https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2025/08/27/prosper-council-approves-additional-housing-for-gates-of-prosper-development/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3631dd31-cb1a-46e1-ae2d-da54ea911411', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: communityimpact.com, weareprosper.com, eu.prosperpressnews.com. Topic has not surfaced in any Bartley statements or council records.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-...)
-- Bartley praised the $192.3M bond work and supported a bond that included police
-- additions and a new public library. She praised the bond committee''s work and noted
-- "We have a lot more projects than we have money." The bond included police department
-- additions — supporting increased police capacity. Consistent with answer 4: increase
-- police staffing, equipment, and pay.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('3631dd31-cb1a-46e1-ae2d-da54ea911411', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3631dd31-cb1a-46e1-ae2d-da54ea911411', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from record: Bartley praised the $192.3M bond committee''s work and the council unanimously voted to place the bond on the November 2025 ballot. The bond package included additions to the Prosper Police Department, new public library, and roadwork — all categorized under public safety and infrastructure. Bartley requested expanding silo renovation funds, indicating engagement with individual bond line items. Council supported police additions as core to the bond. Consistent with answer 4: increase police staffing, equipment, and pay to improve response times and deter crime.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2025/08/13/prosper-council-calls-1923m-november-bond-election/',
        'https://starlocalmedia.com/checkout/prosper/prosper-voters-to-determine-192m-bond-in-november/article_c1f1e7f5-0d21-428f-8ae6-bee23df8b7ca.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives (eb3d1247-...)
-- No individual-specific placement. Bartley''s economic development positions track the
-- council mainstream but no distinct personal statements on incentive philosophy found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3631dd31-cb1a-46e1-ae2d-da54ea911411', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no individual-specific placement. Bartley''s economic development role tracks the council mainstream (PEDC, bond support), but no individual statements distinguishing her position on incentive philosophy were found. Checked: communityimpact.com, weareprosper.com, eu.prosperpressnews.com.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2025/08/13/prosper-council-calls-1923m-november-bond-election/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities (ba59337e-...)
-- No individual-specific placement found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3631dd31-cb1a-46e1-ae2d-da54ea911411', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no individual-specific placement. The $192.3M bond included $8.5M for DNT-related roadwork, which Bartley supported, but no specific statements on transportation priorities beyond road improvements were found.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2025/08/13/prosper-council-calls-1923m-november-bond-election/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement (b9ccee94-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3631dd31-cb1a-46e1-ae2d-da54ea911411', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: communityimpact.com, weareprosper.com, eu.prosperpressnews.com. Topic has not surfaced in any Bartley statements or council records.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- CHRIS KERN — Council Member Place 4 (Deputy Mayor Pro-Tem)
-- ID: 0b5356c6-178b-4898-afd9-9883d2bce114
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b5356c6-178b-4898-afd9-9883d2bce114', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. Checked: kernforprosper.com, communityimpact.com, weareprosper.com, citizenportal.ai. Topic has not surfaced in any Kern statements or council records.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b5356c6-178b-4898-afd9-9883d2bce114', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Prosper has essentially no visible homelessness; topic has not surfaced in any Kern statements or local press coverage reviewed.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-...)
-- Kern voted AGAINST Gates of Prosper multifamily addition (Aug 2025) and voted against
-- the Prosper Arts District development. He explicitly said "I continue to have heartburn
-- with the overall number and the longevity of this project" regarding apartment counts.
-- His concern was that approving more multifamily would "limit future growth opportunities,
-- particularly in the southern parts of town." He served on P&Z for 3 years, where he
-- reviewed requests with a skeptical-of-density lens. This pattern aligns with answer 2:
-- allow modest density increases (duplexes, accessory units) with strong design review
-- and neighborhood input, but resist large-scale multifamily expansions beyond existing caps.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0b5356c6-178b-4898-afd9-9883d2bce114', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b5356c6-178b-4898-afd9-9883d2bce114', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from votes and statements: Kern voted against Gates of Prosper multifamily additions (Aug 2025) and the Prosper Arts District, saying "I continue to have heartburn with the overall number and the longevity of this project" re: apartment unit counts. He expressed concern that adding multifamily would limit future growth in southern Prosper. He served 3 years on the Planning and Zoning Commission reviewing proposals with consistent skepticism of density. His pattern — supporting the existing plan but opposing density beyond caps — aligns with answer 2: allow modest density increases with strong design review and neighborhood input, resist broad multifamily expansion.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2025/08/27/prosper-council-approves-additional-housing-for-gates-of-prosper-development/',
        'https://localprofile.com/news/35-acre-development-prosper-zoning-7507148',
        'https://kernforprosper.com/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b5356c6-178b-4898-afd9-9883d2bce114', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: kernforprosper.com, communityimpact.com, weareprosper.com. Topic has not surfaced in any Kern statements or council records.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-...)
-- Kern''s campaign explicitly listed "commitment to safety by supporting police and fire
-- chiefs" as a core value, and cited fiscal responsibility for infrastructure including
-- public safety. Consistent with maintaining/increasing police capacity. Matches answer 4.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0b5356c6-178b-4898-afd9-9883d2bce114', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b5356c6-178b-4898-afd9-9883d2bce114', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from campaign statement: Kern''s campaign platform explicitly listed "commitment to safety by supporting police and fire chiefs" as a forefront value alongside fiscal responsibility. No evidence of redirecting police budgets to social services or adding mental health co-responders. Consistent with answer 4: increase police staffing, equipment, and pay to improve response times and deter crime.',
  ARRAY['https://kernforprosper.com/',
        'https://citizenportal.ai/articles/3290999/Prosper/Collin-County/Texas/Prosper-Town-Council-welcomes-new-members-Marcus-Ray-and-Chris-Kern'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives (eb3d1247-...)
-- No individual-specific placement. Kern supports fiscal responsibility and infrastructure
-- funding but no specific statements on EDC incentive philosophy found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b5356c6-178b-4898-afd9-9883d2bce114', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no individual-specific placement. Kern supports fiscal responsibility and commercial development generally but no individual statements on EDC incentive philosophy or specific corporate incentive votes were found. Checked: kernforprosper.com, communityimpact.com, citizenportal.ai.',
  ARRAY['https://kernforprosper.com/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities (ba59337e-...)
-- No individual-specific placement found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b5356c6-178b-4898-afd9-9883d2bce114', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no individual-specific placement. No specific transportation priority statements found beyond general infrastructure support. Checked: kernforprosper.com, communityimpact.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement (b9ccee94-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('0b5356c6-178b-4898-afd9-9883d2bce114', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: kernforprosper.com, communityimpact.com. Topic has not surfaced in any Kern statements or council records.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- JEFF HODGES — Council Member Place 5
-- ID: c5396e9d-1a97-40ac-a877-4b6512934099
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5396e9d-1a97-40ac-a877-4b6512934099', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. Checked: prospertx.gov, communityimpact.com, weareprosper.com, eu.prosperpressnews.com. Topic has not surfaced in any Hodges statements or council records.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5396e9d-1a97-40ac-a877-4b6512934099', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Prosper has essentially no visible homelessness; topic has not surfaced in any Hodges statements or local press coverage reviewed.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-...)
-- No individual-specific placement. Hodges has voted on development matters (seconding
-- Downtown rezoning motions 2020) but no specific density philosophy statements found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5396e9d-1a97-40ac-a877-4b6512934099', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no individual-specific placement. Hodges voted on several development matters (seconded Downtown rezoning motions in 2020) and voted in opposition on one unspecified zoning matter (6-1 vote), but no individual statements or quotes on density philosophy were found. Checked: prospertx.gov, communityimpact.com, eu.prosperpressnews.com.',
  ARRAY['https://eu.prosperpressnews.com/story/news/2020/10/07/meet-candidates-vying-for-prosper-town-council-seats/114235148/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5396e9d-1a97-40ac-a877-4b6512934099', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: prospertx.gov, communityimpact.com, weareprosper.com. Topic has not surfaced in any Hodges statements or council records.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-...)
-- Hodges served as Vice-President of the Special Purpose District Board for the
-- one-half-cent sales tax dedicated to the Police and Fire Departments, and served
-- as Vice-President of NCT9-1-1. He has identified public safety as "one of his main
-- focuses." This active role in securing dedicated police/fire funding matches answer 4:
-- increase police staffing, equipment, and pay.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('c5396e9d-1a97-40ac-a877-4b6512934099', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5396e9d-1a97-40ac-a877-4b6512934099', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from record: Hodges served as Vice-President of the Special Purpose District Board of Directors for the one-half-cent sales tax dedicated exclusively to Police and Fire Departments, and served as Vice-President of NCT9-1-1. Local press noted public safety as "one of his main focuses" during his council tenure. His active role in creating and managing dedicated police/fire funding streams is consistent with answer 4: increase police staffing, equipment, and pay to improve response times and deter crime.',
  ARRAY['https://eu.prosperpressnews.com/story/news/2020/10/07/meet-candidates-vying-for-prosper-town-council-seats/114235148/',
        'https://www.prospertx.gov/directory.aspx?eid=68'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives (eb3d1247-...)
-- No individual-specific placement found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5396e9d-1a97-40ac-a877-4b6512934099', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no individual-specific placement. No specific statements on economic development incentive philosophy found for Hodges. Checked: prospertx.gov, communityimpact.com, weareprosper.com, eu.prosperpressnews.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities (ba59337e-...)
-- Hodges serves on the Hike and Bike Trail Steering Committee and served 3 years on
-- the Parks and Recreation Board before election. His focus on hike/bike infrastructure
-- indicates some prioritization of non-motorized multimodal options, but not at the
-- level of answer 1-2 (prioritize pedestrian/cycling/transit over roads). The committee
-- role alone is insufficient to place — Prosper''s hike/bike trails are a parks amenity,
-- not a transportation-priority statement.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5396e9d-1a97-40ac-a877-4b6512934099', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no individual-specific placement. Hodges serves on the Hike and Bike Trail Steering Committee and prior Parks and Recreation Board — indicating interest in non-motorized infrastructure, but these are parks amenities, not transportation policy priorities. No statements on road vs. transit vs. cycling investment prioritization found. Checked: prospertx.gov, communityimpact.com, eu.prosperpressnews.com.',
  ARRAY['https://eu.prosperpressnews.com/story/news/2020/10/07/meet-candidates-vying-for-prosper-town-council-seats/114235148/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement (b9ccee94-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5396e9d-1a97-40ac-a877-4b6512934099', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: prospertx.gov, communityimpact.com, weareprosper.com. Topic has not surfaced in any Hodges statements or council records.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- CAMERON REEVES — Council Member Place 6
-- ID: ab366066-cb11-46db-9d87-6506048389f6
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab366066-cb11-46db-9d87-6506048389f6', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. Checked: communityimpact.com, prospertx.gov, weareprosper.com. Reeves joined council May 2024; no affordable housing policy statements found.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab366066-cb11-46db-9d87-6506048389f6', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Prosper has essentially no visible homelessness; topic has not surfaced in any Reeves statements or local press coverage reviewed.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-...)
-- Reeves explicitly stated he does not support altering the future land use plan,
-- "particularly to increase the density designation from medium to high," adding
-- "The future land use plan [is] there for a reason, especially in these outskirt areas."
-- His P&Z Commission background and opposition to density increases aligns with
-- answer 2: allow modest density increases (duplexes, accessory units) with strong
-- design review and neighborhood input, but hold the line on the overall plan.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('ab366066-cb11-46db-9d87-6506048389f6', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab366066-cb11-46db-9d87-6506048389f6', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from direct statement: Reeves said he does not support altering the future land use plan "particularly to increase the density designation from medium to high," adding "The future land use plan [is] there for a reason, especially in these outskirt areas." He has P&Z Commission experience and a community focus consistent with deferring to the approved plan and allowing only modest, plan-conforming density. This matches answer 2: allow modest density increases with strong design review and neighborhood input; resist upzoning beyond the existing plan.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2025/09/01/prosper-council-tables-zoning-change-for-374-acre-housing-development-off-parvin-road/',
        'https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2024/05/07/meet-cameron-reeves-prospers-newest-town-council-member/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab366066-cb11-46db-9d87-6506048389f6', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: communityimpact.com, prospertx.gov, weareprosper.com. Topic has not surfaced in any Reeves statements or council records.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-...)
-- No individual-specific placement. Reeves supports the general council approach but
-- no individual statements on police funding philosophy found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab366066-cb11-46db-9d87-6506048389f6', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no individual-specific placement. Reeves joined council in May 2024 and serves as 2025 Bond Committee liaison (bond includes police additions), but no individual statements on police staffing or public safety funding philosophy were found. Checked: communityimpact.com, prospertx.gov.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2024/05/07/meet-cameron-reeves-prospers-newest-town-council-member/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives (eb3d1247-...)
-- No individual-specific placement found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab366066-cb11-46db-9d87-6506048389f6', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no individual-specific placement. No specific statements on economic development incentive philosophy found for Reeves. Checked: communityimpact.com, prospertx.gov, weareprosper.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities (ba59337e-...)
-- No individual-specific placement found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab366066-cb11-46db-9d87-6506048389f6', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no individual-specific placement. No specific transportation priority statements found for Reeves. Checked: communityimpact.com, prospertx.gov.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement (b9ccee94-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('ab366066-cb11-46db-9d87-6506048389f6', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: communityimpact.com, prospertx.gov. Topic has not surfaced in any Reeves statements or council records.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- ============================================================
-- MARCUS RAY — Council Member Place 1
-- ID: e89206d9-e960-472f-8402-691dc498355e
-- ============================================================

-- 1. Affordable Housing (669cac97-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e89206d9-e960-472f-8402-691dc498355e', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. Checked: facebook.com/mr4Prosper, communityimpact.com, weareprosper.com. Topic has not surfaced in any Ray statements or council records.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e89206d9-e960-472f-8402-691dc498355e', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Prosper has essentially no visible homelessness; topic has not surfaced in any Ray statements or local press coverage reviewed.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-...)
-- Ray is a frequent and consistent opponent of multifamily density increases. He voted
-- against Gates of Prosper multifamily additions (Aug 2025) stating "I have significant
-- heartburn with the quantity of multifamily" and "There''s not one [resident] that says
-- they want more multifamily." He called for council to "hold the line to be consistent"
-- with Prosper''s established multifamily standards, and questioned Bella Prosper
-- (Feb 2026): "I don''t know if this makes sense where it''s at." His voting pattern and
-- statements reflect protecting existing neighborhood character and resisting further
-- density — matches answer 1: protect existing neighborhood character strictly; require
-- community votes before any rezoning.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('e89206d9-e960-472f-8402-691dc498355e', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e89206d9-e960-472f-8402-691dc498355e', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from votes and statements: Ray voted against Gates of Prosper multifamily additions (Aug 2025), saying "I have significant heartburn with the quantity of multifamily" and "There''s not one [resident] that says they want more multifamily." He called for council to "hold the line to be consistent." In Feb 2026 he questioned Bella Prosper multifamily: "I don''t know if this makes sense where it''s at." He is described as a "frequent skeptic of density and ''generic'' development" who "often pulls items to record opposition to multifamily." His sustained opposition to any density beyond existing caps matches answer 1: protect existing neighborhood character strictly.',
  ARRAY['https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2025/08/27/prosper-council-approves-additional-housing-for-gates-of-prosper-development/',
        'https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2026/02/25/prosper-town-council-tables-302m-bella-prosper-development-for-third-time/',
        'https://communityimpact.com/dallas-fort-worth/prosper-celina/government/2026/01/02/a-completely-different-town-prosper-looks-to-balance-growth-with-small-town-roots/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e89206d9-e960-472f-8402-691dc498355e', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: facebook.com/mr4Prosper, communityimpact.com, weareprosper.com, vote-usa.org. Topic has not surfaced in any Ray statements or council records.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-...)
-- No individual-specific placement. Ray serves on the Finance and Broadband Committees
-- and previously on NCTCOG Emergency Response Council. No specific police funding
-- philosophy statements found beyond general council consensus.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e89206d9-e960-472f-8402-691dc498355e', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no individual-specific placement. Ray serves on Finance and Broadband Committees, and previously on NCTCOG Emergency Response Council, but no individual statements distinguishing his police funding philosophy from the council consensus were found. Checked: facebook.com/mr4Prosper, communityimpact.com, weareprosper.com.',
  ARRAY['https://www.prospertx.gov/directory.aspx?eid=64'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives (eb3d1247-...)
-- No individual-specific placement found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e89206d9-e960-472f-8402-691dc498355e', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no individual-specific placement. No specific statements on economic development incentive philosophy found for Ray. Checked: facebook.com/mr4Prosper, communityimpact.com, weareprosper.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities (ba59337e-...)
-- No individual-specific placement found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e89206d9-e960-472f-8402-691dc498355e', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no individual-specific placement. No specific transportation priority statements found for Ray. Checked: facebook.com/mr4Prosper, communityimpact.com, weareprosper.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement (b9ccee94-...)
-- No public record found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('e89206d9-e960-472f-8402-691dc498355e', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: facebook.com/mr4Prosper, communityimpact.com, weareprosper.com. Topic has not surfaced in any Ray statements or council records.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
