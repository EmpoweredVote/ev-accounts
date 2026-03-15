# Phase 24: Public Auth Hub (Login Rebrand + Signup Flow) - Research

**Researched:** 2026-03-14
**Domain:** React auth UI (Vite + React 18 + React Router 6 + Zustand + Tailwind v4), Express backend signup route extension
**Confidence:** HIGH — almost entirely determined by existing codebase patterns; no new libraries required

---

## Summary

Phase 24 is a UI + backend extension phase, not a greenfield feature. The stack is already established: Vite/React 18/React Router 6/Zustand/Tailwind v4 on the frontend, Express 4.x/TypeScript strict on the backend. The work is:

1. Replace the existing `admin/src/pages/Login.tsx` with a tier-neutral login page
2. Add a `/signup` route to the React app with invite code + legal name + covenant callout
3. Add a `POST /api/auth/request-access` backend endpoint (email capture for code-less users)
4. Extend `POST /api/auth/signup` to accept `legal_name` and `invite_code`, validate the invite code, create the Supabase auth user, and atomically create the `connected_profiles` row via a new `connect.signup_with_invite` RPC
5. Add post-login routing logic in the React app (tier detection → redirect to profile page or `?redirect=` target)
6. Add "Admin Panel" link to the profile page for admin-flagged users

The most important architectural question is: **does Phase 24 signup go through the existing multi-step `connect/` flow, or does it create the Connected profile atomically at signup time?** The answer, per the CONTEXT.md, is atomic at signup: invite code + legal name are collected on the signup form, so the flow collapses into a single `POST /api/auth/signup` call that creates the auth user AND the `connected_profiles` row together. A new `connect.signup_with_invite` RPC handles this atomically.

**Primary recommendation:** Build one new SECURITY DEFINER RPC (`connect.signup_with_invite`) that accepts `(p_user_id, p_legal_name, p_invite_code)` and atomically validates the invite, claims it, and creates `connected_profiles`. The existing backend signup route grows to accept `legal_name` and `invite_code`. No new npm packages are needed on either frontend or backend.

---

## Standard Stack

No new libraries needed. All work uses already-installed packages.

### Core (already installed)

| Library | Version in Use | Purpose | Note |
|---------|---------------|---------|------|
| react | ^18.3.1 | UI | Already in admin/package.json |
| react-router-dom | ^6.21.1 | Routing (`/login`, `/signup`) | Already used |
| zustand | ^5.0.11 | Auth state store (`useAuthStore`) | Already used |
| tailwindcss | ^4.0.0 | Styling | Already used, Tailwind v4 `@theme` with `ev-*` tokens |
| @headlessui/react | ^2.2.9 | Modal dialogs | Already installed, use for "Request Access" modal if needed |
| express | ^4.21.0 | Backend | Already used |
| zod | ^3.23.0 | Validation | Already used for all request body schemas |

### No New Dependencies

All required functionality exists in the current stack. Do NOT add:
- A form library (react-hook-form, formik) — existing forms use controlled state with `useState`
- A toast library — if toasts are needed, follow the pattern already in admin pages
- Any auth SDK additions — `@supabase/ssr` is already present but auth calls go through the backend API

**Installation:** None needed.

---

## Architecture Patterns

### Recommended File Structure Changes

```
admin/src/
├── pages/
│   ├── Login.tsx          # REPLACE existing file — rebrand to tier-neutral
│   ├── Signup.tsx         # NEW — invite code + legal name + covenant callout
│   └── admin/             # unchanged
├── store/
│   └── authStore.ts       # EXTEND — add tier, completed_onboarding, is_admin fields
└── App.tsx                # EXTEND — add /signup route, add post-login routing logic

backend/src/
├── routes/
│   └── auth.ts            # EXTEND — new fields on signup, new /request-access endpoint
└── supabase/migrations/
    └── YYYYMMDDXXXXXX_phase24_signup_with_invite.sql  # NEW
```

### Pattern 1: Tier-Neutral Login Page

The existing `Login.tsx` is admin-first ("Empowered Accounts Admin" / "Internal admin panel"). Replace entirely with civic-facing branding.

**What changes:**
- Heading: `"Sign in to Empowered Vote"`
- Remove "Internal admin panel" subtitle
- Add Empowered Vote logo (PNG assets already in repo root: `Empowered_Vote_Logo_2026.png`)
- Add "Don't have an account? Create one" link below sign-in button → navigates to `/signup`
- Remove admin-specific error message copy; use generic auth error messages
- Post-login routing: detect tier + onboarding state + `?redirect=` param before navigating

**Admin access:** Login page does NOT check admin status. Admin panel link appears on profile page for admin-flagged accounts.

**What stays the same:** The actual login API call (`POST /api/auth/login`), error handling pattern, form validation approach.

### Pattern 2: Post-Login Routing

After login, the frontend calls `GET /api/account/me` to determine tier and `completed_onboarding`, then routes.

```typescript
// Source: codebase pattern (account.ts GET /me response shape)
async function routeAfterLogin(token: string, redirectParam: string | null) {
  const me = await apiFetch<MeResponse>('/account/me', {
    headers: { Authorization: `Bearer ${token}` }
  });

  // 1. Validate redirect param — only *.empowered.vote domains
  if (redirectParam) {
    try {
      const url = new URL(redirectParam);
      if (url.hostname === 'empowered.vote' || url.hostname.endsWith('.empowered.vote')) {
        window.location.href = redirectParam;
        return;
      }
    } catch {
      // malformed URL — fall through to default routing
    }
  }

  // 2. Default routing by tier + onboarding state
  // All tiers currently land on /profile — dashboards are future phases
  navigate('/profile');
}
```

**Routing table (all currently land on /profile):**
- `completed_onboarding = false` → `/profile`
- Connected, onboarding complete → `/profile` (Connected dashboard is a future phase)
- Empowered → `/profile` (Empowered view is a future phase)
- Admin flag (any tier) → `/profile` (admin panel link visible there)

### Pattern 3: Signup Flow — Single-Step Form

Fields: email, password, legal name, invite code. With only 4 fields, a single-page form is appropriate (no multi-step needed).

**Form layout recommendation:** Single page, linear stacking. Covenant callout as an `<aside>` or info box between the invite code field and the submit button. "Request access" as a text link below the form (not a button — secondary action).

```
[Empowered Vote logo]
"Create your account"

[Email field]
[Password field]
[Legal name field]  ← stored in connected_profiles.legal_name
[Invite code field] ← XXXX-XXXX format, normalize to uppercase

[Covenant callout — info box, NOT a checkbox]
  "This is your one Empowered Vote account. ..."

[Create account button]

---
"Don't have a code? Request access" (link → opens modal or /request-access page)
"Already have an account? Sign in" (link → /login)
```

### Pattern 4: Backend Signup Route Extension

The existing `POST /api/auth/signup` accepts `{ email, password, guest_state? }`. Phase 24 extends it to accept `{ email, password, legal_name, invite_code }`.

**Critical architectural note:** The existing signup uses `signUpWithEmail` which may return `null` session when email confirmation is enabled. The new fields (`legal_name`, `invite_code`) must be validated and the Connected profile created in the same request flow. Because email confirmation is enabled (Supabase default), the user does not have a session immediately after signup — but the user ID is available from `data.user.id`. The `connected_profiles` row can be created immediately using the service role (not requiring auth).

**New RPC needed:** `connect.signup_with_invite(p_user_id UUID, p_legal_name TEXT, p_invite_code TEXT)`

This RPC atomically:
1. Validates and claims the invite code (same logic as `claimInviteCode()`)
2. Creates the `connected_profiles` row with `verification_method = 'invite'`, `verification_status = 'pending'`
3. Returns the inviter_id for potential "invited by X" messaging

**Why a new RPC instead of reusing existing:** The existing `complete_connect_flow` RPC reads from a `verification_session` that must pre-exist. Signup with invite bypasses the session entirely. The `promote_to_connected` RPC is admin-only and logs to `tier_promotion_log`. A dedicated `signup_with_invite` RPC is the right pattern.

### Pattern 5: `?redirect=` Trusted Domain Validation

Domain validation happens client-side before the redirect. The server does not need to validate redirects (no OAuth-style server state needed).

```typescript
// Source: derived from project architecture (pure client-side routing)
function isValidRedirect(redirectParam: string | null): string | null {
  if (!redirectParam) return null;
  try {
    const url = new URL(redirectParam);
    const hostname = url.hostname;
    if (hostname === 'empowered.vote' || hostname.endsWith('.empowered.vote')) {
      return redirectParam;
    }
  } catch {
    // malformed
  }
  return null;
}
```

The `?redirect=` param is read on mount in the Login and Signup components. When valid, show callout: `"You'll be returned to [hostname] after signing in"`.

### Pattern 6: Admin Panel Link on Profile Page

The profile page (Phase 23) shows user data from `GET /api/account/profile/me`. That endpoint does not return `is_admin`. The "Admin Panel" link requires knowing admin status.

**Options:**
1. Call `GET /api/admin/me` separately and show link if it returns 200 (403 = not admin)
2. Add `is_admin` field to `GET /api/account/me` (account.ts) response
3. Call `GET /api/admin/me` silently in the authStore population step

**Recommendation:** Option 2 — add `is_admin: boolean` to the `GET /api/account/me` response. The `requireAdmin` middleware queries `admin_users` using service role. A matching query in the account route handler (using `supabaseAdmin` via a lib helper) gives the `is_admin` flag at login time. This means one call instead of two. Store `is_admin` in `useAuthStore` alongside `tier` and `completed_onboarding`.

### Anti-Patterns to Avoid

- **Don't add admin check to the login page itself:** Admin access is unlocked from the profile page, not the login surface. Do not call `GET /api/admin/me` as part of the login flow to gate access.
- **Don't reuse `complete_connect_flow` RPC for signup:** That RPC reads a `verification_session`. No session exists during signup. Use the new `signup_with_invite` RPC.
- **Don't expose `?redirect=` param to the backend:** Redirect validation is pure client-side URL parsing. No server state needed.
- **Don't check `completed_onboarding` on Inform-tier users:** `completed_onboarding` lives on `connected_profiles`. Inform users don't have that row. The `GET /api/account/me` response returns `completed_onboarding: false` for Inform users — treat as "send to profile page."
- **Don't store `access_token` in localStorage:** Current pattern uses `sessionStorage.getItem('admin_token')`. Keep this pattern for Phase 24 tokens.
- **Don't use `.strict()` on Zod schemas in backend routes:** Project pattern uses `.object()` which strips unknown keys silently.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Invite code validation + claim | Custom JS transaction | `signup_with_invite` SECURITY DEFINER RPC | Atomicity, same pattern as all other multi-table writes in this codebase |
| Trusted domain check | Complex regex | `new URL(redirectParam).hostname.endsWith('.empowered.vote')` | Built-in URL parser handles all edge cases |
| Form state management | Custom reducer | `useState` per field (existing pattern in all auth forms) | Matches existing codebase style |
| Modal for "Request Access" | Third-party modal library | `@headlessui/react` Dialog (already installed) | Zero new dependencies |
| Auth token persistence | Custom storage logic | Existing `sessionStorage` pattern in `authStore.ts` + App.tsx | Keep consistency |

**Key insight:** This codebase deliberately avoids form libraries and uses simple controlled components. Follow that pattern.

---

## Common Pitfalls

### Pitfall 1: Email Confirmation + Session Timing

**What goes wrong:** Signup via `signUpWithEmail` with email confirmation enabled returns `data.session = null`. Code that immediately tries to use `data.session.access_token` throws a null reference error.

**Why it happens:** Supabase does not return a session when email confirmation is required (default on production). The Phase 23 invite-code-based signup will have this behavior.

**How to avoid:** After signup, check `data.user` for success (not `data.session`). Create the `connected_profiles` row using `supabaseAdmin` (service role) with `p_user_id = data.user.id`. The user can log in after confirming their email.

**Warning signs:** Tests that pass with email confirmation disabled but fail on production.

### Pitfall 2: `?redirect=` XSS / Open Redirect

**What goes wrong:** Untrusted `?redirect=` values allow attackers to redirect users to phishing sites after login.

**Why it happens:** Not validating domain before using `window.location.href`.

**How to avoid:** Use `new URL(param)` and check `.hostname.endsWith('.empowered.vote')`. Any exception (malformed URL) or non-matching domain → silently ignore, use default routing. Never navigate to an unvalidated `?redirect=` value.

**Warning signs:** Any code path that does `navigate(redirectParam)` without URL parsing first.

### Pitfall 3: Invite Code Race Condition

**What goes wrong:** Two users submit the same invite code simultaneously. Without a transaction lock, both succeed.

**Why it happens:** The existing `claimInviteCode()` function is a JavaScript-level check + update, not atomic at the DB level.

**How to avoid:** The `signup_with_invite` RPC uses `SELECT ... FOR UPDATE` on the invite code row before claiming it, same as `complete_connect_flow` does. Never do claim + create as separate JS awaits.

**Warning signs:** Using `claimInviteCode()` + `supabaseAdmin.insert()` as two separate awaits in the route handler.

### Pitfall 4: `?redirect=` Present on Signup — Missing Profile Stop

**What goes wrong:** A user who signs up with `?redirect=` is immediately sent to the redirect target before ever visiting the profile page to set location, display name, etc.

**Why it happens:** Context decision is: "Post-signup with redirect: fires immediately after account creation (no profile page stop)." This is intentional behavior. The pitfall is accidentally sending to the profile page when a redirect is present.

**How to avoid:** Post-signup routing must follow the exact priority: redirect param → profile page. No intermediate stops when redirect is valid.

**Warning signs:** Routing logic that always hits profile page after signup regardless of redirect param.

### Pitfall 5: Admin Flag Not Available at Route-Time

**What goes wrong:** Profile page renders before admin status is known, causing a flash of "no admin link" then "admin link appears."

**Why it happens:** Admin status is not in the initial `GET /api/account/me` response (not yet — it's added in Phase 24). If admin detection uses a separate API call on the profile page, there's a race.

**How to avoid:** Add `is_admin: boolean` to `GET /api/account/me` response (requires querying `admin_users` table via `supabaseAdmin` in account.ts). Store in `useAuthStore`. Profile page reads from store — no flicker.

**Warning signs:** A `useEffect` on the profile page that makes a second `/api/admin/me` call independently.

### Pitfall 6: Invite Code Format Validation

**What goes wrong:** The invite code schema is `XXXX-XXXX` (9 chars with hyphen). The existing `claimBodySchema` validates `min(9).max(9)`. The signup form must normalize to uppercase before sending.

**How to avoid:** Match existing backend normalize pattern: `.toUpperCase().trim()` before submission.

**Warning signs:** Lowercase invite codes returning 422 or 404 from the backend.

---

## Code Examples

### Backend: Extended Signup Schema

```typescript
// Source: backend/src/routes/auth.ts (extend existing signUpBodySchema)
const signUpBodySchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  legal_name: z.string().min(1).max(200).optional(),
  invite_code: z.string().length(9).optional(),
  guest_state: z.object({ /* ... existing ... */ }).optional(),
});
// NOTE: legal_name and invite_code are optional so the existing CompassV2 signup
// path still works. When invite_code is present, legal_name MUST also be present.
// Validate this business rule in the handler, not just in the schema.
```

### Backend: New `signup_with_invite` RPC (SQL skeleton)

```sql
-- Source: derived from connect.promote_to_connected pattern in
--   supabase/migrations/20260314000035_phase23_tier_promotion.sql
CREATE OR REPLACE FUNCTION connect.signup_with_invite(
  p_user_id    UUID,
  p_legal_name TEXT,
  p_invite_code TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_invite_id  UUID;
  v_inviter_id UUID;
BEGIN
  -- 1. Lock + validate invite code
  SELECT id, created_by INTO v_invite_id, v_inviter_id
    FROM connect.invite_codes
    WHERE code = upper(trim(p_invite_code))
      AND is_claimed = false
      AND (expires_at IS NULL OR expires_at > now())
    FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'INVALID_OR_CLAIMED_CODE';
  END IF;

  -- 2. Prevent self-invite (edge case: user already had account, restarted)
  IF v_inviter_id = p_user_id THEN
    RAISE EXCEPTION 'SELF_INVITE_BLOCKED';
  END IF;

  -- 3. Claim the invite code
  UPDATE connect.invite_codes
    SET is_claimed = true, claimed_by = p_user_id, claimed_at = now()
    WHERE id = v_invite_id;

  -- 4. Create connected_profiles row
  INSERT INTO connect.connected_profiles (
    user_id, display_name, account_standing, verification_status,
    verification_method, total_xp, completed_onboarding
  ) VALUES (
    p_user_id, NULL, 'active', 'pending', 'invite', 0, false
  );

  -- 5. Store invite chain
  INSERT INTO connect.invite_chains (invite_code_id, inviter_id, invitee_id)
    VALUES (v_invite_id, v_inviter_id, p_user_id);

  RETURN jsonb_build_object('ok', true, 'inviter_id', v_inviter_id);

EXCEPTION WHEN OTHERS THEN
  RAISE;
END;
$$;
```

**Note:** Verify actual column names and invite_chains table structure in existing migrations before writing final SQL. The above is derived from analogous patterns.

### Frontend: Auth Store Extension

```typescript
// Source: admin/src/store/authStore.ts (extend existing)
interface User {
  id: string;
  email: string;
  isAdmin: boolean;
  tier: 'inform' | 'connected' | 'empowered';
  completed_onboarding: boolean;
}
```

### Frontend: Redirect Validation Hook

```typescript
// Source: derived from CONTEXT.md decisions
function useRedirectParam(): string | null {
  const params = new URLSearchParams(window.location.search);
  const raw = params.get('redirect');
  if (!raw) return null;
  try {
    const url = new URL(raw);
    if (url.hostname === 'empowered.vote' || url.hostname.endsWith('.empowered.vote')) {
      return raw;
    }
  } catch { /* malformed */ }
  return null;
}
```

### Frontend: Post-Login Routing Logic

```typescript
// Source: derived from CONTEXT.md routing table + account.ts GET /me response shape
async function handlePostLogin(token: string, redirectTarget: string | null) {
  const me = await apiFetch<MeResponse>('/account/me');
  // Store tier, completed_onboarding, is_admin in authStore

  if (redirectTarget) {
    window.location.href = redirectTarget;
    return;
  }

  // All tiers currently land on /profile (dashboards are future phases)
  navigate('/profile');
}
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|-----------------|--------|
| Admin-only login page ("Empowered Accounts Admin") | Tier-neutral login for all civic users | Login.tsx is a full replacement |
| Signup = CompassV2 flow (no invite code) | Signup requires invite code + legal name, creates Connected profile atomically | New backend RPC + extended signup route |
| No `/signup` route in accounts app | `/signup` route with invite validation, covenant callout | New React page + route |
| Admin panel = separate app, no link from accounts | Admin flag users see "Admin Panel" link on profile page | `is_admin` added to `/api/account/me` |

**Deprecated/outdated by this phase:**
- The `Login.tsx` heading "Empowered Accounts Admin": replaced with "Sign in to Empowered Vote"
- Using `POST /api/connect/start` as the invite claim step for new user signups: replaced by atomic `signup_with_invite` RPC

---

## Open Questions

1. **`invite_codes` table schema — `invite_chains` confirmation**
   - What we know: `claimInviteCode()` exists in `inviteService.ts` and sets `is_claimed = true`, `claimed_by`, `claimed_at` on `connect.invite_codes`
   - What's unclear: Whether `connect.invite_chains` table exists or whether the chain is tracked differently (the `inviteService.ts` should be verified before writing the RPC)
   - Recommendation: Read `backend/src/lib/inviteService.ts` and relevant migration before writing `signup_with_invite` SQL

2. **`GET /api/account/me` — is_admin field cost**
   - What we know: `admin_users` table is service-role only. Adding an `is_admin` check to account.ts requires calling `supabaseAdmin.from('admin_users').select().eq('user_id', ...)` in the hot path of every `GET /api/account/me`
   - What's unclear: Whether this is acceptable performance-wise (it's a simple PK lookup) or whether the profile page should use a lazy `GET /api/admin/me` call
   - Recommendation: Add to `GET /api/account/me` — single lookup, PK-indexed, negligible cost. Avoids flicker on the profile page.

3. **Existing `POST /api/auth/signup` callers**
   - What we know: CompassV2 and CTC call `POST /api/auth/signup` with `{ email, password, guest_state? }`. Adding `legal_name` and `invite_code` as optional fields is backward-compatible.
   - What's unclear: Whether any caller will break if the response shape changes (it currently returns `{ id, message }`)
   - Recommendation: Keep response shape unchanged. `legal_name` + `invite_code` are optional; when absent, behavior is exactly as before.

4. **"Request Access" — where does captured email go?**
   - What we know: The CONTEXT.md says "captures email for admin review"
   - What's unclear: Is there a table for this, or does it just send an email to an admin address?
   - Recommendation: Create a `public.access_requests` table with `(id, email, requested_at)` via migration. Admin can view in admin panel or query directly. Simpler than an email pipeline.

---

## Sources

### Primary (HIGH confidence)
- Codebase direct read — `admin/src/pages/Login.tsx`: existing login page to replace
- Codebase direct read — `admin/src/App.tsx`: existing routing structure to extend
- Codebase direct read — `admin/src/store/authStore.ts`: auth state shape to extend
- Codebase direct read — `backend/src/routes/auth.ts`: signup + login routes to extend
- Codebase direct read — `backend/src/routes/connect.ts`: connect flow, RPC patterns
- Codebase direct read — `backend/src/middleware/requireAdmin.ts`: admin detection pattern
- Codebase direct read — `supabase/migrations/20260314000035_phase23_tier_promotion.sql`: `promote_to_connected` RPC as the model for `signup_with_invite`
- Codebase direct read — `admin/package.json`, `backend/package.json`: confirmed versions

### Secondary (MEDIUM confidence)
- CONTEXT.md decisions section: routing priority, trusted domain logic, form fields — treated as authoritative user decisions

### Tertiary (LOW confidence)
- `invite_chains` table assumption: derived from `adjustInviterToleranceRating` function which implies a chain table exists. Must verify in `inviteService.ts` before writing RPC.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries confirmed in package.json
- Architecture (RPC pattern): HIGH — directly modeled on existing `promote_to_connected` and `complete_connect_flow` RPCs
- Architecture (frontend routing): HIGH — existing `useNavigate` + `useAuthStore` patterns confirmed
- Pitfall (email confirmation timing): HIGH — existing auth.ts comments explicitly document this behavior
- Pitfall (open redirect): HIGH — standard security principle, no verification needed
- Open question (invite_chains): LOW — need to verify table structure in inviteService.ts

**Research date:** 2026-03-14
**Valid until:** 2026-04-14 (stable stack — no fast-moving dependencies)
