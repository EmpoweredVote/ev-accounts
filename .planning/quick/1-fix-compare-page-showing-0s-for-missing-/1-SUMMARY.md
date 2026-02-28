---
quick: 1
title: Fix compare page showing 0s for missing stances
subsystem: CompassV2, EV-Backend
tags: [bug-fix, compare-panel, data-cleanup]
key-files:
  modified:
    - CompassV2/src/components/ComparePanel.jsx
    - CompassV2/src/pages/Compass.jsx
    - EV-Backend/data/stance_research.csv
decisions:
  - Exclude 0-value entries from compareAnswers in Compass.jsx rather than filtering in ComparePanel, so the radar chart also benefits from the fix
  - Remove Kerry Thomson trans-athletes row entirely from CSV and database rather than marking as disputed, because the source URL contained no relevant content and there was no reasoning text
metrics:
  completed_date: "2026-02-28"
  tasks: 2
  files_modified: 3
---

# Quick Fix 1: Fix Compare Page Showing 0s for Missing Stances

**One-liner:** Hide stance buttons and radar polygon points for unanswered compare topics by filtering 0-values at the source; also removed inaccurate Kerry Thomson trans-athletes data from CSV and database.

## Tasks Completed

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 | Hide stance options when politician has no answer and filter 0-values from compareAnswers | bb8caca (CompassV2) | ComparePanel.jsx, Compass.jsx |
| 2 | Remove Kerry Thomson trans-athletes bad data from CSV and database | 10576c7 (EV-Backend) | stance_research.csv |

## Changes Made

### Task 1: ComparePanel + Compass.jsx

**Compass.jsx** (`src/pages/Compass.jsx`, line ~562):

Changed the `compareAnswers` builder to skip topics where the politician has no answer (value 0 or absent), instead of mapping them to 0:

```javascript
// Before
return [t.short_title, a ? a.value : 0];

// After
if (!a || a.value === 0) return null;
return [t.short_title, a.value];
```

This means `compareAnswers[dropdownValue]` returns `undefined` for unanswered topics instead of `0`. The radar chart no longer receives 0-value entries in `compareData`, eliminating collapsed polygon points at 0.

**ComparePanel.jsx** (`src/components/ComparePanel.jsx`):

Restructured the topic content section to branch on `polHasAnswered`:

- When `polHasAnswered` is true (politician has a stance): renders legend, stance buttons, write-in block, and reasoning/sources as before
- When `polHasAnswered` is false (no stance): renders only the "{polName} hasn't answered this topic yet." message — no stance buttons, no legend, no reasoning section

The `isPol` check inside the stance buttons loop was also simplified from `polHasAnswered && polValue === stanceNum` to just `polValue === stanceNum` since the whole block is now inside the `polHasAnswered` branch.

### Task 2: Kerry Thomson Trans-Athletes Data Removal

Removed inaccurate stance record:
- **CSV**: Deleted row from `EV-Backend/data/stance_research.csv` line 429: `Kerry Thomson,,trans-athletes,2,https://bloomington.in.gov/mayor,,`
- **Database**: Deleted `compass.answers` record for politician `1c6dbdaf-e110-48d3-9b88-27f911d9521f` / topic `f2f55c7b-c94d-59f9-b118-abee1d86791d`
- **Database**: Deleted `compass.contexts` record for same politician/topic pair
- The `ThomsonBanksYoungHouchin.csv` file was confirmed to have no trans-athletes row for Kerry Thomson (her entries are: abortion, same-sex-marriage, climate-change, fossil-fuels, civil-rights, housing, immigration, deportation)

## Deviations from Plan

None — plan executed exactly as written.

## Verification

- `cd CompassV2 && npm run build` succeeds (built in 841ms, no errors)
- `grep "Kerry Thomson.*trans-athlete" EV-Backend/data/stance_research.csv` returns 0 matches
- Database query confirms 0 remaining records for Kerry Thomson / trans-athletes

## Self-Check: PASSED

- CompassV2/src/components/ComparePanel.jsx: FOUND (modified)
- CompassV2/src/pages/Compass.jsx: FOUND (modified)
- EV-Backend/data/stance_research.csv: FOUND (modified)
- Commit bb8caca: FOUND (CompassV2 repo)
- Commit 10576c7: FOUND (EV-Backend repo)
