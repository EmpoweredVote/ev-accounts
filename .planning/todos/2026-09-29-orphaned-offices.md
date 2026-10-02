# 349 offices point at a chamber that does not exist

**Found 2026-09-29** while verifying `CC_0185` (Indianapolis/Marion consolidation).
**Not caused by that migration** — proven below. Nothing here is urgent; it is recorded because
nothing in CI watches it and it will otherwise be rediscovered by whoever next deletes a chamber.

## The measurement

```sql
SELECT count(*) FROM essentials.offices o
 WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.id = o.chamber_id);
-- 349
```

`chambers.government_id` has no foreign key and `offices.chamber_id` is not enforced either, so a
chamber delete orphans its offices **silently, with no error**. That is the same class of hazard
`CC_0185` had to order its own deletes around.

## Why it is not CC_0185's doing

Measured immediately after applying, against the 349:

| check | result |
| --- | --- |
| pointing at one of the 6 chambers `CC_0185` deleted | **0** |
| sitting on any Marion County district (`geo_id LIKE '18097%'`) | **0** |
| carrying `representing_city = 'Indianapolis'` | **0** |
| states spanned | `as` … `vi` — nationwide |

`CC_0185` moved all 6 offices to their new chambers **before** deleting anything, and deleted only
chambers it had proven empty. It created no orphans.

⚠ **I did not take a baseline count before applying**, which is the honest gap here: the argument
above is from the orphans' own properties, not from a before/after difference. It is sound, but a
baseline would have been stronger and cost nothing.

## Worth knowing before fixing

- 🔴 **An orphaned office is invisible, not broken.** Every read path joins `offices → chambers →
  governments`, so these rows simply never appear. They are not serving wrong data to anyone;
  they are dead weight that inflates raw `offices` counts.
- ⚠ **Do not mass-delete them.** Some may hold `office_terms`, and a term is a historical record.
  Check `office_terms` and `office_current_holder` per row first.
- The likely source is a retired discovery wave — Indiana's was retired 2026-09-12 with 671
  unreachable offices — but that is a hypothesis, not a measurement. **Group by source and read a
  sample before writing any predicate against them.**

## A cheap guard, if it is worth one

```sql
-- would have caught this the day it happened
SELECT count(*) FROM essentials.offices o
 WHERE NOT EXISTS (SELECT 1 FROM essentials.chambers c WHERE c.id = o.chamber_id);
```

A baseline assertion in `check:occupancy` would do it, in the same shape as
`essentials.offices_missing_terms`: fail above a recorded number, and lower the number whenever a
change shrinks it.
