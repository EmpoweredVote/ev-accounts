BEGIN;

-- =============================================================================
-- Migration 024: Phase 7 admin schema
-- =============================================================================
-- New tables:  public.admin_users, public.notifications,
--              public.calibration_lapse_runs
-- ALTERs:      public.admin_audit_log (add target_user_id + details columns
--              so Phase 7 adminService.logAdminAction can use consistent names)
-- RPC replace: public.get_calibration_lapsed_users (went_live_at-aware version)
--
-- NOTE: public.admin_audit_log was scaffolded in migration 003 with columns:
--   target_id (nullable UUID) and metadata (JSONB).
--   Phase 7 adds target_user_id (FK to users) and details (JSONB NOT NULL)
--   as the canonical columns used by adminService.ts.
--   Both old columns are retained for backward compatibility.
-- =============================================================================


-- =============================================================================
-- 1. public.admin_users
-- Simple allowlist — rows inserted manually for Alpha via migration.
-- No user-facing RLS policies (default deny for non-service-role).
-- RLS is enabled so the table is not accessible without service role.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.admin_users (
  user_id    UUID        PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
-- No policies: admin_users is accessible only via service role (supabaseAdmin)


-- =============================================================================
-- 2. public.admin_audit_log — add Phase 7 canonical columns
-- Migration 003 created this table with target_id and metadata.
-- Phase 7 adminService.ts uses target_user_id (typed FK) and details (JSONB NOT NULL).
-- We ADD these columns; the old columns remain for historical records.
-- =============================================================================

ALTER TABLE public.admin_audit_log
  ADD COLUMN IF NOT EXISTS target_user_id UUID REFERENCES public.users(id);

ALTER TABLE public.admin_audit_log
  ADD COLUMN IF NOT EXISTS details JSONB NOT NULL DEFAULT '{}';

-- Supplemental indexes for Phase 7 access patterns
CREATE INDEX IF NOT EXISTS idx_audit_log_actor
  ON public.admin_audit_log(actor_id);

CREATE INDEX IF NOT EXISTS idx_audit_log_target
  ON public.admin_audit_log(target_user_id);

CREATE INDEX IF NOT EXISTS idx_audit_log_created
  ON public.admin_audit_log(created_at DESC);


-- =============================================================================
-- 3. public.notifications
-- Reusable notification table for all future event types.
-- SELECT policy: authenticated users can read their own notifications.
-- Writes are service-layer only (no INSERT/UPDATE/DELETE policies for users).
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.notifications (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type       TEXT        NOT NULL,
  payload    JSONB       NOT NULL DEFAULT '{}',
  read_at    TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
  ON public.notifications(user_id, created_at DESC)
  WHERE read_at IS NULL;

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notifications: owner select"
  ON public.notifications
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = user_id);


-- =============================================================================
-- 4. public.calibration_lapse_runs
-- Idempotency table for the daily calibration cron job.
-- run_date DATE PRIMARY KEY: one row per calendar day — ON CONFLICT DO NOTHING
-- is the idempotency check (CRON-04).
-- No user-facing policies: admin-only via service role.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.calibration_lapse_runs (
  run_date         DATE        PRIMARY KEY,
  started_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at      TIMESTAMPTZ,
  users_warned_25  INTEGER     NOT NULL DEFAULT 0,
  users_warned_30  INTEGER     NOT NULL DEFAULT 0,
  users_demoted    INTEGER     NOT NULL DEFAULT 0,
  error_message    TEXT
);

ALTER TABLE public.calibration_lapse_runs ENABLE ROW LEVEL SECURITY;
-- No policies: calibration_lapse_runs accessible only via service role


-- =============================================================================
-- 5. Replace public.get_calibration_lapsed_users RPC
-- Phase 4 version had no went_live_at awareness — it returned any Empowered
-- user missing any live topic, regardless of when the topic went live.
-- Phase 7 replaces with a timestamp-aware version using p_days_threshold.
-- The cron calls this with thresholds 25, 30, and 31.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.get_calibration_lapsed_users(
  p_days_threshold INTEGER DEFAULT 30
)
RETURNS TABLE (
  user_id          UUID,
  overdue_topic_ids UUID[],
  days_overdue     INTEGER
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT
    ep.user_id,
    array_agg(ct.id)                                            AS overdue_topic_ids,
    (CURRENT_DATE - MIN(ct.went_live_at)::date)::integer        AS days_overdue
  FROM empower.empowered_profiles ep
  JOIN inform.compass_topics ct
    ON ct.is_live = true
   AND ct.went_live_at IS NOT NULL
   AND ct.went_live_at <= now() - (p_days_threshold || ' days')::interval
  WHERE ep.is_active = true
    AND NOT EXISTS (
      SELECT 1 FROM inform.compass_responses cr
      WHERE cr.user_id = ep.user_id
        AND cr.topic_id = ct.id
    )
  GROUP BY ep.user_id;
$$;

-- Grant execute on the replacement RPC to service_role and authenticated
GRANT EXECUTE ON FUNCTION public.get_calibration_lapsed_users(INTEGER)
  TO service_role, authenticated;


-- =============================================================================
-- 6. Grant permissions on new tables
-- =============================================================================

-- admin_users: service_role only (no grants to authenticated)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.admin_users TO service_role;

-- admin_audit_log: service_role can write; no authenticated grants (RLS covers nothing)
GRANT SELECT, INSERT ON public.admin_audit_log TO service_role;

-- notifications: service_role can write; authenticated can SELECT (RLS owner policy above)
GRANT SELECT, INSERT, UPDATE ON public.notifications TO service_role;
GRANT SELECT ON public.notifications TO authenticated;

-- calibration_lapse_runs: service_role only
GRANT SELECT, INSERT, UPDATE ON public.calibration_lapse_runs TO service_role;

COMMIT;
