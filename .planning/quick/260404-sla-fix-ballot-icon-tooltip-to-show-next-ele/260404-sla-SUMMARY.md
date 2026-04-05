---
phase: quick
plan: 260404-sla
subsystem: essentials
tags: [ballot, tooltip, election-date, ui]
one_liner: "Ballot icon tooltip now shows computed next election date with clarified seat-on-ballot wording"
key_files:
  modified:
    - essentials/src/utils/ballotStatus.js
    - essentials/src/components/IconOverlay.jsx
decisions:
  - "Election year for Jan-Mar term ends maps to prior November (the election that determined that term)"
  - "Election date displayed as month+year only (not full date) for clean tooltip text"
metrics:
  duration: "~10 minutes"
  completed: "2026-04-05T00:39:03Z"
  tasks_completed: 1
  tasks_total: 1
  files_modified: 2
---

# Quick Task 260404-sla: Fix Ballot Icon Tooltip to Show Next Election Date

## Summary

Ballot icon tooltip now shows computed next election date with clarified seat-on-ballot wording. Previously the tooltip showed the term end date (`On your ballot — Jan 2027`), which was confusing. Now it shows the US general election date (`This seat is on your ballot — Election: Nov 2026`), making it clear when users need to vote and that the seat (not the person) is on the ballot.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add election date computation and update tooltip | cd34a70 | ballotStatus.js, IconOverlay.jsx |

## Changes Made

### ballotStatus.js

Added `getElectionDate(termEndDate)` helper that computes the US general election date:
- Determines election year: Jan-Mar term ends use prior November (year-1), all others use same year
- Finds first Monday in November by advancing from Nov 1 to next Monday
- Returns the Tuesday immediately after that Monday (election day)

Updated `getSeatBallotStatus()` return to include `electionDate`:
```js
return { onBallot: true, termEndDate: date, electionDate: getElectionDate(date) };
```

### IconOverlay.jsx

Updated `@param` JSDoc to include `electionDate: Date` in ballot type annotation.

Updated tooltip string:
- Before: `On your ballot — Jan 2027`
- After: `This seat is on your ballot — Election: Nov 2026`

## Deviations from Plan

None - plan executed exactly as written.

## Verification

- Build passes: `cd essentials && npx vite build` succeeded with no errors
- `getElectionDate` correctly maps Jan 2027 term end → Nov 2026 election
- `getElectionDate` correctly maps Dec 2027 term end → Nov 2027 election
- Tooltip reads "This seat is on your ballot — Election: Nov 2026" (example)

## Self-Check: PASSED

- essentials/src/utils/ballotStatus.js: modified and committed
- essentials/src/components/IconOverlay.jsx: modified and committed
- Commit cd34a70 exists in essentials repo
