# Phase 44: Accounts API SSO Infrastructure - Research

**Researched:** 2026-03-24
**Domain:** Express 4.x HTTP cookies, cross-origin credentialed requests, Supabase auth refresh
**Confidence:** HIGH

## Summary

Phase 44 is a pure Express 4.x backend change. The ev-accounts API already owns
login and logout in `backend/src/routes/auth.ts`. The work is: (1) inject a
`Set-Cookie` header into the existing login response, (2) add a `GET /api/auth/session`
endpoint that reads that cookie and calls `supabase.auth.refreshSession()`, (3) update
logout to also clear the cookie, and (4) tighten the CORS configuration to allow
credentialed cross-origin requests with exact-origin matching.

The standard Express pattern for reading cookies WITHOUT `cookie-parser` is
`req.cookies` (undefined — not available) vs. parsing `req.headers.cookie` manually.
Because `cookie-parser` is NOT in the current `package.json` dependencies, the
planner must include installing it (or use manual header parsing). Using
`cookie-parser` is the standard, minimal-dependency path.

The critical CORS constraint is that `Access-Control-Allow-Credentials: true` is
incompatible with `Access-Control-Allow-Origin: *`. The current dev config (`origin: '*'`)
must change so dev also uses explicit origins — or a dev-safe wildcard check is
implemented. Production already uses the `CORS_ORIGIN` env var (comma-separated list),
but the `cors` middleware config lacks `credentials: true`.

**Primary recommendation:** Install `cookie-parser`, add `COOKIE_DOMAIN` env var (defaults
to `.empowered.vote`; allow empty string for local dev where domain attribute must be
omitted entirely), add `credentials: true` to the cors config with origin as a function
that exact-matches allowed origins list, inject Set-Cookie in login, add the session
endpoint, and update logout.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `cookie-parser` | ^1.4.7 | Parse `Cookie` header into `req.cookies` | De-facto Express middleware; already typed via `@types/cookie-parser` |
| `cors` (already installed) | ^2.8.5 | CORS headers including `credentials: true` | Already in use; just needs config update |
| `@supabase/supabase-js` (already installed) | ^2.45.0 | `supabase.auth.refreshSession()` for token exchange | Already in use |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `@types/cookie-parser` | ^1.4.8 | TypeScript types for cookie-parser middleware | Required alongside cookie-parser since project uses TypeScript strict |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `cookie-parser` | Manual `req.headers.cookie` parse | cookie-parser is standard; manual parse is error-prone and unnecessary |
| `cookie-parser` | `@fastify/cookie` | Wrong framework entirely |

**Installation:**
```bash
npm install cookie-parser
npm install --save-dev @types/cookie-parser
```

## Architecture Patterns

### Recommended Project Structure

No new files or directories. All changes are in existing files:

```
backend/src/
├── index.ts              # Add cookie-parser middleware + update cors config
├── lib/
│   └── env.ts            # Add COOKIE_DOMAIN env var (optional with default)
└── routes/
    └── auth.ts           # Set-Cookie in login, new /session endpoint, clear cookie in logout
```

### Pattern 1: Setting an HttpOnly Cookie on Login

**What:** After a successful `signInWithEmail()`, call `res.cookie()` before `res.json()`.
`res.cookie()` appends a `Set-Cookie` header; it does NOT interfere with the JSON body.

**When to use:** Immediately after `data.session` is confirmed non-null in `POST /login`.

**Example:**
```typescript
// Source: Express 4.x docs — res.cookie(name, value, options)
res.cookie('ev_session', data.session.refresh_token, {
  httpOnly: true,
  secure: env.NODE_ENV === 'production',
  sameSite: 'lax',
  domain: env.COOKIE_DOMAIN || undefined,  // undefined = host-only (correct for dev)
  maxAge: 60 * 60 * 24 * 30 * 1000,       // 30 days in ms (matches Supabase refresh TTL)
});
```

Key points:
- `domain: undefined` vs `domain: '.empowered.vote'` — in dev, omit domain entirely.
  Setting `domain=localhost` causes the cookie to be rejected by browsers.
- `secure: true` only in production — local dev runs HTTP, `Secure` would silently
  drop the cookie and be very confusing to debug.
- `maxAge` is milliseconds in Express `res.cookie()` (NOT seconds). 30 days = 2,592,000,000 ms.
- Cookie value = `data.session.refresh_token` (not access_token — access tokens expire in ~1h,
  refresh tokens are long-lived).

### Pattern 2: Reading Cookie in GET /api/auth/session

**What:** Use `req.cookies.ev_session` (available after `cookie-parser` middleware), call
`supabaseAdmin.auth.refreshSession({ refresh_token })`, return the new tokens.

**When to use:** The new `GET /api/auth/session` endpoint.

**Example:**
```typescript
// Source: Supabase JS SDK — supabase.auth.refreshSession
router.get('/session', async (req: Request, res: Response): Promise<void> => {
  const refreshToken = req.cookies?.ev_session;
  if (!refreshToken) {
    res.status(401).end();  // No body — per SSO-02 requirement
    return;
  }

  const { data, error } = await supabaseAdmin.auth.refreshSession({
    refresh_token: refreshToken,
  });

  if (error || !data.session) {
    // Cookie present but token invalid/expired — clear the stale cookie
    res.clearCookie('ev_session', { domain: env.COOKIE_DOMAIN || undefined });
    res.status(401).end();
    return;
  }

  // Rotate the cookie with the new refresh_token (Supabase rotates on each refresh)
  res.cookie('ev_session', data.session.refresh_token, {
    httpOnly: true,
    secure: env.NODE_ENV === 'production',
    sameSite: 'lax',
    domain: env.COOKIE_DOMAIN || undefined,
    maxAge: 60 * 60 * 24 * 30 * 1000,
  });

  res.status(200).json({
    access_token: data.session.access_token,
    refresh_token: data.session.refresh_token,
  });
});
```

Important: Supabase rotates refresh tokens on each use (security by default). The
new `refresh_token` from `data.session` MUST replace the old one in the cookie or
the next `/session` call will fail with an invalid token error.

### Pattern 3: Clearing Cookie on Logout

**What:** Add `res.clearCookie()` call in the existing `POST /logout` handler.

**When to use:** After `signOutUser(accessToken)` is called (even if it errors).

**Example:**
```typescript
// After existing signOutUser + recordLogout calls:
res.clearCookie('ev_session', {
  domain: env.COOKIE_DOMAIN || undefined,
  path: '/',
});
```

`res.clearCookie()` sends `Set-Cookie: ev_session=; Max-Age=0; ...` — this is the
correct way to expire a cookie. The `domain` and `path` must exactly match the
cookie's original `domain` and `path` or browsers will not clear it.

### Pattern 4: CORS Configuration for Credentialed Requests

**What:** `Access-Control-Allow-Credentials: true` requires EXACT origin matching —
`*` wildcard is forbidden by the CORS spec when credentials are included.

**Current state:** `origin: '*'` in dev, `origin: [list]` in prod. Neither sets
`credentials: true`.

**Required change:**

```typescript
// Source: cors npm package docs — origin as a function for dynamic matching
const ALLOWED_ORIGINS = env.CORS_ORIGIN
  ? env.CORS_ORIGIN.split(',').map((o) => o.trim())
  : [];

app.use(
  cors({
    origin: (origin, callback) => {
      // Allow same-origin (no Origin header) and server-to-server requests
      if (!origin) return callback(null, true);
      if (env.NODE_ENV === 'development') return callback(null, true);
      if (ALLOWED_ORIGINS.includes(origin)) return callback(null, true);
      callback(new Error('Not allowed by CORS'));
    },
    credentials: true,
  })
);
```

Key insight: When `credentials: true`, the response header must be
`Access-Control-Allow-Origin: https://app.empowered.vote` (the exact requesting
origin), NOT `*`. The `cors` package handles this automatically when origin is
a function that calls `callback(null, true)` — it echoes back the request origin.

**Dev CORS note:** The current wildcard for dev will still work for browser fetches
WITHOUT credentials (same-origin Vite proxy calls). For cross-origin dev testing
of the SSO flow, the dev CORS check should pass `true` for any origin, which is
what the `if (env.NODE_ENV === 'development') return callback(null, true)` does.

### Pattern 5: Cookie-parser Middleware Registration

**What:** `cookie-parser` must be registered in `index.ts` before routes.

**Example:**
```typescript
import cookieParser from 'cookie-parser';
// ...
app.use(cookieParser());
app.use(express.json());
// routes follow
```

Order matters: `cookieParser()` before any route handler that reads `req.cookies`.

### Anti-Patterns to Avoid

- **Setting `domain=localhost`:** Browsers reject cookies with explicit domain=localhost.
  For local dev, omit the `domain` attribute entirely (use `undefined`, not empty string).
- **Using `secure: true` in dev:** Silently drops the cookie on HTTP connections.
  Check `NODE_ENV === 'production'`.
- **Returning JSON body on 401 from /session:** The requirement says "no error body"
  — use `res.status(401).end()` not `res.status(401).json({...})`.
- **Not rotating the refresh token:** Supabase invalidates the old refresh token when
  it issues a new one. Failing to update the cookie leaves clients unable to refresh.
- **Wildcard CORS with credentials:** `Access-Control-Allow-Origin: *` +
  `Access-Control-Allow-Credentials: true` violates CORS spec; browsers refuse the response.
- **Skipping cookie-parser but using req.cookies:** `req.cookies` is `undefined` without
  the middleware. The handler will silently 401 all requests — no error, just broken.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cookie header parsing | Manual `req.headers.cookie.split(';')` | `cookie-parser` | Handles edge cases: quoted values, encoded chars, multiple cookies |
| CORS preflight | Manual OPTIONS handler | `cors` package (already installed) | Already handles preflight; just needs `credentials: true` added |
| Token refresh | Custom Supabase HTTP call | `supabaseAdmin.auth.refreshSession()` | Official SDK method; handles error codes correctly |

**Key insight:** The entire phase is wiring — not building. Every primitive already
exists in installed libraries. The plan is configuration and route logic, not new
infrastructure.

## Common Pitfalls

### Pitfall 1: Cookie Domain Mismatch Between Set and Clear

**What goes wrong:** Cookie is set with `domain: '.empowered.vote'` but cleared
without specifying domain, or with a different path. Browser ignores the clear.

**Why it happens:** `res.clearCookie()` defaults: `path: '/'` but no domain.
If the original Set-Cookie had `domain=.empowered.vote`, the clear must also
specify `domain=.empowered.vote`.

**How to avoid:** Create a shared helper `cookieOptions()` that returns the
consistent options object, used in both `res.cookie()` and `res.clearCookie()`.

**Warning signs:** Manual testing shows logout succeeds (200) but cookie persists
in browser DevTools → Network tab.

### Pitfall 2: Supabase Refresh Token Rotation

**What goes wrong:** `/session` returns valid tokens, but the NEXT call to `/session`
returns 401 even though the cookie was never cleared.

**Why it happens:** Supabase uses single-use refresh tokens by default. After
`refreshSession()`, the old token is immediately invalidated. If the route doesn't
update the cookie with `data.session.refresh_token`, the stored cookie is now dead.

**How to avoid:** Always call `res.cookie('ev_session', data.session.refresh_token, ...)`
in the session endpoint BEFORE returning the response.

**Warning signs:** First `/session` call works; second call returns 401.

### Pitfall 3: CORS Preflight Fails for Credentialed Requests

**What goes wrong:** GET /api/auth/session gets a CORS error in the browser even
though the endpoint returns 200 for direct requests.

**Why it happens:** Browsers send OPTIONS preflight before cross-origin credentialed
requests. The preflight must receive `Access-Control-Allow-Credentials: true` and
an exact-matched `Access-Control-Allow-Origin`. The `cors` package handles this
automatically IF `credentials: true` is set in the config.

**How to avoid:** Ensure `credentials: true` is in the `cors()` config AND the
origin function returns the exact origin (callback(null, true), not callback(null, '*')).

**Warning signs:** Browser console shows "The value of the 'Access-Control-Allow-Origin'
header in the response must not be the wildcard '*' when the request's credentials
mode is 'include'."

### Pitfall 4: Logout Requires requireAuth — but Cookie Clearing Happens Even if JWT Is Missing

**What goes wrong:** User's JWT has already expired but cookie still exists. They
try to logout via `/api/auth/logout`, but `requireAuth` returns 401 before the
cookie-clear code runs. Cookie persists.

**Why it happens:** The current logout requires a valid JWT via `requireAuth`. For
SSO cookie clearing, the cookie should be clearable without a valid JWT — a user
whose JWT expired should still be able to clear the shared session cookie.

**How to avoid:** The phase plan should consider whether to add a separate
"cookie-only clear" path or make the cookie clearing happen even when `requireAuth`
fails. Best approach: add a distinct `POST /api/auth/logout-sso` endpoint OR
modify logout to try-clear the cookie before the 401 returns. The simplest approach
is to make cookie clearing happen in a middleware that runs before `requireAuth`.

**Warning signs:** Integration test where access token is expired but cookie exists
— POST /logout returns 401 and cookie is NOT cleared.

### Pitfall 5: SameSite=Lax and POST Requests

**What goes wrong:** Assuming SameSite=Lax blocks cross-site POSTs to logout.

**Why it happens:** SameSite=Lax sends cookies on cross-site GET navigations (top-level)
but NOT on cross-site POST, PUT, DELETE, etc. This is fine for the SSO architecture:
`GET /api/auth/session` gets the cookie. The `POST /api/auth/logout` is a credentialed
cross-site fetch, not a form POST navigation — browsers DO include cookies with `fetch()`
+ `credentials: 'include'` even with SameSite=Lax, because the Lax restriction only
applies to third-party context navigation, not same-site fetches from subdomain apps.

**How to avoid:** No action needed — this is not actually a problem. Document it so
the planner doesn't second-guess SameSite=Lax.

## Code Examples

### Supabase refreshSession — verified API signature

```typescript
// Source: @supabase/supabase-js v2 — auth.refreshSession
const { data, error } = await supabaseAdmin.auth.refreshSession({
  refresh_token: 'the-refresh-token-string',
});
// data.session.access_token  — new access token
// data.session.refresh_token — new refresh token (ROTATED — must store)
// data.session.expires_in    — seconds until access_token expires
// error                      — AuthApiError if token invalid/expired/revoked
```

### COOKIE_DOMAIN env var pattern

```typescript
// In env.ts (add to envSchema):
COOKIE_DOMAIN: z.string().optional().default(''),  // empty = host-only (dev)
// usage:
domain: env.COOKIE_DOMAIN ? env.COOKIE_DOMAIN : undefined,
// production .env: COOKIE_DOMAIN=.empowered.vote
// local dev .env: COOKIE_DOMAIN=  (empty or absent)
```

### res.cookie with all required attributes

```typescript
res.cookie('ev_session', refreshToken, {
  httpOnly: true,                                           // SSO-01: httpOnly required
  secure: env.NODE_ENV === 'production',                    // HTTPS-only in prod
  sameSite: 'lax',                                          // SSO-01: SameSite=Lax
  domain: env.COOKIE_DOMAIN ? env.COOKIE_DOMAIN : undefined, // SSO-01: .empowered.vote in prod
  maxAge: 30 * 24 * 60 * 60 * 1000,                        // 30 days in milliseconds
  path: '/',
});
```

### cors config with credentials support

```typescript
// In index.ts — replace existing cors() call
const allowedOrigins = env.CORS_ORIGIN
  ? env.CORS_ORIGIN.split(',').map((o) => o.trim())
  : [];

app.use(
  cors({
    origin: (origin, callback) => {
      if (!origin) return callback(null, true);          // server-to-server
      if (env.NODE_ENV === 'development') return callback(null, true);
      if (allowedOrigins.includes(origin)) return callback(null, true);
      callback(new Error(`CORS: origin ${origin} not allowed`));
    },
    credentials: true,                                   // required for cookie passing
  })
);
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| SameSite=None (required for cross-site cookies pre-2020) | SameSite=Lax (sufficient for subdomain SSO) | ~2020 browser updates | SameSite=Lax works because all EV apps share `.empowered.vote` — they're same-site |
| JWT-in-localStorage for cross-app auth | HttpOnly cookie + token exchange endpoint | SSO pattern matured ~2021 | Removes XSS attack surface from token storage |

**Deprecated/outdated:**
- `SameSite=None; Secure`: Required for truly cross-site cookies (different eTLD+1).
  Not needed here since all apps are `*.empowered.vote` (same site). Lax is correct.
- `document.cookie` localStorage sync: Old pattern where apps read cookies directly.
  The SSO design uses `GET /api/auth/session` API call instead — HttpOnly means
  JS cannot read the cookie, which is the security property we want.

## Open Questions

1. **Logout cookie-clear without valid JWT**
   - What we know: Current `POST /logout` requires `requireAuth` (valid JWT). If JWT
     has expired, logout returns 401 and cookie is never cleared.
   - What's unclear: Should the plan add a separate unauthenticated cookie-clear path?
     Or handle this in the same endpoint by doing cookie-clear before `requireAuth`?
   - Recommendation: The planner should address this in 44-01-PLAN. Simplest fix:
     move cookie-clear out of the `requireAuth` middleware chain — create a small
     inline middleware that clears the cookie unconditionally before `requireAuth`
     runs. This way even failed auth clears the cookie.

2. **CORS_ORIGIN env var in production — current value**
   - What we know: `CORS_ORIGIN` is optional in env.ts and used by existing cors config.
   - What's unclear: Whether the production Render env var currently includes all five
     app origins (`app.empowered.vote`, `compass.empowered.vote`, etc.) or just the
     admin UI origin.
   - Recommendation: The plan should note that `CORS_ORIGIN` must be updated in
     Render to include all `*.empowered.vote` app origins before deploying.

3. **Rate limiting on GET /api/auth/session**
   - What we know: The authLimiter (10 req / 15 min) is applied to login and signup.
   - What's unclear: Whether `/session` should be rate-limited. Apps may call it on
     every load — 10 req / 15 min could be too restrictive.
   - Recommendation: Either no rate limiter on `/session`, or a separate higher-limit
     limiter (e.g., 60 req / 15 min). The endpoint does one Supabase call and returns
     quickly — it's not a brute-force target.

## Sources

### Primary (HIGH confidence)
- Read `backend/src/routes/auth.ts` — current login, logout handler implementations
- Read `backend/src/index.ts` — current CORS config, middleware chain, no cookie-parser
- Read `backend/src/middleware/auth.ts` — requireAuth pattern, how JWT is extracted
- Read `backend/src/lib/authService.ts` — signOutUser uses `supabaseAdmin.auth.admin.signOut`
- Read `backend/src/lib/supabase.ts` — supabaseAdmin client (persistSession: false)
- Read `backend/src/lib/env.ts` — CORS_ORIGIN present and optional, no COOKIE_DOMAIN
- Read `backend/package.json` — `cookie-parser` NOT present; `cors` ^2.8.5 present

### Secondary (MEDIUM confidence)
- Express 4.x `res.cookie()` docs — `maxAge` is milliseconds, `domain` undefined = host-only
- `cors` npm package — `credentials: true` + origin function for exact-match
- Supabase JS v2 `auth.refreshSession()` — rotates refresh token on each call

### Tertiary (LOW confidence)
- SameSite=Lax behavior on subdomain cross-origin fetches — behavior is browser-spec
  compliant but worth smoke-testing in real browsers after implementation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — read package.json directly; cookie-parser absence confirmed
- Architecture: HIGH — read all relevant source files; patterns derived from existing code
- CORS credentials behavior: HIGH — well-specified in CORS spec; cors package behavior confirmed
- Supabase refresh token rotation: MEDIUM — based on Supabase docs knowledge; verify with
  a real refresh call during implementation
- Logout-without-JWT edge case: MEDIUM — identified from reading requireAuth; resolution
  approach is a planner decision

**Research date:** 2026-03-24
**Valid until:** 2026-04-24 (stable domain — Express, cors, cookie-parser APIs change infrequently)
