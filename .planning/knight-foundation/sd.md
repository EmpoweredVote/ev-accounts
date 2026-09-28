# SD — slice 15 (Aberdeen · Brown County)

Program tracker: [`PROGRAM.md`](./PROGRAM.md) · spec:
[`2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)

**Opened 2026-09-28.** Lease `state:sd` held by chris@empowered.vote on DESKTOP-G6KDNN2, until
2026-09-29 07:08Z. Worktree `C:\ev-accounts-sd`, branch `knight/sd-slice15`, cut from
`origin/master` at `b200979f`.

| Stage | State |
| --- | --- |
| 1 geography | ▶ **OPEN — `sldu` + `sldl` ONLY.** `place` (310) and `county` (66) already exist; SD holds **zero** state legislative polygons |
| 2 legislature | ▶ **OPEN, FROM ZERO.** South Dakota holds **no legislative office at all** — 0 of 70 House, 0 of 35 Senate |
| 3 city waves | ▶ **OPEN, FROM ZERO.** Aberdeen holds no government row, no chamber and no office |
| 4 county waves | ▶ **OPEN, FROM ZERO.** Brown County holds no government row, no chamber and no office |
| 5 assets | — not started. No `aberdeen` banner key |

---

## 🔴🔴 THE ONE THING THAT MAKES THIS SLICE DIFFERENT: THE HOUSE IS MULTI-MEMBER **AND PARTLY SINGLE-MEMBER**, AND A COUNT OF 70 CANNOT TELL THE TWO APART

This is carried from the program note and from ND's precedent. **It is NOT yet proved against a
South Dakota source, and it must be proved before SD-1 loads anything.** Written here as the
hypothesis to test, not as a fact.

| | polygons (expected) | seats (expected) |
| --- | --- | --- |
| Senate | 35 | 35 |
| House | **35 or 37 — MEASURE IT** | **70** |

The claim carried in is: 35 legislative districts, each electing one senator and two
representatives, **except districts 26 and 28, which are split into single-member subdistricts
26A / 26B and 28A / 28B**. That gives 33x2 + 4 = 70 House seats.

🔴🔴 **70 IS THE SAME TOTAL ON A WRONG STRUCTURE.** 35 whole districts electing two each is also
70. So the House seat count **cannot** distinguish the real structure from a flat two-per-district
one. Neither gate that closed an earlier slice carries over:

- **MI-4's "exactly one office per district"** is false here on every whole district.
- **ND's "exactly two on each whole district, one on each subdistrict, 94 in total"** is the right
  *shape*, but ND's numbers are its own. SD's version is **exactly two offices on each whole
  district, exactly one on each of 26A, 26B, 28A, 28B, and 70 in total** — and the count of whole
  districts in that sentence is the number SD-1 must measure, not assume.

▶ **The discriminating measurement is the TIGER `sldl` polygon count for FIPS 46.** If TIGER files
the subdistricts separately, `sldl` is **37** polygons for 70 seats. If it files districts 26 and
28 whole, `sldl` is **35** polygons for 70 seats and the subdistrict split lives only in the
statute. Read the `.dbf` and count — the same way ND's 48 was established. Do not infer it from the
seat total.

⚠ **A South Dakota House district is probably not an integer either.** `26A` and `28B` are labels,
not numbers. ND-1 hit exactly this with `4A`/`4B`; read [`nd.md`](./nd.md) § "A NORTH DAKOTA HOUSE
DISTRICT IS NOT AN INTEGER" before writing any district-label handling.

▶ **The program's four-answer probe will return FIVE answers in South Dakota** on a whole district
— council member, county commissioner, state senator, and **two** state representatives — and
**four** inside 26A/26B/28A/28B. Neither count is a defect. Aberdeen's own district must be
established before the probe is written, because which of the two shapes applies there decides what
the probe asserts.

---

## Baseline as measured when the slice opened, 2026-09-28 — before anything was written

Measured against production (`supabase-local` MCP) in this session. **Nothing has been written.**

### What already exists

| Thing | Count | Note |
| --- | --- | --- |
| `governments` for SD | **1** | `State of South Dakota`, `geo_id` **46**, id `29fbd5e8-ef43-456b-b89f-2d170062a3b8` |
| `chambers` under it | **5** | one per statewide executive |
| `offices` under it | **5** | Governor, Lieutenant Governor, Attorney General, Secretary of State, Treasurer — **all 5 seated, none vacant** |
| `districts` `STATE_EXEC` | 5 | the seats above |
| `districts` `COUNTY` | **66** | every SD county, including **Brown County `46013`** |
| `districts` `NATIONAL_UPPER` | 1 | |
| `districts` `NATIONAL_LOWER` | 1 | SD's at-large House seat |
| `geofence_boundaries` `G4110` place | **310** | includes **Aberdeen city `4600100`** |
| `geofence_boundaries` `G4020` county | **66** | |
| `geofence_boundaries` `G4040` cousub | **1219** | townships, loaded by `feat/ks-nd-sd-townships` (merged) |
| `geofence_boundaries` `G4210` CDP | 175 | statistical |
| `geofence_boundaries` `G6350` | 376 | ZCTAs |
| `geofence_boundaries` `G5200` | 1 | the at-large congressional district |
| `treasury` budgets | **18** City of Aberdeen (2016-2024) · **8** Brown County (2016-2024) · 48 State of South Dakota (2002-2025) | the only Aberdeen data that exists today |

### What does not exist

- 🔴 **No `sldu` and no `sldl` polygon for FIPS 46 — zero of each.** SD and MS are the last two
  states in the program's geofence table owing them, and they are the only rows that block address
  reachability.
- 🔴 **No legislative office. 0/70 House, 0/35 Senate.** There is no legislature government row, no
  House chamber and no Senate chamber.
- 🔴 **No Aberdeen government, chamber, office or `districts` row.** The city exists only as a TIGER
  polygon and a budget.
- 🔴 **No Brown County government, chamber or office.** The `districts` row exists and carries
  **0 offices**.
- **No `aberdeen` banner key**, and no SD portrait anywhere outside the 5 statewide executives.

### Program-wide baseline measured in the same session

`essentials.offices_missing_terms`: **422 total · 184 flagged `is_vacant` · 238 unflagged.**

⚠ The unflagged count is **238**, matching the 2026-09-24 baseline exactly; the total has fallen by
one (423 → 422). **238 unflagged is the number to hold.** Re-measure immediately before each write
— this figure has no standing value between sessions.

---

## Anchors — bind on these, never on a name

| Anchor | Key | Why it matters |
| --- | --- | --- |
| Aberdeen city | `place` / **`4600100`** | the stage-3 subject |
| Aberdeen city (MCD) | `cousub` / `4601300100` | 🔴 **a SECOND "Aberdeen city" polygon** |
| Aberdeen township | `cousub` / `4601300140` | 🔴 **a THIRD "Aberdeen"** |
| Brown County, SD | `county` / **`46013`**, district id `c1c642b8-3d72-45d3-807f-dce2e2857733` | the stage-4 subject |

🔴🔴 **"Aberdeen" RESOLVES THREE WAYS INSIDE SOUTH DAKOTA ALONE** — one incorporated place and two
county subdivisions, one of which carries the *same* name string, `Aberdeen city`. A match on name
returns all three. **Bind on (mtfcc, geo_id).**

🔴🔴 **"Brown County" RESOLVES NINE WAYS ACROSS THE DATABASE** — measured 2026-09-28, `districts`
holds a Brown County in **IL `17009`, IN `18013`, KS `20013`, MN `27015`, NE `31017`, OH `39015`,
SD `46013`, TX `48049` and WI `55009`**. Indiana's is filed as **nine separate rows**, one per
elected officer (`Brown County Sheriff`, `Brown County Auditor`, …), so a `LIKE 'Brown County%'`
match returns 17 rows for 9 counties. **Bind on (mtfcc, geo_id).** This is the same key rule as the
1,159 known `geo_id` collisions — see `src/lib/geoIdGuard.ts`.

⚠ `treasury.municipalities` already holds its **own** `Brown County` row scoped `SD`
(`e3fe197e-5d8b-41e1-a308-db939851bacd`). It is a different table with a different key and is not a
government row. It does not satisfy stage 4.

---

## Expected scope

| Stage | Expected | Confidence |
| --- | --- | --- |
| 1 geography | `sldu` 35 + `sldl` **35 or 37** polygons | **the polygon count is UNMEASURED** |
| 2 legislature | **105 offices** — 70 House + 35 Senate | seat totals carried, structure unproved |
| 3 Aberdeen | unknown — the office inventory has not been read | **nothing read yet** |
| 4 Brown County | unknown — the office inventory has not been read | **nothing read yet** |
| 5 assets | portraits for everything seated, plus an `aberdeen` banner | |

⚠ **Aberdeen's and Brown County's office inventories are NOT yet known and must not be guessed.**
ND-3 found Grand Forks elects **nine** offices, not eight, because a Municipal Judge is elected and
named in one sentence on a court staff page; ND-4 found Grand Forks County elects **seven** and its
commission sits **at large with no districts**. Read the city's own code and the county's own
charter. Do not standardise the municipality — `backend/data/seed-<place>/ROSTERS.md` first.

---

## Next steps, in order

1. **SD-1 measurement.** Pull TIGER 2024 FIPS 46 `sldu` and `sldl`, read the `.dbf`, and count the
   polygons and their `NAMELSAD` / district-label strings. **Settle 35 vs 37 from the file**, and
   record the exact label strings the subdistricts carry.
2. **Prove the vintage.** A count alone cannot date an SD map. Find identity anchors the way MN used
   Duluth's Senate renumbering and PA used State College's SD-34 → SD-25 — pick points whose
   district number differs between the pre- and post-2021 plans, and probe them.
3. **Add SD to `STATE_LAYER_ALLOWLIST`** in `backend/scripts/load-state-tiger-boundaries.ts` with the
   measurement that justifies its numbers written into the comment, as every other state's entry
   does. 🔴 **This is the program's hottest shared file** — merge `master` into this branch early and
   often, in this worktree.
4. **Dry-run, then apply SD-1.** Assert `districts` and `geofence_boundaries` each move by exactly
   the loaded count and that nothing else moves.
5. **SD-2**: read the legislature's own roster; establish the term-start dates from the body's own
   record, never computed. Then SD-3 and SD-4 on Aberdeen and Brown County.

---

## Debts and open questions this slice already owes

- 🔴 **The House structure is unproved.** 35 vs 37 polygons, and whether 26A/26B/28A/28B are the only
  splits, both open.
- 🔴 **The vintage is unproved.** No anchor has been chosen yet.
- 🔴 **Aberdeen's office inventory is unread**, and so is Brown County's.
- ⚠ **Which legislative district Aberdeen sits in is unknown**, so the acceptance probe cannot be
  written yet — and whether it asserts four answers or five depends on it.
- ⚠ **No `SD` entry exists in the TIGER loader allowlist**, though line 742 already maps FIPS `46` to
  `sd`. The existing SD polygons came from earlier national loads, not from this script.
