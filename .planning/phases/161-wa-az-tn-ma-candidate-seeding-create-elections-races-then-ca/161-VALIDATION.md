---
phase: 161
slug: wa-az-tn-ma-candidate-seeding-create-elections-races-then-ca
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-03
---

# Phase 161 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Synced to the final 11-plan set after plan-checker pass (0 blockers) 2026-07-03.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | psql read-only gate scripts (`-v ON_ERROR_STOP=1`) + `node` diag/validator scripts in `backend/scripts/` |
| **Config file** | none — scripts run against production Supabase (ref `kxsdzaojfaibhuzmclfq`) via `backend/src/lib/db.js` pool |
| **Quick run command** | per-plan `<automated>` verify + the psql assertions listed in each task's `<acceptance_criteria>` |
| **Full suite command** | `backend/scripts/161-verify.sql` (37-district mini-gate, authored by 161-11) + coordinate smoke incl. severe-TN negative sample |
| **Estimated runtime** | ~30–60 seconds |

---

## Sampling Rate

- **After every task commit:** Run the task's `<automated>` verify; run the acceptance-criteria psql assertions for any prod-writing task
- **After every plan wave:** Run the per-state read-only assertion block for the state just completed (counts, 0-unsourced, non-null politician_id, no party on race_candidates)
- **Before `/gsd:verify-work`:** `161-verify.sql` must pass (psql exit 0) + coordinate smoke green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

Plan-level map (per-task `<automated>` + `<acceptance_criteria>` are authoritative inside each PLAN.md; checker confirmed every task carries both).

| Plan | Wave | Requirement | Verification | Status |
|------|------|-------------|--------------|--------|
| 161-01 TN correspondence audit | 1 | USHC3-03 | Audit artifact exists with machine-readable "Severe geo_id list:" line; per-district severity table complete for TN-1..9 | ⬜ pending |
| 161-02 AZ seed (mig 1187/1188) | 1 | USHC3-02/03/04 | psql: 1 AZ election + 9 races (office_id non-null) + 32 new pols + race_candidates counts; headshot politician_images rows | ⬜ pending |
| 161-03 AZ stances | 2 | USHC3-05 | psql: 0 unsourced (every answer paired to politician_context with source URL); skip pins with search trails | ⬜ pending |
| 161-04 WA seed (mig 1189/1190) | 2 | USHC3-02/03/04 | psql: 1 WA election + 10 races + 60 new pols; zero duplicate full_name; headshots | ⬜ pending |
| 161-05 WA stances | 3 | USHC3-05 | psql: 0 unsourced; per-state push complete | ⬜ pending |
| 161-06 TN seed (mig 1191/1192) | 3 | USHC3-02/03/04 | psql: TN races wired to existing CD districts; severe races' election_id → backdated non-general "Polygon Pending" election; office_id never null | ⬜ pending |
| 161-07 TN stances p1 (TN-1..5) | 4 | USHC3-05 | psql: 0 unsourced for TN-1..5 candidates | ⬜ pending |
| 161-08 MA seed (mig 1193) | 4 | USHC3-02/03/04 | psql: candidates wired onto 9 existing_race_id races; Clark/Pressley not duplicated (NOT EXISTS proven by count) | ⬜ pending |
| 161-09 TN stances p2 (TN-6..9) | 5 | USHC3-05 | psql: 0 unsourced for TN-6..9 candidates | ⬜ pending |
| 161-10 MA stances | 5 | USHC3-05 | psql: 0 unsourced for MA candidates | ⬜ pending |
| 161-11 37-district mini-gate | 6 | USHC3-02..05 | `161-verify.sql` psql exit 0 (all labeled assertions) + coordinate smoke incl. severe-TN zero-race negative sample | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements — read-only SQL gates and diag scripts are the established validation stack (no framework install needed).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| /elections surfaces each district's field for an in-district coordinate | USHC3-03 | Coordinate smoke exercises the live feed path against prod | Run the 161-11 coordinate-smoke script (152/158 pattern) for representative in-district coordinates per state, incl. the severe-TN negative sample (must return zero races) |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (checker Dimension 8 pass; depth caveat noted as Warning 2 — real prod assertions live in acceptance_criteria, established 156/158/159 style)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (none — existing stack)
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-07-03 (plan-checker: 0 blockers, 3 doc-hygiene warnings — W1/W3 fixed, W2 accepted as established style)
