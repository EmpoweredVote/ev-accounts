---
phase: 99
slug: election-central-page
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-29
---

# Phase 99 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Vitest (ev-accounts backend) |
| **Config file** | `ev-accounts/backend/vitest.config.ts` |
| **Quick run command** | `cd ev-accounts/backend && npm test` |
| **Full suite command** | `cd ev-accounts/backend && npm test` |
| **Estimated runtime** | ~15 seconds |

Note: The `essentials` frontend has no test infrastructure. Frontend validation is manual browser testing.

---

## Sampling Rate

- **After every task commit:** Run `cd ev-accounts/backend && npm test`
- **After every plan wave:** Run `cd ev-accounts/backend && npm test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 99-01-01 | 01 | 1 | ELEC-01 | manual | Browser: navigate to /results?view=elections | N/A | ⬜ pending |
| 99-01-02 | 01 | 1 | ELEC-02 | manual | Browser: verify tier/position grouping | N/A | ⬜ pending |
| 99-01-03 | 01 | 1 | ELEC-03 | manual | Browser: verify candidate cards render | N/A | ⬜ pending |
| 99-01-04 | 01 | 1 | ELEC-04 | manual | Browser: verify incumbent badge | N/A | ⬜ pending |
| 99-01-05 | 01 | 1 | ELEC-05 | manual | Browser: verify election date/countdown | N/A | ⬜ pending |
| 99-01-06 | 01 | 1 | ELEC-06 | manual | Browser: switch tabs, verify address persists | N/A | ⬜ pending |
| 99-01-07 | 01 | 1 | ELEC-07 | manual | Browser: search non-coverage address | N/A | ⬜ pending |
| 99-W0-01 | W0 | 0 | elections-by-address | integration | `cd ev-accounts/backend && npm test` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `backend/src/routes/__tests__/essentials-elections.test.ts` — integration test for `GET /api/essentials/elections-by-address` endpoint: valid address returns elections array, invalid address returns empty elections, missing address param returns 422

*Frontend: no test infrastructure — all ELEC-0x requirements validated manually in browser*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Elections tab visible on Results page | ELEC-01 | No frontend test infra | Navigate to /results with valid address, verify "Elections" tab appears |
| Races grouped by tier then position | ELEC-02 | Visual layout verification | Switch to Elections tab, verify Federal>State>Local grouping with positions |
| All candidates shown with name/photo | ELEC-03 | Visual rendering check | Verify each race shows all candidates with name and photo/initials |
| Incumbent badge visible | ELEC-04 | Visual styling check | Verify incumbent candidates show "Incumbent" label below name |
| Election date + countdown | ELEC-05 | Visual format check | Verify election header shows date, type, and countdown when <60 days |
| Tab preserves address | ELEC-06 | User interaction flow | Switch between Representatives/Elections tabs, verify address persists |
| Empty state for no-data | ELEC-07 | Edge case rendering | Search address outside coverage area, verify friendly empty state message |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
