---
phase: quick
plan: 260401-tdf
type: execute
wave: 1
depends_on: []
files_modified:
  - ev-accounts/backend/scripts/link-monroe-candidates-to-politicians.sql
autonomous: false
must_haves:
  truths:
    - "Candidates who are existing politicians have politician_id linked"
    - "Linked candidates show is_incumbent = true"
    - "Script is idempotent — safe to re-run"
    - "Unmatched candidates remain unchanged (politician_id = NULL)"
  artifacts:
    - path: "ev-accounts/backend/scripts/link-monroe-candidates-to-politicians.sql"
      provides: "Idempotent SQL linking candidates to politician records"
      contains: "UPDATE essentials.race_candidates"
  key_links:
    - from: "essentials.race_candidates"
      to: "essentials.politicians"
      via: "politician_id FK"
      pattern: "politician_id = p\\.id"
---

<objective>
Create an idempotent SQL script that links Monroe County 2026 Primary candidates to their existing `essentials.politicians` records by matching on last_name (with first_name disambiguation). Linked candidates get `politician_id` set and `is_incumbent = true`, enabling the CandidateProfile frontend to display full politician data (photos, bio, legislative history).

Purpose: Candidates who are incumbent politicians should show their full profile data, not just a name.
Output: `link-monroe-candidates-to-politicians.sql` script ready to run against the database.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@ev-accounts/backend/scripts/seed-monroe-county-2026-primary.sql
</context>

<tasks>

<task type="auto">
  <name>Task 1: Write idempotent SQL linking script</name>
  <files>ev-accounts/backend/scripts/link-monroe-candidates-to-politicians.sql</files>
  <action>
Create `ev-accounts/backend/scripts/link-monroe-candidates-to-politicians.sql` with the following structure:

1. **Header comment** — purpose, usage (`psql $DATABASE_URL -f scripts/link-monroe-candidates-to-politicians.sql`), idempotency note

2. **Wrap in BEGIN/COMMIT transaction**

3. **Step 1: Preview matches (as a SELECT, for transparency)**
   - Join `essentials.race_candidates rc` to `essentials.politicians p` on `lower(rc.last_name) = lower(p.last_name)`
   - Scope candidates to the 2026 Indiana Primary election only: join through `essentials.races r` and `essentials.elections e` where `e.name = '2026 Indiana Primary' AND e.election_date = '2026-05-05' AND e.state = 'IN'`
   - Only match candidates where `rc.politician_id IS NULL` (skip already-linked)
   - Show: rc.full_name, p.first_name || ' ' || p.last_name as politician_name, p.id as politician_id
   - For last_name collisions (multiple politicians with same last_name), add `lower(left(rc.first_name, 3)) = lower(left(p.first_name, 3))` as a tiebreaker (handles "Judith" vs "Judith A." style differences)

4. **Step 2: UPDATE with CTE**
   - Use a CTE `matched` that finds the same join as Step 1
   - UPDATE `essentials.race_candidates` SET `politician_id = matched.politician_id, is_incumbent = true, updated_at = now()`
   - WHERE `race_candidates.id = matched.candidate_id AND race_candidates.politician_id IS NULL`
   - The `politician_id IS NULL` condition makes it idempotent

5. **Step 3: Verification query**
   - SELECT showing all candidates for the 2026 Indiana Primary with their link status
   - Columns: rc.full_name, rc.is_incumbent, rc.politician_id, p.first_name || ' ' || p.last_name as linked_politician
   - LEFT JOIN to politicians so unlinked show NULL
   - ORDER BY rc.politician_id IS NULL (linked first), rc.last_name

Important: The match must handle the case where multiple politicians share a last name by also checking first_name prefix. Use `left(name, 3)` prefix matching rather than exact first_name to handle middle initials and name variations (e.g., "Judith A. Sharp" candidate first_name is "Judith", politician might be "Judith" too — this is fine, but be safe).
  </action>
  <verify>
    <automated>grep -c "UPDATE essentials.race_candidates" ev-accounts/backend/scripts/link-monroe-candidates-to-politicians.sql && grep -q "politician_id IS NULL" ev-accounts/backend/scripts/link-monroe-candidates-to-politicians.sql && echo "PASS"</automated>
  </verify>
  <done>Script exists with idempotent UPDATE scoped to 2026 Indiana Primary, includes preview SELECT and verification query</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>SQL script that links Monroe County 2026 Primary candidates to existing politician records</what-built>
  <how-to-verify>
    1. Review the script: `cat ev-accounts/backend/scripts/link-monroe-candidates-to-politicians.sql`
    2. Run against the database: `psql $DATABASE_URL -f ev-accounts/backend/scripts/link-monroe-candidates-to-politicians.sql`
    3. Confirm the preview query shows expected matches (e.g., Efrat Rosser, Judith Sharp, Kara Krothe)
    4. Confirm the verification query shows linked candidates with politician_id populated
    5. Re-run the script to confirm idempotency (no errors, no duplicate links)
  </how-to-verify>
  <resume-signal>Type "approved" or describe issues with the matches</resume-signal>
</task>

</tasks>

<verification>
- Script file exists at `ev-accounts/backend/scripts/link-monroe-candidates-to-politicians.sql`
- Script contains BEGIN/COMMIT transaction wrapper
- Script scopes to 2026 Indiana Primary election only
- UPDATE has `WHERE politician_id IS NULL` for idempotency
- Verification query included at end
</verification>

<success_criteria>
- Script links candidates to existing politician records by name matching
- Linked candidates have `is_incumbent = true` and `politician_id` set
- Script is safe to re-run without side effects
- CandidateProfile frontend will now show full politician data for linked candidates
</success_criteria>

<output>
After completion, create `.planning/quick/260401-tdf-link-election-candidates-with-existing-p/260401-tdf-SUMMARY.md`
</output>
