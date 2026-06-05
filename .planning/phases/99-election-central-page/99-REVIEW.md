---
phase: 99-election-central-page
reviewed: 2026-06-05T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - backend/src/lib/electionService.ts
  - backend/src/routes/essentials.ts
  - tests/integration/essentials-elections.test.ts
  - backend/migrations/267_ut_2026_primary.sql
  - C:\Transparent Motivations\essentials\src\components\ElectionsView.jsx
  - C:\Transparent Motivations\essentials\src\App.jsx
findings:
  critical: 3
  warning: 5
  info: 3
  total: 11
status: issues_found
---

# Phase 99: Code Review Report

**Reviewed:** 2026-06-05T00:00:00Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Phase 99 delivers Elections Central — a `/elections` route with an `ElectionsRedirect` async component, two new backend API endpoints (`GET /elections` and `GET /elections-by-address`), a stored-geo-id path (`GET /elections/me`), the `getElectionsByCoordinate` / `getElectionsByGeoIds` service functions, and a Utah 2026 Primary data migration.

The implementation is generally solid: parameterized queries throughout, correct PostGIS lon/lat argument order (well-commented), and the antipartisan subgroup-label fix is correctly applied. Three blocking issues were found: unvalidated lat/lng ranges that can produce illegal PostGIS coordinates (and send arbitrary float values into a geo query), a cross-race candidate deduplication bug that silently drops a candidate from one race if the same `candidate_id` appears in a second race, and the `ElectionsRedirect` component having no error handler, leaving users stranded on a blank page on any `loadUserAddressFromContext` rejection. Five additional warnings and three informational items are noted below.

---

## Critical Issues

### CR-01: No lat/lng range validation — arbitrary floats reach PostGIS

**File:** `backend/src/routes/essentials.ts:79-84`

**Issue:** The `/elections` endpoint calls `parseFloat()` on `req.query.lat` and `req.query.lng` and only rejects `NaN`. It does not validate that `lat` is in `[-90, 90]` or `lng` is in `[-180, 180]`. A caller can supply `?lat=9999&lng=99999`, which is numerically valid but geometrically meaningless. PostGIS will silently construct an out-of-bounds point (`ST_MakePoint(99999, 9999)`) and evaluate the spatial query against it, returning an empty result without error. The caller receives `{ elections: [] }` indistinguishable from a valid no-coverage result, masking bad data. More importantly, there is no rate-limiting guard shown in this route, so the unvalidated path also constitutes a minor denial-of-service surface (repeated large-coordinate PostGIS calls).

**Fix:**
```typescript
const lat = parseFloat(req.query.lat as string);
const lng = parseFloat(req.query.lng as string);

if (isNaN(lat) || isNaN(lng) || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
  res.status(422).json({
    code: 'VALIDATION_ERROR',
    message: 'lat must be in [-90, 90] and lng must be in [-180, 180]',
  });
  return;
}
```

---

### CR-02: Cross-race candidate deduplication drops candidates who appear in two races

**File:** `backend/src/lib/electionService.ts:244-251` (same logic repeated at lines 452-458 and 658-664)

**Issue:** The deduplication loop tracks `candidate_id` values in a single `seenCandidates` set across _all_ rows from both the district query and the statewide query. If a candidate record legitimately appears in two different races (e.g., a candidate who ran in both a special and a regular primary in the same cycle, or a data entry that links one `race_candidate` row to multiple races), the second occurrence is silently dropped. The first row's `race_id` wins and the candidate is never added to the second race's `candidates[]` array.

The comment says "deduplicate by candidate_id" but the intent is to deduplicate candidates within a single race, not globally across all races. Because `LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id` produces one row per (race, candidate) pair, and `DISTINCT` is on the outer query, the same `candidate_id` can legitimately appear under two different `race_id` values only if the data contains an error — but the fix should be a per-race deduplication or an assertion, not silent cross-race suppression.

The practical impact: if the statewide query and the district query return the same (election, race, candidate) combination (which `DISTINCT` should prevent but which can occur with the two-query architecture), the second row is dropped before the race map is populated, so the race entry from the second query has zero candidates even though it should have one.

**Fix:** Scope deduplication to `(race_id, candidate_id)` pairs rather than bare `candidate_id`:

```typescript
const seenCandidates = new Set<string>();
const dedupedRows = allRows.filter((row) => {
  if (row.candidate_id !== null) {
    const key = `${row.race_id}:${row.candidate_id}`;
    if (seenCandidates.has(key)) return false;
    seenCandidates.add(key);
  }
  return true;
});
```

Apply the same fix at all three call sites (lines 244–251, 452–458, 658–664).

---

### CR-03: `ElectionsRedirect` has no `.catch()` — rejection leaves users on a blank page forever

**File:** `C:\Transparent Motivations\essentials\src\App.jsx:45-55`

**Issue:** `loadUserAddressFromContext` is called with `.then()` but no `.catch()`. The implementation of `loadUserAddressFromContext` in `compass.js` wraps its body in a `try/catch` that returns `null` on error, so normal errors are absorbed. However, the `.then()` callback itself (`if (cancelled) return; if (stored?.addr) { ... }`) can throw if `stored` is an unexpected non-null non-object value (edge case). More concretely, because the `useEffect` has no error boundary, any unhandled rejection from the `.then()` chain will leave `to` at `null` permanently — the component renders `null` (a blank page) and never navigates. There is no timeout guard either: if `loadUserAddressFromContext` hangs (IndexedDB lock on some browsers), the user is stranded indefinitely.

**Fix:** Add a `.catch()` fallback that forces navigation to the no-address results page:

```javascript
useEffect(() => {
  let cancelled = false;
  loadUserAddressFromContext()
    .then((stored) => {
      if (cancelled) return;
      if (stored?.addr) {
        setTo(`/results?prefilled=true&view=elections&q=${encodeURIComponent(stored.addr)}`);
      } else {
        setTo('/results?prefilled=true&view=elections');
      }
    })
    .catch(() => {
      if (!cancelled) setTo('/results?prefilled=true&view=elections');
    });
  return () => { cancelled = true; };
}, []);
```

---

## Warnings

### WR-01: Non-null assertions on nullable SQL columns can throw at runtime

**File:** `backend/src/lib/electionService.ts:291-298` (also lines 496-505, 706-715)

**Issue:** When a candidate row is pushed onto a race's `candidates` array, three fields are accessed with non-null assertions (`!`):

```typescript
full_name: row.full_name!,
is_incumbent: row.is_incumbent!,
candidate_status: row.candidate_status!,
```

The `ElectionRow` interface declares all three as `string | null` or `boolean | null`. These columns are `LEFT JOIN`ed: if a `race_candidates` row somehow has a `NULL full_name` (schema may not enforce `NOT NULL`), or if the join produces a null row (possible when `LEFT JOIN race_candidates` produces a null-candidate row for a race with no candidates), the non-null assertion will propagate a `null` value through into the typed object without throwing — TypeScript non-null assertions are compile-time only and have no runtime effect. This means `full_name: null` gets assigned to a field typed as `string`, which then surfaces as `null` in the API response where the frontend expects a string.

The guard `if (row.candidate_id !== null)` (lines 288/495/705) protects against null-join rows, so for normal data this is benign. However, if `full_name` is ever actually NULL in the DB, the data silently leaks through as `null` despite the `!` assertion.

**Fix:** Add explicit fallbacks or enforce NOT NULL on `full_name` and `candidate_status` at the schema layer. At minimum, add runtime guards:

```typescript
full_name: row.full_name ?? '',
is_incumbent: row.is_incumbent ?? false,
candidate_status: row.candidate_status ?? 'unknown',
```

---

### WR-02: `elections/me` Path 1.5 uses `j.jurisdiction_state` (potentially stale) instead of the freshly-resolved state

**File:** `backend/src/routes/essentials.ts:779`

**Issue:** In the Path 1.5 branch of `/elections/me`, after `resolve_user_jurisdiction` resolves district geo-ids from encrypted coordinates, `getElectionsByGeoIds` is called with `j.jurisdiction_state` (the value stored on `connected_profiles`) as the state parameter rather than deriving the state from the resolved jurisdiction data. If the user has moved and their stored `jurisdiction_state` is stale (not yet updated), the statewide elections query will use the wrong state. By contrast, the write-back updates `congressional_geo_id`, `state_senate_geo_id`, etc., but does NOT write `jurisdiction_state` — so it will remain stale even after Path 1.5 runs. The representative path in the same handler (lines 638-675) has the same pattern but this is specifically problematic for elections since statewide races (Governor, US Senate) are matched entirely by `e.state`.

**Fix:** Derive state from the resolved district data when available. The RPC response already includes `jd.state_senate` which can be cross-referenced with `essentials.districts.state`, or the write-back block should also update `jurisdiction_state` from the resolved data:

```typescript
// In the write-back query, also set:
// jurisdiction_state = $13 -- derived from the resolved state if available
```

Or, for the statewide query call, extract state from the resolved geo-ids by querying `essentials.districts` (similar to the `stateQueryText` approach used in `getElectionsByGovernmentGeoIds`).

---

### WR-03: `inferDistrictType` "attorney" catch catches "district attorney" — LOCAL wins over COUNTY for county attorney offices

**File:** `backend/src/lib/electionService.ts:101-102`

**Issue:** In `inferDistrictType`, the LOCAL catch-all condition at line 101–102 includes:

```typescript
(p.includes('attorney') && !p.includes('attorney general'))
```

The position name "Salt Lake County District Attorney" (seeded in migration 267) contains "attorney" but not "attorney general". The check for "county" appears later on line 103 (`if (p.includes('county') || ...)`) and the LOCAL check fires first. So "Salt Lake County District Attorney" resolves to `LOCAL` instead of `COUNTY`. In `ElectionsView.jsx`'s `deriveBodyAndSubGroup`, `LOCAL` falls through to a township-match which won't match "Salt Lake County District Attorney", returning `{ body: 'Salt Lake County District Attorney', subgroup: 'Salt Lake County District Attorney' }` — losing the county grouping. This means the Salt Lake County District Attorney race appears under a solo "Local" body rather than grouped under "Salt Lake County" alongside the Sheriff and other county offices.

**Fix:** Reorder the LOCAL condition to exclude positions that also contain "county":

```typescript
if ((p.includes('council') || p.includes('commissioner') || ... || 
    (p.includes('attorney') && !p.includes('attorney general') && !p.includes('county'))))
  return 'LOCAL';
if (p.includes('county') || p.includes('supervisor'))
  return 'COUNTY';
```

---

### WR-04: `getElectionsByGovernmentGeoIds` statewide query has misaligned indentation on date filter

**File:** `backend/src/lib/electionService.ts:232-236`

**Issue:** The `AND (` block for the date filter in the statewide sub-query (lines 232–236 inside `getElectionsByGovernmentGeoIds`) is indented two spaces less than the surrounding SQL lines, suggesting a copy-paste misalignment. While functionally harmless, the indentation differs from the identical clause in every other query in the same file (which all use consistent 8-space indentation inside the `WHERE` block). This is the only instance with mismatched indentation. More importantly, it makes it harder to verify the date filter is applied correctly during audits.

**Fix:** Re-indent to match the surrounding SQL:

```sql
        AND (
          (e.election_type != 'general' AND e.election_date >= CURRENT_DATE - INTERVAL '30 days')
          OR (e.election_type = 'general' AND e.election_date >= DATE_TRUNC('year', CURRENT_DATE::date))
        )
```

---

### WR-05: `PostHogPageview` rendered outside `BrowserRouter` — `useLocation` will throw

**File:** `C:\Transparent Motivations\essentials\src\App.jsx:81`

**Issue:** `PostHogPageview` calls `useLocation()` from react-router-dom. In `App()`, `PostHogPageview` is rendered inside `<CompassProvider>` but before `<Routes>` — critically, it is NOT wrapped in `<BrowserRouter>`. The file imports `BrowserRouter` but the `App` component renders it only in... actually, looking at the full file, `App` returns:

```jsx
<CompassProvider ...>
  <PostHogPageview />   {/* <-- useLocation() here, no Router ancestor */}
  <Routes>...</Routes>
</CompassProvider>
```

There is no `<BrowserRouter>` wrapping the `CompassProvider`. This means `useLocation()` inside `PostHogPageview` will throw `Error: useLocation() may be used only in the context of a <Router> component` at runtime unless a `BrowserRouter` (or equivalent) is provided by a parent component (e.g., in `main.jsx`). If the app currently works, it is because `main.jsx` wraps the whole app in `BrowserRouter` — but that dependency is invisible from this file. The `BrowserRouter` import in `App.jsx` (line 3) is unused, which confirms it was either removed from `App.jsx` or was always in `main.jsx`. The unused import is a dead code smell and can mislead future maintainers into thinking the `<BrowserRouter>` is provided here.

**Fix:** Remove the unused `BrowserRouter` import. Confirm `main.jsx` wraps `<App>` in `<BrowserRouter>`. Document this dependency with a comment.

---

## Info

### IN-01: Migration 267 omits all 171 candidate INSERT statements

**File:** `backend/migrations/267_ut_2026_primary.sql:172-174`

**Issue:** The migration file contains a comment "Candidates omitted from this file for brevity — all 171 were applied via execute_sql batches." This means the migration file as committed is NOT idempotent and NOT self-contained. Re-running the migration against a fresh database will produce 138 empty races with no candidates. Any future developer running migrations from scratch (disaster recovery, staging environment setup) will get a broken seeding state for Utah 2026 without any warning at runtime.

**Fix:** Include the full 171 candidate `INSERT` statements in this file with `ON CONFLICT DO NOTHING` guards, matching the rest of the migration's idempotent pattern. The "applied via execute_sql batches" note describes the execution method, not a reason to omit them from the canonical migration file.

---

### IN-02: `ElectionsView.jsx` — `deriveCardTitleSubtitle` returns `'Indiana Circuit Court Judge'` hardcoded for all JUDICIAL positions

**File:** `C:\Transparent Motivations\essentials\src\components\ElectionsView.jsx:103`

**Issue:** The `deriveCardTitleSubtitle` function has an early-exit for `districtType === 'JUDICIAL'` that hardcodes the title as `'Indiana Circuit Court Judge'`. Utah (the migration target for Phase 99) has no judicial races in migration 267, so this does not affect the current data, but the function is part of the shared `ElectionsView` component that will be used for elections in any state. Any non-Indiana judicial race will display "Indiana Circuit Court Judge" as the card title.

**Fix:** Replace the hardcoded string with a dynamic derivation. For the court name, fall back to extracting from `positionName` rather than assuming Indiana:

```javascript
if (districtType === 'JUDICIAL') {
  const courtMatch = pos.match(/^(?:Judge of the\s+)?(.+?Court)/i);
  const courtTitle = courtMatch ? `${courtMatch[1]} Judge` : 'Circuit Court Judge';
  // ...subtitle derivation unchanged
  return { title: courtTitle, subtitle: subtitle || undefined };
}
```

---

### IN-03: Test file hardcodes real credentials in `process.env` at module scope

**File:** `tests/integration/essentials-elections.test.ts:7-10`

**Issue:** The test file sets `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, and `DATABASE_URL` to placeholder strings at module load time. While these are clearly test stubs (not real credentials), the pattern of setting `SUPABASE_SERVICE_ROLE_KEY` at the top of a test file as a hardcoded string is a bad practice pattern. If a developer copies this test as a template and accidentally substitutes a real service role key, it becomes a credential leak risk. The `DATABASE_URL` value `postgresql://postgres:password@localhost:5432/postgres` uses the literal string `"password"` which some secret-scanning tools will flag as a hardcoded credential.

**Fix:** Move test environment variable setup to a dedicated `vitest.setup.ts` or `vitest.config.ts` environment block, and replace the hardcoded `password` with a clearly fake placeholder like `PLACEHOLDER_NOT_REAL`. This is low-severity but reduces false positives in secret scanning CI steps.

---

_Reviewed: 2026-06-05T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
