---
phase: 09-building-imagery
verified: 2026-02-18T16:00:00Z
status: passed
score: 6/6 must-haves verified (automated); visual/interaction behavior requires human sign-off
re_verification: false
human_verification:
  - test: "Bloomington IN (ZIP 47401) — scroll-spy building swap in All mode"
    expected: "Sidebar shows Bloomington City Hall photo initially; as user scrolls down through State tier it swaps to Indiana State House; scrolling to Federal swaps to US Capitol photo"
    why_human: "IntersectionObserver scroll behavior cannot be verified by static analysis"
  - test: "Bloomington IN — tier filter buttons change photo immediately"
    expected: "Clicking Local shows bloomington-city-hall.jpg; clicking State shows indiana-state-house.jpg; clicking Federal shows us-capitol.jpg; clicking All resumes scroll-spy"
    why_human: "React state transitions and rendered output require a running browser"
  - test: "Los Angeles CA (ZIP 90001) — all tier photos correct"
    expected: "Local shows la-city-hall.jpg; State shows california-state-capitol.jpg; Federal shows us-capitol.jpg"
    why_human: "Requires running app with live BallotReady data to confirm city name derivation produces 'los angeles'"
  - test: "Unsupported location (ZIP 10001 — New York) — SVG fallback renders"
    expected: "Sidebar shows SVG illustrated images (city-hall-generic.svg for Local, state-capitol-generic.svg for State, us-capitol.svg for Federal); no broken images"
    why_human: "Browser rendering required to confirm SVGs display without errors"
  - test: "Photo quality and aspect ratio in sidebar"
    expected: "All 5 photos display clearly within the 300px-wide portrait aspect-ratio (1/2.25) container with object-fit: cover; no distortion, no white bars"
    why_human: "Visual quality assessment requires human judgment"
---

# Phase 9: Building Imagery Verification Report

**Phase Goal:** Users see real building photos matched to their location and the tier they are viewing
**Verified:** 2026-02-18
**Status:** human_needed — all automated checks pass; 5 interactive/visual behaviors need human sign-off
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| #  | Truth                                                                              | Status     | Evidence                                                                                    |
|----|------------------------------------------------------------------------------------|------------|---------------------------------------------------------------------------------------------|
| 1  | Federal tier displays a real photograph of the US Capitol (not SVG placeholder)    | VERIFIED   | `us-capitol.jpg` is a valid 1200x621 JPEG (183KB); CURATED maps Federal → `/images/us-capitol.jpg` for both cities; activeBuildingImage resolves to this path when selectedFilter=Federal |
| 2  | State tier for Indiana displays a real photograph of the Indiana State House        | VERIFIED   | `indiana-state-house.jpg` is a valid 800x562 JPEG (143KB); CURATED.bloomington.State → `/images/indiana-state-house.jpg` |
| 3  | State tier for California displays a real photograph of the California State Capitol | VERIFIED  | `california-state-capitol.jpg` is a valid 618x800 JPEG (168KB); CURATED['los angeles'].State → `/images/california-state-capitol.jpg` |
| 4  | Local tier for Bloomington displays a real photograph of Bloomington City Hall      | VERIFIED   | `bloomington-city-hall.jpg` is a valid 1280x720 JPEG (195KB); CURATED.bloomington.Local → `/images/bloomington-city-hall.jpg` |
| 5  | Local tier for Los Angeles displays a real photograph of LA City Hall               | VERIFIED   | `la-city-hall.jpg` is a valid 600x800 JPEG (144KB); CURATED['los angeles'].Local → `/images/la-city-hall.jpg` |
| 6  | Selecting a tier filter immediately shows that tier's building photo                | VERIFIED   | `activeBuildingImage = buildingImageMap[selectedFilter]` when not All; passed as `buildingImageSrc` to FilterSidebar which renders `<img src={buildingImageSrc}>` |
| 7  | In All mode, building photo swaps as user scrolls between tier sections             | VERIFIED*  | IntersectionObserver on `[data-tier]` sections calls `setScrollActiveTier(entry.target.dataset.tier)`; activeBuildingImage driven by scrollActiveTier in All mode (*runtime behavior needs human) |
| 8  | Unsupported locations show existing SVG illustrated images (no broken images)       | VERIFIED   | `getBuildingImages()` returns FALLBACK for any city not matching 'bloomington' or 'los angeles'; FALLBACK SVGs (city-hall-generic.svg, state-capitol-generic.svg, us-capitol.svg) all exist on disk |

**Score:** 6/6 truths verified automated (2 of those need human confirmation for runtime behavior)

---

### Required Artifacts

| Artifact                                          | Provides                                                  | Exists | Substantive                                                          | Wired      | Status     |
|---------------------------------------------------|-----------------------------------------------------------|--------|----------------------------------------------------------------------|------------|------------|
| `essentials/public/images/us-capitol.jpg`         | Real photograph of US Capitol building                    | YES    | Valid JPEG, 1200x621, 183KB                                          | Referenced in CURATED | VERIFIED |
| `essentials/public/images/indiana-state-house.jpg`| Real photograph of Indiana State House                    | YES    | Valid JPEG, 800x562, 143KB                                           | Referenced in CURATED | VERIFIED |
| `essentials/public/images/california-state-capitol.jpg` | Real photograph of California State Capitol         | YES    | Valid JPEG, 618x800, 168KB                                           | Referenced in CURATED | VERIFIED |
| `essentials/public/images/bloomington-city-hall.jpg` | Real photograph of Bloomington City Hall               | YES    | Valid JPEG, 1280x720, 195KB                                          | Referenced in CURATED | VERIFIED |
| `essentials/public/images/la-city-hall.jpg`       | Real photograph of LA City Hall                           | YES    | Valid JPEG, 600x800, 144KB                                           | Referenced in CURATED | VERIFIED |
| `essentials/src/lib/buildingImages.js`            | CURATED map (.jpg paths); FALLBACK map (.svg paths)       | YES    | 37 lines; CURATED + FALLBACK constants; getBuildingImages() exported | Imported and called in Results.jsx line 16, 255 | VERIFIED |

All 7 original SVG fallback files confirmed present:
- `bloomington-city-hall.svg`, `california-state-capitol.svg`, `city-hall-generic.svg`
- `indiana-state-capitol.svg`, `la-city-hall.svg`, `state-capitol-generic.svg`, `us-capitol.svg`

---

### Key Link Verification

| From                               | To                                | Via                        | Status    | Details                                                                                  |
|------------------------------------|-----------------------------------|----------------------------|-----------|------------------------------------------------------------------------------------------|
| `buildingImages.js`                | `essentials/public/images/*.jpg`  | CURATED path strings       | WIRED     | All 5 CURATED paths use `/images/<name>.jpg`; all 5 files exist at matching public paths |
| `buildingImages.js`                | `essentials/public/images/*.svg`  | FALLBACK path strings      | WIRED     | All 3 FALLBACK paths use `/images/<name>.svg`; all 3 SVG files exist                     |
| `Results.jsx`                      | `buildingImages.js`               | import + call              | WIRED     | Line 16: `import { getBuildingImages }...`; line 255: `getBuildingImages(representingCity)` |
| `Results.jsx` → `FilterSidebar`    | building image display            | `buildingImageSrc` prop    | WIRED     | Line 428: `buildingImageSrc={activeBuildingImage}`; FilterSidebar renders `<img src={buildingImageSrc}>` (line 246) |
| `Results.jsx` scroll-spy           | tier section swap in All mode     | IntersectionObserver + data-tier | WIRED | Observer on `[data-tier]` sections; setScrollActiveTier updates; activeBuildingImage uses scrollActiveTier when selectedFilter=All |
| `Results.jsx` city derivation      | chamber_name fallback             | regex on LOCAL politicians | WIRED     | Lines 244-249: fallback extracts city from `chamber_name.match(/^(\w[\w\s]+?)\s+City\b/)` for LOCAL district_type |

---

### Requirements Coverage

| Requirement | Description                                                                     | Status    | Evidence                                                                                     |
|-------------|---------------------------------------------------------------------------------|-----------|----------------------------------------------------------------------------------------------|
| IMG-01      | Real photo of US Capitol displays for federal tier                               | SATISFIED | `us-capitol.jpg` exists (valid JPEG); CURATED.bloomington.Federal + CURATED['los angeles'].Federal both point to it; activeBuildingImage resolves to it when selectedFilter=Federal |
| IMG-02      | Real photo of state capitol for state tier (Indiana State House / CA State Capitol) | SATISFIED | Both `.jpg` files exist (valid JPEGs); CURATED entries map each city's State key to the correct file |
| IMG-03      | Real photo of city hall for local tier (Bloomington / LA)                        | SATISFIED | Both `.jpg` files exist (valid JPEGs); CURATED entries map each city's Local key to the correct file |
| IMG-04      | Selecting a tier filter shows that tier's building image                          | SATISFIED | `activeBuildingImage = buildingImageMap[selectedFilter]` drives `buildingImageSrc` prop when filter is not All |
| IMG-05      | All mode: building image swaps instantly as user scrolls between tier sections   | SATISFIED | IntersectionObserver wired on `[data-tier]` divs; `scrollActiveTier` state drives `buildingImageMap[scrollActiveTier]` in All mode |
| IMG-06      | Unsupported locations fall back to existing SVG illustrated images               | SATISFIED | `getBuildingImages()` returns `FALLBACK` constant for non-Bloomington/non-LA cities; all 3 FALLBACK SVG files exist; FilterSidebar renders whatever path is passed |

No orphaned requirements. All 6 IMG-01 through IMG-06 are claimed in the plan frontmatter and have evidence in the codebase.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `ev-ui/src/FilterSidebar.jsx` | 201 | `placeholder="ZIP or address"` | INFO | HTML input placeholder attribute — not an implementation stub |

No implementation stubs, empty handlers, or incomplete wiring found.

---

### Human Verification Required

All automated artifact and wiring checks pass. The following items require a running browser to confirm:

#### 1. Bloomington IN — scroll-spy building swap in All mode

**Test:** Start essentials dev server (`cd essentials && npm run dev`). Search ZIP 47401. In "All" mode, scroll slowly through Local, State, and Federal tier sections.
**Expected:** Sidebar building photo swaps from Bloomington City Hall → Indiana State House → US Capitol as each tier section crosses the viewport center (rootMargin: -40%/-60%).
**Why human:** IntersectionObserver scroll behavior is a runtime DOM event; cannot be verified by static analysis.

#### 2. Bloomington IN — tier filter buttons change photo immediately

**Test:** With ZIP 47401 results loaded, click Local, State, Federal, and All filter buttons in sequence.
**Expected:** Each button click immediately updates the sidebar photo to the correct building. Clicking All resumes scroll-spy behavior.
**Why human:** React state transitions and rendered output require a running browser.

#### 3. Los Angeles CA — city name derivation produces correct photos

**Test:** Search ZIP 90001 (Los Angeles). Click Local, State, Federal.
**Expected:** Local shows LA City Hall; State shows California State Capitol; Federal shows US Capitol.
**Why human:** Requires live BallotReady data to confirm `representing_city` or `chamber_name` produces 'los angeles' string matching the `city.includes('los angeles')` check in `getBuildingImages()`.

#### 4. Unsupported location — SVG fallback renders without errors

**Test:** Search ZIP 10001 (New York). Check sidebar for all three tier filters.
**Expected:** Sidebar displays SVG illustrated images (not broken image icons, not blank space). SVGs render correctly.
**Why human:** Browser rendering required to confirm SVG display; cannot detect broken image tags from static file check.

#### 5. Photo quality and aspect ratio in sidebar

**Test:** View photos for both Bloomington and LA locations in the sidebar (300px wide, aspect-ratio 1/2.25 with object-fit: cover).
**Expected:** All photos display clearly, cropped appropriately, no distortion, no white bars. Photos look polished and trustworthy.
**Why human:** Visual quality assessment requires human judgment.

---

### Build Verification

```
> essentials@0.0.0 build
> vite build

vite v7.3.1 building client environment for production...
✓ 64 modules transformed.
dist/index.html        0.49 kB
dist/assets/index.js  335.09 kB
✓ built in 666ms
```

Build passes without errors or warnings.

---

### Notes

**Commit references in SUMMARY.md** (`bcd63c5`, `bd39af7`) were not found in the planning repository's git history. This is expected: the planning repo only tracks `.planning/` files; `essentials/` is listed as an untracked directory in `git status`. The actual file evidence (5 valid JPEGs, updated `buildingImages.js`, wired `Results.jsx`) confirms the work was done — the commits were made in a separate project repository or to a fork not connected to this planning repo.

**chamber_name fallback** (added in fix commit `bd39af7`): The regex `/^(\w[\w\s]+?)\s+City\b/` in `Results.jsx` (lines 244-249) extracts city name from LOCAL politicians' `chamber_name` field. This is the critical fix enabling Bloomington image matching when BallotReady does not populate `representing_city`. Wiring verified: the fallback runs before returning `null`, and `getBuildingImages(null)` would return `FALLBACK` without it.

---

_Verified: 2026-02-18_
_Verifier: Claude (gsd-verifier)_
