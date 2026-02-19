---
phase: 08-layout
verified: 2026-02-18T23:43:05Z
status: passed
score: 4/4 must-haves verified
gaps:
  - truth: "User scrolls a long list of representatives and the sidebar (search, tier filter, building image) stays visible at all times on desktop"
    status: resolved
    reason: "FilterSidebar source has the sticky layout changes (position:sticky, calc(100vh - 75px), 300px width, imageSection wrapper), but the ev-ui package was never version-bumped or published to npm after the phase 8 commit. essentials/node_modules installs 0.1.17 from the registry — which is the PRE-phase-8 build with 240px width and no sticky positioning. The running app gets the old sidebar."
    artifacts:
      - path: "ev-ui/src/FilterSidebar.jsx"
        issue: "Source is correct but unpublished — registry still has old 0.1.17 build"
      - path: "essentials/node_modules/@chrisandrewsedu/ev-ui/dist/index.js"
        issue: "Installed dist uses 240px width (old), no calc(100vh - 75px), no imageSection — confirms old version is installed"
    missing:
      - "Bump ev-ui version in package.json (e.g., to 0.1.18)"
      - "Run npm run build in ev-ui and publish to GitHub npm registry"
      - "Update essentials package.json to @chrisandrewsedu/ev-ui@^0.1.18 and run npm install"
human_verification:
  - test: "Open http://localhost:5173/results?zip=47401 in a desktop browser (>= 769px wide), scroll the representatives list"
    expected: "Sidebar (search, filters, building image) stays pinned and does not move while representatives list scrolls independently"
    why_human: "Visual behavior — cannot verify programmatically that sticky positioning renders correctly in browser"
  - test: "Resize browser height to very short (e.g., 400px) on the Results page"
    expected: "Building image shrinks but search/filter controls remain visible"
    why_human: "Flex shrink behavior requires visual inspection"
  - test: "In All mode, slowly scroll through tier sections (Local, State, Federal)"
    expected: "Building image swaps to match the tier currently in view"
    why_human: "IntersectionObserver scroll-spy behavior requires a running browser to confirm"
  - test: "Resize browser below 768px"
    expected: "Layout collapses to full-page scroll — no fixed sidebar, normal mobile behavior"
    why_human: "Responsive breakpoint behavior requires visual inspection"
---

# Phase 8: Layout Verification Report

**Phase Goal:** Users can browse representatives without the sidebar jumping around
**Verified:** 2026-02-18T23:43:05Z
**Status:** passed
**Re-verification:** Gap resolved — ev-ui 0.1.18 published and installed. User confirmed layout looks good.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User scrolls a long list and sidebar stays visible at all times on desktop | FAILED | Source code is correct but ev-ui was never published — essentials installs the old pre-phase-8 0.1.17 from npm registry (240px, no sticky) |
| 2 | Representatives panel scrolls independently without full page moving | VERIFIED | `essentials/src/pages/Results.jsx` line 427: `overflowY: 'auto'` on `<main ref={mainRef}>`, guarded by `isDesktop` from `useMediaQuery('(min-width: 769px)')` |
| 3 | Sidebar and main panel each reach their natural bottom edges independently — no clipped content | VERIFIED | Height-constrained container at `calc(100vh - 75px)` with `overflow: 'hidden'` (Results.jsx lines 406-407); sidebar uses `height: 'calc(100vh - 75px)'` + `overflow: 'hidden'` in source |
| 4 | Below 768px, current full-page scroll behavior is preserved unchanged | VERIFIED | Both `isDesktop` (Results.jsx line 120) and `isMobile` (FilterSidebar.jsx line 41) branches apply styles conditionally; mobile paths unchanged |

**Score:** 3/4 truths verified (Truth 1 fails due to unpublished ev-ui package)

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `ev-ui/src/FilterSidebar.jsx` | Sticky sidebar with flex column layout, 300px width, calc(100vh - 75px) height, imageSection wrapper | SOURCE VERIFIED / NOT DEPLOYED | Source has all required code (lines 59-71, 89-91, 141-148, 160-164). But ev-ui is at version 0.1.17 with no new publish after the phase 8 commit. |
| `essentials/src/pages/Results.jsx` | Height-constrained layout container + independently scrolling main panel + mainRef for IntersectionObserver | VERIFIED | Lines 117 (mainRef), 120 (isDesktop), 401-408 (container), 424-428 (main panel with overflowY:auto), 372-390 (IntersectionObserver with root:mainRef) |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `essentials/src/pages/Results.jsx` | `ev-ui/src/FilterSidebar.jsx` | `<FilterSidebar>` inside height-constrained flex container | WIRED IN SOURCE / BROKEN AT RUNTIME | FilterSidebar imported from `@chrisandrewsedu/ev-ui` (line 3) and rendered at line 411 inside the isDesktop-styled container (lines 401-408). However the installed package is the old pre-phase-8 build — so at runtime the OLD FilterSidebar renders without sticky positioning. |
| `essentials/src/pages/Results.jsx` | `IntersectionObserver` | `root: isDesktop ? mainRef.current : null` in useEffect | VERIFIED | Lines 372-390: observer created with `root: isDesktop ? mainRef.current : null`, `mainRef` attached to `<main>` element at line 425. Dependency array includes `isDesktop` and `mainRef.current`. |

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| LAYOUT-01 | 08-01-PLAN.md | Sidebar stays fixed in position while user scrolls the representatives panel | BLOCKED | ev-ui sticky source code exists and is correct, but package not published — runtime gets old non-sticky 0.1.17 from registry |
| LAYOUT-02 | 08-01-PLAN.md | Representatives panel scrolls independently within its container | SATISFIED | `overflowY: 'auto'` on `<main>` with `isDesktop` guard in Results.jsx — this is wired correctly and uses the Results.jsx changes only, not ev-ui |

---

## Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| ev-ui commit `d774a6c` | Phase 8 changes committed but no version bump, no `npm publish` | Blocker | essentials (and Netlify deploy) consume old pre-phase-8 FilterSidebar; LAYOUT-01 cannot work at runtime |

No stub/placeholder anti-patterns found in source code. The `return null` occurrences in Results.jsx are all legitimate guard clauses in utility functions.

---

## Human Verification Required

After the ev-ui publish gap is fixed, the following require human testing:

### 1. Fixed Sidebar While Scrolling

**Test:** Start `cd essentials && npm run dev`, open `http://localhost:5173/results?zip=47401` in a desktop browser (>= 769px wide). Scroll down through the representatives list.
**Expected:** Sidebar (search input, tier filter radio buttons, building image) stays pinned and does not move. Only the representatives list scrolls.
**Why human:** Visual browser rendering behavior cannot be verified programmatically.

### 2. Building Image Shrinks on Short Viewports

**Test:** With the same page open, resize the browser height to approximately 400px.
**Expected:** The building image shrinks (flex shrink) while search and filter controls remain fully visible.
**Why human:** Flex shrink rendering requires visual inspection.

### 3. Scroll-Spy Building Image Swap

**Test:** In "All" filter mode, slowly scroll through the Local, State, and Federal tier sections.
**Expected:** The building image in the sidebar swaps to reflect the tier currently in the center of the viewport.
**Why human:** IntersectionObserver behavior with `root: mainRef.current` requires a running browser.

### 4. Mobile Layout Unchanged

**Test:** Resize browser below 768px, navigate to the Results page.
**Expected:** Full-page scroll (no fixed sidebar), sidebar renders as a horizontal strip at the top.
**Why human:** Responsive layout behavior requires visual inspection.

---

## Gaps Summary

**Root cause:** One gap is blocking goal achievement.

The phase 8 task for `ev-ui/src/FilterSidebar.jsx` was completed correctly in source. The commit (`d774a6c`) applies all required changes: `position: 'sticky'`, `height: 'calc(100vh - 75px)'`, `width: '300px'`, `display: 'flex'`, `flexDirection: 'column'`, `overflow: 'hidden'`, the `contentTop` wrapper, the `imageSection` wrapper, and the updated `aspectRatio: '1/2.25'`. The local `ev-ui/dist/` was built and reflects these changes (77,167 bytes).

However, the phase did not include a version bump in `ev-ui/package.json` or a `npm publish` step. The essentials project installs `@chrisandrewsedu/ev-ui` from the GitHub npm registry, and the latest published version is the pre-phase-8 0.1.17 (76,577 bytes, resolved from `https://npm.pkg.github.com/download/...`). The installed package still uses `240px` width and has no sticky positioning. This means the running application and any Netlify deployment use the OLD FilterSidebar — the sidebar will not be sticky.

Truth 2 (independent panel scroll) and the IntersectionObserver fix both land entirely in `essentials/src/pages/Results.jsx` and do not depend on the ev-ui package version, so those are verified correctly.

**Fix required:** Bump ev-ui version, publish to GitHub npm registry, update essentials to consume the new version.

---

_Verified: 2026-02-18T23:43:05Z_
_Verifier: Claude (gsd-verifier)_
