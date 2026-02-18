# Phase 8: Layout - Context

**Gathered:** 2026-02-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Fixed sidebar with independently scrolling representatives panel in the Essentials app. The sidebar (search, tier filter, building image) stays visible while users browse a long list of representatives. Desktop/laptop layout only — mobile keeps current behavior.

</domain>

<decisions>
## Implementation Decisions

### Mobile/responsive behavior
- Desktop-only layout: the fixed sidebar + independent scroll only applies at >= 768px
- Below 768px, current full-page scroll behavior is preserved
- Minor mobile tweaks are OK if they improve the experience (e.g., sticky search bar)
- Breakpoint transition behavior is Claude's discretion

### Sidebar sizing & position
- Left sidebar, fixed pixel width (~300px)
- Representatives panel takes remaining space
- Subtle border line separating sidebar from reps panel
- Sidebar content stacks: search/filters on top (~50%), building image on bottom (~50%)

### Scroll feel & indicators
- No special scroll cues — standard browser scrollbar only
- No fade effects, edge shadows, or custom scrollbars
- Native browser scroll behavior (OS default momentum/inertia)
- Tier filter behavior unchanged — this phase doesn't modify filter logic

### Sidebar overflow
- Sidebar must never scroll — all content fits within viewport height
- Building image has portrait aspect ratio (~1:2.25, matching original design prototype)
- Building image scales down to prevent overflow
- Search/filters take priority on very short viewports — image shrinks or hides first
- Building image has rounded corners

### Claude's Discretion
- Exact breakpoint transition animation (instant vs smooth)
- Minor mobile improvements if beneficial
- Building image minimum size before hiding on very short viewports
- Exact border line styling (color, thickness)
- Spacing and padding within sidebar sections

</decisions>

<specifics>
## Specific Ideas

- Original design prototype had building image at ~450px height x 200px width (1:2.25 ratio)
- Sidebar splits roughly 50/50 between search/filters and building image
- Search/filters always take priority over building image in constrained viewports

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 08-layout*
*Context gathered: 2026-02-18*
