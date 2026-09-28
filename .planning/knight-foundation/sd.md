# SD — slice 15 (Aberdeen · Brown County)

Program tracker: [`PROGRAM.md`](./PROGRAM.md) · spec:
[`2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)

**Opened 2026-09-28.** Lease `state:sd` held by chris@empowered.vote on DESKTOP-G6KDNN2, until
2026-09-29 07:08Z. Worktree `C:\ev-accounts-sd`, branch `knight/sd-slice15`, cut from
`origin/master` at `b200979f`.

| Stage | State |
| --- | --- |
| 1 geography | ▶ **OPEN — `sldu` + `sldl` ONLY, and the load is MEASURED: `sldu` 35 + `sldl` 37 = 72 polygons.** `place` (310) and `county` (66) already exist; SD holds **zero** state legislative polygons. 🔴 **Blocked on the vintage proof, which the file cannot give** |
| 2 legislature | ▶ **OPEN, FROM ZERO.** South Dakota holds **no legislative office at all** — 0 of 70 House, 0 of 35 Senate |
| 3 city waves | ▶ **OPEN, FROM ZERO.** Aberdeen holds no government row, no chamber and no office |
| 4 county waves | ▶ **OPEN, FROM ZERO.** Brown County holds no government row, no chamber and no office |
| 5 assets | — not started. No `aberdeen` banner key |

---

## ✅ MEASURED 2026-09-28 — THE HOUSE IS 37 POLYGONS FOR 70 SEATS, AND THE STRUCTURE IS PROVED

Measured from the TIGER files themselves by
[`backend/scripts/measure-sd-tiger-legislative.mjs`](../../backend/scripts/measure-sd-tiger-legislative.mjs).
The count is taken **twice by independent routes** — the `.dbf` header's own record count (bytes
4..7, read with no shapefile library) and the number of feature rows the reader yields — and a
**positive control runs first**: a bogus FIPS 99 must 404, or the counts prove nothing. It did.

| | polygons | seats |
| --- | --- | --- |
| Senate `sldu` | **35** | **35** |
| House `sldl` | **37** | **70** |

**TIGER 2024 FIPS 46, measured:**

- `sldl` **37 records**, MTFCC `G5220`, `FUNCSTAT N`, 0 `ZZZ`. Codes `001`-`025`, `027`,
  `029`-`035` — **33 whole districts** — plus **`26A`, `26B`, `28A`, `28B`**. `NAMELSAD` reads
  `State House District 26A`, and so on.
- `sldu` **35 records**, MTFCC `G5210`, 0 `ZZZ`, codes `001`-`035` **contiguous, no letters**.

🔴 **THERE IS NO `026` AND NO `028` POLYGON IN THE HOUSE FILE.** TIGER files those two districts
**only** as their subdistricts. The Senate keeps both **whole**. So the House code set is
deliberately **not contiguous**, and a gate asserting `001..035` contiguous **fails correctly** on
the House. Do not fill the gap.

▶ So the seat arithmetic is **33 × 2 + 4 × 1 = 70**, and the four subdistricts are exactly
26A/26B/28A/28B — **no others**. The claim carried into this slice is now proved against the file
rather than assumed, and 70 is *derived* here, not asserted.

🔴🔴 **70 WOULD HAVE BEEN THE SAME TOTAL ON A WRONG STRUCTURE** (a flat 35 × 2 is also 70), which is
why the polygon count and not the seat count was the measurement. Neither earlier gate carries over:

- **MI-4's "exactly one office per district"** is false here on all 33 whole districts.
- **ND's "48 polygons / 94 seats"** is the right *shape* with the wrong numbers. **SD's gate is:
  exactly two offices on each of the 33 whole districts, exactly one on each of 26A/26B/28A/28B,
  70 in total, and no office on any `026` or `028` district because no such district exists.**

⚠ **A South Dakota House district is NOT an integer**, exactly as ND-1 found with `4A`/`4B` — read
[`nd.md`](./nd.md) § "A NORTH DAKOTA HOUSE DISTRICT IS NOT AN INTEGER". Three traps, all measured:

- 🔴 **Never cast the code to a number, and never reuse a helper that validates it as numeric.**
  `normaliseCode` in `verify-ks-tiger-vintage.mjs` **throws** on `26A` by design.
- 🔴 **The padding rule differs inside one field.** Numeric codes are zero-padded to three
  (`004`); lettered ones are not (`26A`, never `026A`). `GEOID` is FIPS + code, so `46004` and
  `4626A` are both five characters.
- 🔴 **An ASCII sort misplaces the subdistricts** — `26A` sorts *after* `035` because `0` < `2`.
  Numerically they sit between `025` and `027`. Sort on a parsed (number, letter) pair.

### 🔴🔴 THE COUNT CANNOT DATE THE MAP, AND NEITHER CAN THE CODE SET

Measured across four vintages on 2026-09-28. **Every one is 37 records with the identical code
set** — including TIGER 2020, which carries the **superseded pre-2021 plan**:

| vintage | `sldl` records | `LSY` | code set |
| --- | --- | --- | --- |
| TIGER 2020 | 37 | 2018 | same 33 + 26A/26B/28A/28B |
| TIGER 2022 | 37 | 2022 | same |
| TIGER 2024 | 37 | 2024 | same |
| TIGER 2025 | 37 | 2024 | same |

South Dakota's subdistrict structure **survived the 2021 redistricting unchanged**, so a count
check, a letter check and a code-set check **all pass on a decade-old superseded map**. This
reproduces the Kansas and Kentucky findings inside South Dakota.

⚠ **`LSY` looks like a discriminator and is not** — it tracks the Census refresh, not the plan, the
same trap KS-1 documented.

▶ **SD-1's vintage proof must therefore be GEOMETRIC** — identity anchors whose district number
differs between the pre- and post-2021 plans, in the shape MN, PA and ND used. **Still open.**

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
| 1 geography | `sldu` **35** + `sldl` **37** = **72 polygons / 72 districts** | ✅ **MEASURED 2026-09-28** |
| 2 legislature | **105 offices** — 70 House + 35 Senate | ✅ seat total now **derived** (33x2 + 4) |
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

1. ✅ **SD-1 measurement — DONE 2026-09-28.** `sldl` **37**, `sldu` **35**, subdistricts
   `26A`/`26B`/`28A`/`28B`, no `026` or `028` polygon. Script
   `backend/scripts/measure-sd-tiger-legislative.mjs`, which asserts that shape and was watched
   failing on a tampered count **and** on a tampered subdistrict list.
2. ▶ **Prove the vintage — NOW THE BLOCKER, and it must be geometric.** The count, the letters and
   the code set are **identical in TIGER 2020**, which carries the superseded plan, so none of them
   can date the map. Find identity anchors the way MN used Duluth's Senate renumbering and PA used
   State College's SD-34 → SD-25 — pick points whose district number differs between the pre- and
   post-2021 plans, and probe them. The South Dakota Legislative Research Council is the authority
   to look for first; KS-1 shows what a legislature's own enacted plan file is worth.
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

- ✅ ~~The House structure is unproved.~~ **CLOSED 2026-09-28 — 37 `sldl` polygons, 33 whole + four
  subdistricts `26A`/`26B`/`28A`/`28B`, and those are the only splits.**
- 🔴 **The vintage is unproved, and it is now the blocker.** No anchor has been chosen, and the file
  gives no structural discriminator — TIGER 2020 carries the superseded plan with the **same 37
  records and the same code set**. The proof has to be geometric.
- 🔴 **Aberdeen's office inventory is unread**, and so is Brown County's.
- ⚠ **Which legislative district Aberdeen sits in is unknown**, so the acceptance probe cannot be
  written yet — and whether it asserts four answers or five depends on it.
- ⚠ **No `SD` entry exists in the TIGER loader allowlist**, though line 742 already maps FIPS `46` to
  `sd`. The existing SD polygons came from earlier national loads, not from this script.
