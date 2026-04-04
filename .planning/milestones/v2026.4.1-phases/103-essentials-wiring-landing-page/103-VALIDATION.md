---
phase: 103
slug: essentials-wiring-landing-page
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-03
---

# Phase 103 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | vitest (ev-accounts/backend), manual browser (essentials frontend) |
| **Config file** | ev-accounts/backend/vitest.config.ts |
| **Quick run command** | `cd ev-accounts/backend && npm test` |
| **Full suite command** | `cd ev-accounts/backend && npm test && cd ../../essentials && npm run build` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd essentials && npm run build` (catches TS/import errors)
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 103-01-01 | 01 | 0 | — | setup | `cd essentials && npm ls @chrisandrewsedu/ev-ui` | ✅ | ⬜ pending |
| 103-02-01 | 02 | 1 | VIS-01, VIS-02 | visual/build | `cd essentials && npm run build` | ✅ | ⬜ pending |
| 103-03-01 | 03 | 1 | VIS-04, VIS-05 | visual/build | `cd essentials && npm run build` | ✅ | ⬜ pending |
| 103-04-01 | 04 | 1 | NAV-01, NAV-02 | visual/build | `cd essentials && npm run build` | ✅ | ⬜ pending |
| 103-05-01 | 05 | 2 | VIS-04 | visual/build | `cd essentials && npm run build` | ✅ | ⬜ pending |
| 103-06-01 | 06 | 2 | DATA-04 | unit | `cd ev-accounts/backend && npx tsx backend/scripts/auditHeadshots.ts --dry-run` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `npm update @chrisandrewsedu/ev-ui` — upgrade essentials to ev-ui 0.1.55
- [ ] `npm install @floating-ui/react` — tooltip dependency for icon overlays

*Existing test infrastructure covers backend. Frontend validation is build-check + manual browser.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Tier hue differentiation visible | VIS-01, VIS-02 | Visual color check | Open /results with Monroe County address, verify Federal/State/Local sections have distinct teal shades |
| Icon tooltips on hover/tap | VIS-04, VIS-05 | Interactive behavior | Hover icons on desktop, tap on mobile — verify tooltip text and dismiss behavior |
| Election page reduced noise | VIS-04 | Visual layout judgment | Compare election page before/after — race grouping should be clearer |
| Coverage cards on landing | NAV-01, NAV-02 | Visual + navigation | Verify two cards appear, click each to confirm navigation to correct results |
| Headshot audit CSV output | DATA-04 | Script output review | Run audit script, verify CSV has correct columns and flags real issues |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
