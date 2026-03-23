# Phase 95: Entity Switcher - Context

**Gathered:** 2026-03-22
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can navigate between all available jurisdictions (Bloomington, Ellettsville, Monroe County, LA County, LA City) in a single Treasury Tracker session without reloading the page. The entity switcher replaces the existing non-functional City/State/Federal tabs, updates all page content dynamically, and reflects selection state in the URL for shareability.

</domain>

<decisions>
## Implementation Decisions

### Switcher Placement & Style
- **D-01:** Replace the existing City/State/Federal NavigationTabs with an entity dropdown in the same header position. The current tabs are non-functional placeholders — clean swap, no new UI real estate needed.
- **D-02:** Entities grouped by `entity_type` (Cities, Counties) in the dropdown menu, matching the DB model from Phase 92.
- **D-03:** Display format is "Name, ST" — e.g., "Bloomington, IN", "Monroe County, IN", "Los Angeles, CA". Compact and familiar.

### Hero Card Adaptation
- **D-04:** Hero title updates dynamically to "{Entity Name} Finances" per selected entity. Background photo changes per entity.
- **D-05:** Entity photos stored as a `hero_image_url` column on the `treasury.municipalities` DB table. Returned by the municipalities list API endpoint.
- **D-06:** Info cards: hide the "per resident" calculation when population data is unavailable for an entity. Show total budget amount regardless.

### Data Loading on Switch
- **D-07:** Show a spinner overlay on the content area while loading new entity data. Keep the header/switcher interactive during load.
- **D-08:** Persist year and dataset selection when switching entities. If the new entity lacks data for the selected year, fall back to its most recent available year.
- **D-09:** Dataset tabs that have no data for the current entity are shown but disabled (grayed out, non-clickable) with a tooltip like "No salary data available".

### URL & Deep Linking
- **D-10:** Selected entity reflected in URL via query parameter: `?entity=bloomington-in`. Shareable and bookmarkable. Falls back to default if param missing.
- **D-11:** Year and dataset also in URL query params: `?entity=la-county-ca&year=2024&dataset=revenue`. All three params optional with sensible defaults.
- **D-12:** Default entity when no query parameter is present: Bloomington, IN (the original and most complete dataset).

### Claude's Discretion
- Entity slug format for URL params (e.g., `bloomington-in` vs `bloomington-indiana`)
- API endpoint design for listing municipalities with their available datasets/years
- Spinner implementation details (CSS animation vs library)
- How to derive available years per entity (API response metadata vs separate endpoint)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Treasury Tracker Frontend
- `treasury-tracker/src/App.tsx` — Main app component with hardcoded Bloomington references to replace
- `treasury-tracker/src/data/dataLoader.ts` — Data loader already parameterized by municipalityName, cache keyed by name-year-dataset
- `treasury-tracker/src/components/NavigationTabs.tsx` — Component to replace with entity dropdown
- `treasury-tracker/src/components/datasets/DatasetTabs.tsx` — Dataset tabs that need disabled state support
- `treasury-tracker/src/components/Breadcrumb.tsx` — Breadcrumbs that reference hardcoded "City" label
- `treasury-tracker/src/components/YearSelector.tsx` — Year selector with hardcoded year list

### Backend
- `EV-Backend/internal/treasury/` — Treasury module with Municipality model
- `.planning/phases/92-schema-foundation-bloomington-migration/92-CONTEXT.md` — Municipality model rename decisions (D-04, D-05)

### Prior Phase Context
- `.planning/phases/93-indiana-data-import/93-CONTEXT.md` — Config-driven display names (D-08)
- `.planning/phases/94-la-data-import/94-CONTEXT.md` — Socrata import config pattern (D-02, D-09)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `dataLoader.ts` — Already accepts municipalityName param and caches by name-year-dataset. Core data loading logic is entity-agnostic.
- `DatasetTabs` component — Exists but needs disabled state support added.
- `YearSelector` component — Exists, needs to accept dynamic year list per entity.
- `Breadcrumb` component — Exists, needs entity name instead of hardcoded "City".
- `SiteHeader` from ev-ui — Already used, no changes needed.

### Established Patterns
- State management via React useState hooks (no external state library).
- Data fetching via useEffect with loading/error states.
- API base URL from `VITE_API_URL` env var.
- Cache invalidation by key composition (`municipalityName-year-dataset`).

### Integration Points
- `NavigationTabs` import in App.tsx → replace with new EntitySwitcher component.
- `loadBudgetData` calls on lines 75 and 95 → parameterize with selected entity.
- Hero section JSX (lines 289-303) → make dynamic based on selected entity.
- Breadcrumb items construction (lines 153-175) → replace "City" with entity name.
- `getDatasetDisplayText` function (lines 25-46) → replace "city" language with entity-appropriate language.

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches for dropdown menus and URL state management.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 95-entity-switcher*
*Context gathered: 2026-03-22*
