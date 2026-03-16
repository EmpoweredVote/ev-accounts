---
phase: 90-location-based-filtering
plan: 01
subsystem: ui
tags: [react, zustand, google-maps, typescript, framer-motion]

# Dependency graph
requires: []
provides:
  - LocationFilter interface and locationFilter state in Zustand store (v7)
  - setLocationFilter/clearLocationFilter store actions persisted to localStorage
  - searchPoliticians API function (POST /essentials/politicians/search)
  - useGooglePlacesAutocomplete TypeScript hook
  - AddressFilterInput component with two UX states (input and filter chip)
affects: [90-02-location-based-filtering]

# Tech tracking
tech-stack:
  added: ["@googlemaps/js-api-loader", "@types/google.maps"]
  patterns:
    - "Google Maps Places autocomplete attached to input via hook with inputRef pattern"
    - "Zustand partialize persists locationFilter across page reloads"

key-files:
  created:
    - EV-readrank/src/hooks/useGooglePlacesAutocomplete.ts
    - EV-readrank/src/components/AddressFilterInput.tsx
  modified:
    - EV-readrank/src/store/useReadRankStore.ts
    - EV-readrank/src/data/api.ts
    - EV-readrank/package.json
    - EV-readrank/tsconfig.app.json

key-decisions:
  - "window.google guard added to autocomplete cleanup — prevents runtime error when Maps SDK unavailable during effect teardown"
  - "google.maps added to tsconfig.app.json types array — required for TypeScript to resolve google.maps.places namespace"
  - "noMatchWarning is local state (not store) — ephemeral UI feedback, no persistence needed"

patterns-established:
  - "useGooglePlacesAutocomplete: RefObject<HTMLInputElement | null> signature for React 19 compatibility"
  - "callbackRef pattern (useRef wrapping onPlaceSelected) prevents stale closure on place_changed listener"

requirements-completed: [LOC-01, LOC-05]

# Metrics
duration: 26min
completed: 2026-03-16
---

# Phase 90 Plan 01: Location Filter Foundation Summary

**Zustand store v7 with LocationFilter state, Google Places autocomplete TypeScript hook, searchPoliticians API, and AddressFilterInput component with filter chip UX**

## Performance

- **Duration:** ~26 min
- **Started:** 2026-03-16T01:04:32Z
- **Completed:** 2026-03-16T01:30:37Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Store bumped to v7 with LocationFilter interface (`{ address, politicianIds }`), persisted via partialize, clean migrate for returning users
- `searchPoliticians(query)` function added to api.ts — POST to `/essentials/politicians/search`, reads custom response headers, handles errors gracefully
- TypeScript port of essentials `useGooglePlacesAutocomplete.js` with React 19 ref types and window.google cleanup guard
- `AddressFilterInput` component: renders address text input with Places autocomplete, collapses to compact filter chip after selection, shows zero-match warning auto-cleared after 3s

## Task Commits

Each task was committed atomically (in EV-readrank repo):

1. **Task 1: Store v7 migration, searchPoliticians API, install dependencies** - `dd8846c` (feat)
2. **Task 2: useGooglePlacesAutocomplete TS hook + AddressFilterInput component** - `d05bf1a` (feat)

## Files Created/Modified
- `EV-readrank/src/store/useReadRankStore.ts` - Added LocationFilter interface, locationFilter state, setLocationFilter/clearLocationFilter actions, bumped persist version to 7
- `EV-readrank/src/data/api.ts` - Added SearchPolitician, SearchPoliticiansResult interfaces and searchPoliticians async function
- `EV-readrank/src/hooks/useGooglePlacesAutocomplete.ts` - TypeScript port of Essentials hook with window.google guard and explicit google.maps.places type cast
- `EV-readrank/src/components/AddressFilterInput.tsx` - Address input / filter chip component with AnimatePresence transitions, spinner, zero-match warning
- `EV-readrank/package.json` - Added @googlemaps/js-api-loader (dep) and @types/google.maps (devDep)
- `EV-readrank/tsconfig.app.json` - Added google.maps to types array for TypeScript resolution

## Decisions Made
- `window.google` guard added in useGooglePlacesAutocomplete cleanup: the Essentials JS version calls `google.maps.event.clearInstanceListeners` without guarding, which throws if Maps SDK hasn't loaded. TypeScript port adds the guard explicitly.
- `google.maps` added to `tsconfig.app.json` types array: the `@types/google.maps` package declares globals but tsconfig only included `vite/client` — build failed with `Cannot find namespace 'google'` until this was added.
- `noMatchWarning` kept as local component state (not Zustand): it's transient UI feedback (3s auto-clear), no benefit to persisting it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed unused React import in AddressFilterInput.tsx**
- **Found during:** Task 2 (first build attempt)
- **Issue:** `import React` was included but unused, causing `noUnusedLocals` TypeScript error
- **Fix:** Removed the React import; JSX transform in tsconfig handles React automatically
- **Files modified:** EV-readrank/src/components/AddressFilterInput.tsx
- **Verification:** Build passes with no TS errors
- **Committed in:** d05bf1a (Task 2 commit)

**2. [Rule 3 - Blocking] Added google.maps to tsconfig.app.json types**
- **Found during:** Task 2 (first build attempt)
- **Issue:** tsconfig.app.json only listed `vite/client` in types; TypeScript couldn't resolve `google.maps.places` namespace
- **Fix:** Added `google.maps` to the types array in tsconfig.app.json
- **Files modified:** EV-readrank/tsconfig.app.json
- **Verification:** Build passes with no `Cannot find namespace 'google'` errors
- **Committed in:** d05bf1a (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking)
**Impact on plan:** Both auto-fixes necessary for TypeScript build to pass. No scope creep.

## Issues Encountered
None beyond the two TypeScript compilation errors resolved above.

## User Setup Required

Before deploying to Cloudflare Pages:
1. Add `VITE_GOOGLE_MAPS_API_KEY` to EV-readrank Cloudflare Pages environment variables
2. Confirm `POST /essentials/politicians/search` CORS allows `readrank.empowered.vote` in EV-Backend middleware

## Next Phase Readiness
- All primitives for Plan 02 are in place: LocationFilter state + actions, searchPoliticians API, AddressFilterInput component
- Plan 02 can wire AddressFilterInput into IssueHub and apply politician ID filtering in EvaluationPhase

---
*Phase: 90-location-based-filtering*
*Completed: 2026-03-16*
