---
phase: 67
plan: 01
name: login-hub-cta-and-inform-modal
subsystem: admin-app-auth
status: complete
completed: 2026-04-27

tech-stack:
  added: []
  patterns:
    - headlessui v2 flat Dialog API (Dialog/DialogPanel/DialogTitle, no Transition.Child)
    - caller-controlled navigation callbacks (modal has zero routing logic)
    - two-CTA login pattern (primary Inform + secondary Connected)

key-files:
  created:
    - admin/src/components/InformConstraintsModal.tsx
  modified:
    - admin/src/pages/Login.tsx

decisions:
  - id: D-01
    decision: "Keep InformConstraintsModal navigation-free — caller passes onContinue/onUseInviteCode callbacks"
    rationale: "Pure presentational modal is more testable and lets caller handle redirect-preserving logic"
  - id: D-02
    decision: "Replace single 'Don't have an account?' para with two-CTA div (yellow button + teal link)"
    rationale: "Inform must be visually primary (large yellow button); Connected stays accessible but secondary"
  - id: D-03
    decision: "informSignupHref preserves ?redirect= using same encodeURIComponent pattern as signupHref"
    rationale: "Consistent redirect behavior across both signup paths; prevents loss of deep-link context"

metrics:
  duration: "2m 33s"
  tasks_completed: 2
  tasks_total: 2
  commits: 2
---

# Phase 67 Plan 01: Login Hub CTA and Inform Modal Summary

Added a primary "Create an Account" CTA and InformConstraintsModal to the Login page, making Inform Account the visible first-class entry point while preserving the Connected invite-code path as a secondary option.

## What Was Built

### InformConstraintsModal (`admin/src/components/InformConstraintsModal.tsx`)

New reusable modal component explaining Inform Account capabilities before signup commitment.

**Component contract:**
```tsx
interface InformConstraintsModalProps {
  open: boolean;
  onClose: () => void;
  onContinue: () => void;      // caller navigates to /signup/inform
  onUseInviteCode: () => void; // caller navigates to /signup
}
```

**Behavior:**
- headlessui v2 flat API: `Dialog`, `DialogPanel`, `DialogTitle` (no `Transition.Child`)
- Yellow `ev-yellow/30` border, `rounded-2xl` panel, black/40 backdrop
- Title: "What is an Inform Account?"
- Three `ev-yellow` checkmark bullets:
  - Full Inform access (Compass, Essentials, Read & Rank, Civics Test)
  - Observe-only Connected/Empowered (no Validation Quests or Focused Communities)
  - Yellow gems for Inform activity (no red or teal gems)
- Primary button: `bg-ev-yellow text-ev-black` — "Got it — Create my Inform Account" → `onContinue`
- Secondary link: `text-ev-teal` — "Have an invite code? Create a Connected Account →" → `onUseInviteCode`
- Backdrop click and Esc close via headlessui `Dialog.onClose`

### Login.tsx (`admin/src/pages/Login.tsx`) — additive changes only

All existing login form behavior, error handling, `handleSubmit`, `setAuth`, `useAuthStore`, and `getValidRedirect` logic is unchanged.

**Added:**
1. `import InformConstraintsModal from '../components/InformConstraintsModal'`
2. `const [signupModalOpen, setSignupModalOpen] = useState(false)` state hook
3. `informSignupHref` const (mirrors `signupHref` pattern, targets `/signup/inform`)
4. Replaced single "Don't have an account?" paragraph with two-CTA block:
   - Yellow `bg-ev-yellow` "Create an Account" button → opens modal
   - Small teal "Have an invite code? Create a Connected Account" link → navigates to `/signup`
5. `<InformConstraintsModal>` mounted at page level, outside the card div, with navigate callbacks

**Redirect preservation:**
- `onContinue` → `navigate(informSignupHref)` (includes `?redirect=` when present)
- `onUseInviteCode` → `navigate(signupHref)` (includes `?redirect=` when present)

## Verification Results

- `npx tsc --noEmit`: clean (0 errors)
- `npm run build`: success (3.52s, chunk size warning is pre-existing)
- Grep checks: `InformConstraintsModal` import + JSX present, `/signup/inform` href present, `bg-ev-yellow` CTA present
- `Transition.Child`: not present in InformConstraintsModal (v2 flat API confirmed)

## Deviations from Plan

None — plan executed exactly as written.

## Commits

| Hash | Message |
|------|---------|
| 2e64b45 | feat(67-01): create InformConstraintsModal component |
| 231b027 | feat(67-01): wire CTA and modal into Login.tsx |
