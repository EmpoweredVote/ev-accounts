---
phase: 127
plan: 02
subsystem: ev-ui
tags: [ev-ui, component-library, react, card, compass]
dependency_graph:
  requires:
    - ev-ui/src/PlaceholderRadar.jsx (Plan 01)
    - ev-ui/src/IconOverlay.jsx (Plan 01)
    - ev-ui/src/RadarChartCore.jsx (existing)
  provides:
    - ev-ui/src/CompassCardHorizontal.jsx
    - ev-ui/src/CompassCardHorizontalMeta.jsx
    - ev-ui/src/compassHelpers.js
    - "CompassCardHorizontal export in @empoweredvote/ev-ui"
    - "IconOverlay export in @empoweredvote/ev-ui"
  affects:
    - ev-ui/dist/index.js (CJS bundle, +14KB)
    - ev-ui/dist/index.mjs (ESM bundle, +13.45KB)
tech_stack:
  added: []
  patterns:
    - token-only inline styles (no hex/px literals — exception: none needed, colors.textWhite used)
    - controlled props pattern (view/surface owned by consumer, not card)
    - try-catch guard on userAnswers shaping for T-127-06 DoS mitigation
    - portrait slot at same 260px dimensions as radar slot for grid uniformity (D-10)
key_files:
  created:
    - ev-ui/src/compassHelpers.js
    - ev-ui/src/CompassCardHorizontalMeta.jsx
    - ev-ui/src/CompassCardHorizontal.jsx
  modified:
    - ev-ui/src/index.js
decisions:
  - "colors.textWhite (#FFFFFF) used for initials fallback text — token exists, no hex literal needed"
  - "userAnswers shaping supports embedded topic objects (a.topic.short_title) as primary path, with short_title-direct fallback"
  - "T-127-06 guard implemented as try-catch on shaping block — falls back to PlaceholderRadar on any malformed input"
  - "IconOverlay NOT re-exported from icons grouping — placed in Components section alongside PoliticianCard per plan instruction"
metrics:
  duration: "~20 minutes"
  completed: "2026-04-19T03:05:00Z"
  tasks_completed: 3
  files_created: 3
  files_modified: 1
requirements:
  - CARD-01
  - CARD-02
  - CARD-03
---

# Phase 127 Plan 02: CompassCardHorizontal Component — Summary

**One-liner:** CompassCardHorizontal (radar-left/meta-right, 260px slot) + CompassCardHorizontalMeta (surface-switched) + compassHelpers ported to ev-ui and barrel-exported

## What Was Built

### Task 1 — compassHelpers.js + CompassCardHorizontalMeta.jsx

**ev-ui/src/compassHelpers.js** — Private util porting `buildAnswerMapByShortTitle` verbatim from `essentials/src/lib/compass.js`. Not exported from barrel. Used by CompassCardHorizontal to shape raw userAnswers arrays into topics/data for RadarChartCore.

**ev-ui/src/CompassCardHorizontalMeta.jsx** — Meta column renderer with surface switch:
- `surface='representatives'` → shows `politician.office_title`
- `surface='elections'` → shows `politician.office_running_for` + "Running unopposed" banner when `politician.running_unopposed` is truthy
- Name: 18px/600 weight, `colors.evMutedBlue`
- Title: 14px/600 weight, `colors.textSecondary`, 2-line WebkitLineClamp
- District: 14px/400 weight, `colors.textMuted`, single-line ellipsis
- Affordance icons via `IconOverlay` (ballot, hasStances, branch)
- Token-only styling, antipartisan clean, internal only

### Task 2 — CompassCardHorizontal.jsx

Port of `essentials/src/components/CompassFirstCard.jsx` variant C branch with full cleanup:

**Stripped:** `VARIANT_CONFIG`, `variant` prop, `useNavigate`, `useCompass`, `MOCK_USER_COMPASS`, `MOCK_TOPICS`, all inline hex/px literals

**Added:**
- `view='compass'|'portrait'` prop (default: `'compass'`) — fully controlled, no internal state
- `surface='representatives'|'elections'` prop (default: `'representatives'`)
- `onClick` prop replacing internal `navigate()`
- Portrait slot at same 260px (SLOT_WIDTH) as radar slot — grid uniformity (D-10, Pitfall 2)
- `colors.textWhite` for initials fallback (token found — no hex literal needed)
- T-127-06 try-catch guard on userAnswers shaping → PlaceholderRadar fallback

**Public API Contract:**
```jsx
<CompassCardHorizontal
  politician={object}           // required
  userAnswers={Array|null}      // null/[] → PlaceholderRadar; default null
  tierVisuals={{bg, accent, text}} // optional tier background; default null
  view="compass"                // 'compass' | 'portrait'; default 'compass'
  surface="representatives"     // 'representatives' | 'elections'; default 'representatives'
  onClick={Function}            // optional click handler
/>
```

### Task 3 — ev-ui/src/index.js barrel update

Added two exports to the Components section (adjacent to `PoliticianCard`):
```js
export { default as CompassCardHorizontal } from "./CompassCardHorizontal.jsx";
export { default as IconOverlay } from "./IconOverlay.jsx";
```

Internals remain private: `CompassCardHorizontalMeta`, `PlaceholderRadar`, `buildAnswerMapByShortTitle` / `compassHelpers` — none leaked to barrel.

## Commits (ev-ui repo — feat/compass-first-card branch)

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Port compassHelpers + CompassCardHorizontalMeta | 3e894aa | ev-ui/src/compassHelpers.js, ev-ui/src/CompassCardHorizontalMeta.jsx |
| 2 | Build CompassCardHorizontal | a7b7046 | ev-ui/src/CompassCardHorizontal.jsx |
| 3 | Barrel export CompassCardHorizontal + IconOverlay | 72d5325 | ev-ui/src/index.js |

## Token Mismatches Encountered

None. `colors.textWhite` is defined in `ev-ui/src/tokens.js` as `'#FFFFFF'`, so it was used for the initials fallback text color instead of a hex literal. No hex literals appear in any new file.

## Internals Confirmed Private

- `CompassCardHorizontalMeta` — not in `ev-ui/src/index.js`, not in `dist/index.js` exports
- `PlaceholderRadar` — not in `ev-ui/src/index.js`, not in `dist/index.js` exports
- `compassHelpers` / `buildAnswerMapByShortTitle` — not in `ev-ui/src/index.js`, not in `dist/index.js` exports

Verified via: `node -e "const m=require('./dist/index.js'); if(m.CompassCardHorizontalMeta||m.PlaceholderRadar||m.buildAnswerMapByShortTitle) throw 'leaked'"`

## Deviations from Plan

### Minor Deviations

**1. [Rule 2 - Missing critical functionality] userAnswers shaping — added embedded-topic path**

The plan's `renderCompass()` pseudocode referenced `buildAnswerMapByShortTitle` with `MOCK_TOPICS` (an allowedShorts array from mock data). In ev-ui, there are no mock topics — the card receives raw `userAnswers` from the consumer. Added an embedded-topic detection path (`a.topic.short_title`) as the primary shaping route, with a short_title-direct fallback and a try-catch guard (T-127-06). When shaping produces no topics, PlaceholderRadar is rendered.

No architectural deviation — all within the single component file.

No Rule 4 blockers encountered.

## Verification Results

- `cd ev-ui && npm run build` — exits 0 (ESM 188.77KB, CJS 201.32KB)
- `dist/index.js` exports `CompassCardHorizontal` and `IconOverlay` as functions
- `dist/index.mjs` contains both names
- `grep -rE "#[0-9a-fA-F]{3,6}" ev-ui/src/CompassCardHorizontal.jsx ev-ui/src/CompassCardHorizontalMeta.jsx` — no matches
- `grep -rE "Democrat|Republican" ev-ui/src/Compass*.jsx ev-ui/src/compassHelpers.js` — no matches (antipartisan clean)
- `ev-ui/package.json` version: `0.4.4` (unchanged)
- No git tag pushed

## Threat Surface Scan

No new security surface introduced beyond what the plan's threat model covers:
- T-127-03: React auto-escaping — no `dangerouslySetInnerHTML` in any new file (verified via grep)
- T-127-05: `photo_origin_url` rendered as `<img src>` attribute — React treats as attribute, no JS execution
- T-127-06: malformed `userAnswers` → try-catch → PlaceholderRadar fallback implemented

## Known Stubs

None. `CompassCardHorizontal` is a complete, production-ready component. The userAnswers shaping does require the consumer to provide properly structured answers (with embedded `topic` objects for the primary path), but this is a documented consumer contract, not a stub.

## Self-Check: PASSED

- [x] ev-ui/src/compassHelpers.js exists and exports `buildAnswerMapByShortTitle`
- [x] ev-ui/src/CompassCardHorizontalMeta.jsx exists with surface switch, IconOverlay, "Running unopposed"
- [x] ev-ui/src/CompassCardHorizontal.jsx exists with RADAR_SIZE=250, SLOT_WIDTH=260, view/surface props, PlaceholderRadar, RadarChartCore, role="article"
- [x] ev-ui/src/index.js exports CompassCardHorizontal and IconOverlay (no internals leaked)
- [x] Commits 3e894aa, a7b7046, 72d5325 exist in ev-ui feat/compass-first-card branch
- [x] Build passes (ESM + CJS)
- [x] No hex strings in new component files
- [x] No version bump performed (still 0.4.4)
- [x] Antipartisan clean
