BEGIN;

-- =============================================================================
-- Migration 193: Fill missing compass_topic_roles for 5 national topics
-- =============================================================================
-- ai-regulation, immigration, deportation, healthcare, and taxes were added
-- without role-scope entries. All 5 are national-level policy topics that
-- apply across federal and state jurisdictions.
-- =============================================================================

INSERT INTO inform.compass_topic_roles (topic_id, role_scope, is_required)
SELECT t.id, s.role_scope, true
FROM inform.compass_topics t
CROSS JOIN (VALUES ('federal'), ('state')) AS s(role_scope)
WHERE t.topic_key IN ('ai-regulation', 'immigration', 'deportation', 'healthcare', 'taxes')
  AND t.is_live = true
ON CONFLICT (topic_id, role_scope) DO NOTHING;

COMMIT;
