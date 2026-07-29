# `ocd_id` backfill revert logs

Snapshots written by `scripts/backfill-district-ocd.ts --write` **before** it updates anything: one
file per (tier, state) run, capturing every district it was about to touch and the value it held.
This is the rollback path for the `essentials.districts.ocd_id` backfills.

## Why these are copied here

The script writes them to **`.planning/coverage/`, which is gitignored** — `.gitignore` has a broad
`coverage/` rule for test output that matches any directory of that name. (`backend/data/coverage/` is
exempted by an explicit `!` negation a few lines below it; `.planning/coverage/` is not.) So the
originals exist only on the machine that ran the backfill. These are byte-identical copies, tracked so
the rollback path survives that machine.

**If you run another backfill, copy its new log in here too** — the script still writes to
`.planning/coverage/`.

## Shape

```json
{
  "captured": "2026-07-29",          // UTC — an afternoon-Pacific run dates tomorrow
  "tier": "SCHOOL",                  // --type, or "deferred (LOCAL/SCHOOL/COUNTY)" when unscoped
  "state": "in",                     // --state, or "all"
  "count": 2,
  "districts": [
    { "id": "…uuid…", "district_type": "SCHOOL", "state": "in", "geo_id": "1804770",
      "old_ocd_id": null, "new_ocd_id": "ocd-division/country:us/state:in/school_district:…" }
  ]
}
```

## Reverting

`old_ocd_id` is `null` for every row in every log here — the backfill only ever writes to rows whose
`ocd_id` is NULL or non-conforming, so a revert is "set it back to NULL", scoped to the captured ids:

```sql
-- Guarded on new_ocd_id so this cannot clobber a value someone has since corrected by hand.
UPDATE essentials.districts d
   SET ocd_id = NULL
  FROM (SELECT (j->>'id')::uuid AS id, j->>'new_ocd_id' AS new_ocd_id
          FROM jsonb_array_elements(:log::jsonb -> 'districts') AS j) s
 WHERE d.id = s.id AND d.ocd_id = s.new_ocd_id;
```

## Verified against prod, 2026-07-29

26 logs, all parse, **572 districts / 572 distinct ids** (no id appears in two logs), and **0 rows with
a non-NULL `old_ocd_id`** — which is what makes "set it back to NULL" the correct revert rather than an
assumption.

Against the live database: all 572 ids still exist; **562 still hold exactly the `new_ocd_id`** the log
recorded, so a revert would apply to them. The other **10 have drifted, and all 10 are accounted for** —
they are the Pima (AZ) and Riverside (CA) county boards that **migration 1484** re-keyed from the wrong
`place:pima/ward:N` to `county:pima/council_district:N`. The revert SQL's `AND d.ocd_id = s.new_ocd_id`
guard skips exactly those, which is the intended behaviour: a hand-corrected value must not be clobbered
by a rollback of the run that first set it.

Reverting costs **dashboard visibility only** — `ocd_id` is read solely by
`coverageService`/`coverageMapService` behind `requireAuth + requireAdmin`. Address search joins
`geofence_boundaries.geo_id = districts.geo_id` (+ mtfcc) and never reads `ocd_id`.

**Not covered by these logs:** migration `1485_dc_ward_geo_ids.sql`, which changed **`geo_id`** on
DC's 16 ward districts. That one *is* public-facing (it drives address search) and reverts by
restoring `'dc-ward-' || n` / `'dc-sboe-ward-' || n`, as documented in the migration itself.
