---
phase: quick
plan: 260405-doq
type: execute
wave: 1
depends_on: []
files_modified:
  - ev-accounts/backend/src/lib/essentialsService.ts
autonomous: true
---

<objective>
Fix the "on the ballot" icon incorrectly showing for ALL politicians in a state instead of only those actually on an upcoming ballot.

Purpose: The `UPCOMING_ELECTIONS_LATERAL` SQL lateral join matches elections only by `e.state = d.state`, so every Indiana politician gets the next election date for the entire state, regardless of whether they are actually a candidate in a race for that election. The frontend correctly displays the ballot icon when `nextPrimaryDate` or `nextGeneralDate` is present, so the fix is backend-only.

Output: Modified lateral join that only returns election dates for politicians who are actually candidates (via `race_candidates.politician_id`) or whose office has a race (via `races.office_id`).
</objective>

<context>
@ev-accounts/backend/src/lib/essentialsService.ts
@ev-accounts/backend/migrations/042_election_schema.sql
</context>

<tasks>

<task type="auto">
  <name>Task 1: Fix UPCOMING_ELECTIONS_LATERAL to filter by actual ballot participation</name>
  <files>ev-accounts/backend/src/lib/essentialsService.ts</files>
  <action>
Replace the `UPCOMING_ELECTIONS_LATERAL` constant (lines 47-56) with a corrected lateral join that joins through `essentials.races` and optionally `essentials.race_candidates` to determine if a politician is actually on an upcoming ballot.

The new lateral join must correlate on the outer query aliases `p` (politicians) and `o` (offices), which are available in all queries that use this constant. It should match a politician to an election when EITHER:

1. **Office match:** A race exists for that election where `r.office_id = o.id` (the politician holds an office that has a race scheduled), OR
2. **Candidate match:** The politician is explicitly listed as an active candidate via `rc.politician_id = p.id` AND `rc.candidate_status = 'active'`

New SQL (replace lines 47-56):

```sql
const UPCOMING_ELECTIONS_LATERAL = `
  LEFT JOIN LATERAL (
    SELECT
      MIN(CASE WHEN e.election_type = 'primary' THEN e.election_date END)::text AS next_primary_date,
      MIN(CASE WHEN e.election_type = 'general' THEN e.election_date END)::text AS next_general_date
    FROM essentials.elections e
    JOIN essentials.races r ON r.election_id = e.id
    LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id AND rc.politician_id = p.id
    WHERE e.election_date >= CURRENT_DATE
      AND (r.office_id = o.id OR (rc.politician_id IS NOT NULL AND rc.candidate_status = 'active'))
  ) upcoming ON true
`;
```

Key changes from the old query:
- REMOVED: `e.state = d.state` (the overly broad state-only match causing the bug)
- ADDED: `JOIN essentials.races r ON r.election_id = e.id` (connects elections to specific races)
- ADDED: `LEFT JOIN essentials.race_candidates rc` (checks if politician is explicitly a candidate)
- ADDED: WHERE condition requiring either office match (`r.office_id = o.id`) or active candidate match

This ensures only politicians with an actual race for their office OR who are explicitly listed as candidates will get election dates populated. All other politicians will get NULL (coerced to empty string), so the frontend ballot icon will correctly not appear.

Do NOT modify essentialsBrowseService.ts — it does not use the UPCOMING_ELECTIONS_LATERAL constant (the browse queries for area-based browsing don't include election lateral joins).
  </action>
  <verify>
    <automated>cd /Users/chrisandrews/Documents/GitHub/ev-accounts/backend && npx tsc --noEmit 2>&1 | head -20</automated>
  </verify>
  <done>
The UPCOMING_ELECTIONS_LATERAL constant joins through races and race_candidates tables instead of matching on state alone. TypeScript compiles without errors. Politicians without an actual race or candidate record will no longer receive election dates.
  </done>
</task>

<task type="auto">
  <name>Task 2: Verify query correctness against live database</name>
  <files>ev-accounts/backend/src/lib/essentialsService.ts</files>
  <action>
Start the dev server and make a test request to verify the fix works correctly.

1. Run `npm run dev` in background
2. Make a request to the essentials endpoint for a known Indiana address (e.g., Bloomington):
   `curl -s http://localhost:3000/api/essentials/address?address=401+N+Morton+St,+Bloomington,+IN+47404 | jq '[.[] | {full_name, next_primary_date, next_general_date}]'`
3. Verify that MOST politicians now have empty strings for `next_primary_date` and `next_general_date` (they are NOT on an upcoming ballot)
4. Only politicians who actually have races/candidates linked should show dates
5. If ALL politicians still show dates, the fix is wrong — debug the lateral join
6. If NO politicians show dates at all (and there ARE upcoming elections with races), check that the JOIN conditions are correct

Stop the dev server after verification.
  </action>
  <verify>
    <automated>cd /Users/chrisandrews/Documents/GitHub/ev-accounts/backend && npx tsc --noEmit</automated>
  </verify>
  <done>
Test request confirms that only politicians with actual races or candidate records show election dates. Politicians without ballot participation show empty strings for next_primary_date and next_general_date.
  </done>
</task>

</tasks>

<verification>
1. TypeScript compiles without errors
2. The UPCOMING_ELECTIONS_LATERAL constant references `essentials.races` and `essentials.race_candidates` tables
3. The lateral join correlates on `o.id` (office) and `p.id` (politician), not `d.state`
4. API response for an Indiana address shows ballot dates only for politicians with actual races
</verification>

<success_criteria>
- The "on the ballot" icon no longer appears for all Indiana politicians
- Only politicians with an actual race (via office_id) or who are explicitly listed as active candidates (via race_candidates) display the ballot icon
- No regressions — politicians who ARE on the ballot still show correct election dates
</success_criteria>
