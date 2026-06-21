-- 931_victor_preciado_stances.sql — Phase 147 Wave 4 — AUDIT-ONLY (NOT registered in schema_migrations)
-- Victor Preciado (D2, external_id 675753). Evidence-only chairs; 100% citation; no judicial topics.
DO $do$
DECLARE pid uuid;
BEGIN
  SELECT id INTO pid FROM essentials.politicians WHERE external_id = 675753;

  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
    (pid,'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',2),
    (pid,'669cac97-66a6-4087-b036-936fbe62efb3',2),
    (pid,'4e2c69ce-591e-4197-9cd5-7aceff79d390',2),
    (pid,'b9ccee94-ad96-4f10-b655-889d8e5abe92',1),
    (pid,'1935979c-b290-42e4-baa5-8cb0138b4ffa',1),
    (pid,'eb3d1247-0de1-4b7f-baec-7259861efd53',3),
    (pid,'ba59337e-30e2-4aba-a39a-426b3366eb27',2)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
    (pid,'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',$$Voted YES on the second reading (Oct 20 2025) and the Nov 17 2025 permanent Rent Stabilization Ordinance making Pomona's 5% annual cap (pre-1995 units) permanent — supporting extending/strengthening rent stabilization rather than full rent control or opposition.$$,ARRAY['https://la.streetsblog.org/2025/11/07/pomona-approves-rent-control','https://www.thepomonan.com/theopera/2025/10/28/pomona-city-council-quietly-reverses-course-on-rent-cap-ordinance']),
    (pid,'669cac97-66a6-4087-b036-936fbe62efb3',$$Campaign priorities call to 'continue to build housing at all affordability levels, expanding inclusionary housing,' paired with his support for rent stabilization — inclusionary requirements plus rent caps rather than market-only.$$,ARRAY['https://victorforpomona.com/priorities','https://la.streetsblog.org/2025/11/07/pomona-approves-rent-control']),
    (pid,'4e2c69ce-591e-4197-9cd5-7aceff79d390',$$Took 'a deliberate stance against federal immigration enforcement actions, leading Pomona's efforts to ensure all residents are protected from ICE,' and co-organizes 'CommUnity Pull Up' resource fairs serving residents regardless of status — a welcoming, services-inclusive posture.$$,ARRAY['https://victorforpomona.com/about-victor/']),
    (pid,'b9ccee94-ad96-4f10-b655-889d8e5abe92',$$Described as leading Pomona's efforts to protect residents from ICE; the council unanimously adopted (April 2026) a resolution barring city property from being used as a staging area for federal immigration enforcement — the most protective, non-cooperative local stance.$$,ARRAY['https://victorforpomona.com/about-victor/','https://thepolypost.com/news/2026/04/14/pomona-adopts-ice-resolution/']),
    (pid,'1935979c-b290-42e4-baa5-8cb0138b4ffa',$$Record centers expanding green space: 'revitalized every park in District 2' (skate park, large playground, community garden) and secured a $500,000 grant to begin transforming the Palm Lakes Golf Course — a strong require-green-space priority.$$,ARRAY['https://victorforpomona.com/about-victor/']),
    (pid,'eb3d1247-0de1-4b7f-baec-7259861efd53',$$Prioritizes 'attracting and retaining quality jobs while supporting small and local businesses' and allocated over $100,000 of ARPA funds to 15 microgrants for community organizations — a targeted, community-benefit approach.$$,ARRAY['https://victorforpomona.com/priorities','https://victorforpomona.com/about-victor/']),
    (pid,'ba59337e-30e2-4aba-a39a-426b3366eb27',$$Serves on the Foothill Transit board where 'he emphasizes community accessibility' and lists 'ensuring equitable transportation' as a priority — multimodal/transit-supportive investment.$$,ARRAY['https://victorforpomona.com/about-victor/'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
END $do$;
