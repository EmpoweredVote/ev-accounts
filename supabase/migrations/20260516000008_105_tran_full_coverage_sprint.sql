-- Full coverage sprint for Derek Tran (politician_id: b7612f49-c914-4ea7-a6da-559d71f313c2)
-- Group A: fill sources on 6 existing thin answers
--          (ai-regulation, civil-rights, misinformation, tariffs, ukraine-support, voting-rights)
-- Group B: insert 11 new answer+context rows
--          (childcare, data-centers, economic-development, homelessness, homelessness-response,
--           public-safety-approach, redistricting, religious-freedom, school-vouchers,
--           trans-athletes, transportation-priorities)

-- ── GROUP A: Fill sources on existing context rows ────────────────────────────

UPDATE inform.politician_context SET
  reasoning = 'Tran is a member of the New Democrat Coalition, which promotes responsible innovation and a pro-technology agenda while supporting accountability measures for emerging industries. As Ranking Member on the House Small Business Subcommittee on Oversight, Investigations, and Regulations, he has jurisdiction over regulatory policy affecting small businesses including AI-adjacent industries. No specific AI safety bill sponsorship found, but his caucus alignment and regulatory subcommittee role suggest support for basic safety standards rather than laissez-faire or heavy-handed approaches.',
  sources = ARRAY[
    'https://en.wikipedia.org/wiki/New_Democrat_Coalition',
    'https://en.wikipedia.org/wiki/Derek_Tran',
    'https://en.wikipedia.org/wiki/House_Committee_on_Small_Business'
  ]
WHERE politician_id = 'b7612f49-c914-4ea7-a6da-559d71f313c2' AND topic_id = '666bf03d-81fc-4138-ab15-69ae734c9023';

UPDATE inform.politician_context SET
  reasoning = 'Tran is a member of the Congressional Equality Caucus, which works to advance LGBTQ+ rights and eliminate discriminatory laws. His campaign platform highlighted systemic barriers facing Vietnamese-American and minority communities and he publicly condemned racially charged ''red-baiting'' rhetoric against Asian American candidates as promoting ''perpetual foreigner'' narratives. His caucus memberships and Democratic voting pattern align with strengthening civil rights enforcement and addressing systemic discrimination.',
  sources = ARRAY[
    'https://en.wikipedia.org/wiki/Congressional_Equality_Caucus',
    'https://en.wikipedia.org/wiki/Derek_Tran',
    'https://en.wikipedia.org/wiki/Equality_Act_(United_States)'
  ]
WHERE politician_id = 'b7612f49-c914-4ea7-a6da-559d71f313c2' AND topic_id = '0bc588c6-39e1-4084-b5de-cac909b8b762';

UPDATE inform.politician_context SET
  reasoning = 'Tran voted in March 2025 for legislation restricting foreign influence in American higher education, breaking with most House Democrats, citing concerns about Chinese Communist Party disinformation and academic infiltration. He co-chairs the House Democratic Caucus National Security Task Force and identified CCP influence operations as a pressing national security concern. His stance reflects support for platform accountability and transparency requirements to combat foreign-directed disinformation, consistent with a mandate fact-checking and algorithmic transparency approach.',
  sources = ARRAY[
    'https://en.wikipedia.org/wiki/Derek_Tran',
    'https://en.wikipedia.org/wiki/New_Democrat_Coalition',
    'https://en.wikipedia.org/wiki/Congressional_Taiwan_Caucus'
  ]
WHERE politician_id = 'b7612f49-c914-4ea7-a6da-559d71f313c2' AND topic_id = 'ddd65d64-9dc7-4208-a30f-59f4b9c0653d';

UPDATE inform.politician_context SET
  reasoning = 'Tran is a member of the New Democrat Coalition, which explicitly supports free trade and "the diversification and strengthening of global supply chains" while advocating for a "transparent exclusion process from Section 301 tariffs" — signaling selective tariff use rather than blanket protectionism or elimination. He represents CA-45, a district with significant manufacturing, retail, and Asian-American small business communities that would be harmed by broad tariffs, yet his national security focus on China suggests openness to targeted trade measures.',
  sources = ARRAY[
    'https://en.wikipedia.org/wiki/New_Democrat_Coalition',
    'https://en.wikipedia.org/wiki/Derek_Tran',
    'https://en.wikipedia.org/wiki/California%27s_45th_congressional_district'
  ]
WHERE politician_id = 'b7612f49-c914-4ea7-a6da-559d71f313c2' AND topic_id = '683c8084-2281-4920-a07c-18439b2dd413';

UPDATE inform.politician_context SET
  reasoning = 'Tran has publicly identified the Russo-Ukrainian War as a "pressing security concern" and co-chairs the House Democratic Caucus National Security Task Force alongside Rep. Jason Crow. He emphasizes the importance of standing with allies against authoritarian aggression. No evidence of calls to cut Ukraine aid; his national security-focused caucus role and New Democrat Coalition membership indicate continued support for current military and economic assistance to Ukraine.',
  sources = ARRAY[
    'https://en.wikipedia.org/wiki/Derek_Tran',
    'https://en.wikipedia.org/wiki/New_Democrat_Coalition',
    'https://en.wikipedia.org/wiki/119th_United_States_Congress'
  ]
WHERE politician_id = 'b7612f49-c914-4ea7-a6da-559d71f313c2' AND topic_id = '24e9212c-b011-422a-865c-093e35050901';

UPDATE inform.politician_context SET
  reasoning = 'The Safeguard American Voter Eligibility (SAVE) Act, which would require proof of citizenship to register to vote in federal elections, passed the House 220-208 with only one Democrat (Henry Cuellar) voting yes — meaning Tran almost certainly voted No. His New Democrat Coalition membership and Democratic voting pattern indicate support for expanding voting access, including mail-in voting and early voting, consistent with opposing strict ID mandates while supporting voter verification measures.',
  sources = ARRAY[
    'https://en.wikipedia.org/wiki/Safeguard_American_Voter_Eligibility_Act',
    'https://en.wikipedia.org/wiki/Derek_Tran',
    'https://en.wikipedia.org/wiki/New_Democrat_Coalition'
  ]
WHERE politician_id = 'b7612f49-c914-4ea7-a6da-559d71f313c2' AND topic_id = 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2';

-- ── GROUP B: New answer + context rows ───────────────────────────────────────

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7612f49-c914-4ea7-a6da-559d71f313c2', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7612f49-c914-4ea7-a6da-559d71f313c2','c1ac1330-47f7-44ec-baf3-c913d926b97c',
  'Tran co-chairs the Lowering Costs Caucus, focused on reducing costs of living for working families. He personally grew up in a family that relied on federal safety-net programs including SNAP and WIC, and has cited this as motivating his work to expand economic opportunity. His New Democrat Coalition membership and repeated emphasis on affordability and public-private partnerships indicate support for significant childcare subsidy expansion for low- and middle-income families.',
  ARRAY['https://en.wikipedia.org/wiki/Derek_Tran','https://en.wikipedia.org/wiki/New_Democrat_Coalition','https://en.wikipedia.org/wiki/California%27s_45th_congressional_district'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7612f49-c914-4ea7-a6da-559d71f313c2', '4559b513-0fd8-4ed1-babd-f3b554162f40', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7612f49-c914-4ea7-a6da-559d71f313c2','4559b513-0fd8-4ed1-babd-f3b554162f40',
  'No direct statement by Tran on data center policy was found. As a member of the Fusion Energy Caucus and the New Democrat Coalition''s pro-technology wing, Tran generally supports energy innovation and technology investment. His Lowering Costs Caucus co-chair role suggests sensitivity to consumer cost impacts from infrastructure development. A balanced approach — allowing development with impact assessments and cost-sharing agreements — is consistent with his pro-growth but consumer-conscious policy profile.',
  ARRAY['https://en.wikipedia.org/wiki/Derek_Tran','https://en.wikipedia.org/wiki/New_Democrat_Coalition','https://en.wikipedia.org/wiki/California%27s_45th_congressional_district'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7612f49-c914-4ea7-a6da-559d71f313c2', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7612f49-c914-4ea7-a6da-559d71f313c2','eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Tran serves as Ranking Member on the House Small Business Subcommittee on Oversight, Investigations, and Regulations, overseeing regulatory impacts on small business. His New Democrat Coalition membership signals support for targeted economic development incentives paired with accountability, rather than blanket corporate subsidies or laissez-faire approaches. He has specifically highlighted public-private partnerships as the model for affordable housing development, suggesting a preference for community benefit requirements alongside development incentives.',
  ARRAY['https://en.wikipedia.org/wiki/Derek_Tran','https://en.wikipedia.org/wiki/House_Committee_on_Small_Business','https://en.wikipedia.org/wiki/New_Democrat_Coalition'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7612f49-c914-4ea7-a6da-559d71f313c2', '4938766b-b45a-46e3-93bd-b8b30651271a', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7612f49-c914-4ea7-a6da-559d71f313c2','4938766b-b45a-46e3-93bd-b8b30651271a',
  'Tran publicly supported California Proposition 36 in 2024, officially titled "The Homelessness, Drug Addiction, and Theft Reduction Act," which increased felony charges for repeat theft and certain drug crimes. This positions him in the center — supporting enforcement tools against drug-related homelessness while simultaneously advocating for expanded affordable housing through the Low-Income Housing Tax Credit and public-private partnerships. His stance combines enforcement when adequate remedies are available with investment in services and housing.',
  ARRAY['https://en.wikipedia.org/wiki/Derek_Tran','https://en.wikipedia.org/wiki/2024_California_Proposition_36','https://en.wikipedia.org/wiki/California%27s_45th_congressional_district'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7612f49-c914-4ea7-a6da-559d71f313c2', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7612f49-c914-4ea7-a6da-559d71f313c2','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
  'Tran supported Prop 36 (enforcement tools for drug/theft crimes tied to homelessness) while simultaneously advocating for expanded affordable housing funding through LIHTC and public-private partnerships. His approach combines outreach, services, and shelter investment with reasonable public space enforcement — not a pure criminalization stance nor a services-only approach. He has not called for eliminating anti-camping ordinances but also has not endorsed pure enforcement as a primary strategy.',
  ARRAY['https://en.wikipedia.org/wiki/Derek_Tran','https://en.wikipedia.org/wiki/2024_California_Proposition_36','https://en.wikipedia.org/wiki/New_Democrat_Coalition'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7612f49-c914-4ea7-a6da-559d71f313c2', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7612f49-c914-4ea7-a6da-559d71f313c2','e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Tran is a member of the Congressional Law Enforcement Caucus and voted for the Laken Riley Act (2025), which requires mandatory detention of undocumented immigrants accused of theft-related crimes — a measure supported by nearly all Republicans and 46 Democrats. He supports current police funding while backing the Gun Violence Prevention Task Force. His record reflects maintaining current public safety funding and adding crisis response tools, not defunding or significantly expanding police budgets.',
  ARRAY['https://en.wikipedia.org/wiki/Derek_Tran','https://en.wikipedia.org/wiki/Laken_Riley_Act','https://en.wikipedia.org/wiki/119th_United_States_Congress'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7612f49-c914-4ea7-a6da-559d71f313c2', '48cc9585-ec22-4f53-8d42-6839828dd36f', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7612f49-c914-4ea7-a6da-559d71f313c2','48cc9585-ec22-4f53-8d42-6839828dd36f',
  'As a Democrat from California — a state that uses an independent Citizens Redistricting Commission — Tran''s party broadly supports independent redistricting reform. House Democrats nearly unanimously backed the For the People Act, which would have required all states to use independent commissions for congressional redistricting. Tran''s competitive D+1 district was drawn by California''s bipartisan independent commission, and his Democratic membership implies support for independent commissions with equal partisan representation.',
  ARRAY['https://en.wikipedia.org/wiki/Derek_Tran','https://en.wikipedia.org/wiki/For_the_People_Act','https://en.wikipedia.org/wiki/California_Citizens_Redistricting_Commission'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7612f49-c914-4ea7-a6da-559d71f313c2', '6b9ba6d9-1001-43f5-b073-4d37130696fd', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7612f49-c914-4ea7-a6da-559d71f313c2','6b9ba6d9-1001-43f5-b073-4d37130696fd',
  'Tran is a member of the Congressional Equality Caucus, which supports LGBTQ protections, and House Democrats broadly supported the Respect for Marriage Act (2022) — which included some religious organization exemptions from participating in same-sex marriages. The Equality Act, which Democrats supported, does not include RFRA exemptions. Tran''s record suggests a balance: protecting religious practice while ensuring it does not override anti-discrimination protections in employment and public accommodations.',
  ARRAY['https://en.wikipedia.org/wiki/Respect_for_Marriage_Act','https://en.wikipedia.org/wiki/Congressional_Equality_Caucus','https://en.wikipedia.org/wiki/Derek_Tran'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7612f49-c914-4ea7-a6da-559d71f313c2', '00b95a6a-75db-4521-b523-3326bba938de', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7612f49-c914-4ea7-a6da-559d71f313c2','00b95a6a-75db-4521-b523-3326bba938de',
  'No evidence of Derek Tran supporting school voucher programs was found. He grew up in a family that relied on federal public assistance programs and has emphasized expanding economic opportunity through public institutions. His Democratic affiliation, New Democrat Coalition membership, and support for public programs over private alternatives suggest he would prioritize public school funding while potentially allowing limited, means-tested voucher access for low-income families without adequate local options.',
  ARRAY['https://en.wikipedia.org/wiki/Derek_Tran','https://en.wikipedia.org/wiki/New_Democrat_Coalition','https://en.wikipedia.org/wiki/California%27s_45th_congressional_district'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7612f49-c914-4ea7-a6da-559d71f313c2', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7612f49-c914-4ea7-a6da-559d71f313c2','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
  'Tran is a member of the Congressional Equality Caucus, which advances LGBTQ+ rights including protections for transgender individuals. House Democrats nearly unanimously opposed the Protection of Women and Girls in Sports Act, which would ban transgender athletes from competing consistent with their gender identity in federally funded programs. His Equality Caucus membership and Democratic voting pattern indicate he supports allowing transgender athletes to compete on teams matching their gender identity after completing basic transition documentation.',
  ARRAY['https://en.wikipedia.org/wiki/Congressional_Equality_Caucus','https://en.wikipedia.org/wiki/Derek_Tran','https://en.wikipedia.org/wiki/Equality_Act_(United_States)'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('b7612f49-c914-4ea7-a6da-559d71f313c2', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('b7612f49-c914-4ea7-a6da-559d71f313c2','ba59337e-30e2-4aba-a39a-426b3366eb27',
  'No direct statement by Tran on local transportation investment priorities was found. As a federal representative for a suburban Orange County district (CA-45) with communities including Westminster, Garden Grove, and Cerritos, his constituents are largely car-dependent. His New Democrat Coalition membership suggests a pragmatic approach: maintaining roads while selectively adding transit connections and pedestrian improvements where population density supports them, rather than a pure multimodal or highway-only approach.',
  ARRAY['https://en.wikipedia.org/wiki/Derek_Tran','https://en.wikipedia.org/wiki/California%27s_45th_congressional_district','https://en.wikipedia.org/wiki/New_Democrat_Coalition'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
