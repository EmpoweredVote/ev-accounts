# 🔴 URGENT — Prod DB degradation via slow campaign-finance queries (2026-07-22)

**Priority: P1 live service degradation.** Pick this up FIRST after /clear.

## Symptoms (live, essentials frontend)
- FEC "Where the money came from" bar NOT rendering (even on funded incumbents e.g. Warnock).
- Compass takes ~20s to load; only ONE lens shows on Warnock's profile.
- Console: `GET api.empowered.vote/api/auth/session → 401`.
All of these are DOWNSTREAM of one thing (below) — the 401 + 1-lens are symptoms of DB/pool saturation, not the cause.

## Root cause (measured on prod, kxsdzaojfaibhuzmclfq)
Campaign-finance queries over `transparent_motivations.contributions` (26.9M rows) run **up to 61s**:
- `SELECT … c.raw_record->>'contributor_name' … FROM transparent_motivations.contributions c …`
- `SELECT COALESCE(SUM(c.amount),0), COUNT(*) … FROM …contributions c …`
Several run concurrently as the page reloads → **connection pool saturates** → compass/auth/finance all stall or time out. The frontend `/summary` fetch times out before the query returns → bar hides (`useCampaignFinance.js` hides section on error/empty).

**Likely trigger:** Postgres **collation-version mismatch** on prod — `WARNING: database "postgres" ... collation version 153.120, but OS provides 153.121` (Supabase OS/glibc bump). Invalidates text-index usage → seq scans on the text/JSONB finance queries → sudden slowdown ("worked earlier, slow now").

## NOT the cause
- NOT the Essentials frontend push (that only triggers a Netlify rebuild).
- NOT the 164.2 redistricting / FL candidate work (never touched `transparent_motivations` or compass query paths).
- Backend + data are intact: `api.empowered.vote` + onrender both return Warnock's full summary (total_raised $2.6M, last_sync 2026-07-22T12:35), HTTP 200. Cache populated (3713 fec_candidate_totals, 26.9M contributions).

## Action taken this session
- Cancelled runaway >15s queries via `pg_cancel_backend` (none active at cancel time — the 60s ones had just completed). Relief is transient; recurs on next slow page load.

## Durable fix plan (needs operator approval — prod DDL, locking)
1. **Confirm** with read-only `EXPLAIN` (plan only — NOT `EXPLAIN ANALYZE`, which would run the 61s query) on the two slow finance queries → verify seq scan / unused index.
2. **`ALTER DATABASE postgres REFRESH COLLATION VERSION;`** (clears the version tracking) THEN **`REINDEX`** the affected `transparent_motivations` indexes (or `REINDEX DATABASE` in a window — REINDEX locks; use `REINDEX INDEX CONCURRENTLY` per-index to avoid downtime). Check Supabase status/support re: the collation bump — they may have triggered the OS upgrade.
3. **Consider** a covering/functional index for the contributor_name + SUM(amount)/COUNT aggregate path, or route the summary/contributions endpoints through the cached `transparent_motivations.contribution_summary_agg` instead of live aggregates over 26.9M rows.
4. **Interim mitigation options** (fast, low-risk): add a `statement_timeout` on those specific finance queries so they fail fast instead of pinning the pool; or temporarily short-circuit the campaign-finance section server-side until reindex completes.

## Key files
- Backend: `backend/src/lib/campaignFinanceService.ts` (the slow aggregate queries), `backend/src/routes/campaignFinance.ts`, `backend/src/lib/fecBackfill.ts`.
- Frontend: `essentials/src/components/CampaignFinance/hooks/useCampaignFinance.js` (hides on error), `.../CampaignFinanceSection.jsx`, wired at `essentials/src/pages/CandidateProfile.jsx:233`.
- Prod DB: schema `transparent_motivations` (contributions, fec_candidate_totals, contribution_summary_agg, politician_sources); same project as essentials `kxsdzaojfaibhuzmclfq`.
