---
phase: 62-onboarding-restyle
plan: 01
subsystem: ui
tags: [react, tailwind, onboarding, v2.0]

requires:
  - phase: 60-design-foundation
    provides: AppNav, StepProgress, AuthCard, AuthInput, PrimaryButton, SecondaryButton components
  - phase: 61-auth-flow-restyle
    provides: SignupPage scaffold pattern (bg-ev-navy + AppNav + StepProgress + AuthCard)

provides:
  - Restyled LocationStep with v2.0 dark chrome (AppNav + StepProgress 2/3)
  - Four address fields immediately visible (no reveal gate)
  - isUpdate=true suppresses AppNav/StepProgress for UpdateLocationPage compatibility

affects: [62-03, UpdateLocationPage]

tech-stack:
  added: []
  patterns: [v2.0 page scaffold pattern applied to LocationStep]

key-files:
  created: []
  modified:
    - app/src/pages/onboarding/steps/LocationStep.tsx

key-decisions:
  - "isUpdate=true suppresses AppNav and StepProgress so UpdateLocationPage keeps its own wrapper"
  - "Back button navigates to /welcome (not suppressed in onboarding path)"
  - "cardContent JSX variable extracted to avoid duplication between isUpdate and !isUpdate render paths"

patterns-established:
  - "isUpdate guard for onboarding-only chrome"

duration: 2min
completed: 2026-04-25
---

# Plan 62-01: LocationStep Restyle Summary

**LocationStep restyled with v2.0 design language — AppNav + StepProgress 2/3 + AuthCard + four AuthInput fields, reveal gate removed, Learn More link removed, isUpdate guard preserves UpdateLocationPage compatibility**

## Accomplishments
- Removed legacy "I understand — show the input" reveal gate and `revealed` state
- Added AppNav + StepProgress (Step 2 of 3) + dark AuthCard wrapper on onboarding path
- Four address fields (street, city, state, ZIP) visible immediately on mount
- isUpdate=true path suppresses AppNav/StepProgress; renders only AuthCard content so UpdateLocationPage's existing wrapper (with its own back button) is not disturbed
- "Learn More" link removed from explanatory copy — one line only
- Pin icon in `w-16 h-16 rounded-full bg-ev-blue/10` badge with Heroicons-style outline path
- SecondaryButton "Back" navigates to /welcome on onboarding path; not rendered in isUpdate path
- `ERROR_MESSAGES` map and `handleSubmit` logic preserved byte-for-byte

## Task Commits

1. **Task 1: Rewrite LocationStep** - `58e3ff2` (feat)

**Plan metadata:** see final docs commit below

## Files Modified
- `app/src/pages/onboarding/steps/LocationStep.tsx` - Full rewrite with v2.0 chrome

## Decisions Made
- isUpdate guard: when true, returns only the `cardContent` AuthCard fragment — no min-h-screen bg-ev-navy outer wrapper, no AppNav, no StepProgress
- cardContent extracted as a JSX variable to share between both render paths without duplication
- Back button: SecondaryButton with `onClick={() => navigate('/welcome')}`, not rendered in isUpdate path

## Deviations from Plan
None — plan executed exactly as written.

## Issues Encountered
None.

## Next Phase Readiness
LocationStep ready for plan 62-03 which simplifies OnboardingPage and wires the WelcomeScreen from Phase 61 into the onboarding flow.
