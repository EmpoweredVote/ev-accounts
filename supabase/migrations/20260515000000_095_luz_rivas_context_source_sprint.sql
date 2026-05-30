-- Source quality sprint for Luz Maria Rivas (essentials politician_id: a1fc524b-7c90-43c0-83a7-c76664293913)
-- Removes 6 duplicate stale-topic-id rows and fills sources for 6 gap topics.

-- Step 1: Delete stale duplicate rows from politician_answers
DELETE FROM inform.politician_answers
WHERE politician_id = 'a1fc524b-7c90-43c0-83a7-c76664293913'
  AND topic_id IN (
    'f2a62698-a64c-4f7f-8fba-5971d35c51cf',  -- ai-regulation (stale)
    '83eeb217-0289-47df-bde9-c53866b5b3e9',  -- deportation (stale)
    'be60844f-5e21-4fec-ae99-e00e95c1e19b',  -- healthcare (stale)
    'a9f53bc4-db4e-48e1-8663-c87f2c18b63d',  -- housing (stale)
    'c6957429-bc9e-48e7-b36f-a102b968a972',  -- immigration (stale, value 2.0 — live row has correct 1.0)
    '45ca4740-a861-4c8c-b3b5-0a49cf953501'   -- taxes (stale)
  );

-- Step 2: Delete stale duplicate rows from politician_context
DELETE FROM inform.politician_context
WHERE politician_id = 'a1fc524b-7c90-43c0-83a7-c76664293913'
  AND topic_id IN (
    'f2a62698-a64c-4f7f-8fba-5971d35c51cf',
    '83eeb217-0289-47df-bde9-c53866b5b3e9',
    'be60844f-5e21-4fec-ae99-e00e95c1e19b',
    'a9f53bc4-db4e-48e1-8663-c87f2c18b63d',
    'c6957429-bc9e-48e7-b36f-a102b968a972',
    '45ca4740-a861-4c8c-b3b5-0a49cf953501'
  );

-- Step 3: Fill sources + corrected reasoning for 6 gap topics

-- Deportation
UPDATE inform.politician_context
SET
  reasoning = 'As a U.S. Congresswoman, Rivas issued multiple press releases condemning ICE raids in the San Fernando Valley and co-authored AB 937 (the VISION Act) in the California Assembly, which would have prohibited state prisons and local jails from transferring immigrants to ICE custody. She also voted YES on SB 852 (2023, the PROTECT Act), prohibiting ICE agents from impersonating probation officers to detain immigrants. Her record consistently opposes mass deportation infrastructure, supporting deportation only for those convicted of serious violent crimes.',
  sources = ARRAY[
    'https://rivas.house.gov/media/press-releases/congresswoman-luz-rivas-statement-ice-raids-across-san-fernando-valley-and-los',
    'https://caimmigrant.org/wp-content/uploads/2022/03/Vision-Act-AB-937-Fact-Sheet-ENG.pdf',
    'https://aclucalaction.org/legislator/luz-rivas/'
  ]
WHERE politician_id = 'a1fc524b-7c90-43c0-83a7-c76664293913'
  AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac';

-- Fossil Fuels
UPDATE inform.politician_context
SET
  reasoning = 'As Chair of the California Assembly Committee on Natural Resources, Rivas earned a 100% score from California Environmental Voters and was named a Sustainability Star. She voted YES on SB 1137 (2022), which established 3,200-foot health protection zones prohibiting new oil and gas drilling near homes, schools, and hospitals — one of the strongest fossil fuel restrictions in U.S. history. She also voted YES on AB 1279 (the California Climate Crisis Act), codifying carbon neutrality by 2045 and accelerating emissions reduction targets.',
  sources = ARRAY[
    'https://envirovoters.org/archives/scorecard/2022/representative/luz-rivas/',
    'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SB1137',
    'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220AB1279'
  ]
WHERE politician_id = 'a1fc524b-7c90-43c0-83a7-c76664293913'
  AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';

-- Housing
UPDATE inform.politician_context
SET
  reasoning = 'Rivas authored three landmark homelessness bills: AB 1845 (2020) created California''s first-ever Office to End Homelessness; AB 71 (2021, the Bring California Home Act) proposed generating up to $1 billion annually for homelessness programs through corporate tax reform; and AB 799 (2023, the Homelessness Accountability and Results Act) tied HHAP program dollars to measurable local outcomes, signed September 2024. This record of mandating new state funding streams and accountability structures for affordable housing aligns with large-scale public investment and systematic government intervention in housing supply.',
  sources = ARRAY[
    'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220AB71',
    'https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml?bill_id=201920200AB1845',
    'https://a43.asmdc.org/press-releases/20230426-homelessness-accountability-bill-clears-assembly-housing-committee'
  ]
WHERE politician_id = 'a1fc524b-7c90-43c0-83a7-c76664293913'
  AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';

-- Immigration
UPDATE inform.politician_context
SET
  reasoning = 'Rivas voted to expand Medi-Cal eligibility to all low-income adults regardless of immigration status (AB 4, 2021). As a U.S. Congresswoman, she cosponsored H.R. 1589 (American Dream and Promise Act of 2025), providing a citizenship pathway for DACA recipients, DREAMers, and TPS holders. She also voted against H.R. 2966, which would have denied SBA loans to DACA recipients — demonstrating consistent support for full public services and expanded legal pathways for undocumented residents, aligning squarely with stance 1.',
  sources = ARRAY[
    'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220AB4',
    'https://www.congress.gov/bill/119th-congress/house-bill/1589/text',
    'https://rivas.house.gov/media/press-releases/congresswoman-luz-rivas-votes-protect-immigrant-small-businesses'
  ]
WHERE politician_id = 'a1fc524b-7c90-43c0-83a7-c76664293913'
  AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';

-- Redistricting
UPDATE inform.politician_context
SET
  reasoning = 'Rivas voted YES on SB 314 (2023), which established an independent Citizens'' Redistricting Commission for Sacramento County supervisor districts — the first such county-level commission in California, signed by Governor Newsom on October 7, 2023. The commission mirrors the statewide Citizens Redistricting Commission criteria and bars political insiders and former officeholders. Her support reflects a consistent preference for structural transparency and nonpartisan redistricting reform.',
  sources = ARRAY[
    'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240SB314',
    'https://sd08.senate.ca.gov/news/governor-newsom-signs-ashby-bill-creating-independent-citizens-redistricting-commission',
    'https://www.capradio.org/articles/2023/02/13/california-bill-would-require-redistricting-commission-for-sacramento-county-supervisor-districts/'
  ]
WHERE politician_id = 'a1fc524b-7c90-43c0-83a7-c76664293913'
  AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f';

-- Trans Athletes (corrected: AB 1163 is the LGBT Disparities Reduction Act, not a sports bill)
UPDATE inform.politician_context
SET
  reasoning = 'Rivas voted YES on SB 107 (2022), California''s landmark gender-affirming care sanctuary bill protecting transgender youth — passed the Assembly 60–19 and signed September 2022. She authored AB 1163 (2023, the Lesbian, Gay, Bisexual, and Transgender Disparities Reduction Act), requiring state agencies to collect gender identity and sexual orientation data to identify and close equity gaps, and voted YES on ACA 5 affirming marriage equality as a constitutional right. Her consistent record supports full inclusion of transgender people across public institutions.',
  sources = ARRAY[
    'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202320240AB1163',
    'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml?bill_id=202120220SB107',
    'https://aclucalaction.org/legislator/luz-rivas/'
  ]
WHERE politician_id = 'a1fc524b-7c90-43c0-83a7-c76664293913'
  AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4';
