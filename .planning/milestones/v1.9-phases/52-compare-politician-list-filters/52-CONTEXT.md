# Phase 52: Compare Politician List Filters - Context

**Gathered:** 2026-02-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can narrow the politician list in the compare picker by state and governance level. Filters apply in both the InlinePoliticianPicker dropdown and the full CompareModal. This phase adds filtering controls to existing picker components — it does not add new data sources or address-based lookup.

</domain>

<decisions>
## Implementation Decisions

### Filter placement & layout
- Filters sit below the search input, above the politician list in both pickers
- Pill/chip toggles for governance level, compact dropdown for state
- Filters appear in both InlinePoliticianPicker and CompareModal (consistent experience)
- Filters persist across dropdown open/close cycles — no visual indicator in collapsed state; user sees filtered results when they reopen

### Level filter design
- Three tiers only: Federal / State / Local
- Explicit "All" pill included (four pills total: All, Federal, State, Local)
- Each pill shows a count of matching politicians, e.g., `Federal (12)`
- Counts update dynamically when state filter is active
- Single-select — tapping one level deselects the previous
- Hide tier pills that have zero politicians entirely (don't show disabled/grayed out)

### State filter design
- Compact dropdown with "State" as default placeholder label (no filter applied)
- Only show states that have politicians with compass data — no empty states in the list
- Dynamic population — state list updates based on active level filter (e.g., selecting "Federal" may reduce available states)
- Alphabetical sort

### Filter interactions
- AND logic when both state and level filters are active simultaneously
- Individual clear ("x") per filter + a "Clear all" button that appears when any filter is active
- Disable impossible filter combinations where feasible (e.g., gray out level pills that would yield zero results for the selected state)
- Friendly empty message as fallback if edge cases produce zero results despite prevention
- If user switches level and their selected state is no longer valid for the new level, auto-clear the state filter with subtle visual feedback

### Claude's Discretion
- Exact pill sizing, spacing, and color treatment (active vs inactive states)
- State dropdown implementation (native select, custom dropdown, or combobox)
- "Clear all" button placement and style
- Transition/animation for filter state changes
- How to share filter state between InlinePoliticianPicker and CompareModal (shared hook, context, or independent)
- Mobile responsiveness of the filter row (wrapping, scrolling, sizing)

</decisions>

<specifics>
## Specific Ideas

- The pill counts give users immediate signal about data availability before tapping — reduces dead-end clicks
- Dynamic state list + impossible combo prevention means users should almost never hit a zero-results state
- Auto-clearing state when level changes keeps the experience fluid — no manual cleanup needed

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `usePoliticianList` hook (`CompassV2/src/hooks/usePoliticianList.js`): Module-level cached fetch of `/compass/politicians` — shared by both pickers, returns `{ politicians, loading }`
- `classifyCategory()` (`essentials/src/lib/classify.js`): Maps `district_type` to `{ tier, group }` — directly reusable for level filtering (tier = Federal/State/Local)
- `InlinePoliticianPicker` (`CompassV2/src/components/InlinePoliticianPicker.jsx`): Dropdown picker from Phase 51 with search, keyboard nav, scrollable list
- `CompareModal` (`CompassV2/src/components/CompareModal.jsx`): Full-screen modal picker with search

### Established Patterns
- Text search filtering: Both pickers use `useMemo` with normalized query matching — filter logic can follow same pattern
- Module-level caching in `usePoliticianList` means politician data is fetched once and shared
- Tailwind CSS for all styling — pills and dropdowns should use Tailwind classes

### Integration Points
- Politician objects from API include `district_type` and `representing_state` fields — both filter dimensions already in the data
- `classifyCategory()` lives in `essentials/src/lib/classify.js` — may need to import into CompassV2 or extract the tier logic
- Filter state needs to compose with existing text search (query + level + state all applied together)

</code_context>

<deferred>
## Deferred Ideas

- **Address-based filtering** — Wire essentials geocoding/ZIP lookup into the Compass compare flow so users can filter by "my representatives." This is a distinct capability (new data source integration) that deserves its own phase.

</deferred>

---

*Phase: 52-compare-politician-list-filters*
*Context gathered: 2026-02-28*
