# GA-4 — Columbus + Muscogee County

**Status: TASK 1 APPLIED 2026-09-01 (`X0044`, 8 boundaries). TASK 2 WRITTEN AND DRY-RUN CLEAN 2026-09-01 (`CC_wip_columbus_structure.sql`) — NOT APPLIED. Tasks 3-5 not yet written.** Written 2026-09-01, branch `knight/ga-4-columbus-muscogee`.

**Program tracker:** [`.planning/knight-foundation/PROGRAM.md`](../../../.planning/knight-foundation/PROGRAM.md) ·
**State notes:** [`.planning/knight-foundation/ga.md`](../../../.planning/knight-foundation/ga.md) ·
**Roster and every measurement behind this plan:** [`backend/data/seed-columbus-2026/ROSTERS.md`](../../../backend/data/seed-columbus-2026/ROSTERS.md) ·
**Brief:** <https://claude.ai/code/artifact/3154e2c0-b658-4dcb-a253-3e99b432fa1d>

**16 offices, 16 people, 0 vacancies** — 11 city, 5 county. The program's **first consolidated
city-county**.

---

## 0. Blocked on one ruling, and one correction is queued ahead of it

| # | Item | State |
| --- | --- | --- |
| B1 | **Ruling R4** — are the elected Municipal Court Clerk and Municipal Court Judge seated? | ✅ **RULED 2026-09-01 (Cantrell): exclude both.** The wave is **16 offices** |
| B2 | **`CC_0030_baldwin_coroner_succession.sql`** — GA-3 seated a coroner who retired 2026-05-01 | ✅ **APPLIED 2026-09-01.** Chapple holds `-1331019`, so GA-4 starts at `-1331020` |

**Both are now resolved, so Task 1 is unblocked.** The wave is 16 offices and the identity sub-range
is `-1331020 .. -1331035`.

---

## 1. What makes this wave different from GA-3

Consolidation is the headline, but it is the *easy* part: one government, and stage 4 simply drops the
commission. Three things are genuinely new, and each is written up in full in `ROSTERS.md`:

1. **The certified-results route runs out.** The SOS API settled all 18 Milledgeville seats. For
   Muscogee it carries municipal contests **only from 2026**, so it cannot seat the five even-numbered
   districts at all. The charter plus the city's own roster carry them.
2. **Two council-district layers that invert.** The layer with the current roster has the superseded
   geometry; the layer whose geometry matches the county's ballot-building record names a predecessor
   who left in May. Geometry from layer 3, roster from the city — never both from one layer.
3. **Four of the six people Columbus elected in 2026 do not hold the office yet.** Only the winners of
   the two *special* contests started early.

---

## 2. Structure to be created

One government — **Columbus Consolidated Government** — and three chambers.

| Chamber | Offices | District they hang on |
| --- | --- | --- |
| Columbus Council | 8 district + 2 at-large = **10** | 8 × `X0044` (`LOCAL`), 2 × citywide `1319000` (`LOCAL`) |
| Office of the Mayor | **1** | citywide `1319000` (`LOCAL`) |
| Muscogee County Elected Officials | **5** | Muscogee County `13215` / `G4020` (`COUNTY`) |

🔴 **`district_type` differs by tier** — city districts are `LOCAL`, county districts are `COUNTY`.
GA-3's generator got this wrong on its first draft by generalising the city precedent instead of
reading the county one.

🔴 **The citywide district is CREATED; the county district is only ASSERTED.** GA-1 loaded the place
*boundary* `1319000`/`G4110` and created no place *district*, so the citywide `LOCAL` district must be
inserted. The TIGER county load already made `13215`/`G4020` a `COUNTY` district, so inserting it again
would lay a second district over the same ground. The county migration's pre-flight **fails hard** if
that row is missing — the five officers have nowhere to sit without it.

⚠ Note that the citywide `LOCAL` district and the `COUNTY` district cover **identical ground**
(221.011 sq mi each). That is correct and unavoidable under consolidation: same ground, two tiers.
It is also why the acceptance probe must assert both tiers separately.

---

## 3. Tasks

### Task 1 — load the 8 council districts as `X0044` ✅ APPLIED 2026-09-01 (8 boundaries, all 7 gates green, re-runs clean)

Source: `Elections/Districts` **layer 3**, `outSR=4326`, one polygon per `DISTRICTID` 001–008.
**Not layer 10.** Model on `scripts/load-milledgeville-council-boundaries.ts`.

Gates before any write:
- exactly 8 features, `DISTRICTID` 001–008, no duplicates;
- per-district symmetric difference against the dissolved `Elections Combinations` layer **= 0.000 sq mi**
  (this is what proves the vintage, and it is cheap — re-run it, do not trust this file);
- no two districts overlap by more than 0.001 sq mi;
- the union is **146.24 sq mi**, and the county-minus-union gap agrees with the `N/A` combination area
  to within 1 sq mi. 🔴 **Do NOT gate on full coverage of the county — it fails on correct data.**

### Task 2 — city structure (`CC_wip_columbus_structure.sql`) ✅ WRITTEN AND DRY-RUN CLEAN 2026-09-01, NOT APPLIED

1 government, 2 chambers, 9 districts (8 × `X0044` + 1 citywide), 11 offices.

- Mayor: `voting_powers = 'non_voting'` **plus a `representation_note`** — required by CHECK, and both
  read paths must render it. Charter **Sec. 4-201(2) and 4-201(4)**: presides, has a voice, votes only
  to break a tie. 🔴 **CITATION CORRECTED 2026-09-01 — this line said Sec. 4-102, which is
  “General provisions concerning departments” and says nothing about the Mayor.** The note is
  voter-facing prose, so the wrong number would have been published.
- Posts 9 and 10 are titled as at-large and hang on the citywide district. **They have no geometry**;
  both GIS layers return 8 polygons, which is the independent confirmation.
- Post-verify refuses any office titled with *Mayor Pro Tem* (ruling R3).

### Task 3 — city occupancy (`CC_wip_columbus_people.sql`)

11 politicians, 11 terms. Band `-1331020 .. -1331030`.

- 9 terms open-ended at `start_precision 'unknown'` — Columbus publishes no service-start.
- **Barnes `2026-05-26` and Cook `2026-07-14` at `day` precision**, both `how_started` = **`'elected'`**.
  These are the only dated starts in the wave and both are twice-sourced.
  🔴 **CORRECTED 2026-09-01 — this line said `how_started` *special election*, which is NOT a legal
  value.** `essentials.office_terms` carries `CHECK how_started IN ('elected','appointed','succeeded',
  'redistricted','unknown')`. Both won **special** elections; that fact belongs in the `source` string
  and the migration header, not in the column.
- 🔴 The band guard claims **only `-1331020 .. -1331030`**, never the shared band — the FL-4 correction.

### Task 4 — county officers (`CC_wip_muscogee_county.sql`)

1 chamber, 5 offices + 5 people + 5 terms, in **one** migration per spec §3. Band `-1331031 .. -1331035`.
Britt at `2025-01-01` / `month`; the other four `unknown`.

### Task 5 — dry-run, then take the numbers last

🔴 **The occupancy half cannot be dry-run alone** — its offices do not exist yet. Run structure +
occupancy + county as **one transaction ending in `ROLLBACK`**, with the stream asserted to hold zero
`COMMIT` before it is sent (the FL-6 method), then confirm the rollback reverted. Only then rename
`CC_wip_*` → `CC_00NN`, re-counting against **every remote ref**, and apply.

---

## 4. Acceptance

Run the probe **before** applying as well as after — GA-3 scored 2 of 4 beforehand, and FL-6's probe
ruling was only caught because it was run early.

**Anchor A — Columbus Government Center, 100 10th Street.** Four required answers, plus the at-large
pair:

| Slot | Expected |
| --- | --- |
| Council district | exactly 1 councilor |
| Council at-large | exactly 2 (Posts 9 and 10) |
| County officers | exactly 5 |
| State House | HD-137 Debbie Buckner |
| State Senate | SD-15 Ed Harbison |

**Anchor B — a second address in a different council district**, to prove the tiers were not crossed.
A wave that had crossed city and county tiers would still pass anchor A.

🔴 **Pair `geo_id` with `district_type` in every probe join, and demonstrate it** — run one probe
unpaired and record the wrong officials it returns, as GA-3 did. Georgia's `geo_id` collision is
three-way, and `13215` is Muscogee County while `132` is nothing — but `13009`-style collisions bite
elsewhere in the same query.

**Per-district positive control.** `check:reachability` takes no per-jurisdiction probe list, so a green
gate cannot distinguish *swept and clean* from *not swept*. Test all 8 district seats individually at
their own interior point: 1 holder each, 8 of 8.

**Standing gates:** `check:migrations`, `check:occupancy`, `check:reachability` against baseline
5/17/37, `offices_missing_terms` unflagged **unchanged at 655**, and all migrations re-run clean with
the second pass seating 0.

---

## 5. Known traps, carried into the apply

- A guessed SOS election slug returns **HTTP 204**, indistinguishable from "no such contest".
  Enumerate from `/api/jurisdictions/muscogee-county-ga`.
- `gis.columbus.gov` is **Columbus, Ohio**, with a live redistricting layer and a plausible name.
- Layer 3's *school board* field is fresh while its *council* field is stale. Read freshness per field,
  not per layer.
- Re-check the roster on the day of apply. Four councilors and the Mayor change in **January 2027**,
  and this wave's whole point is that a certified result is not a fact about who holds the seat today.
