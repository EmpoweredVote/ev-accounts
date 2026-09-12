# Job / API split — `EV_ROLE` (Move 1)

**Status:** Move 1 only — code + PR. No deploy, no new Render/Supabase service, no plan
change. Rationale and destination: `ev-cto/tasks/2026-08-25-hosting-decision-followup.md`
(step 5) and `ev-cto/knowledge/decisions/0002-render-vs-cloudflare.md`.

## The problem

`ev-accounts-api` serves every platform login **and**, in the same process, runs the
scheduled jobs, an SQS long-poll loop, boot-recovery calls, and a ~2 GB Cal-Access
import. That mix blocks a second copy of the API and caused the 2026-07-22 P1
(`backend/src/lib/cache.ts`). Goal: the API process serves requests only; the jobs run
from their own entry points.

## What this PR changes

One env var, `EV_ROLE` (`backend/src/lib/env.ts`), read only in `backend/src/index.ts`:

| `EV_ROLE` | Behaviour |
|---|---|
| unset (default) | **Exactly today**: Express + every cron + SQS worker + boot recovery. Nothing changes until a later move sets `EV_ROLE=api`. |
| `api` | Express only. Zero crons, no SQS worker, no boot recovery. |
| `worker` | The SQS ingestion long-poll loop only. No HTTP listener. |

A blank/whitespace `EV_ROLE` is coerced to unset, so a stray empty value in the dashboard
cannot brick the login API.

**Per-job entry:** `backend/src/jobs/run.ts`, run as `node dist/jobs/run.js <job-name>`.
It runs one named job to completion, then exits (0 ok / 1 job threw / 2 unknown name). It
binds no HTTP port and registers no cron — it imports only `backend/src/jobs/registry.ts`,
never `index.ts`. Model: `backend/src/lambda/cron-*.ts`. Each job calls the **same**
run-function the in-process cron calls, so behaviour and DB writes are unchanged.

The Dockerfile `CMD` is untouched (`node … dist/index.js`), so the deployed service keeps
today's behaviour until someone sets `EV_ROLE=api`. Move 2 (not here) creates the job
homes and flips the flag.

## Job-health manifest

Intended home is per `ev-cto` step 5: heavy/long → Render cron; light/frequent →
Supabase Cron (no new vendor). "Proof it ran" is the durable write that must advance if
the job worked — the thing to watch after Move 2.

| Job (`run.js <name>`) | Source | Schedule (today) | Intended home | Proof it ran |
|---|---|---|---|---|
| `fec-burst` | `cron/campaignFinanceCron.ts:34` | `0 6 * * *` (daily 06:00 UTC) — **HEAVY**: 33 min min, seen 9h32m, no ceiling | Render cron (12h-cap risk — measure) | `transparent_motivations.ingestion_runs` row `adapter_name='fec'` → `status=completed`, `completed_at` set (the task's "reaching 662"); data in `.contributions` (`data_source='fec'`) |
| `la-county-netfile` | `cron/campaignFinanceCron.ts:50` | `0 3 1 * *` (monthly) | Render cron | `transparent_motivations.ingestion_runs` row `adapter_name='la_county_netfile'` → `status=completed` |
| `ocpf` | `cron/campaignFinanceCron.ts:66` | `0 4 1 * *` (monthly) | Render cron | `transparent_motivations.ingestion_runs` row `adapter_name='ocpf'` → `status=completed` |
| `calibration-lapse` | `cron/calibrationLapse.ts` | `0 2 * * *` (daily) | Supabase Cron (light daily) | `calibration_lapse_runs` run-date row, finalized with `warned_25`/`warned_30`/`demoted` |
| `district-staleness` | `cron/districtStaleness.ts` | `0 3 * * 0` (weekly Sun) | Supabase Cron (light weekly) | `connect.connected_profiles.districts_last_verified_at = now()` advances on resolved rows |
| `reap-stale-ingestion-runs` | `cron/reapStaleRuns.ts` | `30 5 * * *` (daily 05:30 UTC) | Supabase Cron — or fold into `fec-burst` (see note) | `transparent_motivations.ingestion_runs.status` `running`→`failed` + `completed_at` on stale rows (0 reaped is a valid run — watch it never grows) |
| `vq-consensus` | `vq/scheduler.ts:22` | `*/5 * * * *` (every 5 min; own overlap guard) | Supabase Cron (drives the Supabase-Cron choice) | `validation_quests.consensus_records.threshold_met_at` / `finalized_at` — **only when eligible quests resolve** (no per-run marker) |
| `vq-rotation` | `vq/scheduler.ts` | `0 4 * * *` (daily 04:00 UTC) | Supabase Cron (light daily) | new `validation_quests.user_quest_assignments` rows (fresh `expires_at`) |
| `trivia-expiration` | `trivia/cron/startCron.ts:14` | `0 * * * *` (hourly) | Supabase Cron | trivia `questions.status` `active`→`expired` on newly-expired rows |
| `trivia-election-detection` | `trivia/cron/startCron.ts` | `0 6 * * *` ET (daily) | Supabase Cron (LLM spend — measure) | trivia `election_races.questions_generated` `false`→`true` — **no write when 0 races detected** |
| `trivia-pipeline` | `trivia/cron/startCron.ts` | `0 2 * * *` ET (daily) | Supabase Cron (LLM spend — measure) | new trivia `generation_jobs` row per collection with terminal `status` |

Not in the manifest, by design:
- **`discovery-sweep`** (`cron/discoverySweep.ts`, `0 2 * * 0`) — default-OFF
  (`DISCOVERY_SWEEP_ENABLED`) and on-demand only, so it has no active schedule to move.
  Left off.
- **SQS ingestion worker** (`campaignFinanceScheduler.ts:765`) — a long-poll **loop**, not
  a run-to-completion job. It stays in the process as `EV_ROLE=worker`. See below.
- **Boot recovery** (`reapStaleIngestionRuns` on boot, `maybeResumeFecBurstOnBoot`,
  `maybeResumeBackfillOnBoot`) — these exist only because the always-on API restarts
  mid-job. Once a job owns its own process (Render cron won't restart it mid-run), they
  are obsolete. `reap-stale-ingestion-runs` stays available on demand. **Note:** with FEC
  moved to a Render cron that platform-locks overlapping runs, the 05:30 reaper's original
  rationale (API auto-deploy stranding `running` rows) largely goes away — decide at Move 2
  whether it stays a separate job or folds into `fec-burst`.

## The SQS loop stays (flagged)

The task says: do not delete the SQS poll loop unless the Lambda SQS event-source mapping
is confirmed deployed and draining. It is **not**. The only IaC that wires
`sqs-worker.handler` to an SQS event source is a CDK stack under `docs/infra/`
(`docs/infra/lib/infra-stack.ts`, `SqsWorkerFunction` + `SqsEventSource`), which **no CI
pipeline deploys**, and the live Render runtime bypasses all Lambda handlers via the
`!isLambda` gate. So the in-process long-poll loop (`startSqsWorker`, only active when
`SQS_INGEST_QUEUE_URL` is set) is the sole possible drainer today. This PR keeps it and
gives it a home outside the API process: `EV_ROLE=worker`. Deleting it is a later decision,
once the Lambda mapping is confirmed live in AWS.

## What still blocks running two copies of the API

After `EV_ROLE=api` removes the crons, the SQS worker, and boot recovery from the API
process, two API copies still share these process-local states. **Not fixed here — listed
for Move 2+.**

1. **Five `express-rate-limit` limiters** — `routes/auth.ts`, `invites.ts`, `feedback.ts`,
   `events.ts`, `essentialsCoordinateLookup.ts`. **Already wired** to a shared Upstash
   store (`lib/rateLimitStore.ts`). Residual: when `UPSTASH_REDIS_REST_URL`/`_TOKEN` are
   unset they fall back to the per-instance `MemoryStore`, so a second copy multiplies
   every cap by the instance count (the 6-second smoke run logged exactly this fallback).
   **Action:** confirm Upstash is configured on the API service — no code change needed.
2. **In-memory cache** (`lib/cache.ts`, the 2026-07-22 P1) — same shape: Upstash-backed
   shared mode with a per-process in-memory fallback (smoke log: `[cache] … using
   in-memory fallback`). Residual: without Upstash, two copies hold divergent caches.
   **Action:** confirm Upstash configured; verify which entries must be consistent across
   copies.
3. **Process-local locks:**
   - `inProcessLocks` (`lib/campaignFinanceScheduler.ts:95`) — a **fallback** mutex used
     only when the Redis distributed lock is unavailable. The on-demand ingestion path
     (`POST /admin/ingest/:adapter`) still runs on the API; with `REDIS_URL` set the Redis
     lock is cross-instance, but without it two copies are not serialised. **Action:**
     require the Redis lock for ingestion before running two copies.
   - `lockHeld` (`lib/discoveryCron.ts:71`) — a per-process boolean that API routes
     acquire directly (`acquireRunLock`). The scheduled sweep is off under `EV_ROLE=api`,
     but the on-demand discovery route can still be triggered; two copies each hold their
     own boolean and could run concurrently (double Anthropic spend, double writes).
     **Action:** replace with a shared (Redis) lock.

## Proof of the three run modes (hermetic, bogus DB — never touched prod)

Built `dist/` run from a directory with no `.env`, dummy env, `DATABASE_URL` at a refused
port. Full logs captured; key signals:

- **Unset (default):** `[server] listening on port …` + all core cron registrations
  (`[cron] … registered` for calibration, FEC daily 06:00, Netfile monthly, OCPF monthly,
  district-staleness weekly, reaper daily 05:30) + `startSqsWorker` called
  (`SQS_INGEST_QUEUE_URL not set — SQS worker disabled`) + `startVqCrons`/`startTriviaCrons`
  called + boot recovery ran (`[startup] stale ingestion-run reap failed …` against the
  bogus DB). Same as today.
- **`EV_ROLE=api`:** `[server] EV_ROLE=api — serving requests only; no crons, no SQS
  worker, no boot recovery` + `[server] listening …`, and **zero** cron/worker/boot
  signatures. It still runs the request-path inits (campaign-finance schema warm-up,
  trivia session storage).
- **`EV_ROLE=worker`:** `[server] EV_ROLE=worker …` + `startSqsWorker` call, and **no**
  `listening` line — binds no HTTP port.
- **Per-job:** `node dist/jobs/run.js district-staleness` → `[jobs] running
  "district-staleness"` → fails fast on the bogus DB → exit 1, **no** `listening` line.
  Unknown name → exit 2 + usage.

## Verification

- `npm run build` — passes.
- `npm run test:unit` — 123 files, 1599 tests, all pass (includes
  `src/jobs/registry.test.ts`). Integration tests under `../tests/**` need real secrets
  this checkout lacks; this change cannot affect them — the `index.ts` edits are all inside
  the `NODE_ENV !== 'test'` guard, and `env.ts` only adds one optional field.
