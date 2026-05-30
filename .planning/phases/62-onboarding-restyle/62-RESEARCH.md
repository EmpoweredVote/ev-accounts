# Phase 62: Onboarding Restyle — Research

**Researched:** 2026-04-25
**Domain:** React onboarding flow restyle (internal codebase audit)
**Confidence:** HIGH — all findings from direct source inspection

---

## Summary

This phase is a pure frontend restyle of the onboarding flow. All findings are based on reading the existing source code directly — no external libraries need to be evaluated. The Phase 60 design system components (AppNav, StepProgress, AuthCard, AuthInput, PrimaryButton) already exist and have defined APIs. The current OnboardingPage uses a string-state machine with four steps (`welcome`, `location`, `location-celebration`, `pseudonym`). After this phase, the sequence collapses to two steps (`location`, `location-celebration`) and the OnboardingPage becomes significantly simpler.

The most important engineering decision in this phase: `PseudonymStep` is the only place that calls `POST /auth/complete-onboarding`. Removing it without relocating that call would break onboarding entirely — users would never have `completedOnboarding: true` set, and `OnboardingGuard` would loop them back to `/onboarding` forever. `LocationCelebrationStep` must absorb that call.

The step counter on `SignupPage` says `1 of 4` in two places — one in `StepProgress` props (`currentStep={1} totalSteps={4}`) and once in display copy (`"Step 1 of 4 — set up your sign-in."`). Both must be updated to `3`.

**Primary recommendation:** Restyle LocationStep and LocationCelebrationStep in-place using the Phase 60 components; transplant the `complete-onboarding` call from PseudonymStep into LocationCelebrationStep; delete WelcomeStep and PseudonymStep files; simplify OnboardingPage to a two-step state machine.

---

## Standard Stack

No new dependencies. All components are from the existing codebase.

### Phase 60 Components (already built, ready to use)

| Component | File | Props | Notes |
|-----------|------|-------|-------|
| `AppNav` | `app/src/components/AppNav.tsx` | `children?: ReactNode` | Sticky header, `bg-ev-navy`, `border-white/10` |
| `StepProgress` | `app/src/components/StepProgress.tsx` | `currentStep: number`, `totalSteps: number` | Progress bar uses `bg-ev-blue` fill |
| `AuthCard` | `app/src/components/AuthCard.tsx` | `children: ReactNode`, `className?: string` | `bg-gray-900 rounded-2xl border border-gray-800 p-6 space-y-5` |
| `AuthInput` | `app/src/components/AuthInput.tsx` | `label`, `value`, `onChange`, `placeholder?`, `error?`, `autoComplete?`, `required?`, `autoFocus?`, `inputProps?`, `inputClassName?` | Error state uses `border-ev-red focus:ring-ev-red`; default uses `border-gray-700 focus:ring-ev-blue` |
| `PrimaryButton` | `app/src/components/PrimaryButton.tsx` | `children`, `onClick?`, `type?`, `disabled?`, `className?` | `bg-ev-blue`, full-width, `disabled:opacity-40` |

### Supporting Components (already exist)

| Component | File | Notes |
|-----------|------|-------|
| `SecondaryButton` | `app/src/components/SecondaryButton.tsx` | `bg-gray-800 border border-gray-700` — useful for Back button if needed |

### Design Tokens (from `app/src/index.css`)

| Token | Value | Usage in this phase |
|-------|-------|---------------------|
| `ev-navy` | `#020618` | Page background (replaces `bg-white dark:bg-ev-black`) |
| `ev-blue` | `#3B82F6` | CTA color (PrimaryButton uses this) |
| `ev-teal` | `#00657C` | Connect feature accent |
| `ev-teal-light` | `#59B0C4` | Light accent |
| `ev-red` | `#FF5740` | Error states |
| `ev-black` | `#1c1c1c` | Body text |

**Key observation:** The old onboarding steps use `bg-white dark:bg-ev-black` as page background. The new v2.0 design language uses `bg-ev-navy`. Phase 62 must switch the OnboardingPage wrapper to `bg-ev-navy`.

---

## Architecture Patterns

### Current Onboarding Structure (as-is)

```
app/src/pages/onboarding/
├── OnboardingPage.tsx           # State machine: welcome → location → location-celebration → pseudonym
└── steps/
    ├── WelcomeStep.tsx          # REMOVE — replaced by /welcome (Phase 61)
    ├── LocationStep.tsx         # RESTYLE
    ├── LocationCelebrationStep.tsx  # RESTYLE + absorb complete-onboarding call
    └── PseudonymStep.tsx        # REMOVE — display_name captured on SignupPage (Phase 61)
```

### Target Onboarding Structure (after Phase 62)

```
app/src/pages/onboarding/
├── OnboardingPage.tsx           # State machine: location → location-celebration only
└── steps/
    ├── LocationStep.tsx         # RESTYLED with AppNav + StepProgress (Step 2 of 3)
    └── LocationCelebrationStep.tsx  # RESTYLED with AppNav + StepProgress (Step 3 of 3) + complete-onboarding call
```

### OnboardingPage State Machine (current → target)

**Current `Step` type:**
```typescript
type Step = 'welcome' | 'location' | 'location-celebration' | 'pseudonym';
```

**Target `Step` type:**
```typescript
type Step = 'location' | 'location-celebration';
```

**Current `initialStep` logic:**
```typescript
function initialStep(locationConsent: boolean): Step {
  if (locationConsent) return 'pseudonym';  // resumption goes to pseudonym
  return 'welcome';
}
```

**Target `initialStep` logic:**
```typescript
function initialStep(locationConsent: boolean): Step {
  // If locationConsent already set, skip location entry — land on celebration
  if (locationConsent) return 'location-celebration';
  return 'location';
}
```
Note: The `location-celebration` resumption case is edge-case (user has location but no `completed_onboarding`). The planner should decide whether `location-celebration` should re-display or immediately call `complete-onboarding` and navigate to `/`. The simpler path: if `locationConsent` is already true, call `complete-onboarding` directly in a `useEffect` and redirect — but this needs the `locationResult` which is not in the store. Alternative: always start at `location` if `locationConsent` is false, and re-run location if true but onboarding incomplete. RECOMMENDATION: if `locationConsent` is already true when OnboardingPage mounts, call `complete-onboarding` in a `useEffect` and navigate to `/` directly.

### Pattern: Wrapping Each Step with AppNav + StepProgress

The Phase 60 pattern (as used in SignupPage) is:

```tsx
// Source: app/src/pages/SignupPage.tsx (verified)
<div className="min-h-screen bg-ev-navy flex flex-col">
  <AppNav />
  <div className="flex-1 px-4 py-8">
    <div className="max-w-sm mx-auto space-y-6">
      <StepProgress currentStep={2} totalSteps={3} />
      <AuthCard>
        {/* step content */}
      </AuthCard>
    </div>
  </div>
</div>
```

Each step component should own its full-page layout following this pattern — not rely on the OnboardingPage wrapper.

### Pattern: LocationStep — "Revealed" UX to Remove

The current LocationStep has a two-phase reveal: a context box first, then a "I understand — show the input →" button that reveals the address form (`revealed` state). The CONTEXT.md decisions remove this — the form is always visible. The `revealed` state and the reveal button should be removed entirely.

The `isUpdate` prop controls alternative headings for the settings flow. It should remain on the component so UpdateLocationPage continues to work — only the onboarding-specific reveal animation is removed.

### Pattern: LocationCelebrationStep — New Responsibility

Currently `LocationCelebrationStep`:
1. Receives a `LocationResult` prop
2. Shows district data
3. Calls `onContinue` which advances to PseudonymStep

After Phase 62:
1. Receives a `LocationResult` prop (keep — it still may be used for display, though the CONTEXT.md design is milestone items, not district list)
2. Shows three milestone items (not district list)
3. Calls `POST /auth/complete-onboarding`
4. Calls `updateUser({ completedOnboarding: true })`
5. Navigates to `/` (or calls an `onComplete` callback that OnboardingPage handles)

The current `onContinue` prop signature works if OnboardingPage calls `handleOnboardingComplete`. The `LocationCelebrationStep` needs access to `apiFetch` and `useAuthStore` — these are already used elsewhere in the onboarding steps.

### Anti-Patterns to Avoid

- **Forgetting to remove WelcomeStep import from OnboardingPage.tsx.** The Step type and the conditional rendering both import it — removing just the render block leaves a dead import.
- **Not updating the `initialStep` function.** The old logic sends `locationConsent=true` users to `pseudonym`. After the removal that step doesn't exist.
- **Leaving `PseudonymStep` files in place without removing imports.** OnboardingPage imports all four step components — all four imports must be cleaned up.
- **Not relocating `complete-onboarding` call.** This is the most dangerous omission. Without it, `completedOnboarding` stays false, `OnboardingGuard` redirects to `/onboarding`, and the user is stuck in a loop.
- **Using old `bg-white dark:bg-ev-black` wrapper.** Onboarding steps currently use the old background. Phase 62 adopts `bg-ev-navy` to match v2.0 design language.
- **Keeping the "I understand — show the input" reveal on LocationStep.** CONTEXT.md is explicit: location form is always visible (no skip/reveal path). Remove `revealed` state and the context block's button.
- **Keeping `onContinue` pointing to pseudonym.** `LocationCelebrationStep.onContinue` must navigate to `/` (or equivalent) — not to a removed step.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Step progress bar | Custom CSS progress | `StepProgress` component | Already built, matches design system |
| Address fields | Raw `<input>` elements | `AuthInput` component | Error state, label, ring style all pre-built |
| CTA button | Raw `<button>` | `PrimaryButton` | Consistent `ev-blue` style, disabled state |
| Page card container | Custom div styling | `AuthCard` | `bg-gray-900` card pattern already defined |
| Nav header | Custom header | `AppNav` | Sticky, logo, consistent across auth pages |

**Key insight:** All visual building blocks are available. The work is wiring + copy, not component construction.

---

## Common Pitfalls

### Pitfall 1: complete-onboarding call lost in transition

**What goes wrong:** PseudonymStep is deleted. `LocationCelebrationStep.onContinue` now calls `handleOnboardingComplete` which navigates to `/`. But `completedOnboarding` is never set to `true`. OnboardingGuard sees `!user.completedOnboarding` and redirects back to `/onboarding`. Infinite loop.

**Why it happens:** The `complete-onboarding` API call is buried inside PseudonymStep — easy to miss when removing it.

**How to avoid:** `LocationCelebrationStep` must call `POST /auth/complete-onboarding` AND `updateUser({ completedOnboarding: true })` before navigating forward. These were in PseudonymStep lines 30–31.

**Warning signs:** After testing, user lands at `/onboarding` repeatedly instead of dashboard.

### Pitfall 2: LocationResult not available for resumption path

**What goes wrong:** If `locationConsent` is already `true` when OnboardingPage mounts (user left mid-flow), the `initialStep` function returns `'location-celebration'`. But `locationResult` state is `null` because the user never ran location in this session. `LocationCelebrationStep` receives `result={null}` and crashes or shows blank district data.

**Why it happens:** `locationResult` is local state in `OnboardingPage` — it's not persisted.

**How to avoid:** The updated OnboardingPage should detect `locationConsent === true` on mount and either (a) call `complete-onboarding` directly and navigate to `/`, or (b) restart at `location` step and prompt re-entry. Option (a) is cleaner for this case. The `LocationCelebrationStep` in the normal flow always receives a fresh `LocationResult` from the just-completed location API call.

### Pitfall 3: StepProgress color uses ev-blue, not ev-teal

**What goes wrong:** Developers apply `text-ev-teal` to the progress bar fill, expecting Connect brand color. But `StepProgress` uses `bg-ev-blue` (v2.0 design token `#3B82F6`). If someone overrides this to teal, it visually diverges from SignupPage's bar.

**Why it happens:** The Connect feature color is ev-teal, but v2.0 auth/onboarding uses ev-blue for CTAs and progress.

**How to avoid:** Do not override StepProgress's fill color. Use the component as-is — it matches SignupPage exactly.

### Pitfall 4: SignupPage counter updated in only one place

**What goes wrong:** `SignupPage` sets `totalSteps={4}` on `StepProgress` but also has display copy `"Step 1 of 4 — set up your sign-in."` in the `AuthCard`. Both must change. Updating only the `StepProgress` prop leaves mismatched copy.

**Why it happens:** Two separate places encoding the same number.

**How to avoid:** Search for `"4"` and `"1 of 4"` in SignupPage.tsx. Change both: `totalSteps={3}` and `"Step 1 of 3 — set up your sign-in."`.

### Pitfall 5: LocationStep isUpdate prop and UpdateLocationPage compatibility

**What goes wrong:** UpdateLocationPage uses `<LocationStep isUpdate onSuccess={handleSuccess} />`. If the LocationStep restyle removes or renames the `isUpdate` prop, UpdateLocationPage breaks.

**Why it happens:** LocationStep serves double duty — onboarding and settings update.

**How to avoid:** Keep the `isUpdate` prop. Only change the onboarding-specific heading/copy/layout. The `isUpdate=true` path can retain its current minimal heading (or get updated copy separately).

---

## Code Examples

### AuthInput with error — verified API

```tsx
// Source: app/src/components/AuthInput.tsx (verified)
<AuthInput
  label="Street address"
  value={street}
  onChange={setStreet}
  placeholder="123 Main St"
  autoComplete="address-line1"
  required
  autoFocus
  error={fieldErrors.street}
/>
```

### StepProgress usage — verified

```tsx
// Source: app/src/pages/SignupPage.tsx (verified)
<StepProgress currentStep={2} totalSteps={3} />
// Renders: "Step 2 of 3  67%"  with progress bar at 67%
```

### PrimaryButton with loading state — verified

```tsx
// Source: app/src/pages/SignupPage.tsx (verified)
<PrimaryButton type="submit" disabled={loading}>
  {loading ? 'Finding your community…' : 'Continue'}
</PrimaryButton>
```

### AppNav + AuthCard page scaffold — verified

```tsx
// Source: app/src/pages/SignupPage.tsx (verified)
<div className="min-h-screen bg-ev-navy flex flex-col">
  <AppNav />
  <div className="flex-1 px-4 py-8">
    <div className="max-w-sm mx-auto space-y-6">
      <StepProgress currentStep={N} totalSteps={3} />
      <AuthCard>
        {/* content */}
      </AuthCard>
    </div>
  </div>
</div>
```

### complete-onboarding call pattern — from PseudonymStep (must move to LocationCelebrationStep)

```tsx
// Source: app/src/pages/onboarding/steps/PseudonymStep.tsx lines 30-31
await apiFetch('/auth/complete-onboarding', { method: 'POST' });
updateUser({ completedOnboarding: true });
```

### LocationStep API call — verified

```tsx
// Source: app/src/pages/onboarding/steps/LocationStep.tsx
const result = await apiFetch<LocationResult>('/connect/set-location', {
  method: 'POST',
  body: JSON.stringify({ address, ...(isUpdate && { force: true }) }),
});
```

---

## State of the Art

| Old Approach | Current Approach | Changed | Impact |
|---|---|---|---|
| WelcomeStep in onboarding router | `/welcome` (WelcomeScreen, Phase 61) | Phase 61 | Onboarding starts at LocationStep |
| PseudonymStep collects display_name | SignupPage fifth field (Phase 61 migration 071) | Phase 61 | PseudonymStep is redundant |
| 4-step journey (welcome/location/celebration/pseudonym) | 2-step onboarding + 1-step signup = 3 total | Phase 62 | StepProgress totals change |
| `bg-white dark:bg-ev-black` page background | `bg-ev-navy` | Phase 60 design system | All pages use dark navy base |
| Raw `<button>` and `<input>` in steps | AuthInput, PrimaryButton, AuthCard | Phase 60 components | Consistent styling |

---

## Open Questions

1. **Resumption path when locationConsent is already true**
   - What we know: Old code sent `locationConsent=true` to `pseudonym`. That step is gone.
   - What's unclear: Should we (a) skip directly to complete-onboarding+redirect, or (b) send user back to LocationStep to re-enter address?
   - Recommendation: Option (a) — call `complete-onboarding` in a `useEffect` on mount when `locationConsent` is already true and navigate to `/`. The user has already set location; there's no value in re-entering it.

2. **Back button on LocationStep**
   - What we know: CONTEXT.md marks this as Claude's Discretion — "whether the Back button on LocationStep navigates to signup or is hidden."
   - What's unclear: Phase 61 SignupPage is at `/signup`. After email confirmation + login, the user lands at `/onboarding`. Going "back" to `/signup` is not meaningful (account already created).
   - Recommendation: Hide the Back button on LocationStep during the onboarding flow. The `isUpdate` path (UpdateLocationPage) already has its own Back button.

3. **LocationCelebrationStep — district data or milestone items only?**
   - What we know: CONTEXT.md specifies three milestone confirmation items. The current component shows district data from `LocationResult`.
   - What's unclear: Does the new design show districts at all, or only the three milestone items?
   - Recommendation: Based on CONTEXT.md, the new design shows ONLY the three milestone items and green checkmarks. District data display is removed from the celebration step. The `LocationResult` prop can be kept for potential future use but the district list UI is replaced.

---

## Sources

### Primary (HIGH confidence)

All findings are from direct source file inspection (no external research needed for this phase):

- `app/src/pages/onboarding/OnboardingPage.tsx` — step machine, state, navigation
- `app/src/pages/onboarding/steps/WelcomeStep.tsx` — confirmed for deletion
- `app/src/pages/onboarding/steps/PseudonymStep.tsx` — complete-onboarding call location
- `app/src/pages/onboarding/steps/LocationStep.tsx` — current API, revealed state, error messages
- `app/src/pages/onboarding/steps/LocationCelebrationStep.tsx` — current design, props
- `app/src/components/AppNav.tsx` — confirmed props API
- `app/src/components/StepProgress.tsx` — confirmed props API, ev-blue fill
- `app/src/components/AuthCard.tsx` — confirmed props API
- `app/src/components/AuthInput.tsx` — confirmed full props API including error state
- `app/src/components/PrimaryButton.tsx` — confirmed props API
- `app/src/components/SecondaryButton.tsx` — available for Back button
- `app/src/pages/SignupPage.tsx` — confirmed `totalSteps={4}` and `"Step 1 of 4"` copy (both need updating)
- `app/src/pages/WelcomeScreen.tsx` — confirmed Phase 61 WelcomeScreen at `/welcome`
- `app/src/App.tsx` — confirmed `/welcome` route, `/onboarding` route, OnboardingGuard usage
- `app/src/components/OnboardingGuard.tsx` — confirmed `completedOnboarding` check logic
- `app/src/store/authStore.ts` — confirmed `updateUser` and `completedOnboarding` field
- `app/src/index.css` — confirmed color tokens including `ev-navy` and `ev-blue`
- `backend/src/routes/auth.ts` — confirmed `complete-onboarding` endpoint contract

---

## Metadata

**Confidence breakdown:**
- Current code state: HIGH — all files read directly
- Component APIs: HIGH — read from source
- complete-onboarding contract: HIGH — read from backend route
- Resumption path recommendation: MEDIUM — inferred from logic, no explicit spec

**Research date:** 2026-04-25
**Valid until:** Until any of the source files above change (stable — no external deps)
