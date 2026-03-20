# Phase 40: Frontend Auth Updates - Context

**Gathered:** 2026-03-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Switch all 4 frontend apps (CompassV2, Essentials, Read & Rank, Treasury Tracker) from cookie-based Go server auth to Bearer token auth against the ev-accounts API URL. This phase does NOT add new features to the frontends — only auth model and API URL changes. Formal Go server decommission is Phase 42.

</domain>

<decisions>
## Implementation Decisions

### Cutover strategy
- Simultaneous cutover — all 4 apps flip at the same time (not rolling)
- Staging-first verification before prod cutover
- 1–3 day monitoring window after prod cutover before Go server is decommissioned (Phase 42 handles formal decommission)
- A written cutover runbook is a required deliverable of this phase — three parties are involved (user/ED, Claude, Chris Andrews)

### App ownership
- All 4 apps are separate GitHub repos:
  - CompassV2: `https://github.com/EmpoweredVote/CompassV2`
  - Read & Rank: `https://github.com/EmpoweredVote/read-rank`
  - Essentials: `https://github.com/EmpoweredVote/essentials`
  - Treasury Tracker: `https://github.com/EmpoweredVote/treasury-tracker`
- This team (user + Claude) makes code changes directly — not a spec-for-Chris approach
- Chris Andrews developed all 4 frontends; user (Executive Director) has git access to all repos

### Token acquisition
- Supabase JS SDK directly — apps call `supabase.auth.signIn()` and extract `session.access_token`
- All 4 apps point to the **ev-accounts Supabase project** (same project as the backend API)
- HTTP interceptor or fetch wrapper handles Bearer token attachment automatically on every authenticated request — no per-request manual attachment
- ev-accounts API base URL stored as environment variable (`VITE_API_URL` or equivalent per app)

### User session handling
- Forced logout on cutover — old cookie sessions are invalid; users re-authenticate on next visit
- Brief banner on login screen: something like "We've made some improvements — please log in again" to prevent confusion
- Supabase default session behavior: 1-hour access token, silently auto-refreshed by SDK
- Treasury Tracker: optional auth — if a user is already logged in (Supabase session exists), send the Bearer token; public treasury data loads without auth either way

### Claude's Discretion
- Exact wording of the "please log in again" banner
- HTTP interceptor implementation pattern per app (depends on what fetch/axios pattern Chris already used)
- Env var naming convention per app (use whatever pattern already exists in each repo)

</decisions>

<specifics>
## Specific Ideas

- Treasury Tracker currently only shows Bloomington data — the optional auth decision was made with future location personalization in mind (user's jurisdiction → defaults to their home town/state). Not implemented in this phase but the auth plumbing should not block it later.
- Three-party coordination: user is Executive Director, Chris Andrews built the frontends, Claude makes the code changes. Runbook must be clear enough for all three to act from.

</specifics>

<deferred>
## Deferred Ideas

- **Treasury Tracker location personalization** — Route user's jurisdiction data to Treasury Tracker so it defaults to their home town/state on load. Currently Bloomington-only prototype. Needs a location-to-treasury routing mechanism; separate feature phase.

</deferred>

---

*Phase: 40-frontend-auth-updates*
*Context gathered: 2026-03-20*
