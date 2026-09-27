# KS — slice 14 (Wichita · Sedgwick County)

Opened 2026-09-26. **Nothing has been written to production.** This file records the baseline as
measured when the slice opened, and the two mistakes that measurement corrected.

Lease: `state:ks`, claimed 2026-09-26, expires **2026-09-28 06:08Z**. Branch: `knight/ks-slice14`.

## 🔴🔴 THE FIRST MEASUREMENT OF THIS SLICE WAS WRONG, AND THE LOADER'S OWN COMMENT CAUGHT IT

A first pass counted `essentials.districts` for Kansas and concluded **"zero places"**, which would
have put a 600-row `place` load into stage 1 that Kansas does not need.

`scripts/load-state-tiger-boundaries.ts` says, in the ND block, that North Dakota

> *"owes no `place` load — one of six such states (**KS** KY MI MS ND SD)"*

▶ **That contradiction was the tell.** Re-measured against `essentials.geofence_boundaries`,
Kansas holds **114 `G4210` place rows**. The first query was counting the wrong table: places have
boundary rows and **no `districts` rows**, so a districts-only count reports zero and looks
authoritative.

🔴 **AND THE TWO TABLES KEY DIFFERENTLY.** `districts.state` holds a **USPS** code (`ks`);
`geofence_boundaries.state` holds a **2-digit FIPS** code (`20`). A query written for one and
pointed at the other returns an empty set rather than an error.
▶ **Measure geometry in `geofence_boundaries` keyed by FIPS. Measure offices and districts in
`districts` keyed by USPS.** Never infer one from the other.

⚠ **`PROGRAM.md`'s `626` column for Kansas is COUNTY SUBDIVISIONS, not places.** Reading it as a
place count is what made the first pass plausible.

## Baseline as measured when the slice opened, 2026-09-26

### Geometry — `essentials.geofence_boundaries`, `state = '20'`

| MTFCC | Kind | Rows |
| --- | --- | --- |
| `G4040` | cousub / MCD | 1,391 |
| `G6350` | (unclassified in this query) | 704 |
| `G4110` | county subdivision | 626 |
| `G4210` | **place** | **114** |
| `G4020` | county | 105 |
| `G5200` | congressional | 4 |
| **`G5210`** | **sldu (state senate)** | **0** |
| **`G5220`** | **sldl (state house)** | **0** |

🟢 **The two zeros were CONTROLLED before they were believed.** The same query shape over states
known to hold legislative geometry returns Kentucky **38/100**, Michigan **38/110**, North Dakota
**47/48**. The detector can see geometry where it exists; Kansas genuinely has none.

### Districts and offices — `essentials.districts`, `state = 'ks'`

| Kind | Rows |
| --- | --- |
| county (`G4020`) | 105 |
| congressional (`G5200`) | 4 |
| statewide, **no MTFCC** | 6 |
| **place / sldu / sldl** | **0** |

⚠ **The six MTFCC-less rows are not an anomaly** — they are the statewide entities: US Senate
(2 offices) and five state executives (Governor, Lt Governor, Attorney General, Secretary of State,
Treasurer). A statewide district legitimately carries no MTFCC and `geo_id = '20'`.

**Kansas holds ZERO state legislative offices.** `PROGRAM.md` records `0/125` House and `0/40`
Senate.

## What KS-1 owes

**`sldu` + `sldl` only** — the same shape as OH, PA, SC, MI, ND and KY. No `place` load, no
`county` load, no `cd` load; all three are already in production.

```ts
KS: new Set(['sldu', 'sldl']),
```

Expected: **40 Senate + 125 House = 165 boundaries and 165 districts.** Stage 2 then owes 165
offices.

## ▶ The open question for KS-1: what dates the map

Kentucky proved that **a count check cannot date a map** — KY was 38/100 in TIGER 2022, 2023, 2024
and 2025 alike, with no code-set discriminator, so vintage had to be proved against the
legislature's own GIS authority rather than against the Census. North Dakota was the opposite: its
own code set dated the plan, because a remedial order dissolved two subdistricts.

**Kansas is unknown on this axis and it must be established before anything is loaded.** Known
starting points, none of them verified yet:

- Kansas redistricted in 2022. The Senate map is **SB 563** and the House map **HB 2736**; the
  congressional map **Ardanna 2** was litigated (*Rivera v. Schwab*) and upheld by the Kansas
  Supreme Court in May 2022. Whether either legislative map was challenged is **not established
  here** — read it from a primary source, not from memory.
- **Kansas senators serve four-year terms** and were last elected in **November 2024**; House
  members serve two years. So the sitting chamber's electing map is the question MI-1 got wrong
  first — *two chambers of one legislature can be on different plans*.
- The authority to check TIGER against is the **Kansas Legislature's own GIS / redistricting
  office**, not the Census. Find it; do not assume `kslegislature.gov` publishes a service.

🔴 **Do not take "newest TIGER vintage" as the answer.** ND proved the superseded plan can be
published beside the live one and sort ABOVE it on a freshness field.

## Expected scope for the slice

| Stage | Owed | Basis |
| --- | --- | --- |
| 1 geography | **165** — 40 sldu + 125 sldl | measured above; place/county/cd already present |
| 2 legislature | **165 offices** — 125 House + 40 Senate | Kansas holds zero today |
| 3 Wichita | unmeasured | city council, from the charter |
| 4 Sedgwick County | unmeasured | Kansas county officers, from state law |
| 5 assets | 165 + city + county portraits, plus a `wichita` banner | |

🔴 **WICHITA'S BANNER COLLIDES WITH THE KANSAS STATE BANNER** — one of four such cities in the
programme (with Miami, Detroit and Charlotte). ▶ **Read `states/KS.jpg` in the 6:1 band before
choosing anything**; Charlotte and Lexington both turned on whether the state banner actually shows
the subject its credit names.

## Next steps, in order

1. **Establish the map vintage** against the Kansas Legislature's own authority, with a control that
   fails — the KY-1 shape.
2. Add the allowlist entry and a pre-flight block asserting **40 and 125**, and watch each assertion
   fail before trusting it.
3. Load, measure `districts` and `geofence_boundaries` from outside against a same-session baseline
   taken **through the same connection the loader writes with**, and re-run to prove 0 inserted.
4. Probe end to end from a Wichita address, with a negative control outside Kansas.
5. Then stage 2 — **the legislature must precede the cities.**

## Debts this slice already owes

- Nothing yet. Nothing has been written.
