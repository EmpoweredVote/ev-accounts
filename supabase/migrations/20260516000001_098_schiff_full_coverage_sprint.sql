-- Full coverage sprint for Adam Schiff (politician_id: 8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032)
-- Group A: 4 new answer+context rows (economic-development, homelessness-response,
--          public-safety-approach, transportation-priorities)
-- Group B: 9 thin-source boosts (climate-change, healthcare, immigration, medicare/aid,
--          redistricting, tariffs, taxes, trans-athletes, voting-rights)

-- ── GROUP A: New answer + context rows ───────────────────────────────────────

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032',
  'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Schiff voted for the CHIPS and Science Act and the Inflation Reduction Act — landmark federal industrial-policy legislation channeling hundreds of billions in direct government investment into semiconductor manufacturing, clean energy, and advanced manufacturing. His affordability agenda calls for "a massive investment in renewable energy" and he has described SBA funding and innovation-economy growth as federal priorities. His support for the lithium-extraction economy in California''s Imperial Valley illustrates a recurring pattern: federal dollars and regulatory frameworks should direct economic development, not merely incentivize it.',
  ARRAY[
    'https://www.lcv.org/moc/adam-b-schiff/',
    'https://www.adamschiff.com/plans/affordability-agenda/',
    'https://calmatters.org/california-voter-guide-2024/us-senate/adam-schiff/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032',
  '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
  'Schiff explicitly endorses a Housing First approach, stating people "need to have stable housing before receiving any other interventions." His Housing for All Act, Hotels to Housing Conversion Act, and PATH Act pair mental health and substance-use treatment with housing grants, centering stable housing and wraparound services over enforcement. His Housing BOOM Act (2025) authorizes over $5 billion annually for long-term housing, emergency shelter, and prevention — framing massive public investment, not enforcement, as the core solution.',
  ARRAY[
    'https://www.adamschiff.com/plans/housing-and-homelessness-plan/',
    'https://www.schiff.senate.gov/news/press-releases/news-sen-schiff-unveils-landmark-legislation-to-spur-new-housing-boom-address-housing-crisis/',
    'https://schiff.house.gov/news/press-releases/rep-schiff-introduces-bill-to-address-dual-housing-and-behavioral-health-crises'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032',
  'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Schiff co-sponsored the George Floyd Justice in Policing Act, which limits qualified immunity and lowers the criminal-intent standard for prosecuting officer misconduct. He also co-sponsored the COPS Improvements Act to increase community-policing funding and authored the Youth PROMISE Act for evidence-based juvenile-crime prevention programs. His CalMatters questionnaire called for "law enforcement that goes hand in hand with a greater investment in community violence prevention," indicating a balanced reform-and-accountability position rather than a policing-reduction stance.',
  ARRAY[
    'https://www.ontheissues.org/ca/Adam_Schiff_Crime.htm',
    'https://calmatters.org/california-voter-guide-2024/us-senate/adam-schiff/',
    'https://www.schiff.senate.gov/news/press-releases/news-sen-schiff-introduces-two-bills-to-increase-education-and-literacy-opportunities-for-incarcerated-americans/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES (
  '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032',
  'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Schiff attended the May 2026 grand opening of the LA Metro D Line extension, stating "This extension of the D line is going to bring people together. It''s going to get us out of our cars," and secured approximately $91 million in the 2026 Appropriations bill for Olympic-related transit. He joined Padilla in urging $536 million in federal high-speed rail funding for the California Phase 1 Corridor, describing it as "essential for enhancing our nation''s and California''s strategic transportation network."',
  ARRAY[
    'https://www.schiff.senate.gov/news/press-releases/photos-sen-schiff-attends-grand-opening-of-metro-d-line-in-l-a-emphasizes-efforts-to-push-for-safe-and-efficient-transportation/',
    'https://www.schiff.senate.gov/news/press-releases/news-padilla-schiff-california-house-colleagues-push-for-critical-high-speed-rail-funding/',
    'https://calmatters.org/california-voter-guide-2024/us-senate/adam-schiff/'
  ]
)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- ── GROUP B: Thin-source boosts on existing context rows ─────────────────────

UPDATE inform.politician_context SET
  reasoning = 'Schiff is an original cosponsor of the Green New Deal (H.Res.109) and stated "I was an original co-sponsor of the Green New Deal." He voted YES on the Inflation Reduction Act (2022), earning a 98% LCV lifetime score. He stated: "Moving off of fossil fuels and moving to renewable sources of energy is an environmental imperative. It is a health imperative. It''s an economic imperative. It is a national security imperative."',
  sources = ARRAY[
    'https://www.lcv.org/moc/adam-b-schiff/',
    'https://www.ontheissues.org/ca/Adam_Schiff.htm',
    'https://www.schiff.senate.gov/news/press-releases/news-sen-schiff-rep-carbajal-local-leaders-call-out-trump-administrations-attempts-to-restart-offshore-oil-operations-on-central-coast/'
  ]
WHERE politician_id = '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';

UPDATE inform.politician_context SET
  reasoning = 'Schiff is an original cosponsor of the Medicare for All Act and explicitly listed "passing Medicare for All" as a policy priority in his CalMatters 2024 candidate questionnaire. He has stated "we must make every effort to provide universal coverage to all Americans." As a senator he has strongly opposed Republican bills that "kick millions of Americans off of their health care" and slash Medicaid.',
  sources = ARRAY[
    'https://calmatters.org/california-voter-guide-2024/us-senate/adam-schiff/',
    'https://www.schiff.senate.gov/news/press-releases/statement-sen-schiff-on-republicans-bill-to-kick-millions-off-health-care-and-slash-food-assistance-to-give-massive-tax-cuts-to-billionaires/',
    'https://www.schiff.senate.gov/news/press-releases/statement-sen-schiff-calls-on-senate-to-pass-three-year-extension-of-affordable-care-act-tax-credits-following-u-s-house-of-representatives-passage/'
  ]
WHERE politician_id = '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032' AND topic_id = 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529';

UPDATE inform.politician_context SET
  reasoning = 'Schiff supports the U.S. Citizenship Act to create a pathway to citizenship for approximately 11 million undocumented immigrants and co-sponsored the American Dream and Promise Act for Dreamers. He demanded answers when the Trump administration diverted federal law enforcement to immigration enforcement, arguing it "necessarily means one less agent available to catch child predators and drug traffickers." He has characterized Trump''s enforcement as a "politically orchestrated deportation drive" targeting non-violent people with no criminal history.',
  sources = ARRAY[
    'https://calmatters.org/california-voter-guide-2024/us-senate/adam-schiff/',
    'https://www.schiff.senate.gov/news/press-releases/news-schiff-padilla-gallego-colleagues-demand-answers-on-diversion-of-federal-law-enforcement-agents-to-immigration-enforcement/',
    'https://www.schiff.senate.gov/news/press-releases/watch-sen-schiff-demands-accountability-for-ongoing-abuse-of-power-and-force-by-immigration-enforcement-agencies-opposes-additional-dhs-funding/'
  ]
WHERE politician_id = '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032' AND topic_id = '4e2c69ce-591e-4197-9cd5-7aceff79d390';

UPDATE inform.politician_context SET
  reasoning = 'Schiff is an original cosponsor of the Medicare for All Act and his official position states "Adam believes we must make every effort to provide universal coverage to all Americans." He and 27 Democratic colleagues signed a letter demanding the Trump administration "strongly oppose any efforts by Musk — or anyone else — cutting or damaging these vital programs," arguing "Medicare and Medicaid must not be raided to pay for tax cuts for billionaires." He has also opposed Republican legislation that would "slash Medicaid and the Affordable Care Act, and lead to hundreds of billions of dollars in cuts to Medicare funding."',
  sources = ARRAY[
    'https://www.adamschiff.com/plans/affordability-agenda/',
    'https://www.schiff.senate.gov/news/press-releases/news-sens-schiff-padilla-colleagues-raise-alarm-on-trump-administration-targeting-cuts-to-medicare-and-medicaid/',
    'https://www.schiff.senate.gov/news/press-releases/statement-sen-schiff-on-republicans-bill-to-kick-millions-off-health-care-and-slash-food-assistance-to-give-massive-tax-cuts-to-billionaires/'
  ]
WHERE politician_id = '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032' AND topic_id = 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b';

UPDATE inform.politician_context SET
  reasoning = 'Schiff explicitly praised California''s independent citizens'' commission model and supports applying it nationally: "We need to end this nefarious practice just like California did by passing the For the People Act." He co-sponsored the For the People Act (H.R.1, 117th Congress) requiring independent redistricting commissions for all federal elections, and co-sponsored the John R. Lewis Voting Rights Advancement Act, both of which directly address the gerrymandering and redistricting reforms he advocates on his official issues page.',
  sources = ARRAY[
    'https://www.adamschiff.com/issue/defending-democracy/',
    'https://www.ontheissues.org/ca/Adam_Schiff.htm',
    'https://calmatters.org/california-voter-guide-2024/us-senate/adam-schiff/'
  ]
WHERE politician_id = '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032' AND topic_id = '48cc9585-ec22-4f53-8d42-6839828dd36f';

UPDATE inform.politician_context SET
  reasoning = 'Schiff co-sponsored S.3905 (February 2026) requiring refunds of Trump''s IEEPA tariffs found unlawful — opposing broad unilateral tariff authority. He told constituents directly: "When you place a tariff on goods, say to Canada, Canada doesn''t pay it. You pay it," and warned that Trump''s tariffs would raise food, housing, and consumer prices. He has also called for compensatory federal aid to California farmers harmed by tariff-driven market losses, reflecting opposition to broad tariffs while accepting some targeted trade tools.',
  sources = ARRAY[
    'https://www.finance.senate.gov/ranking-members-news/wyden-markey-shaheen-and-19-senate-democrats-release-legislation-requiring-refunds-of-trumps-illegal-tariffs',
    'https://www.schiff.senate.gov/news/press-releases/watch-sen-schiff-breaks-down-the-trump-tax-starting-at-midnight-raising-costs-for-americans/',
    'https://www.schiff.senate.gov/news/press-releases/watch-sen-schiff-talks-impacts-of-tariffs-and-deportations-on-central-valley-farmers-workers-on-kbak-bakersfield/'
  ]
WHERE politician_id = '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032' AND topic_id = '683c8084-2281-4920-a07c-18439b2dd413';

UPDATE inform.politician_context SET
  reasoning = 'Schiff''s platform explicitly states "the wealthiest Americans and big corporations must pay their fair share" and proposes returning the corporate tax rate to 35% by rolling back the Trump tax cuts. He supports fully funding the IRS to collect taxes owed by the top 1%, lifting the Social Security payroll cap to $250,000, and raising the estate tax. He condemned the Republican "Big Ugly Bill" as designed "to give a massive tax cut to wealthy people and big corporations, while borrowing even more money from our kids to do it."',
  sources = ARRAY[
    'https://www.adamschiff.com/plans/affordability-agenda/',
    'https://www.schiff.senate.gov/news/press-releases/statement-sen-schiff-on-republicans-bill-to-kick-millions-off-health-care-and-slash-food-assistance-to-give-massive-tax-cuts-to-billionaires/',
    'https://www.ontheissues.org/ca/Adam_Schiff.htm'
  ]
WHERE politician_id = '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032' AND topic_id = 'f7e5678d-dadd-4556-a2fc-446e24642ceb';

UPDATE inform.politician_context SET
  reasoning = 'Schiff introduced the PERIOD Act to protect trans students'' medical privacy, characterizing menstrual tracking requirements as "a not-at-all disguised effort to discriminate against trans students." He voted against the FY2025 NDAA citing provisions that "undermine access to lifesaving health care for military families" — widely understood to include anti-trans healthcare restrictions. His consistent co-sponsorship of the Equality Act and service as vice chair of the Congressional LGBTQ+ Equality Caucus reflect support for trans inclusion with appropriate legal processes rather than categorical bans.',
  sources = ARRAY[
    'https://www.washingtonblade.com/2023/02/09/exclusive-adam-schiff-discusses-senate-run-and-new-bill-protecting-trans-youth/',
    'https://www.schiff.senate.gov/news/press-releases/statement-schiff-votes-against-ndaa-cites-policy-riders-and-failure-to-aid-ukraine/',
    'https://www.ontheissues.org/ca/Adam_Schiff.htm'
  ]
WHERE politician_id = '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032' AND topic_id = 'd1618b9c-0b9e-45af-b986-bb33d270b8e4';

UPDATE inform.politician_context SET
  reasoning = 'Schiff supports automatic voter registration, same-day registration, universal mail-in voting, making Election Day a federal holiday, and restoring voting rights for formerly incarcerated people. He co-sponsored the For the People Act (H.R.1) and the John R. Lewis Voting Rights Advancement Act, and has called voter ID laws "purposefully designed to discourage minorities from voting." He stated: "Republicans in state legislatures across the nation are engaged in an all-out assault on our democracy, enacting highly restrictive voter suppression and subversion laws."',
  sources = ARRAY[
    'https://www.adamschiff.com/issue/defending-democracy/',
    'https://www.ontheissues.org/ca/Adam_Schiff.htm',
    'https://calmatters.org/california-voter-guide-2024/us-senate/adam-schiff/'
  ]
WHERE politician_id = '8a27a8b7-88b4-4f79-bbcf-d1d0e70d4032' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';
