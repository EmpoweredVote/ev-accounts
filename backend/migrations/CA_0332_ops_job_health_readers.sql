-- CA_0332 — read-only pg_cron / pg_net summaries for the job-health alarm.
-- Created 2026-10-26 with Chris Andrews. Steward slot CA_0332.
-- Source: ev-cto task 2026-09-14-cron-failure-alerting ("nothing tells anyone when a
-- scheduled job stops working"). The donor-name refresh failed 54 nights in a row
-- (2026-07-23 → 2026-09-14) and nothing read cron.job_run_details to notice.
--
-- WHY A SECURITY DEFINER FUNCTION
--   The job-health check runs inside the API process as `ev_api`, which has no USAGE on
--   the `cron` schema and must not get it: USAGE + SELECT on cron.job would also expose
--   each job's `command` text. These two functions return only what the alarm needs —
--   job name, schedule, run times, failure counts, the newest failure message, and
--   HTTP status codes — never `cron.job.command` and never a response body.
--
--   They live in a new `ops` schema that only `ev_api` can use. `ops` is not in
--   pgrst.db_schemas, and EXECUTE is revoked from PUBLIC, anon and authenticated, so the
--   weekly anon-execute sweep (treasury.run_anon_execute_sweep) has nothing to flag.
--
-- WHAT pg_net CAN AND CANNOT TELL US
--   A pg_cron job that calls net.http_post records 'succeeded' as soon as the request is
--   QUEUED. A 401 (rotated token) or a 5xx (API down) never reaches cron.job_run_details.
--   net._http_response holds the answer, but only for ~6 hours (pg_net's default TTL),
--   and it has no URL column. So ops.http_trigger_health() reports non-2xx responses in
--   whatever window is retained. A daily check sees ~6 hours of it — enough, because
--   ev-vq-consensus fires every 5 minutes: a broken token or a dead API shows there.
--
-- IDEMPOTENT: CREATE SCHEMA IF NOT EXISTS, CREATE OR REPLACE, REVOKE/GRANT are re-runnable.
-- REVERSAL: DROP SCHEMA ops CASCADE;

BEGIN;

CREATE SCHEMA IF NOT EXISTS ops;
REVOKE ALL ON SCHEMA ops FROM PUBLIC;
GRANT USAGE ON SCHEMA ops TO ev_api;

-- One row per pg_cron job: its schedule, newest run, and failures inside the window.
CREATE OR REPLACE FUNCTION ops.pg_cron_health(p_fail_window interval DEFAULT interval '24 hours')
RETURNS TABLE (
  jobid               bigint,
  jobname             text,
  schedule            text,
  active              boolean,
  last_start          timestamptz,
  fails               integer,
  first_fail_at       timestamptz,
  newest_fail_at      timestamptz,
  newest_fail_message text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT j.jobid,
         j.jobname::text,
         j.schedule::text,
         j.active,
         last_run.start_time,
         COALESCE(f.fails, 0)::integer,
         f.first_fail_at,
         f.newest_fail_at,
         left(f.newest_fail_message, 500)
  FROM cron.job j
  LEFT JOIN LATERAL (
    SELECT max(d.start_time) AS start_time
    FROM cron.job_run_details d
    WHERE d.jobid = j.jobid
  ) last_run ON true
  LEFT JOIN LATERAL (
    SELECT count(*) AS fails,
           min(d.start_time) AS first_fail_at,
           max(d.start_time) AS newest_fail_at,
           (array_agg(d.return_message ORDER BY d.start_time DESC))[1] AS newest_fail_message
    FROM cron.job_run_details d
    WHERE d.jobid = j.jobid
      AND d.status NOT IN ('succeeded', 'running', 'starting')
      AND d.start_time > now() - p_fail_window
  ) f ON true
  ORDER BY j.jobid;
$$;

-- Non-2xx (or errored / timed out) pg_net responses still retained. Status and error only.
CREATE OR REPLACE FUNCTION ops.http_trigger_health()
RETURNS TABLE (
  status_code   integer,
  timed_out     boolean,
  error_msg     text,
  responses     integer,
  first_seen    timestamptz,
  last_seen     timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT r.status_code,
         COALESCE(r.timed_out, false),
         left(r.error_msg, 200),
         count(*)::integer,
         min(r.created),
         max(r.created)
  FROM net._http_response r
  WHERE r.status_code IS NULL
     OR r.status_code NOT BETWEEN 200 AND 299
     OR r.timed_out
     OR r.error_msg IS NOT NULL
  GROUP BY 1, 2, 3
  ORDER BY 4 DESC;
$$;

REVOKE ALL ON FUNCTION ops.pg_cron_health(interval) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION ops.http_trigger_health()    FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION ops.pg_cron_health(interval) TO ev_api;
GRANT EXECUTE ON FUNCTION ops.http_trigger_health()    TO ev_api;

-- Post-verify gate: ev_api can call both; anon and authenticated cannot; ev_api still
-- cannot read cron.job directly (the whole point of going through a function).
DO $$
DECLARE
  v_jobs int;
BEGIN
  IF NOT has_function_privilege('ev_api', 'ops.pg_cron_health(interval)', 'EXECUTE')
     OR NOT has_function_privilege('ev_api', 'ops.http_trigger_health()', 'EXECUTE') THEN
    RAISE EXCEPTION 'CA_0332: ev_api cannot execute the ops health functions';
  END IF;
  IF has_function_privilege('anon', 'ops.pg_cron_health(interval)', 'EXECUTE')
     OR has_function_privilege('authenticated', 'ops.pg_cron_health(interval)', 'EXECUTE')
     OR has_function_privilege('anon', 'ops.http_trigger_health()', 'EXECUTE')
     OR has_function_privilege('authenticated', 'ops.http_trigger_health()', 'EXECUTE') THEN
    RAISE EXCEPTION 'CA_0332: anon/authenticated can execute an ops health function';
  END IF;
  IF has_schema_privilege('ev_api', 'cron', 'USAGE') THEN
    RAISE EXCEPTION 'CA_0332: ev_api has USAGE on cron — it should read only through ops';
  END IF;
  SELECT count(*) INTO v_jobs FROM ops.pg_cron_health();
  IF v_jobs <> (SELECT count(*) FROM cron.job) THEN
    RAISE EXCEPTION 'CA_0332: pg_cron_health returned % rows, cron.job has %',
      v_jobs, (SELECT count(*) FROM cron.job);
  END IF;
END $$;

COMMIT;
