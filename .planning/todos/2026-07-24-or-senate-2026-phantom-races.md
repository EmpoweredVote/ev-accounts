# OR State Senate: all 30 districts have a 2026 general race row, but Oregon only elects half

**Created:** 2026-07-24 (found while seeding the Bend, OR deep seed — NOT caused by it)
**Priority:** medium — surfaces empty//wrong races to Oregon voters; no data loss
**Scope:** pre-existing defect in `essentials.races`, statewide OR. Migrations 1414/1415 did not
touch it and deliberately did not add SD-27 candidates.

## What was found

```sql
SELECT r.position_name, count(rc.id)
FROM essentials.races r
JOIN essentials.elections e ON e.id = r.election_id
LEFT JOIN essentials.race_candidates rc ON rc.race_id = r.id
WHERE e.state = 'OR' AND e.election_date = '2026-11-03'
  AND r.position_name LIKE 'OR State Senate District %'
GROUP BY 1;
```

returns **all 30** districts (1–30), every one with **0 candidates**.

Oregon senators serve staggered 4-year terms, so only about half the chamber is on any given
general-election ballot. Concretely for Bend: **State Senate District 27** was last elected in
**November 2024** (Anthony Broadman, `external_id -4110027`), whose term runs through **January
2029** — so SD 27 is *not* on the 2026 ballot at all, yet a 2026 race row exists for it.

Likely cause: `migrations/generate_or_senate.ps1` / `generate_or_legislative_races.ps1` emitted a
race row per district without applying the odd/even staggering schedule. (OR State **House**
rows are fine — all 60 seats are elected every 2 years.)

## Why it matters

A Bend address resolves to SD 27, so the elections feed can show the voter a Senate race that
does not exist on their ballot. It is currently empty of candidates, which limits the damage, but
any future bulk candidate backfill keyed off these rows would populate a phantom contest.

## What to do

1. Determine the authoritative 2026 OR Senate class from the Secretary of State's list of open
   offices (or Ballotpedia's "Oregon State Senate elections, 2026"). Do not infer from
   even/odd district numbers without checking — mid-term vacancy appointments shift the schedule.
2. Delete (or mark) the 2026-11-03 race rows for districts not up in 2026. Check
   `essentials.race_candidates` is empty for each before deleting, and check the same class logic
   against **2028** rows if any exist.
3. Audit the sibling generators for other states with staggered upper chambers seeded the same
   way (the generator family covers OR, MD, ME, VA at least).
4. While in there: Levy (`-4120053`), Kropf (`-4120054`) and Broadman (`-4110027`) all have
   **zero** compass stances — see §4 of `2026-07-24-bend-or-postfiling-recheck.md`.
