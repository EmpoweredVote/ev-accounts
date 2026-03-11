---
phase: 75
slug: ev-ui-categorysection-update
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-11
---

# Phase 75 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None — ev-ui and essentials have no test suites |
| **Config file** | none |
| **Quick run command** | Manual browser verification (`npm run dev` in essentials/) |
| **Full suite command** | Manual browser verification + `npm view @chrisandrewsedu/ev-ui version` |
| **Estimated runtime** | ~30 seconds (visual check) |

---

## Sampling Rate

- **After every task commit:** Manual browser check of local essentials dev server
- **After every plan wave:** Visual verification of link icon rendering + no-websiteUrl regression
- **Before `/gsd:verify-work`:** Published 0.1.41 visible in registry + essentials renders link icons
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 75-01-01 | 01 | 1 | LINK-01 | manual | Visual: icon appears when websiteUrl provided | N/A | ⬜ pending |
| 75-01-02 | 01 | 1 | LINK-01 | manual | Visual: no icon when websiteUrl absent | N/A | ⬜ pending |
| 75-01-03 | 01 | 1 | LINK-01 | manual | Visual: link opens target=_blank | N/A | ⬜ pending |
| 75-01-04 | 01 | 1 | LINK-01 | semi-auto | `npm view @chrisandrewsedu/ev-ui version` shows 0.1.41 | ❌ post-publish | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No test framework installation needed — manual verification is the established pattern for ev-ui.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| External-link icon renders in CategorySection header | LINK-01 | No test suite in ev-ui/essentials | 1. Run `npm run dev` in essentials/ 2. Search an address 3. Verify link icons appear on sections with government_body_url |
| No icon when websiteUrl absent | LINK-01 | No test suite | 1. Find a section without government_body_url 2. Verify no broken icon/anchor |
| Link opens correctly | LINK-01 | Browser behavior | 1. Click link icon 2. Verify new tab opens with correct URL |
| ev-ui 0.1.41 published | LINK-01 | Registry verification | Run `npm view @chrisandrewsedu/ev-ui version` — expect 0.1.41 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
