# Phase 127: CompassCardHorizontal in ev-ui - Research

**Researched:** 2026-04-19
**Domain:** React component library authoring (ev-ui) — port of a compass-first politician card from essentials
**Confidence:** HIGH

## Summary

Phase 127 is a component-lift operation: `essentials/src/components/CompassFirstCard.jsx` variant C is the near-complete reference implementation and needs to be ported into `@empoweredvote/ev-ui` as `CompassCardHorizontal`. The ev-ui repo already has a stable publishing pipeline (OIDC trusted publishing + auto-bump PRs to consumers), a proven token system (`tokens.js` + `tailwind-preset.js`), and an existing `PoliticianCard` that establishes the affordance baseline for CARD-03 parity. Variant C's visual behavior has already been approved and is live at `/prototype`; no behavioral redesign is required.

The two material pieces of new work: (1) adding a controlled `view` prop and portrait rendering at identical 260px dimensions to the radar (grid uniformity), (2) splitting meta-column content by a `surface` prop (representatives vs elections). Both are locked in `127-UI-SPEC.md` and `127-CONTEXT.md`.

**Primary recommendation:** Treat this as a mechanical port + token rewire. Three new files in `ev-ui/src/` (`CompassCardHorizontal.jsx`, `CompassCardHorizontalMeta.jsx`, `PlaceholderRadar.jsx`), one export added to `index.js`, one harness update in `essentials/src/pages/Prototype.jsx`. No test framework exists in ev-ui today — do not block the phase on adding one; validate via the harness (manual visual + type-level) and via a consumer smoke build.

## User Constraints (from CONTEXT.md)

### Locked Decisions

**Component API**
- D-01: Flat top-level props — `politician`, `userAnswers`, `tierVisuals` as separate props. Not a config object, not slot-based.
- D-02: Radar is rendered internally by the card via `RadarChartCore`. No render-prop / children API for the chart.
- D-03: Card accepts a controlled `view` prop (`'compass' | 'portrait'`). Card does NOT own view state and does NOT render its own toggle button.

**View Toggle**
- D-04: View state lives at the parent/page level. One page-level `SegmentedControl` flips all cards simultaneously.
- D-05: View preference persists globally per-user via localStorage (key `ev:compass-card-view`).
- D-06: No per-card toggle button in this phase.

**Metadata Parity (CARD-03)**
- D-07: Representatives meta: name, position, district/ward, affordance icons. All current PoliticianCard affordances preserved.
- D-08: Elections meta: name, position running for, district/ward, affordance icons, "running unopposed" banner where applicable.
- D-09: Card supports a surface variant (`surface: 'representatives' | 'elections'`). Single component, not two.
- D-10: In portrait view, the radar slot is replaced by a large portrait at the same dimensions. Initials circle fallback when no photo.

**Styling & Theming**
- D-11: Sources colors/spacing/radii/shadows from `ev-ui/src/tokens.js` and `tailwind-preset.js`. No inlined constants copied from variant C.
- D-12: Antipartisan — no party labels or partisan color treatments anywhere on the card.

**Harness**
- D-13: Prototype harness remains at `essentials/src/pages/Prototype.jsx`. No new ev-ui demo page. Harness retires in Phase 129.

### Claude's Discretion

- Internal file layout within `ev-ui/src/` (single file vs split helpers for `PlaceholderRadar`, meta renderer)
- Exact prop name for the surface distinction (D-09) — UI-SPEC has settled on `surface`
- Whether the localStorage key is defined in ev-ui or essentials (ev-ui ideally stays stateless — key lives in essentials)
- Tests: snapshot vs DOM assertions, which lib — pick what matches existing ev-ui conventions (see Testing Conventions below)
- Handling of missing `userAnswers`/`tierVisuals` — render gracefully without throwing

### Deferred Ideas (OUT OF SCOPE)

- **Empty/non-compass variants** — placeholder radar when <3 answers, administrative, judicial layouts → Phase 128 (STATE-01, STATE-02, STATE-03)
- **Essentials adoption + `/prototype` retirement** → Phase 129 (ADOPT-01..04)
- **ev-ui standalone demo page** (rejected at D-13)
- **Per-card inline view toggle** (rejected at D-06)
- **Stance summary snippet in portrait view** (rejected at D-10)

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CARD-01 | Publish `CompassCardHorizontal` in ev-ui based on variant C, with props for politician/userAnswers/tierVisuals | Port Strategy §; Port Source variant C already implements horizontal=true + 250px radar |
| CARD-02 | Dual-view toggle between compass and portrait views, parent-controlled | Controlled-view pattern §; `view` prop mirrors parent-state convention used across ev-ui (no card owns page state) |
| CARD-03 | Preserve all existing PoliticianCard affordances — tier/branch, elected/appointed, unopposed, term dates, subtitle, initials fallback | Affordance Parity Checklist § — cross-referenced with `ev-ui/src/PoliticianCard.jsx` and `essentials/src/components/IconOverlay.jsx` |

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Card presentational rendering | ev-ui (component library) | — | ev-ui is the shared surface consumed by essentials/CompassV2; components are presentational by convention |
| Radar chart rendering | ev-ui (`RadarChartCore`) | — | Already published and stable; used directly per D-02 |
| View toggle state (`view` prop value) | essentials page (parent) | — | Page owns view mode per D-03/D-04; card is controlled |
| localStorage persistence of view | essentials | — | ev-ui stays stateless (D-11 spirit); persistence is an app concern |
| Compass topic/answer data fetching | essentials (`CompassContext`) | — | Card receives raw `userAnswers`; no network calls from ev-ui |
| Mock stance/test data | essentials (`data/mockCompassData`) | — | Harness concern — does not leak into ev-ui |
| Publish/distribution | ev-ui GitHub Actions → npm | consumer auto-bump PRs | Existing OIDC + app-token pipeline — no new work |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React | >=17 (peer) | Component framework | ev-ui peer dep — all consumers on React 19 |
| @react-spring/web | >=9 (peer) | Animation for RadarChartCore | Already used by `RadarChartCore.jsx` |
| tsup | ^8.0.0 | Build (ESM + CJS) | Existing ev-ui build tool; produces `dist/index.js` + `dist/index.mjs` |

### Supporting (already in ev-ui / essentials)
| Library | Purpose | When to Use |
|---------|---------|-------------|
| `@empoweredvote/ev-ui` tokens export | Colors, spacing, radii, shadows, focus, duration | All style values — no inlined hex/pixel constants |
| `@floating-ui/react` | Tooltip primitives used by `IconOverlay` | If affordance icons need tooltips in ev-ui surface, decide: (a) port `IconOverlay` into ev-ui (adds `@floating-ui/react` to ev-ui peers) or (b) keep icon-tooltip rendering in essentials and accept a simpler icon strip in ev-ui |

### Key decision: tooltip strategy for icon strip

Variant C in essentials composes `IconOverlay` (which uses `@floating-ui/react`). ev-ui does NOT currently depend on `@floating-ui/react`. Two viable paths:

| Path | Pros | Cons |
|------|------|------|
| A. Port `IconOverlay` into ev-ui, add `@floating-ui/react` as a peer/direct dep | Single-component API parity; essentials simplifies | Adds a new dep to ev-ui; tooltip styling becomes an ev-ui concern |
| B. Render only the icon row in ev-ui (no tooltips); consumer wraps in tooltip if needed | Keeps ev-ui dep surface small | Affordance parity (tooltips were part of the existing UX) regresses in the ev-ui surface until Phase 129 |

**Recommendation:** Path A. The UI-SPEC explicitly lists tooltip copy as part of the affordance parity checklist (CARD-03). Port `IconOverlay` into ev-ui alongside the card, add `@floating-ui/react` to ev-ui `peerDependencies`. essentials already resolves it. [VERIFIED: essentials/src/components/IconOverlay.jsx imports `BallotIcon, CompassIcon, BranchIcon` from `@empoweredvote/ev-ui` — icons are already ev-ui exports.]

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `@floating-ui/react` for tooltips | CSS-only tooltip, Radix Popover | Floating-UI already used in essentials and handles portal/flip/shift correctly; CSS-only fails with icon strips near card edges |
| Splitting into two components (`CompassCardHorizontalRepresentatives`, `...Elections`) | Single component with `surface` prop | Specifics §: "prefer a single prop over forking into two components, to keep API surface small" — locked |

**Installation (inside ev-ui):**
```bash
cd ev-ui
npm install @floating-ui/react
# Move to peerDependencies in package.json after install
```

**Version verification (2026-04-19):**
- `react` pinned as peer `>=17`; all consumers run 19.x. No change needed.
- `@react-spring/web` peer `>=9`. Already satisfied.
- `@floating-ui/react` — verify latest via `npm view @floating-ui/react version` before adding. [ASSUMED: latest is in the 0.26.x+ range — planner should confirm at task time.]

## Architecture Patterns

### System Architecture Diagram

```
┌────────────────────────── essentials (consumer app) ───────────────────────────┐
│                                                                                 │
│   Prototype.jsx  ──►  SegmentedControl ─── (view: 'compass'|'portrait') ──┐    │
│         │                                                                  │    │
│         ├──► useCompass() ──► userAnswers (raw)  ──────────────────────┐  │    │
│         │                                                               │  │    │
│         ├──► usePoliticianData() ──► politicians[]  ───────────────┐   │  │    │
│         │                                                           ▼   ▼  ▼    │
│         └──► localStorage('ev:compass-card-view')  ──► view ──►  <CompassCardHorizontal
│                                                                     politician    
│                                                                     userAnswers   
│                                                                     tierVisuals   
│                                                                     view          
│                                                                     surface />    
└──────────────────────────────────────────┬──────────────────────────────────────┘
                                           │ imported from
                                           ▼
┌──────────────────────── @empoweredvote/ev-ui ──────────────────────────────────┐
│                                                                                 │
│   CompassCardHorizontal.jsx                                                     │
│         │                                                                       │
│         ├── view='compass' ──► RadarChartCore   OR   PlaceholderRadar          │
│         │                     (when userAnswers    (when userAnswers null/     │
│         │                      present)             empty — Phase 128 handles  │
│         │                                           <3 answers)                 │
│         │                                                                       │
│         ├── view='portrait' ──► <img> OR initials circle                        │
│         │                                                                       │
│         └── meta column ──► CompassCardHorizontalMeta                          │
│                              ├── surface='representatives': name, title,        │
│                              │   district, icon strip                           │
│                              └── surface='elections': name, office_running_for, │
│                                  district, icon strip, "unopposed" banner       │
│                                                                                 │
│   Styles from: tokens.js (colors, spacing, borderRadius, shadows, focus, …)    │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Recommended Project Structure (ev-ui/src/)
```
ev-ui/src/
├── CompassCardHorizontal.jsx        # main export — card shell + radar/portrait slot logic
├── CompassCardHorizontalMeta.jsx    # meta column renderer (surface switch)
├── PlaceholderRadar.jsx             # dashed octagon SVG (port from CompassFirstCard)
├── IconOverlay.jsx                  # port from essentials — affordance icon row with tooltips
└── index.js                         # add: export { default as CompassCardHorizontal }
                                     #      export { default as IconOverlay } (optional)
```

### Pattern 1: Controlled view prop (no internal state)
**What:** Card receives `view` from parent. No `useState` for view mode inside the card.
**When to use:** Any time page-level state needs to drive multiple cards uniformly (D-04).
**Example:**
```jsx
// Parent (essentials/src/pages/Prototype.jsx)
const [view, setView] = useLocalStorage('ev:compass-card-view', 'compass');
return (
  <>
    <SegmentedControl
      options={[{value:'compass',label:'Compass'},{value:'portrait',label:'Portrait'}]}
      value={view}
      onChange={setView}
    />
    {politicians.map(p => (
      <CompassCardHorizontal key={p.id} politician={p} userAnswers={userAnswers} view={view} surface="representatives" />
    ))}
  </>
);
```

### Pattern 2: Token-only styling
**What:** Every color/spacing/radius/shadow imported from `./tokens.js`. No hex strings or pixel values in JSX.
**When to use:** Always (D-11).
**Example:**
```jsx
import { colors, spacing, borderRadius, shadows, focus, duration } from './tokens';

const cardStyle = {
  backgroundColor: colors.bgWhite,       // not '#FFFFFF'
  borderRadius: borderRadius.xl,          // not '12px'
  padding: spacing[4],                    // not '16px'
  boxShadow: hovered ? shadows.cardHover : shadows.md,
  transition: `box-shadow ${duration.normal} ease`,
  // ...
};
```

### Pattern 3: Surface-prop branching (D-09)
**What:** One component, one switch on `surface`, two content sets. Shared chrome (card shell, radar slot, hover/focus) lives outside the switch.
```jsx
// CompassCardHorizontalMeta.jsx
export default function CompassCardHorizontalMeta({ politician, surface }) {
  return (
    <div style={metaStyle}>
      <Name>{politician.full_name}</Name>
      <Title>{surface === 'elections' ? politician.office_running_for : politician.office_title}</Title>
      <Subtitle>{politician.district_label}</Subtitle>
      <IconOverlay ballot={politician.ballot} hasStances={politician.hasStances} branch={politician.branch} />
      {surface === 'elections' && politician.running_unopposed && <UnopposedBanner />}
    </div>
  );
}
```

### Anti-Patterns to Avoid
- **Inlining hex/pixel constants copied from variant C** — violates D-11. Port the *structure* of variant C, rewire all values through tokens.
- **Letting the card own `view` state** — violates D-03. Breaks the page-level toggle contract.
- **Forking into two components for representatives vs elections** — violates D-09 and the "small API surface" discretion note.
- **Shipping `PlaceholderRadar` behavior that branches on answer count (<3)** — that's STATE-01, Phase 128. In Phase 127, `PlaceholderRadar` is rendered only when `userAnswers` is null/empty (mirrors variant C behavior).
- **Adding a per-card toggle button** — violates D-06.
- **Coupling ev-ui to `localStorage`** — violates the "ev-ui stays stateless" discretion guidance. Persistence lives in the consumer.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Radar chart | Custom SVG radar | `RadarChartCore` (already exported from ev-ui) | Stable, animated via `@react-spring/web`, handles label wrapping + inversion |
| Tooltip positioning | Custom CSS hover tooltip | `@floating-ui/react` via ported `IconOverlay` | Correct portal/flip/shift; existing proven pattern |
| Design tokens | Hard-coded hex/px | `tokens.js` imports | Single source of truth; enforces WCAG AA and antipartisan constraints |
| Image fallback to initials | Inline img/error handling | `PoliticianCard`-style `useState`/`useEffect` on `imgError` | Existing pattern proven; copy verbatim |
| npm publish + consumer bump | Manual publish steps | `npm version patch && git push --follow-tags` (OIDC publish + auto-bump already configured) | Zero new infrastructure; see README-AUTOBUMP.md |

**Key insight:** Every "hard" problem on this phase already has an in-repo solution — ev-ui is a mature library surface, and variant C is a proven reference impl. Hand-rolling anything here is a smell.

## Port Strategy (load-bearing for planner)

### What to lift from `essentials/src/components/CompassFirstCard.jsx` variant C

**Keep:**
- Overall flex row layout (`flexDirection: 'row'`, `alignItems: 'center'`, `gap: 16`)
- Radar wrapper sizing logic (`radarSize + 10` for label bleed, `flexShrink: 0`, `overflow: 'hidden'`)
- `RadarChartCore` invocation with `padding=20, labelOffset=5, labelFontSize=12, size=250`
- `PlaceholderRadar` SVG (dashed octagon) — moves into its own file in ev-ui
- Hover/focus/keyboard event handlers (`handleClick`, `handleKeyDown`, `onMouseEnter/Leave`, `onFocus/Blur`)
- `role="article"`, `aria-label`, `tabIndex={0}`

**Strip:**
- `VARIANT_CONFIG` object entirely — variants A and B are not in scope; horizontal=true is implicit in `CompassCardHorizontal`
- `variant` prop
- `useNavigate()` / `useCompass()` hooks — ev-ui is router-agnostic and context-agnostic; navigation becomes `onClick` prop, compass data comes in as `userAnswers` prop
- All inlined hex/pixel constants — replace with token references per D-11
- `MOCK_USER_COMPASS` / `MOCK_TOPICS` fallbacks — ev-ui receives real data from consumers
- Internal `buildAnswerMapByShortTitle` call — either (a) port this helper into ev-ui as an internal utility, or (b) accept pre-shaped answers and let the consumer transform. **Recommendation: port the helper** to keep the card's prop API faithful to variant C (`userAnswers` as an array, not a pre-shaped map).

**Add:**
- `view` prop handling (compass vs portrait) — new in Phase 127
- Portrait rendering at 260px — mirror the radar wrapper dimensions; use `PoliticianCard`'s image fallback pattern (img with `onError` → initials circle with `colors.evMutedBlue` bg)
- `surface` prop handling — delegate content choice to `CompassCardHorizontalMeta`
- "Running unopposed" banner (elections surface only) — new UI per D-08
- Props-driven icon visibility — mirror existing `IconOverlay` logic but receive all data via `politician` shape

### Dependency: `buildAnswerMapByShortTitle`

Located at `essentials/src/lib/compass.js` (inferred from import in CompassFirstCard.jsx). Planner must verify this exists and decide: port it into ev-ui, or make the card accept pre-shaped answers. **Path of least surprise:** port the helper into ev-ui as a private util (not exported), keeping the public API simple (`userAnswers` array passed in).

## Runtime State Inventory

Not applicable — this is a greenfield component addition, not a rename/refactor. No stored data, service config, OS registrations, secrets, or build artifacts are affected.

## Common Pitfalls

### Pitfall 1: RadarChartCore label bleed breaking layout
**What goes wrong:** `RadarChartCore`'s SVG viewBox extends beyond `size` to accommodate labels. If the radar wrapper isn't width-constrained, the meta column gets squeezed.
**Why it happens:** `RadarChartCore` uses symmetric padding up to `padding * 2` (line 117) based on label widths.
**How to avoid:** Variant C's proven solution — wrap the radar in `<div style={{ width: radarSize + 10, overflow: 'hidden', flexShrink: 0 }}>`. Port this verbatim.
**Warning signs:** Meta column collapses to 0 width on narrow viewports; horizontal scroll appears within card.

### Pitfall 2: Portrait view dimension mismatch breaks grid uniformity
**What goes wrong:** Portrait renders at natural image dimensions instead of 260px, causing grid rows to go ragged.
**Why it happens:** `<img>` without explicit width/aspect-ratio respects intrinsic dimensions.
**How to avoid:** Wrap portrait in the same `{ width: 260, overflow: 'hidden', flexShrink: 0 }` box used for the radar. Apply `objectFit: 'cover'`, `objectPosition: imageFocalPoint ?? 'center 20%'` on the img. (Pattern already in `ev-ui/src/PoliticianCard.jsx`.)
**Warning signs:** Cards of different heights in the same grid row.

### Pitfall 3: Adding `@floating-ui/react` to ev-ui without peer declaration
**What goes wrong:** Consumers double-install `@floating-ui/react` (one via direct dep, one via ev-ui), risking duplicate React context and broken portals.
**Why it happens:** If added only as a `dependency`, npm installs a second copy.
**How to avoid:** Add `@floating-ui/react` to `peerDependencies` in `ev-ui/package.json`. Also add to `devDependencies` for local builds. Verify essentials, CompassV2, read-rank already have it (essentials does — `IconOverlay.jsx` imports from it).
**Warning signs:** Tooltips not rendering, React "invalid hook call" warnings in consumer.

### Pitfall 4: `view` prop becomes uncontrolled if parent forgets to pass it
**What goes wrong:** Consumer omits `view`, card renders `undefined` branch, placeholder shows instead of radar.
**Why it happens:** D-03 says card is controlled — no default.
**How to avoid:** Either (a) default `view='compass'` in prop signature so omission has safe behavior, or (b) throw a dev-mode `console.warn` if `view` is missing. **Recommendation: default to `'compass'`** — matches legacy variant C (which only had radar view). Consumers who want portrait opt in.
**Warning signs:** Cards showing the placeholder radar in the harness when they should show live radar.

### Pitfall 5: ev-ui publish fires consumer auto-bump PRs on trivial commits
**What goes wrong:** Every `npm version patch` push dispatches `ev-ui-published` to 4 consumer repos. A WIP version bump creates 4 PRs.
**Why it happens:** Publish is tag-driven; any pushed tag fires the pipeline.
**How to avoid:** Don't bump the version until the phase is gate-reviewed and ready to ship. Do not run `npm version patch` during task execution — that's a Phase 129 (ADOPT-04) concern.
**Warning signs:** Unexpected PRs opened on CompassV2/essentials/read-rank/civic-spaces.

## Code Examples

### Card shell skeleton (token-driven)
```jsx
// ev-ui/src/CompassCardHorizontal.jsx
// Source: port of essentials/src/components/CompassFirstCard.jsx variant C
import { useState, useEffect } from 'react';
import { colors, spacing, borderRadius, shadows, focus, duration, fonts } from './tokens';
import RadarChartCore from './RadarChartCore.jsx';
import PlaceholderRadar from './PlaceholderRadar.jsx';
import CompassCardHorizontalMeta from './CompassCardHorizontalMeta.jsx';

const RADAR_SIZE = 250;
const SLOT_WIDTH = RADAR_SIZE + 10;

export default function CompassCardHorizontal({
  politician,
  userAnswers,
  tierVisuals,
  view = 'compass',
  surface = 'representatives',
  onClick,
}) {
  const [hovered, setHovered] = useState(false);
  const [focused, setFocused] = useState(false);
  const [imgError, setImgError] = useState(false);
  useEffect(() => { setImgError(false); }, [politician?.photo_origin_url]);

  const cardStyle = {
    display: 'flex',
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[4],
    backgroundColor: tierVisuals?.bg ?? colors.bgWhite,
    border: `1px solid ${colors.borderLight}`,
    borderRadius: borderRadius.xl,
    padding: spacing[4],
    boxShadow: focused ? focus.ring : hovered ? shadows.cardHover : shadows.md,
    transform: hovered ? 'translateY(-2px)' : 'none',
    transition: `box-shadow ${duration.normal} ease, transform ${duration.normal} ease`,
    cursor: onClick ? 'pointer' : 'default',
    fontFamily: fonts.primary,
    outline: 'none',
    minHeight: '44px',
  };

  const slotStyle = { width: SLOT_WIDTH, flexShrink: 0, overflow: 'hidden' };

  return (
    <div
      role="article"
      aria-label={`${politician.full_name}, ${politician.office_title || ''}`}
      tabIndex={0}
      style={cardStyle}
      onClick={onClick}
      onKeyDown={(e) => {
        if (onClick && (e.key === 'Enter' || e.key === ' ')) { e.preventDefault(); onClick(); }
      }}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      onFocus={() => setFocused(true)}
      onBlur={() => setFocused(false)}
    >
      <div style={slotStyle}>
        {view === 'portrait'
          ? renderPortrait(politician, imgError, setImgError)
          : renderCompass(politician, userAnswers)}
      </div>
      <CompassCardHorizontalMeta politician={politician} surface={surface} />
    </div>
  );
}
```

### PlaceholderRadar (verbatim port, token-wired)
```jsx
// ev-ui/src/PlaceholderRadar.jsx
// Source: essentials/src/components/CompassFirstCard.jsx lines 56-83
import { colorScales, borderRadius } from './tokens';

export default function PlaceholderRadar({ size = 250, name = '' }) {
  const cx = size / 2, cy = size / 2, r = (size / 2) * 0.65, n = 8;
  const pts = Array.from({ length: n }, (_, i) => {
    const a = (2 * Math.PI * i) / n;
    return `${cx + r * Math.sin(a)},${cy - r * Math.cos(a)}`;
  }).join(' ');
  return (
    <svg
      width={size}
      height={size}
      viewBox={`0 0 ${size} ${size}`}
      role="img"
      aria-label={name ? `${name} — compass data unavailable` : 'compass data unavailable'}
      style={{ backgroundColor: colorScales.teal['050'], borderRadius: borderRadius.sm, flexShrink: 0 }}
    >
      <polygon points={pts} fill="none" stroke={colorScales.gray['200']} strokeWidth="1.5" strokeDasharray="4 3" />
    </svg>
  );
}
```

### Export barrel update
```js
// ev-ui/src/index.js — add:
export { default as CompassCardHorizontal } from './CompassCardHorizontal.jsx';
export { default as IconOverlay } from './IconOverlay.jsx'; // if ported
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Vertical card with photo-first layout (`ev-ui/src/PoliticianCard.jsx`) | Horizontal compass-first card anchored by radar | Milestone v2026.4.5 | Compass becomes primary visual; photo relegated to portrait toggle |
| Per-app card implementation duplication (essentials has its own PoliticianCard) | Shared ev-ui export adopted by all apps | Phase 129 (ADOPT-01..04) | Phase 127 only *publishes* the component — adoption is deferred |
| Manual ev-ui publish via `NPM_TOKEN` | OIDC trusted publishing + provenance attestations | Prior work (documented in README-AUTOBUMP.md) | Planner does not need to manage npm tokens |

**Deprecated/outdated:**
- `VARIANT_CONFIG` (A/B/C) in `CompassFirstCard.jsx` — only C survives, as `CompassCardHorizontal`. A and B are not being ported.
- `/prototype` route — still active in Phase 127 as the harness, retires in Phase 129.

## Testing Conventions

**Current state of ev-ui tests:** None. `npm test` does not exist in `ev-ui/package.json`; no `*.test.*` or `*.spec.*` files under `ev-ui/`. [VERIFIED: `cat ev-ui/package.json` + `Glob ev-ui/**/*.test.*`]

**Implications for Phase 127:**
- Adding a test framework is out of scope; the planner should not block the phase on framework setup.
- Validation is anchored on: (1) the harness at `essentials/src/pages/Prototype.jsx` exercising all prop shapes, (2) `tsup` build succeeds, (3) consumer smoke: `cd essentials && npm run build` resolves `CompassCardHorizontal` from the published/linked ev-ui without errors.

**If the planner decides to add a lightweight test:** Vitest is the least-friction fit — it aligns with ev-accounts (`npm test → vitest`) and essentials' Vite tooling. But this is a Claude's-discretion item; explicitly recommended to defer unless the team wants to establish the pattern in this phase.

## Release Pipeline Notes (planner-relevant)

1. **Do not bump ev-ui version during Phase 127 task execution.** Version bump + tag push fires auto-bump PRs across 4 consumer repos (README-AUTOBUMP.md §Release workflow). Phase 127's goal is "component available in ev-ui" — shipping to consumers is Phase 129 (ADOPT-04).
2. **Local consumption during development:** Use `npm link` or a relative file dep in `essentials/package.json` to test the harness against unpublished ev-ui changes.
3. **When it's time to publish (end of Phase 127 or start of Phase 129 — planner's call):**
   ```bash
   cd ev-ui
   npm version patch   # 0.4.4 → 0.4.5
   git push origin main --follow-tags
   ```
   Everything else is automated (OIDC publish → `repository_dispatch` → consumer PRs → auto-merge on patch/minor → Render deploys).
4. **Peer dep addition (`@floating-ui/react`) is a minor bump, not patch.** If added, use `npm version minor`.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `buildAnswerMapByShortTitle` lives at `essentials/src/lib/compass.js` (inferred from import path in CompassFirstCard.jsx) — planner should verify at task time | Port Strategy | Low — worst case the helper is in a sibling path and the planner adjusts the import target |
| A2 | Latest `@floating-ui/react` is in the 0.26.x+ range | Standard Stack | Low — planner runs `npm view @floating-ui/react version` before adding |
| A3 | All current ev-ui consumers (CompassV2, essentials, read-rank, civic-spaces) will transpile/bundle the new ESM export without config changes | Architecture Patterns | Low — existing `PoliticianCard` export uses the same `tsup` → `dist/index.mjs` path |
| A4 | Tooltip port (Path A) is the preferred direction over stripping tooltips from the ev-ui surface | Standard Stack | Medium — if the team prefers to keep ev-ui's dep footprint minimal, Path B is viable and Phase 129 re-wires tooltips in consumers |

## Open Questions

1. **Should the localStorage key live in ev-ui or essentials?**
   - What we know: CONTEXT §Claude's Discretion says "likely essentials; ev-ui ideally stays stateless"; D-11 reinforces ev-ui as presentational.
   - What's unclear: Whether a small `useLocalStorageState` hook belongs in ev-ui for reuse.
   - Recommendation: Keep persistence in essentials. If the pattern repeats in Phase 129, extract then.

2. **Should `buildAnswerMapByShortTitle` be exported from ev-ui or kept private?**
   - What we know: It's currently an essentials internal. The card needs its behavior.
   - What's unclear: Whether other ev-ui consumers will need the same transform.
   - Recommendation: Port as private (not exported). Re-export later if a second caller emerges.

3. **Does Phase 127 need to handle `userAnswers=null` differently from `userAnswers=[]`?**
   - What we know: Variant C falls back to `PlaceholderRadar` when `!mockAnswers`. STATE-01 (Phase 128) adds a richer "<3 answers" placeholder.
   - What's unclear: The exact threshold for "show placeholder vs show real radar with partial data".
   - Recommendation: Port variant C behavior verbatim — PlaceholderRadar when `!userAnswers || userAnswers.length === 0`. Phase 128 refines.

## Environment Availability

Not applicable — this phase is pure JavaScript/React component work against an already-installed toolchain (node, npm, tsup, Vite). No new external runtimes, databases, or services.

## Validation Architecture

> workflow.nyquist_validation not explicitly disabled — section included.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | **None currently in ev-ui.** essentials uses Vite; essentials-level smoke build is the default validation. |
| Config file | none (ev-ui); `vite.config.*` in essentials |
| Quick run command | `cd ev-ui && npm run build` — verifies tsup build succeeds and exports resolve |
| Full suite command | `cd ev-ui && npm run build && cd ../essentials && npm run build` — verifies consumer build-through |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CARD-01 | `CompassCardHorizontal` exported from `@empoweredvote/ev-ui`; renders radar-left / meta-right layout matching variant C | build + visual | `cd ev-ui && npm run build` (export resolves) + Prototype harness visual QA at `http://localhost:5173/prototype` | Build exists. Harness exists. |
| CARD-01 | Component accepts `politician`, `userAnswers`, `tierVisuals` props without throwing on partial data | smoke (manual in harness) | Harness renders cards with/without `userAnswers` and with missing `tierVisuals` | Harness must be updated — Wave 0 gap |
| CARD-02 | View toggle flips all cards between compass and portrait; preference persists in localStorage across reload | manual visual + DOM-inspect | Harness: click SegmentedControl, reload page, confirm view persists | SegmentedControl exists; `view` wiring + localStorage wiring = Wave 0 gap |
| CARD-03 | All existing PoliticianCard affordances present — BallotIcon, CompassIcon, BranchIcon, initials fallback, district subtitle, "running unopposed" (elections) | manual visual checklist against `ev-ui/src/PoliticianCard.jsx` + `IconOverlay` | Harness renders one card per affordance state; checker walks the Affordance Parity Checklist table | Harness coverage = Wave 0 gap |
| CARD-03 | Portrait view renders at same 260px dimensions as radar (grid uniformity) | manual visual | Toggle view in harness, confirm grid rows stay uniform | — |
| CARD-03 | Antipartisan — no party labels or colors anywhere on the card | code inspection + visual | Grep new files for 'Democrat', 'Republican', 'party', '#DC' (red), '#007' (blue) — confirm none present as data-driven content | — |

### Sampling Rate
- **Per task commit:** `cd ev-ui && npm run build` (< 10 sec — verifies TypeScript, tsup output, no broken imports)
- **Per wave merge:** Full build-through — `cd ev-ui && npm run build && cd ../essentials && npm run build`, then `cd essentials && npm run dev` and visually verify `/prototype` harness renders all three prop shapes
- **Phase gate:** All 6 UI-SPEC dimensions signed off by checker; harness walkthrough recorded/screenshotted; `cd essentials && npm run build` passes with ev-ui linked locally

### Wave 0 Gaps

- [ ] `essentials/src/pages/Prototype.jsx` — update to:
  - Import `CompassCardHorizontal` from `@empoweredvote/ev-ui` (linked locally) instead of `CompassFirstCard`
  - Add a page-level `SegmentedControl` for view mode (`compass` | `portrait`) with localStorage persistence under `ev:compass-card-view`
  - Render at least one card with `surface='elections'` (per UI-SPEC Harness Reference)
  - Remove/retain the A/B/C variant toggle (retain for now — it lets us visually compare the ported version against the legacy variant during migration)
- [ ] ev-ui test infrastructure — **do not add in Phase 127**. Accept that validation is harness + consumer-build based. Record this decision explicitly in the plan so the checker doesn't flag it.

*If no gaps: N/A — two concrete gaps listed above.*

## Project Constraints (from CLAUDE.md)

| Directive | Section | How Phase 127 Complies |
|-----------|---------|------------------------|
| Use Manrope font across all React projects | §Design System | `fonts.primary` token used for all text |
| EV palette: ev-coral / ev-muted-blue / ev-light-blue / ev-yellow | §Design System | Only `ev-muted-blue` (`#00657C`) used as card accent; UI-SPEC explicitly excludes coral/yellow |
| Never show party or use partisan color associations | §Antipartisan Principle (via user memory) | D-12; no party data touched, no red/blue partisan semantics |
| ev-ui publishing via `npm version patch && git push --follow-tags` | §ev-ui Component Library | Release deferred to Phase 129; mechanical command documented |
| All frontends on Render, auto-deploy on merge to main | §Infrastructure | N/A for Phase 127 (no consumer deployment in this phase) |

## Sources

### Primary (HIGH confidence)
- `essentials/src/components/CompassFirstCard.jsx` — port source (read in full)
- `ev-ui/src/index.js`, `ev-ui/src/PoliticianCard.jsx`, `ev-ui/src/tokens.js`, `ev-ui/src/tailwind-preset.js`, `ev-ui/src/RadarChartCore.jsx` — target library surface (read in full)
- `ev-ui/README-AUTOBUMP.md` — publish pipeline (read in full)
- `ev-ui/package.json` — peer deps, scripts, exports (read in full)
- `essentials/src/components/IconOverlay.jsx` — affordance icon pattern (read in full)
- `essentials/src/pages/Prototype.jsx` — harness (read in full)
- `.planning/phases/127-compass-card-horizontal-ev-ui/127-CONTEXT.md` — locked decisions (read in full)
- `.planning/phases/127-compass-card-horizontal-ev-ui/127-UI-SPEC.md` — UI contract (read in full)
- `.planning/REQUIREMENTS.md` — CARD-01..03 (read in full)
- `.planning/ROADMAP.md` — phase goal + success criteria (read in full)
- `/Users/chrisandrews/Documents/GitHub/CLAUDE.md` — project constraints (read in full)

### Secondary (MEDIUM confidence)
- Location of `buildAnswerMapByShortTitle` — inferred from import path in CompassFirstCard.jsx; planner to verify

### Tertiary (LOW confidence)
- None. All critical claims verified against in-repo files.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — ev-ui package.json + existing imports directly verified
- Architecture: HIGH — variant C + existing ev-ui components read in full
- Pitfalls: HIGH — drawn from actual code (RadarChartCore padding math, PoliticianCard img error handling, README-AUTOBUMP.md release flow)
- Testing convention: HIGH — absence of test files confirmed via Glob

**Research date:** 2026-04-19
**Valid until:** 2026-05-19 (stable component library, stable publishing pipeline)

## RESEARCH COMPLETE

**Phase:** 127 - CompassCardHorizontal in ev-ui
**Confidence:** HIGH

### Key Findings
- Variant C in `essentials/src/components/CompassFirstCard.jsx` is a near-complete reference implementation; Phase 127 is a mechanical port + token rewire, not a design exercise.
- ev-ui has a stable OIDC-based publishing pipeline with consumer auto-bump — planner must **not** bump version during Phase 127 execution (bump belongs in Phase 129).
- ev-ui has **zero test infrastructure today**; validation is anchored on `tsup` build + `essentials/prototype` harness + consumer build-through.
- `@floating-ui/react` must be added to ev-ui `peerDependencies` if `IconOverlay` is ported (recommended Path A for CARD-03 tooltip parity).
- Three new files recommended: `CompassCardHorizontal.jsx`, `CompassCardHorizontalMeta.jsx`, `PlaceholderRadar.jsx`, plus (optionally) `IconOverlay.jsx` ported from essentials.

### File Created
`/Users/chrisandrews/Documents/GitHub/.planning/phases/127-compass-card-horizontal-ev-ui/127-RESEARCH.md`

### Confidence Assessment
| Area | Level | Reason |
|------|-------|--------|
| Standard Stack | HIGH | package.json + imports directly verified |
| Architecture | HIGH | Full variant C read; ev-ui surface fully mapped |
| Pitfalls | HIGH | Drawn from real code (RadarChartCore padding, publish pipeline) |
| Testing | HIGH | Absence of test infra confirmed by Glob |

### Open Questions
- Exact filesystem location of `buildAnswerMapByShortTitle` (inferred `essentials/src/lib/compass.js`) — planner verifies at task time.
- Whether to add a minimal Vitest setup to ev-ui in this phase (Claude's discretion — recommended: defer).
- Tooltip port strategy: Path A (port `IconOverlay` into ev-ui, add `@floating-ui/react` peer dep) vs Path B (ev-ui ships icons without tooltips). Recommended Path A for CARD-03 parity.

### Ready for Planning
Research complete. Planner can now create PLAN.md files decomposing this phase into tasks: (1) scaffold new ev-ui files + tokens wiring, (2) port PlaceholderRadar + IconOverlay + meta, (3) wire surface/view props, (4) update essentials harness, (5) smoke-build verification.
