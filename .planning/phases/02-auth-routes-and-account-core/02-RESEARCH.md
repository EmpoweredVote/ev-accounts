# Phase 2: Auth Routes and Account Core - Research

**Researched:** 2026-02-25
**Domain:** Supabase Auth (email+password), Express route handlers, field-level privacy serialization, RLS UPDATE policies
**Confidence:** HIGH (primary sources: official Supabase docs, auth-js source code, project migrations)

---

## Summary

Phase 2 delivers five routes on top of the Phase 1 Express/Supabase foundation: `POST /api/auth/signup`, `POST /api/auth/login`, `POST /api/auth/logout`, `GET /api/account/me`, and `PATCH /api/account/me`. The primary technical challenges are (1) threading the user-scoped Supabase client correctly so the supabaseAdmin architecture ban is never violated, (2) enforcing field-level privacy (`tolerance_rating`, `legal_name`) at the serialization layer in addition to RLS, and (3) bridging the RLS gap: `public.users` and `connect.connected_profiles` have no UPDATE policies — those were explicitly deferred to Phase 2.

The standard pattern for this stack is: route handlers receive the access token from the JWT middleware (`req.accessToken`), construct a `createUserClient(accessToken)` for all database reads that feed the response body, and call `supabaseAdmin.auth.admin.signOut(jwt, 'global')` (a permitted use — admin auth operations, not data reads) for logout. Supabase returns a flat `{ data, error }` response from all auth methods. Email confirmation is enabled by default on hosted Supabase; `signUp()` returns `session: null` when email confirmation is pending, which is correct and expected.

The architecture enforcement test already blocks `supabaseAdmin` inside `src/routes/`. The logout handler is the edge case: the admin sign-out method (`supabaseAdmin.auth.admin.signOut`) must be called from a service layer or treated as a permitted pattern per the architecture test's current allowlist (currently only `lib/supabase.ts`, `middleware/auth.ts`, `middleware/tierGuards.ts`). The cleanest solution is a `src/lib/authService.ts` that encapsulates admin-scoped auth calls — imported from routes without the architecture ban being triggered (since only `supabaseAdmin` as a string is searched, not the import source).

**Primary recommendation:** Create a thin `src/lib/authService.ts` wrapper for Supabase auth calls, use `createUserClient` for all DB reads in routes, and add a new migration (013) that adds the missing UPDATE RLS policies on `public.users` and `connect.connected_profiles`.

---

## Standard Stack

The established libraries/tools for this domain:

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@supabase/supabase-js` | `^2.45.0` | Auth + DB client | Already installed; provides `signUp`, `signInWithPassword`, `signOut`, `auth.admin.signOut` |
| `express` | `^4.21.0` | HTTP routing | Already installed; route structure mirrors Phase 1 health route pattern |
| `zod` | `^3.23.0` | Request body validation | Already installed; parse req.body before any auth calls |
| `express-rate-limit` | `^7.4.0` | Auth endpoint rate limiting | Already installed; auth routes must be rate-limited per OWASP |
| `vitest` + `supertest` | Already installed | Integration testing | Established pattern from Phase 1 health tests |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `jose` | `^5.9.0` | JWT verification | Already used in `middleware/auth.ts`; no additional setup needed |
| `winston` | `^3.17.0` | Structured logging | Already installed; log auth events at INFO level, never log credentials |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Inline Zod in route | `zod-express-middleware` | Third-party middleware adds a dependency; hand-rolling a `validate(schema)` wrapper with Zod `safeParse` is 10 lines and already matches the project pattern |
| `scope: 'global'` for signOut | `scope: 'local'` | `global` revokes all sessions across devices — appropriate for a civic auth model; `local` is more permissive |

**No new packages required.** All dependencies are already in `backend/package.json`.

---

## Architecture Patterns

### Recommended Project Structure

New files for Phase 2:

```
backend/src/
├── lib/
│   └── authService.ts       # Wraps supabaseAdmin auth calls (signUp, signIn, signOut)
├── routes/
│   ├── auth.ts              # POST /api/auth/signup, /login, /logout
│   └── account.ts           # GET /api/account/me, PATCH /api/account/me
└── middleware/
    └── requireVerified.ts   # Checks email_confirmed_at; blocks unverified write access

supabase/migrations/
└── 20260225000013_rls_update_policies.sql  # UPDATE policies for public.users and connect.connected_profiles
```

### Pattern 1: Auth Service Wrapper

The architecture test scans `src/routes/` files for the string `supabaseAdmin`. `signUp`, `signInWithPassword`, and `admin.signOut` require the admin client (for signUp/signIn) or explicitly the admin API (signOut). Solution: wrap them in `src/lib/authService.ts`, which IS allowed to use `supabaseAdmin` (the test only checks files inside `src/routes/`).

**What:** A thin wrapper that delegates auth operations to Supabase and returns typed results.

**When to use:** All auth operations in route handlers — routes import from `authService`, not from `supabase`.

```typescript
// Source: Official Supabase docs + architecture test enforcement
// src/lib/authService.ts

import { supabaseAdmin } from './supabase.js';

export async function signUpWithEmail(email: string, password: string) {
  // Uses supabaseAdmin for signup — this is a trusted server-side operation
  // Route handlers MUST NOT import supabaseAdmin directly
  return supabaseAdmin.auth.signUp({ email, password });
}

export async function signInWithEmail(email: string, password: string) {
  // createClient with anon key also works for signIn, but using admin is fine
  // since signIn result (session/tokens) goes to client, not DB reads
  return supabaseAdmin.auth.signInWithPassword({ email, password });
}

export async function signOutUser(accessToken: string) {
  // admin.signOut revokes the refresh token server-side (scope: global)
  // This is the correct server-side invalidation method
  return supabaseAdmin.auth.admin.signOut(accessToken, 'global');
}
```

**Note on architecture test:** The current test checks for the string `supabaseAdmin` in files under `src/routes/`. Since `authService.ts` lives in `src/lib/`, it is allowed. The test also checks `supabaseAdmin` exists ONLY in its allowlist files (`lib/supabase.ts`, `middleware/auth.ts`, `middleware/tierGuards.ts`). Adding `lib/authService.ts` to the allowlist is required — this is a deliberate extension of the permitted pattern.

### Pattern 2: User-Scoped Client for DB Reads

All database reads that feed the response body use `createUserClient(req.accessToken)`. This is already the established pattern.

```typescript
// Source: Phase 1 middleware/auth.ts + lib/supabase.ts
// src/routes/account.ts

import { createUserClient } from '../lib/supabase.js';
import type { AuthenticatedRequest } from '../middleware/auth.js';

router.get('/', requireAuth, async (req: AuthenticatedRequest, res) => {
  const db = createUserClient(req.accessToken);

  // RLS enforced: user can only read their own row
  const { data: user, error } = await db
    .schema('public')
    .from('users')
    .select('id, display_name, avatar_url, created_at')
    .eq('id', req.userId)
    .single();

  // ...
});
```

### Pattern 3: Email Verification Middleware

Supabase `signUp` with email confirmation enabled returns `session: null`. Users who complete signup but haven't confirmed email can still log in after confirmation. The CONTEXT.md decision: "Authenticated-but-unverified users have read-only access; write endpoints block."

The JWT `email` claim is present. Email confirmation status is NOT in the JWT — it must be checked via `supabaseAdmin.auth.admin.getUserById(userId)` or the user's `email_confirmed_at` field from `auth.getUser()`.

**Recommendation:** For `PATCH /api/account/me` (write access), use a `requireVerified` middleware that calls `supabaseAdmin.auth.admin.getUserById(req.userId)` and checks `user.email_confirmed_at !== null`. This is a trusted server-side check (not a data read for the response body), so it follows the same pattern as `middleware/auth.ts`.

```typescript
// src/middleware/requireVerified.ts
import { supabaseAdmin } from '../lib/supabase.js';
import type { AuthenticatedRequest } from './auth.js';

export async function requireVerified(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  const { data: { user }, error } = await supabaseAdmin.auth.admin.getUserById(req.userId);

  if (error || !user?.email_confirmed_at) {
    res.status(403).json({
      code: 'EMAIL_NOT_VERIFIED',
      message: 'Email verification required for this action',
    });
    return;
  }
  next();
}
```

### Pattern 4: Tier Detection from DB

The schema design is "tier by child record presence." To determine tier for `GET /api/account/me`, the route must check whether `connected_profiles` and `empowered_profiles` rows exist for the user. Use `createUserClient` for connected_profiles (RLS: owner-only) and the public read for empowered (anon + authenticated can SELECT).

```typescript
// Tier detection pattern using user-scoped client
const db = createUserClient(req.accessToken);

// Check Connected tier (RLS: owner-only on base table)
const { data: connected } = await db
  .schema('connect')
  .from('connected_profiles')
  .select('id, display_name, account_standing, verification_status, tolerance_rating, xp, gem_balance, created_at')
  .eq('user_id', req.userId)
  .maybeSingle();

// Check Empowered tier (public select on active + owner sees own inactive)
const { data: empowered } = await db
  .schema('empower')
  .from('empowered_profiles')
  .select('id, legal_name, is_active, candidate_page_slug, empowered_at')
  .eq('user_id', req.userId)
  .maybeSingle();

// Tier = presence of child record
const tier = empowered ? 'empowered' : connected ? 'connected' : 'inform';
```

### Pattern 5: Field-Level Privacy at Serialization

`tolerance_rating` must NEVER appear in non-owner responses. Since `GET /api/account/me` is always the owner's own view, it CAN include `tolerance_rating` from `connected_profiles` (per SUCCESS CRITERIA #2). `legal_name` is owner-only for empowered tier — also safe here since it's the owner view.

The privacy contract: always serialize from a whitelist, never a blacklist. Build the response object explicitly — do not spread `connected` or `empowered` directly.

```typescript
// Correct: whitelist serialization
const meResponse = {
  id: user.id,
  email: authUser.email, // from auth.getUser() or stored in public.users
  display_name: user.display_name,
  avatar_url: user.avatar_url,
  tier,
  account_standing: connected?.account_standing ?? 'active',
  created_at: user.created_at,
  // tolerance_rating: included only in self-view (owner calling /me)
  ...(connected && {
    tolerance_rating: connected.tolerance_rating,  // owner sees own score
    xp: connected.xp,
    gem_balance: connected.gem_balance,
    verification_status: connected.verification_status,
  }),
  ...(empowered && {
    legal_name: empowered.legal_name,  // owner sees own legal_name
    candidate_page_slug: empowered.candidate_page_slug,
    is_active: empowered.is_active,
  }),
};
```

### Pattern 6: PATCH /api/account/me — Editable Fields

Based on requirements (AUTH-05) and schema analysis:

**`public.users` editable fields** (requires new UPDATE RLS policy in migration 013):
- `display_name` — basic profile update
- `avatar_url` — avatar URL update

**`connect.connected_profiles` editable fields** (Connected+ tier only, requires UPDATE RLS policy):
- `display_name` — Connected display name (separate from public.users; AUTH-05 specifies this)

**NOT editable via PATCH /api/account/me in Phase 2:**
- `tolerance_rating` — internal, computed by system
- `legal_name` — set during empowerment flow (Phase 5)
- `verification_status`, `verification_method`, `verified_region` — set during Connect flow (Phase 3)
- `account_standing` — admin-only
- `xp`, `gem_balance` — computed/ledger-based

**Recommendation for non-editable fields in body:** Strip silently (not reject). A 422 for unknown fields is a poor DX for a mobile app posting a partial payload. Strip unknown keys after Zod parse using `schema.strip()` (Zod default behavior with `.object()`).

**PATCH response shape:** 200 with the updated resource. Reason: The client needs the server-computed values (e.g., `updated_at`) to stay in sync. 204 forces an extra GET round-trip.

### Pattern 7: Missing UPDATE RLS Policies (Migration 013 Required)

The Phase 1 migration comments explicitly stated: "No UPDATE policy: Updates go through application service functions (Phase 2 /account/me PATCH)."

Phase 2 MUST ship a new migration adding these policies:

```sql
-- Migration 013: UPDATE RLS policies for Phase 2 PATCH /api/account/me
BEGIN;

-- public.users: owner can update display_name and avatar_url
CREATE POLICY "users: owner update"
  ON public.users
  FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = id AND deleted_at IS NULL)
  WITH CHECK ((select auth.uid()) = id AND deleted_at IS NULL);

-- Grant UPDATE permission to authenticated role
GRANT UPDATE (display_name, avatar_url, updated_at) ON public.users TO authenticated;

-- connect.connected_profiles: owner can update display_name
CREATE POLICY "connected_profiles: owner update"
  ON connect.connected_profiles
  FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = user_id AND deleted_at IS NULL)
  WITH CHECK ((select auth.uid()) = user_id AND deleted_at IS NULL);

-- Grant UPDATE permission (column-restricted)
GRANT UPDATE (display_name, updated_at) ON connect.connected_profiles TO authenticated;

COMMIT;
```

**Why column-level GRANT matters:** Supabase RLS alone does not prevent a user from sending an UPDATE that changes `tolerance_rating` to an arbitrary value if they know the column name. Column-level GRANTs restrict which columns the `authenticated` role can actually update, providing defense-in-depth alongside Zod input validation.

### Anti-Patterns to Avoid

- **Spreading full DB row into response:** `res.json({ ...connected })` would expose `tolerance_rating` to the owner response as-is BUT the test framework asserts ABSENCE — always build response object explicitly from named fields.
- **Using supabaseAdmin in route handlers:** Architecture test will fail. Put admin calls in `src/lib/authService.ts` or `src/middleware/`.
- **Chaining JS awaits for updates:** Only public.users update is a single-table operation in Phase 2 — safe. Any future multi-table writes must go through RPC.
- **Generic error response for email not confirmed:** Supabase returns `error.code === 'email_not_confirmed'` on login for unverified users. Map this explicitly; don't return the raw Supabase error to the client.

---

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Session management | Custom JWT issuance/storage | Supabase Auth `signUp`/`signInWithPassword` | Supabase handles hashing, salting, token generation; JWTs verified by existing JWKS middleware |
| Email verification emails | Custom SMTP integration | Supabase Auth (built-in confirmation emails) | Already configured per project auth settings; trigger link redirect is dashboard config |
| Server-side session invalidation | Token blocklist in Redis | `supabaseAdmin.auth.admin.signOut(jwt, 'global')` | Revokes all refresh tokens server-side; access token expires naturally (short TTL) |
| Request body validation | Manual `if (!req.body.email)` checks | Zod `safeParse` | Type narrowing, composable schemas, clear error messages |
| Rate limiting auth endpoints | Manual counter + Redis | `express-rate-limit` (already installed) | Handles `X-RateLimit-*` headers, configurable windows |
| Tier detection | Status flag checks | Child record presence queries | Already the project pattern — `connected_profiles` row exists = Connected |

**Key insight:** Supabase Auth handles the hard parts (credential storage, token generation, refresh). The Express layer's job is routing, validation, and field-level response shaping.

---

## Common Pitfalls

### Pitfall 1: signUp Returns session: null (Email Confirmation)

**What goes wrong:** Developer calls `signUp`, gets `session: null` in response, assumes failure. The route returns an error.

**Why it happens:** Supabase returns `session: null` when "Confirm email" is enabled in the Supabase dashboard (default for hosted projects). The signup itself succeeded — a `public.users` row was created by the trigger, and a confirmation email was sent.

**How to avoid:** The signup response should check for `data.user` (not `data.session`). Return 201 with `{ user_id, message: 'Check your email to confirm your account' }`. Do NOT treat `session: null` as an error.

**Warning signs:** Route returning 500 or 400 on signUp even though the Supabase dashboard shows a new user in `auth.users`.

### Pitfall 2: supabaseAdmin in Route Handler Fails Architecture Test

**What goes wrong:** Developer imports `supabaseAdmin` in a route file to call `auth.admin.signOut`. Architecture test (`architecture.test.ts`) fails immediately.

**Why it happens:** The test scans all `.ts` files under `src/routes/` for the string `supabaseAdmin`.

**How to avoid:** All admin-client auth calls must go through `src/lib/authService.ts`. The allowlist in the architecture test must be updated to include `lib/authService.ts`.

**Warning signs:** `vitest` reports `Architecture violation: the following route files reference supabaseAdmin`.

### Pitfall 3: Missing UPDATE RLS Policy Causes Postgres Permission Denied

**What goes wrong:** PATCH /api/account/me calls `db.from('users').update({display_name}).eq('id', userId)` using `createUserClient`. Supabase returns a `42501: permission denied` error.

**Why it happens:** `public.users` has no UPDATE RLS policy (migration 007 explicitly deferred this). Without an UPDATE policy, RLS denies all non-service-role updates.

**How to avoid:** Migration 013 must be written and applied before PATCH routes are tested.

**Warning signs:** PATCH returns 500 with Supabase error containing `42501` or `permission denied for table users`.

### Pitfall 4: Exposing Raw Supabase Error Codes to Client

**What goes wrong:** The route catches `supabaseAdmin.auth.signInWithPassword` error and sends `res.json({ error })` directly. Client receives Supabase internals like `invalid_credentials` or full error stack.

**Why it happens:** Supabase errors are developer-friendly but not user-safe.

**How to avoid:** Map Supabase error codes to the project's `{ code, message }` contract:
- `invalid_credentials` → `{ code: 'INVALID_CREDENTIALS', message: 'Invalid email or password' }` — **do NOT distinguish** email vs password (enumeration risk)
- `email_not_confirmed` → `{ code: 'EMAIL_NOT_VERIFIED', message: 'Please verify your email before logging in' }` — this IS distinguishable; it is a UX-necessary distinction (user needs to check email), not an enumeration risk
- `email_exists` → `{ code: 'EMAIL_EXISTS', message: 'An account with this email already exists' }` — note: this IS an enumeration signal; evaluate whether to make it generic; for Alpha (invite-only) it's acceptable

**Warning signs:** API response body contains `"code": "invalid_credentials"` or Supabase error message strings.

### Pitfall 5: tolerance_rating in Non-Owner Response

**What goes wrong:** Developer uses `select('*')` on `connect.connected_profiles` and spreads the result into the response. `tolerance_rating` appears in the response body even though this is a self-view.

**Why it happens:** The RLS policy on `connected_profiles` base table (owner-only SELECT) correctly returns `tolerance_rating` to the owner — so RLS doesn't block it. The risk is accidental exposure when building responses for OTHER users in future phases.

**How to avoid:** ALWAYS serialize from a named field list. Never spread DB rows. Write tests that assert `res.body.tolerance_rating` is `undefined` for non-owner callers (Phase 4/5 tests).

**Warning signs:** Success criteria #2 test (`different authenticated user calling the same endpoint cannot see that field`) would catch this if mock data is set up correctly.

### Pitfall 6: email Field Not in public.users

**What goes wrong:** GET /api/account/me tries to read `email` from `public.users` — it doesn't exist there. Email lives in `auth.users`.

**Why it happens:** The schema design keeps `auth.users` and `public.users` separate. `public.users` has: `id`, `display_name`, `avatar_url`, `deleted_at`, `created_at`, `updated_at`.

**How to avoid:** For the `GET /api/account/me` response, email must come from `createUserClient(req.accessToken).auth.getUser()`. The `getUser()` method makes a network request to validate the JWT and returns the full user including email. This is the correct and secure approach for server-side user identity.

```typescript
// Correct: email from auth.getUser()
const { data: { user: authUser } } = await createUserClient(req.accessToken).auth.getUser();
const email = authUser?.email; // confirmed email from auth.users
```

### Pitfall 7: architecture.test.ts Allowlist Not Updated

**What goes wrong:** `authService.ts` is added in `src/lib/` and uses `supabaseAdmin`. The second architecture test (`supabaseAdmin exists only in expected files`) fails because `lib/authService.ts` is not in the allowlist.

**How to avoid:** Update `tests/integration/architecture.test.ts` to add `lib/authService.ts` to the `allowedFiles` array.

---

## Code Examples

Verified patterns from official sources:

### signUp (email + password)

```typescript
// Source: https://supabase.com/docs/reference/javascript/auth-signup
// When "Confirm email" is ON: returns { data: { user, session: null }, error: null }
// When "Confirm email" is OFF: returns { data: { user, session: {...} }, error: null }
const { data, error } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'secure-password',
});

// data.user.id is set even when session is null
// The public.users trigger fires on auth.users INSERT (before signUp returns)
```

### signInWithPassword

```typescript
// Source: https://supabase.com/docs/reference/javascript/auth-signinwithpassword
// Session object: { access_token, refresh_token, expires_in, expires_at, token_type: 'bearer', user }
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'secure-password',
});

// On success: data.session.access_token + data.session.refresh_token
// Supabase error code for wrong email OR wrong password: 'invalid_credentials'
// Supabase error code for unverified email login attempt: 'email_not_confirmed'
```

### admin.signOut (server-side session invalidation)

```typescript
// Source: https://github.com/supabase/auth-js/blob/master/src/GoTrueAdminApi.ts
// Revokes all refresh tokens for this user (scope: 'global')
// Access token remains valid until exp — short TTL (typically 1 hour)
const { data, error } = await supabaseAdmin.auth.admin.signOut(
  accessToken, // the user's current JWT
  'global'     // 'local' | 'global' | 'others'
);
```

### getUser (get email from auth server)

```typescript
// Source: https://supabase.com/docs/reference/javascript/auth-getuser
// Makes a network call — validates JWT on the Supabase Auth server
// Use for server-side identity confirmation
const { data: { user }, error } = await createUserClient(accessToken).auth.getUser();
// user.email — confirmed email address
// user.email_confirmed_at — null if unverified, timestamp if verified
// user.id === req.userId (confirmed by JWT + server validation)
```

### Zod schema for signup body

```typescript
// Source: Zod docs + project conventions
import { z } from 'zod';

const SignUpSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

// In route handler:
const result = SignUpSchema.safeParse(req.body);
if (!result.success) {
  res.status(422).json({
    code: 'VALIDATION_ERROR',
    message: result.error.issues.map(i => i.message).join('; '),
  });
  return;
}
const { email, password } = result.data;
```

### Rate limiting auth routes

```typescript
// Source: express-rate-limit docs (already installed)
import rateLimit from 'express-rate-limit';

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10,                   // 10 attempts per window per IP
  standardHeaders: true,
  legacyHeaders: false,
  message: { code: 'RATE_LIMIT_EXCEEDED', message: 'Too many requests, please try again later' },
});

// Apply to signup and login only
router.post('/signup', authLimiter, signupHandler);
router.post('/login', authLimiter, loginHandler);
```

---

## Key Decisions (Claude's Discretion Resolved)

### Login Response Payload

**Decision:** Return tokens + minimal profile in login response.

**Rationale:** A mobile/SPA client calling login immediately needs tier and account_standing to route the user to the correct screen. Making a separate GET /api/account/me immediately after login is wasteful. Login response: `{ access_token, refresh_token, expires_in, expires_at, token_type, user: { id, email, tier, account_standing, display_name } }`.

### Auth Error Specificity

**Decision:** Single generic code for credential failure; specific code for email-not-confirmed.

**Rationale:** `INVALID_CREDENTIALS` for both wrong-email and wrong-password (enumeration protection, OWASP recommendation). `EMAIL_NOT_VERIFIED` for confirmed-email-required case — this is NOT an enumeration risk (attacker already knows the email exists to trigger this; the useful signal is UX for legitimate users who forgot to verify).

### Validation Error Detail Level

**Decision:** Include first validation failure as a human-readable message.

**Rationale:** The flat `{ code, message }` contract allows this. `code: 'VALIDATION_ERROR'`, `message: 'password: String must contain at least 8 character(s)'`. Enough detail for debugging; no nested arrays.

### HTTP Status for Account State Errors

**Decision:** 403 Forbidden for suspended accounts.

**Rationale:** 401 means "authenticate again" — wrong, the JWT is valid. 403 means "authenticated but access denied" — correct semantics for a suspended account. The existing `requireAuth` middleware already returns 403 for suspended accounts. Consistent with existing Phase 1 middleware.

### Connected-Tier Data in /account/me

**Decision:** Inline in the same endpoint.

**Rationale:** This is the owner's self-view. A separate endpoint for connected_profiles would require two round-trips for the most common app use case. Inline is simpler and matches what the success criteria test expects (owner calls GET /api/account/me and receives tolerance_rating).

### Invite Code Placement

**Decision:** NOT in /api/account/me for Phase 2. Invite codes belong in Phase 3 (Alpha Enrollment). No invite system exists yet.

### PATCH Response Shape

**Decision:** 200 with updated resource.

**Rationale:** Clients need `updated_at` and possibly other server-computed fields. 200 eliminates the need for a follow-up GET.

### PATCH Non-Editable Fields

**Decision:** Strip silently (not reject).

**Rationale:** Zod `.object()` by default strips unknown keys. A client posting `{ display_name: 'Alice', tolerance_rating: 5 }` gets `tolerance_rating` ignored without an error. This is the safer DX for API evolution — adding new fields to the schema later won't break existing clients.

### PATCH Editable Fields (Phase 2 scope)

**Decision:** `display_name` on both `public.users` and `connect.connected_profiles` (Connected+ only); `avatar_url` on `public.users`.

**Rationale:** AUTH-05 explicitly mentions display name updates. `avatar_url` is a logical companion. No other profile fields belong in Phase 2 (legal_name = Phase 5, preferences = TBD, verified fields = Phase 3).

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `@supabase/auth-helpers-*` | `@supabase/ssr` | 2023 | Auth helpers deprecated; project already uses `@supabase/ssr` |
| `supabase.auth.api.signOut(jwt)` (v1 API) | `supabaseAdmin.auth.admin.signOut(jwt, scope)` (v2 API) | supabase-js v2 | The old v1 path no longer exists |
| `jsonwebtoken` + `jwks-rsa` | `jose` + `createRemoteJWKSet` | Post May 2025 | ES256 default; already implemented in Phase 1 |
| `getSession()` for server-side identity | `getUser()` for server-side identity | supabase-js v2 | `getSession()` is insecure on server; `getUser()` validates with auth server |

**Deprecated/outdated:**
- `supabase.auth.session()` (v1) — does not exist in v2
- `supabase.auth.user()` (v1) — does not exist in v2; use `supabase.auth.getUser()`
- `@supabase/auth-helpers-*` — deprecated, project correctly uses `@supabase/ssr`

---

## Open Questions

1. **Architecture test allowlist update**
   - What we know: `architecture.test.ts` has a hardcoded allowlist of files permitted to use `supabaseAdmin`
   - What's unclear: Whether the plan should update the test to add `lib/authService.ts`, or use a different strategy
   - Recommendation: Update the allowlist in the architecture test. The comment in the test explains the intent — `lib/authService.ts` fits the "trusted server-side operations" permitted pattern.

2. **Email value in /account/me response**
   - What we know: `email` is NOT in `public.users`; it lives in `auth.users`
   - What's unclear: Whether the plan should call `createUserClient.auth.getUser()` (network round-trip) or assume email is stable enough to skip re-validation on every GET
   - Recommendation: Call `getUser()` once per request to GET /api/account/me. The extra network call is small relative to the DB queries already made. Supabase caches this internally per JWKS rotation.

3. **connected_profiles UPDATE GRANT scope**
   - What we know: Column-level GRANT should restrict what authenticated role can update
   - What's unclear: Whether `GRANT UPDATE (display_name, updated_at)` on `connect.connected_profiles` is sufficient or if `verification_status` should also be grantable for Phase 3
   - Recommendation: Phase 2 grants only `display_name` and `updated_at`. Phase 3 can extend.

4. **Supabase signUp "Confirm email" setting**
   - What we know: The CONTEXT.md decision is "email verification is required — account is active but write-access is locked until verified"
   - What's unclear: Whether this requires changing the Supabase dashboard setting (which is default ON for hosted) or relies purely on application-layer enforcement
   - Recommendation: Rely on Supabase's default "Confirm email = ON" for hosted projects. Document this in the environment setup notes. The route behavior (read-only until `email_confirmed_at` is set) is enforced by the `requireVerified` middleware regardless.

---

## Sources

### Primary (HIGH confidence)

- `https://github.com/supabase/auth-js/blob/master/src/GoTrueAdminApi.ts` — `auth.admin.signOut` method signature and implementation
- `https://supabase.com/docs/reference/javascript/auth-signup` — signUp behavior with email confirmation enabled
- `https://supabase.com/docs/reference/javascript/auth-signout` — signOut scopes (global/local/others)
- `https://supabase.com/docs/guides/auth/debugging/error-codes` — Supabase auth error codes (`invalid_credentials`, `email_not_confirmed`, `email_exists`, `weak_password`)
- `https://supabase.com/docs/guides/auth/jwt-fields` — JWT claim list (confirms `email_confirmed_at` is NOT in the JWT)
- `https://supabase.com/docs/reference/javascript/auth-getuser` — getUser vs getSession distinction for server-side use
- `C:\EV-Accounts\supabase\migrations\20260224000007_rls_public.sql` — confirms no UPDATE policy exists on public.users
- `C:\EV-Accounts\supabase\migrations\20260224000011_grant_schema_permissions.sql` — confirms no UPDATE GRANT on public.users or connected_profiles
- `C:\EV-Accounts\tests\integration\architecture.test.ts` — exact allowlist of files permitted to use supabaseAdmin

### Secondary (MEDIUM confidence)

- `https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/403` — 403 semantics for suspended accounts
- `https://auth0.com/blog/forbidden-unauthorized-http-status-codes/` — 401 vs 403 decision rationale
- `https://cheatsheetseries.owasp.org/cheatsheets/REST_Security_Cheat_Sheet.html` — auth enumeration prevention (use generic credentials error)
- `https://supabase.com/docs/guides/auth/signout` — signOut scope behavior and JWT access token caveat

### Tertiary (LOW confidence)

- `https://til.unessa.net/supabase/properly-sign-out/` — blog post about server-side signOut with DB session deletion; the admin.signOut approach is the correct SDK-native solution; the DB RPC approach in this article is older workaround

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all packages already in package.json, verified against project files
- Architecture: HIGH — based on existing Phase 1 code structure + official Supabase auth-js source
- RLS gap: HIGH — directly verified from reading migration files; no speculation
- Auth error codes: HIGH — official Supabase error codes page
- Pitfalls: HIGH — derived from verified code analysis and official docs
- Discretionary decisions: MEDIUM — reasoned from requirements, schema, and API semantics; no single authoritative source dictates these choices

**Research date:** 2026-02-25
**Valid until:** 2026-03-25 (Supabase auth-js API is stable; no rapid API changes expected)
