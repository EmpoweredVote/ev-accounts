---
phase: 122-cross-app-loop-polish
reviewed: 2026-04-17T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - essentials/src/lib/treasury.js
  - essentials/src/contexts/CompassContext.jsx
  - essentials/src/pages/Results.jsx
  - ev-accounts/tests/integration/treasury-cities.test.ts
findings:
  critical: 0
  warning: 3
  info: 4
  total: 7
status: issues_found
---

# Phase 122: Code Review Report

**Reviewed:** 2026-04-17
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

Four files were reviewed covering the INTG-03 Treasury CTA feature, the cross-app compass loop, and the essentials Results page. No critical security or data-loss issues were found. There are three warnings — all in `Results.jsx` — involving a stale closure in a `useMemo`, a missing error path in the elections fetch, and a dependency array lint suppression that papers over a real issue. Four informational items cover dead code, a subtle edge case in the slug builder, and a suppressed lint warning in the test file.

`treasury.js` and `treasury-cities.test.ts` are clean. `CompassContext.jsx` is well-structured; the one lint suppression it carries (`eslint-disable-line react-hooks/exhaustive-deps` on the `logout` dependency of the memoised value) is handled correctly because `logout` is a stable closure defined inside the component but outside the `useMemo` dep array — no bug, just an info note.

---

## Warnings

### WR-01: `filteredHierarchy` useMemo suppresses `matchesAppointedFilter` dependency

**File:** `essentials/src/pages/Results.jsx:499`
**Issue:** The `filteredHierarchy` memo calls `matchesAppointedFilter` (line 494) but that function is defined inside the component body (line 409) and is not listed in the dependency array. The `eslint-disable-line react-hooks/exhaustive-deps` comment silences the warning. Because `matchesAppointedFilter` closes over nothing mutable this is currently safe, but if the function's body ever reads from component state or props the stale closure will silently return wrong results without a lint warning.

**Fix:** Lift `matchesAppointedFilter` outside the component (it takes all its inputs as parameters and has no implicit dependencies), then remove the eslint suppression:
```js
// Outside the component, near top of file
function matchesAppointedFilter(pol, filter) {
  if (filter === 'All') return true;
  const isAppointed = pol.is_appointed === true || !pol.is_elected;
  if (filter === 'Elected') return !isAppointed || pol.faces_retention_vote === true;
  if (filter === 'Appointed') return isAppointed;
  return true;
}
```
Also inline `resolveIsAppointed` into it (or hoist both), then remove the `// eslint-disable-line` comment on line 499.

---

### WR-02: Elections fetch silently swallows network errors

**File:** `essentials/src/pages/Results.jsx:344-351`
**Issue:** The elections `useEffect` calls `fetchElectionsByAddress(...).then(...)` with no `.catch()`. If the fetch rejects (network error, non-ok response), `electionsLoading` stays `true` forever and the user sees an infinite spinner with no error message. The representatives tab handles errors via the `error` state returned from `usePoliticianData`; elections has no equivalent.

**Fix:**
```js
fetchElectionsByAddress(decodeURIComponent(activeQuery))
  .then((data) => {
    if (!cancelled) {
      setElectionsData(data.elections || []);
      setElectionsLoading(false);
    }
  })
  .catch(() => {
    if (!cancelled) {
      setElectionsData([]);   // treat error as empty — show no-elections state
      setElectionsLoading(false);
    }
  });
```

---

### WR-03: `mainRef.current` used as `useEffect` dependency

**File:** `essentials/src/pages/Results.jsx:542`
**Issue:** `mainRef.current` is listed as a dependency of the scroll-spy `useEffect` (line 542). Refs are mutable objects — React does not track changes to `.current`, so listing it in a dependency array does not re-run the effect when the DOM node mounts. On the first render, `mainRef.current` is `null`; the effect runs with a `null` root in `IntersectionObserver`, which falls back to the viewport (masking the bug). If the component ever remounts with a non-null ref, the effect would not re-run. The correct pattern is to use a `useCallback` ref or run the effect unconditionally and read `mainRef.current` at setup time.

**Fix:** Remove `mainRef.current` from the dependency array and read it inside the effect body:
```js
useEffect(() => {
  if (selectedFilter !== 'All') return;
  const root = isDesktop ? mainRef.current : null;
  const observer = new IntersectionObserver(
    (entries) => { /* ... */ },
    { root, rootMargin: '-40% 0px -60% 0px', threshold: 0 }
  );
  // ...
}, [selectedFilter, isDesktop]); // mainRef.current removed
```

---

## Info

### IN-01: `toTreasurySlug` does not strip dots or commas from state abbreviation

**File:** `essentials/src/lib/treasury.js:33-36`
**Issue:** The state sanitisation only strips `/ ? #`. If the API ever returns a state value containing a dot (e.g. "IN." from a data-entry typo) or other URL-unsafe characters, the slug would be malformed. The name sanitisation is comprehensive; the state branch should match it.

**Fix:**
```js
const state = city.state
  .toLowerCase()
  .replace(/[^a-z0-9-]/g, '');  // allow only slug-safe chars
return `${name}-${state}`;
```

---

### IN-02: `formatElectionDate` constructs `Date` from string without timezone handling

**File:** `essentials/src/pages/Results.jsx:42-46`
**Issue:** `new Date(dateStr)` on a bare date string like `"2026-11-03"` is parsed as UTC midnight, then rendered with `toLocaleDateString` in the user's local timezone. In timezones west of UTC, this displays as the previous month. This is a minor display issue, not data corruption.

**Fix:**
```js
function formatElectionDate(dateStr) {
  if (!dateStr) return '';
  // Append T12:00:00 to force local-noon parsing, avoiding UTC offset rollback
  const d = new Date(`${dateStr}T12:00:00`);
  if (isNaN(d.getTime())) return dateStr;
  return d.toLocaleDateString('en-US', { month: 'short', year: 'numeric' });
}
```

---

### IN-03: `logout` missing from `useMemo` dependency array in `CompassContext`

**File:** `essentials/src/contexts/CompassContext.jsx:262-277`
**Issue:** The `useMemo` that builds the context value includes `logout` in the returned object (line 260) but not in the dependency array (lines 262-277). This means if `logout` were ever redefined between renders, consumers would hold a stale reference. In practice `logout` is defined once per mount (not inside the dep array cycle), so this is harmless today. However it is an inconsistency that could confuse future maintainers.

**Fix:** Either add `logout` to the dependency array, or wrap `logout` in `useCallback` (with `[]` deps) and add it to the memo deps:
```js
const logout = useCallback(async () => { /* ... */ }, []);
// Then add logout to the useMemo dep array
```

---

### IN-04: Test skips shape validation when the database is empty

**File:** `ev-accounts/tests/integration/treasury-cities.test.ts:46`
**Issue:** The shape test uses an early `return` when `cities.length === 0` (line 46). This means the contract test passes vacuously in a fresh dev environment with no treasury data loaded. If the endpoint starts returning `[]` due to a regression, the test still passes. The comment acknowledges this ("Shape test applies only when there is at least one city"), which is reasonable for an integration test against a real DB, but it should be documented as a known gap.

**Fix:** No code change required if the intent is deliberate. Consider adding a comment that cites the known gap and the condition under which the test provides full coverage:
```ts
// NOTE: shape contract is only verified when at least one city exists in the DB.
// In CI this requires treasury seed data. Without it, the test provides
// partial coverage (200 + array) only.
if (cities.length === 0) return;
```

---

_Reviewed: 2026-04-17_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
