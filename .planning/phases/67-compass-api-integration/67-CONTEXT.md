# Phase 67: Compass API Integration - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire existing compass API endpoints into Essentials for logged-in users and politician stances. Enable the Essentials app to fetch user compass answers, selected topics, topics list, and politician stance availability from the shared backend. Fix cookie domain for cross-app session sharing.

</domain>

<decisions>
## Implementation Decisions

### Auth State in Essentials
- Minimal indicator: small avatar/initials in nav bar right side when logged in
- Non-logged-in users see nothing in that spot (empty)
- Auth check (`/auth/me`) runs on every page load, not just profile pages
- Auth state feeds the nav indicator globally and the compass context provider

### Politician Stance Availability
- Eager fetch: call `GET /compass/politicians` on app load to get list of politician IDs with stances
- Compass badge on dashboard politician cards for those with stance data
- Hover on badge shows mini radar chart preview of politician's stances (+ user overlay if logged in)
- Mobile: tap badge to show preview (tooltip-style), tap outside to dismiss
- Currently 23 of ~800+ politicians have stances

### Cookie Domain Deployment
- Change cookie domain to `.empowered.vote` in this phase — required for cross-app sessions
- Environment-aware: production sets `Domain: .empowered.vote`, local dev keeps current behavior (no domain set)
- Existing dev/prod branching for Secure and SameSite already in auth/handlers.go — extend same pattern
- Small user base, forced re-login is acceptable
- Verify production `ALLOWED_ORIGINS` env var includes essentials.empowered.vote (hardcoded allow-list already has it, but secrets manager value needs confirmation)

### User Answers Fetch Pattern
- React Context provider (`CompassContext`) at the Essentials app root
- Context provides: isLoggedIn, userName, userAnswers (map), selectedTopics (user's 8 chosen topics), allTopics (full list), politicianIdsWithStances (set)
- All data fetched on mount: auth check, topics, selected topics, user answers (if logged in), politician stance list
- Existing `essentials/src/lib/compass.js` has fetchTopics() and fetchPoliticianAnswers() — add fetchUserAnswers() and fetchSelectedTopics() and fetchPoliticiansWithStances()

### Claude's Discretion
- Loading state design while compass data fetches
- Error handling for failed API calls (retry vs graceful degradation)
- Exact mini radar preview sizing and positioning
- Whether to cache compass data in the context or re-fetch on navigation

</decisions>

<specifics>
## Specific Ideas

- "I'd love for it to be something you can hover over to see the compass on hover" — the compass badge on dashboard cards should show a mini radar chart preview on hover (desktop) and on tap (mobile)
- Pattern should feel like a tooltip/popover, not a modal

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `essentials/src/lib/compass.js`: Already has fetchTopics(), fetchPoliticianAnswers(), buildAnswerMapByShortTitle() — add user-answer and selected-topics fetching
- `RadarChartCore` in ev-ui: Supports dual dataset overlay (pink/blue) — can power the mini hover preview
- `GET /compass/politicians` endpoint: Returns list of politicians with answers — use for stance availability
- `GET /compass/answers` (session-protected): Returns user's compass answers
- `GET /compass/selected-topics` (session-protected): Returns user's selected topic IDs

### Established Patterns
- All Essentials API calls use `credentials: "include"` — same pattern for compass calls
- CompassV2 uses a CompassContext for global state — mirror this pattern in Essentials
- CORS middleware echoes origin if in allow-list; `essentials.empowered.vote` already listed
- Cookie config has dev/prod branching (Secure, SameSite) — extend for Domain

### Integration Points
- `EV-Backend/internal/auth/handlers.go`: Cookie Domain change (LoginHandler, LogoutHandler)
- `EV-Backend/internal/middleware/middleware.go`: CORS allow-list already includes Essentials origins
- `essentials/src/App.jsx` or root: Wrap with CompassContext provider
- `essentials/src/pages/Dashboard.jsx`: Consume politicianIdsWithStances for badge display
- `essentials/src/pages/Profile.jsx`: Will consume user answers and politician data (Phase 69+)

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 67-compass-api-integration*
*Context gathered: 2026-03-06*
