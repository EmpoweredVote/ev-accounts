# Knight Foundation Cities — live program tracker

**Spec:** [`docs/superpowers/specs/2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)

**Update this file at the end of every session.** It is the only place that knows where the program
stands. `MEMORY.md` holds one pointer to it and nothing else.

Per-state notes: [`fl.md`](./fl.md).

Stage legend, from spec §3:
`1` geography (TIGER place + sldu + sldl) · `2` legislature · `3` city waves · `4` county waves ·
`5` assets (headshots + banner).
Status: `—` not started · `WIP` in progress · `✅` done and gated · `n/a` not required.

---

## Slice status

| # | State | Jurisdictions | 1 geo | 2 legis | 3 city | 4 county | 5 assets |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | FL | Bradenton, Miami, Palm Beach County, Tallahassee | ✅ | ✅ | WIP | WIP | — |
| 2 | GA | Columbus, Macon, Milledgeville | — | — | — | — | — |
| 3 | CA | Long Beach, San José | ✅ | ✅ | — | — | — |
| 4 | IN | Fort Wayne, Gary | ✅ | — | — | — | — |
| 5 | MN | Duluth, Saint Paul | — | — | — | — | — |
| 6 | PA | Philadelphia, State College | — | — | — | — | — |
| 7 | SC | Columbia, Myrtle Beach | — | — | — | — | — |
| 8 | OH | Akron | — | — | — | — | — |
| 9 | CO | Boulder | ✅ | ✅ | — | — | — |
| 10 | NC | Charlotte | ✅ | ✅ | — | — | — |
| 11 | MI | Detroit | — | — | — | — | — |
| 12 | ND | Grand Forks | — | — | — | — | — |
| 13 | KY | Lexington | — | — | — | — | — |
| 14 | KS | Wichita | — | — | — | — | — |
| 15 | SD | Aberdeen | — | — | — | — | — |
| 16 | MS | Biloxi | — | — | — | — | — |

Order of execution is slice 1 → 16 as numbered (spec §3.1: grouped by state, largest group first).

FL stages 3 and 4 are `WIP`, not `✅`: **Bradenton and Manatee County are seated and gated**, and
Tallahassee/Leon, Palm Beach and Miami/Miami-Dade remain. Neither stage closes until all four Florida
jurisdictions are in.

## Jurisdiction detail

| Jurisdiction | State | Parent county | Note |
| --- | --- | --- | --- |
| Bradenton | FL | Manatee | smallest FL jurisdiction — the FL pipeline pilot |
| Miami | FL | Miami-Dade | **not** consolidated; city and county are separate governments |
| Palm Beach County | FL | — | county only, no city half. Banner key undecided (spec §8.3) |
| Tallahassee | FL | Leon | city commission may be entirely at-large — verify |
| Columbus | GA | Muscogee | **consolidated city-county** |
| Macon | GA | Bibb | **consolidated city-county** (Macon-Bibb) |
| Milledgeville | GA | Baldwin | |
| Long Beach | CA | Los Angeles | 4 citywide execs already seated; all 9 council districts absent |
| San José | CA | Santa Clara | Mayor already seated; all 10 council districts absent |
| Fort Wayne | IN | Allen | IN legislature is 12/100 + 6/50 — polygons already loaded |
| Gary | IN | Lake | |
| Duluth | MN | St. Louis | |
| Saint Paul | MN | Ramsey | |
| Philadelphia | PA | — | **consolidated city-county**, coterminous |
| State College | PA | Centre | borough, not a city |
| Columbia | SC | Richland | |
| Myrtle Beach | SC | Horry | |
| Akron | OH | Summit | |
| Boulder | CO | Boulder | CO legislature complete; cheapest slice |
| Charlotte | NC | Mecklenburg | NC legislature complete |
| Detroit | MI | Wayne | banner conflicts with the MI state banner |
| Grand Forks | ND | Grand Forks | ND House is multi-member — 2 per district |
| Lexington | KY | Fayette | **consolidated city-county** |
| Wichita | KS | Sedgwick | banner conflicts with the KS state banner |
| Aberdeen | SD | Brown | SD House is multi-member, with 26A/26B and 28A/28B subdistricts |
| Biloxi | MS | Harrison | |

For the four **consolidated city-counties** — Columbus, Macon, Philadelphia, Lexington — stage 4 drops
the county commission (the city council already is it) but **keeps the separately elected county
officers**. Stage 4 is never skipped entirely. See spec §3.2.

## Baselines measured 2026-08-28

Re-measure rather than trust these once any wave has applied.

### Legislature seats owed

| State | House have/expect | Senate have/expect |
| --- | --- | --- |
| CA | 80/80 | 40/40 |
| CO | 65/65 | 35/35 |
| NC | 120/120 | 50/50 |
| IN | 12/100 | 6/50 |
| FL | **120/120** | **40/40** |
| GA | 0/180 | 0/56 |
| KS | 0/125 | 0/40 |
| KY | 0/100 | 0/38 |
| MI | 0/110 | 0/38 |
| MN | 0/134 | 0/67 |
| MS | 0/122 | 0/52 |
| ND | 0/94 | 0/47 |
| OH | 0/99 | 0/33 |
| PA | 0/203 | 0/50 |
| SC | 0/124 | 0/46 |
| SD | 0/70 | 0/35 |

Total owed: **2,155**, of which **160 are now seated** (FL complete). Remaining: **1,995**.

### Geofence polygons present

| State | sldl | sldu | place | county |
| --- | --- | --- | --- | --- |
| CA | 80 | 40 | 482 | 58 |
| CO | 65 | 35 | 272 | 64 |
| IN | 100 | 50 | 566 | 92 |
| NC | 120 | 50 | 552 | 100 |
| FL | **120** | **40** | **411** | 67 |
| GA | 0 | 0 | 0 | 159 |
| KS | 0 | 0 | 0 | 105 |
| KY | 0 | 0 | 0 | 120 |
| MI | 0 | 0 | 0 | 83 |
| MN | 0 | 0 | 0 | 87 |
| MS | 0 | 0 | 0 | 82 |
| ND | 0 | 0 | 0 | 53 |
| OH | 0 | 0 | 0 | 88 |
| PA | 0 | 0 | 0 | 67 |
| SC | 0 | 0 | 0 | 46 |
| SD | 0 | 0 | 0 | 66 |

Every state except CA, CO, IN and NC needs a `place` + `sldu` + `sldl` load before any seat in it is
reachable by address.

### Local and county seats present

| Jurisdiction | Offices | Seated | With headshot |
| --- | --- | --- | --- |
| Long Beach city | 4 | 4 | 4 |
| Long Beach county (LA) | 3 | 3 | 3 |
| San José city | 1 | 1 | 1 |
| San José county (Santa Clara) | 3 | 3 | 0 |
| **Bradenton city** | **6** | **6** | **0** |
| **Manatee County** | **12** | **11** | **0** |
| every other jurisdiction | 0 | 0 | 0 |

Bradenton and Manatee measured 2026-08-28 after FL-3. Manatee's twelfth office is Commission
District 1, flagged vacant since 2026-02-24 — the incumbent died and the Governor left the seat empty,
so it is on the 2026 ballot for a two-year unexpired term. **17 people, 0 headshots: that is the whole
of FL-3's stage-5 debt so far.**

### Banners present

`long beach` and `san jose` only. 24 missing. Four have a state-banner composition conflict: Miami,
Wichita, Detroit, Charlotte (spec §8.1).

## Migration ledger

| Slice | Wave | Migration slots | Applied |
| --- | --- | --- | --- |
| FL | FL-2 structure | `CC_0006_fl_legislature_structure.sql` | 2026-08-28 |
| FL | FL-2 occupancy | `CC_0007_fl_legislature_incumbents.sql` | 2026-08-28 |
| FL | FL-3 city structure | `CC_0008_bradenton_structure.sql` | 2026-08-28 |
| FL | FL-3 city occupancy | `CC_0009_bradenton_people.sql` | 2026-08-28 |
| FL | FL-3 county (offices + people) | `CC_0010_manatee_county.sql` | 2026-08-28 |
| — | — | next free is **`CC_0011`** | — |

Private MTFCC allocations, which are a second sequence to take numbers from: `X0036` Bradenton wards,
`X0037` Manatee commission districts. **Next free is `X0038`.** There is no central registry — each
wave hardcodes its code in its own loader, so this table is the only place they are listed together.

Append a row per applied migration. Namespace is `CC_` (Cantrell). Take the number last.

## Session log

| Date | Session did | Next action |
| --- | --- | --- |
| 2026-08-28 | Program brainstormed and spec written. Production measured: 2,155 legislative seats owed, 12 states with no `place`/`sldu`/`sldl` polygons, 24 of 26 jurisdictions with zero local seats, 24 banners missing. | (done) |
| 2026-08-28 | **FL-1 + FL-2 APPLIED.** Loaded 120 `sldl` + 40 `sldu` + 411 `place` polygons for FIPS 12; vintage confirmed against the enacted plans `H000H8013`/`S027S8058` (6 of 6 anchors). Seated the Florida Legislature: **160 offices, 155 people, 5 vacancies** (the plan had assumed 160/160). `CC_0006` + `CC_0007`. All gates green, no new reachability bucket, zero missing-terms drift. | Write the FL-3 plan: Bradenton + Manatee County. |
| 2026-08-28 | **FL-3 PLANNED, not applied.** Wrote [`2026-08-28-knight-fl-wave-3-bradenton-manatee.md`](../../docs/superpowers/plans/2026-08-28-knight-fl-wave-3-bradenton-manatee.md): 18 offices, 17 people, 1 vacancy. Measured while planning — the `geo_id` collision includes the COUNTY layer (`12081` is Manatee County **and** HD-81); Bradenton's ward layer is land-only, so the tiling gate goes against TIGER `AREALAND`, not the place polygon; Manatee's four district services are the same boundary to 0.000 sq mi; Commission District 1 is vacant and the Supervisor of Elections' own two pages disagree about it; Manatee is a **non-charter** county. | Execute FL-3 Task 1 (load `X0036` Bradenton wards). |
| 2026-08-28 | **FL-3 APPLIED.** Loaded `X0036` (5 Bradenton wards) and `X0037` (5 Manatee commission districts), then seated **18 offices, 17 people, 1 vacancy** — `CC_0008`, `CC_0009`, `CC_0010`. The four-answer probe at Bradenton City Hall returns Ward 3, Commission District 3, HD-71 and SD-20. All gates green, no new reachability bucket, `offices_missing_terms` unflagged unchanged at 655 of a 699 threshold. Four corrections went into `fl.md`: the `geo_id` collision reaches the **county** layer (`12081` is Manatee County *and* HD-81); the child-county matview rule was too broad; `seat_officeholder()` refuses a NULL `term_start`; and an `external_id` band guard must be an **allowlist**, not a count, or the migration is not idempotent. | Write the FL-4 plan: Tallahassee + Leon County. Verify first whether Tallahassee's city commission is entirely at-large. |
