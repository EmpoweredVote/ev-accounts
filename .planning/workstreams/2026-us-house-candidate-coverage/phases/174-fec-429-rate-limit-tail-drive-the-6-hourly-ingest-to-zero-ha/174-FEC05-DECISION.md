# Phase 174 — FEC-05 Decision Doc

**Decided:** 2026-07-23
**Requirement:** FEC-05 (terminal verification + decision record for the Phase 174 FEC 429 rate-limit-tail redesign)
**Status:** Code-side decisions LOCKED. Deploy HELD pending explicit operator go-ahead (see §5). Zero-429 confirmation is a post-deploy operator check, not a phase-blocking gate (see §4).

---

## 1. DECISION — cron cadence is DAILY (06:00 UTC), not 6-hourly

**Decision:** The `fec-ingest` cron job's cadence changes from `0 */6 * * *` (every 6 hours) to a daily fire at 06:00 UTC.

**Rationale:**
- FEC's `min_load_date`/`max_load_date` Schedule A filter (the mechanism 174-02 uses for incremental refresh) has **date-only granularity** — confirmed live via a 422 rejection of an hour-level timestamp (`174-RESEARCH-amendments.md` §1, point 1). Running the incremental refresh every 6 hours would re-scan the *same calendar day's* `min_load_date` window up to 4 times with **zero additional freshness** — every extra fire inside the same UTC day returns the identical row set (modulo brand-new same-day loads), which is pure rate-limit-budget waste, not a real refresh.
- FEC's own `load_date` timestamps cluster around `~03:05 UTC` in live samples (`174-RESEARCH-amendments.md` §2 point 3), consistent with a nightly batch load process. A `06:00 UTC` fire gives a safety margin after that nightly load completes, and the existing 2-day lookback window on the persisted watermark (174-02) absorbs any residual day-boundary/timezone ambiguity.
- Net effect: the daily cadence is not a compromise on freshness — it is the *correct* cadence given the filter's granularity. A sub-daily schedule was strictly worse (more requests, same data).

**Where this lives in code:** `backend/src/cron/campaignFinanceCron.ts` — the FEC job's `node-cron` registration (updated in 174-03; unchanged by this plan).

---

## 2. DECISION — NO higher/dedicated api.data.gov FEC key is required

**Decision:** This phase explicitly declines the FEC key-upgrade lever (requesting a 7,200/hr "upgraded" key via `APIinfo@fec.gov`, versus the current 1,000/hr registered "personal" key). **This decision is recorded here specifically so the option is not silently reconsidered later** without someone re-deriving why it wasn't needed.

**Rationale — why the code alone is sufficient:**
1. **Bulk-first committee resolution (FEC-01, 174-02):** `resolveCommitteeIds` now sources committee IDs from the free, unrate-limited `ccl{YY}.zip` bulk file mapping first, falling back to the live `/v1/candidates/search/` API call only on a stale/missing bulk-map entry. This eliminates the majority of what was previously a per-candidate API call on every single run.
2. **Incremental `min_load_date` refresh (FEC-02, 174-02):** Instead of re-pulling each committee's whole 2-year Schedule A history every run, each daily run only requests rows since the last successful watermark (minus a 2-day safety lookback). Live-measured order-of-magnitude reduction: a committee with zero new/amended activity in the window now costs **1 request** (previously it cost a full paginated walk of its entire history). Estimated steady-state: ~1,000 tracked committees × ~1 request average ≈ 1,000–1,500 requests per full daily sweep, versus tens of thousands per 6-hour window under the old whole-cycle-every-run design (`174-RESEARCH-amendments.md` §1 point 5) — a 10–50× reduction.
3. **Shared rate limiter across all real call sites (FEC-03, 174-01/03):** every outbound FEC HTTP request — `fecAdapter.ts`'s two call sites, `fecResearch.ts`'s admin-triggered auto-match, and `fecBackfill.ts`'s two backfill call sites (found and closed as a 174-03 deviation) — now acquires a slot from one shared Redis-backed (in-process-fallback) fixed-window limiter before firing, budgeted at `FEC_RATE_LIMIT_PER_MINUTE` (see §3) ≈ 900/hr, a 10% safety margin under the confirmed 1,000/hr ceiling. No call site can silently exceed the shared budget, including the previously-unlocked admin routes that could run concurrently with the cron.
4. **Server-signaled backoff (FEC-02/03, 174-01/03):** both retry loops now read `X-RateLimit-Remaining` proactively and parse `Retry-After` defensively (clamped to a 120s ceiling) on 429, rather than blind exponential backoff alone.

Combined, these four changes bring the code's steady-state request volume (≈1,000–1,500/day, smoothly paced under ~900/hr) comfortably under the current registered key's 1,000/hr ceiling — with headroom even during FEC quarterly-filing-deadline spikes (many committees amending/filing at once). **The ceiling was never actually the binding constraint once the request volume itself was cut at the root; it was the old whole-cycle-every-6-hours request *pattern* that was binding.** Upgrading the key would raise the ceiling but does nothing to address a request pattern that no longer needs a higher ceiling.

**The upgrade lever remains available and is documented here as a non-blocking fallback, not discarded:** if a future operational change (e.g., a second concurrent ingest worker, or a much larger tracked-committee roster) causes the daily sweep to approach the 900/hr budget again, requesting the 7,200/hr upgraded key via a one-line email to `APIinfo@fec.gov` is cheap, carries no code risk, and was independently verified as a real, documented option (`174-RESEARCH.md` Open Question 2; corroborated live via FEC's own 429 error body in `174-RESEARCH-amendments.md` §2 point 4: `"...1000 calls per hour for a personal key, or 120 calls per minute for an upgraded key"`). **This decision explicitly declines to act on that lever now** — it should not be silently revisited without re-deriving that the code-side fixes have stopped being sufficient (i.e., without a fresh non-zero reading from the §4 verification query below, sustained over more than an isolated one-off).

---

## 3. Limiter budget default + env knob

**Default:** `FEC_RATE_LIMIT_PER_MINUTE=15` (≈ 900/hr — a 10% margin under the confirmed 1,000/hr registered-key ceiling), implemented as a per-minute Redis fixed-window counter (`fecRateLimiter.ts`, `DEFAULT_BUDGET_PER_MINUTE = 15`), degrading to an in-process `Map` counter when Upstash Redis env vars are absent or erroring.

**Env knob:** `FEC_RATE_LIMIT_PER_MINUTE` is operator-tunable without a code change — set it lower to widen the safety margin (e.g. if other, non-cron processes are observed consuming the same `FEC_API_KEY` concurrently) or, if ever paired with an upgraded 7,200/hr key (§2), raised to make use of the larger ceiling.

**Why per-minute, not per-hour:** an hourly-only bucket would let the first ~900 requests of the hour fire in a burst then stall the remainder of the hour ("burst then stall") — smooth per-minute pacing avoids that and keeps request timing well clear of the per-page `AbortSignal.timeout(60_000)` (`174-RESEARCH.md` Pattern 3 / Anti-Patterns / Pitfall 4).

---

## 4. OPERATOR VERIFICATION — zero-429 confirmation (documented check, NOT a blocking gate)

**What to run, and when:** After the Render deploy in §5 goes live AND the first real daily cron fire occurs post-deploy (out-of-process — the running dyno keeps the OLD 6-hourly cadence until redeployed, and the first daily fire happens on its own schedule, not on demand), run this **read-only** query via Supabase MCP against production (`kxsdzaojfaibhuzmclfq`):

```sql
SELECT count(*)
FROM transparent_motivations.ingestion_runs
WHERE adapter_name = 'fec'
  AND status = 'failed'
  AND (notes ILIKE '%429%' OR notes ILIKE '%rate limit%')
  AND started_at > now() - interval '25 hours';
```

**Expected result:** `0` rows.

**Why 25 hours, not exactly 24:** the daily cron fires once per calendar day; a 25-hour lookback window guarantees the query's coverage spans at least one full fire even accounting for minor scheduling jitter, without needing to know the exact deploy or first-fire timestamp in advance.

**Why this is a documented operator check, not a phase-blocking gate (matches the cron-audit item-0 verification precedent):** the daily cron's first post-deploy fire is out-of-process — it happens on FEC-03's `0 6 * * *` schedule, not synchronously with this plan's execution. Phase 174 cannot wait ~25 hours inside a single execution session for that fire to occur and be queryable. This query is handed to the operator as the durable, exact confirmation step to run once that window has elapsed. A non-zero result at that point would indicate the code-side fixes (§2) are insufficient and warrant revisiting the key-upgrade decision — but the *absence* of that confirmation today does not block this phase's completion, consistent with `174-VALIDATION.md`'s "Manual-Only Verifications" table and the prohibition already recorded in `174-05-PLAN.md`'s frontmatter (`MUST NOT block phase completion on the live zero-429 result`).

---

## 5. Deploy status — HELD pending operator go-ahead

**The Render deploy that ships this phase's TypeScript changes (174-01 through 174-04) has NOT been triggered.** The operator is explicitly holding the production deploy pending their own go-ahead. This is not a code failure or an unavailable-hook situation — it is a deliberate operator hold, and it is recorded here (per this plan's own allowance for handing the deploy to the operator) rather than fired automatically.

**Exact deploy command for the operator to run when ready** (do not run automatically; hook URL value is a secret and is never printed here):

```bash
cd backend
set -a && . ./.env && set +a && curl -fsS -X POST "$RENDER_DEPLOY_HOOK"
```

This returns `{"deploy":{"id":"dep-..."}}` — record the returned `dep-...` id. The hook only *triggers* the deploy; it does not report completion. To check status once triggered:

```bash
curl -H "Authorization: Bearer $RENDER_API_KEY" \
  "https://api.render.com/v1/services/$RENDER_SERVICE_ID_EV_ACCOUNTS_API/deploys/<deployId>"
```

— inspect the JSON `status` field (`live` = done; `build_in_progress`/`update_in_progress` = running; `*_failed` = bad). Both `RENDER_API_KEY` and `RENDER_SERVICE_ID_EV_ACCOUNTS_API` live in `backend/.env` (gitignored) per the project's established `reference_render_deploy` deploy method — no new credentials are introduced by this phase.

**Why a deploy is required at all (not optional) for this phase to take effect:** every FEC-01 through FEC-04 change is TypeScript running inside the single Render backend dyno; the running dyno keeps its OLD in-memory `node-cron` registration (6-hourly cadence, no shared limiter, no incremental cursor, no bulk-first committee resolution) until a new deploy replaces the running process. Pure-data changes need no deploy; this phase is a pure-code change and does.

**Until the operator runs the deploy:** the production dyno continues running the pre-Phase-174 code (6-hourly cadence, per-request backoff only, no shared limiter, no incremental refresh, no amendment-supersession handling) — the residual ~15/12h 429 tail this phase addresses will persist unchanged in production until the deploy ships.

---

## Summary of durable decisions (for future reference, so these are not silently re-litigated)

| Decision | Value | Why | Reversible if |
|---|---|---|---|
| Cron cadence | Daily, 06:00 UTC | `min_load_date` filter is date-granularity; sub-daily = wasted budget, zero freshness gain | FEC ever adds hour-level `load_date` granularity |
| FEC key upgrade | **Declined** — stay on current 1,000/hr registered key | Code-side fixes (bulk resolution + incremental refresh + shared limiter + server-signaled backoff) bring steady-state volume to ~1,000–1,500/day, well under budget | §4's zero-429 query shows a *sustained* non-zero 429 count post-deploy (not an isolated one-off) |
| Limiter budget default | `FEC_RATE_LIMIT_PER_MINUTE=15` (~900/hr) | 10% margin under the confirmed 1,000/hr ceiling; env-tunable | Operator observes real `X-RateLimit-Remaining` values in production logs suggesting a different margin is safer/looser |
| Deploy | HELD | Operator is explicitly holding for go-ahead, not a code/availability failure | Operator runs the recorded command in §5 |

---

*Phase: 174-fec-429-rate-limit-tail-drive-the-6-hourly-ingest-to-zero-ha*
*Plan: 05*
*Requirement: FEC-05*
