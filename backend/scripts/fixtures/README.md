# TIGER baseline fixtures

## tiger_baseline_ca.csv

CA byte-equivalence baseline for FIPS 06, captured 2026-05-06 (Phase 130).

Format: `geo_id,mtfcc,row_hash` where `row_hash = md5(ST_AsBinary(geometry))`.
Sorted: `(geo_id, mtfcc)` ascending.
Filter: `WHERE state = '06' AND mtfcc IN ('G5200','G5210','G5220','G4110','G5420')`.
Row count: 1000 data rows (1001 lines including header).

### Why this file exists

This is the source of truth for "the new TS `load-state-tiger-boundaries.ts`
produced the same bytes as the old TIGER pipeline for CA / FIPS 06." The
snapshot test (`test-tiger-baseline-ca.ts`) diffs a fresh dump from the new
loader against this file. Any delta (row count, geo_id set, or row_hash) fails
the gate (PIPE-03 byte equivalence).

### When to regenerate

NEVER regenerate this file unless explicitly accepting a baseline change (e.g.,
a new TIGER vintage with intentional geometry updates). The file is immutable
from the snapshot test's perspective. Re-running the snapshot harness with
`--truncate` does NOT regenerate the baseline — it produces a fresh DB-side
dump and diffs it against this file.

### Per-layer baseline rationale

For each layer, the baseline rows are either
(a) **legacy-Python-derived** — captured from the old EV-Backend Python TIGER
pipeline (now retired) on a clean DB, so the snapshot test validates byte parity
with the legacy implementation; or
(b) **self-referential** — captured from the new TS loader's first run because
no usable legacy source existed (the legacy unsd loader was broken on the
current SQLAlchemy/geopandas stack); the snapshot test validates self-consistency
across re-runs but NOT legacy parity.

| layer | mtfcc | source                                              | rationale        | row count |
|-------|-------|-----------------------------------------------------|------------------|-----------|
| cd    | G5200 | EV-Backend Python (legacy, retired)                 | legacy-derived   | 52        |
| sldu  | G5210 | EV-Backend Python (legacy, retired)                 | legacy-derived   | 40        |
| sldl  | G5220 | EV-Backend Python (legacy, retired)                 | legacy-derived   | 80        |
| place | G4110 | EV-Backend Python (legacy, retired)                 | legacy-derived   | 482       |
| unsd  | G5420 | new TS loader, first successful run                 | self-referential | 346       |

### Capture procedure (historical — for archival reference)

DB target: production Supabase project `kxsdzaojfaibhuzmclfq`. Pre-capture
cleanup truncated the 5 baseline MTFCCs across `state IN ('06','CA')` (see
"Legacy data cleanup" below). The legacy EV-Backend Python TIGER scripts then
re-loaded cd / sldu / sldl / place under uniform `state='06'`. The unsd layer
was captured from the first successful run of the new TS loader (its legacy
Python source had a bug that prevented it from running against the current
geopandas + SQLAlchemy versions).

Hash dump SQL (used for both baseline capture and the snapshot harness):

```sql
\copy (
  SELECT geo_id, mtfcc, md5(ST_AsBinary(geometry)) AS row_hash
  FROM essentials.geofence_boundaries
  WHERE state = '06'
    AND mtfcc IN ('G5200','G5210','G5220','G4110','G5420')
  ORDER BY geo_id, mtfcc
) TO 'fixtures/tiger_baseline_ca.csv'
WITH CSV HEADER
```

The legacy EV-Backend Python TIGER loaders are no longer part of the deployment
surface. Going forward, any TIGER vintage update uses the new TS loader
(`load-state-tiger-boundaries.ts`) and is validated against this baseline via
the snapshot harness (`test-tiger-baseline-ca.ts`).

### Legacy data cleanup (one-time, 2026-05-06)

The first 130-02 capture produced a partial 574-row baseline because production
held legacy rows under the literal string `state='CA'` (instead of FIPS code
`'06'`) for SLDU and half of SLDL. The unique constraint on `(geo_id, mtfcc)`
caused fresh `state='06'` inserts to silently skip. Investigation found that
the 80 G5210 rows under `state='CA'` were composed of 40 correct senate-district
geometries plus **40 orphan rows whose geometry was identical (per
`ST_Equals`) to G5220 assembly districts** — pure data corruption from a
historical loader bug, not a distinct vintage worth preserving.

After explicit user authorization, the truncate scope was widened to all 5
baseline MTFCCs across `state IN ('06','CA')` and re-capture produced clean
data uniformly under `state='06'`. The orphan G5210 duplicates are correctly
absent from this baseline.

### Future TIGER vintage updates

To validate a new TIGER vintage:

1. Update the new TS loader's vintage / congress arguments (see
   `load-state-tiger-boundaries.ts` CLI flags).
2. Run the snapshot harness: `npx tsx scripts/test-tiger-baseline-ca.ts --truncate`.
3. If the diff is clean, no action — the loader is byte-stable.
4. If the diff is intentional (Census re-released boundaries, etc.), inspect
   the diff carefully, get explicit approval, and regenerate this baseline
   from the new clean DB state.
