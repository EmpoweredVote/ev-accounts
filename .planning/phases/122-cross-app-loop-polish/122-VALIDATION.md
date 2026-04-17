---
phase: 122
slug: cross-app-loop-polish
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-16
updated: 2026-04-16
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

- **After every task commit:** Run `npm run typecheck` (or `npm run build`) in the affected app (essentials / ev-accounts / CompassV2)
- **After every plan wave:** Run backend `npm test` if backend touched; build each touched frontend (`npm run build`)
- **Before `/gsd-verify-work`:** Full suite green + production smoke evidence captured per D-13
- **Max feedback latency:** ~90s for typecheck+unit; manual prod smoke gated at phase end

**Continuity check:** No 3 consecutive tasks without an automated verify. The map below confirms this — every task either has an `<automated>` block or (for checkpoints) immediately follows a task that did, and is followed by one that does.

---

## Per-Task Verification Map

Tasks are from `122-01-PLAN.md`. Automated verifies run locally; manual verifications listed in the Manual-Only table below.

| Task ID | Task Name | Automated Verify | Manual Verify |
|---------|-----------|------------------|---------------|
| 0.1 | Backend contract test for GET /api/treasury/cities | `cd ev-accounts/backend && npm test -- treasury.cities.contract` | — |
| 0.2 | Dev-mode probe log in CompassContext guest-priority chain | `cd essentials && npm run build` | Probe logs visible in `npm run dev` console |
| 0.3 | Populate VALIDATION.md Per-Task Map + flip nyquist_compliant | `grep -q "nyquist_compliant: true" .../122-VALIDATION.md && grep -q "Task 3.3" .../122-VALIDATION.md` | — |
| 1.1 | **checkpoint** — Diagnose INTG-01 root cause | (manual — diagnosis only) | See Manual-Only row "CompassCard overlay for returning guest" + diagnostic steps in PLAN Task 1.1 how-to-verify |
| 1.2 | Fix INTG-01 at confirmed broken layer | `cd essentials && npm run build` | Local Pierce direct-visit smoke (guest + authed) — see Manual-Only rows |
| 2.1 | **checkpoint** — Verify INTG-02 picker links | (manual — evidence-first per D-07) | Manual-Only row "Compass→Essentials profile link resolves for every picker entry" |
| 2.2 | (conditional) INTG-02 code fix | `cd ev-accounts/backend && npm run typecheck && cd ../../CompassV2 && npm run build` | Re-verify picker entry that previously failed |
| 3.1 | treasury.js helpers + VITE_TREASURY_URL env | `cd essentials && npm run build` | — |
| 3.2 | Wire Treasury CTA in Results.jsx | `cd essentials && npm run build` | Manual-Only rows "Treasury CTA appears below Bloomington" + "Treasury CTA absent for non-matches" |
| 3.3 | **checkpoint** — Production smoke + evidence | (manual — prod gate per D-13) | Manual-Only row "Prod verification gate" — all evidence under `evidence/` |

**Continuity audit:**
- Tasks 0.1 → 0.2 → 0.3 → 1.1 — 3 consecutive automated, then checkpoint (OK — preceded by three automated).
- Tasks 1.1 → 1.2 — checkpoint followed by automated (OK).
- Tasks 2.1 → 2.2 — checkpoint, conditional automated; if 2.2 skipped, next automated is 3.1 — 2 consecutive manual at most (OK).
- Tasks 3.1 → 3.2 → 3.3 — two automated, then checkpoint (OK).
- **No 3-consecutive-manual violations.**

---

## Wave 0 Requirements

Phase 122 is a diagnose-and-fix phase with limited greenfield code. Wave 0 delivers:

- [ ] INTG-01 diagnostic probe (Task 0.2) in `essentials/src/contexts/CompassContext.jsx` guest-priority-chain (line §104–141) that emits the priority resolution (`api` / `fragment` / `storage` / `empty`) + `guestCompass` key state. Gated behind `import.meta.env.DEV`.
- [ ] INTG-03 backend contract test (Task 0.1): vitest integration test hitting `GET /api/treasury/cities` and asserting the response shape used by Essentials (`id`, `name`, `state`, `available_datasets`, `entity_type`). Protects against silent shape drift.
- [ ] VALIDATION.md Per-Task Verification Map populated (Task 0.3).
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
| Prod verification gate | D-13 | Production URLs only | All above on `essentials.empowered.vote` + `compass.empowered.vote` after Render deploy. Screenshot + DOM evidence saved to phase dir `evidence/`. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (checkpoints documented as manual with adjacent automated coverage)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (typecheck/build counts)
- [x] Wave 0 covers diagnostic probe + treasury endpoint contract test
- [x] No watch-mode flags
- [x] Feedback latency < 90s for automated checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** planner-approved — ready for execute-phase.
