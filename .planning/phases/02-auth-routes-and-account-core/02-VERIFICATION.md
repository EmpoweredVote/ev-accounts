---
status: human_needed
phase: 02-auth-routes-and-account-core
verified: 2026-02-25T00:00:00Z
score: 3/4 must-haves fully verified from code; 1/4 requires live Supabase confirmation for TTL behavior
human_verification:
  - test: "Signup trigger creates public.users row"
    expected: "After POST /api/auth/signup returns 201, a row exists in public.users with matching id"
    why_human: "Trigger execution requires live Supabase; cannot be verified from code alone"
  - test: "GET /api/account/me returns full profile including tolerance_rating for Connected user"
    expected: "Authenticated Connected user receives 200 with connected_profile.tolerance_rating present; tolerance_rating absent from root"
    why_human: "Requires live Supabase with a Connected user record"
  - test: "PATCH /api/account/me display_name change persists across sessions"
    expected: "After PATCH returns 200 with updated display_name, subsequent GET /api/account/me returns the new display_name"
    why_human: "Persistence requires a live DB write and subsequent read"
  - test: "POST /api/auth/logout token invalidation window"
    expected: "Confirm TTL window is acceptable: Supabase session and refresh tokens immediately invalidated. Access token JWT valid until TTL expiry (~1 hour). Verify whether this window is acceptable for civic auth security model."
    why_human: "requireAuth uses JWKS-only verification which does not check Supabase session revocation. admin.signOut revokes session/refresh tokens but not the access token JWT itself. Documented intentional design but requires security-level human approval."
---

# Phase 2: Auth Routes and Account Core — Verification Report

**Phase Goal:** Users can create accounts, authenticate, and access their tier-appropriate profile — and the API enforces field-level privacy on every response
**Verified:** 2026-02-25
**Status:** human_needed
**Re-verification:** No — initial verification

All four must-haves are structurally implemented correctly. Three are fully verifiable from code. One (logout token invalidation) requires live Supabase confirmation due to a documented JWT TTL design tradeoff.

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | New user signs up; public.users record auto-created via trigger | VERIFIED (code) + ? (live) | Signup route correct; trigger in migration 002; no separate INSERT |
| 2 | GET /me returns own tolerance_rating; field privacy structurally enforced | VERIFIED | Whitelist serialization; nested in connected_profile; self-view only |
| 3 | Connected user PATCHes display_name; update persists | VERIFIED (code) + ? (live) | Middleware chain confirmed; UPDATE RLS present; 200 re-fetch |
| 4 | Logout invalidates session; subsequent requests return 401 | ? NEEDS HUMAN | admin.signOut(global) called; JWKS-only auth does not check revocation list; TTL window |

**Score:** 3/4 fully verified from code; 1/4 requires human confirmation of TTL behavior acceptability

---

## Required Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `backend/src/routes/auth.ts` | VERIFIED | signup/login/logout; rate-limited; requireAuth on logout |
| `backend/src/lib/authService.ts` | VERIFIED | signUpWithEmail, signInWithEmail, signOutUser; admin.signOut(token, global) |
| `backend/src/routes/account.ts` | VERIFIED | GET /me + PATCH /me; whitelist serialization; requireAuth+requireVerified+requireConnected on PATCH |
| `backend/src/middleware/requireVerified.ts` | VERIFIED | checks email_confirmed_at; returns 403 {code: EMAIL_NOT_VERIFIED} |
| `backend/src/middleware/tierGuards.ts` | VERIFIED | requireConnected checks existence AND verification_status=verified |
| `backend/src/index.ts` | VERIFIED | authRouter at /api/auth; accountRouter at /api/account |
| `supabase/migrations/20260225000013_rls_update_policies.sql` | VERIFIED | CREATE POLICY and column-level GRANT UPDATE for both tables |
| `tests/integration/auth.test.ts` | VERIFIED | validation tests; Supabase-dependent tests isolated in nested describes |
| `tests/integration/account.test.ts` | VERIFIED | ALLOWED_ME_KEYS whitelist; tolerance_rating/legal_name absence asserted |
| `tests/integration/architecture.test.ts` | VERIFIED | Allowlist includes lib/authService.ts and middleware/requireVerified.ts |

---

## Architecture Constraint Verification

| Rule | Status | Evidence |
|------|--------|---------|
| No supabaseAdmin in src/routes/ | VERIFIED | account.ts and auth.ts contain no supabaseAdmin references |
| supabaseAdmin only in allowlisted files | VERIFIED | 5-file allowlist in architecture.test.ts |
| All route handler DB reads use createUserClient | VERIFIED | account.ts uses createUserClient throughout |

---

## Must-Have 4: Logout Token Invalidation — Detail

`POST /api/auth/logout` calls `supabaseAdmin.auth.admin.signOut(accessToken, 'global')` which revokes the Supabase session and all refresh tokens server-side. However, `requireAuth` uses JWKS-only verification (`jwtVerify` from `jose`) which checks signature, expiry, issuer, and audience — but NOT Supabase's session revocation list.

An access token with remaining TTL (~1 hour Supabase default) will still pass JWKS verification after signOut. This is a documented, intentional design decision noted in the research and in code comments.

The must-have as stated ("subsequent authenticated requests return 401") is only fully true after the access token's natural TTL expiry. Human confirmation is needed that this tradeoff is acceptable.

---

## Human Verification Checklist

### 1. Signup trigger creates public.users row
**Test:** POST /api/auth/signup with a unique email and valid password
**Expected:** 201 response with `{ id, message }`; row in `public.users` with matching `id`; no separate INSERT

### 2. GET /api/account/me full response for Connected user
**Test:** GET /api/account/me with valid JWT from a Connected verified user
**Expected:** 200 with `connected_profile.tolerance_rating` as a number; `tolerance_rating` absent at root

### 3. PATCH /api/account/me display_name persists
**Test:** PATCH `{ display_name: "New Name" }`, then GET /api/account/me with same user's token
**Expected:** Both responses show the new display_name

### 4. Logout TTL window (security review)
**Test A:** After logout, attempt to use the access token within ~1 hour window
**Documented behavior:** May still succeed until TTL expires. Refresh token is immediately revoked.

**Security decision:** Is the ~1 hour TTL window acceptable for civic auth?
- If yes: current design is intentional and documented
- If no: reduce Supabase access token TTL in dashboard settings, or add session revocation check to requireAuth

---

## Anti-Patterns Found

| Location | Issue | Severity |
|----------|-------|---------|
| `middleware/auth.ts`, `middleware/tierGuards.ts` | `{ error: string }` response shape (not `{ code, message }`) | Warning — non-blocking, Phase 1 artifacts |
| `types/database.types.ts` | Placeholder type stub | Info — expected, regenerated from `supabase gen types` |

No blocking anti-patterns. No supabaseAdmin in routes. No DB row spreading.

---

_Verified: 2026-02-25_
_Verifier: Claude (gsd-verifier)_
