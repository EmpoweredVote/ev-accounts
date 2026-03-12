---
phase: 81
slug: profile-integration
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-12
---

# Phase 81 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None detected — no test config files in ev-ui, EV-ReadRank, or essentials |
| **Config file** | none — manual verification is established pattern for this project |
| **Quick run command** | `npm run dev` (local dev server + manual check) |
| **Full suite command** | Manual end-to-end flow: Read & Rank → CTA → Essentials profile |
| **Estimated runtime** | ~5 minutes (manual) |

---

## Sampling Rate

- **After every task commit:** Run local dev server and manually verify the changed behavior in the browser
- **After every plan wave:** Full end-to-end flow: do a Read & Rank session, click "View on Essentials," verify badges on profile
- **Before `/gsd:verify-work`:** Full end-to-end flow must pass all success criteria
- **Max feedback latency:** ~5 minutes (manual verification)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 81-01-01 | 01 | 1 | VERD-05 | manual | `npm run dev` + inspect ev-ui StanceAccordion renders quotes | ❌ manual | ⬜ pending |
| 81-01-02 | 01 | 1 | PROF-02 | manual | `npm run dev` + expand StanceAccordion row, verify quote cards with badges | ❌ manual | ⬜ pending |
| 81-02-01 | 02 | 1 | PROF-04 | manual | Click "View on Essentials" CTA, verify URL fragment contains `v` key | ❌ manual | ⬜ pending |
| 81-02-02 | 02 | 1 | PROF-04 | manual | Verify CTA on both ResultsPhase and CandidateAlignmentPage | ❌ manual | ⬜ pending |
| 81-03-01 | 03 | 2 | VERD-06 | manual | Open Essentials with crafted fragment URL, check localStorage for `guestVerdicts` | ❌ manual | ⬜ pending |
| 81-03-02 | 03 | 2 | PROF-01 | manual | Open Essentials profile with verdict fragment, inspect React DevTools for `verdicts` state | ❌ manual | ⬜ pending |
| 81-03-03 | 03 | 2 | PROF-02 | manual | Full E2E: Read & Rank → CTA → profile shows badges on correct quotes | ❌ manual | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- No automated test infrastructure to install — manual verification is the established pattern for this project

*Existing manual verification protocol covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `buildVerdictFragment()` encodes verdicts into `#compass=BASE64({v})` | VERD-05 | No test framework in EV-ReadRank | In EV-ReadRank dev: rate quotes, click CTA, inspect URL fragment — verify `v` key present in decoded base64 |
| Essentials reads `v` key from fragment and saves to `guestVerdicts` localStorage | VERD-06 | No test framework in essentials | Navigate to Essentials profile with crafted `#compass=BASE64({v:{...}})` URL, open DevTools > Application > localStorage, verify `guestVerdicts` key is set |
| `useCompass().verdicts` returns populated Record after fragment parse | PROF-01 | No test framework in essentials | Open Essentials profile with verdict fragment, use React DevTools to inspect CompassContext state — confirm `verdicts` field is populated |
| Expanded StanceAccordion shows quote cards with Agreed (cyan) / Disagreed (amber) badges | PROF-02 | No test framework in ev-ui/essentials | Open Essentials profile with verdicts loaded, expand a topic row — verify quote cards appear with correct badge colors |
| "View on Essentials" CTA on both ResultsPhase and CandidateAlignmentPage | PROF-04 | No test framework in EV-ReadRank | Complete a Read & Rank session, verify CTA appears on results page per candidate card; open a CandidateAlignmentPage, verify CTA in header |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 300s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
