-- Migration 731: Yasmine-Imani McMorrin (Culver City Council) Stances
-- Phase 130 — Culver City. Yasmine-Imani McMorrin, external_id -700552, UUID 1408cd55-dccb-40fa-9296-049af125ec6f.
-- Council Member (rotational; has served as Mayor). First Black woman on CC council; "equity champion."
-- Topic UUIDs: rent-regulation=c308e8e8-caac-44f5-ab04-dbfecf40bbe2  housing=669cac97-66a6-4087-b036-936fbe62efb3
-- public-safety-approach=e9ebefcd-c496-45e8-b816-a79f8442ba85  transportation-priorities=ba59337e-30e2-4aba-a39a-426b3366eb27
-- climate-change=f1e44d66-5d27-4b51-b54f-b7ace86f6a3c  civil-rights=0bc588c6-39e1-4084-b5de-cac909b8b762

BEGIN;

-- rent-regulation = 1.0 (rent-control champion; moratorium, permanent RC, right to counsel)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1408cd55-dccb-40fa-9296-049af125ec6f', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1408cd55-dccb-40fa-9296-049af125ec6f', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
$$Council Member McMorrin is a leading rent-control advocate, championing the temporary eviction moratorium, the permanent rent control and tenant protections the council adopted, and the Tenant Right to Counsel pilot providing free legal support to renters facing eviction.$$,
ARRAY['https://www.culvercityobserver.com/story/2025/04/17/news/lot-program-to-provide-free-legal-support-to-rental-tenants-established/15019.html','https://inthesetimes.com/article/culver-city-california-progressive-daniel-lee-policing-rent-control-corporate-power-reparations']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing = 1.0 (upzoning, affordable-housing funding)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1408cd55-dccb-40fa-9296-049af125ec6f', '669cac97-66a6-4087-b036-936fbe62efb3', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1408cd55-dccb-40fa-9296-049af125ec6f', '669cac97-66a6-4087-b036-936fbe62efb3',
$$McMorrin has voted in favor of upzoning initiatives to allow more housing and advocates increasing funding for affordable housing projects to ensure long-term affordability, a strongly pro-supply, pro-affordability position.$$,
ARRAY['https://protectculvercity.org/2022/05/07/upzoning-culver-city/']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- public-safety-approach = 1.0 (advocate of defunding CCPD)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1408cd55-dccb-40fa-9296-049af125ec6f', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1408cd55-dccb-40fa-9296-049af125ec6f', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$McMorrin has advocated reallocating Culver City Police Department funding toward community services, supporting a non-enforcement-first, services-centered model of public safety.$$,
ARRAY['https://inthesetimes.com/article/culver-city-california-progressive-daniel-lee-policing-rent-control-corporate-power-reparations']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- transportation-priorities = 1.0 (defended MOVE; transit as climate/working-class justice)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1408cd55-dccb-40fa-9296-049af125ec6f', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1408cd55-dccb-40fa-9296-049af125ec6f', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$McMorrin voted against scaling back the MOVE Culver City bus and bike lanes, framing transit as a climate-justice and working-class issue, citing traffic deaths among children and the disproportionate harm to lower-income communities, and pledging to protect and expand MOVE.$$,
ARRAY['https://laist.com/news/transportation/culver-city-eliminates-bus-and-bike-lanes','https://www.culvercitynews.org/council-votes-to-change-move-culver-city/']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- climate-change = 2.0 (transit/green space as climate justice)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1408cd55-dccb-40fa-9296-049af125ec6f', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1408cd55-dccb-40fa-9296-049af125ec6f', 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
$$McMorrin frames mobility and land use as climate justice, championing expanded public transit, safer biking, and green community spaces as climate priorities for Culver City.$$,
ARRAY['https://laist.com/news/transportation/culver-city-eliminates-bus-and-bike-lanes']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- civil-rights = 1.0 (equity champion; reparations; first Black woman on council)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('1408cd55-dccb-40fa-9296-049af125ec6f', '0bc588c6-39e1-4084-b5de-cac909b8b762', 1.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('1408cd55-dccb-40fa-9296-049af125ec6f', '0bc588c6-39e1-4084-b5de-cac909b8b762',
$$The first Black woman elected to the Culver City Council, McMorrin campaigns explicitly as an "equity champion" and has supported the city's racial-equity agenda, including its reparations efforts, making civil rights and equity central to her record.$$,
ARRAY['https://culvercitycatalyst.co/yasmine-mcmorrin-im-running-to-be-your-equity-champion/','https://inthesetimes.com/article/culver-city-california-progressive-daniel-lee-policing-rent-control-corporate-power-reparations']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
