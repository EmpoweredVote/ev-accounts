---
phase: 174
slug: fec-429-rate-limit-tail-drive-the-6-hourly-ingest-to-zero-hard-failures
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-23
---

# Phase 174 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Seeded from `174-RESEARCH.md` "## Validation Architecture"; per-task rows finalized once PLAN.md files exist.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Vitest `^2.1.x` (installed) |
| **Config file** | `backend/vitest.config.ts` |
| **Quick run command** | `cd backend && npx vitest run src/lib/fecRateLimiter.test.ts src/lib/adapters/fecAdapter.test.ts` (files created by this phase) |
| **Full suite command** | `cd backend && npm run test:unit` (`vitest run src`) |
| **Estimated runtime** | ~5–15 seconds (quick); ~15–30s unit suite |

---

## Sampling Rate

- **After every task commit:** Run the quick command
- **After every plan wave:** Run `cd backend && npm run test:unit`
- **Before `/gsd-verify-work`:** Full unit suite must be green + `npx tsc --noEmit` clean
- **Max feedback latency:** ~15 seconds

---

## Per-Task Verification Map

*Seeded — finalized by the planner/plan-checker once PLAN.md tasks exist. Anchors from RESEARCH Validation Architecture:*

| Requirement | Correct Behavior | Test Type | Command (indicative) |
|-------------|------------------|-----------|----------------------|
| FEC-01 | committee resolution reads bulk `ccl` linkage (`cmteToSource`); API `resolveCommitteeIds` only on stale/missing fallback | unit | `vitest run` (mock bulk ccl source + assert no API call on hit) |
| FEC-02 | Schedule A pull sends `min_load_date` = persisted cursor; cursor advances after a successful run; whole-cycle re-pull no longer issued | unit | `vitest run` (mock fetch; assert `min_load_date` param + cursor persistence) |
| FEC-03 | cron cadence is daily; all THREE FEC call sites acquire from one shared limiter (Redis + in-process degrade); 429 honors `Retry-After`/`X-RateLimit-Remaining` then exponential fallback | unit | `vitest run` (mock Redis `.incr`/`.expire` + 429 responses; assert acquire gating + backoff) |
| FEC-04 | a returned row with populated `original_sub_id` retires the superseded row (no double-count); dead `is_amended` check removed | unit + 1 live confirm query | `vitest run` (mock incremental batch incl. `original_sub_id`; assert delete/retire) |
| FEC-05 | after deploy, a full daily cycle logs zero `status='failed'` 429 rows | manual / read-only prod query | `SELECT count(*) FROM transparent_motivations.ingestion_runs WHERE adapter_name='fec' AND status='failed' AND (notes ILIKE '%429%' OR notes ILIKE '%rate limit%') AND started_at > now()-interval '25 hours'` |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `backend/src/lib/fecRateLimiter.test.ts` — NEW; FEC-03 shared-limiter acquire/degrade + 429 `Retry-After`/`X-RateLimit-Remaining` backoff. Mock `@upstash/redis` (`.incr`/`.expire`) + `fetch`.
- [ ] `backend/src/lib/adapters/fecAdapter.test.ts` — NEW or extended; FEC-01 bulk-ccl committee resolution (no API call on hit), FEC-02 `min_load_date` incremental cursor (param sent + cursor advance), FEC-04 `original_sub_id` supersession retirement + dead-`is_amended` removal.
- [ ] Framework install: none — Vitest already installed + configured.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| A full 6-hour `fec-ingest` cycle completes with zero 429 hard-failures | FEC-04 | Requires the live 6-hourly cron to fire against the real FEC API post-deploy — out-of-process | After Render deploy, wait for the next `0 */6 * * *` fire (or a manual trigger), then run the read-only `ingestion_runs` query above; expect 0 rows |
| FEC-key-upgrade / cadence decision recorded | FEC-04 | Operator/documentation decision (request higher api.data.gov limit vs. code-only pacing; 6h→daily?) | Confirm the decision note exists in the phase docs |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies (FEC-04 outcome is manual-only by nature)
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (2 new/extended test files)
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
