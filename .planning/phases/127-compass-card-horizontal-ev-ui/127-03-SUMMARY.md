---
phase: 127
plan: 03
subsystem: essentials
tags: [essentials, harness, prototype, integration, ev-ui]
dependency_graph:
  requires:
    - ev-ui/src/CompassCardHorizontal.jsx (Plan 02)
    - ev-ui/src/index.js (Plan 02 — CompassCardHorizontal barrel export)
    - essentials/src/pages/Prototype.jsx (pre-existing)
  provides:
    - "essentials/src/pages/Prototype.jsx (Phase 127 visual harness)"
    - "localStorage-backed compass/portrait view toggle"
    - "5 harness scenarios for CARD-01/02/03 verification"
  affects:
    - essentials/dist/ (consumer build)
tech_stack:
  added: []
  patterns:
    - localStorage lazy-init useState (try-catch guard on SSR/private-mode)
    - controlled view prop passed down to CompassCardHorizontal (consumer owns state)
    - MOCK_USER_COMPASS reshaped to { short_title, value }[] for CompassCardHorizontal fallback path
key_files:
  created: []
  modified:
    - essentials/src/pages/Prototype.jsx
decisions:
  - "npm link used (not file: dep) — essentials/package.json unchanged, no git diff"
  - "USER_ANSWERS derived from MOCK_USER_COMPASS at module scope — avoids per-render allocation"
  - "CompassCardHorizontal showcase rendered only when politicians array has data (guarded by &&) — avoids flash during load"
  - "Legacy CompassFirstCard and VARIANT_CONFIG retained per 127-RESEARCH.md Wave 0 — retirement deferred to Phase 129"
metrics:
  duration: "~15 minutes"
  completed: "2026-04-18T22:45:00Z"
  tasks_completed: 2
  files_created: 0
  files_modified: 1
requirements:
  - CARD-01
  - CARD-02
  - CARD-03
---

# Phase 127 Plan 03: Prototype Harness — Summary

**One-liner:** Prototype.jsx wired with CompassCardHorizontal from locally-linked ev-ui, localStorage-backed view toggle, and 5 harness scenarios (representatives/elections surfaces, empty-data, missing-photo, running_unopposed)

## What Was Built

### Task 1 — ev-ui linked locally into essentials

**Method:** `npm link` (preferred — reversible, no package.json diff)

```bash
cd /Users/chrisandrews/Documents/GitHub/ev-ui && npm run build && npm link
cd /Users/chrisandrews/Documents/GitHub/essentials && npm link @empoweredvote/ev-ui
```

**Result:**
- `essentials/node_modules/@empoweredvote/ev-ui` is a symlink pointing to `../../../ev-ui`
- `require('@empoweredvote/ev-ui').CompassCardHorizontal` resolves to a function
- `essentials/package.json` is **unchanged** (no file: dep fallback needed)
- `ev-ui/package.json` version remains `0.4.4` (no bump performed)
- No git tag pushed

**Verification passed:**
```
ls -la essentials/node_modules/@empoweredvote/ev-ui
# lrwxr-xr-x -> ../../../ev-ui

node -e "require('@empoweredvote/ev-ui').CompassCardHorizontal" → function ✓
```

### Task 2 — Prototype.jsx updated with view toggle and 5 harness scenarios

**File:** `essentials/src/pages/Prototype.jsx`  
**Commit:** `df4d213` (essentials repo, branch: main)

**Edit 1 — New import added alongside existing:**
```jsx
import { SiteHeader, CategorySection, CompassCardHorizontal } from '@empoweredvote/ev-ui';
import MOCK_STANCES, { MOCK_USER_COMPASS } from '../data/mockCompassData';
```

**Edit 2 — USER_ANSWERS shaped at module scope:**
`MOCK_USER_COMPASS` (`{ [short_title]: number }`) converted to `[{ short_title, value }]` array — compatible with CompassCardHorizontal's fallback shaping path.

**Edit 3 — View-mode state with localStorage persistence:**
```jsx
const [view, setView] = useState(() => {
  try {
    const stored = localStorage.getItem('ev:compass-card-view');
    return stored === 'portrait' ? 'portrait' : 'compass';
  } catch { return 'compass'; }
});
useEffect(() => {
  try { localStorage.setItem('ev:compass-card-view', view); } catch {}
}, [view]);
```

**Edit 4 — Page-level SegmentedControl added above legacy variant toggle:**
Both controls rendered in a flex row. View toggle (`compass`/`portrait`) appears first; legacy A/B/C variant toggle retained alongside.

**Edit 5 — CompassCardHorizontal showcase section added below tier sections:**

5 harness scenarios, all guarded by `politicians && politicians.length > 0`:

| Scenario | Key | Surface | userAnswers | Special |
|----------|-----|---------|-------------|---------|
| 1 | rep-0, rep-1, rep-2 | representatives | USER_ANSWERS (live) | Normal compass/portrait |
| 3 | rep-empty | representatives | null | Forces PlaceholderRadar |
| 4 | rep-nophoto | representatives | USER_ANSWERS | photo_origin_url=null, images=null → initials fallback |
| 5a | elec-contested | elections | USER_ANSWERS | running_unopposed: false |
| 5b | elec-unopposed | elections | USER_ANSWERS | running_unopposed: true |

**Legacy retained:** `CompassFirstCard`, `VARIANT_CONFIG`, A/B/C toggle grid — all untouched per 127-RESEARCH.md Wave 0.

**Smoke build result:**
```
vite build → ✓ built in 2.26s (exit 0)
```
Pre-existing chunk size warning only (not new, not an error).

## Commits

| Task | Name | Repo | Commit | Files |
|------|------|------|--------|-------|
| 1 | Link ev-ui locally into essentials | — (shell only, no file changes) | — | essentials/node_modules/@empoweredvote/ev-ui (symlink) |
| 2 | Update Prototype.jsx with view toggle and 5 harness scenarios | essentials | df4d213 | essentials/src/pages/Prototype.jsx |

## Checkpoint Required

**Status:** AWAITING_HUMAN_VERIFY  
**Task:** Task 3 — Human verifies harness scenarios (CARD-01, CARD-02, CARD-03)

### What Was Built

- `CompassCardHorizontal` exported from `@empoweredvote/ev-ui` (Plan 02, branch `feat/compass-first-card` in ev-ui repo)
- Prototype harness at `essentials/src/pages/Prototype.jsx` renders 5 scenarios under both `view='compass'` and `view='portrait'`, plus representatives and elections surfaces
- Page-level SegmentedControl persists view mode via localStorage key `ev:compass-card-view`
- No ev-ui version bump has been performed (still 0.4.4)

### Dev Server Command

```bash
cd /Users/chrisandrews/Documents/GitHub/essentials && npm run dev
# Open http://localhost:5173/prototype (confirm exact port in terminal output)
```

### 8-Point Verification Checklist

1. **CARD-01 — Horizontal layout matches variant C.** Scroll to "CompassCardHorizontal (ev-ui port) → Representatives surface". Confirm each card has radar on the LEFT (~260px wide) and meta column on the RIGHT with name in muted blue, then office title, then district subtitle, then affordance icons. Compare against legacy CompassFirstCard variant C above — layouts should be indistinguishable.

2. **CARD-02 — View toggle flips all cards simultaneously.** Click "Portrait" in the view SegmentedControl. ALL cards must switch from radar/placeholder to portrait/initials. Click "Compass" — all switch back. Reload (Cmd+R) — last-selected view mode must persist.

3. **CARD-02 — Empty-data card shows PlaceholderRadar.** The "rep-empty" card (userAnswers=null) in compass view must show a dashed octagon placeholder, NOT a blank space. In portrait view it shows portrait/initials.

4. **CARD-03 — Portrait fallback.** The "rep-nophoto" card in portrait view must show an initials circle (muted-blue background, white letters "NP" for "No Photo Politician"). In compass view it shows radar/placeholder normally.

5. **CARD-03 — Elections surface + Running unopposed banner.** In "Elections surface", one card must display a "Running unopposed" banner (muted-blue left border, pale teal background). The other elections card must NOT show this banner. Elections cards must show `office_running_for`, not `office_title`.

6. **CARD-03 — Affordance icon parity.** Hover each affordance icon (Ballot, Compass, Branch where present). Tooltips must appear via floating-ui positioning. Tooltip copy matches 127-UI-SPEC.md §Copywriting Contract.

7. **Antipartisan (D-12).** Nothing on any card shows "Democrat", "Republican", or red/blue party associations.

8. **Accessibility smoke.** Tab into a card — focus ring (white inner + muted-blue outer) appears.

### Sign-off Required

Type `approved` if all 8 checks pass, or describe any failures for gap closure.

## Deviations from Plan

### Minor Deviations

**1. [Rule 2 - Missing critical functionality] USER_ANSWERS shaped at module scope**

The plan pseudocode referenced `userAnswers` from a `useCompass` context, but the existing Prototype.jsx uses no compass context — it uses `MOCK_STANCES` directly. Added `USER_ANSWERS` constant derived from `MOCK_USER_COMPASS` at module scope, shaped into the `[{ short_title, value }]` array format that `CompassCardHorizontal`'s fallback path accepts. This is the correct adaptation given the existing harness data architecture.

**2. [Rule 2 - Missing guard] CompassCardHorizontal section guarded by politicians data check**

The plan's pseudocode rendered the showcase section unconditionally. Added `{politicians && politicians.length > 0 && (` guard to prevent rendering with `undefined` politician references during the API loading phase. This prevents "cannot read property of undefined" errors on `politicians[0]` and `politicians[1]`.

No Rule 4 blockers encountered.

## ev-ui Version Check

- `ev-ui/package.json` version: `0.4.4` (unchanged from Phase 127 start)
- No git tag pushed

## Known Stubs

None. All 5 harness scenarios use real politician data from the live API call (Bloomington, IN address). The `USER_ANSWERS` fixture is mock data but that is intentional for the harness — it is not a production stub.

## Threat Surface Scan

No new security surface introduced:
- T-127-07: `photo_origin_url` rendered as `<img src>` — same pattern as Plan 02, fixtures are developer-controlled
- T-127-08: `npm link` symlink — local dev only, not a production path

## Self-Check: PASSED

- [x] essentials/src/pages/Prototype.jsx modified with all required patterns
- [x] `grep "CompassCardHorizontal.*from '@empoweredvote/ev-ui'"` matches
- [x] `grep "ev:compass-card-view"` matches
- [x] `grep 'surface="elections"'` matches
- [x] `grep 'surface="representatives"'` matches
- [x] `grep "running_unopposed: true"` matches
- [x] `grep "view={view}"` matches
- [x] `grep "CompassFirstCard"` still matches (legacy retained)
- [x] `grep "VARIANT_CONFIG"` still matches (legacy retained)
- [x] `cd essentials && npm run build` exits 0
- [x] Commit df4d213 exists in essentials repo (main branch)
- [x] ev-ui version 0.4.4 unchanged
- [x] No git tag pushed
