# Phase 128: Empty & Non-Compass Variants - Research

**Researched:** 2026-04-25
**Domain:** ev-ui component extension, cross-app deep-link contract, role classification
**Confidence:** HIGH — all findings verified against live codebase; no external library lookups required

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Card accepts an explicit `variant` prop: `'compass' | 'empty' | 'administrative' | 'judicial'`. Page-level code classifies; the card stays presentational.
- **D-02:** Variant classification logic lives in `essentials/src/lib/classify.js`. ev-ui does not regex politician titles.
- **D-03:** Empty-variant detection happens in the parent by counting answered topics in `userAnswers`. Threshold is existing 3-topic minimum. The card itself does NOT inspect `userAnswers.length`.
- **D-04:** The existing `view` prop (`'compass' | 'portrait'`) still applies to ALL variants.
- **D-05:** In COMPASS view, non-compass variants (administrative, judicial) replace the radar slot with: **"Compass currently unavailable for this role."** (same copy for both).
- **D-06:** In PORTRAIT view, non-compass variants render exactly like compass-variant portrait view from Phase 127. No extra captions.
- **D-07:** Empty variant radar slot shows the existing `PlaceholderRadar` (dashed octagon SVG). Lift into ev-ui in Phase 128.
- **D-08:** CTA copy: **"Build your compass"**. Placement: under or overlaid on the placeholder radar (exact placement is Claude's discretion).
- **D-09:** CTA target: deep-link into CompassV2's existing `CalibrationOverlay` flow. Wire to appropriate entry point using existing `startAtPick` and `resumeMode` props.
- **D-10:** Topic preselection scope: all unanswered topics across all levels. Not filtered by politician's level.
- **D-11:** Empty variant respects `view` toggle — in PORTRAIT view, placeholder and CTA disappear, standard portrait shown.
- **D-12:** Administrative detection: titles matching clerk, auditor, recorder, treasurer, assessor (classify.js lines 172-176, 213).
- **D-13:** Admin compass-view: "Compass currently unavailable for this role." plate. No role-specific hooks.
- **D-14:** Admin portrait-view: standard portrait, no extra caption.
- **D-15:** Judicial detection: `district_type = 'JUDICIAL'` or title matching judge/justice/court (officeDescriptions.js:89).
- **D-16:** Judicial compass-view: same neutral plate as administrative.
- **D-17:** Judicial portrait-view: standard portrait, no extra caption.
- **D-18:** Retention judge dual-appearance preserved unchanged (filter-layer behavior, not card-level).

### Claude's Discretion

- Exact CTA button placement, styling, and micro-copy variations (overlay vs below the placeholder, button vs link)
- Internal file layout in `ev-ui/src/` (one component file with branched render vs split files per variant)
- Copy of `PlaceholderRadar` into ev-ui — keep as inline helper or extract as separately-exported component
- Plate styling for "Compass currently unavailable for this role." text — typography, icon (or no icon), background treatment, spacing
- Whether empty-variant CTA preserves the user's intended destination after calibration completes

### Deferred Ideas (OUT OF SCOPE)

- Role-specific compass content (treasurer budget summaries, judicial retention bars, clerk records summaries)
- Treasurer → Treasury Tracker link
- Clerk → public records portal link
- Auditor → audit reports link
- Judicial retention history viz
- Court level + appointment source callouts
- Topic preselection by politician level
- Inline calibration modal in Essentials
- Different judicial variant content per filter context (elected vs appointed)
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STATE-01 | When user has < 3 compass answers, card renders placeholder radar + "Build your compass" CTA deep-linking to CompassV2 calibration | PlaceholderRadar already in ev-ui; CalibrationOverlay deep-link contract documented below |
| STATE-02 | Administrative roles render non-compass variant — "Compass currently unavailable for this role." plate in compass view, standard portrait in portrait view | Admin detection keywords verified in classify.js; plate spec documented from UI-SPEC.md |
| STATE-03 | Judicial roles render judge-appropriate non-compass variant; retention judges preserve dual-appearance | Judicial detection via `district_type === 'JUDICIAL'` or title regex; dual-appearance is filter-layer behavior unaffected by card change |
</phase_requirements>

---

## Summary

Phase 128 extends `CompassCardHorizontal` (ev-ui) with three new render paths activated by a new `variant` prop. All source assets — `PlaceholderRadar`, the card itself, the design tokens — already exist and are verified live. The primary implementation work is:

1. Adding the `variant` and `onBuildCompass` props to `CompassCardHorizontal` and branching `renderCompass()` accordingly.
2. Defining the deep-link URL contract from essentials → CompassV2 `CalibrationOverlay`.
3. Adding variant-computation logic to `essentials/src/pages/Prototype.jsx` so all four variant values can be exercised (Phase 129 wires live pages).
4. Publishing a patch/minor ev-ui release via the auto-bump pipeline.

The CalibrationOverlay deep-link is cross-app (essentials → compass.empowered.vote). The existing `?return=` + `sessionStorage.essentials_return_url` pattern is already implemented by `ReturnBanner.jsx` — this is the handoff mechanism to reuse.

**Primary recommendation:** Extend `renderCompass()` in `CompassCardHorizontal` with a `variant` branch guard before the existing radar logic; use inline plate and CTA patterns from the UI-SPEC.md; define the CompassV2 deep-link URL as `https://compass.empowered.vote/?return=<current-url>` (using the existing `essentials_return_url` sessionStorage key); publish as a minor ev-ui bump.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Variant classification (which variant to show) | Client — essentials page | — | D-02: ev-ui stays presentational; essentials owns classify.js |
| Rendering placeholder radar + CTA | Client — ev-ui component | — | D-07: PlaceholderRadar lifted into ev-ui; card renders it |
| Rendering "unavailable" plate | Client — ev-ui component | — | D-05: plate is purely presentational, owned by the card |
| Answer-count threshold check (< 3) | Client — essentials page | — | D-03: parent counts answers, passes `variant='empty'` |
| Deep-link URL construction | Client — essentials page | — | Parent builds URL (COMPASS_URL + ?return=), passes as `onBuildCompass` handler |
| CalibrationOverlay entry point | Client — CompassV2 app | — | Existing overlay already handles `startAtPick`; no CompassV2 changes needed |
| Cross-app return flow | Client — CompassV2 (ReturnBanner) | Client — essentials (URL reads fragment) | Existing sessionStorage + `?return=` pattern is already live |
| ev-ui publish + consumer auto-bump | CI — GitHub Actions | — | Auto-bump pipeline (OIDC → npm → dispatch → auto-merge) |

---

## Standard Stack

### Core (all already in use — no new installs)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@empoweredvote/ev-ui` | current (patch/minor bump) | Component being extended | The package being published |
| React | 19 | Component rendering | Already used across all apps |
| `ev-ui/src/tokens.js` | in-repo | Design tokens (colors, spacing, motion) | Single source of truth for EV design system |

### No New Dependencies

Phase 128 introduces no new npm packages. All required tools exist:
- `PlaceholderRadar` — already in ev-ui at `ev-ui/src/PlaceholderRadar.jsx` [VERIFIED: codebase]
- `CompassCardHorizontal` — already in ev-ui at `ev-ui/src/CompassCardHorizontal.jsx` [VERIFIED: codebase]
- `tokens.js` — all color, spacing, motion, typography values needed are already present [VERIFIED: codebase]

---

## Architecture Patterns

### System Architecture Diagram

```
essentials (page level)
  ├─ classifyCategory(pol) → tier/group
  ├─ isAdminRole(pol) → checks title for clerk/treasurer/auditor/recorder/assessor
  ├─ isJudicialRole(pol) → checks district_type === 'JUDICIAL' or title regex
  ├─ userAnswers.length < 3 → variant = 'empty'
  ├─ isAdminRole → variant = 'administrative'
  ├─ isJudicialRole → variant = 'judicial'
  └─ else → variant = 'compass'
        │
        ▼
CompassCardHorizontal (ev-ui)
  props: { politician, userAnswers, tierVisuals, view, surface, variant, onBuildCompass, onClick }
        │
        ├─ slotStyle (260×260 fixed square)
        │     ├─ view === 'portrait' → renderPortrait() [unchanged from Phase 127]
        │     ├─ variant === 'empty' → PlaceholderRadar + CTA button (position: absolute, bottom: 12px)
        │     ├─ variant === 'administrative' → neutral plate (teal-050 bg, textMuted text)
        │     ├─ variant === 'judicial' → same neutral plate as administrative
        │     └─ variant === 'compass' → renderCompass() [unchanged from Phase 127]
        │
        └─ CompassCardHorizontalMeta (unchanged)

CTA button (onBuildCompass)
  │
  └─ Parent builds: window.open(`${COMPASS_URL}/?return=${encodeURIComponent(window.location.href)}`)
        │
        └─ CompassV2 App.jsx reads ?return= → sessionStorage.essentials_return_url
              └─ CalibrationOverlay (startAtPick=true) handles calibration flow
                    └─ ReturnBanner shows "Return to Essentials" link after calibration
```

### Recommended Project Structure

```
ev-ui/src/
├── CompassCardHorizontal.jsx   # extend: add variant + onBuildCompass props
├── PlaceholderRadar.jsx        # already exists — no changes
├── CompassCardHorizontalMeta.jsx  # unchanged
├── tokens.js                   # unchanged
└── index.js                    # add onBuildCompass to JSDoc comment only

essentials/src/pages/
└── Prototype.jsx               # extend: compute variant per politician, pass onBuildCompass
```

### Pattern 1: Variant Branch in renderCompass()

The current `renderCompass()` function in `CompassCardHorizontal` handles only the live-radar or PlaceholderRadar cases. Phase 128 inserts a variant guard before the existing logic.

```jsx
// Source: ev-ui/src/CompassCardHorizontal.jsx (current production)
function renderSlotContent() {
  // Portrait view: same for all variants
  if (view === 'portrait') return renderPortrait();

  // Non-compass variants: replace radar slot
  if (variant === 'empty') return renderEmptyVariant();
  if (variant === 'administrative' || variant === 'judicial') return renderUnavailablePlate();

  // Default compass variant: existing logic unchanged
  return (
    <div style={{ width: '100%', height: '100%', display: 'flex', alignItems: 'center',
      justifyContent: 'center', padding: spacing[3], boxSizing: 'border-box' }}>
      {renderCompass()}
    </div>
  );
}
```

### Pattern 2: Empty Variant Render (CTA overlay)

From UI-SPEC.md — exact spec already locked:

```jsx
// Source: 128-UI-SPEC.md (verified design contract)
function renderEmptyVariant() {
  const [ctaHovered, setCtaHovered] = useState(false);
  return (
    <div style={{ width: '100%', height: '100%', position: 'relative',
      display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <PlaceholderRadar size={RADAR_SIZE} name={politician?.full_name || ''} />
      <button
        onClick={onBuildCompass}
        onMouseEnter={() => setCtaHovered(true)}
        onMouseLeave={() => setCtaHovered(false)}
        style={{
          position: 'absolute',
          bottom: '12px',
          left: '50%',
          transform: 'translateX(-50%)',
          minWidth: '160px',
          height: '44px',
          backgroundColor: ctaHovered
            ? semanticTokens.light.buttonPrimary.background.hovered  // #003E4D
            : semanticTokens.light.buttonPrimary.background.default, // #005366
          color: colors.textWhite,
          fontSize: fontSizes.sm,     // 14px
          fontWeight: fontWeights.semibold, // 600
          fontFamily: fonts.primary,
          borderRadius: borderRadius.full, // pill
          border: 'none',
          cursor: 'pointer',
          whiteSpace: 'nowrap',
          transition: `background ${duration.normal} ease`,
        }}
      >
        Build your compass
      </button>
    </div>
  );
}
```

### Pattern 3: Unavailable Plate (administrative + judicial)

```jsx
// Source: 128-UI-SPEC.md (verified design contract)
function renderUnavailablePlate() {
  return (
    <div style={{
      width: '100%',
      height: '100%',
      backgroundColor: colorScales.teal['050'],  // #F5F9FA
      borderRadius: borderRadius.xl,             // matches card border-radius
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      padding: spacing[4],
      boxSizing: 'border-box',
    }}>
      <p style={{
        fontSize: fontSizes.sm,           // 14px
        fontWeight: fontWeights.semibold, // 600
        lineHeight: 1.4,
        color: colors.textMuted,          // #718096 — 4.6:1 on #F5F9FA, WCAG AA
        textAlign: 'center',
        maxWidth: '180px',
        margin: 0,
      }}>
        Compass currently unavailable for this role.
      </p>
    </div>
  );
}
```

### Pattern 4: Admin/Judicial Variant Detection in Prototype.jsx

```jsx
// Source: essentials/src/lib/classify.js (verified) + officeDescriptions.js (verified)
function computeVariant(pol, userAnswers) {
  const answeredCount = (userAnswers || []).length;
  if (answeredCount < 3) return 'empty';

  const title = (pol.office_title || '').toLowerCase();
  const dt = pol.district_type || '';

  // Administrative detection — from classify.js lines 172-176, 213
  if (/clerk|treasurer|auditor|recorder|assessor/.test(title)) return 'administrative';

  // Judicial detection — from officeDescriptions.js:89 + branchType.js JUDICIAL case
  if (dt === 'JUDICIAL' || /judge|justice|court/.test(title)) return 'judicial';

  return 'compass';
}
```

### Pattern 5: Deep-Link URL Construction (essentials page)

```jsx
// Source: essentials/src/components/CompassCard.jsx pattern (verified)
const COMPASS_URL = import.meta.env.VITE_COMPASS_URL || 'https://compass.empowered.vote';

function handleBuildCompass() {
  const returnUrl = window.location.href;
  window.open(`${COMPASS_URL}/?return=${encodeURIComponent(returnUrl)}`, '_blank');
  // CompassV2 App.jsx reads ?return= and stores in sessionStorage.essentials_return_url
  // ReturnBanner.jsx renders "Return to Essentials" once calibration is complete
}
```

**Why `window.open` (new tab) over `window.location.href` (same tab):** CompassV2 is a separate domain. A same-tab redirect abandons the essentials page state. The existing `ReturnBanner` + `essentials_return_url` pattern is designed for users who navigate back — they click "Return to Essentials" after calibration. Using a new tab keeps context visible while the user calibrates.

**Note on `startAtPick`:** CompassV2's `App.jsx` HelpGuard checks `calibration_completed` / `calibration_skipped`. If neither flag is set, the user is redirected to `/results` which auto-launches `CalibrationOverlay` with `startAtPick=true`. If either flag is set, the user lands on the Compass page normally and must manually trigger calibration. The deep-link from essentials does not currently bypass this — it relies on the user's existing calibration state. This is consistent with D-09 (reuse existing flow, not rebuild it).

### Anti-Patterns to Avoid

- **Variant classification in ev-ui:** D-02 forbids this. The card receives `variant` as a prop; it never inspects `politician.district_type` or regexes titles internally.
- **Embedding answer-count logic in the card:** D-03 forbids this. The card does not count `userAnswers.length`; parent passes `variant='empty'` when count < 3.
- **Separate components per variant:** File proliferation for what is essentially a branched `renderSlotContent()`. One file with branched render is sufficient and matches Phase 127 patterns.
- **Re-implementing CalibrationOverlay in essentials:** D-09 explicitly rejects this. Use the deep-link to CompassV2.
- **Hard-coding COMPASS_URL:** Use `import.meta.env.VITE_COMPASS_URL || 'https://compass.empowered.vote'` following the existing `CompassCard.jsx` pattern.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Placeholder radar SVG | Custom dashed SVG | `PlaceholderRadar` from `ev-ui/src/PlaceholderRadar.jsx` | Already ported to ev-ui in Phase 127; pixel-perfect, accessible, tokens-sourced |
| Calibration flow | Inline topic picker in essentials | `CalibrationOverlay` in CompassV2 via deep-link | The full flow (pick → answer → persist → complete celebration) is ~1100 lines; deep-link reuses it entirely |
| Admin/judicial detection | New regex in ev-ui | `classify.js` + `officeDescriptions.js` in essentials | Classification is already centralized and battle-tested (Nicole Bolden fixes, Circuit Court reclassification) |
| Design tokens | Inline hex values | `colors`, `colorScales`, `semanticTokens`, `spacing`, `borderRadius`, `fontWeights`, `fontSizes`, `duration` from `ev-ui/src/tokens.js` | Token-sourced values maintain design consistency and enable future design system updates |

**Key insight:** Every building block exists. Phase 128 is assembly and wiring, not invention.

---

## Common Pitfalls

### Pitfall 1: `overflow: 'hidden'` on slotStyle clips absolute-positioned CTA button

**What goes wrong:** The `slotStyle` in Phase 127 has `overflow: 'hidden'` (clips slot corners via card border-radius). An absolute-positioned CTA button inside that div is clipped at the slot boundary.

**Why it happens:** `overflow: hidden` containing blocks clip all absolute descendants, not just those that overflow. The CTA at `bottom: 12px` is within the 260px slot height, so it is NOT clipped — but if `position: relative` is not set on the slot's inner wrapper, the CTA's absolute positioning anchors to the card root instead.

**How to avoid:** Wrap `PlaceholderRadar` and the CTA in a `position: relative` container that fills the slot (width/height 100%), then position the CTA absolutely within that container. The existing compass-render wrapper `<div style={{ width: '100%', height: '100%', display: 'flex', ... }}>` needs `position: 'relative'` added for the empty-variant branch.

**Warning signs:** CTA button appears in wrong position relative to the radar SVG; button is partially or fully hidden.

### Pitfall 2: `variant` prop default missing — existing consumers break

**What goes wrong:** If `variant` has no default, existing callers (prototype harness) that don't pass `variant` get `undefined`, causing the slot to render nothing.

**How to avoid:** Default `variant = 'compass'` in the component signature. All existing behavior is preserved; the new variants only activate when explicitly passed.

### Pitfall 3: CTA state (hover) lives in a sub-render function, triggering full re-mount

**What goes wrong:** Declaring `useState` inside a render function (not a component) violates the Rules of Hooks. `renderEmptyVariant()` is a method, not a React component — it cannot have local state.

**How to avoid:** Add `emptyCtaHovered` as a sibling `useState` at the `CompassCardHorizontal` top level, alongside the existing `hovered`/`focused`/`imgError` states. Set it via `onMouseEnter`/`onMouseLeave` on the CTA button element.

### Pitfall 4: `onBuildCompass` called without null guard when `variant !== 'empty'`

**What goes wrong:** `onBuildCompass` prop is undefined for non-empty variants. If the button renders in any other path (copy-paste error), calling `onClick={onBuildCompass}` without a guard throws.

**How to avoid:** Only render the CTA button in the `variant === 'empty'` branch. No null guard on `onBuildCompass` within the button because the button itself is conditional.

### Pitfall 5: Plate background color does not clip to card border-radius

**What goes wrong:** The `renderUnavailablePlate()` div fills the 260×260 slot and uses `borderRadius.xl`. But the card's `overflow: 'hidden'` on the outer card div already clips the slot to the card shape — applying `borderRadius.xl` again on the plate div creates a visible inner-radius gap at the slot boundary.

**How to avoid:** Remove `borderRadius` from the plate div — let the card's `overflow: hidden` clip it naturally. The plate should be `borderRadius: 0` (or no border-radius set) so it fills flush to the slot edges. Alternatively, apply only the portion of the radius that faces the interior (but simpler to let the card clip it).

### Pitfall 6: `classifyCategory` group name is not the variant signal

**What goes wrong:** Using `classifyCategory(pol).group` to detect admin/judicial roles is unreliable. For example, "Municipal Officials" includes clerks, but not all Municipal Officials are admin non-compass roles (future additions may change groupings). Similarly, "Local Judiciary" group exists, but JUDICIAL district_type is the authoritative signal.

**How to avoid:** Use the direct title keyword test (`/clerk|treasurer|auditor|recorder|assessor/`) and `district_type === 'JUDICIAL'` check, mirroring classify.js lines 172-176 and 213, not the group-name output.

---

## Code Examples

### CompassCardHorizontal — full prop signature after Phase 128

```jsx
// Source: ev-ui/src/CompassCardHorizontal.jsx (to be modified)
export default function CompassCardHorizontal({
  politician,
  userAnswers = null,
  tierVisuals = null,
  view = 'compass',
  surface = 'representatives',
  variant = 'compass',          // NEW: 'compass' | 'empty' | 'administrative' | 'judicial'
  onBuildCompass = null,        // NEW: () => void — called when "Build your compass" clicked
  onClick,
}) { ... }
```

### PlaceholderRadar — current production implementation in ev-ui

Already ported from essentials. Props: `size` (default 250), `name` (default ''). Background: `colorScales.teal['050']` (#F5F9FA). Stroke: `colorScales.gray['200']` (#D3D7DE). SVG aria-label: `"{name} — compass data unavailable"` or `"compass data unavailable"`.

```jsx
// Source: ev-ui/src/PlaceholderRadar.jsx (verified live)
// No changes needed — use as-is with size={RADAR_SIZE} (250)
<PlaceholderRadar size={RADAR_SIZE} name={politician?.full_name || ''} />
```

### Prototype.jsx — variant computation and onBuildCompass wiring

```jsx
// Source: essentials/src/pages/Prototype.jsx (to be modified)
const COMPASS_URL = import.meta.env.VITE_COMPASS_URL || 'https://compass.empowered.vote';

function computeVariant(pol, userAnswers) {
  if ((userAnswers || []).length < 3) return 'empty';
  const title = (pol.office_title || '').toLowerCase();
  const dt = pol.district_type || '';
  if (/clerk|treasurer|auditor|recorder|assessor/.test(title)) return 'administrative';
  if (dt === 'JUDICIAL' || /judge|justice|court/.test(title)) return 'judicial';
  return 'compass';
}

function handleBuildCompass() {
  const returnUrl = window.location.href;
  window.open(`${COMPASS_URL}/?return=${encodeURIComponent(returnUrl)}`, '_blank');
}

// In render:
<CompassCardHorizontal
  key={pol.id}
  politician={pol}
  userAnswers={userAnswers || []}
  tierVisuals={...}
  view={view}
  surface="representatives"
  variant={computeVariant(pol, userAnswers)}
  onBuildCompass={handleBuildCompass}
  onClick={() => navigate(`/politician/${pol.id}`)}
/>
```

### index.js — prop addition (JSDoc only, no new exports)

`PlaceholderRadar` is already exported from `ev-ui/src/index.js`? No — checking index.js, `PlaceholderRadar` is NOT currently exported. It is an internal dependency of `CompassCardHorizontal`. Per D-07, it should be lifted into ev-ui (already done in Phase 127 as an internal file). The UI-SPEC.md notes it is at `ev-ui/src/PlaceholderRadar.jsx`. No new export is required — it stays internal to `CompassCardHorizontal`. If a consumer needs it independently, that is a future decision.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `PlaceholderRadar` defined inline in `essentials/src/components/CompassFirstCard.jsx` | `PlaceholderRadar` extracted to `ev-ui/src/PlaceholderRadar.jsx` | Phase 127 (2026-04-19) | Can now be used from ev-ui directly without re-defining |
| `renderCompass()` handles only live radar or placeholder | `renderSlotContent()` branches on `variant` | Phase 128 (this phase) | Four render paths, all slot-uniform at 260×260 |

---

## Deep-Link Contract (Cross-App)

This is the key integration point for STATE-01. The contract between essentials and CompassV2 is defined entirely by existing code — no new CompassV2 changes are required.

### How CompassV2 handles inbound deep-links (verified in live code)

1. User clicks "Build your compass" in essentials
2. essentials opens: `https://compass.empowered.vote/?return=<encoded-essentials-url>`
3. `CompassV2/src/App.jsx` → `HelpGuard` reads `?return=` param → stores in `sessionStorage.essentials_return_url`
4. If user is uncalibrated (no `calibration_completed` / `calibration_skipped` flags), user is redirected to `/results`
5. `Compass.jsx` auto-launches `CalibrationOverlay` with `startAtPick=true` when `showChart` is false
6. After calibration, `ReturnBanner.jsx` reads `sessionStorage.essentials_return_url` and shows "Return to Essentials" banner
7. User clicks "Return" → `ReturnBanner.handleReturn()` navigates to `essentials-url + compass-fragment`

### Open question: already-calibrated users

If the user has previously calibrated (flags set), the HelpGuard passes them through directly to the Compass page — no auto-launch of CalibrationOverlay. These users already have ≥ 3 answers and should NOT see `variant='empty'` cards in the first place (parent would pass `variant='compass'`). So the deep-link is only reachable by users who are genuinely uncalibrated. This is self-consistent.

### URL environment variable

essentials already has `VITE_COMPASS_URL` used in `CompassCard.jsx` and `CompassPreview.jsx`. Production value: `https://compass.empowered.vote`. The Prototype.jsx harness does not currently use this — it will need to import it for the CTA.

---

## Prototype Harness Gap

The current `Prototype.jsx` uses `CompassFirstCard` from essentials (legacy), not `CompassCardHorizontal` from ev-ui. Phase 127 delivered `CompassCardHorizontal` in ev-ui but the prototype was not updated (Phase 129 was supposed to handle adoption, but the CONTEXT.md for Phase 128 says the prototype harness is needed to exercise all four variant values).

**Finding:** The prototype harness must switch from `CompassFirstCard` → `CompassCardHorizontal` AND add `computeVariant` + `onBuildCompass` wiring. This is a Phase 128 task, not Phase 129.

**Action required:** Prototype.jsx needs to:
1. Replace `CompassFirstCard` import with `CompassCardHorizontal` from `@empoweredvote/ev-ui`
2. Remove `VARIANT_CONFIG`, `VARIANT_OPTIONS`, the variant `SegmentedControl` (the `A/B/C` toggle no longer applies)
3. Add `computeVariant()` helper
4. Add `COMPASS_URL` constant and `handleBuildCompass()` function
5. Pass `variant`, `onBuildCompass`, `view`, `surface`, `userAnswers` to `CompassCardHorizontal`

Note: `userAnswers` from `CompassContext` is available in Prototype.jsx (it uses `CompassFirstCard` which already reads from context). After switching to `CompassCardHorizontal`, the prototype needs to read `userAnswers` from context directly.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `PlaceholderRadar` was already ported to `ev-ui/src/PlaceholderRadar.jsx` in Phase 127 | Standard Stack | [VERIFIED: codebase — file exists at that path with correct implementation] |
| A2 | `window.open` (new tab) is the right CTA navigation strategy vs same-tab redirect | Deep-Link Contract | If same-tab is preferred, essentials page state is abandoned. Deferred to Claude's discretion per D-09. |
| A3 | `VITE_COMPASS_URL` env var is available in essentials Prototype.jsx | Deep-Link Contract | [VERIFIED: CompassCard.jsx and CompassPreview.jsx already use it in essentials] |
| A4 | Phase 127 did not switch Prototype.jsx from CompassFirstCard to CompassCardHorizontal | Prototype Harness Gap | [VERIFIED: Prototype.jsx still imports CompassFirstCard — confirmed in live code] |

If this table were empty, all claims would be fully verified. A2 is a discretion call; others are code-verified.

---

## Open Questions

1. **New-tab vs same-tab for CompassV2 deep-link**
   - What we know: existing `CompassCard.jsx` links use `COMPASS_URL` but open in same tab (profile page context); existing `ReturnBanner` is designed for cross-app flow
   - What's unclear: user preference for "Build your compass" — new tab (preserves essentials) vs same tab (simpler, less context juggling)
   - Recommendation: default to new tab (`window.open(..., '_blank')`) to preserve essentials page state; if UX feedback prefers same tab, it is a one-line change

2. **Prototype.jsx userAnswers source**
   - What we know: current Prototype.jsx imports `CompassFirstCard` which reads from context internally; `CompassCardHorizontal` expects `userAnswers` as a prop
   - What's unclear: whether the CompassContext in essentials is mounted at the prototype route level
   - Recommendation: check that `essentials/src/App.jsx` wraps the prototype route with `CompassProvider` (or that context is accessible); if not, the prototype may need a mock userAnswers array for variant demonstration

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | ev-ui build (tsup) | ✓ | (project-standard) | — |
| npm | ev-ui publish pipeline | ✓ | — | — |
| `@empoweredvote/ev-ui` (public npm) | essentials, CompassV2 consumers | ✓ | Current | — |
| GitHub Actions (OIDC publish) | Auto-bump pipeline | ✓ | — | Manual: `npm publish` |

No missing dependencies. Phase 128 is code-only across three repos: `ev-ui`, `essentials`, `CompassV2` (no CompassV2 changes needed).

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Vitest (essentials) |
| Config file | `vite.config.js` (essentials) — Vitest runs via Vite |
| Quick run command | `cd essentials && npx vitest run src/lib/classify.js` or `npx vitest run --reporter=verbose` |
| Full suite command | `cd essentials && npm test` |

ev-ui has no test infrastructure (no test script, no test files, no testing devDependencies). Tests for new classify logic should live in essentials.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| STATE-01 | `computeVariant` returns `'empty'` when `userAnswers.length < 3` | unit | `cd essentials && npx vitest run src/lib/classify` | ❌ Wave 0 |
| STATE-01 | `computeVariant` returns `'compass'` when `userAnswers.length >= 3` and non-admin/judicial | unit | same | ❌ Wave 0 |
| STATE-02 | `computeVariant` returns `'administrative'` for titles: clerk, treasurer, auditor, recorder, assessor | unit | `cd essentials && npx vitest run src/lib/classify` | ❌ Wave 0 |
| STATE-02 | `computeVariant` returns `'compass'` for non-admin titles with >= 3 answers | unit | same | ❌ Wave 0 |
| STATE-03 | `computeVariant` returns `'judicial'` for `district_type === 'JUDICIAL'` | unit | same | ❌ Wave 0 |
| STATE-03 | `computeVariant` returns `'judicial'` for titles: judge, justice, court | unit | same | ❌ Wave 0 |
| STATE-03 | Retention judge dual-appearance unaffected | smoke (visual) | manual — verify in prototype harness | N/A |
| UI contract | CTA button renders at `bottom: 12px`, `height: 44px`, pill shape | visual/smoke | manual — verify in prototype harness | N/A |
| UI contract | Plate text is centered in 260×260 slot for admin/judicial | visual/smoke | manual — verify in prototype harness | N/A |

**Note:** The `computeVariant` function should be extracted to a named export in `essentials/src/lib/classify.js` (not inlined in Prototype.jsx) to make it testable.

### Sampling Rate

- **Per task commit:** `cd essentials && npx vitest run src/lib/classify`
- **Per wave merge:** `cd essentials && npm test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `essentials/src/lib/classify.test.js` (or append to existing test) — covers STATE-01, STATE-02, STATE-03 `computeVariant` logic
- [ ] Export `computeVariant` from `essentials/src/lib/classify.js` to make it importable in tests

*(Existing test infrastructure: `essentials/src/lib/groupHierarchy.test.js` and `compass.address.test.js` use Vitest — no new framework install needed)*

---

## Security Domain

Phase 128 introduces no authentication, data persistence, or server-side changes. The deep-link URL passes `window.location.href` (an essentials page URL) to CompassV2 via a `?return=` query parameter.

**Open redirect risk:** The `?return=` param is stored in `sessionStorage.essentials_return_url` and used in `ReturnBanner.handleReturn()` as `window.location.href = returnUrl + fragment`. This is the existing production behavior. The risk is that a malicious URL could redirect users off-domain. However, since essentials constructs this URL internally (not from user input), the attack surface is low. The existing code does not validate the return URL against an allowlist — this is a pre-existing pattern, not something introduced by Phase 128.

No ASVS categories are meaningfully activated by Phase 128 beyond what already exists.

---

## ev-ui Release Pipeline Summary

After Phase 128 implementation:

1. PR from `feat/compass-how-it-works` (or a feature branch) into `ev-ui/main`
2. After merge: `cd ev-ui && npm version minor && git push origin main --follow-tags`
   - Minor bump (not patch) because `variant` and `onBuildCompass` are new public API surface
3. `publish.yml` fires: builds, publishes to npm (OIDC — no token needed), dispatches to consumers
4. Consumer repos (`CompassV2`, `essentials`, `read-rank`, `civic-spaces`) each get an auto-PR
5. `build-check.yml` gates auto-merge; once green, Render auto-deploys

The essentials-side changes (Prototype.jsx, classify.js additions) are in the `essentials` repo on the shared branch. They do NOT require a separate npm publish — they are direct source changes.

---

## Sources

### Primary (HIGH confidence — verified in live codebase)

- `ev-ui/src/CompassCardHorizontal.jsx` — full Phase 127 component API, SLOT_WIDTH=260, RADAR_SIZE=250, renderCompass(), renderPortrait(), slotStyle
- `ev-ui/src/PlaceholderRadar.jsx` — exact SVG implementation, props, tokens used
- `ev-ui/src/tokens.js` — all color/spacing/typography/motion values
- `ev-ui/src/index.js` — current export barrel
- `essentials/src/lib/classify.js` — admin detection keywords (lines 172-176: `clerk|treasurer|auditor|recorder|assessor`; line 213: county variants)
- `essentials/src/utils/branchType.js` — judicial district_type handling (`case 'JUDICIAL': return 'Judicial'`), county admin regex
- `essentials/src/utils/officeDescriptions.js:89` — judicial title regex: `/judge|justice|court/`
- `CompassV2/src/components/CalibrationOverlay.jsx` — full prop API (`onComplete`, `onSkip`, `resumeMode`, `startAtPick`), `STORAGE_KEY`, step flow
- `CompassV2/src/App.jsx` — HelpGuard `?return=` param → `sessionStorage.essentials_return_url`
- `CompassV2/src/components/ReturnBanner.jsx` — cross-app return flow
- `essentials/src/pages/Prototype.jsx` — current harness using `CompassFirstCard` (not yet switched to `CompassCardHorizontal`)
- `essentials/src/components/CompassCard.jsx` — `VITE_COMPASS_URL` pattern (existing cross-app link pattern)
- `.planning/phases/128-empty-non-compass-variants/128-UI-SPEC.md` — verified design contract for all three new variants
- `.planning/phases/128-empty-non-compass-variants/128-CONTEXT.md` — all 18 locked decisions
- `ev-ui/README-AUTOBUMP.md` — release pipeline (OIDC, dispatch, auto-merge)

### Secondary (MEDIUM confidence)

- `essentials/src/lib/groupHierarchy.test.js` — confirms Vitest is the test framework in essentials; pattern for writing new classify tests

---

## Metadata

**Confidence breakdown:**
- Standard Stack: HIGH — no new packages; all existing
- Architecture: HIGH — all code verified; data flow traced through live files
- Pitfalls: HIGH — verified against specific live code patterns (overflow:hidden, hook rules, etc.)
- Deep-link contract: HIGH — full CalibrationOverlay and ReturnBanner code read and traced

**Research date:** 2026-04-25
**Valid until:** 2026-05-25 (30 days — stable codebase, no fast-moving dependencies)
