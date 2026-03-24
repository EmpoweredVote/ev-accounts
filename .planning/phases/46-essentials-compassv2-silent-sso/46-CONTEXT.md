# Phase 46: Essentials + CompassV2 Silent SSO - Context

**Gathered:** 2026-03-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Both Essentials (`C:\Transparent Motivations\essentials`) and CompassV2 (`C:\EV-CompassV2`) silently inherit an active `ev_session` cookie on load. A user already logged in at any EV app arrives at either app in their authenticated state without a re-login prompt. Logout from either app clears the shared cookie. Uses the same pattern established in Phase 45 (Profile Hub + CTC).

Creating the session endpoint or modifying ev-accounts backend is out of scope — Phase 44 delivered that. This phase is frontend-only for two apps.

</domain>

<decisions>
## Implementation Decisions

### Check timing & render
- **Soft block pattern**: Hold the unauthenticated render while the session check fires — do not render Inform-baseline then upgrade in-place
- If the check resolves with a session, user lands in authenticated state with no flash or reflow
- **2-second timeout**: If `GET /api/auth/session` doesn't respond within 2 seconds, abort and render Inform-baseline silently
- Matches Phase 45 (AuthInitializer) pattern exactly — consistency across EV apps is the goal

### State transition UX
- **Silent upgrade**: No toast, no animation, no "Welcome back" notification — the soft block means users land in the right state the first time
- **No redirect on SSO success**: Upgrade state in-place; user stays on whatever page they loaded, including deep links
- CompassV2's calibration state and Essentials' jurisdiction-aware list both appear correctly on first render, not as a mid-render swap

### Failure handling
- **All failures = silent Inform-baseline**: 401 (no cookie), network error, and timeout all produce the same outcome — render Inform-baseline silently, no error surfaced to the user, no console.error
- **Once on initial load only**: Silent check fires when the app mounts, not on subsequent SPA route changes — in-memory auth state is source of truth after that

### Logout coordination
- **Always call `POST /api/auth/logout`**: Every logout path in both apps calls the ev-accounts logout endpoint, regardless of how the session was established (native login vs. SSO inheritance)
- **Complete local logout regardless**: If the `POST /api/auth/logout` call fails (network error, API down), clear local tokens and state anyway — user is logged out of the current app; shared cookie expires naturally
- Do not block or warn the user if the cookie-clear API call fails

### Claude's Discretion
- Exact placement of the AuthInitializer check (component vs. hook vs. top-level effect) — match each app's existing auth bootstrap pattern
- Whether to `console.warn` on timeout in development builds only
- Token storage after SSO exchange (match each app's existing localStorage key conventions)

</decisions>

<specifics>
## Specific Ideas

- "Matches Phase 45 pattern" is the strongest reference — Phase 45 (Profile Hub + CTC) is the authoritative implementation to replicate
- CompassV2 has a `publicFetch` flow and existing AuthInitializer — the session check should integrate with that, not add a parallel system
- Essentials has its own auth bootstrap — wire in before the unauthenticated state renders

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 46-essentials-compassv2-silent-sso*
*Context gathered: 2026-03-24*
