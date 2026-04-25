---
phase: 62-onboarding-restyle
plan: 03
subsystem: ui
tags: [react, tailwind, onboarding, v2.0, cleanup]

requires:
  - phase: 62-01
    provides: Restyled LocationStep with StepProgress 2-of-3
  - phase: 62-02
    provides: Restyled LocationCelebrationStep with onComplete prop and complete-onboarding call

provides:
  - Simplified OnboardingPage: two-step state machine (location → location-celebration)
  - Resumption useEffect handles locationConsent=true edge case silently
  - SignupPage step counter updated to 1-of-3 in both StepProgress prop and inline copy
  - WelcomeStep.tsx and PseudonymStep.tsx deleted from repo

affects: []

tech-stack:
  added: []
  patterns: [resumption useEffect pattern for interrupted onboarding]

key-files:
  created: []
  modified:
    - app/src/pages/onboarding/OnboardingPage.tsx
    - app/src/pages/SignupPage.tsx
  deleted:
    - app/src/pages/onboarding/steps/WelcomeStep.tsx
    - app/src/pages/onboarding/steps/PseudonymStep.tsx

key-decisions:
  - "Resumption path: useEffect silently calls complete-onboarding when locationConsent=true on mount, then navigates to /"
  - "handleOnboardingComplete only navigates — complete-onboarding is LocationCelebrationStep's responsibility"
  - "Resumption fallback: if complete-onboarding fails, setResuming(false) so user lands on LocationStep and can re-submit"
  - "OnboardingPage wrapper div removed — step components own their own bg-ev-navy backgrounds"

patterns-established:
  - "Resumption useEffect: detect partial completion state on mount, finish silently via API, then navigate"

duration: 2min
completed: 2026-04-25
---

# Plan 62-03: OnboardingPage Simplification Summary

**OnboardingPage collapsed to two-step flow, legacy WelcomeStep and PseudonymStep deleted, SignupPage counter updated to 1-of-3 — onboarding journey is now a consistent 3-step sequence**

## Accomplishments
- OnboardingPage rewritten as two-step state machine (`location` → `location-celebration`) — dropped `'welcome'` and `'pseudonym'` steps entirely
- Resumption useEffect handles edge case: `locationConsent=true` + `completedOnboarding=false` on mount — calls `POST /auth/complete-onboarding` silently and navigates to `/`; falls back to LocationStep if the call fails
- SignupPage `StepProgress totalSteps={4}` → `totalSteps={3}` and inline copy `Step 1 of 4` → `Step 1 of 3`
- WelcomeStep.tsx and PseudonymStep.tsx removed via `git rm` with zero dangling references
- Full build passes: `npm run build` — 61 modules, 245.89 kB JS bundle

## Task Commits

1. **Task 1: Simplify OnboardingPage** - `7263d34` (feat)
2. **Task 2: Fix SignupPage counter** - `ad74c2e` (fix)
3. **Task 3: Delete legacy files** - `e687dd6` (chore)

## Files Modified/Deleted
- `app/src/pages/onboarding/OnboardingPage.tsx` - Simplified state machine, resumption useEffect, fragment wrapper
- `app/src/pages/SignupPage.tsx` - Step counter 4 → 3 (both StepProgress prop and visible copy)
- `app/src/pages/onboarding/steps/WelcomeStep.tsx` - DELETED (superseded by WelcomeScreen.tsx at /welcome, Phase 61)
- `app/src/pages/onboarding/steps/PseudonymStep.tsx` - DELETED (display_name absorbed by SignupPage Phase 61; complete-onboarding absorbed by LocationCelebrationStep plan 02)

## Decisions Made
- `handleOnboardingComplete` only navigates — `complete-onboarding` is LocationCelebrationStep's job (prevents double-call)
- Resumption useEffect falls back to LocationStep if `complete-onboarding` fails — user can re-submit address and celebration step will re-trigger the call
- Outer wrapper div removed from OnboardingPage — step components own their own `bg-ev-navy` backgrounds so a competing `bg-white dark:bg-ev-black` wrapper was wrong

## Deviations from Plan
None — plan executed exactly as written.

## Issues Encountered
None.

## Next Phase Readiness
Phase 62 execution complete. All 3 plans (62-01 LocationStep, 62-02 LocationCelebrationStep, 62-03 OnboardingPage cleanup) are done.

Full signup → onboarding journey: 1/3 (SignupPage) → magic-link confirmation (out of band) → 2/3 (LocationStep) → 3/3 (LocationCelebrationStep) → `/` (dashboard).

Next: Phase 63 — Profile Page + Activity Feed.
