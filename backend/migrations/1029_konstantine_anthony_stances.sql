-- 1029_konstantine_anthony_stances.sql
-- Phase 154 Burbank deep-seed Wave 4 — evidence-only compass stances for Konstantine Anthony
-- AUDIT-ONLY: raw SQL applied live via Supabase MCP, NOT registered in supabase_migrations.schema_migrations (ledger stays 1027).
-- CHAIRS model (value = the chair the evidence matches, never a polarity axis). 100% citation (paired
-- inform.politician_answers + inform.politician_context, every stance with reasoning + >=1 real source URL).
-- No defaulted/neutral values; honest blank spokes omitted. NO judicial-* topics (council-manager city).
-- politician_id 6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7 | 13 stances.

BEGIN;

-- public-safety-approach = 1
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 1)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 'Anthony publicly declared himself a ''full abolitionist'' in 2023, stating he supports eliminating police and prisons entirely to end the ''carceral state.'' His 2020 campaign called for decoupling the Mental Health Evaluation Team from police oversight and redirecting non-criminal police duties to other agencies, and he opposes qualified immunity and predictive policing. Chair 1 (''redirect a significant portion of the police budget to social services'') is the closest match; his actual stated position goes even further than chair 1, but chair 1 is the highest available and best matches his documented direction.', ARRAY['https://www.foxnews.com/media/democrat-mayor-spanked-drag-queen-wants-destroy-police-prisons-claims-marxism-real-american-dream', 'https://myburbank.com/city-council-candidate-question-6-defunding-the-police-and-race-relations/', 'https://la.streetsblog.org/2020/12/21/interview-with-newly-elected-burbank-city-councilmember-konstantine-anthony']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- jail-capacity = 1
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0', 1)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0', 'Anthony''s self-described ''full abolitionist'' position explicitly includes the elimination of prisons as part of ending the ''carceral state,'' placing him squarely at chair 1 (redirect incarceration funding into community-based alternatives to shrink the jail system). His 2020 campaign also advocated for decoupling mental health response from policing, consistent with diversion over incarceration.', ARRAY['https://www.foxnews.com/media/democrat-mayor-spanked-drag-queen-wants-destroy-police-prisons-claims-marxism-real-american-dream', 'https://myburbank.com/city-council-candidate-question-6-defunding-the-police-and-race-relations/']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- rent-regulation = 1
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 1)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 'In the October 2024 Burbank rent cap vote (which passed 3-1 as a 4% soft cap), Anthony voted YES and had advocated for a harder cap as low as 3%. His campaign explicitly stated he spent four years pushing for ''real tenant protections and rent stabilization in the form of a robust ordinance.'' His preferred position — a hard cap lower than 4% applied to all rental units — aligns with chair 1 (''expand rent control to all rental units with strong tenant protections and just-cause eviction requirements'').', ARRAY['https://outlooknewspapers.com/burbankleader/burbank-city-council-votes-for-soft-rent-cap/article_7ab49793-bbb8-410a-84d1-0de1911a0cb3.html', 'https://lapublicpress.org/2024/01/burbank-is-a-city-of-renters-its-looking-to-expand-tenant-protections-in-2024/']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness-response = 1
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 1)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 'Anthony''s stated primary goal when taking office was to open Burbank''s first year-round homeless shelter ''with all the wraparound services normally associated with the Housing First Model.'' He unanimously co-adopted the 2022-2027 homelessness plan expanding services and shelter capacity. He expressed frustration at the city''s failure to build a shelter sooner and supports Housing First with no criminalization — consistent with chair 1.', ARRAY['https://ballotpedia.org/Konstantine_Anthony_(Burbank_City_Council_At-large,_California,_candidate_2024)', 'https://burbankleader.outlooknewspapers.com/2022/11/23/city-doubles-down-on-services-for-homeless-people/', 'https://la.streetsblog.org/2020/12/21/interview-with-newly-elected-burbank-city-councilmember-konstantine-anthony']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness = 2
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', '4938766b-b45a-46e3-93bd-b8b30651271a', 'Anthony''s approach centers on expanding shelter capacity and services as the primary strategy rather than criminalization — he co-adopted a 5-year homelessness plan focused on building a supportive housing shelter, increasing outreach funding, and investing in wraparound services. His Housing First rhetoric and opposition to criminalization place him at chair 2 (decriminalize public sleeping while investing in shelter capacity, outreach workers, and voluntary service connections), rather than chair 1 which would mean protecting a ''right to sleep in public spaces.''', ARRAY['https://burbankleader.outlooknewspapers.com/2022/11/23/city-doubles-down-on-services-for-homeless-people/', 'https://www.burbankca.gov/burbanks-response/homelessness-plan', 'https://ballotpedia.org/Konstantine_Anthony_(Burbank_City_Council_At-large,_California,_candidate_2024)']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change = 2
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 'Anthony co-championed Burbank''s Green New Deal (passed 2022), which commits the city to a 50% carbon reduction by 2030 and carbon neutrality by 2040, and he has pushed to accelerate the net-zero goal beyond 2040. He supports banning single-use plastics, adopting battery storage technology, and expanding recycled water infrastructure. This maps to chair 2 (''rapidly transition to renewable energy and phase out fossil fuels by 2030'').', ARRAY['https://lalcv.org/los-angeles-league-of-conservation-voters-endorses-konstantine-anthony-and-eddy-polon-for-burbank-city-council/', 'https://ballotpedia.org/Konstantine_Anthony_(Burbank_City_Council_At-large,_California,_candidate_2024)']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- local-environment = 1
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 1)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 'As part of co-championing the Burbank Green New Deal, Anthony helped pass a requirement that new developments must include parks and open space. The LALCV endorsement specifically cites his ''passing the requirement for new developments to have parks and open space'' and his investment in stormwater infrastructure. This matches chair 1 (''require significant green space, tree preservation, and environmental review before approving any development'').', ARRAY['https://lalcv.org/los-angeles-league-of-conservation-voters-endorses-konstantine-anthony-and-eddy-polon-for-burbank-city-council/', 'https://ballotpedia.org/Konstantine_Anthony_(Burbank_City_Council_At-large,_California,_candidate_2024)']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- transportation-priorities = 1
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 1)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 'Anthony chaired Burbank''s Transportation Commission from 2017 to 2020 and worked on the Complete Streets Plan. He advocates protected bike lanes on Alameda Avenue, 3rd Street, and Hollywood Way; dedicated bus lanes for Metro BRT; 15-minute bus frequency; fare-free transit; and seamless bike path connections. Streets For All endorsed him. This aligns with chair 1 (''prioritize pedestrian infrastructure, cycling networks, and public transit; reduce parking requirements citywide'').', ARRAY['https://la.streetsblog.org/2020/12/21/interview-with-newly-elected-burbank-city-councilmember-konstantine-anthony', 'https://www.streetsforall.org/2024-voter-guide']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing = 2
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', '669cac97-66a6-4087-b036-936fbe62efb3', 2)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', '669cac97-66a6-4087-b036-936fbe62efb3', 'Anthony''s rent stabilization push, campaign commitment to ''housing justice'' and championing renters, and explicit refusal of developer/landlord/realtor donations signal a strong pro-regulation housing stance. His preferred hard rent cap + just-cause eviction protections go beyond subsidies, matching chair 2 (''use rent caps, require new developments to include affordable units, and publicly fund new housing''). He has not publicly called for the city to directly build and operate public housing, making chair 1 a stretch.', ARRAY['https://outlooknewspapers.com/burbankleader/burbank-city-council-votes-for-soft-rent-cap/article_7ab49793-bbb8-410a-84d1-0de1911a0cb3.html', 'https://www.konstantineanthony.com/']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights = 2
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', '0bc588c6-39e1-4084-b5de-cac909b8b762', 'Anthony campaigned on BIPOC rights and support, spoke at Black Lives Matter demonstrations in 2020, opposed qualified immunity, and calls himself an ''abolitionist.'' His platform included hate crime reporting improvements and equity across city departments. His positions go well beyond maintaining current laws; they match chair 2 (''strengthen civil rights enforcement and address systemic discrimination''). Chair 1 (''mandate racial equity requirements and reparations'') was not specifically evidenced with a reparations position.', ARRAY['https://myburbank.com/city-council-candidate-question-6-defunding-the-police-and-race-relations/', 'https://progressivevotersguide.com/california/2020/general/konstantine-anthony']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- local-immigration = 1
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 1)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', 'b9ccee94-ad96-4f10-b655-889d8e5abe92', 'Anthony posted ''ICE out of Burbank'' on Instagram (June 2026) and is associated with anti-ICE organizing in the city. The DSA-LA Immigration Justice Committee publicly criticized Anthony and the council for renewing Flock''s contract (which shares data with ICE), indicating that he is expected — by his own base — to actively oppose ICE cooperation. His self-identification as a democratic socialist/abolitionist and his BLM/immigrant-rights activist record places him at chair 1 (''refuse all ICE detainers; prohibit city employees from sharing immigration status information with federal agencies''). Note: the Flock vote (June 2026) is a complication — he voted for budget renewal including Flock — but this appears to be a single budget-process vote rather than a reversal of his stated local-immigration position.', ARRAY['https://www.instagram.com/p/DUJiR7DEy2T/', 'https://dsa-la.org/expression-of-disapproval-burbank-city-council-budget-flock-inclusion/']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- campaign-finance = 1
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', '92730f69-ae57-401c-8ad1-2d07834a895d', 1)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', '92730f69-ae57-401c-8ad1-2d07834a895d', 'Anthony explicitly refuses donations from corporations, corporate PACs, property developers, realtors, landlords, fossil fuel executives, and police associations — a full corporate-free pledge. His identification as a democratic socialist is consistent with broadly opposing private money in politics, matching chair 1 (''ban all private money in politics and publicly fund campaigns'') more closely than chair 2. His campaign website explicitly lists these refusals.', ARRAY['https://www.konstantineanthony.com/']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- economic-development = 2
INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 2)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES ('6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 'Anthony''s 2020 platform explicitly prioritized small businesses (''return Burbank to its roots as a union town,'' protecting ''mom and pop businesses,'' and vanishing small businesses). He refuses corporate developer and real estate donations. As a DSA member who critique large corporation executives, he aligns with chair 2 (''small business support and local entrepreneur programs only; avoid large corporate subsidies'') rather than chair 1 (no tax incentives at all).', ARRAY['https://la.streetsblog.org/2020/12/21/interview-with-newly-elected-burbank-city-councilmember-konstantine-anthony', 'https://www.konstantineanthony.com/']::text[])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;

-- Post-apply verification:
--   SELECT COUNT(*) FROM inform.politician_answers WHERE politician_id='6c4c7919-3e7f-41fa-8b1b-1c8b421fe4a7'; -> 13
--   every answer has a paired context row (0 unpaired); 0 judicial-* topics; ledger MAX unchanged (1027).
