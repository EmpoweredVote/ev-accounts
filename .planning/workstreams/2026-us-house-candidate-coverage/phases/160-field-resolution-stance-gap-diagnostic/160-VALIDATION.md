---
phase: 160
slug: field-resolution-stance-gap-diagnostic
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-03
---

# Phase 160 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> This is a **read-only, write-free diagnostic** phase — the "tests" are the diagnostic
> scripts and the write-free `160-verify.sql` gate themselves (they ARE the deliverables).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `psql -v ON_ERROR_STOP=1` (SQL gate); `python3` (CSV shape validator); `node --import tsx` (DB diagnostic scripts) |
| **Config file** | none — scripts are standalone, run from `backend/` to resolve `node_modules` |
| **Quick run command** | `cd /c/EV-Accounts/backend && set -a && source .env && set +a && node --import tsx scripts/diag-160-incumbent-stance-gap.ts` |
| **Full suite command** | `cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/160-verify.sql` |
| **Estimated runtime** | ~10–60 seconds (DB round-trips against `kxsdzaojfaibhuzmclfq`) |

---

## Sampling Rate

- **After every task commit:** Run the relevant diagnostic script and confirm it exits 0 with well-formed output.
- **After every plan wave:** Run all diagnostic + validator commands for that wave's state subset (incumbent-map script, collision audit, race-preexistence audit, field-table CSV validator, `160-verify.sql`).
- **Before `/gsd:verify-work`:** All commands green — 178-row incumbent map, negative-id audit with all 16 discovered collisions documented + safe-seq resolved, field-table 178-row / 88-decided-90-late partition PASS, `160-verify.sql` exits 0.
- **Max feedback latency:** ~60 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 160-*-* | TBD | TBD | USHC3-01 (Part A) | — | N/A (read-only) | integration | `node --import tsx scripts/diag-160-incumbent-stance-gap.ts` (exits 0; 178-district incumbent→`politician_id` map + per-incumbent federal-24 stance counts written) | ❌ W0 | ⬜ pending |
| 160-*-* | TBD | TBD | USHC3-01 (Part B) | — | N/A (read-only) | integration | `node --import tsx scripts/diag-160-external-id-collision.ts` (exits 0; `160-negative-id-audit.csv` written; 0 UNRESOLVED collisions — all 16 discovered ones carry a documented safe-seq recommendation) | ❌ W0 (NEW — no 154 precedent) | ⬜ pending |
| 160-*-* | TBD | TBD | USHC3-01 (Part C) | — | N/A (read-only) | integration | `node --import tsx scripts/diag-160-race-preexistence-audit.ts` (exits 0; pre-existing race/candidate audit for ANY election_date, all 38 states — incl. the discovered 29-race ME/MD/MA/NV/OR baseline + IN-9 mislabel) | ❌ W0 (NEW) | ⬜ pending |
| 160-*-* | TBD | TBD | USHC3-01 (Part D) | — | N/A (read-only) | integration | `python3 scripts/diag-160-validate-field-table.py` (exits 0 = field-table.csv shape-valid; 178 rows; per-state counts; AL district-split handled; 88/90 decided/late partition) | ❌ W0 | ⬜ pending |
| 160-*-* | TBD | TBD | USHC3-01 (Part E) | — | N/A (read-only) | integration | `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/160-verify.sql` (DB baseline assertions pass — asserting the DISCOVERED 29-race baseline, not "0 races") | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*
*Exact task IDs assigned by the planner; the five Req-Parts above are the verification contract.*

---

## Wave 0 Requirements

- [ ] `backend/scripts/diag-160-incumbent-stance-gap.ts` — Part A (adapt from `diag-154-incumbent-stance-gap.ts`; 38-state FIPS set; SQL shape proven in 160-RESEARCH.md)
- [ ] `backend/scripts/diag-160-external-id-collision.ts` — Part B (NEW; collision logic proven in research, needs packaging + CSV emit)
- [ ] `backend/scripts/diag-160-race-preexistence-audit.ts` — Part C (NEW; logic proven in research, needs packaging + CSV emit)
- [ ] `backend/scripts/diag-160-validate-field-table.py` — Part D (adapt from `diag-154-validate-field-table.py`; add AL district-level split handling)
- [ ] `backend/scripts/160-verify.sql` — Part E (clone `154-verify.sql` `DO $$ … RAISE EXCEPTION` style; write-free; assert discovered 29-race baseline)
- [ ] `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-incumbent-map.csv` — output artifact
- [ ] `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-negative-id-audit.csv` — output artifact (NEW, no Phase-154 equivalent)
- [ ] `.planning/phases/160-field-resolution-stance-gap-diagnostic/160-field-table.csv` — output artifact

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Per-district ballot field is *correct* (right candidates, not just well-formed) | USHC3-01 | Field accuracy is a human research judgment against official/results sources; a script validates CSV shape, not factual correctness | Spot-check the field table against the cited per-state source for every incumbent-not-nominee flag, the AL-1/2/6/7 special-redistricting districts, LA's jungle-primary field, and ≥1 routine district per decided state |
| Incumbent-not-nominee flags resolved from a results source, never from incumbency (154 D-04 carried forward) | USHC3-01 | Requires confirming the *provenance* of each flag, not just its presence | Verify each flagged race cites an official/results URL |
| RCV races (AK, ME) exhaustively captured (CONTEXT D-04a over-indulgence) | USHC3-01 | Completeness vs official lists is a research judgment | Cross-check AK/ME field rows against the official Division of Elections / SoS candidate list; confirm `rcv` flag present |

---

## Validation Sign-Off

- [ ] All tasks have an `<automated>` verify command (diagnostic script or `160-verify.sql`) or a Wave 0 dependency
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (the 5 scripts + 3 output CSVs above)
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-07-03
