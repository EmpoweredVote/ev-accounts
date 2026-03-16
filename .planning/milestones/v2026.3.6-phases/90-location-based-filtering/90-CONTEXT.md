# Phase 90: Location-Based Filtering - Context

**Gathered:** 2026-03-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Hub page gains an optional address input (Google Maps Places autocomplete) that filters issues to only show those with 2+ unique local representative quotes. Evaluation within a filtered issue only presents quotes from matched politicians. Cross-app context from Essentials auto-applies the filter via URL query param. No backend changes required — client-side filtering against POST /essentials/politicians/search results.

</domain>

<decisions>
## Implementation Decisions

### Address input UX
- Inline text field sits between the editorial header ("Choose an Issue") and the progress/issue cards
- Google Maps Places autocomplete with US restriction (same pattern as Essentials' useGooglePlacesAutocomplete hook — port to TypeScript in EV-readrank)
- Same Google Maps API key as Essentials, added as `VITE_GOOGLE_MAPS_API_KEY` in ReadRank's Cloudflare Pages env
- While searching: spinner on the input field, issue cards dim slightly (no full-page loader or skeleton replacement)
- After address is set: input collapses into a compact filter chip showing the address + X to clear, with "Showing N of M issues" count below
- Address + matched politician IDs persist in Zustand store (store version bump to v7), so returning users see the hub pre-filtered

### Filtering behavior
- Issues with fewer than 2 unique local politicians with quotes are hidden entirely (not grayed out)
- "Unique local politicians" = distinct politician IDs from the search results that have quotes in that issue — 2 quotes from the same rep doesn't count
- When filtering is active, EvaluationPhase filters quotesToEvaluate to only include quotes where candidateId matches a local politician — fewer cards, more relevant
- If address matches zero politicians with quotes across all issues: show inline warning message ("No representatives found with quotes for this address"), auto-clear filter, show all issues unfiltered
- Clearing the location filter restores the full unfiltered issue list

### Filtered state display
- Editorial header text ("Choose an Issue") stays the same regardless of filter state — filter chip + count already communicate filtering
- Issues completed while filtered retain their progress — no data loss on filter clear
- After clearing filter: issues that were completed while filtered show a subtle note that the evaluation only included local reps (warn about mixed data)

### Cross-app context (Essentials → ReadRank)
- Essentials passes address via URL query param: `readrank.empowered.vote?address=123+Main+St+LA+CA`
- SiteHeader's "Read & Rank" nav link appends `?address=` when user has an active address search in Essentials — no new UI, just dynamic href
- ReadRank on mount: parse `?address`, call POST /essentials/politicians/search, apply filter, persist to store, strip `?address` from URL
- URL param always overrides stored address — user explicitly navigated from Essentials with new address, honor that intent
- CORS: verify and update ALLOWED_ORIGINS on EV-Backend to include `readrank.empowered.vote` for the politicians/search endpoint (pre-deploy task, flagged in STATE.md)

### Claude's Discretion
- useGooglePlacesAutocomplete TypeScript port details
- Filter chip styling and animation
- Warning message styling for no-match and mixed-data scenarios
- Whether to debounce or batch the politician search + quote filter logic
- Store shape details beyond the decided `locationFilter: { address, politicianIds } | null`

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements
- `.planning/REQUIREMENTS.md` — LOC-01 through LOC-05 define location filtering acceptance criteria

### Prior phase context
- `.planning/phases/86-chrome-cleanup-store-migration/86-CONTEXT.md` — Store migration pattern (v2), Phase union, profile menu reset
- `.planning/phases/89-coach-marks/89-CONTEXT.md` — Store v6 migration pattern, latest store shape

### State decisions
- `.planning/STATE.md` — Accumulated decisions: "Location filtering is client-side only — POST /essentials/politicians/search + client filter; no backend changes required"; CORS and API key pre-deploy blockers

### Existing implementation references
- `essentials/src/hooks/useGooglePlacesAutocomplete.js` — Google Maps Places autocomplete hook to TypeScript-port
- `essentials/src/lib/api.jsx` lines 77-103 — `searchPoliticians()` function showing POST /essentials/politicians/search call pattern
- `EV-readrank/src/data/api.ts` — Quote fetching with candidateId on each quote (filter join point)
- `EV-readrank/src/components/IssueHub.tsx` — Current hub rendering (where address input and filtering logic integrate)
- `EV-readrank/src/store/useReadRankStore.ts` — Zustand store (v6 currently, bump to v7)
- `EV-readrank/src/utils/verdictFragment.ts` — Cross-app URL pattern reference (fragment encoding for verdicts)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `useGooglePlacesAutocomplete` (essentials): Full Google Maps Places autocomplete hook — needs TypeScript port to EV-readrank
- `searchPoliticians()` (essentials): POST /essentials/politicians/search call pattern — replicate in EV-readrank's api.ts
- `Quote.candidateId` field: Every quote already carries the politician UUID — filtering is a simple Set.has() check
- `getQuotesForIssue()`: Existing filter helper — location filter composes on top of this

### Established Patterns
- Zustand persist with version + migrate: Store at v6, bump to v7 with `locationFilter: null` migration
- `@googlemaps/js-api-loader`: Already a dependency in Essentials — add to EV-readrank
- Fragment/query param cross-app handoff: verdict fragment bridge (v2026.3.4) establishes the pattern; this uses query params instead

### Integration Points
- `IssueHub.tsx`: Add address input component above progress bar; filter `issues` array before rendering cards
- `EvaluationPhase.tsx`: When locationFilter active, filter `quotesToEvaluate` to local rep candidateIds only
- `useReadRankStore.ts`: Add `locationFilter` to store interface + initial state + v7 migration + partialize
- `App.tsx`: Parse `?address` query param on mount, trigger search + filter flow
- `ev-ui SiteHeader` (essentials integration): Dynamic href on "Read & Rank" nav link when address active
- `EV-Backend middleware.go`: Verify `readrank.empowered.vote` in ALLOWED_ORIGINS for POST endpoint

</code_context>

<specifics>
## Specific Ideas

- Filter chip pattern mirrors how Google Search shows active filters — compact, clearly dismissible
- The "Showing 3 of 5 issues" count reinforces that content is filtered without being alarming
- Mixed-data warning after clearing filter is low-key — a subtle note, not a blocking modal
- SiteHeader nav link dynamically carrying address context is elegant — zero new UI in Essentials

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 90-location-based-filtering*
*Context gathered: 2026-03-15*
