---
phase: 125
plan: "03"
subsystem: read-rank, treasury-tracker
tags: [ux-polish, tab-title, featured-communities, fy-notice]
requirements: [UX-01]

dependency_graph:
  requires: [125-02]
  provides: [G-114-020, G-114-021, G-114-023]
  affects: [read-rank/index.html, treasury-tracker/src/components/AlphaLanding.tsx, treasury-tracker/src/App.tsx]

tech_stack:
  added: []
  patterns:
    - Filter-and-section pattern for CityGrid partition (featured vs other)
    - Data-driven conditional banner (availableYears check, no hardcoded entity names)

key_files:
  created: []
  modified:
    - read-rank/index.html
    - treasury-tracker/src/components/AlphaLanding.tsx
    - treasury-tracker/src/App.tsx

decisions:
  - "Used HTML entity &amp; in <title> tag (correct HTML encoding; browser renders as &)"
  - "Extracted renderCityButton() local function in CityGrid to avoid duplicating button JSX across Featured and Other sections"
  - "npm install was needed in treasury-tracker before build (ev-ui not installed); pre-existing condition, not a deviation"

metrics:
  duration: "~12 minutes"
  completed: "2026-04-17"
  tasks_completed: 2
  tasks_total: 3
  files_changed: 3
---

# Phase 125 Plan 03: Wave 3a UX Polish (Read & Rank title + Treasury Featured/FY) Summary

Read & Rank tab title updated to "Read & Rank — Empowered Vote" and Treasury Tracker landing enhanced with a Featured communities section plus a data-driven FY notice banner. Task 3 is a human verification checkpoint — not executed.

## Tasks Completed

### Task 1: G-114-020 — Read & Rank tab title (read-rank)

**Commit:** `85a2fdd` (after rebase onto remote main)

Changed `<title>readrank-prototype</title>` to `<title>Read &amp; Rank — Empowered Vote</title>` in `read-rank/index.html` line 7. Used HTML entity `&amp;` for the ampersand (correct HTML encoding) and the real em-dash U+2014 directly in the string.

**Verification:** `grep` confirms "Read &amp; Rank — Empowered Vote" present; no occurrence of "readrank-prototype" remains.

---

### Task 2: G-114-021 + G-114-023 — Treasury Featured communities + FY notice (treasury-tracker)

**Commit:** `3c5d752`

**Part A — AlphaLanding.tsx CityGrid partition (G-114-021):**
- Added `const featured = available.filter(m => m.state === 'IN')` and `const others = available.filter(m => m.state !== 'IN')` inside `CityGrid`.
- Extracted existing per-city button JSX into local function `renderCityButton(city: Municipality)` — no behavior change.
- Replaced single flat grid with `<div className="space-y-6">` containing two conditional sections:
  - "Featured communities" section (rendered only when `featured.length > 0`) — IN municipalities (Bloomington, Monroe County)
  - "Other communities" section (rendered only when `others.length > 0`)
  - Section headers: `text-xs font-semibold uppercase tracking-wider text-[#6B7280] mb-2`
- All existing button styling, "Pilot" badge, icon/year/arrow content preserved.

**Part B — App.tsx FY notice banner (G-114-023):**
- Inserted conditional banner above the controls bar wrapper (line ~514):
  ```tsx
  {selectedEntity && availableYears.length > 0 && !availableYears.includes('2026') && (
    <div className="bg-[#FFF8ED] border-l-4 border-[#F5D98B]">
      <div className="max-w-[1400px] mx-auto px-6 py-2">
        <p className="text-sm text-[#92400E]" style={{ fontFamily: "'Manrope', sans-serif" }}>
          Latest available: FY{availableYears[0]}. FY2026 data not yet published by {selectedEntity.name}.
        </p>
      </div>
    </div>
  )}
  ```
- Fully data-driven — no hardcoded "Monroe County". Banner appears for any entity whose `availableYears` array has data but excludes '2026'.
- No new imports.

**Build:** `npm run build` passes (tsc + vite). Pre-existing CSS `@import` order warning present before this change; not introduced by these edits.

---

### Task 3: Production verification — PENDING (human checkpoint)

Not executed. Awaiting human verification per checkpoint protocol. User should:
1. Visit https://readrank.empowered.vote — browser tab should read "Read & Rank — Empowered Vote"
2. Visit https://treasurytracker.empowered.vote — landing should show "Featured communities" and "Other communities" sections
3. Click Monroe County — FY notice banner should appear: "Latest available: FY2025. FY2026 data not yet published by Monroe County."
4. Click Bloomington — banner should NOT appear (Bloomington has FY2026 data)
5. Verify Bloomington YearSelector dropdown contains 2025 (G-114-024)

Resume signal: "Wave 3 part A verified"

---

## Commits

| Repo | Hash | Message |
|------|------|---------|
| read-rank | 85a2fdd | feat(125-03): update browser tab title to Read & Rank — Empowered Vote |
| treasury-tracker | 3c5d752 | feat(125-03): featured communities section + FY notice banner |

Both pushed to remote `main` (Render auto-deploys triggered).

---

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Missing npm dependencies in treasury-tracker**
- **Found during:** Task 2 build verification
- **Issue:** `@empoweredvote/ev-ui` not installed locally; `npm run build` failed immediately with unresolved import
- **Fix:** Ran `npm install` in treasury-tracker to restore node_modules; build then succeeded
- **Files modified:** `package-lock.json` (not committed — dependency state only)
- **Impact:** Pre-existing condition, no code changes required

---

## Known Stubs

None — both changes are fully wired to live data (`availableYears` from `selectedEntity.available_datasets`, `state` field from municipality objects).

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes introduced.

## Self-Check: PASSED

- [x] `read-rank/index.html` — updated title confirmed via grep
- [x] `treasury-tracker/src/components/AlphaLanding.tsx` — "Featured communities" and "Other communities" present
- [x] `treasury-tracker/src/App.tsx` — "Latest available: FY" banner present
- [x] Treasury build green (`✓ built in 1.91s`)
- [x] Commits `85a2fdd` (read-rank) and `3c5d752` (treasury-tracker) exist and pushed
