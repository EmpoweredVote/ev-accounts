# Phase 101: Candidate Profiles - Context

**Gathered:** 2026-03-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Candidates on the Election Central page link to full Essentials-style profile pages via `/candidate/:id`. Incumbents (with linked politician records) get full parity with Profile.jsx — compass card, legislative summary, judicial record. Challengers (race_candidates only) render a clean minimal profile with no empty loading states. Compass and verdict UI is wired up and self-gating so it activates automatically when data is imported in a future milestone.

</domain>

<decisions>
## Implementation Decisions

### Profile Page Architecture
- **D-01:** Unified CandidateProfile.jsx handles both incumbents and challengers at `/candidate/:id`. All candidate cards on Election Central route here regardless of incumbent status.
- **D-02:** When a candidate has a `politician_id` (incumbent), CandidateProfile fetches the full politician data — compass card, legislative summary, judicial record — achieving full parity with Profile.jsx. A state senator running for US Congress still shows their state legislative record.
- **D-03:** When a candidate has no `politician_id` (challenger), CandidateProfile renders only available data (name, photo, position sought, election banner) and skips legislative/compass API calls entirely — no empty loading states, no placeholder sections.

### Compass & Verdict Data
- **D-04:** CompassCard and Read & Rank verdict badge support are wired into CandidateProfile now. Both self-gate (only render when stance/quote data exists). Profiles look clean today and automatically light up when data is imported later.
- **D-05:** Actual compass stance research and quote collection for candidates is **deferred to a future milestone**. AI-assisted research is the planned approach, but not in scope for Phase 101.
- **D-06:** PROF-04 and PROF-05 (compass stances imported, sourced quotes imported) are **not achievable in this phase** — the profile UI wiring satisfies the architectural requirement, but data population is deferred.

### Challenger Profile Content
- **D-07:** Ship with current race_candidates fields only (name, photo, position, incumbent flag). No new schema columns (bio_text, campaign_website) in this phase.
- **D-08:** Architecture should accommodate future enrichment (campaign website scraping, interview data, etc.) — the profile renders whatever's available and hides what's not. But no enrichment pipeline work in this phase.

### Navigation & Linking
- **D-09:** All candidate cards on Election Central navigate to `/candidate/:id` using the race_candidates ID. Consistent URL pattern from the elections context.
- **D-10:** Back navigation uses the existing `ev:fromView` sessionStorage pattern (from Phase 99). If user came from Elections tab, back goes to Elections. If from Representatives, back goes to Representatives.

### Claude's Discretion
- How to detect politician_id linkage from race_candidates and conditionally fetch full vs minimal data
- Loading skeleton design for candidate profiles
- How PoliticianProfile (ev-ui) handles the minimal-data case for challengers
- Whether to add a candidate-specific API endpoint or extend the existing fetchPolitician to handle race_candidates IDs

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Candidate Profile
- `essentials/src/pages/CandidateProfile.jsx` — Current candidate profile page at `/candidate/:id`. Already fetches politician data, legislative summary, election info, and renders PoliticianProfile from ev-ui with election banners. **This is the file being extended.**
- `essentials/src/pages/Profile.jsx` — Full politician profile page at `/politician/:id`. Includes CompassCard, CampaignFinanceSection, judicial record — the parity target for incumbent candidates.

### Compass & Verdict Integration
- `essentials/src/components/CompassCard.jsx` — Compass comparison card component. Self-gates on `politicianIdsWithStances`. Must be added to CandidateProfile for incumbents.
- `essentials/src/contexts/CompassContext.jsx` — Provides compass state (userAnswers, selectedTopics, verdicts, etc.) used by CompassCard
- `ev-ui` package — `PoliticianProfile`, `StanceAccordion`, `RadarChartCore` components

### Election Data Layer
- `ev-accounts/backend/src/lib/electionService.ts` — Election query API, race_candidates data model
- `ev-accounts/backend/src/routes/essentialsPoliticians.ts` — `GET /api/essentials/politicians/:id/elections` endpoint
- `ev-accounts/backend/src/routes/essentialsCandidates.ts` — Existing candidate routes (for Empowered tier — different concept, but review for naming conflicts)

### Frontend Infrastructure
- `essentials/src/App.jsx` — Router definition, existing `/candidate/:id` route
- `essentials/src/lib/api.jsx` — API client functions (fetchPolitician, fetchLegislativeSummary, fetchJudicialRecord)
- `essentials/src/lib/auth.js` — apiFetch for authenticated API calls
- `essentials/src/utils/ballotStatus.js` — getSeatBallotStatus for election banner logic

### Prior Phase Context
- `.planning/phases/99-election-central-page/99-CONTEXT.md` — Election Central page decisions, candidate card pattern, tier grouping, seeded random ordering
- `.planning/phases/100-elected-appointed-filter/100-CONTEXT.md` — Elected/Appointed filter decisions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **CandidateProfile.jsx**: Already handles `/candidate/:id` with PoliticianProfile, election banners, back navigation. Needs CompassCard, legislative summary parity, and challenger-vs-incumbent branching.
- **Profile.jsx**: Full-parity reference — includes CompassCard, CampaignFinanceSection, judicial record. The target feature set for incumbent candidates.
- **CompassCard**: Self-gating component — only renders when politician has stance data. Can be dropped into CandidateProfile with no empty-state risk.
- **PoliticianProfile (ev-ui)**: Handles politician display. Need to verify it handles minimal data gracefully for challengers.
- **ev:fromView sessionStorage**: Already implemented in CandidateProfile.jsx for context-aware back navigation.

### Established Patterns
- **Conditional data fetching**: Profile.jsx uses Promise.all for parallel fetches, with individual try/catch per data source. CandidateProfile should follow same pattern, gating fetches on politician_id presence.
- **Election banner**: CandidateProfile.jsx already renders "Candidate for [position]" and "This seat is on the ballot" banners based on election data.
- **Self-gating sections**: CompassCard checks `politicianIdsWithStances` before rendering. Legislative sections check for data before rendering. This pattern means no explicit hide logic needed.

### Integration Points
- **CandidateProfile.jsx**: Add CompassCard import, add legislative/judicial data fetching when politician_id exists, handle challenger minimal render
- **race_candidates → politician_id**: Need to determine how the frontend gets the politician_id linkage to decide what to fetch
- **API**: May need a candidate-detail endpoint that returns race_candidates data + linked politician_id for the profile page to know what additional data to fetch

</code_context>

<specifics>
## Specific Ideas

- "If there was a state senator now running for US Congress, then their legislative record as a state senator is still relevant" — incumbent profiles should show ALL legislative history, not just the race they're running for
- "The goal is to have most information included where relevant" — compass data for everyone is the long-term vision, deferred to AI-assisted research in a future milestone
- Challenger profiles should be "clean and honest" — show what's available, don't show empty sections or placeholder text

</specifics>

<deferred>
## Deferred Ideas

- **AI-assisted compass stance research for candidates** — Use politician-stance-researcher agent to research positions across 21 topics. Deferred to future milestone.
- **Read & Rank quote collection for candidates** — Source quotes from campaign websites, interviews, town halls. Deferred to future milestone.
- **bio_text and campaign_website columns on race_candidates** — Schema enrichment for richer challenger profiles. Deferred to future milestone.
- **Campaign website scraping pipeline** — Automated enrichment of candidate data from their campaign sites. Deferred to future milestone.

</deferred>

---

*Phase: 101-candidate-profiles*
*Context gathered: 2026-03-30*
