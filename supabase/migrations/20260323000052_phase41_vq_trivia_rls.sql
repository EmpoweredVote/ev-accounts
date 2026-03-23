-- Phase 41: RLS policies for validation_quests and trivia schemas
-- Pattern: Phase 34 (20260319000044_phase34_essentials_rls.sql)
-- Tables: 13 validation_quests + 9 trivia = 22 total
-- Categories: 11 owner-read, 9 public-read, 2 service_role-only
--
-- PRE-FLIGHT FINDING: All 22 tables already have RLS enabled and most
-- policies already exist from the original VQ/trivia schema migrations.
-- This migration adds the 3 missing policies and grants anon access
-- to the 2 public-read tables that were authenticated-only.
--
-- USER_ID COLUMN TYPE: All 11 owner-read tables confirmed uuid (no cast needed).
-- Pattern: (SELECT auth.uid()) = user_id

BEGIN;

-- ============================================================
-- SECTION 1: ENABLE ROW LEVEL SECURITY (idempotent — already enabled)
-- Listed for documentation completeness; ALTER TABLE ... ENABLE ROW LEVEL
-- SECURITY is safe to run if already enabled (no error).
-- ============================================================

-- validation_quests (13 tables)
ALTER TABLE validation_quests.gem_reward_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE validation_quests.quest_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE validation_quests.user_notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE validation_quests.user_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE validation_quests.user_quest_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE validation_quests.user_veracity_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE validation_quests.veracity_event_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE validation_quests.verification_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE validation_quests.consensus_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE validation_quests.quest_contests ENABLE ROW LEVEL SECURITY;
ALTER TABLE validation_quests.verification_quests ENABLE ROW LEVEL SECURITY;
ALTER TABLE validation_quests.admin_override_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE validation_quests.ai_agent_credentials ENABLE ROW LEVEL SECURITY;

-- trivia (9 tables)
ALTER TABLE trivia.collection_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE trivia.collection_topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE trivia.collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE trivia.election_races ENABLE ROW LEVEL SECURITY;
ALTER TABLE trivia.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE trivia.topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE trivia.player_prefs ENABLE ROW LEVEL SECURITY;
ALTER TABLE trivia.player_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE trivia.question_flags ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- SECTION 2: ADD MISSING POLICIES
--
-- Pre-flight found 3 validation_quests tables with no policies at all:
--   gem_reward_events, user_quest_assignments (owner-read missing)
--   quest_contests (public-read missing)
-- ============================================================

-- gem_reward_events: owner SELECT (was entirely missing)
CREATE POLICY "gem_reward_events: owner select"
  ON validation_quests.gem_reward_events FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- user_quest_assignments: owner SELECT (was entirely missing)
CREATE POLICY "user_quest_assignments: owner select"
  ON validation_quests.user_quest_assignments FOR SELECT TO authenticated
  USING ((SELECT auth.uid()) = user_id);

-- quest_contests: public read (was entirely missing)
CREATE POLICY "quest_contests: public read"
  ON validation_quests.quest_contests FOR SELECT TO anon, authenticated
  USING (true);

-- ============================================================
-- SECTION 3: FIX SCOPE — ADD ANON ACCESS TO PUBLIC-READ TABLES
--
-- consensus_records: existing policy is authenticated-only.
--   Plan category: public-read. Add anon SELECT policy.
--
-- verification_quests: existing policy is authenticated-only + status filter.
--   Plan category: public-read quest catalog. Add anon SELECT for active quests.
-- ============================================================

-- consensus_records: add anon access (authenticated policy already exists)
CREATE POLICY "consensus_records: anon read"
  ON validation_quests.consensus_records FOR SELECT TO anon
  USING (true);

-- verification_quests: add anon access for active quests (authenticated policy already exists)
CREATE POLICY "verification_quests: anon read active"
  ON validation_quests.verification_quests FOR SELECT TO anon
  USING (status = 'active'::validation_quests.quest_status);

-- ============================================================
-- SECTION 4: SCHEMA GRANTS
-- Grant USAGE + SELECT to anon and authenticated for both schemas.
-- Mirrors Phase 34 pattern for essentials/staging.
-- ALTER DEFAULT PRIVILEGES covers future tables.
-- ============================================================

-- validation_quests
GRANT USAGE ON SCHEMA validation_quests TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA validation_quests TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA validation_quests GRANT SELECT ON TABLES TO anon, authenticated;

-- trivia
GRANT USAGE ON SCHEMA trivia TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA trivia TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA trivia GRANT SELECT ON TABLES TO anon, authenticated;

-- service_role explicit grants (bypasses RLS but explicit grant needed for PostgREST visibility)
GRANT USAGE ON SCHEMA validation_quests TO service_role;
GRANT ALL ON ALL TABLES IN SCHEMA validation_quests TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA validation_quests GRANT ALL ON TABLES TO service_role;

GRANT USAGE ON SCHEMA trivia TO service_role;
GRANT ALL ON ALL TABLES IN SCHEMA trivia TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA trivia GRANT ALL ON TABLES TO service_role;

COMMIT;
