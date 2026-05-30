-- Full coverage sprint for Sydney Kamlager-Dove (politician_id: a2c6adc7-7689-49b9-964f-8f2aeb243a83)
-- Group A: fill sources on 6 existing answers (ai-regulation, civil-rights, medicare/aid,
--          religious-freedom, ukraine-support, voting-rights)
-- Group B: insert 6 new answer+context rows (childcare, economic-development, school-vouchers,
--          homelessness, public-safety-approach, transportation-priorities)

-- ── GROUP A: Update existing context rows ────────────────────────────────────

UPDATE inform.politician_context
SET
  reasoning = 'Kamlager-Dove co-sponsored H.R. 1941 (Preventing Deepfakes of Intimate Images Act, 119th Congress), a targeted disclosure and consent bill addressing AI-generated non-consensual intimate imagery rather than broad AI restrictions. Her approach to AI reflects a narrowly tailored disclosure-and-harm-prevention framework without calling for industry-wide bans or broad government approval requirements. No evidence of co-sponsorship of expansive AI oversight legislation.',
  sources = ARRAY[
    'https://www.congress.gov/bill/119th-congress/house-bill/1941',
    'https://kamlager-dove.house.gov/issues/technology',
    'https://www.congress.gov/member/sydney-kamlager-dove/K000402?q=%7B%22search%22%3A%22AI%22%7D'
  ]
WHERE politician_id = 'a2c6adc7-7689-49b9-964f-8f2aeb243a83'
  AND topic_id = '666bf03d-81fc-4138-ab15-69ae734c9023';

UPDATE inform.politician_context
SET
  reasoning = 'Kamlager-Dove co-authored California''s CROWN Act (SB 188, 2019), prohibiting race-neutral policies that discriminate against natural hairstyles, and authored AB-118 (C.R.I.S.E.S. Grant Pilot Program, 2021), creating state grants for community-based equity infrastructure. She is an original cosponsor of the Equality Act (H.R. 15, 119th Congress), which mandates anti-discrimination protections across employment, housing, and public accommodations, and is a founding member of the Congressional Caucus on Black Women and Girls.',
  sources = ARRAY[
    'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201920200SB188',
    'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202120220AB118',
    'https://www.congress.gov/bill/119th-congress/house-bill/15'
  ]
WHERE politician_id = 'a2c6adc7-7689-49b9-964f-8f2aeb243a83'
  AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';

UPDATE inform.politician_context
SET
  reasoning = 'Kamlager-Dove was an original cosponsor of the Medicare for All Act (H.R. 3069, 119th Congress, introduced April 29, 2025), which would expand Medicare to cover all Americans in a single-payer system, and has cosponsored the same bill across prior sessions. She also cosponsored H.R. 3954 (Improving Access to Medicare Coverage Act of 2025). Her consistent cross-session record confirms a durable commitment to universal public-sector healthcare.',
  sources = ARRAY[
    'https://www.congress.gov/bill/119th-congress/house-bill/3069',
    'https://www.congress.gov/bill/119th-congress/house-bill/3954',
    'https://kamlager-dove.house.gov/issues/health-care'
  ]
WHERE politician_id = 'a2c6adc7-7689-49b9-964f-8f2aeb243a83'
  AND topic_id = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b';

UPDATE inform.politician_context
SET
  reasoning = 'Kamlager-Dove cosponsored the Equality Act (H.R. 15, 119th Congress), which prohibits discrimination based on sexual orientation and gender identity and explicitly excludes RFRA carve-outs, making civil rights protections non-negotiable over religious exemption claims. She also cosponsored the Global Respect Act (H.R. 6151), further reflecting a consistent prioritization of anti-discrimination protections over religious accommodation frameworks.',
  sources = ARRAY[
    'https://www.congress.gov/bill/119th-congress/house-bill/15',
    'https://www.congress.gov/bill/118th-congress/house-bill/6151',
    'https://kamlager-dove.house.gov/issues/lgbtq'
  ]
WHERE politician_id = 'a2c6adc7-7689-49b9-964f-8f2aeb243a83'
  AND topic_id = '6b9ba6d9-1001-43f5-b073-4d37130696fd';

UPDATE inform.politician_context
SET
  reasoning = 'The Ukraine Security Supplemental Appropriations Act (2024) passed the House with 210 Democrats voting yes and zero Democrats voting no, and Kamlager-Dove has no documented opposition to Ukraine military aid. She sits on the House Foreign Affairs Committee and has expressed no dissent from the Democratic caucus position of continued military, economic, and humanitarian support for Ukraine against Russian aggression.',
  sources = ARRAY[
    'https://www.congress.gov/bill/118th-congress/house-bill/8035',
    'https://kamlager-dove.house.gov/issues/foreign-affairs',
    'https://en.wikipedia.org/wiki/21st_Century_Peace_through_Strength_Act'
  ]
WHERE politician_id = 'a2c6adc7-7689-49b9-964f-8f2aeb243a83'
  AND topic_id = '24e9212c-b011-422a-865c-093e35050901';

UPDATE inform.politician_context
SET
  reasoning = 'Kamlager-Dove was an original cosponsor of the John R. Lewis Voting Rights Advancement Act (H.R. 14, 119th Congress, March 2025), which restores federal pre-clearance requirements for voting law changes and expands protections against discriminatory election rules. She also supported restoring voting rights to parolees during her California state legislative tenure, reflecting a consistent commitment to expanding voter access and protecting against suppression.',
  sources = ARRAY[
    'https://www.congress.gov/bill/119th-congress/house-bill/14',
    'https://kamlager-dove.house.gov/issues/voting-rights',
    'https://en.wikipedia.org/wiki/John_Lewis_Voting_Rights_Advancement_Act'
  ]
WHERE politician_id = 'a2c6adc7-7689-49b9-964f-8f2aeb243a83'
  AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';

-- ── GROUP B: Insert new answer + context rows ─────────────────────────────────

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a2c6adc7-7689-49b9-964f-8f2aeb243a83', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a2c6adc7-7689-49b9-964f-8f2aeb243a83',
  'c1ac1330-47f7-44ec-baf3-c913d926b97c',
  'Kamlager-Dove cosponsored H.R. 7637 (Head Start for America''s Children Act, 119th Congress) reauthorizing and expanding the federal Head Start early childhood program, and cosponsored H.R. 2763 (American Family Act) expanding the Child Tax Credit and family support programs. She voted for the Build Back Better Act (November 2021), which included $400 billion for universal pre-K and childcare cost caps — supporting heavily subsidized childcare with sliding-scale fees rather than a fully nationalized system.',
  ARRAY[
    'https://www.congress.gov/bill/119th-congress/house-bill/7637',
    'https://www.congress.gov/bill/119th-congress/house-bill/2763',
    'https://en.wikipedia.org/wiki/Build_Back_Better_Act'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a2c6adc7-7689-49b9-964f-8f2aeb243a83', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a2c6adc7-7689-49b9-964f-8f2aeb243a83',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Kamlager-Dove voted for the Inflation Reduction Act (August 2022), deploying $370 billion in clean energy and industrial investment, and authored SB-679 (2021) creating the Los Angeles County Affordable Housing Solutions Agency funded through public bonds and taxes. She consistently supports direct government investment as the primary economic development strategy, particularly for underserved communities, reflecting a preference for public investment and industrial policy over tax-incentive-only approaches.',
  ARRAY[
    'https://en.wikipedia.org/wiki/Inflation_Reduction_Act',
    'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202120220SB679',
    'https://kamlager-dove.house.gov/issues/economy'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a2c6adc7-7689-49b9-964f-8f2aeb243a83', '00b95a6a-75db-4521-b523-3326bba938de', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a2c6adc7-7689-49b9-964f-8f2aeb243a83',
  '00b95a6a-75db-4521-b523-3326bba938de',
  'Kamlager-Dove cosponsored H.R. 433 (Department of Education Protection Act, 119th Congress), which would bar the elimination or restructuring of the Department of Education — a direct counter to voucher-based school choice policy. She also cosponsored H.R. 1810 (Safe Schools Improvement Act) and other bills that direct resources exclusively through public school institutions. Her entire legislative record contains no support for school voucher programs.',
  ARRAY[
    'https://www.congress.gov/bill/119th-congress/house-bill/433',
    'https://www.congress.gov/bill/119th-congress/house-bill/1810',
    'https://kamlager-dove.house.gov/issues/education'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a2c6adc7-7689-49b9-964f-8f2aeb243a83', '4938766b-b45a-46e3-93bd-b8b30651271a', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a2c6adc7-7689-49b9-964f-8f2aeb243a83',
  '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Kamlager-Dove authored AB-118 (C.R.I.S.E.S. Grant Pilot Program, 2021), a California law creating community-based crisis response alternatives that redirect funding from enforcement to services for vulnerable populations. She cosponsored H.R. 3013 and H.R. 3014 (119th Congress) expanding VA homeless veteran housing and permanent supportive housing programs. Her legislative record contains no support for anti-camping enforcement or criminalization measures, reflecting a consistent housing-first approach.',
  ARRAY[
    'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202120220AB118',
    'https://www.congress.gov/bill/119th-congress/house-bill/3013',
    'https://www.congress.gov/bill/119th-congress/house-bill/3014'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a2c6adc7-7689-49b9-964f-8f2aeb243a83', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a2c6adc7-7689-49b9-964f-8f2aeb243a83',
  'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Kamlager-Dove authored AB-118 (C.R.I.S.E.S. Act, 2021), a California law creating grants for community-based alternatives to law enforcement as first responders — explicitly designed to remove police from primary crisis response roles. She was also an original cosponsor of the George Floyd Justice in Policing Act (H.R. 7120, 117th Congress), which would ban chokeholds, end qualified immunity, and require body cameras federally. Her South LA district experience has reinforced a consistent position prioritizing community investment and root causes over expanded policing.',
  ARRAY[
    'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=202120220AB118',
    'https://www.congress.gov/bill/117th-congress/house-bill/7120',
    'https://kamlager-dove.house.gov/issues/public-safety'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a2c6adc7-7689-49b9-964f-8f2aeb243a83', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  'a2c6adc7-7689-49b9-964f-8f2aeb243a83',
  'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Kamlager-Dove cosponsored H.R. 3449 (Stronger Communities through Better Transit Act, 119th Congress) prioritizing federal transit investment, H.R. 409 (Supporting Transit Commutes Act) expanding transit commuter benefits, and H.R. 5452 (Safe Streets for All Reauthorization Act) funding pedestrian and cycling safety infrastructure. Her dense South LA district is heavily dependent on Metro rail and bus, and her legislative record consistently prioritizes public transit investment over highway expansion.',
  ARRAY[
    'https://www.congress.gov/bill/119th-congress/house-bill/409',
    'https://www.congress.gov/bill/119th-congress/house-bill/5452',
    'https://www.congress.gov/bill/119th-congress/house-bill/3449'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
