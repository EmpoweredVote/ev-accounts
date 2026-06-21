-- 1013_tony_wu_stances.sql
-- Phase 152 Wave 4 (WCOV-01): evidence-only compass stances for Tony Wu (West Covina D5, ext_id 687367).
-- AUDIT-ONLY raw SQL: does NOT register in schema_migrations (ledger stays 1011). Committed to EV-Accounts.
-- CHAIRS model (value = the chair the evidence matches). 100% citation. Honest blanks for everything omitted.
-- pol_id 1bb5c062-9b9d-44de-820b-c3efe0d08222. 6 evidence-backed stances; all federal/state topics blank.

BEGIN;

-- public-safety-approach = 4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1bb5c062-9b9d-44de-820b-c3efe0d08222','e9ebefcd-c496-45e8-b816-a79f8442ba85',4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1bb5c062-9b9d-44de-820b-c3efe0d08222','e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Wu's campaign touts that the council under his leadership added 10 police officers ("making our police force 100 strong") and installed the Flock camera system; as mayor his stated public-safety priority is "enhancing resources for police, fire, emergency services." This matches increasing police staffing/equipment to deter crime and improve response (chair 4).$$,
ARRAY['https://wuforwestcovina.com/','https://www.westcovina.org/Home/Components/News/News/2745/17']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- economic-development = 4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1bb5c062-9b9d-44de-820b-c3efe0d08222','eb3d1247-0de1-4b7f-baec-7259861efd53',4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1bb5c062-9b9d-44de-820b-c3efe0d08222','eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Wu has aggressively recruited major employers (Sprouts, Grocery Outlet, SF Supermarket) and championed the 200+ room BKK landfill resort hotel as a revenue strategy to pay off city bonds, celebrating West Covina being named a top "business-savvy" city. Active competition to attract large employers and grow the tax base matches chair 4.$$,
ARRAY['https://wuforwestcovina.com/','https://davidcarmany.com/as-bkk-landfill-developments-continue-many-west-covina-residents-still-dissent/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- growth-and-development = 4
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1bb5c062-9b9d-44de-820b-c3efe0d08222','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1bb5c062-9b9d-44de-820b-c3efe0d08222','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Wu has for years pushed to develop the former BKK landfill and build hotels, voting to extend the Singpoli purchasing agreement and stating it is "not the city's job to tell Singpoli what they can or can't build." He frames welcoming development as a revenue strategy — a pro-development, recruit-to-grow-the-tax-base posture (chair 4).$$,
ARRAY['https://davidcarmany.com/as-bkk-landfill-developments-continue-many-west-covina-residents-still-dissent/','https://sac.media/2018/11/21/west-covina-residents-speak-against-singpolis-hotel-on-a-dump/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- homelessness-response = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1bb5c062-9b9d-44de-820b-c3efe0d08222','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1bb5c062-9b9d-44de-820b-c3efe0d08222','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Under Wu the city runs the H.O.P.E. (Homeless Outreach Park Enforcement) team, partners with LAHSA, supported the Rapid Rehousing program, frames its philosophy as "a Hand Up & Not a Hand Out," and acknowledges it cannot legally remove someone simply for being in a park. Investment in outreach/shelter/services alongside enforcement of reasonable public-space rules matches chair 3.$$,
ARRAY['https://www.westcovina.gov/330/Homeless-Solutions-for-West-Covina','https://wuforwestcovina.com/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- housing = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1bb5c062-9b9d-44de-820b-c3efe0d08222','669cac97-66a6-4087-b036-936fbe62efb3',3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1bb5c062-9b9d-44de-820b-c3efe0d08222','669cac97-66a6-4087-b036-936fbe62efb3',
$$Wu's campaign highlights that major housing projects "all feature city requested first-time homebuyer down payment assistance" — targeted buyer-assistance subsidies attached to private development rather than public housing or rent caps. This targeted-help approach matches chair 3.$$,
ARRAY['https://wuforwestcovina.com/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- taxes = 3
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1bb5c062-9b9d-44de-820b-c3efe0d08222','f7e5678d-dadd-4556-a2fc-446e24642ceb',3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1bb5c062-9b9d-44de-820b-c3efe0d08222','f7e5678d-dadd-4556-a2fc-446e24642ceb',
$$Wu's fiscal record emphasizes growing reserves (from $9M in 2018 to over $24M), running a surplus, and refinancing the pension liability — generating revenue through development rather than raising tax rates. With no record of proposing tax increases or major service cuts, his approach to keep the existing tax structure stable matches chair 3.$$,
ARRAY['https://wuforwestcovina.com/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

COMMIT;
-- AUDIT-ONLY: not registered in schema_migrations (ledger stays 1011).
