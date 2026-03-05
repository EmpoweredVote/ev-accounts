# Phase 59: Frontend Profile Sections - Context

**Gathered:** 2026-03-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Display legislative activity on politician profiles — committees, leadership, voting records, and sponsored legislation — with graceful empty states when data is unavailable. Two-tier approach: lightweight inline summary on the existing profile card, plus a dedicated full legislative record page.

</domain>

<decisions>
## Implementation Decisions

### Section layout & placement
- **Two-tier design:** Inline summary embedded in the existing profile card (below bio/contact), plus a full legislative record on a separate page at `/politician/:id/record`
- Inline summary includes: topic tags, key stats (attendance %, bills advanced, leadership roles — whatever is available), most recent notable action in plain language, and a "View Full Legislative Record" link
- Topic tags should align with compass issue categories (citizen-friendly language like "Housing", "Climate", "Transit") — the mapping table from bill subjects/committee names to compass categories is deferred to a follow-up, but the UI slot for tags should exist
- Stats show whatever is available for that politician and skip the rest — no N/A placeholders or empty stat slots
- Full record page section order: Committees & Leadership first, Sponsored Legislation second, Voting Record third
- Full record page uses nested route: `/politician/:id/record`
- Build so it works with either UUID or future slug-based URLs — no hardcoded assumptions about ID format

### Data density (full record page)
- **Committees:** Name + role badge (Chair/Member/etc), flat list. No subcommittee grouping, chamber labels, or dates for now
- **Voting record:** Bill title/description + date + position badge (Yea/Nay) + overall outcome (Passed/Failed) + clickable link to source (Congress.gov, LegiScan, etc)
- **Sponsored legislation:** Bill number + title + status badge + introduction date + sponsor/cosponsor indicator. No inline summaries — summaries deferred to future bill detail view
- Default 20-25 items per section, "Show all" link to expand and load the full history

### Empty state design
- Inline summary on profile card **only renders when at least some legislative data exists** — politicians with zero legislative data (school board, sheriffs, etc) see the profile exactly as it is today
- "View Full Legislative Record" link appears whenever any legislative data exists, even if partial
- Full record page always shows all three section headers (Committees & Leadership, Sponsored Legislation, Voting Record)
- Empty sections display a brief factual/informative note explaining why data is unavailable — e.g., "Voting records are not available for this office" or "This body does not publish individual voting records"
- Tone: clear, concise, explains the gap without jargon. Not apologetic, not technical

### Year filter (replaces session toggle)
- **No session toggle** — "session" is insider language most citizens won't understand
- Year dropdown filter on Votes and Bills sections only — Committees & Leadership section stays unfiltered (current assignments)
- Default selection: "All" with items sorted most recent first
- Year options populated from the data (e.g., 2026, 2025, 2024)
- The 20-25 item default cap keeps "All" manageable; "Show all" expands within the selected year filter

### Claude's Discretion
- Exact inline summary layout and spacing within the profile card
- How topic tag pills are styled (colors, shapes — reference the screenshot for inspiration but don't replicate exactly)
- Loading states for the parallel API fetches
- How the "Show all" expansion works (append to list vs full page load)
- Empty state message wording per jurisdiction (as long as tone matches: factual, concise, informative)
- How year dropdown interacts with "Show all" (filter first, then expand — or expand then filter)

</decisions>

<specifics>
## Specific Ideas

- User shared screenshots showing the concept: inline summary with topic tag pills, stat line (attendance + bills + leadership role), latest action, and "View Full Legislative Record" button. Full record page with card-style committee rows (name + date + role badge), vote rows (title + date + Yea/Nay badge), and bill rows with status badges
- "I don't necessarily love the look" of the screenshots — they show the concept but the visual design should be refined. Use as structural reference, not pixel-perfect target
- Topic tags should feel like the compass issue categories — citizen-friendly language, not Congress.gov subject taxonomy
- Existing `CommitteeTable` component in ev-ui shows BallotReady committees (name + position) — the new legislative committee data is richer (role badges, chamber, subcommittee hierarchy) and should replace or augment this display
- The stats in the inline summary should be derived from real data, not hardcoded — attendance from vote positions, bill count from sponsored legislation with status != "Introduced", leadership from committee roles

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ev-ui/PoliticianProfile.jsx`: Main profile component — inline summary will be added below existing bio/contact info, above the children slot
- `ev-ui/CommitteeTable.jsx`: Existing committee table (name + position). May be replaced or extended for legislative committee data with role badges
- `ev-ui/tokens.js`: Design tokens (colors, fonts, spacing, etc) — all new components should use these
- `ev-ui/IssueTags.jsx`: Existing component — may be reusable or adaptable for topic tag pills
- `essentials/src/lib/api.jsx`: API fetch functions — needs new functions for legislative endpoints

### Established Patterns
- Profile page fetches one politician endpoint, passes data to PoliticianProfile as props
- ev-ui components use inline styles with tokens (not Tailwind classes) — consistent with PoliticianProfile pattern
- Components use `useMediaQuery` hook for mobile/desktop responsive behavior
- ev-ui published to GitHub npm registry, consumed by essentials app

### Integration Points
- 5 API endpoints ready: `GET /politician/{id}/committees`, `/leadership`, `/bills`, `/votes`, `/legislative-summary`
- Bills endpoint supports `?limit=` and `?all=true` query params
- Votes endpoint supports `?limit=` query param
- Legislative summary endpoint returns bounded overview (5 recent bills + votes) — useful for inline summary
- New route needed in essentials app: `/politician/:id/record`
- `fetchPolitician` in api.jsx currently fetches the base profile — parallel fetches needed for legislative data

</code_context>

<deferred>
## Deferred Ideas

- **Slug-based politician URLs** — Replace `/politician/:uuid` with `/politician/:name-state` for shareability and SEO. Affects all profile routing, not just legislative record. Phase 59 should be built to work with either scheme.
- **Topic tag mapping table** — Mapping from Congress.gov bill subjects and committee names to compass issue categories. May require adjusting compass categories to align with legislative topics. Build the UI slot now, ship the mapping later.
- **Bill detail view** — Expandable or linked view showing CRS plain-language summaries for individual bills. Summaries can be paragraph-length for federal bills.
- **Subcommittee grouping** — Federal reps sit on 8-15 subcommittees. Could group under parent committees for hierarchy. Start flat, add grouping if it gets unwieldy.
- **Compass category alignment audit** — Review whether current compass topic labels map cleanly to legislative subject areas. Adjust categories if needed so tags feel consistent across products.

</deferred>

---

*Phase: 59-frontend-profile-sections*
*Context gathered: 2026-03-03*
