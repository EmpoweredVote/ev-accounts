---
phase: 68
plan: 01
subsystem: admin-ui
tags: [modal, headlessui, connected-tier, inform-tier, react, typescript]

dependency_graph:
  requires:
    - "67-01: InformConstraintsModal canonical pattern"
    - "60-01: ev-teal color token in admin/src/index.css"
  provides:
    - "ConnectedExplainerModal component (CEXP-02, CEXP-03)"
    - "Focused Connected Account explainer with invite-code CTA"
  affects:
    - "68-02: ProfilePage.tsx imports and wires this modal"

tech_stack:
  added: []
  patterns:
    - "headlessui v2 flat Dialog API (Dialog/DialogPanel/DialogTitle only, no Transition)"
    - "ev-teal border accent for Connected tier modal identity"

key_files:
  created:
    - admin/src/components/ConnectedExplainerModal.tsx
  modified: []

decisions:
  - "Used InformConstraintsModal.tsx as canonical pattern — flat headlessui v2, no Transition wrappers"
  - "ev-teal/30 border (not ev-yellow) — modal explains Connected tier, not Inform tier"
  - "Link to='/signup' + onClose on click — modal closes before router navigation"
  - "Close button is low-prominence (gray-400) to avoid competing with primary CTA"

metrics:
  duration: "~2 minutes"
  completed: "2026-05-07"
---

# Phase 68 Plan 01: ConnectedExplainerModal Summary

**One-liner:** New `ConnectedExplainerModal` dialog with teal Connected-tier theming, CEXP-02 explainer content (identity verification + Alpha invite codes), and CEXP-03 invite-code CTA linking to `/signup`.

## What Was Built

Created `admin/src/components/ConnectedExplainerModal.tsx` — a focused Connected Account explainer modal for Inform-tier users viewing `/profile`. The component explains what Connected Accounts are, how identity verification works during Alpha (invite codes), and provides a teal "I have an invite code →" CTA that navigates to the existing `/signup` route.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Create ConnectedExplainerModal.tsx | 695b662 | admin/src/components/ConnectedExplainerModal.tsx |

## Component Contract

- **Default export:** `ConnectedExplainerModal`
- **Props:** `{ open: boolean; onClose: () => void }`
- **Dialog API:** headlessui v2 flat (`Dialog`, `DialogPanel`, `DialogTitle` — no `Transition`)
- **Color system:** `border-ev-teal/30`, `bg-ev-teal` CTA button
- **Closes via:** Escape key, backdrop click, Close button, CTA click (`onClose` on Link)
- **CTA:** `<Link to="/signup">` — routes to existing Connected signup flow

## Verification

- TypeScript: `npx tsc --noEmit` — zero errors
- Build: `npm run build` — succeeded in 3.09s
- Line count: 59 lines (above 50-line minimum)
- No `Transition` or `Transition.Child` imports
- `border-ev-teal` present
- `to="/signup"` Link present
- `@headlessui/react` import present

## Deviations from Plan

None — plan executed exactly as written.

## Next Phase Readiness

Plan 68-02 (`ProfilePage.tsx` Inform tier + wiring) can import this component directly:
```tsx
import ConnectedExplainerModal from '../components/ConnectedExplainerModal';
```
No props changes needed. Component is self-contained and ready.
