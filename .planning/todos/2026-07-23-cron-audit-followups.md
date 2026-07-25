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
- FEC 429 backoff fix — `fecAdapter.ts`, commit `d505c9ad`, deployed to prod. **VERIFIED WORKING 2026-07-23** (see item 0).
- **Discovery-sweep / Anthropic cost control — Phase 173 EXECUTED + verified + deployed 2026-07-23** (was item 1). 4/4 plans, OPS-01..04 all green, Render deploy `dep-d9gsb1n41pts73de2f1g` live. Next real exercise = Sun 2026-07-26 02:00 UTC sweep.
- DB cleanup of `transparent_motivations.ingestion_runs`.
- Donor search matview + ev_api role + finance indexes (separate incident, all shipped).

## Next steps (prioritized)

### 0. VERIFY FEC fix — ✅ DONE 2026-07-23
Confirmed working in prod after the fix went live (shipped with the Phase 173 Render deploy).
Evidence (`transparent_motivations.ingestion_runs`, `kxsdzaojfaibhuzmclfq`):
- Daily FEC failures: Jul 22 (pre-fix daytime) **3,410** → Jul 23 (post-fix, partial) **101**.
- Hourly post-deploy: `07-23 06 UTC` cycle **0 failed**; last 12h only **~15** total failures.
- **Error signature changed** = proof the new path is active: old `FEC candidate lookup failed: HTTP 429` (immediate throw) → new `FEC candidate lookup rate limited (429) after 5 retries` (retries + mostly recovers).
- Residual tail (~15/12h) is the FEC-key ceiling — see item 1 below.

### 1. FEC 429 residual TAIL — drive to zero (NEW, MEDIUM) — successor to the backoff fix
The per-request exp backoff (`d505c9ad`) recovers most 429s but **does not pace the batch**: backoff is independent per request, so the ~1k-source 6-hourly run can still collectively exceed the **shared ~1,000 req/hr FEC key** ceiling and a few requests exhaust all 5 retries. Two request sites: `resolveCommitteeIds` (candidate→committee lookup, `fecAdapter.ts:87`) + `fetchWithRetry` (Schedule A pages, `fecAdapter.ts:475`). Cron: `campaignFinanceCron.ts:27` `0 */6 * * *`.
Proposed approach (compose, cheapest-first):
- **(a) Cut request VOLUME — cache committee-ID resolution.** `resolveCommitteeIds` re-hits FEC for every source every 6h though committee IDs rarely change. Cache in DB/Redis (e.g. 30-day TTL) → roughly halves FEC calls per run. Highest ROI, lowest risk.
- **(b) Honor server rate-limit signal.** On 429 read `Retry-After` / `X-RateLimit-*` headers and back off by the server-provided amount instead of blind exponential (both retry loops). Cheap; makes backoff accurate.
- **(c) Global token-bucket limiter (the real pacing fix).** Gate ALL FEC fetches through one shared limiter targeting ~900/hr (margin under 1,000). Redis-backed so it holds across instances AND reflects the key being shared org-wide. Every fetch acquires a token first → aggregate never exceeds ceiling → tail → 0.
- **(d) Ops lever (no code):** request a higher FEC rate limit / dedicated key from api.data.gov, or (cheap stopgap) drop `fec-ingest` 6h→daily (item 3) to cut burst volume 4×.
- Verify after deploy: a full 6h cycle with **0** `failed` FEC rows.
- GSD entry: `/gsd-plan-phase` (new phase in workstream `2026-us-house-candidate-coverage`) — (a)+(b)+(c) are a tight, testable code change; (d) is a parallel operator decision.

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
Item 0 ✅ and old item 1 (discovery/Anthropic → Phase 173) ✅ both done. Highest-value remaining code change = **item 1 (FEC 429 residual tail)** → `/gsd-plan-phase` in workstream `2026-us-house-candidate-coverage`. Items 2–3 are partly operator/infra decisions — clarify before planning.
