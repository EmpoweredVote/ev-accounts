-- 929_tim_sandoval_stances.sql — Phase 147 Wave 4 — AUDIT-ONLY (NOT registered in schema_migrations)
-- Tim Sandoval (Mayor, external_id -200916). Evidence-only chairs; 100% citation; no judicial topics.
-- politician_id resolved by external_id at apply time.

DO $do$
DECLARE pid uuid;
BEGIN
  SELECT id INTO pid FROM essentials.politicians WHERE external_id = -200916;

  -- helper inserts (answer + context) per topic
  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
    (pid,'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',2),
    (pid,'669cac97-66a6-4087-b036-936fbe62efb3',2),
    (pid,'d4f18138-a2e0-4110-b925-7387d9d0d16d',3),
    (pid,'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',3),
    (pid,'6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',2),
    (pid,'b9ccee94-ad96-4f10-b655-889d8e5abe92',1),
    (pid,'4e2c69ce-591e-4197-9cd5-7aceff79d390',2),
    (pid,'ba59337e-30e2-4aba-a39a-426b3366eb27',1),
    (pid,'1935979c-b290-42e4-baa5-8cb0138b4ffa',1),
    (pid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',2)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
    (pid,'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',$$Led/championed Pomona's permanent Rent Stabilization & Eviction Control Ordinance (5% annual cap + just-cause), revived it after the initial version failed, and voted yes (5-1, Nov 17 2025). Strengthens local stabilization beyond the state baseline.$$,ARRAY['https://la.streetsblog.org/2025/11/07/pomona-approves-rent-control','https://members.aagla.org/news/editorial-news-alert-pomona-passes-permanent-rent-stabilization']),
    (pid,'669cac97-66a6-4087-b036-936fbe62efb3',$$Under Sandoval, Pomona adopted an inclusionary housing ordinance (7-13% affordable set-aside for developments over 3 units) plus the 5% rent cap and a pro-housing Housing Element, framed around preventing displacement.$$,ARRAY['https://www.westerncity.com/article/pomonas-housing-toolbox-holistic-long-term-plan-housing-construction','https://la.streetsblog.org/2025/11/07/pomona-approves-rent-control']),
    (pid,'d4f18138-a2e0-4110-b925-7387d9d0d16d',$$Pomona's housing strategy uses a transect plan (20 to 100+ units/acre) encouraging mixed-use along major corridors plus ADUs and missing-middle housing — multifamily near corridors rather than blanket upzoning.$$,ARRAY['https://www.westerncity.com/article/pomonas-housing-toolbox-holistic-long-term-plan-housing-construction']),
    (pid,'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',$$The 'housing toolbox' plans infrastructure and density together via a transect framework while streamlining approvals with objective design standards — planning density/infrastructure ahead of growth.$$,ARRAY['https://www.westerncity.com/article/pomonas-housing-toolbox-holistic-long-term-plan-housing-construction']),
    (pid,'6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',$$Opened the 'Hope for Home' services center, partnered on LA County's Pathway Home interim-housing-plus-services program, and backed Measure H homeless-services funding — a shelter-plus-services strategy.$$,ARRAY['https://www.pomonaca.gov/government/departments/neighborhood-services/homeless-programs','https://homeless.lacounty.gov/news/pathway-home-pomona/']),
    (pid,'b9ccee94-ad96-4f10-b655-889d8e5abe92',$$Pomona adopted a resolution (April 2026) barring use of city property for federal civil immigration enforcement staging and convened public hearings documenting alleged ICE abuses; Sandoval: 'no one in the Pomona community should feel unwanted or unwelcome.'$$,ARRAY['https://thepolypost.com/news/2026/04/14/pomona-adopts-ice-resolution/','https://claremont-courier.com/latest-news/public-hearing-documents-alleged-ice-abuses-in-pomona-88339/']),
    (pid,'4e2c69ce-591e-4197-9cd5-7aceff79d390',$$Convened the Pomona Compassion Fund (with the California Community Foundation) providing financial assistance, supplies, and health/legal resources to immigrant residents; consistently frames Pomona as a welcoming city.$$,ARRAY['https://www.pomonaca.gov/government/mayor-city-council/mayor-sandoval','https://thepolypost.com/news/2026/04/14/pomona-adopts-ice-resolution/']),
    (pid,'ba59337e-30e2-4aba-a39a-426b3366eb27',$$Serves on the LA Metro Board (SGV seat), chairs the Foothill Gold Line Construction Authority, sits on Metrolink's board, championed the Metro A Line extension to Pomona, and eliminated 20+ miles of truck routes for air quality/pedestrian safety — clear transit/pedestrian focus.$$,ARRAY['https://la.streetsblog.org/2021/01/06/pomona-mayor-tim-sandoval-elected-to-metro-board-to-represent-sgv','https://lalcv.org/los-angeles-league-of-conservation-voters-endorses-tim-sandoval-for-mayor-of-pomona-2/']),
    (pid,'1935979c-b290-42e4-baa5-8cb0138b4ffa',$$Eliminated 20+ miles of designated truck routes for air quality and pedestrian safety, works with Transformative Climate Communities on green infrastructure, and installed EV chargers at city parks — prioritizes environmental review and green space.$$,ARRAY['https://lalcv.org/los-angeles-league-of-conservation-voters-endorses-tim-sandoval-for-mayor-of-pomona-2/']),
    (pid,'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',$$Formed Pomona Choice Energy (community choice aggregation) to increase the city's use of renewable power and partners with the Transformative Climate Communities initiative — actively pushing renewables.$$,ARRAY['https://lalcv.org/los-angeles-league-of-conservation-voters-endorses-tim-sandoval-for-mayor-of-pomona-2/'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
END $do$;
