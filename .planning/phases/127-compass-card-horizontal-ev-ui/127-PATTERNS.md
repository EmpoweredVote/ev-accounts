# Phase 127: CompassCardHorizontal in ev-ui - Pattern Map

**Mapped:** 2026-04-19
**Files analyzed:** 6 (4 new, 2 modified)
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `ev-ui/src/CompassCardHorizontal.jsx` (new) | component (presentational card) | props-in / event-out (controlled view) | `essentials/src/components/CompassFirstCard.jsx` (variant C branch) | exact (port source) |
| `ev-ui/src/CompassCardHorizontalMeta.jsx` (new) | component (sub-renderer) | props-in / render-out | `ev-ui/src/PoliticianCard.jsx` (content block, lines 270-282) | role-match |
| `ev-ui/src/PlaceholderRadar.jsx` (new) | component (pure SVG) | props-in / static render | `essentials/src/components/CompassFirstCard.jsx` (inline `PlaceholderRadar`, lines 56-83) | exact (verbatim port) |
| `ev-ui/src/IconOverlay.jsx` (new) | component (affordance row + tooltips) | props-in / render-out | `essentials/src/components/IconOverlay.jsx` | exact (verbatim port) |
| `ev-ui/src/index.js` (modified) | barrel export | static re-export | existing entries in `ev-ui/src/index.js` | exact |
| `essentials/src/pages/Prototype.jsx` (modified) | page (harness) | context + state → card grid | `essentials/src/pages/Prototype.jsx` (self, pre-port) | self-evolve |

## Pattern Assignments

### `ev-ui/src/CompassCardHorizontal.jsx` (component, props-in/event-out)

**Primary analog:** `essentials/src/components/CompassFirstCard.jsx` (variant C path only — strip A/B/`VARIANT_CONFIG`)
**Secondary analog:** `ev-ui/src/PoliticianCard.jsx` (for imgError/initials fallback, token imports)

**Imports pattern** — use `PoliticianCard.jsx` lines 1-2 shape (token-only, no hex/px):
```jsx
import React, { useState, useEffect } from 'react';
import { colors, fonts, fontWeights, fontSizes, spacing, borderRadius, shadows } from './tokens';
import RadarChartCore from './RadarChartCore.jsx';
import PlaceholderRadar from './PlaceholderRadar.jsx';
import IconOverlay from './IconOverlay.jsx';
import CompassCardHorizontalMeta from './CompassCardHorizontalMeta.jsx';
```
Strip all of `CompassFirstCard.jsx` lines 2-7 (`useNavigate`, `useCompass`, `buildAnswerMapByShortTitle`, mocks, `IconOverlay` relative import) — ev-ui must be router-agnostic and context-agnostic.

**Hover/focus/keyboard card shell** (port from `CompassFirstCard.jsx` lines 135-156, 247-259 — rewire constants through tokens):
```jsx
const cardStyle = {
  position: 'relative',
  backgroundColor: tierVisuals?.bg ?? colors.bgWhite,
  border: `1px solid ${colors.borderLight}`,
  borderRadius: borderRadius.xl,         // was '12px'
  padding: spacing[4],                    // was '16px'
  boxShadow: focused ? focus.ring : hovered ? shadows.cardHover : shadows.md,
  transition: `box-shadow ${duration.normal} ease, transform ${duration.normal} ease`,
  transform: hovered ? 'translateY(-2px)' : 'none',
  display: 'flex', flexDirection: 'row', alignItems: 'center',
  gap: spacing[4],
  minHeight: '44px',
  outline: 'none',
  cursor: onClick ? 'pointer' : 'default',
};
```
Keep `role="article"`, `aria-label`, `tabIndex={0}`, onMouseEnter/Leave/Focus/Blur, onKeyDown (Enter/Space → onClick) verbatim from `CompassFirstCard.jsx` lines 247-259.

**Radar slot (controlled `view` prop)** — replace `CompassFirstCard.jsx` lines 158-184 with:
```jsx
const RADAR_SIZE = 250;
const SLOT_WIDTH = RADAR_SIZE + 10;  // preserves label-bleed wrapper pattern
const slotStyle = { width: SLOT_WIDTH, flexShrink: 0, overflow: 'hidden' };

<div style={slotStyle}>
  {view === 'portrait'
    ? renderPortrait(politician, imgError, setImgError)
    : (userAnswers && userAnswers.length > 0
        ? <RadarChartCore topics={topicsFiltered} data={...} compareData={...}
            invertedSpokes={{}} onToggleInversion={() => {}} onReplaceTopic={() => {}}
            size={RADAR_SIZE} padding={20} labelOffset={5} labelFontSize={12} />
        : <PlaceholderRadar size={RADAR_SIZE} name={politician.full_name} />)}
</div>
```

**Portrait fallback — lift verbatim from `PoliticianCard.jsx` lines 215-225, 255-268:**
```jsx
const [imgError, setImgError] = useState(false);
useEffect(() => { setImgError(false); }, [politician?.photo_origin_url]);

const getInitials = (n) => {
  const parts = (n || '').split(' ').filter(Boolean);
  const initials = parts.length >= 2
    ? parts[0][0] + parts[parts.length - 1][0]
    : parts[0]?.[0] || '?';
  return initials.toUpperCase();
};

// In portrait slot:
{imageSrc && !imgError
  ? <img src={imageSrc} alt={`${politician.full_name} portrait`}
      style={{ width:'100%', height:'100%', objectFit:'cover',
               objectPosition: politician.imageFocalPoint ?? 'center 20%' }}
      onError={() => setImgError(true)} />
  : <div style={{ width:'100%', height:'100%',
      backgroundColor: colors.evMutedBlue, color:'#fff',
      display:'flex', alignItems:'center', justifyContent:'center',
      fontFamily: fonts.primary, fontWeight: fontWeights.bold,
      borderRadius: 0 }}>{getInitials(politician.full_name)}</div>}
```

**Prop default for `view` (Pitfall 4 fix):** `view = 'compass'` in signature.

---

### `ev-ui/src/CompassCardHorizontalMeta.jsx` (component, props-in/render-out)

**Primary analog:** `ev-ui/src/PoliticianCard.jsx` lines 270-282 (content column), + `CompassFirstCard.jsx` lines 189-245 (meta block already in horizontal mode).

**Imports:**
```jsx
import { colors, fonts, fontWeights, fontSizes, spacing, borderRadius } from './tokens';
import IconOverlay from './IconOverlay.jsx';
```

**Core surface-switch pattern** (implements D-07/D-08/D-09):
```jsx
export default function CompassCardHorizontalMeta({ politician, surface = 'representatives', userAnswers }) {
  const titleText = surface === 'elections'
    ? politician.office_running_for
    : politician.office_title;

  return (
    <div style={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column', gap: spacing[1] }}>
      <p style={{ fontSize: fontSizes.lg, fontWeight: fontWeights.semibold,
                  lineHeight: 1.4, color: colors.evMutedBlue,
                  fontFamily: fonts.primary, margin: 0 }}>
        {politician.full_name}
      </p>
      <p style={{ fontSize: fontSizes.sm, fontWeight: fontWeights.semibold,
                  lineHeight: 1.4, color: colors.textSecondary,
                  fontFamily: fonts.primary, margin: 0,
                  overflow:'hidden', display:'-webkit-box',
                  WebkitLineClamp: 2, WebkitBoxOrient: 'vertical' }}>
        {titleText || ''}
      </p>
      {politician.district_label && (
        <p style={{ fontSize: fontSizes.sm, fontWeight: fontWeights.regular,
                    lineHeight: 1.5, color: colors.textMuted,
                    fontFamily: fonts.primary, margin: 0,
                    overflow:'hidden', textOverflow:'ellipsis', whiteSpace:'nowrap' }}>
          {politician.district_label}
        </p>
      )}
      <IconOverlay
        ballot={politician.ballot || null}
        hasStances={Boolean(userAnswers && userAnswers.length > 0) || Boolean(politician.hasStances)}
        branch={politician.branch || null}
      />
      {surface === 'elections' && politician.running_unopposed && (
        <div style={{ backgroundColor: colors.infoLight,
                      borderLeft: `3px solid ${colors.evMutedBlue}`,
                      borderRadius: borderRadius.md,
                      padding: `${spacing[1]} ${spacing[2]}`,
                      fontSize: fontSizes.xs, fontWeight: fontWeights.regular,
                      color: colors.evMutedBlue,
                      fontFamily: fonts.primary }}>
          Running unopposed
        </div>
      )}
    </div>
  );
}
```

Pattern derived from `CompassFirstCard.jsx` lines 200-244 (text block) + UI-SPEC §Surface Variants for the unopposed banner (new UI).

---

### `ev-ui/src/PlaceholderRadar.jsx` (component, static SVG)

**Primary analog:** `essentials/src/components/CompassFirstCard.jsx` lines 56-83 (inline `PlaceholderRadar` function — verbatim port, rewire colors through `colorScales`).

**Full pattern — port verbatim, replace hex with token references:**
```jsx
import { colorScales, borderRadius } from './tokens';

export default function PlaceholderRadar({ size = 250, name = '' }) {
  const cx = size / 2;
  const cy = size / 2;
  const r = (size / 2) * 0.65;
  const n = 8;
  const pts = Array.from({ length: n }, (_, i) => {
    const a = (2 * Math.PI * i) / n;
    return `${cx + r * Math.sin(a)},${cy - r * Math.cos(a)}`;
  }).join(' ');
  return (
    <svg
      width={size} height={size}
      viewBox={`0 0 ${size} ${size}`}
      role="img"
      aria-label={name ? `${name} — compass data unavailable` : 'compass data unavailable'}
      style={{ backgroundColor: colorScales.teal['050'],   // was '#F5F9FA'
               borderRadius: borderRadius.sm,              // was '4px'
               flexShrink: 0 }}
    >
      <polygon points={pts} fill="none"
        stroke={colorScales.gray['200']}   // was '#D3D7DE'
        strokeWidth="1.5" strokeDasharray="4 3" />
    </svg>
  );
}
```

No error handling, no state — pure presentational SVG.

---

### `ev-ui/src/IconOverlay.jsx` (component, tooltip row)

**Primary analog:** `essentials/src/components/IconOverlay.jsx` (lines 1-139) — verbatim port.

**Imports pattern — adjust one import only** (icons are already ev-ui exports, change the bare-package import to a relative one inside ev-ui):
```jsx
import React, { useState } from 'react';
import {
  useFloating, useHover, useFocus, useDismiss, useRole,
  useInteractions, FloatingPortal, offset, flip, shift, autoUpdate,
} from '@floating-ui/react';
import { BallotIcon, CompassIcon, BranchIcon } from './icons.js';  // was '@empoweredvote/ev-ui'
```

**IconWithTooltip pattern (verbatim — lines 22-81)** — keep floating-ui setup, hover/focus/dismiss/role interactions, `role="tooltip"`, `FloatingPortal` usage identical. Optionally rewire tooltip inline styles through `semanticTokens.light.tooltip` (`ev-ui/src/tokens.js` line 187) rather than hard-coded `#2F3237` / `#EBEDEF`:
```jsx
background: semanticTokens.light.tooltip.background, // '#2F3237'
color:      semanticTokens.light.tooltip.text,       // '#EBEDEF'
```

**IconOverlay pattern (verbatim — lines 94-139)** — unchanged. The `#00657C` color on each `IconWithTooltip` call should become `colors.evMutedBlue`.

**Dependency note:** Add `@floating-ui/react` to `ev-ui/package.json` `peerDependencies` (not `dependencies`) per Pitfall 3. Also add to `devDependencies` for local builds.

---

### `ev-ui/src/index.js` (barrel export)

**Analog:** existing export lines 1-34 in `ev-ui/src/index.js`.

**Pattern — append to Components section:**
```js
export { default as CompassCardHorizontal } from "./CompassCardHorizontal.jsx";
export { default as IconOverlay } from "./IconOverlay.jsx";
```
Do NOT export `CompassCardHorizontalMeta` or `PlaceholderRadar` — both are internal implementation details. Keeps the public API surface minimal.

---

### `essentials/src/pages/Prototype.jsx` (harness update)

**Self-evolve:** the file already is the harness. Modifications are additive:

**Replace import** (current line 12):
```js
// Before:
import CompassFirstCard, { VARIANT_CONFIG } from '../components/CompassFirstCard';
// After:
import { CompassCardHorizontal } from '@empoweredvote/ev-ui';
// Keep CompassFirstCard + VARIANT_CONFIG import alongside during migration
// (CONTEXT §Wave 0 Gaps: retain A/B/C toggle for visual comparison)
import CompassFirstCard, { VARIANT_CONFIG } from '../components/CompassFirstCard';
```

**Add view-mode SegmentedControl** (pattern taken from existing variant SegmentedControl at lines 102-115):
```jsx
const [view, setView] = useState(() => {
  try { return localStorage.getItem('ev:compass-card-view') || 'compass'; }
  catch { return 'compass'; }
});
useEffect(() => {
  try { localStorage.setItem('ev:compass-card-view', view); } catch {}
}, [view]);

<SegmentedControl
  options={[{ value:'compass', label:'Compass' }, { value:'portrait', label:'Portrait' }]}
  value={view}
  onChange={setView}
  ariaLabel="Card view mode"
/>
```

**Add at least one `surface='elections'` card row** in the grid render (Wave 0 gap — see RESEARCH §Wave 0).

**Do not retire `CompassFirstCard`** — Phase 129 concern.

---

## Shared Patterns

### Token-only styling (applies to all new ev-ui files)
**Source:** `ev-ui/src/PoliticianCard.jsx` lines 1-2, 47-173 (entire `styles` object uses tokens exclusively).
**Apply to:** `CompassCardHorizontal.jsx`, `CompassCardHorizontalMeta.jsx`, `PlaceholderRadar.jsx`, `IconOverlay.jsx`
```jsx
import { colors, fonts, fontWeights, fontSizes, spacing, borderRadius, shadows } from './tokens';
// Never: '#FFFFFF', '12px', '16px' etc. Always: colors.bgWhite, borderRadius.xl, spacing[4].
```
Enforces D-11. Exception: `RADAR_SIZE = 250` and `SLOT_WIDTH = 260` are dimensional constants (not spacing tokens), per UI-SPEC §Spacing Scale "Exceptions" note.

### Image → initials fallback (applies to portrait view)
**Source:** `ev-ui/src/PoliticianCard.jsx` lines 215-268.
**Apply to:** `CompassCardHorizontal.jsx` portrait slot renderer.
**Key elements:** `useState(false)` for `imgError`, `useEffect` reset on `imageSrc` change, `getInitials()` helper, `onError` handler on `<img>`, initials `<div>` fallback on `colors.evMutedBlue` background with `colors.textWhite`.

### Hover/focus/keyboard card shell (applies to interactive cards)
**Source:** `essentials/src/components/CompassFirstCard.jsx` lines 95-97, 126-156, 247-259.
**Apply to:** `CompassCardHorizontal.jsx` root div.
**Key elements:** `useState` for `hovered`/`focused`, `tabIndex={0}`, `role="article"`, `aria-label`, onKeyDown (Enter/Space → onClick), shadow escalation `shadows.md` → `shadows.cardHover` → `focus.ring`.

### Controlled-prop convention (D-03/D-04 — applies to `view`, `surface`)
**Source:** existing ev-ui components — none own page-level state.
**Apply to:** `CompassCardHorizontal.jsx` — no `useState` for `view` or `surface`. Parent holds state; card is fully controlled. Provide safe defaults (`view='compass'`, `surface='representatives'`) per Pitfall 4.

### Antipartisan constraint (D-12)
**Source:** user memory `feedback_antipartisan.md`; CLAUDE.md.
**Apply to:** all new files. Grep the implementation for `party`, `Democrat`, `Republican`, and red/blue partisan hex values before merge — must return zero data-driven matches.

### ev-ui peer dep hygiene
**Source:** `ev-ui/package.json` existing `peerDependencies` entries.
**Apply to:** `@floating-ui/react` addition — add to `peerDependencies` AND `devDependencies`, NOT `dependencies`. Prevents duplicate install in consumers (Pitfall 3).

---

## No Analog Found

All files have strong analogs. No gaps.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| — | — | — | N/A |

One genuinely new UI element — the **"Running unopposed" banner** (D-08) — has no direct analog in the codebase. UI-SPEC §Surface Variants specifies exact styling (bg `colors.infoLight`, left-border `3px solid #00657C`, `borderRadius.md`, 12px text). Implement fresh per UI-SPEC; no port.

---

## Metadata

**Analog search scope:**
- `ev-ui/src/` (full JSX inventory surveyed)
- `essentials/src/components/` (CompassFirstCard, IconOverlay, PoliticianCard references)
- `essentials/src/pages/Prototype.jsx` (harness, self-evolve)
- `essentials/src/lib/compass.js` (confirmed `buildAnswerMapByShortTitle` at line 65 — resolves RESEARCH A1 assumption)

**Files scanned:** 8 primary (all read in full or targeted)

**Pattern extraction date:** 2026-04-19

**Load-bearing source confirmations:**
- `buildAnswerMapByShortTitle` IS at `essentials/src/lib/compass.js` line 65 (assumption A1 from RESEARCH — VERIFIED). Planner may either port this helper into ev-ui as a private util or require consumers to pre-shape `userAnswers`. RESEARCH recommends the former; PATTERNS concurs.
- `IconOverlay` in essentials imports icons from `@empoweredvote/ev-ui` — the ported ev-ui version MUST use a relative `./icons.js` import instead to avoid circular package self-reference.
- `ev-ui/src/index.js` barrel order: add new exports alongside other Components entries (lines 2-23), not in Icons or Hooks sections.

## PATTERN MAPPING COMPLETE

**Phase:** 127 - CompassCardHorizontal in ev-ui
**Files classified:** 6 (4 new, 2 modified)
**Analogs found:** 6 / 6

### Coverage
- Files with exact analog: 4 (`CompassCardHorizontal.jsx`, `PlaceholderRadar.jsx`, `IconOverlay.jsx`, `index.js`)
- Files with role-match analog: 2 (`CompassCardHorizontalMeta.jsx`, `Prototype.jsx`)
- Files with no analog: 0

### Key Patterns Identified
- All new ev-ui files must use token-only styling (imports from `./tokens.js`) — no hex/px constants, mirroring `PoliticianCard.jsx`.
- `CompassCardHorizontal` is a mechanical port of `CompassFirstCard.jsx` variant C with A/B/`VARIANT_CONFIG` stripped, router/context hooks removed, and `view`/`surface` props added.
- `IconOverlay` port requires adding `@floating-ui/react` to ev-ui `peerDependencies` (not `dependencies`) and switching its icon import from `@empoweredvote/ev-ui` to relative `./icons.js`.
- Image → initials fallback is a lift-and-shift from `PoliticianCard.jsx` lines 215-268 (useState `imgError`, useEffect reset, `getInitials` helper, `onError` handler).
- Hover/focus/keyboard card shell is a direct port from `CompassFirstCard.jsx` lines 247-259 — keep all ARIA attributes and event handlers verbatim.
- The "Running unopposed" banner is the only genuinely new UI element; all other affordances have exact analogs.

### File Created
`/Users/chrisandrews/Documents/GitHub/.planning/phases/127-compass-card-horizontal-ev-ui/127-PATTERNS.md`

### Ready for Planning
Pattern mapping complete. Planner can now reference analog patterns with file + line-number excerpts in PLAN.md actions.
