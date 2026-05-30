---
phase: 67-login-hub-+-inform-signup-flow
plan: 02
subsystem: admin-app-auth
committed: 2026-04-27
commits:
  - 4d7fada feat(67-02): create InformSignup page at /signup/inform
  - fcaaeef feat(67-02): register /signup/inform route in App.tsx
tech-stack:
  added: []
  modified:
    - admin/src/pages/InformSignup.tsx (new file, 201 lines)
    - admin/src/App.tsx (2 lines added)
requirements-closed:
  - ISUP-01
  - ISUP-02
  - ISUP-03
---

# Plan 67-02 Summary: Inform Signup Page

## What Was Built

**`admin/src/pages/InformSignup.tsx`** — new public page at `/signup/inform`.

- Three-field form in order: display name → email → password. No invite code, no legal name, no "Request access" link anywhere.
- Posts to `POST /api/auth/signup` with `{ email, password, display_name }` — backend treats absent `invite_code` as the Inform path.
- On 201 → success screen: yellow "Inform Account" pill, "Check your email" heading, user's email displayed.
- Yellow theming throughout: `border-ev-yellow/30` card border, `focus:ring-ev-yellow` on all inputs, `bg-ev-yellow text-ev-black` submit button.
- Redirect param preserved on footer links (`/login?redirect=...` and `/signup?redirect=...`).
- `appName` callout rendered when `validRedirect` is present (same pattern as Login.tsx).
- Error handling: 409 → "An account with this email already exists", 422 → backend message, 429/503 → user-friendly copy.

**`admin/src/App.tsx`** — two lines added:
- `import InformSignup from './pages/InformSignup'`
- `<Route path="/signup/inform" element={<InformSignup />} />` (placed directly after `/signup`, no AuthGuard)

## Implementation Notes

- Done outside the GSD execute flow (committed directly on 2026-04-27, same session as 67-01 and 67-03).
- `useNavigate` not imported — success state renders in-place rather than redirecting, keeping the email visible.
- No regression on `/signup` (Connected path) — `Signup.tsx` untouched.

## UAT Status

Human checkpoint from the plan was not formally recorded. Code matches plan spec exactly. Full end-to-end UAT (form render, DB state, email confirmation flow) to be confirmed during Phase 67 verification.
