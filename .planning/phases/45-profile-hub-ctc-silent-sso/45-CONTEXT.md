# Phase 45: Profile Hub + CTC Silent SSO - Context

**Gathered:** 2026-03-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Profile Hub (`app/src`) and CTC (`C:\Project Test\frontend`) silently inherit the shared `ev_session` cookie on load — a user already logged in at accounts.empowered.vote arrives at either app already authenticated without a re-login prompt. Logout from either app calls `POST /api/auth/logout` to clear the shared cookie. New auth endpoints from Phase 44 are the only dependency; no new backend work is in scope.

</domain>

<decisions>
## Implementation Decisions

### Silent Check UX
- Show a generic app-level spinner (centered, same for both Profile Hub and CTC)
- Spinner appears only after a 150ms delay — fast session checks feel instant with no spinner flash
- 3-second timeout before treating the check as failed and falling through to unauthenticated state
- Both apps use the same pattern; no per-app custom skeleton

### CTC Token Conflict
- Silent SSO check runs **only if `ev_refresh_token` is absent from localStorage** — existing CTC sessions are not disrupted
- After a successful silent SSO check, tokens are written to localStorage under CTC's existing key names
- Tokens from `GET /api/auth/session` are used as-is — they are already rotated server-side; no second rotation needed
- Auth state dispatch approach: Claude's Discretion — inspect how CTC reads tokens from localStorage and match that initialization pattern

### Logout Destination
- After logout from either app: user stays on the same page, unauthenticated state renders, a brief toast confirms "You've been signed out"
- No confirmation dialog — logout executes immediately on click
- If `POST /api/auth/logout` fails (network error or 500): always clear local auth state regardless; user is logged out locally
- Whether CTC already has a logout button: Claude's Discretion — inspect CTC frontend and add or update as needed

### Failure Behavior
- On 5xx or timeout: retry once after a 1-second delay, then fall through silently to unauthenticated
- 401 = not logged in elsewhere; fall through silently immediately (no retry)
- CORS errors: fall through silently to unauthenticated — same as network failure
- Same retry logic for both Profile Hub and CTC — no per-app divergence

### Claude's Discretion
- How CTC dispatches auth state changes after writing tokens to localStorage (match existing CTC pattern)
- Whether CTC currently has a logout button (inspect frontend, add if missing)
- Exact spinner/loading component to use in each app (match each app's existing loading primitives)

</decisions>

<specifics>
## Specific Ideas

- Spinner delay pattern: show spinner only if check takes >150ms (standard debounce pattern — prevents flash for fast connections)
- "You've been signed out" toast on logout from both Profile Hub and CTC
- Retry only once on server failure — two total attempts before fall-through

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 45-profile-hub-ctc-silent-sso*
*Context gathered: 2026-03-24*
