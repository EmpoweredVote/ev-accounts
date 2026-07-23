---
phase: 174-fec-429-rate-limit-tail-drive-the-6-hourly-ingest-to-zero-ha
verified: 2026-07-23T20:26:17Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 1
behavior_unverified_items:
  - truth: "After deploy, a full daily fec-ingest cycle completes with zero status='failed' 429 rows in ingestion_runs (FEC-05)."
    test: "Run the RENDER_DEPLOY_HOOK deploy, then after the first daily cron fire (06:00 UTC) run the §4 read-only zero-429 query in 174-FEC05-DECISION.md over a ~25h window against prod ref kxsdzaojfaibhuzmclfq."
    expected: "0 rows."
    why_human: "The daily cron is out-of-process; the first fire happens on the Render dyno after the operator-gated deploy. By plan design (prohibition + threat T-174-12) this is a documented operator check, NOT a phase-blocking gate."
verified_by: orchestrator (inline — gsd-verifier agent not installed in this environment)
---

# Phase 174: FEC 429 rate-limit tail → zero — Verification Report

**Phase Goal:** Drive the FEC ingest's residual 429 tail to zero via a root-cause incremental redesign (bulk-ccl committee resolution + incremental `min_load_date` Schedule A + shared limiter/backoff + daily cadence + amendment supersession fix), with NO api.data.gov key upgrade.
**Verified:** 2026-07-23T20:26:17Z
**Status:** passed

## Goal Achievement

### Observable Truths

| # | Truth (Req) | Status | Evidence |
|---|-------------|--------|----------|
| 1 | Candidate→committee resolution sourced from free bulk `ccl` linkage, API lookup as fallback only (FEC-01) | ✓ VERIFIED | `fecBulkLoader.buildCandidateCommitteeMap`; `fecAdapter.resolveCommitteeIds` refactored bulk-first; `fecAdapter.test.ts` FEC-01 cases green; REQUIREMENTS FEC-01 `[x]` |
| 2 | Schedule A refresh fetches only rows since last run via `min_load_date` cursor, replacing whole-cycle re-pull (FEC-02) | ✓ VERIFIED | `getFecLoadCursor` + `minLoadDate` threaded through `streamAllPages→…→streamPagesForWindow`; FEC-02 cursor tests green; REQUIREMENTS FEC-02 `[x]` |
| 3 | 6h→daily cadence + shared limiter + Retry-After/X-RateLimit-Remaining backoff on ALL FEC call sites (FEC-03) | ✓ VERIFIED | `acquireFecSlot()` gates all **4** sites (adapter, fecResearch, plus `fecBackfill` discovered during exec); `campaignFinanceCron` daily; 20/20 tests; REQUIREMENTS FEC-03 `[x]` |
| 4 | Amended row with populated `original_sub_id` retires the superseded row; dead `is_amended` skip removed (FEC-04) | ✓ VERIFIED | `retireSupersededRows` — parameterized `DELETE … WHERE data_source='fec' AND source_transaction_id = ANY($1)`, fed only by non-null `original_sub_id` (empty→inert); 14/14 adapter tests; REQUIREMENTS FEC-04 `[x]`. Live `original_sub_id` linkage NOT caught in 2 sampling sessions → operator authorized proceed on schema-level evidence (option 2, recorded in 174-FEC04-LIVE-CONFIRM.md). |
| 5 | Decision doc locks daily cadence, declines key upgrade with rationale, hands operator the zero-429 query (FEC-05) | ✓ VERIFIED | `174-FEC05-DECISION.md` §1–5; full suite 401/401 + tsc clean; REQUIREMENTS FEC-05 `[x]`. Deploy + live zero-429 = documented operator check (item below). |

**Score:** 5/5 truths verified (1 present-but-behavior-unverified: the post-deploy live zero-429 outcome, non-blocking by design).

### Required Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `backend/src/lib/fecRateLimiter.ts` (+test) | ✓ EXISTS + SUBSTANTIVE | `acquireFecSlot()`, Redis token-bucket w/ in-process fallback; 6 tests |
| `backend/src/lib/adapters/fecBulkLoader.ts` | ✓ EXISTS + SUBSTANTIVE | `buildCandidateCommitteeMap(cycle)` |
| `backend/src/lib/adapters/fecAdapter.ts` (+test) | ✓ EXISTS + SUBSTANTIVE | bulk-first committees, `min_load_date` cursor, limiter+backoff, `retireSupersededRows` |
| `backend/src/lib/fecResearch.ts` / `fecBackfill.ts` (+tests) | ✓ EXISTS + SUBSTANTIVE | remaining FEC call sites limiter-gated |
| `backend/src/cron/campaignFinanceCron.ts` | ✓ EXISTS | cadence 6h → daily |
| `174-FEC04-LIVE-CONFIRM.md` | ✓ EXISTS | operator decision recorded (option 2 / proceed) |
| `174-FEC05-DECISION.md` | ✓ EXISTS | daily cadence + no-key-upgrade + operator zero-429 query + deploy command |

## Automated Checks

- `cd backend && npx tsc --noEmit` — clean (run at each wave gate + terminal).
- `npm run test:unit` (174-05 terminal) — 36/36 files, **401/401 tests pass**; all Phase-174 test files green; no new failures.

## Operator Follow-ups (non-blocking, by plan design)

1. **Render deploy** — held for operator go-ahead; exact command in `174-FEC05-DECISION.md §5` (the cadence/code changes are out-of-process and only take effect after deploy).
2. **Zero-429 verification** — after the first daily cron fire post-deploy, run the `174-FEC05-DECISION.md §4` read-only query over ~25h; expect 0 rows.
3. **Efficacy caveat (follow-up todo)** — `original_sub_id` was null in all live samples; the FEC-04 retirement is safe+inert today but will not fire while the field stays null, so the amendment double-count (new `sub_id`, old row persists) may still occur and may need a different dedup key. Tracked as a follow-up, not a Phase-174 blocker.

**Conclusion:** Phase goal achieved at code + decision-record level. All 5 requirements closed. Remaining items are documented, non-blocking operator actions.
