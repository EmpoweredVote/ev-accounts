-- Full coverage sprint for Katy Yaroslavsky (politician_id: 10678016-146d-4543-941c-00414b4c4ad2)
-- LA City Council District 5
-- Group A: update 6 existing thin rows + fix values on climate-change (3→2) and fossil-fuels (3→2)
--          (climate-change, fossil-fuels, homelessness-response, housing, local-immigration, rent-regulation)
-- Group B: insert 14 new answer+context rows
--          (abortion, childcare, civil-rights, deportation, economic-development, healthcare,
--           homelessness, immigration, jail-capacity, same-sex-marriage, school-vouchers,
--           taxes, trans-athletes, voting-rights)
-- Skipped: ai-regulation, campaign-finance, misinformation, data-centers — no local council record

-- ── GROUP A: Update existing thin context rows ────────────────────────────────

-- climate-change: value 3→2 (career at Climate Action Reserve)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '10678016-146d-4543-941c-00414b4c4ad2' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';

UPDATE inform.politician_context SET
  reasoning = 'Prior to her council career Yaroslavsky served as general counsel and director of government affairs at Climate Action Reserve, a nonprofit dedicated to reducing greenhouse gas emissions through carbon markets, and helped create LA County''s Office of Sustainability. She also co-developed Measure W (the Safe, Clean Water Program) in 2018, stating ''You can''t talk about water anymore without also talking about climate change.'' Her council record reflects rapid renewable transition advocacy consistent with aggressive climate action.',
  sources = ARRAY['https://www.planningreport.com/2019/09/03/katy-young-yaroslavsky-unpacks-measure-w-implementation-la-s-safe-clean-water-program','https://en.wikipedia.org/wiki/Katy_Yaroslavsky','https://www.climateactionreserve.org/about/']
WHERE politician_id = '10678016-146d-4543-941c-00414b4c4ad2' AND topic_id = 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c';

-- fossil-fuels: value 3→2 (career trajectory at GHG-reduction nonprofit)
UPDATE inform.politician_answers SET value = 2
WHERE politician_id = '10678016-146d-4543-941c-00414b4c4ad2' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';

UPDATE inform.politician_context SET
  reasoning = 'Yaroslavsky spent years as general counsel at Climate Action Reserve, whose core mission is advancing carbon credit markets and greenhouse gas reductions — a signal of strong opposition to unregulated fossil fuel use. She worked to expand stormwater capture to reduce reliance on imported (energy-intensive) water and framed climate and water policy as inseparable. No evidence she supports expanded fossil fuel extraction; her career trajectory aligns with halting new permits rather than expanding production.',
  sources = ARRAY['https://www.planningreport.com/2019/09/03/katy-young-yaroslavsky-unpacks-measure-w-implementation-la-s-safe-clean-water-program','https://en.wikipedia.org/wiki/Katy_Yaroslavsky']
WHERE politician_id = '10678016-146d-4543-941c-00414b4c4ad2' AND topic_id = 'a22215c3-6693-4bc2-b248-01aebba14570';

UPDATE inform.politician_context SET
  reasoning = 'In a 2021 forum Yaroslavsky said ''Moving people from one corner to another is not how we solve homelessness,'' and advocated pairing enforcement with outreach, housing placement, and services. She supported doubling or tripling the share of the homelessness budget devoted to prevention and backed county-city coordination on mental health and addiction services. Her approach combines shelter investment and services with reasonable public-space enforcement.',
  sources = ARRAY['https://beverlypress.com/2021/09/weho-explores-opening-a-homeless-services-center/','https://www.westsidecurrent.com/elections/katy-young-yaroslavsky-set-to-win-la-councils-5th-district-seat-yebri-concedes/article_dc418cf2-651d-11ed-b569-b75e1a947e81.html']
WHERE politician_id = '10678016-146d-4543-941c-00414b4c4ad2' AND topic_id = '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f';

UPDATE inform.politician_context SET
  reasoning = 'In 2024 Yaroslavsky introduced a motion to block ED1 fast-tracked affordable housing in all of LA''s Historic Preservation Overlay Zones (HPOZs), including a proposed 70-unit affordable building her chief of staff called ''egregious.'' In 2025 she voted with a slim council majority to oppose SB 79, legislation that would have allowed more housing development near metro and bus stations. These two actions — blocking both fast-track affordable production and transit-oriented density — align with reducing regulations and letting private developers solve shortages.',
  sources = ARRAY['https://laist.com/news/housing-homelessness/los-angeles-city-affordable-housing-ed1-historic-preservation-zones-yaroslavsky-motion','https://laist.com/news/housing-homelessness/los-angeles-metro-board-of-directors-sb-79-opposition-vote']
WHERE politician_id = '10678016-146d-4543-941c-00414b4c4ad2' AND topic_id = '669cac97-66a6-4087-b036-936fbe62efb3';

UPDATE inform.politician_context SET
  reasoning = 'Los Angeles is a sanctuary city. In 2024 the city council passed an ordinance prohibiting city resources from being used in immigration enforcement or cooperation with federal immigration agents unless required by state law. Yaroslavsky, a Democrat representing a district with a large immigrant population, has not broken from the council''s sanctuary city consensus. No record found of her opposing or abstaining on sanctuary protections.',
  sources = ARRAY['https://en.wikipedia.org/wiki/Sanctuary_city','https://en.wikipedia.org/wiki/Katy_Yaroslavsky']
WHERE politician_id = '10678016-146d-4543-941c-00414b4c4ad2' AND topic_id = 'b9ccee94-ad96-4f10-b655-889d8e5abe92';

UPDATE inform.politician_context SET
  reasoning = 'No direct votes on rent control expansion by Yaroslavsky were found, but her broader housing record is market-oriented: she blocked affordable housing fast-tracking in HPOZs (2024) and opposed SB 79 transit-oriented density (2025), prioritizing neighborhood character and market processes over tenant protection mandates. West LA District 5 is one of the most expensive rental markets in the city; her housing votes signal limited appetite for new rent regulations beyond existing RSO protections.',
  sources = ARRAY['https://laist.com/news/housing-homelessness/los-angeles-city-affordable-housing-ed1-historic-preservation-zones-yaroslavsky-motion','https://laist.com/news/housing-homelessness/los-angeles-metro-board-of-directors-sb-79-opposition-vote']
WHERE politician_id = '10678016-146d-4543-941c-00414b4c4ad2' AND topic_id = 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2';

-- ── GROUP B: New answer + context rows ───────────────────────────────────────

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2', 'af2fdfd6-02c4-49df-b09c-cf8536f4773f', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2','af2fdfd6-02c4-49df-b09c-cf8536f4773f',
  'Yaroslavsky is a Democrat representing a heavily progressive West LA district (Westwood, Bel Air, Pico-Robertson) and has not taken any position contrary to full abortion access. While no specific city council vote on abortion was found — LA City Council does not legislate on state abortion law — she has consistently identified with the progressive wing of the Democratic Party. California law ensures broad access; no evidence she would restrict it.',
  ARRAY['https://en.wikipedia.org/wiki/Katy_Yaroslavsky'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2', 'c1ac1330-47f7-44ec-baf3-c913d926b97c', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2','c1ac1330-47f7-44ec-baf3-c913d926b97c',
  'No specific vote or statement on childcare policy was found. As a council member with three children representing a district that includes working families in Westwood and Pico-Robertson, Yaroslavsky has expressed concern for housing affordability and equitable access to public services. Her mentor Sheila Kuehl was a champion of childcare and early childhood programs at the state and county level. Consistent with significant subsidy expansion for low- and middle-income families.',
  ARRAY['https://en.wikipedia.org/wiki/Katy_Yaroslavsky'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2', '0bc588c6-39e1-4084-b5de-cac909b8b762', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2','0bc588c6-39e1-4084-b5de-cac909b8b762',
  'Yaroslavsky worked for Supervisor Sheila Kuehl, one of California''s strongest civil rights advocates, and has described her public-service values as rooted in equity. She said in 2022 that infrastructure development must ensure ''the people building and maintaining all of this new infrastructure can afford to live and raise their families here.'' No record of opposing civil rights enforcement; her background at Climate Action Reserve and working for Kuehl aligns with strengthening civil rights protections and addressing systemic discrimination.',
  ARRAY['https://www.planningreport.com/2019/09/03/katy-young-yaroslavsky-unpacks-measure-w-implementation-la-s-safe-clean-water-program','https://jewishinsider.com/2022/06/los-angeles-city-council-sam-yebri-katy-young-yaroslavsky-scott-epstein-jimmy-biblarz/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2', '44905f3b-e105-4f6c-afc7-5d223813dbac', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2','44905f3b-e105-4f6c-afc7-5d223813dbac',
  'As a member of a sanctuary city council, Yaroslavsky operates within LA''s policy framework prohibiting city resources from aiding immigration enforcement. District 5 is home to many immigrant communities. No statement found endorsing mass deportation or deviating from LA''s posture of deporting only those with serious criminal records while providing legal status pathways for others.',
  ARRAY['https://en.wikipedia.org/wiki/Sanctuary_city'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2', 'eb3d1247-0de1-4b7f-baec-7259861efd53', 3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2','eb3d1247-0de1-4b7f-baec-7259861efd53',
  'No direct statement or vote found specifically on business incentive policy. Her background blends public-sector sustainability work with private-sector experience. Her 2022 campaign emphasized collaborative governance, cross-sector partnership, and leveraging funding streams across municipal, county, state, and federal levels — suggesting a targeted-incentives approach with accountability requirements rather than maximum corporate subsidies or no incentives at all.',
  ARRAY['https://jewishinsider.com/2022/06/los-angeles-city-council-sam-yebri-katy-young-yaroslavsky-scott-epstein-jimmy-biblarz/'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2', 'e8dad4a8-eb93-4931-91f5-d8fb5d7dd529', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2','e8dad4a8-eb93-4931-91f5-d8fb5d7dd529',
  'No specific LA City Council votes on healthcare access were found; healthcare is primarily a state and federal issue. Yaroslavsky worked for Supervisor Sheila Kuehl, who was California''s most prominent single-payer healthcare advocate. She has expressed views consistent with expanding access. No evidence she supports full single-payer or leaving it to markets; her background and party alignment place her closest to a public option with regulated private insurance.',
  ARRAY['https://en.wikipedia.org/wiki/Katy_Yaroslavsky'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2', '4938766b-b45a-46e3-93bd-b8b30651271a', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2','4938766b-b45a-46e3-93bd-b8b30651271a',
  'Yaroslavsky described homelessness as ''the moral crisis of our time'' and called for dramatically increasing prevention funding, stating ''We''re spending maybe 1% or 2% of our total homelessness budget on prevention, and I think if we doubled or tripled that, we''d see huge progress.'' She supported a housing-first philosophy and keeping people housed rather than relying on street-based responses.',
  ARRAY['https://beverlypress.com/2021/09/weho-explores-opening-a-homeless-services-center/','https://www.westsidecurrent.com/elections/katy-young-yaroslavsky-set-to-win-la-councils-5th-district-seat-yebri-concedes/article_dc418cf2-651d-11ed-b569-b75e1a947e81.html'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2', '4e2c69ce-591e-4197-9cd5-7aceff79d390', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2','4e2c69ce-591e-4197-9cd5-7aceff79d390',
  'Yaroslavsky sits on an LA City Council that has maintained sanctuary city protections and enacted a 2024 ordinance barring city resources from immigration enforcement. Her 2022 campaign did not feature restrictive immigration rhetoric; her connection to Sheila Kuehl — who explicitly expanded protections for undocumented crime victims — signals support for significantly expanding legal pathways.',
  ARRAY['https://en.wikipedia.org/wiki/Sanctuary_city'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2', 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2','c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
  'No specific vote or statement on jail expansion was found. As a progressive Democrat on the LA City Council, Yaroslavsky''s record on homelessness (prioritizing services and prevention over incarceration) and public safety (not endorsing mass incarceration approaches) suggests alignment with reducing the incarcerated population through diversion and alternatives rather than building new capacity.',
  ARRAY['https://en.wikipedia.org/wiki/Katy_Yaroslavsky'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2', 'c5ab4eab-702f-49b8-9277-8ea53f3835c6', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2','c5ab4eab-702f-49b8-9277-8ea53f3835c6',
  'Yaroslavsky is a Democrat representing one of California''s most LGBTQ-affirming districts (West Hollywood is adjacent). No record of her opposing same-sex marriage; her mentor Sheila Kuehl co-authored California''s first same-sex marriage bill in 2002. California has recognized same-sex marriage since 2013. No evidence of any dissent from full federal recognition and protections.',
  ARRAY['https://en.wikipedia.org/wiki/Sheila_Kuehl'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2', '00b95a6a-75db-4521-b523-3326bba938de', 1)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2','00b95a6a-75db-4521-b523-3326bba938de',
  'No specific vote or statement on school vouchers was found at the LA City Council level (school funding is primarily a state issue). However, Yaroslavsky''s district includes LAUSD schools and she has supported robust public services. As a progressive Democrat in California with a background in equity-focused public policy, she shows no alignment with voucher programs that divert taxpayer money from public schools.',
  ARRAY['https://en.wikipedia.org/wiki/Katy_Yaroslavsky'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2', 'f7e5678d-dadd-4556-a2fc-446e24642ceb', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2','f7e5678d-dadd-4556-a2fc-446e24642ceb',
  'No specific vote on city tax measures was found in Yaroslavsky''s council record. She has not campaigned on tax cuts; her 2022 platform emphasized robust public services and infrastructure investment funded through regional collaboration. Her District 5 (West LA, Bel Air) includes high earners; no evidence she opposes modest increases on high earners to fund services.',
  ARRAY['https://en.wikipedia.org/wiki/Katy_Yaroslavsky'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2', 'd1618b9c-0b9e-45af-b986-bb33d270b8e4', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2','d1618b9c-0b9e-45af-b986-bb33d270b8e4',
  'No specific statement or vote by Yaroslavsky on transgender athletes was found. As a Democrat representing a progressive West LA district adjacent to West Hollywood, she has no record of supporting restrictions on transgender athletes. Her background working for Kuehl — who authored LGBTQ protections in California — signals consistent support for allowing transgender athletes to compete after basic transition documentation.',
  ARRAY['https://en.wikipedia.org/wiki/Sheila_Kuehl'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2', 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2', 2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('10678016-146d-4543-941c-00414b4c4ad2','d1792200-1d3b-4955-a0b7-0e6980d7a7b2',
  'No specific LA City Council vote on voting rights was found — elections are primarily administered by LA County. Yaroslavsky has expressed a commitment to civic engagement and democratic participation. As a progressive Democrat in LA she has no record opposing early voting, mail-in ballots, or access expansions. Her public service record and party alignment place her with expanding early voting and making mail-in voting available to all voters.',
  ARRAY['https://en.wikipedia.org/wiki/Katy_Yaroslavsky'])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
