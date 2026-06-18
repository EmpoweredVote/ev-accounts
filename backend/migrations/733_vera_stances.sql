-- Migration 733: Albert Vera (Culver City Council) Stances
-- Phase 130 — Culver City. Albert Vera, external_id -700554, UUID 435a4b18-6db9-451f-9379-a62898337825.
-- Council Member (rotational; former Mayor). Sorrento Italian Market owner; business-aligned fiscal conservative.
-- Topic UUIDs: rent-regulation=c308e8e8-caac-44f5-ab04-dbfecf40bbe2  public-safety-approach=e9ebefcd-c496-45e8-b816-a79f8442ba85
-- residential-zoning=d4f18138-a2e0-4110-b925-7387d9d0d16d  housing=669cac97-66a6-4087-b036-936fbe62efb3
-- transportation-priorities=ba59337e-30e2-4aba-a39a-426b3366eb27

BEGIN;

-- rent-regulation = 5.0 (opposed rent control; backed Measure B repeal; against registration fees)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('435a4b18-6db9-451f-9379-a62898337825', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2', 5.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('435a4b18-6db9-451f-9379-a62898337825', 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
$$Council Member Vera opposed Culver City establishing rent control and tenant protections, supported Measure B which would have repealed rent control, and voted against the rental-registration fees that fund enforcement of rent control — a consistently anti-rent-regulation record.$$,
ARRAY['https://www.c-c-d-c.com/property-and-privilege/','https://www.ourculver.org/blog/2024-voter-guide']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- public-safety-approach = 4.0 (well-resourced law enforcement)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('435a4b18-6db9-451f-9379-a62898337825', 'e9ebefcd-c496-45e8-b816-a79f8442ba85', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('435a4b18-6db9-451f-9379-a62898337825', 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
$$Vera is a strong public-safety supporter who argues well-resourced law enforcement is crucial to keeping Culver City safe and prosperous for residents and businesses — an enforcement-supportive posture opposite the council's police-defunding advocates.$$,
ARRAY['https://patch.com/california/culvercity/meet-albert-vera-candidate-city-council-culver-city']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- residential-zoning = 4.0 (ended Incremental Infill; preserve neighborhood quality)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('435a4b18-6db9-451f-9379-a62898337825', 'd4f18138-a2e0-4110-b925-7387d9d0d16d', 4.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('435a4b18-6db9-451f-9379-a62898337825', 'd4f18138-a2e0-4110-b925-7387d9d0d16d',
$$Vera's council majority ended Culver City's "Incremental Infill" program, framing the move as preserving the quality of existing neighborhoods while still meeting housing goals — a position favoring preservation of lower-density residential zoning over infill upzoning.$$,
ARRAY['https://www.ourculver.org/blog/2024-voter-guide']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- housing = 3.0 (attainable housing for working professionals; preservation-oriented)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('435a4b18-6db9-451f-9379-a62898337825', '669cac97-66a6-4087-b036-936fbe62efb3', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('435a4b18-6db9-451f-9379-a62898337825', '669cac97-66a6-4087-b036-936fbe62efb3',
$$Vera supports "attainable housing for working professionals" and meeting housing goals, but pairs it with neighborhood-preservation priorities and ending incremental infill — a moderate housing position balancing some new supply against neighborhood character.$$,
ARRAY['https://patch.com/california/culvercity/meet-albert-vera-candidate-city-council-culver-city']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

-- transportation-priorities = 3.0 (scaled back MOVE for business/traffic; kept combined bus/bike lane + extension)
INSERT INTO inform.politician_answers (politician_id, topic_id, value)
VALUES ('435a4b18-6db9-451f-9379-a62898337825', 'ba59337e-30e2-4aba-a39a-426b3366eb27', 3.0)
ON CONFLICT (politician_id, topic_id) DO UPDATE SET value = EXCLUDED.value;
INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
VALUES ('435a4b18-6db9-451f-9379-a62898337825', 'ba59337e-30e2-4aba-a39a-426b3366eb27',
$$Vera joined the majority to modify MOVE Culver City — restoring a vehicle lane and citing traffic and downtown-business impacts — but the revision kept a combined bus/bike lane and extended the corridor to Fairfax, a business-conscious but still partly multimodal middle-ground position.$$,
ARRAY['https://laist.com/news/transportation/culver-city-eliminates-bus-and-bike-lanes','https://www.culvercityobserver.com/story/2024/01/25/news/city-council-awards-construction-contract-for-move-culver-city-modifications-sidewalk-business-fees-municipal-code-revisions/13236.html']::text[]::text[])
ON CONFLICT (politician_id, topic_id) DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources;

COMMIT;
