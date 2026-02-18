# Phase 5: Essentials Improvements - Research

**Researched:** 2026-02-18
**Domain:** React frontend display enhancements (politician cards, candidates, building imagery, scroll-spy, federal ordering)
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Candidate toggle & integration**
- Toggle switch (on/off) labeled "Show Candidates" — not tabs
- Toggle placement is subtle/secondary — doesn't compete with main results
- Default state: off (officials only)
- When toggled on, candidate cards appear **inline alongside** officials within the same tier categories (e.g., a Senate candidate sits next to current U.S. Senators in the Federal section)
- No separate "Candidates" section — they mix into existing tier structure

**Candidate card design**
- Corner badge saying "Candidate" in EV coral (#ff5740) — the primary visual differentiator
- Card layout otherwise matches official cards
- Show profile photo if available (same treatment as officials)
- Additional info on candidate cards: **election date + race name** (e.g., "Nov 2026 — U.S. Senate")

**Building imagery**
- Real photographs in **tall/portrait orientation** in the left sidebar, below the tier radio buttons (matching current Bloomington screenshot layout)
- **Scroll-spy behavior on "All" filter**: image defaults to local building, then transitions to state capitol as user scrolls to state officials, then to U.S. Capitol for federal section
- When a specific tier filter is selected (Local/State/Federal), show that tier's building image statically
- **Match to user's searched location**: show the actual buildings for their city, their state capitol, and U.S. Capitol
- MVP localities with curated images: **Bloomington, IN (Monroe County)** and **Los Angeles, CA (Los Angeles County)**
- All other localities get a generic fallback image per tier

**Position term dates**
- Format: **Month Year — Month Year** (e.g., "Jan 2023 — Dec 2026")
- Placement: directly below the politician's title/role on the card
- **Show actual term end date, not "Present"** — users should see when the elected term expires and reelection is needed
- If date data is unavailable: **hide the date line entirely** (no placeholder text)

**Federal category ordering**
- Exact order: U.S. Senate > U.S. House > President/VP > Cabinet > Agencies
- Legislative branch first, then executive branch

### Claude's Discretion
- Scroll-spy implementation approach (IntersectionObserver vs scroll events)
- Toggle switch styling details (size, exact placement in sidebar)
- Candidate badge exact positioning and sizing within card corner
- Fallback building image selection for non-curated localities
- Image transition animation between buildings during scroll
- How to source/store building images (Supabase Storage bucket structure)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| ESST-01 | Candidates appear in Essentials results with opt-in toggle (default: officials only) | BallotReady `races` query with location + date filter; new backend endpoint `/essentials/candidates/{zip}` needed; candidate data stored in `election_records` table |
| ESST-02 | Candidates visually differentiated from elected officials via badge or label | `PoliticianCard` in ev-ui needs a `badge` prop or wrapper; candidate flag field needed on response shape |
| ESST-03 | Election date shown on candidate cards | `election_date` and `election_name` fields available from `ElectionRecord` model; need to surface them in candidate response |
| ESST-04 | Building images shown for federal/state/local sections | `FilterSidebar` already accepts `buildingImageSrc` prop; scroll-spy needed for "All" filter; images must be sourced and served; curated for Bloomington IN and LA CA |
| ESST-05 | Federal section reordered — U.S. Senate and U.S. House before executive branch | `FEDERAL_ORDER` array in `classify.js` requires reordering; change is one-line in a constant |
| ESST-06 | Position start date and end date shown on politician profile card | `valid_from`/`valid_to` fields exist in DB (from BallotReady `startAt`/`endAt`) but are NOT in `OfficialOut` DTO; backend needs to expose them; frontend card needs term date line |
</phase_requirements>

---

## Summary

Phase 5 adds five display enhancements to the `essentials` app: a candidates toggle, candidate card badging, building imagery with scroll-spy, federal section reordering, and term dates on cards. All work is frontend-heavy, with one significant backend addition (candidate query endpoint) and one small backend addition (expose `valid_from`/`valid_to` in `OfficialOut`).

The **active production UI is `Results.jsx`** (not `Dashboard.jsx`). `Results.jsx` uses the `ev-ui` design system components: `FilterSidebar`, `PoliticianCard`, `CategorySection`. Building images are already plumbed into `FilterSidebar` via the `buildingImageSrc` prop — the prop exists but the images referenced in `Results.jsx` (`/images/us-landmarks.jpg`, `/images/state-capitol.jpg`, `/images/city-hall.jpg`) need to exist in the `public/images/` directory. Currently, the `public/` directory only has `EVLogo.svg` and `vite.svg`.

The **candidate data path** is the biggest new work. BallotReady exposes a `races` top-level query (not `officeHolders`) that accepts a `location: { zip: $zip }` filter and a `filterBy: { electionDay: { gte: "today" } }` filter. Each race contains `candidacies` with `candidate` (a `Person` object) and `position`. This requires a new GraphQL query, new Go types, a new backend endpoint `/essentials/candidates/{zip}`, and frontend state management for the toggle. The key concern flagged in planning notes is that district-to-ZIP mapping for candidates differs from the officeholder path — the `races` query uses position-level geography, not `officeHolders`.

**Term dates** (ESST-06): The `valid_from`/`valid_to` fields from BallotReady's `startAt`/`endAt` are already stored in the `essentials.politicians` table and populated via upserts in all three warm functions. However, `OfficialOut` does not include them. The fix is: add `TermStart`/`TermEnd` string fields to `OfficialOut`, populate them in all `fetchOfficialsFromDB`/`fetchFederalAndStateFromDBFiltered`/`normalizedToOfficialOut` functions, then render conditionally in the frontend card.

**Primary recommendation:** Work in this order: (1) ESST-05 federal reorder (trivial, 5 min), (2) ESST-06 term dates (backend DTO + frontend card), (3) ESST-04 building images (source assets + scroll-spy), (4) ESST-01/02/03 candidate toggle (largest, requires new backend endpoint).

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React | 19.1.1 | UI rendering | Already in essentials app |
| Tailwind CSS | 4.1.12 | Styling (Dashboard.jsx still uses Tailwind) | Already configured |
| @chrisandrewsedu/ev-ui | 0.1.16 | Design system components (PoliticianCard, FilterSidebar, CategorySection) | All production UI uses this |
| react-router-dom | 7.8.2 | Routing, useSearchParams | Already in use |
| Go 1.24.3 + Chi | current | Backend API | Already in use |
| GORM + PostgreSQL | current | Database ORM | Already in use |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| IntersectionObserver (native) | Browser API | Scroll-spy for building image transitions | Discretion item — no library needed |
| @react-spring/web | 10.0.2 | Smooth image cross-fade animation | Already in essentials package.json; use for building image transition |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| IntersectionObserver | scroll event listeners | IntersectionObserver is declarative, performant, and avoids scroll jank — preferred |
| CSS transition for image swap | @react-spring/web | CSS transition is sufficient for a simple opacity crossfade; react-spring only if animated transition is desired |

**Installation:** No new packages needed. All required libraries are already installed.

---

## Architecture Patterns

### Recommended Project Structure
```
essentials/src/
├── pages/
│   └── Results.jsx       # PRIMARY production UI — add toggle + scroll-spy here
├── lib/
│   ├── classify.js       # FEDERAL_ORDER fix goes here (ESST-05)
│   └── api.jsx           # Add fetchCandidates() function (ESST-01)
├── components/
│   └── CandidateBadge.jsx  # Optional thin wrapper (or inline in Results.jsx)
└── public/images/        # Building images go here (must create directory)

ev-ui/src/
└── PoliticianCard.jsx    # May need badge prop added (ESST-02)

EV-Backend/internal/essentials/
├── handlers.go           # Add valid_from/valid_to to OfficialOut + add GetCandidatesByZip
├── routes.go             # Register /candidates/{zip}
└── ballotready/
    ├── client.go         # Add racesQuery + FetchRacesByZip()
    ├── types.go          # Add Race/Candidacy/CandidateOut types (may partially exist)
    └── transform.go      # Transform race candidacies to OfficialOut-like shape
```

### Pattern 1: Federal Order Fix (ESST-05)
**What:** Reorder the `FEDERAL_ORDER` constant in `classify.js`
**When to use:** Immediate — one-line change, no risk
**Current order:** `["President / VP", "U.S. Senate", "U.S. House", "Cabinet", "Independent Agencies & Commissions", "Executive (Other)"]`
**New order:** `["U.S. Senate", "U.S. House", "President / VP", "Cabinet", "Independent Agencies & Commissions", "Executive (Other)"]`
**File:** `/Users/chrisandrews/Documents/GitHub/essentials/src/lib/classify.js` line 8

```javascript
// Source: classify.js line 8 — change from:
export const FEDERAL_ORDER = [
  "President / VP",
  "U.S. Senate",
  "U.S. House",
  // ...
];
// To:
export const FEDERAL_ORDER = [
  "U.S. Senate",
  "U.S. House",
  "President / VP",
  "Cabinet",
  "Independent Agencies & Commissions",
  "Executive (Other)",
];
```

### Pattern 2: Term Dates Backend (ESST-06)
**What:** Add `TermStart`/`TermEnd` to `OfficialOut` DTO and populate from DB
**When to use:** After ESST-05

The `valid_from` / `valid_to` columns already exist in `essentials.politicians` (stored as strings from BallotReady `startAt`/`endAt`). They are populated in all three warm paths. They are NOT in `OfficialOut` and NOT in any SQL SELECT.

Backend changes needed:
1. Add to `OfficialOut` struct in `handlers.go`:
```go
TermStart string `json:"term_start,omitempty"`
TermEnd   string `json:"term_end,omitempty"`
```
2. Add to raw SQL `row` struct in `fetchOfficialsFromDB` (line ~2095):
```go
ValidFrom string
ValidTo   string
```
3. Add to SELECT query: `p.valid_from, p.valid_to`
4. Populate in the `OfficialOut{...}` construction: `TermStart: r.ValidFrom, TermEnd: r.ValidTo`
5. Same changes for `fetchFederalAndStateFromDBFiltered` (line ~2379) and `GetPoliticianByID` (line ~3032) and `normalizedToOfficialOut` (line ~2672)
6. `normalizedToOfficialOut` can read from `provider.NormalizedOfficial.ValidFrom` / `.ValidTo` (already in the struct at provider/types.go line 25-26)

Frontend changes (in `Results.jsx`, after receiving `term_start`/`term_end`):
```jsx
// Format: "Jan 2023 — Dec 2026"
function formatTermDate(dateStr) {
  if (!dateStr) return null;
  const d = new Date(dateStr);
  if (isNaN(d)) return null;
  return d.toLocaleDateString('en-US', { month: 'short', year: 'numeric' });
}

// In PoliticianCard or alongside it:
const termLine = pol.term_start
  ? `${formatTermDate(pol.term_start)} — ${formatTermDate(pol.term_end) || '?'}`
  : null;
```

The `PoliticianCard` in ev-ui currently accepts `name` and `title` props only. The term date needs to appear below the title. Options:
- **Option A (preferred):** Add `subtitle` prop to `PoliticianCard` in ev-ui for the term date line
- **Option B:** Pass term date as part of `title` (string concatenation) — simpler but messy
- **Option C:** Wrap PoliticianCard with additional DOM below it — hard to style cleanly

Option A requires rebuilding and republishing ev-ui (version bump to 0.1.17) before it can be used in essentials.

### Pattern 3: Building Images + Scroll-Spy (ESST-04)
**What:** Static images per tier when filter is selected; scroll-spy image swap when filter is "All"
**When to use:** After term dates

`FilterSidebar` already accepts `buildingImageSrc` (a string URL). It renders an `<img>` with `aspectRatio: '4/5'` (portrait). Images should be placed in `essentials/public/images/`.

**Image serving approach:** Place static images in the essentials `public/images/` directory. They are served as static assets by Vite. No Supabase Storage needed for MVP.

**Curated image mapping:**
```javascript
// In Results.jsx or a new lib/buildingImages.js
const BUILDING_IMAGES = {
  bloomington: {
    local: '/images/bloomington-city-hall.jpg',
    state: '/images/indiana-state-capitol.jpg',
    federal: '/images/us-capitol.jpg',
  },
  'los angeles': {
    local: '/images/la-city-hall.jpg',
    state: '/images/california-state-capitol.jpg',
    federal: '/images/us-capitol.jpg',
  },
  fallback: {
    local: '/images/city-hall-generic.jpg',
    state: '/images/state-capitol-generic.jpg',
    federal: '/images/us-capitol.jpg',
  },
};

function getBuildingImages(representingCity, representingState) {
  const city = (representingCity || '').toLowerCase();
  if (city.includes('bloomington')) return BUILDING_IMAGES.bloomington;
  if (city.includes('los angeles')) return BUILDING_IMAGES['los angeles'];
  return BUILDING_IMAGES.fallback;
}
```

**Scroll-spy with IntersectionObserver:** When `selectedFilter === 'All'`, attach refs to the tier section header elements (Local, State, Federal divs). Use `IntersectionObserver` with `threshold: 0` and `rootMargin` to detect which tier is currently in view.

```javascript
// Source: MDN IntersectionObserver - HIGH confidence browser API
useEffect(() => {
  if (selectedFilter !== 'All') return;

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          setActiveTier(entry.target.dataset.tier);
        }
      });
    },
    { rootMargin: '-40% 0px -60% 0px', threshold: 0 }
  );

  const sections = document.querySelectorAll('[data-tier]');
  sections.forEach((el) => observer.observe(el));
  return () => observer.disconnect();
}, [selectedFilter]);
```

The `rootMargin: '-40% 0px -60% 0px'` fires when the section header crosses the middle 20% of the viewport — a standard scroll-spy pattern for navigation highlighting.

**Image transition:** Use CSS `transition: opacity 0.4s ease` on a wrapper that crossfades between images. Alternatively, use react-spring `useSpring` for a smoother animated crossfade (package already installed in essentials).

### Pattern 4: Candidate Toggle + Data (ESST-01/02/03)
**What:** New backend endpoint fetching candidates via BallotReady `races` query; frontend toggle state; candidate cards mixed inline
**When to use:** After all other features, as it requires new backend + API

**Backend: New GraphQL query**

The BallotReady `races` query accepts `location: { zip: $zip }` and `filterBy: { electionDay: { gte: "YYYY-MM-DD" } }`. Each race returns `candidacies` which contain `candidate` (a `Person`) and `position` (a `Position`). This is a completely different query path from `officeHolders`.

```graphql
# Source: CivicEngine GraphQL API Documentation.md (in workspace)
query RacesByZip($zip: String!, $electionDayGte: String!) {
  races(
    location: { zip: $zip }
    filterBy: { electionDay: { gte: $electionDayGte } }
    orderBy: { field: ELECTION_DAY, direction: ASC }
    first: 50
  ) {
    nodes {
      id
      databaseId
      isPrimary
      isRunoff
      position {
        id
        databaseId
        name
        level
        state
        judicial
        appointed
      }
      election {
        id
        name
        date
      }
      candidacies(includeUncertified: false) {
        id
        databaseId
        isCertified
        withdrawn
        parties { name shortName }
        candidate {
          id
          firstName
          middleName
          lastName
          nickname
          fullName
          images { url type }
        }
      }
    }
    pageInfo { hasNextPage endCursor }
  }
}
```

**Key note from CivicEngine docs:** The `races` query top-level filter (`electionDay`) filters races but NOT the nested `election` object dates. Use `races` as the top-level query (not `elections`) for location-based candidate lookup.

**Backend: New response type**

```go
type CandidateOut struct {
  ID            uuid.UUID  `json:"id"`          // Will be empty uuid if not in DB
  ExternalID    int        `json:"external_id"`  // BallotReady databaseId
  FirstName     string     `json:"first_name"`
  LastName      string     `json:"last_name"`
  PhotoOriginURL string    `json:"photo_origin_url"`
  OfficeTitle   string     `json:"office_title"`   // Position name
  DistrictType  string     `json:"district_type"`  // From position level
  Party         string     `json:"party"`
  IsCandidate   bool       `json:"is_candidate"`   // Always true
  ElectionDate  string     `json:"election_date"`  // e.g., "2026-11-03"
  ElectionName  string     `json:"election_name"`  // e.g., "Illinois General Election"
  IsPrimary     bool       `json:"is_primary"`
  IsRunoff      bool       `json:"is_runoff"`
  // Fields for classify.js to work
  RepresentingState string `json:"representing_state"`
  ChamberName       string `json:"chamber_name"`
  ChamberNameFormal string `json:"chamber_name_formal"`
  GovernmentName    string `json:"government_name"`
}
```

**CRITICAL: District-to-ZIP mapping for candidates differs from officeholders.** The `races` query uses position-level geographic filtering. It does NOT use `zip_politicians` junction table. Candidates are not yet in the `politicians` table. The backend must call BallotReady live (or cache with short TTL) and return real-time candidate data.

**Backend: New endpoint**

`GET /essentials/candidates/{zip}` — calls BallotReady `races` query with today's date as `electionDayGte`, transforms results into a flat list of `CandidateOut` objects (one per candidacy), and returns JSON.

**Frontend: Toggle state management**

Add `showCandidates` boolean state in `Results.jsx`. When true, also fetch from `/essentials/candidates/{zip}` and merge into the display. Candidate objects need `is_candidate: true` field so `classify.js` and card rendering can distinguish them.

**Frontend: Classify candidates**

Candidate objects from the API can use the same `classifyCategory()` function if `district_type` is populated from position level. Map BallotReady position level to district type:
- `level: "FEDERAL"` → use position name to infer `NATIONAL_UPPER` / `NATIONAL_LOWER` / `NATIONAL_EXEC`
- `level: "STATE"` → `STATE_UPPER` / `STATE_LOWER` / `STATE_EXEC`
- `level: "LOCAL"` → `LOCAL` / `COUNTY` / `SCHOOL`

**Frontend: Candidate badge (ESST-02)**

The `PoliticianCard` in ev-ui does not have a badge prop. Options:
- **Option A (recommended):** Add `badge` prop to ev-ui `PoliticianCard` — renders an absolute-positioned coral pill in the top-right corner. Requires ev-ui version bump.
- **Option B:** Wrap `PoliticianCard` in `Results.jsx` with a relative-position container and render the badge as a sibling element using Tailwind absolute positioning. No ev-ui change needed.

Option B is faster but creates a visual mismatch risk if ev-ui card overflow:hidden clips the badge. Given that `ev-ui/src/PoliticianCard.jsx` sets `overflow: 'hidden'` on the card — an absolute-positioned child INSIDE the card would be clipped. The badge must be outside the card or implemented via the `badge` prop pattern.

**Recommended:** Add `badge` prop to ev-ui `PoliticianCard`. When truthy, renders a small absolute-positioned pill before the image. Publish as 0.1.17.

### Anti-Patterns to Avoid
- **Fetching candidates on page load:** The toggle is off by default. Never fetch candidates until the toggle is turned on.
- **Sorting candidates with `valid_from`/`valid_to`:** Candidates don't have term dates — they have election dates. The term date display applies only to current officeholders.
- **Using `Dashboard.jsx` for new features:** The active production page is `Results.jsx`. `Dashboard.jsx` appears to be an older/simpler version. Confirm with the developer which page is the one users land on.
- **Mixing candidate and official sort keys:** Candidates should appear after officials within the same category section (officials first, candidates after).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Scroll-spy | Custom scroll event throttler | Native `IntersectionObserver` | Built into browsers, no layout thrash, handles resize correctly |
| Image crossfade animation | Keyframe CSS manually | CSS `transition: opacity` or `@react-spring/web useSpring` | Already available, well-tested |
| Date formatting | Custom month/year formatter | `Date.toLocaleDateString` with `{month: 'short', year: 'numeric'}` | Built into browser, handles locale |
| BallotReady race pagination | Manual cursor tracking | Follow same pagination pattern as `FetchOfficeHoldersByZip` in `ballotready/client.go` | Pattern already established in codebase |

**Key insight:** All the hard parts (BallotReady pagination, GORM upserts, Chi routing, ZIP-to-state mapping) already have working implementations in the codebase. Follow existing patterns exactly.

---

## Common Pitfalls

### Pitfall 1: `valid_from`/`valid_to` Not in OfficialOut SQL
**What goes wrong:** Even though the fields exist in `essentials.politicians`, the SQL SELECT in `fetchOfficialsFromDB` uses a manual `type row struct{}` and explicit column list — the fields are NOT selected or mapped.
**Why it happens:** The raw SQL approach (not GORM model scan) requires explicit column selection. New fields on the model are not automatically included.
**How to avoid:** Add `p.valid_from, p.valid_to` to BOTH raw SQL queries in `fetchOfficialsFromDB` AND `fetchFederalAndStateFromDBFiltered`. Also update the `row` struct definition in each function scope.
**Warning signs:** Term dates showing as empty strings despite data being in the DB.

### Pitfall 2: Building Images Not Found
**What goes wrong:** `Results.jsx` references `/images/us-landmarks.jpg` etc. but the `public/images/` directory doesn't exist yet — currently `public/` only has `EVLogo.svg` and `vite.svg`. The img tag silently fails.
**Why it happens:** Nobody has added the image assets yet.
**How to avoid:** Create `essentials/public/images/` and populate it before wiring up the image paths. Test locally with `npm run dev` to verify images load.

### Pitfall 3: PoliticianCard Badge Clipped by overflow:hidden
**What goes wrong:** Adding a badge as an absolute-positioned child inside ev-ui `PoliticianCard` gets clipped because the card sets `overflow: 'hidden'`.
**Why it happens:** The inline `overflow: 'hidden'` at line 47 in `PoliticianCard.jsx` clips absolutely-positioned children.
**How to avoid:** Add `badge` prop to `PoliticianCard` internally (so the badge is rendered inside the card's position:relative context, which handles overflow). Or render the badge wrapper outside the PoliticianCard component with a wrapping div.

### Pitfall 4: Candidates from races Query Include Past Elections
**What goes wrong:** BallotReady `races` query returns ALL races matching the location, including past ones, unless filtered by date.
**Why it happens:** The `electionDay: { gte: "today" }` filter must use the current date dynamically.
**How to avoid:** Compute today's date server-side in Go (not hardcoded). Use `time.Now().Format("2006-01-02")` for the `electionDayGte` variable.

### Pitfall 5: Scroll-Spy Fires Too Eagerly
**What goes wrong:** The IntersectionObserver fires before the user has scrolled into the section, making the building image swap at wrong times.
**Why it happens:** Default `rootMargin: '0px'` fires exactly when the element hits the viewport edge.
**How to avoid:** Use `rootMargin: '-40% 0px -60% 0px'` — fires when the element is in the middle 20% of the viewport, matching where the user's eye is.

### Pitfall 6: Candidates Not Classifiable by classifyCategory
**What goes wrong:** `classifyCategory()` uses `pol.district_type` which won't be populated on candidate objects if the BallotReady `races` response doesn't map position level to district type.
**Why it happens:** `races` returns `position.level` ("FEDERAL", "STATE", "LOCAL") not the internal `NATIONAL_UPPER` etc. format.
**How to avoid:** Create a `levelToDistrictType(position)` mapping function in the API transform layer that maps BallotReady position name + level to the internal district type enum. Use `position.name` keywords (e.g., "Senate" → `NATIONAL_UPPER`) as hints.

### Pitfall 7: ev-ui Version Mismatch
**What goes wrong:** Changes to ev-ui `PoliticianCard` for badge support require a version bump and republish. The essentials app's `package.json` specifies `^0.1.14` (or current `0.1.16`) which will auto-resolve to the new version — but the Netlify CI build needs the NPM_TOKEN to pull from GitHub packages registry.
**Why it happens:** ev-ui is published to GitHub npm registry, not npm public registry.
**How to avoid:** After bumping ev-ui version, run `npm run build` in `ev-ui`, publish, then `npm install @chrisandrewsedu/ev-ui@0.1.17` in essentials. Verify `.npmrc` in essentials contains `//npm.pkg.github.com/:_authToken=${NPM_TOKEN}` (it does — see MEMORY.md).

---

## Code Examples

Verified patterns from existing codebase:

### Add new field to OfficialOut (backend)
```go
// Source: EV-Backend/internal/essentials/handlers.go OfficialOut struct (line 112)
// Add alongside existing fields:
type OfficialOut struct {
  // ... existing fields ...
  TermStart string `json:"term_start,omitempty"` // new
  TermEnd   string `json:"term_end,omitempty"`   // new
}

// In raw SQL row struct:
type row struct {
  // ... existing fields ...
  ValidFrom string
  ValidTo   string
}

// In SELECT:
// Add: p.valid_from, p.valid_to

// In OfficialOut construction:
OfficialOut{
  // ... existing fields ...
  TermStart: r.ValidFrom,
  TermEnd:   r.ValidTo,
}
```

### BallotReady races query (new, based on docs + existing client pattern)
```go
// Source: Based on CivicEngine API documentation and existing officeHoldersByZipQuery pattern
const racesByZipQuery = `
query RacesByZip($zip: String!, $electionDayGte: String!, $first: Int!, $after: String) {
  races(
    location: { zip: $zip }
    filterBy: { electionDay: { gte: $electionDayGte } }
    orderBy: { field: ELECTION_DAY, direction: ASC }
    first: $first
    after: $after
  ) {
    nodes {
      id
      databaseId
      isPrimary
      isRunoff
      position {
        id
        databaseId
        name
        level
        state
        judicial
        appointed
      }
      election {
        id
        name
        date
      }
      candidacies(includeUncertified: false) {
        id
        databaseId
        isCertified
        withdrawn
        parties { name shortName }
        candidate {
          id
          firstName
          middleName
          lastName
          nickname
          fullName
          images { url type }
        }
      }
    }
    pageInfo { hasNextPage endCursor }
  }
}
`
```

### Frontend toggle state pattern
```jsx
// Source: Results.jsx pattern (existing toggle approach in Profile.jsx)
const [showCandidates, setShowCandidates] = useState(false);

// Fetch candidates when toggled on
const { data: candidateData } = useCandidateData(activeQuery, {
  enabled: showCandidates && !!activeQuery,
});

// Toggle UI (subtle, secondary placement)
<label style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '14px', color: '#718096' }}>
  <input
    type="checkbox"
    checked={showCandidates}
    onChange={(e) => setShowCandidates(e.target.checked)}
  />
  Show Candidates
</label>
```

### Scroll-spy with IntersectionObserver
```jsx
// Source: MDN IntersectionObserver API (browser native)
const [scrollActiveTier, setScrollActiveTier] = useState('Local');

useEffect(() => {
  if (selectedFilter !== 'All') return;
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          setScrollActiveTier(entry.target.dataset.tier);
        }
      });
    },
    { rootMargin: '-40% 0px -60% 0px', threshold: 0 }
  );
  document.querySelectorAll('[data-tier]').forEach((el) => observer.observe(el));
  return () => observer.disconnect();
}, [selectedFilter]);

// Derive building image
const activeTier = selectedFilter === 'All' ? scrollActiveTier : selectedFilter;
const buildingImageSrc = buildingImages[activeTier];

// In JSX, mark tier sections:
<div data-tier="Local">...</div>
<div data-tier="State">...</div>
<div data-tier="Federal">...</div>
```

### Term date format
```javascript
// Source: MDN Date.toLocaleDateString
function formatTermDate(dateStr) {
  if (!dateStr) return null;
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return null;
  return d.toLocaleDateString('en-US', { month: 'short', year: 'numeric' });
}

// Usage:
const termStart = formatTermDate(pol.term_start); // "Jan 2023"
const termEnd = formatTermDate(pol.term_end);     // "Dec 2026"
const termLine = termStart ? `${termStart} — ${termEnd || '?'}` : null;
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Dashboard.jsx` (Tailwind, simple tabs) | `Results.jsx` (ev-ui components, FilterSidebar, radio filter) | Phase 4 | Results.jsx is the production page; Dashboard.jsx may be retired or kept as legacy |
| Building images hardcoded as full URL strings | `buildingImageSrc` prop on FilterSidebar | Phase 4 | Images from public/ directory, not external URLs |
| No candidate data | `election_records` table + candidacy lazy-fetch per politician | Phase B | Records exist per politician, but there is no ZIP-level candidate query yet |
| `valid_from`/`valid_to` stored but not exposed | Not yet in API | Today | Backend addition needed |

**Deprecated/outdated:**
- `LocationCard.jsx`: Legacy component with hardcoded image URL — not used in production
- `Dashboard.jsx`: May be superseded by `Results.jsx`; clarify with developer before touching it

---

## Open Questions

1. **Which page is the production target: Results.jsx or Dashboard.jsx?**
   - What we know: `Results.jsx` uses ev-ui components and is registered at `/results` route; `Dashboard.jsx` is at `/dashboard`. The App.jsx route configuration shows both exist.
   - What's unclear: Which URL do users actually land on from the main site? If it's `/dashboard`, all the ev-ui component work targeting `Results.jsx` is in the wrong file.
   - Recommendation: Confirm with developer before writing any code. The CONTEXT.md references a "Bloomington screenshot layout" that suggests `Results.jsx` with `FilterSidebar` is the target (since FilterSidebar is the sidebar component with radio buttons and portrait building image).

2. **Does the EV contract with BallotReady include the `races` query for candidates?**
   - What we know: CivicEngine docs say "Depending on contract we might already filter some data" and "your contract might be limited to candidate data and exclude officeholder data." Currently the codebase only uses `officeHolders` — no `races` query exists.
   - What's unclear: Whether the API key has access to `races` + `candidacies`. Must be validated before building the backend.
   - Recommendation: Test the `races` query against the BallotReady API with the existing API key before implementing the full backend endpoint.

3. **Does BallotReady `races` query support `location: { zip: $zip }`?**
   - What we know: The `races` query signature in the CivicEngine docs shows `location: LocationFilter` as an argument. The `LocationFilter` input includes a `zip` field (confirmed at doc line 3141). The `officeHolders` query uses the same `LocationFilter`.
   - What's unclear: Whether the zip filter on `races` has the same geographic expansion behavior as on `officeHolders` (i.e., does it expand from ZIP to county to state for higher-level races?).
   - Recommendation: Test empirically with a known ZIP before relying on it.

4. **What is the actual date format of `valid_from`/`valid_to` stored in the DB?**
   - What we know: BallotReady `startAt`/`endAt` are ISO8601 strings. They are stored in `essentials.politicians.valid_from` / `valid_to` as Go `string` type (not `time.Time`). The format depends on what BallotReady sends.
   - What's unclear: Whether BallotReady consistently sends `"2023-01-10"` (date-only) or `"2023-01-10T00:00:00Z"` (full datetime). The date formatter needs to handle both.
   - Recommendation: Check actual DB values before writing the frontend date formatter. Use `new Date(dateStr)` which handles both formats.

5. **Which localities are the "Bloomington" and "Los Angeles" target demos?**
   - What we know: CONTEXT.md says "Bloomington, IN (Monroe County)" and "Los Angeles, CA (Los Angeles County)". The city match for building images should key off `representing_city` from the politician data.
   - What's unclear: Whether `representing_city` from BallotReady data is "Bloomington" exactly or might vary (e.g., "City of Bloomington").
   - Recommendation: Check actual `representing_city` values in the DB for a Bloomington, IN ZIP code (47401) to confirm the exact string to match against.

---

## Sources

### Primary (HIGH confidence)
- Codebase: `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/handlers.go` — OfficialOut struct, fetchOfficialsFromDB, all handler patterns
- Codebase: `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/ballotready/client.go` — BallotReady query patterns, FetchOfficeHoldersByZip pagination
- Codebase: `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/ballotready/types.go` — Candidacy types (Phase B already implemented)
- Codebase: `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/models.go` — DB model fields including valid_from/valid_to
- Codebase: `/Users/chrisandrews/Documents/GitHub/EV-Backend/internal/essentials/provider/types.go` — NormalizedOfficial.ValidFrom/ValidTo already present
- Codebase: `/Users/chrisandrews/Documents/GitHub/essentials/src/pages/Results.jsx` — Production UI; buildingImages already defined; FilterSidebar wiring
- Codebase: `/Users/chrisandrews/Documents/GitHub/essentials/src/lib/classify.js` — FEDERAL_ORDER constant; classifyCategory function
- Codebase: `/Users/chrisandrews/Documents/GitHub/ev-ui/src/PoliticianCard.jsx` — overflow:hidden confirmed; no badge prop exists
- Codebase: `/Users/chrisandrews/Documents/GitHub/ev-ui/src/FilterSidebar.jsx` — buildingImageSrc prop confirmed; portrait aspect ratio 4/5
- Codebase: `/Users/chrisandrews/Documents/GitHub/ev-ui/src/tokens.js` — evCoral: '#ff5740' confirmed
- `/Users/chrisandrews/Documents/GitHub/CivicEngine GraphQL API Documentation.md` — races query signature, location filter, candidacy fields, isCertified semantics

### Secondary (MEDIUM confidence)
- MDN IntersectionObserver API — scroll-spy pattern with rootMargin verified against browser standard
- MDN Date.toLocaleDateString — date formatting verified

### Tertiary (LOW confidence)
- BallotReady `races` query zip filter behavior — documented but not tested against actual API key in this codebase

---

## Metadata

**Confidence breakdown:**
- ESST-05 (federal reorder): HIGH — trivial constant change, fully understood
- ESST-06 (term dates): HIGH — data exists in DB, path is clear, just needs plumbing
- ESST-04 (building images): HIGH for structure/wiring; MEDIUM for scroll-spy timing details (needs empirical tuning)
- ESST-01/02/03 (candidates): MEDIUM — query pattern documented but requires API key validation; badge implementation has one architectural choice (ev-ui change vs wrapper)

**Research date:** 2026-02-18
**Valid until:** 2026-03-20 (30 days — stable codebase)
