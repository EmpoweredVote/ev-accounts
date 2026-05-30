-- Full coverage sprint for Janice Hahn (politician_id: 6640a2dd-0f1d-4f3e-a794-23e3cc716ae6)
-- Group A: insert 9 new answer+context rows
--          (ai-regulation, campaign-finance, childcare, data-centers, economic-development,
--           redistricting, religious-freedom, trans-athletes, ukraine-support)
-- Group B: update reasoning+sources on 17 existing thin rows
--          (civil-rights, climate-change, deportation, fossil-fuels, healthcare,
--           homelessness, homelessness-response, housing, immigration,
--           judicial-criminal-justice, judicial-police-accountability, misinformation,
--           public-safety-approach, same-sex-marriage, social-security, taxes,
--           transportation-priorities)

-- ── GROUP B: Update existing thin context rows ────────────────────────────────

UPDATE inform.politician_context SET
  reasoning = 'Authored and championed the return of Bruce''s Beach to the Bruce family (2021) as reparations for historical racial discrimination — one of the most prominent reparative justice acts by any local official in California. Co-authored the Anti-Racist and Diversity Initiative (ARDI) and the county''s Racial Equity Strategic Plan. In 2025 condemned the SCOTUS decision allowing racial profiling by federal agents: ''I really thought that race-based arrests would have been the red line for this SCOTUS.''',
  sources = ARRAY['https://hahn.lacounty.gov/news/hahn-issues-statement-in-response-to-scotus-decision-allowing-racial-profiling-by-federal-agents/','https://hahn.lacounty.gov/priorities/','https://hahn.lacounty.gov/news/page/28/']
WHERE politician_id = '6640a2dd-0f1d-4f3e-a794-23e3cc716ae6' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';

UPDATE inform.politician_context SET
  reasoning = 'Supported LA County''s ban on new oil and gas drilling (2022); applauded $44M federal investment in zero-emission trucks at Port of Long Beach stating ''we do not need to choose between good jobs and clean air''; backed 50% clean electricity by 2030 in congressional record; led $130M in stormwater capture projects; fleet electrification (lifeguard EV trucks). Strong clean-energy advocate focused on rapid transition with job protection.',
  sources = ARRAY['https://hahn.lacounty.gov/news/hahn-applauds-44-million-for-zero-emissions-trucks-at-port-of-long-beach/','https://hahn.lacounty.gov/news/hahn-inaugurates-massive-stormwater-capture-system-under-adventure-park-in-south-whittier/','https://www.ontheissues.org/CA/Janice_Hahn.htm']
WHERE politician_id = '6640a2dd-0f1d-4f3e-a794-23e3cc716ae6' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';

UPDATE inform.politician_context SET
  reasoning = 'Called ICE agents ''undertrained and trigger happy'' and demanded Kristi Noem withdraw ICE from American cities (Jan 2026). Testified before Congress on ICE misconduct (2025) and condemned ICE raids as ''targeting people based on the color of their skin, or their accent, or the place that they work.'' Co-authored ordinance barring masked law enforcement during operations. Created RepresentLA (2016) to provide legal representation to detained immigrants. Strong record against mass deportation; position aligns with deporting only serious violent criminals.',
  sources = ARRAY['https://hahn.lacounty.gov/news/in-wake-of-ice-shooting-hahn-calls-for-kristi-noem-to-withdraw-ice/','https://hahn.lacounty.gov/news/hahn-testifies-at-congressional-hearing-on-ice-misconduct/','https://hahn.lacounty.gov/news/la-county-will-explore-expanding-legal-assistance-for-immigrants/']
WHERE politician_id = '6640a2dd-0f1d-4f3e-a794-23e3cc716ae6' AND topic_id = '44905f3b-e105-4f6c-afc7-5d223813dbac';

UPDATE inform.politician_context SET
  reasoning = 'Supported LA County''s 2022 ordinance banning new oil and gas wells in unincorporated areas and phasing out existing wells. Applauded $44M federal grant for zero-emission trucks at Port of Long Beach (2024), stating ''we do not need to choose between good jobs and clean air.'' Endorsed 50% clean electricity by 2030 and green jobs creation in her congressional record. Consistently endorsed by the League of Conservation Voters.',
  sources = ARRAY['https://hahn.lacounty.gov/news/hahn-applauds-44-million-for-zero-emissions-trucks-at-port-of-long-beach/','https://www.ontheissues.org/CA/Janice_Hahn.htm','https://ballotpedia.org/Janice_Hahn']
WHERE politician_id = '6640a2dd-0f1d-4f3e-a794-23e3cc716ae6' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';

UPDATE inform.politician_context SET
  reasoning = 'Co-authored and championed $5M county program that eliminated $500M in medical debt for 134,000+ low-income LA County residents (2024), stating ''No one should be driven into poverty because they got sick'' and ''we have a moral obligation to seize this opportunity.'' Voted for the ACA, opposed all ACA repeal efforts, and supported expanding Medicaid access. Pushed county hospital ordinance requiring hospitals to report medical debt data to develop reduction strategies.',
  sources = ARRAY['https://hahn.lacounty.gov/news/la-county-will-launch-pilot-program-to-eliminate-low-income-residents-medical-debt/','https://hahn.lacounty.gov/news/supervisors-approve-ordinance-to-require-hospitals-to-report-medical-debt-data/','https://hahn.lacounty.gov/news/over-134000-la-county-residents-will-receive-notices-of-medical-debt-relief/']
WHERE politician_id = '6640a2dd-0f1d-4f3e-a794-23e3cc716ae6' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';

UPDATE inform.politician_context SET
  reasoning = 'Declared a homelessness state of emergency in December 2022. Secured $12.2M for homeless solutions in her district cities. Voted to create a dedicated County Homelessness Department (2024), citing LAHSA accountability failures. Launched Pathway Home encampment resolution program that brought nearly 2,000 people indoors. Stated: ''I want to end homelessness in Torrance. Not manage it, not shift it around — end it.'' Housing declared a human right in her priorities.',
  sources = ARRAY['https://hahn.lacounty.gov/priorities/','https://hahn.lacounty.gov/news/we-have-a-chance-to-do-something-real-about-homelessness-in-torrance/','https://hahn.lacounty.gov/news/hahn-issues-statement-on-vote-for-county-homeless-department/']
WHERE politician_id = '6640a2dd-0f1d-4f3e-a794-23e3cc716ae6' AND topic_id = '4938766b-b45a-46e3-93bd-b8b30651271a';

UPDATE inform.politician_context SET
  reasoning = 'Employs housing-first approach via Project Homekey motel conversions (''without permanent housing, shelters get full, streets stay crowded with tents, and the crisis drags on''). Opened multiple permanent supportive housing sites (80-bed Hondo Center, 55-unit Norwalk PSH, 97-unit West Whittier apartments). Launched Pathway Home to clear encampments and move people into interim then permanent housing. Champions mental health and CARE Court services alongside housing placements.',
  sources = ARRAY['https://hahn.lacounty.gov/news/we-have-a-chance-to-do-something-real-about-homelessness-in-torrance/','https://hahn.lacounty.gov/news/hahn-opens-55-unit-permanent-supportive-housing-at-former-motel-6-site-in-norwalk/','https://hahn.lacounty.gov/news/hahn-celebrates-grand-opening-of-97-new-apartments-for-formerly-homeless-in-west-whittier/']
WHERE politician_id = '6640a2dd-0f1d-4f3e-a794-23e3cc716ae6' AND topic_id = '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f';

UPDATE inform.politician_context SET
  reasoning = 'Declared housing a human right (official priorities page). Secured $62M+ in affordable housing bonds; championed Project Homekey conversions across multiple sites; called for county to purchase tax-defaulted properties before auction for affordable housing; supported $500M in county medical debt relief so residents are not driven to housing insecurity by medical bills. Explicit goals: house all homeless veterans in District 4 by 2028.',
  sources = ARRAY['https://hahn.lacounty.gov/priorities/','https://hahn.lacounty.gov/news/hahn-celebrates-grand-opening-of-97-new-apartments-for-formerly-homeless-in-west-whittier/','https://hahn.lacounty.gov/news/hahn-opens-55-unit-permanent-supportive-housing-at-former-motel-6-site-in-norwalk/']
WHERE politician_id = '6640a2dd-0f1d-4f3e-a794-23e3cc716ae6' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';

UPDATE inform.politician_context SET
  reasoning = 'Created RepresentLA (formerly LA Justice Fund) in 2016 to provide legal defense to immigrants facing deportation; re-expanded it in 2025 in response to Trump ICE raids. Requested ''Know Your Rights'' materials for immigrants displayed throughout Metro system. Voted $20M in rent relief for immigrants impacted by ICE workplace raids (2025). Notable exception: voted for HR 4038 in 2015 restricting Syrian/Iraqi refugee resettlement — a single outlier in an otherwise strongly pro-immigrant record.',
  sources = ARRAY['https://hahn.lacounty.gov/news/hahn-requests-know-your-rights-info-for-immigrants-be-displayed-throughout-metro-system/','https://hahn.lacounty.gov/news/la-county-will-explore-expanding-legal-assistance-for-immigrants/','https://hahn.lacounty.gov/news/hahn-votes-for-20-million-rent-relief-program-for-fire-victims-and-immigrants/']
WHERE politician_id = '6640a2dd-0f1d-4f3e-a794-23e3cc716ae6' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';

UPDATE inform.politician_context SET
  reasoning = 'Authored motion on rising in-custody deaths in LA County jails (2025), directing a 90-day systemic review. Supported CARE Court for mental health treatment pathways. Backed Care-First/Jail-Last framework and juvenile justice reforms. Opposed expanding jail capacity in favor of treatment alternatives. Authored drug smuggling intervention at juvenile facilities that combined enhanced security with expanded substance use treatment.',
  sources = ARRAY['https://hahn.lacounty.gov/news/board-of-supervisors-passes-hahn-motion-in-response-to-rising-deaths-in-la-county-jails/','https://hahn.lacounty.gov/news/la-county-to-implement-improvements-to-care-court-program-for-individuals-with-untreated-mental-health-disorders/','https://hahn.lacounty.gov/news/supervisors-advance-strategy-to-tackle-drug-use-and-smuggling-at-county-juvenile-facilities/']
WHERE politician_id = '6640a2dd-0f1d-4f3e-a794-23e3cc716ae6' AND topic_id = '9db07b16-1076-4b7d-ad89-ebe7b51f4336';

UPDATE inform.politician_context SET
  reasoning = 'Authored ordinance barring law enforcement from wearing masks or concealing identities during public operations, passed by the Board (2025), stating: ''This is how authoritarian secret police behaves — not legitimate law enforcement in a democracy.'' Testified before Congress on ICE misconduct alleging agents targeted residents by race, accent, and workplace. Supported chief firing guilty probation officers and called for wholesale culture change in the department.',
  sources = ARRAY['https://hahn.lacounty.gov/news/los-angeles-county-supervisors-vote-to-bar-law-enforcement-from-wearing-masks-concealing-identities/','https://hahn.lacounty.gov/news/hahn-testifies-at-congressional-hearing-on-ice-misconduct/','https://hahn.lacounty.gov/news/hahn-issues-statement-after-california-ag-indicts-30-probation-officers/']
WHERE politician_id = '6640a2dd-0f1d-4f3e-a794-23e3cc716ae6' AND topic_id = '7bad33eb-e93e-4d94-8822-97212d49bde5';

UPDATE inform.politician_context SET
  reasoning = 'Chaired a county task force to combat election and COVID-19 misinformation. On the Issues records her support for campaign finance disclosure requirements and transparency in political spending. No record of advocating mandatory platform takedowns or algorithmic regulation; approach consistent with mandating fact-checking transparency and disclosure standards while protecting free speech.',
  sources = ARRAY['https://www.ontheissues.org/CA/Janice_Hahn.htm','https://ballotpedia.org/Janice_Hahn','https://hahn.lacounty.gov/priorities/']
WHERE politician_id = '6640a2dd-0f1d-4f3e-a794-23e3cc716ae6' AND topic_id = 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d';

UPDATE inform.politician_context SET
  reasoning = 'Deployed 60+ unarmed mental health field teams responding 24/7 via 988 hotline; secured $2.2M state grant to expand follow-up care; Metro Board approved mental health response improvement (Jan 2024). Maintains full police staffing while adding parallel crisis response (''We are building up a system so that when someone has a serious mental health crisis, anyone can pick up the phone, dial 9-8-8 and expect help at their door''). Reform-oriented without proposing police budget cuts.',
  sources = ARRAY['https://hahn.lacounty.gov/news/hahn-leads-effort-to-preserve-and-expand-incentives-to-recruit-mental-health-field-teams/','https://hahn.lacounty.gov/news/la-county-mental-health-mobile-response-teams-to-provide-follow-up-care/','https://hahn.lacounty.gov/priorities/']
WHERE politician_id = '6640a2dd-0f1d-4f3e-a794-23e3cc716ae6' AND topic_id = 'e9ebefcd-c496-45e8-b816-a79f8442ba85';

UPDATE inform.politician_context SET
  reasoning = 'Described as a ''fighter for the LGBTQ community'' in On the Issues; voted to oppose anti-gay discrimination in public schools; created the $4.2M LGBTQ+ Community Resource Center in Whittier (2023); appointed inaugural LGBTQ+ Commission members; co-authored motion preserving LGBTQ+ crisis hotline services after Trump federal funding cuts (2025), stating ''the federal government may be turning its back on LGBTQ+ people, but here in LA County we''ll do everything within our power to keep this community safe.''',
  sources = ARRAY['https://www.ontheissues.org/CA/Janice_Hahn.htm','https://hahn.lacounty.gov/news/supervisors-move-forward-on-effort-to-preserve-lgbtq-crisis-hotline-services-locally-after-federal-funding-cuts/','https://hahn.lacounty.gov/news/hahn-celebrates-anniversary-of-historic-opening-of-whittier-lgbtq-community-center/']
WHERE politician_id = '6640a2dd-0f1d-4f3e-a794-23e3cc716ae6' AND topic_id = 'c5ab4eab-702f-49b8-9277-8ea53f3835c6';

UPDATE inform.politician_context SET
  reasoning = 'On the Issues records her strong opposition to Social Security privatization and stated ''moral responsibility to honor our obligations to seniors.'' Opposes any reduction of current benefits. Congressional record shows opposition to deficit reduction efforts that include Social Security cuts. Favors protecting and expanding the program funded by removing the income cap on payroll taxes.',
  sources = ARRAY['https://www.ontheissues.org/CA/Janice_Hahn.htm','https://ballotpedia.org/Janice_Hahn']
WHERE politician_id = '6640a2dd-0f1d-4f3e-a794-23e3cc716ae6' AND topic_id = '87d20824-a6e9-407b-983c-65440084a0ab';

UPDATE inform.politician_context SET
  reasoning = 'On the Issues records her support for a ''minimum tax rate of 30% for those earning over $1 million'' (Buffett Rule) and opposition to tax cuts for high earners. Supports progressive taxation and 100% UFCW labor rating. Does not advocate dramatically higher rates across all income levels or major new taxes — consistent with modest increases on high earners while protecting middle-class rates.',
  sources = ARRAY['https://www.ontheissues.org/CA/Janice_Hahn.htm','https://ballotpedia.org/Janice_Hahn','https://hahn.lacounty.gov/priorities/']
WHERE politician_id = '6640a2dd-0f1d-4f3e-a794-23e3cc716ae6' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';

UPDATE inform.politician_context SET
  reasoning = 'Chaired LA Metro Board in 2024 with explicit focus on multimodal safety and rider experience. Championed Southeast Gateway Line connecting Southeast LA communities to Downtown. Redirected $750M in 710 freeway widening funds toward transit, traffic, and pollution solutions. Funded 8.4 miles of new bike lanes plus pedestrian sidewalk improvements in South Whittier.',
  sources = ARRAY['https://hahn.lacounty.gov/priorities/','https://hahn.lacounty.gov/news/supervisors-greenlight-8-4-miles-of-new-bike-lanes-and-road-improvements-in-south-whittier/','https://hahn.lacounty.gov/news/hahn-celebrates-federal-support-for-southeast-gateway-line/']
WHERE politician_id = '6640a2dd-0f1d-4f3e-a794-23e3cc716ae6' AND topic_id = 'ba59337e-30e2-4aba-a39a-426b3366eb27';

-- ── GROUP A: New answer + context rows ───────────────────────────────────────

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6640a2dd-0f1d-4f3e-a794-23e3cc716ae6', '666bf03d-81fc-4138-ab15-69ae734c9023', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6640a2dd-0f1d-4f3e-a794-23e3cc716ae6','666bf03d-81fc-4138-ab15-69ae734c9023',
  'No direct LA County or congressional record on AI regulation. As a Democrat who supported federal oversight of tech platforms (chaired a county misinformation task force, 2021) and opposes deregulatory approaches, she aligns with light oversight and self-regulation with transparency requirements rather than heavy mandates — consistent with mainstream Democratic House caucus posture during her 2011-2016 tenure.',
  ARRAY['https://hahn.lacounty.gov/priorities/','https://www.ontheissues.org/CA/Janice_Hahn.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6640a2dd-0f1d-4f3e-a794-23e3cc716ae6', '92730f69-ae57-401c-8ad1-2d07834a895d', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6640a2dd-0f1d-4f3e-a794-23e3cc716ae6','92730f69-ae57-401c-8ad1-2d07834a895d',
  'On the Issues records her support for ''require full disclosure of independent campaign expenditures'' and public financing through voter vouchers and small-donor matching funds. She endorsed campaign finance transparency and limits on dark money while in the House (2011–2016), stopping short of a full ban on private money.',
  ARRAY['https://www.ontheissues.org/CA/Janice_Hahn.htm','https://ballotpedia.org/Janice_Hahn'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6640a2dd-0f1d-4f3e-a794-23e3cc716ae6', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6640a2dd-0f1d-4f3e-a794-23e3cc716ae6','c1ac1330-47f7-44ec-baf3-c913d926b97c',
  'No explicit childcare legislation found in her LA County record; however her district priorities page lists access to healthcare and county services for families, she co-authored the Office of Food Equity (2023), and her congressional record reflects support for expanded federal family services. Consistent with mainstream Democratic support for significant subsidies and expanded access, stopping short of universal public childcare.',
  ARRAY['https://hahn.lacounty.gov/priorities/','https://www.ontheissues.org/CA/Janice_Hahn.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6640a2dd-0f1d-4f3e-a794-23e3cc716ae6', '4559b513-0fd8-4ed1-babd-f3b554162f40', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6640a2dd-0f1d-4f3e-a794-23e3cc716ae6','4559b513-0fd8-4ed1-babd-f3b554162f40',
  'No direct statements found on data center development or energy cost policy. As LA County Supervisor focused on air quality at ports and stormwater infrastructure, she supports environmental impact assessments for major development (Measure W) while also championing economic development and job creation in Southeast LA. This suggests a middle-ground position requiring impact assessments and community benefit agreements.',
  ARRAY['https://hahn.lacounty.gov/priorities/','https://hahn.lacounty.gov/news/hahn-applauds-44-million-for-zero-emissions-trucks-at-port-of-long-beach/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6640a2dd-0f1d-4f3e-a794-23e3cc716ae6', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6640a2dd-0f1d-4f3e-a794-23e3cc716ae6','eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Championed the Southeast Gateway Line ($231M+ in federal funding), redirected $750M in 710 freeway funds toward transit and economic improvements, supported $50K golf initiative for Southeast LA, and helped connect displaced Phillips 66 and 99 Cents Only workers with county job opportunities (Dec 2024). Favors targeted economic investment with community benefit, not blanket corporate incentives.',
  ARRAY['https://hahn.lacounty.gov/news/hahn-celebrates-231-million-awarded-to-southeast-gateway-line/','https://hahn.lacounty.gov/priorities/','https://hahn.lacounty.gov/news/page/29/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6640a2dd-0f1d-4f3e-a794-23e3cc716ae6', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6640a2dd-0f1d-4f3e-a794-23e3cc716ae6','48cc9585-ec22-4f53-8d42-6839828dd36f',
  'Authored and co-authored governance reform measures (July 2024 Board vote) calling for expanding the LA County Board from 5 to 9 supervisors with independent ethics oversight and public budget presentations. Stated: ''They tell us they want smaller, more representative districts, checks and balances, and commonsense ethics reforms.'' Consistent with support for independent or bipartisan redistricting commissions.',
  ARRAY['https://hahn.lacounty.gov/news/la-county-governance-and-ethics-reforms-to-be-placed-on-november-ballot/','https://hahn.lacounty.gov/priorities/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6640a2dd-0f1d-4f3e-a794-23e3cc716ae6', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6640a2dd-0f1d-4f3e-a794-23e3cc716ae6','6b9ba6d9-1001-43f5-b073-4d37130696fd',
  'No direct statements found on religious freedom vs. anti-discrimination tensions. As a strong LGBTQ+ ally who flew the Progress Pride flag and funded the Whittier LGBTQ+ Resource Center, she would resist religious exemptions that override civil rights protections; but her record shows no advocacy for stripping religious organizations of operational autonomy. Aligns with balancing religious practice with equal treatment under law.',
  ARRAY['https://hahn.lacounty.gov/news/hahn-celebrates-anniversary-of-historic-opening-of-whittier-lgbtq-community-center/','https://hahn.lacounty.gov/news/hahn-holds-pride-flag-raising-ceremony-in-downey/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6640a2dd-0f1d-4f3e-a794-23e3cc716ae6', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6640a2dd-0f1d-4f3e-a794-23e3cc716ae6','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
  'No direct statements found on transgender athlete policy. As a consistent LGBTQ+ ally (LGBTQ+ Resource Center, crisis hotline preservation, Pride flag ceremonies, LGBTQ+ Commission appointment), she aligns with Democratic mainstream support for transgender inclusion with basic documentation/transition requirements rather than either no restrictions or a blanket ban.',
  ARRAY['https://hahn.lacounty.gov/priorities/','https://hahn.lacounty.gov/news/supervisors-move-forward-on-effort-to-preserve-lgbtq-crisis-hotline-services-locally-after-federal-funding-cuts/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('6640a2dd-0f1d-4f3e-a794-23e3cc716ae6', '24e9212c-b011-422a-865c-093e35050901', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('6640a2dd-0f1d-4f3e-a794-23e3cc716ae6','24e9212c-b011-422a-865c-093e35050901',
  'No direct statements found on Ukraine aid. During her House tenure (2011–2016) she served on the Homeland Security Committee and voted with the Democratic mainstream on foreign policy. Given her strong anti-Trump/authoritarian posture (2025–2026 statements on federal overreach) and opposition to US retrenchment on democratic norms, she aligns with continued support for Ukraine defense aid at current levels.',
  ARRAY['https://ballotpedia.org/Janice_Hahn','https://www.ontheissues.org/CA/Janice_Hahn.htm'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
