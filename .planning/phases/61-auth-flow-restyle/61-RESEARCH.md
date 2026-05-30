# Phase 61: Auth Flow Restyle - Research

**Researched:** 2026-04-25
**Domain:** React frontend restyle, Tailwind v4, auth screen UX, routing
**Confidence:** HIGH — all findings from live codebase inspection; no external sources needed

---

## Summary

Phase 61 is a pure frontend restyle of three existing screens (LoginPage, SignupPage including its "check email" state) plus one new screen (WelcomeScreen at `/welcome`). The backend contract is unchanged. Every component needed for the restyle — AuthCard, AuthInput, PrimaryButton, SecondaryButton, AppNav, StepProgress — was built in Phase 60 and is confirmed VERIFIED and ready to use.

The current auth screens use the old v1.x palette: `bg-ev-black` page background, `bg-ev-teal-light` primary buttons, `focus:ring-ev-teal-light` on inputs, raw `<input>` and `<button>` elements with no shared components. Phase 61 replaces all of this with `bg-ev-navy` backgrounds, `PrimaryButton` (blue CTA), `AuthInput` (dark field, blue focus ring), and `AuthCard` wrapper, plus adds `AppNav` to SignupPage and LoginPage.

The primary routing change is: add `/welcome` route in `App.tsx` pointing to a new `WelcomeScreen` page. The `*` catch-all currently redirects unknown routes to `/` (dashboard). After Phase 61, `/welcome` must be a public route accessible before auth.

**Primary recommendation:** Implement as four atomic tasks in sequence: (1) WelcomeScreen new page + route, (2) SignupPage restyle, (3) check-email confirmation screen restyle (lives inside SignupPage as the `done` state), (4) LoginPage restyle. Each task is independent because the pages don't share state. WelcomeScreen is highest risk because it's a new file + new route.

---

## Standard Stack

### Core (all Phase 60 deliverables — already built, verified, and ready)

| Component | File | Purpose | Phase 61 Usage |
|-----------|------|---------|----------------|
| `AuthCard` | `app/src/components/AuthCard.tsx` | Dark rounded card wrapper — `bg-gray-900 rounded-2xl border border-gray-800 p-6 space-y-5` | Wrap signup and login form bodies; WelcomeScreen card |
| `AuthInput` | `app/src/components/AuthInput.tsx` | Controlled labeled input with dark style and blue focus ring | Replace all raw `<input>` elements on SignupPage and LoginPage |
| `PrimaryButton` | `app/src/components/PrimaryButton.tsx` | Blue CTA button — `bg-ev-blue text-white`, full-width | Replace teal CTA buttons on SignupPage, LoginPage, check-email screen |
| `SecondaryButton` | `app/src/components/SecondaryButton.tsx` | Dark secondary button — `bg-gray-800 border border-gray-700` | "Continue exploring" on WelcomeScreen |
| `AppNav` | `app/src/components/AppNav.tsx` | Sticky navy top nav with logo + "Civic Platform" + right slot | Add to SignupPage and LoginPage layouts |
| `StepProgress` | `app/src/components/StepProgress.tsx` | "Step X of Y" + percentage + blue bar | SignupPage only — `currentStep={1} totalSteps={4}` |

### Design Tokens (in `app/src/index.css` — already added in Phase 60)

| Token | Hex | Phase 61 Usage |
|-------|-----|----------------|
| `ev-navy` | `#020618` | Page background (`bg-ev-navy min-h-screen`) on all auth screens |
| `ev-blue` | `#3B82F6` | Inherited through PrimaryButton; also `ring-ev-blue` in AuthInput |
| `ev-teal-light` | `#59B0C4` | Retained only for "sign in" / "create account" text links (no restyle needed on links) |
| `ev-red` | `#FF5740` | Error messages (already in AuthInput) |

### No New Dependencies

Phase 61 requires zero new packages. All styling is done with existing Tailwind tokens and Phase 60 components.

---

## Architecture Patterns

### Current Page Structure (what exists before Phase 61)

```
LoginPage.tsx
  - Full page: bg-ev-black min-h-screen
  - Wordmark header: hardcoded h1 "empowered.vote"
  - Card: raw div bg-gray-900 rounded-2xl border border-gray-800 p-6
  - Inputs: raw <input> with focus:ring-ev-teal-light
  - Button: raw <button> with bg-ev-teal-light text-ev-black
  - Link: "Have an invite code? Create account" → /signup
  - Redirect: ?redirect= query param preserved through login → cross-app token hash

SignupPage.tsx
  - Full page: bg-ev-black min-h-screen
  - Wordmark header: hardcoded h1 "empowered.vote"
  - Card: raw div bg-gray-900 (same pattern as login)
  - Fields: email, password, legal_name, invite_code (NO display_name in API)
  - "One Account, One Voice" info box (teal-light palette)
  - Check-email screen: conditional render when done === true (separate JSX block)
  - Redirect: ?redirect= param forwarded to /login?redirect= after signup
```

### Target Page Structure (after Phase 61)

```
WelcomeScreen.tsx  (new file at app/src/pages/WelcomeScreen.tsx)
  - bg-ev-navy min-h-screen flex items-center justify-center
  - AppNav (no children — no right-slot content on welcome screen)
  - AuthCard (max-w-sm centered)
    - Heading: "Join to participate"
    - Three options: PrimaryButton "Create account" → /signup
                     SecondaryButton "Log in" → /login
                     text link / ghost "Continue exploring" → / (dashboard redirect)
  - Copy: invitational framing, zero pressure language

SignupPage.tsx  (restyle existing)
  - AppNav at top (no children)
  - Below nav: px-4 py-8 max-w-sm mx-auto content column
  - StepProgress currentStep={1} totalSteps={4}
  - AuthCard wrapping:
    - heading "Create your account"
    - AuthInput for email
    - AuthInput type="password" for password
    - AuthInput for legal_name with hint text below (AUTH-03)
    - AuthInput for invite_code with shield icon + hint text below (AUTH-04)
    - PrimaryButton type="submit" "Create Account"
  - "Already have an account? Sign in" link below card

  done === true → CheckEmailScreen (can remain inline or extract):
  - AppNav
  - Centered card: email address shown, magic-link explanation, "Sign in" link

LoginPage.tsx  (restyle existing)
  - AppNav at top (no children)
  - Below nav: centered column
  - AuthCard wrapping:
    - AuthInput for email
    - AuthInput type="password" for password
    - PrimaryButton type="submit" "Log in"
    - error display
  - "Already have account? Sign In" link below card (AUTH-06 copy)
```

### New Route Registration

App.tsx currently has no `/welcome` route. The catch-all `<Route path="*" element={<Navigate to="/" replace />}` would redirect `/welcome` to `/`. Adding `/welcome` requires:

```tsx
// In App.tsx <Routes>:
<Route path="/welcome" element={<WelcomeScreen />} />
<Route path="/login" element={<LoginPage />} />
<Route path="/signup" element={<SignupPage />} />
```

The `/welcome` route is public (no AuthGuard). It sits parallel to `/login` and `/signup`.

### "Continue exploring" Target

REQUIREMENTS.md AUTH-01 says "Continue exploring" — but the InformLanding at `/` for unauthenticated users is a Phase 64 deliverable. As of Phase 61, the root `/` route is protected by `AuthGuard`, which redirects unauthenticated users to `https://login.empowered.vote/login`. So "Continue exploring" cannot link to `/` in Phase 61 without AuthGuard blocking it.

Resolution options:
1. Link "Continue exploring" to an external URL (e.g., `https://empowered.vote` or another public page) — simple but leaves the app.
2. Navigate to `/login` with a note — wrong UX.
3. Navigate to `/welcome` itself (no-op link) — wrong.
4. Accept the limitation: Phase 64 wires up the real InformLanding. Phase 61 can render "Continue exploring" as a `<Link to="/">` — when unauthenticated it will bounce to `login.empowered.vote`. Not ideal but defers the proper behavior to Phase 64 without breaking anything.

**Recommendation:** Planner should note this explicitly. "Continue exploring" in Phase 61 can navigate to `/` (which AuthGuard will redirect unauthenticated users to `login.empowered.vote/login`). Phase 64's InformLanding work makes this properly explorable for Inform-tier users. Document the known behavior gap.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dark card wrapper | `bg-gray-900 rounded-2xl ...` inline div | `AuthCard` from Phase 60 | Already built; max-width is set by parent, not card |
| Labeled dark input | Raw `<input>` with inline styles | `AuthInput` from Phase 60 | Handles label, error state, blue focus ring, autoFocus, pass-through props |
| Blue CTA button | Raw `<button>` with `bg-ev-teal-light` | `PrimaryButton` from Phase 60 | Already handles disabled, loading state pattern |
| Dark secondary button | Custom ghost button | `SecondaryButton` from Phase 60 | Consistent dark button for "Log in" on WelcomeScreen |
| Progress bar + step counter | Custom implementation | `StepProgress` from Phase 60 | Defensive math, right copy, blue fill — done |
| Top nav shell | Inline `<header>` | `AppNav` from Phase 60 | Logo, wordmark, right slot — done; `bg-ev-navy` matches the v2.0 spec |
| Inline SVG shield icon | Custom SVG draw | Heroicons SVG path inline | Existing codebase pattern is inline SVG paths (no icon library installed) |

**Key insight:** Every visual component for this restyle is pre-built by Phase 60. This phase is almost entirely composition + copy changes.

---

## Common Pitfalls

### Pitfall 1: Adding display_name to signup form and API call

**What goes wrong:** AUTH-02 requirement text says "AuthInput fields for email, password, display name, legal name, and invite code." The backend `POST /api/auth/signup` Zod schema accepts only `email`, `password`, `legal_name`, `invite_code` (and optional `guest_state`). Adding `display_name` to the signup API call will be silently ignored by the backend — it's not validated, not passed to the `signup_with_invite` RPC, and not stored. Display name is captured in `PseudonymStep` during onboarding (`PATCH /api/account/me` with `{ display_name }`).

**Why it happens:** The requirement text is aspirational / design-future-looking. The backend contract is the truth.

**How to avoid:** Do NOT add a display_name field to the SignupPage form or the API call. The field can be mentioned in requirement interpretation notes, but the planner should omit it from implementation. Onboarding (Phase 62) handles display name capture.

**Warning signs:** If a task adds `display_name` to `handleSubmit` body JSON and the API call succeeds without error — that's because the backend silently strips unknown fields, not because it was stored.

### Pitfall 2: Using bg-ev-black instead of bg-ev-navy on page backgrounds

**What goes wrong:** The existing pages use `bg-ev-black` (#1c1c1c — near-black warm dark). The v2.0 design uses `bg-ev-navy` (#020618 — almost pure dark blue-black). They look similar in some screen calibrations but are distinct tokens.

**Why it happens:** Muscle memory from existing code; both look "very dark" in diff review.

**How to avoid:** Every `min-h-screen` wrapper on Phase 61 pages must use `bg-ev-navy`, not `bg-ev-black`. Verify in a browser — `ev-navy` has a blue tint that `ev-black` lacks.

**Warning signs:** The page background matches the old signin screens exactly (warm dark brown-black vs. blue-black).

### Pitfall 3: AuthInput onChange signature mismatch

**What goes wrong:** `AuthInput.onChange` has signature `(value: string) => void` — it passes the string value directly, NOT the event. Existing page code uses `onChange={(e) => setEmail(e.target.value)}` pattern (React event). Mixing these will cause TypeScript errors or runtime `undefined` values.

**Why it happens:** AuthInput extracts the value internally (`onChange={(e) => onChange(e.target.value)}`). The consumer receives the string directly.

**How to avoid:** When migrating existing `<input onChange={(e) => setEmail(e.target.value)}>` to `<AuthInput onChange={(value) => setEmail(value)}>`, use the string directly. TypeScript will catch this if strict mode is on (and it is).

**Warning signs:** `npx tsc --noEmit` error: `Argument of type '(e: React.ChangeEvent<HTMLInputElement>) => void' is not assignable to parameter of type '(value: string) => void'`.

### Pitfall 4: WelcomeScreen missing from App.tsx routes

**What goes wrong:** Creating `WelcomeScreen.tsx` without adding a `<Route path="/welcome">` in `App.tsx` means the route doesn't exist. The catch-all `*` redirects to `/`, which hits AuthGuard, which redirects to `login.empowered.vote`. The WelcomeScreen is unreachable.

**Why it happens:** File creation and route registration are separate steps; it's easy to commit only the component.

**How to avoid:** The task that creates `WelcomeScreen.tsx` must also add the route in `App.tsx` as part of the same plan step.

**Warning signs:** Navigating to `/welcome` redirects to `login.empowered.vote/login` instead of rendering the welcome card.

### Pitfall 5: InviteCode field losing font-mono and tracking-wider

**What goes wrong:** The current invite code `<input>` has `font-mono tracking-wider` which makes invite codes like `XXXX-XXXX` readable. Migrating to `AuthInput` without passing these via `inputProps` loses the visual treatment.

**Why it happens:** `AuthInput` doesn't know it's rendering an invite code. The base styling omits mono font.

**How to avoid:** Use `AuthInput`'s `inputProps` escape hatch: `<AuthInput inputProps={{ className: 'font-mono tracking-wider', spellCheck: false }} ... />`. Note: `inputProps.className` will REPLACE the internal className unless the component merges it. Looking at the current `AuthInput` implementation, `inputProps` is spread via `{...inputProps}` BEFORE the hardcoded `className`. This means `inputProps.className` from the consumer CANNOT override the internal className — they're in different positions and `className` in `{...inputProps}` is overridden by the explicit `className` prop that follows.

**Actual resolution:** The `AuthInput` component spreads `inputProps` first, then sets `className` explicitly. So `inputProps.className` is overridden. To add `font-mono tracking-wider`, the task must either: (a) add a `className` prop to `AuthInput` that merges with the base input class, OR (b) handle the invite code input as a raw `<div>` with a custom wrapper that replicates AuthInput styling manually. Option (a) is cleaner — `AuthInput` already accepts an optional `inputProps` spread, the simplest fix is to ensure the `AuthInput` component's `className` construction joins `inputProps.className` if provided, using a template literal.

**Warning signs:** Invite code field renders in proportional font, `XXXX-XXXX` looks cramped without the mono-spaced alignment.

### Pitfall 6: Forgetting the ?redirect= query param in WelcomeScreen links

**What goes wrong:** When `login.empowered.vote` links to `/welcome?redirect=...`, the WelcomeScreen's "Create account" and "Log in" buttons need to forward the `redirect` query param to `/signup?redirect=...` and `/login?redirect=...` respectively. If the WelcomeScreen discards the param, the post-auth redirect to the calling app breaks.

**Why it happens:** New component, easy to forget that the redirect param propagation pattern exists.

**How to avoid:** Use `useLocation()` or `window.location.search` to read the current `?redirect=` param and forward it to the `/signup` and `/login` Link destinations. The same `getValidatedRedirectUrl()` utility function from LoginPage/SignupPage can be extracted and shared, or simply duplicated.

**Warning signs:** Signing up from WelcomeScreen works but doesn't redirect back to the calling app after login.

---

## Code Examples

### WelcomeScreen structure

```tsx
// app/src/pages/WelcomeScreen.tsx
// Pattern: public route, no auth required, invitational copy
import { Link, useSearchParams } from 'react-router-dom';
import { AppNav } from '../components/AppNav';
import { AuthCard } from '../components/AuthCard';
import { PrimaryButton } from '../components/PrimaryButton';
import { SecondaryButton } from '../components/SecondaryButton';

export default function WelcomeScreen() {
  const [searchParams] = useSearchParams();
  const redirect = searchParams.get('redirect');
  const redirectSuffix = redirect ? `?redirect=${encodeURIComponent(redirect)}` : '';

  return (
    <div className="min-h-screen bg-ev-navy flex flex-col">
      <AppNav />
      <div className="flex-1 flex items-center justify-center px-4 py-12">
        <div className="w-full max-w-sm">
          <AuthCard>
            {/* heading, copy, three options */}
            <Link to={`/signup${redirectSuffix}`}>
              <PrimaryButton>Create account</PrimaryButton>
            </Link>
            <Link to={`/login${redirectSuffix}`}>
              <SecondaryButton>Log in</SecondaryButton>
            </Link>
            {/* "Continue exploring" text link */}
          </AuthCard>
        </div>
      </div>
    </div>
  );
}
```

### SignupPage structure (post-restyle)

```tsx
// Pattern: AppNav + StepProgress outside the card, AuthCard wraps form
import { AppNav } from '../components/AppNav';
import { AuthCard } from '../components/AuthCard';
import { AuthInput } from '../components/AuthInput';
import { PrimaryButton } from '../components/PrimaryButton';
import { StepProgress } from '../components/StepProgress';

// Page layout:
// <div className="min-h-screen bg-ev-navy flex flex-col">
//   <AppNav />
//   <div className="flex-1 px-4 py-8">
//     <div className="max-w-sm mx-auto space-y-6">
//       <StepProgress currentStep={1} totalSteps={4} />
//       <AuthCard>
//         {/* form fields */}
//       </AuthCard>
//       {/* "Already have an account?" link */}
//     </div>
//   </div>
// </div>
```

### AuthInput with invite code mono styling

The current `AuthInput` component spreads `inputProps` before setting `className`:
```tsx
// From AuthInput.tsx line 39-48:
<input
  {...inputProps}                          // spread first
  type={type}
  value={value}
  onChange={(e) => onChange(e.target.value)}
  placeholder={placeholder}
  autoComplete={autoComplete}
  required={required}
  autoFocus={autoFocus}
  className={`w-full bg-gray-800 border ${borderClass} rounded-xl px-4 py-3 text-white ...`}
  // ↑ explicit className OVERRIDES inputProps.className
/>
```

To support mono font for invite code: the task must modify `AuthInput` to merge `inputProps.className` into the base className string, OR the invite code field can be rendered as a raw `<input>` with the same Tailwind classes applied manually. **Recommendation for planner:** extend `AuthInput` to accept an `inputClassName?: string` prop that appends to the base className. One-line change; unblocks Phase 61 and future phases cleanly.

### Route registration in App.tsx

```tsx
// Add before the AuthGuard block:
<Route path="/welcome" element={<WelcomeScreen />} />
<Route path="/login" element={<LoginPage />} />
<Route path="/signup" element={<SignupPage />} />
```

No guard needed — `/welcome` is a public page.

### Shield icon inline SVG (codebase pattern)

```tsx
// Pattern: inline SVG, no icon library. Heroicons shield-check path:
<svg className="w-4 h-4 text-ev-blue" fill="none" stroke="currentColor" strokeWidth={2} viewBox="0 0 24 24">
  <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75m-3-7.036A11.959 11.959 0 013.598 6 11.99 11.99 0 003 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285z" />
</svg>
```

---

## Exact Component APIs (Phase 60 verified)

The planner needs to know the exact call signatures:

**AuthCard**
```tsx
<AuthCard className?={string}>
  {children}
</AuthCard>
```
Note: `max-w-sm` is NOT inside AuthCard — parent page sets width.

**AuthInput**
```tsx
<AuthInput
  label={string}                          // required
  type?={string}                          // default "text"
  value={string}                          // required, controlled
  onChange={(value: string) => void}      // receives string, not event
  placeholder?={string}
  error?={string}                         // shows red error below input
  autoComplete?={string}
  required?={boolean}
  autoFocus?={boolean}
  inputProps?={Omit<InputHTMLAttributes, ...>}  // escape hatch; className is OVERRIDDEN
/>
```

**PrimaryButton**
```tsx
<PrimaryButton
  type?={'button'|'submit'|'reset'}       // default "button"
  onClick?={()=>void}
  disabled?={boolean}
  className?={string}
>
  {children}
</PrimaryButton>
```

**SecondaryButton** — identical prop shape to PrimaryButton.

**StepProgress**
```tsx
<StepProgress
  currentStep={number}    // 1-indexed; clamped defensively
  totalSteps={number}     // total steps; clamped to min 1
/>
```

**AppNav**
```tsx
<AppNav>
  {children?}  // optional right slot
</AppNav>
```
Renders sticky `bg-ev-navy` header with logo + "Civic Platform" wordmark. Logo is `app/public/logo.png` (12087 bytes, confirmed in Phase 60 verification).

---

## State of the Art

| Old Approach | v2.0 Approach | What Changes |
|--------------|---------------|--------------|
| `bg-ev-black` page background | `bg-ev-navy` page background | Palette shift — apply to ALL Phase 61 pages |
| `bg-ev-teal-light text-ev-black` CTA button | `PrimaryButton` (bg-ev-blue) | Semantic shift from teal to blue; composable component |
| `focus:ring-ev-teal-light` on inputs | `focus:ring-ev-blue` via `AuthInput` | Already baked into AuthInput; no manual class needed |
| Hardcoded `<h1>empowered.vote</h1>` wordmark | `AppNav` with logo image + "Civic Platform" | Brand upgrade from text to image + wordmark |
| No step indicator on signup | `StepProgress currentStep={1} totalSteps={4}` | Establishes 4-step signup funnel context |
| No WelcomeScreen — direct /login and /signup | `/welcome` with WelcomeScreen + 3 options | New entry point for invitational framing |
| "Check your email" inline teal button | `PrimaryButton` + AuthCard styled screen | Consistent with restyle |

**Deprecated/outdated in Phase 61 context:**
- Hardcoded `<h1 className="text-3xl font-bold text-ev-teal-light">empowered.vote</h1>` — replaced by AppNav in Phase 61
- Raw `<input>` elements in auth pages — replaced by AuthInput
- `bg-gray-800 border border-gray-700 rounded-xl px-4 py-3` inline input classes — encapsulated in AuthInput

---

## Open Questions

1. **display_name field on SignupPage (AUTH-02 vs backend reality)**
   - What we know: AUTH-02 requirement text mentions "display name" field in the signup form. Backend `POST /api/auth/signup` does not accept `display_name` — the Zod schema ignores it. Display name is captured during onboarding PseudonymStep.
   - What's unclear: Is AUTH-02 aspirational (describing a future all-in-one signup) or describing the current flow where display_name is omitted from signup?
   - Recommendation: Omit `display_name` from the signup form. The requirement description appears to be a listing of all connected account fields, not exclusively signup-form fields. Phase 62 (onboarding restyle) handles PseudonymStep. Planner should document this explicitly in the plan and not implement display_name on signup.

2. **"Continue exploring" destination**
   - What we know: `/` is guarded by AuthGuard; unauthenticated access redirects to `login.empowered.vote`. InformLanding at `/` for unauthenticated users is Phase 64.
   - What's unclear: Should "Continue exploring" be a dead link, navigate to `/` (triggering auth redirect), or navigate somewhere else?
   - Recommendation: Render "Continue exploring" as a `<Link to="/">` for now. Document the known behavior: unauthenticated users will be redirected to `login.empowered.vote`. Phase 64 fixes this properly when InformLanding replaces the auth redirect for unauthenticated root visits.

3. **AuthInput invite code mono font**
   - What we know: The current AuthInput `inputProps.className` is overridden by the internal `className` prop. Adding mono font via inputProps doesn't work.
   - What's unclear: Should Phase 61 patch AuthInput to support merging, or handle invite code as a raw input?
   - Recommendation: Patch `AuthInput` to accept an optional `inputClassName?: string` that is appended to the base className string. Minimal change, fixes the problem cleanly, and benefits any future field needing custom input styling.

---

## Sources

### Primary (HIGH confidence)

- Live codebase: `app/src/pages/LoginPage.tsx` — complete current implementation inspected
- Live codebase: `app/src/pages/SignupPage.tsx` — complete current implementation including check-email state inspected
- Live codebase: `app/src/App.tsx` — complete routes inspected; confirmed no `/welcome` route
- Live codebase: `app/src/components/AuthCard.tsx` — Phase 60 component, exact API confirmed
- Live codebase: `app/src/components/AuthInput.tsx` — Phase 60 component, exact API + inputProps behavior confirmed
- Live codebase: `app/src/components/PrimaryButton.tsx` — Phase 60 component, exact API confirmed
- Live codebase: `app/src/components/SecondaryButton.tsx` — Phase 60 component, exact API confirmed
- Live codebase: `app/src/components/StepProgress.tsx` — Phase 60 component, exact API confirmed
- Live codebase: `app/src/components/AppNav.tsx` — Phase 60 component, exact API confirmed
- Live codebase: `app/src/index.css` — confirmed `ev-blue` and `ev-navy` tokens present
- Live codebase: `backend/src/routes/auth.ts` — Zod signup schema inspected; `display_name` not accepted
- Live codebase: `.planning/phases/60-design-foundation/60-VERIFICATION.md` — Phase 60 all 5/5 truths VERIFIED
- Live codebase: `.planning/REQUIREMENTS.md` — AUTH-01 through AUTH-06 full requirement text read
- Live codebase: `app/src/components/AuthGuard.tsx` — redirect behavior for unauthenticated root access confirmed

---

## Metadata

**Confidence breakdown:**
- Current auth screen implementation: HIGH — full source read
- Phase 60 component APIs: HIGH — source read + verification report confirmed
- Route structure: HIGH — App.tsx fully read
- display_name backend reality: HIGH — Zod schema inspected directly
- "Continue exploring" routing gap: HIGH — AuthGuard behavior confirmed; InformLanding confirmed Phase 64

**Research date:** 2026-04-25
**Valid until:** 2026-05-25 (stable stack; no dependency churn expected)
