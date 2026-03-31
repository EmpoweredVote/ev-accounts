---
phase: 97
slug: schema-foundation-data-audit
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-29
---

# Phase 97 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | vitest |
| **Config file** | ev-accounts/backend/vitest.config.ts |
| **Quick run command** | `cd ev-accounts/backend && npx vitest run --reporter=verbose` |
| **Full suite command** | `cd ev-accounts/backend && npm test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd ev-accounts/backend && npx vitest run --reporter=verbose`
- **After every plan wave:** Run `cd ev-accounts/backend && npm test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 97-01-01 | 01 | 1 | DATA-01 | integration | `psql -c "\d essentials.elections"` | ❌ W0 | ⬜ pending |
| 97-01-02 | 01 | 1 | DATA-01 | integration | `psql -c "\d essentials.races"` | ❌ W0 | ⬜ pending |
| 97-01-03 | 01 | 1 | DATA-01 | integration | `psql -c "\d essentials.race_candidates"` | ❌ W0 | ⬜ pending |
| 97-01-04 | 01 | 1 | DATA-05 | grep | `grep -r 'party' ev-accounts/backend/migrations/042*` | ❌ W0 | ⬜ pending |
| 97-02-01 | 02 | 1 | DATA-02 | document | `test -f .planning/phases/97-*/DATA-SOURCE-DECISION.md` | ❌ W0 | ⬜ pending |
| 97-03-01 | 03 | 2 | DATA-03 | script | `cd ev-accounts/backend && npx tsx scripts/auditIsAppointed.ts` | ❌ W0 | ⬜ pending |
| 97-04-01 | 04 | 2 | DATA-04 | integration | `psql -c "SELECT column_name FROM information_schema.columns WHERE table_name='offices' AND column_name='faces_retention_vote'"` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Migration files created (042, 043) — schema changes are the primary deliverable
- [ ] Audit script stub — `ev-accounts/backend/scripts/auditIsAppointed.ts`
- [ ] Data source decision document template

*Existing vitest infrastructure covers integration test needs.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Geofence queries exclude candidates | DATA-01 | Requires PostGIS query against live data | Run essentials address lookup, verify no race_candidates in results |
| Data source coverage gaps documented | DATA-02 | Requires human judgment on completeness | Review DATA-SOURCE-DECISION.md for Monroe County IN gap analysis |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
