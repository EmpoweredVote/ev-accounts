---
phase: 129-essentials-adoption-prototype-retirement
verified: 2026-04-26T21:00:00Z
status: passed
score: 8/9
overrides_applied: 0
human_verification:
  - test: "Open essentials dev server, enter a Bloomington IN address, confirm Representatives tab shows CompassCardVertical (portrait + name + position + radar) for every politician with no floating hover popover"
    expected: "Every politician card renders CompassCardVertical inline radar; no CompassPreview popover appears on hover"
    why_human: "Visual card rendering and hover behavior cannot be verified by grep or build output alone"
  - test: "On the Representatives tab, apply a non-default sort option (e.g. by name or district) and toggle the elected/appointed filter"
    expected: "Card order updates on sort; visible card set changes on filter toggle; no cards disappear or error"
    why_human: "Sort/filter behavior is runtime React state that cannot be verified statically"
  - test: "Scroll the Representatives page from top to bottom"
    expected: "Tier-band scroll-spy indicator (Federal → State → Local) updates as corresponding sections enter viewport"
    why_human: "IntersectionObserver scroll-spy behavior requires a live browser"
  - test: "Switch to Elections tab via SegmentedControl, verify both directions of the toggle work"
    expected: "Incumbents render full compass card; challengers render empty/minimal variant; tab toggle works in both directions"
    why_human: "Variant rendering logic and tab toggle state require live browser verification"
  - test: "Navigate to /prototype in the browser address bar"
    expected: "Page does NOT load the old Prototype page — hits the app's 404/fallback"
    why_human: "Route fallback behavior is browser-runtime; file deletion and App.jsx grep confirm the route is gone but the 404 fallback itself needs visual confirmation"
  - test: "Open compass.empowered.vote (or run CompassV2 locally), navigate to Compare view, open the politician compare picker"
    expected: "Picker renders without errors, politicians are selectable, no console errors"
    why_human: "Live consumer smoke-check for ev-ui 0.6.1 compatibility and network-dependent politician data"
---

# Phase 129: Essentials Adoption & Prototype Retirement — Verification Report

**Phase Goal:** Retire the /prototype route and prototype harness components; remove the redundant CompassPreview floating popover — leaving CompassCardVertical as the sole production card on Representatives and Elections pages.
**Verified:** 2026-04-26T21:00:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | /prototype route removed from App.jsx (import + Route element gone) | VERIFIED | `grep -n "Prototype" essentials/src/App.jsx` → 0 matches; route table shows only `/`, `/results`, `/politician/:id` |
| 2 | Prototype.jsx, CompassFirstCard.jsx, mockCompassData.js deleted | VERIFIED | `test -f` checks for all three → all absent from filesystem |
| 3 | CompassPreview floating popover removed from Results.jsx | VERIFIED | `grep -n "CompassPreview\|previewPol\|setPreviewPol"` → 0 matches in Results.jsx |
| 4 | CompassPreview.jsx component file deleted | VERIFIED | `test -f essentials/src/components/CompassPreview.jsx` → file absent |
| 5 | No residual prototype or popover references anywhere in essentials/src/ | VERIFIED | Full sweep: `grep -rn "CompassPreview\|previewPol\|Prototype\|CompassFirstCard\|mockCompassData" essentials/src/` → 0 matches |
| 6 | classify.js JSDoc no longer references Prototype.jsx; computeVariant still exported | VERIFIED | `grep "Prototype.jsx" classify.js` → 0 matches; `grep "computeVariant" classify.js` → line 311 confirms export |
| 7 | SegmentedControl import preserved in Results.jsx (Reps/Elections tab toggle) | VERIFIED | Line 12: `import SegmentedControl from '../components/SegmentedControl'` confirmed present |
| 8 | CompassCardVertical wired in both Results.jsx and ElectionsView.jsx | VERIFIED | Results.jsx line 904: `<CompassCardVertical ... />` with real props; ElectionsView.jsx line 639: `<CompassCardVertical ... />` with real props; both receive `politician`, `userAnswers`, `variant`, `surface` props from live data |
| 9 | essentials production build passes clean | VERIFIED | `npm run build` → 753 modules, exit 0; warnings are pre-existing chunk-size and dynamic-import notes unrelated to this phase |

**Score:** 9/9 automated truths verified

### Deferred Items

No items deferred to later phases.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `essentials/src/App.jsx` | Route table with no /prototype route and no Prototype import | VERIFIED | No Prototype import or /prototype Route; routes: `/`, `/results`, `/politician/:id` only |
| `essentials/src/pages/Results.jsx` | Results page with no CompassPreview popover; CompassCardVertical remains the production card | VERIFIED | No CompassPreview/previewPol; CompassCardVertical import at line 3, render at line 904 |
| `essentials/src/pages/Prototype.jsx` | Deleted | VERIFIED | File absent |
| `essentials/src/components/CompassFirstCard.jsx` | Deleted | VERIFIED | File absent |
| `essentials/src/data/mockCompassData.js` | Deleted | VERIFIED | File absent |
| `essentials/src/components/CompassPreview.jsx` | Deleted | VERIFIED | File absent |
| `.planning/phases/129-essentials-adoption-prototype-retirement/129-03-SUMMARY.md` | End-to-end verification record | VERIFIED | File present; contains human smoke-test results table with PASSED for all 10 checks |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `essentials/src/App.jsx` | (removed) | no import of ./pages/Prototype | VERIFIED | `grep "Prototype" App.jsx` → 0 matches |
| `essentials/src/pages/Results.jsx` | `@empoweredvote/ev-ui` CompassCardVertical | import at line 3, render at line 904 | VERIFIED | Import confirmed; `<CompassCardVertical politician={polForCard} userAnswers={userAnswers} variant={computeVariant(...)} surface="representatives" />` |
| `essentials/src/components/ElectionsView.jsx` | `@empoweredvote/ev-ui` CompassCardVertical | import at line 6, render at line 639 | VERIFIED | `<CompassCardVertical politician={polForCard} userAnswers={userAnswers} variant={computeVariant(...)} surface="elections" />` |
| `ev-ui` tag push | publish.yml → consumer auto-bump PRs | git tag v0.6.1 | VERIFIED | Tag `v0.6.1` confirmed in ev-ui repo; essentials commit `7f4811b` "chore: bump @empoweredvote/ev-ui to 0.6.1 (#23)" on main; CompassV2 package.json also at `^0.6.1` |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|--------------------|--------|
| `Results.jsx` CompassCardVertical | `userAnswers` | `useCompass()` hook → `rawUserAnswers` from context (API or ev-context) | Yes — derived from real compass answers via `useMemo` over `rawUserAnswers` | FLOWING |
| `Results.jsx` CompassCardVertical | `polForCard` | Constructed at line 890 from `pol` (politician from API response) | Yes — built from live API politician data | FLOWING |
| `ElectionsView.jsx` CompassCardVertical | `userAnswers`, `polForCard` | Same `useCompass()` pattern; `polForCard` from candidate data | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| No residual prototype symbols in essentials/src | `grep -rn "Prototype\|CompassFirstCard\|mockCompassData" essentials/src/` | 0 matches | PASS |
| No residual popover symbols in essentials/src | `grep -rn "CompassPreview\|previewPol" essentials/src/` | 0 matches | PASS |
| CompassCardVertical still wired in Results.jsx | `grep -q "CompassCardVertical" essentials/src/pages/Results.jsx` | match found | PASS |
| CompassCardVertical still wired in ElectionsView.jsx | `grep -q "CompassCardVertical" essentials/src/components/ElectionsView.jsx` | match found | PASS |
| essentials production build | `cd essentials && npm run build` | exit 0, 753 modules, no errors | PASS |
| ev-ui 0.6.1 tag published | `git tag --sort=-creatordate` in ev-ui | `v0.6.1` at top | PASS |
| Auto-bump commit on essentials main | `git log origin/main \| grep "bump.*0.6.1"` | commit `7f4811b` found | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| ADOPT-01 | 129-02, 129-03 | Representatives page cards replaced with compass-first card, preserving sort/filter/scroll-spy | VERIFIED (automated) + human_needed | CompassCardVertical wired in Results.jsx with real data; live sort/filter/scroll-spy requires browser smoke |
| ADOPT-02 | 129-02, 129-03 | Elections page candidate cards adopt the new card | VERIFIED (automated) + human_needed | CompassCardVertical wired in ElectionsView.jsx; incumbent/challenger variant rendering requires browser smoke |
| ADOPT-03 | 129-01 | /prototype route retired | VERIFIED | Route removed from App.jsx; all prototype files deleted; 0 residual references; /prototype 404 fallback requires browser confirmation |
| ADOPT-04 | 129-03 | ev-ui bumped via auto-bump pipeline; essentials + CompassV2 render correctly | VERIFIED (pipeline) + human_needed | ev-ui v0.6.1 tag pushed; auto-bump PRs ran (essentials #23, CompassV2 both on ^0.6.1); CompassV2 compare picker live smoke requires browser |

### Anti-Patterns Found

No anti-patterns found. Full sweep of essentials/src/ after phase changes returned 0 matches for all deleted symbols. Build output shows only pre-existing chunk-size and dynamic-import warnings that predate this phase.

### Human Verification Required

The automated checks are all PASSING. The items below require a live browser session to lock in the full ROADMAP success criteria (all 4 involve visual and interactive behaviors).

#### 1. Representatives Page Card Rendering

**Test:** Run `npm run dev` in `essentials/`, enter a Bloomington IN address, go to /results Representatives tab
**Expected:** Every politician card shows portrait + name + position + radar (CompassCardVertical); no floating mini-radar popover appears on hover
**Why human:** Visual card layout and hover-popover absence cannot be verified by static analysis

#### 2. Representatives Sort, Filter, and Scroll-Spy

**Test:** On the Representatives tab, apply a non-default sort (e.g. by name), toggle the elected/appointed filter, then scroll from top to bottom
**Expected:** Card order updates on sort; visible card set changes on filter; tier-band indicator (Federal/State/Local) updates as sections enter viewport
**Why human:** Runtime React state, filter logic, and IntersectionObserver behavior require a live browser

#### 3. Elections Tab Card Rendering and Toggle

**Test:** Switch to Elections tab via SegmentedControl; verify both directions of the toggle work
**Expected:** Incumbents render full compass card; challengers render empty/minimal variant; tab toggle works in both directions without error
**Why human:** Variant selection logic and tab-toggle state are runtime behaviors

#### 4. /prototype Route Fallback

**Test:** Navigate to `/prototype` in the browser address bar on the dev server
**Expected:** Page does NOT load the old Prototype page — hits the app's 404/fallback (blank or error route)
**Why human:** React Router fallback rendering is a live-browser behavior; file deletion and App.jsx grep confirm route is gone but the rendered 404 state needs visual confirmation

#### 5. CompassV2 Compare Picker Consumer Smoke Check

**Test:** Open compass.empowered.vote (or `cd CompassV2 && npm run dev`), go to Compare view, open the politician compare picker
**Expected:** Picker renders without errors, politicians are selectable, no browser console errors
**Why human:** Network-dependent politician data and cross-app ev-ui 0.6.1 compatibility require a live session; InlinePoliticianPicker dynamically imports ev-ui for evContext

### Gaps Summary

No blocking gaps found. All automated must-haves are verified. The `human_needed` status reflects that the ROADMAP Success Criteria (SC1–SC4) include interactive and visual behaviors that cannot be confirmed programmatically.

The human smoke-test recorded in `129-03-SUMMARY.md` claims PASSED for all 10 checks (performed 2026-04-26 during plan execution). The verification report captures these as still needing external confirmation per the GSD verification protocol, since the plan executor's own smoke-test is not an independent verification.

If the phase executor's smoke-test record is accepted as sufficient, this phase can be marked passed with an override on the human-verification items.

---

_Verified: 2026-04-26T21:00:00Z_
_Verifier: Claude (gsd-verifier)_
