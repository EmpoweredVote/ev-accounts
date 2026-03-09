# Feature Landscape — Jurisdiction Resolution

**Feature scope:** `/api/account/me/jurisdiction` endpoint + PostGIS district resolution
**Domain:** Civic location infrastructure — point-in-polygon district assignment
**Researched:** 2026-03-09
**Milestone context:** v1.3 location infrastructure (Indiana-scoped Alpha, Monroe County pilot)

---

## Purpose of This Document

Maps the complete feature surface of a civic point-in-polygon jurisdiction system:
what district types exist, which TIGER/Line files provide them, what the complete
jurisdiction response object looks like, and what edge cases need explicit handling.

The research question: *What does a complete jurisdiction response require to power
Essentials (find all representatives, federal through school board) and Validation
Quests (surface location-relevant quests)?*

---

## District Types Required for Complete Coverage

### Tier 1 — Alpha-Critical (must ship)

These are the minimum set for Essentials to find representatives at every level
and for Validation Quests to surface meaningful location-based content for the
Bloomington/Monroe County pilot.

| District Type | DB Column Name | TIGER/Line Folder | File Pattern | Notes |
|---------------|---------------|-------------------|--------------|-------|
| U.S. Congressional District | `congressional_district` | `CD/` | `tl_2024_18_cd119.zip` | Indiana FIPS = 18; 119th Congress |
| State Senate District | `state_senate_district` | `SLDU/` | `tl_2024_18_sldu.zip` | Upper chamber |
| State House District | `state_house_district` | `SLDL/` | `tl_2024_18_sldl.zip` | Lower chamber |
| County | `county_fips` | `COUNTY/` | `tl_2024_us_county.zip` | National file; filter to Indiana (STATEFP=18) |
| Incorporated Place (city/town) | `place_fips` | `PLACE/` | `tl_2024_18_place.zip` | NULL if unincorporated |
| Unified School District | `school_district_id` | Varies (see below) | `tl_2024_18_unsd.zip` | Indiana uses unified districts |

**Indiana school district note (HIGH confidence):** Indiana classifies its school
districts as Unified (UNSD) — the single district type that covers K-12. Monroe
County specifically has two: Monroe County Community School Corporation (MCCSC,
covers most of Monroe County) and Richland-Bean Blossom Community School Corporation
(covers Richland and Bean Blossom townships). The TIGER/Line UNSD folder covers
these. Indiana does not use elementary-only (ELSD) or secondary-only (SCSD)
split-district types. Load only UNSD for Indiana; ELSD and SCSD are irrelevant
for this Alpha scope.

### Tier 2 — Post-Alpha (add when Validation Quests needs them)

| District Type | DB Column Name | TIGER/Line Folder | File Pattern | Notes |
|---------------|---------------|-------------------|--------------|-------|
| County Council District | `county_council_district` | Not in TIGER | County GIS portals | District-level county legislators; not federally tracked |
| City Council Ward/District | `city_council_district` | Not in TIGER | City GIS portals | Bloomington has 4 wards; sourced from city |
| Census Tract | `census_tract` | `TRACT/` | `tl_2024_18_tract.zip` | Useful for Validation Quest density routing, not for representatives |
| Township | `township` | `COUSUB/` | `tl_2024_18_cousub.zip` | Indiana uses civil townships for fire/trustee jurisdiction |
| Indiana State Senate Committee Subdistrict | — | Not in TIGER | State-specific | Out of scope for Alpha |

### Tier 3 — Explicitly Out of Scope

The following district types exist in Indiana but are not actionable for Essentials
or Validation Quests in Alpha. Do not load shapefiles for these.

- **Special districts** (fire protection, water/sewer, conservancy, soil & water):
  Indiana SBOA tracks ~1,800 special districts. Boundaries are not in TIGER/Line
  and vary by county. There is no statewide GIS source. Defer until a specific
  feature requires them.
- **Judicial circuits and superior courts:** No representative to look up; not a
  voting district.
- **Federal judicial districts:** Informational only; no elected official.
- **ZIP Code Tabulation Areas (ZCTA):** These are statistical geographies, not
  political districts. A user's ZCTA is not a jurisdiction. Do not include in
  the jurisdiction response.

---

## Exact TIGER/Line Files to Load (Indiana Alpha)

All files are from the 2024 vintage (confirmed current as of research date).
The TIGER/Line FTP base path is `https://www2.census.gov/geo/tiger/TIGER2024/`.

| File | Download Path | Layer Name in PostGIS | What It Provides |
|------|--------------|----------------------|------------------|
| `tl_2024_18_cd119.zip` | `CD/tl_2024_18_cd119.zip` | `congressional_districts` | Indiana's 9 congressional districts (119th Congress) |
| `tl_2024_18_sldu.zip` | `SLDU/tl_2024_18_sldu.zip` | `state_senate_districts` | Indiana State Senate, 50 districts |
| `tl_2024_18_sldl.zip` | `SLDL/tl_2024_18_sldl.zip` | `state_house_districts` | Indiana House of Representatives, 100 districts |
| `tl_2024_us_county.zip` | `COUNTY/tl_2024_us_county.zip` | `counties` | All US counties; filter WHERE STATEFP = '18' |
| `tl_2024_18_place.zip` | `PLACE/tl_2024_18_place.zip` | `places` | Incorporated cities and towns in Indiana |
| `tl_2024_18_unsd.zip` | `UNSD/tl_2024_18_unsd.zip` | `school_districts` | Unified school district boundaries in Indiana |

**File naming convention** (HIGH confidence, verified via Census FTP index):
`tl_[year]_[state_fips]_[layer_type]` for state-scoped files.
`tl_[year]_us_[layer_type]` for national files.
Indiana state FIPS = `18`. Monroe County FIPS = `18105`.

**Coordinate reference system:** All TIGER/Line shapefiles use NAD83 (EPSG:4269).
PostGIS stores and queries geography in WGS84 (EPSG:4326). Coordinates from a
geocoder will be WGS84. Either transform on load (`ST_Transform(geom, 4326)`) or
query using `ST_Transform(point, 4269)`. The former (transform on load) is
recommended — do it once at import time, not on every query.

---

## The Jurisdiction Response Object

### Design Principles

1. **Never return raw coordinates or home address.** The endpoint resolves point → district IDs and returns only those IDs plus human-readable names.
2. **Null is valid.** Unincorporated areas have no `place_fips`. Rural areas may lack city council districts.
3. **Include confidence.** When geocoding accuracy is below rooftop-level, surface it so callers can decide whether to trust school board assignment.
4. **Return enough for both consumers.** Essentials needs district IDs to look up representatives. Validation Quests needs district IDs to filter quests by location relevance.

### Complete JSON Response Schema

```jsonc
{
  "jurisdiction": {
    // --- Federal ---
    "congressional_district": {
      "geoid": "1809",           // TIGER GEOID: state_fips + district_number
      "name": "Indiana's 9th Congressional District",
      "district_number": "9"
    },

    // --- State ---
    "state_senate_district": {
      "geoid": "1840",           // TIGER GEOID
      "name": "Indiana Senate District 40",
      "district_number": "40"
    },
    "state_house_district": {
      "geoid": "1846",           // TIGER GEOID
      "name": "Indiana House District 46",
      "district_number": "46"
    },

    // --- County ---
    "county": {
      "fips": "18105",           // 5-digit FIPS: state_fips + county_fips
      "name": "Monroe County",
      "state_fips": "18",
      "county_fips": "105"       // 3-digit county code within state
    },

    // --- Municipal (null if unincorporated) ---
    "place": {
      "fips": "1808308",         // 7-digit FIPS place code
      "name": "Bloomington",
      "class_code": "C1"         // Census LSAD: C1 = incorporated city
    } | null,

    // --- School District ---
    "school_district": {
      "geoid": "1800630",        // NCES/TIGER district ID
      "name": "Monroe County Community School Corporation",
      "type": "unified"          // "unified" | "elementary" | "secondary"
    },

    // --- Resolution Metadata ---
    "resolution": {
      "geocode_accuracy": "rooftop",  // "rooftop" | "range_interpolated" | "geometric_center" | "approximate"
      "geocode_provider": "google",   // or "census" | "nominatim"
      "resolved_at": "2026-03-09T14:23:00Z",
      "is_stale": false               // true if boundaries may have changed since resolution
    }
  }
}
```

### Field-Level Notes

**`congressional_district.geoid`:** The TIGER GEOID for CDs is `STATEFP + CD119FP`,
e.g., `"18"` + `"09"` = `"1809"`. The `CD119FP` value from TIGER is zero-padded to
2 digits. Store this as the canonical ID.

**`county.fips`:** The 5-digit FIPS is the universal join key for county data across
federal datasets. Store it, not just the county name.

**`place`:** Returns `null` for unincorporated addresses. This is a valid, expected
state — do not treat it as an error. Census Designated Places (CDPs) are statistical
entities, not governmental jurisdictions; they should NOT be returned here. Only
legally incorporated places (municipalities with their own government) belong in
this field.

**`school_district.geoid`:** The 7-digit NCES/TIGER LEAID (Local Education Agency
ID). For Indiana unified districts this is the TIGER UNSD `GEOID` field.
`1800630` is the LEAID for Monroe County Community School Corporation (confirmed
via NCES CCD).

**`resolution.geocode_accuracy`:** Values mirror the Google Maps Geocoding API
`location_type` field. Callers should warn users (but not block) when accuracy is
`approximate` and the query involves school board assignment — the district that
serves a `geometric_center`-quality coordinate may be wrong for exact boundary
cases.

---

## Edge Cases and Handling Strategies

### Edge Case 1 — Address Falls on District Boundary

**What happens:** PostGIS `ST_Within` returns FALSE for points exactly on a polygon
boundary. `ST_Contains` returns FALSE for a point on the boundary of the containing
polygon (technically outside the polygon's interior). This is a strict topological
edge case that occurs in practice when geocoders interpolate to street centerlines
that double as district boundaries.

**Handling strategy:** Use `ST_Covers` instead of `ST_Contains` or `ST_Within`.
`ST_Covers(district_polygon, user_point)` returns TRUE when the point is on the
boundary — it does not require the point to be in the strict interior.

```sql
-- Preferred predicate for jurisdiction resolution
SELECT sd.geoid, sd.name
FROM school_districts sd
WHERE ST_Covers(sd.geom, ST_SetSRID(ST_Point($lng, $lat), 4326))
```

For adjacent districts that share a border, a boundary point will satisfy
`ST_Covers` for both polygons. TIGER/Line polygons from the same layer
(e.g., two adjacent school districts) have topologically shared edges with no
gap, so in practice a boundary point resolves to exactly one district because the
shared edge belongs to exactly one polygon in TIGER's topology. If the query
somehow returns multiple matches (data quality issue), take the first match by
area (largest containing district) and log the ambiguity.

**Confidence:** MEDIUM — PostGIS documentation verifies ST_Covers semantics;
TIGER topology behavior is inference from documentation.

### Edge Case 2 — Unincorporated Address (No Municipality)

**What happens:** An address outside any incorporated city or town will not match
any row in the `places` layer. This is normal for rural Indiana addresses and for
addresses in Census Designated Places (which are statistical, not governmental).

**Handling strategy:** `place` field returns `null`. This is not an error state.
The county field still resolves (every address in the US is in exactly one county).
County-level representatives cover unincorporated areas. Do not attempt to return
a CDP as a substitute for a municipality — CDPs have no elected officials.

### Edge Case 3 — PO Box Address

**What happens:** A PO Box is a mail delivery address, not a physical location.
Geocoders return either the post office coordinates or a ZIP-centroid for PO Boxes.
Neither is suitable for district resolution — especially school board districts
where exact address matters.

**Handling strategy:**
1. Validate the address format at the Connect flow input step before geocoding.
   Detect and reject PO Box formats (`P\.?O\.?\s*Box`, `Post\s*Office\s*Box`) with
   a user-facing message: "A residential or business street address is required for
   jurisdiction resolution. PO Box addresses cannot be used."
2. If a PO Box somehow reaches the geocoder and returns coordinates, check the
   geocode accuracy. A PO Box geocoded to `approximate` or `geometric_center`
   should be rejected — do not store the coordinates or resolve jurisdiction.
3. The `location_consent` flag on `connected_profiles` should remain `false`
   for users who cannot provide a valid street address.

### Edge Case 4 — Address Not Geocodable (Geocoder Returns No Results)

**What happens:** The geocoder returns zero results for an address. This happens
for rural routes, very new streets, addresses with typos, or non-standard formats.

**Handling strategy:**
1. Return a 422 from the address submission endpoint with `{ error: "address_not_found", message: "..." }`.
2. Suggest address corrections: prompt for full street address including apartment/unit.
3. Do not fall back to ZIP-centroid geocoding for jurisdiction purposes. A ZIP
   centroid will resolve the correct county and congressional district most of the
   time, but will fail for school board resolution near district boundaries.
4. Log the raw failed address (encrypted, not in plain text) for admin review.
   Pattern failures may indicate a missing street in the geocoder's reference data.

### Edge Case 5 — Low-Accuracy Geocode (Range Interpolation vs. Rooftop)

**What happens:** Most geocoders interpolate addresses along street segments when
no rooftop-level coordinate is available. The resulting point is on the street
centerline, within the correct block, but may be tens of meters from the actual
structure. For dense districts (city council wards, school attendance boundaries
within a single school district), this is usually acceptable. For school district
boundaries between neighboring districts, it may not be.

**Handling strategy:**
1. Return `geocode_accuracy` in the resolution metadata so callers can display
   appropriate confidence UI.
2. For `rooftop` or `range_interpolated` accuracy: proceed with full resolution.
3. For `geometric_center` or `approximate` accuracy: resolve and return, but set
   `resolution.low_confidence: true` in the response so Validation Quests can
   opt out of school-board-specific quest surfacing.
4. Do not silently discard low-accuracy geocodes — just surface the limitation.

### Edge Case 6 — Address in a Split School District County

**What happens:** Monroe County has two school districts: MCCSC (most of the county)
and Richland-Bean Blossom CSC (Richland and Bean Blossom townships). A user in
Richland Township will not be served by MCCSC. The ZIP code or city name alone
cannot distinguish between these — exact address is required.

**Handling strategy:** This is the core reason for PostGIS over ZIP lookup. The
`ST_Covers` query against `school_districts` (loaded from `tl_2024_18_unsd.zip`)
handles this correctly as long as geocode accuracy is `rooftop` or
`range_interpolated`. No special casing needed — it resolves naturally.

**This is the canonical example of why ZIP-based jurisdiction lookup is insufficient
for this feature.**

### Edge Case 7 — Redistricting (Boundaries Change Mid-Year)

**What happens:** Congressional and state legislative districts are redrawn after
each decennial census. Indiana's districts were redrawn in 2021 (post-2020 census).
Between redistricting cycles, TIGER/Line shapefiles are updated annually. A user's
stored jurisdiction may become stale if boundaries are redrawn.

**Handling strategy:**
1. Store `resolved_at` timestamp with the jurisdiction data.
2. Implement a `is_stale` flag that can be set by an admin job when new TIGER/Line
   files are loaded. When `is_stale = true`, the next call to
   `GET /api/account/me/jurisdiction` re-resolves from stored coordinates.
3. For Alpha scale: re-resolution can be triggered manually by an admin migration.
   Automated re-resolution (cron job) is a post-Alpha concern.

### Edge Case 8 — Address Outside Indiana

**What happens:** For Alpha, the platform is Indiana-scoped. A user providing a
non-Indiana address should not get a partial jurisdiction resolution (federal
districts only) — that would be misleading.

**Handling strategy:**
1. After geocoding, check that the returned state FIPS is `18` (Indiana).
2. If not Indiana: return 422 with `{ error: "outside_alpha_region", message: "During the Alpha, location must be within Indiana." }`.
3. Do not store coordinates for out-of-state addresses.
4. Document this as a known limitation in the API contract — it will be lifted
   when the platform expands beyond Indiana.

---

## Table Stakes vs. Differentiators for This Feature

### Table Stakes

| Feature | Why Required | Complexity |
|---------|-------------|------------|
| Congressional district resolution | Federal representative lookup requires it | Low (single ST_Covers query) |
| State senate district resolution | State senator lookup requires it | Low |
| State house district resolution | State rep lookup requires it | Low |
| County resolution | Universal coverage — every address has one | Low |
| Place resolution (null for unincorporated) | City/town mayor and council lookup | Low |
| School district resolution | School board member lookup; ZIP cannot do this | Low (query) / Medium (setup) |
| PO Box rejection | Prevents corrupt jurisdiction data | Low |
| `geocode_accuracy` in response | Callers need to know confidence level | Trivial |
| Unincorporated area handling (null place) | 30–40% of Indiana addresses are unincorporated | Trivial |

### Differentiators

| Feature | Value | Complexity |
|---------|-------|------------|
| Never returning coordinates | Privacy architecture — jurisdiction replaces location | Low |
| `is_stale` flag for redistricting | Proactive data quality without forcing re-consent | Low |
| Encrypted lat/lng at rest (pgcrypto/Vault) | Coordinates are sensitive PII; encrypt before storing | Medium |
| `location_consent` flag | User controls when their address is geocoded | Low |

### Anti-Features (Explicit Exclusions)

| Anti-Feature | Why Excluded |
|-------------|--------------|
| Return raw lat/lng in jurisdiction response | Violates privacy architecture; jurisdiction IDs are sufficient for all consumers |
| ZIP-based lookup as primary method | Fails for school board districts; ZIP centroids are unreliable for boundary cases |
| Return Census Designated Places as municipalities | CDPs have no elected officials; including them would produce false representative results |
| Load national-scope TIGER files for school districts | Indiana uses unified districts only; ELSD/SCSD are irrelevant here |
| Return ZCTA as jurisdiction | ZCTAs are statistical geographies, not political jurisdictions |
| Special district resolution in Alpha | No statewide GIS source; Indiana has ~1,800 special districts with inconsistent boundary data |

---

## Consumer API Contract Summary

The `/api/account/me/jurisdiction` endpoint is consumed by:

**Essentials (local officials lookup):**
- Uses `congressional_district.geoid` → looks up U.S. House member
- Uses `state_senate_district.geoid` → looks up Indiana State Senator
- Uses `state_house_district.geoid` → looks up Indiana State Rep
- Uses `county.fips` → looks up county commissioners, county council
- Uses `place.fips` (if not null) → looks up mayor, city council
- Uses `school_district.geoid` → looks up school board members

**Validation Quests:**
- Uses `county.fips` + `place.fips` to filter quests by location relevance
- Uses `school_district.geoid` to surface school board quests
- Does not need `resolution.geocode_accuracy` for filtering; uses it for trust scoring

**Response must NEVER include:**
- Raw latitude/longitude
- Home address or any fragment of it
- Geocoder raw response
- Any field derivable to a precise home location

---

## Sources

- U.S. Census Bureau TIGER/Line 2024 FTP index: https://www2.census.gov/geo/tiger/TIGER2024/
- TIGER/Line 2024 Technical Documentation: https://www2.census.gov/geo/pdfs/maps-data/data/tiger/tgrshp2024/TGRSHP2024_TechDoc.pdf
- TIGER/Line 2024 Shapefile Name Definitions: https://www2.census.gov/geo/tiger/TIGER2024/2024_TL_Shapefiles_File_Name_Definitions.pdf
- PostGIS ST_Covers documentation: https://postgis.net/docs/ST_Covers.html
- PostGIS ST_Contains documentation: https://postgis.net/docs/ST_Contains.html
- NCES School District Boundaries: https://nces.ed.gov/programs/edge/Geographic/DistrictBoundaries
- Monroe County Community School Corporation (NCES LEAID 1800630): https://nces.ed.gov/ccd/districtsearch/district_detail.asp?Search=2&details=1&DistrictID=1800630&ID2=1800630
- Monroe County Community School Corporation (Wikipedia): https://en.wikipedia.org/wiki/Monroe_County_Community_School_Corporation
- Indiana Special Districts (SBOA): https://www.in.gov/sboa/political-subdivisions/special-districts/
- IndianaMap GIS portal: https://www.indianamap.org/
- Indiana's 9th Congressional District: https://en.wikipedia.org/wiki/Indiana%27s_9th_congressional_district
- Census unincorporated area identification: https://www.serviceobjects.com/blog/how-to-identify-incorporated-and-unincorporated-places-in-the-united-states/
- Google Civic Information API (now retired, district type taxonomy reference): https://developers.google.com/civic-information/docs/v2
- Open Civic Data OCD-ID specification: https://open-civic-data.readthedocs.io/en/latest/ocdids.html
- Point-in-polygon boundary behavior (PostGIS users group): https://groups.google.com/g/postgis-users/c/3yB6im4wRGw
- Geocoding accuracy levels (Geocodio): https://www.geocod.io/guides/accuracy-types-scores/

---

**Confidence summary:**

| Area | Confidence | Basis |
|------|------------|-------|
| TIGER/Line folder names (CD, SLDU, SLDL, COUNTY, PLACE, UNSD) | HIGH | Verified via live Census FTP index |
| Indiana = unified school districts only | HIGH | NCES data, MCCSC Wikipedia, TIGER catalog entries for Indiana |
| Indiana FIPS = 18, Monroe County FIPS = 18105 | HIGH | Multiple Census sources |
| Monroe County congressional district = IN-09 | HIGH | Wikipedia + Chamber of Commerce source |
| Monroe County state senate includes District 40 | MEDIUM | Search results; exact per-address district requires query |
| ST_Covers as correct boundary predicate | MEDIUM | PostGIS documentation; TIGER topology inference |
| MCCSC NCES LEAID = 1800630 | HIGH | Direct NCES CCD link |
| Indiana special district boundary unavailability | MEDIUM | SBOA lists them; no statewide GIS source found |

*Overwrite of previous FEATURES.md (original covered tiered account system features from v1.0 greenfield research, no longer needed as active research file — that content is now embedded in the shipped implementation).*
