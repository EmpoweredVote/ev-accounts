# Job / API split — Move 2 runbook (`EV_ROLE=api` cutover)

Companion to [`docs/JOB-API-SPLIT.md`](JOB-API-SPLIT.md) (the design + job-health manifest) and
ev-accounts issue #476 (the checklist). Move 1 (PR #473) shipped `EV_ROLE` + the per-job runner
with `EV_ROLE` unset — no behaviour change. Move 2 runs the jobs from their own homes, then sets
`EV_ROLE=api` so the login API serves requests only.

**Decisions settled 2026-09-12 (Chris Andrews):**

1. **FEC burst → Render cron now.** Steady state fits the 12-hour cap (worst day ~10.4h, 0 days
   over 12h in the last 30). Watch the next quarterly FEC deadline (**2026-10-15**); if a day
   exceeds 12h, move only `fec-burst` to Render Workflows / Cloud Run Jobs. Keep the historical
   backfill (`FEC_BACKFILL_AUTORESUME`, default off) OUT of the 12h-capped cron.
2. **SQS drain → no worker, $0.** Live AWS check (account 361769553908, 2026-09-12) found **no
   `ev-accounts-ingest` queue, no `ev-accounts-sqs-worker` Lambda, no event-source mapping, no
   EventBridge rule**, and the backend has **no code that sends SQS messages** (the enqueuer was
   AWS EventBridge, defined only in the never-deployed CDK at `docs/infra/lib/infra-stack.ts`).
   The SQS drain is not deployed and not fed. **Create no worker home.** Confirm
   `SQS_INGEST_QUEUE_URL` is unset on the API (pre-flight below). On-demand Cal-Access ingest via
   `POST /admin/ingest/:adapter` is unchanged.
3. **Reaper → own Supabase Cron job.** `reap-stale-ingestion-runs` stays independent of FEC — a
   safety net should not depend on the job it protects, and it still covers on-demand imports
   stranded by an API redeploy. $0.
4. **Light/frequent jobs → Supabase Cron via a new HTTP trigger route.** pg_cron cannot exec a
   Node CLI; it can only run SQL or call an HTTP endpoint (pg_net). **PR #477** adds
   `POST /internal/jobs/:name` (X-Admin-Token) for exactly this. It must be merged + deployed
   before the Supabase Cron jobs can work. This corrects the "no code change" assumption in #476.

**Revised cost:** ~$4/month added (3 heavy Render crons + 2 LLM Render crons, of which only FEC
has real compute ~$2; Supabase Cron $0; no worker). Confirm against the real Render invoice after
cutover (ev-cto watchlist #63).

---

## 🔴 The env gotcha — read before creating any home

Each Render cron runs `node dist/jobs/run.js <name>`, which imports the job registry, which
imports `src/lib/env.ts`. `env.ts` **exits the process at import** if any *required* var is
missing. The required set is **not** just the DB — it includes secrets a district-staleness job
never uses:

```
SUPABASE_URL  SUPABASE_ANON_KEY  SUPABASE_SERVICE_ROLE_KEY
READRANK_TOKEN_SECRET  DATABASE_URL  ADMIN_INGEST_TOKEN
```

A home missing any of these **crash-loops at import** — it never runs the job, and (Render cron)
just shows a failed run. So give every job home the **full env of `ev-accounts-api`**, not a
subset. Plus the job-specific keys: `FEC_API_KEY` (fec-burst) and `ANTHROPIC_API_KEY`
(trivia-pipeline, trivia-election-detection).

The simplest way to avoid drift: create a Render **Environment Group** with the API's vars and
link it to the API and every job home. (Today the API keeps vars at the service level, envGroupIds
`[]`.) A first pass can just copy the vars to each home; move to a group later.

---

## Pre-flight (read-only, before touching anything)

Confirm in the Render dashboard for `ev-accounts-api` (`srv-d6h1pahr0fns739kfjfg`):

- [ ] `EV_ROLE` is **unset** (current state).
- [ ] `ADMIN_INGEST_TOKEN` is set — record it; Supabase Cron sends it as `X-Admin-Token`.
- [ ] `SQS_INGEST_QUEUE_URL` is **unset** (Decision 2). If it is set, it points at a queue that no
      longer exists — it drains nothing; safe to leave or remove.
- [ ] `UPSTASH_REDIS_REST_URL` + `UPSTASH_REDIS_REST_TOKEN` are set (not required for `EV_ROLE=api`;
      needed only before a *second* API copy — the "blocks two copies" list in the design).
- [ ] PR #477 is **merged and deployed** — `POST /internal/jobs/:name` must be live before the
      Supabase Cron jobs are enabled. Verify: `curl -s -o /dev/null -w '%{http_code}' -X POST
      https://accounts-api.empowered.vote/internal/jobs/x` returns **401** (route mounted, token
      required) — not 404.

Facts about the API service (the template every home mirrors):
`repo EmpoweredVote/ev-accounts · branch master · rootDir backend · env node ·
build "npm install && npx tsc" · region oregon · health /api/health`.

---

## Step 1 — Create the Render cron homes (PAUSED)

🔴 Paid services — confirm before creating. Create each **suspended/paused**; enable only after
the flip (Step 4). For each: same repo/branch/rootDir/build as the API, full env (see gotcha
above), **Notify on failure = ON**.

| Home (cron) | Start command | Schedule (UTC) | Notes |
|---|---|---|---|
| `ev-jobs-fec-burst` | `node --dns-result-order=verbatim dist/jobs/run.js fec-burst` | `0 6 * * *` | Needs `FEC_API_KEY`. 12h cap — watch 2026-10-15. |
| `ev-jobs-la-county-netfile` | `node --dns-result-order=verbatim dist/jobs/run.js la-county-netfile` | `0 3 1 * *` | monthly |
| `ev-jobs-ocpf` | `node --dns-result-order=verbatim dist/jobs/run.js ocpf` | `0 4 1 * *` | monthly |
| `ev-jobs-trivia-pipeline` | `node --dns-result-order=verbatim dist/jobs/run.js trivia-pipeline` | `0 7 * * *` | Needs `ANTHROPIC_API_KEY`. Was 02:00 **ET** — see DST note. LLM spend. |
| `ev-jobs-trivia-election-detection` | `node --dns-result-order=verbatim dist/jobs/run.js trivia-election-detection` | `0 11 * * *` | Needs `ANTHROPIC_API_KEY`. Was 06:00 **ET** — see DST note. LLM spend. |

- **DST note:** Render/Supabase cron is **UTC only**; the two trivia jobs were scheduled in ET via
  node-cron. `0 7 * * *` / `0 11 * * *` UTC match ET during standard time (EST); they drift one
  hour under daylight time (EDT). The exact hour does not affect correctness — accept the drift, or
  pick your preferred UTC hour.
- The `--dns-result-order=verbatim` flag mirrors the API's proven start command. (The design's
  worker example used `ipv4first`; the crons reach the DB via `DATABASE_URL` = the session pooler,
  so either works. Mirroring the API is the safe default.)

## Step 2 — Create the Supabase Cron jobs (DISABLED), + failure alerts

🔴 Prod DB config — confirm before applying. Requires PR #477 deployed. Each job calls the HTTP
route via `pg_net`. Store the admin token in **Supabase Vault**, not inline, so it is not sitting
in plaintext in `cron.job`.

One-time:
```sql
create extension if not exists pg_cron;
create extension if not exists pg_net;
-- Store the admin token once (value = ev-accounts-api's ADMIN_INGEST_TOKEN):
select vault.create_secret('<ADMIN_INGEST_TOKEN>', 'admin_ingest_token');
```

Per job (example — repeat with each name/schedule from the table):
```sql
select cron.schedule(
  'ev-vq-consensus',            -- job name
  '*/5 * * * *',                -- schedule (UTC)
  $$
  select net.http_post(
    url     := 'https://accounts-api.empowered.vote/internal/jobs/vq-consensus',
    headers := jsonb_build_object(
                 'Content-Type', 'application/json',
                 'X-Admin-Token',
                 (select decrypted_secret from vault.decrypted_secrets where name = 'admin_ingest_token')
               ),
    body    := '{}'::jsonb,
    timeout_milliseconds := 5000
  );
  $$
);
-- Create DISABLED until after the flip (Step 4):
update cron.job set active = false where jobname = 'ev-vq-consensus';
```

| Supabase Cron job | route `:name` | Schedule (UTC) |
|---|---|---|
| `ev-vq-consensus` | `vq-consensus` | `*/5 * * * *` |
| `ev-trivia-expiration` | `trivia-expiration` | `0 * * * *` |
| `ev-calibration-lapse` | `calibration-lapse` | `0 2 * * *` |
| `ev-vq-rotation` | `vq-rotation` | `0 4 * * *` |
| `ev-reap-stale-ingestion-runs` | `reap-stale-ingestion-runs` | `30 5 * * *` |
| `ev-district-staleness` | `district-staleness` | `0 3 * * 0` |

**Failure alerts (Move 2 step 2 — the real safety net; do this before anything depends on the
jobs):**
- Render crons: "Notify on failure" ON per service (Step 1).
- Supabase Cron: `pg_net` is fire-and-forget, so `cron.job_run_details` records whether the *call*
  was made, **not** whether the job succeeded. Job success is the manifest "proof it ran" signal.
  Recommended: one small Supabase Cron **health job** that runs the manifest "did it advance?"
  queries and raises one alert if any signal is stale (the ev-cto task's suggested pattern). Build
  it once the manual check has proven the manifest.

## Step 3 — (nothing for SQS)

Per Decision 2, create **no** worker. The in-process SQS loop stops on the API at the flip
(`EV_ROLE=api`); it was draining nothing. Deleting the loop from the code is a later, optional
cleanup — safe, but not required for Move 2.

## Step 4 — Cutover 🔴

1. Confirm Steps 1–2 done and all schedules **paused/disabled**.
2. Set `EV_ROLE=api` on `ev-accounts-api` and redeploy. This atomically stops the API from running
   any cron, the SQS loop, and boot recovery.
3. Verify:
   - `curl https://accounts-api.empowered.vote/api/health` → `200`.
   - `render logs --resources srv-d6h1pahr0fns739kfjfg` shows the banner
     `[server] EV_ROLE=api — serving requests only; no crons, no SQS worker, no boot recovery`
     and **zero** `[cron] … registered`, `SQS worker`, or `[startup] stale ingestion-run reap`
     lines.
4. **Enable** the Render crons (unpause) and the Supabase Cron jobs
   (`update cron.job set active = true where jobname like 'ev-%'`).
5. Run each once and confirm its "proof it ran" signal advanced (Step 5). Watch one full cycle of
   `vq-consensus` (5 min) and `trivia-expiration` (hourly).

Pausing until after the flip means no job runs in two places; enabling right after keeps the gap to
minutes. (FEC is the one safe overlap — its Redis lock serialises across processes.)

## Step 5 — "Proof it ran" (manifest verification queries)

Run once per job after enabling. Full table in `docs/JOB-API-SPLIT.md`.

```sql
-- fec-burst
select adapter_name, status, completed_at from transparent_motivations.ingestion_runs
 where adapter_name = 'fec' order by started_at desc limit 3;
-- la-county-netfile / ocpf: same, adapter_name = 'la_county_netfile' / 'ocpf'
-- calibration-lapse
select * from calibration_lapse_runs order by run_date desc limit 1;
-- district-staleness
select max(districts_last_verified_at) from connect.connected_profiles;
-- reap-stale-ingestion-runs  (0 reaped is a valid run — watch it never grows)
select status, count(*) from transparent_motivations.ingestion_runs group by status;
-- vq-consensus  (advances only when eligible quests resolve)
select max(finalized_at) from validation_quests.consensus_records;
-- vq-rotation
select max(expires_at) from validation_quests.user_quest_assignments;
-- trivia-expiration
select status, count(*) from questions group by status;   -- expired grows on newly-expired rows
-- trivia-election-detection  (no write when 0 races detected)
select count(*) from election_races where questions_generated = true;
-- trivia-pipeline
select id, status, created_at from generation_jobs order by created_at desc limit 5;
```

Trigger a Supabase-Cron job on demand (bypasses the schedule):
```bash
curl -X POST https://accounts-api.empowered.vote/internal/jobs/<name> \
  -H "X-Admin-Token: <ADMIN_INGEST_TOKEN>"
# -> 202 {"status":"started"}   then watch the proof query above
```

## Rollback (one variable)

Unset `EV_ROLE` on `ev-accounts-api` and redeploy → the API resumes running everything in-process
exactly as today. Pause the new homes (`update cron.job set active=false where jobname like 'ev-%'`;
suspend the Render crons). The default path is preserved precisely to make this a single-variable
revert.

## After cutover

- Daily for ~2 weeks, then weekly, then fold into the CTO weekly review: run the Step 5 proofs.
- Read the real Render invoice; confirm the added line is ~$4/month (watchlist #63). Reopen ev-cto
  decision 0002 if Render compute passes ~$85/month.
- Before a **second** API copy: clear the "blocks two copies" list in `docs/JOB-API-SPLIT.md`
  (Upstash for the 5 rate limiters + `cache.ts`; shared Redis lock for discovery `lockHeld` and
  ingestion `inProcessLocks`).
