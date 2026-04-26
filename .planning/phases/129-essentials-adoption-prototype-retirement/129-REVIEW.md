---
phase: 129-essentials-adoption-prototype-retirement
reviewed: 2026-04-26T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - essentials/src/App.jsx
  - essentials/src/lib/classify.js
  - essentials/src/pages/Results.jsx
findings:
  critical: 0
  warning: 5
  info: 5
  total: 10
status: issues_found
---

# Phase 129: Code Review Report

**Reviewed:** 2026-04-26
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Three files reviewed: the app shell (`App.jsx`), the politician classification library (`classify.js`), and the main results page (`Results.jsx`). No security vulnerabilities or data-loss risks found. The most actionable issues are a likely double-`decodeURIComponent` on the elections fetch URL (could corrupt addresses containing `%`), a no-op `useMemo` whose misleading name suggests filtering was intended, a `ref.current` dependency in a `useEffect` dep array (won't re-run when the ref target changes), a misleading display-name mapping for the Federal Judiciary category, and a default-parameter trap in `computeVariant` that silently falls through to `compass`/`empty` instead of `no-stances` when the third argument is omitted. The remaining items are style/dead-code issues.

---

## Warnings

### WR-01: Double `decodeURIComponent` on elections address fetch

**File:** `essentials/src/pages/Results.jsx:458`
**Issue:** `activeQuery` is read from `searchParams.get('q')`, which the browser already URL-decodes. Calling `decodeURIComponent(activeQuery)` a second time will corrupt any address that legitimately contains a `%` character (e.g., a street address stored with a percent-encoded segment). The value is used as the raw address string passed to the elections API, so a malformed decode would produce an incorrect API call.
**Fix:**
```js
// Before
fetchElectionsByAddress(decodeURIComponent(activeQuery)).then(...)

// After — activeQuery from searchParams.get() is already decoded
fetchElectionsByAddress(activeQuery).then(...)
```

---

### WR-02: `filteredPols` useMemo is a no-op — name implies filtering that no longer exists

**File:** `essentials/src/pages/Results.jsx:585`
**Issue:** `const filteredPols = useMemo(() => list, [list])` returns `list` unmodified. The name `filteredPols` is used throughout the component (including in downstream memos), so it implies filtering. The comment on line 584 says "no longer filtering VACANT names" — the intent was apparently to remove client-side filtering, but the variable and memo were left in place. This is dead code that adds noise and could confuse future developers who try to add filtering here.
**Fix:** Either remove the memo and replace `filteredPols` with `list` at each use site, or rename it to `pols` to signal it is unfiltered:
```js
// Simple replacement — no memo needed
const pols = list;
```

---

### WR-03: `ref.current` in `useEffect` dependency array

**File:** `essentials/src/pages/Results.jsx:789`
**Issue:** `mainRef.current` appears in the dependency array of the IntersectionObserver `useEffect`. React does not track mutations to `ref.current`; the effect will NOT re-run when the ref's target DOM node changes (e.g., during the `isDesktop` layout switch). The observer will be attached to the wrong `root` until the component unmounts/remounts.
**Fix:** Use the ref object itself (not `.current`) in the dep array, and read `.current` inside the effect body:
```js
useEffect(() => {
  const root = isDesktop ? mainRef.current : null;
  const observer = new IntersectionObserver(..., { root, ... });
  // ...
}, [selectedFilter, isDesktop]); // mainRef is stable — no need to include it
```

---

### WR-04: `computeVariant` default parameter silently bypasses `no-stances` path

**File:** `essentials/src/lib/classify.js:311`
**Issue:** `computeVariant(pol, userAnswers, hasStances = true)` defaults `hasStances` to `true`. Any call site that omits the third argument will never return `'no-stances'`, even for politicians with no stances on file. In `Results.jsx` line 908 the correct three-argument form is used, but if any future call site (e.g., when wiring into another component) omits the argument, it would silently show a compass CTA for politicians with no data.
**Fix:** Default should be `false` (safest fallback — if we don't know, assume no stances rather than assuming stances exist):
```js
export function computeVariant(pol, userAnswers, hasStances = false) {
```
Alternatively, remove the default and make the argument required so callers are forced to be explicit.

---

### WR-05: Misleading `CATEGORY_DISPLAY_NAMES` entry — "Federal Judiciary" maps to "U.S. Supreme Court"

**File:** `essentials/src/lib/classify.js:265`
**Issue:** `"Federal Judiciary": "U.S. Supreme Court"` maps the entire federal judiciary category — which includes circuit court judges, district court judges, and other federal judicial officers — to the display name "U.S. Supreme Court". A user viewing a federal district court judge's card would see "U.S. Supreme Court" as the category label, which is factually wrong.
**Fix:**
```js
"Federal Judiciary": "Federal Courts",
```
Or keep "U.S. Supreme Court" only if the data in practice only ever contains Supreme Court justices (in which case the group name should also be narrowed to "U.S. Supreme Court" in `FEDERAL_ORDER` to maintain consistency).

---

## Info

### IN-01: `BrowserRouter` imported but unused in App.jsx

**File:** `essentials/src/App.jsx:3`
**Issue:** `BrowserRouter` is imported from `react-router-dom` but never rendered in `App.jsx`. The router wrapper must exist somewhere (presumably `main.jsx`). The import is dead code.
**Fix:** Remove the unused import:
```js
import { Routes, Route } from 'react-router-dom';
```

---

### IN-02: Side effects at module scope in App.jsx

**File:** `essentials/src/App.jsx:17-20`
**Issue:** `extractHashToken()` and `localStorage.removeItem('lastZip')` are called at module scope (outside any function or component). These run on every import of the module, including in test environments. Module-level side effects are an anti-pattern in React apps — they cannot be cleaned up, are hard to test, and can fire at unexpected times.
**Fix:** Move both calls inside a `useEffect` with an empty dependency array in the `App` component, or into a dedicated initialization hook:
```js
useEffect(() => {
  extractHashToken();
  localStorage.removeItem('lastZip');
}, []);
```

---

### IN-03: `console.error` debug artifact in browse shortcut handler

**File:** `essentials/src/pages/Results.jsx:495`
**Issue:** `console.error('browse shortcut error:', error)` is left in production code. This leaks internal error context to browser dev tools in production.
**Fix:** Either remove it or gate it behind a dev-mode check:
```js
if (import.meta.env.DEV) console.error('browse shortcut error:', error);
```

---

### IN-04: `LOCAL_EXEC` "township" title match is unreachable

**File:** `essentials/src/lib/classify.js:154-155`
**Issue:** In the `LOCAL_EXEC` branch, `if (hasAny(title, ["township"]))` routes to `"Township Officials"`. However, `LOCAL_EXEC` is intended for executive roles (mayors, county executives, etc.) and a township trustee/board-member with `LOCAL_EXEC` district type is unusual. More practically, a "Fire Chief" or "City Director" with `LOCAL_EXEC` district type reaches the second condition (lines 157-162) which catches any title containing `"director"` or `"chief"` and routes them to `"Local Departments & Special Districts"` rather than `"Municipal Executives"`. This may be intentional, but it means city directors are not grouped with other municipal executives. Worth confirming against actual data.
**Fix:** No code change required unless confirmed to be wrong — document the intent in a comment, or add specific executive titles to `ROLE_LOCAL_EXEC` to protect them from the agency catch.

---

### IN-05: Deduplication key can collide across distinct officials

**File:** `essentials/src/pages/Results.jsx:716`
**Issue:** The deduplication key is `${pol.first_name}-${pol.last_name}-${pol.office_title}-${pol.government_body_name || ''}-${pol.is_vacant || false}`. Two officials at different government bodies with the same name and title but no `government_body_name` (both `null`) would be de-duped to one. This is most likely to occur with common titles (e.g., "Commissioner") in the same result set.
**Fix:** Include `pol.id` as a tiebreaker, or include `pol.district_id` in the key to distinguish seats:
```js
const key = `${pol.first_name}-${pol.last_name}-${pol.office_title}-${pol.district_id || ''}-${pol.government_body_name || ''}`;
```

---

_Reviewed: 2026-04-26_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
