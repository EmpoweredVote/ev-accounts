# Phase 127 Code Review

**Depth:** standard
**Files reviewed:** 7
**Date:** 2026-04-19

## Summary

Phase 127 successfully ports `CompassCardHorizontal` and its supporting files into `@empoweredvote/ev-ui`. The component architecture is sound: fully controlled props, no routing/context imports, token-driven styling, and antipartisan clean. Internals are correctly kept private in the barrel. The main concerns are two runtime crash risks (a `TypeError` on `ballot.electionDate` when it arrives as a string rather than a `Date` object, and a null-dereference path inside `onKeyDown`), two token violations in the "Running Unopposed" overlay, a misleading `hasStances` logic that will show the compass icon for all cards whenever the user has any answers, and several minor quality issues. No security issues found.

---

## Findings

### MEDIUM — `ballot.electionDate.toLocaleDateString()` crashes on string input

**File:** `ev-ui/src/IconOverlay.jsx:99`

**Issue:** `ballotTooltip` calls `.toLocaleDateString()` directly on `ballot.electionDate`. If the caller passes a date string from a JSON API response (e.g. `"2026-11-03"`) rather than a `Date` object, this throws `TypeError: ballot.electionDate.toLocaleDateString is not a function`. The JSDoc declares `electionDate: Date` but there is no runtime enforcement. This is a crash risk once the ballot icon is exercised with real API data.

**Fix:**
```js
const electionDate = ballot.electionDate instanceof Date
  ? ballot.electionDate
  : new Date(ballot.electionDate);
const ballotTooltip = ballot
  ? `This seat is on your ballot \u2014 ${ballot.electionLabel}: ${electionDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}`
  : null;
```

---

### MEDIUM — `hasStances` logic shows compass icon for all cards when user has answers

**File:** `ev-ui/src/CompassCardHorizontalMeta.jsx:82`

**Issue:** The condition `Boolean(userAnswers && userAnswers.length > 0) || Boolean(politician.hasStances)` evaluates to `true` for every card on the page whenever the user has answers, regardless of whether the individual politician has any stances to compare. The compass icon is supposed to signal "compare your views with this politician" — showing it for a politician who has no stances creates a dead affordance (clicking does nothing meaningful). The first operand should be removed; the icon should only depend on the politician's own `hasStances` flag.

**Fix:**
```jsx
<IconOverlay
  ballot={politician.ballot || null}
  hasStances={Boolean(politician.hasStances)}
  branch={politician.branch || null}
/>
```

If the intent was to show the icon whenever the user has answers AND this politician has stances, the condition should be:
```jsx
hasStances={Boolean(userAnswers && userAnswers.length > 0) && Boolean(politician.hasStances)}
```

---

### MEDIUM — `onKeyDown` passes no event to `onClick`; keyboard activation drops the event argument

**File:** `ev-ui/src/CompassCardHorizontal.jsx:197-200`

**Issue:** The keyboard handler calls `onClick()` with no arguments. Mouse clicks reach the handler via `onClick={onClick}` on the element, so the caller receives the `MouseEvent`. Keyboard activations reach it as `onClick()` with `undefined`. If any consumer uses the event (e.g., `e.currentTarget`, `e.preventDefault()`, or coordinates), keyboard activation silently passes `undefined`. Inconsistent contract between input methods.

**Fix:**
```jsx
onKeyDown={(e) => {
  if (onClick && (e.key === 'Enter' || e.key === ' ')) {
    e.preventDefault();
    onClick(e);
  }
}}
```

---

### LOW — Token violations in "Running Unopposed" overlay

**File:** `ev-ui/src/CompassCardHorizontal.jsx:219,227`

**Issue:** Two hardcoded literals in the overlay that have token equivalents:
- `color: '#fff'` — should be `colors.textWhite`
- `fontSize: '12px'` — should be `fontSizes.xs`

The `rgba(0,0,0,0.35)` background is explicitly approved per the verification notes and is acceptable. The other two are not.

**Fix:**
```jsx
// Add fontSizes to the import at line 3, then:
color: colors.textWhite,
fontSize: fontSizes.xs,
```

---

### LOW — `aria-label` always uses `office_title`, ignores `elections` surface

**File:** `ev-ui/src/CompassCardHorizontal.jsx:192`

**Issue:** The root element's `aria-label` is hardcoded to `politician.office_title` regardless of the `surface` prop. On `elections` surface the relevant field is `office_running_for`. Screen reader users on an elections page hear the wrong office description.

**Fix:**
```jsx
const ariaTitle = surface === 'elections'
  ? (politician.office_running_for || politician.office_title || '')
  : (politician.office_title || '');

// then:
aria-label={`${politician.full_name}, ${ariaTitle}`}
```

---

### LOW — Dead variable `topicById` in `compassHelpers.js`

**File:** `ev-ui/src/compassHelpers.js:14`

**Issue:** `const topicById = new Map(allTopics.map((t) => [t.id, t]))` is constructed but never read. Its sibling `shortById` is used; `topicById` is a copy-paste remnant that adds noise and a redundant allocation.

**Fix:** Remove the unused line:
```js
// Delete this line:
const topicById = new Map(allTopics.map((t) => [t.id, t]));
```

---

### LOW — Misleading guard `!Array.isArray(userAnswers[0])` in `renderCompass`

**File:** `ev-ui/src/CompassCardHorizontal.jsx:95`

**Issue:** The comment says "Try treating as array of `{ short_title, value }`", and the guard `if (!Array.isArray(userAnswers[0]))` is meant to check that individual answer items are not themselves arrays. But this condition is always `true` for any well-formed answer object, so it provides no filtering. An empty `if (true)` guard is misleading to future readers and should either be removed (making the block unconditional) or replaced with an actual property check.

**Fix:** Remove the dead outer condition:
```js
// Replace:
if (!Array.isArray(userAnswers[0])) {
  topics = userAnswers.filter(a => a.short_title) ...
}

// With (the try-catch already guards against structural errors):
topics = userAnswers.filter(a => a.short_title)
  .map(a => ({ id: a.topic_id || a.short_title, short_title: a.short_title, title: a.short_title }));
data = {};
for (const a of userAnswers) {
  if (a.short_title) data[a.short_title] = a.value ?? 0;
}
```

---

### INFO — Hardcoded hex values in `Prototype.jsx` banner and harness sections

**File:** `essentials/src/pages/Prototype.jsx:83,96,99,103,108,178,195`

**Issue:** Multiple hardcoded hex values and px literals in the prototype harness (`#F0F8FA`, `#E4F3F6`, `#C0E8F2`, `#003E4D`, `4a5568`, `#f3f4f6`, etc.) bypass the token system. This is a harness file scheduled for retirement in Phase 129, so it is low priority, but aligns poorly with the token-driven convention.

**Fix:** No action required before Phase 129. When `Prototype.jsx` is retired, no migration needed. If the harness is ever promoted to production, replace literals with the corresponding `colors.*` / `colorScales.*` tokens.

---

### INFO — `useState` and `useEffect` imported but `React` not imported in `Prototype.jsx`

**File:** `essentials/src/pages/Prototype.jsx:1`

**Issue:** `Prototype.jsx` imports `{ useState, useMemo, useEffect }` from `'react'` without a default `React` import. In `essentials` (Vite + React 19 with automatic JSX transform) this is fine and intentional — the JSX transform does not require the explicit import. This is correctly scoped to `essentials`, not `ev-ui`, so it does not violate the ev-ui explicit-import constraint. Noted here for completeness only.

**Fix:** No action required. The automatic JSX transform makes this correct for this project.

---

## Verdict

**PASS WITH NOTES** — No runtime crashes are certain from the current test scenarios, but two MEDIUM issues represent latent crash risks under real data conditions (`ballot.electionDate` as a string; incorrect `hasStances` logic creating misleading UI affordances). Token violations in the overlay are minor but go against an explicit project constraint. Recommend fixing the two MEDIUM items before cutting a release version, and addressing the LOW token violations in the same pass.
