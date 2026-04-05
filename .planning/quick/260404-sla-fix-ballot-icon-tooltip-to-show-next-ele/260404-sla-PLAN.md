---
phase: quick
plan: 260404-sla
type: execute
wave: 1
depends_on: []
files_modified:
  - essentials/src/utils/ballotStatus.js
  - essentials/src/components/IconOverlay.jsx
autonomous: true
must_haves:
  truths:
    - "Ballot icon tooltip shows next election date, not term end date"
    - "Tooltip wording clarifies the seat/position is on the ballot, not the person"
    - "Election date computed as first Tuesday after first Monday in November"
  artifacts:
    - path: "essentials/src/utils/ballotStatus.js"
      provides: "Election date computation alongside existing ballot status"
      contains: "electionDate"
    - path: "essentials/src/components/IconOverlay.jsx"
      provides: "Updated tooltip text using election date"
      contains: "This seat is on your ballot"
  key_links:
    - from: "essentials/src/utils/ballotStatus.js"
      to: "essentials/src/components/IconOverlay.jsx"
      via: "ballot.electionDate property"
      pattern: "ballot\\.electionDate"
---

<objective>
Fix the ballot icon tooltip in the essentials app to show the next election date instead of the term end date, and clarify that the position/seat is on the ballot (not the person).

Purpose: Users currently see a term end date which is confusing — they need to know WHEN to vote, and the tooltip should communicate that this seat is up for election.
Output: Updated ballotStatus utility and IconOverlay tooltip text.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@essentials/src/utils/ballotStatus.js
@essentials/src/components/IconOverlay.jsx
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add election date computation to ballotStatus and update tooltip</name>
  <files>essentials/src/utils/ballotStatus.js, essentials/src/components/IconOverlay.jsx</files>
  <action>
**ballotStatus.js** — Add a helper function `getElectionDate(termEndDate)` that computes the US general election date (first Tuesday after the first Monday in November):

1. Determine the election year: if term ends Jan-Mar of year X, election is in November of year X-1. Otherwise November of year X.
2. Compute the first Monday in November of that year: start at Nov 1, advance to next Monday if not already Monday.
3. The election day is that Monday + 1 day (Tuesday).
4. Return a Date object for election day.

Update `getSeatBallotStatus()` return to include `electionDate`:
```js
return { onBallot: true, termEndDate: date, electionDate: getElectionDate(date) };
```

**IconOverlay.jsx** — Update the ballot tooltip string (line 95-97):
- Change from: `On your ballot — ${ballot.termEndDate.toLocaleDateString(...)}`
- Change to: `This seat is on your ballot — Election: ${ballot.electionDate.toLocaleDateString('en-US', { month: 'short', year: 'numeric' })}`

Also update the JSDoc `@param` for ballot prop to include `electionDate: Date` in the type annotation (line 88).
  </action>
  <verify>
    <automated>cd /Users/chrisandrews/Documents/GitHub/essentials && npx vite build 2>&1 | tail -5</automated>
  </verify>
  <done>
- ballotStatus.js exports getSeatBallotStatus returning { onBallot, termEndDate, electionDate }
- getElectionDate correctly computes first Tuesday after first Monday in November
- For a term ending Jan 2027, election date is Nov 2026
- For a term ending Dec 2027, election date is Nov 2027
- IconOverlay tooltip reads "This seat is on your ballot — Election: Nov 2026" (example)
- Build succeeds with no errors
  </done>
</task>

</tasks>

<verification>
- `cd essentials && npx vite build` succeeds
- Visually inspect ballotStatus.js for correct election date logic
- Grep for "This seat is on your ballot" in IconOverlay.jsx
</verification>

<success_criteria>
- Ballot icon tooltip shows "This seat is on your ballot — Election: {month} {year}" with the computed election date
- Election date logic correctly handles Jan-Mar term ends (election in prior year's November)
- No regressions — existing onBallot detection unchanged
- Build passes cleanly
</success_criteria>

<output>
After completion, create `.planning/quick/260404-sla-fix-ballot-icon-tooltip-to-show-next-ele/260404-sla-SUMMARY.md`
</output>
