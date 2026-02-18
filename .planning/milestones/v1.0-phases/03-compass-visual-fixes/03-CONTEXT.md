# Phase 3: Compass Visual Fixes - Context

**Gathered:** 2026-02-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix rendering issues in the compass visualization: chart sizing to fit viewport, label overflow handling for long issue titles, removal of dashed/solid spoke distinction, and help box cleanup. No new features — purely visual correctness.

</domain>

<decisions>
## Implementation Decisions

### Chart Sizing
- Chart + controls must fit viewport height without scrolling on laptop screens (1280x800+)
- Chart dominates the page — minimal header/nav, chart takes 80-90% of viewport height
- Scales down proportionally on smaller screens (tablets, small laptops ~1024px) — same layout, just smaller
- Chart always stays centered in its container regardless of label lengths

### Label Overflow
- Multi-word titles: wrap to max 2 lines; if still too long, reduce font size
- Single-word titles: reduce font size to fit
- Handle label overlap — adjust positions to prevent collisions between adjacent spoke labels
- Chart must remain centered; labels extend into available margins, never push chart off-center

### Spoke Appearance
- All spokes become uniform solid lines — same color and thickness as current solid spokes
- No visual distinction between inverted and non-inverted spokes
- Click-to-invert behavior preserved — clicking still toggles inversion
- No indicator of inversion state — it's purely invisible to the user (internal value flip only)

### Help Box
- Remove the dashed/solid line explanation paragraph only
- Do not replace the removed text with anything
- Keep the help box itself and all other help text unchanged
- Keep current visibility behavior (toggle or always-on, whatever it is now)

### Claude's Discretion
- Minimum chart size floor below which scrolling is allowed (based on label readability)
- Exact responsive breakpoint handling
- Label overlap collision algorithm

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches within the decisions above.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 03-compass-visual-fixes*
*Context gathered: 2026-02-17*
