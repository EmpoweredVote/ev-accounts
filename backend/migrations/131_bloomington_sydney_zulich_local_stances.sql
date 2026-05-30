-- Migration 131: Local Lens compass stances for Sydney Zulich
-- Bloomington City Common Council District 6 (politician_id: 0ed5eea3-27a1-4ed9-8f4b-409247322745)
-- Researched: 2026-05-11

BEGIN;

-- 1. Affordable Housing
-- Value 2: Use rent caps, require new developments to include affordable units, and publicly fund new housing
-- Evidence: Zulich is a self-described "advocate for more types of affordable housing," championed PILOT tax-exemption
-- programs for affordable housing developers, advocated SRO zoning via UDO amendment, and proposed a Hopewell PUD
-- condition requiring 15% permanently affordable units. Her positions go beyond mere "targeted help" to systemic
-- tools (inclusionary-style requirements, publicly funded affordability mechanisms).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0ed5eea3-27a1-4ed9-8f4b-409247322745', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0ed5eea3-27a1-4ed9-8f4b-409247322745',
  '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from council votes and statements. Zulich describes herself as "an advocate for more types of affordable housing." She championed PILOT (Payment in Lieu of Taxes) programs giving tax exemptions to affordable housing developers, advocated revising the UDO to allow Single Room Occupancy buildings as a low-cost housing pathway, and proposed that the Hopewell South PUD maintain 15% permanently affordable units. Her approach favors systemic policy tools — publicly funded incentives, inclusionary-style requirements, and zoning reforms — rather than simply subsidizing individual buyers or cutting red tape.',
  ARRAY[
    'https://www.idsnews.com/article/2024/09/bloomington-indiana-homelessness-city-council-meeting-sept11-2024',
    'https://www.ipm.org/news/2025-09-04/city-develops-affordable-housing-fund-to-comply-with-state-code',
    'https://bsquarebulletin.com/hopewell-south-pud-vote-postponed-by-bloomington-city-council-until-april-1/',
    'https://bsquarebulletin.com/start-of-process-for-possible-zoning-changes-halted-with-4-4-votes-by-bloomington-city-council/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness
-- Value 2: Decriminalizing public sleeping while investing in shelter capacity, outreach workers, and voluntary service connections
-- Evidence: Zulich explicitly called a 2023 camping ban "discriminatory" and said focus should be "reduction of harm and
-- preservation of dignity." She opposed enforcement-first approaches and instead championed SRO housing via UDO,
-- expanding public restrooms 24/7, and connecting individuals to services voluntarily.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0ed5eea3-27a1-4ed9-8f4b-409247322745', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0ed5eea3-27a1-4ed9-8f4b-409247322745',
  '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Direct evidence. Zulich called a September 2023 proposed camping ban "discriminatory" and argued the community "should be focusing on two things when it comes to the homeless population, and that''s reduction of harm and preservation of dignity. This bill does neither of these things." She noted that targeting belongings unhoused people carry inevitably targets unhoused people themselves. Her policy advocacy focuses on decriminalization paired with structural housing solutions: revising the UDO to allow Single Room Occupancy buildings, expanding 24/7 public restroom access, and changing family-definition zoning rules to allow more shared housing.',
  ARRAY[
    'https://www.ipm.org/2023-09-14/city-council-rejects-effort-to-prevent-camping-on-sidewalks-streets',
    'https://www.idsnews.com/article/2024/09/bloomington-indiana-homelessness-city-council-meeting-sept11-2024'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning
-- Value 3: Allow multifamily and mixed-use near commercial corridors while protecting most residential zones
-- Evidence: Zulich was absent for the March 2025 vote on broad upzoning (duplexes/triplexes citywide, parking
-- elimination) but stated process concerns without endorsing the substance. She supported Hopewell PUD with
-- affordability conditions and UDO revisions for SRO. Her pattern is cautious support for targeted density
-- increases (affordable units, SROs) while not clearly endorsing wholesale elimination of single-family zoning.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0ed5eea3-27a1-4ed9-8f4b-409247322745', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0ed5eea3-27a1-4ed9-8f4b-409247322745',
  'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Inferred from votes and statements. Zulich was absent when the council split 4-4 on March 2025 resolutions that would have allowed duplexes, triplexes, and quadplexes citywide and eliminated parking minimums. She stated she is "an advocate for more types of affordable housing" but criticized the short-notice legislative process, stopping short of indicating how she would have voted on the substance. She supported Hopewell South PUD (a mixed-use development with affordability conditions) and championed UDO changes to allow Single Room Occupancy buildings. Her pattern suggests comfort with targeted multifamily additions and affordable unit requirements but caution about broad upzoning of all residential zones — consistent with value 3.',
  ARRAY[
    'https://bsquarebulletin.com/start-of-process-for-possible-zoning-changes-halted-with-4-4-votes-by-bloomington-city-council/',
    'https://www.idsnews.com/article/2025/03/city-council-udo-residential-upzoning',
    'https://bsquarebulletin.com/hopewell-south-pud-vote-postponed-by-bloomington-city-council-until-april-1/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice
-- Value 2: Strengthen civil rights enforcement and address systemic discrimination
-- Evidence: Zulich was part of the council that unanimously created the joint Bloomington/Monroe County Human Rights
-- Commission. She published a letter expressing solidarity with pro-Palestinian protesters and First Amendment rights.
-- Bloomington earned a perfect score on HRC's Municipal Equality Index nine consecutive years. The city's 2020 Racial
-- Equity Plan created task forces to evaluate systemic racism including in law enforcement.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0ed5eea3-27a1-4ed9-8f4b-409247322745', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0ed5eea3-27a1-4ed9-8f4b-409247322745',
  '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Inferred from council actions and public statements. Zulich sits on a council that unanimously created the joint Bloomington/Monroe County Human Rights Commission (2023), which investigates civil rights complaints and advocates for strengthened protections. She published a letter on First Amendment rights regarding IU campus protests (April 2024) expressing pride in constituents standing up for their values. Bloomington has earned a perfect score on the Human Rights Campaign Municipal Equality Index nine consecutive years. No statements found endorsing reparations or mandated equity requirements (value 1), nor restricting civil rights enforcement (values 4-5).',
  ARRAY[
    'https://bloomington.in.gov/news/2023/05/11/5614',
    'https://bloomington.in.gov/news/2023/11/16/5789',
    'https://bloomingtonian.com/2024/04/30/letter-statement-regarding-the-violation-of-first-amendment-rights-on-iub-campus/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach
-- Value 3: Keep current public safety funding while adding crisis response teams for mental health and addiction calls
-- Evidence: Zulich did not advocate defunding or significantly cutting police. The 2026 budget maintained substantial
-- public safety funding (nearly half the budget). Bloomington has the Stride Crisis Center providing mental health
-- diversion and the Community Advisory on Public Safety Commission exploring alternatives. Zulich's budget priorities
-- focused on housing, environment, and transportation rather than police reform.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0ed5eea3-27a1-4ed9-8f4b-409247322745', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0ed5eea3-27a1-4ed9-8f4b-409247322745',
  'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Inferred from budget votes and council context. Zulich voted for the 2026 budget (approved 7-2) which kept substantial public safety funding and moved some police expenses to the LIT fund. She has not publicly advocated for defunding police or significantly redirecting the police budget to social services. Bloomington has the Stride Crisis Center providing mental health and substance-use diversion from jail and the city-council-created Community Advisory on Public Safety Commission to explore evidence-based alternatives. Her 2025-2026 priority areas centered on housing, environment, and transportation rather than police restructuring, suggesting she supports the current trajectory of maintaining police while adding crisis response capacity.',
  ARRAY[
    'https://bsquarebulletin.com/163m-budget-for-2026-okd-by-bloomington-councilmembers-2-dissent-citing-lack-of-trust/',
    'https://www.idsnews.com/article/2025/10/bloomington-city-council-adopts-2026-budget',
    'https://www.idsnews.com/article/2025/10/stride-crisis-bloomington-crime-rate-indiana-news-monroe-county-jail',
    'https://bloomington.in.gov/council/public-safety-advisory'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement
-- Value 2: Comply only with court-ordered detainers; protect undocumented crime victims and witnesses from referral
-- Evidence: Zulich explicitly praised ending the Flock contract because it prevented ICE data-sharing, stating she
-- hopes the city "can continue reducing its use of taxpayer resources to fund the surveillance of residents."
-- The council issued a joint statement condemning ICE raids as "wreaking real havoc." BPD chief states the department
-- does not inquire about immigration status and received no ICE cooperation requests in three years.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0ed5eea3-27a1-4ed9-8f4b-409247322745', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0ed5eea3-27a1-4ed9-8f4b-409247322745',
  'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Direct evidence. Zulich explicitly supported ending the city''s Flock camera contract, citing concern that Flock could share license plate data with ICE, stating she hopes the city "can continue reducing its use of taxpayer resources to fund the surveillance of residents." The Bloomington City Council — including Zulich — issued a joint statement in January 2026 characterizing ICE enforcement as targeting people "for reasons unrelated to legitimate public safety concerns" and condemning "militarized raids." The Bloomington Police Chief stated the department has a firewall between local policing and immigration enforcement and received no ICE cooperation requests in three years. The city''s pattern — refusing proactive cooperation but not fully refusing all federal contact — maps to value 2.',
  ARRAY[
    'https://www.idsnews.com/article/2026/04/city-of-bloomington-ends-flock-contract-data-sharing-with-indiana-law-enforcement',
    'https://www.wthr.com/article/news/local/bloomington-councilors-residents-police-questions-flock-cameras-surveillance/531-b49fa7f6-fbb9-4f4a-82a8-a6c5d3874697',
    'https://www.wglt.org/local-news/2026-03-27/bloomington-police-chief-reinforces-the-firewall-between-policing-and-immigration'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives
-- Value 3: Targeted incentives for specific industries with community benefit agreements and job quality requirements
-- Evidence: No direct statements found from Zulich on economic development incentives. Bloomington uses PILOT
-- programs (targeted tax exemptions for affordable housing with community benefit conditions), TIF districts, and
-- targeted incentive packages. Zulich's general center-left positioning and support for community benefit
-- agreements in housing (Hopewell PUD condition) suggests alignment with targeted incentives rather than
-- either no-subsidy or maximum-incentive approaches.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0ed5eea3-27a1-4ed9-8f4b-409247322745', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0ed5eea3-27a1-4ed9-8f4b-409247322745',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Inferred from general positioning. No direct statements from Zulich on business tax incentives or TIF districts were found. Bloomington uses targeted economic development tools including PILOT programs (tax exemptions for affordable housing developers with community benefit conditions), TIF districts, and company-specific incentive packages. Zulich''s pattern of requiring community benefit conditions in housing (her Hopewell PUD affordability requirement proposal) and her general center-left positioning suggest she would favor targeted incentives with community benefit requirements over either a no-subsidy or maximum-incentive approach. Treat this as a weak inference; no direct public record found.',
  ARRAY[
    'https://bloomington.in.gov/business/districts/tif',
    'https://bsquarebulletin.com/hopewell-south-pud-vote-postponed-by-bloomington-city-council-until-april-1/',
    'https://www.ipm.org/news/2025-09-04/city-develops-affordable-housing-fund-to-comply-with-state-code'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities
-- Value 2: Invest equally in roads and multimodal options; require bike lanes and sidewalks on all new road projects
-- Evidence: Zulich's 2021 campaign explicitly prioritized "better north-south bus service" and public transportation.
-- She voted to establish the Transportation Commission whose mandate explicitly "prioritizes nonautomotive modes and
-- sustainability." She discussed Bloomington Transit's downtown shuttle experiment positively. Her district
-- encompasses downtown, where pedestrian/transit infrastructure is a focus.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('0ed5eea3-27a1-4ed9-8f4b-409247322745', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '0ed5eea3-27a1-4ed9-8f4b-409247322745',
  'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Inferred from campaign platform and council votes. Zulich''s 2021 campaign explicitly listed "better north-south bus service" and public transportation as key priorities alongside personal safety. She voted to establish Bloomington''s new Transportation Commission, whose mandate explicitly includes "prioritizing nonautomotive modes and sustainability" — replacing the prior traffic, bicycle/pedestrian safety, and parking commissions. She appeared on The 812 podcast (May 2025) discussing Bloomington Transit''s downtown shuttle experiment positively. Her district includes downtown Bloomington where multimodal investments are concentrated. No statements found prioritizing roads or driving over transit.',
  ARRAY[
    'https://www.zulichforcouncil.com/',
    'https://bsquarebulletin.com/bloomington-district-6-city-council-dems-pick-zulich/',
    'https://bsquarebulletin.com/amid-shift-in-bloomington-street-oversight-flaherty-gets-city-council-nod-for-new-transportation-group-2/',
    'https://the812show.org/199-s3e46-councilmember-sydney-zulich-d-6-on-ongoing-improvements-to-downtown-bloomington/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
