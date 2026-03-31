---
phase: 100
slug: elected-appointed-filter
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-30
---

# Phase 100 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Vitest (backend only; essentials frontend has no test framework) |
| **Config file** | `ev-accounts/vitest.config.ts` |
| **Quick run command** | `cd ev-accounts && npm test` |
| **Full suite command** | `cd ev-accounts && npm test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Manual browser check of filter behavior + `cd ev-accounts && npm test`
- **After every plan wave:** `cd ev-accounts && npm test`
- **Before `/gsd:verify-work`:** Full suite must be green + manual filter verification
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 100-01-01 | 01 | 1 | FILT-01 | integration | `cd ev-accounts && npm test` | ❌ W0 | ⬜ pending |
| 100-02-01 | 02 | 2 | FILT-01 | manual | n/a (no frontend test framework) | N/A | ⬜ pending |
| 100-02-02 | 02 | 2 | FILT-02 | manual | n/a | N/A | ⬜ pending |
| 100-02-03 | 02 | 2 | FILT-03 | manual | n/a | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `ev-accounts/tests/integration/essentials-fields.test.ts` — verify `is_appointed` and `faces_retention_vote` present in `/api/essentials/by-address` response shape

*Frontend validation is manual — essentials has no test framework.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Filter toggle renders with All/Elected/Appointed options | FILT-01 | No frontend test framework in essentials | Load results page → verify segmented control appears below tier filter |
| Retention judges appear in both Elected and Appointed views | FILT-02 | Requires visual confirmation with real data | Search Indiana address → select Elected → verify appellate judges visible → select Appointed → verify same judges visible |
| Filter defaults to All | FILT-03 | No frontend test framework | Load results page → verify All is selected → verify all politicians shown |
| Stacked filters work simultaneously | FILT-01 | No frontend test framework | Select "State" tier + "Elected" → verify only elected state officials shown |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
