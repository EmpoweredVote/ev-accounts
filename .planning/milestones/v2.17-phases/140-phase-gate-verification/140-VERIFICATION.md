---
phase: 140-phase-gate-verification
status: passed
verified: 2026-06-20
requirements: [USHS-14]
---

# Phase 140 Verification — Consolidated Phase Gate

**Goal:** A single read-only, labeled-assertion SQL script confirms all 212 in-scope US House reps have sourced stance coverage with zero unsourced rows — the consolidated proof that v2.17 is complete.

## Goal-backward result: PASSED

`backend/scripts/verify-phase-132-140.sql` ran read-only against production (`psql -v ON_ERROR_STOP=1`) and **every labeled assertion (USHS-06..14) emitted its PASS NOTICE**, ending with `verify-phase-132-140: ALL USHS-06..14 ASSERTIONS PASSED`.

## Success Criteria

1. ✅ The script (following the `verify-phase-127-131.sql` pattern) runs read-only and every labeled assertion PASSES against production.
2. ✅ Asserts all 212 in-scope reps have ≥1 stance (211 covered + the 1 documented honest-skip McDowell −37006) and that **zero** answer rows lack a paired `inform.politician_context` row with a real source URL (USHS-14b PASS: 0).
3. ✅ Per-state/per-wave coverage counts asserted (USHS-06..13); USHS-14a pins the sole gap to exactly −37006, so any *other* missed rep would fail.

## Notes

- Read-only verified: only SELECT/COUNT in DO blocks; no write statements (grep-checked).
- Constants fixed by a live diagnostic; no constant edited to force a pass.

**Verdict: PASSED.** USHS-14 satisfied. **v2.17 is complete — all 9 requirements (USHS-06..14) closed across phases 132–140.** Ready for `/gsd-complete-milestone`.
