---
phase: 159
slug: mi-va-primary-field-coverage
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-01
---

# Phase 159 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. This is a PURE-DATA phase — validation is SQL-gate + coordinate-smoke driven (no unit-test framework), consistent with Phases 155/156/157/158.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `psql` against prod (ref kxsdzaojfaibhuzmclfq) via `backend/.env` `DATABASE_URL` + node coordinate-smoke script (`ST_Covers` geofence check), same as 158 |
| **Config file** | `backend/.env` (gitignored) |
| **Quick run command** | `cd backend && source .env && psql "$DATABASE_URL" -f scripts/159-verify.sql` |
| **Full suite command** | Above gate + coordinate smoke (in-district MI + VA test addresses → House race surfaces full field) |
| **Estimated runtime** | ~15–30 seconds |

---

## Sampling Rate

- **After every seeding task commit:** Run per-state count assertions (records created, race_candidates wired, 0 duplicate incumbents)
- **After every stance push:** Run 0-unsourced assertion (every `politician_answers` row has a paired `inform.politician_context` row with a non-empty source URL)
- **After each plan wave:** Run `159-verify.sql` in full
- **Before phase verification:** Full gate green (psql exit 0) + coordinate smoke all-green
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Secure Behavior | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------------|-----------|-------------------|--------|
| 159-A-* | 159-A | 1 | USHC2-02/03/04/05 (MI) | data-only; no auth surface | SQL assertion | `psql -f scripts/159-verify.sql` (MI section) | ⬜ pending |
| 159-B-* | 159-B | 1 | USHC2-02/03/04/05 (VA) | data-only | SQL assertion | `psql -f scripts/159-verify.sql` (VA section) | ⬜ pending |
| 159-C-* | 159-C | 2 (≥Aug-5) | USHC2-06 (cull) | data-only | SQL assertion | two-path prune verify | ⬜ pending |
| 159-D-* | 159-D | 3 | USHC2-06 (gate) | read-only | SQL + coordinate smoke | `psql -f scripts/159-verify.sql` + smoke | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- `backend/scripts/159-verify.sql` — the consolidated MI+VA gate (authored by 159-D plan; mirrors `158-verify.sql` dual-state shape + per-state honest-skip pins)
- Coordinate-smoke harness — reuse the 158 node script; add in-district MI + VA test coordinates

*Existing pipeline scripts (`_merge.ts`, `_push_uuid.ts`, `_push.ts`, `_push_relaxed.ts`) cover seeding/stance push — no new framework install.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Primary-source stance verification | USHC2-05 | Source-truth judgement can't be asserted by SQL | Before each push: fetch each cited URL, confirm it supports the stance value (chairs-not-polarity) |
| Headshot correct-person check | USHC2-04 | Homonym/wrong-person risk (156 lesson) | Visual confirm each imported headshot is the right individual; documented honest-skips allowed |
| Aug-4 primary-result confirmation | USHC2-06 | Official results only exist post-primary | 159-C: read MI SoS / VA DoE official results to confirm advancing nominees before culling |

---

## Validation Sign-Off

- [ ] All seeding tasks have an SQL count/coverage assertion
- [ ] 0-unsourced assertion runs after every stance push
- [ ] `159-verify.sql` covers all 13 MI + 11 VA districts + honest-skip pins
- [ ] Coordinate smoke covers ≥1 in-district MI + ≥1 in-district VA address
- [ ] `nyquist_compliant: true` set once the gate script exists

**Approval:** pending
