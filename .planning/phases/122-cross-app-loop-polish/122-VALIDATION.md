---
phase: 122
slug: cross-app-loop-polish
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-16
---

# Phase 122 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | vitest (ev-accounts backend) + manual DOM/prod smoke (essentials, CompassV2) |
| **Config file** | `ev-accounts/backend/vitest.config.ts`; essentials/CompassV2 have no component test framework |
| **Quick run command** | `cd ev-accounts/backend && npm run typecheck` |
| **Full suite command** | `cd ev-accounts/backend && npm test` + manual prod smoke script |
| **Estimated runtime** | ~30s typecheck + ~60s backend tests + ~5min manual prod smoke |

---

## Sampling Rate

- **After every task commit:** Run `npm run typecheck` in the affected app (essentials / ev-accounts / CompassV2)
- **After every plan wave:** Run backend `npm test` if backend touched; build each touched frontend (`npm run build`)
- **Before `/gsd-verify-work`:** Full suite green + production smoke evidence captured per D-13
- **Max feedback latency:** ~90s for typecheck+unit; manual prod smoke gated at phase end

---

## Per-Task Verification Map

See `122-01-PLAN.md` for task-level verify blocks. Populated by the planner.

---

## Wave 0 Requirements

Phase 122 is a diagnose-and-fix phase with limited greenfield code. Wave 0 needs:

- [ ] INTG-01 diagnostic harness: a dev-mode probe log in `essentials/src/contexts/CompassContext.jsx` guest-priority-chain (line §104–141) that emits the priority resolution (`api` / `fragment` / `storage` / `empty`) + `guestCompass` key state. Removed before merge OR gated behind `import.meta.env.DEV`.
- [ ] INTG-03 backend contract test: add a vitest integration test that hits `GET /api/treasury/cities` and asserts the response shape used by Essentials (`id`, `name`, `state`, `available_datasets`). Protects against silent shape drift.
- [ ] No new test framework needed; essentials/CompassV2 keep manual verification.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| CompassCard shows comparison overlay for returning calibrated guest | INTG-01 | Cross-origin fragment relay + localStorage — not unit-testable without a browser harness | Guest: complete compass on compass.empowered.vote → click "View profile" for Matt Pierce → verify overlay. Close tab. Revisit essentials.empowered.vote/politician/{pierce-id} directly (no fragment). Verify overlay still renders. DevTools: `localStorage.getItem('guestCompass')` is non-null. |
| CompassCard overlay for logged-in returning user | INTG-01 / D-14 | Requires authed session | Same as above, logged in. Verify `clearGuestCompass()` does not wipe cache when API returns []. |
| Compass→Essentials profile link resolves for every picker entry | INTG-02 / D-14 | Cross-origin navigation | On compass.empowered.vote compare page, cycle through each politician in the picker. Click "View full profile on Essentials". Confirm each loads `/politician/:id` (or `/candidate/:id` if applicable). Capture screenshot evidence for at least one politician and one candidate entry if present. |
| Treasury CTA appears below Bloomington local-tier section | INTG-03 | Prod Essentials UI + live Treasury data match | Enter a Bloomington, IN address on essentials.empowered.vote. Scroll to local-tier sections. Verify "Explore Bloomington revenue and expenses →" CTA appears below the Bloomington section; click navigates to `treasurytracker.empowered.vote/?entity=bloomington-in`. |
| Treasury CTA absent for non-matching municipalities | INTG-03 | Negative case | Same address — verify township/county sections without Treasury data show NO CTA (not grayed, simply absent). |
| Prod verification gate | D-13 | Production URLs only | All above on `essentials.empowered.vote` + `compass.empowered.vote` after Render deploy. Screenshot + DOM evidence saved to phase dir. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify (typecheck counts)
- [ ] Wave 0 covers diagnostic probe + treasury endpoint contract test
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s for automated checks
- [ ] `nyquist_compliant: true` set in frontmatter once populated by planner

**Approval:** pending
