-- 1346_rescope_local_lens_compass_questions.sql
-- Rescope the "local lens" compass topics away from hard "your city" framing so the
-- same 5-point scale reads correctly across levels of government. Surfaced by the
-- CA-governor Read & Rank question re-audit (read-rank#70, ev-accounts#82/#83).
--
-- Two registers, chosen from each topic's role_scope (inform.compass_topic_roles):
--   * local-only topics  -> "your community"  (covers city / county / town / township,
--                            still reads local; never reads federal)
--   * local + state topics -> "government"     (matches the already-neutral jail-capacity
--                            house style, which is itself local+state)
--   * judicial topic     -> "government"       (city attorney / county counsel / state AG)
--
-- Question wording only — no stance VALUES change, no topic VERSION bump, no is_live
-- change. inform.compass_responses is keyed by (user_id, topic_id, value), so existing
-- Compass answers stay attached and NO user is forced to re-take. Stance label TEXT is
-- likewise rescoped in place (same value ordinal, same semantics).
--
-- Idempotent: every statement sets a fixed final value and is safe to re-run.

BEGIN;

-- ============================================================================
-- Tier A: local-only topics -> "your community"
-- ============================================================================
UPDATE inform.compass_topics SET
  question_text = 'How should your community approach street cleanliness and sanitation?',
  updated_at = now()
WHERE topic_key = 'city-sanitation';

UPDATE inform.compass_topics SET
  question_text = 'What should be your community''s primary strategy for addressing homelessness?',
  updated_at = now()
WHERE topic_key = 'homelessness-response';

UPDATE inform.compass_topics SET
  question_text = 'How should your community balance new development with environmental preservation?',
  updated_at = now()
WHERE topic_key = 'local-environment';

-- police department -> law enforcement, so county sheriffs (the key local ICE-cooperation
-- actor) are included alongside city police departments.
UPDATE inform.compass_topics SET
  question_text = 'How should your community''s law enforcement relate to federal immigration enforcement?',
  updated_at = now()
WHERE topic_key = 'local-immigration';

UPDATE inform.compass_topics SET
  question_text = 'How should your community fund and operate public safety services?',
  updated_at = now()
WHERE topic_key = 'public-safety-approach';

UPDATE inform.compass_topics SET
  question_text = 'What should guide decisions about housing density and neighborhood character in your community?',
  updated_at = now()
WHERE topic_key = 'residential-zoning';

-- ============================================================================
-- Tier B: local + state topics -> "government" (matches jail-capacity house style)
-- ============================================================================
UPDATE inform.compass_topics SET
  question_text = 'How should government attract businesses and support economic development?',
  updated_at = now()
WHERE topic_key = 'economic-development';

UPDATE inform.compass_topics SET
  question_text = 'How should government manage population growth and new development?',
  updated_at = now()
WHERE topic_key = 'growth-and-development';

UPDATE inform.compass_topics SET
  question_text = 'What role should government play in regulating rents and protecting tenants?',
  updated_at = now()
WHERE topic_key = 'rent-regulation';

UPDATE inform.compass_topics SET
  question_text = 'Where should government focus its transportation investment?',
  updated_at = now()
WHERE topic_key = 'transportation-priorities';

-- ============================================================================
-- Judicial topic -> "government" (works for city attorney, county counsel, state AG)
-- ============================================================================
UPDATE inform.compass_topics SET
  question_text = 'When government employees do wrong, does the office defend them or hold them accountable?',
  updated_at = now()
WHERE topic_key = 'judicial-police-accountability';

-- ============================================================================
-- Stance ("chair label") text rescoping — literal city/municipal wording only.
-- Same value ordinal + same semantics; matched by topic_key + value.
-- ============================================================================

-- Tier A labels -> community / local / public
UPDATE inform.compass_stances s SET
  text = 'Increase sanitation crews and prioritize historically underserved neighborhoods to equalize cleanliness communitywide'
FROM inform.compass_topics t
WHERE s.topic_id = t.id AND t.topic_key = 'city-sanitation' AND s.value = 2;

UPDATE inform.compass_stances s SET
  text = 'Prioritize strict enforcement of trespassing and camping bans; minimize public spending on homeless services'
FROM inform.compass_topics t
WHERE s.topic_id = t.id AND t.topic_key = 'homelessness-response' AND s.value = 5;

UPDATE inform.compass_stances s SET
  text = 'Refuse all ICE detainers; prohibit local employees from sharing immigration status information with federal agencies'
FROM inform.compass_topics t
WHERE s.topic_id = t.id AND t.topic_key = 'local-immigration' AND s.value = 1;

UPDATE inform.compass_stances s SET
  text = 'Follow federal law as required but do not use local resources for proactive immigration enforcement'
FROM inform.compass_topics t
WHERE s.topic_id = t.id AND t.topic_key = 'local-immigration' AND s.value = 3;

UPDATE inform.compass_stances s SET
  text = 'Direct local police to actively assist with immigration enforcement and support federal detention operations'
FROM inform.compass_topics t
WHERE s.topic_id = t.id AND t.topic_key = 'local-immigration' AND s.value = 5;

UPDATE inform.compass_stances s SET
  text = 'Make expanding the police budget the top spending priority over other services'
FROM inform.compass_topics t
WHERE s.topic_id = t.id AND t.topic_key = 'public-safety-approach' AND s.value = 5;

UPDATE inform.compass_stances s SET
  text = 'Eliminate single-family-only zoning; allow any housing type on any lot communitywide'
FROM inform.compass_topics t
WHERE s.topic_id = t.id AND t.topic_key = 'residential-zoning' AND s.value = 5;

-- Tier B labels -> drop the "city" qualifier (topic stem is now "government")
UPDATE inform.compass_stances s SET
  text = 'Offer maximum incentives to attract any large employer; economic growth is the top priority'
FROM inform.compass_topics t
WHERE s.topic_id = t.id AND t.topic_key = 'economic-development' AND s.value = 5;

UPDATE inform.compass_stances s SET
  text = 'Streamline permitting, reduce fees, and actively recruit development to grow the tax base'
FROM inform.compass_topics t
WHERE s.topic_id = t.id AND t.topic_key = 'growth-and-development' AND s.value = 4;

UPDATE inform.compass_stances s SET
  text = 'Prioritize pedestrian infrastructure, cycling networks, and public transit; reduce parking requirements communitywide'
FROM inform.compass_topics t
WHERE s.topic_id = t.id AND t.topic_key = 'transportation-priorities' AND s.value = 1;

-- Judicial labels -> "government" (the office's client is the government it represents)
UPDATE inform.compass_stances s SET
  text = 'Represent the government fairly while acknowledging when claims have merit.'
FROM inform.compass_topics t
WHERE s.topic_id = t.id AND t.topic_key = 'judicial-police-accountability' AND s.value = 3;

UPDATE inform.compass_stances s SET
  text = 'Defend government employees vigorously. That''s the job. Settlements invite more lawsuits.'
FROM inform.compass_topics t
WHERE s.topic_id = t.id AND t.topic_key = 'judicial-police-accountability' AND s.value = 4;

UPDATE inform.compass_stances s SET
  text = 'The client is the government. Defending its employees and decisions — aggressively when needed — is the core function.'
FROM inform.compass_topics t
WHERE s.topic_id = t.id AND t.topic_key = 'judicial-police-accountability' AND s.value = 5;

COMMIT;
