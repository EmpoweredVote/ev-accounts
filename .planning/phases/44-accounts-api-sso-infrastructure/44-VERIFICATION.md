---
phase: 44-accounts-api-sso-infrastructure
verified: 2026-03-24T19:28:29Z
status: passed
score: 4/4 must-haves verified
re_verification: false
---

# Phase 44: Accounts API SSO Infrastructure — Verification Report

**Phase Goal:** The ev-accounts API issues and reads the shared `ev_session` cookie — the foundation all other phases depend on. A user who logs in receives the cookie; any app can silently exchange it for fresh tokens; logout clears it everywhere.
**Verified:** 2026-03-24T19:28:29Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|---------|
| 1 | After `POST /api/auth/login`, response includes `Set-Cookie: ev_session` with HttpOnly, Secure (prod), SameSite=Lax, Domain from env | ✓ VERIFIED | `res.cookie('ev_session', data.session.refresh_token, { ...evSessionCookieOptions(), maxAge: 30d })` at auth.ts:327. `evSessionCookieOptions()` sets `httpOnly:true`, `secure: env.NODE_ENV === 'production'`, `sameSite:'lax'`, `domain: env.COOKIE_DOMAIN ? env.COOKIE_DOMAIN : undefined`. Runs only after confirmed `data.session` is non-null. |
| 2 | `GET /api/auth/session` with valid cookie returns 200 `{ access_token, refresh_token }`; without cookie returns 401 with no body | ✓ VERIFIED | Route at auth.ts:361. Missing cookie → `res.status(401).end()`. Valid exchange → `res.status(200).json({ access_token, refresh_token })`. Error path also returns `res.status(401).end()`. Cookie is rotated with new refresh_token on every successful exchange (auth.ts:382). `supabaseAdmin.auth.refreshSession` called at auth.ts:368. No `authLimiter` applied to this route. |
| 3 | `POST /api/auth/logout` clears `ev_session` unconditionally (even when JWT is expired) and revokes Supabase session | ✓ VERIFIED | Logout route at auth.ts:403 is a 3-middleware chain: (1) pre-middleware clears cookie via `res.clearCookie('ev_session', evSessionCookieOptions())` at auth.ts:408 then calls `next()`, (2) `requireAuth`, (3) handler calls `signOutUser` + `recordLogout`. Cookie clear runs before requireAuth — so an expired JWT still gets the cookie cleared. |
| 4 | CORS responses include `Access-Control-Allow-Credentials: true` and exact-origin matching (no wildcard) for `*.empowered.vote` requests | ✓ VERIFIED | index.ts:52–65. `credentials: true` at index.ts:63. Origin function reads `CORS_ORIGIN` env var (comma-separated list), does exact `allowedOrigins.includes(origin)` match in production. Dev allows all origins. The `cors` package echoes back the requesting origin (not `*`) when the callback returns `true`, satisfying the `Access-Control-Allow-Origin: <exact origin>` requirement. |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `backend/src/lib/env.ts` | `COOKIE_DOMAIN` env var | ✓ VERIFIED | Line 12: `COOKIE_DOMAIN: z.string().optional().default('')`. Optional, defaults to empty string (host-only cookie for local dev). |
| `backend/src/index.ts` | cookie-parser middleware + CORS credentials config | ✓ VERIFIED | cookieParser imported (line 6), registered at line 46 (`app.use(cookieParser())`) before routes. CORS `credentials: true` at line 63. |
| `backend/src/routes/auth.ts` | Cookie set on login, cookie read+rotate on session, cookie clear on logout | ✓ VERIFIED | 2× `res.cookie('ev_session', ...)` (login:327, session:382); 2× `res.clearCookie('ev_session', ...)` (logout:408, session error:374). Single `evSessionCookieOptions()` helper ensures domain/path consistency. |
| `backend/package.json` | `cookie-parser` installed | ✓ VERIFIED | `"cookie-parser": "^1.4.7"` (dependencies:21); `"@types/cookie-parser": "^1.4.10"` (devDependencies:37). |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `backend/src/routes/auth.ts` | `backend/src/lib/env.ts` | `env.COOKIE_DOMAIN` for cookie domain option | ✓ WIRED | `import { env } from '../lib/env.js'` at auth.ts:12. `env.COOKIE_DOMAIN` used at auth.ts:22. |
| `backend/src/index.ts` | `cookie-parser` | `app.use(cookieParser())` before routes | ✓ WIRED | Registered at line 46, after `app.use(helmet())` (line 45) and before `cors()` (line 52) and all route registrations (lines 69+). |
| `backend/src/routes/auth.ts` | `supabaseAdmin.auth.refreshSession` | Token exchange in GET /session | ✓ WIRED | Called at auth.ts:368 with `{ refresh_token: refreshToken }`. Result used at auth.ts:372 (error check), 382 (cookie rotation), 387 (response). |
| `backend/src/routes/auth.ts` | `res.cookie('ev_session')` | Cookie rotation after refreshSession | ✓ WIRED | New `data.session.refresh_token` written back to `ev_session` cookie at auth.ts:382 on every successful exchange. |

### Requirements Coverage

| Requirement | Status | Notes |
|-------------|--------|-------|
| SSO-01: Login sets `ev_session` cookie | ✓ SATISFIED | Cookie set at auth.ts:327 with correct options |
| SSO-02: `GET /session` exchanges cookie for tokens, 401 on missing | ✓ SATISFIED | Route at auth.ts:361, no body on 401 (`res.status(401).end()`) |
| SSO-03: Logout clears cookie + revokes session | ✓ SATISFIED | Pre-requireAuth clear at auth.ts:408; Supabase revocation via `signOutUser` |
| SSO-04: CORS credentials support for all EV app origins | ✓ SATISFIED | `credentials: true` + origin function in index.ts:52–65 |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | — | — | No blocker or warning anti-patterns found |

TypeScript compilation (`npx tsc --noEmit`) passes with zero errors.

### Human Verification Required

The following behaviors require human testing to fully confirm (automated checks pass):

1. **Cookie Domain in Production**
   **Test:** Deploy to production, `POST /api/auth/login`, inspect `Set-Cookie` header in browser DevTools.
   **Expected:** `Set-Cookie: ev_session=...; Domain=.empowered.vote; HttpOnly; Secure; SameSite=Lax`
   **Why human:** `COOKIE_DOMAIN` is an env var; correctness of the production env var value (`.empowered.vote`) can only be confirmed against the actual Render environment config.

2. **Cross-App Cookie Inheritance**
   **Test:** Log in at `accounts.empowered.vote`, navigate to `app.empowered.vote`, observe `GET /api/auth/session` call from the second app.
   **Expected:** Second app silently inherits session — no login prompt.
   **Why human:** Browser subdomain cookie sharing requires confirming the `Domain=.empowered.vote` attribute propagates correctly across deployed origins, which can only be verified in a live multi-app environment.

3. **Logout on Expired JWT**
   **Test:** Allow access token to expire (1 hour), then `POST /api/auth/logout`.
   **Expected:** `ev_session` cookie is cleared (verify via `Set-Cookie: ev_session=; Max-Age=0`); response is 401; subsequent `GET /api/auth/session` returns 401.
   **Why human:** Token expiry cannot be simulated programmatically without either mocking or waiting; confirms the pre-requireAuth middleware clear works end-to-end.

### Gaps Summary

No gaps. All four must-haves are verified at all three levels (exists, substantive, wired). The implementation is complete and structurally sound.

The one nuance worth noting: `COOKIE_DOMAIN` defaults to empty string, which means in local development the cookie is host-only (no `Domain` attribute). This is correct and intentional — browsers reject `domain: 'localhost'`. Production behavior depends on the `COOKIE_DOMAIN=.empowered.vote` env var being correctly set in the Render environment, which is a deployment concern, not a code gap.

---

_Verified: 2026-03-24T19:28:29Z_
_Verifier: Claude (gsd-verifier)_
