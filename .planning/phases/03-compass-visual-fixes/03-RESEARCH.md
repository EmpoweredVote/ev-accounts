# Phase 3: Compass Visual Fixes - Research

**Researched:** 2026-02-17
**Domain:** SVG radar chart rendering, CSS viewport sizing, React component library publishing
**Confidence:** HIGH

## Summary

This phase makes four targeted visual corrections to the compass radar chart: viewport-fit sizing, label overflow handling, spoke appearance uniformity, and help box copy cleanup. The chart rendering is split across two repos — the core SVG logic lives in `ev-ui/src/RadarChartCore.jsx` (published as `@chrisandrewsedu/ev-ui`) and the page layout lives in `CompassV2/src/pages/Compass.jsx`. Most of the work happens in `RadarChartCore.jsx`.

The critical workflow implication: changes to `RadarChartCore.jsx` must be built and published (or link-resolved) before CompassV2 sees them. CompassV2 currently has ev-ui version `0.1.12` installed; source is at `0.1.14`. Any plan that modifies `RadarChartCore.jsx` must include a build-publish-update step in ev-ui followed by `npm install` in CompassV2, or use a local `npm link` during development.

The spoke dashed line and help box copy fixes are the simplest changes. The sizing and label fixes are more involved — sizing requires `height`-constrained CSS on the SVG container, and label overflow requires a smarter `wrapLabel` function plus font-size reduction as a fallback.

**Primary recommendation:** Do the two plans in sequence — sizing/label first (03-01), then spoke/help-box (03-02). Both touch ev-ui but 03-02 is simpler and can be verified independently.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Chart Sizing**
- Chart + controls must fit viewport height without scrolling on laptop screens (1280x800+)
- Chart dominates the page — minimal header/nav, chart takes 80-90% of viewport height
- Scales down proportionally on smaller screens (tablets, small laptops ~1024px) — same layout, just smaller
- Chart always stays centered in its container regardless of label lengths

**Label Overflow**
- Multi-word titles: wrap to max 2 lines; if still too long, reduce font size
- Single-word titles: reduce font size to fit
- Handle label overlap — adjust positions to prevent collisions between adjacent spoke labels
- Chart must remain centered; labels extend into available margins, never push chart off-center

**Spoke Appearance**
- All spokes become uniform solid lines — same color and thickness as current solid spokes
- No visual distinction between inverted and non-inverted spokes
- Click-to-invert behavior preserved — clicking still toggles inversion
- No indicator of inversion state — it's purely invisible to the user (internal value flip only)

**Help Box**
- Remove the dashed/solid line explanation paragraph only
- Do not replace the removed text with anything
- Keep the help box itself and all other help text unchanged
- Keep current visibility behavior (toggle or always-on, whatever it is now)

### Claude's Discretion
- Minimum chart size floor below which scrolling is allowed (based on label readability)
- Exact responsive breakpoint handling
- Label overlap collision algorithm

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| QUIZ-04 | Compass visualization fits on page without scrolling (except screens smaller than mobile breakpoint) | SVG viewport sizing via CSS height constraints on the container; `h-dvh` or `calc(100dvh - headerHeight)` pattern in Compass.jsx |
| QUIZ-05 | Compass title cutoff fixed — long titles no longer push chart left or get clipped | wrapLabel max-lines cap (2 lines), font-size reduction fallback in RadarChartCore; viewBox padding adjustment |
| QUIZ-06 | Dashed/solid line visual distinction removed from inverted spokes (inversion logic preserved) | Remove `strokeDasharray` conditional in RadarChartCore line rendering; one-line change |
| QUIZ-07 | Help box updated to remove dashed/solid line references | Remove the `<div className="flex items-center gap-3...">` legend block from SpokeHint in Compass.jsx; one-line change |
</phase_requirements>

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React | 19.1.0 | Component model | Already in use |
| SVG (browser-native) | n/a | Radar chart rendering | All chart logic uses SVG directly — no chart library |
| Tailwind CSS 4 | 4.1.10 | Utility classes for layout constraints | Already in use |
| tsup | 8.x | ev-ui build tool | Already configured |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| @react-spring/web | 9.7.2 (ev-ui peer) / 10.0.1 (CompassV2) | Animated polygon springs in RadarChartCore | Already powering the animated chart shape; not changed in this phase |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| CSS height constraint on SVG container | `size` prop + JS resize observer | CSS is simpler and already works with SVG's `viewBox` scaling |
| Manual font-size reduction in wrapLabel | foreignObject with HTML text | foreignObject has cross-browser issues; SVG text with font-size is standard |
| Padding-based label overflow | Larger SVG viewBox padding | Larger padding shrinks the chart area — centering breaks. Better to shrink font instead. |

**Installation:** No new packages needed. All required tools are already installed.

---

## Architecture Patterns

### File Locations

```
ev-ui/
├── src/
│   └── RadarChartCore.jsx      ← Chart rendering: spoke lines, labels, viewBox
│
CompassV2/
└── src/
    ├── pages/Compass.jsx        ← Chart container sizing, SpokeHint help box, layout
    └── components/RadarChart.jsx ← Thin wrapper; passes topics + padding=50 to RadarChartCore
```

### Pattern 1: Viewport-Fit SVG Sizing

**What:** Constrain the SVG container to a fraction of viewport height. The SVG itself uses `viewBox` + `preserveAspectRatio="xMidYMid meet"` with `w-full h-auto`, meaning it scales to fill its container while maintaining aspect ratio. The fix is to set a maximum height on the *container*, not the SVG itself.

**Current state in Compass.jsx (desktop):**
```jsx
<div className="w-[108%] relative">
  <RadarChart ... />
</div>
```
The container has no height constraint — the SVG expands to fill horizontal width, which on large screens can make the chart taller than the viewport.

**Fix approach:** Apply a `max-h-[Xvh]` or `h-[calc(100dvh-Ypx)]` constraint on the chart container. The SVG will scale down to fit because `h-auto` respects max-height on the parent when combined with `aspect-ratio` or when the SVG itself has an intrinsic aspect ratio from `viewBox`.

**Current viewBox calculation:**
```
viewBox=`-${padding} -${padding} ${size + padding * 2} ${size + padding * 2}`
// With size=400, padding=50:
// viewBox="-50 -50 500 500"  → square aspect ratio
```
The SVG is always square (viewBox is size + 2*padding square). So: constrain container max-height → SVG width auto-shrinks to maintain square aspect ratio.

**Recommended approach:**
```jsx
// Compass.jsx — desktop chart container
<div className="w-full max-h-[calc(100dvh-180px)] aspect-square relative">
  <RadarChart ... />
</div>
```
The `aspect-square` ensures the container stays square (matching SVG viewBox), and `max-h-[calc(100dvh-180px)]` caps the height. `180px` accounts for: header (~75px) + back button (~32px) + action buttons (~48px) + margins (~25px).

**Header height:** The `SiteHeader` renders with `padding: 16px 24px` (spacing[4]/spacing[6]) and a logo of `height: 43px`. Estimated rendered height is ~75px on desktop.

**Minimum floor (Claude's discretion):** Set a `min-h-[320px]` on the container — below 320px the labels become unreadable. Below this floor, scrolling is acceptable.

**Example:**
```jsx
// Desktop chart wrapper in Compass.jsx
<div className="w-full min-h-[320px] max-h-[calc(100dvh-180px)] aspect-square relative">
  {showSpokeHint && <SpokeHint onDismiss={dismissSpokeHint} />}
  <RadarChart ... />
</div>
```

### Pattern 2: Label Overflow — Two-Line Cap + Font Size Reduction

**What:** The current `wrapLabel` function in `RadarChartCore.jsx` wraps at 12 chars per line with no line cap. Long titles produce 3+ lines, extending into the SVG's `padding` zone and potentially beyond.

**Current wrapLabel behavior:**
```js
function wrapLabel(label, maxChars = 12) {
  // wraps at word boundaries, no line limit
  // long single words are placed on their own line (not split)
  // returns: string[]
}
```

**Current label rendering:** Labels use a fixed `fSize = labelFontSize || 16` (16px SVG units). Multi-line labels already shift upward for top spokes. The issue is 3+ lines and very long single words pushing outside the viewBox padding.

**Fix approach — in RadarChartCore.jsx:**

Step 1: Cap `wrapLabel` to max 2 lines.
Step 2: If wrapping produces more than 2 lines at current font size, reduce font size (try 13px, then 11px) until it fits in 2 lines.
Step 3: For a single very long word, reduce font size rather than truncating.

```js
// In RadarChartCore.jsx — updated label logic
function computeLabel(shortTitle, maxChars, baseFontSize) {
  // Try base font size
  const lines = wrapLabel(shortTitle, maxChars);
  if (lines.length <= 2) return { lines, fontSize: baseFontSize };
  // Try 13px (smaller maxChars per line proportional to reduction)
  const lines13 = wrapLabel(shortTitle, Math.floor(maxChars * (13/baseFontSize)));
  if (lines13.length <= 2) return { lines: lines13, fontSize: 13 };
  // Force 2 lines at 11px
  const lines11 = wrapLabel(shortTitle, Math.floor(maxChars * (11/baseFontSize)));
  return { lines: lines11.slice(0,2), fontSize: 11 };
}
```

**Single-word case:** Single-word long titles (like "Redistricting") already wrap to one line with the current code. If the word is very long and font size is 16, it overflows the padding. The fix: detect single-word and reduce font size until `word.length * charWidth <= available_label_width`. SVG character width at 16px (Manrope) is approximately 9px per char. Available label space within padding (50px) is ~45px = ~5 chars at 16px. This is a limitation of the fixed-size SVG approach.

**Better approach for Claude's discretion (label overlap + single-word):**
- Increase `padding` prop passed from RadarChart.jsx (currently 50) to 70 when there are long labels detected at the chart level
- Dynamically compute `maxChars` based on available padding: `maxChars = Math.floor(padding * 0.7 / 9)` (9px per char estimate at 16px)
- This is cleaner than font-size reduction but requires passing label data upward

**Recommended simple approach (fits in plan scope):**
1. Cap wrapLabel at 2 lines
2. Add `reducedFontSize` fallback to 13px then 11px
3. Increase default padding from 50 to 70 in RadarChart.jsx

### Pattern 3: Label Collision Avoidance (Claude's Discretion)

**What:** Adjacent spokes whose labels are close in angle can overlap at low spoke counts (e.g., 4-5 spokes) or at small chart sizes.

**SVG label positions:** Each label is placed at angle `(2π * i) / numSpokes` at distance `radius + labelOffset`. For labels close together (few spokes), vertical shift can cause collision.

**Standard approach:** Detect collision by comparing bounding boxes of adjacent labels. SVG `getBBox()` provides this — but it's only available after render (requires a ref/useEffect). This adds complexity.

**Simpler approach (recommended for this phase):** Increase `labelOffset` proportionally for spokes with many lines, and increase overall viewBox padding. True collision detection (getBBox-based) is a larger feature — flag for Claude's discretion and recommend the simpler padding approach as the plan-1 implementation.

**Minimum viable collision avoidance:**
```js
// Increase labelOffset for labels with 2 lines
const labelOffset = lines.length > 1 ? 28 : 20;
```

### Pattern 4: Spoke Dashed Line Removal

**What:** In `RadarChartCore.jsx`, the spoke `<line>` element has:
```jsx
strokeDasharray={isInverted ? "6 4" : "none"}
```
Remove the conditional — always render `"none"` (or omit `strokeDasharray` entirely).

**Fix:** Remove the `isInverted` check, remove the `strokeDasharray` prop entirely from the spoke line:
```jsx
<line
  key={`line-${shortTitle}`}
  x1={centerX} y1={centerY}
  x2={x} y2={y}
  stroke="black"
  // strokeDasharray removed
/>
```
The `isInverted` variable on line 106 of RadarChartCore.jsx can also be removed since it has no other use after this change.

### Pattern 5: Help Box Copy Cleanup

**What:** In `Compass.jsx`, the `SpokeHint` component contains:
```jsx
<div className="flex items-center gap-3 mt-1.5 text-gray-400">
  <span className="flex items-center gap-1">
    <svg width="20" height="2">...</svg> normal
  </span>
  <span className="flex items-center gap-1">
    <svg width="20" height="2">...</svg> inverted
  </span>
</div>
```
This is the dashed/solid line legend. Remove this `<div>` block only. Keep the surrounding `<div>` that contains `<span>Click any spoke to invert it.</span>`.

**Fix:**
```jsx
// SpokeHint — after fix
<div>
  <span>Click any spoke to invert it.</span>
  {/* dashed/solid legend div removed */}
</div>
```

### Anti-Patterns to Avoid

- **Modifying SVG `size` prop for viewport fit:** The `size` prop controls the SVG coordinate space, not the rendered size. Changing it rescales the entire chart geometry. Use CSS container sizing instead.
- **Setting `width`/`height` attributes on the `<svg>` element:** The SVG uses `className="w-full h-auto"` (Tailwind utilities). Adding hardcoded `width`/`height` SVG attributes overrides CSS and breaks responsive scaling.
- **Truncating labels with ellipsis in SVG:** SVG `<text>` doesn't support `text-overflow: ellipsis`. Use font-size reduction or line capping instead.
- **Publishing ev-ui without bumping version:** CompassV2 uses `^0.1.12` in package.json — any new publish of a compatible version (0.1.x) will be picked up with `npm install`. Must bump to at least `0.1.15` (or current+1) and run `npm install` in CompassV2.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Label bounding box collision | Custom geometry math | SVG `getBBox()` after render | Browser provides exact text dimensions including font kerning |
| Chart resizing | JS resize observer + state | CSS `max-height` + SVG `viewBox` | SVG scales purely with CSS; no JS needed |
| SVG text wrapping | HTML foreignObject | SVG `<tspan>` with dy | foreignObject has cross-browser issues; tspan is standard SVG |

**Key insight:** SVG's `viewBox` + `preserveAspectRatio="xMidYMid meet"` + CSS container sizing handles all scaling automatically. The chart code already uses this correctly — the fix is just adding CSS height constraints to the container in Compass.jsx.

---

## Common Pitfalls

### Pitfall 1: ev-ui build/publish cycle
**What goes wrong:** Developer edits RadarChartCore.jsx, tests in ev-ui directly (or via link), but CompassV2 still loads the old installed version from `node_modules`.
**Why it happens:** CompassV2 consumes the compiled dist from npm, not the source.
**How to avoid:** Use `npm link` during development: `cd ev-ui && npm run build && npm link`, then `cd CompassV2 && npm link @chrisandrewsedu/ev-ui`. Or: bump version, `npm run build`, publish, then `npm install` in CompassV2.
**Warning signs:** Changes to RadarChartCore.jsx have no visual effect in CompassV2's dev server.

### Pitfall 2: SVG viewport units vs CSS viewport units
**What goes wrong:** Using `vh` in SVG attributes (like `height="80vh"`) — SVG doesn't support viewport units in attributes.
**Why it happens:** Confusing SVG presentation attributes with CSS properties.
**How to avoid:** Apply viewport-unit sizing through CSS classes on the container div, not on the `<svg>` element's attributes. The Tailwind `max-h-[calc(100dvh-180px)]` class applies to the div wrapper, which constrains the SVG via its `w-full h-auto` CSS.
**Warning signs:** `max-h` class on the SVG element itself has no effect.

### Pitfall 3: `aspect-square` + `w-full` interaction
**What goes wrong:** The container grows wider than it is tall when `w-full` hits a wide viewport, but `aspect-square` forces height = width, making the container taller than intended.
**Why it happens:** `aspect-square` maintains 1:1 ratio based on width. On a wide desktop, `w-full` of a flex-1 column can be 600px, making height 600px — too tall for an 800px viewport.
**How to avoid:** Use `max-h-[...]` to cap the height, which then constrains the width via the square aspect ratio. Or use `w-full max-w-[calc(100dvh-180px)]` to cap width instead. The max-height approach is cleaner.

### Pitfall 4: wrapLabel maxChars vs label rendering width
**What goes wrong:** `maxChars = 12` wraps at character count, not pixel width. Manrope characters vary in width — "W" is wider than "i". A 12-char line with wide chars overflows the label area.
**Why it happens:** Character-count wrapping is an approximation for proportional fonts.
**How to avoid:** Accept the approximation but decrease `maxChars` slightly (10-11) and increase SVG padding to provide more label margin. For this phase, the two-line cap + font size reduction is sufficient.

### Pitfall 5: Removing `strokeDasharray` vs setting it to "none"
**What goes wrong:** `strokeDasharray="none"` is not valid SVG — `"none"` is not a valid dash-array value. The correct way to disable dashing is to omit the attribute entirely.
**Why it happens:** Treating SVG presentation attributes like CSS properties.
**How to avoid:** Remove the `strokeDasharray` prop from the `<line>` element entirely rather than setting it to `"none"`. The current code uses the string `"none"` which browsers often accept but is technically incorrect.

---

## Code Examples

### Viewport-Fit Container (Compass.jsx desktop section)
```jsx
// Source: direct codebase analysis of Compass.jsx + Header.jsx
// Header height: ~75px (43px logo + 16px padding top + 16px padding bottom)
// Back button: ~32px, Action buttons: ~56px, margins: ~17px = 180px total chrome

{/* desktop chart container — BEFORE */}
<div className="w-[108%] relative">

{/* desktop chart container — AFTER */}
<div className="w-full min-h-[320px] max-h-[calc(100dvh-180px)] aspect-square relative">
```

### Two-Line Label Cap with Font Size Fallback (RadarChartCore.jsx)
```jsx
// Source: direct codebase analysis of RadarChartCore.jsx lines 120-163

// Replace this block in the label-rendering map:
const lines = wrapLabel(shortTitle, 10);
const fSize = labelFontSize || 16;

// With:
const baseFSize = labelFontSize || 16;
let lines = wrapLabel(shortTitle, 10);
let fSize = baseFSize;
if (lines.length > 2) {
  lines = wrapLabel(shortTitle, 8);
  fSize = 13;
  if (lines.length > 2) {
    lines = lines.slice(0, 2);
    fSize = 11;
  }
}
```

### Remove Spoke Dashed Line (RadarChartCore.jsx)
```jsx
// Source: RadarChartCore.jsx lines 102-118

// BEFORE:
const isInverted = !!invertedSpokes[shortTitle];
return (
  <line
    key={`line-${shortTitle}`}
    x1={centerX} y1={centerY} x2={x} y2={y}
    stroke="black"
    strokeDasharray={isInverted ? "6 4" : "none"}
  />
);

// AFTER (isInverted const removed, strokeDasharray removed):
return (
  <line
    key={`line-${shortTitle}`}
    x1={centerX} y1={centerY} x2={x} y2={y}
    stroke="black"
  />
);
```

### Remove Help Box Legend (Compass.jsx — SpokeHint component)
```jsx
// Source: Compass.jsx lines 23-31

// BEFORE:
<div>
  <span>Click any spoke to invert it.</span>
  <div className="flex items-center gap-3 mt-1.5 text-gray-400">
    <span className="flex items-center gap-1">
      <svg width="20" height="2"><line x1="0" y1="1" x2="20" y2="1" stroke="currentColor" strokeWidth="2"/></svg> normal
    </span>
    <span className="flex items-center gap-1">
      <svg width="20" height="2"><line x1="0" y1="1" x2="20" y2="1" stroke="currentColor" strokeWidth="2" strokeDasharray="4 3"/></svg> inverted
    </span>
  </div>
</div>

// AFTER:
<div>
  <span>Click any spoke to invert it.</span>
</div>
```

### ev-ui Publish Workflow
```bash
# In ev-ui — bump version, build, publish
# Edit package.json version to 0.1.15
npm run build
npm publish --registry https://npm.pkg.github.com

# In CompassV2 — update dependency
npm install @chrisandrewsedu/ev-ui@latest
```

---

## State of the Art

| Old Approach | Current Approach | Notes |
|--------------|------------------|-------|
| `vh` CSS units | `dvh` CSS units | `dvh` = dynamic viewport height, accounts for mobile browser chrome. Use `dvh` for mobile-correct sizing, `vh` as fallback. |
| Inline `style={{ height: '...vh' }}` | Tailwind `max-h-[calc(100dvh-...)]` | Consistent with existing Tailwind 4 usage in codebase |
| SVG `foreignObject` for text wrapping | SVG `<tspan>` with `dy` | Already used correctly in codebase |

---

## Open Questions

1. **Exact header height at runtime**
   - What we know: Header uses 43px logo + 16px top padding + 16px bottom padding = ~75px estimated
   - What's unclear: Whether the `Back to Library` button and `ActionButtons` (Edit Topics, Compare) are inside or outside the height-constrained region
   - Recommendation: The action buttons sit below the chart. Include them in the chrome calculation (~56px). Use `180px` as the total chrome offset in `calc(100dvh - 180px)` — validates visually on first render.

2. **Label collision algorithm scope**
   - What we know: True collision detection requires `getBBox()` which only works post-render via refs
   - What's unclear: Whether collision is a real issue at the typical 5-8 spoke count
   - Recommendation: Skip true collision detection for this phase. Implement it as a stretch goal only if the padding increase + 2-line cap doesn't resolve visible overlaps in practice.

3. **Mobile chart sizing on the Graph tab**
   - What we know: Mobile has a separate chart container: `<div className="w-full relative">` inside `max-w-md md:max-w-lg`
   - What's unclear: Whether QUIZ-04 also requires mobile viewport fit or only laptop (1280px+)
   - Recommendation: The requirement says "except screens smaller than mobile breakpoint." Apply the same max-height approach on mobile too — `max-h-[calc(100dvh-220px)]` (extra for mobile tab bar). Allow scroll below the minimum floor.

4. **`w-[108%]` on desktop chart container**
   - What we know: Current desktop chart uses `w-[108%]` — slightly wider than parent flex column. This was presumably intentional to account for label overflow into margins.
   - What's unclear: Whether removing this will break the centering intent
   - Recommendation: Replace `w-[108%]` with `w-full` when adding `aspect-square` + `max-h`. The `aspect-square` constrains both dimensions correctly without the overhang hack.

---

## Sources

### Primary (HIGH confidence)
- Direct source read: `/Users/chrisandrews/Documents/GitHub/ev-ui/src/RadarChartCore.jsx` — full chart implementation
- Direct source read: `/Users/chrisandrews/Documents/GitHub/CompassV2/src/pages/Compass.jsx` — layout, SpokeHint
- Direct source read: `/Users/chrisandrews/Documents/GitHub/ev-ui/src/Header.jsx` — header height/padding tokens
- Direct source read: `/Users/chrisandrews/Documents/GitHub/ev-ui/src/tokens.js` — spacing values
- Direct source read: `/Users/chrisandrews/Documents/GitHub/CompassV2/package.json` — installed ev-ui version (0.1.12)
- Direct source read: `/Users/chrisandrews/Documents/GitHub/ev-ui/package.json` — current ev-ui version (0.1.14)

### Secondary (MEDIUM confidence)
- SVG `preserveAspectRatio` and `viewBox` scaling behavior — well-established SVG spec, no version drift risk
- CSS `dvh` unit — widely supported in modern browsers (Chrome 108+, Safari 15.4+, Firefox 101+)
- `aspect-ratio` CSS property — broadly supported, no version concerns

### Tertiary (LOW confidence)
- Estimated header rendered height (75px) — computed from token values, not measured at runtime
- Manrope character width estimate (9px at 16px font size) — approximation; actual width varies by glyph

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all verified from package.json and installed modules
- Architecture: HIGH — read full source of all affected files
- Pitfalls: HIGH — derived from actual code analysis, not speculation
- Label size estimates: LOW — approximations only; validate visually

**Research date:** 2026-02-17
**Valid until:** 2026-03-17 (stable libraries, no breaking change risk)
