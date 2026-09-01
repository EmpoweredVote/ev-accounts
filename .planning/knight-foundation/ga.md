# Georgia — slice 2 notes

**Program tracker:** [`PROGRAM.md`](./PROGRAM.md) · **Spec:** [`docs/superpowers/specs/2026-08-28-knight-cities-program-design.md`](../../docs/superpowers/specs/2026-08-28-knight-cities-program-design.md)

Jurisdictions: **Columbus** (Muscogee), **Macon** (Bibb), **Milledgeville** (Baldwin).

| Wave | Scope | Status |
| --- | --- | --- |
| GA-1 | TIGER `place` + `sldu` + `sldl`, FIPS 13 | ✅ **APPLIED 2026-08-31** |
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

## ✅ The vintage check — CLOSED 2026-08-31. All 236 districts, not three.

Georgia's 2021 legislative maps were **struck down** on 2023-10-26. Remedial House and Senate plans
passed 2023-12-05, were signed 2023-12-08 and approved by the trial court 2023-12-28. **The operative
maps are the 2023 remedial plans.** This is a sharper vintage risk than Florida, whose legislative
maps were never litigated, so the check had to be geometric.

### The authority, and how to get it

The General Assembly's own [Find Your Legislator](https://www.legis.ga.gov/find-my-legislator) page
labels its layers **"Current Georgia House (2023)"** and **"Current Georgia Senate (2023)"** and loads
each as a GeoJSON payload from its own API:

```
/api/legislatormaps/GoogleMaps/House%20Map%202023     180 features
/api/legislatormaps/GoogleMaps/Senate%20Map%202023      56 features
```

🔴 **BOTH ENDPOINTS RETURN HTTP 401 TO curl AND TO an in-page `fetch()`.** They carry a bearer
token minted by `/api/authentication/token`. The way through is to let the page load them itself and
read the response bodies out of the browser's network log — the same shape as the WAF lesson, by a
different mechanism.

### The result

For **every** TIGER polygon, that polygon's own guaranteed-interior point (`INTPTLON`/`INTPTLAT`) was
tested against the state's map:

| Chamber | State features | TIGER polygons | Agree | Differ | Point in no state district |
| --- | --- | --- | --- | --- | --- |
| House | 180 | 180 | **180** | 0 | 0 |
| Senate | 56 | 56 | **56** | 0 | 0 |

TIGER 2024 FIPS 13 **is** the 2023 remedial plan. Load it.

🔴🔴 **TEST EVERY DISTRICT WHEN THE STATE PUBLISHES THE WHOLE MAP — THREE ANCHORS CAN PASS
ON THE WRONG MAP.** Florida used three anchor points because its plan services are queried one point
at a time. Here the entire map arrives in one payload, so the complete comparison costs the same as
three. A remap leaves many districts untouched, so three anchors that all happen to sit in unchanged
districts would agree with the superseded map too. The three anchors this file first recorded
(Columbus HD-137/SD-15, Macon-Bibb HD-145/SD-26, Milledgeville HD-149/SD-25) all matched — but they
are now a subset of a stronger result, not the result.

⚠ **DO NOT PICK A SERVICE BY ITS NAME.** A search for Georgia legislative geometry surfaces
`services2.arcgis.com/StQaZGYzUARPnrpL/.../Georgia_Senate_District`, which is a **county
government's** copy described as the **2022** adoption — the superseded map. It was not used.

## 🟢 The same payload is a GA-2 roster source, and maybe a GA-5 one

Each feature carries the sitting member, not only geometry:

```json
{"District":154,"Name":"Gerald Greene","DateVacated":null,
 "PortraitUrl":"https://www.legis.ga.gov/api/images/default-source/portraits/greene-gerald-115.jpg?size=mpSm",
 "Url":"https://www.legis.ga.gov/members/house/115"}
```

- **236 of 236 districts carry a name**, and `DateVacated` is null on every one — the General Assembly
  is claiming a full house. ⚠ That is ONE source. The wave anatomy needs **two**, and the
  "check every seat for a change since the source was last edited" rule still applies: a payload that
  reports no vacancies is exactly what a stale payload also looks like.
- `Url` yields a stable member id (`/members/house/115`) — a better external key than a name.
- `PortraitUrl` is present for all 236, but `?size=mpSm` is a **thumbnail**. Before stage 5 treats
  these as headshots, test whether dropping or raising `size` returns the original — the Ballotpedia
  `thumbs/200/300/` lesson in a different dress.

## ✅ GA-1 applied 2026-08-31

`scripts/load-state-tiger-boundaries.ts` had no `GA` entry. Adding a state is a deliberate code
change, so GA got the full FL treatment: a layer allowlist entry, a `STATE_CITY_ASSERTIONS` entry and
its own MTFCC pre-flight block, each carrying the measurement that justifies its numbers.

```
npx tsx scripts/load-state-tiger-boundaries.ts --state GA --fips 13 --layers sldu,sldl,place
```

| Layer | Boundaries | Districts | Skipped | Errors |
| --- | --- | --- | --- | --- |
| `sldu` `G5210` | 56 | 56 | 0 | 0 |
| `sldl` `G5220` | 180 | 180 | 0 | 0 |
| `place` `G4110` | 537 | 0 | **138 CDPs** | 0 |
| **total** | **773** | **236** | 138 | 0 |

Every gate passed on the dry run before any write: `GA MTFCC pre-flight` 56 / 180 / 537, and
`STATE_CITY_ASSERTIONS` for all three cities.

### Verified after the load

| Check | Result |
| --- | --- |
| Boundaries by `mtfcc` | `G4110` 537, `G5210` 56, `G5220` 180 — and `G4020` 159, `G5200` 14, `G6350` 751 untouched |
| Districts | `STATE_LOWER` **180**, `STATE_UPPER` **56**, every one with a `geo_id` |
| The three places, by **exact `geo_id`** | `1319000` Columbus 221.011 sq mi · `1349008` Macon-Bibb 254.906 · `1351492` Milledgeville 20.420 |
| Legislative `geo_id` ranges | `G5210` 13001–13056, `G5220` 13001–13180 — intact |
| `check:child-county` | children 7,782 · mapped 7,782 · **stale 0** after the CONCURRENT refresh |

The two consolidated places measure the same after loading as they did in the raw `.dbf`, and the
same as their counties: Columbus 221.011 = Muscogee, Macon-Bibb 254.906 = Bibb.

🟢 **The three-way collision does not bite, because the join is written correctly.** Resolving each
anchor through our own polygons, pairing `geo_id` with `district_type`, returns **exactly two answers
each** and they are the state's answers:

```
Columbus       -> State House District 137 · State Senate District 15
Macon-Bibb     -> State House District 145 · State Senate District 26
Milledgeville  -> State House District 149 · State Senate District 25
```

⚠ The matview refresh needs the `postgres` role — `ev_api` does not own it — so it went through the
Supabase MCP. `REFRESH … CONCURRENTLY` cannot run inside a transaction block, and the MCP wrapped it
without complaint. Per FL's correction, the refresh is required because this load wrote `place`
(`G4110`); a wave that loads only `X` codes does not need it.

## Open questions for GA-3 onward

- Which county officers are **separately elected** in Columbus-Muscogee and Macon-Bibb. Spec §3.2
  says consolidation merges the legislative body only, and names Sheriff, Clerk of Superior Court and
  Tax Commissioner as the expected Georgia set — **confirm from each charter, inherit nothing.**
- Council structure for all three: district vs at-large split, and whether the mayor sits on the body.
- Milledgeville is the small pilot for this slice, as Bradenton was for Florida.
