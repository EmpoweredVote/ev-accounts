# Cron / scheduled-job audit — follow-ups (2026-07-23)

Handoff backlog from the 2026-07-23 cron audit. Self-contained so a fresh context can execute.
Full audit + evidence: memory `project_cron_jobs_audit.md`. Related: `project_prod_finance_slowdown_incident.md`.

## Context (what prompted this)
User reported cron jobs "breaking all the time and costing money." Audit found:
- All live scheduling = in-process **node-cron in the single Render backend web service** (`backend/src/index.ts:205-209`). Lambda handlers exist (`backend/src/lambda/*`) but **no IaC in repo** → dormant or manually-configured (untracked).
- 🔴 FEC ingestion mass-failing on FEC API HTTP 429 → **FIXED + DEPLOYED** (commit `d505c9ad`: 429 backoff in `fecAdapter.ts resolveCommitteeIds`). Verify below.
- 🧹 `ingestion_runs` bloat/orphans → **CLEANED** (38,522 stale failed rows pruned, 11 orphaned 'running' resolved).
- ⚠️ Remaining items below.

## Already done (do NOT redo)
- FEC 429 backoff fix — `fecAdapter.ts`, commit `d505c9ad`, deployed to prod.
- DB cleanup of `transparent_motivations.ingestion_runs`.
- Donor search matview + ev_api role + finance indexes (separate incident, all shipped).

## Next steps (prioritized)

### 0. VERIFY FEC fix (near-term, no code) — DO FIRST
After a 6-hour `fec-ingest` cron fire (00/06/12/18:00 UTC), query prod:
`SELECT status, count(*) FROM transparent_motivations.ingestion_runs WHERE started_at > now()-interval '7 hours' GROUP BY 1;`
Expect failed-rate to drop sharply from ~65%. (Prod = Supabase project `kxsdzaojfaibhuzmclfq`.)

### 1. Discovery-sweep / Anthropic cost control — the real "costing money" (HIGH)
> **PLANNED 2026-07-22 → Phase 173** (workstream `2026-us-house-candidate-coverage`, milestone v2.24). 4 plans / 3 waves, RESEARCH+VALIDATION+plan-checker all PASSED. Reqs OPS-01..04. Execute with `/gsd-execute-phase 173`. Phase dir: `.planning/workstreams/2026-us-house-candidate-coverage/phases/173-discovery-sweep-anthropic-cost-reliability-hardening/`.
Weekly Sun 02:00 (`discoverySweep.ts:21`) → `discoveryCron.ts` → `discoveryAgentRunner.ts`. Uses PAID Anthropic API (claude-sonnet-4-6 + server-side `web_search_20250305`) + Resend email, once per jurisdiction in `SWEEP_HORIZON_DAYS=180`. Failures: 144× "Anthropic credit balance too low", 45× key-not-configured, 21× "Claude did not invoke report_candidates".
- Add a pre-flight Anthropic credit/spend guard; skip + alert if unavailable (avoid the credit-exhaustion failures).
- Reduce the `withRetry` 3× retry on 429/transient (`discoveryCron.ts:34,86-110`) — it multiplies spend on flaky jurisdictions.
- Handle the "did not invoke report_candidates" (end_turn) case gracefully (don't count as hard failure / don't burn a retry).
- Confirm the weekly cadence + 180-day horizon are intended (cost scales with # jurisdictions).
- Needs code + deploy.

### 2. AWS Lambda/SQS path decision (MEDIUM — duplicate-work / double-spend risk)
`runFecScheduledJob()` and `runAdapterForAll()` are wired to BOTH in-process node-cron AND `backend/src/lambda/{cron-campaign-finance,sqs-worker,cron-calibration}.ts`. No IaC in repo.
- Determine (operator/AWS console) whether EventBridge schedules + SQS event-source mapping are actually live.
- If dead: delete the Lambda handlers + `startSqsWorker` wiring; keep in-process crons.
- If live: choose ONE path, add IaC (serverless/SAM/terraform) + `DEPLOY.md` docs, disable the duplicate. Note: only the Redis `FEC_LOCK_KEY` guards FEC against concurrent double-run; monthly netfile/ocpf jobs are UNLOCKED.
- While in Render env: check `FEC_BACKFILL_AUTORESUME` — if `1`, the backfill re-hammers FEC on every boot; set `0` unless a backfill is intentionally in progress.

### 3. Hygiene (LOW)
- Add a nightly pg_cron retention prune on `ingestion_runs` (e.g. delete `status='failed'` older than 14d) so the log doesn't re-bloat — as a migration + `cron.schedule`.
- Consider dropping `fec-ingest` from every-6h to daily (`campaignFinanceCron.ts:27`, `'0 */6 * * *'` → `'0 6 * * *'`) — 4× fewer FEC calls; confirm freshness needs.
- Commit the untracked treasury pg_cron jobs (jobid 5, 6) + the deployed `functions/v1/treasury...` edge function into the repo (currently prod-only, unversioned).

### 4. Lower-priority carryover (from finance incident)
- Move `fecBackfill.ts` runtime DDL on `fec_candidate_totals` into a migration; revoke `ev_api` CREATE on `transparent_motivations`.
- Deferred: donor-name btree/trgm collation `REINDEX` + `ALTER DATABASE postgres REFRESH COLLATION VERSION` (low priority — donor search already fast via matview).

## Suggested GSD entry point
Item 1 (discovery/Anthropic cost) is the highest-value code change → `/gsd-plan-phase` (or `/gsd-quick` if scoped tight). Items 2–3 are partly operator/infra decisions — clarify before planning. Item 0 is a quick verification, not a phase.
