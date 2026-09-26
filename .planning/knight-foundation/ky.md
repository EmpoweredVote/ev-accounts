# KY — slice 13 (Lexington · Fayette County)

Program tracker: [`PROGRAM.md`](./PROGRAM.md) · spec:
[`2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)

**Opened 2026-09-26.** Lease `state:ky` held by chris@empowered.vote on DESKTOP-G6KDNN2.
Worktree `C:\ev-accounts-ky`, branch `knight/ky-slice13`.

| Stage | State |
| --- | --- |
| 1 geography | ✅ **APPLIED 2026-09-26 — 138 boundaries, 138 districts, 0 errors.** Only `sldu` + `sldl` were owed; `place` already existed |
| 2 legislature | — **owes 138 offices.** Kentucky holds ZERO state legislative offices today |
| 3 city waves | — Lexington-Fayette Urban County Council, unmeasured |
| 4 county waves | — Fayette County officers. Consolidated, so the commission drops and the officers stay |
| 5 assets | — portraits for everyone seated in the slice, plus one `lexington` banner |

---

## 🔴🔴 THE ONE THING THAT MAKES THIS SLICE DIFFERENT: NOTHING IN THE FILE DATES THE MAP

North Dakota could be dated by its own code set — 49 House polygons is HB 1504, 48 is the remedial
plan. Michigan could refuse an older vintage because an older plan exists. **Kentucky offers neither.**

Measured 2026-09-26 by parsing the `.dbf` inside each TIGER zip directly:

| vintage | `sldu` | `sldl` | `LSY` | `ZZZ` | `000` | codes |
| --- | --- | --- | --- | --- | --- | --- |
| TIGER 2022 | 38 | 100 | 2022 | 0 | 0 | contiguous `001..038` / `001..100` |
| TIGER 2023 | 38 | 100 | 2022 | 0 | 0 | contiguous |
| TIGER 2024 | 38 | 100 | **2024** | 0 | 0 | contiguous |
| TIGER 2025 | 38 | 100 | **2024** | 0 | 0 | contiguous |

**A count check, a code-set check and a contiguity check all pass every vintage.** Both chambers
are single-member, so polygon count *is* seat count — unlike ND and SD. There are no subdistricts
and no letter codes anywhere in the Kentucky file.

▶ **So the vintage evidence in this slice is GEOMETRIC, and nothing else.** That is the whole
reason `scripts/verify-ky-tiger-vintage.mjs` exists and why the loader's pre-flight carries anchors
rather than leaning on its count.

### ⚠ The one field that looks like a discriminator is misleading

`LSY` (legislative session year) moves 2022 → 2024 between TIGER 2023 and TIGER 2024. That reads
like a new plan. It is a Census bookkeeping refresh:

- `ALAND` changes by at most **0.0049%** (Senate) and **0.0306%** (House), median ~0.0000% — noise
  from routine re-digitization of the underlying county and water lines.
- Every TIGER 2024 internal point falls inside the **same** TIGER 2022 district: **38/38 and
  100/100**, 0 moved, 0 not found.

🔴 **THAT UNIFORM ANSWER WAS CONTROLLED BEFORE IT WAS BELIEVED.** A uniform answer is a broken
detector until a positive control passes. The identical comparison run over **North Dakota** — a
state known to have been redistricted between those vintages — reports Senate `015->009` and House
`015->09B`, `009->09A`, reproducing exactly the two districts the *Turtle Mountain* remedial order
moved. The method can see a real plan change. It sees none in Kentucky.

## 🟢 THE AUTHORITY, AND WHY IT IS NOT THE CENSUS

The **Kentucky Legislative Research Commission** — the legislature's own agency, which draws these
districts — publishes them itself:

```
https://kygisserver.ky.gov/arcgis/rest/services/WGS84WM_Services/
  Ky_Legislative_Districts_WGS84WM/MapServer      layer 0 = House, layer 1 = Senate
```

The service's own `copyrightText` is `Legislative Research Commission`. It answers a plain HTTPS
request — no WAF, no Playwright, unlike Ohio's Secretary of State. `outSR=4326` is load-bearing.

Result, measured 2026-09-26: **TIGER 2024 agrees 100/100 (House) and 38/38 (Senate).**

**The control failed as required**: House points against the **Senate** layer agree only **3 of
100**, and those three are numeric coincidence, not geography.

### ▶ TIGER 2022 agreeing is a PASS here, not a failure — the opposite of North Dakota

Kentucky's legislative maps are:

- **HB 2 (2022)** — state House, enacted over the governor's veto **2022-01-20**.
- **SB 2 (2022)** — state Senate, became law without signature **2022-01-21**.
- (SB 3 drew the *congressional* map. It is not a legislative plan and is not loaded here.)

*Graham v. Adams* (Ky., rendered **2023-12-14**) held that partisan-gerrymandering claims **are**
justiciable under the Kentucky Constitution, but **upheld** the plans and ordered **no remedial
map**. SB 2 was never challenged. One plan has governed since 2022 and governs the 2026 election.

So the verifier asserts that TIGER 2022 **must also agree**, and fails if it does not. That
expectation is only meaningful because it is stated in advance: if it ever disagrees, Kentucky was
redistricted after all and this file's premise is wrong.

## 🔴🔴 THE `geo_id` COLLISION LANDS ON THIS SLICE'S OWN COUNTY

Loaded ids run `21001..21038` (`sldu`) and `21001..21100` (`sldl`). Kentucky's **120 counties** are
`21001..21239` odd. So **19 counties collide with the Senate range and 50 with the House range** —
and the worst one is ours. Measured in production after the load:

| `geo_id` | rows | what |
| --- | --- | --- |
| `21001` | **3** | Adair County · State Senate District 1 · State House District 1 |
| `21067` | **2** | **Fayette County** · **State House District 67** |

Grand Forks escaped the identical collision only by luck of odd numbering. Lexington does not.
**Every join must pair `geo_id` with `mtfcc`/`district_type`** — see `src/lib/geoIdGuard.ts`.

### 🔴 A Kentucky district code is not an integer on the authority side

The LRC serves `District = 'H001'` / `'S001'` beside `DistrictID = '001'`. **`parseInt('H001')` is
`NaN`, not 1** — the same family as ND's `04A` and MN's `08A`, where a numeric cast silently
collapses or drops a district. Match on `DistrictID`; never cast a code to a number.

### ⚠ And a name search finds the wrong Fayette

`%fayette%` also matches **`LaFayette city` (`2143444`)**. Match on `geo_id`, never on name — the
same shape as Saint Paul in MN-1.

## ✅ KY-1 APPLIED 2026-09-26

**138 boundaries and 138 districts — 38 Senate + 100 House — 0 errors.** No migration: a pure
geography load writes no offices, so this is the OH-1/MI-1 shape and no slot was taken.

### Measured from outside, against a same-session baseline

Taken through the same connection the loader writes with, as `ev_api`:

| Measure | Before | After | Delta |
| --- | --- | --- | --- |
| `districts` | 10,124 | 10,262 | **+138** exact |
| `geofence_boundaries` | 72,307 | 72,445 | **+138** exact |
| KY `G5210` | 0 | 38 | |
| KY `G5220` | 0 | 100 | |
| `offices_missing_terms` | 422 / 238 unflagged | 422 / 238 | **unmoved** |

⚠ **`offices_missing_terms` read 422, not the 423 recorded at ND-4.** It drifts. Measure it in the
session that writes; never read it off a tracker.

**Idempotent, proved by re-running**: 0 inserted / 138 already existed, and both totals unmoved at
10,262 / 72,445.

### Gates, each watched failing first

| Gate | Tamper | Fired |
| --- | --- | --- |
| Verifier count | Senate 38 → 37 | 🔴 `expected 37 TIGER records, got 38` |
| Verifier control | House compared to the **House** layer | 🔴 `THE CONTROL DID NOT FAIL` |
| Loader count | `KY_PREFLIGHT_CONTROL=count` | 🔴 `[KY MTFCC assertion] expected 37, got 38` |
| Loader vintage | `KY_PREFLIGHT_CONTROL=anchor` | 🔴 `[KY vintage assertion] … resolved to 77, expected 999` |

Each failed for **its own** reason, not by aborting early. A control that aborts for the wrong
reason proves nothing.

⚠ **Kentucky has no `--vintage 2022` control, and that absence is the finding, not an oversight.**
Michigan can refuse an older file because an older plan exists. Kentucky's 2022 file carries the
*same* plan, so loading it is correct — the vintage control had to be **constructed** from the
authority rather than borrowed from an earlier map.

### End-to-end in production, with controls

| Point | House | Senate |
| --- | --- | --- |
| Lexington-Fayette Government Center | **77** | **13** |
| Kentucky State Capitol, Frankfort | 57 | 20 |
| Louisville Metro Hall | 43 | 33 |
| Paducah City Hall | 1 | 2 |

- **Negative control**: Nashville, TN returns **0** Kentucky districts.
- **Per-district control**: all 138 resolve to exactly one — **38/38 and 100/100, 0 anomalies**.
- `check:reachability`: nothing regressed, all three buckets at baseline
  (`BAD_GEOMETRY` 4, `DEAD_GEOGRAPHY` 17, `UNREACHABLE` 7).

## Baseline as measured when the slice opened, 2026-09-26

### What already existed

| Layer | Rows | Note |
| --- | --- | --- |
| `G4020` counties | 120 | all of Kentucky |
| `G4110` places | 419 | incl. **Lexington-Fayette urban county `2146027`** |
| `G4210` CDPs | 136 | statistical, not loaded by this program |
| `G5200` congressional | 6 | |

One government row: **`State of Kentucky`**, carrying 5 statewide executives — Governor,
Lieutenant Governor, Attorney General, Secretary of State, Treasurer — **all 5 seated**. No
candidate-office decoy of the kind Ohio carried.

### What did not exist

- **Zero `G5210`/`G5220` rows.** KY-1 closed this.
- **Zero state legislative offices.** Stage 2 owes **138**.
- **No Lexington government row.** Stage 3 creates it.

## 🟢 The authority also carries a roster and a portrait route

The LRC layer serves, alongside the geometry:

`District` · `DistrictID` · `District_Title` · `Party` · `Legislator` · `Full_Name` · `Counties` ·
`LRC_URL` · `PIC_URL`

All 100 House and 38 Senate rows carry a `Full_Name`. That is a stage-2 roster and a stage-5
portrait route from one fetch.

🔴 **Treat it as ONE source needing a second, never as settled.** MN-2's rule stands: a roster list
is not a change-check, and `house.mn.gov` listed a member three months after he resigned. Every
member page must still be read individually, and a departure dated from the member's own page.

⚠ **`Party` is not written.** Party is antipartisan in this schema: it lives on
`races.primary_party`, never on a person or an office.

## Expected scope

| Stage | Owed | Basis |
| --- | --- | --- |
| 2 legislature | **138 offices** — 100 House + 38 Senate | Ky. Const. § 33; both chambers single-member |
| 3 Lexington | unmeasured | Urban County Council, from the charter |
| 4 Fayette County | unmeasured | consolidated — commission drops, separately elected officers stay |
| 5 assets | 138 + city + county portraits, plus a `lexington` banner | |

**Fayette County is split across 9 House and 7 Senate districts** (LRC `Counties` field): House
`039,045,073,075,076,077,079,088,093`; Senate `012,013,017,022,027,028,034`. A Lexington address
must therefore return exactly one of each, not nine and seven.

## Next steps, in order

1. **Stage 2.** Pull the LRC roster plus a second independent source, diff them, list every
   disagreement, and read all 138 member pages for a departure. Write `ROSTERS.md`.
2. Generate structure and occupancy migrations from that file. Take the slot from the allocator
   (`steward slot CC`) — **never count**.
3. Dry-run against production with `BEGIN; … ROLLBACK;` through `psql`, and confirm the rollback
   reverted.
4. Then stage 3 (Lexington), stage 4 (Fayette officers), stage 5 (assets).

## Debts this slice already owes

- Nothing yet. Stage 1 closed clean with no accepted debt.
