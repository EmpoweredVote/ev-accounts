BEGIN;

-- JAY NORTHCUT — Mayor
-- ID: b8d0cef2-3787-4074-9d85-81a9d27aaef8
-- Sources: jayformelissamayor.com (campaign website), cityofmelissa.com

-- 1. Affordable Housing (669cac97-66a6-4087-b036-936fbe62efb3)
-- No public statement found on affordable housing programs, rent caps, or subsidies.
-- Campaign focuses on property tax reductions and homestead exemptions but not housing supply policy.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8d0cef2-3787-4074-9d85-81a9d27aaef8', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found on affordable housing policy. Campaign touts property tax rate reduction (20% since FY2021) and senior tax freeze but no stated position on housing affordability programs. Checked: jayformelissamayor.com, cityofmelissa.com, local news searches.',
  ARRAY['https://jayformelissamayor.com/home', 'https://www.cityofmelissa.com/271'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness (4938766b-b45a-46e3-93bd-b8b30651271a)
-- No public statement found. Melissa is a small fast-growing suburb; homelessness not a documented council issue.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8d0cef2-3787-4074-9d85-81a9d27aaef8', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Homelessness has not surfaced as a policy issue in Melissa city council records, campaign materials, or local news coverage. Checked: jayformelissamayor.com, cityofmelissa.com agendas, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning (d4f18138-a2e0-4110-b925-7387d9d0d16d)
-- Northcut''s tenure saw approval of multifamily developments (Eastwood Village Luxury Apartments ~$51M,
-- multiple townhome communities) near US 75 and commercial corridors, per TDLR records and local coverage.
-- Campaign website promotes 1.3M sq ft commercial approvals. No evidence of broad upzoning or eliminating
-- single-family zones. Pattern matches allowing multifamily near commercial corridors (answer 3).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8d0cef2-3787-4074-9d85-81a9d27aaef8', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8d0cef2-3787-4074-9d85-81a9d27aaef8', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Under Northcut''s mayoralty, Melissa approved multiple multifamily developments near US 75 and commercial corridors (Eastwood Village Luxury Apartments ~$51M est. completion 3/2025, multiple townhome rental communities including HARMON Melissa and FarmHouse121). City approved 1.3M sq ft commercial space since 2021. City Manager cited ~1,400 multifamily units in the pipeline. No evidence of broad upzoning or elimination of single-family zoning. Pattern matches answer 3: multifamily/mixed-use near commercial corridors while preserving most residential zones.',
  ARRAY['https://jayformelissamayor.com/home', 'https://www.tdlr.texas.gov/TABS/Search/Print/TABS2023009965', 'https://www.localprofile.com/real-estate/northern-collin-county-continues-to-boom-townhome-community-planned-for-melissa-10148558'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice (0bc588c6-39e1-4084-b5de-cac909b8b762)
-- No public statement found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8d0cef2-3787-4074-9d85-81a9d27aaef8', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Civil rights or racial equity policy has not appeared in Melissa city council records, campaign materials, or local news. Checked: jayformelissamayor.com, cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach (e9ebefcd-c496-45e8-b816-a79f8442ba85)
-- Campaign website explicitly states: "Police staffing increased by 79%", added traffic unit and commercial
-- vehicle enforcement unit, installed 22 LPR cameras, "crime won''t thrive in Melissa."
-- Council put Crime Control and Prevention District to voters (May 2024) reallocating sales tax to police/fire.
-- Matches answer 4: increase police staffing, equipment, and pay to improve response times and deter crime.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8d0cef2-3787-4074-9d85-81a9d27aaef8', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8d0cef2-3787-4074-9d85-81a9d27aaef8', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Campaign website explicitly: "Police staffing increased by 79%"; added traffic unit and commercial vehicle enforcement unit; installed 22 license plate reader cameras; fire staffing increased 80%; second fire station entering construction. Northcut led City Council in creating and putting to voters a Crime Control and Prevention District (May 2024) reallocating sales tax from industrial development to police/fire services. Quote: "crime won''t thrive in Melissa." Matches answer 4: increase police staffing, equipment, and pay.',
  ARRAY['https://jayformelissamayor.com/home', 'https://www.cityofmelissa.com/496/Crime-Control-Fire-Prevention-District-E'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives (eb3d1247-0de1-4b7f-baec-7259861efd53)
-- Campaign touts approving 1.3M sq ft commercial space since 2021, welcoming Walmart ("store of the future"),
-- Kroger, H-E-B, Cardinal Carrier Express. Sales tax revenue grew from $4.6M (2022) to $9.1M (2024).
-- City also reallocated industrial economic development sales tax to police/fire in 2024.
-- No literal mention of tax abatements but active competition for major employers with infrastructure investment.
-- Matches answer 4: compete actively for major employers with tax abatements and infrastructure investment.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8d0cef2-3787-4074-9d85-81a9d27aaef8', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8d0cef2-3787-4074-9d85-81a9d27aaef8', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Campaign website highlights approving 1.3M sq ft commercial space since 2021; landing Walmart "store of the future" (320 jobs, $1M+ tax revenue), H-E-B, Kroger, Cardinal Carrier Express; sales tax revenue grew $4.6M to $9.1M (2022-2024). City maintains active Economic Development Corporation (4A and 4B boards) and pursued commercial growth as core city priority. Matches answer 4: compete actively for major employers with significant infrastructure investment.',
  ARRAY['https://jayformelissamayor.com/home', 'https://www.cityofmelissa.com/199/Economic-Development'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities (ba59337e-30e2-4aba-a39a-426b3366eb27)
-- Campaign website focuses exclusively on road projects: Melissa Road reconstruction (Hwy 5 to 121),
-- Cardinal Road extension, TxDOT widening Hwy 5, FM 545 design phase, downtown street improvements.
-- No mention of transit, bike lanes, sidewalk networks, or pedestrian infrastructure beyond roads.
-- Voters passed $2.45M streets/roads bond May 2024. Matches answer 4: focus on road capacity and traffic flow.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b8d0cef2-3787-4074-9d85-81a9d27aaef8', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8d0cef2-3787-4074-9d85-81a9d27aaef8', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Campaign website transportation section is exclusively road-focused: Melissa Road reconstruction (Hwy 5 to 121 and west of Hwy 75), Cardinal Road extension to Highland Road, TxDOT widening Hwy 5, FM 545 in design phase, downtown street improvements. No mention of transit, bike infrastructure, or pedestrian networks. Council put $2.45M streets/roads bond to voters (passed May 2024). Matches answer 4: focus on road capacity and traffic flow; transportation investment should serve the majority who drive.',
  ARRAY['https://jayformelissamayor.com/home', 'https://www.nbcdfw.com/news/politics/lone-star-politics/may-4-election-results-collin-county/3532463/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement (b9ccee94-ad96-4f10-b655-889d8e5abe92)
-- No public statement found. Immigration enforcement has not appeared in Melissa city council records.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b8d0cef2-3787-4074-9d85-81a9d27aaef8', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Local immigration enforcement has not appeared in Melissa city council agendas, campaign materials, or news coverage. Checked: jayformelissamayor.com, cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- PRESTON TAYLOR — Council Member Place 1
-- ID: 3e377dbe-2c37-41ed-a65d-664de75318ae
-- 7th-generation Collin County resident; commercial real estate broker; former P&Z Commission chairman.
-- No individual policy positions found in public records.

-- 1. Affordable Housing
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3e377dbe-2c37-41ed-a65d-664de75318ae', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. No individual policy statements on affordable housing located in campaign materials, council records, or news coverage. Checked: Facebook campaign page, LinkedIn, cityofmelissa.com, localprofile.com.',
  ARRAY['https://www.facebook.com/PrestonForMelissaCityCouncilPlace1/', 'https://www.legistorm.com/person/bio/508430/Preston_Taylor.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3e377dbe-2c37-41ed-a65d-664de75318ae', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Homelessness has not surfaced as a policy issue in Melissa council records or coverage. Checked: Facebook campaign page, cityofmelissa.com, local news.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3e377dbe-2c37-41ed-a65d-664de75318ae', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no public record found. Taylor was chairman of P&Z Commission before joining council (May 2024) but no individual zoning philosophy or specific votes attributed to him in public records. Checked: Facebook campaign page, heartofmelissa.com podcast, LinkedIn, cityofmelissa.com.',
  ARRAY['https://www.heartofmelissa.com/s2-e4-preston-taylor-plan-accordingly/', 'https://www.linkedin.com/in/preston-taylor-a39027201/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3e377dbe-2c37-41ed-a65d-664de75318ae', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. No civil rights or equity policy positions located. Checked: Facebook campaign page, cityofmelissa.com, local news.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3e377dbe-2c37-41ed-a65d-664de75318ae', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no public record found. No individual public safety statements located. Checked: Facebook campaign page, cityofmelissa.com, local news.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3e377dbe-2c37-41ed-a65d-664de75318ae', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no public record found. No individual economic development positions located. Taylor''s commercial real estate background is noted but does not constitute a stated policy position. Checked: Facebook campaign page, LinkedIn, cityofmelissa.com.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3e377dbe-2c37-41ed-a65d-664de75318ae', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no public record found. No individual transportation positions located. Checked: Facebook campaign page, cityofmelissa.com, local news.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('3e377dbe-2c37-41ed-a65d-664de75318ae', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Immigration enforcement has not appeared in Melissa council records or coverage. Checked: Facebook campaign page, cityofmelissa.com, local news.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- RENDELL HENDRICKSON — Council Member Place 2
-- ID: af2697d7-f766-4ddd-8b61-65e5d0c2df70
-- No individual policy positions found in public records.

-- 1. Affordable Housing
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('af2697d7-f766-4ddd-8b61-65e5d0c2df70', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. No individual policy statements on affordable housing located. Checked: cityofmelissa.com, clustrmaps public records, local news searches.',
  ARRAY['https://www.cityofmelissa.com/202/City-Council'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('af2697d7-f766-4ddd-8b61-65e5d0c2df70', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Checked: cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('af2697d7-f766-4ddd-8b61-65e5d0c2df70', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no public record found. No individual zoning positions or votes attributed to Hendrickson in public records. Checked: cityofmelissa.com agendas, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('af2697d7-f766-4ddd-8b61-65e5d0c2df70', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('af2697d7-f766-4ddd-8b61-65e5d0c2df70', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no public record found. Checked: cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('af2697d7-f766-4ddd-8b61-65e5d0c2df70', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no public record found. Checked: cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('af2697d7-f766-4ddd-8b61-65e5d0c2df70', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no public record found. Checked: cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('af2697d7-f766-4ddd-8b61-65e5d0c2df70', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- DANA CONKLIN — Council Member Place 3
-- ID: 30680496-7464-495c-a9bc-eb44cc6b84b8
-- Campaign tagline: "Your neighbor & your voice in Melissa''s future." No individual policy positions found.

-- 1. Affordable Housing
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30680496-7464-495c-a9bc-eb44cc6b84b8', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. Campaign page tagline is "Your neighbor & your voice in Melissa''s future" but no specific housing policy positions located. Checked: Facebook campaign page, cityofmelissa.com, local news searches.',
  ARRAY['https://www.facebook.com/p/Dana-Conklin-Melissa-City-Council-Place-3-100078415706860/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30680496-7464-495c-a9bc-eb44cc6b84b8', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Checked: Facebook campaign page, cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30680496-7464-495c-a9bc-eb44cc6b84b8', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no public record found. No individual zoning positions or votes attributed to Conklin in public records. Checked: Facebook campaign page, cityofmelissa.com agendas, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30680496-7464-495c-a9bc-eb44cc6b84b8', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: Facebook campaign page, cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30680496-7464-495c-a9bc-eb44cc6b84b8', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no public record found. Checked: Facebook campaign page, cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30680496-7464-495c-a9bc-eb44cc6b84b8', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no public record found. Checked: Facebook campaign page, cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30680496-7464-495c-a9bc-eb44cc6b84b8', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no public record found. Checked: Facebook campaign page, cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('30680496-7464-495c-a9bc-eb44cc6b84b8', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: Facebook campaign page, cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- JOSEPH ARMSTRONG — Council Member Place 4
-- ID: 12d3560f-3b07-4fe7-b8c4-c2466c13e7eb
-- Background: former youth pastor, commercial construction professional, restaurant owner.
-- No individual policy positions found in public records.

-- 1. Affordable Housing
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('12d3560f-3b07-4fe7-b8c4-c2466c13e7eb', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. No individual housing policy positions located. Checked: Facebook page, heartofmelissa.com podcast, cityofmelissa.com, local news searches.',
  ARRAY['https://www.heartofmelissa.com/s2-e10-joseph-armstrong-forward-thinking-raising-the-bar/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('12d3560f-3b07-4fe7-b8c4-c2466c13e7eb', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Checked: Facebook page, cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('12d3560f-3b07-4fe7-b8c4-c2466c13e7eb', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no public record found. No individual zoning positions or votes attributed to Armstrong in public records. Checked: Facebook page, cityofmelissa.com agendas, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('12d3560f-3b07-4fe7-b8c4-c2466c13e7eb', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: Facebook page, cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('12d3560f-3b07-4fe7-b8c4-c2466c13e7eb', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no public record found. Checked: Facebook page, cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('12d3560f-3b07-4fe7-b8c4-c2466c13e7eb', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no public record found. Checked: Facebook page, cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('12d3560f-3b07-4fe7-b8c4-c2466c13e7eb', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no public record found. Checked: Facebook page, cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('12d3560f-3b07-4fe7-b8c4-c2466c13e7eb', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: Facebook page, cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- CRAIG ACKERMAN — Council Member Place 5 (Mayor Pro Tem)
-- ID: c5d9869d-6e7b-448d-bb48-43c2cd795d9a
-- No individual policy positions found in public records.

-- 1. Affordable Housing
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d9869d-6e7b-448d-bb48-43c2cd795d9a', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. No individual housing policy positions located. Checked: Facebook campaign page (Ackermanmelissacitycouncil), cityofmelissa.com, local news searches.',
  ARRAY['https://www.facebook.com/Ackermanmelissacitycouncil/', 'https://www.cityofmelissa.com/270'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d9869d-6e7b-448d-bb48-43c2cd795d9a', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Checked: Facebook campaign page, cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d9869d-6e7b-448d-bb48-43c2cd795d9a', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no public record found. No individual zoning positions or votes attributed to Ackerman in public records. Checked: Facebook campaign page, cityofmelissa.com agendas, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d9869d-6e7b-448d-bb48-43c2cd795d9a', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: Facebook campaign page, cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d9869d-6e7b-448d-bb48-43c2cd795d9a', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no public record found. No individual public safety positions located beyond council-wide support for Crime Control District. Checked: Facebook campaign page, cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d9869d-6e7b-448d-bb48-43c2cd795d9a', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no public record found. Checked: Facebook campaign page, cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d9869d-6e7b-448d-bb48-43c2cd795d9a', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no public record found. Checked: Facebook campaign page, cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('c5d9869d-6e7b-448d-bb48-43c2cd795d9a', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: Facebook campaign page, cityofmelissa.com, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;


-- SEAN LEHR — Council Member Place 6
-- ID: b3602d0c-9af7-4baf-a96c-a15be063c272
-- No individual policy positions found in public records.

-- 1. Affordable Housing
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b3602d0c-9af7-4baf-a96c-a15be063c272', '669cac97-66a6-4087-b036-936fbe62efb3',
  'Researched 2026-05-11 — no public record found. No individual housing policy positions located. Checked: cityofmelissa.com, YouTube Council Connect recaps, local news searches.',
  ARRAY['https://www.cityofmelissa.com/274/Sean-Lehr', 'https://www.youtube.com/watch?v=PkIDqC8yEUE'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b3602d0c-9af7-4baf-a96c-a15be063c272', '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Checked: cityofmelissa.com, YouTube Council Connect recaps, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b3602d0c-9af7-4baf-a96c-a15be063c272', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Researched 2026-05-11 — no public record found. No individual zoning positions or votes attributed to Lehr in public records. Checked: cityofmelissa.com agendas, YouTube Council Connect recaps, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b3602d0c-9af7-4baf-a96c-a15be063c272', '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Researched 2026-05-11 — no public record found. Checked: cityofmelissa.com, YouTube Council Connect recaps, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b3602d0c-9af7-4baf-a96c-a15be063c272', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no public record found. Checked: cityofmelissa.com, YouTube Council Connect recaps, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Economic Development Incentives
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b3602d0c-9af7-4baf-a96c-a15be063c272', 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Researched 2026-05-11 — no public record found. Checked: cityofmelissa.com, YouTube Council Connect recaps, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Transportation Priorities
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b3602d0c-9af7-4baf-a96c-a15be063c272', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no public record found. Checked: cityofmelissa.com, YouTube Council Connect recaps, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Local Immigration Enforcement
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b3602d0c-9af7-4baf-a96c-a15be063c272', 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Researched 2026-05-11 — no public record found. Checked: cityofmelissa.com, YouTube Council Connect recaps, local news searches.',
  '{}')
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
