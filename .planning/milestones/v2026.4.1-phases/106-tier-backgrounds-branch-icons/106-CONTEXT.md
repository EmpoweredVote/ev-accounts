# Phase 106: Tier Background Hues & Branch Icons - Context

**Gathered:** 2026-04-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Section backgrounds use tier-specific hues so the page visually shifts as you scroll Federal -> State -> Local, and branch type is conveyed with 3 distinct icons (Executive, Legislative, Judicial) instead of a single generic landmark icon.

</domain>

<decisions>
## Implementation Decisions

### Section Backgrounds
- **D-01:** Each tier (Federal, State, Local) gets a faint background tint applied to the entire section — not just the title pill. The tint covers the full section area including card grid.
- **D-02:** Background tint is applied at the **tier level** (one continuous band per tier), not per-CategorySection. All Federal categories share one band, all State share another, etc.
- **D-03:** Three distinct tint levels are required. Current `tierColors` has federal=teal-100 and state/local both=teal-050. Update `tierColors` so local uses a lighter value (white or near-white) to differentiate from state. Federal=darkest, State=medium, Local=lightest.
- **D-04:** Tier background extends **edge-to-edge** (full viewport width) while cards stay within the content container. Creates immersive tier bands.
- **D-05:** Hard break between tier sections — clean edge where one tier's tint ends and the next begins. No gradient fading or blending.
- **D-06:** Minimal vertical padding within each tier band — just enough to separate cards from the tier boundary. Tighter layout, not generous whitespace.

### Branch Icon Design
- **D-07:** Replace the single generic `BranchIcon` with a single component that accepts a `branch` prop (`'executive'|'legislative'|'judicial'`). API: `<BranchIcon branch="executive" />`.
- **D-08:** Icon symbols:
  - **Executive:** Building with flag (administration/office building silhouette with small flag on top)
  - **Legislative:** Scroll/document (represents lawmaking and legislation)
  - **Judicial:** Scales of justice
- **D-09:** All three branch icons use the **same color** as the other metadata icons (BallotIcon, CompassIcon) — muted gray/teal. Shape alone differentiates branch type.
- **D-10:** Tooltip text: "Executive branch" / "Legislative branch" / "Judicial branch" — simple, matching existing tooltip pattern from Phase 103.
- **D-11:** Branch type mapping from district_type is locked from Phase 103 (D-10):
  - `NATIONAL_EXEC`, `STATE_EXEC`, `LOCAL_EXEC` -> executive
  - `NATIONAL_UPPER`, `NATIONAL_LOWER`, `STATE_UPPER`, `STATE_LOWER`, `LOCAL`, `SCHOOL` -> legislative
  - `JUDICIAL` -> judicial
  - `COUNTY` -> title-based heuristic (council/commissioner -> legislative, sheriff/clerk/etc. -> executive)

### Card Treatment
- **D-12:** Cards have white background with a subtle drop shadow, appearing to float on the tinted tier band. The tint shows through gaps between cards.

### Claude's Discretion
- Exact teal shade for the new local tier bg value (must be lighter than teal-050 or white)
- SVG path details for the 3 branch icons (building+flag, scroll, scales) — match existing outlined stroke style at 16px
- Shadow values for cards (subtle, not heavy)
- CSS approach for edge-to-edge tier backgrounds (negative margin + padding or full-width wrapper)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### ev-ui Components
- `ev-ui/src/tokens.js` — `tierColors` token with federal/state/local bg/accent/text values (lines 60-76). Needs local bg updated for 3-way distinction.
- `ev-ui/src/icons.js` — Current `BranchIcon` (lines 54-75). Single landmark SVG to be replaced with branch-prop-based component.
- `ev-ui/src/CategorySection.jsx` — Accepts `tier` prop, uses `tierColors` for title pill styling (lines 14-48). Title pill should continue using tierColors.
- `ev-ui/src/index.js` — Exports all components/tokens

### Essentials Frontend
- `essentials/src/pages/Results.jsx` — Main representatives page. Tier-level wrapper divs exist (lines 958-1025, `data-tier` attributes). Need tier background applied at these wrapper divs.
- `essentials/src/components/IconOverlay.jsx` — Already imports BranchIcon and wires tooltips via @floating-ui/react. Needs to pass `branch` prop.
- `essentials/src/components/PoliticianCard.jsx` — Local card wrapper that renders IconOverlay

### Phase 103 Context (prior decisions)
- `.planning/phases/103-essentials-wiring-landing-page/103-CONTEXT.md` — D-06 through D-10 define icon overlay behavior, tooltip pattern, and branch type mapping. All carry forward.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `tierColors` token in ev-ui already has the 3-tier structure with bg/accent/text — just needs local.bg updated
- `CategorySection` already accepts `tier` prop and applies `tierColors` to title pill
- `IconOverlay` already renders BranchIcon with @floating-ui/react tooltips — just needs to pass branch type
- Results.jsx already has `data-tier` wrapper divs for Federal/State/Local — natural place to apply background

### Established Patterns
- Inline SVG components in `ev-ui/src/icons.js` with `size` and `color` props
- @floating-ui/react for all icon tooltips (hover/focus/dismiss)
- `tierColors` semantic token pattern: `{ bg, accent, text }` per tier

### Integration Points
- ev-ui `BranchIcon` API change (add `branch` prop) -> essentials `IconOverlay` must pass branch type
- ev-ui `tierColors.local.bg` value change -> essentials Results.jsx tier wrapper styling
- ev-ui version bump required -> essentials must update dependency

</code_context>

<specifics>
## Specific Ideas

- User wants a page that visually shifts as you scroll — the tier bands should create a sense of moving through government levels
- Judicial = scales of justice was an immediate yes; executive and legislative were deliberated — building+flag and scroll/document chosen for maximum distinctness at small sizes
- Minimal padding preferred — user doesn't want excessive whitespace, just enough separation

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 106-tier-backgrounds-branch-icons*
*Context gathered: 2026-04-04*
