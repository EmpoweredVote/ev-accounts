---
phase: 127-compass-card-horizontal-ev-ui
verified: 2026-04-19T00:00:00Z
status: human_needed
score: 3/3
overrides_applied: 0
human_verification:
  - test: "Visual layout: radar slot on left (~260px), meta column on right — compare against legacy CompassFirstCard variant C"
    expected: "Cards are visually indistinguishable from variant C in horizontal layout"
    why_human: "Pixel-level layout fidelity requires visual inspection; the slot dimensions are correct in code (SLOT_WIDTH=260) but exact visual rendering cannot be confirmed programmatically"
  - test: "View toggle: click Portrait in SegmentedControl — all CompassCardHorizontal cards switch simultaneously; click Compass to switch back; reload — last view mode persists"
    expected: "All 5 harness cards respond to single page-level toggle; localStorage persistence survives reload"
    why_human: "Interactive state transitions and localStorage persistence require browser execution"
  - test: "Empty-data card (userAnswers=null) shows a dashed octagon PlaceholderRadar in compass view, not blank space"
    expected: "Dashed SVG octagon visible for the rep-empty scenario card"
    why_human: "SVG render correctness requires visual inspection"
  - test: "Portrait fallback: rep-nophoto card in portrait view shows an initials circle with muted-blue background and white letters"
    expected: "Initials 'NP' visible in 260x260 slot with evMutedBlue background"
    why_human: "Image error fallback path requires browser to fire onError; cannot test without rendering"
  - test: "Elections surface: elec-unopposed card shows Running Unopposed overlay; elec-contested does not; both show office_running_for not office_title"
    expected: "Semi-transparent uppercase bar on unopposed card only; correct field in title slot"
    why_human: "Visual overlay positioning and field-switching require rendered inspection"
  - test: "IconOverlay tooltips appear on hover for Ballot, Compass, Branch icons"
    expected: "Floating-UI tooltip visible on hover; tooltip copy matches 127-UI-SPEC.md copywriting contract"
    why_human: "Hover interaction requires browser"
  - test: "Accessibility: Tab into a card — focus ring (white inner + muted-blue outer) appears"
    expected: "Visible focus indicator on card element"
    why_human: "Focus ring requires browser rendering of :focus state"
---

# Phase 127 Verification Report

**Phase Goal:** Port `CompassCardHorizontal` into the `@empoweredvote/ev-ui` React component library — a horizontal card with radar chart (or portrait photo) on the left and politician metadata on the right.
**Verified:** 2026-04-19
**Status:** HUMAN NEEDED (all automated checks pass; 7 items require browser/visual verification)
**Re-verification:** No — initial verification

---

## Goal Achievement

Phase 127 delivered every artifact it promised. The `CompassCardHorizontal` component exists, is substantive, is barrel-exported, has no routing/context dependencies, supports the `view` and `surface` props, renders `PlaceholderRadar` on null/empty answers, and renders an initials fallback when images fail. The prototype harness exercises all 5 required scenarios. No automated must-have failed. Three MEDIUM-severity code issues documented in REVIEW.md are open but do not block the phase goal (they are latent crash risks under real API data, not current test-scenario blockers).

---

## Requirement Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| CARD-01: Horizontal layout — radar slot on left (~260px), meta column on right | VERIFIED (code) / HUMAN (visual) | `CompassCardHorizontal.jsx:28` `SLOT_WIDTH=260`; `cardStyle.flexDirection='row'`; `slotStyle.width=SLOT_WIDTH`; meta column at `flex:1` right of slot |
| CARD-02: view prop switches between compass and portrait; PlaceholderRadar shown for null userAnswers | VERIFIED | `CompassCardHorizontal.jsx:65-66` null/empty guard → PlaceholderRadar; `line 208` `view==='portrait'` branch; `Prototype.jsx:278-293` all 5 cards receive `view={view}` from page-level state; localStorage persistence at `Prototype.jsx:47-63` |
| CARD-03: surface prop switches title field; elections surface shows running_unopposed overlay; portrait fallback shows initials | VERIFIED | `CompassCardHorizontalMeta.jsx:22-24` `office_running_for` vs `office_title` switch; `CompassCardHorizontal.jsx:213` `surface==='elections' && politician.running_unopposed` overlay; `CompassCardHorizontal.jsx:166-186` initials fallback with `evMutedBlue` bg + `textWhite` text |

---

## Required Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `ev-ui/src/CompassCardHorizontal.jsx` | VERIFIED | 243 lines; fully controlled props; no router/context imports; view + surface + onClick props; PlaceholderRadar + RadarChartCore + portrait + initials paths |
| `ev-ui/src/CompassCardHorizontalMeta.jsx` | VERIFIED | 89 lines; surface-switched title; district label; IconOverlay; "Running unopposed" conditional |
| `ev-ui/src/PlaceholderRadar.jsx` | VERIFIED | 35 lines; SVG dashed octagon; aria-label |
| `ev-ui/src/IconOverlay.jsx` | VERIFIED | 142 lines; floating-ui tooltips; ballot/compass/branch icons |
| `ev-ui/src/compassHelpers.js` | VERIFIED | Exports `buildAnswerMapByShortTitle`; not exported from barrel |
| `ev-ui/src/index.js` (barrel) | VERIFIED | `CompassCardHorizontal` and `IconOverlay` exported; `CompassCardHorizontalMeta`, `PlaceholderRadar`, `compassHelpers` correctly absent |
| `essentials/src/pages/Prototype.jsx` | VERIFIED | Imports `CompassCardHorizontal` from `@empoweredvote/ev-ui`; page-level `view` state with localStorage; 5 harness scenarios wired |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `Prototype.jsx` | `CompassCardHorizontal` | `import { CompassCardHorizontal } from '@empoweredvote/ev-ui'` | WIRED | `Prototype.jsx:2`; npm link in place |
| `CompassCardHorizontal` | `RadarChartCore` | direct import | WIRED | `CompassCardHorizontal.jsx:6` |
| `CompassCardHorizontal` | `PlaceholderRadar` | direct import | WIRED | `CompassCardHorizontal.jsx:7` |
| `CompassCardHorizontal` | `CompassCardHorizontalMeta` | direct import | WIRED | `CompassCardHorizontal.jsx:8` |
| `CompassCardHorizontal` | `buildAnswerMapByShortTitle` | `compassHelpers.js` | WIRED | `CompassCardHorizontal.jsx:9,85` |
| `ev-ui/src/index.js` | `CompassCardHorizontal` | barrel export | WIRED | `index.js:7` |

---

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `Prototype.jsx` CompassCardHorizontal showcase | `politicians` | `usePoliticianData(BLOOMINGTON_ADDRESS)` API call | Yes — live API; guarded by `politicians && politicians.length > 0` | FLOWING |
| `CompassCardHorizontal` radar path | `userAnswers` | Passed as prop from Prototype (`USER_ANSWERS` / `null`) | Yes — shaped from `MOCK_USER_COMPASS` at module scope; null scenario intentional for placeholder test | FLOWING |
| `CompassCardHorizontal` portrait path | `photo_origin_url` | `politician.photo_origin_url` from API; `null` injected for nophoto scenario | Yes for live data; intentionally null for initials-fallback scenario | FLOWING |

---

## Behavioral Spot-Checks

| Behavior | Check | Status |
|----------|-------|--------|
| `CompassCardHorizontal` is exported from barrel | `grep "CompassCardHorizontal" ev-ui/src/index.js` | PASS |
| Internals not leaked from barrel | No match for `CompassCardHorizontalMeta`, `PlaceholderRadar`, `compassHelpers` in `index.js` | PASS |
| Prototype imports `CompassCardHorizontal` from `@empoweredvote/ev-ui` | `Prototype.jsx:2` | PASS |
| No partisan references in new component files | grep `Democrat\|Republican` — no matches | PASS |
| No routing/context imports in `CompassCardHorizontal` | grep `useNavigate\|useCompass\|useContext` — no matches | PASS |
| `view` prop controls compass/portrait branch | `CompassCardHorizontal.jsx:208` conditional on `view === 'portrait'` | PASS |
| `userAnswers=null` triggers PlaceholderRadar | `CompassCardHorizontal.jsx:65-66` explicit null/empty guard | PASS |
| `surface='elections'` switches title field | `CompassCardHorizontalMeta.jsx:22-24` | PASS |
| `running_unopposed` overlay conditional | `CompassCardHorizontal.jsx:213` | PASS |
| Initials fallback constructed from `full_name` | `CompassCardHorizontal.jsx:166-186` | PASS |

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `CompassCardHorizontal.jsx` | 220 | `color: '#fff'` — hex literal; `colors.textWhite` token exists | Warning | Minor token violation; does not affect behavior |
| `CompassCardHorizontal.jsx` | 221 | `fontSize: '12px'` — px literal; `fontSizes.xs` token exists | Warning | Minor token violation; does not affect behavior |
| `CompassCardHorizontalMeta.jsx` | 82 | `hasStances={Boolean(userAnswers && userAnswers.length > 0) \|\| Boolean(politician.hasStances)}` — shows compass icon for all cards when user has any answers, regardless of whether that politician has stances | Warning (MEDIUM per REVIEW.md) | Creates dead affordance for politicians without stances; not a goal-blocking issue for Phase 127 since the harness mock data does not expose this condition |
| `IconOverlay.jsx` | 99 | `ballot.electionDate.toLocaleDateString()` without Date-object guard | Warning (MEDIUM per REVIEW.md) | Crash risk when API returns date strings; not triggered by current harness since no ballot data is passed in Phase 127 scenarios |
| `CompassCardHorizontal.jsx` | 197 | `onClick()` called without event argument in `onKeyDown` handler | Warning (MEDIUM per REVIEW.md) | Inconsistent click/keyboard event contract; no current consumer is affected |

All five issues are documented in `127-REVIEW.md`. None are goal-blocking for Phase 127 (harness-level verification) but items 3 and 4 should be resolved before the component ships in a tagged ev-ui release.

---

## Human Verification Required

### 1. CARD-01 — Horizontal layout visual fidelity

**Test:** Load `http://localhost:5173/prototype`. Scroll to "CompassCardHorizontal (ev-ui port) — Representatives surface". Confirm each card has radar on the LEFT (~260px wide) and meta column on the RIGHT with name in muted blue, office title, district subtitle, then affordance icons. Compare against the legacy CompassFirstCard variant C cards above — layouts should be indistinguishable.
**Expected:** Visual parity with variant C; slot approximately 260px wide.
**Why human:** Pixel-level layout requires visual inspection of the rendered browser output.

### 2. CARD-02 — View toggle flips all cards simultaneously and persists

**Test:** Click "Portrait" in the top SegmentedControl. Confirm ALL CompassCardHorizontal cards switch to portrait/initials. Click "Compass" — all switch back. Reload (Cmd+R) — last-selected view mode must be remembered.
**Expected:** Simultaneous switch on all 5 cards; localStorage key `ev:compass-card-view` persists the choice.
**Why human:** Interactive state transitions and localStorage persistence require a live browser.

### 3. CARD-02 — Empty-data card shows PlaceholderRadar

**Test:** In compass view, identify the "rep-empty" card (fourth card in the Representatives section, using `userAnswers=null`). Confirm it shows a dashed octagon graphic rather than a blank white box.
**Expected:** Dashed SVG octagon on teal-tinted background visible.
**Why human:** SVG render correctness requires visual inspection.

### 4. CARD-03 — Portrait fallback shows initials

**Test:** Switch to portrait view. Find "rep-nophoto" card (the "No Photo Politician" card). Confirm a solid muted-blue square with white initials "NP" fills the left slot.
**Expected:** Initials circle (muted-blue background, white "NP") at 260x260.
**Why human:** `onError` image fallback path requires the browser to attempt image load and trigger the error handler.

### 5. CARD-03 — Elections surface + Running Unopposed overlay

**Test:** Scroll to "Elections surface". Confirm: (a) both cards show `office_running_for` text in the title slot, (b) the "elec-unopposed" card shows a "RUNNING UNOPPOSED" overlay bar, (c) the "elec-contested" card does NOT show the bar.
**Expected:** Overlay visible only on the unopposed card; title field sourced from `office_running_for`.
**Why human:** Overlay positioning and conditional rendering require visual confirmation.

### 6. CARD-03 — Affordance icon tooltips

**Test:** Hover over the Ballot, Compass, and Branch affordance icons on cards that have them. Confirm tooltips appear via floating-ui.
**Expected:** Tooltips appear; copy matches 127-UI-SPEC.md §Copywriting Contract.
**Why human:** Hover interaction cannot be tested programmatically without a browser.

### 7. Accessibility — focus ring

**Test:** Tab into a CompassCardHorizontal card. Confirm a visible focus ring appears on the card element.
**Expected:** White inner ring + muted-blue outer ring (or equivalent visible focus indicator).
**Why human:** Focus ring rendering requires a browser.

---

## Known Gaps

No automated must-haves failed. The phase goal is structurally complete. Three items to address before the ev-ui release tag:

1. `hasStances` logic in `CompassCardHorizontalMeta.jsx:82` — should be `Boolean(politician.hasStances)` (or `Boolean(userAnswers?.length) && Boolean(politician.hasStances)`). Current logic shows the compass icon for every card when the user has any answers.
2. `ballot.electionDate.toLocaleDateString()` in `IconOverlay.jsx:99` — needs a `instanceof Date` guard to handle string input from JSON APIs.
3. Token violations (`'#fff'`, `'12px'`) in the "Running Unopposed" overlay at `CompassCardHorizontal.jsx:220-221` — replace with `colors.textWhite` and `fontSizes.xs`.

These are pre-release fixes, not Phase 127 goal gaps. The harness verification (8-point checklist in SUMMARY-03) was completed and approved by the user on 2026-04-19.

---

_Verified: 2026-04-19_
_Verifier: Claude (gsd-verifier)_
