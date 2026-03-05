# Phase 51: Compare Inline Picker - Context

**Gathered:** 2026-02-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can switch the compared politician directly on the compare page without reopening the full-screen modal. The existing CompareModal remains the entry point for initial politician selection. This phase adds an inline picker for quick switching once a comparison is active.

</domain>

<decisions>
## Implementation Decisions

### Picker placement & trigger
- Replace the politician header in ComparePanel with a clickable dropdown trigger
- Collapsed state shows: politician photo + name + chevron icon (▾)
- Same placement on mobile (Compare tab) — consistent across breakpoints
- Tapping the header area opens the inline picker

### Search & selection UX
- Each row in the picker shows photo + name + office title (same richness as CompareModal)
- Share the politician list data with CompareModal — avoid duplicate API fetches; if modal already loaded the list, inline picker gets it instantly
- Full keyboard navigation: arrow keys to navigate, Enter to select, Escape to close
- Include a "Clear comparison" option in the dropdown

### Switching behavior
- Radar chart animates a smooth morph from old politician's polygon to new one (react-spring already supports this)
- During API fetch for new stances: keep old polygon visible, then morph when new data arrives (no empty/loading state on chart)
- Both radar chart AND ComparePanel update to reflect the new politician
- If a topic was selected in ComparePanel, preserve that topic selection when switching — shows the new politician's stance on the same issue

### Modal coexistence
- Full CompareModal opens for initial politician selection (first time comparing) — no change to existing flow
- Once a politician is selected, inline picker handles all subsequent switching
- Small expand/browse button available to re-open the full modal from the compare page
- Clearing comparison (via picker dropdown or blue legend click) returns to the initial "Select a politician to compare" prompt state, where tapping opens the full modal again

### Claude's Discretion
- Inline picker list style (dropdown overlay vs inline expansion) — pick best pattern for space constraints
- Row density for inline picker (how to display photo/name/title in the dropdown)
- Exact position/style of the "re-open full modal" expand button
- Loading indicator for the search field while data loads (if not already cached)

</decisions>

<specifics>
## Specific Ideas

- The collapsed trigger should feel like a natural part of the ComparePanel header — photo + name + chevron, not a separate UI element bolted on
- The morph animation leverages what RadarChartCore already does with react-spring — updating compareData should naturally animate
- "Keep old polygon, then morph" means the transition is seamless: user never sees a blank chart

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 51-compare-inline-picker*
*Context gathered: 2026-02-28*
