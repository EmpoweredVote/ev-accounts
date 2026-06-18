-- Migration 732: Dan O'Brien (Culver City Council) Stances
-- Phase 130 — Culver City. Dan O'Brien, external_id -700553, UUID a2e727ea-2115-455c-a623-5b69a7336224.
-- Council Member (rotational; has served as Mayor/Vice Mayor). Business-aligned moderate.
-- Topic UUIDs: transportation-priorities=ba59337e-30e2-4aba-a39a-426b3366eb27  public-safety-approach=e9ebefcd-c496-45e8-b816-a79f8442ba85
-- residential-zoning=d4f18138-a2e0-4110-b925-7387d9d0d16d  housing=669cac97-66a6-4087-b036-936fbe62efb3
-- homelessness-response=6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f  local-environment=1935979c-b290-42e4-baa5-8cb0138b4ffa

BEGIN;

-- transportation-priorities = 3.0 (scaled back MOVE as "middle ground"; supports some bike/ped + car access)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a2e727ea-2115-455c-a623-5b69a7336224', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a2e727ea-2115-455c-a623-5b69a7336224', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Council Member O'Brien was part of the 3-2 majority that scaled back MOVE Culver City's protected bike lanes to restore a car lane, calling the modified design a "middle ground" aligned with downtown businesses seeking better car access. He nonetheless supports targeted active-transportation projects such as the Overland Avenue bike lane and more walkable, accessible sidewalks — a balanced, car-and-bike approach.$$,
ARRAY['https://laist.com/news/transportation/culver-city-eliminates-bus-and-bike-lanes','https://www.danobrien4culvercity.com/priorities/']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- public-safety-approach = 4.0 (maintain PD staffing, resources to stop violent crime; with accountability)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a2e727ea-2115-455c-a623-5b69a7336224', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a2e727ea-2115-455c-a623-5b69a7336224', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$O'Brien pledges to keep the police department at normal staffing levels and to budget the resources needed to stop violent crime — an enforcement-supportive posture (in contrast to the council's defunding advocates) — while also calling for law enforcement to be accountable, equitable, and transparent with the community.$$,
ARRAY['https://www.danobrien4culvercity.com/priorities/']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- residential-zoning = 4.0 (preserve R1; oppose dismantling single-family neighborhoods)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a2e727ea-2115-455c-a623-5b69a7336224', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a2e727ea-2115-455c-a623-5b69a7336224', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$O'Brien argues that rather than "dismantling R1 neighborhoods," housing growth should be directed to large-scale developments on appropriately zoned land — a position favoring preservation of single-family residential zoning over broad upzoning.$$,
ARRAY['https://www.danobrien4culvercity.com/priorities/']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing = 3.0 (supports affordable housing via large developments, not broad upzoning)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a2e727ea-2115-455c-a623-5b69a7336224', '669cac97-66a6-4087-b036-936fbe62efb3', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a2e727ea-2115-455c-a623-5b69a7336224', '669cac97-66a6-4087-b036-936fbe62efb3',
$$O'Brien acknowledges rising rents are leaving Culver City families housing-insecure and supports affordable housing, but channels new supply toward large-scale developments on suitable land rather than broad neighborhood upzoning — a moderate housing position.$$,
ARRAY['https://www.danobrien4culvercity.com/priorities/']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- homelessness-response = 3.0 (stated "balanced approach")
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a2e727ea-2115-455c-a623-5b69a7336224', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a2e727ea-2115-455c-a623-5b69a7336224', '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
$$O'Brien lists a "balanced approach to addressing the homelessness crisis" among his top priorities, positioning himself between pure services and pure enforcement.$$,
ARRAY['https://www.danobrien4culvercity.com/priorities/']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- local-environment = 2.0 (greener Ballona Creek, expanded green/pedestrian space)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('a2e727ea-2115-455c-a623-5b69a7336224', '1935979c-b290-42e4-baa5-8cb0138b4ffa', 2.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('a2e727ea-2115-455c-a623-5b69a7336224', '1935979c-b290-42e4-baa5-8cb0138b4ffa',
$$O'Brien advocates a greener Ballona Creek with expanded green space, bike lanes, and pedestrian areas, prioritizing local environmental and open-space improvements.$$,
ARRAY['https://www.danobrien4culvercity.com/priorities/']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
