# Phase 47: Validation Quests Silent SSO - Context

**Gathered:** 2026-03-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Add silent SSO session inheritance to Validation Quests. On app load, if Supabase reports no active session, silently call `GET /api/auth/session` (ev-accounts) and initialize via `supabase.auth.setSession({ access_token, refresh_token })`. On logout, call `POST /api/auth/logout` (clear shared `ev_session` cookie) before `supabase.auth.signOut()`. No accounts-side changes — this is a VQ-only frontend change.

</domain>

<decisions>
## Implementation Decisions

### Session check trigger
- Only fire the silent check when `supabase.auth.getSession()` returns null — skip entirely if Supabase already has a valid session
- Run the check inside an auth effect in VQ's top-level auth provider (co-located with existing auth logic)
- Apply a 3-second AbortController timeout on the `GET /api/auth/session` fetch; on timeout, fall through to unauthenticated state silently
- On mid-session SIGNED_OUT event (token expiry, revocation from another app): react to `onAuthStateChange`, render unauthenticated — do NOT re-attempt the SSO check

### Loading / transition UX
- Show a loading state only on the SSO check path (when `getSession()` returned null and we're waiting on the network call); native Supabase sessions render instantly
- Use VQ's existing app launch/loading state — no new loading treatment needed; SSO check slots into existing initialization
- Hold all routes behind auth loading state on first render — nothing renders until the check resolves (max wait: 3s)
- After SSO initializes, render the route the user requested (respect deep links); first-login detection runs as VQ-internal post-auth logic

### Failure handling
- All failure modes (401, 5xx, network timeout, `setSession()` rejection) degrade silently to unauthenticated state — no error banner, no user-facing message
- `console.error` with failure mode context (distinguish 401/expected from 5xx/timeout/unexpected) for debugging observability
- If `setSession()` rejects tokens returned from the endpoint: silent fallback, no retry
- Post-init auth errors (403, JWT expiry on Supabase queries): VQ's existing auth error handling applies — no SSO-specific behavior

### Logout coordination
- Order: `POST /api/auth/logout` first (clears shared `ev_session` cookie), then `supabase.auth.signOut()`
- If `POST /api/auth/logout` fails: continue to `supabase.auth.signOut()` regardless — failed cookie clear doesn't block VQ local logout
- Centralize in a `logout()` utility function — all VQ logout triggers call this single function
- Post-logout destination: VQ's current post-logout behavior unchanged

### Claude's Discretion
- Exact implementation structure of the auth provider effect
- How to thread `isAuthChecking` state through VQ's existing provider
- CORS credentials handling (`credentials: 'include'`) on the `GET /api/auth/session` fetch

</decisions>

<specifics>
## Specific Ideas

- VQ's first-login detection should be VQ-internal: on session initialization, check if user has any quests assigned (zero quests = first session = run onboarding initialization). No accounts-side signal needed.
- `verification_status = 'verified'` is already guaranteed for all alpha users (invite = verified). No Phase 47 change needed to satisfy VQ's feed gate.

</specifics>

<deferred>
## Deferred Ideas

- VQ onboarding initialization endpoint (`/api/onboarding/initialize`) — VQ-internal; no accounts changes required, out of Phase 47 scope
- `?onboarding=true` redirect param from accounts to VQ — coupling accounts to VQ's internal state; rejected in favor of VQ-internal first-login detection

</deferred>

---

*Phase: 47-validation-quests-silent-sso*
*Context gathered: 2026-03-24*
