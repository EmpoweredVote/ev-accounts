---
phase: 112
slug: data-completeness-audit
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-12
---

# Phase 112 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | vitest (existing in ev-accounts/backend) |
| **Config file** | ev-accounts/backend/vitest.config.ts |
| **Quick run command** | `cd ev-accounts/backend && npx vitest run --reporter=verbose` |
| **Full suite command** | `cd ev-accounts/backend && npm test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd ev-accounts/backend && npx vitest run --reporter=verbose`
- **After every plan wave:** Run `cd ev-accounts/backend && npm test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 112-01-01 | 01 | 1 | AUDIT-07 | — | N/A | manual | Verify baseline doc exists | ❌ W0 | ⬜ pending |
| 112-02-01 | 02 | 2 | AUDIT-01 | — | N/A | integration | `npx tsx scripts/auditRaces.ts` | ❌ W0 | ⬜ pending |
| 112-02-02 | 02 | 2 | AUDIT-02 | — | N/A | integration | `npx tsx scripts/auditCandidates.ts` | ❌ W0 | ⬜ pending |
| 112-02-03 | 02 | 2 | AUDIT-03 | — | N/A | integration | `npx tsx scripts/auditStances.ts` | ❌ W0 | ⬜ pending |
| 112-02-04 | 02 | 2 | AUDIT-04 | — | N/A | integration | `npx tsx scripts/auditQuotes.ts` | ❌ W0 | ⬜ pending |
| 112-02-05 | 02 | 2 | AUDIT-05 | — | N/A | integration | `npx tsx scripts/auditHeadshotsV2.ts` | ❌ W0 | ⬜ pending |
| 112-02-06 | 02 | 2 | AUDIT-06 | — | N/A | integration | `npx tsx scripts/auditProfiles.ts` | ❌ W0 | ⬜ pending |
| 112-03-01 | 03 | 3 | AUDIT-08 | — | N/A | integration | `npx tsx scripts/geofenceSmokeTest.ts` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Audit script templates created from existing `auditHeadshots.ts` pattern
- [ ] Ballot baseline document created in `.planning/research/`

*Existing infrastructure covers test framework requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Ballot baseline accuracy | AUDIT-07 | Requires human verification against official sources | Compare baseline doc races against Monroe County Clerk sample ballot PDFs |
| Geofence address resolution | AUDIT-08 | Requires live DB with geofence data | Run smoke test script with 5-6 Monroe County addresses, verify results match baseline |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
