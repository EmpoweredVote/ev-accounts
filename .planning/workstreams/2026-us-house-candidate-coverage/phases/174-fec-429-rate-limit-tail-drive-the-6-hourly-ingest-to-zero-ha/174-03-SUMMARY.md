---
phase: 174-fec-429-rate-limit-tail-drive-the-6-hourly-ingest-to-zero-ha
plan: 03
subsystem: backend
tags: [fec, rate-limit, cron, cadence, backend-reliability, redis]

requires:
  - phase: 174-fec-429-rate-limit-tail-drive-the-6-hourly-ingest-to-zero-ha
    provides: "acquireFecSlot() shared limiter (174-01) + bulk-first committee resolution and incremental min_load_date (174-02)"
provides:
  - "Every outbound FEC HTTP request across the codebase (5 call sites in 3 files, not the 3 originally scoped) acquires the shared limiter before firing"
  - "429 backoff in fecAdapter.ts prefers a clamped server Retry-After over blind exponential delay; X-RateLimit-Remaining read defensively; X-RateLimit-Reset never read"
  - "fec-ingest cron cadence changed 6-hourly -> daily at 06:00 UTC"
affects: [fec-ingestion, campaign-finance, cron-jobs]

tech-stack:
  added: []
  patterns:
    - "Every fetch() to api.open.fec.gov, in any file, must precede the call with `await acquireFecSlot()` — grep api.open.fec.gov backend/src is the standing verification for this invariant, not just the files a given plan lists"

key-files:
  created:
    - backend/src/lib/fecResearch.test.ts
    - backend/src/lib/fecBackfill.test.ts
  modified:
    - backend/src/lib/adapters/fecAdapter.ts
    - backend/src/lib/adapters/fecAdapter.test.ts
    - backend/src/lib/fecResearch.ts
    - backend/src/lib/fecBackfill.ts
    - backend/src/cron/campaignFinanceCron.ts

key-decisions:
  - "Deviation (Rule 2): grep api.open.fec.gov across backend/src turned up a 4th call-site file, fecBackfill.ts (fetchCandidateCycles/fetchCandidateTotals), missed by 174-RESEARCH.md's 'three call sites' framing and by this plan's own files_modified/verification scope. Gated both with the same acquireFecSlot() pattern rather than leaving the plan's own prohibition ('MUST NOT leave any FEC-host fetch() ungated') unsatisfied."
  - "X-RateLimit-Remaining is read defensively on every response (success or 429) in both fecAdapter.ts HTTP paths and logged when <= 5, per Pattern 2's 'read on every response' guidance — but does not (yet) feed back into acquireFecSlot's budget; that composition is out of this plan's stated scope."
  - "parseRetryAfterMs/readRemaining placed once, above resolveCommitteeIds, and reused by fetchWithRetry — avoids duplicating the header-parsing logic across the file's two retry loops."

requirements-completed: [FEC-03]

coverage:
  - id: D1
    description: "fetchWithRetry (Schedule A) and resolveCommitteeIds' API fallback both acquire the shared limiter before every fetch attempt, including retries"
    requirement: "FEC-03"
    verification:
      - kind: unit
        ref: "backend/src/lib/adapters/fecAdapter.test.ts#fecAdapter FEC-03 > acquires the shared limiter before every schedule_a fetch (limiter gate)"
        status: pass
      - kind: unit
        ref: "backend/src/lib/adapters/fecAdapter.test.ts#fecAdapter FEC-03 > acquires the shared limiter before the resolveCommitteeIds candidate-search fallback fetch (limiter gate)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A 429 with a numeric/HTTP-date Retry-After drives the sleep, clamped to <= 120000ms; absent header falls back to the existing exponential delay"
    requirement: "FEC-03"
    verification:
      - kind: unit
        ref: "backend/src/lib/adapters/fecAdapter.test.ts#fecAdapter FEC-03 > a 429 with a numeric Retry-After header sleeps the clamped parsed value, not the raw exponential delay"
        status: pass
      - kind: unit
        ref: "backend/src/lib/adapters/fecAdapter.test.ts#fecAdapter FEC-03 > a 429 with a Retry-After header exceeding 120s clamps the sleep to the 120000ms ceiling"
        status: pass
      - kind: unit
        ref: "backend/src/lib/adapters/fecAdapter.test.ts#fecAdapter FEC-03 > a 429 with no Retry-After header falls back to the existing exponential delay"
        status: pass
    human_judgment: false
  - id: D3
    description: "searchFecCandidates (fecResearch.ts, the admin auto-match path) acquires the shared limiter before every candidate-search fetch, including the last-name fallback search"
    requirement: "FEC-03"
    verification:
      - kind: unit
        ref: "backend/src/lib/fecResearch.test.ts#fecResearch searchFecCandidates (FEC-03) > awaits acquireFecSlot before issuing the candidate-search fetch"
        status: pass
      - kind: unit
        ref: "backend/src/lib/fecResearch.test.ts#fecResearch searchFecCandidates (FEC-03) > acquires a fresh slot on every call, including a repeated (last-name-fallback-style) search"
        status: pass
    human_judgment: false
  - id: D4
    description: "fecBackfill.ts's two previously-unscoped call sites (fetchCandidateCycles, fetchCandidateTotals) also acquire the shared limiter — closing the gap the plan's own grep-based verification would otherwise have failed against"
    verification:
      - kind: unit
        ref: "backend/src/lib/fecBackfill.test.ts#fecBackfill (FEC-03 deviation) > populateFecCandidateCycles awaits acquireFecSlot before fetching a candidate's cycles"
        status: pass
      - kind: unit
        ref: "backend/src/lib/fecBackfill.test.ts#fecBackfill (FEC-03 deviation) > populateFecCandidateTotals awaits acquireFecSlot before fetching a candidate's totals"
        status: pass
    human_judgment: false
  - id: D5
    description: "fec-ingest cron cadence changed from every 6 hours to once daily at 06:00 UTC; netfile/ocpf schedules unchanged; tsc clean"
    requirement: "FEC-03"
    verification:
      - kind: other
        ref: "grep -n \"0 6 \\* \\* \\*\" backend/src/cron/campaignFinanceCron.ts (present) + grep -n \"0 \\*/6 \\* \\* \\*\" (absent) + npx tsc --noEmit (clean)"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-07-23
status: complete
---

# Phase 174 Plan 03: FEC-03 Limiter Wiring + Retry-After Backoff + Daily Cron Summary

**All five real outbound-fetch sites to api.open.fec.gov (not the three originally scoped) now acquire the shared per-minute limiter before firing; fecAdapter.ts's two 429 branches prefer a clamped server `Retry-After` over blind exponential backoff; the fec-ingest cron cadence changed from every 6 hours to once daily at 06:00 UTC.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-07-23
- **Tasks:** 3 (plan-scoped) + 1 deviation (fecBackfill.ts gating)
- **Files modified:** 5 (2 new test files, 3 modified source files, 1 modified test file, 1 modified cron file)

## Accomplishments
- `fetchWithRetry` (Schedule A) and `resolveCommitteeIds`' candidate-search API fallback in `fecAdapter.ts` both call `await acquireFecSlot()` as the first statement of every retry-loop attempt — including retries, not just the first try.
- New `parseRetryAfterMs(response)`/`readRemaining(response)` helpers in `fecAdapter.ts`: on a 429, a present `Retry-After` header (numeric seconds or HTTP-date) drives the sleep, clamped to the existing 120s ceiling (`Math.min(serverDelay ?? delayMs, 120_000)`) — never sleeping on an unclamped server value (V5/DoS). Absent header falls back to the unchanged exponential progression. `X-RateLimit-Remaining` is read defensively on every response and logged when low; `X-RateLimit-Reset` is never read anywhere in the file (that header does not exist for this API — Pitfall 1).
- `searchFecCandidates` in `fecResearch.ts` (the admin-triggered `runFecAutoMatch` path, which shares the FEC key but not the cron's distributed lock) now acquires the same shared limiter before every call, closing Pitfall 2's named collision risk.
- **Deviation:** a fresh `grep -rn "api.open.fec.gov" backend/src` (run as part of this plan's own verification step) surfaced a 4th call-site file the phase's research missed — `fecBackfill.ts`'s `fetchCandidateCycles`/`fetchCandidateTotals` (used by the boot-time historical backfill / cycle-cache population, gated behind `FEC_BACKFILL_AUTORESUME`). Gated both with the identical `acquireFecSlot()` pattern so the plan's own must-have ("MUST NOT leave any FEC-host fetch() ungated") actually holds against the real codebase, not just the 3 sites the plan named.
- `campaignFinanceCron.ts`'s `fec-ingest` job cron expression changed from `0 */6 * * *` to `0 6 * * *` (once daily, 06:00 UTC) — a safety margin past FEC's observed ~03:05 UTC nightly batch-load cluster (174-RESEARCH-amendments.md A3). Header comment and startup log string updated to match; `netfile-ingest` (`0 3 1 * *`) and `ocpf-ingest` (`0 4 1 * *`) schedules left untouched.
- 14 new/extended Vitest cases (7 in `fecAdapter.test.ts`, 3 new in `fecResearch.test.ts`, 2 new in `fecBackfill.test.ts`) proving: limiter-acquired-before-fetch ordering on all 5 real call sites; a numeric Retry-After drives the 429 sleep instead of the raw exponential value; a Retry-After exceeding 120s clamps to 120000ms; an absent header falls back to the unchanged exponential delay. All existing FEC-01/FEC-02 tests from 174-02 still pass unmodified (their mock responses were extended with a `headers.get` stub since every response now flows through `readRemaining`).

## Task Commits

Each task was committed atomically:

1. **Task 1: FEC-03 — gate fecAdapter HTTP with acquireFecSlot + honor Retry-After/X-RateLimit-Remaining** - `5317974f` (feat)
2. **Task 2: FEC-03 — gate the admin auto-match FEC call site (fecResearch) + fecBackfill deviation** - `b6bf48d7` (feat)
3. **Task 3: FEC-03 — change fec-ingest cron cadence from 6-hourly to daily** - `47f8bf10` (feat)

**Plan metadata:** (this commit, docs: complete plan)

_Task 2's commit bundles the plan-scoped `fecResearch.ts` change together with the `fecBackfill.ts` deviation fix, since both address the same "every FEC call site acquires the limiter" invariant surfaced by the same verification grep._

## Files Created/Modified
- `backend/src/lib/adapters/fecAdapter.ts` - `acquireFecSlot()` gate on both HTTP retry loops; new `parseRetryAfterMs`/`readRemaining` helpers; 429 branches prefer clamped server delay
- `backend/src/lib/adapters/fecAdapter.test.ts` - 7 new FEC-03 test cases; existing mock responses extended with a `headers.get` stub (required now that every response flows through `readRemaining`)
- `backend/src/lib/fecResearch.ts` - `acquireFecSlot()` gate before `searchFecCandidates`' fetch (covers both the primary and last-name-fallback searches in `runFecAutoMatch`)
- `backend/src/lib/fecResearch.test.ts` - new file; 3 test cases covering the acquire-before-fetch ordering and per-call re-acquisition
- `backend/src/lib/fecBackfill.ts` - (deviation) `acquireFecSlot()` gate added to `fetchCandidateCycles` and `fetchCandidateTotals`, the 4th/5th real call sites found by grep
- `backend/src/lib/fecBackfill.test.ts` - new file; 2 test cases covering the acquire-before-fetch ordering for both gated functions
- `backend/src/cron/campaignFinanceCron.ts` - fec-ingest cron expression `0 */6 * * *` -> `0 6 * * *`; header comment + startup log string updated to describe the daily cadence

## Decisions Made
- Treated the `fecBackfill.ts` gap as a Rule 2 deviation (missing critical correctness functionality) rather than deferring it, because the plan's own `<verification>` section explicitly runs `grep -rn "api.open.fec.gov" backend/src` and asserts it returns only the 3 originally-named sites — leaving `fecBackfill.ts` ungated would have made this plan's own acceptance bar false against the real codebase.
- `X-RateLimit-Remaining` is read and logged defensively (Pattern 2's "read on every response" guidance) but does not feed into `acquireFecSlot`'s budget calculation in this plan — that composition (proactive throttling from a live header value) is a natural follow-up but was not in this plan's `<behavior>` spec, which only required defensive reading.
- Kept `parseRetryAfterMs`/`readRemaining` as free functions defined once (above `resolveCommitteeIds`) and called from both `resolveCommitteeIds`' fallback loop and `fetchWithRetry`, rather than duplicating the header-parsing logic inline in each loop.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Gated fecBackfill.ts's two ungated FEC call sites**
- **Found during:** Task 2 (running the plan's own `grep -rn "api.open.fec.gov" backend/src` verification step)
- **Issue:** 174-RESEARCH.md and this plan's `files_modified`/`<verification>` scope named only 3 FEC call sites (2 in `fecAdapter.ts`, 1 in `fecResearch.ts`). A live grep across `backend/src` found 2 more, unguarded fetches in `fecBackfill.ts` (`fetchCandidateCycles`, `fetchCandidateTotals`) — used by the boot-time historical backfill / candidate-cycle-cache population. Left ungated, this plan's own must-have prohibition ("MUST NOT leave any FEC-host fetch() ungated") would be violated, and the plan's stated goal (aggregate FEC request rate never exceeds the ceiling regardless of source count or a concurrent admin run) would have a real, un-mitigated gap: `fecBackfill.ts` runs with its own independent, un-coordinated backoff and could add uncounted request volume on top of whatever budget the shared limiter is enforcing for the other call sites.
- **Fix:** Imported `acquireFecSlot` from `./fecRateLimiter.js` into `fecBackfill.ts` and added `await acquireFecSlot()` as the first statement of each retry attempt in both `fetchCandidateCycles` and `fetchCandidateTotals`, mirroring the identical pattern used in `fecAdapter.ts`/`fecResearch.ts`.
- **Files modified:** `backend/src/lib/fecBackfill.ts` (new import + 2 gate insertions), `backend/src/lib/fecBackfill.test.ts` (new file, 2 test cases)
- **Verification:** `npx vitest run src/lib/fecBackfill.test.ts` (2/2 pass); `npx tsc --noEmit` clean; `grep -rn "api.open.fec.gov" backend/src` now shows all 5 real sites, each preceded by an `acquireFecSlot()` call (verified by direct code reading, not just grep count)
- **Committed in:** `b6bf48d7` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** Necessary to make the plan's own stated invariant ("every outbound FEC HTTP request is limiter-gated") actually true against the real codebase rather than the 3-site subset 174-RESEARCH.md identified. No scope creep beyond the mechanical, same-pattern gate addition — no new test infrastructure risk, no behavior change to fecBackfill's own retry/backoff logic.

## Issues Encountered
None beyond the deviation above.

## User Setup Required

None - no external service configuration required. The cron cadence change and limiter gating take effect on next deploy with no operator action.

## Next Phase Readiness
- FEC-03 is now fully implemented: every real outbound fetch to `api.open.fec.gov` in the codebase (verified by grep, 5 sites across 3 files) acquires the shared per-minute limiter from 174-01, and both of `fecAdapter.ts`'s 429 branches honor a clamped server `Retry-After` before falling back to the existing exponential delay.
- The fec-ingest cron now fires once daily at 06:00 UTC instead of every 6 hours, eliminating the same-calendar-day 4x re-scan waste that `min_load_date`'s date-only granularity made pointless.
- This closes out Phase 174's FEC-03 requirement. Combined with 174-01 (shared limiter primitive) and 174-02 (bulk-first committee resolution + incremental min_load_date, FEC-01/FEC-02), the phase's full request-volume-and-pacing redesign is now implemented; FEC-04's live "zero 429s" verification (if scoped to a later wave) is unblocked.
- No blockers for the rest of Phase 174.

---
*Phase: 174-fec-429-rate-limit-tail-drive-the-6-hourly-ingest-to-zero-ha*
*Plan: 03*
*Completed: 2026-07-23*

## Self-Check: PASSED

All 7 created/modified source+test files and this SUMMARY.md confirmed present on disk; all 3 task commit hashes (`5317974f`, `b6bf48d7`, `47f8bf10`) confirmed present in `git log`.
