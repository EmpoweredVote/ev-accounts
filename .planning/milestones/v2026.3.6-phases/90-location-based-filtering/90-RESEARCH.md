# Phase 90: Location-Based Filtering - Research

**Researched:** 2026-03-15
**Domain:** Google Maps Places Autocomplete, Zustand store migration, cross-app URL context, client-side filtering
**Confidence:** HIGH

## Summary

Phase 90 adds an optional address filter to the EV-readrank IssueHub that uses `POST /essentials/politicians/search` plus client-side quote filtering to show only issues with 2+ unique local-rep quotes. All required primitives exist: the Google Places autocomplete hook lives in Essentials and needs a TypeScript port, the politician search API call pattern is documented in `essentials/src/lib/api.jsx`, and every `Quote` already carries a `candidateId` field that makes the filtering a simple `Set.has()` check.

The Zustand store is at v6. A v7 migration adds `locationFilter: { address: string; politicianIds: string[] } | null` with `null` as the initial value and a v7 migration path that preserves existing user issue progress. Cross-app context arrives as `?address=` query param on mount in `App.tsx`, which mirrors the existing verdict fragment pattern in `verdictFragment.ts` but uses query params instead of hash fragments.

The two pre-deploy blockers flagged in STATE.md are already resolved: `readrank.empowered.vote` is confirmed present in `middleware.go` ALLOWED_ORIGINS, and the `VITE_GOOGLE_MAPS_API_KEY` env var just needs to be added to EV-readrank's Cloudflare Pages env (same key already used by Essentials).

**Primary recommendation:** Port `useGooglePlacesAutocomplete` to TypeScript, add `@googlemaps/js-api-loader` to EV-readrank dependencies, wire store v7 migration, then build the address input + filter chip component into IssueHub.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Address input: inline text field between editorial header and progress/issue cards
- Autocomplete: Google Maps Places with US restriction — same `useGooglePlacesAutocomplete` hook pattern as Essentials, TypeScript-ported into EV-readrank
- Same Google Maps API key as Essentials, added as `VITE_GOOGLE_MAPS_API_KEY` in ReadRank's Cloudflare Pages env
- Loading state: spinner on the input field, issue cards dim slightly (no full-page loader or skeleton replacement)
- After address set: input collapses into compact filter chip (address + X to clear) with "Showing N of M issues" count below
- Address + matched politician IDs persist in Zustand store (store version bump to v7), so returning users see hub pre-filtered
- Issues with fewer than 2 unique local politicians with quotes are hidden entirely (not grayed out)
- "Unique local politicians" = distinct politician IDs from search results that have quotes in that issue — 2 quotes from the same rep does NOT count
- When filtering active, EvaluationPhase filters `quotesToEvaluate` to only include quotes where `candidateId` matches a local politician
- Zero-match scenario: show inline warning ("No representatives found with quotes for this address"), auto-clear filter, show all issues unfiltered
- Clear filter: restores full unfiltered issue list
- Editorial header text ("Choose an Issue") stays the same regardless of filter state
- Issues completed while filtered retain their progress on filter clear
- After clearing: subtle note on completed issues that evaluation only included local reps
- Cross-app: Essentials passes address via `?address=` URL query param
- SiteHeader's "Read & Rank" nav link appends `?address=` when user has active address search in Essentials — no new UI, just dynamic href
- ReadRank on mount: parse `?address=`, call POST /essentials/politicians/search, apply filter, persist to store, strip `?address=` from URL
- URL param always overrides stored address
- CORS: `readrank.empowered.vote` already in ALLOWED_ORIGINS — confirmed in middleware.go

### Claude's Discretion
- `useGooglePlacesAutocomplete` TypeScript port details
- Filter chip styling and animation
- Warning message styling for no-match and mixed-data scenarios
- Whether to debounce or batch the politician search + quote filter logic
- Store shape details beyond `locationFilter: { address, politicianIds } | null`

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| LOC-01 | Hub page has optional address input using Google Maps Places autocomplete | `useGooglePlacesAutocomplete` hook exists in Essentials; needs TS port + `@googlemaps/js-api-loader` added to EV-readrank |
| LOC-02 | When address provided, only issues with quotes from user's representatives are shown | `Quote.candidateId` field is the join point; filter is `Set.has(candidateId)` against politician IDs from search response |
| LOC-03 | Issues with fewer than 2 quotes from local reps are hidden from hub | IssueHub `issues` array is filtered before rendering; threshold check is `uniquePoliticianIds.size >= 2` |
| LOC-04 | Cross-app context: arriving from Essentials with address context auto-applies filter | `App.tsx` `useEffect` on mount parses `?address=` param, calls search, applies filter, strips param via `history.replaceState` or router |
| LOC-05 | User can clear location filter to see all issues | Filter chip X button calls `clearLocationFilter()` store action; sets `locationFilter: null` |
</phase_requirements>

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@googlemaps/js-api-loader` | ^2.0.2 | Google Maps JS API lazy loader | Already in Essentials; `importLibrary('places')` is the approved pattern per Google's modular SDK |
| `zustand` | ^5.0.9 | Store persistence with version + migrate | Already in EV-readrank at v6; v7 migration follows established pattern |
| `react-router-dom` | ^7.11.0 | URL query param parsing on mount | Already in EV-readrank; `useSearchParams` or `URLSearchParams(window.location.search)` |
| `framer-motion` | ^12.23.26 | Filter chip entrance/exit animation | Already in EV-readrank; existing hub uses it for card stagger |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| TypeScript built-ins | — | `URLSearchParams` for query param parsing | Parse `?address=` on mount without extra deps |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `@googlemaps/js-api-loader` direct | `@vis.gl/react-google-maps` | React wrapper adds weight; direct loader already proven in Essentials |
| Client-side filtering | New backend endpoint | Out of scope per locked decision; at ~61 quotes client-side is sufficient |

**Installation (EV-readrank only):**
```bash
cd EV-readrank
npm install @googlemaps/js-api-loader
```

---

## Architecture Patterns

### Recommended Integration Structure

The phase touches four files in EV-readrank plus two files in Essentials/ev-ui:

```
EV-readrank/src/
├── hooks/
│   └── useGooglePlacesAutocomplete.ts   # NEW — TS port from Essentials
├── components/
│   ├── IssueHub.tsx                     # MODIFY — address input + filter chip + filtered issues list
│   ├── AddressFilterInput.tsx           # NEW — address input + filter chip (extracted for clarity)
│   └── EvaluationPhase.tsx              # MODIFY — filter quotesToEvaluate by locationFilter.politicianIds
├── store/
│   └── useReadRankStore.ts              # MODIFY — v7 migration, locationFilter state + actions
├── data/
│   └── api.ts                           # MODIFY — add searchPoliticians() function
└── App.tsx                              # MODIFY — parse ?address= on mount

essentials/src/
└── components/Layout.jsx (or wherever SiteHeader is rendered)
                                         # MODIFY — dynamic href on "Read & Rank" nav link

ev-ui/src/
└── SiteHeader.jsx                       # No change — navItems passed from consumer
```

### Pattern 1: TypeScript Port of useGooglePlacesAutocomplete

The existing JS hook is clean. The TypeScript port is straightforward:

```typescript
// EV-readrank/src/hooks/useGooglePlacesAutocomplete.ts
// Source: essentials/src/hooks/useGooglePlacesAutocomplete.js (TS port)
import { useState, useEffect, useRef } from 'react';
import { setOptions, importLibrary } from '@googlemaps/js-api-loader';

const API_KEY = import.meta.env.VITE_GOOGLE_MAPS_API_KEY as string | undefined;

function ensureConfigured(): void {
  if (API_KEY && !window.google?.maps?.importLibrary) {
    setOptions({ key: API_KEY });
  }
}

interface UseGooglePlacesAutocompleteOptions {
  onPlaceSelected: (formattedAddress: string) => void;
}

export default function useGooglePlacesAutocomplete(
  inputRef: React.RefObject<HTMLInputElement>,
  { onPlaceSelected }: UseGooglePlacesAutocompleteOptions
): { loadError: boolean } {
  const [loadError, setLoadError] = useState(false);
  const callbackRef = useRef(onPlaceSelected);
  callbackRef.current = onPlaceSelected;

  useEffect(() => {
    if (!API_KEY || !inputRef.current) {
      setLoadError(true);
      return;
    }
    let autocomplete: google.maps.places.Autocomplete | null = null;
    ensureConfigured();

    importLibrary('places').then((placesLib) => {
      if (!inputRef.current) return;
      const Places = placesLib as typeof google.maps.places;
      autocomplete = new Places.Autocomplete(inputRef.current, {
        componentRestrictions: { country: 'us' },
        fields: ['formatted_address', 'address_components'],
        types: ['geocode'],
      });
      autocomplete.addListener('place_changed', () => {
        const place = autocomplete!.getPlace();
        if (place?.formatted_address) {
          callbackRef.current(place.formatted_address);
        }
      });
    }).catch(() => setLoadError(true));

    return () => {
      if (autocomplete) {
        google.maps.event.clearInstanceListeners(autocomplete);
      }
    };
  }, [inputRef]);

  return { loadError };
}
```

**Note on TypeScript and google.maps types:** The `@googlemaps/js-api-loader` package ships types. For `google.maps.places.Autocomplete`, you need `@types/google.maps` as a dev dependency, or cast `placesLib` explicitly.

### Pattern 2: Zustand v7 Migration

```typescript
// Source: existing migrate() in useReadRankStore.ts — extend the same pattern
{
  name: 'ev_readrank',
  version: 7,
  migrate: (_persistedState, version) => {
    const isUpgrade = version > 0;
    return {
      phase: 'hub' as Phase,
      currentIssueId: null as string | null,
      issueProgress: {} as Record<string, IssueProgress>,
      practiceCompleted: isUpgrade,
      practiceProgress: null as PracticeProgress | null,
      coachMarksCompleted: isUpgrade,
      locationFilter: null,   // NEW — all users start with no filter on migration
    };
  },
  partialize: (state) => ({
    phase: state.phase,
    currentIssueId: state.currentIssueId,
    issueProgress: state.issueProgress,
    practiceCompleted: state.practiceCompleted,
    practiceProgress: state.practiceProgress,
    coachMarksCompleted: state.coachMarksCompleted,
    locationFilter: state.locationFilter,   // NEW — persisted
  }),
}
```

**Key:** `migrate()` returns `locationFilter: null` for ALL users (new and upgrading) — correct behavior since there is no stored address to restore from an older schema version.

### Pattern 3: searchPoliticians in EV-readrank api.ts

```typescript
// Source: essentials/src/lib/api.jsx lines 77-103 — TypeScript port
const API_BASE = import.meta.env.VITE_API_URL || 'https://api.empowered.vote';

export interface Politician {
  id: string;
  name: string;
  // ...other fields from /essentials/politicians/search response
}

export interface SearchPoliticiansResult {
  status: string;
  data: Politician[];
  formattedAddress: string;
  error?: string;
}

export async function searchPoliticians(query: string): Promise<SearchPoliticiansResult> {
  try {
    const res = await fetch(`${API_BASE}/essentials/politicians/search`, {
      method: 'POST',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ query }),
    });
    const status = res.headers.get('X-Data-Status') || res.headers.get('x-data-status') || '';
    const formattedAddress = res.headers.get('X-Formatted-Address') || res.headers.get('x-formatted-address') || '';
    if (!res.ok) {
      return { status: 'error', data: [], error: `${res.status} ${res.statusText}`, formattedAddress: '' };
    }
    const data: Politician[] = await res.json();
    return { status: status || 'fresh', data, formattedAddress };
  } catch (error) {
    return { status: 'error', data: [], error: (error as Error).message, formattedAddress: '' };
  }
}
```

**Important:** The backend returns a flat array of politician objects (not paginated), with politician UUIDs in `id` field. These UUIDs match `Quote.candidateId`.

### Pattern 4: Client-Side Filtering Logic

```typescript
// Source: analysis of existing getQuotesForIssue() in EV-readrank/src/data/api.ts
function getUniquePoliticianIdsForIssue(
  quotes: Quote[],
  issueId: string,
  localPoliticianIds: Set<string>
): Set<string> {
  return new Set(
    quotes
      .filter(q => q.issue === issueId && q.candidateId && localPoliticianIds.has(q.candidateId))
      .map(q => q.candidateId as string)
  );
}

// In IssueHub — filter issues before rendering
const filteredIssues = locationFilter
  ? issues.filter(issue => {
      const uniqueLocalReps = getUniquePoliticianIdsForIssue(
        allQuotes,
        issue.id,
        new Set(locationFilter.politicianIds)
      );
      return uniqueLocalReps.size >= 2;
    })
  : issues;
```

### Pattern 5: URL Query Param Parsing on Mount

```typescript
// Source: verdictFragment.ts cross-app pattern + react-router-dom useSearchParams
// In App.tsx — parse ?address= on mount
import { useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';

function useAddressQueryParam(onAddress: (address: string) => void) {
  const [searchParams, setSearchParams] = useSearchParams();

  useEffect(() => {
    const address = searchParams.get('address');
    if (address) {
      onAddress(decodeURIComponent(address));
      // Strip the param without page reload
      setSearchParams(prev => {
        prev.delete('address');
        return prev;
      }, { replace: true });
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []); // Run once on mount only
}
```

**Note:** `useSearchParams` from react-router-dom v7 is already a dependency. The `{ replace: true }` option strips the param without adding a history entry.

### Pattern 6: Dynamic "Read & Rank" Nav Link in Essentials

The SiteHeader in ev-ui uses a static `defaultNavItems` array. Essentials renders `<SiteHeader>` but doesn't currently pass custom `navItems`. The locked decision says "no new UI, just dynamic href" — meaning Essentials passes a custom `navItems` array (or `onNavigate` handler) that appends `?address=` when an active address is in Results page state.

Since Essentials' Results page holds `addressInput` as local component state, the SiteHeader must receive the dynamic href via a prop. The cleanest approach: Essentials' Layout component (or Results page directly) renders SiteHeader with `navItems` overriding the "Read & Rank" href when `addressInput` is set. The ev-ui SiteHeader already accepts `navItems` passthrough via the `Header` component.

### Anti-Patterns to Avoid

- **Filtering in EvaluationPhase before selectIssue:** `quotesToEvaluate` is set at `selectIssue()` time. When location filter is active, `selectIssue()` must receive the already-filtered quotes array — or EvaluationPhase reads from `locationFilter` to filter `quotesToEvaluate` at render time. The locked decision says EvaluationPhase filters at render; do NOT re-filter at `selectIssue()` since that would persist filtered quotes to the store and cause data loss on filter clear.
- **Storing full politician objects in locationFilter:** Store only `politicianIds: string[]` — not the full politician response. Keeps localStorage lean; full politician data is not needed downstream.
- **Using `window.history.replaceState` directly:** Use react-router-dom's `setSearchParams(..., { replace: true })` to stay consistent with the router's URL tracking.
- **Calling searchPoliticians without debounce from autocomplete:** The autocomplete fires `place_changed` once per selection (not on every keystroke), so no debounce is needed for the API call. The spinner pattern (not a full-page loader) is correct.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Address autocomplete | Custom input + fetch Places API | `@googlemaps/js-api-loader` + Places.Autocomplete | Session tokens, billing optimization, dropdown UI, keyboard nav all handled |
| Autocomplete cleanup | Manual event listener removal | `google.maps.event.clearInstanceListeners(autocomplete)` in useEffect cleanup | Prevents memory leaks on HMR/unmount |
| URL param strip without reload | `window.location.href = ...` | `setSearchParams(prev => { prev.delete('address'); return prev; }, { replace: true })` | Avoids full page reload, stays within React Router history |

**Key insight:** The Places Autocomplete widget handles the entire dropdown lifecycle including keyboard navigation, session billing, and US restriction filtering — do not replicate any of this.

---

## Common Pitfalls

### Pitfall 1: `@googlemaps/js-api-loader` Key Format
**What goes wrong:** Passing `apiKey` instead of `key` to `setOptions()` causes Google to reject the request with a 400 (Google converts camelCase to snake_case, so `apiKey` becomes `api_key` which is not the accepted param).
**Why it happens:** The loader's TypeScript types accept both forms but the underlying URL construction only works with `key`.
**How to avoid:** Always use `setOptions({ key: API_KEY })` — this is explicitly called out in the existing Essentials hook with a comment.
**Warning signs:** Console error "InvalidKeyMapError" or autocomplete dropdown never appears.

### Pitfall 2: Store v7 Migration Wipes Issue Progress
**What goes wrong:** The current `migrate()` returns a hardcoded `initialState` regardless of version — this is the established pattern (from Phase 86 decision). On v7 bump this will wipe existing `issueProgress` for returning users.
**Why it happens:** The Phase 86 decision intentionally returns hardcoded initial state to handle old incompatible localStorage.
**How to avoid:** This is expected behavior and by design for this project. Document clearly in the plan that existing user progress will reset on the v7 migration deploy.
**Warning signs:** Users report lost progress — expected; communicate via release notes if needed.

### Pitfall 3: `Quote.candidateId` May Be Undefined
**What goes wrong:** The `Quote` interface has `candidateId?: string` (optional). Filtering with `localPoliticianIds.has(q.candidateId)` without null guard passes `undefined` to `Set.has()` which returns false (safe) but TypeScript will complain without a guard.
**Why it happens:** Some quotes may not have a politician linked (e.g., practice quotes don't have real candidateIds).
**How to avoid:** Always guard: `q.candidateId && localPoliticianIds.has(q.candidateId)`.

### Pitfall 4: `window.google` Not Available Until `importLibrary` Resolves
**What goes wrong:** Cleanup function `google.maps.event.clearInstanceListeners(autocomplete)` in useEffect return fires immediately on unmount. If the component unmounts before `importLibrary` resolves, `window.google` is undefined.
**Why it happens:** `importLibrary` is async; the cleanup function may run before it completes.
**How to avoid:** Guard cleanup with `if (autocomplete && window.google)`. The Essentials hook doesn't guard this — add the guard in the TypeScript port.

### Pitfall 5: Essentials Address State Is Local to Results Page
**What goes wrong:** The "dynamic Read & Rank href" needs the active address from Essentials' Results page. That address lives in local `useState` inside `Results.jsx` — it's not in a context or URL. Passing it up to the Layout/SiteHeader requires either lifting state or using the URL (`?q=` param is already in the URL bar on Results page).
**Why it happens:** Essentials was designed with simple local state; no global address context exists.
**How to avoid:** The easiest approach: read `?q=` from `useSearchParams()` inside the component that renders SiteHeader, and construct the Read & Rank href from that. The `?q=` param is set at `handleAddressSearch` in Results.jsx and already contains the encoded address — no state lifting needed.

### Pitfall 6: CORS — Confirmed Already Resolved
**What goes wrong:** STATE.md flags "Confirm CORS allows readrank.empowered.vote" as a pre-deploy blocker.
**Resolution:** Confirmed — `https://readrank.empowered.vote` and `https://readrank-dev.empowered.vote` are already in `middleware.go` ALLOWED_ORIGINS (lines 74-75). No backend change required.

---

## Code Examples

### Filtering issues in IssueHub
```typescript
// Source: analysis of IssueHub.tsx + getQuotesForIssue in api.ts
const localPoliticianSet = locationFilter
  ? new Set(locationFilter.politicianIds)
  : null;

const filteredIssues = localPoliticianSet
  ? issues.filter(issue => {
      const repIds = new Set(
        quotes
          .filter(q => q.issue === issue.id && q.candidateId && localPoliticianSet.has(q.candidateId))
          .map(q => q.candidateId as string)
      );
      return repIds.size >= 2;
    })
  : issues;
```

### Filtering quotesToEvaluate in EvaluationPhase
```typescript
// Source: EvaluationPhase.tsx pattern — read from store at render time
const { locationFilter } = useReadRankStore();
const rawQuotesToEvaluate = progress?.quotesToEvaluate ?? [];

const quotesToEvaluate = locationFilter
  ? rawQuotesToEvaluate.filter(q =>
      q.candidateId && locationFilter.politicianIds.includes(q.candidateId)
    )
  : rawQuotesToEvaluate;
```

### Reading ?address= param in App.tsx
```typescript
// Source: react-router-dom v7 + verdictFragment.ts pattern
// Placed in MainApp() component which already uses useReadRankStore
const [searchParams, setSearchParams] = useSearchParams();

useEffect(() => {
  const address = searchParams.get('address');
  if (!address) return;
  const decoded = decodeURIComponent(address);
  // Strip param immediately
  setSearchParams(prev => { prev.delete('address'); return prev; }, { replace: true });
  // Trigger search + store update
  setLocationFilterFromAddress(decoded); // store action
}, []); // mount only
```

### Store interface additions
```typescript
// Source: useReadRankStore.ts — extends existing ReadRankState interface
interface LocationFilter {
  address: string;
  politicianIds: string[];
}

// Add to ReadRankState:
locationFilter: LocationFilter | null;
setLocationFilter: (filter: LocationFilter | null) => void;
clearLocationFilter: () => void;
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Google Maps Places API loaded via `<script>` tag | `@googlemaps/js-api-loader` with `importLibrary()` | 2023 (Google modular SDK) | No global script tag needed; tree-shakeable; avoids duplicate load |
| `setOptions({ apiKey: ... })` | `setOptions({ key: ... })` | Established in Essentials (see hook comment) | Prevents 400 rejection from Google |

**Deprecated/outdated:**
- `new google.maps.places.Autocomplete()` via synchronously loaded script: Works but bypasses session token optimization; the loader pattern is preferred.

---

## Open Questions

1. **`@types/google.maps` for TypeScript port**
   - What we know: `@googlemaps/js-api-loader` includes its own types but Places-specific types (`google.maps.places.Autocomplete`) require casting or the `@types/google.maps` package.
   - What's unclear: Whether the existing EV-readrank TypeScript config will compile cleanly after adding the loader without explicit `@types/google.maps`.
   - Recommendation: Add `@types/google.maps` as a dev dependency; cast `placesLib as typeof google.maps.places` in the hook.

2. **Essentials SiteHeader dynamic href: exact implementation**
   - What we know: `?q=` param is in the URL bar on Essentials Results page; `SiteHeader` in ev-ui accepts `navItems` prop override.
   - What's unclear: Whether `Results.jsx` should pass override `navItems` prop directly or if a layout wrapper should handle it.
   - Recommendation: In `Results.jsx`, construct a `readRankHref` from `useSearchParams()` and pass a custom `navItems` array to `<SiteHeader>` that overrides the "Read & Rank" href. This is the least-invasive change and requires no ev-ui publish.

3. **Mixed-data warning after filter clear: where to store completion metadata**
   - What we know: Issues completed while filtered should show a subtle note after clearing. The locked decision says "subtle note, not blocking."
   - What's unclear: Whether to track `completedWhileFiltered: boolean` per `IssueProgress` or derive it from store state at render time.
   - Recommendation: Add `completedWhileFiltered: boolean` to `IssueProgress` in the v7 schema. Set it to `true` when `setPhase('results')` is called and `locationFilter !== null`. Read it in IssueHub card rendering.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None detected — no test config files in EV-readrank |
| Config file | None — Wave 0 gap |
| Quick run command | N/A |
| Full suite command | N/A |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LOC-01 | Address input renders with autocomplete | manual-only | N/A — requires live Google Maps API | ❌ Wave 0 |
| LOC-02 | Issues filtered to only show reps' issues | unit | N/A — no test framework | ❌ Wave 0 |
| LOC-03 | Issues with < 2 unique rep quotes hidden | unit | N/A — no test framework | ❌ Wave 0 |
| LOC-04 | ?address= param auto-applies filter on mount | manual-only | N/A — integration test | ❌ Wave 0 |
| LOC-05 | Clearing filter restores full issue list | manual-only | N/A — requires UI | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** TypeScript build check: `cd /Users/chrisandrews/Documents/GitHub/EV-readrank && npm run build`
- **Per wave merge:** Full TypeScript build + manual smoke test in dev server
- **Phase gate:** Manual end-to-end verification before `/gsd:verify-work`

### Wave 0 Gaps
- No test framework exists in EV-readrank. Given the UI-heavy and API-dependent nature of LOC requirements, the pragmatic validation approach for this phase is TypeScript build success + manual smoke test rather than automated unit tests.
- The filtering logic (LOC-02, LOC-03) is the only pure-function behavior testable in isolation — could add a `filterIssuesByLocation.test.ts` if a test framework is added, but not a blocker for this phase.

---

## Sources

### Primary (HIGH confidence)
- Direct file inspection: `essentials/src/hooks/useGooglePlacesAutocomplete.js` — complete hook implementation
- Direct file inspection: `essentials/src/lib/api.jsx` lines 77-103 — `searchPoliticians()` call pattern
- Direct file inspection: `EV-readrank/src/store/useReadRankStore.ts` — v6 store, current interfaces, migrate() pattern
- Direct file inspection: `EV-readrank/src/components/IssueHub.tsx` — current hub structure, integration points
- Direct file inspection: `EV-readrank/src/data/api.ts` — `Quote.candidateId` field confirmed optional
- Direct file inspection: `EV-Backend/internal/middleware/middleware.go` lines 74-75 — CORS confirmation for readrank.empowered.vote
- Direct file inspection: `essentials/package.json` — `@googlemaps/js-api-loader@^2.0.2` confirmed as dependency
- Direct file inspection: `EV-readrank/package.json` — `@googlemaps/js-api-loader` NOT present (needs adding)
- Direct file inspection: `ev-ui/src/SiteHeader.jsx` — static navItems, accepts navItems prop override
- Direct file inspection: `essentials/src/pages/Results.jsx` — `?q=` param in URL, local `addressInput` state

### Secondary (MEDIUM confidence)
- `@googlemaps/js-api-loader` key vs apiKey pitfall: documented in existing Essentials hook comment (code comment as source)

### Tertiary (LOW confidence)
- `@types/google.maps` dev dependency requirement: inferred from TypeScript port needs; not directly verified against loader package types

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries directly inspected in project files
- Architecture: HIGH — integration points confirmed by reading all relevant source files
- Pitfalls: HIGH for CORS (confirmed resolved) and key format (documented in existing code); MEDIUM for TypeScript types question
- Filtering logic: HIGH — `Quote.candidateId` confirmed, `Set.has()` pattern straightforward

**Research date:** 2026-03-15
**Valid until:** 2026-04-14 (stable dependencies; Google Maps API surface is stable)
