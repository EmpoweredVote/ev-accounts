# Phase 104: Compass-First Card Prototype - Context

**Gathered:** 2026-04-04
**Status:** Ready for planning

<domain>
## Phase Boundary

A standalone `/prototype` route in essentials showing compass-first politician cards where the radar chart is the visual anchor instead of headshot photos. Uses real representative data from the Bloomington, IN address with hardcoded mock compass stances. Includes a variant toggle (A/B/C) to compare card shape and density options in-browser. Feature-flagged: direct URL only, no nav link.

</domain>

<decisions>
## Implementation Decisions

### Card Layout
- **D-01:** Radar chart is the dominant visual element, positioned at the top of the card. Name, title, and icons appear below the radar.
- **D-02:** Dual overlay when user has compass data — coral (user) + blue (politician), same as CompassCard on profiles. Politician-only (blue) when no user compass data.
- **D-03:** Radar chart is static/view-only — no interactive spoke clicks or inversion toggle. Click the card to navigate to full profile (/politician/:id).
- **D-04:** No spoke labels on the card radar — shape only. Topic names visible only on full profile CompassCard.
- **D-05:** White card background — radar colors (coral/blue) are the only color. Tier hue differentiation applied to CategorySection headers wrapping the card groups (carried from Phase 102/103).
- **D-06:** Phase 103 icon overlays (ballot, compass, branch) included on compass-first cards. Icons positioned near name/title area since there's no photo corner.

### Photo Treatment
- **D-07:** No headshot photo at all. The radar chart IS the visual identity. Name + title provide identification.
- **D-08:** Politicians without mock compass data show a dashed outline placeholder radar (light gray dashed polygon). No initials — name is already displayed below.
- **D-09:** Consistent card sizing whether politician has compass data or not (placeholder radar same dimensions as filled radar).

### Mock Data Strategy
- **D-10:** Mock compass stances defined in a local JSON/JS file in essentials (e.g., `src/data/mockCompassData.js`). Imported only by the /prototype route.
- **D-11:** Mock stances for ALL politicians returned by the Bloomington, IN address (100 W Kirkwood Ave). Full coverage of every representative.
- **D-12:** Mock stance values are varied and plausible — hand-craft 3-4 distinct "profiles" (e.g., progressive, moderate, conservative, mixed patterns) and assign them to politicians. Creates visually distinct radar shapes demonstrating comparison value.
- **D-13:** Use real topic IDs from compass.topics so dual overlay works naturally with user's real compass data. RadarChartCore expects topic-keyed answer maps.

### Page Structure
- **D-14:** Full representative layout mirroring Results page — tier sections (Federal/State/Local) with CategorySection headers and compass-first cards in grid layout. No sidebar, no address input, no LocationBrowser.
- **D-15:** Brief banner at top: "Compass-First Prototype — Exploring a new card layout where your political compass is the visual anchor. Bloomington, IN representatives."
- **D-16:** Live API fetch — hit existing /api/essentials/search with Bloomington address on page load. Mock compass data layered on top by matching politician IDs.
- **D-17:** SiteHeader included for consistency with every other essentials page.
- **D-18:** Route registered in App.jsx as `/prototype` — no nav link, accessible by direct URL only.

### Layout Variants
- **D-19:** Toggle switcher at the top of /prototype (segmented control or tabs) lets user switch between 3 card layout variants. Same data, different card designs.
- **D-20:** Variant dimension is card shape/density:
  - **Variant A:** Tall cards, ~200px radar, 2 per row on desktop. Spacious, radar-dominant.
  - **Variant B:** Compact cards, ~150px radar, 3 per row on desktop. Denser, more politicians visible at once.
  - **Variant C:** Wide horizontal cards, radar on left + name/title on right side-by-side. Different scanning pattern.
- **D-21:** Use the `frontend-design` skill during execution to ensure each variant has polished, distinctive visual design — not generic AI aesthetics.

### Claude's Discretion
- Exact segmented control styling for variant toggle (consistent with SegmentedControl from Phase 103 if possible)
- Responsive breakpoints for each variant's grid (mobile collapses to 1 column for all variants)
- Exact topic IDs to use (researcher should query compass.topics for the current 8 active topics)
- Politician-to-profile-type mapping for mock data (which politicians get which stance profile)
- Dashed outline placeholder exact styling (stroke dasharray, color, polygon shape)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Compass Components
- `essentials/src/components/CompassCard.jsx` — Full radar + stance accordion for profiles. Reference for dual overlay pattern, answer map building, and RadarChartCore usage.
- `essentials/src/components/CompassPreview.jsx` — Mini radar popover. Reference for compact radar rendering and politician answer fetching.
- `essentials/src/contexts/CompassContext.jsx` — User compass state (answers, topics, verdicts). Prototype needs this for dual overlay.

### ev-ui Components
- `ev-ui/src/RadarChartCore.jsx` — Core radar chart component. Accepts datasets, labels, size props.
- `ev-ui/src/icons.js` — BallotIcon, CompassIcon, BranchIcon SVG components (Phase 102).
- `ev-ui/src/tokens.js` — tierColors token (Phase 102).
- `ev-ui/src/CategorySection.jsx` — Tier-aware section wrapper with hue differentiation.

### Essentials Frontend
- `essentials/src/pages/Results.jsx` — Current representative page layout. Reference for tier grouping, CategorySection usage, and card grid.
- `essentials/src/components/PoliticianCard.jsx` — Current photo-first card. Reference for what to replace, not reuse.
- `essentials/src/App.jsx` — Router configuration. Add `/prototype` route here.
- `essentials/src/lib/classify.js` — Politician tier classification (Federal/State/Local categories).
- `essentials/src/utils/sorters.js` — Sorting options per category.

### Phase 102/103 Context
- `.planning/phases/102-ev-ui-foundation-quick-wins/102-CONTEXT.md` — tierColors, icon system, headshot crop decisions
- `.planning/phases/103-essentials-wiring-landing-page/103-CONTEXT.md` — Icon overlay wiring, tier hue differentiation, election page restructure

### Requirements
- `.planning/REQUIREMENTS.md` — PROTO-01, PROTO-02

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `CompassCard.jsx`: Full radar comparison pattern — dual overlay logic, answer map building, RadarChartCore props. Core rendering logic can be extracted/adapted for the compass-first card.
- `CompassPreview.jsx`: Compact radar rendering with position/size control. Shows how to render RadarChartCore at smaller sizes.
- `RadarChartCore` (ev-ui): Accepts `size`, `datasets`, `labels`, `invertedSpokes` props. Already handles dual overlay (two dataset arrays).
- `classify.js`: `classifyPoliticians()` groups politicians by tier/category — reuse directly for the prototype page structure.
- `CategorySection` (ev-ui): Already accepts `tier` prop for hue differentiation from Phase 103.

### Established Patterns
- essentials uses Tailwind CSS 4 for layout + ev-ui components with inline styles/tokens
- Results page uses `classifyPoliticians()` → tier sections → CategorySection → PoliticianCard grid
- CompassContext provides user answers, topics, invertedSpokes for dual overlay
- `fetchPoliticianAnswers()` fetches politician compass data — prototype bypasses this with mock data

### Integration Points
- `App.jsx` — add Route for `/prototype`
- `CompassContext` — prototype page needs to be wrapped in CompassProvider (already app-wide via App.jsx)
- Mock data file — new file in `src/data/` consumed only by prototype page component

</code_context>

<specifics>
## Specific Ideas

- User wants 2-3 visually distinct layout variants to compare in-browser, not just one fixed design
- Variant toggle on the same page (not separate routes) for quick A/B/C comparison
- Card shape/density is the variant dimension: tall/spacious vs compact/dense vs wide/horizontal
- No photos at all — the whole point is to explore whether the radar chart can replace the headshot as visual identity
- Placeholder radar for no-data politicians should be a dashed outline (no initials needed since name is below)
- Use frontend-design skill during execution for polished, distinctive visual quality

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 104-compass-first-card-prototype*
*Context gathered: 2026-04-04*
