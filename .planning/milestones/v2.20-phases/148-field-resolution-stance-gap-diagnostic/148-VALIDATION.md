---
phase: 148
slug: field-resolution-stance-gap-diagnostic
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-28
---

# Phase 148 — Validation Strategy

> Per-phase validation contract. Phase 148 is a **read-only diagnostic / data-gathering** phase — it produces reference artifacts (a per-district field table + incumbent/stance-gap map + new-candidate enumeration), not application code. There is no unit-test framework in scope; validation is via read-only SQL/`node --import tsx` assertions against production and reconciliation of the produced artifacts.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | none — read-only diagnostic queries via `node --import tsx` + `pool` from `backend/src/lib/db` (load `.env`); no jest/vitest in scope |
| **Config file** | none |
| **Quick run command** | `cd backend && set -a && source .env && set +a && node --import tsx <diagnostic script>` |
| **Full suite command** | re-run the diagnostic SQL + assert the field-table artifact row count = 144 (minus confirmed vacancies) |
| **Estimated runtime** | ~10–30 seconds (network-bound on field-source fetches) |

---

## Sampling Rate

- **After every task:** re-run the relevant read-only query; confirm row counts reconcile (per-state district totals: CA 52 / TX 38 / FL 28 / NY 26).
- **Before phase close:** the per-district field table covers all 144 districts; every incumbent mapped to a `politician_id` by `(district_type='NATIONAL_LOWER', geo_id)`; every non-incumbent-nominee district flagged.
- **Max feedback latency:** ~30 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Secure Behavior | Test Type | Verification | Status |
|---------|------|------|-------------|-----------------|-----------|--------------|--------|
| 148-01-* | 01 | 1 | USHC-01 | read-only (no writes to prod) | data-assertion | per-state district count + incumbent `politician_id` map reconciles | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red. Per-task rows finalized by the planner.*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase needs — `node --import tsx` + `pool` is the established read-only query harness (v2.17/v2.18 methodology in STATE.md). No framework install required.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Nov-3 general-ballot field is correct per district | USHC-01 | External ground truth (Wikipedia/Ballotpedia/FEC) is not machine-assertable against an internal source of truth — this phase *establishes* that source | Spot-check a sample of districts per state against the cited primary source; confirm NY-10 (Goldman lost) + NY-13 (Espaillat lost) + CA same-party top-two generals from a primary-results source |

---

## Validation Sign-Off

- [ ] Field table covers 144 districts (minus confirmed vacancies FL-20 / TX-23), per-state counts reconcile
- [ ] Every incumbent mapped to existing `politician_id` via `(district_type, geo_id)` — 0 computed-external_id lookups
- [ ] Every non-incumbent-nominee district flagged with a cited primary-results source
- [ ] New-candidate-vs-reuse classification complete per state
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
