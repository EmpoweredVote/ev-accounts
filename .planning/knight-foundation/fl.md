# Florida — slice notes

**Spec:** [`docs/superpowers/specs/2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)
**Plan (FL-1, FL-2):** [`docs/superpowers/plans/2026-08-28-knight-fl-waves-1-2.md`](../../docs/superpowers/plans/2026-08-28-knight-fl-waves-1-2.md)
**Roster evidence:** `backend/data/seed-fl-legislature-2026/ROSTERS.md`

Jurisdictions: **Bradenton** (Manatee), **Miami** (Miami-Dade), **Palm Beach County**, **Tallahassee** (Leon).

---

## Status

| Wave | Content | Status |
| --- | --- | --- |
| FL-1 | TIGER `place` + `sldu` + `sldl`, FIPS 12 | ✅ applied 2026-08-28 |
| FL-2 | Florida Legislature | ✅ applied 2026-08-28 — `CC_0006`, `CC_0007` |
| FL-3 | Bradenton + Manatee County | — |
| FL-4 | Tallahassee + Leon County | — |
| FL-5 | Palm Beach County (county only) | — |
| FL-6 | Miami + Miami-Dade County | — |
| FL-7 | Florida assets (headshots + 3 banners) | — |

## Geography loaded (FL-1)

Counts measured against the raw TIGER 2024 FIPS 12 `.dbf` before loading, then verified after.

| Layer | mtfcc | Loaded | Note |
| --- | --- | --- | --- |
| `sldl` | `G5220` | 120 | 0 `ZZZ` pseudo-districts, `LSY = 2024` |
| `sldu` | `G5210` | 40 | 0 `ZZZ` pseudo-districts, `LSY = 2024` |
| `place` | `G4110` | 411 | 956 raw records; the other 545 are `G4210` CDPs, skipped |

Florida is **single-member in both chambers**, so polygon count equals seat count.

`county` (`G4020`, 67 rows) was already present and is deliberately excluded from the allowlist.
`cousub` is deliberately excluded — Florida is not a strong-MCD state, so its county subdivisions are
statistical. **Do not add FL to `COUSUB_FUNCSTAT_STATES`.**

`essentials.geofence_child_county` was refreshed `CONCURRENTLY` after each load. The loader prints an
ACTION REQUIRED notice for this and the FL-1 plan had omitted it; `check:child-county` runs in CI on
every push and fails without it. **Every future slice must refresh the matview after a boundary load.**
The refresh needs the `postgres` role — `ev_api` is not the owner — so it goes through the Supabase MCP.

## 🔴 Identity anchors — the vintage check

Resolved 2026-08-28 against the **enacted plans themselves**, independent of TIGER, and all three
matched after the load.

| Point | Coordinates (lon, lat) | House | Senate |
| --- | --- | --- | --- |
| Tallahassee | -84.2522719, 30.4535287 | HD-9 | SD-3 |
| Bradenton | -82.5768045, 27.4897985 | HD-71 | SD-20 |
| Miami | -80.2086152, 25.7751630 | HD-113 | SD-36 |

Sources, in order of authority:

- **House plan `H000H8013`** — `https://services.arcgis.com/ptvDyBs1KkcwzQNJ/arcgis/rest/services/Florida_House_2022_H000H8013/FeatureServer/2`
- **Senate plan `S027S8058`** — `https://services.arcgis.com/ptvDyBs1KkcwzQNJ/arcgis/rest/services/Florida_Senate_2022_S027S8058/FeatureServer/1`
- Tallahassee also confirmed by **Leon County Supervisor of Elections** (`intervector.leoncountyfl.gov`, layers 5 and 4): District 9 / District 3.
- Miami also confirmed by **Miami-Dade County** `MD_KnowWhereToVote` (`gisweb.miamidade.gov`, layers 7 and 6): 113 / 36.

⚠ **Bradenton has ONE source only.** Manatee County publishes no legislative-district service —
searched ArcGIS Online 2026-08-28, 128 results, none legislative. If the Bradenton anchor is ever the
only one that disagrees, suspect the anchor before suspecting the load.

The plan numbers also confirm the vintage: the operative maps are the **2022 apportionment**, and
Florida redistricts decennially, so the next legislative remap is 2032. Only the congressional map was
litigated after 2022.

## Target-city place GEOIDs (for FL-3 onward)

| Place | GEOID | Interior point (lon, lat) |
| --- | --- | --- |
| Bradenton city | `1207950` | -82.5768045, 27.4897985 |
| Tallahassee city | `1270600` | -84.2522719, 30.4535287 |
| Miami city | `1245000` | -80.2086152, 25.7751630 |
| West Palm Beach city | `1276600` | -80.1270377, 26.7451143 |
| Palm Beach town | `1254025` | -80.0418628, 26.6948430 |

⚠ **`STATE_CITY_ASSERTIONS` is a SUBSTRING match and is weak for Florida.** `'Miami city'` is
satisfied by `'West Miami city'`, which Florida also contains, so a run missing the real Miami record
would still pass that gate. The load-bearing check is the exact-`geo_id` query at the bottom of
`scripts/verify-fl-tiger-import.sql`.

## 🔴 The `geo_id` collision is TOTAL for districts 1–40

Florida's `sldl` and `sldu` GEOIDs **both start at `12001`**, so `12040` is both HD-40 and SD-40.
Every join must pair `geo_id` with `mtfcc` or `district_type`. This is not theoretical here: SD-3,
SD-20 and SD-39 are all inside the colliding range, so two of the three anchors and one of the five
vacancies would resolve to the wrong chamber without the pairing.

## Legislature seated (FL-2)

| | Offices | People | Vacant |
| --- | --- | --- | --- |
| House | 120 | 116 | 4 |
| Senate | 40 | 39 | 1 |
| **Total** | **160** | **155** | **5** |

`external_id` bands: **House `-(1220000 + n)`, Senate `-(1230000 + n)`.**

🔴 **The obvious band was TAKEN.** The NC/CO scheme `-(1210000 + n)` collides with 166 existing rows
at `-1212802 … -1210101` — the 2026 US House candidates from `seed-fl-2026-house/`, keyed
`-12<district><candidate>`. `ON CONFLICT DO NOTHING` would have absorbed the collision silently and
left seats held by whoever already owned those ids. Both bands actually used were measured empty and
are re-asserted by `CC_0007` before it inserts anything.

Date precision: **day 39, year 116, unknown 0.** `how_started` is `'elected'` for all 155 — Florida
fills legislative vacancies by **special election**, not appointment (Fla. Const. art. III, s. 15(d);
ch. 100, F.S.).

## 🔴 The five vacancies

| Seat | Vacant since | Predecessor's last day |
| --- | --- | --- |
| HD-55 | 2026-08-06 | Kevin M. Steele, 2026-08-05 |
| HD-78 | 2026-05-21 | Jenna Persons-Mulicka, 2026-05-20 |
| HD-113 | 2025-11-19 | Vicki L. Lopez, 2025-11-18 |
| HD-116 | 2026-08-22 | Daniel Perez, 2026-08-21 |
| SD-39 | **not published** | not published |

Each has an office with `is_vacant = true`, zero `office_terms` rows and a NULL holder. **Flagging is
load-bearing twice over:**

1. `check-address-reachability.mjs` classifies `DEAD_GEOGRAPHY` as
   `reachable AND offices > 0 AND active_holders = 0 AND vacant_offices = 0`. An unflagged empty
   office fires a **new `fl|STATE_LOWER` bucket** and fails the gate.
2. `essentials.offices_missing_terms` counts only **unflagged** rows as drift. This wave moved it
   814 → 819 total and 159 → 164 flagged, with **unflagged unchanged at 655** against a 699 threshold.

**MIAMI HAS NO STATE REPRESENTATIVE RIGHT NOW.** The city-hall anchor sits in HD-113, so the
four-answer probe for Miami can only ever return three answers until the special election is held.
This is the truth, not a defect — but FL-6 must not be judged as failing because of it.

▶ **Re-check all five before FL-7.** Three of the four House vacancies opened within four months of
2026-08-28, so special elections are pending. Miami-Dade's own GIS still lists "Vicki Lopez" as HD-113's
`REPNAME`, which is a reminder that a county name field can be stale even when its geometry is right.

## Sources for FL-3 onward, not yet gathered

- **Florida's constitutional county officers** are Sheriff, Tax Collector, Property Appraiser,
  Supervisor of Elections and Clerk of the Circuit Court. **Charter counties vary**, so the template is
  confirmed per county from that county's charter, never inherited from the state. Manatee, Leon, Palm
  Beach and Miami-Dade are all to be checked separately.
- **Miami-Dade County and the City of Miami are separate governments.** Miami-Dade is not a
  consolidated city-county. Do not conflate them.
- Miami-Dade's elected **Sheriff** was restored by constitutional amendment and filled recently.
  Confirm the office is elected before seeding it.
- **Tallahassee's city commission may be entirely at-large.** If it is, no ward layer is needed and the
  citywide `place` polygon (`1270600`) carries every seat.
- **Palm Beach County has no city half**, and `buildingImages.js` is keyed by city, so its banner needs
  a decision at FL-5 — a county key, or the Florida state banner as a fallback.
- **Miami's banner cannot be a downtown skyline.** The Florida STATE banner already is one
  ("Miami Late Afternoon Skyline"), and the adjacency rule forbids repeating a composition.

## Applied migrations

| Slot | File | Applied |
| --- | --- | --- |
| `CC_0006` | `CC_0006_fl_legislature_structure.sql` | 2026-08-28 |
| `CC_0007` | `CC_0007_fl_legislature_incumbents.sql` | 2026-08-28 |

Next free slot: **`CC_0008`**.
