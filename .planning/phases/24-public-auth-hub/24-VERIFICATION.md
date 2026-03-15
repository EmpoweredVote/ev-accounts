---
phase: 24-public-auth-hub
verified: 2026-03-15T06:50:09Z
status: passed
score: 8/8 must-haves verified
re_verification: false
---

# Phase 24: Public Auth Hub Verification Report

**Phase Goal:** accounts.empowered.vote becomes the universal Connected Account portal - the login page is rebranded for civic participants, a /signup route creates Connected Accounts, post-login routing reflects the users actual tier, and other apps can redirect here with a ?redirect= param.
**Verified:** 2026-03-15T06:50:09Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1 | Login page shows Sign in to Empowered Vote (civic branding, not admin-first) | VERIFIED | admin/src/pages/Login.tsx line 91: h1 text is Sign in to Empowered Vote |
| 2 | Signup page collects email, password, legal name, invite code plus covenant callout | VERIFIED | admin/src/pages/Signup.tsx lines 181-240: all four fields; lines 166-172: covenant callout div |
| 3 | POST /api/auth/signup accepts invite_code and legal_name and calls signup_with_invite RPC | VERIFIED | backend/src/routes/auth.ts lines 159-199: adminRpc call with p_user_id, p_legal_name, p_invite_code confirmed |
| 4 | POST /api/auth/request-access endpoint exists | VERIFIED | backend/src/routes/auth.ts lines 382-399: full implementation calling insertAccessRequest |
| 5 | GET /api/account/me returns is_admin boolean | VERIFIED | backend/src/routes/account.ts line 118: is_admin: isAdmin in meResponse whitelist |
| 6 | After login routing goes to /profile not /admin | VERIFIED | admin/src/pages/Login.tsx line 70: navigate to /profile; App.tsx line 69: /profile under AuthGuard |
| 7 | ?redirect= validated against *.empowered.vote | VERIFIED | admin/src/lib/redirect.ts lines 12-13: hostname whitelist enforced |
| 8 | Migration 036 exists with signup_with_invite RPC and access_requests table | VERIFIED | supabase/migrations/20260314000036_phase24_signup_with_invite.sql: table at line 13, RPC at line 37 |

**Score:** 8/8 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| admin/src/pages/Login.tsx | Civic-branded login with redirect support | VERIFIED | 154 lines; default export; imported in App.tsx line 17 |
| admin/src/pages/Signup.tsx | Connected Account signup plus request-access modal | VERIFIED | 349 lines; default export; imported in App.tsx line 18 |
| admin/src/lib/redirect.ts | Redirect validation utility | VERIFIED | 33 lines; two named exports; imported in Login.tsx and Signup.tsx |
| backend/src/routes/auth.ts | Auth routes including signup and request-access | VERIFIED | 401 lines; POST /signup, POST /request-access, POST /login, POST /logout all present |
| backend/src/routes/account.ts | GET /me returns is_admin | VERIFIED | is_admin: isAdmin at line 118; isUserAdmin() called at line 76 |
| supabase/migrations/20260314000036_phase24_signup_with_invite.sql | access_requests table and signup_with_invite RPC | VERIFIED | Both present; SECURITY DEFINER and SET search_path applied |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| Login.tsx | /api/account/me | fetch plus setAuth | WIRED | Lines 48-64: fetches me after login, maps is_admin, tier, completedOnboarding |
| Login.tsx | /profile post-login route | navigate /profile | WIRED | Line 70: navigates to /profile when no validRedirect |
| Login.tsx | ?redirect= to window.location.href | getValidRedirect() | WIRED | Lines 18-19 and 67-68: reads redirect, navigates externally when valid |
| Signup.tsx | POST /api/auth/signup | fetch | WIRED | Lines 43-52: POSTs email, password, legal_name, invite_code |
| Signup.tsx | POST /api/auth/request-access | fetch in handleRequestAccess | WIRED | Lines 90-94: modal form POSTs to request-access endpoint |
| auth.ts signup handler | connect.signup_with_invite RPC | adminRpc() | WIRED | Lines 161-169: adminRpc with p_user_id, p_legal_name, p_invite_code in connect schema |
| account.ts GET /me | isUserAdmin() | adminService | WIRED | Line 76: called; result placed in meResponse at line 118 |
| redirect.ts | Login.tsx and Signup.tsx | named imports | WIRED | Both pages import getValidRedirect and getAppNameFromRedirect |

### Requirements Coverage

No REQUIREMENTS.md in scope for phase 24 (requirements dissolved after v1.2). All must-haves derived from phase goal and PLAN.md.

### Anti-Patterns Found

None detected. Scanned Login.tsx, Signup.tsx, redirect.ts, auth.ts signup and request-access handlers, account.ts GET /me, and migration 036 for TODO/FIXME, placeholder text, empty returns, and stub handlers. All handlers have substantive implementations.

### Human Verification Completed

Human verification was performed and approved on 2026-03-14. The following was confirmed:

1. **Login branding** - Login page displayed Sign in to Empowered Vote with correct civic framing.
2. **Signup flow** - Signup form created a Connected account using an invite code; all four fields accepted input correctly.
3. **Email confirmation** - Confirmation email was received and the link successfully activated the account.
4. **Post-login routing** - After login, the user landed on /profile (not /admin).
5. **Redirect callout** - When visiting with a ?redirect= param pointing to a *.empowered.vote URL, the callout appeared on both login and signup pages.

### Gaps Summary

No gaps. All eight must-haves verified against the actual codebase. The phase goal is fully achieved:

- Civic-branded login and signup pages exist with real implementations (no stubs).
- The signup handler atomically creates a Connected profile via the signup_with_invite RPC when both invite_code and legal_name are supplied.
- The request-access endpoint captures waitlist emails in the access_requests table.
- Post-login routing lands on /profile for all users; admins navigate separately to /admin from the profile page.
- Redirect validation restricts open-redirect to *.empowered.vote only, enforced in redirect.ts.
- GET /api/account/me returns is_admin so the frontend can gate admin navigation without a separate request.
- Migration 036 ships the access_requests table and signup_with_invite SECURITY DEFINER function with SET search_path and concurrent-claim protection via FOR UPDATE.

---

_Verified: 2026-03-15T06:50:09Z_
_Verifier: Claude (gsd-verifier)_
