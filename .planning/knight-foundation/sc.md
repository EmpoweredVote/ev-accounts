# SC — slice 7 (Columbia · Myrtle Beach)

Program tracker: [`PROGRAM.md`](./PROGRAM.md) · spec:
[`2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)

| Stage | State |
| --- | --- |
| 1 geography | ✅ applied 2026-09-20 |
| 2 legislature | — owes 170 offices |
| 3 city waves | — Columbia, Myrtle Beach |
| 4 county waves | — Richland, Horry |
| 5 assets | — |

---

## Baseline, measured against production 2026-09-20 (before anything was written)

Re-measure rather than trust this once any wave has applied.

### What exists

| Layer | Count | Note |
| --- | --- | --- |
| `districts` COUNTY | 46 | all 46 carry a `geo_id`. **Richland `45079`** (Columbia) and **Horry `45051`** (Myrtle Beach) are both present |
| `districts` NATIONAL_LOWER | 7 | congressional |
| `districts` NATIONAL_UPPER | 1 | |
| `districts` STATE_EXEC | 5 | Governor, Lt. Governor, Attorney General, Secretary of State, Treasurer — all five seated |
| `geofence_boundaries` G4020 | 46 | counties, imported 2026-07-10 |
| `geofence_boundaries` G5200 | 7 | congressional, imported 2026-04-02 |
| `geofence_boundaries` G6350 | 424 | ZCTAs |
| `geofence_boundaries` G4110 | 271 | **incorporated places — imported 2026-09-19, the day before this wave opened.** Columbia city `4516000` and Myrtle Beach city `4549075` both present with geometry |
| `geofence_boundaries` G4210 | 204 | CDPs, same import |
| `governments` "State of South Carolina" | **1** | ✅ not Indiana's 18 |
| `chambers` | 5 | all statewide executives; **no legislative chamber** |

### What did not exist

- **No `STATE_UPPER` and no `STATE_LOWER` districts, and no `G5210`/`G5220` boundary rows.** Zero.
- **No state legislative offices.** SC held **15 offices in total**: 7 US House, 2 US Senate, 5
  statewide executives, plus one `Candidate for U.S. Senate — South Carolina` office.
- **No government row for Columbia and none for Myrtle Beach**, and no `districts` row for either
  place — normal, because `place` writes a boundary and never a district.
- **No county subdivisions** (`G4040`). South Carolina is not an MCD state in the way Pennsylvania is.

Indiana's shape does not recur here, and that was verified rather than assumed: one government row,
zero offices on a pseudo-chamber, and `data_source ILIKE '%discovery%'` returns nothing at all,
nationally.

---

## 🔴 Traps found while opening the wave

### 1. 🔴🔴 SOUTH CAROLINA REDREW ITS HOUSE TWICE IN ONE YEAR, AND ONLY THREE POINTS SEPARATE THE TWO MAPS

S.C. Const. Art. III fixes the chambers at 124 and 46, so — exactly as in Pennsylvania — a count can
never date the map. South Carolina then adds a second layer that Pennsylvania does not have:

| Plan | Signed | Status |
| --- | --- | --- |
| 2012 plan | | superseded |
| **Act 118** | 2022-01-27 | House **superseded five months later**; Senate still current |
| **Act 226** | 2022-06-17 | the remedial House plan, "effective for the 2024 election" (RFA) |

So a 124-polygon file is consistent with **three** House maps, two of them five months apart.

**The proof is on all 170 polygons.** Each TIGER 2024 polygon was tested at its own internal point
against the **State of South Carolina's own ArcGIS server**, `gis.state.sc.us`
(`Boundaries_Districts/House_Districts` and `/Senate_Districts`), maintained by the Revenue and
Fiscal Affairs Office — the agency that draws these maps, not a Census mirror:
**124/124 and 46/46 agree, 0 differ, 0 errors.** TIGER's own `LSY` field reads 2024 on every record.

⚠ **And the sweep was then made to fail, twice.**

| Control | Result |
| --- | --- |
| TIGER 2022 — **Act 118**, the superseded House map | **3** districts differ: `HD 52 ↔ 70` swap at their internal points, and `95 → 90` |
| TIGER 2018 — the 2012 plan | **21** House and **6** Senate districts differ |

🔴 **The Act 118 control is the one that matters.** Only three internal points move between the
superseded House map and the live one. A count, a shape check, a plausibility check on population,
and even a comparison against the 2012 plan would all wave the wrong map through. Tool:
[`backend/scripts/verify-sc-tiger-vintage.mjs`](../../backend/scripts/verify-sc-tiger-vintage.mjs),
which carries every half — the 2024 sweep and both controls — and names the districts each control
moves rather than reporting a number.

### 2. 🔴 THE `geo_id` COLLISION IS WITH COUNTIES, AND THIS SLICE'S OWN TWO COUNTIES ARE IN IT

SC legislative GEOIDs run `45001..45124` (House) and `45001..45046` (Senate). SC's 46 counties are
`45001..45091`, odd numbers only. Measured 2026-09-20:

- **all 46 county geo_ids are also a House district geo_id**,
- **23 are also a Senate district**,
- **all 46 Senate ids are also House ids**.

🔴 **`45079` is Richland County AND House District 79** — Richland is Columbia's parent county.
**`45051` is Horry County AND House District 51** — Horry is Myrtle Beach's. Both of this slice's
county waves sit inside the collision. The key is `(mtfcc, geo_id)`, never `geo_id` alone.
`essentials.districts` is safe by construction — `insertDistrictIfMissing` dedupes on
`(geo_id, district_type)` — and it is ad-hoc SQL that will get this wrong. Congressional is
unaffected (4-character ids, `4501..4507`).

### 3. ⚠ THE PLACE LAYER ARRIVED ONE DAY EARLIER, FROM A DIFFERENT WAVE

SC's `G4110` (271) and `G4210` (204) were imported on **2026-09-19** by the municipal wave, not by
this program — the same thing that happened to Pennsylvania one day before PA-1. So **stage 1 here
owed legislative geography only**, and `place` is excluded from SC's allowlist entry with the reason
written next to it. The lesson is the tracker's own: **measure the layer before loading it.**

### 4. 🔴 SIX PLACES ARE NAMED "COLUMBIA CITY", AND TWO SC CITIES CONTAIN "MYRTLE BEACH"

Measured nationally in `geofence_boundaries`:

| Name | Where |
| --- | --- |
| Columbia city | KY `2116750` · MS `2815340` · **SC `4516000`** · SD `4613420` · TN `4716540` |
| Columbia City | IN `1814716` |
| Myrtle Beach city | **SC `4549075`** |
| North Myrtle Beach city | SC `4551280` |

Within SC, `%columbia%` also returns **West Columbia**. This is Minnesota's `St. Paul` trap with a
wider blast radius: a name match can hit five other states. **Match on `geo_id`.** No government row
currently exists for either target, and the only near-miss row nationally is `District of Columbia`.

### 5. ⚠ `check:child-county` CANNOT SEE THIS LOAD, AND THAT WAS READ IN THE SOURCE

The loader prints an ACTION REQUIRED banner asking for a matview refresh after any boundary insert.
It does not apply here: `scripts/check-child-county-mapping.mjs` defines a child as
`mtfcc IN ('G4110','G5420','G5400','G5410')`, so **`G5210` and `G5220` are not children** and this
wave's 170 rows cannot appear in the stale count. Checked in the check's own source, not inferred
from MN-1 or PA-1. The job's pre-existing red is recorded in [`pa.md`](./pa.md) and is not this
wave's.

---

# SC-1 — stage 1 APPLIED 2026-09-20. 170 boundaries, 170 districts, 0 errors.

`scripts/load-state-tiger-boundaries.ts --state SC --fips 45 --layers sldu,sldl`. No migration: this
loader writes `geofence_boundaries` and `districts` directly, the path MN-1 and PA-1 used.

### What was written

| | Boundaries | Districts |
| --- | --- | --- |
| `G5210` / STATE_UPPER | 46 | 46 |
| `G5220` / STATE_LOWER | 124 | 124 |

### Measured from outside, after the apply

- `districts` total **8,989 → 9,159** and `geofence_boundaries` total **71,130 → 71,300** — both moved
  by exactly **170**. Nothing else moved.
- **`offices_missing_terms` unmoved at 823 / 655 unflagged.** Stage 1 creates no office, so this is
  the number that must not move, and it did not.
- **170 distinct `ocd_id`s for 170 rows** (`…/state:sc/sldl:1` … `sldl:124`, `sldu:1` … `sldu:46`).
  The MN `08A` / MD `1A` collapse cannot arise in a state whose codes are plain digits, and the
  loader asserts the distinct count rather than reasoning about it.
- All 170 geometries **valid**, SRID **4326**, and every one a simple polygon — **0 multipolygon**.
- **Idempotent, proved by re-running**: the second run reports `Inserted 0 / Already existed 170`.

### Gates

- **Both pre-flight gates were watched failing first.** The count gate was tampered to expect 45
  Senate districts and aborted at `expected 45, got 46`, before any DB write. The OCD-ID gate was
  tampered to collapse every suffix to one and aborted at `46 records collapsed to 1 distinct`.
  Both were then restored and the real dry-run passed: `46 records (expected 46), 46 distinct
  OCD-ID suffixes` and `124 / 124`.
  - ⚠ **The first attempt at the OCD tamper silently did nothing AND deleted a guard.** A
    line-numbered edit landed on the `skipDistrictCodes` line instead of the `add` line, so the run
    went green with 46 distinct suffixes and the skip rule gone. The green was the tell — a control
    that is supposed to fail and does not has not proved the gate works, it has proved the tamper
    missed. **Read back what a control actually planted.** Same shape as MN-3's two controls that
    aborted for the wrong reason.
- **Per-district control: 46/46 and 124/124 resolve to exactly one district** of their own type by
  `ST_Covers` on `ST_PointOnSurface`, 0 failures.
- **Negative control:** Charlotte NC city hall matches **0** of the 170 SC polygons.
- **Six anchors probed against the rows actually in production**, each geocoded by the Census
  geocoder and answered by both production and the state's own layer:

| Anchor | SD | HD | Agrees with SC RFA |
| --- | --- | --- | --- |
| Columbia City Hall | 26 | 74 | ✅ |
| SC State House | 26 | 72 | ✅ |
| Myrtle Beach City Hall | 33 | 107 | ✅ |
| Charleston City Hall | 43 | 110 | ✅ |
| Greenville City Hall | 7 | 23 | ✅ |
| Rock Hill City Hall | 17 | 49 | ✅ |

- `check:reachability` **nothing regressed, two buckets below baseline**: `BAD_GEOMETRY` 4 of 5,
  `UNREACHABLE` 37 of 38, `DEAD_GEOGRAPHY` 17 of 17.

### 🟢 A third authority for stage 2 already exists, and it is the state's own

`gis.state.sc.us` carries the member on the district: `House_Districts` exposes `District_Num`,
`District`, `Rep_Aff` (name and party) and `URL`; `Senate_Districts` exposes `District_Num`,
`Senator` and `URL`, each `URL` pointing at that member's own `scstatehouse.gov` page.

⚠ Use it as the **third authority, not the primary**. It is a GIS attribute table, exactly the kind
of source that can be stale on a resignation. MN-2's rule stands: **a roster list page is not a
change-check; a member's own page is.** The `URL` field is what makes the per-member sweep cheap.

The same server also publishes `County_Council_Districts` and `Municipalities`, which stages 3 and 4
will need for Richland, Horry, Columbia and Myrtle Beach.

▶ **Stage 2 owes 170 offices — SC currently has ZERO state legislative offices and no legislative
chamber.**
