---
phase: 154
slug: field-resolution-stance-gap-diagnostic
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-30
---

# Phase 154 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> This is a **read-only, write-free diagnostic** phase — the "tests" are the diagnostic
> scripts and the write-free `154-verify.sql` gate themselves (they ARE the deliverables).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `psql -v ON_ERROR_STOP=1` (SQL gate); `python3` (CSV shape validator); `node --import tsx` (DB diagnostic scripts) |
| **Config file** | none — scripts are standalone, run from `backend/` to resolve `node_modules` |
| **Quick run command** | `cd /c/EV-Accounts/backend && set -a && source .env && set +a && node --import tsx scripts/diag-154-incumbent-stance-gap.ts` |
| **Full suite command** | `cd /c/EV-Accounts/backend && psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/154-verify.sql` |
| **Estimated runtime** | ~10–30 seconds (three DB round-trips against `kxsdzaojfaibhuzmclfq`) |

---

## Sampling Rate

- **After every task commit:** Run the relevant diagnostic script and confirm it exits 0 with well-formed output.
- **After every plan wave:** Run all three commands (incumbent-map script, field-table CSV validator, `154-verify.sql`).
- **Before `/gsd:verify-work`:** `154-verify.sql` must exit 0 (all `DO $$ … RAISE EXCEPTION` assertions green).
- **Max feedback latency:** ~30 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 154-01-* | 01 | 1 | USHC2-01 (Part A) | — | N/A (read-only) | integration | `node --import tsx scripts/diag-154-incumbent-stance-gap.ts` (exits 0; 113-district incumbent→`politician_id` map + per-incumbent stance counts written) | ❌ W0 | ⬜ pending |
| 154-02-* | 02 | 2 | USHC2-01 (Part B) | — | N/A (read-only) | integration | `python3 scripts/diag-154-validate-field-table.py` (exits 0 = field-table.csv shape-valid; 89 `decided` + 24 `pending-primary` rows) | ❌ W0 | ⬜ pending |
| 154-02-* | 02 | 2 | USHC2-01 (Part C) | — | N/A (read-only) | integration | `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f scripts/154-verify.sql` (DB baseline pre-seeding assertions pass) | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*
*Exact task IDs assigned by the planner; the three Req-Parts above are the verification contract.*

---

## Wave 0 Requirements

- [ ] `backend/scripts/diag-154-incumbent-stance-gap.ts` — USHC2-01 Part A (adapt from `diag-148-incumbent-stance-gap.ts`: 8-state FIPS set incl. MI+VA, expected counts, Query A/B/C)
- [ ] `backend/scripts/diag-154-validate-field-table.py` — USHC2-01 Part B (adapt from `diag-148-validate-field-table.py`: row count 113, state list, `decided` vs `pending-primary (Aug-4)` field_status)
- [ ] `backend/scripts/154-verify.sql` — USHC2-01 Part C (new, `DO $$ … RAISE EXCEPTION` style cloned from `149-verify.sql`; write-free; must NOT assert a decided field for MI or VA)
- [ ] `.planning/phases/154-field-resolution-stance-gap-diagnostic/154-incumbent-map.csv` — output artifact
- [ ] `.planning/phases/154-field-resolution-stance-gap-diagnostic/154-field-table.csv` — output artifact

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Per-district Nov-3 general-ballot field is *correct* (right candidates, not just well-formed) | USHC2-01 | Field accuracy is a human research judgment against official/results sources; a script can only validate CSV shape, not factual correctness | Spot-check the field table against the cited per-state source (SoS results / Ballotpedia) for the three special/open cases (VA-11 Walkinshaw, NJ-11 Mejia, GA-13 Clark+Chavez) and ≥1 routine district per decided state |
| Non-incumbent-nominee flags resolved from a results source, never from incumbency (D-04) | USHC2-01 | Requires confirming the *provenance* of each flag, not just its presence | Verify each flagged race cites an official/results URL; confirm NJ-11 Query-A-returns-Sherrill override is documented |

---

## Validation Sign-Off

- [ ] All tasks have an `<automated>` verify command (diagnostic script or `154-verify.sql`) or a Wave 0 dependency
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (the 3 scripts + 2 output CSVs above)
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
