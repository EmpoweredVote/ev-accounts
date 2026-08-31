# Georgia — slice 2 notes

**Program tracker:** [`PROGRAM.md`](./PROGRAM.md) · **Spec:** [`docs/superpowers/specs/2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)

Jurisdictions: **Columbus** (Muscogee), **Macon** (Bibb), **Milledgeville** (Baldwin).

| Wave | Scope | Status |
| --- | --- | --- |
| GA-1 | TIGER `place` + `sldu` + `sldl`, FIPS 13 | ⏸ **measured, not loaded** — the vintage anchor check is not finished |
| GA-2 | Legislature: 180 House + 56 Senate | — |
| GA-3..5 | Columbus, Macon, Milledgeville | — |

---

## Starting position, measured against production 2026-08-31

| What | Georgia holds |
| --- | --- |
| `geofence_boundaries` | `G4020` county **159**, `G5200` congressional **14**, `G6350` **751**. **No `place`, no `sldu`, no `sldl`.** |
| `districts` | COUNTY 159, NATIONAL_LOWER 14, NATIONAL_UPPER 1, STATE_EXEC 4. **Zero STATE_LOWER, STATE_UPPER, LOCAL.** |
| `offices` | 14 US House (13 seated), 4 NATIONAL_UPPER (4 seated), 4 STATE_EXEC (4 seated) |
| Target jurisdictions | Baldwin, Bibb, Muscogee counties exist as districts with `geo_id`. **All three carry ZERO offices.** |

So Georgia is greenfield below the congressional layer, exactly as the spec's §2 measurement said.

## TIGER 2024 FIPS 13, measured from the raw `.dbf` before any load

Files downloaded to `backend/data/seed-ga-2026/` (untracked) on 2026-08-31.

| Layer | Raw records | Keep | mtfcc | `LSY` | `ZZZ` pseudo-districts |
| --- | --- | --- | --- | --- | --- |
| `sldl` | 180 | 180 | `G5220` | `2024` on all 180 | 0 |
| `sldu` | 56 | 56 | `G5210` | `2024` on all 56 | 0 |
| `place` | 675 | **537** | `G4110` 537 + `G4210` 138 CDPs | — | 0 |

Georgia is **single-member in both chambers**, so polygon count equals seat count: 180 and 56.
`county` is already loaded (159) and is deliberately excluded from the layer allowlist — those rows
carry the county districts this slice will hang offices on. `cousub` is excluded: Georgia is not a
strong-MCD state, its county subdivisions are statistical militia districts. **Do not add GA to
`COUSUB_FUNCSTAT_STATES`.**

### 🔴🔴 The `geo_id` collision is THREE-WAY in Georgia, not two-way

| Layer | GEOID range |
| --- | --- |
| `sldl` | `13001` → `13180` |
| `sldu` | `13001` → `13056` |
| `county` | `13001` → `13321` (odd steps) |

All 56 `sldu` GEOIDs collide with `sldl`, **and 89 of the 159 county GEOIDs fall inside the `sldl`
range**. So `13009` is Baldwin County **and** State House District 9; `13021` is Bibb County **and**
House District 21. Florida's collision reached the county layer too, but only between two legislative
layers plus county — here three layers overlap at once.

**Every join must pair `geo_id` with `district_type` (or `mtfcc`). Never match on `label`.**

### 🔴 Two of the three target places are consolidated, and the consolidation is COMPLETE — measured

Nashville's lesson was that a consolidated city's TIGER *place* can be the **balance**, excluding
satellite municipalities whose residents still elect the consolidated council. That is **not** the
case here, and it was measured rather than assumed:

| Place | GEOID | TIGER `ALAND` + `AWATER` | Its county, measured in prod | Verdict |
| --- | --- | --- | --- | --- |
| Columbus city | `1319000` | 216.500 + 4.511 = **221.011** sq mi | Muscogee `13215` = **221.011** | identical — whole county |
| Macon-Bibb County | `1349008` | 249.383 + 5.523 = **254.906** sq mi | Bibb `13021` = **254.906** | identical — whole county |
| Milledgeville city | `1351492` | 20.259 + 0.161 sq mi | Baldwin `13009` = 268.276 | ordinary city inside a county |

Neither Payne City (Bibb) nor Bibb City (Muscogee) appears anywhere in the TIGER 2024 place file —
both dissolved into their consolidated governments. There is no satellite municipality to strand.

### 🔴 TIGER models Georgia's consolidated governments in TWO different ways, and the difference is the tell

Exactly two `G4110` places in the whole state carry `FUNCSTAT = 'F'` rather than `'A'`:

```
1304204  Augusta-Richmond County consolidated government (balance)
1303440  Athens-Clarke County unified government (balance)
```

Those are **balance** records, and they exist because Richmond County still contains Hephzibah and
Blythe, and Clarke County still contains Winterville and Bogart. **Macon-Bibb County is `FUNCSTAT =
'A'`** — a whole-county place, no balance. So in Georgia, `FUNCSTAT` on the consolidated place tells
you whether satellites exist. Neither of our two consolidated targets is a balance record.

⚠ If a later slice takes Augusta or Athens, that `'F'` is the Nashville problem waiting.

### 🔴 "Macon County" is NOT Macon's county

Production holds both `13021 Bibb County` (which contains the city of Macon) and `13193 Macon
County` — a different, rural county 60 miles away. A name-based lookup for Macon's parent county
returns the wrong row. Bibb is the parent. Same class of defect as the FEC homonyms.

### TIGER place naming trap for the city assertions gate

TIGER does not call it "Macon city". The record is **`Macon-Bibb County`**. A
`STATE_CITY_ASSERTIONS` entry of `'Macon city'` would fail on correct data, and the gate is a
substring match, so it is weak either way. The load-bearing check stays an **exact `geo_id`** query:

| Jurisdiction | Place GEOID | TIGER `NAMELSAD` | Interior point (lon, lat) |
| --- | --- | --- | --- |
| Columbus | `1319000` | Columbus city | -84.8749462, 32.5101909 |
| Macon | `1349008` | Macon-Bibb County | -83.6940595, 32.8089903 |
| Milledgeville | `1351492` | Milledgeville city | -83.2406135, 33.0879449 |

## ⏸ The vintage check — STARTED, NOT FINISHED. Do not load until it closes.

Georgia's 2021 legislative maps were **struck down** by a federal court on 2023-10-26. Remedial House
and Senate plans passed 2023-12-05, were signed 2023-12-08, and were approved by the trial court on
2023-12-28. **The operative maps are the 2023 remedial plans, not the 2021 ones.** This is a sharper
vintage risk than Florida's, where the legislative maps were never litigated.

`LSY = 2024` on all 236 records is consistent with the remedial plans — but `LSY` is a field, not
proof. Florida's rule applies: confirm against the enacted plan itself, independently of TIGER.

What TIGER 2024 answers at the three interior points, computed offline from the downloaded
shapefiles by point-in-polygon:

| Anchor | TIGER House | TIGER Senate | Independent confirmation |
| --- | --- | --- | --- |
| Columbus `1319000` | **HD-137** | **SD-15** | ⏸ not yet |
| Macon-Bibb `1349008` | **HD-145** | **SD-26** | ⏸ not yet |
| Milledgeville `1351492` | **HD-149** | **SD-25** | ⏸ not yet |

⚠ **DO NOT PICK A SERVICE BY ITS NAME.** A search for Georgia legislative services surfaces
`services2.arcgis.com/StQaZGYzUARPnrpL/.../Georgia_Senate_District`, which is a **county
government's** copy of the layer and is described as the **2022** adoption — i.e. the superseded
map. The FL-6 rule stands: the service name is not authority for the vintage; the geometry is.

▶ **The state's own address→district tool is [`Find My Legislator`](https://www.legis.ga.gov/find-my-legislator).**
The Reapportionment Office landing page (`/joint-office/reapportionment`) is a JavaScript shell and
carries no plan-file links in its DOM. Next session: resolve the three anchors through Find My
Legislator, or locate the Reapportionment Office's plan geometry, and only then load.

## Loader work GA-1 needs

`scripts/load-state-tiger-boundaries.ts` has **no `GA` entry**. Adding a state is a deliberate code
change. GA needs:

1. `STATE_LAYER_ALLOWLIST.GA = new Set(['sldu', 'sldl', 'place'])` — the FL shape exactly, with the
   three-way collision and the `FUNCSTAT` finding written into the comment.
2. A `STATE_CITY_ASSERTIONS.GA` entry using the real TIGER strings: `'Columbus city'`,
   `'Macon-Bibb County'`, `'Milledgeville city'`.
3. After loading `place` (`G4110`), refresh `essentials.geofence_child_county` **`CONCURRENTLY`**
   through the Supabase MCP — `ev_api` does not own the matview. `check:child-county` runs in CI on
   every push and fails without it. (Per FL's correction: the refresh is needed after a `place` or
   school-district load, not after every load.)

## Open questions for GA-3 onward

- Which county officers are **separately elected** in Columbus-Muscogee and Macon-Bibb. Spec §3.2
  says consolidation merges the legislative body only, and names Sheriff, Clerk of Superior Court and
  Tax Commissioner as the expected Georgia set — **confirm from each charter, inherit nothing.**
- Council structure for all three: district vs at-large split, and whether the mayor sits on the body.
- Milledgeville is the small pilot for this slice, as Bradenton was for Florida.
