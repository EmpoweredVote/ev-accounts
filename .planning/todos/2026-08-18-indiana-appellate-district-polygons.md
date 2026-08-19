# Indiana appellate retention districts — build the real polygons

Opened 2026-08-18. **Operator decision: build the polygons properly.** Baselining the failure was
offered and declined.

`npm run check:reachability` is **RED on master** because of this, and has been since before the
Austin/Travis wave. Austin/Travis added no regression (`UNREACHABLE` held at baseline 38,
`DEAD_GEOGRAPHY` improved 20 → 19); this is the only thing failing:

```
BAD_GEOMETRY  observed 7 (baseline 5)
  in JUDICIAL  Indiana Appeals Court Judge - District 1 (Retain Bailey?)    [1800001]
  in JUDICIAL  Indiana Appeals Court Judge - District 2 (Retain Bradford?)  [1800002]
BAD_GEOMETRY  in|JUDICIAL  observed 2 (NEW bucket — this jurisdiction was clean before)
```

## The actual defect — read this before touching anything

It is **not** "two rows are broken". It is that **the same Court of Appeals district is modelled two
different ways depending on which judge's retention row it is.** Measured against prod 2026-08-18:

| `geo_id` | districts | what they are | geofence rows |
|---|---|---|---|
| `18` | **14** | all 5 COA districts *and* the Supreme Court retentions | 1 (statewide Indiana, valid) |
| `1800001` | 1 | COA **District 1** (Retain Bailey?) | **0** |
| `1800002` | 1 | COA **District 2** (Retain Bradford?) | **0** |

So COA District 1 exists twice — once on `18` (Retain Foley?) and once on `1800001` (Retain Bailey?).
Same for District 2 (`18`/Retain Altice? and Retain Kirsch?, vs `1800002`/Retain Bradford?).

🔴 **AND THE TWO FAILING ROWS ARE THE MORE CORRECT ONES.** Indiana Court of Appeals judges in the
**1st, 2nd and 3rd Districts stand for retention by the voters of their own district only**; the 5th
District's judges are voted on statewide. So the 14 rows sitting on `geo_id='18'` are an
**over-inclusive shortcut** — they would show a District 1 judge to a District 3 voter. The two rows
that fail the gate were an attempt to model it properly and simply never had polygons loaded.

**Do not "fix" this by setting `1800001`/`1800002` to `'18'`.** That turns the gate green by making the
data less correct, which is the exact trade the gate exists to prevent.

## Question that must be resolved FIRST (do not assume)

**Which COA districts are geographic, and which are statewide?** The one source consulted so far says
Districts 1–3 retain by district and the 5th is statewide, and says nothing definitive about the
**4th**. Our DB has rows for all five. Resolve from statute/primary source before building anything:

- Indiana Code on Court of Appeals districts and their county composition (Title 33) —
  `iga.in.gov`. This is the authority for **which counties are in which district**.
- `in.gov/courts/appeals/about/faqs/` and `in.gov/courts/about/retention/` for the retention rule.
- ⚠ Ballotpedia may be used as a cross-check only. It was **stale on Travis County Pct 4** in the
  Austin wave (months out of date on an appointment), so it is a detector, not an oracle.

Record the answer in the migration header, including the 4th District's disposition.

## Build method — union of counties, not a sourced shapefile

Indiana's appellate districts are defined as **groups of counties**, and we already hold **every
Indiana county geofence** (`essentials.geofence_boundaries`, `mtfcc='G4020'`, `geo_id='18xxx'`). So the
polygons are **derived, not downloaded**:

```sql
-- shape of it; do NOT run until the county lists are sourced from statute
INSERT INTO essentials.geofence_boundaries (geo_id, name, state, mtfcc, geometry, source)
SELECT '<district geo_id>', 'Indiana Court of Appeals District N', '18', '<mtfcc>',
       public.ST_Multi(public.ST_Union(g.geometry)), '<statute cite + migration NNNN>'
FROM essentials.geofence_boundaries g
WHERE g.mtfcc = 'G4020' AND g.geo_id IN ( /* member county FIPS */ );
```

Then validate: `ST_IsValid`, `NOT ST_IsEmpty`, and that the unioned area ≈ the sum of its counties (a
union that silently dropped a county still passes `ST_IsValid`). `ST_MakeValid` if needed.

🔴 **MTFCC CHOICE IS LOAD-BEARING — check it against `MTFCC_DISTRICT_TYPE_GUARD` in
`src/lib/geoIdGuard.ts` before picking one.** Reading the guard as it stands:
- `G4020` admits `JUDICIAL`, but reusing the county MTFCC for a multi-county district is misleading.
- Anything matching `X%` is restricted to `LOCAL`/`COUNTY` by the X catch-all — **an `X0005`-style code
  would NOT admit `JUDICIAL`** and the districts would stay unreachable.
- A non-`X`, non-excluded code is admitted for any `district_type` by the fallback clause. The excluded
  list is `FALLBACK_EXCLUDED_MTFCCS`.
Whatever is chosen, add an **explicit** guard clause rather than relying on the catch-all, and extend
`geoIdGuard.test.ts`.

## Also decide: what happens to the 14 rows on `geo_id='18'`

Once real district polygons exist, the statewide rows are the remaining inconsistency. Options:
1. Repoint each COA retention row at its own district's `geo_id`, leaving only the Supreme Court
   retentions (and any genuinely statewide COA seats) on `18`. **Most correct.**
2. Leave them and accept that most Indiana appellate retentions are over-inclusive.

Option 1 is the point of the exercise. Note it changes what real voters see, so it deserves the
before/after address probe below.

## Acceptance criteria

- [ ] County composition per district cited from statute in the migration header; 4th District resolved.
- [ ] Real polygons in `geofence_boundaries`, `ST_IsValid` and non-empty, area cross-checked.
- [ ] MTFCC admitted for `JUDICIAL` by an **explicit** guard clause; `geoIdGuard.test.ts` extended.
- [ ] `npm run check:reachability` **green**, with `BAD_GEOMETRY` back to its baseline of 5 and
      **no new `UNREACHABLE`** — repointing rows can strand them, so check both directions.
- [ ] Address probe before/after: a point in District 1 returns District 1's judges and **not**
      District 3's. That end-to-end probe is the only reliable detector.
- [ ] Baseline file untouched, or updated in the same commit with a written reason.

## Notes

- Related and pre-existing: `.planning/todos/2026-07-30-indiana-address-reachability.md` — 17 of 18
  stranded Indiana officeholders need geography that does not exist. **Indiana is not a merge job.**
- 🔴 `geo_id` alone is not unique across MTFCCs anywhere in this database. Scope every statement by
  `(geo_id, district_type)` or `(geo_id, mtfcc)`.
- The earlier reachability failure (`syntax error at or near "$"`) was a **different** incident, caused
  by `1dc0562b` interpolating a constant into a guard read as raw text, and was fixed in `bad34f33`.
  Do not conflate the two.
- Interim, if master needs to be green before this lands: baseline the two rows **with the reasoning
  written into the commit**, and link this file. The gate's own failure message sanctions that when the
  growth is understood. Offered 2026-08-18 and declined in favour of doing it properly.
