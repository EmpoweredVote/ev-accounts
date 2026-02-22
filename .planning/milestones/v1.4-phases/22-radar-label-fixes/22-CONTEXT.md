# Phase 22: Radar Label Fixes - Context

**Gathered:** 2026-02-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix label visibility and readability in ev-ui RadarChartCore. Labels must not clip at edges, must meet a minimum font size, and must wrap multi-word text fully. Publish a new ev-ui patch version and update CompassV2.

</domain>

<decisions>
## Implementation Decisions

### Overflow strategy
- Add horizontal-only padding (left and right) so the chart keeps its full height
- Padding is dynamic — measure actual label widths on each side, size padding to fit
- Chart polygon stays the same size; only the SVG/container widens to accommodate labels

### Minimum font size
- 10px floor — no label renders below 10px regardless of length
- Adaptive sizing — labels can vary in size based on their length (short labels slightly larger, long labels slightly smaller), as long as all stay at or above 10px
- Never truncate — always show full text, let dynamic padding handle the space

### Word wrap rules
- Natural word breaks — split at spaces, each word on its own line if needed
- "Medicare/Medicaid" splits at the `/` character onto two lines (only topic with this pattern)
- Maximum 2 lines per label
- Inside-aligned text — left-side labels right-align toward the chart, right-side labels left-align toward the chart

### Scaling behavior
- Topic count is bounded: minimum 3, maximum 8
- No label overlap allowed — if labels would overlap, adjust spacing/sizing to prevent it
- Same label rules apply in both the personal compass and Compare views
- Optimize primarily for the 5-8 topic range

### Claude's Discretion
- Whether the component handles padding internally (self-contained) or communicates to parent
- Chart centering vs visual balancing when labels are asymmetric
- Whether top/bottom vs left/right labels need position-aware wrap behavior
- Font weight adjustments at small sizes for readability (e.g., semibold at 10-11px if Manrope needs it)

</decisions>

<specifics>
## Specific Ideas

- "Medicare/Medicaid" is the only topic with a `/` delimiter — should split there for two-line rendering
- With a max of 8 topics, labels should have comfortable spacing in most cases
- The fix is in ev-ui RadarChartCore, then publish and bump in CompassV2

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 22-radar-label-fixes*
*Context gathered: 2026-02-21*
