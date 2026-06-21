-- 930_nora_garcia_stances.sql — Phase 147 Wave 4 — AUDIT-ONLY (NOT registered in schema_migrations)
-- Nora Garcia (D3, Vice Mayor, external_id -201350). Evidence-only chairs; 100% citation; no judicial topics.
DO $do$
DECLARE pid uuid;
BEGIN
  SELECT id INTO pid FROM essentials.politicians WHERE external_id = -201350;

  INSERT INTO inform.politician_answers (politician_id, topic_id, value) VALUES
    (pid,'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',2),
    (pid,'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',1),
    (pid,'1935979c-b290-42e4-baa5-8cb0138b4ffa',1),
    (pid,'b9ccee94-ad96-4f10-b655-889d8e5abe92',1),
    (pid,'4e2c69ce-591e-4197-9cd5-7aceff79d390',1),
    (pid,'d4f18138-a2e0-4110-b925-7387d9d0d16d',1)
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;

  INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources) VALUES
    (pid,'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',$$Voted YES on Pomona's permanent Rent Stabilization Ordinance (5% cap, Nov 17 2025, passed 5-1). As the council's only renter she pushed to go further — 'We need rental stabilization. We need a rental inspection ordinance. We need a rental registry' — strengthening/extending stabilization rather than full rent control on all units.$$,ARRAY['https://la.streetsblog.org/2025/11/07/pomona-approves-rent-control','https://caanet.org/pomona-council-approves-permanent-rent-control-ordinance-with-5-cap/']),
    (pid,'fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',$$Voted to extend Pomona's warehouse moratorium and supported zoning changes banning mega-warehouses and other uses that adversely impact neighborhoods — favoring hard limits on incompatible growth near residential areas over streamlined recruitment.$$,ARRAY['https://laist.com/brief/news/climate-environment/new-warehouses-will-be-allowed-in-pomona-again-after-city-council-ban-fails','https://noraforpomona.com/about/']),
    (pid,'1935979c-b290-42e4-baa5-8cb0138b4ffa',$$Living ~1,000 ft from an industrial zone, she framed warehouse truck traffic as an environmental-justice harm and backed the mega-warehouse/pallet-yard bans and zoning overhaul to protect neighborhoods from diesel pollution — prioritizing environmental protection in development.$$,ARRAY['https://laist.com/brief/news/climate-environment/new-warehouses-will-be-allowed-in-pomona-again-after-city-council-ban-fails','https://noraforpomona.com/about/']),
    (pid,'b9ccee94-ad96-4f10-b655-889d8e5abe92',$$Backed Pomona's April 2026 resolution barring city property from federal immigration-enforcement staging ('would not be allowed to organize, plan or plant their cars anywhere on city property') and described 2025 raids as agents coming to 'kidnap residents' — refusing cooperation and protecting residents.$$,ARRAY['https://thepolypost.com/news/2026/04/14/pomona-adopts-ice-resolution/']),
    (pid,'4e2c69ce-591e-4197-9cd5-7aceff79d390',$$Worked to provide resources and support for families and businesses harmed by immigration raids, attended community-defense events, and championed barring ICE from city property — a consistently welcoming, services-and-protection orientation.$$,ARRAY['https://noraforpomona.com/about/','https://thepolypost.com/news/2026/04/14/pomona-adopts-ice-resolution/']),
    (pid,'d4f18138-a2e0-4110-b925-7387d9d0d16d',$$Framed zoning around protecting District 3 neighborhood character from incompatible/industrial uses — championing the new Zoning Code and the Waste, Recycling, and Pallet Yard ban to keep harmful uses out of residential areas.$$,ARRAY['https://noraforpomona.com/about/'])
  ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;
END $do$;
