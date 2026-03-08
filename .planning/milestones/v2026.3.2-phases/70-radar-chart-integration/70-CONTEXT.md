# Phase 70: Radar Chart Integration - Context

**Gathered:** 2026-03-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire RadarChartCore dual-overlay into the CompassCard left zone on Essentials profile pages. The user's compass (coral polygon) and the politician's stances (blue polygon) render on the same radar chart. This phase delivers the chart rendering only — Phase 71 adds the right-side stance breakdown panel.

</domain>

<decisions>
## Implementation Decisions

### Chart Interactivity
- Read-only chart — no spoke click toggling on the profile page
- Carry over user's existing inverted spokes from CompassV2 (display-only, via CompassContext `invertedSpokes`)
- No tooltips on spokes — spoke labels and Phase 71's breakdown panel provide the detail
- Spring animation on first render (RadarChartCore's built-in react-spring transitions)

### Topic Filtering Logic
- Intersection only — show spokes only where BOTH user and politician have answers
- Cap at 8 spokes maximum, consistent with CompassV2 and CompassPreview
- Zero overlap fallback: show CTA to add more topics (link to CompassV2), similar to Phase 69's no-compass CTA pattern
- Spoke order matches user's selectedTopics order from CompassV2 (preserves mental model of compass shape)

### Chart Sizing & Responsiveness
- ~300px on desktop in the 2-column card layout
- Responsive resize on mobile (scales to card width in stacked layout)
- Centered horizontally in the left column
- Blends into card background — no additional border or frame around chart area

### Color Legend
- Simple legend positioned above the chart
- Format: coral dot + "You" | blue dot + "[Position] [Last Name]" (e.g., "Senator Young", "Council Member Stosberg")
- Position + last name format matches the CompassPreview popup pattern

### Spoke Labels
- Show topic short_title labels at spoke ends (RadarChartCore default behavior)
- Font size tuned for 300px chart (Claude's discretion on exact value)

### Claude's Discretion
- Exact label font size and padding values for 300px chart
- Loading state while politician answers are being fetched
- Responsive breakpoint for chart size scaling
- How to extract position + last name for the legend (from available politician data)
- Exact CTA wording and styling for zero-overlap state

</decisions>

<specifics>
## Specific Ideas

- Legend label should say "[Position] [Last Name]" — e.g., "Senator Young", "Council Member Stosberg" — matching how CompassPreview identifies politicians
- Legend above the chart so users read it first, then interpret the dual polygons
- Chart should feel like a natural part of the profile page, not a separate widget — hence blending into card background

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ev-ui/src/RadarChartCore.jsx`: Full dual-overlay support with `data` (coral) and `compareData` (blue) props, react-spring animations, spoke labels
- `essentials/src/components/CompassPreview.jsx`: Working reference implementation at 240px with identical data flow — `fetchPoliticianAnswers()`, `buildAnswerMapByShortTitle()`, 8-spoke cap
- `essentials/src/lib/compass.js`: `fetchPoliticianAnswers()`, `fetchUserAnswers()`, `buildAnswerMapByShortTitle()` helpers ready to use
- `essentials/src/components/CompassCard.jsx`: Phase 69 shell with left-zone skeleton placeholder ready for chart insertion

### Established Patterns
- CompassPreview data flow: fetch politician answers → build filtered topic list from selectedTopics order → build answer maps via `buildAnswerMapByShortTitle()` → pass to RadarChartCore
- RadarChartCore props: `topics` (filtered array), `data` (user answers by short_title), `compareData` (politician answers), `invertedSpokes`, `size`, `labelFontSize`, `padding`, `labelOffset`
- CTA pattern from CompassPreview (lines 285-350): greyed compass SVG + prompt text + teal button with return URL

### Integration Points
- `essentials/src/components/CompassCard.jsx`: Replace left-zone skeleton with RadarChartCore rendering
- `essentials/src/contexts/CompassContext.jsx`: Provides `userAnswers`, `selectedTopics`, `allTopics`, `invertedSpokes` — no changes needed
- `politicianId` and `politicianName` props already passed to CompassCard from Profile.jsx

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 70-radar-chart-integration*
*Context gathered: 2026-03-07*
