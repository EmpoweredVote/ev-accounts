# ✅ RESOLVED — Prod DB degradation via slow campaign-finance queries (2026-07-22)

**Priority: P1 live service degradation. RESOLVED 2026-07-22 ~22:38 UTC.**

> **Correction:** the original triage (below, under "Superseded theory") blamed a Postgres
> **collation-version mismatch → seq scans on text indexes**. That was WRONG for this symptom.
> The real cause was a **missing composite index** on `contributions`. Root cause, fix, and
> verification are recorded below. The collation mismatch is real but is a *separate* issue that
> only affects donor-*name* search — it is deferred, not part of this incident.

## Symptoms (live, essentials frontend)
- FEC "Where the money came from" bar NOT rendering (even on funded incumbents e.g. Warnock).
- Compass takes ~20s to load; only ONE lens shows on Warnock's profile.
- Console: `GET api.empowered.vote/api/auth/session → 401`.
All DOWNSTREAM of one thing (below) — the 401 + 1-lens are symptoms of DB/pool saturation, not the cause.

## Root cause (EXPLAIN-confirmed on prod, kxsdzaojfaibhuzmclfq)
`transparent_motivations.contributions` (26.9M rows, ~14.5 GB heap) had **no
`(politician_source_id, election_cycle)` index** — only a single-column `politician_source_id`
btree. So every campaign-finance query bitmap-scanned **all** of a filer's rows across all cycles,
then filtered `election_cycle` in the heap. Warnock has **1.5M** contribution rows (1.08M in 2022
alone).

The pool-killer specifically: even the pre-agg fast path (`getSummaryFromAgg`) calls
**`getPacContributions` live on every request** (`campaignFinanceService.ts:978`). Its
`SELECT COALESCE(SUM(c.amount),0), COUNT(DISTINCT …) … WHERE election_cycle=$2 AND
raw_record->>'entity_type' IN ('PAC','PTY')` was the ~60s query. A few of these concurrently
saturate the `db.ts` pool (`max: 10`) → compass/auth/finance all stall. 54 filers have >100k rows =
54 latent landmines.

Contributing factor: the API connects as the **`postgres` superuser, which had NO
`statement_timeout`** (`rolconfig` null), while `anon`/`authenticated`/`authenticator` were all
capped. So a slow query could pin a connection for the full ~60s instead of failing fast.

## NOT the cause (still accurate)
- NOT the Essentials frontend push (that only triggers a Netlify rebuild).
- NOT the 164.2 redistricting / FL candidate work (never touched `transparent_motivations` or compass query paths).
- Backend + data are intact: `api.empowered.vote` + onrender both return Warnock's full summary, HTTP 200. Cache populated (3713 fec_candidate_totals, 26.9M contributions).

## Fix applied (approved plan: timeout first, then indexes)
1. **`ALTER ROLE postgres SET statement_timeout='8s';`** — instant relief; slow queries now fail
   fast instead of pinning the pool. Reversible: `ALTER ROLE postgres RESET statement_timeout;`.
2. **`idx_contrib_src_cycle_pac`** — PARTIAL index
   `(politician_source_id, election_cycle) WHERE raw_record->>'entity_type' IN ('PAC','PTY')`.
   Fixes `getPacContributions` (the pool-killer): cost **47,404 → 120 (~390×)**.
3. **`idx_contrib_src_cycle`** — composite `(politician_source_id, election_cycle)`, 184 MB.
   Covers the live-scan path (confidence filter / non-backfilled filers) + `getContributions`
   count: totals-query cost **47,404 → 11,604**.

Both indexes built with `CREATE INDEX CONCURRENTLY` (no table lock). Method note: the Supabase MCP
uses a fresh session per call and wraps multi-statement calls in a transaction, so CONCURRENTLY was
run via **psql** (`backend/.env` DATABASE_URL, IPv6 pooler) with `SET statement_timeout='0'` in the
same session; builds take ~5–15 min on this heap and survive the client being killed. Monitor via
`pg_stat_progress_create_index` + `pg_index.indisvalid`.

## Verification
- Pool healthy: 0 long-running finance queries; ~5 active connections.
- Live Warnock summary: **HTTP 200 in 0.36 s warm** (was ~20 s / timeout).
- Both indexes `indisvalid=true`; no invalid leftovers.

## Follow-ups (not incident-critical)
- **⚠️ Ingestion caveat:** backfill scripts also connect as `postgres`; `refreshSummaryAgg` on
  mega-raisers can exceed 8s. Before a manual backfill, `RESET` the role cap or have the script
  `SET statement_timeout=0`. (The new indexes also make those aggregations much faster.)
- **Promote the indexes into a repo migration** so they're reproducible (currently applied live only).
- **Root smell:** the API running as `postgres` superuser is *why* there was no timeout — move it to
  a scoped app role.
- **Collation mismatch** (`WARNING: … collation version 153.120, but OS provides 153.121`, Supabase
  glibc bump) is real but separate — only touches donor-*name* text indexes. Schedule a
  `REINDEX INDEX CONCURRENTLY` of `idx_contributions_donor_name_btree` / `_trgm` then
  `ALTER DATABASE postgres REFRESH COLLATION VERSION;` in a maintenance window.
- **Consider** precomputing the PAC list into `contribution_summary_agg` so `getPacContributions`
  never runs live at all.

## Key files
- Backend: `backend/src/lib/campaignFinanceService.ts` (getPacContributions ~L646, getSummaryFromAgg ~L875), `backend/src/routes/campaignFinance.ts`, `backend/src/lib/fecBackfill.ts`, `backend/src/lib/db.ts` (pool max:10).
- Frontend: `essentials/src/components/CampaignFinance/hooks/useCampaignFinance.js` (hides on error), `.../CampaignFinanceSection.jsx`, wired at `essentials/src/pages/CandidateProfile.jsx:233`.
- Prod DB: schema `transparent_motivations` (contributions, fec_candidate_totals, contribution_summary_agg, politician_sources); project `kxsdzaojfaibhuzmclfq`.

---
## Superseded theory (kept for the record — this was WRONG)
Original triage attributed the slowdown to a Postgres collation-version mismatch invalidating
text-index usage → seq scans on the text/JSONB finance queries. In fact the summary path is scoped
by `politician_source_id` (a UUID index, collation-independent); the slowness was the missing
`(politician_source_id, election_cycle)` composite forcing full cross-cycle heap scans. The
collation mismatch exists but is unrelated to this symptom.
