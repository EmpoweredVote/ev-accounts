# Phase 2: Auth Routes and Account Core - Context

**Gathered:** 2026-02-25
**Status:** Ready for planning

<domain>
## Phase Boundary

API routes for authentication (signup, login, logout) and account profile access (GET/PATCH /api/account/me). The API enforces field-level privacy on every response. No OAuth, no social auth, no password reset — those belong in other phases.

</domain>

<decisions>
## Implementation Decisions

### Sign-up and login behavior
- Sign-up returns a session immediately (access_token + refresh_token) on success
- Email verification is required — account is active but write-access is locked until verified
- Authenticated-but-unverified users have read-only access; write endpoints block with an appropriate error
- Login response shape: Claude's discretion (tokens only vs tokens + profile — pick what makes sense for this stack)

### Error response contract
- All errors use `{ code: string, message: string }` shape — flat, no nested details array
- Auth error specificity (distinct EMAIL_NOT_FOUND vs WRONG_PASSWORD codes): Claude's discretion — follow security best practices
- Validation error shape: Claude's discretion — stay within the flat `{ code, message }` contract
- HTTP status for valid JWT on suspended/deleted account: Claude's discretion — follow HTTP semantics

### Account/me response shape
- Always returns: id, email, display_name, tier, account_standing, created_at, and user settings/preferences
- `tolerance_rating` IS returned in self-view (success criteria explicitly requires owner to receive their own score)
- Connected-tier data (connected_profiles fields) inclusion strategy: Claude's discretion — inline vs separate endpoint
- Invite code inclusion in /account/me: Claude's discretion — may belong in a dedicated invites endpoint

### PATCH /account/me scope
- Editable fields: Claude's discretion — determine from requirements and schema what makes sense in Phase 2
- Connected+ tier only — PATCH is gated; Basic (pre-Connect) users cannot update profile fields
- Response on success: Claude's discretion — 200 with updated resource or 204, pick the right REST pattern
- Unrecognized or non-editable fields in body: Claude's discretion — pick the safer behavior (strip vs reject)

### Claude's Discretion
- Login response payload (tokens only vs tokens + basic profile)
- Auth error specificity (enumeration risk vs DX tradeoff)
- Validation error detail level
- HTTP status codes for account-state errors
- Whether connected_profiles data is inline or a separate endpoint in Phase 2
- Invite code placement in the API surface
- Full editable field set for PATCH /account/me
- PATCH response shape (200 updated resource vs 204 No Content)
- How PATCH handles non-editable fields in body

</decisions>

<specifics>
## Specific Ideas

No specific implementation references — open to standard patterns for Express + Supabase auth flows.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 02-auth-routes-and-account-core*
*Context gathered: 2026-02-25*
