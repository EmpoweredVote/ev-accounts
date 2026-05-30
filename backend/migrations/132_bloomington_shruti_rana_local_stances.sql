-- Migration 132: Local Lens compass stances for Shruti Rana
-- Bloomington City Common Council District 5 (politician_id: 57470eda-1734-4543-ae2a-893b8bcc0a86)
-- Researched: 2026-05-11
-- Note: Rana was elected Nov 2023, sworn in Jan 1 2024, resigned Feb 7 2024 (5 weeks in office).
-- She cast no substantive council votes. Evidence drawn entirely from 2022–2023 campaign materials,
-- forum coverage, and endorser statements.

BEGIN;

-- 1. Affordable Housing
-- Value 3: Offer targeted help like subsidies for affordable projects, first-time buyer assistance, and easier building permits
-- Evidence: Rana's campaign platform listed "fostering an environment to attract better jobs and opportunities"
-- and "supporting sustainable development." She discussed a "one-stop shop" approach where people facing
-- eviction could access mental health and substance abuse resources in one location, framing housing
-- instability as interconnected with other social supports. She cited IRA federal grant opportunities
-- as a mechanism to advance climate and housing goals. No evidence for rent caps, inclusionary mandates,
-- or public housing construction (values 1-2). No evidence for purely deregulatory approach (values 4-5).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('57470eda-1734-4543-ae2a-893b8bcc0a86', '669cac97-66a6-4087-b036-936fbe62efb3', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '57470eda-1734-4543-ae2a-893b8bcc0a86',
  '669cac97-66a6-4087-b036-936fbe62efb3',
  'Inferred from 2023 campaign materials and forum statements. Rana described housing as part of a "continuum of care" alongside mental health and substance abuse services, and proposed a "one-stop shop" where people facing eviction could access wraparound resources. She cited federal Inflation Reduction Act grants as a funding mechanism and emphasized "sustainable development." Her framing positions government as a targeted facilitator — connecting people to existing programs and attracting outside funding — rather than directly building public housing or mandating rent controls. No evidence found for rent caps, inclusionary requirements, or direct public housing development (values 1-2). No evidence for a deregulatory-only approach (values 4-5).',
  ARRAY[
    'https://bsquarebulletin.com/bloomington-city-council-district-5-democratic-party-primary-shruti-rana-jenny-stevens/',
    'https://specials.idsnews.com/bloomington-city-council-candidates-election-2023/',
    'https://www.ipm.org/2022-12-22/shruti-rana-announces-bid-for-bloomington-city-council-district-5'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 2. Criminalization of Homelessness
-- Not found: No specific public record found on her position on encampment enforcement or criminalization.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '57470eda-1734-4543-ae2a-893b8bcc0a86',
  '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Researched 2026-05-11 — no public record found. Rana resigned after 5 weeks in office, casting no substantive votes including on Bloomington homelessness enforcement debates. Her campaign mentioned housing instability and wraparound services but did not address encampment enforcement specifically. Checked: B Square Bulletin, Indiana Public Media/IPM, Indiana Daily Student, electshruti.com, Stop Bloomington Upzoning endorsement article, Bloomington Chamber candidate questionnaire page.',
  '{}'
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 3. Residential Zoning
-- Value 2: Allow modest density increases (duplexes, accessory units) with strong design review and neighborhood input
-- Evidence: Rana directly opposed top-down upzoning, stating: "I don't see people in my neighborhood
-- talking about issues like upzoning, except to say that's not something that they want." She asserted
-- that neighborhood sentiment should not be overridden by citywide initiatives and advocated for
-- consensus-building over rapid zoning changes. She questioned whether Bloomington faces compelling
-- population pressure requiring housing inventory expansion. Both she and her primary opponent (Stevens)
-- opposed the city administration's blanket upzoning approach. Rana's anti-upzoning group (Stop Bloomington
-- Upzoning) endorsed Stevens over Rana as marginally more moderate, suggesting Rana leaned toward
-- protecting neighborhood character while still being open to modest consensus-driven changes — value 2.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('57470eda-1734-4543-ae2a-893b8bcc0a86', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '57470eda-1734-4543-ae2a-893b8bcc0a86',
  'd4f18138-a2e0-4110-b925-7387d9d0d16d',
  'Direct evidence from 2023 primary campaign. Rana explicitly stated: "I don''t see people in my neighborhood talking about issues like upzoning, except to say that''s not something that they want," and asserted that she opposes top-down development approaches where citywide initiatives override neighborhood sentiment. She advocated consensus-building as a "slower but more sustainable approach to growth." She questioned whether Bloomington faces compelling population pressure requiring expanded housing inventory. The anti-upzoning blog "The Dissident Democrat / Stop Bloomington Upzoning" endorsed her opponent Jenny Stevens, characterizing Rana as slightly more resistant to citywide density increases. Rana''s stated approach — neighborhood consensus required before development, concern for neighborhood character — maps to value 2 (allow modest density increases with strong design review and neighborhood input) rather than value 1 (community votes before any rezoning) or values 4-5 (broad upzoning).',
  ARRAY[
    'https://stopbtownupzoning.org/2023/04/18/we-endorse-jenny-stevens-city-council-district-5/',
    'https://bsquarebulletin.com/bloomington-city-council-district-5-democratic-party-primary-shruti-rana-jenny-stevens/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 4. Civil Rights and Social Justice
-- Value 2: Strengthen civil rights enforcement and address systemic discrimination
-- Evidence: Rana ran explicitly "to promote civil and human rights for residents." She played a leading role
-- opposing Indiana's 2022 abortion ban (SB 1) and testified before the state Senate. She served on boards of
-- Monroe County NOW and the Indiana Chapter of the National Asian Pacific American Women's Forum. She is a
-- professor specializing in human rights and international law. She emphasized racial and gender equality
-- as campaign priorities. Endorsers noted her work on reproductive justice, LGBTQ rights, and racial justice.
-- No evidence for reparations mandates (value 1). No evidence for restricting civil rights enforcement
-- (values 4-5).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('57470eda-1734-4543-ae2a-893b8bcc0a86', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '57470eda-1734-4543-ae2a-893b8bcc0a86',
  '0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Direct evidence from campaign record. Rana ran explicitly on "promoting civil and human rights for residents," emphasizing racial and gender equality. She played a leading role in opposition to Indiana''s 2022 abortion ban (SB 1) and testified before the state Senate chamber. She served on the boards of Monroe County NOW and the Indiana Chapter of the National Asian Pacific American Women''s Forum, and is a professor specializing in human rights and international law with experience at the United Nations Division for the Advancement of Women. Her background demonstrates commitment to strengthening civil rights protections and addressing systemic discrimination. No evidence found for reparations mandates or mandatory racial equity requirements in all institutions (value 1). No evidence for limiting civil rights enforcement (values 4-5). Value 2 is strongly supported.',
  ARRAY[
    'https://www.ipm.org/2022-12-22/shruti-rana-announces-bid-for-bloomington-city-council-district-5',
    'https://specials.idsnews.com/bloomington-city-council-candidates-election-2023/',
    'https://bsquarebulletin.com/bloomington-city-council-district-5-democratic-party-primary-shruti-rana-jenny-stevens/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 5. Public Safety Approach
-- Not found: No direct statement on police funding or budget reallocation found.
-- Note: An endorser on her campaign website described her "positioning on a 'world without prisons'" as
-- "refreshing" and tied to "actual plans." She also served on the Bloomington Board of Public Safety and
-- advocated a "one-stop shop" for mental health and substance abuse services alongside housing. These signals
-- suggest a reform-oriented stance, but without a direct statement on police staffing or budget allocation
-- no reliable value can be assigned.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '57470eda-1734-4543-ae2a-893b8bcc0a86',
  'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Researched 2026-05-11 — no direct public record found on police funding or budget allocation. Contextual signals exist: an endorser on her campaign website described her "positioning on a ''world without prisons''" as "refreshing" and said she tied the vision to "actual plans we could put in place"; she served on the Bloomington Board of Public Safety; and she proposed a "one-stop shop" for mental health and substance abuse services. These point toward a reform-oriented stance but do not establish whether she favored redirecting police budget, co-responder models, or simply crisis response additions. She resigned after 5 weeks with no budget vote. Checked: electshruti.com endorsements, B Square Bulletin, Indiana Public Media, Indiana Daily Student.',
  ARRAY[
    'https://www.electshruti.com/endorsements',
    'https://bsquarebulletin.com/bloomington-city-council-district-5-democratic-party-primary-shruti-rana-jenny-stevens/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 6. Local Immigration Enforcement
-- Value 1: Refuse all ICE detainers; prohibit city employees from sharing immigration status information
-- Evidence: Rana is a professor specializing in human rights and immigration law, a board member of
-- Exodus Refugee Immigration (Bloomington's refugee resettlement organization), and has stated she is
-- "passionate about women's international human rights and immigrants' rights." Her city (Monroe County)
-- is listed as Indiana's only "sanctuary jurisdiction" on a Homeland Security watchlist. Bloomington's
-- policy is to not inquire about immigration status; the BPD chief stated a "firewall" between policing
-- and immigration enforcement. Given Rana's deep professional and advocacy commitment to immigrant
-- protection — including board service at Exodus when the organization faced state AG pressure over
-- alleged interference with federal immigration enforcement — value 1 is the most consistent inference.
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('57470eda-1734-4543-ae2a-893b8bcc0a86', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '57470eda-1734-4543-ae2a-893b8bcc0a86',
  'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Inferred from professional background and advocacy record. Rana is a professor of international law and human rights specializing in immigration and refugee law, and is a board member of Exodus Refugee Immigration — Bloomington''s refugee resettlement organization. She has publicly stated she is "passionate about immigrants'' rights" and that "immigrant women are some of the most vulnerable to legal and political attacks on fundamental rights." Monroe County (Bloomington) is listed as Indiana''s only "sanctuary jurisdiction" on a Homeland Security watchlist, and BPD maintains a stated firewall against immigration enforcement cooperation. Rana''s board service at Exodus — which faced state AG pressure over alleged interference with federal immigration enforcement — and her professional advocacy place her at the most protective end of the spectrum. No direct council vote on ICE detainers (she served only 5 weeks), but her positions are consistent with value 1 (refuse detainers; prohibit sharing immigration status information). This is an inference from advocacy record, not a direct public statement on detainer policy.',
  ARRAY[
    'https://www.ipm.org/2022-12-22/shruti-rana-announces-bid-for-bloomington-city-council-district-5',
    'https://www.all-options.org/shruti-rana/',
    'https://bloomingtonian.com/2025/05/30/monroe-county-named-indianas-only-sanctuary-jurisdiction-on-homeland-security-watchlist/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 7. Economic Development Incentives
-- Value 3: Targeted incentives for specific industries with community benefit agreements and job quality requirements
-- Evidence: Rana proposed conditioning business incentives on employers offering health benefits that cover
-- out-of-state reproductive care. This directly demonstrates she supports using economic development
-- incentives as a policy lever — not rejecting them (value 1-2) — but with explicit community benefit
-- conditions tied to job quality and employee welfare (value 3). She also emphasized "fostering an
-- environment to attract better jobs and opportunities" rather than maximizing any employer attraction
-- (values 4-5).
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('57470eda-1734-4543-ae2a-893b8bcc0a86', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '57470eda-1734-4543-ae2a-893b8bcc0a86',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Direct evidence from 2023 campaign. Rana proposed conditioning city business incentives on employers offering health benefits that cover out-of-state reproductive care — a concrete example of using targeted incentives with an explicit community benefit requirement (employee healthcare access). She also listed "fostering an environment to attract better jobs and opportunities" as a top-three campaign priority, indicating support for active economic development rather than a no-incentive approach. Her framing of attaching strings to incentives (reproductive health benefits as a condition) matches value 3 (targeted incentives for specific industries with community benefit agreements and job quality requirements). No evidence for a no-corporate-incentives approach (values 1-2) or a maximize-all-incentives stance (values 4-5).',
  ARRAY[
    'https://stopbtownupzoning.org/2023/04/18/we-endorse-jenny-stevens-city-council-district-5/',
    'https://bsquarebulletin.com/bloomington-city-council-district-5-democratic-party-primary-shruti-rana-jenny-stevens/',
    'https://www.ipm.org/2022-12-22/shruti-rana-announces-bid-for-bloomington-city-council-district-5'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- 8. Transportation Priorities
-- Not found: No direct statement on transportation investment priorities found.
-- Note: She was appointed to the Bloomington-Monroe County Metropolitan Planning Organization and the
-- Sidewalk Standing Committee, and her campaign listed transportation as a priority area. However, her
-- endorsers noted that District 5 is "relatively car-centric" and residents raised parking shortages at
-- parks as a concern — suggesting she was responsive to car-based constituents. No clear position on
-- transit vs. roads investment found.
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '57470eda-1734-4543-ae2a-893b8bcc0a86',
  'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Researched 2026-05-11 — no direct policy statement on transportation investment priorities found. Rana listed transportation as a campaign priority area and noted "housing, transportation, affordability, all of these things fit together." She was assigned to the Bloomington-Monroe County Metropolitan Planning Organization and the Sidewalk Standing Committee when she joined council, but served only 5 weeks and made no substantive statements on transit vs. road investment. Coverage described District 5 as "relatively car-centric" with residents raising parking shortages at parks as a concern, suggesting she was attentive to car-dependent constituents, but no position statement on investment priorities was found. Checked: B Square Bulletin, Stop Bloomington Upzoning endorsement piece, Indiana Daily Student, Indiana Public Media.',
  ARRAY[
    'https://stopbtownupzoning.org/2023/04/18/we-endorse-jenny-stevens-city-council-district-5/',
    'https://bsquarebulletin.com/bloomington-city-council-district-5-democratic-party-primary-shruti-rana-jenny-stevens/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
