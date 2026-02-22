# Phase 28: Address Autocomplete - Research

**Researched:** 2026-02-22
**Domain:** Google Maps Places Autocomplete, React state/UX, frontend-only refactor
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Search input transition**
- Placeholder text: "Enter your address" — simple and direct
- Subheading changes to: "Enter your address to see who represents you" (drop ZIP reference)
- Selecting a Google suggestion fills the input field — user must click Search to navigate (not auto-search on select)
- If user types text but doesn't select a Google suggestion and hits Search: prompt them to select from the dropdown (e.g., "Please select an address from the suggestions") — don't submit raw text
- All ZIP code references and ZIP-only search paths are removed from both Landing and Results pages

**Address confirmation display (Results page layout reorganization)**
- Address autocomplete search bar moves to the full-width top position (where "Search Representative" bar currently lives)
- "Search Representative" name filter moves into the left sidebar
- "Show Candidates" toggle moves into the left sidebar
- "Sort by" option is removed entirely
- Full formatted address shown in the search bar (e.g., "123 Main St, Bloomington, IN 47401") — not shortened
- The results page address bar has full Google Places autocomplete so users can re-search without going back to landing
- Address bar appears immediately on page load; results load below with loading skeletons

**Degraded mode behavior**
- If Google Maps API fails to load: input is disabled, inline error message below it reads "Address search is temporarily unavailable. Please try again later."
- Subtle hint shown when autocomplete isn't working: small text below the input
- No fallback to raw text submission — without Google autocomplete, the search cannot produce valid results
- The "must select a suggestion" validation does not need to be relaxed because the input is disabled in degraded mode

### Claude's Discretion
- Loading skeleton design for results area
- Exact styling/positioning of the inline error message in degraded mode
- How the "please select a suggestion" validation hint appears (inline text, toast, etc.)
- Transition animations when navigating from landing to results

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| ADDR-01 | User enters address via Google Maps Places autocomplete widget | Existing `useGooglePlacesAutocomplete` hook + `@googlemaps/js-api-loader` already wired; extend for degraded mode and "must select" validation |
| ADDR-02 | ZIP code search path is removed — address is the only search input | Landing.jsx: remove ZIP branch from handleSearch, remove `/^\d{5}$/` test, remove `?zip=` param. Results.jsx: remove `zipFromUrl`, remove ZIP-specific sessionStorage key logic, remove `handleZipLookup` delegation in SearchPoliticians is backend-only (keep as-is). api.jsx: `fetchPoliticiansOnce` and `fetchPoliticiansProgressive` can be left but will never be called. `usePoliticianData` ZIP branch becomes dead code — leave or simplify. |
| ADDR-03 | User sees their validated/confirmed address in search results | `formattedAddress` is already returned by `usePoliticianData` (from `X-Formatted-Address` header) but not yet displayed. Wire it into Results.jsx address bar as the controlled input value after selection. |
| ADDR-04 | User sees a clear message when local-level data is not available for their area | Backend sends `X-Data-Status: no-geofence-data`. `dataStatus` is already returned by `usePoliticianData`. Results.jsx reads it but ignores it — add a UI banner/message when `dataStatus === 'no-geofence-data'`. |
</phase_requirements>

---

## Summary

Phase 28 is a **frontend-only refactor** of the `essentials` React app. The Google Maps infrastructure is already in place: `@googlemaps/js-api-loader` (v2.0.2) is installed, `VITE_GOOGLE_MAPS_API_KEY` is set in `.env.local`, and `useGooglePlacesAutocomplete` already attaches the legacy `Autocomplete` class to an input ref and fires `onPlaceSelected(formattedAddress)`. The backend already returns `X-Formatted-Address` and `X-Data-Status: no-geofence-data` headers. None of the four ADDR requirements need new backend work.

The primary work is in four areas: (1) retrofitting Landing.jsx to remove ZIP logic and add degraded-mode disable/error, (2) restructuring Results.jsx layout so the address bar is full-width at the top and sidebar gains name search + candidates toggle, (3) wiring `formattedAddress` from `usePoliticianData` into the visible address bar, and (4) showing the no-geofence message using `dataStatus`. The key behavioral addition is tracking whether the user has made a valid Google selection (a "place selected" flag) vs. just typed raw text, so Search can be blocked until a suggestion is confirmed.

The STATE.md note about `PlaceAutocompleteElement` shadow DOM complexity is relevant: this phase explicitly does **not** migrate to the new Web Component API — the legacy `Autocomplete` class is the correct choice here (per the REQUIREMENTS.md Out of Scope table entry "PlaceAutocompleteElement migration").

**Primary recommendation:** Extend `useGooglePlacesAutocomplete` with a `loadError` return value and a `placeSelected` flag, then update both Landing and Results pages to consume those values. No new dependencies required.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@googlemaps/js-api-loader` | `^2.0.2` (already installed) | Dynamically loads Google Maps JS API with ES modules, deduplication across components | Already in use; provides `setOptions`/`importLibrary` pattern used by existing hook |
| React | `^19.1.1` (already installed) | Component framework | Project standard |
| React Router DOM | `^7.8.2` (already installed) | URL state via `useSearchParams`, `useNavigate` | Project standard |
| Tailwind CSS 4 | `^4.1.12` (already installed) | Styling | Project standard |
| `@chrisandrewsedu/ev-ui` | `^0.1.19` (already installed) | `FilterSidebar` component (needs changes) | Project standard |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| (none new) | — | No additional installs required | All needed libraries are already present |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Legacy `Autocomplete` class | `PlaceAutocompleteElement` (Web Component) | New API has shadow DOM Tailwind issues; legacy still works with existing API keys predating March 2025; explicitly deferred in REQUIREMENTS.md |
| `importLibrary('places')` pattern | Loading `places` library in Loader constructor | Both work; `importLibrary` is the current approach and avoids changing anything outside the hook |

**Installation:**
```bash
# No new packages needed — everything is already installed
```

---

## Architecture Patterns

### Existing Hook — What It Does Today

```javascript
// src/hooks/useGooglePlacesAutocomplete.js (current)
// Attaches google.maps.places.Autocomplete to an inputRef
// Fires onPlaceSelected(formattedAddress: string) when user selects a suggestion
// Uses importLibrary('places') — loads lazily, deduplicates via setOptions

import { useEffect, useRef } from 'react';
import { setOptions, importLibrary } from '@googlemaps/js-api-loader';

export default function useGooglePlacesAutocomplete(inputRef, { onPlaceSelected }) {
  // ...
  importLibrary('places')
    .then((placesLib) => {
      autocomplete = new placesLib.Autocomplete(inputRef.current, {
        componentRestrictions: { country: 'us' },
        fields: ['formatted_address', 'address_components'],
        types: ['geocode'],  // or ['address'] — both work; 'geocode' includes more result types
      });
      autocomplete.addListener('place_changed', () => {
        const place = autocomplete.getPlace();
        if (place?.formatted_address) {
          callbackRef.current(place.formatted_address);
        }
      });
    });
  // ...
}
```

### Pattern 1: Extended Hook with loadError + placeSelected Tracking

**What:** Add two return values to `useGooglePlacesAutocomplete`:
- `loadError: boolean` — true if `importLibrary('places')` rejected (network failure, bad key, quota)
- An internal mechanism to let callers know if the current input value came from a selection vs raw typing

**When to use:** Both Landing and Results need to disable the input and show an error when the API fails. Both need to block the Search button when the user has typed but not selected.

**How to track "placeSelected":** The cleanest approach for the locked UX decision (fill on select, Search required) is:
1. The hook calls `onPlaceSelected(formattedAddress)` — the parent component keeps a `hasValidSelection: boolean` state flag
2. The flag is set to `true` in `onPlaceSelected`, and reset to `false` in the `onChange` handler on the input
3. Search button is disabled when `!hasValidSelection` (when user edits input after selection, flag resets)

```javascript
// Extended hook signature
export default function useGooglePlacesAutocomplete(inputRef, { onPlaceSelected }) {
  const [loadError, setLoadError] = useState(false);
  // ...
  importLibrary('places')
    .then(...)
    .catch(() => setLoadError(true));  // catches network errors, bad API key, etc.

  return { loadError };
}
```

```javascript
// In Landing.jsx or Results.jsx
const [hasValidSelection, setHasValidSelection] = useState(false);
const [addressInput, setAddressInput] = useState('');

const { loadError } = useGooglePlacesAutocomplete(inputRef, {
  onPlaceSelected: (formattedAddress) => {
    setAddressInput(formattedAddress);
    setHasValidSelection(true);
  },
});

const handleInputChange = (e) => {
  setAddressInput(e.target.value);
  setHasValidSelection(false);  // any manual edit invalidates the selection
};

const handleSearch = () => {
  if (!hasValidSelection) {
    // show "Please select from suggestions" hint
    return;
  }
  navigate(`/results?q=${encodeURIComponent(addressInput)}`);
};
```

**Source:** Verified against `importLibrary` docs — the returned Promise rejects on failure. (Context7: `/googlemaps/js-api-loader`)

### Pattern 2: Results Page Layout Restructure

**What:** The Results page currently has `FilterSidebar` (left panel) + `main` (right panel). The autocomplete input lives inside `FilterSidebar` via `zipInputRef`. After Phase 28:

- A new **full-width top bar** component holds the address autocomplete input and Search button
- FilterSidebar keeps: filter radio buttons (All/Local/State/Federal), name search input, Candidates toggle, building image
- The `ResultsHeader` component (currently holds "Search Representative" + "Sort by") is removed or repurposed
- "Sort by" is removed entirely

**Layout structure (desktop after Phase 28):**
```
┌──────────────────────────────────────────────────┐
│ SiteHeader                                       │
├──────────────────────────────────────────────────┤
│ AddressBar (full-width): [autocomplete input] [Search] │
│ If no-geofence: coverage gap message            │
├────────────┬─────────────────────────────────────┤
│ Sidebar    │ Main content (scrollable)           │
│ - Filter   │ SkeletonCards (while loading)       │
│ - Name     │ CategorySection × N                 │
│ - Cands    │                                     │
│ - Image    │                                     │
└────────────┴─────────────────────────────────────┘
```

**FilterSidebar changes:** The `zipInputRef` / `autocompleteContainerRef` props are no longer needed for the address input (it moves to top bar). The sidebar still needs the name search field. This means the sidebar either: (a) keeps its existing name-search-like input but wired to the representative name filter, or (b) gets new props. Since `FilterSidebar` is in `ev-ui` (the component library), changes there require a library version bump and re-publish.

**Critical discovery:** `FilterSidebar` in `ev-ui` v0.1.19 includes the location input section (lines 185-215 in `FilterSidebar.jsx`). Moving the address bar out of the sidebar means the sidebar no longer needs `zipCode`, `onZipChange`, `onZipClear`, `onZipSubmit`, `zipInputRef`, `autocompleteContainerRef` props. Adding a name search and candidates toggle to the sidebar is new functionality.

**Options for sidebar changes:**
1. **Modify ev-ui, bump version, republish** — cleanest long-term, requires npm publish
2. **Build a local `LocalFilterSidebar` component in essentials** — avoids ev-ui publish, faster iteration, duplicates some code

For a phase that's already touching Landing and Results significantly, option 2 (local component) is faster and safer. The ev-ui `FilterSidebar` can be replaced by a local component in `essentials/src/components/`.

### Pattern 3: formattedAddress Display

**What:** `usePoliticianData` already returns `formattedAddress` (from the `X-Formatted-Address` response header). It is populated only for address searches (not ZIP). Wire it into the address bar's controlled input value.

```javascript
// In Results.jsx
const {
  data: hookData,
  phase: hookPhase,
  error,
  dataStatus,
  formattedAddress,
} = usePoliticianData(activeQuery, { ... });

// Pre-populate address bar with confirmed address from backend
useEffect(() => {
  if (formattedAddress) {
    setAddressInput(formattedAddress);
    setHasValidSelection(true);  // backend-confirmed = valid
  }
}, [formattedAddress]);
```

### Pattern 4: No-Geofence Coverage Gap Message (ADDR-04)

**What:** Backend sends `X-Data-Status: no-geofence-data` when there are no geofences for the address. `dataStatus` is already tracked in `usePoliticianData` state. Currently unused in Results.jsx.

```javascript
// In Results.jsx, in the address bar section:
{dataStatus === 'no-geofence-data' && (
  <p className="text-sm text-amber-700 bg-amber-50 border border-amber-200 rounded px-3 py-2 mt-2">
    Local representative data is not yet available for this area.
    Federal and state officials are shown based on your state.
  </p>
)}
```

**Placement:** Below the full-width address bar, before the two-panel layout begins. Visible immediately, not buried in the results section.

### Pattern 5: Loading Skeletons (Claude's Discretion)

**What:** When `phase === 'loading'`, show skeleton cards instead of the spinner. The skeleton should match the `PoliticianCard` shape (horizontal variant: ~80px tall with image placeholder + two text lines).

**Recommended approach:** Simple Tailwind CSS skeleton with `animate-pulse`:

```jsx
function SkeletonCard() {
  return (
    <div className="flex items-center gap-3 p-3 rounded-lg border border-gray-100 animate-pulse">
      <div className="w-16 h-16 rounded-full bg-gray-200 flex-shrink-0" />
      <div className="flex-1 space-y-2">
        <div className="h-4 bg-gray-200 rounded w-3/4" />
        <div className="h-3 bg-gray-200 rounded w-1/2" />
      </div>
    </div>
  );
}

function SkeletonSection({ count = 3 }) {
  return (
    <div className="mb-6">
      <div className="h-4 bg-gray-200 rounded w-24 mb-3 animate-pulse" />
      <div className="space-y-2">
        {Array.from({ length: count }).map((_, i) => <SkeletonCard key={i} />)}
      </div>
    </div>
  );
}
```

### Anti-Patterns to Avoid

- **Auto-navigate on selection:** The locked decision is "fill input on select, Search required." Do NOT call `navigate()` inside `onPlaceSelected`. Only fill `addressInput` and set `hasValidSelection = true`.
- **Submitting raw text:** If `hasValidSelection` is false, block submission. The input being disabled in degraded mode means the "must select" check doesn't need to be bypassed in that case.
- **Using `?zip=` URL parameter:** Phase 28 removes the ZIP path from the frontend. All searches go through `?q=`. The backend's `SearchPoliticians` handler already handles the `?q=` path correctly.
- **Passing autocomplete ref through ev-ui FilterSidebar:** The sidebar in ev-ui was designed with `zipInputRef`/`autocompleteContainerRef` for the location input. Moving the address bar to a full-width top position means the sidebar no longer needs those props at all. Don't try to keep the autocomplete inside the ev-ui sidebar.
- **Re-running importLibrary on every render:** The existing hook correctly checks `window.google?.maps?.importLibrary` before calling `setOptions`. This pattern must be preserved in any refactor.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Places API dropdown suggestions | Custom autocomplete dropdown | `google.maps.places.Autocomplete` (existing hook) | Handles geolocation bias, prediction ranking, keyboard navigation, accessibility — enormous complexity |
| Address validation | Custom regex or postal DB | Let Places API return `formatted_address` only when `place_changed` fires | Google's geocoder validates; only call onPlaceSelected when `place?.formatted_address` exists |
| Debounced geocoding | Manual debounce + geocode | Places Autocomplete handles all of this internally | Adds API call cost and complexity |

**Key insight:** The existing hook is correct and already handles the hard parts. The only change needed is adding error tracking and tightening the selection-required contract.

---

## Common Pitfalls

### Pitfall 1: Google Autocomplete Dropdown Z-index in Fixed Layouts

**What goes wrong:** The `.pac-container` (Google's dropdown) is appended to `document.body` with a fixed position. In a layout with `overflow: hidden` panels (like the current desktop two-panel layout), the dropdown renders correctly. However, if the new top address bar uses `position: sticky` or is inside a transformed/overflow container, the dropdown can be clipped.

**Why it happens:** Google appends `.pac-container` directly to `<body>` to avoid z-index battles, but some CSS transforms or `overflow: hidden` ancestors can still interfere.

**How to avoid:** Keep the address bar in the normal document flow (not inside `position: sticky` with `overflow: hidden`). The current Results layout uses `height: calc(100vh - 75px)` with `overflow: hidden` for the two-panel section — the address bar should be ABOVE that container, in normal flow.

**Warning signs:** Dropdown appears cut off or behind other content.

### Pitfall 2: place_changed Fires with No Geometry (User Presses Enter Without Selecting)

**What goes wrong:** If a user types text and presses Enter without selecting a suggestion, `place_changed` fires but `autocomplete.getPlace()` returns an object without `formatted_address` (it only has `name` equal to whatever the user typed).

**Why it happens:** The Google Autocomplete class fires `place_changed` on keyboard Enter even without a selection to support "first result" behavior in some configurations.

**How to avoid:** The existing hook already checks `if (place?.formatted_address)` before calling `onPlaceSelected`. This means `hasValidSelection` stays `false` when Enter is pressed without a dropdown selection. The Search button remains disabled. This is the correct behavior and aligns with the locked decision.

**Warning signs:** Submitting raw text to the backend — would return unexpected results from the geocoder.

### Pitfall 3: formattedAddress State Sync on Back Navigation

**What goes wrong:** When a user navigates back to Results from a Profile page, `sessionStorage.getItem('ev:results')` restores list data. But `formattedAddress` from `usePoliticianData` starts as `""` (the hook doesn't run because `cachedResult` is set). The address bar appears empty even though results are shown.

**Why it happens:** The `formattedAddress` is only populated by the hook's address-search branch when the hook actually fires. On cache-restore, the hook is gated (`enabled: !!activeQuery && !cachedResult`).

**How to avoid:** When restoring from cache, also restore the address input from the URL's `?q=` parameter. The `queryFromUrl` value (already available in Results.jsx) is the `encoded` address string — decode it and pre-populate `addressInput`.

```javascript
// In Results.jsx useState initialization
const [addressInput, setAddressInput] = useState(
  queryFromUrl ? decodeURIComponent(queryFromUrl) : ''
);
```

### Pitfall 4: ZIP Param Remnants in URL State

**What goes wrong:** The Results page currently reads both `searchParams.get('zip')` and `searchParams.get('q')`. After Phase 28, Landing no longer navigates to `?zip=`, but a user with an old bookmark might still land on `?zip=90210`. Also, the `handleZipSubmit` function currently checks `/^\d{5}$/.test(normalized)` and sets `{ zip: normalized }`.

**Why it happens:** Legacy navigation paths not cleaned up.

**How to avoid:** In Results.jsx, remove `zipFromUrl` state entirely. Remove `handleZipSubmit`. The only URL parameter is `?q=`. If someone arrives with `?zip=`, the page will show an empty address bar (fine — they can enter a new address). Or optionally redirect `?zip=X` to `?q=X` for graceful degradation.

**Warning signs:** `fetchPoliticiansOnce` (the ZIP-specific endpoint `/essentials/politicians/{zip}`) being called from Results after Phase 28.

### Pitfall 5: FilterSidebar in ev-ui Requires Publish to Change

**What goes wrong:** Any changes to `ev-ui/src/FilterSidebar.jsx` require running `npm run build` in `ev-ui`, bumping the version in `package.json`, publishing to the GitHub npm registry, and updating the version reference in `essentials/package.json`. This is a multi-step process.

**Why it happens:** `ev-ui` is a published component library, not a local import.

**How to avoid:** For the sidebar changes in Phase 28 (adding name search + candidates toggle, removing address input), build a local `FilterSidebar` replacement directly in `essentials/src/components/`. Import it locally. The ev-ui `FilterSidebar` stops being used in the Results page. This avoids the publish cycle for prototype-phase iteration.

---

## Code Examples

Verified patterns from official sources and existing codebase:

### Extended Hook with loadError

```javascript
// src/hooks/useGooglePlacesAutocomplete.js (extended)
import { useEffect, useRef, useState } from 'react';
import { setOptions, importLibrary } from '@googlemaps/js-api-loader';

const API_KEY = import.meta.env.VITE_GOOGLE_MAPS_API_KEY;

function ensureConfigured() {
  if (API_KEY && !window.google?.maps?.importLibrary) {
    setOptions({ key: API_KEY });
  }
}

export default function useGooglePlacesAutocomplete(inputRef, { onPlaceSelected }) {
  const callbackRef = useRef(onPlaceSelected);
  callbackRef.current = onPlaceSelected;
  const [loadError, setLoadError] = useState(false);

  useEffect(() => {
    if (!API_KEY || !inputRef.current) {
      // No API key = always degraded
      if (!API_KEY) setLoadError(true);
      return;
    }

    let autocomplete = null;
    ensureConfigured();

    importLibrary('places')
      .then((placesLib) => {
        if (!inputRef.current) return;
        autocomplete = new placesLib.Autocomplete(inputRef.current, {
          componentRestrictions: { country: 'us' },
          fields: ['formatted_address', 'address_components'],
          types: ['geocode'],
        });
        autocomplete.addListener('place_changed', () => {
          const place = autocomplete.getPlace();
          if (place?.formatted_address) {
            callbackRef.current(place.formatted_address);
          }
        });
      })
      .catch(() => {
        setLoadError(true);
      });

    return () => {
      if (autocomplete) {
        google.maps.event.clearInstanceListeners(autocomplete);
      }
    };
  }, [inputRef]);

  return { loadError };
}
// Source: Existing codebase + importLibrary docs (/googlemaps/js-api-loader)
```

### Landing Page — Address-Only Search

```jsx
// src/pages/Landing.jsx (after Phase 28)
import { useState, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { SiteHeader } from '@chrisandrewsedu/ev-ui';
import useGooglePlacesAutocomplete from '../hooks/useGooglePlacesAutocomplete';

export default function Landing() {
  const [addressInput, setAddressInput] = useState('');
  const [hasValidSelection, setHasValidSelection] = useState(false);
  const [showSelectionHint, setShowSelectionHint] = useState(false);
  const navigate = useNavigate();
  const inputRef = useRef(null);

  const { loadError } = useGooglePlacesAutocomplete(inputRef, {
    onPlaceSelected: (formattedAddress) => {
      setAddressInput(formattedAddress);
      setHasValidSelection(true);
      setShowSelectionHint(false);
    },
  });

  const handleInputChange = (e) => {
    setAddressInput(e.target.value);
    setHasValidSelection(false);  // reset on manual edit
    setShowSelectionHint(false);
  };

  const handleSearch = () => {
    if (!hasValidSelection) {
      setShowSelectionHint(true);
      return;
    }
    navigate(`/results?q=${encodeURIComponent(addressInput)}`);
  };

  return (
    <div className="min-h-screen bg-[var(--ev-bg-light)]">
      <SiteHeader logoSrc="/EVLogo.svg" />
      <main className="container mx-auto px-4 sm:px-6 py-16">
        {/* ... layout ... */}
        <p className="text-xl text-gray-700 mb-8">
          Enter your address to see who represents you
        </p>
        <div className="flex flex-col sm:flex-row gap-3">
          <input
            ref={inputRef}
            type="text"
            value={addressInput}
            onChange={handleInputChange}
            placeholder="Enter your address"
            disabled={loadError}
            className="flex-1 min-w-0 px-4 py-3 text-lg border border-gray-300 rounded-lg
                       focus:outline-none focus:ring-2 focus:ring-[var(--ev-teal)]
                       bg-white shadow-sm disabled:bg-gray-100 disabled:cursor-not-allowed"
          />
          <button
            onClick={handleSearch}
            disabled={!addressInput.trim() || loadError}
            className="px-4 sm:px-8 py-3 text-lg font-bold text-white bg-[var(--ev-teal)]
                       rounded-lg hover:bg-[var(--ev-teal-dark)] disabled:opacity-50
                       disabled:cursor-not-allowed transition-colors"
          >
            Search
          </button>
        </div>
        {loadError && (
          <p className="mt-2 text-sm text-red-600">
            Address search is temporarily unavailable. Please try again later.
          </p>
        )}
        {showSelectionHint && !loadError && (
          <p className="mt-2 text-sm text-amber-700">
            Please select an address from the suggestions.
          </p>
        )}
      </main>
    </div>
  );
}
```

### Results Page — Address Bar (Top, Full-Width)

```jsx
// Address bar section at top of Results.jsx (above the two-panel div)
<div className="px-4 sm:px-8 py-3 border-b border-gray-200 bg-white">
  <div className="flex gap-3">
    <input
      ref={addressInputRef}  // separate ref from sidebar
      type="text"
      value={addressInput}
      onChange={handleInputChange}
      placeholder="Enter your address"
      disabled={loadError}
      className="flex-1 min-w-0 px-4 py-2 border border-gray-300 rounded-lg
                 focus:outline-none focus:ring-2 focus:ring-[var(--ev-teal)]
                 disabled:bg-gray-100 disabled:cursor-not-allowed"
    />
    <button
      onClick={handleAddressSearch}
      disabled={!hasValidSelection || loadError}
      className="px-6 py-2 font-bold text-white bg-[var(--ev-teal)] rounded-lg
                 hover:bg-[var(--ev-teal-dark)] disabled:opacity-50 transition-colors"
    >
      Search
    </button>
  </div>
  {loadError && (
    <p className="mt-1 text-sm text-red-600">
      Address search is temporarily unavailable. Please try again later.
    </p>
  )}
  {showSelectionHint && !loadError && (
    <p className="mt-1 text-sm text-amber-700">
      Please select an address from the suggestions.
    </p>
  )}
  {dataStatus === 'no-geofence-data' && activeQuery && !loadError && (
    <p className="mt-2 text-sm text-amber-700 bg-amber-50 border border-amber-200 rounded px-3 py-2">
      Local representative data is not yet available for this area.
      Showing federal and state officials based on your state.
    </p>
  )}
</div>
```

### sessionStorage — Restore Address on Back Navigation

```javascript
// In Results.jsx
const queryFromUrl = searchParams.get('q') || '';

// Initialize address input from URL (for back-nav cache restore case)
const [addressInput, setAddressInput] = useState(
  queryFromUrl ? decodeURIComponent(queryFromUrl) : ''
);
// hasValidSelection: true only if URL has a q= param (it was set by a prior valid search)
const [hasValidSelection, setHasValidSelection] = useState(!!queryFromUrl);
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Autocomplete` class (Legacy) | `PlaceAutocompleteElement` (Web Component) | March 2025 Google Maps API update | New API has session token cost optimization; legacy still works; migration deferred per REQUIREMENTS.md |
| ZIP + address dual input | Address-only (Phase 28) | Phase 28 | Simpler UX, backend already handles address-only |
| Spinner during load | Loading skeletons (Phase 28) | Phase 28 | Better perceived performance |

**Deprecated/outdated:**
- `fetchPoliticiansProgressive`: dead code after Phase 28 (never called after ZIP removal) — leave for now, remove in Phase 29 cleanup
- `fetchPoliticiansOnce`: similarly dead code if no ZIP path — leave for Phase 29

---

## Open Questions

1. **ev-ui FilterSidebar: local replacement vs. publish new version?**
   - What we know: The sidebar needs name search + candidates toggle added; address input removed. These are new props/functionality.
   - What's unclear: Whether the planner prefers a local `LocalFilterSidebar` component (faster) or a new ev-ui version (cleaner long-term).
   - Recommendation: Use a local component in `essentials/src/components/LocalFilterSidebar.jsx` for Phase 28. Add a note to update ev-ui in a future phase. Avoids npm publish during a refactor-heavy phase.

2. **`types: ['geocode']` vs `types: ['address']` in Autocomplete options**
   - What we know: Current hook uses `['geocode']` which returns all geographic types (addresses, localities, regions). `['address']` restricts to street-level addresses only.
   - What's unclear: Whether city-level searches like "Bloomington, IN" should be allowed (they work with `'geocode'`, not with `'address'`).
   - Recommendation: Keep `['geocode']` — allows users to enter just a city name and still get valid results. The backend geocoder handles both fine.

3. **What happens on Results page when `activeQuery` is empty (direct navigation to /results)?**
   - What we know: Currently, Results initializes `zip` state from `zipFromUrl || queryFromUrl`. After Phase 28, only `queryFromUrl` matters. If empty, no search fires (hook gated).
   - What's unclear: Should `/results` with no params redirect to `/` (Landing)?
   - Recommendation: Keep current behavior — show empty address bar, wait for user to enter an address. No redirect needed.

---

## Sources

### Primary (HIGH confidence)
- `/googlemaps/js-api-loader` (Context7) — `importLibrary`, Promise rejection behavior, `setOptions` pattern
- `/websites/developers_google_maps_javascript_reference` (Context7) — `Autocomplete` class, `place_changed` event, `formatted_address` field, `ComponentRestrictions`
- Existing codebase — `useGooglePlacesAutocomplete.js`, `Results.jsx`, `Landing.jsx`, `usePoliticianData.js`, `api.jsx`, `FilterSidebar.jsx`, `handlers.go` (SearchPoliticians function)

### Secondary (MEDIUM confidence)
- Google Maps JS API official docs via Context7 — `PlaceAutocompleteElement` shadow DOM behavior (verified in STATE.md blocker note)
- REQUIREMENTS.md Out of Scope table — `PlaceAutocompleteElement` migration deferred

### Tertiary (LOW confidence)
- None — all key claims verified against source code or official docs

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries already installed and in use; no new dependencies
- Architecture: HIGH — all patterns derived from existing code + official docs; no novel patterns
- Pitfalls: HIGH — derived from direct code inspection of Results.jsx, Landing.jsx, FilterSidebar.jsx, handlers.go

**Research date:** 2026-02-22
**Valid until:** 2026-03-22 (Google Maps API stable; library versions fixed)
