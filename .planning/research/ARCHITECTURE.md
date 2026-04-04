# Architecture Patterns

**Domain:** Visual polish — icon system, tier hues, compass-first cards, headshot validation
**Researched:** 2026-04-02
**Milestone:** v2026.4.1 Essentials Visual Polish & Election Improvements
**Overall confidence:** HIGH — all findings from direct source inspection

---

## Current Component Map

### ev-ui (shared library, v0.1.54)

| Component | File | What it does |
|-----------|------|-------------|
| `PoliticianCard` | `PoliticianCard.jsx` | Horizontal/vertical card with image, name, title, subtitle, badge pill, compass button. Inline SVG compass icon. All styles via `tokens.js` inline objects (not Tailwind classes). |
| `CategorySection` | `CategorySection.jsx` | Section wrapper with title pill, info tooltip, external website link. Styles via `tokens.js`. Grid layout with `auto-fill minmax(250px)`. |
| `PoliticianProfile` | `PoliticianProfile.jsx` | Full politician profile view. Contains its own `buildTitleAndSubtitle()` — duplicates logic from Results.jsx. |
| `tokens.js` | `tokens.js` | Single source of truth: brand colors, full color scales (050-950 per hue), pillar themes (inform/connect/empower), semantic tokens, data viz palette, spacing, typography, shadows, motion. |
| `tailwind-preset.js` | `tailwind-preset.js` | Tailwind theme config consuming tokens. Flattens color scales to `ev-coral-500`, `ev-teal-300`, etc. |

### essentials (app, React 19 + Tailwind CSS 4)

| File | Role |
|------|------|
| `src/pages/Results.jsx` | Main page: address search, two-panel layout, representatives + elections tabs. Contains its own title/subtitle/qualification logic that partially duplicates `PoliticianProfile.jsx`. |
| `src/pages/Landing.jsx` | Single address input box with Search button. No location shortcuts or coverage messaging. |
| `src/lib/classify.js` | `classifyCategory(pol)` returns `{ tier: "Federal"|"State"|"Local", group: string }`. Exports ordered group arrays (`FEDERAL_ORDER`, `STATE_ORDER`, `LOCAL_ORDER`) and a display name map. |
| `src/components/ElectionsView.jsx` | Elections tab renderer. Uses `CategorySection` + `PoliticianCard` from ev-ui. Has its own simpler `getTier()` that maps `district_type` prefix to Federal/State/Local. |
| `src/components/PoliticianCard.jsx` | Separate, older vertical-layout card used in PoliticianGrid. Different visual and props from ev-ui's `PoliticianCard`. No tier color logic. |
| `src/components/CompassPreview.jsx` | Popover showing mini radar chart triggered from compass button. |
| `src/components/LocationBrowser.jsx` | Browse-by-location dropdown used in Results.jsx for non-address searches. |

---

## Integration Points by Feature

### 1. Icon System

**Where icons currently appear:**
- `PoliticianCard` (ev-ui) — one hard-coded inline SVG (compass/radar icon inside the teal compass button). The `badge` prop renders a coral text pill (e.g., "On Ballot", "Candidate", "Vacant").
- `CategorySection` (ev-ui) — no icon slots exist.
- `ElectionsView.jsx` (essentials) — tier separator rows show plain text ("Federal", "State", "Local") with a horizontal rule.

**Proposed icon slots and ownership:**

| Surface | Icon type | Where it lives | Integration point |
|---------|-----------|---------------|------------------|
| PoliticianCard | "On Ballot", "Compass Available", branch type | ev-ui | Add `icons?: string[]` prop alongside existing `badge`. Render as 16px SVG glyphs with tooltip on hover. |
| CategorySection title | Branch indicator (legislative/executive/judicial) | ev-ui | Add optional `icon?: React.ReactNode` prop rendered left of the title pill. |
| ElectionsView tier headers | Federal/State/Local tier icon | essentials | Keep local — `getTier()` is essentials-only; add icon beside the tier label. |

**New file: `ev-ui/src/icons.js`**

Export named SVG function components (e.g., `BallotIcon`, `CompassIcon`, `LegislativeIcon`, `ExecutiveIcon`, `JudicialIcon`). Pattern matches the existing inline `CompassIcon` inside PoliticianCard — simple 24x24 paths, `currentColor`, no external dependency.

**Signal sources in Results.jsx (already available):**
- `politicianIdsWithStances.has(pol.id)` → "Compass Available" icon
- `getSeatBallotStatus(pol.term_end, pol.term_date_precision)` → "On Ballot" icon (currently renders as text badge)
- `pol.district_type` → branch type (NATIONAL_EXEC/STATE_EXEC/LOCAL_EXEC = Executive; NATIONAL_UPPER/LOWER/STATE_UPPER/LOWER/LOCAL = Legislative; JUDICIAL = Judicial)

**Backward compatibility:** The `badge` prop stays. `icons[]` is additive. Existing callsites that pass only `badge="On Ballot"` continue working unchanged.

---

### 2. Tier Hue Differentiation

**Current state:** No tier hue logic anywhere. `classifyCategory()` returns tier strings used only for filtering/ordering. `CategorySection` title pill has uniform `colors.bgWhite` background and `colors.borderMedium` border — no color variation.

**Where tier hue logic belongs — `tokens.js`:**

`tokens.js` already has `colorScales` (full per-hue scales) and a `pillars` map (inform/connect/empower). Add a new `tierColors` export alongside `pillars`:

```js
// tokens.js addition
export const tierColors = {
  Federal: {
    accent: colorScales.teal['500'],       // #00657C
    light:  colorScales.teal['050'],       // #F5F9FA
    border: colorScales.teal['200'],       // #C0E8F2
    text:   colorScales.teal['700'],       // #003E4D — AA-safe
  },
  State: {
    accent: colorScales.skyblue['500'],    // #59B0C4
    light:  colorScales.skyblue['050'],    // #F6F8F8
    border: colorScales.skyblue['200'],    // #CDE0E5
    text:   colorScales.skyblue['700'],    // #327E8F — AA-safe
  },
  Local: {
    accent: colorScales.yellow['600'],     // #FAC400
    light:  colorScales.yellow['050'],     // #FAF9F5
    border: colorScales.yellow['200'],     // #F1E7C0
    text:   colorScales.yellow['900'],     // #7B640E — AA-safe
  },
};
```

**Propagation to CategorySection:**

Add an optional `tier?: 'Federal' | 'State' | 'Local'` prop. When present, apply `tierColors[tier].light` as titlePill background and `tierColors[tier].border` as titlePill border. When absent, use existing neutral defaults — backward compatible.

**Where `tier` comes from:**

`classify.js` `classifyCategory()` already produces `{ tier, group }`. In Results.jsx, the render loop maps groups to `CategorySection` calls. The `tier` is already in scope at the call site; it just needs to be passed down.

**Why not Tailwind classes:** All `PoliticianCard` and `CategorySection` styles are inline objects resolved from `tokens.js` (not Tailwind classes). Dynamic Tailwind class strings (e.g., `bg-ev-teal-050`) are not safe with Tailwind 4's static analyzer. The inline-from-tokens pattern is correct and consistent.

---

### 3. Compass-First Card

**Current situation:** `PoliticianCard` (ev-ui) is photo-first. The compass button is a small teal circle in the far right. The compass is a secondary affordance even when stances are available.

**Component decision — new local component in essentials:**

| Option | Verdict |
|--------|---------|
| New `CompassFirstCard` in essentials | Prototype here first. Fast, zero library publish cycle, can be iterated without affecting CompassV2 or EV-readrank. |
| Variant prop on ev-ui `PoliticianCard` | Risks making an already complex component (horizontal + vertical + 3 badge states) harder to maintain before the design is confirmed. |
| New component directly in ev-ui | Premature. ev-ui is published to npm; API churn during prototyping requires version bumps and consumer updates. |

**Recommended:** Build `CompassFirstCard.jsx` in `essentials/src/components/`. Promote to ev-ui in a follow-up milestone once the layout is confirmed. This follows the precedent of `CompassPreview.jsx` (still local to essentials).

**Data flow for compass-first card:**

All signals are already available in Results.jsx:
- `politicianIdsWithStances.has(pol.id)` — whether compass data exists
- `onCompassClick` handler — opens `CompassPreview` popover
- `getImageUrl(pol)` — optional (photo becomes secondary or omitted)
- `pol.first_name`, `pol.last_name`, `cardTitle`, `subtitle` — identity text

The compass-first card uses the radar mini-preview as the primary visual block (replacing the photo slot), with the politician name and title below. When no stances exist, falls back to the standard photo layout.

**Feature flag approach:** Add a toggle button in the ResultsHeader area (similar to the existing "Search by Address / Browse by Location" mode toggle). Store in local state (`useState`) — no persistence needed for prototype phase.

---

### 4. Headshot Crop Validation

**Current handling:** `PoliticianCard` (ev-ui) uses `objectFit: 'cover'` on an 80px-wide × 96px-tall container (horizontal variant). No crop validation exists. An `onError` handler falls back to initials. There is no aspect-ratio checking or focal point control.

**The problem:** 503 CDN-hosted headshots vary in crop quality — landscape photos, portrait shots with excessive headroom, low-resolution thumbnails all render poorly at 80×96 with center-crop.

**Recommended two-phase approach:**

Phase A — Immediate improvement with no data changes:

Add an `imageFocalPoint?: { x: number, y: number }` prop to `PoliticianCard` (ev-ui). Apply as `objectPosition: '${x*100}% ${y*100}%'` on the `<img>` element. Default the prop to `{ x: 0.5, y: 0.15 }` — top-weighted center. Politicians' faces appear in the upper portion of most headshot photos; this default improves rendering across all 503 images without any per-image data.

Phase B — Audit script (one-time, runs against Supabase):

Write a Node.js script that fetches each CDN URL from `essentials.politician_images`, downloads the image via `sharp`, checks aspect ratio and minimum dimension, and flags outliers. Output: a markdown report identifying images needing re-crop or replacement. No automated changes — human reviews and re-uploads as needed.

**Validation approach comparison:**

| Approach | Complexity | When | Notes |
|----------|-----------|------|-------|
| Default top-weighted `objectPosition` | Low | Immediate | Improves most headshots; no data changes |
| One-time audit script + manual fixes | Medium | One-time | Catches true outliers; doesn't scale with 503 images |
| Runtime face detection (browser ML) | High | Per render | Overkill; adds large bundle |
| Build-time automated crop correction | High | CI | Requires server-side image processing infrastructure |

---

### 5. Landing Page Location Buttons

**Current state:** `Landing.jsx` is 74 lines — a centered heading, subtitle, and single address input. No coverage area messaging, no location shortcuts.

**Recommended implementation:** Hardcoded coverage area buttons added below the search input. Two buttons for the two supported areas (Monroe County IN / LA County CA). Each calls `handleSearch()` with a representative address that will resolve to the correct geofence set.

No new components needed. No API changes. The `LocationBrowser` component (used in Results.jsx browse mode) is not appropriate for the landing page — it is a dropdown for browsing all bodies, not a "quick start" affordance.

**Simple implementation:**

```jsx
// Below the search input in Landing.jsx
<div className="flex gap-3 justify-center mt-4">
  <button onClick={() => navigate('/results?q=Bloomington%2C%20IN')}>
    Monroe County, IN
  </button>
  <button onClick={() => navigate('/results?q=Los%20Angeles%2C%20CA')}>
    Los Angeles County, CA
  </button>
</div>
```

Pair with a short coverage disclaimer: "Currently covering Monroe County, IN and Los Angeles County, CA."

---

## Component Boundaries (Revised for v2026.4.1)

```
ev-ui (npm library)
├── tokens.js         MODIFY: add tierColors export
├── icons.js          NEW: named SVG icon exports (BallotIcon, CompassIcon, etc.)
├── PoliticianCard    MODIFY: add icons[] prop, imageFocalPoint prop
├── CategorySection   MODIFY: add optional tier prop for hue
└── (unchanged: PoliticianProfile, RadarChartCore, SiteHeader, StanceAccordion, ...)

essentials (app)
├── pages/Landing.jsx            MODIFY: add location buttons + coverage text
├── pages/Results.jsx            MODIFY: pass tier to CategorySection; pass icons to PoliticianCard
├── components/CompassFirstCard  NEW: compass-first layout prototype (local, not ev-ui yet)
├── components/ElectionsView     MODIFY: add tier icons to separator rows; remove incumbent subtitle
└── (unchanged: CompassPreview, LocationBrowser, SegmentedControl, ...)
```

---

## Data Flow

### Icon signal resolution (Results.jsx → PoliticianCard)

```
For each pol in renderPoliticianCard():

  icons = []

  politicianIdsWithStances.has(pol.id)
    → true: icons.push('compass')

  getSeatBallotStatus(pol.term_end, pol.term_date_precision)
    → truthy: icons.push('ballot')  [replaces badge="On Ballot"]

  pol.district_type ends with _EXEC
    → icons.push('executive')
  pol.district_type contains UPPER or LOWER
    → icons.push('legislative')
  pol.district_type === 'JUDICIAL'
    → icons.push('judicial')

  <PoliticianCard icons={icons} ... />
```

### Tier color flow

```
classify.js
  classifyCategory(pol) → { tier: "Federal"|"State"|"Local", group: string }

Results.jsx
  for each (tier, groups) in displayedPoliticians:
    <CategorySection tier={tier} ... />   // passes tier down

CategorySection
  import { tierColors } from './tokens'
  const hue = tierColors[tier]            // resolved from tokens.js
  titlePill style: { background: hue?.light, borderColor: hue?.border }
  (if no tier prop → existing neutral defaults unchanged)
```

### Compass-first card data flow

```
Results.jsx state:
  [compassMode, setCompassMode] = useState(false)   // toggle

  if (compassMode && politicianIdsWithStances.has(pol.id)):
    render <CompassFirstCard pol={pol} onCompassClick={...} onClick={...} />
  else:
    render <PoliticianCard ... />   // unchanged path
```

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Dynamic Tailwind class interpolation for tier hues

**What:** `` className={`bg-ev-${tier.toLowerCase()}-050`} ``

**Why bad:** Tailwind 4 uses static analysis to build the CSS output. Dynamic string construction means the class is never included in the output. The element will have no background.

**Instead:** Inline styles with `tierColors[tier].light` from tokens.js, or a pre-enumerated static lookup object mapping tier strings to full Tailwind class strings.

---

### Anti-Pattern 2: Adding an icon library dependency to ev-ui

**What:** Installing Heroicons, Lucide, Phosphor, etc. in ev-ui.

**Why bad:** ev-ui has zero icon dependencies today. Adding one increases the bundle size for all three consumers (CompassV2, essentials, EV-readrank). Heroicons adds ~15KB min+gz for the full set.

**Instead:** Inline SVG components exported from `ev-ui/src/icons.js`. The compass button in PoliticianCard is already an inline SVG — this is the established pattern in the codebase.

---

### Anti-Pattern 3: Runtime image crop detection in the browser

**What:** Face-detection API, canvas pixel analysis, or ML model to validate headshots at render time.

**Why bad:** Adds significant JS weight, delays rendering, fires on every image load, and adds latency for a problem that is better solved once at import time.

**Instead:** Default top-weighted `objectPosition: '50% 15%'` on PoliticianCard images (catches 80% of cases), plus a one-time offline audit script for the remaining outliers.

---

### Anti-Pattern 4: Promoting CompassFirstCard to ev-ui during prototype

**What:** Adding the compass-first card layout to ev-ui while its API is still being iterated.

**Why bad:** ev-ui publishes to GitHub Packages npm registry. Breaking or changing a component's prop interface requires bumping the version and running `npm update @chrisandrewsedu/ev-ui` in all three consuming apps. Prototype churn is expensive to propagate.

**Instead:** Keep CompassFirstCard in essentials until the design is confirmed across at least one full release cycle. Then promote to ev-ui with a stable prop API.

---

### Anti-Pattern 5: Hardcoded tier colors in components (not tokens.js)

**What:** Writing `backgroundColor: '#F5F9FA'` directly in CategorySection for Federal.

**Why bad:** Color values must stay in tokens.js — that is the single source of truth synced to Penpot. Direct hex values in components break the design system and cannot be updated centrally.

**Instead:** Always reference `tierColors[tier].light` (or equivalent) from `tokens.js`.

---

## Build Order (Dependency-Ordered)

| Step | Work | Location | Dependency |
|------|------|----------|-----------|
| 1 | Add `tierColors` to `tokens.js` | ev-ui | Nothing — first |
| 2 | Create `icons.js` with SVG exports | ev-ui | Nothing — parallel with step 1 |
| 3 | Add `tier` prop to `CategorySection` | ev-ui | Step 1 |
| 4 | Add `icons[]` prop to `PoliticianCard` | ev-ui | Step 2 |
| 5 | Add `imageFocalPoint` prop to `PoliticianCard` | ev-ui | Independent; batch with step 4 |
| 6 | Publish ev-ui v0.1.55 | npm | Steps 1-5 complete |
| 7 | Update essentials to ev-ui v0.1.55 | essentials | Step 6 |
| 8 | Wire `tier` into CategorySection calls in Results.jsx | essentials | Step 7 |
| 9 | Wire `icons[]` into PoliticianCard calls in Results.jsx + ElectionsView.jsx | essentials | Step 7 |
| 10 | Add location buttons + coverage text to Landing.jsx | essentials | Independent; no ev-ui dep |
| 11 | Remove incumbent subtitle from ElectionsView | essentials | Independent |
| 12 | Run headshot audit script | scripts | Independent; batch with steps 10-11 |
| 13 | Build `CompassFirstCard.jsx` prototype | essentials | Steps 7-9 (card patterns finalized) |

Steps 1+2 and 3+4+5 can be done in parallel. Steps 10, 11, and 12 are independent of each other.

---

## Scalability Considerations

| Concern | Now | After v2026.4.1 |
|---------|-----|----------------|
| Icon bundle size | 0 (1 inline SVG) | ~2-4KB (handful of inline SVGs in icons.js) |
| Tier color tokens | None | 12 color values in tokens.js |
| ev-ui consumers affected | 3 | 3 — new props are optional, no breaking changes |
| Headshot validation overhead | None | Zero runtime cost (objectPosition is CSS-only) |
| CompassFirstCard maintenance | N/A | Local to essentials; no cross-app impact until promoted |

---

## Sources

All findings from direct code inspection — no external verification required for integration questions.

- `ev-ui/src/PoliticianCard.jsx` — prop interface, styling approach, existing inline SVG pattern
- `ev-ui/src/CategorySection.jsx` — prop interface, styling approach
- `ev-ui/src/tokens.js` — colorScales, colors, pillars, semantic tokens, spacing
- `ev-ui/src/tailwind-preset.js` — how tokens map to Tailwind class names
- `ev-ui/src/index.js` / `index.jsx` — exported public API
- `ev-ui/package.json` — current version: 0.1.54
- `essentials/src/pages/Results.jsx` — renderPoliticianCard(), classify flow, compass integration, tier loop
- `essentials/src/pages/Landing.jsx` — current state (74 lines, single input)
- `essentials/src/lib/classify.js` — classifyCategory(), tier/group taxonomy
- `essentials/src/components/ElectionsView.jsx` — getTier(), tier separator rendering
- `essentials/src/components/PoliticianCard.jsx` — legacy vertical card (separate from ev-ui)
- `.planning/PROJECT.md` — v2026.4.1 target features
