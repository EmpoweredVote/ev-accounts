# Cal-Access committee records sitting in essentials.politicians

**Found:** 2026-07-03, during a Strategy Hub coverage audit (Fable session).
**Severity:** Low today (rows are inert), medium for data hygiene and admin search quality.

## What

24,044 rows in `essentials.politicians` are campaign committees, not people.  Example: `full_name = "GOLDEN FOR SCHOOL BOARD, FRIENDS TO RE-ELECT DEBBIE"`.  All 24,044:

- `source = 'cal_access_discovery'` (of 76,330 total cal_access_discovery rows; curated politician set is ~7,221)
- `is_active = false` (already quarantined from user-facing surfaces)
- zero `office_id`, zero stances, zero `zip_politicians` rows, zero `race_candidates`, zero images

So no voter-facing impact.  The cost is admin/name-search pollution, inflated table counts, and eventual triage burden in the planned Cal-Access ambiguity UX (Essentials v3.0).

## Detection pattern used

```sql
SELECT count(*) FROM essentials.politicians
WHERE source = 'cal_access_discovery'
  AND full_name ~ '^[^a-z]*$'   -- all-caps heuristic
  AND (full_name ILIKE '%committee%' OR full_name ILIKE '%friends %'
    OR full_name ILIKE '%friends of%' OR full_name ILIKE '%re-elect%'
    OR full_name ILIKE '%to elect%' OR full_name ILIKE '%citizens for%'
    OR full_name ILIKE '% pac' OR full_name ILIKE 'pac %'
    OR full_name ILIKE '%campaign%');
-- 24,044 as of 2026-07-03
```

Pattern is conservative; there are likely more (e.g. "TAXPAYERS FOR", "VOTERS FOR", names ending in numbers/IDs).  A classifier pass during v3.0 triage could tag `entity_kind = committee` or delete outright.

## Suggested fix (when v3.0 Cal-Access triage happens)

1. Add the committee-pattern classifier to the discovery triage flow so these rows are auto-tagged and excluded from person-matching before human review.
2. Either bulk-delete the tagged rows (they are unreferenced; verify FK-wide first with a full referencing-table sweep) or move them to `candidate_staging`/a committees table if finance linkage wants them.
3. Regression guard: discovery imports should reject or divert rows matching the committee pattern at ingest.

No action taken in the database.  Rows verified inert and already inactive; deletion deferred to a reviewed migration.
