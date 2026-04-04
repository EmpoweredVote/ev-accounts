# Phase 104: Compass-First Card Prototype - Research

**Researched:** 2026-04-04
**Domain:** React frontend — new route + new card component in `essentials`, mock data strategy, RadarChartCore integration
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Card Layout**
- D-01: Radar chart is the dominant visual element, positioned at the top of the card. Name, title, and icons appear below the radar.
- D-02: Dual overlay when user has compass data — coral (user) + blue (politician), same as CompassCard on profiles. Politician-only (blue) when no user compass data.
- D-03: Radar chart is static/view-only — no interactive spoke clicks or inversion toggle. Click the card to navigate to full profile (/politician/:id).
- D-04: No spoke labels on the card radar — shape only. Topic names visible only on full profile CompassCard.
- D-05: White card background — radar colors (coral/blue) are the only color. Tier hue differentiation applied to CategorySection headers wrapping the card groups.
- D-06: Phase 103 icon overlays (ballot, compass, branch) included on compass-first cards. Icons positioned near name/title area (not photo corner — no photo).

**Photo Treatment**
- D-07: No headshot photo at all. The radar chart IS the visual identity. Name + title provide identification.
- D-08: Politicians without mock compass data show a dashed outline placeholder radar (light gray dashed polygon). No initials.
- D-09: Consistent card sizing whether politician has compass data or not (placeholder radar same dimensions as filled radar).

**Mock Data Strategy**
- D-10: Mock compass stances defined in a local JSON/JS file in essentials (e.g., `src/data/mockCompassData.js`). Imported only by the /prototype route.
- D-11: Mock stances for ALL politicians returned by the Bloomington, IN address (100 W Kirkwood Ave). Full coverage of every representative.
- D-12: Mock stance values are varied and plausible — hand-craft 3-4 distinct "profiles" (progressive, moderate, conservative, mixed patterns) and assign them to politicians.
- D-13: Use real topic IDs from compass.topics so dual overlay works naturally with user's real compass data. RadarChartCore expects topic-keyed answer maps.

**Page Structure**
- D-14: Full representative layout mirroring Results page — tier sections (Federal/State/Local) with CategorySection headers and compass-first cards in grid layout. No sidebar, no address input, no LocationBrowser.
- D-15: Brief banner at top: "Compass-First Prototype — Exploring a new card layout where your political compass is the visual anchor. Bloomington, IN representatives."
- D-16: Live API fetch — hit existing /api/essentials/search with Bloomington address on page load. Mock compass data layered on top by matching politician IDs.
- D-17: SiteHeader included for consistency with every other essentials page.
- D-18: Route registered in App.jsx as `/prototype` — no nav link, accessible by direct URL only.

**Layout Variants**
- D-19: Toggle switcher at the top of /prototype (segmented control or tabs) lets user switch between 3 card layout variants. Same data, different card designs.
- D-20: Variant dimension is card shape/density:
  - Variant A: Tall cards, ~200px radar, 2 per row on desktop. Spacious, radar-dominant.
  - Variant B: Compact cards, ~150px radar, 3 per row on desktop. Denser.
  - Variant C: Wide horizontal cards, radar on left + name/title on right side-by-side.
- D-21: Use the `frontend-design` skill during execution to ensure each variant has polished, distinctive visual design.

### Claude's Discretion
- Exact segmented control styling for variant toggle (consistent with SegmentedControl from Phase 103 if possible)
- Responsive breakpoints for each variant's grid (mobile collapses to 1 column for all variants)
- Exact topic IDs to use (researcher should query compass.topics for the current 8 active topics)
- Politician-to-profile-type mapping for mock data (which politicians get which stance profile)
- Dashed outline placeholder exact styling (stroke dasharray, color, polygon shape)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROTO-01 | Standalone /prototype route showing compass-first politician cards with real representative data | Route registration pattern in App.jsx verified; `searchPoliticians()` + `usePoliticianData` hook available for live fetch; classify.js + CategorySection cover tier grouping |
| PROTO-02 | Prototype uses hardcoded mock compass data to demonstrate full vision without database changes | `buildAnswerMapByShortTitle()` signature confirmed; mock data can be a plain JS map keyed by politician ID + short_title values; RadarChartCore `data`/`compareData` props accept `{ [short_title]: number }` directly |
</phase_requirements>

---

## Summary

Phase 104 is a pure frontend build inside the `essentials` React app. No backend changes, no ev-ui changes, no new npm dependencies. All building blocks are already in place: `RadarChartCore` (ev-ui), `CategorySection` (ev-ui), `SegmentedControl`, `IconOverlay`, `classify.js`, and `usePoliticianData` hook. The prototype needs four new artifacts: `src/pages/Prototype.jsx`, `src/components/CompassFirstCard.jsx`, `src/data/mockCompassData.js`, and a route entry in `App.jsx`.

The single design challenge is rendering `RadarChartCore` in "shape-only" mode (no labels). The component always renders labels when `data` has keys — the planner must ensure `labelFontSize={0}` or `padding={0}` / `labelOffset={0}` suppresses them, or stub the topics array so short_titles are empty strings. Reviewed the component source: `labelFontSize` controls font size of spoke labels; setting it to `0` will make them invisible (font-size:0 in SVG). Setting `padding={0}` and `labelOffset={0}` makes label positions collapse to spoke tips but doesn't remove them. The clean approach is `labelFontSize={0}` — verified in RadarChartCore.jsx line 99 where `fSize = adaptiveFontSize(longestLineLen, baseFSize)` which calls `Math.max(baseFSize, 10)`. This means the minimum rendered font size is 10px regardless of `labelFontSize`. **The planner must account for this: labels cannot be fully hidden via props alone.** The correct approach is to pass `topics` where each `short_title` is an empty string, and use matching empty-string keys in `data`. This renders spokes without any text.

The mock data file must be seeded with topic `short_title` values from the live `compass.topics` table. The executor needs to query `SELECT id, short_title FROM compass.topics WHERE active = true ORDER BY display_order` before writing the file. The UI-SPEC documents 4 stance profiles (progressive, moderate, conservative, mixed) — the executor assigns these to the specific politician IDs returned by the Bloomington address.

**Primary recommendation:** Build `CompassFirstCard` as a thin wrapper over `RadarChartCore` with a `variant` prop ('A'|'B'|'C') that controls grid column count, radar `size`, and card padding via a lookup object — all rendering logic stays in one file.

---

## Standard Stack

### Core (already installed — no new deps)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| @chrisandrewsedu/ev-ui | ^0.1.55 | RadarChartCore, CategorySection, icons, tokens | Internal EV component library |
| react | ^19.1.1 | Component framework | Project standard |
| react-router-dom | ^7.8.2 | Route registration | Already used for all routes |
| tailwindcss | ^4.1.12 | Layout utilities | Project standard |

### No New Dependencies

The UI-SPEC (registry safety section) explicitly confirms: "No new npm dependencies introduced by this phase." All required functionality is covered by existing packages.

**Installation:** Nothing to install.

---

## Architecture Patterns

### Recommended File Structure

```
essentials/src/
├── pages/
│   └── Prototype.jsx         # new — /prototype route component
├── components/
│   └── CompassFirstCard.jsx  # new — compass-first card with variant prop
├── data/
│   └── mockCompassData.js    # new — hardcoded mock stances
└── App.jsx                   # modify — add /prototype Route
```

### Pattern 1: Route Registration (Feature-Flagged, No Nav Link)

`App.jsx` uses `<Routes>` from react-router-dom v7. Adding `/prototype` is a single `<Route>` addition. The route is NOT linked from any nav component — access is direct URL only (decision D-18).

```jsx
// In App.jsx Routes block — add after existing routes
import Prototype from "./pages/Prototype";

<Route path="/prototype" element={<Prototype />} />
```

No `RequireAuth` wrapper — the prototype is a public demo page.

### Pattern 2: Live API Fetch Using Existing Hook

`usePoliticianData` hook (verified in `src/hooks/usePoliticianData.js`) accepts a `query` string and `options.enabled`. The prototype passes the Bloomington address as a hardcoded string:

```jsx
const { data: politicians, phase } = usePoliticianData(
  "100 W Kirkwood Ave, Bloomington, IN 47404",
  { enabled: true }
);
```

The hook calls `searchPoliticians()` which calls `POST /essentials/candidates/search` with `{ query }`. No address state, no autocomplete input needed.

### Pattern 3: Mock Data Overlay

The mock data file exports a lookup by politician ID:

```js
// src/data/mockCompassData.js
// topic short_titles must match compass.topics.short_title exactly (case-sensitive)
const MOCK_STANCES = {
  // key: politician UUID (string), value: { [short_title]: number (1–n) }
  "uuid-of-politician-1": {
    "Healthcare": 8, "Climate": 7, "Economy": 3, "Immigration": 4,
    "Gun Policy": 3, "Education": 7, "Foreign Policy": 5, "Social Justice": 8,
  },
  // ... more politicians
};

export default MOCK_STANCES;
```

In `Prototype.jsx`, after `politicians` loads, the page merges mock stances:

```jsx
const mockAnswers = MOCK_STANCES[pol.id] || null; // null = placeholder state
```

### Pattern 4: RadarChartCore in Shape-Only Mode (No Labels)

`RadarChartCore` always renders label `<text>` elements when `data` has keys. Setting `labelFontSize={0}` does NOT work — `adaptiveFontSize` in the component enforces `Math.max(baseFSize, 10)`, so the minimum rendered size is 10px.

**Correct approach:** Pass topics where `short_title` is `""` and match keys accordingly:

```jsx
// Build topics array with blank short_titles for shape-only rendering
const blankTopics = spokeCount.map((_, i) => ({
  id: `mock-${i}`,
  short_title: `s${i}`,   // unique but display-irrelevant
  stances: Array(10).fill(null), // max denominator = 10
}));

// Data keys match the short_title values
const polData = { s0: 8, s1: 3, s2: 7, s3: 5, s4: 6, s5: 2, s6: 9, s7: 4 };
```

However, for dual overlay to work with user's real compass data (D-13), the topics and keys MUST match what `CompassContext.allTopics` uses. The prototype therefore uses the real short_titles from `allTopics` but suppresses labels visually by wrapping the RadarChartCore in a container with `overflow: hidden` and setting `padding` and `labelOffset` to `0` so labels render outside the SVG viewBox.

**Verified approach (from RadarChartCore.jsx viewBox calculation, lines 154-156):**

```jsx
// viewBox: `-${leftPadding} -${verticalPadding} ${size + leftPadding + rightPadding} ${size + verticalPadding * 2}`
// Setting padding=0 and labelOffset=0 means labels render at spoke tips but
// the SVG viewBox is exactly [0,0,size,size], clipping label text outside the box.
<RadarChartCore
  topics={topicsForCard}
  data={polData}
  compareData={userData}
  invertedSpokes={{}}
  onToggleInversion={() => {}}     // no-op — static per D-03
  onReplaceTopic={() => {}}        // no-op — static per D-03
  size={200}                       // variant A
  labelFontSize={0}                // suppressed (renders as 10px but outside viewBox)
  padding={0}
  labelOffset={0}
/>
```

With `padding=0` and `labelOffset=0`, `leftPadding`/`rightPadding`/`verticalPadding` all collapse to 0. The viewBox becomes `0 0 200 200`. Labels are positioned at `radius + 0` from center = at the SVG edge. They render but are clipped by the viewBox. This is the reliable suppression strategy without modifying ev-ui.

### Pattern 5: Placeholder Radar (D-08)

For politicians with no mock data, render a static SVG polygon (no RadarChartCore needed):

```jsx
function PlaceholderRadar({ size = 200 }) {
  const cx = size / 2;
  const cy = size / 2;
  const r = (size / 2) * 0.65; // ~70% max radius
  const n = 8; // octagon = 8 spokes
  const pts = Array.from({ length: n }, (_, i) => {
    const a = (2 * Math.PI * i) / n;
    return `${cx + r * Math.sin(a)},${cy - r * Math.cos(a)}`;
  }).join(' ');
  return (
    <svg
      width={size} height={size}
      viewBox={`0 0 ${size} ${size}`}
      role="img"
      aria-label="compass data unavailable"
    >
      <polygon
        points={pts}
        fill="none"
        stroke="#D3D7DE"
        strokeWidth="1.5"
        strokeDasharray="4 3"
      />
    </svg>
  );
}
```

### Pattern 6: Variant-Driven Grid Layout

The `variant` prop controls grid columns and card dimensions. Centralize variant config in a lookup object inside `CompassFirstCard.jsx` or co-locate in `Prototype.jsx`:

```js
const VARIANT_CONFIG = {
  A: { radarSize: 200, gridCols: 'grid-cols-1 md:grid-cols-2', padding: '16px', borderRadius: '12px' },
  B: { radarSize: 150, gridCols: 'grid-cols-2 sm:grid-cols-3', padding: '12px', borderRadius: '10px' },
  C: { radarSize: 140, gridCols: 'grid-cols-1', padding: '16px', borderRadius: '12px', horizontal: true },
};
```

Variant C uses a horizontal flex layout inside the card rather than a vertical stack.

### Pattern 7: CategorySection Tier Grouping

Reuse the exact same tier grouping logic from `Results.jsx`. The prototype calls `classifyCategory()` on each politician, groups them into Federal/State/Local buckets using `orderedEntries()`, and renders a `CategorySection` with `tier="federal"`, `tier="state"`, or `tier="local"` prop.

### Anti-Patterns to Avoid

- **Calling `fetchPoliticianAnswers()` for each politician:** The prototype bypasses the live API fetch for compass stances entirely — mock data is a local JS file. Never call the compass answers endpoint from the prototype.
- **Fetching compass topics to build the spoke layout:** The prototype reuses `CompassContext.allTopics` (already loaded globally by `CompassProvider` in `App.jsx`). No additional API calls needed.
- **Wrapping the prototype in a separate `CompassProvider`:** `CompassProvider` is already app-wide in `App.jsx` — the prototype page gets it for free via context.
- **Passing `undefined` to RadarChartCore `topics` when no mock data:** The placeholder state should render a plain SVG, not call RadarChartCore with empty/undefined data.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Politician tier grouping | Custom grouping logic | `classifyCategory()` + `orderedEntries()` from `classify.js` | Already handles all district types, order definitions |
| API fetch with loading state | Custom fetch hook | `usePoliticianData` hook | Race condition safety, abort controller, phase state |
| Accessible tooltips on icons | Custom tooltip | `IconOverlay` component | Already uses @floating-ui/react with ARIA roles |
| Radar chart rendering | Custom SVG chart | `RadarChartCore` from ev-ui | Animation, dual overlay, spoke layout all handled |
| Segmented control toggle | Custom tab component | `SegmentedControl.jsx` (existing) | ARIA radiogroup semantics, EV styling, already in project |
| Tier-aware section headers | Custom header | `CategorySection` from ev-ui | Accepts `tier` prop, tierColors wiring done in Phase 103 |

---

## Common Pitfalls

### Pitfall 1: RadarChartCore Minimum Label Font Size

**What goes wrong:** Developer sets `labelFontSize={0}` expecting labels to disappear. Labels render at 10px (hardcoded minimum in `adaptiveFontSize`).

**Why it happens:** `adaptiveFontSize` in `RadarChartCore.jsx` returns `Math.max(baseFSize, 10)`. The 10px floor was added to prevent unreadable labels in the full profile view.

**How to avoid:** Use `padding={0}` and `labelOffset={0}` together. The SVG viewBox collapses to `0 0 {size} {size}`, clipping label text that renders outside the polygon area. This requires no ev-ui changes.

**Warning signs:** Labels appear faintly at card scale during dev.

### Pitfall 2: Topic Short_Title Mismatch in Mock Data

**What goes wrong:** Mock data uses capitalization or spacing that doesn't exactly match `compass.topics.short_title`, causing dual overlay to show no user shape even when the user has compass data.

**Why it happens:** `buildAnswerMapByShortTitle` uses `.toLowerCase()` for matching (line 71 in compass.js), but `RadarChartCore` receives the original-cased short_titles as keys. If mock data keys use different casing from `allTopics[i].short_title`, the overlay breaks.

**How to avoid:** The executor MUST query `SELECT short_title FROM compass.topics WHERE active = true ORDER BY display_order` and use the exact returned strings as both the mock data keys and the topics array short_titles.

**Warning signs:** User has compass data but radar shows only blue polygon (no coral user overlay).

### Pitfall 3: Mock Data File Imported Before Topics Load

**What goes wrong:** Mock data is keyed by `short_title` but `CompassContext.allTopics` is empty on first render. The prototype attempts to build the answer map before topics are ready, resulting in an empty radar.

**Why it happens:** `CompassContext` loads topics asynchronously. The `compassLoading` flag tracks this.

**How to avoid:** Gate radar rendering on `!compassLoading`. Show placeholder card skeleton until `compassLoading === false`.

**Warning signs:** Radar renders as a flat dot (all values 0) on initial load, then flashes to correct shape after a moment.

### Pitfall 4: IconOverlay Position Requires `position: relative` on Card

**What goes wrong:** `IconOverlay` uses `position: absolute` with `bottom: 4, right: 4`. If the card container doesn't have `position: relative`, icons appear at a wrong position or escape the card.

**Why it happens:** Absolute positioning is relative to the nearest positioned ancestor. The existing `PoliticianCard` has `position: relative` on its wrapper — `CompassFirstCard` must do the same.

**How to avoid:** The card's outer `<div>` must have `position: relative`. Icons in the prototype are placed "near name/title area" (D-06) rather than photo corner, so the absolute positioning is applied to the text area container, not the full card.

**Warning signs:** Icons appear at the top-left of the page or float outside card boundaries.

### Pitfall 5: CategorySection Grid Override

**What goes wrong:** `CategorySection` renders `ev-category-grid` with `gridTemplateColumns: 'repeat(auto-fill, minmax(min(250px, 100%), 1fr))'`. This conflicts with the variant-specific column counts (2, 3, or 1 column grids from VARIANT_CONFIG).

**Why it happens:** `CategorySection` renders the grid div internally. The variant grid classes can't be injected into `CategorySection`'s internal grid.

**How to avoid:** Do NOT rely on `CategorySection`'s internal grid for card placement. Use `CategorySection` for the tier header only, and render the card grid as a separate `<div>` child with the variant-appropriate Tailwind classes. `CategorySection` renders `{children}` inside its grid div — wrapping the grid div inside the children with `display: contents` or applying explicit grid overrides via inline styles to override `ev-category-grid`.

**Correct approach:** Override `CategorySection`'s grid with `style` prop on children or render the grid outside CategorySection's children pattern:

```jsx
<CategorySection title={...} tier={...}>
  <div
    className={VARIANT_CONFIG[variant].gridCols}
    style={{ display: 'grid', gap: '16px', gridTemplateColumns: undefined }}
    // Tailwind grid classes override the ev-category-grid default
  >
    {politicians.map(...)}
  </div>
</CategorySection>
```

Since `CategorySection` wraps children in its own grid div, nesting a grid inside a grid works but requires care. Alternatively, the `style` prop on `CategorySection` can override the section wrapper but not the inner grid. The cleanest solution is to render CategorySection header-only (use a thin wrapper that extracts just the pill header) or accept the double-grid and use `display: contents` on the CategorySection's grid child wrapper.

**Warning signs:** Cards snap to auto-fill columns instead of the 2/3/1 column variant layout.

---

## Code Examples

### Verified: CompassContext Usage in Prototype

The prototype page gets compass data via `useCompass()` hook (already app-wide):

```jsx
// Source: essentials/src/contexts/CompassContext.jsx
const {
  allTopics,
  userAnswers,
  selectedTopics,
  invertedSpokes,
  compassLoading,
} = useCompass();
```

For the dual overlay, build user data map using existing utility:

```jsx
// Source: essentials/src/lib/compass.js — buildAnswerMapByShortTitle
const allowedShorts = allTopics
  .filter(t => t.active !== false)
  .map(t => t.short_title);

const { topicsFiltered, answersByShort: userData } = buildAnswerMapByShortTitle(
  allTopics, userAnswers, allowedShorts
);
```

### Verified: RadarChartCore Props

```jsx
// Source: ev-ui/src/RadarChartCore.jsx — prop signature
<RadarChartCore
  topics={topicsFiltered}      // [{ id, short_title, stances: [...] }]
  data={polData}               // { [short_title]: number } — politician (blue)
  compareData={userData}       // { [short_title]: number } — user (coral), omit or {} for blue-only
  invertedSpokes={{}}          // disabled for prototype (no inversion)
  onToggleInversion={() => {}} // no-op (static per D-03)
  onReplaceTopic={() => {}}    // no-op (static per D-03)
  size={200}                   // variant A; 150 for B; 140 for C
  labelFontSize={0}            // suppressed via padding=0+labelOffset=0 clip
  padding={0}
  labelOffset={0}
/>
```

Coral = `data` prop (user), Blue = `compareData` prop (politician). This is the REVERSE of `CompassCard.jsx` where `data=userData` and `compareData=polData`. Verify by checking CompassCard lines 283-292: `data={userData}` renders coral (rgba(255,87,64)), `compareData={polData}` renders blue. The prototype card shows the politician's shape (blue) as primary with user shape (coral) as comparison — same orientation as CompassCard.

### Verified: SegmentedControl for Variant Toggle

```jsx
// Source: essentials/src/components/SegmentedControl.jsx
<SegmentedControl
  options={[
    { value: 'A', label: 'Spacious' },
    { value: 'B', label: 'Compact' },
    { value: 'C', label: 'Horizontal' },
  ]}
  value={variant}
  onChange={setVariant}
  ariaLabel="Card layout variant"
/>
```

The SegmentedControl renders at full container width. Wrap it in a container with `maxWidth: 320px` and `margin: 0 auto` for centered positioning (per UI-SPEC).

### Verified: API Fetch for Bloomington Address

```jsx
// Source: essentials/src/hooks/usePoliticianData.js + essentials/src/lib/api.jsx
const BLOOMINGTON_ADDRESS = "100 W Kirkwood Ave, Bloomington, IN 47404";

const { data: politicians, phase } = usePoliticianData(BLOOMINGTON_ADDRESS, {
  enabled: true,
});
// phase: "idle" | "loading" | "fresh" | "error"
// politicians: Array of politician objects
```

### Verified: Tier Classification for Prototype Page

```jsx
// Source: essentials/src/lib/classify.js
import { classifyCategory, FEDERAL_ORDER, STATE_ORDER, LOCAL_ORDER, orderedEntries } from '../lib/classify';

const byTier = { Federal: {}, State: {}, Local: {} };
for (const pol of politicians) {
  const { tier, group } = classifyCategory(pol);
  if (!byTier[tier]) byTier[tier] = {};
  if (!byTier[tier][group]) byTier[tier][group] = [];
  byTier[tier][group].push(pol);
}
// Then render per tier using orderedEntries(byTier.Federal, FEDERAL_ORDER), etc.
```

---

## State of the Art

| Old Approach | Current Approach | Notes |
|--------------|------------------|-------|
| Headshot photo as card visual anchor | Radar chart as card visual anchor | This is the prototype's entire point — exploring the shift |
| Live API stances per politician card | Hardcoded mock JS data file | Prototype only — production would use real stances |
| Single card design | Three layout variants with in-browser toggle | A/B/C comparison is the prototype's research method |

---

## Open Questions

1. **CategorySection grid override for variant columns**
   - What we know: `CategorySection` renders its own internal grid with `auto-fill` column sizing
   - What's unclear: Can `display: contents` on a child wrapper reliably override the inner grid across all browsers? Or should the planner use CategorySection for the header pill only and render the grid as a sibling element?
   - Recommendation: Planner should design the task to render category title pills independently and put the card grid outside CategorySection's child tree, OR accept a nested grid (grid inside grid is valid CSS Grid) where the inner div uses explicit column counts that override auto-fill behavior.

2. **Topic short_titles for mock data**
   - What we know: Mock data must use exact short_titles from `compass.topics WHERE active = true ORDER BY display_order`
   - What's unclear: The exact 8 active topic short_titles (requires live DB query)
   - Recommendation: Make this Wave 0 task 1 — the executor queries the DB and writes the mock data file with verified IDs before building anything else.

3. **Bloomington politician IDs for mock data assignment**
   - What we know: Mock data is keyed by politician UUID; the exact UUIDs require loading the page
   - What's unclear: The UUIDs until the API is hit
   - Recommendation: Make mock data assignment Wave 0 task 2 — the executor fetches the Bloomington address once in dev, captures politician IDs from the response, then writes `MOCK_STANCES` entries for all returned politicians.

---

## Environment Availability

Step 2.6: SKIPPED — this phase is purely frontend code/config changes. No new external CLI tools, services, or runtimes are introduced. All required tools (Node.js, npm, Vite dev server) are standard project infrastructure verified by prior phases.

---

## Validation Architecture

`workflow.nyquist_validation` key is absent from `.planning/config.json` — treating as enabled.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None — essentials has no test framework configured (no vitest/jest in package.json, no test/ directory) |
| Config file | Does not exist |
| Quick run command | n/a |
| Full suite command | n/a |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROTO-01 | /prototype route renders tier sections with live Bloomington data | visual/smoke | manual — open http://localhost:5173/prototype | N/A |
| PROTO-02 | Mock compass data renders distinct radar shapes without DB access | visual/smoke | manual — verify 4 different polygon shapes visible | N/A |

Both requirements are visual/prototype-nature requirements with no automated test equivalent. Manual verification is the appropriate check.

### Wave 0 Gaps

The essentials project has no test infrastructure. For this prototype-exploration phase, automated tests are not required by REQUIREMENTS.md (PROTO-01 and PROTO-02 are visual prototype goals). No Wave 0 test files needed.

---

## Project Constraints (from CLAUDE.md)

- Tech stack: Node.js 20, TypeScript 5.6, Express 4, Supabase PostgreSQL, Zod — backend only. Frontend is React 19 + TypeScript 5.6 + Tailwind CSS 4.
- Design system: `ev-coral` (#ff5740), `ev-muted-blue` (#00657c), `ev-light-blue` (#59b0c4), `ev-yellow` (#fed12e). Font: Manrope.
- Antipartisan principle (from memory): Never show political parties or use partisan color associations.
- All new backend features follow service/route/migration/middleware pattern — NOT relevant to this phase (pure frontend).
- Compass-first card stays local to essentials as prototype, never promoted to ev-ui until layout confirmed (from STATE.md accumulated decisions).
- No new npm dependencies in this phase (UI-SPEC registry safety gate confirmed).
- Do NOT add nav link — route is feature-flagged, accessible by direct URL only (D-18).

---

## Sources

### Primary (HIGH confidence)
- Read directly: `essentials/src/components/CompassCard.jsx` — dual overlay pattern, answer map building, RadarChartCore props
- Read directly: `ev-ui/src/RadarChartCore.jsx` — complete component source, label suppression limitation identified
- Read directly: `essentials/src/contexts/CompassContext.jsx` — full context value shape
- Read directly: `essentials/src/hooks/usePoliticianData.js` — fetch hook API
- Read directly: `essentials/src/lib/compass.js` — `buildAnswerMapByShortTitle` signature
- Read directly: `essentials/src/lib/classify.js` — `classifyCategory`, `orderedEntries`, tier order arrays
- Read directly: `ev-ui/src/tokens.js` — full design token set
- Read directly: `ev-ui/src/CategorySection.jsx` — grid layout, `tier` prop usage
- Read directly: `essentials/src/components/SegmentedControl.jsx` — props and styling
- Read directly: `essentials/src/components/IconOverlay.jsx` — position pattern, absolute positioning
- Read directly: `essentials/src/App.jsx` — current route structure
- Read directly: `essentials/package.json` — confirmed no test runner, confirmed all deps available
- Read directly: `.planning/phases/104-compass-first-card-prototype/104-UI-SPEC.md` — visual contract, variant specs, spacing contract

### Secondary (MEDIUM confidence)
- None required — all findings verified from source code directly

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — read from package.json and source files
- Architecture: HIGH — all patterns derived from reading actual component source code
- Pitfalls: HIGH — label suppression pitfall verified by reading RadarChartCore.jsx line 305-307; CategorySection grid pitfall verified by reading CategorySection.jsx lines 87-91
- Mock data strategy: HIGH for approach; LOW for exact topic short_titles (requires live DB query — documented as Wave 0 task)

**Research date:** 2026-04-04
**Valid until:** 2026-05-04 (stable internal codebase — no external deps introduced)
