-- Migration 729: Freddy Puza (Culver City Council) Stances
-- Phase 130 — Culver City Stances. Freddy Puza, external_id -700550, UUID 1bb7df04-db6e-447f-b358-3f12526eb32e.
-- Council Member (rotational; serving as Mayor for 2026). Use "Council Member Puza" / rotational-Mayor qualifier where apt.
-- Topic UUIDs: rent-regulation=c308e8e8-caac-44f5-ab04-dbfecf40bbe2  housing=669cac97-66a6-4087-b036-936fbe62efb3
-- homelessness-response=6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f  civil-rights=0bc588c6-39e1-4084-b5de-cac909b8b762
-- transportation-priorities=ba59337e-30e2-4aba-a39a-426b3366eb27  climate-change=f1e44d66-5d27-4b51-b54f-b7ace86f6a3c

BEGIN;

-- rent-regulation = 2.0 (supports rent control; fiscally cautious on new tenant-counsel spending)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1bb7df04-db6e-447f-b358-3f12526eb32e', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1bb7df04-db6e-447f-b358-3f12526eb32e', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
$$Council Member Puza supports rent-control protections, framing them as creating "an equitable playing field" for tenants. On a Tenant Right to Counsel pilot he abstained, citing a predicted budget shortfall and a desire for a data-driven decision — a fiscally cautious nuance within a generally pro-tenant posture.$$,
ARRAY['https://www.culvercitynews.org/city-council-discusses-caveats-in-a-move-towards-permanent-rent-control/','https://culvercitycrossroads.com/2025/04/18/city-council-steps-back-on-tenant-right-to-council-motion-fails-on-a-2-2-1-vote/']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing = 2.0 (funded 93-unit affordable housing shortfall)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1bb7df04-db6e-447f-b358-3f12526eb32e', '669cac97-66a6-4087-b036-936fbe62efb3', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1bb7df04-db6e-447f-b358-3f12526eb32e', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Council Member Puza voted to provide direct city financial support to cover a funding shortfall for a 93-unit affordable housing project, backing expanded affordable-housing production in Culver City.$$,
ARRAY['https://culvercitycrossroads.com/2025/04/18/city-council-steps-back-on-tenant-right-to-council-motion-fails-on-a-2-2-1-vote/']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness-response = 2.0 (Committee on Homelessness; direct service + systemic solutions)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1bb7df04-db6e-447f-b358-3f12526eb32e', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1bb7df04-db6e-447f-b358-3f12526eb32e', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Before and during his council tenure, Puza served on Culver City's Committee on Homelessness and General Plan Advisory Committee, focusing on addressing homelessness through both direct services and systemic housing solutions rather than enforcement.$$,
ARRAY['https://www.losangelesblade.com/2026/01/14/we-will-get-through-all-of-this-culver-citys-first-lgbtq-mayor-discusses-queer-community-and-hope/']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights = 1.0 (first openly LGBTQ+ member/mayor; DEI platform)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1bb7df04-db6e-447f-b358-3f12526eb32e', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1bb7df04-db6e-447f-b358-3f12526eb32e', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$Puza is Culver City's first openly LGBTQ+ council member and first openly LGBTQ+ Mayor, and ran a campaign explicitly centered on diversity, equity and inclusion and LGBTQ+ advancement, making civil rights and equity a defining priority.$$,
ARRAY['https://culvercitycrossroads.com/2022/03/16/puza-focuses-council-campaign-on-diversity-equity-and-inclusion/','https://www.losangelesblade.com/2026/01/14/we-will-get-through-all-of-this-culver-citys-first-lgbtq-mayor-discusses-queer-community-and-hope/']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- transportation-priorities = 1.0 (complete streets, Vision Zero, defended MOVE lanes)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1bb7df04-db6e-447f-b358-3f12526eb32e', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1bb7df04-db6e-447f-b358-3f12526eb32e', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Puza is a strong multimodal-transportation advocate: he was one of two "nay" votes against the April 2023 rollback of the MOVE Culver City bus and bike lanes, praised the project as "an absolute gamechanger," and backs complete streets, Vision Zero, and more car-free streets downtown to mitigate congestion, combat climate change, and improve safety.$$,
ARRAY['https://culvercitycrossroads.com/2023/04/25/council-votes-to-end-protected-bike-lanes-on-move-transit-project/','https://www.bikethevote.com/endorsement-freddy-puza']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change = 2.0 (ties mobility/policy to combating climate crisis)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1bb7df04-db6e-447f-b358-3f12526eb32e', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1bb7df04-db6e-447f-b358-3f12526eb32e', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$Puza frames city infrastructure decisions around climate, criticizing the MOVE rollback as the council majority retreating "on mobility and climate progress" and advocating complete streets specifically to "combat the climate crisis."$$,
ARRAY['https://www.culvercitynews.org/council-votes-to-change-move-culver-city/']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
