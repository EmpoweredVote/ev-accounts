# UT city council seats are unreachable by address search

**Status:** worked up, NOT applied — awaiting go/no-go
**Found:** 2026-07-30, while cleaning up after migrations 1495–1497
**Severity:** user-visible outage in 6 of Utah's largest cities (~760k residents)

## Symptom, proven empirically

Running the real `resolveOfficialsAtPoint` join (`essentialsService.ts:722-776`) against each
city-hall coordinate returns **no district council member**:

| city hall point | what address search returns today |
|---|---|
| Salt Lake City | **Mayor only** — zero council representation |
| Ogden | Mayor + 3 At-Large — **no District councilor** |
| Provo | Mayor + 2 Citywide — **no District councilor** |
| Sandy | Mayor + 3 At-Large — **no District councilor** |
| West Jordan | Mayor + 3 At-Large — **no District councilor** |
| West Valley City | Mayor + 2 At-Large — **no District councilor** |
| **Murray (healthy reference)** | **Mayor + `LOCAL` "Murray City Council, District 3" → Clark Bullen** ✅ |

## Root cause: geography and occupancy live on DIFFERENT district rows

Every affected seat exists **twice**, as two `districts` rows:

- **LIVE row** — `geo_id`/`ocd_id` = `.../place:<city>/council_district:N`
  active holder, all the stances, `chamber_id` set, `seats` NULL,
  **no `geofence_boundaries` row at all** → never enters the ST_Covers join
- **GEO row** — `geo_id`/`ocd_id` = `.../place:<city>/ward:N`
  **owns the real polygon** (mtfcc `X0001`, source `ugrc_sgid_2026`, valid, 47–1015 pts),
  `seats=1`, holds all the contacts, but its holder is a duplicate politician row with
  `is_active=false`

The address query ends with `AND (p.is_active = true OR o.is_vacant = true)`
(`essentialsService.ts:774`). So **both halves fail**: the row with geography is filtered out for
having an inactive holder, and the row with the live holder has no geography to match. Neither is
individually "wrong enough" for any existing guard to notice.

Counts per city — `council_district` (live, no geofence) vs `ward` (geofence, retired):

| city | live seats | ward offices | ward geofences |
|---|---|---|---|
| Salt Lake City | 7 | 4 | 5 |
| Provo | 5 | 5 | 5 |
| Ogden | 4 | 3 | 4 |
| Sandy | 4 | 4 | 4 |
| West Jordan | 4 | 4 | 4 |
| West Valley City | 4 | 4 | 4 |
| **total** | **28** | **24** | **26** |

## Why `ward:N` is the survivor key (durability, not aesthetics)

`backend/data/arcgis_sources.json` defines every UT city council layer with
`layer_class: 'city_ward'`, `mtfcc X0001`, and `geo_id_template`
`ocd-division/country:us/state:ut/place:<city>/ward:{N}`; `load-arcgis-from-config.ts:128` sets
`ocd_id = geo_id`, and the insert is `ON CONFLICT (geo_id, mtfcc) DO NOTHING`.

So `ward:N` is what the importer **re-asserts on every run**. Re-keying the geofences to
`council_district:N` would be undone (worse: it would insert a *second* `ward:N` polygon) the next
time UGRC is imported. The durable direction is therefore to point the surviving district at
`ward:N`, not to move the geography.

Confirming it from the other side: **10 UT cities are already healthy in exactly this shape** —
Cottonwood Heights, Herriman, Holladay, Midvale, Millcreek, Murray, Riverton, South Jordan, South
Salt Lake, Taylorsville — 47 seats where the `ward:N` district holds BOTH the geofence and an
active holder. That is the target end state. (Same method as migration 1496: let the
non-duplicated peers settle the shape.)

## Plan — migration 1498

Per city, per seat N, with LIVE = `council_district:N` row and GEO = `ward:N` row:

1. **Move `politician_contacts`** from the GEO-side politician to the LIVE politician (26 rows).
2. **Carry `seats = 1`** from the GEO office onto the LIVE office where NULL.
3. **Delete the GEO-side `office_terms`, then the GEO-side offices** (24).
4. **Repoint the LIVE district**: `geo_id` AND `ocd_id` → `.../ward:N`, so the row is
   self-consistent and matches what the importer produces.
5. **Delete the now-empty GEO district rows.** This step is NOT optional: `districts.geo_id` is
   not unique, so leaving both rows with `geo_id = ward:N` and `district_type = 'LOCAL'` makes the
   ST_Covers join fan out and reintroduces duplicate reps.
6. **Leave the retired politician rows `is_active=false`, undeleted** — reversible, and invisible
   per ADR 0002 once their term is gone (same call as 1496).

SLC needs three special cases:
- **Districts 4 and 5** have no `ward` twin district at all — the `ward:4` / `ward:5` polygons
  exist but no district points at them. Repoint only; nothing to delete. (This is why the SLC
  city-hall point, which sits inside `ward:4`, matched *zero* districts.)
- **"Salt Lake City Council Ward 1"** has the `ward:1` polygon and **0 offices**. Delete it after
  repointing District 1.
- Districts 4/5 already carry `ocd_id = ward:N` with `geo_id = council_district:N` — a
  half-migrated hybrid, so guard on the pair, not on either column alone.

### Post-verify gate

- For each of the 6 city-hall points, the ST_Covers join returns a `LOCAL` district office with an
  **active** holder (i.e. the Murray shape).
- **No `geo_id` is shared by more than one UT `LOCAL` district** (fan-out guard).
- 43 stance answers still attached to the surviving politicians.
- 26 contacts on survivors, 0 stranded.
- Every surviving seat has a headshot.
- The 10 healthy cities' seat/holder counts are **byte-identical before and after** (regression
  guard — they must not be touched).

## Deliberately NOT in 1498

- **At-Large / Citywide offices are mis-parented** to the `LOCAL_EXEC` "<City> Mayor" district
  instead of the `LOCAL` "<City> City Council" district (Ogden 3, Sandy 3, West Jordan 3, West
  Valley 2, Provo 2, plus Layton 4, Lehi 5, Orem 6, St. George 5 place-level councils). These ARE
  currently address-reachable, because the place-level `G4110` geofence joins to `LOCAL_EXEC` too
  (`essentialsService.ts:738`) — so this is a district_type/semantics defect, not an outage.
  Separate migration.
- **SLC geofence `name` values are councilmember names, not district names** — and `ward:4` is
  still named "Eva Lopez", `ward:5` "Darin Mano", both of whom no longer hold those seats. Ogden
  uses "Municipal District N" and West Valley "District N" correctly. Cosmetic; fix with the
  At-Large pass.

## Lesson for the detector

This is a **third** distinct duplicate shape, and neither earlier detector sees it:

- 1495 (LA) signature: `terms < offices` on one `(district_id, title)`
- 1496 (UT mayors) signature: `offices > distinct occupants` on one `(district_id, title)`
- **this one: the duplicates are on DIFFERENT `district_id`s**, so any grouping by `district_id`
  is blind to it. It only shows up when you group by `(lower(state), label)` — or, far better,
  when you ask the real question: **does a city-hall point actually return a council member?**

An end-to-end ST_Covers probe per seeded city would have caught all three. Worth adding as a CI
check — `offices_missing_terms` cannot see any of them.
