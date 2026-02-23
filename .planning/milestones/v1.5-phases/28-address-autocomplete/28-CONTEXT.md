# Phase 28: Address Autocomplete - Context

**Gathered:** 2026-02-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace the ZIP code + address dual search with Google Maps Places autocomplete as the sole search input. Remove ZIP code path entirely. Show the validated address in results, handle coverage gaps, and degrade gracefully when Google Maps API is unavailable.

</domain>

<decisions>
## Implementation Decisions

### Search input transition
- Placeholder text: "Enter your address" — simple and direct
- Subheading changes to: "Enter your address to see who represents you" (drop ZIP reference)
- Selecting a Google suggestion fills the input field — user must click Search to navigate (not auto-search on select)
- If user types text but doesn't select a Google suggestion and hits Search: prompt them to select from the dropdown (e.g., "Please select an address from the suggestions") — don't submit raw text
- All ZIP code references and ZIP-only search paths are removed from both Landing and Results pages

### Address confirmation display (Results page layout reorganization)
- Address autocomplete search bar moves to the full-width top position (where "Search Representative" bar currently lives)
- "Search Representative" name filter moves into the left sidebar
- "Show Candidates" toggle moves into the left sidebar
- "Sort by" option is removed entirely
- Full formatted address shown in the search bar (e.g., "123 Main St, Bloomington, IN 47401") — not shortened
- The results page address bar has full Google Places autocomplete so users can re-search without going back to landing
- Address bar appears immediately on page load; results load below with loading skeletons

### Degraded mode behavior
- If Google Maps API fails to load: input is disabled, inline error message below it reads "Address search is temporarily unavailable. Please try again later."
- Subtle hint shown when autocomplete isn't working: small text below the input
- No fallback to raw text submission — without Google autocomplete, the search cannot produce valid results
- The "must select a suggestion" validation does not need to be relaxed because the input is disabled in degraded mode

### Claude's Discretion
- Loading skeleton design for results area
- Exact styling/positioning of the inline error message in degraded mode
- How the "please select a suggestion" validation hint appears (inline text, toast, etc.)
- Transition animations when navigating from landing to results

</decisions>

<specifics>
## Specific Ideas

- The existing `useGooglePlacesAutocomplete` hook already handles Places API loading and autocomplete attachment — extend rather than replace
- Landing page and Results page both need the autocomplete behavior (shared hook)
- Address bar in sidebar was problematic because long addresses overflow — that's why it moves to full-width top position
- The layout swap on Results: address gets prominence at top, filtering controls (name search, candidates toggle) consolidate in sidebar

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 28-address-autocomplete*
*Context gathered: 2026-02-22*
