---
phase: 10-term-dates
verified: 2026-02-18T20:30:00Z
status: human_needed
score: 5/5 must-haves verified
human_verification:
  - test: "Dashboard cards show no term dates for officials"
    expected: "Searching any ZIP code shows politician cards with only name, office title, and party — no start/end dates visible beneath official cards"
    why_human: "Visual UI behavior cannot be verified programmatically; requires rendering the app and inspecting cards"
  - test: "Profile page displays term date subtitle below title"
    expected: "Clicking a politician card opens their profile; below the office title h2 appears a muted subtitle in smaller text — either 'Since Jan 2023' (start-only) or 'Jan 2023 – Jan 2027' (full range)"
    why_human: "Whether the rendered subtitle is visually distinct and correctly positioned below the title requires human inspection"
  - test: "Missing dates produce no empty line on profile"
    expected: "A politician with null term_start and null term_end shows no date line — no blank space or placeholder text between title and the next content"
    why_human: "Depends on live data from the API containing a politician with no date fields; cannot verify without rendering"
---

# Phase 10: Term Dates Verification Report

**Phase Goal:** Users see term dates in the right context — profile detail, not card clutter
**Verified:** 2026-02-18T20:30:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Dashboard politician cards do not show any start or end dates | VERIFIED | Results.jsx `renderPoliticianCard` contains zero references to `termLine`, `term_start`, `term_end`, `getTermLine`, or `formatTermDate`; grep returns no matches |
| 2 | Profile page displays term dates below the politician's title as a subtitle | VERIFIED | PoliticianProfile.jsx lines 256-258: `{getTermLine(pol) && (<p style={styles.termDate}>{getTermLine(pol)}</p>)}` placed immediately after `<h2 style={styles.title}>` |
| 3 | Missing dates (both null) hide the date line entirely on the profile | VERIFIED | `getTermLine` (line 14-19) returns null when `formatTermDate(pol.term_start)` returns null; the conditional `{getTermLine(pol) && ...}` prevents render |
| 4 | Start-only dates display as "Since Jan 2023" on the profile | VERIFIED | `getTermLine` (line 18): `return end ? '${start} \u2013 ${end}' : 'Since ${start}'` — returns "Since {month year}" when end is null |
| 5 | Full date ranges display as "Jan 2023 – Jan 2027" on the profile | VERIFIED | `getTermLine` (line 18): returns `${start} \u2013 ${end}` using en-dash (U+2013) when both dates present |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `essentials/src/pages/Results.jsx` | Card rendering without term dates | VERIFIED | File exists, substantive (534 lines), `renderPoliticianCard` function present (lines 51-80), zero term date references |
| `ev-ui/src/PoliticianProfile.jsx` | Term date subtitle below title | VERIFIED | File exists, substantive (304 lines), `formatTermDate` at line 7, `getTermLine` at line 14, `termDate` style at line 188, JSX render at lines 256-258 |
| `ev-ui/package.json` | Version 0.1.19 published | VERIFIED | Version field: `"0.1.19"`, publishConfig registry: `https://npm.pkg.github.com` |
| `essentials/package.json` | ev-ui dependency at ^0.1.19 | VERIFIED | `"@chrisandrewsedu/ev-ui": "^0.1.19"` present in dependencies |
| `essentials/node_modules/@chrisandrewsedu/ev-ui` | Installed at 0.1.19 with built term date code | VERIFIED | Installed version 0.1.19 confirmed; dist/index.js contains `formatTermDate` at line 1781, `getTermLine` at line 1787 |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `ev-ui/src/PoliticianProfile.jsx` | `politician.term_start / politician.term_end` | pol prop destructuring | WIRED | `pol.term_start` at line 15, `pol.term_end` at line 17 within `getTermLine`; `pol` comes from `politician` prop (line 39) |
| `essentials/package.json` | ev-ui published package | npm dependency version | WIRED | `@chrisandrewsedu/ev-ui: ^0.1.19` in package.json; 0.1.19 installed in node_modules; dist contains term date helpers |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| PROF-01 | 10-01-PLAN.md | Start/end dates removed from politician cards on dashboard page | SATISFIED | Results.jsx `renderPoliticianCard` has zero references to any term date variable or function; grep confirms no matches for `termLine`, `term_start`, `term_end`, `getTermLine`, `formatTermDate` |
| PROF-02 | 10-01-PLAN.md | Start/end dates display below the politician's title on the profile page | SATISFIED | PoliticianProfile.jsx renders `<p style={styles.termDate}>{getTermLine(pol)}</p>` conditionally after the `<h2>` office title; style uses `fontSizes.sm` and `colors.textMuted` per spec |

No orphaned requirements — REQUIREMENTS.md maps only PROF-01 and PROF-02 to Phase 10, both claimed by 10-01-PLAN.md.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `ev-ui/src/PoliticianProfile.jsx` | 136, 209, 245 | `placeholder` keyword | Info | These are the photo placeholder style and initials fallback — not stub code; intended UI for missing politician photos |

No blocker or warning anti-patterns found in either modified file.

### Commit Verification

Commits documented in SUMMARY.md exist in their respective repos:
- `e44631b` — `feat(10-01): add term date subtitle to PoliticianProfile` — confirmed in ev-ui repo
- `38d9e8f` — `feat(10-01): remove term dates from dashboard politician cards` — confirmed in essentials repo

### Human Verification Required

#### 1. Dashboard Cards — No Term Dates

**Test:** Start essentials dev server (`cd essentials && npm run dev`). Search any ZIP code (e.g., 47401). Inspect each official politician card.
**Expected:** No start or end date text appears below any official card. Only candidate cards (when toggle enabled) show election dates in coral text.
**Why human:** Card rendering requires a live browser with real API data; cannot confirm visual absence of dates programmatically.

#### 2. Profile Term Date Subtitle — Visual Placement

**Test:** Click any politician card to open profile page. Look below the office title heading.
**Expected:** A smaller, muted-gray date line appears below the title — either "Since Jan 2023" style or "Jan 2023 – Jan 2027" style. It should be visually distinct from the title (smaller, lighter).
**Why human:** Visual hierarchy (font size difference, color contrast) requires human eyes to confirm; line position relative to title is layout-dependent.

#### 3. Null Date Edge Case — No Empty Line

**Test:** Find a politician whose data lacks term_start (check via API or try politicians from BallotReady with incomplete data).
**Expected:** Profile page shows no date line at all — no blank space, no label without a value.
**Why human:** Requires finding a politician with null dates in the live dataset; cannot verify this path without rendering with real data.

### Gaps Summary

No gaps found. All five observable truths are verified by code inspection:
- Results.jsx is clean of all term date code (confirmed by grep returning zero matches)
- PoliticianProfile.jsx implements all three edge cases (null-both hides, start-only shows "Since", full range shows en-dash range)
- The ev-ui package was built, published at 0.1.19, and the installed version in essentials/node_modules contains the built term date code
- Both PROF-01 and PROF-02 are fully accounted for

Three human verification items remain for visual confirmation of UI behavior, which is appropriate for a UI-only change of this nature.

---

_Verified: 2026-02-18T20:30:00Z_
_Verifier: Claude (gsd-verifier)_
