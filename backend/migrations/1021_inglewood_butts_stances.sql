-- 1021_inglewood_butts_stances.sql
-- Phase 153 Wave 4 (INGL-01): evidence-only compass stances for Mayor James T. Butts Jr.
--   (Inglewood, directly-elected Mayor since 2011; ext_id -200740, pol f5775ca1-99f4-4cc2-acf2-5afaacdd94b3).
-- AUDIT-ONLY raw SQL: does NOT register in schema_migrations (ledger stays 1019). Committed to EV-Accounts.
-- CHAIRS model (value = the chair the evidence matches). 100% citation. Honest blanks for everything omitted.
-- 6 evidence-backed stances (richest record). Live non-judicial topic UUIDs confirmed at apply time.
-- OMITTED honest blanks: public-safety-approach (ex-police-chief but no citable budget action to pin chair 3 vs 4),
--   local-immigration, residential-zoning, local-environment, city-sanitation, taxes + all federal/state topics.

BEGIN;

-- rent-regulation = 2 (strengthen/extend rent stabilization)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f5775ca1-99f4-4cc2-acf2-5afaacdd94b3','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',2)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f5775ca1-99f4-4cc2-acf2-5afaacdd94b3','c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
$$Under Mayor Butts, Inglewood adopted one of the stronger rent-stabilization regimes in the greater LA area: covered units capped at 3% or CPI (whichever is greater) with just-cause eviction protections, building on the 2019-2020 Housing Protection Ordinance that tenant advocates campaigned to make lasting. The city actively strengthened and extended tenant protection rather than merely maintaining the status quo, matching chair 2.$$,
ARRAY['https://www.cityofinglewood.org/1594/Allowable-Rent-Increases','https://caanet.org/inglewood-adopts-rent-control-policy-with-3-cap/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- housing = 3 (targeted help for affordable projects alongside private development)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f5775ca1-99f4-4cc2-acf2-5afaacdd94b3','669cac97-66a6-4087-b036-936fbe62efb3',3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f5775ca1-99f4-4cc2-acf2-5afaacdd94b3','669cac97-66a6-4087-b036-936fbe62efb3',
$$Butts touts that Inglewood has among the lowest median rents in the South Bay and a large stock of affordable units per capita, achieved through the city's rent-stabilization law plus support for preserving and developing affordable housing (including transit-oriented projects blending market-rate and affordable units). This is targeted public help for affordable projects alongside private development, not city-built public housing, matching chair 3.$$,
ARRAY['https://www.cityofinglewood.org/820/Mayor-James-T-Butts--Bio','https://www.cityofinglewood.org/1594/Allowable-Rent-Increases']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- economic-development = 3 (targeted recruitment with community-benefit / local-hire requirements)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f5775ca1-99f4-4cc2-acf2-5afaacdd94b3','eb3d1247-0de1-4b7f-baec-7259861efd53',3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f5775ca1-99f4-4cc2-acf2-5afaacdd94b3','eb3d1247-0de1-4b7f-baec-7259861efd53',
$$Butts describes a "business-friendly" strategy that recruits major developers while explicitly avoiding large direct subsidies, pairing deals with community-benefit and job-quality requirements such as local-hire goals and developer-funded job training for Inglewood residents. Targeted recruitment tied to community benefit and job quality matches chair 3 rather than blanket tax-abatement competition.$$,
ARRAY['https://www.planningreport.com/2014/10/31/success-story-inglewood-mayor-james-butts','https://www.cityofinglewood.org/820/Mayor-James-T-Butts--Bio']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- growth-and-development = 4 (aggressive recruitment + infrastructure to grow the tax base)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f5775ca1-99f4-4cc2-acf2-5afaacdd94b3','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',4)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f5775ca1-99f4-4cc2-acf2-5afaacdd94b3','fb25c1ac-91cc-49bf-8afc-c7fa22ef45e4',
$$Butts aggressively recruited and enabled major development to grow Inglewood's tax base -- the Forum renovation, SoFi Stadium, and the Intuit Dome -- pairing it with heavy infrastructure investment (street reconstruction and the proposed Inglewood Transit Connector) to support that growth. City unemployment fell from 17.5% (2011) to 4.7% (2022) as reserves grew, reflecting a streamline-and-recruit, grow-the-tax-base posture matching chair 4.$$,
ARRAY['https://www.cityofinglewood.org/820/Mayor-James-T-Butts--Bio','https://en.wikipedia.org/wiki/James_T._Butts_Jr.']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- transportation-priorities = 3 (maintain roads while selectively adding transit where density supports)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f5775ca1-99f4-4cc2-acf2-5afaacdd94b3','ba59337e-30e2-4aba-a39a-426b3366eb27',3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f5775ca1-99f4-4cc2-acf2-5afaacdd94b3','ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Butts championed the Inglewood Transit Connector (an automated people-mover) to serve the city's sports/entertainment district and residents, securing more than $1B in federal funding, while also overseeing extensive roadway repaving. The transit investment was concentrated where new venue density justified it rather than a citywide pedestrian/transit-first overhaul, matching chair 3.$$,
ARRAY['https://www.cbsnews.com/losangeles/news/inglewood-to-receive-more-than-1-billion-in-federal-funding-for-transit-connector-project/','https://en.wikipedia.org/wiki/Inglewood_Transit_Connector']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

-- homelessness-response = 3 (services-with-enforcement)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('f5775ca1-99f4-4cc2-acf2-5afaacdd94b3','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',3)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value=EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('f5775ca1-99f4-4cc2-acf2-5afaacdd94b3','6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$Butts pairs services with enforcement: Inglewood partnered with LA County's "Pathway Home" to bring unsheltered residents indoors into interim housing with supportive services, while he simultaneously emphasized that the city "long enforced the concept of public right of way being unimpeded" and backed encampment-clearing measures. Outreach and services combined with enforcing public-space rules matches chair 3.$$,
ARRAY['https://homeless.lacounty.gov/pathway-home/a-pathway-home-in-inglewood/','https://www.gov.ca.gov/2024/07/29/what-theyre-saying-california-local-leaders-support-governor-newsoms-executive-order-to-address-homeless-encampments-with-compassion/']::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning=EXCLUDED.reasoning, sources=EXCLUDED.sources;

COMMIT;
-- AUDIT-ONLY: not registered in schema_migrations (ledger stays 1019). 6 stances; remaining topics honest blanks.
