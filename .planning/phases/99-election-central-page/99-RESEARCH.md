# Phase 99: Election Central Page - Research

**Researched:** 2026-03-29
**Domain:** React frontend extension — tab toggle UI, election data display, seeded candidate randomization
**Confidence:** HIGH

## Summary

Phase 99 builds a tab-toggle extension to the existing Results page, adding an Elections view alongside the existing Representatives view. The API layer (electionService + `/api/essentials/elections?lat=X&lng=Y`) is fully implemented by Phase 98. The frontend work is: add a `?view=elections` tab toggle, wire up a new `fetchElections(lat, lng)` call in `api.jsx`, render election data in chronological then tier then position order, show candidate cards using the existing `PoliticianCard` component with an incumbent badge variant, and handle empty state gracefully.

The one architectural complication is that the elections endpoint takes lat/lng coordinates, but the current frontend search pipeline stores only address strings. The geocoded lat/lng computed in `getRepresentativesByAddress` is not currently returned to the frontend. The plan must choose one of two resolution strategies: (A) add `X-Lat` / `X-Lng` response headers to the candidates/search endpoint so the frontend can cache coordinates alongside the address string, or (B) add a new backend endpoint that accepts an address string and returns elections (backend handles geocoding internally, same as the existing address-search endpoint). Option B has lower frontend complexity and avoids leaking raw coordinates; Option A is lighter on backend changes. The plan must pick one.

**Primary recommendation:** Add a `GET /api/essentials/elections-by-address?address=...` endpoint that geocodes internally and calls `getElectionsByCoordinate()` — mirrors the existing `/address-search` pattern exactly, avoids frontend coordinate management, and is consistent with how the rest of the Essentials API is structured.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Navigation & Entry Point**
- D-01: Tab toggle on the Results page — "Representatives" / "Elections" tabs at the top. Address search persists across tab switches, no re-entry needed.
- D-02: Tab state reflected via URL search param (`?view=elections&address=...`). Shareable, back button works, current `/results` URL unchanged by default.
- D-03: Default tab is Representatives — existing behavior preserved. Elections tab is discoverable but not forced.
- D-04: Dot indicator on the Elections tab when upcoming elections exist (hidden when none). Subtle, no count — just signals there's election data.

**Race Card Layout**
- D-05: Candidate grid cards — each race is a section header with candidate cards displayed in a grid, matching the same card style as the Representatives tab (reuse PoliticianCard pattern). Clicking a candidate navigates to their profile.
- D-06: Incumbent badge is a small "Incumbent" text label in ev-muted-blue below the candidate's name. Challengers get no badge.
- D-07: Election date and countdown displayed as a page-level header per election (not per race). E.g., "2026 Indiana Primary · May 6, 2026 · 32 days away". Multiple elections get separate headers.

**Grouping & Hierarchy**
- D-08: Primary grouping: by election (chronological, soonest first). Each election gets its own header section with date/countdown.
- D-09: Secondary grouping: by tier within each election — Local > State > Federal (same tier order as Representatives tab). Use the same building images and CategorySection component from ev-ui.
- D-10: Tertiary grouping: by position within each tier. Follow the exact same ordering as the Representatives page (reuse `LOCAL_ORDER`, `STATE_ORDER`, `FEDERAL_ORDER` from `classify.js` and `GROUP_SORT_OPTIONS` from `sorters.js`). No custom importance sorting.
- D-11: Candidate order within each race is seeded random per user — stable for a user's session but randomized so no candidate appears favored by position.

**Empty & Partial States**
- D-12: Empty state when no elections exist: friendly centered message — "No upcoming elections found for this address. We're expanding coverage — check back as election season approaches."
- D-13: No-photo fallback: initials avatar (candidate's initials in ev-muted-blue circle) — matches existing PoliticianCard fallback pattern.
- D-14: Elections tab dot indicator hidden when no elections exist.

### Claude's Discretion
- Loading skeleton design for the Elections tab
- Election header visual treatment (typography, spacing, card styling)
- Mobile responsive breakpoints for candidate card grid
- How to derive the seed for candidate randomization (user ID, session token, or localStorage key)
- Whether to prefetch election data when Representatives tab loads or lazy-load on tab switch

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ELEC-01 | User can view upcoming election races for their address on a dedicated Election Central page | Tab toggle in Results.jsx + elections data fetch (lat/lng strategy below) |
| ELEC-02 | Races grouped by government body (Federal > State > Local) then by specific position | `classifyCategory()`, `LOCAL_ORDER`/`STATE_ORDER`/`FEDERAL_ORDER`, `CategorySection` reuse |
| ELEC-03 | Each race section shows all candidates with name, photo, and position sought | `PoliticianCard` reuse; `photo_url` from `ElectionCandidate` interface; initials fallback already in card |
| ELEC-04 | Incumbent candidates visually distinguished with badge/indicator | PoliticianCard has `badge` prop (coral pill); need ev-muted-blue text variant per D-06 |
| ELEC-05 | Election date and type displayed per race with days-until countdown when <60 days | `election_date`, `election_type`, `election_name` from `ElectionResult` interface; countdown computed client-side |
| ELEC-06 | User navigates to Election Central from the same address search as representatives page | Tab toggle + `?view` search param; shared address state in Results.jsx |
| ELEC-07 | Empty state shown clearly when no upcoming election data exists | Empty array from API → EmptyState component render |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React | 19 | UI framework | Already in essentials |
| React Router DOM | 6.x | `useSearchParams` for tab state | Already used in Results.jsx |
| Tailwind CSS | 4 | Utility styling | Already in essentials |
| @chrisandrewsedu/ev-ui | current | `PoliticianCard`, `CategorySection`, `useMediaQuery` | Existing shared library used throughout Results.jsx |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| None new | — | No new dependencies required | All needed libraries already installed |

**Installation:** No new packages required.

## Architecture Patterns

### Recommended Project Structure (new files only)
```
essentials/src/
├── pages/Results.jsx            # MODIFY: add tab toggle, view state, elections render
├── lib/api.jsx                  # MODIFY: add fetchElectionsByAddress()
└── components/ElectionsView.jsx # NEW: extracted elections tab content (optional split)
ev-accounts/backend/src/
├── routes/essentials.ts         # MODIFY: add GET /elections-by-address route
└── lib/electionService.ts       # NO CHANGE: already complete
```

### Pattern 1: Tab Toggle via URL Search Param
**What:** Add `?view=elections` param alongside existing `?q=` address param. Read with `useSearchParams`, write with `setSearchParams` preserving existing params.
**When to use:** Single-page tab switching without a route change.
**Example:**
```jsx
// Source: existing Results.jsx pattern (useSearchParams already in use)
const [searchParams, setSearchParams] = useSearchParams();
const activeView = searchParams.get('view') || 'representatives';

const switchToElections = () => {
  setSearchParams(prev => {
    const next = new URLSearchParams(prev);
    next.set('view', 'elections');
    return next;
  });
};
```

### Pattern 2: Elections Data Fetch (Address → API)
**What:** New `fetchElectionsByAddress(address)` in `api.jsx` calls the new backend endpoint `GET /api/essentials/elections-by-address?address=...`. Backend geocodes the address (same Census Geocoder path already used by `getRepresentativesByAddress`) and calls `getElectionsByCoordinate(lat, lng)`.
**Why not expose lat/lng to frontend:** The backend already has all geocoding infrastructure; adding a second address-accepting endpoint follows the existing `address-search` pattern exactly and avoids leaking raw coordinates.
**Example:**
```js
// In api.jsx
export async function fetchElectionsByAddress(address) {
  try {
    const res = await publicFetch(
      `/essentials/elections-by-address?address=${encodeURIComponent(address)}`
    );
    if (!res || !res.ok) return { elections: [] };
    return res.json(); // { elections: ElectionResult[] }
  } catch {
    return { elections: [] };
  }
}
```

### Pattern 3: Race Classification → Tier Grouping
**What:** The API returns `ElectionRace.position_name` (e.g., "City Council District 3", "U.S. Senate"). This must be mapped to tier + category using the same `classifyCategory()` logic as Representatives. However, `ElectionRace` does NOT have `district_type` — classification must be inferred from `position_name` string matching.
**Critical insight:** `classifyCategory()` reads `pol.district_type` primarily. Election races come from `essentials.races` with a `position_name` string but no `district_type` field in the API response. Two options:
  - Option A: Enrich the API response to include district_type from the linked office (requires service change)
  - Option B: Add `district_type` to `ElectionRace` by joining through `races.office_id → offices.district_id → districts.district_type` in `electionService.ts`
  - Option C: Client-side keyword classification from `position_name` (fragile, duplicates logic)

**Recommendation:** Option B — add `district_type` to `ElectionRace` in `electionService.ts`. For statewide races where `office_id IS NULL`, use the `jurisdiction_level` field on the election to infer tier (e.g., `jurisdiction_level = 'state'` → State tier). This is a small service change that unlocks correct tier sorting with zero client-side keyword duplication.

### Pattern 4: Seeded Candidate Randomization
**What:** Per D-11, candidates within a race must be in stable-random order per session. This prevents any candidate from appearing consistently at top position.
**Seed strategy recommendation:** Use a `localStorage` key generated once per session: `localStorage.getItem('ev:session-seed') || (localStorage.setItem('ev:session-seed', Math.random().toString(36)), localStorage.getItem('ev:session-seed'))`. Simple string hash of `(seed + candidate_id)` determines sort order.
**Example:**
```js
// Seeded shuffle — stable per session, different per race
function seededShuffle(candidates, seed) {
  const hash = (s) => s.split('').reduce((a, c) => (a * 31 + c.charCodeAt(0)) | 0, 0);
  return [...candidates].sort((a, b) =>
    hash(seed + a.candidate_id) - hash(seed + b.candidate_id)
  );
}
```

### Pattern 5: Incumbent Badge
**What:** Per D-06, incumbent badge is small "Incumbent" text label in ev-muted-blue, NOT the existing coral pill badge from PoliticianCard's `badge` prop. Must be rendered separately below the candidate name.
**Implementation:** PoliticianCard's existing `badge` prop renders a coral pill (position: absolute, bottom-right). The incumbent indicator must be inline with the name/title stack in ev-muted-blue. Approaches:
  - Option A: Render a custom candidate card wrapper that injects a colored text label below the name — pass `subtitle` as the incumbent indicator
  - Option B: Add an `incumbentBadge` prop to PoliticianCard in ev-ui (requires ev-ui publish)
  - Option C: Use the existing `badge` prop with custom styling overrides (fights the absolute positioning)

**Recommendation:** Option A — use the existing `subtitle` prop of PoliticianCard to show "Incumbent" in ev-muted-blue color. Apply `style={{ color: '#00657c' }}` inline or via a wrapper. This avoids an ev-ui publish cycle and is consistent with how the Representatives tab passes subtitle text.

### Anti-Patterns to Avoid
- **Lat/lng in URL params:** Never expose geocoded coordinates in `?lat=X&lng=Y` URL params. Addresses are more shareable and human-readable; lat/lng leaks precision unnecessarily.
- **Client-side address geocoding:** Don't use Google Maps Geocoding API from the frontend to get lat/lng for the elections endpoint. The backend's Census Geocoder is the authoritative source and already implemented.
- **Duplicate classify logic:** Don't write a second position classifier in the Elections tab. Add `district_type` to ElectionRace in the API response instead.
- **Eager election prefetch:** Don't fetch elections when the address search fires on the Representatives tab. Lazy-load when the Elections tab is first clicked (avoids wasted API call for users who never view it).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Candidate card layout | Custom card component | `PoliticianCard` from ev-ui | Already handles photo, initials fallback, horizontal/vertical variants |
| Tier section header | Custom section wrapper | `CategorySection` from ev-ui | Handles title pill, grid layout, external links |
| Tier classification | New position classifier | `classifyCategory()` from classify.js | Already handles all district_type values |
| Tier ordering | New sort logic | `LOCAL_ORDER`/`STATE_ORDER`/`FEDERAL_ORDER` + `orderedEntries()` | Already tested and correct |
| Address geocoding | Google Maps client-side geocode | Backend `elections-by-address` endpoint | Census Geocoder already wired; consistent with all other search paths |
| Desktop/mobile breakpoint | `window.innerWidth` check | `useMediaQuery` from ev-ui | Already used in Results.jsx |

**Key insight:** The Representatives tab already solved every display problem the Elections tab faces. The entire implementation is composing existing solutions, not building new ones.

## Runtime State Inventory

Step 2.5: SKIPPED — this is a UI feature addition, not a rename/refactor/migration phase. No runtime state is being changed.

## Common Pitfalls

### Pitfall 1: Missing district_type on ElectionRace
**What goes wrong:** `classifyCategory()` falls through to `{ tier: 'Unknown', group: 'Uncategorized' }` for every race because `ElectionRace` doesn't include `district_type`. All races appear in one unordered pile.
**Why it happens:** The current `electionService.ts` query selects from `races` and `race_candidates` but doesn't join through to `districts.district_type`.
**How to avoid:** Add `d.district_type` to the geofence query in `electionService.ts` (already joins through `offices → districts`). For statewide races (office_id IS NULL), add `jurisdiction_level`-based fallback mapping in the frontend.
**Warning signs:** All election races sorted under "Uncategorized" in the UI.

### Pitfall 2: URL param collision between `?q=` and `?view=`
**What goes wrong:** Switching to the Elections tab clears the address because `setSearchParams({ view: 'elections' })` overwrites the existing `?q=` param.
**Why it happens:** `setSearchParams` with a plain object replaces all params, not merges them.
**How to avoid:** Always use the functional form: `setSearchParams(prev => { const next = new URLSearchParams(prev); next.set('view', 'elections'); return next; })`.
**Warning signs:** Address input clears when switching tabs.

### Pitfall 3: Election data fetched with stale address
**What goes wrong:** User searches address A, sees results, changes address to B in the search bar but doesn't hit Search yet — then switches to Elections tab, which fetches elections for address A (from URL params) but shows the B address in the input.
**Why it happens:** The election fetch triggers on URL `?q=` param change, not on address input state.
**How to avoid:** Tie election data fetching to the same `activeQuery` variable (URL `?q=` param) that drives the Representatives fetch. The address input state is draft state until the user submits.

### Pitfall 4: Seeded shuffle non-determinism between renders
**What goes wrong:** Candidate order changes every time the component re-renders because the shuffle is computed inline in the render function without memoization.
**Why it happens:** `Math.random()` in render or a non-stable seed.
**How to avoid:** Compute shuffled candidates inside `useMemo` with `[races, sessionSeed]` dependencies. Use a `localStorage`-persisted session seed, not `Math.random()` at render time.
**Warning signs:** Candidates visibly reorder when hovering cards or when React re-renders for unrelated state changes.

### Pitfall 5: Days-until countdown timezone issues
**What goes wrong:** "32 days away" shows as "31 days away" for users in West Coast time zones because the election date is treated as UTC midnight.
**Why it happens:** `new Date('2026-05-06')` parses as UTC midnight; comparing to local `new Date()` gives the wrong day count.
**How to avoid:** Parse election dates as noon local time to avoid boundary issues: `new Date(dateStr + 'T12:00:00')`. Or compare date strings directly without converting to timestamps.

### Pitfall 6: Tab dot indicator flash on load
**What goes wrong:** The dot indicator briefly appears (or disappears) while election data is loading, causing a layout shift.
**Why it happens:** Initial state is empty before the elections fetch completes.
**How to avoid:** Keep dot indicator in a "not yet determined" hidden state while loading. Only show the dot after the elections fetch completes with data. Never show a loading spinner on the dot itself — just keep it hidden.

## Code Examples

### ElectionResult API response shape (from electionService.ts)
```typescript
// Source: ev-accounts/backend/src/lib/electionService.ts
interface ElectionResult {
  election_id: string;
  election_name: string;
  election_date: string; // "YYYY-MM-DD"
  election_type: string; // "primary" | "general" | "retention" | "special"
  jurisdiction_level: string;
  races: ElectionRace[];
}

interface ElectionRace {
  race_id: string;
  position_name: string;
  primary_party: string | null; // ANTIPARTISAN: only on race, never on candidate
  seats: number;
  candidates: ElectionCandidate[];
}

interface ElectionCandidate {
  candidate_id: string;
  full_name: string;
  first_name: string | null;
  last_name: string | null;
  photo_url: string | null;
  is_incumbent: boolean;
  candidate_status: string; // "filed" | "qualified" | "withdrawn" (withdrawn excluded at query layer)
  politician_id: string | null;
}
```

### Election date countdown helper
```js
// Days until election — avoids timezone boundary issues
function daysUntil(dateStr) {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const target = new Date(dateStr + 'T00:00:00');
  target.setHours(0, 0, 0, 0);
  return Math.round((target - today) / (1000 * 60 * 60 * 24));
}

// Usage per D-07: show countdown only when < 60 days
function formatElectionHeader(election) {
  const days = daysUntil(election.election_date);
  const dateLabel = new Date(election.election_date + 'T12:00:00')
    .toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' });
  const typeLabel = {
    primary: 'Primary',
    general: 'General',
    retention: 'Retention',
    special: 'Special Election',
  }[election.election_type] || election.election_type;

  const base = `${election.election_name} · ${dateLabel}`;
  return days < 60 ? `${base} · ${days} days away` : base;
}
```

### Lazy-load pattern for Elections tab
```jsx
// Source: pattern from existing showCandidates fetch in Results.jsx (lines 373-391)
const [electionsData, setElectionsData] = useState(null);
const [electionsLoading, setElectionsLoading] = useState(false);

useEffect(() => {
  if (activeView !== 'elections' || !activeQuery) return;
  if (electionsData !== null) return; // already loaded for this query

  let cancelled = false;
  setElectionsLoading(true);

  fetchElectionsByAddress(decodeURIComponent(activeQuery)).then((data) => {
    if (!cancelled) {
      setElectionsData(data.elections || []);
      setElectionsLoading(false);
    }
  });

  return () => { cancelled = true; };
}, [activeView, activeQuery]); // eslint-disable-line react-hooks/exhaustive-deps

// Reset elections data when address changes
useEffect(() => {
  setElectionsData(null);
}, [activeQuery]);
```

### PoliticianCard with incumbent subtitle (D-06 approach)
```jsx
// Source: PoliticianCard accepts subtitle prop (ev-ui/src/PoliticianCard.jsx line 267)
<PoliticianCard
  id={candidate.candidate_id}
  imageSrc={candidate.photo_url || undefined}
  name={candidate.full_name}
  title={race.position_name}
  subtitle={candidate.is_incumbent ? 'Incumbent' : undefined}
  // Note: subtitle renders in textMuted color by default in PoliticianCard
  // For ev-muted-blue per D-06, wrap with a style override or render a custom subtitle
  onClick={() => navigate(`/candidate/${candidate.candidate_id}`)}
  variant="vertical" // grid layout suits vertical cards for elections
/>
```

### Backend: elections-by-address route addition
```typescript
// Add to ev-accounts/backend/src/routes/essentials.ts
// Pattern mirrors existing GET /address-search
router.get('/elections-by-address', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  const address = typeof req.query.address === 'string' ? req.query.address.trim() : null;
  if (!address) {
    res.status(422).json({ code: 'VALIDATION_ERROR', message: 'address query parameter is required' });
    return;
  }

  try {
    const { lat, lng } = await geocodeAddress(address);
    const elections = await getElectionsByCoordinate(lat, lng);
    res.json({ elections });
  } catch (err) {
    if (err instanceof GeocodingError) {
      if (err.code === 'ADDRESS_NOT_FOUND') {
        res.status(200).json({ elections: [] }); // Treat as empty, not error
        return;
      }
      // ... other GeocodingError codes
    }
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to fetch election data' });
  }
});
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| fetchCandidates in useEffect (eager) | Lazy fetch on toggle (lines 373-391 of Results.jsx) | Phase 98 | Elections tab should follow same lazy pattern |
| useSearchParams destructive set | Functional update preserving all params | Phase 99 | Required for tab toggle without losing address |

## Open Questions

1. **district_type missing from ElectionRace API response**
   - What we know: `electionService.ts` joins through `offices → districts` for geofence-matched races, so `district_type` is available via `d.district_type` in the existing SQL. Statewide races (Part B) use `office_id IS NULL` so no district join exists there.
   - What's unclear: For statewide races, should the planner map `jurisdiction_level` ('state', 'federal', 'local') to tier directly in the frontend, or should the service set a synthetic `district_type` value?
   - Recommendation: Add `district_type` to the ElectionRace interface and select it in the geofence query. For statewide Part B races, derive a synthetic value from `election.jurisdiction_level` ('state' → 'STATE_EXEC', 'federal' → 'NATIONAL_EXEC') as a fallback. Document this mapping in the service.

2. **PoliticianCard subtitle color for incumbent badge (D-06)**
   - What we know: PoliticianCard's `subtitle` prop renders in `colors.textMuted` (gray). D-06 specifies ev-muted-blue (#00657c).
   - What's unclear: Whether to use `subtitle` with color override vs. a lightweight wrapper vs. a new prop in ev-ui.
   - Recommendation: Pass `subtitle` for the text, then wrap the card in a div that uses a CSS override targeting `.ev-politician-card p:last-child` to apply ev-muted-blue for incumbent cards only. Avoids an ev-ui publish cycle.

3. **Horizontal vs. vertical card variant for Elections tab**
   - What we know: Representatives tab uses `variant="horizontal"` (96px tall, list-style). D-05 says "matching the same card style as the Representatives tab."
   - What's unclear: "Same card style" — does this mean literal horizontal variant, or the same visual language?
   - Recommendation: Use `variant="vertical"` for the elections grid to allow photo-focused cards appropriate for an election context. The grid layout in CategorySection (`auto-fill, minmax(250px)`) is already designed for vertical cards. This matches the design intent while still "reusing PoliticianCard" as specified.

## Environment Availability

Step 2.6: SKIPPED — this phase involves no new external dependencies. All required services (Supabase, Census Geocoder, Google Maps Autocomplete) are already operational and used by the existing Essentials app.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Vitest (ev-accounts backend) |
| Config file | `ev-accounts/backend/vitest.config.ts` |
| Quick run command | `cd ev-accounts/backend && npm test` |
| Full suite command | `cd ev-accounts/backend && npm test` |

Note: The `essentials` frontend has no test infrastructure. Frontend validation is manual browser testing.

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ELEC-01 | Elections tab visible in Results page | manual | Browser test: navigate to /results?q=... | N/A |
| ELEC-02 | Races grouped by tier then position | manual | Browser test: verify section order | N/A |
| ELEC-03 | All candidates shown with name/photo | manual | Browser test: verify cards render | N/A |
| ELEC-04 | Incumbent badge visible | manual | Browser test: verify badge text/color | N/A |
| ELEC-05 | Election date + countdown shown | manual | Browser test: verify header format | N/A |
| ELEC-06 | Tab preserves address, no re-entry | manual | Browser test: switch tabs, verify address persists | N/A |
| ELEC-07 | Empty state for no-data address | manual | Browser test: search non-coverage address | N/A |
| elections-by-address endpoint | Returns elections for valid address | integration | `npm test` (if test written) | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `backend/src/routes/essentials.test.ts` (or similar) — integration test for new `GET /elections-by-address` endpoint covering: valid address returns elections array, invalid address returns empty elections, missing address param returns 422

*(Frontend: no test infrastructure — all ELEC-0x requirements validated manually in browser)*

## Sources

### Primary (HIGH confidence)
- Direct code reading: `ev-accounts/backend/src/lib/electionService.ts` — complete ElectionResult/ElectionRace/ElectionCandidate interfaces and query structure
- Direct code reading: `ev-accounts/backend/src/routes/essentials.ts` — confirmed `/elections?lat=X&lng=Y` endpoint exists and uses `optionalAuth`
- Direct code reading: `essentials/src/pages/Results.jsx` — complete Results page architecture, useSearchParams usage, lazy fetch pattern, rendering structure
- Direct code reading: `ev-ui/src/PoliticianCard.jsx` — confirmed props: id, imageSrc, name, title, subtitle, badge, onClick, variant, style; initials fallback built-in
- Direct code reading: `ev-ui/src/CategorySection.jsx` — confirmed props: title, infoTooltip, websiteUrl, children, style; grid layout built-in
- Direct code reading: `essentials/src/lib/classify.js` — confirmed FEDERAL_ORDER, STATE_ORDER, LOCAL_ORDER, classifyCategory, orderedEntries exports
- Direct code reading: `essentials/src/lib/api.jsx` — confirmed no `fetchElections` function exists; must be added
- Direct code reading: `essentials/src/hooks/useGooglePlacesAutocomplete.js` — confirmed hook returns formatted_address only (no lat/lng)
- Direct code reading: `ev-accounts/backend/src/routes/essentialsCandidates.ts` — confirmed candidates/search does not return coordinates

### Secondary (MEDIUM confidence)
- Pattern inference: backend `elections-by-address` approach matches established `address-search` endpoint pattern in the same routes file

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries verified by direct code inspection
- Architecture: HIGH — all integration points confirmed by reading actual source files
- Pitfalls: HIGH — identified by tracing actual code paths (URL param collision, missing district_type, timezone)
- Lat/lng strategy: HIGH — confirmed by reading both the elections endpoint signature and the frontend hook outputs

**Research date:** 2026-03-29
**Valid until:** 2026-04-28 (stable codebase; valid until project structure changes)
