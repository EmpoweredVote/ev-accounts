# Phase 67: Login Hub + Inform Signup Flow — Research

**Researched:** 2026-04-27
**Domain:** React auth pages, Supabase signup, Express backend route extension
**Confidence:** HIGH (all findings from direct source code inspection)

---

## Summary

Phase 67 adds an Inform-only signup path alongside the existing invite-only Connected signup. The codebase is well-understood: every relevant file was read directly. No guesswork.

The existing signup infrastructure (`POST /api/auth/signup`, `Signup.tsx`) already handles `display_name` in its Zod schema and sends it through the invite path. The gap for Inform is: when no `invite_code` is provided, `display_name` is accepted by the backend but never written to `public.users`. That write needs to be added in the backend handler.

`inform_profiles` has no `display_name` column — display name lives exclusively on `public.users.display_name`. The trigger that creates `public.users` on auth signup inserts only `(id)`, leaving `display_name = NULL`. For Inform users it must be written via a separate `pool.query()` after `signUpWithEmail` succeeds.

The `Dialog`/`DialogPanel`/`DialogTitle` pattern from `@headlessui/react` v2.2.9 is already used throughout the codebase (see `GrantRoleModal.tsx`, `TopicsPage.tsx`). The old `Transition.Child` pattern in `Signup.tsx` is legacy v1 API — new modal work should use the v2 flat API.

**Primary recommendation:** Reuse and restyle the existing `/signup` route for the Inform path. Do NOT create a new route. Add a separate `InformSignup.tsx` page at a new route (e.g., `/signup/inform`) OR repurpose the existing `/signup` to branch on tier intent (simpler). The backend needs one additional `pool.query()` to persist `display_name` for the Inform-only code path.

---

## Standard Stack

### Core (already installed)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@headlessui/react` | 2.2.9 | Modal/dialog | Already used in 4 files; v2 flat API |
| `react-router-dom` | 6.21.1 | Routing | All existing pages use it |
| `zustand` | 5.0.11 | Auth state | `useAuthStore` is the canonical store |
| `tailwindcss` | 4.0.0 | Styling | All UI uses Tailwind v4 `@theme` tokens |

### Backend (already installed)
| Library | Version | Purpose |
|---------|---------|---------|
| `zod` | project-wide | Request validation |
| `express-rate-limit` | project-wide | Already on `/api/auth/signup` |
| `pg` (pool) | project-wide | Direct Postgres writes for non-public schemas |

### No new dependencies needed
All required tooling is already in place.

---

## Architecture Patterns

### Current File Structure
```
admin/src/
├── pages/
│   ├── Login.tsx          # login.empowered.vote/login
│   ├── Signup.tsx         # login.empowered.vote/signup (Connected, invite-required)
│   ├── ProfilePage.tsx    # login.empowered.vote/profile
│   └── PrivacyPage.tsx
├── components/
│   ├── AuthGuard.tsx
│   ├── AdminGuard.tsx
│   └── GrantRoleModal.tsx  # Reference modal implementation (v2 API)
├── store/
│   └── authStore.ts       # tier: 'inform' | 'connected' | 'empowered'
└── lib/
    ├── redirect.ts
    └── api.ts

backend/src/
├── routes/
│   ├── auth.ts            # POST /api/auth/signup, /login, /session, /logout
│   └── account.ts         # GET /api/account/me (returns inform_profile)
├── lib/
│   └── authService.ts     # signUpWithEmail(email, password) — no metadata
└── middleware/
    └── tierGuards.ts      # requireInform, requireConnected, requireEmpowered
```

### Routing (App.tsx — current state)
```tsx
<Route path="/login"   element={<Login />} />
<Route path="/signup"  element={<Signup />} />    // Connected only today
<Route path="/privacy" element={<PrivacyPage />} />

// Authenticated (any tier)
<Route element={<AuthGuard />}>
  <Route path="/profile" element={<ProfilePage />} />
</Route>
```

**For Phase 67:** Add `/signup/inform` route for the Inform signup page. The existing `/signup` stays for Connected. Update `Login.tsx` to link to `/signup/inform` as the primary "Create an Account" CTA.

### Pattern: Headlessui v2 Modal
The correct pattern for new modals (from `GrantRoleModal.tsx`):
```tsx
// Source: admin/src/components/GrantRoleModal.tsx
import { Dialog, DialogPanel, DialogTitle } from '@headlessui/react';

<Dialog open={open} onClose={() => setOpen(false)} className="relative z-50">
  <div className="fixed inset-0 bg-black/40" aria-hidden="true" />
  <div className="fixed inset-0 flex items-center justify-center p-4">
    <DialogPanel className="w-full max-w-md bg-white dark:bg-gray-900 rounded-lg shadow-xl p-6">
      <DialogTitle className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
        Modal Title
      </DialogTitle>
      {/* content */}
    </DialogPanel>
  </div>
</Dialog>
```

**Note:** `Signup.tsx` currently uses the legacy v1 `Transition`/`Transition.Child` API. New modal work (Inform constraints modal) must use the v2 flat API above.

### Pattern: Yellow (Inform) Theming
```
ev-yellow = #FED12E, defined in admin/src/index.css via Tailwind v4 @theme
Usage: bg-ev-yellow, text-ev-yellow, border-ev-yellow, border-ev-yellow/20
```
Existing examples in ProfilePage.tsx:
- `bg-ev-yellow` for Inform dot indicator
- `hover:border-ev-yellow/50` for feature tile hover
- `bg-ev-yellow h-full rounded-full` for progress bars

### Pattern: Auth Page Layout (from Login.tsx)
```tsx
<div className="min-h-screen flex flex-col items-center justify-center bg-gray-50 dark:bg-ev-black px-4 py-12">
  {/* Wordmark */}
  <div className="mb-8 text-center space-y-1">
    <h1 className="text-3xl font-bold text-ev-teal dark:text-ev-teal-light tracking-tight">
      empowered.vote
    </h1>
  </div>

  <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-200 dark:border-gray-800 shadow-sm p-6 w-full max-w-sm space-y-5">
    {/* content */}
  </div>
</div>
```
Use this layout for `InformSignup.tsx`. Use `max-w-sm` (same as Login) not `max-w-md` (legacy Signup uses that — inconsistent with current design language).

### Pattern: "Check your email" screen
Currently in `Signup.tsx` as a conditional render when `success === true`. It shows:
- Logo image
- "Check your email" h2
- Email address in bold
- "Already confirmed? Sign in" link

For Inform signup: replicate this pattern but with yellow accent (`text-ev-yellow`), not teal. The confirmation wording can be identical.

### Pattern: Post-confirm redirect
Login.tsx line 69: `window.location.href = \`${target}#access_token=${token}\``. After email confirmation, Supabase redirects to the `SITE_URL` configured in Supabase dashboard settings (not in code). There is **no `emailRedirectTo`** passed in `signUpWithEmail()` — the redirect is controlled entirely by the Supabase project's "Site URL" / "Redirect URLs" setting.

Current `signUpWithEmail`:
```ts
// Source: backend/src/lib/authService.ts
export async function signUpWithEmail(email: string, password: string) {
  return supabaseAdmin.auth.signUp({ email, password });
}
```

After email confirmation, Supabase will redirect to whatever URL is configured in the Supabase dashboard. For Phase 67, this should go to `login.empowered.vote/profile`. The Supabase dashboard's "Redirect URLs" must include `https://login.empowered.vote/profile` (or `https://login.empowered.vote/**`). **This is a configuration item, not a code item.** The `AuthGuard` wrapping `/profile` will gate access until the user logs in after confirming.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Modal with backdrop | Custom overlay div + useState | `Dialog`/`DialogPanel` from headlessui v2 | Already in project, accessible by default, handles focus trap |
| Form state validation | Custom validators | Zod in backend (already on `/api/auth/signup`) | Consistent with all other endpoints |
| Rate limiting | Custom counter | `authLimiter` already on `POST /api/auth/signup` | Inform signup hits same endpoint — rate limiting comes free |
| Email deduplication | Custom query | Supabase returns `email_exists` error code | Already handled in `auth.ts` error mapping |
| Tier detection in frontend | Manual API calls | `user.tier` from `useAuthStore` | Store already populated from `/account/me` on login |

---

## Common Pitfalls

### Pitfall 1: display_name Not Written for Inform-Only Signups
**What goes wrong:** `display_name` is in the Zod schema (`signUpBodySchema`) and extracted from the request, but it is only passed to `signup_with_invite` RPC when `invite_code && legal_name` are both present. When only email + password + display_name are provided (Inform path), the trigger `on_auth_user_created` creates `public.users (id)` with `display_name = NULL`.

**Root cause:** `signUpWithEmail(email, password)` ignores `display_name` entirely. No subsequent write to `public.users` exists for the Inform-only case.

**How to avoid:** After `signUpWithEmail` succeeds and `!invite_code`, write display_name to `public.users` via:
```ts
// Source: pattern from account.ts PATCH /me
await pool.query(
  `UPDATE public.users SET display_name = $2, updated_at = now() WHERE id = $1`,
  [data.user.id, display_name]
);
```
This uses the same `pool` import already in `auth.ts`.

### Pitfall 2: inform_profiles Has No display_name Column
**What goes wrong:** Assuming `inform.inform_profiles` stores the display name since it's "the inform profile."
**How to avoid:** Display name is always `public.users.display_name`. `inform.inform_profiles` columns are: `user_id`, `yellow_gem_balance`, `last_essentials_location`, `created_at`. Do not add display_name there.

### Pitfall 3: Using v1 Headlessui Transition API
**What goes wrong:** `Signup.tsx` imports `Transition` from `@headlessui/react` and uses `Transition.Child`. This works but is the v1 API. New modal code that copies this pattern will look inconsistent and may fail if headlessui ever drops backward compat.
**How to avoid:** Use `Dialog`/`DialogPanel`/`DialogTitle` flat v2 API (already in `GrantRoleModal.tsx`, `TopicsPage.tsx`). No `Transition` wrapper needed.

### Pitfall 4: inform Schema Inaccessible via PostgREST
**What goes wrong:** Trying to read `inform.inform_profiles` via `supabaseAdmin.schema('inform').from(...)`. The `inform` schema is not in the PostgREST exposed schema list.
**How to avoid:** All inform schema reads/writes use `pool.query()` directly. The `GET /api/account/me` handler already does this correctly. The `PATCH /api/account/location-hint` handler also uses `pool.query()`. Follow the same pattern.

### Pitfall 5: Confusing /signup (Connected) with New Inform Signup Route
**What goes wrong:** Modifying `Signup.tsx` to also handle Inform signups, creating a branching mess with conditional fields.
**How to avoid:** Create a new `InformSignup.tsx` page at `/signup/inform`. The existing `/signup` stays intact for Connected signup. Update `Login.tsx`'s "Create one" link to point to `/signup/inform`. Add `<Route path="/signup/inform" element={<InformSignup />} />` in `App.tsx`.

### Pitfall 6: login.empowered.vote Login Page "Create Account" CTA
**What goes wrong:** The current Login.tsx already has a "Create one" link at the bottom (line 146) pointing to `/signup` (Connected). If we just change that link to `/signup/inform`, Connected users lose direct access to the Connected signup.
**How to avoid:** Phase 67 goal is for Inform signup to be the primary CTA. Connected signup (invite-required) becomes secondary. Options:
- Change "Create one" link to `/signup/inform` (new primary path)  
- Update existing `/signup` (Connected) to add a "Sign up without invite" link to `/signup/inform`
- OR add two CTAs: primary button "Create an Inform Account" + secondary text "Have an invite code? Create a Connected Account"

**Recommended:** Change the Login "Create one" link to `/signup/inform`. The Inform signup page can have a secondary text "Have an invite code? Create a Connected Account →" linking back to `/signup`.

---

## Code Examples

### Backend: Inform-Only display_name Write (the missing piece)
```ts
// In POST /api/auth/signup, after signUpWithEmail succeeds and !invite_code:
// Source: pattern from backend/src/routes/account.ts PATCH /me
if (!invite_code && data.user) {
  await pool.query(
    `UPDATE public.users SET display_name = $2, updated_at = now() WHERE id = $1`,
    [data.user.id, display_name]
  ).catch((err: unknown) => {
    console.error('[auth/signup] display_name write failed:', err);
    // Non-fatal: user was created; display_name can be set later
  });
}
```

### Frontend: Inform Constraints Modal (headlessui v2)
```tsx
// Source: pattern from admin/src/components/GrantRoleModal.tsx
import { Dialog, DialogPanel, DialogTitle } from '@headlessui/react';

<Dialog open={constraintsOpen} onClose={() => setConstraintsOpen(false)} className="relative z-50">
  <div className="fixed inset-0 bg-black/40" aria-hidden="true" />
  <div className="fixed inset-0 flex items-center justify-center p-4">
    <DialogPanel className="w-full max-w-sm bg-white dark:bg-gray-900 rounded-2xl border border-ev-yellow/20 shadow-xl p-6">
      <DialogTitle className="text-lg font-semibold text-gray-900 dark:text-white mb-3">
        What is an Inform Account?
      </DialogTitle>
      {/* Inform tier explanation: read civic data, use Compass/Essentials, no participation */}
      <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">...</p>
      <button
        onClick={() => setConstraintsOpen(false)}
        className="w-full py-2.5 px-4 bg-ev-yellow text-ev-black font-semibold rounded-xl text-sm"
      >
        Got it
      </button>
    </DialogPanel>
  </div>
</Dialog>
```

### Frontend: Login.tsx CTA Addition
```tsx
// In Login.tsx, replace existing "Create one" paragraph:
<p className="text-center text-sm text-gray-500 dark:text-gray-500">
  New here?{' '}
  <Link to={signupHref.replace('/signup', '/signup/inform')} className="text-ev-yellow hover:underline font-medium">
    Create an Inform Account
  </Link>
</p>
<p className="text-center text-xs text-gray-400 dark:text-gray-600 mt-1">
  Have an invite code?{' '}
  <Link to={signupHref} className="text-ev-teal dark:text-ev-teal-light hover:underline">
    Create a Connected Account
  </Link>
</p>
```

### GET /api/account/me response for Inform users
```json
{
  "id": "uuid",
  "email": "user@example.com",
  "display_name": "CivicName",
  "tier": "inform",
  "is_admin": false,
  "completed_onboarding": false,
  "location_consent": false,
  "verification_rating": 60,
  "vq_hold_active": false,
  "red_gem_quests_unlocked": false,
  "account_standing": "active",
  "jurisdiction": null,
  "inform_profile": {
    "yellow_gem_balance": 0,
    "last_essentials_location": null
  },
  "created_at": "...",
  "updated_at": "..."
}
```
No `connected_profile`, no `empowered_profile`, no `gems` key. `inform_profile` is present for all authenticated users.

---

## Per-Plan Recommendations

### 67-01: Login Page CTA + Inform Constraints Modal

**What to do:**
1. Edit `Login.tsx`: replace single "Create one" link with two links: primary yellow "Create an Inform Account" → `/signup/inform`; secondary teal "Have an invite code?" → `/signup`.
2. Add `constraintsOpen` state + `Dialog` modal in `Login.tsx` (or link modal from a `?` icon next to the "Create an Inform Account" CTA). Modal explains: Inform = read-only access to Compass, Essentials, CTC. No participation until Connected.
3. Preserve the `?redirect=` query string propagation in the `/signup/inform` link (same as the existing `signupHref` logic).

**Style guidance:** Yellow (`ev-yellow`) for Inform CTA. The modal border should use `border-ev-yellow/20`, title `text-ev-yellow` or neutral, CTA button `bg-ev-yellow text-ev-black`.

**No backend changes** for this plan.

### 67-02: Inform Signup Form (InformSignup.tsx)

**What to do:**
1. Create `admin/src/pages/InformSignup.tsx` — new file.
2. Fields: **display_name** (required, 1–100 chars), **email** (required), **password** (required, min 8). No invite code. No legal name.
3. On submit: `POST /api/auth/signup` with `{ email, password, display_name }` (no `legal_name`, no `invite_code`). This hits the existing endpoint; the backend already has the Zod schema accepting these three fields.
4. On success (201): show "Check your email" screen with yellow accent instead of teal.
5. Add `<Route path="/signup/inform" element={<InformSignup />} />` in `App.tsx`.

**Style guidance:** Match the `Login.tsx` card layout (`rounded-2xl`, `max-w-sm`, `space-y-5`). Use yellow accent instead of teal for the submit button (`bg-ev-yellow text-ev-black font-semibold`). Header text: "Create your Inform Account". Tagline: "Read civic data. Explore your representatives. No invite required."

**No invite code normalization needed** (that logic lives in the old `Signup.tsx`).

**Covenant callout** (adapt from existing `Signup.tsx`): "One account, one voice. Your data is private by default." Keep the same wording but style with yellow border instead of teal.

### 67-03: Backend — display_name Write for Inform Path

**What to do:**
1. In `backend/src/routes/auth.ts`, after `signUpWithEmail` succeeds and `data.user` is non-null, add a `pool.query()` to write `display_name` to `public.users` when `!invite_code`.
2. This write is non-fatal (same pattern as the connected_profiles sync in `PATCH /me`): catch errors, log, continue.
3. No schema migration needed. `public.users.display_name` column exists (nullable TEXT, defined in `20260224000002_public_users.sql`). The trigger `on_auth_user_created` already creates the row; we just need to UPDATE it.
4. No new endpoint needed. The existing `POST /api/auth/signup` already accepts `display_name`, validates it (Zod), and extracts it. We just need to use it.

**The exact code change** is a single `pool.query()` call inserted after line 183 (the `data.user` null check) and before the invite-code block. See Code Examples section above.

**Zod schema is already correct**: `display_name: z.string().min(1).max(100)` is already required in `signUpBodySchema`. The frontend must send it.

**The frontend Signup.tsx currently does NOT send display_name** — it sends `{ email, password, legal_name, invite_code }`. The new `InformSignup.tsx` must send `{ email, password, display_name }`. The old `Signup.tsx` for Connected must also be updated to send `display_name` (it collects it but the form hasn't had a display_name field — wait, actually checking again: the old `Signup.tsx` has `legalName` but no `displayName` state variable). 

**Important:** The existing Connected `Signup.tsx` does not collect `display_name` from the user — it sends `legal_name` + `invite_code` but NOT `display_name`. Yet the backend's `signup_with_invite` RPC requires `p_display_name`. The RPC call in `auth.ts` passes `display_name` from the parsed Zod body. This means **the Connected signup is currently broken** if `display_name` isn't being sent by `Signup.tsx` — but since it's required in Zod, the backend returns 422. This is a pre-existing inconsistency. Phase 67 should NOT fix this; it's out of scope. Phase 67 only adds the Inform path.

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| `@headlessui/react` v1 `Transition`/`Transition.Child` | v2 flat `Dialog`/`DialogPanel` | `Signup.tsx` uses v1; new code must use v2 |
| `Signup.tsx` (Connected, invite-only) | Add `InformSignup.tsx` at `/signup/inform` | New route, no modification to existing signup |
| Login page links only to Connected signup | Login page links to Inform signup (primary) + Connected (secondary) | Inform is the new entry point |

---

## Open Questions

1. **Connected Signup display_name gap** — The existing `Signup.tsx` does not have a `displayName` field, but `signUpBodySchema` requires it. If someone uses the Connected signup today, they'd get a 422 unless the frontend sends `display_name`. This is a pre-existing bug, not a Phase 67 concern. But the planner should be aware.

2. **Email confirmation redirect URL** — Supabase redirects confirmed users to the project's configured "Site URL." Currently this sends users somewhere (likely `login.empowered.vote`). After confirmation, an unauthenticated user lands on the login page naturally via `AuthGuard → Navigate to /login`. This works correctly. No code change needed; just verify the Supabase dashboard "Redirect URLs" includes `https://login.empowered.vote/**`.

3. **Inform constraints modal content** — What exactly does "Inform" mean to a new user? The planner needs copy: recommended framing is "Inform accounts let you explore Empowered Vote's civic tools — Compass, Essentials, Treasury Tracker, CTC, and Read & Rank. To participate in Validation Quests or Focused Communities, upgrade to a Connected Account (invite required)."

---

## Sources

### Primary (HIGH confidence — direct source inspection)
- `admin/src/pages/Login.tsx` — current state, CTA location, link pattern
- `admin/src/pages/Signup.tsx` — Connected signup form, modal pattern, success screen
- `admin/src/App.tsx` — routing table, AuthGuard usage
- `admin/src/store/authStore.ts` — User type including `tier`
- `backend/src/routes/auth.ts` — POST /api/auth/signup full implementation
- `backend/src/routes/account.ts` — GET /api/account/me inform_profile shape
- `backend/src/lib/authService.ts` — signUpWithEmail (no metadata passed)
- `backend/migrations/084_inform_profiles.sql` — inform_profiles schema + trigger
- `backend/migrations/085_signup_with_invite_yellow_transfer.sql` — signup_with_invite v2
- `backend/migrations/071_signup_with_invite_display_name.sql` — signup_with_invite v1
- `supabase/migrations/20260224000002_public_users.sql` — public.users schema + trigger
- `admin/src/components/GrantRoleModal.tsx` — canonical headlessui v2 Dialog pattern
- `admin/src/index.css` — ev-yellow color token definition
- `admin/package.json` — @headlessui/react 2.2.9 confirmed

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — direct package.json inspection
- Architecture / routing: HIGH — direct App.tsx and page file inspection
- Pitfalls: HIGH — root-caused from actual code, not speculation
- Backend signup path: HIGH — full auth.ts + authService.ts read
- display_name gap: HIGH — confirmed by tracing the full path from Zod schema through signUpWithEmail to trigger

**Research date:** 2026-04-27
**Valid until:** 2026-05-27 (stable codebase — 30 day window)
