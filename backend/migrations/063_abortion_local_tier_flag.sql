BEGIN;

-- =============================================================================
-- Migration 063: Add Local tier flag to abortion topic
-- =============================================================================
-- inform.compass_topic_roles was already mostly populated (presumably during
-- Plan A execution or earlier manual work), and 25/26 live topics match the
-- decisions in the 2026-04-11 compass topic audit
-- (docs/superpowers/audits/2026-04-11-compass-topic-audit.md).
--
-- The one exception: abortion was flagged F+S only. The audit upgraded it to
-- F+S+L because local DAs genuinely have prosecutorial discretion post-Dobbs
-- on whether to prosecute abortion-related cases. This migration adds the
-- missing (abortion, local) row.
--
-- Idempotent — ON CONFLICT DO NOTHING means re-running has no effect.
-- =============================================================================

INSERT INTO inform.compass_topic_roles (topic_id, role_scope, is_required)
SELECT t.id, 'local', true
FROM inform.compass_topics t
WHERE t.topic_key = 'abortion' AND t.is_live = true
ON CONFLICT (topic_id, role_scope) DO NOTHING;

COMMIT;
