---
phase: 98
slug: election-data-import
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-29
---

# Phase 98 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Vitest ^2.1.0 |
| **Config file** | None — Vitest runs via `npm test` script |
| **Quick run command** | `cd ev-accounts/backend && npm run typecheck` |
| **Full suite command** | `cd ev-accounts/backend && npm test && npm run typecheck` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd ev-accounts/backend && npm run typecheck`
- **After every plan wave:** Run `cd ev-accounts/backend && npm test && npm run typecheck`
- **Before `/gsd:verify-work`:** Full suite must be green + all 4 success criteria verified manually
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 98-01-01 | 01 | 1 | DATA-06 | typecheck | `cd ev-accounts/backend && npm run typecheck` | ✅ | ⬜ pending |
| 98-01-02 | 01 | 1 | DATA-06 | typecheck | `cd ev-accounts/backend && npm run typecheck` | ✅ | ⬜ pending |
| 98-02-01 | 02 | 2 | DATA-06 | smoke | `curl "http://localhost:3000/api/essentials/elections?lat=39.165&lng=-86.526"` | N/A | ⬜ pending |
| 98-02-02 | 02 | 2 | DATA-06 | smoke | `curl "http://localhost:3000/api/essentials/elections?lat=34.053&lng=-118.243"` | N/A | ⬜ pending |
| 98-03-01 | 03 | 3 | DATA-06 | code review | `grep -n "ANTIPARTISAN" ev-accounts/backend/scripts/importElectionData.ts` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] No test files to create — DATA-06 verification is primarily manual (test address queries against live DB)
- [ ] Typecheck passes as baseline gate: `cd ev-accounts/backend && npm run typecheck`

*Existing infrastructure covers automated verification needs. Phase 98 is data ingestion — verification is manual smoke testing with test addresses.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Bloomington test address returns election results | DATA-06 criterion 1 | Requires populated DB + running server | `curl "http://localhost:3000/api/essentials/elections?lat=39.165&lng=-86.526"` — verify non-empty elections array |
| LA County test address returns election results | DATA-06 criterion 2 | Requires populated DB + running server | `curl "http://localhost:3000/api/essentials/elections?lat=34.053&lng=-118.243"` — verify non-empty elections array |
| candidate_status field present, no withdrawn returned | DATA-06 criterion 3 | Requires DB query after import | SQL: `SELECT candidate_status, count(*) FROM essentials.race_candidates GROUP BY candidate_status` + verify endpoint excludes withdrawn |
| Antipartisan comments in import script | DATA-06 criterion 4 | Code review item | `grep -n "ANTIPARTISAN\|antipartisan\|party affiliation" ev-accounts/backend/scripts/importElectionData.ts` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
