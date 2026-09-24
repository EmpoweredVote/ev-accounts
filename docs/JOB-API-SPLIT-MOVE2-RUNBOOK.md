# Job / API split — Move 2 runbook (AS BUILT)

**Status: ✅ EXECUTED 2026-09-12 ~15:51 UTC. `EV_ROLE=api` is live on `ev-accounts-api`.**

This is the as-built record of Move 2. It documents what was actually done, the gotchas hit on
the way, the live configuration, and the items still owed. Companion to
[`docs/JOB-API-SPLIT.md`](JOB-API-SPLIT.md) (design + job-health manifest) and ev-accounts issue
#476 (checklist). Move 1 (PR #473) shipped `EV_ROLE` + the per-job runner with `EV_ROLE` unset.
The planning version of this runbook is in git history (PR #477).

## Decisions (settled 2026-09-12, Chris Andrews) — all held

1. **FEC burst → Render cron** (`standard` plan). Steady state fits the 12-hour cap. Watch the
   next quarterly FEC deadline (**2026-10-15**); if a day exceeds 12h, move only `fec-burst` to
   Render Workflows / Cloud Run Jobs. Keep `FEC_BACKFILL_AUTORESUME` (default off) out of it.
2. **SQS drain → no worker, $0.** Live AWS check (account 361769553908) found no queue, worker
   Lambda, event-source mapping, or EventBridge feed, and the backend has no enqueue code. The
   drain was never deployed and is not fed. The in-process loop stopped at the flip (drained
   nothing). Deleting the loop from code is a later optional cleanup.
3. **Reaper → its own Supabase Cron job** (`ev-reap-stale-ingestion-runs`), independent of FEC.
4. **Light/frequent jobs → Supabase Cron → a new HTTP route.** pg_cron cannot exec a Node CLI,
   so PR #477 added `POST /internal/jobs/:name` (X-Admin-Token). This corrected the "no code
   change" assumption in #476.
5. **Execution → Render MCP + Supabase MCP** (the founder authorized the Render connector). The
   Render CLI could not create services; the dashboard was used only to make the env group and
   the Vault secret.

**Cost added ≈ $4/month** (3 heavy + 2 LLM Render crons; only FEC has real compute; Supabase Cron
$0; no worker). Confirm against the real Render invoice after a full cycle (ev-cto watchlist #63).
`ev-jobs-cal-access` (added 2026-09-23) adds ≈ $1.50/month: `pro` at $0.00197/min × ~25 min on a day
the SOS export changed; a 304 day costs about one minute. $1/month minimum per cron.

## The HTTP job-trigger route (PR #477 — merged, deployed)

`POST /internal/jobs/:name`, header `X-Admin-Token: <ADMIN_INGEST_TOKEN>`
(`backend/src/routes/internalJobs.ts`, reuses `requireAdminToken`). Runs the same registry job the
CLI runner and the in-process cron call; fire-and-forget (202, 409 if the same job is already in
flight), mounted on the request path so it is served under `EV_ROLE=api`. Merged as squash
`0c5c3bc8`. Live check: `POST /internal/jobs/x` → **401** (route mounted, token required).

## What was built — Render crons (5), via the Render MCP `create_cron_job`

All: runtime `node`, repo `EmpoweredVote/ev-accounts@master`, region `oregon`, env group
`ev-jobs-shared`, build `cd backend && npm install && npx tsc`.

| Cron | Service ID | Schedule (UTC) | Plan | Start command |
|---|---|---|---|---|
| `ev-jobs-fec-burst` | `crn-dain5h5g1s2s7380ujj0` | `0 6 * * *` | standard | `cd backend && node --dns-result-order=verbatim dist/jobs/run.js fec-burst` |
| `ev-jobs-la-county-netfile` | `crn-dain5k9594qs739emeg0` | `0 3 1 * *` | starter | `… dist/jobs/run.js la-county-netfile` |
| `ev-jobs-ocpf` | `crn-dain6h1594qs739epesg` | `0 4 1 * *` | starter | `… dist/jobs/run.js ocpf` |
| `ev-jobs-trivia-pipeline` | `crn-dain8nuk1f9s738t6gs0` | `0 7 * * *` | starter | `… dist/jobs/run.js trivia-pipeline` |
| `ev-jobs-trivia-election-detection` | `crn-dain6d1594qs739ep150` | `0 11 * * *` | starter | `… dist/jobs/run.js trivia-election-detection` |
| `ev-jobs-cal-access` | `crn-daq44qo473hc73cia100` | `0 16 * * *` | pro (2c-4g) | `… dist/jobs/run.js cal-access` — added 2026-09-23 (PR #659); ~1.9 GB peak, so not `standard` |

**Gotchas hit (why these differ from the plan):**
- `create_cron_job` has **no root-directory parameter**, so `cd backend &&` is baked into the
  build and start commands. Their Render **Root Directory must stay EMPTY** — setting it to
  `backend` would double the `cd` and break them.
- `create_cron_job` **cannot link an env group**, so env was not passed inline. The env group
  `ev-jobs-shared` (copied from `ev-accounts-api`, so it carries the full required set —
  `SUPABASE_*`, `READRANK_TOKEN_SECRET`, `DATABASE_URL`, `ADMIN_INGEST_TOKEN`, `FEC_API_KEY`,
  `ANTHROPIC_API_KEY`) was created and linked **in the dashboard** after creation. A home missing
  any required var crash-loops at import — the env group is what prevents that.
- Created with `notifyOnFail: default` — the MCP cannot set failure notifications. **OWED:** turn
  them on per cron in the dashboard (the ev-cto safety net).
- 🔴 **Build gotcha (found + fixed 2026-09-12): the env group carries `NODE_ENV=production`, which
  Render also applies at BUILD, so `npm install` omits devDependencies and `npx tsc` fails**
  (`Cannot find module 'vitest'`, `@types/express`, `aws-lambda`, …). The first build worked only
  because it ran *before* the env group was linked; every auto-deploy after linking `build_failed`
  (the cron kept running its first good image, but new code could not deploy). **Fix applied:**
  set `NPM_CONFIG_INCLUDE=dev` on each cron (service-level env), which forces devDeps in even
  under `NODE_ENV=production`; one clear-cache rebuild repopulates the cache with devDeps, then
  normal cached builds pass. Longer-term alternatives: put `NPM_CONFIG_INCLUDE=dev` in the env
  group itself (one place), change the build to `npm ci --include=dev && npx tsc`, or exclude
  `*.test.ts` from the build tsconfig.
- The DST note stands: Render cron is UTC-only, so the two trivia jobs (originally ET) run at
  `0 7` / `0 11` UTC and drift one hour across US daylight time. Harmless.
- `trivia-pipeline` and `trivia-election-detection` run as **Render crons** (LLM spend, kept off
  the login API), not via the HTTP route.

## What was built — Supabase Cron jobs (6), via the Supabase MCP `execute_sql`

Each calls the live route through `pg_net`, reading the token from **Supabase Vault** (secret
`admin_ingest_token`) so the token never sits in plaintext in `cron.job`.

| Supabase Cron job | route `:name` | Schedule (UTC) |
|---|---|---|
| `ev-vq-consensus` | `vq-consensus` | `*/5 * * * *` |
| `ev-trivia-expiration` | `trivia-expiration` | `0 * * * *` |
| `ev-calibration-lapse` | `calibration-lapse` | `0 2 * * *` |
| `ev-vq-rotation` | `vq-rotation` | `0 4 * * *` |
| `ev-reap-stale-ingestion-runs` | `reap-stale-ingestion-runs` | `30 5 * * *` |
| `ev-district-staleness` | `district-staleness` | `0 3 * * 0` |

**Gotcha hit — enabling/disabling:** the Supabase MCP role can call the SECURITY DEFINER functions
`cron.schedule` / `cron.alter_job` but **cannot `UPDATE cron.job` directly** (permission denied).
So the "create paused" pattern was `cron.alter_job(cron.schedule(name, sched, cmd), active := false)`
in a single statement (atomic — nothing fired before the cutover), and enabling was:

```sql
select cron.alter_job(jobid, active := true)  from cron.job where jobname like 'ev-%';   -- enable
select cron.alter_job(jobid, active := false) from cron.job where jobname like 'ev-%';   -- disable (rollback)
```

Extensions `pg_cron` (1.6) and `pg_net` (0.20.0) were already enabled — no change needed. The
per-job command shape actually used:

```sql
select net.http_post(
  url     := 'https://accounts-api.empowered.vote/internal/jobs/<name>',
  body    := '{}'::jsonb,
  headers := jsonb_build_object('Content-Type','application/json','X-Admin-Token',
             (select decrypted_secret from vault.decrypted_secrets where name = 'admin_ingest_token')),
  timeout_milliseconds := 5000
);
```

## The cutover (done)

1. `EV_ROLE=api` set on `ev-accounts-api` (`srv-d6h1pahr0fns739kfjfg`) via the Render MCP
   `update_environment_variables` (merge — one var). Render auto-redeployed (`dep-dain9mh594qs739f4vd0`).
2. Verified: the new instance logged
   `[server] EV_ROLE=api — serving requests only; no crons, no SQS worker, no boot recovery` +
   `[server] listening on port 10000`, with **zero** `[cron] registered`, SQS-worker, or
   boot-recovery lines (only the request-path inits: campaign-finance schema check, trivia Redis,
   PostgreSQL connected). `/api/health` → 200.
3. Enabled the 6 Supabase Cron jobs (`cron.alter_job … active := true`).
4. End-to-end proof:
   - Manual `pg_net` fire of `reap-stale-ingestion-runs` → route returned **202**
     `{"status":"started"}`; API log `[internal-jobs] running … completed in 341ms`.
   - Scheduled `ev-vq-consensus` fired at **15:55:00** → `cron.job_run_details` = **succeeded**,
     API log `[internal-jobs] running "vq-consensus"`. pg_cron → pg_net → route → job confirmed.

## Monitoring — daily health check

A **local scheduled task** `move2-cron-health-check` runs **daily at 08:07 America/Indianapolis**
and reports to the owning session in Simplified Technical English. It is a *local* task, not a
cloud routine: cloud routines cannot use the Supabase/Render MCP connectors, and every job's
"proof it ran" signal lives in the Supabase database, so the check queries the DB directly (it
covers the Render crons too). It runs while the desktop app is open (or on next launch). Plan to
stop it after ~2 weeks, once the jobs prove stable.

### Proof-of-run queries (corrected — trivia tables are in the `trivia` schema)

```sql
-- Supabase Cron jobs: last run + status
select j.jobname, j.active, d.status, d.start_time, left(coalesce(d.return_message,''),80) msg
from cron.job j
left join lateral (select * from cron.job_run_details r where r.jobid=j.jobid order by r.start_time desc limit 1) d on true
where j.jobname like 'ev-%' order by j.jobname;

-- fec-burst (daily 06:00 UTC): completed run in the last ~24h
select adapter_name, status, completed_at from transparent_motivations.ingestion_runs where adapter_name='fec' order by started_at desc limit 1;
-- stale-run guard: 'running' must not keep growing
select status, count(*) from transparent_motivations.ingestion_runs group by status;
-- la-county-netfile / ocpf (monthly, 1st) — do NOT flag stale on other days
select adapter_name, max(completed_at) from transparent_motivations.ingestion_runs where adapter_name in ('la_county_netfile','ocpf') group by adapter_name;
-- calibration-lapse (daily)
select max(run_date) from calibration_lapse_runs;
-- district-staleness (weekly Sun)
select max(districts_last_verified_at) from connect.connected_profiles;
-- vq-rotation (daily)
select max(expires_at) from validation_quests.user_quest_assignments;
-- trivia-expiration (hourly)
select status, count(*) from trivia.questions group by status;
-- trivia-election-detection (daily; no write when 0 races — absence is not a failure)
select count(*) from trivia.election_races where questions_generated = true;
-- trivia-pipeline (daily)
select id, status, created_at from trivia.generation_jobs order by created_at desc limit 3;
```

Trigger any Supabase-Cron job on demand (bypasses the schedule; uses the same Vault token):

```sql
select net.http_post(
  url := 'https://accounts-api.empowered.vote/internal/jobs/<name>',
  body := '{}'::jsonb,
  headers := jsonb_build_object('Content-Type','application/json','X-Admin-Token',
             (select decrypted_secret from vault.decrypted_secrets where name='admin_ingest_token')),
  timeout_milliseconds := 8000);
-- then: select id, status_code, content::text from net._http_response order by id desc limit 1;  -- expect 202
```

## Rollback (one variable)

Set `ev-accounts-api` `EV_ROLE` back to unset (delete the var) and redeploy → the API resumes
running everything in-process exactly as before. Disable the Supabase jobs
(`select cron.alter_job(jobid, active := false) from cron.job where jobname like 'ev-%';`) and
suspend the Render crons. The default path is preserved precisely to keep this a single-variable
revert.

## Still owed (owner: Chris)

- [ ] **Turn on failure notifications** for the 5 Render crons (created `notifyOnFail=default`; the
  MCP can't set it). ev-cto task step 2 — the safety net.
- [ ] Verify each **Render cron** at its first real run (fec + trivia tomorrow; Netfile/OCPF Oct 1)
  via the proof queries — or a manual "Run" in the dashboard.
- [ ] Read the real Render invoice after a full cycle; confirm ~$4/month (ev-cto watchlist #63).
- [ ] **`ev-jobs-cal-access`: link env group `ev-jobs-shared` in the dashboard** (the MCP cannot link
  one). Without it the run exits at `env.ts` import. Then check its first run (16:00 UTC): one
  `ingestion_runs` row per confirmed link, or `data_source_metadata.cal_access_zip_etag`
  `last_sync_status='not_modified'` on a 304 day.
- [ ] Optional: one self-alerting Supabase Cron **health job** that runs the proofs and alerts if
  any signal is stale — a laptop-independent alternative to the local daily task.
- [ ] Before a **second** API copy: clear the "blocks two copies" list in `docs/JOB-API-SPLIT.md`
  (Upstash for the 5 rate limiters + `cache.ts`; shared Redis lock for discovery `lockHeld` and
  ingestion `inProcessLocks`).

## Gotchas worth keeping (for next time)

- **Render CLI v2.26.0 cannot create services or read env vars** — use the Render MCP.
- **`create_cron_job` has no root-dir and no env-group parameter** — bake `cd backend &&` into the
  commands (leave Root Directory empty) and link the env group in the dashboard.
- **The Supabase MCP role cannot `UPDATE cron.job`** — use `cron.schedule` / `cron.alter_job`
  (SECURITY DEFINER) to create, enable, and disable jobs.
- **Trivia proof tables are in the `trivia` schema** — qualify `trivia.questions`,
  `trivia.election_races`, `trivia.generation_jobs`.
- **Cloud scheduled routines cannot use Claude Code MCP connectors** — a check that needs the
  Supabase/Render connectors must be a *local* scheduled task, not a cloud routine.
- **`get_service` (Render MCP) does not return env values** by design — you cannot read secrets
  back through it; provision cron env via an env group in the dashboard.
- **An env group copied from the API brings `NODE_ENV=production`, which breaks a `npx tsc` build**
  (npm omits devDeps at build). Set `NPM_CONFIG_INCLUDE=dev` on the build, or the build command
  installs no `typescript`/`@types`. This is silent until the *next* deploy after the group is
  linked — the create-time build passes, so watch the first post-link auto-deploy.
